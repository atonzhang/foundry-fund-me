// SPDX-License-Identifier: MIT

pragma solidity ^0.8.30;

import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";
import {Script, console} from "forge-std/Script.sol";

abstract contract CodeConstants {
    uint8 public constant DECIMALS = 8;
    int256 public constant INITIAL_PRICE = 2000e8;

    // CHAIN IDS
    uint256 public constant ETH_SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant LOCAL_CHAIN_ID = 31337;
    uint256 public constant BASE_SEPOLIA_CHAIN_ID = 84532;
}


contract HelpConfig is CodeConstants, Script {
    error HelperConfig__InvalidChainId();


    struct NetworkConfig {
        address priceFeed;
    }
    
    NetworkConfig public localNetworkConfig;
    mapping(uint256 chainId => NetworkConfig) public networkConfigs;

    constructor() {
        networkConfigs[ETH_SEPOLIA_CHAIN_ID] = getSepoliaEthConfig();
        networkConfigs[BASE_SEPOLIA_CHAIN_ID] = getBaseSepoliaConfig();
    }

    function getConfigByChainId(uint256 chainId) public returns(NetworkConfig memory) {
        if (networkConfigs[chainId].priceFeed != address(0)) {
            return networkConfigs[chainId];
        } else if (chainId == LOCAL_CHAIN_ID) {
            return getOrCreateAnvilEthConfig();
        } else {
            revert HelperConfig__InvalidChainId();
        }
    }

    function getSepoliaEthConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x694AA1769357215DE4FAC081bf1f309aDC325306 // ETH / USD
        });
    }

    function getBaseSepoliaConfig() public pure returns(NetworkConfig memory) {
        return NetworkConfig({
            priceFeed: 0x4aDC67696bA383F43DD60A9e78F2C97Fbbfc7cb1 // ETH / USD
        });
    }

    function getOrCreateAnvilEthConfig() public returns(NetworkConfig memory) {
        if (localNetworkConfig.priceFeed != address(0)) {
            return localNetworkConfig;
        }

        console.log("You have deployed a mock contract!");
        vm.startBroadcast();
        MockV3Aggregator mockPriceFeed = new MockV3Aggregator(DECIMALS, INITIAL_PRICE);
        vm.stopBroadcast();

        localNetworkConfig = NetworkConfig({priceFeed: address(mockPriceFeed)});
        return localNetworkConfig;
    }
}