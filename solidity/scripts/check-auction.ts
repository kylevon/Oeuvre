import { artifacts } from "hardhat";

async function main() {
  console.log("Checking auction status...");

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
    
    // Check art piece 2 (the new one)
    const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000002";
    const artPieceResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getArtPieceData
    }]);
    
    console.log("Art piece 2 result:", artPieceResult);
    
    // Decode the result to get auction end time
    const auctionEndTimeHex = artPieceResult.substring(258, 322); // Extract auctionEndTime from the result
    const auctionEndTime = parseInt(auctionEndTimeHex, 16);
    console.log("Auction end time:", auctionEndTime);
    console.log("Has auction ended?", currentTime >= auctionEndTime);
    
    // Try to confirm the auction
    if (currentTime >= auctionEndTime) {
      console.log("Attempting to confirm auction...");
      const confirmData = "0x8f283970" + "0000000000000000000000000000000000000000000000000000000000000002";
      
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