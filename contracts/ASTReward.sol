// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC20/IERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "./interfaces/IASTNftSale.sol";
import "./libraries/DateTime.sol";

contract ASTTokenRewards is OwnableUpgradeable, PausableUpgradeable, ReentrancyGuardUpgradeable, DateTime {
    IASTNftSale public nftContract;
    IERC20Upgradeable public token;
    IASTNftSale public _astNftsale;

    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }

    struct UserTokenDetails {
        uint256 lastRewardCliamed;
        uint256 totalRewardsClaimed;
        uint256 toClaim;
        uint256 dueRewards;
    }

    mapping(address => UserTokenDetails) public userTokenDetailsMap;
    mapping(uint256 => mapping(CATEGORY => uint256)) public RewardsMap; //year to category to rewardAmount
    mapping(uint256 => uint256) lastClaimOftoken; //tokenid to timestamp
    mapping(uint256 => uint256) WithdrawlMap; //month to withdrawl limit

    event HoldingRewardsClaimed(uint256 tokenId, uint256 rewards, CATEGORY _category);
    event TotalRewardsClaimed(address _user, uint256 totalRewards, uint256 SoldTokensRewards);

    function initialize(
        address _nftaddress,
        address _AstTokenAddr
    )
        public
        initializer
    {
        nftContract = IASTNftSale(_nftaddress);
        token = IERC20Upgradeable(_AstTokenAddr);
        _astNftsale = IASTNftSale(_nftaddress);
        RewardsMap[1][CATEGORY.BRONZE] = 1 * 10**18;
        RewardsMap[1][CATEGORY.SILVER] = 2 * 10**18;
        RewardsMap[1][CATEGORY.GOLD] = 3 * 10**18;
        RewardsMap[1][CATEGORY.PLATINUM] = 4 * 10**18;

        RewardsMap[2][CATEGORY.BRONZE] = (1 / 2) * 10**18;
        RewardsMap[2][CATEGORY.SILVER] = ((2 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.GOLD] = ((3 * 1) / 2) * 10**18;
        RewardsMap[2][CATEGORY.PLATINUM] = ((4 * 1) / 2) * 10**18;

        RewardsMap[3][CATEGORY.BRONZE] = ((1 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.SILVER] = ((2 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.GOLD] = ((3 * 1) / 4) * 10**18;
        RewardsMap[3][CATEGORY.PLATINUM] = ((4 * 1) / 4) * 10**18;

        WithdrawlMap[2] = 100 * 10**18;
        WithdrawlMap[3] = 200 * 10**18;
        WithdrawlMap[4] = 300 * 10**18;
        WithdrawlMap[5] = 300 * 10**18;
        WithdrawlMap[6] = 750 * 10**18;
        WithdrawlMap[7] = 750 * 10**18;
        WithdrawlMap[8] = 750 * 10**18;
        WithdrawlMap[9] = 750 * 10**18;
        WithdrawlMap[10] = 1500 * 10**18;
        WithdrawlMap[11] = 1500 * 10**18;
        WithdrawlMap[12] = 2500 * 10**18;

        __Ownable_init();
        __Pausable_init();
    }

    function claim()
        external
        nonReentrant
        whenNotPaused
    {
        address user = msg.sender;
        uint256 rewards;
        uint256 nftBalance = nftContract.balanceOf(user);
        UserTokenDetails storage userDetails = userTokenDetailsMap[msg.sender];
        for (uint256 i; i < nftBalance; i++) {
            uint256 id = nftContract.tokenOfOwnerByIndex(user, i);
            bool IsEligible = nftContract.checkTokenRewardEligibility(id);
            if (IsEligible) {
                uint8 x = uint8(nftContract.getCategory(id));
                uint256 amount = getRewardsCalc(x, id);
                lastClaimOftoken[id] = block.timestamp;
                uint256 _rewards = amount;
                rewards += amount;
                emit HoldingRewardsClaimed(id, _rewards, CATEGORY(x));
            }
        }
        uint256 CanClaimRewards = rewards + userDetails.toClaim + userDetails.dueRewards;

        uint256 _allowedWithdrawl = allowedWithdraw(); // allowed this month
        uint256 actualClaimedRewards = CanClaimRewards > _allowedWithdrawl ? _allowedWithdrawl : CanClaimRewards;
        uint256 dueRewards = CanClaimRewards > _allowedWithdrawl ? CanClaimRewards - _allowedWithdrawl : 0;

        userDetails.lastRewardCliamed = actualClaimedRewards;
        userDetails.totalRewardsClaimed += actualClaimedRewards;
        userDetails.dueRewards = dueRewards;
        userDetails.toClaim = 0;
        require(actualClaimedRewards != 0, "No Rewards");
        token.transfer(user, actualClaimedRewards);
        emit TotalRewardsClaimed(user, actualClaimedRewards, userDetails.toClaim);
    }

    function getRewardsCalc(
        uint8 _category,
        uint256 _id
    )
        public
        view
        returns (uint256 rewardAmount)
    {
        CATEGORY category = CATEGORY(_category);
        uint256 purchaseTime = nftContract.getRevealedTime();
        uint256 timeDuration = block.timestamp - purchaseTime;
        uint256 dayCount = timeDuration / 1 days;
        if (dayCount != 0) {
            rewardAmount = dayCount <= 365 ? dayCount * RewardsMap[1][category] : (dayCount > 365 && dayCount <= 730)
                ? (365 * RewardsMap[1][category]) + ((dayCount - 365) * RewardsMap[2][category])
                : dayCount > 730 && dayCount <= 1095
                ? (365 * RewardsMap[1][category]) +
                    (365 * RewardsMap[2][category]) +
                    ((dayCount - 730) * RewardsMap[3][category])
                : (365 * RewardsMap[1][category]) + (365 * RewardsMap[2][category]) + (365 * RewardsMap[3][category]);
        }
        if (lastClaimOftoken[_id] > purchaseTime) {
            uint256 claimDays = (lastClaimOftoken[_id] - purchaseTime) / 1 days;
            uint256 claimedAmount = claimDays <= 365
                ? claimDays * RewardsMap[1][category]
                : claimDays > 365 && claimDays <= 730
                ? (365 * RewardsMap[1][category]) + (claimDays * RewardsMap[2][category])
                : claimDays > 730 && claimDays <= 1095
                ? (365 * RewardsMap[1][category]) +
                    (365 * RewardsMap[2][category]) +
                    (claimDays * RewardsMap[3][category])
                : (365 * RewardsMap[1][category]) + (365 * RewardsMap[2][category]) + (365 * RewardsMap[3][category]);
            rewardAmount -= claimedAmount;
        }
    }

    function updateRewardAmount(
        address _addr,
        uint256 rewardAmount
    )
        external
        returns (bool)
    {
        require(address(nftContract) == msg.sender, "Invalid Caller");
        UserTokenDetails storage userDetails = userTokenDetailsMap[_addr];
        userDetails.toClaim += rewardAmount;
        return true;
    }

    function setWithdrawalLimits(
        uint256 _month,
        uint256 _limit
    )
        external
        onlyOwner
    {
        WithdrawlMap[_month] = _limit;
    }

    function setRewardsMap(
        uint256 _rewards,
        uint256 _year,
        CATEGORY _x
    ) 
        external
        onlyOwner
    {
        RewardsMap[_year][_x] = _rewards * 10**18;
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function allowedWithdraw()
        internal
        view
        returns (uint256)
    {
        uint256 currMonth = DateTime.getMonth(block.timestamp);
        return WithdrawlMap[currMonth];
    }

    function withdrawAmount()
        public
        onlyOwner
    {
        (bool success, ) = payable(_msgSender()).call{ value: address(this).balance }("");
        require(success);
    }

    function withdrawToken(
        address admin,
        address _paymentToken
    )
        external
        onlyOwner
    {
        IERC20Upgradeable _token = IERC20Upgradeable(_paymentToken);
        uint256 amount = _token.balanceOf(address(this));
        token.transfer(admin, amount);
    }
}
