import React, { Component } from 'react';
import Stores from '../components/stores';
import AdminPanel from '../components/adminPanel';
import StoreOwnerPanel from '../components/storeOwnerPanel';

import './marketPlace.css';

class MarketPlace extends Component {
  constructor() {
    super();
    this.state = {
      activeView: 'index',
      isStoreOwner: false,
      isAdmin: false,
    };
    this.setCurrentView = this.setCurrentView.bind(this);
  }

  async componentDidMount() {
    const { contract, accounts } = this.props;
    const [isAdmin, isStoreOwner] = await Promise.all([
      contract.administrators(accounts[0]),
      contract.storeOwners(accounts[0]),
    ]);

    this.state({ isStoreOwner, isAdmin });
  }

  setCurrentView(view) {
    return () => {
      this.setState({ activeView: view });
    };
  }

  renderPageContent() {
    const { activeView } = this.state;
    switch (activeView) {
      case 'index':
        return <Stores />;
      case 'storeOwner':
        return <StoreOwnerPanel />;
      case 'admin':
        return <AdminPanel />;
      default:
        return <Stores />;
    }
  }

  render() {
    const { accounts } = this.props;
    return (
      <div className="marketPlace">
        <h1>Decentralized Market Place</h1>
        <div>
          <button onClick={this.setCurrentView('index')}>Index</button>
          <button onClick={this.setCurrentView('storeOwner')}>
            Store Owner
          </button>
          <button onClick={this.setCurrentView('admin')}>Admin</button>
        </div>
        {this.renderPageContent()}
      </div>
    );
  }
}

export default MarketPlace;
