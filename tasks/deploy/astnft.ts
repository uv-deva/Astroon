import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ASTNFT, ASTNFT__factory } from "../../src/types";
import { readContractAddress, writeContractAddress } from "./addresses/utils";
import cArguments from "./arguments/astnft";

task("deploy:ASTNftPresale")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers, upgrades }) {
    console.log("--- start deploying the AST NFT Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index = Number(taskArguments.signer);

    // Use accounts[1] as the signer for the real roll
    const nftFactory: ASTNFT__factory = <ASTNFT__factory>await ethers.getContractFactory("ASTNftPresale", accounts[index]);

    const astNFTProxy: ASTNFT = <ASTNFT>(
      await upgrades.deployProxy(nftFactory, [cArguments.Name, cArguments.symbol, cArguments.TOKENURIPREFIX, cArguments.tokenAddress, cArguments.baseExtension, cArguments.maxPresaleLimt, cArguments.maxPresaleLimt], {
        initializer: "initialize",
      })
    );
    await astNFTProxy.deployed();
    writeContractAddress("astNFT", astNFTProxy.address);
    console.log("AST NFT  deployed to: ", astNFTProxy.address);
  });

task("verify:ASTNFT")
  .addParam("contractAddress", "Input the deployed contract address")
  .setAction(async function (taskArguments: TaskArguments, { run }) {
    await run("verify:verify", {
      address: "0xa205a2B01E8A1A3f47C12158129EC7384224B222",
      constructorArguments: [cArguments.Name, cArguments.symbol, cArguments.TOKENURIPREFIX, cArguments.tokenAddress, cArguments.baseExtension, cArguments.maxPresaleLimt, cArguments.maxPresaleLimt],
    });
  });
