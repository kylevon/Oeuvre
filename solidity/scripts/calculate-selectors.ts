import { ethers } from "ethers";

async function main() {
  console.log("Calculating function selectors for current contract...\n");
  
  // Function signatures from the current contract
  const functions = [
    "createArtPiece(string,uint256)",
    "bid(uint256)",
    "withdraw(uint256)",
    "confirmAuction(uint256)",
    "cancelAuction(uint256)",
    "getArtPiece(uint256)",
    "getArtPieceCount()",
    "getOwnership(uint256,address)",
    "getUserArtPieces(address)",
    "getActiveAuctions()",
    "getAcquiredArtPieces()",
    "getAuctionBidders(uint256)",
    "endAuctionEarly(uint256)"
  ];
  
  console.log("Function Selectors:");
  console.log("===================");
  
  for (const func of functions) {
    const selector = ethers.id(func).slice(0, 10);
    console.log(`${func}: ${selector}`);
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 