/**
 * searchingHash.ts - Blockchain Transaction Hash Search Utility
 *
 * This script provides functionality to search for and retrieve detailed information
 * about blockchain transactions using their transaction hash. It connects to a local
 * Hardhat network and displays comprehensive transaction details including receipt
 * and transaction data.
 */

import { network } from "hardhat";

// Connect to the local Hardhat network for blockchain operations
const { ethers } = await network.connect({
  network: "localhost",
  chainType: "l1",
});

/**
 * Searches for a transaction on the blockchain using its hash
 * Retrieves both transaction receipt and transaction data for comprehensive information
 *
 * @param hash - The transaction hash to search for (0x... format)
 */
async function searchTransaction(hash: string) {
  try {
    console.log(`\nSearching for transaction: ${hash}`);

    // Get transaction receipt (contains execution results and gas usage)
    const txReceipt = await ethers.provider.getTransactionReceipt(hash);

    // Get transaction data (contains input parameters and transaction details)
    const txData = await ethers.provider.getTransaction(hash);

    // Check if both transaction receipt and data were found
    if (txReceipt && txData) {
      console.log("Transaction Found:");
      console.log("- Hash:", hash); // Transaction hash (unique identifier)
      console.log("- Block Number:", txReceipt.blockNumber); // Block where transaction was included
      console.log("- Gas Used:", txReceipt.gasUsed.toString()); // Total gas consumed
      console.log("- Status:", txReceipt.status === 1 ? "Success" : "Failed"); // Execution status (1=success, 0=failed)
      console.log("- From:", txData.from); // Sender's wallet address
      console.log("- To:", txData.to); // Recipient's wallet address (null for contract creation)
      console.log("- Value:", ethers.formatEther(txData.value || 0), "ETH"); // ETH amount transferred (converted from wei)
      console.log(
        "- Gas Price:",
        ethers.formatUnits(txData.gasPrice || 0, "gwei"), // Gas price in gwei for readability
        "gwei"
      );
      console.log("- Nonce:", txData.nonce); // Transaction sequence number for the sender
      console.log("- Data:", txData.data); // Input data (contract function calls, etc.)
    } else {
      // Handle case where transaction is not found or not yet mined
      console.log("Transaction not found or not yet mined");
    }
  } catch (error) {
    // Handle any errors that occur during the search process
    console.error("Error searching transaction:", error);
  }
}

// Example usage: Search for a transaction (currently empty - needs valid hash)
// To use: Replace empty string with actual transaction hash
searchTransaction("");

// Export the function for use in other modules
export default searchTransaction;
