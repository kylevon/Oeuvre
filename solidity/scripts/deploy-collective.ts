import { artifacts } from "hardhat";

async function main() {
  console.log("Deploying updated Auction contract with collective bidding...");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    // Get accounts
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    
    console.log("Deploying with account:", admin);
    
    // Deploy Auction with collective bidding
    const duration = 3600; // 1 hour
    const deployTx = {
      from: admin,
      data: auctionArtifact.bytecode + "0000000000000000000000000000000000000000000000000000000000000e10",
      gas: "0x3d0900" // 4,000,000 gas
    };
    
    const deployHash = await connection.provider.send("eth_sendTransaction", [deployTx]);
    console.log("Deployment transaction hash:", deployHash);
    
    const deployReceipt = await connection.provider.send("eth_getTransactionReceipt", [deployHash]);
    const auctionAddress = deployReceipt.contractAddress;
    
    console.log("Updated Auction deployed to:", auctionAddress);
    console.log("Admin address:", admin);
    console.log("\nKey changes:");
    console.log("- Collective bidding: multiple people can contribute to the same auction");
    console.log("- Total bid amount is the sum of all contributions");
    console.log("- Ownership is distributed proportionally to all contributors");
    console.log("- No more 'highest bidder' concept");
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 