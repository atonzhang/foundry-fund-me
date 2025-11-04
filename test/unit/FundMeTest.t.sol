// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {HelpConfig, CodeConstants} from "../../script/HelpConfig.s.sol";

contract FundMeTest is Test {
    FundMe public fundMe;
    HelpConfig public helpConfig;

    uint256 public constant SEND_VALUE = 0.1 ether;
    uint256 public constant STARTING_USER_BALANCE = 10 ether;
    uint256 public constant GAS_PRICE = 1;
    
    uint160 public constant USER_NUMBER = 50;
    address public constant USER = address(USER_NUMBER);
    

    function setUp() external {
        DeployFundMe deployer = new DeployFundMe();
        (fundMe, helpConfig) = deployer.deployFundMe();

        vm.deal(USER, STARTING_USER_BALANCE);
    }

    function testPriceFeedSetCorrectly() public {
        address retreivedPriceFeed = address(fundMe.getPriceFeed());
        address expectedPriceFeed = helpConfig.getConfigByChainId(block.chainid).priceFeed;
        assertEq(retreivedPriceFeed, expectedPriceFeed);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert();
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddFundersToArrayOfFunders() public {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();
        assert(address(fundMe).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.prank(address(3));
        fundMe.withdraw();
    }

    function testWithdrawFromSingleFunder() public funded() {
        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        
        assertEq(endingFundMeBalance, 0);
        assertEq(startingFundMeBalance + startingOwnerBalance, endingOwnerBalance);
    }

    function testWithdrawFromMultipleFunder() public funded() {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2 + USER_NUMBER;

        uint256 originalFundMeBalance = address(fundMe).balance;

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), STARTING_USER_BALANCE);
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingFundMeBalance = address(fundMe).balance;
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        uint256 endingFundMeBalance = address(fundMe).balance;
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        
        assert(address(fundMe).balance == 0);
        assert(startingFundMeBalance + startingOwnerBalance == fundMe.getOwner().balance);
    }
}