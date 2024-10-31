# Read-Only Solidity Proxy

> [!CAUTION]
> This is a just-for-fun idea I had and the contract is not audited so use with caution.

`ReadOnlyProxy` is a smart contract that enables call delegation while preserving the state context, ensuring that any calls made through the proxy are restricted to read-only access to the storage.

This read-only access is enforced by using `staticcall` to call a function that performs a `delegatecall` to the target contract.

## Build

`forge build`

## Tests

`forge test`
