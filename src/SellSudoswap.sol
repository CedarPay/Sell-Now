// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// ============ Structs ============
struct PairSwapSpecific {
    address pair;
    uint256[] nftIds;
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
interface ILSSVMRouter {
    /// @notice Buy NFT on sudoswap
    function swapETHForSpecificNFTs(
        PairSwapSpecific[] calldata swapList,
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

contract SellSudoswap {
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev Sudoswap contract
    ILSSVMRouter internal immutable LSSVM;

    /// @notice Creates a new instant sell contract
    /// @param _NFT address of NFT
    /// @param _LSSVM address of sudoswap amm
    constructor(
        address _NFT,
        address _LSSVM
    ) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup Sudoswap contract (0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329)
        LSSVM = ILSSVMRouter(_LSSVM);
        // Give Sudoswap approval to execuate sell (0x2B2e8cDA09bBA9660dCA5cB6233787738Ad68329)
        IERC721(_NFT).setApprovalForAll(_LSSVM, true);
    }

    function executeBuy(bytes memory data, address ethRecipient, address nftRecipient, uint256 deadline) external {
        // Decode variables passed in data
        PairSwapSpecific memory swap = abi.decode(
            data,
            (PairSwapSpecific)
        );
        PairSwapSpecific[] memory swapList = new PairSwapSpecific[](1);
        swapList[0] = swap;

        // buy NFT via Swap NFT
        LSSVM.swapETHForSpecificNFTs(swapList, payable(ethRecipient), nftRecipient, deadline);
    }

    function executeSell(bytes memory data, uint256 minOutput, address tokenRecipient, uint256 deadline) external {
        // Decode variables passed in data
        PairSwapSpecific memory swap = abi.decode(
            data,
            (PairSwapSpecific)
        );
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