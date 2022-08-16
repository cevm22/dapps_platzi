// SPDX-License-Identifier: MIT

pragma solidity >=0.8.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 
import "@openzeppelin/contracts/utils/math/SafeMath.sol"; 
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol"; 
import "./proposals.sol";

contract data_var is proposals {

    uint256 public defaultLifeTime;
    uint256 public defaultFee;
    uint256 public defaultPenalty;
    address payable owner;
    address payable oracle;
    address payable tribunal;

    using SafeERC20 for IERC20;
    using Counters for Counters.Counter;
    using SafeMath for uint256;

    IERC20 _token;
    Counters.Counter private _idCounter;

    struct metadataDeal{
        address buyer; 
        address seller; 
        string title;
        string description; 
        uint256 amount; 
        uint256 goods; 
        uint16 status; //0=pending, 1= open, 2= completed, 3= cancelled, 4= tribunal
        uint256 created;
        uint256 deadline; // timestamp
        string coin;
        uint256 numOfProposals;
    }

    // (0 = No answer, 1 = Accepted, 2 = Cancelled, 3 = Paid, 4 = Refund)
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

    function _addNewToken(string memory _tokenName, address _tokenAddress, uint256 _tokenDecimal)public {
        require(msg.sender == owner, "Only Owner can add a token it");
        require(tokens[_tokenName] == address(0), "This token already exists");
        
        tokens[_tokenName] = _tokenAddress;
        tokenDecimal[_tokenName] = _tokenDecimal;
    }


// TODO> HACER TEST PARA IMPORTAR LAS FUNCIONES PARA LAS PROPUESTAS
// TODO> HACER FUNCIONES PARA EL ORACULO
// TODO> HACER FUNCIONES PARA EL TRIBUNAL
    function _updateDeadline(uint256 _dealID, uint256 _addDays)public openDeal(_dealID) isPartTaker(_dealID) returns(bool){
        // TODO> Agregar nueva variable para actualizacion de decisiones
        (,uint8 _proposalType, uint8 _accepted, , bool _status) = _seeProposals(_dealID,deals[_dealID].numOfProposals);

        require(deals[_dealID].buyer == msg.sender, "Only BUYER");
        require(deals[_dealID].numOfProposals > 0,"First make a proposal");
        require(_proposalType == 1,"NOT deadline type");
        require(_accepted == 1, "not accepted");
        require(_status == true, "still pending ");

        deals[_dealID].deadline = deadlineCal(_addDays);
        return(true);
    }



    function _newProposal(uint _dealID, uint8 _proposalType, string memory _description) 
                        public openDeal(_dealID) isPartTaker(_dealID) returns(bool){

        newProposal( _dealID,  deals[_dealID].buyer,  deals[_dealID].seller, deals[_dealID].numOfProposals,  _proposalType,   _description);
        deals[_dealID].numOfProposals += 1;
        return true;
    }

    function _proposalChoose(uint _dealID, uint8 _choose)public openDeal(_dealID) isPartTaker(_dealID) returns(bool){

       proposalChoose(_dealID, deals[_dealID].numOfProposals, deals[_dealID].buyer, deals[_dealID].seller, _choose);
       return true;
    }
    function __seeProposals(uint _dealId, uint _proposalId)  public view returns(uint256, uint8, uint8, string memory, bool){
        (uint256 created, uint8 proposalType, uint8 accepted, string memory _description, bool proposalStatus) = _seeProposals(_dealId, _proposalId);
        return(created, proposalType, accepted, _description, proposalStatus);
    }

    function createDeal(
        address _buyer, 
        address _seller, 
        string memory _title,
        string memory _description,
        uint256 _amount,
        string memory _coin, 
        uint256 _deadlineInDays

        )public tokenValid(_coin) aboveOfZero(_amount) returns(bool){
        
        require(_deadlineInDays >= 0 && _deadlineInDays <= 30,"Deadline in days. 0 to 30");

        uint256 _newDeadline = deadlineCal(_deadlineInDays);
        uint256 _current = _idCounter.current();

        if(_buyer == msg.sender){
        acceptance[_current] = agreement(0,0,true,false);
        deals[_current] = metadataDeal(msg.sender, _seller, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin, 0);
        _idCounter.increment();
        }else if(_seller == msg.sender){
        acceptance[_current] = agreement(0,0,false,true);
        deals[_current] = metadataDeal(_buyer, msg.sender, _title, _description, _amount, 0, 0, block.timestamp, _newDeadline, _coin, 0);
        _idCounter.increment();
        } else{
            revert("only B or S");
        }
        
        emit _dealEvent( _current,  _coin,  true);
        return(true);
    }

    function deadlineCal(uint256 _deadlineInDays)internal view returns(uint256){
        // TODO> hacer test a esta funcion y revisar que el _newDeadline funcione en createDeal
        if(_deadlineInDays > 0){
            (bool _flagMul,uint256 secs) = SafeMath.tryMul(_deadlineInDays, 86400);
            if(!_flagMul) revert();

            (bool _flagAdd, uint256 _newDeadline) = SafeMath.tryAdd(secs,block.timestamp);
            if(!_flagAdd) revert();

            return(_newDeadline);
        }else{
            (bool _flagAddDeadline, uint256 _defaultDeadline) = SafeMath.tryAdd(0, block.timestamp);//SafeMath.tryAdd(defaultLifeTime, block.timestamp);
            if(!_flagAddDeadline) revert();

            return(_defaultDeadline); 
        }
    }
    
    function depositGoods(uint256 _dealID)public openDeal(_dealID) isPartTaker(_dealID) { 
        // TODO> Pendiente por hacer Test para el require Allowance
        _token = IERC20 (tokens[deals[_dealID].coin]);
        require(_token.allowance(msg.sender, address(this)) >= deals[_dealID].amount, "First increaseAllowance to ERC20 contract");
        require(deals[_dealID].buyer == msg.sender, "only buyer");


        (bool _success) =_token.transferFrom(msg.sender, address(this), deals[_dealID].amount);
        if(!_success) revert();
        
        deals[_dealID].goods += deals[_dealID].amount;
    }

    function payDeal(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        _token = IERC20 (tokens[deals[_dealID].coin]);
        uint256 _fee = feeCalculation(deals[_dealID].amount);

        require(_fee > 0, "Fee > 0");
        require(deals[_dealID].goods > 0, "No tokens ");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and Amount diff value");

        //closing the Deal as completed
        deals[_dealID].status = 2;

        (bool flagAmountFee, uint256 _newAmount)= SafeMath.trySub(deals[_dealID].amount, _fee);
        if(!flagAmountFee) revert();

        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 3;
        acceptance[_dealID].sellerChoose = 3;

        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _fee);
        if(!_success) revert();
        // send to Seller tokens
        (bool _successSeller) = _token.transfer(deals[_dealID].seller, _newAmount);
        if(!_successSeller) revert();

        return(true);
    }

    function refundBuyer(uint256 _dealID)internal openDeal(_dealID) returns(bool){
        // TODO> Agregar anti Reentry Guard
        // TODO> pendiente de testear el calculo del penalty
        _token = IERC20 (tokens[deals[_dealID].coin]);
        
        require(deals[_dealID].goods > 0, "No tokens ");
        require(deals[_dealID].goods == deals[_dealID].amount, "Goods and Amount diff value");

        deals[_dealID].status = 3; //cancel
        uint256 _refundAmount = deals[_dealID].goods;
        deals[_dealID].goods = 0;
        acceptance[_dealID].buyerChoose = 4;
        acceptance[_dealID].sellerChoose = 4;
        
        uint256 _newPenalty = (defaultPenalty * 10 ** tokenDecimal[deals[_dealID].coin]);
        (bool flagPenalty, uint256 _newamount)= SafeMath.trySub(_refundAmount, _newPenalty);
        if(!flagPenalty) revert();

        uint256 _penaltyFee = _refundAmount -= _newamount;
        // send the Fee to owner
        (bool _success)=_token.transfer(owner, _penaltyFee);
        if(!_success) revert();
       
        (bool _successBuyer)= _token.transfer(deals[_dealID].buyer, _newamount);
        if(!_successBuyer) revert();

        return(true);
    }

    function feeCalculation(uint256 _amount)internal view returns (uint256){

        (bool flagMultiply,uint256 mult) = SafeMath.tryMul(_amount, defaultFee);
        if(!flagMultiply) revert();
        
        (bool flagDiv, uint256 _fee) = SafeMath.tryDiv(mult,10000);
        if(!flagDiv) revert();

        (bool flagAmountFee, uint256 _diff)= SafeMath.trySub(_amount, _fee);
        if(!flagAmountFee) revert();

        (bool flagFee, uint256 _newAmount)= SafeMath.trySub(_amount, _diff);
        if(!flagFee) revert();
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
        require(deals[_dealID].goods == deals[_dealID].amount, "Buyer need send the tokens");
        require((_decision > 0 && _decision < 3), "1 = Accepted, 2 = Cancelled");
        if(msg.sender == deals[_dealID].buyer){
            acceptance[_dealID].buyerChoose = _decision;
        }
        if(msg.sender == deals[_dealID].seller){
            acceptance[_dealID].sellerChoose = _decision;
        }
    }


    function cancelDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to cancel and finish
        require(msg.sender == deals[_dealID].buyer,"Only Buyer");
        require((acceptance[_dealID].buyerChoose == 2 && acceptance[_dealID].sellerChoose == 2),"B&S must be agree");
            
        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert();

    }

    function completeDeal(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID) {
        //both want to proceed and finish
        require(msg.sender == deals[_dealID].seller, "Only Seller can claim tokens");
        require((acceptance[_dealID].buyerChoose == 1 && acceptance[_dealID].sellerChoose == 1),"B&S must be agree");

        (bool _flag) = payDeal(_dealID);
        if(!_flag) revert();


    }

    function buyerAskDeadline(uint256 _dealID)public isPartTaker(_dealID) openDeal(_dealID){
        // agregar validacion de cuando se pueda solicitar en el deal
        require(msg.sender == deals[_dealID].buyer,"Only Buyer");
        require(deals[_dealID].deadline < block.timestamp, "Seller still have time");

        (bool _flag) = refundBuyer(_dealID);
        if(!_flag) revert();
    }

}