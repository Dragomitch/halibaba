
START TRANSACTION;

-- Removes all previous data
DROP SCHEMA IF EXISTS marche_halibaba CASCADE;

-- Schema
CREATE SCHEMA marche_halibaba;

-- Users
CREATE TABLE marche_halibaba.users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(35) NOT NULL CHECK (username <> '') UNIQUE,
  pswd VARCHAR(32) NOT NULL CHECK (pswd <> '')
);

-- Clients
CREATE TABLE marche_halibaba.clients (
  client_id SERIAL PRIMARY KEY,
  last_name VARCHAR(35) NOT NULL CHECK (last_name <> ''),
  first_name VARCHAR(35) NOT NULL CHECK (first_name <> ''),
  user_id INTEGER NOT NULL
    REFERENCES marche_halibaba.users(user_id)
);

-- Addresses
CREATE TABLE marche_halibaba.addresses (
  address_id SERIAL PRIMARY KEY,
  street_name VARCHAR(50) NOT NULL CHECK (street_name <> ''),
  street_nbr VARCHAR(8) NOT NULL CHECK (street_nbr <> ''),
  zip_code VARCHAR(5) NOT NULL CHECK (zip_code ~ '^[0-9]+$'),
  city VARCHAR(35) NOT NULL CHECK (city <> '')
);

-- Estimate requests
CREATE TABLE marche_halibaba.estimate_requests (
  estimate_request_id SERIAL PRIMARY KEY,
  description TEXT NOT NULL CHECK (description <> ''),
  construction_address INTEGER NOT NULL
    REFERENCES marche_halibaba.addresses(address_id),
  invoicing_address INTEGER
    REFERENCES marche_halibaba.addresses(address_id),
  pub_date TIMESTAMP NOT NULL DEFAULT NOW(),
  deadline DATE NOT NULL CHECK (deadline > NOW()),
  chosen_estimate INTEGER NOT NULL,
  client_id INTEGER NOT NULL
    REFERENCES marche_halibaba.clients(client_id)
);

-- Houses
CREATE TABLE marche_halibaba.houses (
  house_id SERIAL PRIMARY KEY,
  name VARCHAR(35) NOT NULL CHECK (name <> ''),
  turnover NUMERIC(12,2) NOT NULL DEFAULT 0,
  acceptance_rate NUMERIC(3,2) NOT NULL DEFAULT 0,
  caught_cheating_nbr INTEGER NOT NULL DEFAULT 0,
  caught_cheater_nbr INTEGER NOT NULL DEFAULT 0,
  secret_limit_expiration TIMESTAMP NULL,
  hiding_limit_expiration TIMESTAMP NULL,
  penalty_expiration TIMESTAMP NULL,
  submitted_estimates_nbr INTEGER NOT NULL DEFAULT 0,
  user_id INTEGER NOT NULL
    REFERENCES marche_halibaba.users(user_id)
);

-- Estimates
CREATE TABLE marche_halibaba.estimates (
  estimate_id SERIAL PRIMARY KEY,
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  is_cancelled BOOLEAN NOT NULL DEFAULT FALSE,
  is_secret BOOLEAN NOT NULL DEFAULT FALSE,
  is_hiding BOOLEAN NOT NULL DEFAULT FALSE,
  submission_date TIMESTAMP NOT NULL DEFAULT NOW(),
  estimate_request_id INTEGER NOT NULL
    REFERENCES marche_halibaba.estimate_requests(estimate_request_id),
  house_id INTEGER NOT NULL
    REFERENCES marche_halibaba.houses(house_id)
);

ALTER TABLE marche_halibaba.estimate_requests
ADD CONSTRAINT chosen_estimate_fk FOREIGN KEY (chosen_estimate)
REFERENCES marche_halibaba.estimates(estimate_id)
ON DELETE CASCADE;

-- Options
CREATE TABLE marche_halibaba.options (
  option_id SERIAL PRIMARY KEY,
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  house_id INTEGER NOT NULL
    REFERENCES marche_halibaba.houses(house_id)
);

-- Estimate options
CREATE TABLE marche_halibaba.estimate_options (
  estimate_option_id SERIAL PRIMARY KEY,
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  is_chosen BOOLEAN NOT NULL DEFAULT FALSE,
  estimate_id INTEGER NOT NULL
    REFERENCES marche_halibaba.estimates(estimate_id),
  option_id INTEGER NOT NULL
    REFERENCES marche_halibaba.options(option_id)
);

COMMIT;


CREATE OR REPLACE FUNCTION marche_halibaba.signup_client(VARCHAR(35), VARCHAR(50), VARCHAR(35), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_username ALIAS FOR $1;
  arg_pswd ALIAS FOR $2;
  arg_last_name ALIAS FOR $3;
  arg_first_name ALIAS FOR $4;
  new_user_id INTEGER;
  new_client_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.users(username, pswd) VALUES (arg_username, MD5(arg_pswd)) RETURNING user_id INTO new_user_id;
  INSERT INTO marche_halibaba.clients(last_name, first_name, user_id) VALUES (arg_last_name, arg_first_name, new_user_id) RETURNING client_id INTO new_client_id;
  RETURN new_client_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  estimate_details RECORD;
  option INTEGER;
BEGIN

  SELECT e.estimate_request_id as estimate_request_id,
    e.is_cancelled as is_cancelled, (er.pub_date + INTERVAL '15 days') as expiration_date,
    er.chosen_estimate as chosen_estimate
  INTO estimate_details
  FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
  WHERE er.estimate_request_id = e.estimate_request_id AND
    e.estimate_id = arg_estimate_id;

  -- An exception is raised if a estimate has already been approved for this estimate request
  IF estimate_details.chosen_estimate IS NOT NULL THEN
    RAISE EXCEPTION 'Un devis a déjà été approuvé pour cette demande.';
  END IF;

  -- An exception is raised because the estimate has been cancelled
  IF estimate_details.is_cancelled THEN
    RAISE EXCEPTION 'Ce devis n est pas valide.';
  -- An exception is raised because the estimate request has expired
  ELSIF estimate_details.expiration_date < NOW() THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  -- The estimate and the chosen options are succesfully approved
  ELSE
    UPDATE marche_halibaba.estimate_requests
    SET chosen_estimate = arg_estimate_id
    WHERE estimate_request_id = estimate_details.estimate_request_id;

    FOREACH option IN ARRAY arg_chosen_options
    LOOP
      UPDATE marche_halibaba.estimate_options
      SET is_chosen = TRUE
      WHERE option_id = option;
    END LOOP;

  END IF;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;


