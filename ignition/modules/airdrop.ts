import {buildModule} from '@nomicfoundation/hardhat-ignition/modules'
import * as dotenv from "dotenv";
dotenv.config();




console.log(process.env.TOKEN_ADDRESS);


export default buildModule('airdrop' , (m)=>{
    const airdrop = m.contract("Airdrop",[
        process.env.TOKEN_ADDRESS || "",
        100,
        10,
        100000000000000
    ])

    return{
        airdrop
    }
})