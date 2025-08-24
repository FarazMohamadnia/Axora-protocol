/**
 * Log.ts - Blockchain Transaction and Data Logging Utility
 *
 * This module provides functionality to log blockchain transactions, blocks, and user address data
 * to JSON files for tracking and analysis purposes.
 */

import { network } from "hardhat";
import * as fs from "fs/promises";
import * as path from "path";
import { fileURLToPath } from "url";
import * as dotenv from "dotenv";

// Load environment variables from .env file
dotenv.config();

// Connect to the local Hardhat network
const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});

// Load user data from the accounts/users.json file
const usersData = JSON.parse(await fs.readFile("accounts/users.json", "utf8"));

// Get token contract address from environment variable
const TOKEN_ADDRESS = process.env.TOKEN_ADDRESS || "";

// Get current directory for ES modules compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Define file paths for storing different types of blockchain data
// All files are stored in the blockchain/ directory relative to project root
const TRANSACTION_FILE_PATH = path.join(
  __dirname,
  "..",
  "blockchain",
  "transaction.json"
);
const ADDRESS_FILE_PATH = path.join(
  __dirname,
  "..",
  "blockchain",
  "address.json"
);
const BLOCK_FILE_PATH = path.join(__dirname, "..", "blockchain", "block.json");

/**
 * Ensures that the directory for a given file path exists
 * Creates all necessary parent directories recursively if they don't exist
 *
 * @param filePath - The full file path for which to ensure directory exists
 */
async function ensureDirectoryExists(filePath: string) {
  const dir = path.dirname(filePath);
  await fs.mkdir(dir, { recursive: true });
}

/**
 * Initializes a JSON file with an empty array if it doesn't exist or is corrupted
 * This prevents errors when trying to read from non-existent or malformed files
 *
 * @param filePath - Path to the JSON file to initialize
 */
async function initializeJsonFile(filePath: string) {
  try {
    const fileContent = await fs.readFile(filePath, "utf-8");
    // Try to parse existing content, if it fails, recreate the file
    JSON.parse(fileContent);
  } catch {
    // File doesn't exist or is corrupted, create new one with empty array
    await fs.writeFile(filePath, JSON.stringify([]));
  }
}

/**
 * Appends new data to an existing JSON file
 * Creates the file and directory if they don't exist
 * Handles corrupted files by recreating them with the new data
 *
 * @param filePath - Path to the JSON file to append to
 * @param data - Data object to append to the file
 */
async function appendToJsonFile(filePath: string, data: any) {
  try {
    // Ensure the directory structure exists
    await ensureDirectoryExists(filePath);
    // Initialize the file if needed
    await initializeJsonFile(filePath);

    let jsonData = [];
    try {
      // Read existing data from file
      const fileContent = await fs.readFile(filePath, "utf-8");
      jsonData = JSON.parse(fileContent);
    } catch {
      // If file is corrupted, start with empty array
      jsonData = [];
    }

    // Add new data to the array
    jsonData.push(data);
    // Write the updated data back to file with pretty formatting
    await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2));
    console.log(`Data successfully appended to ${filePath}`);
  } catch (error) {
    console.error(`Error appending to JSON file (${filePath}):`, error);
  }
}

/**
 * Updates existing data in a JSON file or adds new entries
 * This function is specifically designed for address data updates
 * It checks if a user already exists and updates their balances, or adds new users
 *
 * @param filePath - Path to the JSON file to update
 * @param data - Data object containing users array with updated information
 */
async function updateJsonFile(filePath: string, data: any) {
  try {
    // Ensure the directory structure exists
    await ensureDirectoryExists(filePath);
    // Initialize the file if needed
    await initializeJsonFile(filePath);

    let jsonData = [];
    try {
      // Read existing data from file
      const fileContent = await fs.readFile(filePath, "utf-8");
      jsonData = JSON.parse(fileContent);
    } catch {
      // If file is corrupted, start with empty array
      jsonData = [];
    }

    // Process each user in the new data
    for (const newUser of data.users) {
      // Find if user already exists by address
      const existingIndex = jsonData.findIndex(
        (user: any) => user.address === newUser.address
      );

      if (existingIndex !== -1) {
        // Update existing user's balances and timestamp
        jsonData[existingIndex].tokenBalance = newUser.tokenBalance;
        jsonData[existingIndex].ethBalance = newUser.ethBalance;
        jsonData[existingIndex].lastUpdated = new Date().toISOString();
      } else {
        // Add new user if they don't exist, with current timestamp
        jsonData.push({
          ...newUser,
          lastUpdated: new Date().toISOString(),
        });
      }
    }

    // Write the updated data back to file
    await fs.writeFile(filePath, JSON.stringify(jsonData, null, 2));
    console.log(`Data successfully updated in ${filePath}`);
  } catch (error) {
    console.error(`Error updating JSON file (${filePath}):`, error);
  }
}

/**
 * Logs transaction details to the transaction.json file
 * Extracts key information from the transaction object and stores it with timestamp
 *
 * @param tx - Transaction object from the blockchain
 */
async function transactionLog(tx: any) {
  const transactionData = {
    hash: tx.hash, // Transaction hash
    blockNumber: tx.blockNumber, // Block number where transaction was included
    gasUsed: tx?.gasUsed?.toString(), // Gas used by the transaction
    status: tx.status === 1 ? "Success" : "Failed", // Transaction status (1 = success, 0 = failed)
    from: tx.from, // Sender address
    to: tx.to, // Recipient address
    tokenAmount: tx.tokenAmount || 0, // Amount of tokens transferred (if applicable)
    timestamp: new Date().toISOString(), // Current timestamp
  };

  await appendToJsonFile(TRANSACTION_FILE_PATH, transactionData);
}

/**
 * Logs block information to the block.json file
 * Stores block number and timestamp for tracking blockchain progress
 *
 * @param blokData - Block data object containing block information
 */
async function blok(blokData: any) {
  const blockData = {
    blockNumber: blokData.blockNumber, // Block number
    timestamp: new Date().toISOString(), // Current timestamp
  };

  await appendToJsonFile(BLOCK_FILE_PATH, blockData);
}

/**
 * Logs user address data including ETH and token balances
 * Reads current balances from the blockchain and updates the address.json file
 * This function is useful for tracking user portfolio changes over time
 */
async function address() {
  // Get contract instance for the token
  const token = await ethers.getContractAt("Token", TOKEN_ADDRESS);
  const users = [];

  // Iterate through all users in the users.json file
  for (const key in usersData) {
    const user = usersData[key];

    // Get current ETH balance for the user
    const ethBalance = await ethers.provider.getBalance(user.address);
    // Get current token balance for the user
    const tokenBalance = await token.balanceOf(user.address);

    // Add user data to the array
    users.push({
      name: key, // User identifier/name
      address: user.address, // User's wallet address
      tokenBalance: tokenBalance.toString(), // Convert BigInt to string for JSON compatibility
      ethBalance: ethers.formatEther(ethBalance), // Convert wei to ETH for readability
    });
  }

  // Prepare the complete address data object
  const addressData = {
    users, // Array of user data
    timestamp: new Date().toISOString(), // Current timestamp
  };

  // Update the address.json file with new data
  await updateJsonFile(ADDRESS_FILE_PATH, addressData);
  console.log("Address data logged successfully");
}

// Export the main logging functions for use in other modules
export { transactionLog, blok, address };
