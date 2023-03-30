// SPDX-License-Identifier: MIT
pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/utils/Counters.sol"; 


contract proposals{
    using Counters for Counters.Counter;

    Counters.Counter private _idCounter;

    struct historyUpdates{
        uint256 lastUpdateId;
        uint8 buyerChoose;
        uint8 sellerChoose;
        //
        mapping(uint256 => proposal) proposalsInfo;
    }

    struct proposal{
        uint256 created;
        uint8 proposalType; // 0 = informative, 1 = update deadline
        uint8 accepted; //(0 = No answer, 1 = Accepted, 2 = Cancelled, 3 =  No changes, 4 = time updated)
        string description;
        bool proposalStatus;
    }


    // deal ID to history updates
    mapping(uint256 => historyUpdates) public updates;


    function newProposal(uint _dealID, address _dealBuyer, address _dealSeller, 
                        uint256 _lastProposal, uint8 _proposalType, string memory _description)
                        internal   {

        (, , , ,bool _status) = _seeProposals(_dealID, _lastProposal);
        
        if(_lastProposal > 0){
            require(_status,"First complete pending proposal before to create a new one");
        }
        
        historyUpdates storage _historyUpdates = updates[_dealID];
        _historyUpdates.lastUpdateId += 1;

        if(msg.sender == _dealBuyer){
             _historyUpdates.buyerChoose = 1;
        }

        if(msg.sender == _dealSeller){
             _historyUpdates.sellerChoose  = 1;
        }

        //deals[_dealID].numOfProposals = _historyUpdates.lastUpdateId;
        _historyUpdates.proposalsInfo[_historyUpdates.lastUpdateId] = proposal(block.timestamp, _proposalType, 0, _description, false);

    }
    function _deadlineUpdatedStatus(uint _dealId)internal{
        updates[_dealId].proposalsInfo[updates[_dealId].lastUpdateId].accepted = 4;
    }

    function _seeProposals(uint _dealId, uint _proposalId) internal  view returns(uint256, uint8, uint8, string memory, bool){
        proposal memory _info = updates[_dealId].proposalsInfo[_proposalId];
        return(_info.created,_info.proposalType,_info.accepted, _info.description, _info.proposalStatus);
    }


    function proposalChoose(uint _dealID, uint256 _lastProposal ,address _dealBuyer, address _dealSeller ,uint8 _choose) internal{

        historyUpdates storage _historyUpdates = updates[_dealID];

        if(msg.sender == _dealBuyer){
            _historyUpdates.buyerChoose = _choose;
        }

        if(msg.sender == _dealSeller){
            _historyUpdates.sellerChoose  = _choose;
        }

        uint8 _buyerChoose = _historyUpdates.buyerChoose;
        uint8 _sellerChoose= _historyUpdates.sellerChoose;

        //accepted
        if(_buyerChoose == 1 && _sellerChoose == 1){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 1;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;
        }

        //cancelled
        if(_buyerChoose == 2 && _sellerChoose == 2){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 2;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;
        }

        //no changes
        if(_buyerChoose > 0 && _sellerChoose > 0){
            updates[_dealID].proposalsInfo[_lastProposal].accepted = 3;
            updates[_dealID].proposalsInfo[_lastProposal].proposalStatus = true;
            _historyUpdates.buyerChoose = 0;
            _historyUpdates.sellerChoose  = 0;
            return;

        }
    }

}



