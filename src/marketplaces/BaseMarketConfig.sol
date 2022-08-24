// SPDX-License-Identifier: MIT
pragma solidity >=0.8.7;

import { SetupCall, TestOrderPayload, TestOrderContext, TestCallParameters, TestItem20, TestItem721 } from "./Types.sol";

abstract contract BaseMarketConfig {
    /**
     * @dev Market name used in results
     */
    function name() external pure virtual returns (string memory);

    function market() public view virtual returns (address);

    /**
     * @dev Address that should be approved for nft tokens
     *   (ERC721 and ERC1155). Should be set during `beforeAllPrepareMarketplace`.
     */
    address public sellerNftApprovalTarget;
    address public buyerNftApprovalTarget;

    /**
     * @dev Address that should be approved for ERC1155 tokens. Only set if
     *   different than ERC721 which is defined above. Set during `beforeAllPrepareMarketplace`.
     */
    address public sellerErc1155ApprovalTarget;
    address public buyerErc1155ApprovalTarget;

    /**
     * @dev Address that should be approved for erc20 tokens.
     *   Should be set during `beforeAllPrepareMarketplace`.
     */
    address public sellerErc20ApprovalTarget;
    address public buyerErc20ApprovalTarget;

    /**
     * @dev Get calldata to call from test prior to starting tests
     *   (used by wyvern to create proxies)
     * @param seller The seller address used for testing the marketplace
     * @param buyer The buyer address used for testing the marketplace
     * @return From address, to address, and calldata
     */
    function beforeAllPrepareMarketplaceCall(
        address seller,
        address buyer,
        address[] calldata erc20Tokens,
        address[] calldata erc721Tokens
    ) external virtual returns (SetupCall[] memory) {
        SetupCall[] memory empty = new SetupCall[](0);
        return empty;
    }

    /**
     * @dev Final setup prior to starting tests
     * @param seller The seller address used for testing the marketplace
     * @param buyer The buyer address used for testing the marketplace
     */
    function beforeAllPrepareMarketplace(address seller, address buyer)
        external
        virtual;

    /*//////////////////////////////////////////////////////////////
                        Test Payload Calls
    //////////////////////////////////////////////////////////////*/

    /**
     * @dev Get call parameters to execute an order selling a 721 token for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *   order should be listed on chain.
     * @param nft Address and ID for ERC721 token to be sold.
     * @param ethAmount Amount of Ether to be received for the NFT.
     */
    function getPayload_BuyOfferedERC721WithEther(
        TestOrderContext calldata context,
        TestItem721 calldata nft,
        uint256 ethAmount
    ) external virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling an ERC20 token for an ERC721.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param erc20 Address and amount for ERC20 to be sold.
     * @param nft Address and ID for 721 token to be received for ERC20.
     */
    function getPayload_BuyOfferedERC20WithERC721(
        TestOrderContext calldata context,
        TestItem20 calldata erc20,
        TestItem721 calldata nft
    ) external virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /**
     * @dev Get call parameters to execute an order selling many 721 tokens for Ether.
     *   If `context.listOnChain` is true and marketplace does not support on-chain
     *   listing, this function must revert with NotImplemented.
     * @param context Order context, including the buyer and seller and whether the
     *  order should be listed on chain.
     * @param nfts Array of Address and ID for ERC721 tokens to be sold.
     * @param ethAmount Amount of Ether to be received for the NFT.
     */
    function getPayload_BuyOfferedManyERC721WithEther(
        TestOrderContext calldata context,
        TestItem721[] calldata nfts,
        uint256 ethAmount
    ) external virtual returns (TestOrderPayload memory execution) {
        _notImplemented();
    }

    /*//////////////////////////////////////////////////////////////
                          Helpers
    //////////////////////////////////////////////////////////////*/
    ITestRunner private _tester;
    error NotImplemented();

    /**
     * @dev Revert if the type of requested order is impossible
     * to execute for a marketplace.
     */
    function _notImplemented() internal pure {
        revert NotImplemented();
    }

    constructor() {
        _tester = ITestRunner(msg.sender);
    }

    /**
     * @dev Request a signature from the testing contract.
     */
    function _sign(address signer, bytes32 digest)
        internal
        view
        returns (
            uint8,
            bytes32,
            bytes32
        )
    {
        return _tester.signDigest(signer, digest);
    }
}

interface ITestRunner {
    function signDigest(address signer, bytes32 digest)
        external
        view
        returns (
            uint8,
            bytes32,
            bytes32
        );
}
