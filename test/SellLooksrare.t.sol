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
    function testLooksrareSell() public {
        // Enforce contract starts with 0 balance
        vm.deal(address(LOOKSRARE), 0);

        // Setup purchase order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory purchaseOrder = OrderTypes.MakerOrder({
            isOrderAsk: true,
            signer: 0xF3511594D0EeC46D774A9BC691323192604bA05d,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 450000000000000000,
            tokenId: 308,
            amount: 1,
            strategy: 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 57,
            startTime: 1662501096,
            endTime: 1665093090,
            minPercentageToAsk: 9800,
            params: "",
            v: 27,
            r: 0xacf7135d892361b964a26732d710f79bb4621a18d88affb3769ed87ebd5d3817,
            s: 0x596064fedd993eca98d155fd0f71f3cf46a7dc583e243d5f6dab80f014cb26d6
        });

        // Setup sale order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory sellOrder = OrderTypes.MakerOrder({
            isOrderAsk: false,
            signer: 0x562607a01a12E84a4aBE025Ac14ab1E36b76519f,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 314919927039904384,
            tokenId: 0,
            amount: 1,
            strategy: 0x86F909F70813CdB1Bc733f4D97Dc6b03B8e7E8F3,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 809452,
            startTime: 1663054720,
            endTime: 1663055020,
            minPercentageToAsk: 8500,
            params:"",
            v: 28,
            r: 0xc8764a3e2efa1e7a6ca4a9c61cdf6a7cabb140ad481c651beaa77552a237aacb,
            s: 0x670c7dc55d7db301a78ac523af8c4aca72eb1f94fd4e0c00a3529c28594e4260
        });

        // Calculate nftCost
        // Collect balance before
        uint256 balanceBefore = address(this).balance;
        // uint256 LOOKSRAREBefore = address(LOOKSRARE).balance;
        uint256 purchaseCost = purchaseOrder.price;
        // Transfer nftCosst to contract
        payable(address(LOOKSRARE)).transfer(purchaseCost + 1 ether);
         LOOKSRARE.executeBuy(abi.encode(purchaseOrder));
         LOOKSRARE.executeSell(abi.encode(sellOrder),308);

    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
