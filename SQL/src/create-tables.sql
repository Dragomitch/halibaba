-- Removing all tables
DROP SCHEMA IF EXISTS marche_halibaba CASCADE;
DROP TYPE IF EXISTS estimate_status;
CREATE SCHEMA marche_halibaba;

-- Users
CREATE SEQUENCE marche_halibaba.users_pk;
CREATE TABLE marche_halibaba.users (
  user_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.users_pk'),
  username VARCHAR(50) NOT NULL CHECK (username <> '') UNIQUE,
  password VARCHAR(50) NOT NULL CHECK (password <> '')
);
CREATE INDEX password_idx ON marche_halibaba.users(password);

-- Clients
CREATE SEQUENCE marche_halibaba.clients_pk;
CREATE TABLE marche_halibaba.clients (
  client_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.clients_pk'),
  last_name VARCHAR(35) NOT NULL CHECK (last_name <> ''),
  first_name VARCHAR(35) NOT NULL CHECK (first_name <> ''),
  user_id INTEGER
    REFERENCES marche_halibaba.users(user_id)
);

-- Addresses
CREATE SEQUENCE marche_halibaba.addresses_pk;
CREATE TABLE marche_halibaba.addresses (
  address_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.addresses_pk'),
  street_name VARCHAR(50) NOT NULL CHECK (street_name <> ''),
  street_number VARCHAR(8) NOT NULL CHECK (street_number <> ''),
  city VARCHAR(35) NOT NULL CHECK (city <> ''),
  zip_code VARCHAR(8) NOT NULL CHECK (zip_code <> '')
);

-- Estimate requests
CREATE SEQUENCE marche_halibaba.estimate_requests_pk;
CREATE TABLE marche_halibaba.estimate_requests (
  estimate_request_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.estimate_requests_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  work_address INTEGER
    REFERENCES marche_halibaba.addresses(address_id),
  invoicing_address INTEGER NULL
    REFERENCES marche_halibaba.addresses(address_id),
  pub_date TIMESTAMP NOT NULL DEFAULT NOW(),
  deadline DATE NOT NULL CHECK (deadline > NOW()),
  client_id INTEGER
    REFERENCES marche_halibaba.clients(client_id)
);

-- Houses
CREATE SEQUENCE marche_halibaba.houses_pk;
CREATE TABLE marche_halibaba.houses (
  house_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.houses_pk'),
  name VARCHAR(35) NOT NULL CHECK (name <> ''),
  turnover NUMERIC(12,2) NOT NULL DEFAULT 0,
  acceptance_rate NUMERIC(3,2) NOT NULL DEFAULT 0,
  caught_cheating_nbr INTEGER NOT NULL DEFAULT 0,
  caught_cheater_nbr INTEGER NOT NULL DEFAULT 0,
  last_time_secret TIMESTAMP NULL,
  last_time_hiding TIMESTAMP NULL,
  last_time_reported TIMESTAMP NULL,
  submitted_estimates_nbr INTEGER NOT NULL DEFAULT 0,
  user_id INTEGER
    REFERENCES marche_halibaba.users(user_id)
);

-- Estimates
CREATE SEQUENCE marche_halibaba.estimates_pk;
CREATE TYPE estimate_status AS ENUM ('submitted', 'approved', 'cancelled', 'expired');
CREATE TABLE marche_halibaba.estimates (
  estimate_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.estimates_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  status estimate_status NOT NULL DEFAULT 'submitted',
  is_secret BOOLEAN NOT NULL DEFAULT FALSE,
  is_hiding BOOLEAN NOT NULL DEFAULT FALSE,
  pub_date TIMESTAMP NOT NULL DEFAULT NOW(),
  estimate_request_id INTEGER
    REFERENCES marche_halibaba.estimate_requests(estimate_request_id),
  house_id INTEGER
    REFERENCES marche_halibaba.houses(house_id)
);

-- Options
CREATE SEQUENCE marche_halibaba.options_pk;
CREATE TABLE marche_halibaba.options (
  option_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.options_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  house_id INTEGER
    REFERENCES marche_halibaba.houses(house_id)
);

-- Estimate options
CREATE SEQUENCE marche_halibaba.estimate_options_pk;
CREATE TABLE marche_halibaba.estimate_options (
  estimate_option_id INTEGER
    DEFAULT NEXTVAL('marche_halibaba.estimate_options_pk'),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  is_chosen BOOLEAN NOT NULL DEFAULT FALSE,
  estimate_id INTEGER
    REFERENCES marche_halibaba.estimates(estimate_id),
  option_id INTEGER
    REFERENCES marche_halibaba.options(option_id)
);
