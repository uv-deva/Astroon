// 1. Import libraries. Use `npm` package manager to install
import { MerkleTree } from "merkletreejs";
import { soliditySha3 } from "web3-utils";

// 2. Collect list of wallet addresses from competition, raffle, etc.
// Store list of addresses in some data sheeet (Google Sheets or Excel)
const whitelistAddresses = [
  soliditySha3("0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", 1000000000000000),
  soliditySha3("0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB", 1000000000000000),
];

// const hash1 = web3.utils.soliditySha3(address1, token1, amount1);
// 3. Create a new array of `leafNodes` by hashing all indexes of the `whitelistAddresses`
// using `keccak256`. Then creates a Merkle Tree object using keccak256 as the algorithm.
//
// The leaves, merkleTree, and rootHas are all PRE-DETERMINED prior to whitelist claim
// const leafNodes = whitelistAddresses.map(addr => keccak256(addr));
// console.log(leafNodes);

const merkleTree = new MerkleTree(whitelistAddresses, soliditySha3, { sortPairs: true });

// 4. Get root hash of the `merkleeTree` in hexadecimal format (0x)
// Print out the Entire Merkle Tree.
const rootHash = merkleTree.getHexRoot();
console.log("Whitelist Merkle Tree\n", merkleTree.toString());
console.log("Root Hash: ", rootHash);

// ***** ***** ***** ***** ***** ***** ***** ***** //

// CLIENT-SIDE: Use `msg.sender` address to query and API that returns the merkle proof
// required to derive the root hash of the Merkle Tree

const claimingAddress = whitelistAddresses[0] || "";
// console.log("claimingAddress", claimingAddress)
// const claimingAddress = web3.utils.soliditySha3("0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db", 1000000000000000);

// `getHexProof` returns the neighbour leaf and all parent nodes hashes that will
// be required to derive the Merkle Trees root hash.
const hexProof = merkleTree.getHexProof(claimingAddress);
console.log(hexProof);

// This would be implemented in your Solidity Smart Contract
console.log(merkleTree.verify(hexProof, claimingAddress, rootHash));
