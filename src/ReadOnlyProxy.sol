// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;

/// @title A read-only proxy contract
/// @author Gonzalo Sánchez <gnkz.dev@gmail.com>
/// @notice The purpose of this contract is to have a way to proxy calls to another contract but
/// making sure those calls are not able to modify the state. This could be useful in scenarios
/// where there are needs to decrease smart contract sizes by removing public read only functions
/// @dev To make sure the call is read only there is a `delegatecall` that's invoked inside a
/// `staticcall`, this way the delegated contract has access to the storage but is limited by the
/// `staticcall` so if there is any modification to the state the call will revert
abstract contract ReadOnlyProxy {
    error DelegateCallNotAllowed();

    receive() external payable {
        _beforeFallback();
        _fallback();
    }

    fallback() external payable {
        _beforeFallback();
        _fallback();
    }

    /// @notice function in charge of doing a `delegatecall` to the `reader` contract
    /// @param _data the abi encoded method to call on `reader`
    function _delegate(bytes memory _data) external {
        // can only be called from self
        if (msg.sender != address(this)) {
            revert DelegateCallNotAllowed();
        }

        address reader = _reader();

        assembly {
            // delegate the call to the `reader`
            let result := delegatecall(gas(), reader, add(_data, 0x20), mload(_data), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice called inside the `fallback` or `receive` functions. It does an `staticcall` on
    /// `_delegate` proxying `msg.data`
    function _fallback() internal view {
        address self = address(this);
        bytes memory data = abi.encodeWithSelector(ReadOnlyProxy._delegate.selector, msg.data);

        assembly {
            // do an static call to `self._delegate` using `msg.data`
            let result := staticcall(gas(), self, add(data, 0x20), mload(data), 0, 0)

            returndatacopy(0, 0, returndatasize())

            switch result
            case 0 { revert(0, returndatasize()) }
            default { return(0, returndatasize()) }
        }
    }

    /// @notice function used to get the `reader` contract address
    function _reader() internal view virtual returns (address);

    /// @notice called before the `_fallback` function
    /// @dev just for flexibility
    function _beforeFallback() internal virtual {}
}
