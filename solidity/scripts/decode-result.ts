import { artifacts } from "hardhat";

async function main() {
  console.log("Decoding getArtPiece result...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    // Check art piece 2 (the new one we just created)
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000002";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    console.log("Raw result:", artPieceResult);
    console.log("Result length:", artPieceResult.length);
    
    // The result should be: name (string), exists (bool), createdAt (uint256), totalTokens (uint256), isAuctionActive (bool), auctionFinalized (bool), highestBid (uint256), highestBidder (address), auctionEndTime (uint256)
    
    // Decode step by step
    let offset = 2; // Skip 0x
    
    // 1. name (string) - dynamic type, first 32 bytes is offset
    const nameOffsetHex = artPieceResult.substring(offset, offset + 64);
    const nameOffset = parseInt(nameOffsetHex, 16);
    console.log("Name offset:", nameOffset);
    
    // 2. exists (bool) - 32 bytes
    offset += 64;
    const existsHex = artPieceResult.substring(offset, offset + 64);
    const exists = parseInt(existsHex, 16) === 1;
    console.log("Exists:", exists);
    
    // 3. createdAt (uint256) - 32 bytes
    offset += 64;
    const createdAtHex = artPieceResult.substring(offset, offset + 64);
    const createdAt = parseInt(createdAtHex, 16);
    console.log("Created at:", createdAt);
    
    // 4. totalTokens (uint256) - 32 bytes
    offset += 64;
    const totalTokensHex = artPieceResult.substring(offset, offset + 64);
    const totalTokens = parseInt(totalTokensHex, 16);
    console.log("Total tokens:", totalTokens);
    
    // 5. isAuctionActive (bool) - 32 bytes
    offset += 64;
    const isAuctionActiveHex = artPieceResult.substring(offset, offset + 64);
    const isAuctionActive = parseInt(isAuctionActiveHex, 16) === 1;
    console.log("Is auction active:", isAuctionActive);
    
    // 6. auctionFinalized (bool) - 32 bytes
    offset += 64;
    const auctionFinalizedHex = artPieceResult.substring(offset, offset + 64);
    const auctionFinalized = parseInt(auctionFinalizedHex, 16) === 1;
    console.log("Auction finalized:", auctionFinalized);
    
    // 7. highestBid (uint256) - 32 bytes
    offset += 64;
    const highestBidHex = artPieceResult.substring(offset, offset + 64);
    const highestBid = parseInt(highestBidHex, 16);
    console.log("Highest bid:", highestBid);
    console.log("Highest bid (ETH):", highestBid / 1e18);
    
    // 8. highestBidder (address) - 32 bytes
    offset += 64;
    const highestBidderHex = artPieceResult.substring(offset, offset + 64);
    const highestBidder = "0x" + highestBidderHex.substring(24);
    console.log("Highest bidder:", highestBidder);
    
    // 9. auctionEndTime (uint256) - 32 bytes
    offset += 64;
    const auctionEndTimeHex = artPieceResult.substring(offset, offset + 64);
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    console.log("Auction end time:", auctionEndTime);
    
    // Now decode the name
    const nameDataOffset = 2 + (nameOffset * 2); // Convert offset to hex string position
    const nameLengthHex = artPieceResult.substring(nameDataOffset, nameDataOffset + 64);
    const nameLength = parseInt(nameLengthHex, 16);
    console.log("Name length:", nameLength);
    
    const nameDataHex = artPieceResult.substring(nameDataOffset + 64, nameDataOffset + 64 + (nameLength * 2));
    const name = Buffer.from(nameDataHex, 'hex').toString().replace(/\0/g, '');
    console.log("Name:", name);
    
    // Check current time
    const block = await connection.provider.send("eth_getBlockByNumber", ["latest", false]);
    const currentTime = parseInt(block.timestamp, 16);
    console.log("Current time:", currentTime);
    console.log("Has auction ended?", currentTime >= auctionEndTime);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 