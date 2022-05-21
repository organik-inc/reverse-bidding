// Visit beta.OK.gold from your phone to interact with this smart contract. Built by Organik, Inc. 2022
// SPDX-License-Identifier: MIT

pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ReverseBids is IERC20 {
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
    
    function getAllBids() public view returns (Offer[] memory) {
        require(
            block.timestamp > endTime ,
            "This Vault is still accepting more Offers"
        );
        Offer[] memory allBids = new Offer[](offersCount);
        for (uint256 index = 0; index < offersCount; index++) {
            allBids[index] = offers[index];
        }
        return allBids;
    }

    function createOffer(
        address receiverAddress,
        uint256 amount
    ) public payable {
        require(
            msg.value == 1 * 10** uint256(decimals()) ,
            "You need to pay 1 MATIC to create an offer"
        );
        require(
            block.timestamp <= endTime ,
            "This Vault is not accepting more Offers"
        );
        uint256 offerId = offersCount;
        
        Offer storage offer = offers[offerId];
        // Offer Genesis.
        offer.id = offerId;
        offer.payoutAddress = payable(receiverAddress);
        offer.amount = amount;
        offer.genesis = block.timestamp;
        offer.rip     = 0;
        offer.burnt   = false;
        
        offersCount++;
        emit NewOffer(msg.sender, offerId);

    }

    function burstVault() internal pure returns (bool) {
        for (uint256 index = 0; index < offersCount; index++) {
            allBids[index] = offers[index];
            if(leadOffer == offers[index].id){
                // Current Offer is the Lead.
                leader = offers[index].payoutAddress;
            }else{
                // Current Offer may be the next leader.
                if(offers[index].amount > offers[leadOffer].amount){
                    // This bid is not lower. Do no thing.
                }else{
                    // This bid might be equal or lower than the lead
                    if(offers[index].amount == offers[leadOffer].amount){
                        // Same bid? Burn Offer
                        Offer storage offer = offers[index];
                        // Offer RIP.
                        offer.burnt = true;
                        offer.rip   = block.timestamp;

                        Offer storage lead = offers[leadOffer];
                        // Lead Offer RIP.
                        lead.burnt = true;
                        lead.rip   = block.timestamp;
                        
                        leader = owner;
                        // leadOffer Stays the same.

                    }else{
                        // update leader
                        leader = offers[index].payoutAddress;
                        leadOffer = index;
                    }
                }
            }
        }
        winnersCount++;
        return true;
    }

    function withdraw(address _tokenContract) external onlyOwner {
        require(block.timestamp >= endTime, "OKGOLD:ERROR #This Auction is still LIVE.");
        require(address(this).balance >= 0 eth, "OKGOLD:ERROR #This contract is empty");

        burstVault();

        if(address(this) == _tokenContract){
            if(AUCTION_PRIZE <= address(this).balance){
                // Enough to Send to Winner and Owner.
                Address.sendValue(payable(leader), AUCTION_PRIZE);
                // Rest to the Owner.
                uint256 balance = address(this).balance;
                if(balance > 0){
                    Address.sendValue(payable(msg.sender), balance);
                }
            }else{
                // Enough to Send only to the Winner.
                // Withdraw native ETH or MATIC.
                uint256 balance = address(this).balance;
                if(balance > 0){
                    Address.sendValue(payable(leader), balance);
                }
            }
        }else{
            // Withdraw any other Tokens that might have been sent to ie: ETH* APE, LPT, MATIC.
            balance = IERC20(_tokenContract).balanceOf(address(this));
            if(balance > 0){
                IERC20(_tokenContract).safeTransfer(owner(), balance);
            }
        }
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OKGOLD:ERROR #You are not the Owner of this Auction");
        _;
    }

    constructor() public {
        owner = msg.sender;
        endTime = auctionPeriod + block.timestamp;
    }

}