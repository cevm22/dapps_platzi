const { expect } = require("chai");

describe('Platzi Punks Contract', () => {
    const setup = async ({ maxSupply = 10000})  => {
        //el dueno del contrato es quien despliega
        const [owner] = await ethers.getSigners();
        //aqui toma el smartcontract para deployarlo, Tener en cuenta que debe tener el mismo nombre del smartcontract
        const PlatziPunks = await ethers.getContractFactory("PlatziPunks");
        // aqui es equivalente a pasar los parametros al constructor del msart contract
        const deployed = await PlatziPunks.deploy(maxSupply,'0xd92A8d5BCa7076204c607293235fE78200f392A7');

        return{
            owner,
            deployed
        };
    };

    describe('Deployment', () =>{
        it('Sets max supply to passed param', async () => {
            const maxSupply = 4000;

            // creamos el objeto del contrato desplegado
            const { deployed } = await setup({ maxSupply });
        
            // obtener informacion de la variable maxSupply que esta en el smart contract de solidity
            const returnedMaxSupply = await deployed.maxSupply();
            // compara el maxSupply del smartcontract sea igual al que se seteo en esta funcion
            expect(maxSupply).to.equal(returnedMaxSupply);
        })
    })
    describe('Minting', () => {
        it('Mints a new token assigns it to owner', async () =>{
            const { owner, deployed } = await setup({ }); //enviar un objeto vacío para que use el maxSupply por defecto
            //hacemos mint con el mismo owner del contrato, y como la función envía el nft al sender, entonces no se requiere hacer mas
            await deployed.mint();
            //ownerOf() es una funcion de openZeppelin, y el 0 es porque el nft saldra con id 0
            const ownerOfMinted = await deployed.ownerOf(0);
            //validamos que el ownerminted sea igual al dueno del contrato
            expect(ownerOfMinted).to.equal(owner.address);

            //TODO pendiente agregar validacion de enviar ETH
        })
    })
})