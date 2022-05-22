// Visit beta.OK.gold from your phone to interact with this smart contract. Built by Organik, Inc. 2022
// SPDX-License-Identifier: MIT
// OkVault v 5 - GENESIS CONTRACT ._.
pragma solidity 0.8.12;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract OkVault is ERC721URIStorage {
    using SafeMath for uint256;
    address owner;

    uint256 public offersCount = 0;
    uint256 public winnersCount = 0;
    uint256 public totalPOAP = 0;

    string public tokenJSON;
    
    uint256 public endTime = 0;
    uint256 public AUCTION_PRIZE = 0; // updated inside the Constructor
    uint256 public ENTRY_FEE = 1 * 10** uint256(uint32(18)); // 1 eth
    uint32 constant auctionPeriod = 1 days; // EDIT THIS: Vault Life. (1 days)

    address public leader;
    uint256 public leadOffer = 0;
    
    mapping(uint256 => Offer) private offers;
    mapping(uint256 => uint256) private bids;

    struct Offer {
        uint256 id;
        uint256 amount;
        address payable payoutAddress;
        uint256 genesis;
    }

    event NewOffer(address indexed fromAddress, uint256 id);

    event Mint(
        address indexed sender,
        address indexed owner,
        string tokenURI,
        uint256 tokenId
    );
    
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
            msg.value == ENTRY_FEE ,
            "You need to pay X MATIC to create an offer"
        );
        require(
            block.timestamp <= endTime ,
            "This Vault is not accepting more Offers"
        );
        offersCount++;
        uint256 offerId = offersCount;
        
        Offer storage offer = offers[offerId];
        // Offer Genesis.
        offer.id = offerId;
        offer.payoutAddress = payable(receiverAddress);
        offer.amount = amount;
        offer.genesis = block.timestamp;
        
        emit NewOffer(msg.sender, offerId);
        if(balanceOf(receiverAddress) <= 0){
            _mint(receiverAddress, totalPOAP);
            _setTokenURI(totalPOAP, tokenJSON);
            totalPOAP++;
            emit Mint(msg.sender, receiverAddress, tokenJSON, totalPOAP);
        }
        bids[amount]++;
    }

    function burstVault() internal returns (bool) {
        uint256 totalUnique = 0;
        for (uint256 index = 1; index < offersCount; index++) {
            if(bids[offers[index].amount] == 1){
                // Unique Bid.
                totalUnique++;
                if(leadOffer <= 0){
                    leadOffer = index;
                    leader = offers[index].payoutAddress;
                }else{

                    if(offers[index].amount <= offers[leadOffer].amount){
                        leadOffer = index;
                        leader = offers[index].payoutAddress;
                    }

                }
            }
        }
        if(totalUnique <= 0){
            leadOffer = 0;
            leader = owner;
        }
        winnersCount++;
        return true;
    }

    function withdraw(address _tokenContract) external onlyOwner {
        require(block.timestamp >= endTime, "OKGOLD:ERROR #This Auction is still LIVE.");
        require(address(this).balance >= 0, "OKGOLD:ERROR #This contract is empty");

        if(winnersCount <= 0){
            burstVault();
        }
        
        address payable to     = payable(owner);
        address payable winner = payable(leader);
        if(address(this) == _tokenContract){
            if(owner == leader){
                // There was not a unique bid, all offers were burnt.
                if(getBalance() > 0){
                    to.transfer(getBalance());
                }
            }else{
                if(AUCTION_PRIZE <= getBalance() ){
                    // Enough to Send to Winner and Owner.
                    winner.transfer(AUCTION_PRIZE);
                    // Rest to the Owner.
                    if(getBalance() > 0){
                        to.transfer(getBalance());
                    }
                }else{
                    // Enough to Send only to the Winner.
                    // Withdraw native ETH or MATIC.
                    if(getBalance() > 0){
                        winner.transfer(getBalance());
                    }
                }
            }
        }else{
            // Withdraw any other Tokens that might have been sent to ie: ETH* APE, LPT, MATIC.
            uint256 balance = IERC20(_tokenContract).balanceOf(address(this));
            if(balance > 0){
                IERC20(_tokenContract).transfer(msg.sender, balance);
            }
        }
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function totalSupply() public view returns(uint) {
        return totalPOAP;
    }

    function getTimeLeft() public view returns(uint) {
        if(endTime >= block.timestamp){
            return endTime - block.timestamp;
        }
        return uint(0);
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "OKGOLD:ERROR #You are not the Owner of this Auction");
        _;
    }

    constructor(string memory _tokenJSON, uint _prize) public ERC721("POAP - OK.Gold", "OkVaultV1") {
        tokenJSON = _tokenJSON;
        owner = msg.sender;
        AUCTION_PRIZE = _prize * ( 10 ** uint32(18) );
        endTime = auctionPeriod + block.timestamp;
    }

}