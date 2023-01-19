// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/IERC721EnumerableUpgradeable.sol";

interface IASTNftSale is IERC721EnumerableUpgradeable {
    function getCategory(
        uint256 tokenId
    ) external view returns (uint8);

    function getLastPurchaseTime(
        uint256 tokenId,
        address user
    ) external view returns (uint256);

    function checkTokenRewardEligibility(
        uint256 _tokenId
    ) external view returns (bool IsEligible);

    function getRevealedTime() external view returns (uint256);
}