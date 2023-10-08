// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import "forge-std/console.sol";

contract CounterScript is Script {
    function setUp() public {}

    function run() public {
        uint256 privatekey = vm.envUint("PRIVATEKEY");
        address account = vm.addr(privatekey);
        console.log("Account", account);
    }
}
