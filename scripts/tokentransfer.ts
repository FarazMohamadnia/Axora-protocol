import { network } from "hardhat";
import * as fs from "fs";
import { transactionLog, blok, address } from "./log.js";
import * as dotenv from "dotenv";

// Load environment variables
dotenv.config();

// Load users from users.json
const usersData = JSON.parse(fs.readFileSync("accounts/users.json", "utf8"));

// Get token address from environment variable
const TOKEN_ADDRESS =
  process.env.TOKEN_ADDRESS || "";

interface User {
  address: string;
  privateKey: string;
}

const usersList: User[] = [];

// Generate usersList dynamically using a loop
for (const key in usersData) {
  if (usersData.hasOwnProperty(key)) {
    usersList.push({
      address: usersData[key].address,
      privateKey: usersData[key].privateKey,
    });
  }
}

// Set to true to send tokens to all users in bulk
const bulksending = false;

async function main() {
  const { ethers } = await network.connect({
    network: "localhost",
    chainType: "l1",
  });

  const [sender] = await ethers.getSigners();

  // Get the token contract
  const token = await ethers.getContractAt("Token", TOKEN_ADDRESS);

  console.log("Token contract name:", await token.name());
  console.log("Token contract symbol:", await token.symbol());
  console.log("Token contract decimals:", await token.decimals());
  console.log("Token contract totalSupply:", await token.totalSupply());

  if (bulksending) {
    for (const user of usersList) {
      console.log("User address:", user.address);
      console.log("User balance:", await token.balanceOf(user.address));
      console.log("--------------------------------");
    }

    console.log("--------------------------------");

    // Transfer tokens from sender to each user
    for (const user of usersList) {
      try {
        console.log(`Transferring 100 tokens to ${user.address}...`);
        const amount = 100;
        const tx = await token.transfer(user.address, amount);
        const receipt = await tx.wait();
        const dataStructure = {
          hash: tx.hash,
          blockNumber: receipt?.blockNumber,
          gasUsed: receipt?.gasUsed?.toString() || "0",
          status: receipt?.status,
          from: receipt?.from,
          to: receipt?.to,
          tokenAmount: amount,
        };
        transactionLog(dataStructure);
        address();
        console.log(`Transfer successful! Hash: ${tx.hash}`);
      } catch (error) {
        console.error(`Transfer to ${user.address} failed:`, error);
      }
    }
    console.log("--------------------------------");

    for (const user of usersList) {
      console.log("User address:", user.address);
      console.log("User balance:", await token.balanceOf(user.address));
      console.log("--------------------------------");
    }
  } else {
    // change signer to user2 (you can change this to any user)
    const senderWallet = new ethers.Wallet(usersData.user1.privateKey);
    const sender = senderWallet.connect(ethers.provider);
    const tokenWithSigner = token.connect(sender); // Connect sender wallet to token contract

    const amount = 50; // change amount
    const recipient = usersList[5].address; // change recipient to user6
    // add amount and address to send tokens
    const tx = await tokenWithSigner.transfer(recipient, amount);
    const receipt = await tx.wait();
    const dataStructure = {
      hash: tx.hash,
      blockNumber: receipt?.blockNumber,
      gasUsed: receipt?.gasUsed?.toString() || "0",
      status: receipt?.status,
      from: receipt?.from,
      to: receipt?.to,
      tokenAmount: amount,
    };
    transactionLog(dataStructure);
    address();
    console.log(`Transfer successful! Hash: ${tx.hash}`);
    console.log("--------------------------------");
    console.log("Recipient balance:", await token.balanceOf(recipient));
    console.log("Sender balance:", await token.balanceOf(sender.address));

    console.log("--------------------------------");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
