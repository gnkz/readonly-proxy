// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

abstract contract ReadOnlyProxy {
    error DelegateCallNotAllowed();

    function _delegate(bytes memory _data) public {
        if (msg.sender != address(this)) {
            revert DelegateCallNotAllowed();
        }

        address reader = _reader();

        assembly {
            // Call the implementation.
            // out and outsize are 0 because we don't know the size yet.
            let result := delegatecall(gas(), reader, add(_data, 0x20), mload(_data), 0, 0)

            // Copy the returned data.
            returndatacopy(0, 0, returndatasize())

            switch result
            // delegatecall returns 0 on error.
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _fallback() internal view {
        address self = address(this);
        bytes memory data = abi.encodeWithSignature("_delegate(bytes)", msg.data);

        assembly {
            let result := staticcall(gas(), self, add(data, 0x20), mload(data), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    function _reader() internal view virtual returns (address);

    fallback() external payable {
        _fallback();
    }

    receive() external payable {
        _fallback();
    }
}
