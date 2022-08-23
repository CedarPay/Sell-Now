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

        // Setup purchase order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory purchaseOrder = OrderTypes.MakerOrder({
            isOrderAsk: true,
            signer: 0x2c087A1c1CaB13bCbC8eB7914909a9B3Bff7Fa7f,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 44900000000000000000,
            tokenId: 3215,
            amount: 1,
            strategy: 0x56244Bb70CbD3EA9Dc8007399F61dFC065190031,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 353,
            startTime: 1661098303,
            endTime: 1661703086,
            minPercentageToAsk: 8500,
            params: "",
            v: 27,
            r: 0x428b993e6b44e127fd99093979e325a0e4d8a69f6100bedd7d71df944f4b99cd,
            s: 0x1582ac40302ff465d6bc24e078bf19e2c786d37e8e8bc924c5d88e8859874496
        });

        // Setup sale order
        // Details from LooksRare API (https://looksrare.github.io/api-docs/#/Orders/OrderController.getOrders)
        OrderTypes.MakerOrder memory sellOrder = OrderTypes.MakerOrder({
            isOrderAsk: false,
            signer: 0x562607a01a12E84a4aBE025Ac14ab1E36b76519f,
            collection: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            price: 330660329999999936,
            tokenId: 3215,
            amount: 1,
            strategy: 0x86F909F70813CdB1Bc733f4D97Dc6b03B8e7E8F3,
            currency: 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2,
            nonce: 568357,
            startTime: 1661238519,
            endTime: 1661238819,
            minPercentageToAsk: 8500,
            params: "",
            v: 27,
            r: 0x0e53dda3ce27e5d7462d92a204bd321f6fe2f7ed38a7733037430e9d3ef29c70,
            s: 0x1a2c8e270e25a3a7a5d6f107c6087c976e2cf4a65424e440aaa095f30c85a768
        });

        // Calculate nftCost
        uint256 purchaseCost = purchaseOrder.price;
        // Transfer nftCosst + 2 wei to contract
        payable(address(LOOKSRARE)).transfer(purchaseCost + 2 wei);
        LOOKSRARE.executeBuy(abi.encode(purchaseOrder));
        LOOKSRARE.executeSell(abi.encode(sellOrder));
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
