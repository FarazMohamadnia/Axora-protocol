import { network } from "hardhat";
import * as fs from "fs";

// Load users from users.json
const usersData = JSON.parse(fs.readFileSync("accounts/users.json", "utf8"));

const usersList = [
  {
    address: usersData.user1.address,
    privateKey: usersData.user1.privateKey,
  },
  {
    address: usersData.user2.address,
    privateKey: usersData.user2.privateKey,
  },
  {
    address: usersData.user3.address,
    privateKey: usersData.user3.privateKey,
  },
  {
    address: usersData.user4.address,
    privateKey: usersData.user4.privateKey,
  },
  {
    address: usersData.user5.address,
    privateKey: usersData.user5.privateKey,
  },
  {
    address: usersData.user6.address,
    privateKey: usersData.user6.privateKey,
  },
];

// Set to true to send tokens to all users in bulk
const bulksending = true;

async function main() {
  const { ethers } = await network.connect({
    network: "localhost",
    chainType: "l1",
  });

  const [sender] = await ethers.getSigners();

  // Get the token contract
  const token = await ethers.getContractAt(
    "Token",
    "0xe7f1725E7734CE288F8367e1Bb143E90bb3F0512"
  );

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
        const tx = await token.transfer(user.address, 100);
        await tx.wait();
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
    // change signer to user3
    const senderWallet = new ethers.Wallet(usersData.user3.privateKey);
    const sender = senderWallet.connect(ethers.provider);
    // add amount and address to send tokens
    const tx = await token.transfer(usersList[4].address, 127);
    await tx.wait();
    console.log(`Transfer successful! Hash: ${tx.hash}`);
    console.log("--------------------------------");
    console.log("User balance:", await token.balanceOf(usersList[4].address));
    console.log("--------------------------------");
  }
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
