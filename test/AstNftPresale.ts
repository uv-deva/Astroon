import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { expect } from "chai";

const { expectRevert, expectEvent } = require("@openzeppelin/test-helpers");

//import { ASTILO } from "../typechain";

import { ethers } from 'hardhat'
import { upgrades } from 'hardhat'
const truffleAssert = require('truffle-assertions');


describe("Unit Tests", function () {

    let token:any, astNft:any, astReward:any, admin:SignerWithAddress, user:SignerWithAddress

    const _rate = (780000000000000).toString(); //.00078 ether
    const _cap = ("7800000000000000000").toString();

    const _ddays = (2).toString();
    const _threshold = ("10000000000000000000").toString(); //10
    const _cliff = 0;
    const _vesting = (5).toString();
    const _minBound = ("5000000000000000000").toString();

    beforeEach(async function () {
        const signers: SignerWithAddress[] = await ethers.getSigners();
        admin = signers[0];
        user = signers[1];

        const astToken = await ethers.getContractFactory("ASTToken");
        token = await astToken.deploy();
        await token.deployed();

        const nft = await ethers.getContractFactory("ASTNftSale");
        astNft = await upgrades.deployProxy(nft, ["ASTNFT", "AstNft", "http://ipfs.io/ipfs/", token.address, ".json", 4, (110*10**18).toString()], {
        initializer: "initialize",
        });
        await astNft.deployed();

        const reward = await ethers.getContractFactory("ASTTokenRewards");
        astReward = await upgrades.deployProxy(reward, [astNft.address, token.address], {
        initializer: "initialize",
        });
        await astReward.deployed();

        await astNft.setRewardContract(astReward.address);
        
        const blockNumber = await ethers.provider.getBlockNumber();
        const { timestamp } = await ethers.provider.getBlock(blockNumber);

        const tx = await astNft.startPreSale((1*10**18).toString(), (0.1*10**18).toString(), 2400, timestamp, timestamp+(30*24*60*60));
        var x = parseInt((await tx.wait()).logs[0].data);

        // await astNft.setTireMap(1, (100*10**18).toString(),  (300*10**18).toString());
        // await astNft.connect(admin).setTireMap(2, ((300*10**18)+1).toString(), (600*10**18).toString());
        // await astNft.connect(admin).setTireMap(3, ((600*10**18)+1).toString(), (800*10**18).toString());
    });

    describe("ASTNFT", () => {
        it("PreSale buy one by one", async function () {

            await token.transfer(user.address, (110*10**18).toString());
            var tx = await astNft.connect(user).buyPresale(1,{ value: (1*(1*10**18 + 0.1*10**18)).toString()});
            var txn = await tx.wait();

            // await token.transfer(user.address, (200*10**18).toString());
            // var tx = await astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()});
            // var txn = await tx.wait();

            // await token.transfer(user.address, (300*10**18).toString());
            // var tx = await astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()});
            // var txn = await tx.wait();

            // await token.transfer(user.address, (300*10**18).toString());
            // var tx = await astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()});
            // var txn = await tx.wait();

            await ethers.provider.send("evm_increaseTime", [365*24*60*60])
            await ethers.provider.send("evm_mine")
            var tx = await astReward.getRewardsCalc(0, 1, user.address)
            console.log("reward", parseInt(tx))
            // await token.connect(admin).transfer( astReward.address, ("1000000000000000000000".toString()));
            // await astReward.connect(user).claim();
            // await ethers.provider.send("evm_increaseTime", [((365*2) + 300)*24*60*60])
            // await ethers.provider.send("evm_mine")
            // tx = await astReward.getRewardsCalc(0, 1, user.address)
            // console.log("reward", parseInt(tx))
        })
        // it("PreSale buy two-two", async function () {

        //     await token.transfer(user.address, (301*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(2,{ value: (2*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.transfer(user.address, (600*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(2,{value: (2*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.transfer(user.address, (300*10**18).toString());
        //     await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()}), 'buying Limit exceeded');
        // });

        // it("PreSale buy three-one", async function () {

        //     await token.transfer(user.address, (601*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(3,{ value: (3*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.transfer(user.address, (300*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.transfer(user.address, (300*10**18).toString());
        //     await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (1*(1*10**18 + 0.1*10**18)).toString()}), 'buying Limit exceeded');
        // });

        // it("PreSale buy In between token removal from balance three-one", async function () {

        //     await token.transfer(user.address, (601*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(3,{ value: (3*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.connect(user).transfer(admin.address, (300*10**18).toString());
        //     await truffleAssert.reverts(astNft.connect(user).buyPresale(2,{value: (1*(1*10**18 + 0.1*10**18)).toString()}), 'buying Limit exceeded');
        // });

        // it("PreSale buy In between token removal from balance two-two", async function () {

        //     await token.transfer(user.address, (801*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(2,{ value: (2*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();
        //     await token.connect(user).transfer(admin.address, (300*10**18).toString());
        //     await truffleAssert.reverts(astNft.connect(user).buyPresale(3,{value: (2*(1*10**18 + 0.1*10**18)).toString()}), 'buying Limit exceeded');
        // });

        // it("PreSale buy In between token removal from balance one by one", async function () {

        //     await token.transfer(user.address, (801*10**18).toString());
        //     var tx = await astNft.connect(user).buyPresale(1,{ value: (1*(1*10**18 + 0.1*10**18)).toString()});
        //     var txn = await tx.wait();

        //     await token.connect(user).transfer(admin.address, (690*10**18).toString());
        //     await truffleAssert.reverts(astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()}), 'buying Limit exceeded');

        // });
        
        // it("PublicSale and privatesale validate or not", async function () {
        //     await ethers.provider.send("evm_increaseTime", [30*24*60*60])
        //     expect(astNft.connect(user).buyPresale(1,{value: (1*(1*10**18 + 0.1*10**18)).toString()}), 'PrivateSale is InActive');

        //     var tx = await astNft.connect(admin).mint([1, 3, 2, 0], ["demo", "demo1", "demo2", "demo3"]);

        // });
    });
});

