// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 


contract data_var{

    uint256 public defaultLifeTime;
    uint256 public defaultFee;
    uint256 public defaultPenalty;
    address payable owner;

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 _token;
    Counters.Counter private _idCounter;

    struct metadataDeal{
        address buyer; //0x5B38Da6a701c568545dCfcB03FcB875f56beddC4
        address seller; //0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
        string title; //TITULO RANDOM CON PALABRAS RANDOM
        string description; 
        uint256 amount; //Price Deal offer 01234567890123456789
        uint256 goods; // Tokens holded in current deal
        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= tribunal
        uint256 created;
        uint256 deadline; //deadline in timestamp
        string coin;
    }

    //choose (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)
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
    
    // tokens contract > decimals
    mapping(string => uint) public tokenDecimal;

    // EVENTS
    event _dealEvent(uint256 ID, string TOKEN, bool STATUSCREATE);

    constructor(address _tokenAddress, string memory _tokenName,  uint256 _tokenDecimal,uint256 _defaultPenalty){
        // TODO> Agregar funciones para la proteccion de tiempos del BUYER
        // TODO> Agregar funcion para modificar defaultLifeTime
        // TODO> Agregar funcion para modificar limitLifeTime para limite proteccion de tiempos del BUYER
        // TODO> solucionar defaultpenalty para ir acorder a los decimales del token

        owner = payable(msg.sender);
        tokens[_tokenName] = _tokenAddress;
        tokenDecimal[_tokenName] = _tokenDecimal;
        defaultFee = 150; 
        defaultPenalty = _defaultPenalty;
        defaultLifeTime = 604800;
        //================================================================
        // Rinkeby ETH testnet
        // BUSD 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E //decimals 18
        // USDT 0xD9BA894E0097f8cC2BBc9D24D308b98e36dc6D02 //decimals 18
        // USDC 0xeb8f08a975Ab53E34D8a0330E0D34de942C95926 //decimals 6
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

    modifier tokenValid(string memory _tokenName){
        require(tokens[_tokenName] != address(0),"This token is not supported by the contract");
        _;
    }

    modifier aboveOfZero(uint256 _amount){
        require(_amount > 0, "You only can send above of 0 wei");
        _;
    }

    // Change Defaults parms
    function _changeDefaultFee(uint256 _newDefaultFee) public{
        // use Points Basis 1% = 100
        require(msg.sender == owner, "Only Owner can change it");
        require((_newDefaultFee >= 10),"Fee need be in Points Basis MIN 0.1% = 10" );
        require((_newDefaultFee <= 1000),"Fee need be in Points Basis MAX 10% = 1000");
        defaultFee = _newDefaultFee;
    }

    function _changeDefaultPenalty(uint256 _newDefaultPenalty) public{
        require(msg.sender == owner, "Only Owner can change it");
        defaultPenalty = _newDefaultPenalty;
    }

    function _changeDefaultLifeTime(uint256 _newDefaultLifeTime) public{
        require(msg.sender == owner, "Only Owner can change it");
        defaultLifeTime = _newDefaultLifeTime;
    }

    function _addNewToken(string memory _tokenName, address _tokenAddress)public {
        require(msg.sender == owner, "Only Owner can add a token it");
        require(tokens[_tokenName] == address(0), "This token already exists");
        
        tokens[_tokenName] = _tokenAddress;
    }

    function createDeal(
        // TODO> hacer test a esta funcion y revisar que el _newDeadline funcione
        address _buyer, // 0xd20fD73BFD6B0fCC3222E5b881AB03A24449E608
        address _seller, // 0xd92A8d5BCa7076204c607293235fE78200f392A7
        string memory _title,
        string memory _description,
        uint256 _amount,
        string memory _coin, // BUSD 0x4e2442A6f7AeCE64Ca33d31756B5390860BF973E
        uint256 _deadlineInDays

        )public tokenValid(_coin) aboveOfZero(_amount) returns(bool){
        
        require(_deadlineInDays >= 0 && _deadlineInDays <= 30,"Deadline is in days between 0 to 30");

        uint256 _newDeadline = deadlineCal(_deadlineInDays);
        uint256 _current = _idCounter.current();

        if(_buyer == msg.sender){
        acceptance[_current] = agreement(0,0,true,false);
        deals[_current] = metadataDeal(msg.sender, _seller, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin);
        _idCounter.increment();
        }else if(_seller == msg.sender){
        acceptance[_current] = agreement(0,0,false,true);
        deals[_current] = metadataDeal(_buyer, msg.sender, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin);
        _idCounter.increment();
        } else{
            revert("You are not a Buyer or Seller");
        }
        
        emit _dealEvent( _current,  _coin,  true);
        return(true);
    }

    function deadlineCal(uint256 _deadlineInDays)internal view returns(uint256){
        // TODO> hacer test a esta funcion y revisar que el _newDeadline funcione en createDeal
        if(_deadlineInDays > 0){
            (bool _flagMul,uint256 secs) = SafeMath.tryMul(_deadlineInDays, 86400);
            if(!_flagMul) revert("_flagMul overflow");

            (bool _flagAdd, uint256 _newDeadline) = SafeMath.tryAdd(secs,block.timestamp);
            if(!_flagAdd) revert("_flagAdd overflow");

            return(_newDeadline);
        }else{
            (bool _flagAddDeadline, uint256 _defaultDeadline) = SafeMath.tryAdd(defaultLifeTime, block.timestamp);
            if(!_flagAddDeadline) revert("_flagAddDeadline overflow");

            return(_defaultDeadline); 
        }
    }
    
    function depositGoods(uint256 _dealID)public openDeal(_dealID) isPartTaker(_dealID) { 
        // TODO> Pendiente por hacer Test para el require Allowance
        _token = IERC20 (tokens[deals[_dealID].coin]);
        require(_token.allowance(msg.sender, address(this)) >= deals[_dealID].amount, "First increaseAllowance in the ERC20 contract");
        require(deals[_dealID].buyer == msg.sender, "Your are not the buyer");


        (bool _success) =_token.transferFrom(msg.sender, address(this), deals[_dealID].amount);
        if(!_success) revert("Problem paying FEE");
        
        deals[_dealID].goods += deals[_dealID].amount;
    }

    function payDeal(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        _token = IERC20 (tokens[deals[_dealID].coin]);
        uint256 _fee = feeCalculation(deals[_dealID].amount);

        require(_fee > 0, "Fee is lower than 0");
        require(deals[_dealID].goods > 0, "No tokens left");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and deal Amount have diff value");

        //closing the Deal as completed
        deals[_dealID].status = 2;

        (bool flagAmountFee, uint256 _newAmount)= SafeMath.trySub(deals[_dealID].amount, _fee);
        if(!flagAmountFee) revert("flagAmountFee overflow");

        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 3;
        acceptance[_dealID].sellerChoose = 3;

        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _fee);
        if(!_success) revert("Problem paying FEE");
        // send to Seller tokens
        (bool _successSeller) = _token.transfer(deals[_dealID].seller, _newAmount);
        if(!_successSeller) revert("Problem paying SELLER");

        return(true);
    }

    function refundBuyer(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        // TODO> pendiente de testear el calculo del penalty
        _token = IERC20 (tokens[deals[_dealID].coin]);
        
        require(deals[_dealID].goods > 0, "No tokens left");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and deal Amount have diff value");

        deals[_dealID].status = 3; //cancel
        uint256 _refundAmount = deals[_dealID].goods;
        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 4;
        acceptance[_dealID].sellerChoose = 4;
        
        uint256 _newPenalty = (defaultPenalty * 10 ** tokenDecimal[deals[_dealID].coin]);
        (bool flagPenalty, uint256 _newamount)= SafeMath.trySub(_refundAmount, _newPenalty);
        if(!flagPenalty) revert("flagPenalty overflow");

        uint256 _penaltyFee = _refundAmount -= _newamount;
        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _penaltyFee);
        if(!_success) revert("Problem paying PENALTY");
       
        (bool _successBuyer)= _token.transfer(deals[_dealID].buyer, _newamount);
        if(!_successBuyer) revert("Problem with REFUND TOKENS");

        return(true);
    }

    function feeCalculation(uint256 _amount)internal view returns (uint256){

        (bool flagMultiply,uint256 mult) = SafeMath.tryMul(_amount, defaultFee);
        if(!flagMultiply) revert("flagMultiplye overflow");
        
        (bool flagDiv, uint256 _fee) = SafeMath.tryDiv(mult,10000);
        if(!flagDiv) revert("flagDiv overflow or divided by zero");

        (bool flagAmountFee, uint256 _diff)= SafeMath.trySub(_amount, _fee);
        if(!flagAmountFee) revert("flagAmountFee overflow");

        (bool flagFee, uint256 _newAmount)= SafeMath.trySub(_amount, _diff);
        if(!flagFee) revert("flagFee overflow");
        return(_newAmount);
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
        require(deals[_dealID].goods == deals[_dealID].amount, "Buyer need send the tokens before to make a decision");
        require((_decision > 0 && _decision < 3), "Only choose between of: 1 = Accepted, 2 = Cancelled");
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerChoose = _decision;
        }
    }


    function cancelDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to cancel and finish
        require(msg.sender == deals[_dealID].buyer,"Only Buyer can ask for refund");
        require((acceptance[_dealID].buyerChoose == 2 && acceptance[_dealID].sellerChoose == 2),"Buyer and Seller must be agree with the same decision");
            
        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert("Problem with refundBuyer");

    }

    function completeDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to proceed and finish
        require(msg.sender == deals[_dealID].seller, "Only Seller can claim tokens");
        require((acceptance[_dealID].buyerChoose == 1 && acceptance[_dealID].sellerChoose == 1),"Buyer and Seller must be agree with the same decision");

        (bool _flag) = payDeal(_dealID);
        if(!_flag) revert("Problem with payDeal");


    }



}