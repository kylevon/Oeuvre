import { artifacts } from "hardhat";

async function main() {
  console.log("Testing full auction flow...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const bidder = accounts[1];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    console.log("Admin:", admin);
    console.log("Bidder:", bidder);
    
    // Add a bid to auction ID 2
    console.log("Adding bid to auction ID 2...");
    const bidData = "0x454a2ab3" + "0000000000000000000000000000000000000000000000000000000000000002";
    
    const bidTx = {
      from: bidder,
      to: auctionAddress,
      data: bidData,
      value: "0x56bc75e2d63100000", // 100 ETH in wei
      gas: "0x1e8480"
    };
    
    const bidHash = await connection.provider.send("eth_sendTransaction", [bidTx]);
    console.log("Bid transaction hash:", bidHash);
    
    const bidReceipt = await connection.provider.send("eth_getTransactionReceipt", [bidHash]);
    console.log("Bid transaction receipt:", bidReceipt);
    
    // Check the collective bid
    const getCollectiveBidData = "0x9b971a34" + "0000000000000000000000000000000000000000000000000000000000000002";
    const collectiveBidResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getCollectiveBidData
    }]);
    
    console.log("Collective bid result:", collectiveBidResult);
    const collectiveBid = parseInt(collectiveBidResult, 16);
    console.log("Collective bid (ETH):", collectiveBid / 1e18);
    
    // For testing purposes, let's create a new auction with a very short duration (1 minute)
    console.log("Creating a new auction with 1 minute duration for testing...");
    
    const auctionArtifact = await artifacts.readArtifact("Auction");
    const { Interface } = await import("ethers");
    const auctionInterface = new Interface(auctionArtifact.abi);
    const createArtPieceData = auctionInterface.encodeFunctionData("createArtPiece", ["Quick Test", 60]); // 1 minute
    
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
    
    // Add a bid to the quick test auction (ID 3)
    console.log("Adding bid to quick test auction...");
    const bidData2 = "0x454a2ab3" + "0000000000000000000000000000000000000000000000000000000000000003";
    
    const bidTx2 = {
      from: bidder,
      to: auctionAddress,
      data: bidData2,
      value: "0x1bc16d674ec80000", // 20 ETH in wei
      gas: "0x1e8480"
    };
    
    const bidHash2 = await connection.provider.send("eth_sendTransaction", [bidTx2]);
    console.log("Bid 2 transaction hash:", bidHash2);
    
    const bidReceipt2 = await connection.provider.send("eth_getTransactionReceipt", [bidHash2]);
    console.log("Bid 2 transaction receipt:", bidReceipt2);
    
    // Wait 2 minutes for the auction to end
    console.log("Waiting 2 minutes for auction to end...");
    await new Promise(resolve => setTimeout(resolve, 120000));
    
    // Check if auction has ended
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000003";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    // Decode auction end time
    const auctionEndTimeHex = artPieceResult.substring(258, 322);
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    
    const block = await connection.provider.send("eth_getBlockByNumber", ["latest", false]);
    const currentTime = parseInt(block.timestamp, 16);
    
    console.log("Auction end time:", auctionEndTime);
    console.log("Current time:", currentTime);
    console.log("Has auction ended?", currentTime >= auctionEndTime);
    
    if (currentTime >= auctionEndTime) {
      console.log("Auction has ended, attempting to confirm...");
      const confirmData = "0x8f283970" + "0000000000000000000000000000000000000000000000000000000000000003";
      
      const confirmTx = {
        from: admin,
        to: auctionAddress,
        data: confirmData,
        gas: "0x1e8480"
      };
      
      const confirmHash = await connection.provider.send("eth_sendTransaction", [confirmTx]);
      console.log("Confirm transaction hash:", confirmHash);
      
      const confirmReceipt = await connection.provider.send("eth_getTransactionReceipt", [confirmHash]);
      console.log("Confirm transaction receipt:", confirmReceipt);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 