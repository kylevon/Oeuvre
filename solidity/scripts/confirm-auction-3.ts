import { artifacts } from "hardhat";

async function main() {
  console.log("Confirming auction ID 3...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    console.log("Admin:", admin);
    console.log("Contract:", auctionAddress);
    
    // Confirm auction ID 3
    console.log("Confirming auction...");
    const confirmData = "0xa61c8077" + "0000000000000000000000000000000000000000000000000000000000000003";
    
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
    
    // Check if confirmation was successful
    if (confirmReceipt.status === "0x1") {
      console.log("Auction confirmed successfully!");
      
      // Check the ownership distribution
      const getOwnershipData = "0x8da5cb5b" + "00000000000000000000000070997970c51812dc3a010c7d01b50e0d17dc79c8" + "0000000000000000000000000000000000000000000000000000000000000003";
      const ownershipResult = await connection.provider.send("eth_call", [{
        from: admin,
        to: auctionAddress,
        data: getOwnershipData
      }]);
      
      console.log("Ownership result:", ownershipResult);
      const ownership = parseInt(ownershipResult, 16);
      console.log("Ownership percentage:", ownership / 1e16, "%");
    } else {
      console.log("Auction confirmation failed!");
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 