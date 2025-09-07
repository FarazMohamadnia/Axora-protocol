import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
import * as dotenv from "dotenv";
dotenv.config();

export default buildModule("deployICO", (m) => {
  // For testing, we'll use a mock price feed address
  // In production, you would use a real Chainlink price feed address
  const mockPriceFeed = "0x0000000000000000000000000000000000000000"; // Mock address for testing

  const ico = m.contract("ICO", [
    process.env.TOKEN_ADDRESS || "", // Token address
    process.env.USDT_ADDRESS || "", // USDT address
    mockPriceFeed, // Price feed address (mock for testing)
    1000000, // Token price in USDT (1 USDT = 1 token, with 6 decimals)
  ]);

  return {
    ico,
  };
});
