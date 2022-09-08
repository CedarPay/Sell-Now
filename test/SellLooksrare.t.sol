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
            signer: 0x55313b424dE97716c9dfc7f6F97dCaAb0234274D,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 350000000000000000,
            tokenId: 8194,
            amount: 1,
            strategy: 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 1,
            startTime: 1662574436,
            endTime: 1665166436,
            minPercentageToAsk: 7500,
            params: "",
            v: 28,
            r: 0xa006e0d832c2aff6416cbd3d063c656b3f4a90248ec11ae96bfab672b59f1ba0,
            s: 0x174ed06fe2905615fc417f744fb43a957e5e4ef38d4ef62c82e37275b707ce8d
        });

        // Setup sale order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory sellOrder = OrderTypes.MakerOrder({
            isOrderAsk: false,
            signer: 0x33d5CC43deBE407d20dD360F4853385135f97E9d,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 289203377003047744,
            tokenId: 0,
            amount: 1,
            strategy: 0x86F909F70813CdB1Bc733f4D97Dc6b03B8e7E8F3,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 304910,
            startTime: 1662610108,
            endTime: 1662610508,
            minPercentageToAsk: 9000,
            params: "",
            v: 27,
            r: 0xaae3eb8add1eb2d0740f9e2f325af8170857ea21d151c2c13c687020e9023848,
            s: 0x0610152e822b34f31b3259c68a2bdac9d3d805a040af4db9b75a7286fdbdcc38
        });

        // Calculate nftCost
        // Collect balance before
        uint256 balanceBefore = address(this).balance;
        // uint256 LOOKSRAREBefore = address(LOOKSRARE).balance;
        uint256 purchaseCost = purchaseOrder.price;
        // Transfer nftCosst to contract
        payable(address(LOOKSRARE)).transfer(purchaseCost + 1 ether);
         LOOKSRARE.executeBuy(abi.encode(purchaseOrder));
         LOOKSRARE.executeSell(abi.encode(sellOrder),8194);

    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
