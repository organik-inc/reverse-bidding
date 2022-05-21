// Visit beta.OK.gold from your phone to interact with this smart contract. Built by Organik, Inc. 2022
// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract ReverseBids {
    using SafeMath for uint256;
    address owner;

    uint256 public offersCount = 0;
    uint256 public participantsCount = 0;
    uint256 public winnersCount = 0;

    uint256 public endTime = 0;
    uint256 AUCTION_PRIZE = 11 eth;         // EDIT THIS: Total Gold pot inside this Vault.
    uint32 constant auctionPeriod = 1 days; // EDIT THIS: Vault Life.

    address public leader;
    uint256 public leadOffer = 0;
    
    mapping(uint256 => Offer) private offers;

    struct Offer {
        uint256 id;
        uint256 amount;
        address payable payoutAddress;
        bool burnt;
        uint256 genesis;
        uint256 rip;
    }

    event NewOffer(address indexed fromAddress, uint256 id);

    constructor() public {

    }

}