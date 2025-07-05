import { artifacts } from "hardhat";

async function main() {
  console.log("Testing Auction contract functionality...");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  console.log("Auction artifact loaded:", auctionArtifact.contractName);
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    try {
      // Get accounts
      const accounts = await connection.provider.send("eth_accounts", []);
      console.log("Available accounts:", accounts);
      
      // Deploy a new auction for testing
      const duration = 3600; // 1 hour
      const deployTx = {
        from: accounts[0],
        data: auctionArtifact.bytecode + "0000000000000000000000000000000000000000000000000000000000000e10", // duration = 3600
        gas: "0x1e8480" // 2000000 gas
      };
      
      console.log("Deploying test auction...");
      const deployHash = await connection.provider.send("eth_sendTransaction", [deployTx]);
      const deployReceipt = await connection.provider.send("eth_getTransactionReceipt", [deployHash]);
      
      if (deployReceipt && deployReceipt.contractAddress) {
        const auctionAddress = deployReceipt.contractAddress;
        console.log(`Test auction deployed to: ${auctionAddress}`);
        
        // Test bidding with correct function call
        console.log("\nTesting bidding...");
        const bidTx = {
          from: accounts[1],
          to: auctionAddress,
          value: "0xde0b6b3a7640000", // 1 ETH in wei
          data: "0x454a2ab3", // bid() function selector
          gas: "0x186a0"
        };
        
        const bidHash = await connection.provider.send("eth_sendTransaction", [bidTx]);
        const bidReceipt = await connection.provider.send("eth_getTransactionReceipt", [bidHash]);
        console.log(`Bid successful: ${bidHash}`);
        
        // Test another bid
        const bid2Tx = {
          from: accounts[2],
          to: auctionAddress,
          value: "0x1bc16d674ec80000", // 2 ETH in wei
          data: "0x454a2ab3", // bid() function selector
          gas: "0x186a0"
        };
        
        const bid2Hash = await connection.provider.send("eth_sendTransaction", [bid2Tx]);
        const bid2Receipt = await connection.provider.send("eth_getTransactionReceipt", [bid2Hash]);
        console.log(`Second bid successful: ${bid2Hash}`);
        
        console.log("\nAuction test completed successfully!");
        console.log(`Total bids: 3 ETH (1 + 2)`);
        
      } else {
        console.log("Failed to deploy test auction");
      }
      
    } catch (error) {
      console.log("Test failed:", error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 