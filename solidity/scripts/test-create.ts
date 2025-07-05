import { artifacts } from "hardhat";

async function main() {
  console.log("Testing createArtPiece function...");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    // Get accounts
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    
    console.log("Testing with admin:", admin);
    
    // Contract address from deployment
    const auctionAddress = "0x9a676e781a523b5d0c0e43731313a708cb607508";
    
    // Test createArtPiece function
    const { Interface } = await import("ethers");
    const auctionIface = new Interface(auctionArtifact.abi);
    
    // Test parameters
    const artName = "Test Art Piece";
    const auctionDuration = 3600; // 1 hour
    
    console.log(`Creating art piece: "${artName}" with duration: ${auctionDuration} seconds`);
    
    const createArtPieceData = auctionIface.encodeFunctionData("createArtPiece", [
      artName,
      auctionDuration
    ]);
    
    console.log("Encoded data:", createArtPieceData);
    
    const createArtPieceTx = {
      from: admin,
      to: auctionAddress,
      data: createArtPieceData,
      gas: "0x3d0900"
    };
    
    try {
      const createArtPieceHash = await connection.provider.send("eth_sendTransaction", [createArtPieceTx]);
      console.log("Transaction hash:", createArtPieceHash);
      
      const receipt = await connection.provider.send("eth_getTransactionReceipt", [createArtPieceHash]);
      console.log("Transaction receipt:", receipt);
      
      if (receipt.status === "0x1") {
        console.log("✅ Art piece created successfully!");
      } else {
        console.log("❌ Transaction failed");
      }
    } catch (error) {
      console.error("❌ Error creating art piece:", error);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 