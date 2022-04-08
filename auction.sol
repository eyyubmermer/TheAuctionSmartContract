//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Auction{
    address payable public owner;
    uint public startBlock;
    uint public endBlock;
    string public ipfsHash;
    enum State {Started, Running, Ended, Cancelled}
    State public auctionState;
    uint public highestBindingBid;
    address payable public highestBidder;
    mapping(address => uint) public bids;
    uint bidIncrement;


    constructor(){
        owner=payable(msg.sender);
        auctionState = State.Running;
        startBlock = block.number;
        endBlock = startBlock +3;
        ipfsHash="";
        bidIncrement=1000000000000000000;
    }

    modifier notOwner() {
        require(owner != msg.sender);
        _;
    }
    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }
    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }
    modifier onlyOwner(){
        require(owner== msg.sender);
        _;
    }

    function min(uint a, uint b) pure internal returns(uint){
        if(a<=b){
            return a;
        }
        else{
            return b;
        }
    }


    function placeBid() public payable notOwner() afterStart() beforeEnd(){
        require(auctionState == State.Running);
        require(msg.value >= 100);

        uint currentBid= bids[msg.sender] + msg.value;
        require(currentBid > highestBindingBid);

        bids[msg.sender] = currentBid;

        if(currentBid <= bids[highestBidder]){
            highestBindingBid= min(currentBid + bidIncrement, bids[highestBidder]);
        }
        else{
            highestBindingBid= min(currentBid , bids[highestBidder] + bidIncrement);
            highestBidder = payable(msg.sender);
        }
    }

    function cancelAuction() public onlyOwner() {
        auctionState=State.Cancelled;
    }

    function finalizeAuction() public{
        require(block.number > endBlock || auctionState == State.Cancelled);
        require(msg.sender==owner || bids[msg.sender]> 0);
        address payable recipient;
        uint value;

        if(auctionState==State.Cancelled){
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        }
        else{
            if(msg.sender==owner){
                recipient=owner;
                value= highestBindingBid;
            }
            else{
                if(msg.sender != highestBidder){
                recipient=payable(msg.sender);
                value=bids[msg.sender];                    
                }
                else{
                recipient=highestBidder;
                value= bids[highestBidder]-highestBindingBid;                    
                }
            }
        }
        bids[recipient] = 0;
        recipient.transfer(value);
    }
}
