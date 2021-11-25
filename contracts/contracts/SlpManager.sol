
// SPDX-License-Identifier: MIT
// AUTHOR: yoyoismee.eth

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@chainlink/contracts/src/v0.8/ChainlinkClient.sol";


// @notice just a push payment spliter. not the best practice. use it on trusted address only

contract SlpManager is Ownable, ReentrancyGuard, ChainlinkClient {
    using SafeERC20 for IERC20;
    using Chainlink for Chainlink.Request;
    uint256 constant ONE = 1e18;
    
    struct ScholarInfo {
        address roninAddress;
        address player;
        uint256 claimable;
        uint256 percentShare; // 1e18 = 100 %
    }

    /**
     * Network: Kovan
     * Oracle: 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8 (Chainlink Devrel   
     * Node)
     * Job ID: d5270d1c311941d0b08bead21fea7747
     * Fee: 0.1 LINK
     */

    string public APIUrl;
    
    uint256 public percentFee;
    address public devaddr;
    address public guildMaster;
    address public feeAddress;
    uint256 public balance;
    IERC20 public slp;

    //chainlink var
    address private oracle;
    bytes32 private jobId;
    uint256 private fee;
    
    uint256 public claimableTotal;

    //Info of each scholar
    ScholarInfo[] public scholarInfo;
    //list of player
    mapping (address => bool) public playerList;
    //list of ronin addess.
    mapping (address => bool) public roninList;
    // Info of each player that was assigned to scholar.
    mapping (address => uint256) public playerInfo;
    // Info of each ronin wallet that was assigned to Scholar.
    mapping (address => uint256) public roninInfo;
    // Info of recently dailySlp update.
    mapping(address => uint256) lastUpdate;
    // @notice init with a list of recipients
    // constructor(address _token, address _guildMaster, address _feeAddress, uint256 _percentFee) {
    //     slp = IERC20(_token);
    //     guildMaster = _guildMaster;
    //     devaddr = msg.sender;
    //     balance = 0;
    //     feeAddress = _feeAddress;
    //     percentFee = _percentFee;

    //     setPublicChainlinkToken();
    //     oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
    //     jobId = "d5270d1c311941d0b08bead21fea7747";
    //     fee = 0.1 * 10 ** 18; // (Varies by network and job)

    // }
    //for testing
    constructor() {
        slp = IERC20(0x35A98eA6EE6Ff8c5735D254BF496ecf6D2a5C471);
        guildMaster = 0x35A98eA6EE6Ff8c5735D254BF496ecf6D2a5C471;
        devaddr = msg.sender;
        balance = 0;
        feeAddress = 0x35A98eA6EE6Ff8c5735D254BF496ecf6D2a5C471;
        percentFee = 0;

        setPublicChainlinkToken();
        oracle = 0xc57B33452b4F7BB189bB5AfaE9cc4aBa1f7a4FD8;
        jobId = "d5270d1c311941d0b08bead21fea7747";
        fee = 0.1 * 10 ** 18; // (Varies by network and job)

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
        
        uint256 protocolFee = scholarInfo[id].claimable * percentFee / ONE;
        uint256 claimAmount = scholarInfo[id].claimable - fee;

        slp.safeTransfer(msg.sender, claimAmount);
        slp.safeTransfer(feeAddress, protocolFee);
        
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
    
    function getSLPamount(

        string memory _roninAddress
        
    ) public onlyOwner {

        address roninAddress = parseAddr(_roninAddress);
        require(roninList[roninAddress] == true);

        Chainlink.Request memory request = buildChainlinkRequest(jobId, address(this), this.fulfill.selector);

        // Set the URL to perform the GET request on
        // request.add("get", "https://game-api.axie.technology/api/v1/0xaf589071ed4e0f4aa081d445b7644ac75cd722c4");
        
        APIUrl = string(abi.encodePacked("https://game-api.axie.technology/api/v1/", _roninAddress));

        request.add("get", APIUrl);
        request.add("path", "in_game_slp");

        // Multiply the result by 1000000000000000000 to remove decimals
        int timesAmount = 10**18;
        request.addInt("times", timesAmount);

        sendChainlinkRequestTo(oracle, request, fee);

    }

    function updatePaymentBalance(
        uint256 _date,
        string memory _roninAddress
    ) public onlyOwner {

        getSLPamount(_roninAddress);

        address roninAddress = parseAddr(_roninAddress);
        require(lastUpdate[roninAddress] < _date);

        uint256 amount = this.claimableTotal();
        uint256 id = roninInfo[roninAddress];
        scholarInfo[id].claimable += (amount * scholarInfo[id].percentShare) / ONE;
        lastUpdate[roninAddress] = _date;

    }

    function fulfill(bytes32 _requestId, uint256 _claimableTotal) public recordChainlinkFulfillment(_requestId)
    {
        claimableTotal = _claimableTotal;
    }

    function parseAddr(string memory _a) internal pure returns (address _parsedAddress) {
    bytes memory tmp = bytes(_a);
    uint160 iaddr = 0;
    uint160 b1;
    uint160 b2;
    for (uint i = 2; i < 2 + 2 * 20; i += 2) {
        iaddr *= 256;
        b1 = uint160(uint8(tmp[i]));
        b2 = uint160(uint8(tmp[i + 1]));
        if ((b1 >= 97) && (b1 <= 102)) {
            b1 -= 87;
        } else if ((b1 >= 65) && (b1 <= 70)) {
            b1 -= 55;
        } else if ((b1 >= 48) && (b1 <= 57)) {
            b1 -= 48;
        }
        if ((b2 >= 97) && (b2 <= 102)) {
            b2 -= 87;
        } else if ((b2 >= 65) && (b2 <= 70)) {
            b2 -= 55;
        } else if ((b2 >= 48) && (b2 <= 57)) {
            b2 -= 48;
        }
        iaddr += (b1 * 16 + b2);
    }
    return address(iaddr);
}
    
}