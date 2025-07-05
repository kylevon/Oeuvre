import { artifacts } from "hardhat";

async function main() {
  console.log("Adding bid and confirming auction...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const bidder = accounts[1]; // Use second account as bidder
    const auctionAddress = "0x998abeb3e57409262ae5b751f60747921b33613e";
    
    console.log("Admin:", admin);
    console.log("Bidder:", bidder);
    
    // Add a bid to the auction (art piece 2)
    console.log("Adding bid to auction...");
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
    
    // Wait a moment for the transaction to be processed
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Check the collective bid
    const getCollectiveBidData = "0x9b971a34" + "0000000000000000000000000000000000000000000000000000000000000002";
    const collectiveBidResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: getCollectiveBidData
    }]);
    
    console.log("Collective bid result:", collectiveBidResult);
    
    // Now try to confirm the auction
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

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 