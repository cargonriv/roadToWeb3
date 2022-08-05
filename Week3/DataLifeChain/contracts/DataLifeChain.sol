// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// Import this file to use console.log
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

contract DataLifeChain is ERC721URIStorage, ERC721Burnable {
    using Strings for uint256;
    using Counters for Counters.Counter;
    Counters.Counter private _collectedTokenIds;
    Counters.Counter private _tokenIds;

    mapping(address => mapping(uint256 => uint256)) public ownedTokenAtIndex;
    mapping(address => uint256[]) public ownerTokenIds;

    // event Withdrawal(uint amount, uint when);

    constructor() ERC721("DataLifeChain", "DLC") {}

    function mint() public {
        uint256 itemId = _tokenIds.current();
        _tokenIds.increment();

        _safeMint(msg.sender, itemId);
        ownerTokenIds[msg.sender].push(itemId);
        _setTokenURI(itemId, getTokenURI(itemId));

        uint256 userOwnedTokenAmount = ownerTokenIds[msg.sender].length;
        ownedTokenAtIndex[msg.sender][itemId] = userOwnedTokenAmount;
    }

    function collectAmount(uint256[] memory tokenIds) public {
        require(tokenIds.length >= 3, "3 minimum tokens to collect");
        // ? MATH FORMULA FOR UNIQUENESS on collectAmount ?
        // provide an IDIOSYNCRATIC_ID for currentCollected
        // uint256 currentCollected = tokenIds.length + 1;
        for (uint256 index; index < tokenIds.length; index++) {
            require(
                msg.sender == ownerOf(tokenIds[index]),
                "You must own these tokens to collect"
            );
            require(
                _exists(ownedTokenAtIndex[msg.sender][tokenIds[index]]),
                "This token does not yet exist"
            );
            delete ownedTokenAtIndex[msg.sender][tokenIds[index]];
            _burn(ownerTokenIds[msg.sender][tokenIds[index]]);
        }
        uint256 collectedId = _collectedTokenIds.current() + 10000;
        _safeMint(msg.sender, collectedId);
        ownerTokenIds[msg.sender].push(collectedId);
        _setTokenURI(collectedId, getTokenURI(collectedId));
        uint256 userOwnedTokenAmount = ownerTokenIds[msg.sender].length;
        ownedTokenAtIndex[msg.sender][collectedId] = userOwnedTokenAmount;
    }

    function generateDataLife(uint256 tokenId)
        public
        pure
        returns (string memory)
    {
        bytes memory svg = abi.encodePacked(
            // add svg code of gifs?
            // (pngs for now)
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "DataLifeChain",
            "</text>",
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "TokenId: ",
            tokenId.toString(),
            "</text>",
            "</svg>"
        );

        return
            string(
                abi.encodePacked(
                    "data:image/svg+xml;base64,",
                    Base64.encode(svg)
                )
            );
    }

    function getTokenURI(uint256 tokenId) public pure returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "DataLifeChain #',
            tokenId.toString(),
            '",',
            '"description": "DataLife on chain",',
            '"image": "',
            generateDataLife(tokenId),
            '"',
            "}"
        );
        // console.log(string(
        //     abi.encodePacked(
        //         "data:application/json;base64,",
        //         Base64.encode(dataURI)
        //     )))
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    // UTILITY
    // function getToken(uint256 tokenId) public view return(string memory) {return tokenId.toString();}
    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }
}
