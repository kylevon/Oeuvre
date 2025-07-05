import hre from "hardhat";

async function main() {
  console.log("Deploying updated Auction contract...");

  const Auction = await hre.ethers.getContractFactory("Auction");
  const auction = await Auction.deploy(3600); // 1 hour duration

  await auction.waitForDeployment();
  const address = await auction.getAddress();

  console.log("Updated Auction deployed to:", address);
  console.log("Contract address for Flutter app:", address);

  // Create a test art piece
  console.log("\nCreating test art piece 'Mona Lisa'...");
  const createTx = await auction.createArtPiece("Mona Lisa", "Leonardo da Vinci's masterpiece", 3600);
  await createTx.wait();
  console.log("Test art piece created successfully!");

  console.log("\nDeployment complete!");
  console.log("Contract address:", address);
  console.log("Admin address:", await auction.admin());
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  }); 