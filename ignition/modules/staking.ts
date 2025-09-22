import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";
 
const StakingModule = buildModule("StakingModule", (m) => {
  // Get the deployed token addresses from previous deployments
  // You'll need to update these addresses based on your actual token deployments
  const stakingTokenAddress = m.getParameter(
    "stakingTokenAddress",
    process.env.TOKEN_ADDRESS
  );
  const rewardTokenAddress = m.getParameter(
    "rewardTokenAddress",
    process.env.TOKEN_ADDRESS
  );

  // Deploy the staking contract
  const stakingContract = m.contract("StakingContract", [
    stakingTokenAddress,
    rewardTokenAddress,
  ]);

  return { stakingContract };
});

export default StakingModule;
