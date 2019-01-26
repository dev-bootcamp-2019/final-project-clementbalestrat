import React, { Component } from 'react';
import MarketPlaceContract from './contracts/MarketPlace.json';
import { Switch, Route, HashRouter } from 'react-router-dom';
import { ethers, Contract } from 'ethers';
import MarketPlace from './pages/marketPlace';
import AdminPage from './pages/adminPage';
import StoreOwnerPage from './pages/storeOwnerPage';
import StorePage from './pages/storePage';
import './App.css';

const SMART_CONTRACT_ADDR = '0x63Ea05F04666f8d62a27870322fd72e62fB8B890';

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
      this.setState({
        contract,
        accounts,
      });
    } catch (err) {
      console.log(err);
    }
  };

  render() {
    const { contract, accounts } = this.state;
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
              render={props => (
                <MarketPlace
                  {...props}
                  contract={contract}
                  accounts={accounts}
                />
              )}
            />
            <Route
              path="/admin"
              render={props => (
                <AdminPage {...props} contract={contract} accounts={accounts} />
              )}
            />
            <Route
              path="/storeOwner"
              render={props => (
                <StoreOwnerPage
                  {...props}
                  contract={contract}
                  accounts={accounts}
                />
              )}
            />
            <Route
              path="/store/:storeId"
              render={props => (
                <StorePage {...props} contract={contract} accounts={accounts} />
              )}
            />
            <Route
              render={props => (
                <MarketPlace
                  {...props}
                  contract={contract}
                  accounts={accounts}
                />
              )}
            />
          </Switch>
        </HashRouter>
      </div>
    );
  }
}

export default App;
