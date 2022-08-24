// SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { SeaportConfig } from "../src/marketplaces/seaport/SeaportConfig.sol";
import { X2Y2Config } from "../src/marketplaces/X2Y2/X2Y2Config.sol";
import { LooksRareConfig } from "../src/marketplaces/looksRare/LooksRareConfig.sol";
import { SudoswapConfig } from "../src/marketplaces/sudoswap/SudoswapConfig.sol";
import { BaseMarketConfig } from "../src/BaseMarketConfig.sol";

import { SetupCall, TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721, TestItem1155 } from "../src/Types.sol";

import "./tokens/TestERC20.sol";
import "./tokens/TestERC721.sol";
import "./tokens/TestERC1155.sol";
import "./utils/BaseOrderTest.sol";

contract GenericMarketplaceTest is BaseOrderTest {
    BaseMarketConfig seaportConfig;
    BaseMarketConfig x2y2Config;
    BaseMarketConfig looksRareConfig;
    BaseMarketConfig sudoswapConfig;

    constructor() {
        seaportConfig = BaseMarketConfig(new SeaportConfig());
        x2y2Config = BaseMarketConfig(new X2Y2Config());
        looksRareConfig = BaseMarketConfig(new LooksRareConfig());
        sudoswapConfig = BaseMarketConfig(new SudoswapConfig());
    }

    function testSeaport() external {
        Market(seaportConfig);
    }

    function testX2Y2() external {
        Market(x2y2Config);
    }

    function testLooksRare() external {
        Market(looksRareConfig);
    }

    function testSudoswap() external {
        Market(sudoswapConfig);
    }

    function Market(BaseMarketConfig config) public {
        beforeAllPrepareMarketplaceTest(config);
        BuyOfferedERC20WithERC721_ListOnChain(config);
        BuyOfferedERC20WithERC721(config);
    }

    function beforeAllPrepareMarketplaceTest(BaseMarketConfig config) internal {
        // Get requested call from marketplace. Needed by Wyvern to deploy proxy
        SetupCall[] memory setupCalls = config.beforeAllPrepareMarketplaceCall(
            alice,
            bob,
            erc20Addresses,
            erc721Addresses
        );
        for (uint256 i = 0; i < setupCalls.length; i++) {
            vm.startPrank(setupCalls[i].sender);
            (setupCalls[i].target).call(setupCalls[i].data);
            vm.stopPrank();
        }

        // Do any final setup within config
        config.beforeAllPrepareMarketplace(alice, bob);
    }

    /*//////////////////////////////////////////////////////////////
                        Tests
    //////////////////////////////////////////////////////////////*/
 
    /// @dev Sell ERC721 in ERC20
    function BuyOfferedERC20WithERC721_ListOnChain(
        BaseMarketConfig config
    ) internal prepareTest(config) {
        string memory testLabel = "(ERC20 -> ERC721 List-On-Chain)";
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(true, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            _CallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " List")),
                alice,
                payload.submitOrder
            );

            assertEq(test721_1.ownerOf(1), bob);
            // Allow the market to escrow after listing
            assert(
                token1.balanceOf(alice) == 100 ||
                    token1.balanceOf(config.market()) == 100
            );
            assertEq(token1.balanceOf(bob), 0);

            _CallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    /// @dev Sell ERC721 in ERC20
    function BuyOfferedERC20WithERC721(BaseMarketConfig config)
        internal
        prepareTest(config)
    {
        string memory testLabel = "(ERC20 -> ERC721)";
        token1.mint(alice, 100);
        test721_1.mint(bob, 1);
        try
            config.getPayload_BuyOfferedERC20WithERC721(
                TestOrderContext(false, alice, bob),
                TestItem20(address(token1), 100),
                TestItem721(address(test721_1), 1)
            )
        returns (TestOrderPayload memory payload) {
            assertEq(test721_1.ownerOf(1), bob);
            assertEq(token1.balanceOf(alice), 100);
            assertEq(token1.balanceOf(bob), 0);

            _CallWithParams(
                config.name(),
                string(abi.encodePacked(testLabel, " Fulfill w/ Sig")),
                bob,
                payload.executeOrder
            );

            assertEq(test721_1.ownerOf(1), alice);
            assertEq(token1.balanceOf(alice), 0);
            assertEq(token1.balanceOf(bob), 100);
        } catch {
            _logNotSupported(config.name(), testLabel);
        }
    }

    /*//////////////////////////////////////////////////////////////
                          Helpers
    //////////////////////////////////////////////////////////////*/

    function setUp() public virtual override {
        super.setUp();
    }

    modifier prepareTest(BaseMarketConfig config) {
        _resetStorageAndEth(config.market());
        require(
            config.sellerErc20ApprovalTarget() != address(0) &&
                config.sellerNftApprovalTarget() != address(0) &&
                config.buyerErc20ApprovalTarget() != address(0) &&
                config.buyerNftApprovalTarget() != address(0),
            "BaseMarketplaceTester::prepareTest: approval target not set"
        );
        _setApprovals(
            alice,
            config.sellerErc20ApprovalTarget(),
            config.sellerNftApprovalTarget(),
            config.sellerErc1155ApprovalTarget()
        );
        _setApprovals(
            cal,
            config.sellerErc20ApprovalTarget(),
            config.sellerNftApprovalTarget(),
            config.sellerErc1155ApprovalTarget()
        );
        _setApprovals(
            bob,
            config.buyerErc20ApprovalTarget(),
            config.buyerNftApprovalTarget(),
            config.buyerErc1155ApprovalTarget()
        );
        _;
    }

    function signDigest(address signer, bytes32 digest)
        external
        returns (
            uint8 v,
            bytes32 r,
            bytes32 s
        )
    {
        (v, r, s) = vm.sign(privateKeys[signer], digest);
    }

    function _formatLog(string memory name, string memory label)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked("[", name, "] ", label, " -- gas"));
    }

    function _logNotSupported(string memory name, string memory label)
        internal
    {
        emit log(
            string(
                abi.encodePacked("[", name, "] ", label, " -- NOT SUPPORTED")
            )
        );
    }

    function _CallWithParams(
        string memory name,
        string memory label,
        address sender,
        TestCallParameters memory params
    ) internal {
        vm.startPrank(sender);
        uint256 gasDelta;
        bool success;
        assembly {
            let to := mload(params)
            let value := mload(add(params, 0x20))
            let data := mload(add(params, 0x40))
            let ptr := add(data, 0x20)
            let len := mload(data)
            let g1 := gas()
            success := call(gas(), to, value, ptr, len, 0, 0)
            let g2 := gas()
            gasDelta := sub(g1, g2)
            if iszero(success) {
                returndatacopy(0, 0, returndatasize())
                revert(0, returndatasize())
            }
        }
        vm.stopPrank();
        emit log_named_uint(
            _formatLog(name, string(abi.encodePacked(label, " (direct)"))),
            gasDelta
        );
        emit log_named_uint(
            _formatLog(name, label),
            gasDelta + _additionalGasFee(params.data)
        );
    }

    function _additionalGasFee(bytes memory callData)
        internal
        pure
        returns (uint256)
    {
        uint256 sum = 21000;
        for (uint256 i = 0; i < callData.length; i++) {
            // zero bytes = 4, non-zero = 16
            sum += callData[i] == 0 ? 4 : 16;
        }
        return sum - 2600; // Remove call opcode cost
    }
}
