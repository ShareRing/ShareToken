pragma solidity ^0.4.21;

import "./Ownable.sol";

contract WhiteListManager is Ownable {

    // The list here will be updated by multiple separate WhiteList contracts
    mapping (address => bool) public list;

    function unset(address addr) public onlyOwner {

        list[addr] = false;
    }

    function unsetMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            unset(addrList[i]);
        }
    }

    function set(address addr) public onlyOwner {

        list[addr] = true;
    }

    function setMany(address[] addrList) public onlyOwner {

        for (uint256 i = 0; i < addrList.length; i++) {
            
            set(addrList[i]);
        }
    }

    function isWhitelisted(address addr) public view returns (bool) {

        return list[addr];
    }
}