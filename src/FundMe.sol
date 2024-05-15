// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {PriceConverter} from "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUM_USD = 5 * 1e18;

    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmoutFunded;

    address public immutable i_owner;
    AggregatorV3Interface private s_priceFeed;

    constructor(address priceFeedAddress) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeedAddress);
    }

    function fund() public payable {
        require(msg.value.getConversionRate(s_priceFeed) > MINIMUM_USD, "didn't send enough ethers");
        s_funders.push(msg.sender);
        s_addressToAmoutFunded[msg.sender] += msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function cheaperWithdraw() public onlyOwner {
        uint256 funderLength = s_funders.length;
        for (uint256 funderIndex = 0; funderIndex < funderLength; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmoutFunded[funder] = 0;
        }
        s_funders = new address[](0);
        payable(msg.sender).transfer(address(this).balance);
    }

    function withdraw() public onlyOwner {
        for (uint256 funderIndex = 0; funderIndex < s_funders.length; funderIndex++) {
            address funder = s_funders[funderIndex];
            s_addressToAmoutFunded[funder] = 0;
        }
        s_funders = new address[](0);
        payable(msg.sender).transfer(address(this).balance);
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }

    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert FundMe__NotOwner();
        }
        _;
    }

    function getAddressToAmountFunded(address funder) public view returns (uint256) {
        return s_addressToAmoutFunded[funder];
    }

    function getFunder(uint256 index) public view returns (address) {
        return s_funders[index];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
