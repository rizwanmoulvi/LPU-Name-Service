// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import {Base64} from "./libraries/Base64.sol";
import {StringUtils} from "./libraries/StringUtils.sol";

contract Domains is ERC721URIStorage {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIds;

    address payable public owner;
    mapping(uint256 => string) public names;
    mapping(string => string) public records;
    mapping(string => address) public domains;

    error Unauthorized();
    error AlreadyRegistered();
    error InvalidName(string name);

    string public tld;
    string constant SVG_PART_ONE = '<svg xmlns="http://www.w3.org/2000/svg" width="270" height="270" fill="none"><path fill="url(#B)" d="M0 0h270v270H0z"/><defs><filter id="A" color-interpolation-filters="sRGB" filterUnits="userSpaceOnUse" height="270" width="270"><feDropShadow dx="0" dy="1" stdDeviation="2" flood-opacity=".225" width="200%" height="200%"/></filter></defs><path d="M227.79492,52.61621l-96-32a11.98464,11.98464,0,0,0-7.58984,0L28.44678,52.53564l-.05078.01685-.19092.06372c-.17383.05786-.34107.12793-.51074.19312-.20118.07739-.40052.15722-.5962.24487-.24487.10962-.48706.22339-.72216.34814-.11817.06275-.23181.13233-.34766.199-.199.11426-.39526.23144-.58618.3562-.10938.07153-.21655.14551-.32361.2207q-.295.20655-.575.42993c-.09009.07154-.18091.14185-.26892.21607q-.33453.282-.64575.58691c-.04444.04346-.09192.0835-.13575.12744q-.37243.375-.70947.78077c-.06335.07592-.12109.15625-.18249.23364-.15516.1958-.30579.39453-.44837.59961-.07861.11279-.15332.22778-.228.34326q-.175.271-.33483.55127c-.07264.12671-.14551.25268-.21363.38257-.10583.20166-.20251.40844-.297.61645-.05225.115-.10987.22657-.15845.34351-.12842.30835-.24243.62353-.34522.94311-.04187.13086-.07544.2649-.113.39746-.06128.21656-.1189.43384-.16822.65455-.03125.14062-.05908.28222-.08545.4248-.04345.23462-.07861.47119-.10839.71-.01526.124-.03321.24732-.04468.37256C20.02209,63.2583,20,63.627,20,64v80a12,12,0,0,0,24,0V80.64868l23.7146,7.905a67.90093,67.90093,0,0,0,18.11377,84.73047,99.97006,99.97006,0,0,0-41.64819,36.16016,12.00007,12.00007,0,0,0,20.10351,13.10937,76.02217,76.02217,0,0,1,127.43213,0,12.00007,12.00007,0,0,0,20.10352-13.10937,99.97238,99.97238,0,0,0-41.64783-36.16016A67.9008,67.9008,0,0,0,188.2854,88.55371l39.50952-13.16992a11.99952,11.99952,0,0,0,0-22.76758ZM128,44.64941,186.05273,64l-20.70739,6.90234-.03272.011L128,83.35059,90.68677,70.91309l-.02844-.00953L69.94727,64ZM172,120A44,44,0,1,1,90.93738,96.29443l33.2677,11.08936a11.99358,11.99358,0,0,0,7.58984,0l33.2677-11.08936A43.87528,43.87528,0,0,1,172,120Z"  transform="scale(0.5,0.5)" fill="#fff" /><defs><linearGradient id="B" x1="0" y1="0" x2="270" y2="270" gradientUnits="userSpaceOnUse"><stop stop-color="#FF5800"/><stop offset="1" stop-color="#FFBB00" stop-opacity=".99"/></linearGradient></defs><text x="32.5" y="231" font-size="27" fill="#fff" filter="url(#A)" font-family="Plus Jakarta Sans,DejaVu Sans,Noto Color Emoji,Apple Color Emoji,sans-serif" font-weight="bold">';
    string constant SVG_PART_TWO = '</text></svg>';

    modifier onlyOwner() {
        require(isOwner());
        _;
    }

    constructor(string memory _tld)
        payable
        ERC721("LPU Student Web3 Domain", "LSWD")
    {
        owner = payable(msg.sender);
        tld = _tld;
        console.log("%s name service deployed", _tld);
    }

    function isOwner() public view returns (bool) {
        return msg.sender == owner;
    }

    function price(string calldata name) public pure returns (uint256) {
        uint256 len = StringUtils.strlen(name);
        require(len > 0);
        if (len == 3) {
            return 5 * 10**14; 
        } else if (len == 4) {
            return 3 * 10**14; 
        } else {
            return 1 * 10**14;
        }
    }

    function register(string calldata name) public payable {
        if (domains[name] != address(0)) revert AlreadyRegistered();
        if (!valid(name)) revert InvalidName(name);
        require(domains[name] == address(0));

        uint256 _price = price(name);
        require(msg.value >= _price, "Not enough Matic paid");

        string memory _name = string(abi.encodePacked(name, ".", tld));
        string memory finalSvg = string(
            abi.encodePacked(SVG_PART_ONE, _name, SVG_PART_TWO)
         );
        uint256 newRecordId = _tokenIds.current();
        uint256 length = StringUtils.strlen(name);
        string memory strLen = Strings.toString(length);

        console.log(
            "Registering %s.%s on the contract with tokenID %d",
            name,
            tld,
            newRecordId
        );

        
        string memory json = Base64.encode(
            abi.encodePacked(
                '{"name": "',
                _name,
                '", "description": "A Web3 domain for students of LPU", "image": "data:image/svg+xml;base64,',
                Base64.encode(bytes(finalSvg)),
                '","length":"',
                strLen,
                '"}'
            )
        );

        string memory finalTokenUri = string(
            abi.encodePacked("data:application/json;base64,", json)
        );

        console.log(
            "\n--------------------------------------------------------"
        );
        console.log("Final tokenURI", finalTokenUri);
        console.log(
            "--------------------------------------------------------\n"
        );

        _safeMint(msg.sender, newRecordId);
        _setTokenURI(newRecordId, finalTokenUri);
        domains[name] = msg.sender;

        names[newRecordId] = name;
        _tokenIds.increment();
    }

    function getAllNames() public view returns (string[] memory) {
        console.log("Getting all names from contract");
        string[] memory allNames = new string[](_tokenIds.current());
        for (uint256 i = 0; i < _tokenIds.current(); i++) {
            allNames[i] = names[i];
            console.log("Name for token %d is %s", i, allNames[i]);
        }

        return allNames;
    }

    function valid(string calldata name) public pure returns (bool) {
        return StringUtils.strlen(name) >= 3 && StringUtils.strlen(name) <= 10;
    }

    function getAddress(string calldata name) public view returns (address) {
        return domains[name];
    }

    function setRecord(string calldata name, string calldata record) public {
        if (msg.sender != domains[name]) revert Unauthorized();
        records[name] = record;
    }

    function getRecord(string calldata name)
        public
        view
        returns (string memory)
    {
        return records[name];
    }

    function withdraw() public onlyOwner {
        uint256 amount = address(this).balance;

        (bool success, ) = msg.sender.call{value: amount}("");
        require(success, "Failed to withdraw Matic");
    }
}
