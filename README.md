# How to Make NFTs with On-Chain Metadata on Polygon Amoy

Creating NFTs with on-chain metadata allows for fully decentralized and dynamic NFTs that can be updated directly from the smart contract. This tutorial will guide you through creating such NFTs using Hardhat and JavaScript, and deploying them on the Polygon Amoy testnet to minimize gas fees.

## Prerequisites

Before you start, ensure you have the following:
- Node.js and npm installed
- Metamask wallet installed and configured
- An Alchemy account

## Project Setup

### 1. Initialize the Project

Open your terminal and create a new folder for your project:

```bash
mkdir nft-onchain-metadata
cd nft-onchain-metadata
npx hardhat init
```

Select "Create a TypeScript project" and agree to all the defaults. This will create a basic Hardhat project structure.

### 2. Install Dependencies

Install the OpenZeppelin contracts library:

```bash
npm install @openzeppelin/contracts
```

### 3. Configure Hardhat

Open the `hardhat.config.ts` file and update it to connect to the Polygon Amoy testnet:

```ts
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import dotenv from "dotenv";
dotenv.config();

const config: HardhatUserConfig = {
  solidity: "0.8.24",
  networks: {
    amoy: {
      url: process.env.TESTNET_RPC,
      accounts: [process.env.PRIVATE_KEY || ""]
    }
  },
  etherscan: {
    apiKey: process.env.POLYGONSCAN_API_KEY,
  }
};

export default config;

```

Create a `.env` file in the root directory and add the following environment variables:

```plaintext
TESTNET_RPC=your_alchemy_amoy_rpc_url
PRIVATE_KEY=your_metamask_private_key
POLYGONSCAN_API_KEY=your_polygonscan_api_key
```

Replace `your_alchemy_amoy_rpc_url`, `your_metamask_private_key`, and `your_polygonscan_api_key` with your actual values.

### 4. Develop the Smart Contract

Create a new file in the `contracts` folder called `ChainBattles.sol` and add the following code:

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

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

```

### 5. Deploy the Smart Contract

Create a deployment script in the `scripts` folder called `deploy.ts`:

```ts
import hre from 'hardhat';

const main = async () => {
    try {
      const nftContractFactory = await hre.ethers.getContractFactory(
        "ChainBattles"
      );
      const nftContract = await nftContractFactory.deploy();
  
      console.log("Contract deployed to:", await nftContract.getAddress());
      process.exit(0);
    } catch (error) {
      console.log(error);
      process.exit(1);
    }
  };
    
  main();
```

Deploy the smart contract:

```bash
npx hardhat compile
npx hardhat run scripts/deploy.ts --network amoy
```

### 6. Verify the Smart Contract

Once deployed, verify your contract on Polygonscan:

```bash
npx hardhat verify --network amoy <contract_address>
```

Replace `<contract_address>` with the address returned from the deployment script.

### 7. Interacting with the Smart Contract

You can interact with your deployed contract through a web interface as well. Here's how you can mint and train NFTs and verify their presence on OpenSea:

#### Interacting via Web Interface:

1. **Minting NFTs:**
   - Navigate to [amoy.polygonscan.com](https://amoy.polygonscan.com) and search for your contract address.
   - Click on the "Contract" tab, then select "Write Contract".
   - Look for the "mint" function and execute it to mint a new NFT.

2. **Training NFTs:**
   - After minting, repeat the steps above to access the contract on Polygonscan.
   - Find the "train" function and insert the ID of your newly minted NFT (e.g., "1").
   - Click on "Write" to execute the function.

3. **Verification on OpenSea:**
   - Go to [testnets.opensea.io](https://testnets.opensea.io/) and refresh the page.
   - If everything worked as expected, you should now see your NFT displayed on OpenSea with its dynamic image, title, and description.