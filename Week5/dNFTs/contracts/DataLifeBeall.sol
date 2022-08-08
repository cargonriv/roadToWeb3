// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";
import "@chainlink/contracts/src/v0.8/KeeperCompatible.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract DataLifeBeall is ERC721, ERC721Enumerable, ERC721URIStorage, VRFConsumerBase, KeeperCompatibleInterface, ChainlinkClient,  Ownable {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIdCounter;
  AggregatorV3Interface public priceFeed;
  uint public /*immutable*/ interval;
  uint public lastTimeStamp;
  int256 public currentPrice;
  string public dl_json_url;
  uint256 public randomId;
  string public idString;

  bytes32 private keyHash;
  uint256 private linkFee;
  address private oracle;
  bytes32 private jobId;

  struct Collectible {
    string CO_SEXO;
    string CO_REGION;
    string CO_CLASIFICACION;
    string FE_MUERTE;
    string TX_GRUPO_EDAD;
  }

  // MAPPINGS GO DOWN BELOW
  Collectible[] public collectibles;
  event TokensUpdated(string marketTrend);
  event ReturnedCollectible(string idString);
  event RequestedRandomness(bytes32 requestId);
  mapping(bytes32 => uint256) requestToTokenId;
  mapping(bytes32 => address) requestToSender;

  string[] bullUrisIpfs = [
    "https://ipfs.io/ipfs/QmRXyfi3oNZCubDxiVFre3kLZ8XeGt6pQsnAQRZ7akhSNs?filename=gamer_bull.json",
    "https://ipfs.io/ipfs/QmRJVFeMrtYS2CUVUM2cHJpBV5aX2xurpnsfZxLTTQbiD3?filename=party_bull.json",
    "https://ipfs.io/ipfs/QmdcURmN1kEEtKgnbkVJJ8hrmsSWHpZvLkRgsKKoiWvW9g?filename=simple_bull.json"
  ];
  string[] bearUrisIpfs = [
    "https://ipfs.io/ipfs/Qmdx9Hx7FCDZGExyjLR6vYcnutUR8KhBZBnZfAPHiUommN?filename=beanie_bear.json",
    "https://ipfs.io/ipfs/QmTVLyTSuiKGUEmb88BgXG3qNC8YgpHZiFbjHrXKH3QHEu?filename=coolio_bear.json",
    "https://ipfs.io/ipfs/QmbKhBXVWmwrYsTPFYfroR2N7NAekAMxHUVg2CWks7i9qj?filename=simple_bear.json"
  ];

  constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash, uint _updateInterval, address _priceFeedAddress) 
  public 
  ERC721("DataLife", "DLF")
  VRFConsumerBase(_VRFCoordinator, _LinkToken) {
    priceFeed = AggregatorV3Interface(_priceFeedAddress);
    lastTimeStamp = block.timestamp;
    interval = _updateInterval;
    setPublicChainlinkToken();

    dl_json_url = "https://raw.githubusercontent.com/cargonriv/DataLife/main/jsonCSV.json?token=GHSAT0AAAAAABVYOJEANSZ7NFTI5FH74KNEYXHKZNA";
    linkFee = 0.1 * 10 ** 18;
    // remainingTokens = 5
    keyHash = _keyHash;
    // oracle = ;
    // jobId = ;
  }

  function requestNewCollectible(string memory uri) public
  {
    bytes32 requestId = requestRandomness(keyHash, linkFee);
    requestToSender[requestId] = msg.sender;
    emit RequestedRandomness(requestId);
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
    internal
    override
  {
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    randomId = (randomNumber % 5) + 1;
    idString = Strings.toString(randomId);
    request.add("get", dl_json_url);
    request.add("path", idString);
    emit ReturnedCollectible(idString);

    return sendChainlinkRequestTo(oracle, request, linkFee);
  }

  function fulfill(bytes32 _requestId, Collectible calldata _collectible) public 
    recordChainlinkFulfillment(_requestId) 
  {
    
    _tokenIdCounter.increment();
    uint256 newId = _tokenIdCounter.current();
    collectibles.push(Collectible(_collectible));
    _safeMint(requestToSender[_requestId], newId);
  }
 // HELPER FUNCTIONS FOR DYNAMIC UPKEEP AND ERC721 STANDARD FUNCTIONS
  function setInterval(uint256 newInterval) public onlyOwner {
    interval = newInterval;
  }

  function compareStrings(string memory a, string memory b) internal pure returns (bool) {
    return (keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b)));
  }

  function setPriceFeed(address newPriceFeed) public onlyOwner {
    priceFeed = AggregatorV3Interface(newPriceFeed);
  }

  function getLatestPrice() public view returns (int256) {
    (, int256 price, , ,) = priceFeed.latestRoundData();
    return price;
  }

  function checkUpkeep(bytes calldata /*checkData*/)
  public
  view
  override
  returns (bool upkeepNeeded, bytes memory /*performData*/) {
    upkeepNeeded = (block.timestamp - lastTimeStamp) > interval;
  }


  function updateAllTokenUris(string memory trend) internal {
    // VERY EXPENSIVE FUNCTION BY UPDATING ALL NFTs 
    // depending on block state from new mint?
    // CYCLICAL TREND-BASED DYNAMIC
    if (compareStrings("bear", trend)) {
        for (uint i=0; i < _tokenIdCounter.current(); i++){
            setTokenURI(i, bearUrisIpfs[i]);
        }
    } else {
        for (uint i=0; i < _tokenIdCounter.current(); i++){
            setTokenURI(i, bullUrisIpfs[i]);
        }
    }

    emit TokensUpdated(trend);
  }

  function performUpkeep(bytes calldata /*checkData*/) external override {
    if ((block.timestamp - lastTimeStamp) > interval) {
        lastTimeStamp = block.timestamp;
        int lastPrice = getLatestPrice();

        if (lastPrice == currentPrice) {
            return;
        }
        if (lastPrice < currentPrice) {
            updateAllTokenUris("bear");
        }
        else {
            updateAllTokenUris("bull");
        }

        currentPrice = lastPrice;
    }
  }

  function _burn(uint256 tokenId) internal override(ERC721, ERC721URIStorage)
  {
    super._burn(tokenId);
  }

  function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory)
  {
    return super.tokenURI(tokenId);
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "transfer caller is not owner nor approved"
    );
    _setTokenURI(_tokenId, _tokenURI);
  }
  // The following functions are overrides required by Solidity.
  function _beforeTokenTransfer(address from, address to, uint256 tokenId)
    internal override(ERC721, ERC721Enumerable) {
      super._beforeTokenTransfer(from, to, tokenId);
  }

  function supportsInterface(bytes4 interfaceId)
    public
    view
    override(ERC721, ERC721Enumerable)
    returns (bool)
    {
      return super.supportsInterface(interfaceId);
    }

}