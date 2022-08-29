// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

/// ============ Dependicies ============
import "./marketplaces/seaport/lib/ConsiderationStructs.sol";

/// ============ Interfaces ============
import { ConsiderationInterface as ISeaport } from "./marketplaces/seaport/interfaces/ConsiderationInterface.sol";

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

contract SellSeaport {
    /// @dev Wrapped Ether contract
    IWETH internal immutable WETH;
    /// @dev Contract owner
    address internal immutable OWNER;
    /// @dev Seaport exchange contract
    ISeaport internal immutable SEAPORT;

    /// @notice Creates a new instant sell contract
    /// @param _WETH address of WETH
    /// @param _NFT address of NFT
    /// @param _SEAPORT address of seaport exchange
    /// @param _TRANSFER_MANAGER address of seaport transfer manager ERC721
    constructor(
        address _WETH,
        address _NFT,
        address _SEAPORT,
        address _TRANSFER_MANAGER
    ) {
        // Setup contract owner
        OWNER = msg.sender;
        // Setup Wrapped Ether contract
        WETH = IWETH(_WETH);
        // Setup Seaport exchange contract (0x00000000006c3852cbEf3e08E8dF289169EdE581)
        SEAPORT = ISeaport(_SEAPORT);
        // Give Seaport exchange approval to execuate sell (0x1E0049783F008A0085193E00003D00cd54003c71)
        IERC721(_NFT).setApprovalForAll(_TRANSFER_MANAGER, true);
    }

    function executeBuy(bytes memory buy_data) external {
        // Decode variables passed in data
        BasicOrderParameters memory basicComponents = abi.decode(
            buy_data,
            (BasicOrderParameters)
        );

        SEAPORT.fulfillBasicOrder(basicComponents);
    }

    function executeSell(bytes memory sell_data) external {
        // Decode variables passed in data
        BasicOrderParameters memory basicComponents = abi.decode(
            sell_data,
            (BasicOrderParameters)
        );

        SEAPORT.fulfillBasicOrder(basicComponents);
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
