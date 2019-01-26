import React, { Component } from 'react';
import MarketPlaceContract from './contracts/MarketPlace.json';
import { Switch, Route, HashRouter, Redirect } from 'react-router-dom';
import { ethers, Contract } from 'ethers';
import MarketPlace from './pages/marketPlace';
import AdminPage from './pages/adminPage';
import StoreOwnerPage from './pages/storeOwnerPage';
import StorePage from './pages/storePage';
import './App.css';

const SMART_CONTRACT_ADDR = '0xb3989F080F91a181D04Ebd89A02dd9D340738E3d';

class App extends Component {
  state = { accounts: null, contract: null };

  componentDidMount = async () => {
    if (!window.web3 || !window.web3.currentProvider) return;
    const web3Provider = new ethers.providers.Web3Provider(
      window.web3.currentProvider
    );
    const signer = web3Provider.getSigner();

    try {
      const contract = await new Contract(
        SMART_CONTRACT_ADDR,
        MarketPlaceContract.abi,
        signer
      );
      const accounts = await web3Provider.listAccounts();
      const [isAdmin, isStoreOwner] = await Promise.all([
        contract.administratorsByAddress(accounts[0]),
        contract.storeOwnersByAddress(accounts[0]),
      ]);
      this.setState({
        contract,
        accounts,
        isAdmin,
        isStoreOwner,
      });
    } catch (err) {
      console.log(err);
    }
  };

  render() {
    const { accounts, contract, isAdmin, isStoreOwner } = this.state;
    if (!accounts || !contract) {
      return (
        <div style={{ textAlign: 'center' }}>
          Loading Web3, accounts, and contract...
        </div>
      );
    }
    return (
      <div className="App">
        <h1>Decentralized MarketPlace</h1>
        <HashRouter>
          <Switch>
            <Route
              exact
              path="/"
              render={props => <MarketPlace {...props} {...this.state} />}
            />
            <Route
              path="/admin"
              render={props =>
                isAdmin ? (
                  <AdminPage {...props} {...this.state} />
                ) : (
                  <Redirect to={{ pathname: '/' }} />
                )
              }
            />
            <Route
              path="/storeOwner"
              render={props =>
                isStoreOwner ? (
                  <StoreOwnerPage {...props} {...this.state} />
                ) : (
                  <Redirect to={{ pathname: '/' }} />
                )
              }
            />
            <Route
              path="/store/:storeId"
              render={props => <StorePage {...props} {...this.state} />}
            />
            <Route
              render={props => <MarketPlace {...props} {...this.state} />}
            />
          </Switch>
        </HashRouter>
      </div>
    );
  }
}

export default App;
