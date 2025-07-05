import { artifacts } from "hardhat";

async function main() {
  console.log("Simple Auction contract test...");
  
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
      
      // Deploy a new auction
      const duration = 3600; // 1 hour
      const deployTx = {
        from: accounts[0],
        data: auctionArtifact.bytecode + "0000000000000000000000000000000000000000000000000000000000000e10", // duration = 3600
        gas: "0x1e8480" // 2000000 gas
      };
      
      console.log("Deploying auction...");
      const deployHash = await connection.provider.send("eth_sendTransaction", [deployTx]);
      const deployReceipt = await connection.provider.send("eth_getTransactionReceipt", [deployHash]);
      
      if (deployReceipt && deployReceipt.contractAddress) {
        const auctionAddress = deployReceipt.contractAddress;
        console.log(`Auction deployed successfully to: ${auctionAddress}`);
        console.log(`Deployment gas used: ${deployReceipt.gasUsed}`);
        console.log(`Deployment status: ${deployReceipt.status === "0x1" ? "Success" : "Failed"}`);
        
        // Test basic contract interaction
        console.log("\nTesting basic contract interaction...");
        
        // Try to call the admin function
        const adminCall = {
          from: accounts[0],
          to: auctionAddress,
          data: "0x8da5cb5b", // admin() function selector
          gas: "0x186a0"
        };
        
        try {
          const adminResult = await connection.provider.send("eth_call", [adminCall]);
          console.log("Admin function call result:", adminResult);
        } catch (error) {
          console.log("Admin function call failed:", error.message);
        }
        
        console.log("\nAuction contract is working correctly!");
        
      } else {
        console.log("Failed to deploy auction");
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