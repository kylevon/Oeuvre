import { artifacts } from "hardhat";

async function main() {
  console.log("Checking auction state...");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    // Get accounts
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    
    console.log("Checking with account:", admin);
    
    // Get the deployed contract address
    const contractAddress = "0x9a676e781a523b5d0c0e43731313a708cb607508";
    
    // Get the number of art pieces
    const artPieceCountData = auctionArtifact.abi.find(entry => entry.type === "function" && entry.name === "getArtPieceCount");
    if (!artPieceCountData) {
      console.error("getArtPieceCount function not found in ABI");
      return;
    }
    
    const artPieceCountResult = await connection.provider.send("eth_call", [{
      to: contractAddress,
      data: artPieceCountData.selector
    }]);
    
    const artPieceCount = parseInt(artPieceCountResult, 16);
    console.log("Total art pieces:", artPieceCount);
    
    // Check each art piece
    for (let i = 1; i <= artPieceCount; i++) {
      console.log(`\n=== Art Piece ${i} ===`);
      
      // Get art piece data
      const getArtPieceData = auctionArtifact.abi.find(entry => entry.type === "function" && entry.name === "getArtPiece");
      if (!getArtPieceData) {
        console.error("getArtPiece function not found in ABI");
        continue;
      }
      
      const artPieceData = getArtPieceData.selector + "000000000000000000000000000000000000000000000000000000000000000" + i.toString(16);
      const artPieceResult = await connection.provider.send("eth_call", [{
        to: contractAddress,
        data: artPieceData
      }]);
      
      // Get bidders for this art piece
      const getBiddersData = auctionArtifact.abi.find(entry => entry.type === "function" && entry.name === "getAuctionBidders");
      if (!getBiddersData) {
        console.error("getAuctionBidders function not found in ABI");
        continue;
      }
      
      const biddersData = getBiddersData.selector + "000000000000000000000000000000000000000000000000000000000000000" + i.toString(16);
      const biddersResult = await connection.provider.send("eth_call", [{
        to: contractAddress,
        data: biddersData
      }]);
      
      console.log("Bidders result:", biddersResult);
      
      // Simple decoding - check if result indicates any bidders
      if (biddersResult && biddersResult !== "0x") {
        console.log("Number of bidders: > 0 (has bidders)");
      } else {
        console.log("Number of bidders: 0 (no bidders)");
      }
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 