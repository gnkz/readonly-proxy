// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

import {Test} from "forge-std/Test.sol";
import {ReadOnlyProxy} from "../src/ReadOnlyProxy.sol";

contract Readable is ReadOnlyProxy {
    address immutable READER;

    bytes32 private secret = keccak256("SECRET");

    mapping(address => uint256) private map;

    constructor(address reader) {
        READER = reader;
    }

    function add(address _key, uint256 _value) external {
        map[_key] = _value;
    }

    function _reader() internal view override returns (address) {
        return READER;
    }
}

contract Reader {
    bytes32 private secret;

    mapping(address => uint256) private map;

    function getSecret() external view returns (bytes32) {
        return secret;
    }

    function getValue(address _addr) external view returns (uint256) {
        return map[_addr];
    }

    function write(string calldata _newSecret) external {
        secret = keccak256(bytes(_newSecret));
    }
}

contract ReaOnlyProxyTest is Test {
    Readable readable;

    function setUp() external {
        readable = new Readable(address(new Reader()));
    }

    function testItCanBeRead() external {
        // add dummy data
        readable.add(address(1337), 1337);

        // wrap the readable
        Reader reader = Reader(address(readable));

        // get data stored in the readable contract
        vm.assertEq(reader.getSecret(), keccak256("SECRET"));
        vm.assertEq(reader.getValue(address(1337)), 1337);

        // if a reader tries to modify the state it should fail
        vm.expectRevert();
        reader.write("NEW_SECRET");
    }

    /// `_delegate` cannot be called directly
    function testDelegateIsNotCallable() external {
        vm.expectRevert(ReadOnlyProxy.DelegateCallNotAllowed.selector);
        readable._delegate(abi.encodeWithSignature("getSecret()"));
    }
}
