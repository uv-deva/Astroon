// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721URIStorageUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721EnumerableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/security/PausableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/extensions/ERC721BurnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/CountersUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/common/ERC2981Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC20/extensions/IERC20MetadataUpgradeable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./interfaces/IASTNftSale.sol";
import "./interfaces/IASTRewards.sol";

contract ASTNFTSale is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    enum CATEGORY {
        BRONZE,
        SILVER,
        GOLD,
        PLATINUM
    }
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIdCount;

    IERC20MetadataUpgradeable public token;

    string public baseURI;
    string public notRevealedUri;
    string public baseExtension;
    bool public revealed;
    uint256 maxPresaleLimit;
    uint256 minToken;
    uint256 private saleId;
    uint256 private revealedTime;
    IASTRewards public astRewards;
    bool public rewardEnable;

    struct SaleInfo {
        uint256 cost;
        uint256 mintCost;
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
        uint256 remainingSupply;
    }


    struct tierInfo {
        uint256 minValue;
        uint256 maxValue;
    }

    // Events
    event SaleStart(
        uint256 saleId
    );
    event BoughtNFT(
        address indexed to,
        uint256 amount,
        uint256 saleId
    );

    // Mapping
    mapping(uint256 => CATEGORY) categoryOf; // ID to category
    mapping(CATEGORY => uint256[]) tokensByCategory; // array of token IDs
    mapping(uint256 => SaleInfo) public SaleDetailMap;
    mapping(uint256 => tierInfo) public tierMap; // tier mapping



    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _tokenAddr,
        string memory _baseExtension,
        uint256 _maxPresaleLimit,
        uint256 _minToken,
        address _receiverAddress,
        uint96 _royaltyAmt
    )
        public
        initializer
    {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ERC2981_init();
        __ERC2981_init_unchained();
        baseURI = _baseUri;
        baseExtension = _baseExtension;
        maxPresaleLimit = _maxPresaleLimit;
        minToken = _minToken;
        token = IERC20MetadataUpgradeable(_tokenAddr);
        saleId = 1;
        rewardEnable = true;
        _setDefaultRoyalty(_receiverAddress, _royaltyAmt);
        tierMap[1].minValue = 100 * 10 ** 18;
        tierMap[1].maxValue = 300 * 10 ** 18;
        tierMap[2].minValue = (300 * 10 ** 18) + 1;
        tierMap[2].maxValue = 600 * 10 ** 18;
        tierMap[3].minValue = (600 * 10 ** 18) + 1;
        tierMap[3].maxValue = 800 * 10 ** 18;
    }

    function setMaxPreSaleLimit(
        uint256 _presaleLimit
    )
        external
        onlyOwner
    {
        maxPresaleLimit = _presaleLimit;
    }


    // Start Sale
    function startPreSale(
        uint256 _cost,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _startTime,
        uint256 _endTime
    )
        external
        onlyOwner
        returns(uint256)
    {
        SaleDetailMap[saleId] = SaleInfo(
            _cost,
            _mintCost,
            _maxSupply,
            _startTime,
            _endTime,
            _maxSupply
        );
        emit SaleStart(saleId);
        return saleId;
    }

    function setRoyalty(
        address _receiver,
        uint96 _royaltyAmt
    )
        external
        onlyOwner
    {
        _setDefaultRoyalty(
            _receiver,
            _royaltyAmt);
    }

    function setRevealed()
        external
        onlyOwner
    {
        revealed = !revealed;
    }

    function setMinimumToken(
        uint256 _minToken
    )
        external
        onlyOwner
    {
        minToken = _minToken;
    }

    function getCategory(
        uint256 tokenId
    )
        external
        view
        returns(CATEGORY)
    {
        return categoryOf[tokenId];
    }

    function getAllTokenByCategory(
        CATEGORY nftType
    )
        external
        view
        returns(uint256[] memory)
    {
        return tokensByCategory[nftType];
    }

    function setRewardContract(
        IASTRewards _astRewards
    )
        external
        onlyOwner
    {
        astRewards = _astRewards;
    }

    function updateCategory(
        CATEGORY[] memory _category,
        uint256[] memory _id
    )
        external
        onlyOwner
    {
        require(_category.length == _id.length, "Invalid length");
        for (uint256 i; i < _category.length; i++) {
            categoryOf[_id[i]] = _category[i];
            tokensByCategory[_category[i]].push(_id[i]);
        }
    }

    function UpdateTokenAddress(
        address _tokenAddr
    )
        external
        onlyOwner
    {
        token = IERC20MetadataUpgradeable(_tokenAddr);
    }

    function setTireMap(
        uint256 _tierLevel,
        uint256 _min,
        uint256 _max
    )
        external
        onlyOwner
    {
        tierMap[_tierLevel].minValue = _min;
        tierMap[_tierLevel].maxValue = _max;
    }

    function validateNftLimit(
        address _addr,
        uint256 nftQty
    )
        internal
        view
    {
        uint256 tokenBalance = token.balanceOf(_addr);
        uint256 nftBalance = balanceOf(_addr);
        require(
            tokenBalance >= minToken,
            "Insufficient balance"
        );
        require(
            nftBalance + nftQty <= maxPresaleLimit,
            "buying Limit exceeded"
        );
        uint256 count = tokenBalance >= tierMap[1].minValue &&
            tokenBalance <= tierMap[1].maxValue
            ? 1
            : tokenBalance >= tierMap[2].minValue &&
                tokenBalance <= tierMap[2].maxValue
            ? 2
            : tokenBalance >= tierMap[3].minValue &&
                tokenBalance <= tierMap[3].maxValue
            ? 3
            : 4;

        require(
            count >= nftBalance && (count - nftBalance) >= nftQty,
            "buying Limit exceeded"
        );
    }

    function buyPresale(
        uint256 nftQty
    )
        external
        payable
    {
        require(
            SaleDetailMap[saleId].startTime <= block.timestamp &&
            SaleDetailMap[saleId].endTime >= block.timestamp,
            "PrivateSale is InActive"
        );

        validateNftLimit(
            _msgSender(),
            nftQty
        );
        require(
            msg.value == (nftQty * (SaleDetailMap[saleId].cost + SaleDetailMap[saleId].mintCost)),
            "Insufficient value"
        );
        require(
            tokenIdCount.current() + nftQty <= SaleDetailMap[saleId].maxSupply,
            "Not enough tokens"
        );
        SaleDetailMap[saleId].remainingSupply -= nftQty;
        for (uint256 i; i < nftQty; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            i++;
        }
        payable(owner()).transfer(msg.value);
        emit BoughtNFT(_msgSender(), nftQty, saleId);
    }

    function mint(
        CATEGORY[] memory _category,
        string[] memory _tokenURI
    )
        external
        onlyOwner
    {
        require(
            _category.length == _tokenURI.length,
            "Invalid Length"
        );
        for (uint256 i; i < _category.length; ) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            categoryOf[_id] = _category[i];
            tokensByCategory[_category[i]].push(_id);
            i++;
        }
    }

    function setRewardStatus()
        external
        onlyOwner
    {
        rewardEnable = !rewardEnable;
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    )
        public
        override(ERC721Upgradeable, IERC721Upgradeable)
    {
        require(
            _isApprovedOrOwner(
                _msgSender(),
                tokenId
            ),
            "ERC721: caller is not token owner nor approved"
        );
        _safeTransfer(from, to, tokenId, "");
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId,
        uint256 batchSize
    )
        internal
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable)
        whenNotPaused
    {
        if (rewardEnable && from != address(0) && checkTokenRewardEligibility(tokenId)) {
            uint256 _rewards = astRewards.getRewardsCalc(uint8(categoryOf[tokenId]), tokenId, from);
            astRewards.updateRewardAmount(from, _rewards);
        }
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function tokenURI(
        uint256 tokenId
    )
        public
        view
        virtual
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
        returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        if (revealed == false) {
            return notRevealedUri;
        }

        string memory currentBaseURI = _baseURI();
        return
            bytes(currentBaseURI).length > 0
                ? string(
                    abi.encodePacked(
                        currentBaseURI,
                        tokenId.toString(),
                        baseExtension
                    )
                )
                : "";
    }

    function reveal()
        external
        onlyOwner
    {
        revealed = true;
        revealedTime = block.timestamp;
    }

    function _baseURI()
        internal
        view
        virtual
        override
        returns(string memory)
    {
        return baseURI;
    }

    function setBaseURI(
        string memory _newBaseURI
    )
        external
        onlyOwner
    {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(
        string memory _notRevealedURI
    )
        external
        onlyOwner
    {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    )
        external
        onlyOwner
    {
        baseExtension = _newBaseExtension;
    }

    function setCost(
        uint256 _saleId,
        uint256 _newCost
    )
        external onlyOwner {
        SaleDetailMap[_saleId].cost = _newCost;
    }

    function setMintCost(
        uint256 _saleId,
        uint256 _newMintCost
    )
        external
        onlyOwner
    {
        SaleDetailMap[_saleId].mintCost = _newMintCost;
    }

    function isActive()
        external
        view
        returns(bool)
    {
        SaleInfo memory detail = SaleDetailMap[saleId];
        return (block.timestamp >= detail.startTime && // Must be after the start date
            block.timestamp <= detail.endTime); // Must be before the end date
    }

    function pause()
        external
        onlyOwner
    {
        _pause();
    }

    function unpause()
        external
        onlyOwner
    {
        _unpause();
    }

    function withdrawAmount()
        external
        onlyOwner
    {
        payable(owner()).transfer(address(this).balance);
    }

    function _burn(
        uint256 tokenId
    )
        internal
        override(ERC721Upgradeable, ERC721URIStorageUpgradeable)
    {
        super._burn(tokenId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    function checkTokenRewardEligibility(
        uint256 _tokenId
    )
        public
        view
        returns(bool IsEligible)
    {
        if (_tokenId >= 1 && _tokenId <= 2400 && block.timestamp < revealedTime + 1095 days) {
            IsEligible = true;
        }
    }

    function getRevealedTime()
        external
        view
        returns(uint256)
    {
        return revealedTime;
    }
}