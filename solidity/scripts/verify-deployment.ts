import { artifacts } from "hardhat";

async function main() {
  console.log("Verifying deployment...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const auctionAddress = "0x9d4454b023096f34b160d6b654540c56a1f81688";
    
    // Check admin
    const adminData = "0x8da5cb5b"; // admin() function selector
    const adminResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: adminData
    }]);
    
    console.log("Admin result:", adminResult);
    const adminAddress = "0x" + adminResult.substring(26);
    console.log("Admin address:", adminAddress);
    
    // Check auctionEnd (constructor parameter)
    const auctionEndData = "0x1a695230"; // auctionEnd() function selector
    const auctionEndResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: auctionEndData
    }]);
    
    console.log("Auction end result:", auctionEndResult);
    const auctionEnd = parseInt(auctionEndResult, 16);
    console.log("Auction end time:", auctionEnd);
    
    // Check nextArtPieceId
    const nextArtPieceIdData = "0x7d882d0c"; // nextArtPieceId() function selector
    const nextArtPieceIdResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: nextArtPieceIdData
    }]);
    
    console.log("Next art piece ID result:", nextArtPieceIdResult);
    const nextArtPieceId = parseInt(nextArtPieceIdResult, 16);
    console.log("Next art piece ID:", nextArtPieceId);
    
    // Check if art piece 1 exists
    if (nextArtPieceId > 1) {
      const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000001";
      const artPieceResult = await connection.provider.send("eth_call", [{
        from: admin,
        to: auctionAddress,
        data: getArtPieceData
      }]);
      
      console.log("Art piece 1 result:", artPieceResult);
      
      // Decode the name (first part of the result)
      const nameLengthHex = artPieceResult.substring(66, 130);
      const nameLength = parseInt(nameLengthHex, 16);
      console.log("Name length:", nameLength);
      
      // Extract name
      const nameStart = 130 + (nameLength * 2);
      const nameHex = artPieceResult.substring(130, nameStart);
      const name = Buffer.from(nameHex, 'hex').toString().replace(/\0/g, '');
      console.log("Art piece name:", name);
    }
  }
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 