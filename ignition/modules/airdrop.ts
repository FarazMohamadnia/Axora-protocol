import {buildModule} from '@nomicfoundation/hardhat-ignition/modules'
import {network} from 'hardhat'
import * as dotenv from "dotenv";
dotenv.config();
const {ethers} = await network.connect({
    network: "localhost",
})



const [sender] = await ethers.getSigners();

console.log(process.env.TOKEN_ADDRESS);


export default buildModule('airdrop' , (m)=>{
    const airdrop = m.contract("Airdrop",[
        sender.address,
        process.env.TOKEN_ADDRESS || "",
        100,
        10,
        100000000000000
    ])

    return{
        airdrop
    }
})