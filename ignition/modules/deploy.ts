import { buildModule } from "@nomicfoundation/hardhat-ignition/modules";

export default buildModule("deploy", (m) => {
    const token = m.contract("Token",[100000])

    m.call(token, "deploy", []);
    return {
        token,
    };
})