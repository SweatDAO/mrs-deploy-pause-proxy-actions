pragma solidity 0.6.7;

import "ds-test/test.sol";

import "./GebDeployPauseProxyActions.sol";
import {GebDeployTestBase} from "geb-deploy/test/GebDeploy.t.base.sol";
import {DSProxyFactory, DSProxy} from "ds-proxy/proxy.sol";
import {OracleLike} from "geb/OracleRelayer.sol";

contract ProxyCalls {
    DSProxy proxy;
    address proxyActions;

    function modifyParameters(address, address, address, bytes32, uint) public {
        proxy.execute(proxyActions, msg.data);
    }

    function modifyParameters(address, address, address, bytes32, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function modifyParameters(address, address, address, bytes32, bytes32, uint) public {
        proxy.execute(proxyActions, msg.data);
    }

    function modifyParameters(address, address, address, bytes32, bytes32, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function modifyParameters(address, address, address, bytes32, uint256, uint256, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function modifyParameters(address, address, address, bytes32, uint256, uint256) public {
        proxy.execute(proxyActions, msg.data);
    }

    function addAuthorization(address, address, address, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setAuthorityAndDelay(address, address, address, uint) public {
        proxy.execute(proxyActions, msg.data);
    }

    function updateRedemptionRate(address, address, address, bytes32, uint256) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setProtester(address pause, address actions, address protester) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setOwner(address pause, address actions, address owner) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setDelay(address pause, address actions, uint newDelay) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setDelayMultiplier(address pause, address actions, uint delayMultiplier) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setTotalAllowance(address pause, address actions, address who, address account, uint rad) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setPerBlockAllowance(address pause, address actions, address who, address account, uint rad) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setAllowance(address pause, address actions, address join, address account, uint allowance) public {
        proxy.execute(proxyActions, msg.data);
    }
}

contract GebDeployPauseProxyActionsTest is GebDeployTestBase, ProxyCalls {
    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        PAUSE_TYPE = keccak256(abi.encodePacked("PROTEST"));
        super.setUp();
        deployStable(collateralAuctionType);
        DSProxyFactory factory = new DSProxyFactory();
        proxyActions = address(new GebDeployPauseProxyActions());
        proxy = DSProxy(factory.build());
        authority.setRootUser(address(proxy), true);
    }

    function testmodifyParameters() public {
        assertEq(safeEngine.globalDebtCeiling(), 10000 * 10 ** 45);
        this.modifyParameters(address(pause), address(govActions), address(safeEngine), bytes32("globalDebtCeiling"), uint(20000 * 10 ** 45));
        assertEq(safeEngine.globalDebtCeiling(), 20000 * 10 ** 45);
    }

    function testModifyParameters2() public {
        (,,, uint debtCeiling,,) = safeEngine.collateralTypes("ETH");
        assertEq(debtCeiling, 10000 * 10 ** 45);
        this.modifyParameters(address(pause), address(govActions), address(safeEngine), bytes32("ETH"), bytes32("debtCeiling"), uint(20000 * 10 ** 45));
        (,,, debtCeiling,,) = safeEngine.collateralTypes("ETH");
        assertEq(debtCeiling, 20000 * 10 ** 45);
    }

    function testModifyParameters3() public {
        (OracleLike orcl,,) = oracleRelayer.collateralTypes("ETH");
        assertEq(address(orcl), address(orclETH));
        this.modifyParameters(address(pause), address(govActions), address(oracleRelayer), bytes32("ETH"), bytes32("orcl"), address(123));
        (orcl,,) = oracleRelayer.collateralTypes("ETH");
        assertEq(address(orcl), address(123));
    }

    function testModifyParameters4() public {
        assertTrue(address(accountingEngine.protocolTokenAuthority()) == address(0));
        this.modifyParameters(address(pause), address(govActions), address(accountingEngine), bytes32("protocolTokenAuthority"), address(123));
        assertTrue(address(accountingEngine.protocolTokenAuthority()) == address(123));
    }

    function testModifyParameters5And6() public {
        assertTrue(!taxCollector.isSecondaryReceiver(1));
        assertEq(taxCollector.maxSecondaryReceivers(), 0);
        this.modifyParameters(address(pause), address(govActions), address(taxCollector), bytes32("maxSecondaryReceivers"), 2);
        assertEq(taxCollector.maxSecondaryReceivers(), 2);
        this.modifyParameters(address(pause), address(govActions), address(taxCollector), bytes32("ETH"), 100, 10 ** 27, address(this));
        (uint canTakeBackTax, uint taxPercentage) = taxCollector.secondaryTaxReceivers(bytes32("ETH"), 1);
        assertEq(canTakeBackTax, 0);
        assertEq(taxPercentage, 10 ** 27);
        assertTrue(taxCollector.isSecondaryReceiver(1));
        this.modifyParameters(address(pause), address(govActions), address(taxCollector), bytes32("ETH"), 1, 1);
        (canTakeBackTax, taxPercentage) = taxCollector.secondaryTaxReceivers(bytes32("ETH"), 1);
        assertEq(canTakeBackTax, 1);
        assertEq(taxPercentage, 10 ** 27);
    }

    function testAddAuthorization() public {
        assertEq(oracleRelayer.authorizedAccounts(address(123)), 0);
        this.addAuthorization(address(pause), address(govActions), address(oracleRelayer), address(123));
        assertEq(oracleRelayer.authorizedAccounts(address(123)), 1);
    }

    function testUpdateRedemptionRate() public {
        hevm.warp(now + 1);
        assertTrue(oracleRelayer.redemptionPriceUpdateTime() < now);
        this.updateRedemptionRate(address(pause), address(govActions), address(oracleRelayer), bytes32("redemptionRate"), 10 ** 27 + 1);
        assertEq(oracleRelayer.redemptionPriceUpdateTime(), now);
    }

    function testUpdateAccumulatedRateAndModifyParameters() public {
        (uint stabilityFee,) = taxCollector.collateralTypes("ETH");
        assertEq(stabilityFee, 10 ** 27);
        this.modifyParameters(address(pause), address(govActions), address(taxCollector), bytes32("ETH"), bytes32("stabilityFee"), uint(2 * 10 ** 27));
        (stabilityFee,) = taxCollector.collateralTypes("ETH");
        assertEq(stabilityFee, 2 * 10 ** 27);
    }

    function testUpdateAccumulatedRateAndModifyParameters2() public {
        assertEq(coinSavingsAccount.savingsRate(), 10 ** 27);
        this.modifyParameters(address(pause), address(govActions), address(coinSavingsAccount), bytes32("savingsRate"), uint(2 * 10 ** 27));
        assertEq(coinSavingsAccount.savingsRate(), 2 * 10 ** 27);
    }

    function testSetAuthorityAndDelay() public {
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.delay(), 0);
        this.setAuthorityAndDelay(address(pause), address(govActions), address(123), 5);
        assertEq(address(pause.authority()), address(123));
        assertEq(pause.delay(), 5);
    }

    function testSetProtester() public {
        assertEq(address(pause.protester()), address(0));
        this.setProtester(address(pause), address(govActions), address(124));
        assertEq(address(pause.protester()), address(124));
    }

    function testSetOwner() public {
        assertEq(address(pause.owner()), address(0));
        this.setOwner(address(pause), address(govActions), address(124));
        assertEq(address(pause.owner()), address(124));
    }

    function testSetDelay() public {
        assertEq(pause.delay(), 0);
        this.setDelay(address(pause), address(govActions), 1024);
        assertEq(pause.delay(), 1024);
    }

    function testSetDelayMultiplier() public {
        assertEq(pause.delayMultiplier(), 1);
        this.setDelayMultiplier(address(pause), address(govActions), 3);
        assertEq(pause.delayMultiplier(), 3);
    }

    function testSetTotalAllowance() public {
        uint allowance = 25 * 10 ** 45;
        (uint total,) = stabilityFeeTreasury.getAllowance(address(1));
        assertEq(total, 0);
        this.setTotalAllowance(address(pause), address(govActions), address(stabilityFeeTreasury), address(1), allowance);
        (total,) = stabilityFeeTreasury.getAllowance(address(1));
        assertEq(total, allowance);
    }

    function testSetPerBlockAllowance() public {
        uint allowance = 25 * 10 ** 45;
        (, uint perBlock) = stabilityFeeTreasury.getAllowance(address(1));
        assertEq(perBlock, 0);
        this.setPerBlockAllowance(address(pause), address(govActions), address(stabilityFeeTreasury), address(1), allowance);
        (, perBlock) = stabilityFeeTreasury.getAllowance(address(1));
        assertEq(perBlock, allowance);
    }

    function testSetAllowance() public {
        uint allowance = 25 * 10 ** 45;
        assertEq(col6Join.allowance(address(1)), 0);
        this.setAllowance(address(pause), address(govActions), address(col6Join), address(1), allowance);
        assertEq(col6Join.allowance(address(1)), allowance);
    }
}
