// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";    
import "@openzeppelin/contracts/utils/Base64.sol";
import "./PlatziPunksDNA.sol";

contract PlatziPunks is ERC721, ERC721Enumerable, PlatziPunksDNA {
    using Counters for Counters.Counter;

    Counters.Counter private _idCounter;
    uint256 public maxSupply;
    address payable treasury;

    constructor(uint256 _maxSupply, address payable _treasury) ERC721("PlatziPunks","PLPKS"){
        maxSupply = _maxSupply;
        treasury = _treasury;
    }

    function mint() public payable {
        uint256 current = _idCounter.current();
        require(current < maxSupply, "All PlatziPunks were minted");
        require(msg.value > 1000000000000000, "Must be over 0.001 ETH");

        _safeMint(msg.sender, current);
        _idCounter.increment(); // _tokenId.increment()
        treasury.transfer(msg.value);

    }

    function tokenURI(uint256 tokenId) public view override returns (string memory){
        require(_exists(tokenId),"ERC721 Metadata: URI query for none existent token");

        // Aqui se comienza a crear una URI para que se almacene toda la info en la blockchain
        // la manera de concatenar es por medio de bytes, como se muesrta a continuacion
        string memory jsonURI = Base64.encode(
            abi.encodePacked(
                '{ "name": "PlatziPunks #" ',
                tokenId,
                '", "descripcion": "Platzi Punks are randomized avatars stored on chain to teach DAap development on Platzi", "image": ',
                "// TODO: calculate image url",
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