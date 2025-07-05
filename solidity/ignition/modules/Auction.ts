import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("Auction", (m) => {
  const duration = 3600; // 1 hour auction
  const auction = m.contract("Auction", [duration]);
  
  return { auction };
}); 