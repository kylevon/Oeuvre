import { artifacts } from "hardhat";

async function main() {
  console.log("Debugging auction state...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const auctionAddress = "0x998abeb3e57409262ae5b751f60747921b33613e";
    
    // Check current block timestamp
    const block = await connection.provider.send("eth_getBlockByNumber", ["latest", false]);
    const currentTime = parseInt(block.timestamp, 16);
    console.log("Current block timestamp:", currentTime);
    console.log("Current time (human):", new Date(currentTime * 1000).toISOString());
    
    // Check art piece 2
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000002";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    console.log("Art piece 2 raw result:", artPieceResult);
    
    // Decode the result manually
    // The result structure is: name (string), exists (bool), createdAt (uint256), totalTokens (uint256), isAuctionActive (bool), auctionFinalized (bool), highestBid (uint256), highestBidder (address), auctionEndTime (uint256)
    
    // Extract auctionEndTime (should be around position 258-322)
    const auctionEndTimeHex = artPieceResult.substring(258, 322);
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    console.log("Auction end time (hex):", auctionEndTimeHex);
    console.log("Auction end time (decimal):", auctionEndTime);
    console.log("Auction end time (human):", new Date(auctionEndTime * 1000).toISOString());
    
    console.log("Has auction ended?", currentTime >= auctionEndTime);
    console.log("Time difference:", auctionEndTime - currentTime, "seconds");
    
    // Check if auction is active
    const isAuctionActiveHex = artPieceResult.substring(194, 258);
    const isAuctionActive = parseInt(isAuctionActiveHex, 16) === 1;
    console.log("Is auction active:", isAuctionActive);
    
    // Check if auction is finalized
    const isAuctionFinalizedHex = artPieceResult.substring(258, 322);
    const isAuctionFinalized = parseInt(isAuctionFinalizedHex, 16) === 1;
    console.log("Is auction finalized:", isAuctionFinalized);
    
    // Check highest bid
    const highestBidHex = artPieceResult.substring(322, 386);
    const highestBid = parseInt(highestBidHex, 16);
    console.log("Highest bid (wei):", highestBid);
    console.log("Highest bid (ETH):", highestBid / 1e18);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 