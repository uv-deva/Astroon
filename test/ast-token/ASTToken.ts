import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import { artifacts, waffle } from "hardhat";
import type { Artifact } from "hardhat/types";

import { ASTToken } from "../../src/types";

export const deployASTTokenContract = async (signer: SignerWithAddress) => {
  const stakingArtifact: Artifact = await artifacts.readArtifact("ASTToken");
  return <ASTToken>await waffle.deployContract(signer, stakingArtifact, []);
};
