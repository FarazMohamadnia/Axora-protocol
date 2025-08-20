import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("deployToken", (m) => {
  const token = m.contract("Token", [
    100000, // _totalSupply
    "SuperToken", // _name
    "SUPER", // _symbol
    18, // _decimals
  ]);

  return {
    token,
  };
});
