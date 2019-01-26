import React from 'react';
import { Link } from 'react-router-dom';
import './navigation.css';

const Navigation = ({ isAdmin, isStoreOwner }) => {
  return (
    <div className="navigation">
      <Link to={'/'}>Market Place</Link>
      {isStoreOwner ? <Link to={'/storeOwner'}>Store Owners</Link> : null}
      {isAdmin ? <Link to={'/admin'}>Admin</Link> : null}
    </div>
  );
};

export default Navigation;
