import React, { Component } from 'react';
import './marketPlace.css';

class MarketPlace extends Component {
  render() {
    const { accounts } = this.props;
    return <div className="marketPlace">Welcome {accounts[0]}</div>;
  }
}

export default MarketPlace;
