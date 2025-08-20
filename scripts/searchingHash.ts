import { network } from "hardhat";

const { ethers } = await network.connect({
    network: "localhost",
    chainType: "l1",
  });

async function searchTransaction(hash: string) {
    try {
      console.log(`\nSearching for transaction: ${hash}`);
      const txReceipt = await ethers.provider.getTransactionReceipt(hash);
      const txData = await ethers.provider.getTransaction(hash);

      if (txReceipt && txData) {
        console.log("Transaction Found:");
        console.log("- Hash:", hash);
        console.log("- Block Number:", txReceipt.blockNumber);
        console.log("- Gas Used:", txReceipt.gasUsed.toString());
        console.log("- Status:", txReceipt.status === 1 ? "Success" : "Failed");
        console.log("- From:", txData.from);
        console.log("- To:", txData.to);
        console.log("- Value:", ethers.formatEther(txData.value || 0), "ETH");
        console.log(
          "- Gas Price:",
          ethers.formatUnits(txData.gasPrice || 0, "gwei"),
          "gwei"
        );
        console.log("- Nonce:", txData.nonce);
        console.log("- Data:", txData.data);
      } else {
        console.log("Transaction not found or not yet mined");
      }
    } catch (error) {
      console.error("Error searching transaction:", error);
    }
}

searchTransaction("");

export default searchTransaction;