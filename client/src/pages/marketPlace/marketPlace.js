import React, { Component } from 'react';
import { ethers } from 'ethers';
import { Link } from 'react-router-dom';
import Navigation from '../../components/navigation';

import './marketPlace.css';

class MarketPlace extends Component {
  constructor() {
    super();
    this.state = {
      stores: null,
    };
  }

  async componentDidMount() {
    const { contract, accounts } = this.props;
    try {
      const [ids, names, owners] = await contract.getStorefronts();
      let stores = [];
      ids.forEach((id, i) => {
        const name = ethers.utils.parseBytes32String(names[i]);
        stores.push({ id, name, owner: owners[i] });
      });
      this.setState({ stores });
    } catch (e) {
      console.log(e);
    }
  }
  renderContent() {
    const { stores } = this.state;
    if (!stores || stores.length === 0) {
      return <div styles={{ marginTop: '20px' }}>No stores created yet.</div>;
    }
    return (
      <table
        style={{ width: '80%', margin: '50px auto 0 auto' }}
        className="storeTable"
      >
        <thead>
          <tr>
            <th>Name</th>
            <th>Owner</th>
            <th />
          </tr>
        </thead>
        <tbody>
          {stores.map((store, i) => {
            return (
              <tr key={i}>
                <td>{store.name}</td>
                <td>{store.owner}</td>
                <td>
                  <Link to={`store/${store.id}`}>Visit</Link>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    );
  }

  render() {
    const { isAdmin, isStoreOwner, accounts } = this.props;
    return (
      <div className="marketPlace">
        <Navigation isAdmin={isAdmin} isStoreOwner={isStoreOwner} />
        <h1>Market place page</h1>
        <div>Your address: {accounts[0]}</div>
        {this.renderContent()}
      </div>
    );
  }
}

export default MarketPlace;
