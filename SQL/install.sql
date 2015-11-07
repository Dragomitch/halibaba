
-- Removes all previous data
DROP SCHEMA IF EXISTS marche_halibaba CASCADE;
DROP TYPE IF EXISTS estimate_status;

-- Schema
CREATE SCHEMA marche_halibaba;

-- Users
CREATE SEQUENCE marche_halibaba.users_pk;
CREATE TABLE marche_halibaba.users (
  user_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.users_pk'),
  username VARCHAR(35) NOT NULL CHECK (username <> '') UNIQUE,
  pswd VARCHAR(32) NOT NULL CHECK (pswd <> '')
);
CREATE INDEX password_idx ON marche_halibaba.users(pswd);

-- Clients
CREATE SEQUENCE marche_halibaba.clients_pk;
CREATE TABLE marche_halibaba.clients (
  client_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.clients_pk'),
  last_name VARCHAR(35) NOT NULL CHECK (last_name <> ''),
  first_name VARCHAR(35) NOT NULL CHECK (first_name <> ''),
  user_id INTEGER NOT NULL
    REFERENCES marche_halibaba.users(user_id)
);

-- Addresses
CREATE SEQUENCE marche_halibaba.addresses_pk;
CREATE TABLE marche_halibaba.addresses (
  address_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.addresses_pk'),
  street_name VARCHAR(50) NOT NULL CHECK (street_name <> ''),
  street_nbr VARCHAR(8) NOT NULL CHECK (street_nbr <> ''),
  zip_code VARCHAR(5) NOT NULL CHECK (zip_code ~ '^[0-9]+$'),
  city VARCHAR(35) NOT NULL CHECK (city <> '')
);

-- Estimate requests
CREATE SEQUENCE marche_halibaba.estimate_requests_pk;
CREATE TABLE marche_halibaba.estimate_requests (
  estimate_request_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.estimate_requests_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  construction_address INTEGER NOT NULL
    REFERENCES marche_halibaba.addresses(address_id),
  invoicing_address INTEGER
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
  user_id INTEGER NOT NULL
    REFERENCES marche_halibaba.users(user_id)
);

-- Estimates
CREATE SEQUENCE marche_halibaba.estimates_pk;
CREATE TYPE estimate_status AS ENUM ('submitted', 'approved', 'unapproved', 'cancelled', 'expired');
CREATE TABLE marche_halibaba.estimates (
  estimate_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.estimates_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  status estimate_status NOT NULL DEFAULT 'submitted',
  is_secret BOOLEAN NOT NULL DEFAULT FALSE,
  is_hiding BOOLEAN NOT NULL DEFAULT FALSE,
  pub_date TIMESTAMP NOT NULL DEFAULT NOW(),
  estimate_request_id INTEGER NOT NULL
    REFERENCES marche_halibaba.estimate_requests(estimate_request_id),
  house_id INTEGER NOT NULL
    REFERENCES marche_halibaba.houses(house_id)
);

-- Options
CREATE SEQUENCE marche_halibaba.options_pk;
CREATE TABLE marche_halibaba.options (
  option_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.options_pk'),
  description TEXT NOT NULL CHECK (description <> ''),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  house_id INTEGER NOT NULL
    REFERENCES marche_halibaba.houses(house_id)
);

-- Estimate options
CREATE SEQUENCE marche_halibaba.estimate_options_pk;
CREATE TABLE marche_halibaba.estimate_options (
  estimate_option_id INTEGER PRIMARY KEY
    DEFAULT NEXTVAL('marche_halibaba.estimate_options_pk'),
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  is_chosen BOOLEAN NOT NULL DEFAULT FALSE,
  estimate_id INTEGER NOT NULL
    REFERENCES marche_halibaba.estimates(estimate_id),
  option_id INTEGER NOT NULL
    REFERENCES marche_halibaba.options(option_id)
);


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


CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate_request(TEXT, DATE, INTEGER, VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35), VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_description ALIAS FOR $1;
  arg_deadline ALIAS FOR $2;
  arg_client ALIAS FOR $3;
  arg_cons_street_name ALIAS FOR $4;
  arg_cons_street_nbr ALIAS FOR $5;
  arg_cons_zip_code ALIAS FOR $6;
  arg_cons_city ALIAS FOR $7;
  arg_inv_street_name ALIAS FOR $8;
  arg_inv_street_nbr ALIAS FOR $9;
  arg_inv_zip_code ALIAS FOR $10;
  arg_inv_city ALIAS FOR $11;
  new_construction_address_id INTEGER;
  new_invoicing_address_id INTEGER;
  new_estimate_request_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.addresses(street_name, street_nbr, zip_code, city)
    VALUES (arg_cons_street_name, arg_cons_street_nbr, arg_cons_zip_code, arg_cons_city)
    RETURNING address_id INTO new_construction_address_id;

  new_invoicing_address_id := NULL;

  IF arg_inv_street_name IS NOT NULL AND
    arg_inv_street_nbr IS NOT NULL AND
    arg_inv_zip_code IS NOT NULL AND
    arg_inv_city IS NOT NULL THEN

    INSERT INTO marche_halibaba.addresses(street_name, street_nbr, zip_code, city)
      VALUES (arg_inv_street_name, arg_inv_street_nbr, arg_inv_zip_code, arg_inv_city)
      RETURNING address_id INTO new_invoicing_address_id;

  END IF;

  INSERT INTO marche_halibaba.estimate_requests(description, construction_address, invoicing_address, deadline, client_id)
    VALUES (arg_description, new_construction_address_id, new_invoicing_address_id, arg_deadline, arg_client)
    RETURNING estimate_request_id INTO new_estimate_request_id;

  RETURN new_estimate_request_id;
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
  -- An exception is raised if a estimate has already been approved for this estimate request
  IF EXISTS(
    SELECT *
      FROM marche_halibaba.estimates e
      WHERE e.estimate_request_id = (
        SELECT e2.estimate_request_id
          FROM marche_halibaba.estimates e2
          WHERE e2.estimate_id = arg_estimate_id
      ) AND e.status = 'approved'
  )THEN
    RAISE EXCEPTION 'Un devis a déjà été approuvé pour cette demande.';
  END IF;

  SELECT e.estimate_request_id as estimate_request_id,
      e.status as status, (er.pub_date + INTERVAL '15 days') as expiration_date
    INTO estimate_details
    FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
    WHERE er.estimate_request_id = e.estimate_request_id AND
      e.estimate_id = arg_estimate_id;

  -- An exception is raised because the estimate has been cancelled
  IF estimate_details.status <> 'submitted' THEN
    RAISE EXCEPTION 'Ce devis n est pas valide.';
  -- An exception is raised because the estimate request has expired
  ELSIF estimate_details.expiration_date < NOW() THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  -- The estimate and the chosen options are succesfully approved
  ELSE
    UPDATE marche_halibaba.estimates
      SET status = 'approved'
      WHERE estimate_id = arg_estimate_id;

    UPDATE marche_halibaba.estimates
      SET status = 'unapproved'
      WHERE estimate_id IN (
        SELECT e.estimate_id
          FROM marche_halibaba.estimates e
          WHERE e.estimate_request_id = estimate_details.estimate_request_id AND
            e.status = 'submitted'
      );

      UPDATE marche_halibaba.estimate_options
        SET is_chosen = TRUE
        WHERE option_id IN ARRAY arg_chosen_options;



  END IF;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;

SELECT marche_halibaba.approve_estimate(1, '{1,2}');


CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimate_options_update()
  RETURNS TRIGGER AS $$

DECLARE
  house_to_update INTEGER;
  old_turnover NUMERIC(12,2);

BEGIN
  SELECT h.house_id, h.turnover
    INTO house_to_update, old_turnover
    FROM marche_halibaba.estimate_options eo, marche_halibaba.options o, marche_halibaba.houses h
    WHERE eo.option_id = o.option_id AND
      o.house_id = h.house_id AND
      eo.estimate_option_id = OLD.estimate_option_id;

  IF OLD.is_chosen = FALSE AND NEW.is_chosen = TRUE THEN
    UPDATE marche_halibaba.houses
      SET turnover = old_turnover + OLD.price
      WHERE house_id = house_to_update;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimate_options_update
  AFTER UPDATE on marche_halibaba.estimate_options
  FOR EACH ROW
  WHEN (OLD.is_chosen IS DISTINCT FROM NEW.is_chosen)
  EXECUTE PROCEDURE marche_halibaba.trigger_estimate_options_update();


-- Inserts clients
SELECT marche_halibaba.signup_client('jeremy', 'blublu', 'Jeremy', 'Wagemans');
SELECT marche_halibaba.signup_client('philippe', 'blublu', 'Philippe', 'Dragomir');

-- Inserts estimate requests
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

UPDATE marche_halibaba.estimate_requests
  SET pub_date = '2014-12-23'
  WHERE estimate_request_id = 2;

-- Inserts houses (temporary)
INSERT INTO marche_halibaba.houses(name, user_id)
  VALUES ('Blaaaaa', 2);

-- Inserts estimates (temporary)
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 1', 1600, 1, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 2', 1600, 1, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 3', 1600, 1, 1);

INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 1', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 2', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 3', 1600, 2, 1);

-- Inserts options (temporary)
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en or', 6000, 1);
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en argent', 4000, 1);
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en bronze', 2000, 1);

-- Inserts estimate options (temporary)
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (6000, 1, 1);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (4000, 1, 2);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (2000, 1, 3);


