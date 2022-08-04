// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 

contract data_var{

    uint256 public defaultLifeTime;
    uint256 public defaultFee;
    address payable owner;
    
    struct metadataDeal{
        address buyer; //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        address seller; //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        string title; //TITULO RANDOM CON PALABRAS RANDOM
        string description; 
        uint256 amount; //01234567890123456789
        uint16 status; //0=pending, 1= open, 2= closed, 3= cancelled, 4= tribunal
        uint256 created;
    }

    //choose (0 = No answer, 1 = Accepted, 2 = Cancelled)
    struct agreement{
        uint8 buyerChoose;
        uint8 sellerChoose;
        bool buyerAcceptDraft;
        bool sellerAcceptDraft;
    }

    // deal ID to metadata Deal 
    mapping(uint256 => metadataDeal) public deals;

    // deal ID to partTake choose
    mapping(uint256 => agreement) private acceptance;

    constructor(){
        owner = payable(msg.sender);
    }

    // Validate Only the buyer or seller can edit
    modifier isPartTaker(uint256 _dealID){
        require(((msg.sender == deals[_dealID].buyer)||(msg.sender == deals[_dealID].seller)), "You are not part of the deal");
        _;
    }

    // Validate the Deal status still OPEN
    modifier openDeal(uint256 _dealID){
        require(deals[_dealID].status == 1,"This DEAL are not OPEN");
        _;
    }

    // Validate the Deal status is a DRAFT
    modifier openDraft(uint256 _dealID){
        require(deals[_dealID].status == 0,"This DRAFT are not PENDING");
        _;
    }

    function createDeal(
        uint256 _current,
        address _buyer,
        address _seller,
        string memory _title,
        string memory _description,
        uint256 _amount
        )public returns(bool){
        
        if(_buyer == msg.sender){
        acceptance[_current] = agreement(0,0,true,false);
        deals[_current] = metadataDeal(msg.sender, _seller, _title, _description, _amount, 0, block.timestamp);
        }
        if(_seller == msg.sender){
        acceptance[_current] = agreement(0,0,false,true);
        deals[_current] = metadataDeal(_buyer, msg.sender, _title, _description, _amount, 0, block.timestamp);
        }
        
        return(true);
    }

    function finishDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) returns(string memory status){
        //both want to proceed and finish
        if(acceptance[_dealID].buyerChoose == 1 && acceptance[_dealID].sellerChoose == 1){
            // TODO: Pendiente para envio de tokens y quitar fees
            deals[_dealID].status = 2; //close
            return("Deal was succesfully CLOSED");
        }
        //both want to cancel and finish
        if(acceptance[_dealID].buyerChoose == 2 && acceptance[_dealID].sellerChoose == 2){
            // TODO: Pendiente para reembolso de tokens y quitar fees
            deals[_dealID].status = 3; //cancel
            return("Deal was CANCELLED");
        } else {
            revert("Buyer and Seller must be agree with the same decision");
        }
    }

    function takeDecision(uint256 _dealID, uint8 _decision)public isPartTaker(_dealID) openDeal(_dealID){
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerChoose = _decision;
        }
    }

    function acceptDraft(uint256 _dealID, bool _decision)public openDraft(_dealID) {
        //TODO: hacer test a esta funcion
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerAcceptDraft = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerAcceptDraft = _decision;
        }
        if(acceptance[_dealID].buyerAcceptDraft == true && acceptance[_dealID].sellerAcceptDraft == true ){
            deals[_dealID].status = 1;
        }
    }
}