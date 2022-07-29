// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";    
import "@openzeppelin/contracts/utils/Base64.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./PlatziPunksDNA.sol";

contract PlatziPunks is ERC721, ERC721Enumerable, PlatziPunksDNA {
    using Counters for Counters.Counter;
    // agregamos esta libreria para que los valores uint256 los pueda pasar a strings
    using Strings for uint256;

    Counters.Counter private _idCounter;
    uint256 public maxSupply;
    address payable treasury;

    mapping(uint256 => uint256) tokenDNA;

    constructor(uint256 _maxSupply) ERC721("PlatziPunks","PLPKS"){
        maxSupply = _maxSupply;
    }

    function mint() public payable {
        uint256 current = _idCounter.current();
        require(current < maxSupply, "All PlatziPunks were minted");
        //require(msg.value > 1000000000000000, "Must be over 0.001 ETH");

        //generar un DNA con lafuncion  deterministicPseudoRandomDNA
        tokenDNA[current] = deterministicPseudoRandomDNA(current, msg.sender);

        //mintear el nft y enviarlo a quien ejecuta el contrato
        _safeMint(msg.sender, current);
        // incrementar el id del token
        _idCounter.increment(); // _tokenId.increment()
        //enviar eth a la tesoreria
        //treasury.transfer(msg.value);

    }

    // Esta es la base URI que es donde apunta al servidor que guarda la informacion grafica del NFT, y se puede modificar
    // para que en caso de que el servidor alojado ya no exista, lo puedas reconstruir en otro.
    // ya que las caracteristicas del NFT estan escritas y guardadas en la blockchain
    function _baseURI() internal pure override returns(string memory){
        return "https://avataaars.io/";
    }

    function  _paramsURI(uint256 _dna) internal view returns(string memory) {
        string memory params;
        // Aqui se llena el stack de memoria, por lo que se encierra en llaves "{}" y se saca el la ultima variable
      {
        // Esta manera es para concatenar strings
          params =  string(
            abi.encodePacked(
                "accessoriesType=",
                getAccessoriesType(_dna),
                "&clotheColor=",
                getClotheColor(_dna),
                "&clotheType=",
                getClotheType(_dna),
                "&eyeType=",
                getEyeType(_dna),
                "&eyebrowType=",
                getEyeBrowType(_dna),
                "&facialHairColor=",
                getFacialHairColor(_dna),
                "&facialHairType=",
                getFacialHairType(_dna),
                "&hairColor=",
                getHairColor(_dna),
                "&hatColor=",
                getHatColor(_dna),
                "&graphicType=",
                getGraphicType(_dna),
                "&mouthType=",
                getMouthType(_dna),
                "&skinColor=",
                getSkinColor(_dna)
                
            ));
      }
        
        // finalmente se agrega el ultimo parametro en esta sección
        return string(abi.encodePacked(params, "&topType=", getTopType(_dna) ));
    }

    // Aqui se genera el link URL para hacer la visualizacíon del NFT 
    function imageByDNA(uint256 _dna) public view returns (string memory){
        string memory baseURI = _baseURI();
        string memory paramsURI = _paramsURI(_dna);

        return string (abi.encodePacked(baseURI,"?",paramsURI));
    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId),"ERC721 Metadata: URI query for none existent token");

        uint256 dna = tokenDNA[tokenId];
        string memory image = imageByDNA(dna);

        // Aqui se comienza a crear una URI para que se almacene toda la info en la blockchain
        // la manera de concatenar es por medio de bytes, como se muesrta a continuacion
        string memory jsonURI = Base64.encode(
            abi.encodePacked(
                '{ "name": "PlatziPunks #',
                // Asegurarnos con la libreria de openzeppelin para poder pasar todos los caracteres a bytes
                tokenId.toString(),
                '", "description": "Platzi Punks are randomized avatars stored on chain to teach DAap development on Platzi", "image": "',
                image,
                '"}'
            
        ));
                        // Aqui se vuelve a concatenar para crear la URI de acuerdo al estandar
        return string (abi.encodePacked("data:application/json;base64,",jsonURI));
    }

    // The following functions are overrides required by Solidity.
    function _beforeTokenTransfer(address from, address to, uint256 tokenId)
        internal
        override(ERC721, ERC721Enumerable)
    {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }



}