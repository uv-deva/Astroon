import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ASTILO__factory } from "../../src/types/factories/contracts/ASTILO__factory";
import { readContractAddress, writeContractAddress } from "./addresses/utils";
import cArguments from "./arguments/astilo";
task("deploy:ASTILO")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers, upgrades }) {
    console.log("--- start deploying the AST ILO Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index = Number(taskArguments.signer);

    // Use accounts[1] as the signer for the real roll
    const ico: ASTILO__factory = <ASTILO__factory>(
      await ethers.getContractFactory("ASTILO", accounts[index])
    );

    const icoProxy = await upgrades.deployProxy(ico,[cArguments.TOKENADDR, cArguments.INITIAL_SUPPLY]);
    await icoProxy.deployed();
    writeContractAddress("astILO", icoProxy.address);
    console.log("AST ILO proxy deployed to: ", icoProxy.address);

    const impl = await upgrades.erc1967.getImplementationAddress(icoProxy.address);
    console.log("Implementation :", impl);
  });

task("upgrade:ASTILO")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers, upgrades }) {
    console.log("--- start upgrading the AST ILO Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index = Number(taskArguments.signer);

    // Use accounts[1] as the signer for the real roll
    const icoProxy: ASTILO__factory = <ASTILO__factory>(
      await ethers.getContractFactory("ASTILO", accounts[index])
    );

    const proxyMarketPlaceAddress = readContractAddress("astILO");

    const upgraded = await upgrades.upgradeProxy(proxyMarketPlaceAddress, icoProxy);

    console.log("AST ILO upgraded to: ", upgraded.address);

    const impl = await upgrades.erc1967.getImplementationAddress(upgraded.address);
    console.log("Implementation :", impl);
  });

task("verify:ASTILO")
  .addParam("contractAddress", "Input the deployed contract address")
  .setAction(async function (taskArguments: TaskArguments, { run }) {
    await run("verify:verify", {
      address: taskArguments.contractAddress,
      constructorArguments: [],
    });
  });
