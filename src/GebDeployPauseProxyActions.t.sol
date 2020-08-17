pragma solidity ^0.6.7;

import "ds-test/test.sol";

import "./GebDeployPauseProxyActions.sol";
import {GebDeployTestBase} from "geb-deploy/GebDeploy.t.base.sol";
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

    function addAuthorization(address, address, address, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setAuthorityAndDelay(address, address, address, uint) public {
        proxy.execute(proxyActions, msg.data);
    }
}

contract GebDeployPauseProxyActionsTest is GebDeployTestBase, ProxyCalls {
    bytes32 collateralAuctionType = bytes32("ENGLISH");

    function setUp() override public {
        super.setUp();
        deployStable(collateralAuctionType);
        DSProxyFactory factory = new DSProxyFactory();
        proxyActions = address(new GebDeployPauseProxyActions());
        proxy = DSProxy(factory.build());
        authority.setRootUser(address(proxy), true);
    }

    function testmodifyParameters() public {
        assertEq(cdpEngine.globalDebtCeiling(), 10000 * 10 ** 45);
        this.modifyParameters(address(pause), address(govActions), address(cdpEngine), bytes32("globalDebtCeiling"), uint(20000 * 10 ** 45));
        assertEq(cdpEngine.globalDebtCeiling(), 20000 * 10 ** 45);
    }

    function testModifyParameters2() public {
        (,,, uint debtCeiling,,) = cdpEngine.collateralTypes("ETH");
        assertEq(debtCeiling, 10000 * 10 ** 45);
        this.modifyParameters(address(pause), address(govActions), address(cdpEngine), bytes32("ETH"), bytes32("debtCeiling"), uint(20000 * 10 ** 45));
        (,,, debtCeiling,,) = cdpEngine.collateralTypes("ETH");
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

    function testRely() public {
        assertEq(oracleRelayer.authorizedAccounts(address(123)), 0);
        this.addAuthorization(address(pause), address(govActions), address(oracleRelayer), address(123));
        assertEq(oracleRelayer.authorizedAccounts(address(123)), 1);
    }

    function updateRedemptionRate() public {
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
}
