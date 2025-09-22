import { network } from "hardhat";

const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});

async function main() {
  console.log("=== SuperToken Staking Contract Example ===\n");

  // Get the contract factory
  const StakingContract = await ethers.getContractFactory("StakingContract");
  const Token = await ethers.getContractFactory("Token");

  // Deploy tokens (in a real scenario, these would already be deployed)
  console.log("Deploying tokens...");
  const stakingToken = await Token.deploy(
    ethers.parseEther("1000000"), // 1M tokens
    "SuperToken",
    "SUPER",
    18
  );
  await stakingToken.waitForDeployment();

  const rewardToken = await Token.deploy(
    ethers.parseEther("1000000"), // 1M tokens
    "RewardToken",
    "RWD",
    18
  );
  await rewardToken.waitForDeployment();

  console.log("Staking Token deployed to:", await stakingToken.getAddress());
  console.log("Reward Token deployed to:", await rewardToken.getAddress());

  // Deploy staking contract
  console.log("\nDeploying staking contract...");
  const stakingContract = await StakingContract.deploy(
    await stakingToken.getAddress(),
    await rewardToken.getAddress()
  );
  await stakingContract.waitForDeployment();

  console.log(
    "Staking Contract deployed to:",
    await stakingContract.getAddress()
  );

  // Get accounts
  const [owner, user1, user2] = await ethers.getSigners();
  console.log("\nOwner:", owner.address);
  console.log("User1:", user1.address);
  console.log("User2:", user2.address);

  // Transfer tokens to users
  console.log("\nTransferring tokens to users...");
  await stakingToken.transfer(user1.address, ethers.parseEther("10000"));
  await stakingToken.transfer(user2.address, ethers.parseEther("10000"));

  // Transfer reward tokens to staking contract
  await rewardToken.transfer(
    await stakingContract.getAddress(),
    ethers.parseEther("100000")
  );

  // User1 stakes tokens
  console.log("\n=== User1 Staking Process ===");
  const stakeAmount = ethers.parseEther("1000");
  const tier = 0; // 30 days tier

  console.log("User1 approving tokens...");
  await stakingToken
    .connect(user1)
    .approve(await stakingContract.getAddress(), stakeAmount);

  console.log(
    "User1 staking",
    ethers.formatEther(stakeAmount),
    "tokens for tier",
    tier
  );
  await stakingContract.connect(user1).stake(stakeAmount, tier);

  // Check staking info
  const user1StakeCount = await stakingContract.getUserStakeCount(
    user1.address
  );
  const user1TotalStaked = await stakingContract.getUserTotalStaked(
    user1.address
  );
  const totalStaked = await stakingContract.totalStaked();

  console.log("User1 stake count:", user1StakeCount.toString());
  console.log("User1 total staked:", ethers.formatEther(user1TotalStaked));
  console.log("Total staked in contract:", ethers.formatEther(totalStaked));

  // Check available staking tiers
  console.log("\n=== Available Staking Tiers ===");
  const tierCount = await stakingContract.tierCount();
  for (let i = 0; i < Number(tierCount); i++) {
    const tier = await stakingContract.stakingTiers(i);
    console.log(
      `Tier ${i}: ${Number(tier.duration) / 86400} days, ${
        Number(tier.multiplier) / 100
      }x multiplier, Active: ${tier.active}`
    );
  }

  // User2 stakes in different tier
  console.log("\n=== User2 Staking Process ===");
  const stakeAmount2 = ethers.parseEther("2000");
  const tier2 = 1; // 90 days tier

  console.log("User2 approving tokens...");
  await stakingToken
    .connect(user2)
    .approve(await stakingContract.getAddress(), stakeAmount2);

  console.log(
    "User2 staking",
    ethers.formatEther(stakeAmount2),
    "tokens for tier",
    tier2
  );
  await stakingContract.connect(user2).stake(stakeAmount2, tier2);

  // Check rewards after some time
  console.log("\n=== Checking Rewards ===");

  // Fast forward time (in a real scenario, you'd wait)
  console.log("Simulating time passage...");

  // Check earned rewards
  const user1Earned = await stakingContract.earned(user1.address);
  const user2Earned = await stakingContract.earned(user2.address);

  console.log("User1 earned rewards:", ethers.formatEther(user1Earned));
  console.log("User2 earned rewards:", ethers.formatEther(user2Earned));

  // Check if users can unstake
  const user1CanUnstake = await stakingContract.canUnstake(user1.address, 0);
  const user2CanUnstake = await stakingContract.canUnstake(user2.address, 0);

  console.log("User1 can unstake:", user1CanUnstake);
  console.log("User2 can unstake:", user2CanUnstake);

  console.log("\n=== Contract Information ===");
  console.log(
    "Minimum stake amount:",
    ethers.formatEther(await stakingContract.MIN_STAKE_AMOUNT())
  );
  console.log(
    "Maximum stake amount:",
    ethers.formatEther(await stakingContract.MAX_STAKE_AMOUNT())
  );
  console.log(
    "Current reward rate:",
    (await stakingContract.rewardRate()).toString()
  );
  console.log(
    "Total rewards distributed:",
    ethers.formatEther(await stakingContract.totalRewardsDistributed())
  );

  console.log("\n=== Example Complete ===");
  console.log("To interact with the contract:");
  console.log("1. Users can stake tokens using stake(amount, tier)");
  console.log("2. Users can claim rewards using claimRewards()");
  console.log("3. Users can unstake after lock period using unstake(stakeId)");
  console.log("4. Owner can manage tiers and reward rates");
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
