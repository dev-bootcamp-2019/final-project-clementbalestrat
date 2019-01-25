import React, { Component } from 'react';
import Navigation from '../../components/navigation';

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

  render() {
    const { accounts } = this.props;
    return (
      <div className="marketPlace">
        <Navigation />
        <h1>Market place page</h1>
      </div>
    );
  }
}

export default MarketPlace;
