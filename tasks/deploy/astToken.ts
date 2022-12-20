import { Signer } from "@ethersproject/abstract-signer";
import { task } from "hardhat/config";
import { TaskArguments } from "hardhat/types";

import { ASTToken } from "../../src/types/contracts/tokens/ASTToken";
import { ASTToken__factory } from "../../src/types/factories/contracts/tokens/ASTToken__factory";
import { readContractAddress, writeContractAddress } from "./addresses/utils";

task("deploy:ASTToken")
  .addParam("signer", "Index of the signer in the metamask address list")
  .setAction(async function (taskArguments: TaskArguments, { ethers }) {
    console.log("--- start deploying the ASTToken Contract ---");
    const accounts: Signer[] = await ethers.getSigners();
    const index = Number(taskArguments.signer);

    // Use accounts[1] as the signer for the real roll
    const ASTTokenFactory: ASTToken__factory = <ASTToken__factory>(
      await ethers.getContractFactory("ASTToken", accounts[index])
    );
    const ASTToken: ASTToken = <ASTToken>await ASTTokenFactory.deploy();

    await ASTToken.deployed();

    writeContractAddress("astToken", ASTToken.address);
    console.log("ASTToken deployed to: ", ASTToken.address);
  });

task("verify:ASTToken").setAction(async function (taskArguments: TaskArguments, { run }) {
  const address = readContractAddress("astToken");
  await run("verify:verify", {
    address,
    constructorArguments: [],
  });
});
