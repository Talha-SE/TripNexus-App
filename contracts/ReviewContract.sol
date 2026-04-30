// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ReviewContract {
    struct Review {
        address traveler;
        string packageId;
        uint8 rating;
        string comment;
        uint256 timestamp;
    }

    // Mapping from packageId to an array of reviews
    mapping(string => Review[]) private packageReviews;

    // Event emitted when a new review is added
    event ReviewAdded(
        address indexed traveler,
        string indexed packageId,
        uint8 rating,
        uint256 timestamp
    );

    /**
     * @dev Adds a new review for a specific package.
     * @param _packageId The unique identifier of the package.
     * @param _rating The rating given by the traveler (1-5).
     * @param _comment The review comment.
     */
    function addReview(
        string memory _packageId,
        uint8 _rating,
        string memory _comment
    ) public {
        require(_rating >= 1 && _rating <= 5, "Rating must be between 1 and 5");
        require(bytes(_packageId).length > 0, "Package ID cannot be empty");

        Review memory newReview = Review({
            traveler: msg.sender,
            packageId: _packageId,
            rating: _rating,
            comment: _comment,
            timestamp: block.timestamp
        });

        packageReviews[_packageId].push(newReview);

        emit ReviewAdded(msg.sender, _packageId, _rating, block.timestamp);
    }

    /**
     * @dev Returns all reviews for a specific package.
     * @param _packageId The unique identifier of the package.
     */
    function getReviews(string memory _packageId) public view returns (Review[] memory) {
        return packageReviews[_packageId];
    }

    /**
     * @dev Returns the number of reviews for a specific package.
     * @param _packageId The unique identifier of the package.
     */
    function getReviewCount(string memory _packageId) public view returns (uint256) {
        return packageReviews[_packageId].length;
    }
}
