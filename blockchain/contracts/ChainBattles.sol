// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

// Uncomment this line to use console.log
// import "hardhat/console.sol";

import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {Strings} from "@openzeppelin/contracts/utils/Strings.sol";
import {Base64} from "@openzeppelin/contracts/utils/Base64.sol";

contract ChainBattles is ERC721URIStorage {
    using Strings for uint256;
    struct Specs {
        uint256 level;
        uint256 speed;
        uint256 strength;
        uint256 life;
    }

    uint256 private _tokenIds;

    mapping(uint256 => Specs) public tokenIdToSpecs;

    constructor() ERC721("Chain Battles", "CB") {}

    function generateCharacter(
        uint256 tokenId
    ) public view returns (string memory) {
        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            "<style>.base { fill: white; font-family: serif; font-size: 14px; }</style>",
            '<rect width="100%" height="100%" fill="black" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Warrior",
            "</text>",
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">',
            "Specs: ",
            getSpecs(tokenId),
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

    function getSpecs(uint256 tokenId) public view returns (string memory) {
        Specs memory specs = tokenIdToSpecs[tokenId];
        return
            string(
                abi.encodePacked(
                    "Level: ",
                    specs.level.toString(),
                    ", ",
                    "Speed: ",
                    specs.speed.toString(),
                    ", ",
                    "Strength: ",
                    specs.strength.toString(),
                    ", ",
                    "Life: ",
                    specs.life.toString()
                )
            );
    }

    function getTokenURI(uint256 tokenId) public view returns (string memory) {
        bytes memory dataURI = abi.encodePacked(
            "{",
            '"name": "Chain Battles #',
            tokenId.toString(),
            '",',
            '"description": "Battles on chain",',
            '"image": "',
            generateCharacter(tokenId),
            '"',
            "}"
        );
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(dataURI)
                )
            );
    }

    function mint() public {
        _tokenIds += 1;
        uint256 newItemId = _tokenIds;
        _safeMint(msg.sender, newItemId);
        tokenIdToSpecs[newItemId] = Specs({
            level: 1,
            speed: 1,
            strength: 1,
            life: 1
        });
        _setTokenURI(newItemId, getTokenURI(newItemId));
    }

    function train(uint256 tokenId, string memory attribute) public {
        require(ownerOf(tokenId) != address(0), "Please use an existing token");
        require(
            ownerOf(tokenId) == msg.sender,
            "You must own this token to train it"
        );

        Specs storage specs = tokenIdToSpecs[tokenId];

        if (
            keccak256(abi.encodePacked(attribute)) ==
            keccak256(abi.encodePacked("level"))
        ) {
            specs.level += 1;
        } else if (
            keccak256(abi.encodePacked(attribute)) ==
            keccak256(abi.encodePacked("speed"))
        ) {
            specs.speed += 1;
        } else if (
            keccak256(abi.encodePacked(attribute)) ==
            keccak256(abi.encodePacked("strength"))
        ) {
            specs.strength += 1;
        } else if (
            keccak256(abi.encodePacked(attribute)) ==
            keccak256(abi.encodePacked("life"))
        ) {
            specs.life += 1;
        } else {
            revert("Invalid attribute");
        }

        _setTokenURI(tokenId, getTokenURI(tokenId));
    }
}
