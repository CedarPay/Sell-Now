// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

// LooksRare order types
library OrderTypes {
    struct MakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address signer; // signer of the maker order
        address collection; // collection address
        uint256 price; // price (used as )
        uint256 tokenId; // id of the token
        uint256 amount; // amount of tokens to sell/purchase (must be 1 for ERC721, 1+ for ERC1155)
        address strategy; // strategy for trade execution (e.g., DutchAuction, StandardSaleForFixedPrice)
        address currency; // currency (e.g., WETH)
        uint256 nonce; // order nonce (must be unique unless new maker order is meant to override existing one e.g., lower ask price)
        uint256 startTime; // startTime in timestamp
        uint256 endTime; // endTime in timestamp
        uint256 minPercentageToAsk; // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // additional parameters
        uint8 v; // v: parameter (27 or 28)
        bytes32 r; // r: parameter
        bytes32 s; // s: parameter
    }

    struct TakerOrder {
        bool isOrderAsk; // true --> ask / false --> bid
        address taker; // msg.sender
        uint256 price; // final price for the purchase
        uint256 tokenId;
        uint256 minPercentageToAsk; // // slippage protection (9000 --> 90% of the final price must return to ask)
        bytes params; // other params (e.g., tokenId)
    }
}

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

// LooksRare exchange
interface ILooksRareExchange {
    /// @notice Match a taker ask with maker bid
    function matchBidWithTakerAsk(
        OrderTypes.TakerOrder calldata takerAsk,
        OrderTypes.MakerOrder calldata makerBid
    ) external;

    /// @notice Match ask with ETH/WETH bid
    function matchAskWithTakerBidUsingETHAndWETH(
        OrderTypes.TakerOrder calldata takerBid,
        OrderTypes.MakerOrder calldata makerAsk
    ) external payable;
}

contract SellLooksrare {
    /// @dev Wrapped Ether contract
    IWETH internal immutable WETH;
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev LooksRare exchange contract
    ILooksRareExchange internal immutable LOOKSRARE;

    /// @notice Creates a new instant sell contract
    /// @param _WETH address of WETH
    /// @param _NFT address of NFT
    /// @param _LOOKSRARE address of looksrare exchange
    /// @param _TRANSFER_MANAGER address of looksrare transfer manager ERC721
    constructor(
        address _WETH,
        address _NFT,
        address _LOOKSRARE,
        address _TRANSFER_MANAGER
    ) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup Wrapped Ether contract
        WETH = IWETH(_WETH);
        // Setup LooksRare exchange contract (0x59728544B08AB483533076417FbBB2fD0B17CE3a)
        LOOKSRARE = ILooksRareExchange(_LOOKSRARE);
        // Give LooksRare exchange approval to execuate sell (0xf42aa99F011A1fA7CDA90E5E98b277E306BcA83e)
        IERC721(_NFT).setApprovalForAll(_TRANSFER_MANAGER, true);
    }

    function executeSell(bytes memory data) external {
        // Decode variables passed in data
        (
            OrderTypes.MakerOrder memory purchaseAsk,
            OrderTypes.MakerOrder memory saleBid
        ) = abi.decode(data, (OrderTypes.MakerOrder, OrderTypes.MakerOrder));

        // Setup our taker bid to sell
        OrderTypes.TakerOrder memory saleAsk = OrderTypes.TakerOrder({
            isOrderAsk: true,
            taker: address(this),
            price: saleBid.price,
            tokenId: purchaseAsk.tokenId,
            minPercentageToAsk: saleBid.minPercentageToAsk,
            params: ""
        });

        // Accept maker ask order and sell NFT
        LOOKSRARE.matchBidWithTakerAsk(saleAsk, saleBid);
    }

    /// @notice Withdraws contract ETH balance to owner address
    function withdrawBalance() external {
        (bool sent, ) = OWNER.call{value: address(this).balance}("");
        if (!sent) revert("Could not withdraw balance");
    }

    /// @notice Withdraw contract WETH balance to owner address
    function withdrawBalanceWETH() external {
        WETH.transferFrom(address(this), OWNER, WETH.balanceOf(address(this)));
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
