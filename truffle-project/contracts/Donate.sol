// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title Donate Ether to SeaLevelRaise
/// @author Josua Benz
/// @notice With this contract, you donate money to SeaLevelRaise.
contract Donate {

    // MW: should wallet address be saved as well?
   struct Donater{
    string mail;
    uint donatedAmount;
   }

    event DonaterAdded(uint id,string mail, uint donatedAmount);
    event DonationAdded(uint id,string mail, uint amount);
    Donater[] private donaters;
    mapping (address => uint) public idToOwner;

    //mapping if user has donated money
    // MW: if this is a yes or no question, why is it an uint and not a boolean?
    mapping(address => uint) public userHasDonated;

    /// @notice Donate Ether to SeaLevelRaise
    receive() external payable{
        //donations of less than 1 finney will be rejected 
        //MW: this contract will be in the blockchain for ever. Maybe 1 finney becomes a lot of money one day and then this contract will work worse.
        if(msg.value < 1e15) {
            revert();
        }
    }

    function getContractBalance() public view returns (uint) {
        return address(this).balance;
    }

    /// @notice Update the amount when a Donater has donated. If the donater donated for the first time create new Donater and add it to array.
    /// @param _mail Mail of the User
    /// @param _amount Amount the User has donated
    function updateDonatedAmount(string memory _mail, uint _amount) public{
        if(userHasDonated[msg.sender] == 0){
            _createDonater(_amount);
            bytes memory tempEmptyStringTest = bytes(_mail); // Uses memory
            if(tempEmptyStringTest.length != 0) {
                _addMailToDonater(_mail);
            }
            //mapping that this user has donated money to SLR
            userHasDonated[msg.sender] = 1;
               
        }else {
            bytes memory tempEmptyStringTest = bytes(_mail); // Uses memory
            if(tempEmptyStringTest.length != 0) {
                _addMailToDonater(_mail);
            }
            uint id = idToOwner[msg.sender];
            donaters[id].donatedAmount += _amount;
            uint amount = donaters[id].donatedAmount;
            emit DonationAdded(id, _mail, amount);
        }
    }

    /// @notice Create new Donater and add it to the array
    /// @param _amount Amount the User has donated
    function _createDonater(uint _amount) internal {
        string memory mail = '';
        donaters.push(Donater(mail, _amount));
        uint id = donaters.length -1;
        idToOwner[msg.sender] = id;
        emit DonaterAdded(id, mail, _amount);
    }

    /// @notice Add Mail to a Donater if mail was set in frontend
    /// @param _mail Mail of the User
    // MW: What if msg.sender is not a doner yet? id would be -1? error thrown when array of out boundries?
    // MW: maybe needs a function to change email adress?
    function _addMailToDonater(string memory _mail) internal {
        uint id= idToOwner[msg.sender];
        donaters[id].mail = _mail;
    }

    function changeDonatorMailAdress(string memory _mail) public  {
        if(userHasDonated[msg.sender] == 1){
            uint id= idToOwner[msg.sender];
            donaters[id].mail = _mail;
        }
            // MW: implement an email regex to prevent injections etc into the Smart Contract? Needed?
            // MW: how to make sure that private data is not visible on the on-chain network and can only be seen from within the Smart Contract, or rights to alter by the owner?
            // MW: to prevent fishing of emails, there should not be a return value as it would give away whether the email is used or not.
    }

    /// @notice Get Number of Donaters
    // MW: shouldn't donaters.length already give the return value? unless its suppose to uniquely count donors, but this code is not implemented beneath
    function getNumberOfDonaters() public view returns(uint){
        uint numberOfUsers;
        for(uint i=0; i<donaters.length; i++) {
            numberOfUsers++;
        }
        return numberOfUsers;
    }

    /// @notice Get Details for a User that has donated 
    function getDonaterDetails() public view returns(Donater memory){
        if(userHasDonated[msg.sender] == 1){
            uint id = idToOwner[msg.sender];
            return donaters[id];
        } else {
            revert('User has not donated');
        }
    }

}
