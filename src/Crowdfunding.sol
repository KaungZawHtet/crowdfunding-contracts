// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

contract Crowdfunding{

    string public name; // compaign name

    string public  description;

    uint256 public goal;

    uint256 public  deadline;

    address public  owner;//wallet address of the deployer of this contract

    Tier[] public  tiers;

    CompaignState public  state;

    mapping (address => Backer) public backers;

    bool public IsPaused;


    enum CompaignState {Active, Successful, Failed }



    constructor(string memory _name,
        string memory _des,
        uint256 _goal,
        uint256  _durationsInDay,
        address _owner
        ) {

            name = _name;
            description = _des;
            goal = _goal;
            deadline= block.timestamp + ( _durationsInDay * 1 days);
            owner = _owner;//deployer address of this contract

            state = CompaignState.Active;
        }

    //drawing fund from the crowdfunding contarct to winner

    modifier OnlyOwner ()
    {
        require(msg.sender == owner, "Not the owner");
        _;
    }

    modifier CompaignOpen()
    {
        require(state == CompaignState.Active, "Campaign is not active");
        _;
    }

    modifier notPaused()
    {
        require(IsPaused == true, "Contract is paused");
        _;
    }


    struct Tier
    {
        string name;
        uint256 amount;
        uint256 backers;
    }

    struct Backer{
        uint256 totalContribution;
        mapping (uint => bool)  fundedTiers;
    }

     function fund(uint index) public payable CompaignOpen  notPaused

     // on payable func: u can see two main info msg.sender and msg.value. sender is address and value is actual amount
       {
        require(index < tiers.length && index >= 0 , "Invalid TierIndex" );
        require(msg.value == tiers[index].amount, "Invalid Funding. Funding should be same with amount in tier");
        require(block.timestamp < deadline, "Deadline of the campaign reached");

        tiers[index].backers++;
        backers[msg.sender].totalContribution += msg.value;
        backers[msg.sender].fundedTiers[index] = true;

        checkAndUpdateStatus();

    }

    function checkAndUpdateStatus() public  {

        if( state == CompaignState.Active )
        {

            if(block.timestamp < deadline)
            {
                state = address(this).balance >= goal ? CompaignState.Successful  : CompaignState.Failed;

            }
            else {
                state = address(this).balance >= goal ? CompaignState.Successful  : CompaignState.Active;

            }

        }
    }

    function addTier(string memory _name, uint256 _amount ) public OnlyOwner
    {
        require( _amount > 0, "amount must be greater than 0");
        tiers.push(Tier(
         _name, _amount,0
        ));
    }

    function removeTier (uint index) public  OnlyOwner
    {
        require( tiers.length > index && index >=0 , "out of index "  );

       tiers[index] = tiers[tiers.length - 1];
       tiers.pop();

    }

    function withdraw() public OnlyOwner {

        checkAndUpdateStatus();

        require(state ==  CompaignState.Successful, "Not successful yet");

        uint256 balance = address(this).balance;

        require(balance >=  goal, "goal hav not been reached");
         require(balance >  0, "No balance to withdraw");

        payable(owner).transfer(balance);

    }

    function getContractBalance() public view returns (uint256)  {


        return address(this).balance;
    }

    //this func is called by contributor
    function refund() public {
        checkAndUpdateStatus();
       // require(state == CompaignState.Failed,"Refund not allowed"); //if u want to test refund at active stage, cmt this line

        uint256 amount = backers[msg.sender].totalContribution ;


        backers[msg.sender].totalContribution = 0;

        payable(msg.sender).transfer(amount);

    }

    function hasFundTier(address _backer,uint tierIndex) public view returns (bool) {
        return backers[_backer].fundedTiers[tierIndex];
    }

    function getTiers() public view  returns (Tier[] memory) {
        return tiers;
    }

     function togglePaused(bool _paused)   public OnlyOwner {
        IsPaused = !_paused;
    }

    function getCampaignState () view public returns (CompaignState)
    {
        if(state == CompaignState.Active && block.timestamp > deadline)
        {
            return  address(this).balance >= goal? CompaignState.Successful :CompaignState.Failed;
        }

        return state;

    }

    function extendDeadline(uint _daysToAdd) public  OnlyOwner CompaignOpen{
        deadline += _daysToAdd * 1 days;
    }


}