// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

interface IUnsafeBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function RUGPULL() external;
    function owner() external view returns (address);
    function balances(address addr) external view returns (uint256);
}

contract unsafeBank {
    uint256 public userAmount;
    address internal immutable _owner;
    mapping(address => uint256) private _balances;
    string public constant VERSION = "1.0";

    error unsafeBank__notOwner();
    error unsafeBank__notEnoughBalance();

    event unsafeBank__depositToken(address indexed user, uint256 indexed amount);
    event unsafeBank__withdrawToken(address indexed user, uint256 indexed amount);

    constructor() payable {
        _owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != _owner) {
            revert unsafeBank__notOwner();
        }
        _;
    }

    function owner() public view returns (address) {
        return _owner;
    }

    function balances(address addr) public view returns (uint256) {
        return _balances[addr];
    }

    function deposit() public payable {
        _balances[msg.sender] += msg.value;
        emit unsafeBank__depositToken(msg.sender, msg.value);
    }

    function withdraw(uint256 amount) public {
        if (amount > _balances[msg.sender]) {
            revert unsafeBank__notEnoughBalance();
        }

        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Ether transfer failed");

        _balances[msg.sender] -= amount;

        emit unsafeBank__withdrawToken(msg.sender, amount);
    }

    function withdrawAll() public {
        uint256 amount = _balances[msg.sender];
        (bool success,) = msg.sender.call{value: amount}("");
        require(success, "Ether Transfer Failed");

        _balances[msg.sender] = 0;

        emit unsafeBank__withdrawToken(msg.sender, amount);
    }

    function RUGPULL() public onlyOwner {
        (bool success,) = _owner.call{value: address(this).balance}("");
        require(success, "Rug Pull Failed");
    }

    receive() external payable {
        deposit();
    }

    fallback() external payable {
        deposit();
    }
}
