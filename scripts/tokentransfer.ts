/**
 * tokentransfer.ts - Token Transfer and Bulk Sending Utility
 *
 * This script provides functionality to transfer tokens between users on the blockchain.
 * It supports both individual transfers and bulk sending to multiple users.
 * The script connects to a local Hardhat network and uses the Token contract for transfers.
 */

import { network } from "hardhat";
import * as fs from "fs";
import { transactionLog, blok, address } from "./log.js";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Load user account data from the users.json file
const usersData = JSON.parse(fs.readFileSync("accounts/users.json", "utf8"));

// Get token contract address from environment variable
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "";

/**
 * Interface defining the structure of a user account
 * Contains the wallet address and private key for signing transactions
 */
interface User {
  address: string; // User's wallet address
  privateKey: string; // User's private key for transaction signing
}

// Initialize an array to store user objects for easier iteration
const usersList: User[] = [];

// Generate usersList dynamically by extracting user data from usersData
// This creates a flat array structure for easier bulk operations
for (const key in usersData) {
  if (usersData.hasOwnProperty(key)) {
    usersList.push({
      address: usersData[key].address,
      privateKey: usersData[key].privateKey,
    });
  }
}

// Configuration flag to control bulk sending behavior
// Set to true to send tokens to all users, false for individual transfer
const bulksending = false;

/**
 * Main function that handles token transfers based on the bulksending flag
 * Supports both bulk sending to all users and individual transfers between specific users
 */
async function main() {
  // Connect to the local Hardhat network
  const { ethers } = await network.connect({
    network: "localhost",
    chainType: "l1",
  });

  // Get the default signer (usually the first account with ETH)
  const [sender] = await ethers.getSigners();

  // Get the token contract instance using the contract address
  const token = await ethers.getContractAt("Token", TOKEN_ADDRESS);

  // Display token contract information for verification
  console.log("Token contract name:", await token.name());
  console.log("Token contract symbol:", await token.symbol());
  console.log("Token contract decimals:", await token.decimals());
  console.log("Token contract totalSupply:", await token.totalSupply());

  if (bulksending) {
    // BULK SENDING MODE: Send tokens to all users in the list

    // Display initial balances for all users
    console.log("Initial balances:");
    for (const user of usersList) {
      console.log("User address:", user.address);
      console.log("User balance:", await token.balanceOf(user.address));
      console.log("--------------------------------");
    }

    console.log("--------------------------------");

    // Transfer tokens from sender to each user in the list
    for (const user of usersList) {
      try {
        console.log(`Transferring 100 tokens to ${user.address}...`);
        const amount = 100; // Fixed amount to send to each user

        // Execute the token transfer
        const tx = await token.transfer(user.address, amount);
        const receipt = await tx.wait(); // Wait for transaction confirmation

        // Create data structure for logging the transaction
        const dataStructure = {
          hash: tx.hash, // Transaction hash
          blockNumber: receipt?.blockNumber, // Block number where transaction was included
          gasUsed: receipt?.gasUsed?.toString() || "0", // Gas consumed by the transaction
          status: receipt?.status, // Transaction status (1=success, 0=failed)
          from: receipt?.from, // Sender address
          to: receipt?.to, // Recipient address
          tokenAmount: amount, // Amount of tokens transferred
        };

        // Log the transaction details and update address balances
        transactionLog(dataStructure);
        address();
        console.log(`Transfer successful! Hash: ${tx.hash}`);
      } catch (error) {
        console.error(`Transfer to ${user.address} failed:`, error);
      }
    }

    console.log("--------------------------------");

    // Display final balances for all users after transfers
    console.log("Final balances after transfers:");
    for (const user of usersList) {
      console.log("User address:", user.address);
      console.log("User balance:", await token.balanceOf(user.address));
      console.log("--------------------------------");
    }
  } else {
    // INDIVIDUAL TRANSFER MODE: Send tokens from one specific user to another

    // Create a wallet instance using user1's private key
    // This allows user1 to be the sender instead of the default signer
    const senderWallet = new ethers.Wallet(usersData.user1.privateKey);
    const sender = senderWallet.connect(ethers.provider);

    // Connect the sender wallet to the token contract for signing transactions
    const tokenWithSigner = token.connect(sender);

    const amount = 50; // Amount of tokens to transfer
    const recipient = usersList[5].address; // Recipient address (user6)

    // Execute the token transfer from user1 to user6
    const tx = await tokenWithSigner.transfer(recipient, amount);
    const receipt = await tx.wait(); // Wait for transaction confirmation

    // Create data structure for logging the transaction
    const dataStructure = {
      hash: tx.hash, // Transaction hash
      blockNumber: receipt?.blockNumber, // Block number where transaction was included
      gasUsed: receipt?.gasUsed?.toString() || "0", // Gas consumed by the transaction
      status: receipt?.status, // Transaction status (1=success, 0=failed)
      from: receipt?.from, // Sender address
      to: receipt?.to, // Recipient address
      tokenAmount: amount, // Amount of tokens transferred
    };

    // Log the transaction details and update address balances
    transactionLog(dataStructure);
    address();
    console.log(`Transfer successful! Hash: ${tx.hash}`);

    console.log("--------------------------------");

    // Display the final balances for both sender and recipient
    console.log("Recipient balance:", await token.balanceOf(recipient));
    console.log("Sender balance:", await token.balanceOf(sender.address));

    console.log("--------------------------------");
  }
}

// Execute the main function and handle any errors
main().catch((error) => {
  console.error(error);
  process.exitCode = 1; // Set exit code to indicate failure
});
