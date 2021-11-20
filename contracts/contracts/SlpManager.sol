// SPDX-License-Identifier: MIT
// AUTHOR: yoyoismee.eth

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


// @notice just a push payment spliter. not the best practice. use it on trusted address only

contract SlpManager is Ownable, ReentrancyGuard {
    using SafeERC20 for IERC20;
    uint256 constant ONE = 1e18;
    
    struct ScholarInfo {
        string roninAddress;
        address player;
        uint256 claimable;
        uint256 percentShare; // 1e18 = 100 %
    }
    
    address public devaddr;
    address public guildMaster;
    IERC20 public slp;
    uint256 public balance;
    
    //Info of each scholar
    ScholarInfo[] public scholarInfo;
    //list of player
    mapping (address => bool) public playerList;
    //list of ronin addesss
    mapping (string => bool) internal roninList;
    // Info of each player that was assigned to scholar.
    mapping (address => ScholarInfo) public playerInfo;
    // Info of each ronin wallet that was assigned to Scholar.
    mapping (string => ScholarInfo) internal roninInfo;
    // Info of recently dailySlp update.
    mapping(string => uint256) lastUpdate;
    
    // @notice init with a list of recipients
    constructor(address _token, address _guildMaster) {
        slp = IERC20(_token);
        guildMaster = _guildMaster;
        devaddr = msg.sender;
        balance = 0;
        
        //dead scholar for remove function.
        scholarInfo.push(
            ScholarInfo({
                roninAddress: "0x0000000000000000000000000000000000000000",
                player: 0x0000000000000000000000000000000000000000,
                claimable: 0,
                percentShare: 0
            })
        );
        
    }

    event Deposit(address guildMaster, uint256 amount);
    event Withdraw(address guildMaster, uint256 amount);
    
    function scholarLength() external view returns (uint256) {
        return scholarInfo.length;
    }
    
    // Deposit SLP tokens to SlpManager.
    function deposit(uint256 _amount) public {
        require(msg.sender == guildMaster, "only guildMaster can deposit SLP to this contract.");
        slp.safeTransferFrom(msg.sender, address(this), _amount);
        balance += _amount;
        emit Deposit(msg.sender, _amount);
    }
    
    // Withdraw LP tokens from SlpManager.
    function withdraw(uint256 _amount) public {
        require(msg.sender == guildMaster, "only guildMaster can withdraw SLP from this contract.");
        require(balance >= _amount, "withdraw: not good");

        if(_amount > 0) {
            balance = balance - _amount;
            slp.safeTransfer(address(msg.sender), _amount);
        }
        emit Withdraw(msg.sender, _amount);
    }
    
    function claim() public {
        
        require(playerList[msg.sender] == true);
        ScholarInfo memory player = playerInfo[msg.sender];
        
        uint256 claim_amount = player.claimable;
        require(claim_amount <= balance);
        
        balance -= claim_amount;
        playerInfo[msg.sender].claimable = 0;

        slp.safeTransfer(msg.sender, claim_amount);
    }
    
    function addScholar(
        string memory _roninAddress,
        uint256 _percentShare,
        address _player
    ) public {
        require(guildMaster == msg.sender, "only guild master can add scholar.");
        require(roninList[_roninAddress] == false, "please remove old scholar before assign new address.");
        
        scholarInfo.push(
            ScholarInfo({
                roninAddress: _roninAddress,
                player: _player,
                claimable: 0,
                percentShare: _percentShare
            })
        );
        
        playerInfo[_player] = scholarInfo[scholarInfo.length - 1];
        roninInfo[_roninAddress] = scholarInfo[scholarInfo.length - 1];
        roninList[_roninAddress] = true;
        
    }
    
    function updatePercentShare(
        string memory _roninAddress,
        uint256 _percent
    ) public {
        require(guildMaster == msg.sender);
        roninInfo[_roninAddress].percentShare = _percent;
    }
    
    function removeScholar(
        string memory _roninAddress
    ) public {
        
        require(guildMaster == msg.sender, "only guild master can remove scholar.");
        require(roninList[_roninAddress] == true, "you can't remove address that dosen't exist in system");
        
        address player = roninInfo[_roninAddress].player;
        
        playerInfo[player] = scholarInfo[0];
        roninInfo[_roninAddress] = scholarInfo[0];
        roninList[_roninAddress] = false;
        
    }
    
    function transferGuildMaster(address newMaster) public onlyOwner {
        guildMaster = newMaster;
    }
    
    function updatePaymentBalance(
        uint256 _date,
        string memory _roninAddress,
        uint256 _dailySlp
        
    ) public {
        
        require(lastUpdate[_roninAddress] < _date);
        
        for (uint256 i = 0; i < scholarInfo.length; i++) {

            if (
                keccak256(
                    abi.encodePacked(
                        roninInfo[_roninAddress].roninAddress
                    )
                ) == keccak256(abi.encodePacked(_roninAddress))
            ) {
                roninInfo[_roninAddress].claimable +=
                    (_dailySlp * roninInfo[_roninAddress].percentShare) /
                    ONE;%
            }
        }
        lastUpdate[_roninAddress] = _date;
    }
    
}