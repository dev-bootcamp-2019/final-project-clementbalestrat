import React, { Component } from 'react';
import Navigation from '../../components/navigation';

class StorePage extends Component {
  constructor() {
    super();
    this.state = {
      storeId: null,
    };
  }

  componentDidMount() {
    const { match } = this.props;
    if (match.params && match.params.storeId) {
      this.setState({ storeId: match.params.storeId });
    }
  }

  render() {
    const { storeId } = this.state;
    return (
      <div className="marketPlace">
        <Navigation />
        <h1>Store {storeId} page</h1>
      </div>
    );
  }
}

export default StorePage;
