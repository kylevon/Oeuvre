import { artifacts } from "hardhat";

async function main() {
  console.log("Creating a new art piece with long duration...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    console.log("Admin:", admin);
    console.log("Contract:", auctionAddress);
    
    // Check current block timestamp
    const block = await connection.provider.send("eth_getBlockByNumber", ["latest", false]);
    const currentTime = parseInt(block.timestamp, 16);
    console.log("Current block timestamp:", currentTime);
    
    // Create a new art piece with a very long duration (1 year)
    console.log("Creating new art piece with 1 year duration...");
    
    // Use ethers to encode the function call properly
    const auctionArtifact = await artifacts.readArtifact("Auction");
    const { Interface } = await import("ethers");
    const auctionInterface = new Interface(auctionArtifact.abi);
    const createArtPieceData = auctionInterface.encodeFunctionData("createArtPiece", ["Test Art", 31536000]); // 1 year
    
    console.log("Encoded data:", createArtPieceData);
    
    const createTx = {
      from: admin,
      to: auctionAddress,
      data: createArtPieceData,
      gas: "0x1e8480"
    };
    
    const createHash = await connection.provider.send("eth_sendTransaction", [createTx]);
    console.log("Create transaction hash:", createHash);
    
    const createReceipt = await connection.provider.send("eth_getTransactionReceipt", [createHash]);
    console.log("Create transaction receipt:", createReceipt);
    
    // Check the new art piece (should be ID 2)
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000002";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    console.log("New art piece result:", artPieceResult);
    
    // Decode the auction end time
    const auctionEndTimeHex = artPieceResult.substring(258, 322);
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    console.log("Auction end time:", auctionEndTime);
    console.log("Has auction ended?", currentTime >= auctionEndTime);
    console.log("Time until end:", auctionEndTime - currentTime, "seconds");
    console.log("Time until end (days):", (auctionEndTime - currentTime) / 86400);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 