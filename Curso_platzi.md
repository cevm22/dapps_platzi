# introduccion a DAPPS en platzi

Hardhat es un entorno de desarrollo que permite compilar, probar y depslegar smart contracts

- npx hardhat compile > funciona para compilacion de archivos, previamente al despliegue
- npx hardhat test > usa Javascript para hacer tests automatizadas

* Antes de hacer un despliegue, si cuenta con un constructor, se debe configurar los scripts de deploy.js

En caso de que ocurra error por usar muchas variables (mas de 16) https://soliditydeveloper.com/stacktoodeep

* dividirlo en varias funciones
* usar menos variables
* Usar brackets y agreagarlo
contract StackTooDeepTest2 {
    function addUints(
        uint256 a,uint256 b,uint256 c,uint256 d,uint256 e,uint256 f,uint256 g,uint256 h,uint256 i
    ) external pure returns(uint256) {
        
        uint256 result = 0;
        
        {
            result = a+b+c+d+e;
        }
        
        {
            result = result+f+g+h+i;
        }

        return result;
    }
}