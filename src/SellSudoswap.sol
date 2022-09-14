// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
/// ============ Structs ============
struct PairSwapSpecific {
    address pair;
    uint256[] nftIds;
}

struct PairSwapAny {
    address pair;
    uint256 numItems;
}

/// ============ Interfaces ============
// ERC721
interface IERC721 {
    /// @notice Set transfer approval for operator
    function setApprovalForAll(address operator, bool approved) external;

    /// @notice Transfer NFT
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) external;
}

// Sudoswap, source: https://github.com/sudoswap/lssvm/blob/9e8ee80f60682b8f3f73163f1870ff28f7e07668/src/LSSVMRouter.sol
interface IRouter {
    /// @notice Buy NFT on sudoswap
    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable;

    function swapETHForAnyNFTs(
        PairSwapAny[] calldata swapList,
        address payable ethRecipient,
        address nftRecipient,
        uint256 deadline
    ) external payable;

    /// @notice Sell NFT on sudoswap
    function swapNFTsForToken(
        PairSwapSpecific[] calldata swapList,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external;
}

interface IPair {
    /// @notice Buy NFT on sudoswap
    function swapTokenForSpecificNFTs(
        uint256[] calldata nftIds,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable returns (uint256 inputAmount);

    function swapTokenForAnyNFTs(
        uint256 numNFTs,
        uint256 maxExpectedTokenInput,
        address nftRecipient,
        bool isRouter,
        address routerCaller
    ) external payable;

    /// @notice Sell NFT on sudoswap
    function swapNFTsForToken(
        uint256[] calldata nftIds,
        uint256 minExpectedTokenOutput,
        address payable tokenRecipient,
        bool isRouter,
        address routerCaller
    ) external returns (uint256 outputAmount);
}

contract SellSudoswap is IERC721Receiver{
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev Sudoswap contract
    IRouter internal immutable LSSVM;

    /// @notice Creates a new instant sell contract
    /// @param _NFT address of NFT
    /// @param _LSSVM address of sudoswap amm
    constructor(address _NFT, address _LSSVM) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup Sudoswap contract (0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329)
        LSSVM = IRouter(_LSSVM);
        // Give Sudoswap approval to execuate sell (0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329)
        IERC721(_NFT).setApprovalForAll(_LSSVM, true);
    }

    function onERC721Received(
        address,
        address,
        uint256,
        bytes calldata
    ) external pure override returns (bytes4) {
        return this.onERC721Received.selector;
    }
    function executeBuySpecific(
        bytes memory data,
        address ethRecipient,
        address nftRecipient,
        uint256 deadline,
        uint256 payAmount
    ) external {
        // Decode variables passed in data
        PairSwapSpecific memory swap = abi.decode(data, (PairSwapSpecific));
        PairSwapSpecific[] memory swapList = new PairSwapSpecific[](1);
        swapList[0] = swap;

        // buy NFT via Swap NFT
        LSSVM.swapETHForSpecificNFTs(
            swapList,
            payable(ethRecipient),
            nftRecipient,
            deadline
        );
    }

    function executeBuyAny(
        bytes memory data,
        address ethRecipient,
        address nftRecipient,
        uint256 deadline,
        uint256 payAmount
    ) external {
        // Decode variables passed in data
        PairSwapAny memory swap = abi.decode(data, (PairSwapAny));
        PairSwapAny[] memory swapList = new PairSwapAny[](1);
        swapList[0] = swap;

        // buy NFT via Swap NFT
        LSSVM.swapETHForAnyNFTs{value:payAmount}(
            swapList,
            payable(ethRecipient),
            nftRecipient,
            deadline
        );
    }

    function executeSell(
        bytes memory data,
        uint256 minOutput,
        address tokenRecipient,
        uint256 deadline
    ) external {
        // Decode variables passed in data
        PairSwapSpecific memory swap = abi.decode(data, (PairSwapSpecific));
        PairSwapSpecific[] memory swapList = new PairSwapSpecific[](1);
        swapList[0] = swap;

        // sell NFT via Swap NFT
        LSSVM.swapNFTsForToken(swapList, minOutput, tokenRecipient, deadline);
    }

    /// @notice Withdraws contract ETH balance to owner address
    function withdrawBalance() external {
        (bool sent, ) = OWNER.call{value: address(this).balance}("");
        if (!sent) revert("Could not withdraw balance");
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
