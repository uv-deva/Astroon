import type { SignerWithAddress } from "@nomiclabs/hardhat-ethers/dist/src/signer-with-address";

import type { ASTNftPresale } from "../types/ASTNftPresale";

type Fixture<T> = () => Promise<T>;

declare module "mocha" {
  export interface Context {
    ASTNftPresale: ASTNftPresale;
    loadFixture: <T>(fixture: Fixture<T>) => Promise<T>;
    signers: Signers;
  }
}

export interface Signers {
  admin: SignerWithAddress;
}
