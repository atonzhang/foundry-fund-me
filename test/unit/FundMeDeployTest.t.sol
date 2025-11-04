// SPDX-License-Identifier: MIT

pragma solidity 0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {HelpConfig, CodeConstants} from "../../script/HelpConfig.s.sol";

contract FundMeDeployTest is Test {
    FundMe public fundMe;

    function setUp() public {
        fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }

    function testDeploy() public view {
        assertEq(address(fundMe.getPriceFeed()), 0x694AA1769357215DE4FAC081bf1f309aDC325306);
    }
}