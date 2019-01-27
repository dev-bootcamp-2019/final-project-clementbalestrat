# Avoiding common attacks

1. **Prefer newer Solidity constructs**

- `selfdestruct` is used over `suicide` (see `Mortal.sol`)
- `transfer` is used over `require(msg.sender.send())`
- `keccak256` is used over `sha3`

2. **Ownable** To secure admin only function, openzeppelin `Ownable` library has been used.

3. **Pausable** Allows some of the critical parts of the contract to be stopped in case of a major issue, vulnerability or upgrade happening. openzeppelin `Pausable` library has been used.

4. **Integer overflow and underflow - SafeMath** An overflow/underflow happens when an arithmetic operation reach the maximum or minimum size of the type. This could happen whenever you are doing arithmetic operations such as + , - , \* When using openzeppelin `SafeMath` library, the result of those operations will be checked and an error will be thrown stopping the execution of your smart contract.

5. **Access restriction** Some of the contract functions have different level of importance and have to be restricted to only a certain category of user. Three categories have been created in the `MarketPlace` contract: Owner, Admin and StoreOwner.

```
modifier onlyAdmin() {require(administratorsByAddress[msg.sender] == true, "Sender not authorized."); _;}

modifier onlyStoreOwner() {require(storeOwnersByAddress[msg.sender] == true, "Sender not authorized."); _;}

modifier onlyStorefrontOwner(bytes32 _storeId) {require(storefrontsById[_storeId].owner == msg.sender, "Sender not authorized."); _;}
```

6. **Reentrancy** Balance is updated before transferring the funds. It avoids reentrancy attacks, which could potentially use the `transfer()` method multiple times in a loop until they run out of gas (or contract runs out of funds).

```
storefrontsById[_storeId].balance = 0;
msg.sender.transfer(storefrontBalance);
```
