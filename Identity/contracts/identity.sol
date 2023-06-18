// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import {StringUtils} from "./libraries/StringUtils.sol";
import "@openzeppelin/contracts/utils/Base64.sol";

import "hardhat/console.sol";

contract Domains is ERC721URIStorage {
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  string public tld;
  address payable public owner;
  
  string svgPartOne = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M 107.7 44.2 L 107.7 0.8 L 117.2 0.8 L 117.2 42.7 A 39.482 39.482 0 0 0 117.6 48.511 Q 118.481 54.419 121.3 58.2 A 13.242 13.242 0 0 0 129.756 63.357 A 20.418 20.418 0 0 0 133.6 63.7 A 21.386 21.386 0 0 0 138.604 63.151 A 13.455 13.455 0 0 0 146.3 58.35 A 17.382 17.382 0 0 0 149.096 52.955 Q 149.886 50.536 150.231 47.594 A 42.042 42.042 0 0 0 150.5 42.7 L 150.5 0.8 L 159.7 0.8 L 159.7 43.8 A 39.957 39.957 0 0 1 159.078 51.031 A 28.663 28.663 0 0 1 156.45 58.95 Q 153.2 65.3 147.35 68.65 A 25.023 25.023 0 0 1 138.789 71.605 A 32.816 32.816 0 0 1 133.6 72 A 32.706 32.706 0 0 1 125.595 71.076 A 22.492 22.492 0 0 1 114.6 64.8 Q 108.488 58.423 107.79 47.182 A 48.096 48.096 0 0 1 107.7 44.2 Z M 41.6 70.8 L 0 70.8 L 0 0.8 L 9.5 0.8 L 9.5 62.3 L 41.6 62.3 L 41.6 70.8 Z M 60.6 70.8 L 51.1 70.8 L 51.1 1 Q 55.2 0.5 60.15 0.25 A 200.806 200.806 0 0 1 69.08 0.004 A 221.966 221.966 0 0 1 70.4 0 Q 77.97 0 83.572 2.082 A 26.011 26.011 0 0 1 85.2 2.75 A 24.606 24.606 0 0 1 90.282 5.779 A 19.374 19.374 0 0 1 94.5 10.3 Q 97.7 15.1 97.7 21.3 A 25.258 25.258 0 0 1 96.992 27.423 A 19.268 19.268 0 0 1 94 34 A 22.312 22.312 0 0 1 86.449 40.63 A 28.065 28.065 0 0 1 83.7 41.95 A 34.774 34.774 0 0 1 75.611 44.174 A 47.194 47.194 0 0 1 68.4 44.7 Q 64.2 44.7 60.6 44.4 L 60.6 70.8 Z M 60.6 8.4 L 60.6 36.3 Q 61.7 36.438 63.131 36.552 A 96.255 96.255 0 0 0 64.5 36.65 Q 66.8 36.8 69.6 36.8 A 31.831 31.831 0 0 0 74.98 36.375 Q 77.859 35.88 80.163 34.811 A 15.221 15.221 0 0 0 83.4 32.8 A 12.896 12.896 0 0 0 88.255 23.358 A 17.32 17.32 0 0 0 88.3 22.1 A 14.452 14.452 0 0 0 87.539 17.307 A 12.136 12.136 0 0 0 83.6 11.8 A 15.462 15.462 0 0 0 78.519 9.137 Q 76.293 8.427 73.6 8.16 A 34.58 34.58 0 0 0 70.2 8 A 131.125 131.125 0 0 0 66.942 8.039 A 109.939 109.939 0 0 0 65.1 8.1 A 91.274 91.274 0 0 0 62.217 8.264 A 75.041 75.041 0 0 0 60.6 8.4 Z" fill="#fff"/><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#d600ff"/><stop offset="1" stop-color="#bd00ff" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
  string svgPartTwo = '</text></svg>';

  mapping(string => address) public domains;
  mapping(string => string) public records;
  mapping(uint => string) public names;

  error Unauthorized(); 
  error AlreadyRegistered();
  error InvalidName(string name);

  constructor(string memory _tld) ERC721("LPU Name Service", "LNS") payable {
    owner = payable(msg.sender);
    tld = _tld;
    console.log("%s name service deployed", _tld);
  }

  function price(string calldata name) public pure returns(uint) {
    uint len = StringUtils.strlen(name);
    require(len > 0);
    if (len == 3) {
      return 3 * 10**15; 
    } else if (len == 4) {
      return 2 * 10**15; 
    } else {
      return 1 * 10**15;
    }
  }

  function getAllNames() public view returns (string[] memory) {
  console.log("Getting all names from contract");
  string[] memory allNames = new string[](_tokenIds.current());
  for (uint i = 0; i < _tokenIds.current(); i++) {
    allNames[i] = names[i];
    console.log("Name for token %d is %s", i, allNames[i]);
  }

  return allNames;
}

  function getAddress(string calldata name) public view returns (address) {
      return domains[name];
  }

  function getRecord(string calldata name) public view returns(string memory) {
      return records[name];
  }

  function valid(string calldata name) public pure returns(bool) {
  return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
}

  function setRecord(string calldata name, string calldata record) public {
      if (msg.sender != domains[name]) revert Unauthorized();
      records[name] = record;
  }

  function register(string calldata name) public payable {
    if (domains[name] != address(0)) revert AlreadyRegistered();
    if (!valid(name)) revert InvalidName(name);

    uint256 _price = price(name);
    require(msg.value >= _price, "Not enough Matic paid");
    
    string memory _name = string(abi.encodePacked(name, ".", tld));
    string memory finalSvg = string(abi.encodePacked(svgPartOne, _name, svgPartTwo));
    uint256 newRecordId = _tokenIds.current();
    uint256 length = StringUtils.strlen(name);
    string memory strLen = Strings.toString(length);

    console.log("Registering %s.%s on the contract with tokenID %d", name, tld, newRecordId);

    string memory json = Base64.encode(
        abi.encodePacked(
            '{'
                '"name": "', _name,'", '
                '"description": "A domain on the LPU name service", '
                '"image": "data:image/svg+xml;base64,', Base64.encode(bytes(finalSvg)), '", '
                '"length": "', strLen, '"'
            '}'
        )
    );

    string memory finalTokenUri = string( abi.encodePacked("data:application/json;base64,", json));

    console.log("\n--------------------------------------------------------");
    console.log("Final tokenURI", finalTokenUri);
    console.log("--------------------------------------------------------\n");

    _safeMint(msg.sender, newRecordId);
    _setTokenURI(newRecordId, finalTokenUri);
    domains[name] = msg.sender;
    names[newRecordId] = name;
    _tokenIds.increment();
  }

  modifier onlyOwner() {
  require(isOwner());
  _;
}

function isOwner() public view returns (bool) {
  return msg.sender == owner;
}

function withdraw() public onlyOwner {
  uint amount = address(this).balance;
  
  (bool success, ) = msg.sender.call{value: amount}("");
  require(success, "Failed to withdraw Matic");
} 

}