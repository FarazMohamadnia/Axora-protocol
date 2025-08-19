import {buildModule} from '@nomicfoundation/hardhat-ignition/modules'

export default buildModule('airdrop' , (m)=>{
    const airdrop = m.contract("Airdrop",[])
    return{
        airdrop
    }
})