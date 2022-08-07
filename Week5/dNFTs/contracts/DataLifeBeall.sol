// contracts/DataLife.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@chainlink/contracts/src/v0.8/VRFConsumerBase.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";

contract DataLifeBeall is ERC721, VRFConsumerBase, ChainlinkClient, Ownable {
  uint256 public randomId;
  string public idString;
  bytes32 public keyHash;
  address public vrfCoordinator;

  uint256 private linkToken;
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
  event ReturnedCollectible(string idString);
  event RequestedRandomness(bytes32 requestId);
  mapping(bytes32 => uint256) requestToTokenId;
  mapping(bytes32 => address) requestToSender;

  constructor(address _VRFCoordinator, address _LinkToken, bytes32 _keyHash) 
  public 
  ERC721("DataLife", "DLF")
  VRFConsumerBase(_VRFCoordinator, _LinkToken) {
    setPublicChainlinkToken();
    jobId = ;
    oracle = ;
    dl_json_url = "https://raw.githubusercontent.com/cargonriv/DataLife/main/jsonCSV.json?token=GHSAT0AAAAAABVYOJEANSZ7NFTI5FH74KNEYXHKZNA"

    vrfCoordinator = _VRFCoordinator;
    linkFee = 0.1 * 10 ** 18;
    // remainingTokens = 5
    keyHash = _keyHash;
  }

  function requestNewCollectible() public returns (bytes32 requestId)
  {
    bytes32 requestId = requestRandomness(keyHash, linkFee);
    requestToSender[requestId] = msg.sender;
    emit RequestedRandomness(requestId);
    return requestId;
  }

  function fulfillRandomness(bytes32 requestId, uint256 randomNumber)
    internal
    override
  {
    Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);
    randomId = randomNumber.mod(5).add(1);
    idString = Strings.toString(randomId);
    request.add("get", dl_json_url);
    request.add("path", idString);

    emit returnedCollectible(idString);
    return sendChainlinkRequestTo(oracle, request, linkFee)
  }

  function fulfill(bytes32 _requestId, Collectible _collectible) public 
    recordChainlinkFulfillment(_requestId) 
  { 
    uint256 newId = collectibles.length + 1;
    collectibles.push(Collectible(_collectible));
    _safeMint(requestToSender[_requestId], newId);
  }

  function setTokenURI(uint256 _tokenId, string memory _tokenURI) public {
    require(
      _isApprovedOrOwner(_msgSender(), _tokenId),
      "transfer caller is not owner nor approved"
    );
    _setTokenURI(_tokenId, _tokenURI);
  }
}