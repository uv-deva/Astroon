
import { expect } from "chai";
import hre from "hardhat";
import { ethers } from "hardhat"

describe("ASTILO", () => {

    it("check owner", async () => {
        const [owner] = await ethers.getSigners();
        const token = await hre.ethers.getContractFactory("ASTILO");
        const ASToken = await token.deploy()
        const hardhatToken = ASToken.calculateToken(1000,780000000000000);
        expect(await hardhatToken).to.equal(12820512.8205);
        
    })

   // 780000000000

//     rate 780000000000000
// initial tokens 10000000000000000000000000000000000000000
// start 1669980600  2 dec 17:00 (5  pm )
// cap 7800000000000000000
// threshold 10*10^18   10000000000000000000
// cliff 1670221800     5 dec 12 pm
// vesting 10


// sale presale

// token supply = 10000
// rate = 780000000000000
})
 

