// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test, console} from "forge-std/Test.sol";

import "../src/delegation.sol";

contract DelegationTest is Test {
    Delegation internal delegation;
    address internal user;
    address internal owner;
    V1 internal v1;
    V2 internal v2;

    function setUp() public {
        owner = makeAddr("owner");
        user = makeAddr("user");

        v1 = new V1();
        v2 = new V2();

        vm.prank(user);
        delegation = new Delegation(address(v1));
    }
}
