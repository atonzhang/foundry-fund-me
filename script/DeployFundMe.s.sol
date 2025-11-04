// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Script, console} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelpConfig} from "./HelpConfig.s.sol";

contract DeployFundMe is Script {
    function deployFundMe() public returns(FundMe, HelpConfig) {
        HelpConfig helpConfig = new HelpConfig();
        address priceFeed = helpConfig.getConfigByChainId(block.chainid).priceFeed;

        vm.startBroadcast();
        FundMe fundMe = new FundMe(priceFeed);
        vm.stopBroadcast();

        return(fundMe, helpConfig);
    }

    function run() external returns (FundMe, HelpConfig) {
        return deployFundMe();
    }
}