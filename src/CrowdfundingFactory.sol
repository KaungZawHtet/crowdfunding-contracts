// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import {Crowdfunding} from "./Crowdfunding.sol";

contract CrowdfundingFactory {
    address public owner;
    bool public paused;

    struct Campaign {
        address campaignAddress;
        address owner;
        string name;
        uint256 creationTime;
    }

    Campaign[] public campaigns;
    mapping(address => Campaign[]) public userCampaigns;

    modifier onlyOwner() {
        require(msg.sender == owner, "Not Owner");
        _;
    }
    modifier notPaused() {
        require(paused == false, "Factory is paused");
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function createCampaign(
        string memory name,
        string memory desc,
        uint256 goal,
        uint256 durationInDays
    ) external notPaused {
        Crowdfunding newCampaign = new Crowdfunding(
            name,
            desc,
            goal,
            durationInDays,
            msg.sender
        );

        address campaignAddress = address(newCampaign);

        Campaign memory campaign = Campaign({
            campaignAddress: campaignAddress,
            owner: msg.sender,
            name: name,
            creationTime: block.timestamp
        });

        campaigns.push(campaign);

        userCampaigns[msg.sender].push(campaign);


    }

    function getCampaignsByUser(address userAddress) public view returns(Campaign[] memory) {
        return userCampaigns[userAddress];
    }

    function getAllCampaigns() public view returns(Campaign[] memory ) {
        return campaigns;
    }

    function togglePaused() public {
        paused = !paused;
    }
}
