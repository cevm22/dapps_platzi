require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();//dnde esta ubicado el archivo dotenv

/** @type import('hardhat/config').HardhatUserConfig */

const projectId= process.env.INFURA_PROJECT_ID;
const privateKey= process.env.DEPLOYER_SIGNER_PRIVATE_KEY;

module.exports = {
  solidity: "0.8.9",
/*se pueden trabajar con varias redes a la vez */
  defaultNetwork: "rinkeby",
  networks:{
    hardhat: {
    },
    rinkeby:{
      url:'https://rinkeby.infura.io/v3/' + projectId,
      /*la cuenta debe estar fondeada, ya que va ser esta que va firmar el contrato */
      /*IMPORTANTE, agregar "0x" antes a la llave privada */
      accounts:[
        privateKey
      ]
    }
  }
};
