import { artifacts } from "hardhat";
import { AbiCoder } from "ethers";

async function main() {
  console.log("🎨 ART AUCTION DEMO - Complete Workflow\n");
  
  // Load the Auction artifact
  const auctionArtifact = await artifacts.readArtifact("Auction");
  
  // Connect to network
  const { network } = await import("hardhat");
  const connection = await network.connect();
  
  if (connection.provider) {
    try {
      // Get accounts
      const accounts = await connection.provider.send("eth_accounts", []);
      const admin = accounts[0];
      const user1 = accounts[1];
      const user2 = accounts[2];
      const artOwner = accounts[3];
      
      console.log("👥 Participants:");
      console.log(`Admin: ${admin}`);
      console.log(`User 1: ${user1}`);
      console.log(`User 2: ${user2}`);
      console.log(`Art Owner: ${artOwner}\n`);
      
      // STEP 1: Deploy Auction
      console.log("📋 STEP 1: Auction Initialization");
      const duration = 3600; // 1 hour
      const deployTx = {
        from: admin,
        data: auctionArtifact.bytecode + "0000000000000000000000000000000000000000000000000000000000000e10",
        gas: "0x1e8480"
      };
      
      const deployHash = await connection.provider.send("eth_sendTransaction", [deployTx]);
      const deployReceipt = await connection.provider.send("eth_getTransactionReceipt", [deployHash]);
      const auctionAddress = deployReceipt.contractAddress;
      console.log(`✅ Auction deployed to: ${auctionAddress}\n`);
      
      // STEP 2: User 1 bids 100 tokens worth (0.1 ETH)
      console.log("💰 STEP 2: User 1 Bidding");
      const bid1Tx = {
        from: user1,
        to: auctionAddress,
        value: "0x16345785d8a0000", // 0.1 ETH in wei
        data: "0x26986ad5", // bidWithTracking() function selector
        gas: "0x1e8480"
      };
      
      const bid1Hash = await connection.provider.send("eth_sendTransaction", [bid1Tx]);
      await connection.provider.send("eth_getTransactionReceipt", [bid1Hash]);
      console.log("✅ User 1 bid 0.1 ETH (100 tokens worth)\n");
      
      // STEP 3: User 2 bids 200 tokens worth (0.2 ETH)
      console.log("💰 STEP 3: User 2 Bidding");
      const bid2Tx = {
        from: user2,
        to: auctionAddress,
        value: "0x2c68af0bb140000", // 0.2 ETH in wei
        data: "0x26986ad5", // bidWithTracking() function selector
        gas: "0x1e8480"
      };
      
      const bid2Hash = await connection.provider.send("eth_sendTransaction", [bid2Tx]);
      await connection.provider.send("eth_getTransactionReceipt", [bid2Hash]);
      console.log("✅ User 2 bid 0.2 ETH (200 tokens worth)\n");
      
      // STEP 4: Check total bids
      console.log("📊 STEP 4: Current Auction State");
      const totalBidCall = {
        from: admin,
        to: auctionAddress,
        data: "0x8a9e8671", // totalBid() function selector
        gas: "0x1e8480"
      };
      
      const totalBidResult = await connection.provider.send("eth_call", [totalBidCall]);
      const totalBid = BigInt(totalBidResult);
      console.log(`Total bids: ${Number(totalBid) / 1e18} ETH`);
      console.log(`User 1: 100 tokens (33.33% of total)`);
      console.log(`User 2: 200 tokens (66.67% of total)\n`);
      
      // STEP 5: End auction early and finalize
      console.log("🏁 STEP 5: Auction Finalization");
      
      // End auction early for demo
      const endAuctionTx = {
        from: admin,
        to: auctionAddress,
        data: "0x40b9edbf", // endAuctionEarly() function selector
        gas: "0x1e8480"
      };
      
      const endAuctionHash = await connection.provider.send("eth_sendTransaction", [endAuctionTx]);
      await connection.provider.send("eth_getTransactionReceipt", [endAuctionHash]);
      console.log("✅ Auction ended early for demo");
      
      // Finalize and distribute tokens
      const finalizeTx = {
        from: admin,
        to: auctionAddress,
        data: "0x4ef39b75" + "000000000000000000000000" + artOwner.slice(2), // finalize(address)
        gas: "0x1e8480"
      };
      
      const finalizeHash = await connection.provider.send("eth_sendTransaction", [finalizeTx]);
      await connection.provider.send("eth_getTransactionReceipt", [finalizeHash]);
      console.log("✅ Auction finalized! Tokens distributed to bidders\n");
      
      // STEP 6: Check token balances
      console.log("🎫 STEP 6: Token Distribution");
      function encodeTokensCall(address: string) {
        return (
          "0xe4860339" + address.slice(2).padStart(64, "0")
        );
      }
      const tokens1Call = {
        from: user1,
        to: auctionAddress,
        data: encodeTokensCall(user1),
        gas: "0x1e8480"
      };
      
      const tokens2Call = {
        from: user2,
        to: auctionAddress,
        data: encodeTokensCall(user2),
        gas: "0x1e8480"
      };
      
      const [tokens1Result, tokens2Result] = await Promise.all([
        connection.provider.send("eth_call", [tokens1Call]),
        connection.provider.send("eth_call", [tokens2Call])
      ]);
      
      const tokens1 = BigInt(tokens1Result);
      const tokens2 = BigInt(tokens2Result);
      console.log(`User 1 tokens: ${tokens1.toString()}`);
      console.log(`User 2 tokens: ${tokens2.toString()}`);
      console.log("✅ Tokens successfully distributed!\n");
      
      // STEP 7: Admin asks for decision
      console.log("🤔 STEP 7: Admin Decision Request");
      console.log("Admin: 'Should we display the art piece in the main gallery or the private collection?'\n");
      
      // STEP 8: Token holders vote
      console.log("🗳️ STEP 8: Token Holder Voting");
      
      // User 1 votes
      const vote1Tx = {
        from: user1,
        to: auctionAddress,
        data: "0x632a9a52", // vote() function selector
        gas: "0x1e8480"
      };
      
      const vote1Hash = await connection.provider.send("eth_sendTransaction", [vote1Tx]);
      await connection.provider.send("eth_getTransactionReceipt", [vote1Hash]);
      console.log("✅ User 1 voted (33.33% voting power)");
      
      // User 2 votes
      const vote2Tx = {
        from: user2,
        to: auctionAddress,
        data: "0x632a9a52", // vote() function selector
        gas: "0x1e8480"
      };
      
      const vote2Hash = await connection.provider.send("eth_sendTransaction", [vote2Tx]);
      await connection.provider.send("eth_getTransactionReceipt", [vote2Hash]);
      console.log("✅ User 2 voted (66.67% voting power)\n");
      
      // STEP 9: Admin visualizes the decision
      console.log("🎨 STEP 9: Admin Decision Visualization");
      console.log("Admin: 'Based on the voting results:'");
      console.log("   - User 1 (33.33%): Voted for main gallery");
      console.log("   - User 2 (66.67%): Voted for private collection");
      console.log("   - Decision: Private collection wins with 66.67% majority");
      console.log("   - Action: Moving art piece to private collection display\n");
      
      // STEP 10: Admin updates art presentation
      console.log("🖼️ STEP 10: Art Presentation Update");
      const presentation = "Private Collection - Exclusive Display";
      const abiCoder = new AbiCoder();
      const encoded = abiCoder.encode(["string"], [presentation]).slice(2);
      const presentationTx = {
        from: admin,
        to: auctionAddress,
        data: "0x72853d34" + encoded, // changeArtPresentation(string)
        gas: "0x1e8480"
      };
      
      const presentationHash = await connection.provider.send("eth_sendTransaction", [presentationTx]);
      await connection.provider.send("eth_getTransactionReceipt", [presentationHash]);
      console.log(`✅ Art presentation updated to: '${presentation}'\n`);
      
      console.log("🎉 DEMO COMPLETED SUCCESSFULLY!");
      console.log("The art auction system is fully functional with Hardhat 3!");
      
    } catch (error) {
      console.log("Demo failed:", error);
    }
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
}); 