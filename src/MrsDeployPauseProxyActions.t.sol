pragma solidity ^0.5.15;

import "ds-test/test.sol";

import "./MrsDeployPauseProxyActions.sol";
import {MrsDeployTestBase} from "mrs-deploy/MrsDeploy.t.base.sol";
import {DSProxyFactory, DSProxy} from "mrs-deploy/ds/proxy/proxy.sol";
import {PipLike} from "mrs/spot.sol";

contract ProxyCalls {
    DSProxy proxy;
    address proxyActions;

    function file(address, address, address, bytes32, uint) public {
        proxy.execute(proxyActions, msg.data);
    }

    function file(address, address, address, bytes32, bytes32, uint) public {
        proxy.execute(proxyActions, msg.data);
    }

    function file(address, address, address, bytes32, bytes32, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function rely(address, address, address, address) public {
        proxy.execute(proxyActions, msg.data);
    }

    function setAuthorityAndDelay(address, address, address, uint) public {
        proxy.execute(proxyActions, msg.data);
    }
}

contract MrsDeployPauseProxyActionsTest is MrsDeployTestBase, ProxyCalls {
    function setUp() public {
        super.setUp();
        deployStable();
        DSProxyFactory factory = new DSProxyFactory();
        proxyActions = address(new MrsDeployPauseProxyActions());
        proxy = DSProxy(factory.build());
        authority.setRootUser(address(proxy), true);
    }

    function testFile() public {
        assertEq(vat.Line(), 10000 * 10 ** 45);
        this.file(address(pause), address(govActions), address(vat), bytes32("Line"), uint(20000 * 10 ** 45));
        assertEq(vat.Line(), 20000 * 10 ** 45);
    }

    function testFile2() public {
        (,,, uint line,,) = vat.ilks("ETH");
        assertEq(line, 10000 * 10 ** 45);
        this.file(address(pause), address(govActions), address(vat), bytes32("ETH"), bytes32("line"), uint(20000 * 10 ** 45));
        (,,, line,,) = vat.ilks("ETH");
        assertEq(line, 20000 * 10 ** 45);
    }

    function testFile3() public {
        (PipLike pip,,) = spotter.ilks("ETH");
        assertEq(address(pip), address(pipETH));
        this.file(address(pause), address(govActions), address(spotter), bytes32("ETH"), bytes32("pip"), address(123));
        (pip,,) = spotter.ilks("ETH");
        assertEq(address(pip), address(123));
    }

    function testRely() public {
        assertEq(spotter.wards(address(123)), 0);
        this.rely(address(pause), address(govActions), address(spotter), address(123));
        assertEq(spotter.wards(address(123)), 1);
    }

    function testDripAndFile() public {
        (uint duty,) = jug.ilks("ETH");
        assertEq(duty, 10 ** 27);
        this.file(address(pause), address(govActions), address(jug), bytes32("ETH"), bytes32("duty"), uint(2 * 10 ** 27));
        (duty,) = jug.ilks("ETH");
        assertEq(duty, 2 * 10 ** 27);
    }

    function testDripAndFile2() public {
        assertEq(pot.sr(), 10 ** 27);
        this.file(address(pause), address(govActions), address(pot), bytes32("sr"), uint(2 * 10 ** 27));
        assertEq(pot.sr(), 2 * 10 ** 27);
    }

    function testSetAuthorityAndDelay() public {
        assertEq(address(pause.authority()), address(authority));
        assertEq(pause.delay(), 0);
        this.setAuthorityAndDelay(address(pause), address(govActions), address(123), 5);
        assertEq(address(pause.authority()), address(123));
        assertEq(pause.delay(), 5);
    }
}
