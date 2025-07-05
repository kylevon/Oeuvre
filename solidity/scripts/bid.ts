import { artifacts } from "hardhat";

async function main() {
  const contractAddress = "0x5fbdb2315678afecb367f032d93f642f64180aa3"; // Deployed auction address
  const amount = 1; // 1 ETH bid
  
  console.log(`Placing bid of ${amount} ETH on auction ${contractAddress}...`);
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    try {
      // Get accounts
      const accounts = await connection.provider.send("eth_accounts", []);
      const bidder = accounts[1]; // Use second account for bidding
      
      // Create bid transaction
      const bidTx = {
        from: bidder,
        to: contractAddress,
        value: `0x${BigInt(Number(amount) * 1e18).toString(16)}`, // Convert ETH to wei
        gas: "0x186a0" // 100000 gas
      };
      
      const txHash = await connection.provider.send("eth_sendTransaction", [bidTx]);
      console.log(`Bid placed successfully: ${txHash}`);
      
      // Wait for transaction receipt
      const receipt = await connection.provider.send("eth_getTransactionReceipt", [txHash]);
      console.log("Bid receipt:", receipt);
      
    } catch (error) {
      console.log("Bid failed:", error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 