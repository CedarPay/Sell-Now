// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SellLooksrare.sol";

contract SellLooksrareTest is Test {
    // ============  Storage ============
    /// @notice Wrapped Ether contract
    IWETH public WETH;
    /// @notice SellLooksrare contract
    SellLooksrare public LOOKSRARE;

    // ============  Functions ============
    /// @notice Setup tests
    function setUp() public {
        // Setup WETH
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        // Initialize SellLooksrare
        LOOKSRARE = new SellLooksrare(
            address(WETH), // Wrapped Ether
            0x5Af0D9827E0c53E4799BB226655A1de152A425a5, // MIL
            0x59728544B08AB483533076417FbBB2fD0B17CE3a, // LooksRare exchange
            0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e // Looksrare transfer manager
        );
    }

    /// @notice Test claiming excess ETH
    function testClaimExcessETH() public {
        // Enforce contract starts with 0 bala
        vm.deal(address(LOOKSRARE), 0);

        // Collect balance before
        uint256 balanceBefore = address(this).balance;

        // Send 5 ETH to contract
        payable(LOOKSRARE).transfer(5 ether);

        // Assert balance now 5 less
        assertEq(address(this).balance, balanceBefore - 5 ether);

        // Withdraw 5 ETH
        LOOKSRARE.withdrawBalance();

        // Collect balance after
        uint256 balanceAfter = address(this).balance;

        // Assert balance matches
        assertEq(balanceAfter, balanceBefore);
    }

    /// @notice Test claiming excess WETH
    function testClaimExcessWETH() public {
        // Deposit 5 ETH to WETH
        WETH.deposit{value: 5 ether}();

        // Collect balance before
        uint256 balanceBefore = WETH.balanceOf(address(this));

        // Send 5 WETH to contract
        WETH.transferFrom(address(this), address(LOOKSRARE), 5 ether);

        // Assert balance now 0
        assertEq(WETH.balanceOf(address(this)), 0);

        // Withdraw 5 WETH
        LOOKSRARE.withdrawBalanceWETH();

        // Collect balance after
        uint256 balanceAfter = WETH.balanceOf(address(this));

        // Assert balance matches
        assertEq(balanceBefore, balanceAfter);
    }

    /// @notice Test instant sell on looksrare
    function testInstantSell() public {
        // Enforce contract starts with 0 balance
        vm.deal(address(LOOKSRARE), 0);

        // Setup sale order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory sellOrder = OrderTypes.MakerOrder({
        isOrderAsk: false,
        signer: 0x562607a01a12E84a4aBE025Ac14ab1E36b76519f,
        collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
        price: 330329999999999936,
        tokenId: 0,
        amount: 1,
        strategy: 0x86F909F70813CdB1Bc733f4D97Dc6b03B8e7E8F3,
        currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
        nonce: 567078,
        startTime: 1661229677,
        endTime: 1661229977,
        minPercentageToAsk: 8500,
        params: "",
        v: 28,
        r: 0xa2d219129a0e8b8601c1dade4dc99f02415d33641639481c8ad71f2156ae3ea9,
        s: 0x6c9d20e89e6c026ca17118d0224aba139a70246a402ec42b12ed235933908e0d
        });
        
        // Calculate nftCost
        uint256 nftCost = sellOrder.price;
        // Transfer nftCosst + 2 wei to contract
        payable(address(LOOKSRARE)).transfer(nftCost + 2 wei);
        LOOKSRARE.executeSell(abi.encode(sellOrder));
    }
    /// @notice Allows receiving ETH
    receive() external payable {}
}
