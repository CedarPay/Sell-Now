// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SellSudoswap.sol";

contract SellSudoswapTest is Test {
    // ============  Storage ============
    /// @notice SellSudoswap contract
    SellSudoswap public SUDOSWAP;

    // ============  Functions ============
    /// @notice Setup tests
    function setUp() public {
        // Initialize SellSudoswap
        SUDOSWAP = new SellSudoswap(
            0x3F1d193884Fd596e2B2110759F314118Af410CED, // Megmi
            0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329 // Sudoswap exchange
        );
    }

    /// @notice Test buy sepcific nft on sudoswap
    function testBuySpecific() public {
        // Enforce contract starts with 0 balance
        vm.deal(address(SUDOSWAP), 0);

        uint256[] memory nftIds = new uint256[](1);
        nftIds[0] = 9909;
        PairSwapSpecific memory data = PairSwapSpecific({
            pair: address(0x263FF17C75a8C3Eebf62791EbF93A299c28c0398),
            nftIds: nftIds
        });

        address ethRecipient = address(this);
        address nftRecipient = address(this);
        uint256 deadline = 1681127064;

        //SUDOSWAP.executeBuySpecific(abi.encode(data), ethRecipient, nftRecipient, deadline);
    }

    /// @notice Test buy any nft on sudoswap
    function testBuyAny() public {
        // Enforce contract starts with 0 balance
        vm.deal(address(SUDOSWAP), 0);

        PairSwapAny memory data = PairSwapAny({
            pair: address(0xed0b6e4EF057069709FcfddE2d93D6Bc8318366E),
            numItems: 1
        });

        address ethRecipient = address(SUDOSWAP);
        address nftRecipient = address(SUDOSWAP);
        uint256 deadline = 1691127064;
        payable(address(SUDOSWAP)).transfer(3 ether);
        uint256 payamount = 3000000000000000000;
        SUDOSWAP.executeBuyAny(abi.encode(data), ethRecipient, nftRecipient, deadline, payamount);
    }
}