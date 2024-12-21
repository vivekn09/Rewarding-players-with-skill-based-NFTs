// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract SkillBasedNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _tokenIds;

    // Mapping to store player skills and achievements
    mapping(address => mapping(string => uint256)) public playerSkills;
    mapping(uint256 => string) public nftSkillLevel;
    
    // Skill thresholds for different NFT tiers
    uint256 public constant BRONZE_THRESHOLD = 100;
    uint256 public constant SILVER_THRESHOLD = 250;
    uint256 public constant GOLD_THRESHOLD = 500;
    uint256 public constant DIAMOND_THRESHOLD = 1000;

    // Events
    event SkillIncreased(address player, string skillName, uint256 newLevel);
    event NFTRewarded(address player, uint256 tokenId, string skillLevel);

    constructor() ERC721("Skill Based NFT", "SKNFT") Ownable(msg.sender) {}

    // Function to increase player skill points
    function increaseSkill(address player, string memory skillName, uint256 points) 
        external 
        onlyOwner 
    {
        require(points > 0, "Points must be greater than 0");
        playerSkills[player][skillName] += points;
        emit SkillIncreased(player, skillName, playerSkills[player][skillName]);

        // Check if player qualifies for a new NFT
        checkAndRewardNFT(player, skillName);
    }

    // Internal function to check and reward NFT based on skill level
    function checkAndRewardNFT(address player, string memory skillName) internal {
        uint256 skillLevel = playerSkills[player][skillName];
        string memory tier;

        if (skillLevel >= DIAMOND_THRESHOLD) {
            tier = "Diamond";
        } else if (skillLevel >= GOLD_THRESHOLD) {
            tier = "Gold";
        } else if (skillLevel >= SILVER_THRESHOLD) {
            tier = "Silver";
        } else if (skillLevel >= BRONZE_THRESHOLD) {
            tier = "Bronze";
        } else {
            return;
        }

        // Mint NFT if player reaches new threshold
        _mintSkillNFT(player, skillName, tier);
    }

    // Internal function to mint NFT
    function _mintSkillNFT(address player, string memory skillName, string memory tier) 
        internal 
        returns (uint256) 
    {
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        // Construct token URI based on skill and tier
        string memory tokenURI = string(abi.encodePacked(
            "https://api.example.com/nft/",
            skillName,
            "/",
            tier,
            "/",
            newTokenId.toString()
        ));

        _mint(player, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        nftSkillLevel[newTokenId] = tier;

        emit NFTRewarded(player, newTokenId, tier);
        return newTokenId;
    }

    // Function to view player's skill level
    function getPlayerSkill(address player, string memory skillName) 
        external 
        view 
        returns (uint256) 
    {
        return playerSkills[player][skillName];
    }

    // Function to get NFT details
    function getNFTDetails(uint256 tokenId) 
        external 
        view 
        returns (string memory) 
    {
        require(_exists(tokenId), "NFT does not exist");
        return nftSkillLevel[tokenId];
    }

    // Internal function to check if a token exists
    function _exists(uint256 tokenId) internal view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}