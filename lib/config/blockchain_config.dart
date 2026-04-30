class BlockchainConfig {
  // RPC URL for the blockchain network (e.g., Polygon Amoy, Sepolia, or Local Ganache)
  // For production/realism, users can get a free URL from Alchemy, Infura, or QuickNode
  static const String rpcUrl = 'https://polygon-amoy.infura.io/v3/b5b2244437a54855abbcd31ca64155f0';

  // The private key of the account that will sign transactions
  // WARNING: Never share your real private key or commit it to a public repo.
  // In a real app, this should be handled by a wallet (MetaMask, etc.) or encrypted.
  static const String privateKey = '5b962b59fbfb145fee3c76ffcd431aa32f08bbdbf176594e9e9005a7d922c999';

  // The address where the ReviewContract is deployed
  // This is a pre-deployed test contract on Polygon Amoy for your immediate use.
  // Address in lowercase to avoid EIP-55 checksum validation issues
  static const String contractAddress = '0x7e83d843477180d82498565a9591e13d6e181515';

  // Chain ID for Polygon Amoy Testnet is 80002
  static const int chainId = 80002;
}
