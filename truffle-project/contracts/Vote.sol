// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

import "./Donate.sol";

/// @title Vote for the project the user wants to donate the money to
/// @author Josua Benz
/// @notice With this contract, you can vote for the project you want to donate the money to
/// @dev uses the userHasVoted mapping from Donate.sol
contract Vote is Donate {
    //mapping if a user has voted for a project, saved  on the blockchain
    // MW: user can only vote once. in a lifetime! needs a different implementation.
    mapping(address => uint) public userHasVoted;

    struct VoteForProject {
        address user;
        uint projectId;
        uint votingTokens;
    }
    //list with all the votes, saved  on the blockchain
    VoteForProject[] public votes;
    
    /// @notice Vote for a project in SeaLevelRaise. The user is not allowed to vote more than one time and only if they have donated.
    /// @dev uses userHasDonated from Contract Donate.sol
    /// @param _projectId The ID of the Project the user wants to vote for.
    function voteForProject(uint _projectId, uint _amountVotingTokens) public {
        //MW: check whether donator has enough tokens
        //MW: todo check whether it even is a donator 
        require(_hasDonatorVotingTokens(_amountVotingTokens));
        //the user is required to have donated and to not have voted already
        require(userHasDonated[msg.sender] == 1);
        require(userHasVoted[msg.sender] != 1);
        spendVotingTokensOnProject(_projectId, _amountVotingTokens);
        //add this vote to the list of votes
        votes.push(VoteForProject(msg.sender, _projectId, _amountVotingTokens));

        //mapping, that this user has voted
        userHasVoted[msg.sender] = 1;
    }

        //MW: added
    function spendVotingTokensOnProject(uint _projectId, uint _amountVotingTokens) public {
        uint id = idToOwner[msg.sender];
        if(_hasDonatorVotingTokens(_amountVotingTokens)==true) {
            removeDonatorToken(_projectId, _amountVotingTokens);
        }
    }

    /// @notice Get the amount of votes of one project
    /// @param _projectId The ID of the project
    /// @return _votesForThisProject amount of votes for this project
    function getAmountOfVotes(uint _projectId) public view returns (uint) {
        //count the amount of votes for this project
        uint _votesForThisProject=0;
        for(uint i=0; i<votes.length; i++) {
            if(votes[i].projectId == _projectId) {
                _votesForThisProject++;
            }
        }
        return _votesForThisProject;
    }
}
