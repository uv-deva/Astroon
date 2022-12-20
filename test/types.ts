import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";
import type { Fixture } from "ethereum-waffle";
import { Signer } from "ethers";

import {
  ASTToken  
} from "../src/types";

declare module "mocha" {
  export interface Context {
    ASTToken: ASTToken;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}

export interface Signers {
  admin: SignerWithAddress;
  bob: SignerWithAddress;
  alice: SignerWithAddress;

  bhupat: SignerWithAddress;
  akshay: SignerWithAddress;
  priyanshu: SignerWithAddress;
  treasury: SignerWithAddress;
  validator: Signer;
}
