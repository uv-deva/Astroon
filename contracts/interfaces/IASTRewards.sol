// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IASTRewards {
    function getRewardsCalc(
        uint8 _category,
        uint256 _id,
        address _addr
    ) external view returns (uint256);

    function updateRewardAmount(
        address _addr,
        uint256 rewardAmount
    ) external;
}