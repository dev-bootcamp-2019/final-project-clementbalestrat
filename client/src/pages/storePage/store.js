import React, { Component } from 'react';
import { ethers } from 'ethers';
import Navigation from '../../components/navigation';
import './store.css';

const GAZ_LIMIT = 100000;
const GAZ_PRICE = 20000;

class StorePage extends Component {
  constructor() {
    super();
    this.state = {
      store: null,
      inventory: null,
      itemName: '',
      itemPrice: '',
      itemQuantity: '',
      addItemError: false,
      rowEdit: false,
      priceEdit: '',
      quantityEdit: '',
    };
    this.addItem = this.addItem.bind(this);
    this.refreshData = this.refreshData.bind(this);
    this.setEditRow = this.setEditRow.bind(this);
    this.renderItemRow = this.renderItemRow.bind(this);
    this.editItemQuantity = this.editItemQuantity.bind(this);
    this.editItemPrice = this.editItemPrice.bind(this);
    this.onQuantityEditChange = this.onQuantityEditChange.bind(this);
    this.onPriceEditChange = this.onPriceEditChange.bind(this);
    this.removeItem = this.removeItem.bind(this);
    this.purchaseItem = this.purchaseItem.bind(this);
  }

  async refreshData() {
    const { match, contract } = this.props;
    if (match.params && match.params.storeId) {
      const storeId = match.params.storeId;
      try {
        const [store, [ids, names, quantities, prices]] = await Promise.all([
          contract.storefrontsById(storeId),
          contract.getStorefrontInventory(storeId),
        ]);

        let mappedInventory = [];
        ids.forEach((id, i) => {
          mappedInventory.push({
            id,
            name: ethers.utils.parseBytes32String(names[i]),
            quantity: Number(ethers.utils.formatEther(quantities[i])),
            price: ethers.utils.formatEther(prices[i]),
          });
        });
        this.setState({
          store: {
            id: store.id,
            name: ethers.utils.parseBytes32String(store.name),
            owner: store.owner,
            balance: store.balance.toString(),
          },
          inventory: mappedInventory,
        });
      } catch (e) {
        console.log(e);
      }
    }
  }

  componentDidMount() {
    this.refreshData();
  }

  renderTitle() {
    const { store } = this.state;
    if (!store) return null;
    return <h1>Store: {store.name}</h1>;
  }

  onItemInputChange(type) {
    return e => {
      this.setState({ [type]: e.target.value });
    };
  }

  async addItem() {
    const { contract } = this.props;
    const { itemName, itemPrice, itemQuantity, store } = this.state;
    if (itemName === '' || itemPrice === '' || itemQuantity === '') {
      this.setState({ addItemError: true });
    }
    try {
      const itemNameBytes32 = ethers.utils.formatBytes32String(itemName);
      await contract.addItemToInventory(
        store.id,
        itemNameBytes32,
        ethers.utils.parseEther(itemPrice),
        ethers.utils.parseEther(itemQuantity)
      );
      this.setState({ addItemError: false });
      setTimeout(this.refreshData, 5000);
    } catch (e) {
      console.log(e);
      this.setState({ addItemError: true });
    }
  }

  setEditRow(row) {
    return () => {
      this.setState({ rowEdit: row });
    };
  }

  onQuantityEditChange(e) {
    this.setState({ quantityEdit: e.target.value });
  }

  onPriceEditChange(e) {
    this.setState({ priceEdit: e.target.value });
  }

  editItemQuantity(itemId) {
    return async () => {
      const { quantityEdit, store } = this.state;
      const { contract } = this.props;
      if (!quantityEdit || quantityEdit === '') return;
      try {
        await contract.updateItemQuantity(itemId, store.id, quantityEdit);
        setTimeout(() => {
          this.refreshData();
          this.setState({ quantityEdit: '', rowEdit: false });
        }, 5000);
      } catch (e) {
        console.log(e);
      }
    };
  }

  editItemPrice(itemId) {
    return async () => {
      const { priceEdit, store } = this.state;
      const { contract } = this.props;
      if (!priceEdit || priceEdit === '') return;
      try {
        await contract.updateItemPrice(itemId, store.id, priceEdit);
        setTimeout(() => {
          this.refreshData();
          this.setState({ priceEdit: '', rowEdit: false });
        }, 5000);
      } catch (e) {
        console.log(e);
      }
    };
  }

  removeItem(itemId) {
    return async e => {
      e.stopPropagation();
      const { contract } = this.props;
      const { store } = this.state;
      try {
        await contract.removeItemFromInventory(itemId, store.id);
        setTimeout(this.refreshData, 5000);
      } catch (e) {
        console.log(e);
      }
    };
  }

  purchaseItem(item) {
    return async e => {
      e.stopPropagation();
      const { contract } = this.props;
      const { store } = this.state;
      try {
        console.log(store.id, item.id);
        await contract.purchaseItem(store.id, item.id, 1, {
          value: ethers.utils.parseEther(item.price),
          gasLimit: GAZ_LIMIT,
          gasPrice: GAZ_PRICE,
        });
        setTimeout(this.refreshData, 5000);
      } catch (e) {
        console.log(e);
      }
    };
  }

  renderItemRow(item, i) {
    const { rowEdit } = this.state;
    if (rowEdit === i) {
      return (
        <tr onClick={this.setEditRow(i)} key={i}>
          <td>{item.name}</td>
          <td>
            <input
              type="number"
              placeholder={item.quantity}
              onChange={this.onQuantityEditChange}
            />
            <button onClick={this.editItemQuantity(item.id)}>Edit</button>
          </td>
          <td>
            <input
              type="text"
              placeholder={item.price}
              onChange={this.onPriceEditChange}
            />
            <button onClick={this.editItemPrice(item.id)}>Edit</button>
          </td>
          <td />
        </tr>
      );
    } else {
      return (
        <tr onClick={this.setEditRow(i)} key={i}>
          <td>{item.name}</td>
          <td>{item.quantity}</td>
          <td>{item.price}</td>
          <td>
            <button onClick={this.purchaseItem(item)}>Buy</button>
            <button onClick={this.removeItem(item.id)}>Remove</button>
          </td>
        </tr>
      );
    }
  }

  renderItems() {
    const { inventory } = this.state;
    if (!inventory || inventory.length === 0) {
      return <div style={{ margin: '20px 0' }}>No item for sale yet.</div>;
    }
    return (
      <div className="panelSection">
        <h4>Items for sale</h4>
        <table className="inventoryTable" cellSpacing="0">
          <thead>
            <tr>
              <th>Name</th>
              <th>Quantity</th>
              <th>Price (ETH)</th>
              <th />
            </tr>
          </thead>
          <tbody>{inventory.map(this.renderItemRow)}</tbody>
        </table>
      </div>
    );
  }

  renderAddItemSection() {
    const { addItemError } = this.state;
    return (
      <div className="panelSection">
        <h4>Add an item to the store inventory</h4>
        <div>
          <div className="itemInput">
            <label>Name</label>
            <input
              type="text"
              onChange={this.onItemInputChange('itemName')}
              placeholder="Please enter a product name"
            />
          </div>
          <div className="itemInput">
            <label>Price</label>
            <input
              type="text"
              onChange={this.onItemInputChange('itemPrice')}
              placeholder="Please enter a product price"
            />
          </div>
          <div className="itemInput">
            <label>Quantity</label>
            <input
              type="number"
              onChange={this.onItemInputChange('itemQuantity')}
              placeholder="Please enter a product quantity"
            />
          </div>
        </div>
        <button onClick={this.addItem}>Add item</button>
        {addItemError ? (
          <p>
            An error occured. Please make sure you are using the correct types
            when adding an item.
          </p>
        ) : null}
      </div>
    );
  }

  render() {
    return (
      <div className="marketPlace">
        <Navigation />
        {this.renderTitle()}
        {this.renderItems()}
        {this.renderAddItemSection()}
      </div>
    );
  }
}

export default StorePage;
