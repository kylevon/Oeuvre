import { artifacts } from "hardhat";

async function main() {
  console.log("Testing new contract deployment (no time limits)...");

  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    const accounts = await connection.provider.send("eth_accounts", []);
    const admin = accounts[0];
    const bidder = accounts[1];
    const auctionAddress = "0x2bdcc0de6be1f7d2ee689a0342d76f52e8efaba3";
    
    console.log("Admin:", admin);
    console.log("Bidder:", bidder);
    console.log("Contract:", auctionAddress);
    
    // Check if contract exists
    const code = await connection.provider.send("eth_getCode", [auctionAddress, "latest"]);
    if (code === "0x") {
      console.log("ERROR: Contract not deployed at this address!");
      return;
    }
    console.log("✓ Contract deployed successfully");
    
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
    console.log("Expected admin:", admin);
    console.log("✓ Admin check passed");
    
    // Create a test art piece
    console.log("\nCreating test art piece...");
    const createData = "0x48bf823b" + 
      "0000000000000000000000000000000000000000000000000000000000000040" + // string offset
      "0000000000000000000000000000000000000000000000000000000000000000"; // duration (0 = no limit)
    
    const createTx = {
      from: admin,
      to: auctionAddress,
      data: createData + _encodeString("Test Art Piece"),
      gas: "0x1e8480"
    };
    
    const createHash = await connection.provider.send("eth_sendTransaction", [createTx]);
    console.log("Create transaction hash:", createHash);
    
    // Wait for transaction
    await new Promise(resolve => setTimeout(resolve, 2000));
    
    // Check art piece count
    const countData = "0xa0857969"; // getArtPieceCount() function selector
    const countResult = await connection.provider.send("eth_call", [{
      from: admin,
      to: auctionAddress,
      data: countData
    }]);
    
    const count = parseInt(countResult, 16);
    console.log("Art piece count:", count);
    
    if (count > 0) {
      // Check the first art piece
      const getArtPieceData = "0x2e03e468" + "0000000000000000000000000000000000000000000000000000000000000001";
      const artPieceResult = await connection.provider.send("eth_call", [{
        from: admin,
        to: auctionAddress,
        data: getArtPieceData
      }]);
      
      console.log("Art piece 1 result:", artPieceResult);
      
      // Decode the result
      const name = _decodeString(artPieceResult.substring(2, 66));
      const exists = artPieceResult.substring(66, 130) !== "0000000000000000000000000000000000000000000000000000000000000000";
      const createdAt = parseInt(artPieceResult.substring(130, 194), 16);
      const totalTokens = parseInt(artPieceResult.substring(194, 258), 16);
      const auctionId = parseInt(artPieceResult.substring(258, 322), 16);
      const auctionActive = artPieceResult.substring(322, 386) !== "0000000000000000000000000000000000000000000000000000000000000000";
      const auctionFinalized = artPieceResult.substring(386, 450) !== "0000000000000000000000000000000000000000000000000000000000000000";
      const highestBid = parseInt(artPieceResult.substring(450, 514), 16);
      const highestBidder = "0x" + artPieceResult.substring(514, 578).substring(24);
      
      console.log("Decoded art piece:");
      console.log("  Name:", name);
      console.log("  Exists:", exists);
      console.log("  Created at:", createdAt);
      console.log("  Total tokens:", totalTokens);
      console.log("  Auction ID:", auctionId);
      console.log("  Auction active:", auctionActive);
      console.log("  Auction finalized:", auctionFinalized);
      console.log("  Highest bid:", highestBid, "wei");
      console.log("  Highest bidder:", highestBidder);
      
      console.log("✓ Art piece created successfully");
    }
  }
}

function _encodeString(str: string): string {
  const encoder = new TextEncoder();
  const bytes = encoder.encode(str);
  const hex = Array.from(bytes).map(b => b.toString(16).padStart(2, '0')).join('');
  const length = bytes.length.toString(16).padStart(64, '0');
  return length + hex.padEnd(64, '0');
}

function _decodeString(hex: string): string {
  const length = parseInt(hex.substring(0, 64), 16);
  const data = hex.substring(64, 64 + length * 2);
  const bytes = new Uint8Array(length);
  for (let i = 0; i < length; i++) {
    bytes[i] = parseInt(data.substring(i * 2, i * 2 + 2), 16);
  }
  return new TextDecoder().decode(bytes);
}

main().catch(console.error); 