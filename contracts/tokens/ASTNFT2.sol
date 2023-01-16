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


contract ASTNftPresale1 is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{

    enum SALETYPE {PRIVATE_SALE, PUBLIC_SALE}
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIdCount;

    IERC20MetadataUpgradeable token;

    uint256 private saleId;
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    bool public revealed ;
    uint256 maxPresaleLimit = 4;
    uint256 minToken = 110;

    struct SaleInfo {
        uint256 cost;
        uint256 mintCost;
        uint256 maxSupply;
        uint256 startTime;
        uint256 endTime;
    }

    // Events
    event SaleStart(uint256 saleId);
    event BoughtNFT(address indexed to, uint256 amount, uint256 saleId);

    // Mapping
    mapping(SALETYPE => SaleInfo) public SaleInfoMap; // sale mapping
    mapping(uint256=>uint256[]) public tierMap;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri,
        address _tokenAddr
    ) public initializer {
        __ERC721_init(_name, _symbol);
        __ERC721URIStorage_init();
        __ERC721Enumerable_init();
        __Pausable_init();
        __Ownable_init();
        __ERC721Burnable_init();
        __ERC2981_init();
        __ERC2981_init_unchained();
        baseURI = _baseUri;
        token = IERC20MetadataUpgradeable(_tokenAddr);
    }

    function setMaxPreSaleLimit(uint256 _presaleLimit) external onlyOwner {
        maxPresaleLimit = _presaleLimit;
    }

    // Start Sale
    function startSale(
        SALETYPE saleType,
        uint256 _cost,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _startTime,
        uint256 _endTime
    ) external onlyOwner returns (uint256) {
        SaleInfoMap[saleType] = SaleInfo (
            _cost,
            _mintCost,
            _maxSupply,
            _startTime,
            _endTime
        );
        emit SaleStart(saleId);
        return saleId;
    }

    function setTireMap(uint category, uint _min, uint _max) external onlyOwner {
        tierMap[category][0] = _min;
        tierMap[category][1] = _max;
    }
    
    function setMinimumToken(uint256 _minToken) external onlyOwner {
        minToken = _minToken;
    }

    function validateNftLimit(address _addr, uint256 nftQty) internal view {
        uint256 tokenBalance = token.balanceOf(_addr);
        uint256 nftBalance = balanceOf(_addr);
        require (
            tokenBalance >= minToken*10**token.decimals(),
            "Insufficient balance"
        );
        require (
            nftBalance + nftQty <= maxPresaleLimit,
            "buying limit exceeded"
        );
        uint256 count = tokenBalance >= tierMap[1][0] && tokenBalance <= tierMap[1][1] ? 1 
            : tokenBalance >= tierMap[2][0] && tokenBalance <= tierMap[2][1] ? 2 
            : tokenBalance >= tierMap[3][0] && tokenBalance <= tierMap[3][1] ? 3 
            : 4;
        require(
            count >= nftBalance && (count - nftBalance) >= nftQty,
            "buying Limit exceeded"
        );
    }

    function buyPresale(uint256 nftQty) external payable {
        require(
            SaleInfoMap[SALETYPE.PRIVATE_SALE].startTime >= block.timestamp && 
            SaleInfoMap[SALETYPE.PRIVATE_SALE].endTime <= block.timestamp,
            "PrivateSale is InActive"
        );
        SaleInfo memory details = SaleInfoMap[SALETYPE.PRIVATE_SALE];
        validateNftLimit(_msgSender(), nftQty);
        require(
            msg.value == (nftQty * (details.cost + details.mintCost)),
            "Insufficient value"
        );
        require(
            tokenIdCount.current() + nftQty <= details.maxSupply,
            "Not enough tokens"
        );
        for(uint256 i; i < nftQty;) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            i++;
        }
        payable(owner()).transfer(msg.value);
        emit BoughtNFT(_msgSender(), nftQty, saleId);
    }

    function buyPublicSale(uint256 _amount) external payable {
        require(
            SaleInfoMap[SALETYPE.PUBLIC_SALE].startTime >= block.timestamp &&
            SaleInfoMap[SALETYPE.PUBLIC_SALE].endTime <= block.timestamp,
            "PublicSale is InActive"
        );
        SaleInfo memory detail = SaleInfoMap[SALETYPE.PUBLIC_SALE];
        require(
            msg.value == (_amount * (detail.cost + detail.mintCost)),
            "Insufficient value"
        );
        for (uint256 i = 0 ; i < _amount;) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            string memory _tokenURI = tokenURI(_id);
            _setTokenURI(_id, _tokenURI);
            i++;
        }
        payable(owner()).transfer(msg.value);
        emit BoughtNFT(_msgSender(), _amount, saleId);

    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override (ERC721Upgradeable, IERC721Upgradeable) {
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
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

    function reveal() external onlyOwner {
        revealed = true;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseURI;
    }

    function setBaseURI(string memory _newBaseURI) external onlyOwner {
        baseURI = _newBaseURI;
    }

    function setNotRevealedURI(string memory _notRevealedURI) external onlyOwner {
        notRevealedUri = _notRevealedURI;
    }

    function setBaseExtension(
        string memory _newBaseExtension
    ) external onlyOwner {
        baseExtension = _newBaseExtension;
    }

    function setCost(SALETYPE saleType, uint256 _newCost) external onlyOwner {
        SaleInfoMap[saleType].cost = _newCost;
    }

    function setMintCost(
        SALETYPE saleType,
        uint256 _newMintCost
    ) external onlyOwner {
        SaleInfoMap[saleType].mintCost = _newMintCost;
    }

    function isActive(SALETYPE saleType) external view returns (bool) {
        SaleInfo memory detail = SaleInfoMap[saleType];
        return (block.timestamp >= detail.startTime && // Must be after the start date
            block.timestamp <= detail.endTime // Must be before the end date
        );
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function withdrawAmount() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function _burn(
        uint256 tokenId
    ) internal override(ERC721Upgradeable, ERC721URIStorageUpgradeable) {
        super._burn(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721Upgradeable, ERC721EnumerableUpgradeable, ERC2981Upgradeable)
        returns (bool) 
    {
        return super.supportsInterface(interfaceId);
    }

}