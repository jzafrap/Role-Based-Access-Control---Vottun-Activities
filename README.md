In this repository, we take the sample DAO smart contract, and add Role Based Access Control, based in open Zeppelin smart contracts.
So executeProposal method of DAO smart contract only can be called by an EXECUTOR_ROLE address.

This sample DAO smart contract has been created and deployed in Polygon Amoy testnet using [Vottun Web APIs](https://app.vottun.io/smart-contracts/12260),
- deployed address: 0x1cf0E1ad60355A5af6D3603DCf6adEDe69b06f18
- deployed txn: [0x1cfa188c168edc5ebd6138d83530e015666222bd132c86cf561b20eb1da6bf6f](https://www.oklink.com/amoy/tx/0x1cfa188c168edc5ebd6138d83530e015666222bd132c86cf561b20eb1da6bf6f)

# How To - Role Based Access Control

## Adding Role Based Access Control to an existing smart contract

- first step is import Accesscontrol.sol smart contract from @openZeppelin.
```solidity
import "@openzeppelin/contracts/access/AccessControl.sol";
```
  
- second step, is inherit DAO smart contract from AccessControl:
```solidity
contract DAO is AccessControl {
    // ... rest of your contract
}
```
 - then, define EXECUTOR ROLE:

```solidity
 bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");
```
- Grant the EXECUTOR ROLE in the constructor of DAO Smart Contract:

```solidity
constructor(address _tokenAddress, address _treasuryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender); // Grant admin role to the deployer
        _grantRole(EXECUTOR_ROLE, msg.sender); // Grant executor role to the deployer initially
        token = IERC20(_tokenAddress);
        treasury = _treasuryAddress;
}
```
- and last step: modify executeProposal function:
```solidity
 function executeProposal(uint256 _proposalId) public onlyRole(EXECUTOR_ROLE) {
        // ... rest of the executeProposal logic
 }
```
- let's see the complete code of adapted DAO smart contract with Role Based Access Control:

```solidity
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IERC20.sol"; // Assuming you have a separate IERC20 interface file

contract DAO is AccessControl {
    // ...  Proposal struct and other variables

    bytes32 public constant EXECUTOR_ROLE = keccak256("EXECUTOR_ROLE");

    constructor(address _tokenAddress, address _treasuryAddress) {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(EXECUTOR_ROLE, msg.sender); 
        token = IERC20(_tokenAddress);
        treasury = _treasuryAddress;
    }

    // ...  createProposal and vote functions

    function executeProposal(uint256 _proposalId) public onlyRole(EXECUTOR_ROLE) {
        // ... rest of the executeProposal logic
    }

    function grantExecutorRole(address _executor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _grantRole(EXECUTOR_ROLE, _executor);
    }

    function revokeExecutorRole(address _executor) public onlyRole(DEFAULT_ADMIN_ROLE) {
        _revokeRole(EXECUTOR_ROLE, _executor);
    }
}
```
  

