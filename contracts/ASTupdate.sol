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
import "@openzeppelin/contracts/utils/Strings.sol";


contract ASTNftPresale is
    Initializable,
    ERC721Upgradeable,
    ERC721URIStorageUpgradeable,
    ERC721EnumerableUpgradeable,
    PausableUpgradeable,
    OwnableUpgradeable,
    ERC721BurnableUpgradeable,
    ERC2981Upgradeable
{
    using Strings for uint256;
    using CountersUpgradeable for CountersUpgradeable.Counter;
    CountersUpgradeable.Counter private tokenIdCount;

    uint256 private saleId;
    string public baseURI;
    string public notRevealedUri;
    string public baseExtension = ".json";
    bool public presaleM;
    bool public publicM;
    bool public revealed = false;
    address private recipent;

    struct SaleInfo {
        uint256 cost;
        uint256 mintCost;
        uint256 maxSupply;
        uint256 start;
        uint256 _days;
        bool goalReached;
    }

    struct UserInfo {
        uint256 tokens;
        uint256 limit;
        uint256 limitRemain;
        uint256 purchaseAt;
        uint256 lastbuy;
        bool whitelisted;
    }

    // Events
    event SaleStart(uint256 saleId);
    event BoughtNFT(address indexed to, uint256 amount, uint256 saleId);

    // Mapping
    mapping(uint256 => SaleInfo) public SaleInfoMap; // sale mapping
    mapping(address => UserInfo) public UserInfoMap; // user mapping
    mapping(uint256=>uint256[]) public tierMap;

    function initialize(
        string memory _name,
        string memory _symbol,
        string memory _baseUri
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
    }

    function togglePreSale() external onlyOwner {
        presaleM = !presaleM;
    }

    function togglePublicSale() external onlyOwner {
        publicM = !publicM;
    }

    // Start Sale
    function startSale(
        uint256 _cost,
        uint256 _mintCost,
        uint256 _maxSupply,
        uint256 _start,
        uint256 _days
    ) external onlyOwner returns (uint256) {
        saleId++;
        SaleInfoMap[saleId] = SaleInfo (
            _cost,
            _mintCost,
            _maxSupply,
            _start,
            _days,
            false
        );
        emit SaleStart(saleId);
        return saleId;
    }

    function setTireMap(uint _amount, uint _min, uint _max) external onlyOwner {
        tierMap[_amount][0] = _min;
        tierMap[_amount][1] = _max;
    }
    

    // Eligibility Criteria
    function checking(address _addr, uint256 _amount) internal view returns (uint256) {
        uint256 bal = balanceOf(_addr);
        require(bal >= 200, "Insufficient balance");
        uint256 count;
        require(tierMap[_amount][0] >= bal && tierMap[_amount][1]<=bal, "not enough balance for purchase");
        if(_amount == 1){
            count=1;
        } else if(_amount == 2){
            count=2;
        } else if(_amount==3){
            count=3;
        }

        // tierMap[1]=[100,300];
        // tierMap[2]=[301,600];
        // tierMap[3]=[601,800];

        UserInfo memory user = UserInfoMap[_addr];
        user.limit = user.lastbuy == 0 ? count: count - user.tokens;
        user.purchaseAt = bal;
        user.whitelisted = true;
        return user.limit;
    }

    // Presale Buy
    function buyPresale(uint256 _amount) external payable {
        require(presaleM, "Sale is off");
        uint256 buylimit = checking(_msgSender(), _amount);
        require(_amount <= buylimit, "buying limit exceeded");
        SaleInfo memory details = SaleInfoMap[saleId];
        UserInfo memory user = UserInfoMap[_msgSender()];

        require(
            msg.value >= (_amount * (details.cost + details.mintCost)),
            "Insufficient value"
        );
        require(
            tokenIdCount.current() + _amount <= details.maxSupply,
            "Not enough tokens"
        );
        user.tokens += _amount;
        user.lastbuy = block.timestamp;
        user.limitRemain = buylimit - _amount;
        // user.
        uint256 i = 1;
        while (i <= _amount) {
            tokenIdCount.increment();
            uint256 _id = tokenIdCount.current();
            _safeMint(_msgSender(), _id);
            string memory _tokenURI = tokenURI(_id);
            _setTokenURI(_id, _tokenURI);
            i++;
        }
        emit BoughtNFT(_msgSender(), _amount, saleId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override (ERC721Upgradeable) {
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

    function setCost(uint256 _saleId, uint256 _newCost) external onlyOwner {
        SaleInfoMap[_saleId].cost = _newCost;
    }

    function setMintCost(
        uint256 _saleId,
        uint256 _newMintCost
    ) external onlyOwner {
        SaleInfoMap[_saleId].mintCost = _newMintCost;
    }

    function goalReached(uint256 _saleId) public view returns (bool) {
        SaleInfo memory detail = SaleInfoMap[_saleId];
        return (tokenIdCount.current() == detail.maxSupply);
    }

    function isActive(uint256 _saleId) external view returns (bool) {
        SaleInfo memory detail = SaleInfoMap[_saleId];
        return (block.timestamp >= detail.start && // Must be after the start date
            block.timestamp <= detail.start + (detail._days * 1 days) && // Must be before the end date
            goalReached(_saleId) == false); // Goal must not already be reached
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