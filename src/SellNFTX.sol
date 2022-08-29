// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// ============ Structs ============

/// ============ Interfaces ============

// Wrapped Ether
interface IWETH {
    /// @notice Deposit ETH to WETH
    function deposit() external payable;

    /// @notice WETH balance
    function balanceOf(address holder) external returns (uint256);

    /// @notice ERC20 Spend approval
    function approve(address spender, uint256 amount) external returns (bool);

    /// @notice ERC20 transferFrom
    function transferFrom(
        address from,
        address to,
        uint256 amount
    ) external returns (bool);
}

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

// NFTX, source: https://github.com/NFTX-project/nftx-protocol-v2/blob/4875ea6b9ddf87b6920498358ac30029a9f7a1aa/contracts/solidity/NFTXMarketplaceZap.sol
interface INFTXMarketplaceZap {
    /// @notice Buy NFT on NFTX
    function buyAndSwap721(
        uint256 vaultId,
        uint256[] calldata idsIn,
        uint256[] calldata specificIds,
        address[] calldata path,
        address to
    ) external;

    /// @notice Buy NFT on NFTX WETH
    function buyAndSwap721WETH(
        uint256 vaultId,
        uint256[] calldata idsIn,
        uint256[] calldata specificIds,
        uint256 maxWethIn,
        address[] calldata path,
        address to
    ) external;

    /// @notice Sell NFT on NFTX
    function mintAndSell721(
        uint256 vaultId,
        uint256[] calldata ids,
        uint256 minEthOut,
        address[] calldata path,
        address to
    ) external;

    /// @notice Sell NFT on NFTX WETH
    function mintAndSell721WETH(
        uint256 vaultId,
        uint256[] calldata ids,
        uint256 minWethOut,
        address[] calldata path,
        address to
    ) external;
}

contract SellNFTX {
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev NFTX contract
    INFTXMarketplaceZap internal immutable NFTX;

    /// @notice Creates a new instant sell contract
    /// @param _NFT address of NFT
    /// @param _NFTX address of nftx amm
    /// @param _TRANSFER_MANAGER address of nftx transfer manager
    constructor(
        address _NFT,
        address _NFTX,
        address _TRANSFER_MANAGER
    ) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup NFTX contract (0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d)
        NFTX = INFTXMarketplaceZap(_NFTX);
        // Give NFTX approval to execuate sell (0x0fc584529a2AEfA997697FAfAcbA5831faC0c22d)
        IERC721(_NFT).setApprovalForAll(_TRANSFER_MANAGER, true);
    }

    function executeBuy(
        uint256 vaultId,
        uint256[] calldata idsIn,
        uint256[] calldata specificIds,
        address[] calldata path,
        address to
    ) external {
        // buy NFT via NFTX
        NFTX.buyAndSwap721(vaultId, idsIn, specificIds, path, to);
    }

    function executeSell(
        uint256 vaultId,
        uint256[] calldata ids,
        uint256 minWethOut,
        address[] calldata path,
        address to
    ) external {
        // sell NFT via NFTX
        NFTX.mintAndSell721(vaultId, ids, minWethOut, path, to);
    }

    /// @notice Withdraws contract ETH balance to owner address
    function withdrawBalance() external {
        (bool sent, ) = OWNER.call{value: address(this).balance}("");
        if (!sent) revert("Could not withdraw balance");
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
