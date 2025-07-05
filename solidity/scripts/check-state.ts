import { ethers } from "hardhat";

async function main() {
  const contractAddress = "0x9a676e781a523b5d0c0e43731313a708cb607508";
  const contract = await ethers.getContractAt("ArtAuction", contractAddress);
  
  console.log("Checking contract state...");
  
  try {
    const admin = await contract.admin();
    console.log("Admin:", admin);
    
    const activeAuctions = await contract.getActiveAuctions();
    console.log("Active auctions:", activeAuctions);
    
    const auctionCount = await contract.auctionCount();
    console.log("Auction count:", auctionCount.toString());
    
    if (auctionCount > 0) {
      for (let i = 1; i <= auctionCount; i++) {
        try {
          const auction = await contract.auctions(i);
          console.log(`Auction ${i}:`, {
            artPieceName: auction.artPieceName,
            totalBid: ethers.formatEther(auction.totalBid),
            isActive: auction.isActive,
            isFinalized: auction.isFinalized,
            bidders: auction.bidders
          });
        } catch (error) {
          console.log(`Error reading auction ${i}:`, error);
        }
      }
    }
  } catch (error) {
    console.error("Error:", error);
  }
}

main().catch(console.error); 