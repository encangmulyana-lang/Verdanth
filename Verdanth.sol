// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
contract Verdanth is ERC721, Ownable, ReentrancyGuard {
    using Strings for uint256;
    uint256 public constant MAX_SUPPLY = 3333;
    uint256 public constant MINT_PRICE = 0.0003 ether;
    uint256 public constant MAX_MINT_PER_WALLET = 10;
    uint256 public totalMinted;
    bool public mintPaused;
    string private _customBaseURI;
    mapping(address => uint256) public mintedByWallet;
    event Minted(address indexed minter, uint256 indexed tokenId);
    event BaseURISet(string baseURI);
    event MintPausedChanged(bool paused);
    constructor(string memory baseURI_) ERC721("Verdanth", "VERDANTH") Ownable(msg.sender) { _customBaseURI = baseURI_; }
    function _baseURI() internal view override returns (string memory) { return _customBaseURI; }
    function currentPrice() public pure returns (uint256) { return MINT_PRICE; }
    function mint(uint256 quantity) external payable nonReentrant {
        require(!mintPaused, "Verdanth: mint paused");
        require(quantity > 0, "Verdanth: quantity 0");
        require(mintedByWallet[msg.sender] + quantity <= MAX_MINT_PER_WALLET, "Verdanth: wallet limit");
        require(totalMinted + quantity <= MAX_SUPPLY, "Verdanth: sold out");
        require(msg.value == MINT_PRICE * quantity, "Verdanth: wrong value");
        for (uint256 i = 0; i < quantity; i++) {
            totalMinted += 1;
            mintedByWallet[msg.sender] += 1;
            _safeMint(msg.sender, totalMinted);
            emit Minted(msg.sender, totalMinted);
        }
    }
    function setBaseURI(string memory baseURI_) external onlyOwner { _customBaseURI = baseURI_; emit BaseURISet(baseURI_); }
    function setMintPaused(bool paused) external onlyOwner { mintPaused = paused; emit MintPausedChanged(paused); }
    function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(ownerOf(tokenId) != address(0), "Verdanth: token does not exist");
        string memory baseURI = _baseURI();
        return bytes(baseURI).length > 0 ? string(abi.encodePacked(baseURI, tokenId.toString(), ".json")) : "";
    }
    function withdraw() external onlyOwner { (bool ok, ) = payable(owner()).call{value: address(this).balance}(""); require(ok, "Verdanth: withdraw failed"); }
}
