import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("deployUSDT", (m) => {
  const usdt = m.contract("Token", [
    1000000, // _totalSupply (1M USDT)
    "Tether USD", // _name
    "USDT", // _symbol
    6, // _decimals (USDT has 6 decimals)
  ]);

  return {
    usdt,
  };
});
