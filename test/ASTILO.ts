import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expectEvent, expectRevert } from "@openzeppelin/test-helpers";
import { expect } from "chai";
import hre from "hardhat";
//import { ASTILO } from "../typechain";
import { ethers, upgrades } from "hardhat";
import { connect } from "http2";
import { MerkleTree } from "merkletreejs";
import truffleAssert from "truffle-assertions";
import { soliditySha3 } from "web3-utils";

describe("Unit Tests", function () {
  let token: any;
  let contract;
  let initialTokens = (10000).toString();

  let user: SignerWithAddress;
  let admin: SignerWithAddress;

  const _rate = (1 * 10 ** 18).toString(); //.00078 ether
  const _cap = "7800000000000000000".toString();

  const _ddays = (2).toString();
  const _threshold = "10000000000000000000".toString(); //10
  const _cliff = 10;
  const _vesting = (5).toString();
  const _minBound = "1000000000000000000".toString();

  beforeEach(async function () {
    const signers: SignerWithAddress[] = await ethers.getSigners();
    admin = signers[0];
    user = signers[1];

    const astToken = await ethers.getContractFactory("ASTToken");
    token = await astToken.deploy();
    await token.deployed();

    const astilo = await ethers.getContractFactory("ASTILO");
    contract = await upgrades.deployProxy(astilo, [token.address, initialTokens], {
      initializer: "initialize",
    });
    await contract.deployed();

    const blockNumber = await ethers.provider.getBlockNumber();
    const { timestamp } = await ethers.provider.getBlock(blockNumber);

    console.log("contract address is:", contract.address);
    const tx = await contract.startTokenSale(_rate, _cap, timestamp, _ddays, _threshold, _cliff, _vesting, _minBound);
    var x = parseInt((await tx.wait()).logs[0].data);

    const saleOn = await contract.togglePresale();
  });

  describe("isActive", () => {
    it("should return true -sale is active", async function () {
      const tx = await contract.isActive("1");
      expect(tx).to.be.equal(true);
    });
  });

  describe("buyTokens", () => {
    it("should be executed - Public sale is toggled", async function () {
      await truffleAssert.reverts(contract.connect(user).buyTokens(), "sale is OFF");
    });

    it("should be reverted - as amount enetred is not sufficient", async function () {
      await truffleAssert.reverts(contract.connect(user).buyTokens({ value: 0 }), "");
    });

    describe("buyPreTokens", () => {
      async function merkleTree() {
        const whitelistAddresses = [soliditySha3(user.address)];
        const merkleTree = new MerkleTree(whitelistAddresses, soliditySha3, { sortPairs: true });
        const rootHash = merkleTree.getHexRoot();
        console.log("Whitelist Merkle Tree\n", merkleTree.toString());
        console.log("Root Hash: ", rootHash);
        const claimingAddress = whitelistAddresses[0] || "";
        const hexProof = merkleTree.getHexProof(claimingAddress);
        console.log(hexProof);
        await contract.setMerkleRoot(rootHash);
        return hexProof;
      }
      it("buyToken", async function () {
        var hexProof = await merkleTree();
        await contract.connect(user).preSaleBuy(hexProof, { value: (2 * 10 ** 18).toString() });

        await ethers.provider.send("evm_increaseTime", [9 * 24 * 60 * 60]);
        var amount = 10000 * 10 ** 18;
        await token.transfer(contract.address, amount.toLocaleString("fullwide", { useGrouping: false }));
        await truffleAssert.reverts(contract.connect(user).claim(1), "cliff not ended");

        await ethers.provider.send("evm_increaseTime", [2 * 24 * 60 * 60]);
        await contract.connect(user).claim(1);
      });
    });
  });
});
