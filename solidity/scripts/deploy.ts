import { artifacts } from "hardhat";

async function main() {
  console.log("Deploying Auction contract...");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  console.log("Auction artifact loaded:", auctionArtifact.contractName);
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  // Try to deploy using the provider
  if (connection.provider) {
    console.log("Provider available, attempting deployment...");
    
    try {
      // Get accounts
      const accounts = await connection.provider.send("eth_accounts", []);
      console.log("Accounts:", accounts);
      
      if (accounts.length > 0) {
        const deployer = accounts[0];
        const duration = 3600; // 1 hour auction
        
        // Deploy contract with more gas
        const deployTx = {
          from: deployer,
          data: auctionArtifact.bytecode + "0000000000000000000000000000000000000000000000000000000000000e10", // duration = 3600
          gas: "0x1e8480" // 2000000 gas
        };
        
        const txHash = await connection.provider.send("eth_sendTransaction", [deployTx]);
        console.log("Deployment transaction hash:", txHash);
        
        // Wait for transaction receipt
        const receipt = await connection.provider.send("eth_getTransactionReceipt", [txHash]);
        console.log("Deployment receipt:", receipt);
        
        if (receipt && receipt.contractAddress) {
          console.log(`Auction deployed to: ${receipt.contractAddress}`);
          return receipt.contractAddress;
        }
      }
    } catch (error) {
      console.log("Deployment failed:", error);
    }
  }
  
  console.log("No deployment method available");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 
