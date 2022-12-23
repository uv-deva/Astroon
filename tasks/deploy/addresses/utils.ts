import { config as dotenvConfig } from "dotenv";
import * as fs from "fs";
import * as path from "path";

dotenvConfig({ path: path.resolve(__dirname, "../../../.env") });

console.log("DEPLOY_NETWORK: ", process.env.DEPLOY_NETWORK);
type FileName =
   "astToken" | "astNFT" | "astILO"
  ;

const network = () => {
  const { DEPLOY_NETWORK } = process.env;
  if (!DEPLOY_NETWORK || DEPLOY_NETWORK === "hardhat") return "hardhat";
  if (DEPLOY_NETWORK) return DEPLOY_NETWORK;
  return "mainnet";
};

export const writeContractAddress = (contractFileName: FileName, address: string) => {
  const NETWORK = network();

  fs.writeFileSync(
    path.join(__dirname, `${NETWORK}/${contractFileName}.json`),
    JSON.stringify({
      address,
    }),
  );
};

export const readContractAddress = (contractFileName: FileName): string => {
  const NETWORK = network();

  const rawData = fs.readFileSync(path.join(__dirname, `${NETWORK}/${contractFileName}.json`));
  const info = JSON.parse(rawData.toString());

  return info.address;
};
