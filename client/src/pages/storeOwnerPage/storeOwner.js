import React, { Component } from 'react';
import Navigation from '../../components/navigation';

class StoreOwnerPage extends Component {
  constructor() {
    super();
    this.state = {
      stores: null,
    };
  }

  async refreshData() {
    const { contract, accounts } = this.props;
    const stores = await contract.getOwnerStorefronts(accounts[0]);
    console.log(stores);
    this.setState({ stores });
  }
  componentDidMount() {
    this.refreshData();
  }

  renderStoreListSection() {}

  renderStoreListSection() {}

  render() {
    const { accounts } = this.props;
    return (
      <div className="marketPlace">
        <Navigation />
        <h1>Store Owner page</h1>
        <div>Your address: {accounts[0]}</div>
        <div>{this.renderStoreListSection()}</div>
        <div>{this.renderStoreListSection()}</div>
      </div>
    );
  }
}

export default StoreOwnerPage;
