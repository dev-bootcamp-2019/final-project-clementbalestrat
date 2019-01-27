# Design pattern decisions

5 major design patterns have been used in this project:

1. **Ownable** Protects critical functions by using owner only modifiers. `MarketPlace.sol` constructor is also calling the `Ownable constructor` to set `msg.sender` as the owner.

```
constructor()
Ownable()
public {
    administratorsByAddress[msg.sender] = true;
    administrators.push(msg.sender);
}
```

2. **Mortal** Allows a deprecated contract to be self destructed. `onlyOwner` modifier is used to make sure only the owner can call this function.

```
function kill() public onlyOwner {
        emit SelfDestructed(msg.sender);
        selfdestruct(msg.sender);
    }
```

3. **Pausable - Circuit breaker** Allows some of the critical parts of the contract to be stopped in case of a major issue, vulnerability or upgrade happening. `onlyOwner` modifier is also used here.

```
bool private stopped = false;

function toggle_active() public onlyOwner {
    stopped = !stopped;
}

modifier stopIfEmergency(){ require(!stopped); _; }
```

4. **Access restriction** Some of the contract functions have different level of importance and have to be restricted to only a certain category of user. Three categories have been created in the `MarketPlace` contract: Owner, Admin and StoreOwner.

```
modifier onlyAdmin() {require(administratorsByAddress[msg.sender] == true, "Sender not authorized."); _;}

modifier onlyStoreOwner() {require(storeOwnersByAddress[msg.sender] == true, "Sender not authorized."); _;}

modifier onlyStorefrontOwner(bytes32 _storeId) {require(storefrontsById[_storeId].owner == msg.sender, "Sender not authorized."); _;}
```

5. **Withdrawal pattern** Isolates the withdraw functionality to its own transaction. StoreOwners have to manually call `widthdrawStorefrontBalance` to get their store balance transferred, instead of having it done automatically after every purchase.

```
 function widthdrawStorefrontBalance(bytes32 _storeId)
    public
    onlyStorefrontOwner(_storeId)
    whenNotPaused()
    returns(bool) {
        uint storefrontBalance = storefrontsById[_storeId].balance;
        require(storefrontBalance > 0, "Balance needs to be greater than 0");
        storefrontsById[_storeId].balance = 0;
        msg.sender.transfer(storefrontBalance);
        emit BalanceWithdrawn(_storeId, storefrontBalance);
    }
```
