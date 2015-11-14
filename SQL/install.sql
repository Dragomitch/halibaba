
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
  chosen_estimate INTEGER,
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


-- Custom type
--DROP TYPE IF EXISTS marche_halibaba.estimate;
CREATE TYPE marche_halibaba.estimate
  AS (
    estimate_id INTEGER,
    description TEXT,
    price NUMERIC(12,2),
    options_nbr INTEGER,
    pub_date TIMESTAMP,
    house_id INTEGER
  );

-- Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.list_estimates_for(INTEGER)
  RETURNS SETOF marche_halibaba.estimate AS $$

DECLARE
  arg_estimate_request_id ALIAS FOR $1;
  cur_estimate marche_halibaba.estimate;
  out marche_halibaba.estimate;
BEGIN

  -- If an estimate has already been approved for this estimate request,
  -- that estimate is returned
  IF (
    SELECT chosen_estimate
    FROM marche_halibaba.estimate_requests
    WHERE estimate_request_id = arg_estimate_request_id
  ) IS NOT NULL THEN
    SELECT e.estimate_id, e.description, e.price,
        count(DISTINCT eo.option_id), e.submission_date, e.house_id
      INTO out
      FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
      LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
        eo.estimate_id = e.estimate_id
      WHERE er.chosen_estimate = e.estimate_id AND
        er.estimate_request_id = arg_estimate_request_id
      GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id;
    RETURN NEXT out;
    RETURN;
  END IF;

  -- If an hiding estimate has been submitted for this estimate request,
  -- that estimate is returned
  IF EXISTS (
    SELECT *
    FROM marche_halibaba.estimates e
    WHERE e.is_hiding = TRUE AND
      e.is_cancelled = FALSE AND
      e.estimate_request_id = arg_estimate_request_id
  ) THEN
    SELECT e.estimate_id, e.description, e.price,
      count(DISTINCT eo.option_id), e.submission_date, e.house_id
    INTO out
    FROM marche_halibaba.estimates e
      LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
        eo.estimate_id = e.estimate_id
    WHERE e.is_hiding = TRUE AND
      e.is_cancelled = FALSE AND
      e.estimate_request_id = arg_estimate_request_id
    GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id;
    RETURN NEXT out;
    RETURN;
  END IF;

  -- All estimates for this estimate request are returned
  FOR cur_estimate IN (
    SELECT e.estimate_id, e.description, e.price,
      count(DISTINCT eo.option_id), e.submission_date, e.house_id
    FROM marche_halibaba.estimates e
      LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
        eo.estimate_id = e.estimate_id
    WHERE e.is_cancelled = FALSE AND
      e.estimate_request_id = arg_estimate_request_id
    GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id
  ) LOOP
    SELECT cur_estimate.* INTO out;
    RETURN NEXT out;
  END LOOP;
  RETURN;

END;
$$ LANGUAGE 'plpgsql';


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
      WHERE option_id = option AND
        estimate_id = arg_estimate_id;
    END LOOP;

  END IF;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION marche_halibaba.signup_house(VARCHAR(35), VARCHAR(50), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_username ALIAS FOR $1;
  arg_pswd ALIAS FOR $2;
  arg_name ALIAS FOR $3;
  new_user_id INTEGER;
  new_house_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.users(username, pswd)
    VALUES (arg_username, MD5(arg_pswd)) RETURNING user_id INTO new_user_id;
  INSERT INTO marche_halibaba.houses(name, user_id)
    VALUES (arg_name, new_user_id) RETURNING house_id INTO new_house_id;
  RETURN new_house_id;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimate_requests_update()
  RETURNS TRIGGER AS $$

DECLARE
  approved_estimate_house_id INTEGER;
  approved_estimate_price NUMERIC(12,2);
  approved_estimates_nbr NUMERIC(16,2);
  estimates_nbr NUMERIC(16,2);
BEGIN
  SELECT e.house_id, e.price
  INTO approved_estimate_house_id, approved_estimate_price
  FROM marche_halibaba.estimates e
  WHERE e.estimate_id = NEW.chosen_estimate;

  SELECT count(estimate_id)
  INTO approved_estimates_nbr
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE e.estimate_id = er.chosen_estimate AND
    e.house_id = approved_estimate_house_id;

  SELECT count(estimate_id)
  INTO estimates_nbr
  FROM marche_halibaba.estimates e
  WHERE e.house_id = approved_estimate_house_id;

  -- Updates house statistics
  UPDATE marche_halibaba.houses
  SET turnover = turnover + approved_estimate_price,
    acceptance_rate = approved_estimates_nbr/estimates_nbr
  WHERE house_id = approved_estimate_house_id;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_estimate_requests_update
AFTER UPDATE on marche_halibaba.estimate_requests
FOR EACH ROW
WHEN (OLD.chosen_estimate IS NULL AND NEW.chosen_estimate IS NOT NULL)
EXECUTE PROCEDURE marche_halibaba.trigger_estimate_requests_update();


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


