// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IX2Y2Marketplace } from "./interfaces/IX2Y2Marketplace.sol";
import { BaseMarketConfig } from "../../BaseMarketConfig.sol";
import { Market } from "./interfaces/MarketConstants.sol";
import { X2Y2TypeHashes } from "./lib/X2Y2TypeHashes.sol";
import { SetupCall, TestCallParameters, TestOrderContext, TestOrderPayload, TestItem721, TestItem1155, TestItem20 } from "../../Types.sol";

contract X2Y2Config is BaseMarketConfig, X2Y2TypeHashes {
    IX2Y2Marketplace internal constant X2Y2 =
        IX2Y2Marketplace(0x74312363e45DCaBA76c59ec49a7Aa8A65a67EeD3);

    address internal constant X2Y2Owner =
        0x5D7CcA9Fb832BBD99C8bD720EbdA39B028648301;

    address internal constant erc721Delegate =
        0xF849de01B080aDC3A814FaBE1E2087475cF2E354;

    address internal X2Y2Signer;

    function name() external pure override returns (string memory) {
        return "X2Y2";
    }

    function market() public pure override returns (address) {
        return address(X2Y2);
    }

    function beforeAllPrepareMarketplace(address, address) external override {
        buyerNftApprovalTarget = sellerNftApprovalTarget = erc721Delegate;
        buyerErc20ApprovalTarget = sellerErc20ApprovalTarget = address(X2Y2);
    }

    function beforeAllPrepareMarketplaceCall(
        address seller,
        address,
        address[] calldata,
        address[] calldata
    ) external override returns (SetupCall[] memory) {
        SetupCall[] memory setupCalls = new SetupCall[](1);

        address[] memory removeSigners = new address[](0);
        address[] memory addSigners = new address[](1);
        addSigners[0] = seller;

        // Set seller as a signer for X2Y2
        setupCalls[0] = SetupCall(
            X2Y2Owner,
            address(X2Y2),
            abi.encodeWithSelector(
                IX2Y2Marketplace.updateSigners.selector,
                addSigners,
                removeSigners
            )
        );

        X2Y2Signer = seller;

        return setupCalls;
    }

    function encodeFillOrder(
        address offerer,
        address fulfiller,
        TestItem721[] memory nfts,
        uint256 price,
        address currency,
        uint256 intent,
        Market.Fee[] memory fees
    ) internal view returns (bytes memory) {
        Market.RunInput memory input;

        input.shared.user = fulfiller;
        input.shared.deadline = block.timestamp + 1;

        Market.Order[] memory orders = new Market.Order[](1);
        orders[0].user = offerer;
        orders[0].network = 1;
        orders[0].intent = intent;
        orders[0].delegateType = 1;
        orders[0].deadline = block.timestamp + 1;
        orders[0].currency = currency;

        Market.OrderItem[] memory items = new Market.OrderItem[](1);

        Market.Pair[] memory itemPairs = new Market.Pair[](nfts.length);

        for (uint256 i = 0; i < nfts.length; i++) {
            itemPairs[i] = Market.Pair(nfts[i].token, nfts[i].identifier);
        }

        items[0] = Market.OrderItem(price, abi.encode(itemPairs));

        orders[0].items = items;

        (orders[0].v, orders[0].r, orders[0].s) = _sign(
            offerer,
            _deriveOrderDigest(orders[0])
        );
        orders[0].signVersion = Market.SIGN_V1;

        input.orders = orders;

        Market.SettleDetail[] memory details = new Market.SettleDetail[](1);
        details[0].op = intent == Market.INTENT_SELL
            ? Market.Op.COMPLETE_SELL_OFFER
            : Market.Op.COMPLETE_BUY_OFFER;
        details[0].orderIdx = 0;
        details[0].itemIdx = 0;
        details[0].price = price;
        details[0].fees = fees;
        details[0].itemHash = _hashItem(orders[0], orders[0].items[0]);
        details[0].executionDelegate = erc721Delegate;
        input.details = details;

        (input.v, input.r, input.s) = _sign(
            X2Y2Signer,
            _deriveInputDigest(input)
        );

        return abi.encodeWithSelector(IX2Y2Marketplace.run.selector, input);
    }

    /// @dev Buy ERC721 using ETH
    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            ethAmount,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            ethAmount,
            payload
        );
    }

    /// @dev Sell ERC721 in ERC20
    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        TestItem721[] memory nfts = new TestItem721[](1);
        nfts[0] = nft;

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            erc20.amount,
            erc20.token,
            Market.INTENT_BUY,
            fees
        );

        execution.executeOrder = TestCallParameters(address(X2Y2), 0, payload);
    }

    /// @dev Buy multiple ERC721s using ETH
    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external view override returns (TestOrderPayload memory execution) {
        if (context.listOnChain) {
            _notImplemented();
        }

        Market.Fee[] memory fees = new Market.Fee[](0);

        bytes memory payload = encodeFillOrder(
            context.offerer,
            context.fulfiller,
            nfts,
            ethAmount,
            address(0),
            Market.INTENT_SELL,
            fees
        );

        execution.executeOrder = TestCallParameters(
            address(X2Y2),
            ethAmount,
            payload
        );
    }
}
