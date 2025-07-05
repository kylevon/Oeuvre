import { artifacts } from "hardhat";

async function main() {
  const contractAddress = "0x5fbdb2315678afecb367f032d93f642f64180aa3"; // Deployed auction address
  
  console.log(`Checking status of auction ${contractAddress}...`);
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    try {
      // Get accounts
      const accounts = await connection.provider.send("eth_accounts", []);
      const caller = accounts[0];
      
      // Call contract functions to get status
      const adminCall = {
        from: caller,
        to: contractAddress,
        data: "0x8da5cb5b", // admin() function selector
        gas: "0x186a0"
      };
      
      const auctionEndCall = {
        from: caller,
        to: contractAddress,
        data: "0x1f2a2005", // auctionEnd() function selector
        gas: "0x186a0"
      };
      
      const finalizedCall = {
        from: caller,
        to: contractAddress,
        data: "0x7d9f6db6", // finalized() function selector
        gas: "0x186a0"
      };
      
      const totalBidCall = {
        from: caller,
        to: contractAddress,
        data: "0x18160ddd", // totalBid() function selector
        gas: "0x186a0"
      };
      
      // Make the calls
      const [admin, auctionEnd, finalized, totalBid] = await Promise.all([
        connection.provider.send("eth_call", [adminCall]),
        connection.provider.send("eth_call", [auctionEndCall]),
        connection.provider.send("eth_call", [finalizedCall]),
        connection.provider.send("eth_call", [totalBidCall])
      ]);
      
      console.log("Auction Status:");
      console.log(`Admin: ${admin}`);
      
      if (auctionEnd && auctionEnd !== "0x") {
        console.log(`Auction End: ${BigInt(auctionEnd).toString()}`);
      } else {
        console.log("Auction End: Not available");
      }
      
      console.log(`Finalized: ${finalized === "0x0000000000000000000000000000000000000000000000000000000000000001"}`);
      
      if (totalBid && totalBid !== "0x") {
        const totalBidWei = BigInt(totalBid);
        console.log(`Total Bid: ${totalBidWei.toString()} wei (${Number(totalBidWei) / 1e18} ETH)`);
      } else {
        console.log("Total Bid: 0 ETH");
      }
      
    } catch (error) {
      console.log("Status check failed:", error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 