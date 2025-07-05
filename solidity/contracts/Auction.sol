// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Auction {
    address public admin;
    uint256 public auctionEnd;
    bool public finalized;
    address public artOwner;
    uint256 public totalBid;
    mapping(address => uint256) public bids;
    mapping(address => uint256) public tokens;
    mapping(address => bool) public hasVoted;
    string public artPresentation;
    address[] public holders;
    
    event Bid(address indexed user, uint256 amount);
    event Withdraw(address indexed user, uint256 amount);
    event Finalized(address indexed winner, uint256 totalBid);
    event TokensIssued(address indexed user, uint256 tokens);
    event Payout(address indexed user, uint256 amount);
    event ArtPresentationChanged(string newPresentation);
    event Voted(address indexed user);

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only admin");
        _;
    }
    modifier auctionActive() {
        require(block.timestamp < auctionEnd && !finalized, "Auction ended");
        _;
    }
    modifier auctionEnded() {
        require(block.timestamp >= auctionEnd || finalized, "Auction not ended");
        _;
    }

    constructor(uint256 _duration) {
        admin = msg.sender;
        auctionEnd = block.timestamp + _duration;
    }

    function bid() external payable auctionActive {
        require(msg.value > 0, "No ETH sent");
        bids[msg.sender] += msg.value;
        totalBid += msg.value;
        emit Bid(msg.sender, msg.value);
    }

    function bidWithTracking() external payable auctionActive {
        require(msg.value > 0, "No ETH sent");
        if (bids[msg.sender] == 0) {
            holders.push(msg.sender);
        }
        bids[msg.sender] += msg.value;
        totalBid += msg.value;
        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external auctionActive {
        uint256 amount = bids[msg.sender];
        require(amount > 0, "No bid to withdraw");
        bids[msg.sender] = 0;
        totalBid -= amount;
        payable(msg.sender).transfer(amount);
        emit Withdraw(msg.sender, amount);
    }

    function finalize(address _artOwner) external onlyAdmin auctionEnded {
        require(!finalized, "Already finalized");
        finalized = true;
        artOwner = _artOwner;
        for (uint i = 0; i < holders.length; i++) {
            address user = holders[i];
            uint256 userBid = bids[user];
            if (userBid > 0) {
                uint256 userTokens = (userBid * 1e18) / totalBid;
                tokens[user] = userTokens;
                emit TokensIssued(user, userTokens);
            }
        }
        emit Finalized(_artOwner, totalBid);
    }

    function changeArtPresentation(string calldata newPresentation) external onlyAdmin {
        artPresentation = newPresentation;
        emit ArtPresentationChanged(newPresentation);
    }

    function vote() external auctionEnded {
        require(tokens[msg.sender] > 0, "No tokens");
        require(!hasVoted[msg.sender], "Already voted");
        hasVoted[msg.sender] = true;
        emit Voted(msg.sender);
    }

    function endAuctionEarly() external onlyAdmin {
        auctionEnd = block.timestamp;
    }

    function payoutOnResale(uint256 amount) external onlyAdmin auctionEnded {
        require(amount > 0, "No payout");
        for (uint i = 0; i < holders.length; i++) {
            address user = holders[i];
            uint256 share = (tokens[user] * amount) / 1e18;
            if (share > 0) {
                payable(user).transfer(share);
                emit Payout(user, share);
            }
        }
    }
} 