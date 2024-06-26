// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    // ...
    FundMe fundMe;
    address USER = makeAddr("USER");
    uint256 SEND_VALUE = 0.1 ether;
    uint256 INITIAL_BALANCE = 10 ether;

    function setUp() external {
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, INITIAL_BALANCE);
    }

    function testMinmumDollaIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert("didn't send enough ethers");
        fundMe.fund();
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amount = fundMe.getAddressToAmountFunded(USER);
        assertEq(amount, SEND_VALUE);
    }

    function testAddFunderInFundersArray() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerCanWithDraw() public funded {
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFunder() public funded {
        // arrange
        uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 startingBalanceOfFundMe = address(fundMe).balance;

        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // assert
        uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 endingBalanceOfFundMe = address(fundMe).balance;
        assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingBalanceOfFundMe);
        assertEq(endingBalanceOfFundMe, 0);
    }

    function testWithdrawFromMultipFunder() public funded {
        // arrange
        uint160 numbersOfFunders = 10;
        uint160 startAddress = 1;
        for (uint160 i = startAddress; i < numbersOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 startingBalanceOfFundMe = address(fundMe).balance;
        // act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();
        // assert
        uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 endingBalanceOfFundMe = address(fundMe).balance;
        assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingBalanceOfFundMe);
        assertEq(endingBalanceOfFundMe, 0);
    }

    function testWithdrawFromMultipFunderCheaper() public funded {
        // arrange
        uint160 numbersOfFunders = 10;
        uint160 startAddress = 1;
        for (uint160 i = startAddress; i < numbersOfFunders; i++) {
            hoax(address(i), SEND_VALUE);
            fundMe.fund{value: SEND_VALUE}();
        }
        uint256 startingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 startingBalanceOfFundMe = address(fundMe).balance;
        // act
        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        // assert
        uint256 endingBalanceOfOwner = fundMe.getOwner().balance;
        uint256 endingBalanceOfFundMe = address(fundMe).balance;
        assertEq(endingBalanceOfOwner, startingBalanceOfOwner + startingBalanceOfFundMe);
        assertEq(endingBalanceOfFundMe, 0);
    }
}
