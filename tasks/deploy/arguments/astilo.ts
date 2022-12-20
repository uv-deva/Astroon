import { readContractAddress } from "../addresses/utils";

const TOKENADDR = readContractAddress("astToken");
const INITIAL_SUPPLY = "10000000000000000000000";

const values = {
  TOKENADDR,
  INITIAL_SUPPLY,
};

export default values;
