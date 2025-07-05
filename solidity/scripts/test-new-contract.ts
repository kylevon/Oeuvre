import { artifacts } from "hardhat";

async function main() {
  console.log("Testing new contract...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const bidder = accounts[1];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    console.log("Admin:", admin);
    console.log("Bidder:", bidder);
    console.log("Contract:", auctionAddress);
    
    // Check current block timestamp
    const block = await connection.provider.send("eth_getBlockByNumber", ["latest", false]);
    const currentTime = parseInt(block.timestamp, 16);
    console.log("Current block timestamp:", currentTime);
    
    // Check art piece 1 (should be the new Mona Lisa)
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000001";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    console.log("Art piece 1 result:", artPieceResult);
    
    // Decode the result to check auction end time
    const auctionEndTimeHex = artPieceResult.substring(258, 322);
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    console.log("Auction end time:", auctionEndTime);
    console.log("Has auction ended?", currentTime >= auctionEndTime);
    console.log("Time until end:", auctionEndTime - currentTime, "seconds");
    
    // Add a bid
    console.log("Adding bid...");
    const bidData = "0x454a2ab3" + "0000000000000000000000000000000000000000000000000000000000000001";
    
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
    
    // Check collective bid
    const getCollectiveBidData = "0x9b971a34" + "0000000000000000000000000000000000000000000000000000000000000001";
    const collectiveBidResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getCollectiveBidData
    }]);
    
    console.log("Collective bid result:", collectiveBidResult);
    const collectiveBid = parseInt(collectiveBidResult, 16);
    console.log("Collective bid (ETH):", collectiveBid / 1e18);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 