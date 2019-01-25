import React from 'react';
import { Link } from 'react-router-dom';
import './navigation.css';

const Navigation = () => {
  return (
    <div className="navigation">
      <Link to={'/'}>Market Place</Link>
      <Link to={'/storeOwner'}>Store Owners</Link>
      <Link to={'/admin'}>Admin</Link>
    </div>
  );
};

export default Navigation;
