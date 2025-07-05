import { artifacts, network } from "hardhat";

async function main() {
  const contractAddress = "0x9a676e781a523b5d0c0e43731313a708cb607508";
  const auctionArtifact = await artifacts.readArtifact("Auction");
  const { Interface } = await import("ethers");
  const iface = new Interface(auctionArtifact.abi);

  const connection = await network.connect();
  if (!connection.provider) throw new Error("No provider");

  // Use the first account as caller
  const accounts = await connection.provider.send("eth_accounts", []);
  const caller = accounts[0];

  // Get art pieces count (correct function name)
  const getCountData = iface.encodeFunctionData("getArtPieceCount", []);
  const countResult = await connection.provider.send("eth_call", [{
    from: caller,
    to: contractAddress,
    data: getCountData
  }]);
  const artPiecesCount = Number(BigInt(countResult));
  console.log("Art pieces count:", artPiecesCount);

  // For each art piece, get details
  for (let i = 0; i < artPiecesCount; i++) {
    const getArtData = iface.encodeFunctionData("artPieces", [i]);
    const artResult = await connection.provider.send("eth_call", [{
      from: caller,
      to: contractAddress,
      data: getArtData
    }]);
    const decoded = iface.decodeFunctionResult("artPieces", artResult);
    const [name, creator, isActive, highestBid, highestBidder, endTime, isFinalized] = decoded;
    console.log(`Art piece ${i}:`, {
      name,
      creator,
      isActive,
      highestBid: highestBid.toString(),
      highestBidder,
      endTime: new Date(Number(endTime) * 1000).toLocaleString(),
      isFinalized
    });
  }

  // Get active auctions
  const getActiveData = iface.encodeFunctionData("getActiveAuctions", []);
  const activeResult = await connection.provider.send("eth_call", [{
    from: caller,
    to: contractAddress,
    data: getActiveData
  }]);
  const activeAuctions = iface.decodeFunctionResult("getActiveAuctions", activeResult);
  console.log("Active auctions:", activeAuctions);
}

main().catch(console.error); 