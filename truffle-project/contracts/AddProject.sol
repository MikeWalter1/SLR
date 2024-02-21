// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

/// @title Add a project to SeaLevelRaise or view all the projects already added
/// @author Josua Benz
/// @notice With this contract, you can add new projects in small states to SeaLevelRaise or get all the projects already added
/// @dev Check if country is a small state has to be implemented on the client side
contract AddProject {

    //definition of event, will be triggered when new project is added
    event ProjectAdded(uint id, string name, string state, string description, uint amount, uint startDate, uint endDate);
    
    // MW: Onboarding -> PO is not approved inside the DAO yet. Needs a guaranteer. 
    // MW: Voting -> Voting open for this project
    // MW: Started -> Voting completed, project has started and is awaiting its end
    // MW: Ended -> Project livetime has ended, and is awaiting an approving of the donators
    // MW: Completed -> Project has been successfully completed. PO can create a new project
    // MW: Failed -> Donators didn't confirm a successful completion. PO cannot create a new project
    enum ProjectState {Onboarding, Voting, Started, Ended, Completed, Failed}

   struct Donation{
    address owner;
    uint donatedMoney;
   }

    // timestamps have to be uint256, not able to safe gas in struct
    struct Project {
        address owner;
        string name;
        string state;
        string description;
        uint32 amount;
        uint32 votingTokens;
        uint startDate;
        uint endDate;
        string mail;
        ProjectState projectState;
    }

    //Array which contains all projects, saved on the blockchain
    Project[] public projects;

    //Mapping a project to the wallet of the person which added this project, saved on the blockchain
    mapping (uint => address) public projectToOwner;
    //Mapping the address of an owner to the ID of the project
    mapping(address => uint) public ownerToProject;
    //Mapping of the count of how many project the person already has created
    mapping (address => uint) ownerProjectCount;

    /// @notice Add new project to SeaLevelRaise. The sender is not allowed to add more than one project.
    /// @dev The Alexandr N. Tetearing algorithm could increase precision
    /// @param _name The name of the Project.
    /// @param _state The state in which the project is located. Check if this state is a small state has to be implemented in the front-end.
    /// @param _amount The amount of Ether the project wants to raise.
    function addProject(string memory _name, string memory _state, string memory _description, uint32 _amount, string memory _mail) public {
        //check whether user(address) has already created a project, if zero, then user can
        //create a new project, otherwise user cannot create new project
        //MW: How are projects deleted again to allow a new creation later on? Or does every project has it's own wallet? 
        //MW: If so, can we link wallets to each other to define the one project owner later on?
        //MW: obsolete as replaced with line below // require(ownerProjectCount[msg.sender] == 0);
        require(_canOwnerCreateNewProject(msg.sender) == true, "You already have one project in progress.");
        //current timestamp as startDate
        uint256 startDate = block.timestamp;
        uint256 endDate = startDate + 12 weeks;
        //add new project to array
        //MW: If owner is onboarded already, start in state "Voting" otherwise, start a project in "Onboarding"
        if (_isOwnerOnboarded(msg.sender))
            projects.push(Project(msg.sender, _name, _state, _description, _amount, 0, startDate, endDate, _mail, ProjectState.Voting));
        else
            projects.push(Project(msg.sender, _name, _state, _description, _amount, 0, startDate, endDate, _mail, ProjectState.Onboarding));
        //add mapping between project and wallet
        projectToOwner[projects.length-1] = msg.sender;
        ownerToProject[msg.sender] = projects.length-1;
        ownerProjectCount[msg.sender]++;
        //emit event "ProjectAdded"
        emit ProjectAdded(projects.length-1, _name, _state, _description, _amount, startDate, endDate);
    } 

    // MW: Rule -> Owner can only have one open project at a time.
    // MW: iterate through all projects and find whether Owner has an open project that is not "Completed". 
    function _canOwnerCreateNewProject(address _owner) internal view returns (bool){
        for (uint i=0; i<projects.length; i++) {
            if(projects[i].owner == _owner ){
                if(projects[i].projectState!=ProjectState.Completed)
                    return false;
            }
        }
        return true;
    }

    // MW: Checks whether owner has an project already that left the onboarding process and is thereby onboarded
    function _isOwnerOnboarded(address _owner) internal view returns(bool){
        for (uint i=0; i<projects.length; i++) {
            if(projects[i].owner == _owner && projects[i].projectState != ProjectState.Onboarding)
                return true;
        }
        return false;
    }

    function _startProject(uint id) internal {
        projects[id].projectState = ProjectState.Started;
    }

    function _endProject(uint id) internal {
        projects[id].projectState = ProjectState.Ended;
    }

    function _startOnboardingProject(uint id) internal {
        projects[id].projectState = ProjectState.Onboarding;
    }    

    // Info functions 
    /// @notice get the number of projects currently saved on the blockchain
    /// @return length the number of projects
    function getNumberOfProjects() public view returns(uint) {
        return projects.length;
    }

    /// @notice get the details of a project
    /// @param _id ID of the project
    /// @return Project the number of projects
    function getProjectDetails(uint _id) public view returns(Project memory) {
        if( _id < projects.length){
            return projects[_id];
        }
        else {
            revert('project id does not exist');
        }
    }

    /// @notice check if the account is a project owner
    /// @return projectID if account is owner
    function getProjectOwner() public view returns(uint) {
        if(ownerProjectCount[msg.sender] == 1){
            return ownerToProject[msg.sender];

        }else{
            revert('no project added');
        }
    } 

}
