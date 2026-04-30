import 'dart:convert';
import 'package:http/http.dart';
import 'package:web3dart/web3dart.dart';
import '../config/blockchain_config.dart';

class BlockchainService {
  late Web3Client _client;
  late Credentials _credentials;
  late DeployedContract _contract;
  late ContractFunction _addReview;
  late ContractFunction _getReviews;
  
  static BlockchainService? _instance;
  static bool _isInitialized = false;

  BlockchainService._();

  static Future<BlockchainService> getInstance() async {
    if (_instance == null || !_isInitialized) {
      _instance = BlockchainService._();
      try {
        await _instance!._initialize();
        _isInitialized = true;
      } catch (e) {
        print('❌ BlockchainService getInstance failed: $e');
        _instance = null;
        _isInitialized = false;
        rethrow;
      }
    }
    return _instance!;
  }

  Future<void> _initialize() async {
    try {
      print('🔧 Initializing BlockchainService...');
      
      final httpClient = Client();
      _client = Web3Client(BlockchainConfig.rpcUrl, httpClient);
      print('✅ Web3Client created');
      
      // Set up credentials from private key
      _credentials = EthPrivateKey.fromHex(BlockchainConfig.privateKey);
      final address = await _credentials.extractAddress();
      print('✅ Credentials loaded. Address: $address');
      
      // Load Contract ABI
      const abiString = '''[
  {
    "inputs": [
      {"internalType": "string", "name": "_packageId", "type": "string"},
      {"internalType": "uint8", "name": "_rating", "type": "uint8"},
      {"internalType": "string", "name": "_comment", "type": "string"}
    ],
    "name": "addReview",
    "outputs": [],
    "stateMutability": "nonpayable",
    "type": "function"
  },
  {
    "inputs": [
      {"internalType": "string", "name": "_packageId", "type": "string"}
    ],
    "name": "getReviews",
    "outputs": [
      {
        "components": [
          {"internalType": "address", "name": "traveler", "type": "address"},
          {"internalType": "string", "name": "packageId", "type": "string"},
          {"internalType": "uint8", "name": "rating", "type": "uint8"},
          {"internalType": "string", "name": "comment", "type": "string"},
          {"internalType": "uint256", "name": "timestamp", "type": "uint256"}
        ],
        "internalType": "struct ReviewContract.Review[]",
        "name": "",
        "type": "tuple[]"
      }
    ],
    "stateMutability": "view",
    "type": "function"
  }
]''';

      print('🔧 Parsing ABI JSON...');
      try {
        final abiJson = jsonDecode(abiString);
        print('✅ ABI JSON parsed: ${abiJson.length} functions found');
        
        print('🔧 Creating ContractAbi...');
        final abi = ContractAbi.fromJson(jsonEncode(abiJson), 'ReviewContract');
        print('✅ ContractAbi created');
        
        print('🔧 Creating contract instance...');
        _contract = DeployedContract(
          abi,
          EthereumAddress.fromHex(BlockchainConfig.contractAddress),
        );
        print('✅ Contract instance created at ${BlockchainConfig.contractAddress}');

        _addReview = _contract.function('addReview');
        _getReviews = _contract.function('getReviews');
        print('✅ Contract functions loaded: addReview, getReviews');
      } catch (abiError) {
        print('❌ ABI parsing error: $abiError');
        rethrow;
      }
      
      print('🎉 BlockchainService initialized successfully!');
    } catch (e, stackTrace) {
      print('❌ Failed to initialize BlockchainService: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Adds a review to the blockchain
  Future<String> addReview(String packageId, int rating, String comment) async {
    try {
      // Verify the service is initialized
      if (!_isInitialized) {
        throw Exception('BlockchainService is not properly initialized. Please check your blockchain configuration.');
      }
      
      print('🔗 Submitting review to blockchain...');
      print('📦 Package ID: $packageId');
      print('⭐ Rating: $rating');
      print('💬 Comment: $comment');
      
      // Get the account address
      final address = await _credentials.extractAddress();
      print('👤 Account Address: $address');
      
      // Check balance
      try {
        final balance = await _client.getBalance(address);
        print('💰 Account Balance: ${balance.getInWei} wei');
        
        if (balance.getInWei == BigInt.zero) {
          throw Exception('Insufficient funds. Account has 0 MATIC. Please add test MATIC from https://faucet.polygon.technology/');
        }
      } catch (e) {
        print('⚠️ Warning: Could not check balance: $e');
      }
      
      // Send transaction with explicit gas parameters
      final transaction = Transaction.callContract(
        contract: _contract,
        function: _addReview,
        parameters: [packageId, BigInt.from(rating), comment],
        maxGas: 500000, // Set explicit gas limit
      );
      
      print('📤 Sending transaction...');
      final response = await _client.sendTransaction(
        _credentials,
        transaction,
        chainId: BlockchainConfig.chainId,
        fetchChainIdFromNetworkId: false,
      );
      
      print('✅ Transaction sent successfully!');
      print('🔗 Transaction Hash: $response');
      
      if (response.isEmpty) {
        throw Exception('Transaction hash is empty. Transaction may have failed.');
      }
      
      return response;
    } catch (e, stackTrace) {
      print('❌ Error adding review to blockchain: $e');
      print('Stack trace: $stackTrace');
      
      // Provide more user-friendly error messages
      String errorMessage = e.toString();
      
      if (errorMessage.contains('insufficient funds') || errorMessage.contains('Null')) {
        errorMessage = 'Insufficient funds: Please add test MATIC from https://faucet.polygon.technology/ to address: ${await _credentials.extractAddress()}';
      } else if (errorMessage.contains('nonce')) {
        errorMessage = 'Transaction nonce error. Please try again.';
      } else if (errorMessage.contains('gas')) {
        errorMessage = 'Gas estimation failed. The contract may not exist at this address.';
      }
      
      throw Exception(errorMessage);
    }
  }

  /// Fetches reviews for a package from the blockchain
  Future<List<Map<String, dynamic>>> getReviews(String packageId) async {
    try {
      if (BlockchainConfig.contractAddress == '0x0000000000000000000000000000000000000000') {
        // Return mock data if contract is not deployed for demo
        return [];
      }

      final result = await _client.call(
        contract: _contract,
        function: _getReviews,
        params: [packageId],
      );

      final List<dynamic> reviewsData = result[0];
      return reviewsData.map((review) {
        return {
          'traveler': review[0].toString(),
          'packageId': review[1],
          'rating': (review[2] as BigInt).toInt(),
          'comment': review[3],
          'timestamp': DateTime.fromMillisecondsSinceEpoch(
            (review[4] as BigInt).toInt() * 1000,
          ),
        };
      }).toList();
    } catch (e) {
      print('Error getting reviews from blockchain: $e');
      return [];
    }
  }

  /// Returns the balance of the current account in native currency
  Future<EtherAmount> getBalance() async {
    return await _client.getBalance(_credentials.address);
  }
}
