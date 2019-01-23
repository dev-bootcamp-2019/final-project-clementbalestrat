const { assertEventEqual } = require('../utils/testUtils');
const MarketPlace = artifacts.require('MarketPlace');

contract('MarketPlace', async accounts => {
  const [ owner, account1, account2, storeOwner] = accounts;
  let marketPlace;

  beforeEach(async () => {
    marketPlace = await MarketPlace.deployed();
  });

  describe('when admin', () => {
    it('allows an admin to add another admin', async () => {
      await marketPlace.addAdmin(account1, { from: owner });
      const isAdmin = await marketPlace.isAdmin(account1);
      assert.equal(isAdmin, true);
    });
    it('allows an admin to remove another admin', async () => {
      await marketPlace.addAdmin(account1, { from: owner });
      let isAdmin = await marketPlace.isAdmin(account1);
      assert.equal(isAdmin, true);
      await marketPlace.removeAdmin(account1, { from: owner });
      isAdmin = await marketPlace.isAdmin(account1);
      assert.equal(isAdmin, false);
    });
    it('allows an admin to add a store owner', async () => {
      await marketPlace.addStoreOwner(account2, { from: owner });
      const isStoreOwner = await marketPlace.storeOwners(account2);
      assert.equal(isStoreOwner, true);
    });
    it('allows an admin to remove a store owner', async () => {
      await marketPlace.addStoreOwner(account2, { from: owner });
      let isStoreOwner = await marketPlace.storeOwners(account2);
      assert.equal(isStoreOwner, true);
      await marketPlace.removeStoreOwner(account2, { from: owner });
      isStoreOwner = await marketPlace.storeOwners(account2);
      assert.equal(isStoreOwner, false);
    });
  });

  describe('when store owner', () => {
    beforeEach(async () => {
      await marketPlace.addStoreOwner(storeOwner, { from: owner });
    });
    it('allows a store owner to create a store', async () => {
      const transaction = await marketPlace.createStore('My New Store', {
        from: storeOwner,
      });
      assertEventEqual(transaction, 'StoreCreated', {
        name: 'My New Store',
        owner: storeOwner,
      });
    });
    it('allows a store owner to remove their store', async () => {
      const storeId = await marketPlace.storefrontsByOwner(storeOwner, 0);
      let store = await marketPlace.storefrontsById(storeId);
      assert.notEqual(store.id, 0);
      await marketPlace.removeStore(storeId, {
        from: storeOwner,
      });
      store = await marketPlace.storefrontsById(storeId);
      assert.equal(store.id, 0);
    });
    it('allows a store owner to add an item to a store inventory', async () => {
      await marketPlace.createStore('My New Store', {
        from: storeOwner,
      });
      const storeId = await marketPlace.storefrontsByOwner(storeOwner, 0);
      // await marketPlace.addItemToInventory(
      //   storeId,
      //   'a brand new item',
      //   20,
      //   10,
      //   { from: storeOwner }
      // );
    });
    it('allows a store owner to remove an item to a store inventory', async () => {});
    it('allows a store owner to update the price of an item', async () => {});
    it('allows a store owner to update the quantity of an item', async () => {});
    it('allows a store owner to withdraw the balance of an item', async () => {});
  });

  describe('when buyer', () => {
    it('allows a buyer to purchase an item', async () => {});
  });
});
