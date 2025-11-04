// SPDX-License-Identifier: MIT

// 1. Pragma
pragma solidity 0.8.30;

// 2. Imports
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

// 3. Interfaces
error FundMe__NotOwner();
error FundMe__NotEnoughMoney();

contract FundMe {
     // Type Declarations
    using {PriceConverter.getConversionRate} for uint256;
    
    // State variables
    uint256 public constant MINIMUM_USD = 5 * 10 ** 18;
    address private immutable i_owner;
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunded;
    AggregatorV3Interface private s_priceFeed;

    // Modifiers
    modifier onlyOwner() {
        _onlyOwner();
        _;
    }

    function _onlyOwner() internal view {
        if (msg.sender != i_owner) revert FundMe__NotOwner();
    }

    constructor(address priceFeed) {
        s_priceFeed = AggregatorV3Interface(priceFeed);
        i_owner = msg.sender;
    }

    // The reward amount needs to be greater than 5 USDT
    function fund() public payable {
       if(msg.value.getConversionRate(s_priceFeed) < MINIMUM_USD) revert FundMe__NotEnoughMoney();
       s_addressToAmountFunded[msg.sender] += msg.value;
       s_funders.push(msg.sender);
    }

    function withdraw() public onlyOwner() {
        address[] memory funders = s_funders;
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = funders[funderIndex];
            s_addressToAmountFunded[funder] = 0;
        }
        s_funders = new address[](0);

        (bool success,) = i_owner.call{value: address(this).balance}("");
        require(success);
    }


    /**
     * Getter Functions
     */

    // Get the amount that an address has funded
    function getAddressToAmountFunded(address fundingAddress) public view returns(uint256) {
        return s_addressToAmountFunded[fundingAddress];
    }

    function getVersion() public view returns(uint256) {
        return s_priceFeed.version();
    }

    function getFunder(uint256 index) public view returns(address) {
        return s_funders[index];
    }

    function getOwner() public view returns(address) {
        return i_owner;
    }

    function getPriceFeed() public view returns(AggregatorV3Interface) {
        return s_priceFeed;
    }
}