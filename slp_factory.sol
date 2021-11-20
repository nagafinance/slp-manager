// SPDX-License-Identifier: MIT
// AUTHOR: yoyoismee.eth

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// @notice just a push payment spliter. not the best practice. use it on trusted address only
contract NagaGuild is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 constant ONE = 1e18;

    struct guild {
        address guildOwner;
        uint256 balance;
    }

    string[] guildNames;

    struct scholar {
        address scholarWallet;
        string scholarRoninAddress;
        uint256 pending; //slp pending
        uint256 share; // 1e18 = 100 %
    }

    mapping(address => uint256[]) userGuild; //which guild?
    mapping(address => uint256[]) userGuildIndex; //which order of member in the guild

    mapping(string => uint256[]) ronin2Guild;
    mapping(string => uint256[]) ronin2GuildIndex;
    mapping(string => uint256) lastUpdate; //timestamp

    guild[] public guildList;

    IERC20 public paymentToken;
    mapping(uint256 => scholar[]) guildMember;

    // @notice init with a list of recipients
    constructor(address token) {
        paymentToken = IERC20(token);
    }

    function createGuild(address _guildOwner, string memory name) public {
        guildList.push(guild({guildOwner: _guildOwner, balance: 0}));
        guildNames.push(name);
    }

    function deposit(uint256 guildID, uint256 amount) public {
        paymentToken.safeTransferFrom(msg.sender, address(this), amount);
        guildList[guildID].balance += amount;
    }

    function addScholar(
        uint256 guildID,
        string memory scholarRoninAddress,
        uint256 share
    ) public {
        require(guildList[guildID].guildOwner == msg.sender);
        guildMember[guildID].push(
            scholar({
                scholarWallet: msg.sender, //default setting to guild owner
                scholarRoninAddress: scholarRoninAddress,
                pending: 0,
                share: share
            })
        );
        userGuild[msg.sender].push(guildID);
        userGuildIndex[msg.sender].push(guildMember[guildID].length - 1);

        ronin2Guild[scholarRoninAddress].push(guildID);
        ronin2GuildIndex[scholarRoninAddress].push(
            guildMember[guildID].length - 1
        );
    }

    function changeBeneficiary(
        uint256 guildID,
        uint256 index,
        address newBeneficiary,
        bool revokeOldPending
    ) public {
        require(guildList[guildID].guildOwner == msg.sender);
        scholar memory tmp = guildMember[guildID][index];
        if (revokeOldPending) {
            guildMember[guildID].push(
                scholar({
                    scholarWallet: newBeneficiary,
                    scholarRoninAddress: tmp.scholarRoninAddress,
                    pending: tmp.pending,
                    share: tmp.share
                })
            );
            guildMember[guildID][index].pending = 0;
            guildMember[guildID][index].scholarRoninAddress = "dead";
            guildMember[guildID][index].share = 0;
        } else {
            guildMember[guildID].push(
                scholar({
                    scholarWallet: newBeneficiary,
                    scholarRoninAddress: tmp.scholarRoninAddress,
                    pending: 0,
                    share: tmp.share
                })
            );
            guildMember[guildID][index].scholarRoninAddress = "dead";
            guildMember[guildID][index].share = 0;
        }
        
        userGuild[newBeneficiary].push(guildID);
        userGuildIndex[newBeneficiary].push(guildMember[guildID].length - 1);

        ronin2Guild[tmp.scholarRoninAddress].push(guildID);
        ronin2GuildIndex[tmp.scholarRoninAddress].push(
            guildMember[guildID].length - 1
        );
    }

    function updateScholarShare(
        uint256 guildID,
        uint256 index,
        uint256 newShare
    ) public {
        require(guildList[guildID].guildOwner == msg.sender);
        guildMember[guildID][index].share = newShare;
    }

    function transferGuildOwner(uint256 guildID, address newOwner) public {
        require(guildList[guildID].guildOwner == msg.sender);
        guildList[guildID].guildOwner = newOwner;
    }

    function removeScholar(uint256 guildID, uint256 index) public {
        require(guildList[guildID].guildOwner == msg.sender);
        guildMember[guildID][index].scholarRoninAddress = "dead";
        guildMember[guildID][index].share = 0;
    }

    function claim(uint256 guildID, uint256 index) public {
        scholar memory tmp = guildMember[guildID][index];
        require(tmp.scholarWallet == msg.sender);
        require(tmp.pending <= guildList[guildID].balance);
        guildList[guildID].balance -= guildMember[guildID][index].pending;
        guildMember[guildID][index].pending = 0;

        paymentToken.safeTransfer(msg.sender, tmp.pending);
    }

    function updatePaymentBalance(
        uint256 date,
        string memory roninAddress,
        uint256 amount
    ) public {
        require(lastUpdate[roninAddress] < date);
        for (uint256 i = 0; i < ronin2Guild[roninAddress].length; i++) {
            uint256 guildID = ronin2Guild[roninAddress][i];
            uint256 guildIDX = ronin2GuildIndex[roninAddress][i];

            if (
                keccak256(
                    abi.encodePacked(
                        guildMember[guildID][guildIDX].scholarRoninAddress
                    )
                ) == keccak256(abi.encodePacked(roninAddress))
            ) {
                guildMember[guildID][guildIDX].pending +=
                    (amount * guildMember[guildID][guildIDX].share) /
                    ONE;
            }
        }

        lastUpdate[roninAddress] = date;
    }
}
