import React, { Component } from 'react';
import MarketPlaceContract from './contracts/MarketPlace.json';
import getWeb3 from './utils/getWeb3';
import { ethers, Contract } from 'ethers';
import MarketPlace from './pages/marketPlace';

const SMART_CONTRACT_ADDR = '0x8d0e7A6539c97Cc413b0108cF60252A25F6cCa94';

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
    if (!this.state.accounts) {
      return (
        <div style={{ textAlign: 'center' }}>
          Loading Web3, accounts, and contract...
        </div>
      );
    }
    return <MarketPlace contract={contract} accounts={accounts} />;
  }
}

export default App;
