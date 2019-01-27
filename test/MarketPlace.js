const { assertEventEqual } = require('../utils/testUtils');
const ethers = require('ethers');
const MarketPlace = artifacts.require('MarketPlace');

contract('MarketPlace', async accounts => {
  const [owner, account1, account2, storeOwner] = accounts;
  let marketPlace;

  beforeEach(async () => {
    marketPlace = await MarketPlace.new();
  });

  describe('when admin', () => {
    it('allows an admin to add another admin', async () => {
      // We add a new admin
      await marketPlace.addAdmin(account1, { from: owner });
      // Check if the address has been added to the storage mapping.
      const isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, true);
    });
    it('allows an admin to remove another admin', async () => {
      // We add a new admin
      await marketPlace.addAdmin(account1, { from: owner });
      let isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, true);
      //Now that the admin has been added, we remove him.
      await marketPlace.removeAdmin(account1, { from: owner });
      // Then we check if he's not in the storage mapping anymore
      isAdmin = await marketPlace.administratorsByAddress(account1);
      assert.equal(isAdmin, false);
    });
    it('allows an admin to add a store owner', async () => {
      // We add a new store owner
      await marketPlace.addStoreOwner(account2, { from: owner });
      // Check if the address has been added to the storage mapping.
      const isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, true);
    });
    it('allows an admin to remove a store owner', async () => {
      // We add a new store owner
      await marketPlace.addStoreOwner(account2, { from: owner });
      let isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, true);
      //Now that the store owner has been added, we remove him.
      await marketPlace.removeStoreOwner(account2, { from: owner });
      // Then we check if he's not in the storage mapping anymore
      isStoreOwner = await marketPlace.storeOwnersByAddress(account2);
      assert.equal(isStoreOwner, false);
    });
    it('allows to see all the admin addresses', async () => {
      // Calling the view function to make sure the first admin is the owner
      const admins = await marketPlace.getAdministrators();
      assert.equal(admins[0], owner);
    });

    it('allows to see all the store owner addresses', async () => {
      // We add a new store owner
      await marketPlace.addStoreOwner(account2, { from: owner });
      // And we make sure he appears in the getter function
      const storeOwners = await marketPlace.getStoreOwners();
      assert.equal(storeOwners[0], account2);
    });
  });

  describe('when store owner', () => {
    beforeEach(async () => {
      await marketPlace.addStoreOwner(storeOwner, { from: owner });
    });
    it('allows a store owner to create a store', async () => {
      // We need to encode the string to bytes32 before
      const storeName = ethers.utils.formatBytes32String('My New Store');
      // We create the store
      const transaction = await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      // And then check if the StoreCreated event has been emitted
      assertEventEqual(transaction, 'StoreCreated', {
        name: storeName,
        storeOwner,
      });
    });
    it('allows a store owner to remove their store', async () => {
      // We need to encode the string to bytes32 before
      const storeName = ethers.utils.formatBytes32String('My New Store');
      // We create the store
      const transaction = await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      const storeId = await marketPlace.storefrontsByOwner(storeOwner, 0);
      let store = await marketPlace.storefrontsById(storeId);
      // It should have an ID
      assert.notEqual(store.id, 0);
      // Then we remove it
      await marketPlace.removeStore(storeId, {
        from: storeOwner,
      });
      store = await marketPlace.storefrontsById(storeId);
      assert.equal(store.id, 0);
    });
    it('allows a store owner to add an item to their store', async () => {
      const storeName = ethers.utils.formatBytes32String('My New Store');
      const itemName = ethers.utils.formatBytes32String('My New Item');
      // We create a store
      await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      // We get the store ID
      const storeId = await marketPlace.storefronts(0);
      // We add an item to this store
      const transaction = await marketPlace.addItemToInventory(
        storeId,
        itemName,
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('20'),
        { from: storeOwner }
      );
      // We check if ItemAdded event has been emitted.
      assertEventEqual(transaction, 'ItemAdded', {
        name: itemName,
      });
    });
  });

  describe('when buyer', () => {
    var storefrontId;
    beforeEach(async () => {
      //We create an owner, a storefront and an item.
      await marketPlace.addStoreOwner(storeOwner, { from: owner });
      const storeName = ethers.utils.formatBytes32String('My New Store');
      const transaction = await marketPlace.createStore(storeName, {
        from: storeOwner,
      });
      storefrontId = await marketPlace.storefronts(0);
      await marketPlace.addItemToInventory(
        storefrontId,
        ethers.utils.formatBytes32String('test'),
        ethers.utils.parseEther('1'),
        ethers.utils.parseEther('20'),
        { from: storeOwner }
      );
    });
    it('allows a buyer to purchase an item', async () => {
      // We get the ID of the latest added item
      const itemId = await marketPlace.inventoryByStorefrontId(storefrontId, 0);
      // We buy this item
      const transaction = await marketPlace.purchaseItem(
        storefrontId,
        itemId,
        ethers.utils.parseEther('2'),
        { value: ethers.utils.parseEther('2') }
      );
      // And check if the ItemSold event has been emitted
      assertEventEqual(transaction, 'ItemSold', {
        storeId: storefrontId,
        itemId: itemId,
      });
    });
  });
});
