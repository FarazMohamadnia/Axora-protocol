import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("deploy", (m) => {
  const token = m.contract("Token", [100000]);

  // Example: m.call(token, "mint", [m.getAccount(0), 1000]);

  return {
    token,
  };
});
