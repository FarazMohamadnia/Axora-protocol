import { network } from "hardhat";
import * as dotenv from "dotenv";
import * as fs from "fs";
import { address, transactionLog } from "./log.js";

// Load environment variables from .env file
dotenv.config();

/**
 * @dev User interface for airdrop participants
 * @param address The user's Ethereum address
 * @param privateKey The user's private key for signing transactions
 */
interface User {
  address: string;
  privateKey: string;
}

// Flag to control which test to run
const handleTest = false;

// Connect to local Hardhat network for testing
const { ethers } = await network.connect({
  network: "localhost",
});

// Load user accounts from JSON file
const usersData = JSON.parse(fs.readFileSync("accounts/users.json", "utf8"));

// Array to store user objects for airdrop testing
const usersList: User[] = [];

// Generate usersList dynamically from JSON data
for (const key in usersData) {
  if (usersData.hasOwnProperty(key)) {
    usersList.push({
      address: usersData[key].address,
      privateKey: usersData[key].privateKey,
    });
  }
}

// Get the default signer (deployer account)
const [sender] = await ethers.getSigners();

// Initialize contract instances
const airdrop = await ethers.getContractAt(
  "Airdrop",
  process.env.AIRDROP_ADDRESS || ""
);
const token = await ethers.getContractAt(
  "Token",
  process.env.TOKEN_ADDRESS || ""
);

// Display initial airdrop contract status
console.log(
  "➡️  Check : Airdrop Time Data: ",
  await airdrop.getAirdropStatus()
);
console.log("➡️  Owner Address : ", await airdrop.owner());
console.log("➡️  Token Address : ", await airdrop.tokenAddress());
console.log("➡️  Total Airdrop : ", await airdrop.totalAmount());
console.log(
  "➡️Contract Balance (Token) : ",
  await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
);
/**
 * @dev Sends tokens from deployer to airdrop contract
 * @notice Transfers the total airdrop amount to the contract
 * @notice Logs transaction details and updates address balances
 */
const sendToken = async () => {
  try {
    // Transfer tokens to airdrop contract
    const tx = await token.transfer(
      process.env.AIRDROP_ADDRESS || "",
      await airdrop.totalAmount()
    );

    // Wait for transaction confirmation
    const receipt = await tx.wait();

    // Prepare transaction data for logging
    const dataStructure = {
      hash: tx.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed?.toString() || "0",
      status: receipt?.status,
      from: receipt?.from,
      to: receipt?.to,
      tokenAmount: (await airdrop.totalAmount()).toString(),
    };

    // Log transaction and update address balances
    transactionLog(dataStructure);
    address();
  } catch (err) {
    console.log("➡️  sendToken Function Error : ", err);
  }
};

/**
 * @dev Adds a user to the airdrop list
 * @param userAddress The Ethereum address of the user to add
 * @notice Only the airdrop owner can call this function
 */
const addUser = async (userAddress: string) => {
  try {
    console.log(`➡️  Adding user: ${userAddress}`);

    // Call airdrop contract to add user
    const tx = await airdrop.addUser(userAddress);
    await tx.wait();

    console.log(`✅  User ${userAddress} added successfully!`);

    // Display updated airdrop status
    console.log("➡️  Updated Total Airdrop: ", await airdrop.totalAmount());
  } catch (err) {
    console.log("➡️  addUser Function Error : ", err);
  }
};

/**
 * @dev Allows a user to withdraw their airdrop tokens
 * @param userAddress The Ethereum address of the user withdrawing
 * @notice User must be registered in the airdrop and not have claimed yet
 * @notice Creates a new signer for the user and logs the transaction
 */
const withdrawUser = async (userAddress: string) => {
  try {
    // Find the user in the usersList
    const user = usersList.find((u) => u.address === userAddress);
    if (!user) {
      throw new Error(`User ${userAddress} not found`);
    }

    // Create a signer for the specific user
    const userSigner = new ethers.Wallet(user.privateKey, ethers.provider);
    const airdropWithUserSigner = airdrop.connect(userSigner);

    console.log(`➡️  Withdrawing for user: ${userAddress}`);

    // Call airdrop function as the user
    const tx = await airdropWithUserSigner.airdrop();
    const receipt = await tx.wait();

    // Prepare transaction data for logging
    const dataStructure = {
      hash: tx.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed?.toString() || "0",
      status: receipt?.status,
      from: receipt?.from,
      to: receipt?.to,
      tokenAmount: (await airdrop.airdropAmount()).toString(),
    };

    // Log transaction and update address balances
    transactionLog(dataStructure);
    address();

    console.log(`✅  User ${userAddress} withdrawn successfully!`);
  } catch (err) {
    console.log("➡️  withdrawUser Function Error : ", err);
  }
};

// ============ TEST EXECUTION CONTROL ============
/**
 * @dev Simple test execution for basic airdrop functionality
 * @notice When handleTest is true, runs a basic workflow:
 * 1. Send tokens to airdrop contract
 * 2. Add one user (index 3) to airdrop
 * 3. Allow that user to withdraw their tokens
 */
if (handleTest) {
  sendToken().then(() => {
    addUser(usersList[3].address).then(() => {
      withdrawUser(usersList[3].address);
    });
  });
}

// ============ MAIN TEST FUNCTION ============
/**
 * @dev Comprehensive airdrop testing function
 * @notice Tests the complete airdrop workflow:
 * 1. Send tokens to airdrop contract
 * 2. Add multiple users to airdrop
 * 3. Delete some users
 * 4. Allow remaining users to withdraw
 * 5. Display final balances
 */
async function test2() {
  console.log("➡️  Test 2 ================================= ");

  // Select first 7 users for testing
  const AirdropUserList = usersList.slice(0, 7);
  console.log("➡️  AirdropUserList : ", AirdropUserList);

  try {
    // Step 1: Send tokens to airdrop contract
    const tx = await token.transfer(
      process.env.AIRDROP_ADDRESS || "",
      await airdrop.totalAmount()
    );

    // Wait for transaction confirmation
    const receipt = await tx.wait();
    console.log("====================mohemmmmm==============", receipt);

    // Log transaction details
    const dataStructure = {
      hash: tx.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed?.toString() || "0",
      status: receipt?.status,
      from: receipt?.from,
      to: receipt?.to,
      tokenAmount: (await airdrop.totalAmount()).toString(),
    };

    // Log transaction and update balances
    transactionLog(dataStructure);
    address();

    // Display contract balance after transfer
    console.log(
      "✅  Send Token to Airdrop Contract : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );

    // Step 2: Add all users to the airdrop
    for (const user of AirdropUserList) {
      await addUser(user.address);
    }

    // Display all registered users
    console.log(
      "✅  All users added successfully!",
      await airdrop.getUserList()
    );

    // Show updated contract balance
    console.log(
      "➡️  Total Airdrop : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );

    // Step 3: Delete some users (users at index 2, 3, 4, 5)
    const deleteUserList = AirdropUserList.slice(2, 6);
    for (const user of deleteUserList) {
      await airdrop.deleteUser(user.address);
      console.log("✅  User ", user.address, " deleted successfully!");
    }

    // Step 4: Filter out deleted users to get current airdrop participants
    const currentAirdropUsers = [];
    for (const user of AirdropUserList) {
      if (deleteUserList.find((u: any) => u.user != user.address)) {
        currentAirdropUsers.push(user);
      }
    }
    console.log("➡️  Current Airdrop Users : ", currentAirdropUsers);

    // Step 5: Allow remaining users to withdraw their airdrop tokens
    // Use Promise.all to handle all airdrop operations concurrently for efficiency
    const airdropPromises = currentAirdropUsers.map(async (user) => {
      // Create signer for each user
      const userSigner = new ethers.Wallet(user.privateKey, ethers.provider);
      const airdropWithUserSigner = airdrop.connect(userSigner);

      // Call airdrop function
      const tx = await airdropWithUserSigner.airdrop();
      const receipt = await tx.wait();

      // Log transaction details
      const dataStructure = {
        hash: tx.hash,
        blockNumber: receipt?.blockNumber,
        gasUsed: receipt?.gasUsed?.toString() || "0",
        status: receipt?.status,
        from: receipt?.from,
        to: receipt?.to,
        tokenAmount: (await airdrop.airdropAmount()).toString(),
      };

      // Log transaction and update balances
      transactionLog(dataStructure);
      address();

      console.log("✅  User ", user.address, " withdrawn successfully!");
    });
    // Execute all airdrop withdrawals concurrently
    try {
      await Promise.all(airdropPromises);
    } catch (error) {
      console.log("You are not a user of the airdrop");
    }

    // Display final airdrop status
    console.log(
      "✅  All users withdrawn successfully!",
      await airdrop.getUserList()
    );

    // Show final contract balance
    console.log(
      "➡️  Total Airdrop : ",
      await token.balanceOf(process.env.AIRDROP_ADDRESS || "")
    );

    // Step 6: Display final token balances for all users
    for (const user of AirdropUserList) {
      const balance = await token.balanceOf(user.address);
      console.log("➡️  User ", user.address, " balance : ", balance);
    }
  } catch (err) {
    console.log("➡️  ERROR  === TEST 2 : ", err);
  }
}

// ============ SCRIPT EXECUTION ============
// Run the main test if handleTest is false
if (!handleTest) {
  test2();
}
