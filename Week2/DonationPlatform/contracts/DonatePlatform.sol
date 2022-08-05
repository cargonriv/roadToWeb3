// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

// deployed in rinkeby testnet at contract address:
// 0x076275c76A8AAF6F3130F26Ab5cD432411d8557A
// front-end built with replit:
// https://donationplatform.cargonriv.repl.co/

// Import this file to use console.log
import "hardhat/console.sol";

contract DonatePlatform {
    address payable owner;
    event NewDonation(
        address indexed from,
        string name,
        string message,
        uint256 timestamp
    );

    struct Donation {
        address from;
        string name;
        string message;
        uint256 timestamp;
    }
    Donation[] donations;

    constructor() {
        owner = payable(msg.sender);
    }

    function donateETH(string memory _name, string memory _message)
        public
        payable
    {
        require(msg.value > 0, "Unable to donate without coins...");
        donations.push(Donation(msg.sender, _name, _message, block.timestamp));

        emit NewDonation(msg.sender, _name, _message, block.timestamp);
    }

    function getDonations() public view returns (Donation[] memory) {
        return donations;
    }

    function withdrawDonations() public {
        // balance of the smart contract address: address(this).balance;
        require(owner.send(address(this).balance), "unable to withdraw");
    }
}
