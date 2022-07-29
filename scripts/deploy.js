const { ethers } = require("hardhat");

const deploy = async () => {

    const [deployer] = await ethers.getSigners();

    console.log("Deploying contract with the account: ", deployer.address );

    const PlatziPunks = await ethers.getContractFactory("PlatziPunks"); // este debe ser el mismo nombre del smart contract
    const deployed = await PlatziPunks.deploy(10000);

    console.log("Platzi Punks was deployed at: ", deployed.address)
};

deploy()
.then(() => process.exit(0))
.catch(error => {
    console.log(error)
    process.exit(1)
});