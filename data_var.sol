// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
contract data_var{

    uint256 public defaultLifeTime;
    uint256 public defaultFee;
    address payable owner;
    using SafeERC20 for IERC20;
    IERC20 _token;
 
    struct metadataDeal{
        address buyer; //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        address seller; //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        string title; //TITULO RANDOM CON PALABRAS RANDOM
        string description; 
        uint256 amount; //Price Deal offer 01234567890123456789
        uint256 goods; // Tokens holded in current deal
        uint16 status; //0=pending, 1= open, 2= closed, 3= cancelled, 4= tribunal
        uint256 created;
        string coin;
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
    mapping(uint256 => agreement) public acceptance;

    // tokens contract
    mapping(string => address) public tokens;

    constructor(address _tokenAddress, string memory _tokenName){
        owner = payable(msg.sender);
        tokens[_tokenName] = _tokenAddress;
        // BUSD 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E
    }

    // Validate Only the buyer or seller can edit
    modifier isPartTaker(uint256 _dealID){
        require(((msg.sender == deals[_dealID].buyer)||(msg.sender == deals[_dealID].seller)), "You are not part of the deal");
        _;
    }

    // Validate the Deal status was cancelled
    modifier cancelledDeal(uint256 _dealID){
        require(deals[_dealID].status == 3,"This DEAL are not CANCELLED");
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

    modifier tokenValid(string memory _tokenName){
        require(tokens[_tokenName] != address(0),"This token is not supported by the contract");
        _;
    }

    function createDeal(
        uint256 _current,
        address _buyer, // 0xd20fD73BFD6B0fCC3222E5b881AB03A24449E608
        address _seller, // 0xd92A8d5BCa7076204c607293235fE78200f392A7
        string memory _title,
        string memory _description,
        uint256 _amount,
        string memory _coin // BUSD 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E
        )public tokenValid(_coin) returns(bool){

        if(_buyer == msg.sender){
        acceptance[_current] = agreement(0,0,true,false);
        deals[_current] = metadataDeal(msg.sender, _seller, _title, _description, _amount, 0, 0, block.timestamp, _coin);
        }else if(_seller == msg.sender){
        acceptance[_current] = agreement(0,0,false,true);
        deals[_current] = metadataDeal(_buyer, msg.sender, _title, _description, _amount, 0, 0, block.timestamp, _coin);
        } else{
            revert("You are not a Buyer or Seller");
        }
        
        return(true);
    }

    function depositGoods(uint256 _dealID)public openDeal(_dealID) isPartTaker(_dealID) { 
        // TODO> hacer test a esta funcion
        // TODO> Aplicar SAFE MATH lib
        // TODO> Aplicar reverts en caso de no completarse la transaccion
        require(deals[_dealID].buyer == msg.sender, "Your are not the buyer");
        _token = IERC20 (tokens[deals[_dealID].coin]);
        _token.transferFrom(msg.sender, address(this), deals[_dealID].amount);
        deals[_dealID].goods += deals[_dealID].amount;
    }

    function payDeal(uint256 _dealID)public openDeal(_dealID){
        // TODO> Aplicar SAFE MATH lib
        // TODO> Aplicar reverts en caso de no completarse la transaccion
        // TODO> Hacer funcion para quitar FEES
        _token = IERC20 (tokens[deals[_dealID].coin]);

        uint256 _newAmount = deals[_dealID].amount - 100;
        uint256 _fee = deals[_dealID].amount - _newAmount;

        require(_fee > 0, "Fee is lower than 0");
        deals[_dealID].goods -= deals[_dealID].amount;

        // send the Fee to owner
        _token.transfer(owner, _fee);
        // send to Seller tokens
        _token.transfer(deals[_dealID].seller, _newAmount);
        // TODO> transferir FEES al owner

    }

    function refundBuyer(uint256 _dealID)public cancelledDeal(_dealID){
        // TODO> hacer funcion para refund
        deals[_dealID].goods -= deals[_dealID].amount;
        _token.transfer(deals[_dealID].seller, deals[_dealID].amount);

    }

    function feeCalculation()private{
        // TODO> Hacer funcion para quitar FEES
    }

    function acceptDraft(uint256 _dealID, bool _decision)public openDraft(_dealID) isPartTaker(_dealID){
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

    function partTakerDecision(uint256 _dealID, uint8 _decision)public isPartTaker(_dealID) openDeal(_dealID){
        require((_decision > 0 && _decision < 3), "Only choose between of: 1 = Accepted, 2 = Cancelled");
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerChoose = _decision;
        }
    }


    function finishDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) returns(string memory status){
        //both want to proceed and finish
        if(acceptance[_dealID].buyerChoose == 1 && acceptance[_dealID].sellerChoose == 1){
            // TODO: Pendiente para envio de tokens y quitar fees
            deals[_dealID].status = 2; //close
            //TODO> Pendiente de enviar evento
            return("Deal was succesfully CLOSED");
        }
        //both want to cancel and finish
        if(acceptance[_dealID].buyerChoose == 2 && acceptance[_dealID].sellerChoose == 2){
            // TODO: Pendiente para reembolso de tokens y quitar fees
            deals[_dealID].status = 3; //cancel
            //TODO> Pendiente de enviar evento
            return("Deal was CANCELLED");
        } else {
            revert("Buyer and Seller must be agree with the same decision");
        }
    }

   

    
}