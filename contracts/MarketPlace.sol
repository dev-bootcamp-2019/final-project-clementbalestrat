pragma solidity ^0.4.25;
contract MarketPlace {
    mapping (address => bool) public administrators;
    mapping (address => bool) public storeOwners;

    bytes32[] private storefronts;
    mapping (address => bytes32[]) private storefrontsByOwner;
    mapping (bytes32 => Storefront) private storefrontById;
    mapping(bytes32 => bytes32[]) private inventoryByStorefrontId;
    mapping(bytes32 => Item) private itemById;

    address public owner;

    struct Storefront {
        bytes32 id;
        string name;
        address owner;
        uint balance;
    }

    struct Item {
        bytes32 id;
        string name;
        uint price;
        uint quantity;
    }

    event adminAdded(address admin);
    event adminRemoved(address admin);
    event storeOwnerAdded(address storeOwner);
    event storeOwnerRemoved(address storeOwner);
    event storeCreated(bytes32 id, string name, address owner);
    event storeRemoved(bytes32 id);
    event balanceWithdrawn(bytes32 id, uint balance);
    event itemAdded(bytes32 id, string name, uint price, uint qty);
    event itemRemoved(bytes32 id);
    event itemPriceUpdated(bytes32 id, uint newPrice, uint oldPrice);
    event itemQuantityUpdated(bytes32 id, uint newQty, uint oldQty);
    event itemSold(bytes32 storeId, bytes32 itemId, uint qty);

    modifier onlyAdmin() {require(administrators[msg.sender] == true, "Sender not authorized."); _;}
    modifier onlyStoreOwner() {require(storeOwners[msg.sender] == true, "Sender not authorized."); _;}
    modifier onlyStorefrontOwner(bytes32 id) {require(storefrontById[id].owner == msg.sender, "Sender not authorized."); _;}

    constructor() public {
        owner = msg.sender;
        administrators[msg.sender] = true;
    }

    function addAdmin(address addr)
    public
    onlyAdmin()
    returns(bool) {
        administrators[addr] = true;
        emit adminAdded(addr);
        return true;
    }

    function removeAdmin(address addr)
    public
    onlyAdmin()
    returns(bool) {
        administrators[addr] = false;
        emit adminRemoved(addr);
        return true;
    }

    function addStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwners[addr] = true;
        emit storeOwnerAdded(addr);
        return true;
    }

    function removeStoreOwner(address addr)
    public
    onlyAdmin()
    returns(bool) {
        storeOwners[addr] = false;
        emit storeOwnerRemoved(addr);
        return true;
    }

    function createStore(string name)
    public
    onlyStoreOwner()
    returns(bytes32) {
        bytes32 id = keccak256(abi.encodePacked(msg.sender, name, now));
        Storefront memory s = Storefront(id, name, msg.sender, 0);
        storefronts.push(id);
        storefrontsByOwner[msg.sender].push(id);
        storefrontById[id] = s;
        emit storeCreated(id, name, msg.sender);
        return id;
    }

    function removeStore(bytes32 storeId)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {

        // Delete all the items from the store inventory
        for (uint i = 0; i < inventoryByStorefrontId[storeId].length; i++) {
            bytes32 itemId = inventoryByStorefrontId[storeId][i];
            delete itemById[itemId];
        }

        // Delete the store inventory
        delete inventoryByStorefrontId[storeId];

        // Remove from storefrontsByOwner mapping
        uint storefrontCount = storefrontsByOwner[msg.sender].length;
        for(i = 0; i < storefrontCount; i++) {
            if (storefrontsByOwner[msg.sender][i] == storeId) {
                storefrontsByOwner[msg.sender][i] = storefrontsByOwner[msg.sender][storefrontCount-1];
                delete storefrontsByOwner[msg.sender][storefrontCount-1];
                break;
            }
        }

        // Remove from storefronts array
        storefrontCount = storefronts.length;
        for(i = 0; i < storefrontCount; i++) {
            if (storefronts[i] == storeId) {
                delete storefronts[i];
                break;
            }
        }

        // Withdraw Balance
        uint storefrontBalance = storefrontById[storeId].balance;
        if (storefrontBalance > 0) {
            msg.sender.transfer(storefrontBalance);
            storefrontById[storeId].balance = 0;
            emit balanceWithdrawn(storeId, storefrontBalance);
        }

        // Remove from storefrontById
        delete storefrontById[storeId];
        emit storeRemoved(storeId);
        return storeId;
    }

    function addItemToInventory(bytes32 storeId, string itemName, uint itemPrice, uint itemQuantity)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        bytes32 itemId = keccak256(abi.encodePacked(msg.sender, itemName, now));
        Item memory i = Item(itemId, itemName, itemPrice, itemQuantity);
        itemById[itemId] = i;
        inventoryByStorefrontId[storeId].push(itemId);
        emit itemAdded(itemId, itemName, itemPrice, itemQuantity);
        return itemId;
    }

    function removeItemFromInventory(bytes32 itemId, bytes32 storeId)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        // Remove the item from inventory mapping
        uint itemCount = inventoryByStorefrontId[storeId].length;
        for(uint i = 0; i < itemCount; i++) {
            if (inventoryByStorefrontId[storeId][i] == storeId) {
                inventoryByStorefrontId[storeId][i] = inventoryByStorefrontId[storeId][itemCount-1];
                delete inventoryByStorefrontId[storeId][itemCount-1];
                break;
            }
        }
        //Remove item from items mapping
        delete itemById[itemId];
        emit itemRemoved(itemId);
        return itemId;
    }

    function updateItemPrice(bytes32 itemId, bytes32 storeId, uint newPrice)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldPrice = itemById[itemId].price;
        itemById[itemId].price = newPrice;
        emit itemPriceUpdated(itemId, newPrice, oldPrice);
        return itemId;
    }

    function updateItemQuantity(bytes32 itemId, bytes32 storeId, uint newQty)
    public
    onlyStorefrontOwner(storeId)
    returns(bytes32) {
        uint oldQty = itemById[itemId].quantity;
        itemById[itemId].quantity = newQty;
        emit itemQuantityUpdated(itemId, newQty, oldQty);
        return itemId;
    }

    function purchaseItem(bytes32 storeId, bytes32 itemId, uint quantity)
    public
    payable
    returns(bool) {
        Item memory item = itemById[itemId];
        uint totalPrice = item.price * quantity;
        require(msg.value >= totalPrice, "msg.value must be greater or equal than total price");
        require(item.quantity >= quantity, "Item quantity is not enough");

        if (msg.value > totalPrice) {
            msg.sender.transfer(msg.value - totalPrice);
        }

        item.quantity -= quantity;
        storefrontById[storeId].balance += totalPrice;
        emit itemSold(storeId, itemId, quantity);
        return true;
    }

}
