// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SellSeaport.sol";

contract SellSeaportTest is Test {
    // ============  Storage ============
    /// @notice Wrapped Ether contract
    IWETH public WETH;
    /// @notice SellSeaport contract
    SellSeaport public SEAPORT;

    // ============  Functions ============
    /// @notice Setup tests
    function setUp() public {
        // Setup WETH
        WETH = IWETH(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
        // Initialize SellSeaport
        SEAPORT = new SellSeaport(
            address(WETH), // Wrapped Ether
            0x5Af0D9827E0c53E4799BB226655A1de152A425a5, // MIL
            0x00000000006c3852cbEf3e08E8dF289169EdE581, // Seaport exchange
            0x1E0049783F008A0085193E00003D00cd54003c71 // Seaport transfer manager
        );
    }

    /// @notice Test instant sell on Seaport
    function testInstantSell() public {
        // Enforce contract starts with 0 balance
        vm.deal(address(SEAPORT), 0);

        // Setup purchase order
        // Details from Seaport API (https://docs.opensea.io/v2.0/reference/retrieve-listings)
        AdditionalRecipient[] memory totalAdditionalRecipients = new AdditionalRecipient[](2);
        totalAdditionalRecipients[0] = AdditionalRecipient({
            amount: 15000000000000000,
            recipient: payable(0x0000a26b00c1F0DF003000390027140000fAa719)
        });
        totalAdditionalRecipients[1] = AdditionalRecipient({
            amount: 30000000000000000,
            recipient: payable(0xcf3e932f72E5f15411d125ad80579a3ef205b9B4)
        });

        BasicOrderParameters memory basicComponents = BasicOrderParameters({
            considerationToken: 0x0000000000000000000000000000000000000000,
            considerationIdentifier: 0,
            considerationAmount: 555000000000000000,
            offerer: payable(0x72009005C9F76a8EFF11F06d179E814Be84dE896),
            zone: 0x004C00500000aD104D7DBd00e3ae0A5C00560C00,
            offerToken: 0x5Af0D9827E0c53E4799BB226655A1de152A425a5,
            offerIdentifier: 5313,
            offerAmount: 1,
            basicOrderType: BasicOrderType.ETH_TO_ERC721_FULL_OPEN,
            startTime: 1661530712,
            endTime: 1662135512,
            zoneHash: 0x0000000000000000000000000000000000000000000000000000000000000000,
            salt: 36,
            offererConduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
            fulfillerConduitKey: 0x0000007b02230091a7ed01230072f7006a004d60a8d4e71d599b8104250f0000,
            totalOriginalAdditionalRecipients: 2,
            additionalRecipients: totalAdditionalRecipients,
            signature: hex"59170531eb5a58783044c02dbe61b08888e66bfa2f5bbbf4c6ce37d37894c775b0cc55035913cc8e858c08bf755bc8b81163de740811145770081afd5149dd15"
        });

        // execute buy on seaport
        SEAPORT.executeBuy(abi.encode(basicComponents));
    }

    /// @notice Allows receiving ETH
    receive() external payable {}
}
