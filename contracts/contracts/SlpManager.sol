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
        address roninAddress;
        address player;
        uint256 claimable;
        uint256 percentShare; // 1e18 = 100 %
    }
    
    uint256 public Percentfee;
    address public feeAddress;
    address public devaddr;
    address public guildMaster;
    uint256 public balance;
    IERC20 public slp;
    
    //Info of each scholar
    ScholarInfo[] public scholarInfo;
    //list of player
    mapping (address => bool) public playerList;
    //list of ronin addess.
    mapping (address => bool) public roninList;
    // Info of each player that was assigned to scholar.
    mapping (address => uint256) public playerInfo;
    // Info of each ronin wallet that was assigned to Scholar.
    mapping (address => uint256) internal roninInfo;
    // Info of recently dailySlp update.
    mapping(address => uint256) lastUpdate;
    // @notice init with a list of recipients
    constructor(address _token, address _guildMaster) {
        slp = IERC20(_token);
        guildMaster = _guildMaster;
        devaddr = msg.sender;
        balance = 0;
    }

    event Deposit(address guildMaster, uint256 amount);
    event Withdraw(address guildMaster, uint256 amount);
    event Claim(address player, uint256 amount);
    
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

        uint256 id = playerInfo[msg.sender];
        
        require(scholarInfo[id].player == msg.sender);
        require(scholarInfo[id].claimable <= balance);
        
        fee = scholarInfo[id].claimable * percentFee / ONE;
        uint256 claimAmount = scholarInfo[id].claimable - fee;

        slp.safeTransfer(msg.sender, claimAmount);
        slp.safeTransfer(feeAddress, fee);
        
        balance -= scholarInfo[id].claimable;
        scholarInfo[id].claimable = 0;

        emit Claim(msg.sender, claimAmount);
    }
    
    function addScholar(
        address _roninAddress,
        address _player,
        uint256 _percentShare
    ) public {

        require(guildMaster == msg.sender, "only guild master can add scholar.");
        require(roninList[_roninAddress] != true, "please remove old scholar before assign new address.");
        
        scholarInfo.push(
            ScholarInfo({
                roninAddress: _roninAddress,
                player: _player,
                claimable: 0,
                percentShare: _percentShare
            })
        );
        
        playerInfo[_player] = scholarInfo.length - 1;
        roninInfo[_roninAddress] = scholarInfo.length - 1;

        playerList[_player] = true;
        roninList[_roninAddress] = true;
        
    }
    
    function updatePercentShare(
        address _roninAddress,
        uint256 _percent
    ) public {
        require(guildMaster == msg.sender);

        uint256 id = roninInfo[_roninAddress];
        scholarInfo[id].percentShare = _percent;
    }

    function updatePercentFee(uint256 _percent) public onlyOwner {

        percentFee = _percent;

    }
    
    function removeOldPlayer(
        address _player
    ) public {
        
        require(guildMaster == msg.sender, "only guild master can remove player.");
        require(playerList[_player] == true, "you can't remove address that dosen't exist in system");
        
        uint256 id = playerInfo[_player];
        scholarInfo[id].player = 0x000000000000000000000000000000000000dEaD;
        scholarInfo[id].claimable = 0; // For old claimable balance of player shouldn't send to old player using contract.

        playerList[_player] = false;
        delete playerInfo[_player];
        
    }

    function changePlayer(
        address _roninAddress,
        address _newPlayer
    ) public {
        
        require(guildMaster == msg.sender, "only guild master can change player.");
        require(roninList[_roninAddress] == true, "you can't chabge address that dosen't exist in system");
        
        uint256 id = roninInfo[_roninAddress];
        address oldPlayer = scholarInfo[id].player;

        scholarInfo[id].claimable = 0; // For old claimable balance of player shouldn't send to new player using contract.
        scholarInfo[id].player = _newPlayer;

        playerList[oldPlayer] = false;
        delete playerInfo[oldPlayer];

        playerInfo[_newPlayer] = id;
        
    }
    
    function transferGuildMaster(address _newMaster) public onlyOwner {
        guildMaster = _newMaster;
    }
    
    function updatePaymentBalance(
        uint256 _date,
        address _roninAddress,
        uint256 _dailySlp
        
    ) public onlyOwner {
        
        require(lastUpdate[_roninAddress] < _date);
        
        for (uint256 i = 0; i < scholarInfo.length; i++) {

            if ( scholarInfo[i].roninAddress == _roninAddress) {
                scholarInfo[i].claimable +=
                    (_dailySlp * scholarInfo[i].percentShare) /
                    ONE;
            }
        }
        lastUpdate[_roninAddress] = _date;
    }
    
}