import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ASTNFT, ASTNFT__factory } from "../../src/types";
import { readContractAddress, writeContractAddress } from "./addresses/utils";
import cArguments from "./arguments/astnft";

task("deploy:ASTNFT")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers, upgrades }) {
    console.log("--- start deploying the AST NFT Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index = Number(taskArguments.signer);

    // Use accounts[1] as the signer for the real roll
    const nftFactory: ASTNFT__factory = <ASTNFT__factory>await ethers.getContractFactory("ASTNFT", accounts[index]);

    const astNFTProxy: ASTNFT = <ASTNFT>(
      await nftFactory.deploy(cArguments.TOKENURIPREFIX, cArguments.CONTRACTURI)
    );
    await astNFTProxy.deployed();
    writeContractAddress("astNFT", astNFTProxy.address);
    console.log("AST NFT  deployed to: ", astNFTProxy.address);
  });

task("verify:ASTNFT")
  .addParam("contractAddress", "Input the deployed contract address")
  .setAction(async function (taskArguments: TaskArguments, { run }) {
    await run("verify:verify", {
      address: taskArguments.contractAddress,
      constructorArguments: [cArguments.TOKENURIPREFIX, cArguments.CONTRACTURI],
    });
  });
