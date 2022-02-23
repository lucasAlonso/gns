//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.0;

//importante agregar events!!!!

contract Multisign {
    address private _owner;
    mapping(address => uint8) private _voters;
    uint256 public numVotesRequired;
    uint256 public numProposals;
    bool public endedLastProposal;
    uint256 public votes;

    struct Proposal {
        bool status;
        uint16 newFee;
        uint8 signatureCount;
        mapping(address => uint8) signatures;
    }
    mapping(uint256 => Proposal) private _proposalsById;

    modifier isOwner() {
        require(msg.sender == _owner);
        _;
    }

    modifier validVoter() {
        require(msg.sender == _owner || _voters[msg.sender] == 1);
        _;
    }

    constructor() {
        _owner = msg.sender;
        numProposals = 0;
        endedLastProposal = true;
    }

    function addVoter(address voter) public isOwner {
        _voters[voter] = 1;
    }

    function removeOwner(address voter) public isOwner {
        _voters[voter] = 0;
    }

    function addProposal(uint16 _newFee) public returns (uint256 proposalId) {
        require(endedLastProposal);
        proposalId = numProposals++;
        Proposal storage proposal = _proposalsById[proposalId];
        proposal.newFee = _newFee;
        proposal.signatureCount = 0;
        proposal.status = false;
    }

    function signProposal() public validVoter {
        Proposal storage proposal = _proposalsById[numProposals]; //check that its the las proposal
        require(proposal.signatures[msg.sender] != 1);
        proposal.signatures[msg.sender] = 1;
        proposal.signatureCount++;
    }

    function changeFee() public returns (uint16 feeAproved) {
        Proposal storage proposal = _proposalsById[numProposals];
        require(proposal.signatureCount > numVotesRequired - 1);
        return proposal.newFee;
    }
}
