const { ethers } = require("hardhat");

const deploy = async () => {

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contract with the account: ", deployer.address );

    //const PlatziPunks = await ethers.getContractFactory("PlatziPunks"); // este debe ser el mismo nombre del smart contract
    //const deployed = await PlatziPunks.deploy(10000);
    const mycontract = await ethers.getContractFactory("test_contract"); // este debe ser el mismo nombre del smart contract
    const deployed = await mycontract.deploy('0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E'); //BUSD contract 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E

    //console.log("Platzi Punks was deployed at: ", deployed.address)
    console.log("contract was deployed at: ", deployed.address)
};

deploy()
.then(() => process.exit(0))
.catch(error => {
    console.log(error)
    process.exit(1)
});