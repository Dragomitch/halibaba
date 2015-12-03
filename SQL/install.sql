
-- Removes all previous data
DROP SCHEMA IF EXISTS marche_halibaba CASCADE;
DROP SCHEMA IF EXISTS unit_tests CASCADE;

-- Schema
CREATE SCHEMA marche_halibaba;

-- Users
CREATE TABLE marche_halibaba.users (
  user_id SERIAL PRIMARY KEY,
  username VARCHAR(35) NOT NULL CHECK (username <> '') UNIQUE,
  pswd VARCHAR(255) NOT NULL CHECK (pswd <> '')
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
  price NUMERIC(12,2) NOT NULL CHECK (price > 0),
  is_chosen BOOLEAN NOT NULL DEFAULT FALSE,
  estimate_id INTEGER NOT NULL
    REFERENCES marche_halibaba.estimates(estimate_id),
  option_id INTEGER NOT NULL
    REFERENCES marche_halibaba.options(option_id),
  PRIMARY KEY(estimate_id, option_id)
);


DROP VIEW IF EXISTS marche_halibaba.signin_client;
CREATE VIEW marche_halibaba.signin_client AS
  SELECT c.client_id as "c_id", c.first_name as "c_first_name", c.last_name as "c_last_name",
    u.username as "c_username", u.pswd as "c_pswd"
  FROM marche_halibaba.users u, marche_halibaba.clients c
  WHERE u.user_id = c.user_id;


CREATE OR REPLACE FUNCTION marche_halibaba.signup_client(VARCHAR(35), VARCHAR(50), VARCHAR(35), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_username ALIAS FOR $1;
  arg_pswd ALIAS FOR $2;
  arg_first_name ALIAS FOR $3;
  arg_last_name ALIAS FOR $4;
  new_user_id INTEGER;
  new_client_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.users(username, pswd)
    VALUES (arg_username, arg_pswd)
    RETURNING user_id INTO new_user_id;

  INSERT INTO marche_halibaba.clients(first_name, last_name, user_id)
    VALUES (arg_first_name, arg_last_name, new_user_id)
    RETURNING client_id INTO new_client_id;
  RETURN new_client_id;
END;
$$ LANGUAGE 'plpgsql';


DROP VIEW IF EXISTS marche_halibaba.estimate_details;
CREATE VIEW marche_halibaba.estimate_details AS
  SELECT e.estimate_id as "e_id", e.description as "e_description",
    e.price as "e_price", e.is_cancelled as "e_is_cancelled",
    e.submission_date as "e_submission_date",
    h.house_id as "e_house_id", h.name as "e_house_name",
    o.option_id as "e_option_id", o.description as "e_option_description",
    eo.price as "e_option_price"
  FROM marche_halibaba.estimates e
    LEFT OUTER JOIN marche_halibaba.estimate_options eo
      ON e.estimate_id = eo.estimate_id
    LEFT OUTER JOIN marche_halibaba.options o
      ON eo.option_id = o.option_id,
    marche_halibaba.houses h
  WHERE e.house_id = h.house_id;


DROP VIEW IF EXISTS marche_halibaba.clients_list_estimates;

CREATE VIEW marche_halibaba.clients_list_estimates AS
  SELECT view.estimate_id as "e_id", view.description as "e_description",
    view.price as "e_price",
    view.submission_date as "e_submission_date",
    view.estimate_request_id as "e_estimate_request_id",
    view.house_id as "e_house_id",
    view.name as "e_house_name"
  FROM (
    (
    SELECT e.estimate_id, e.description, e.price,
      e.submission_date, e.estimate_request_id, e.house_id, h.name
    FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er,
      marche_halibaba.houses h
    WHERE e.estimate_request_id = er.estimate_request_id AND
      e.house_id = h.house_id AND
      er.chosen_estimate IS NULL AND
      e.is_cancelled = FALSE AND
      NOT EXISTS(
        SELECT *
        FROM marche_halibaba.estimates e2
        WHERE e2.estimate_request_id = e.estimate_request_id AND
          e2.is_hiding = TRUE
      )
    )
    UNION
    (
      SELECT e.estimate_id, e.description, e.price,
        e.submission_date, e.estimate_request_id, e.house_id, h.name
      FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er,
        marche_halibaba.houses h
      WHERE e.estimate_request_id = er.estimate_request_id AND
        e.house_id = h.house_id AND
        er.chosen_estimate IS NULL AND
        e.is_cancelled = FALSE AND
        e.is_hiding = TRUE
    )
    UNION
    (
      SELECT e.estimate_id, e.description, e.price,
        e.submission_date, e.estimate_request_id, e.house_id, h.name
      FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er,
        marche_halibaba.houses h
      WHERE e.estimate_id = er.chosen_estimate AND
        e.house_id = h.house_id
    )) view;

/** DEPRECATED LOOSER MODE
-- Custom type
--DROP TYPE IF EXISTS marche_halibaba.estimate;
CREATE TYPE marche_halibaba.estimate
  AS (
    estimate_id INTEGER,
    description TEXT,
    price NUMERIC(12,2),
    options_nbr INTEGER,
    submission_date TIMESTAMP,
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
    ORDER BY e.submission_date DESC
  ) LOOP
    SELECT cur_estimate.* INTO out;
    RETURN NEXT out;
  END LOOP;
  RETURN;

END;
$$ LANGUAGE 'plpgsql'; **/


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
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  option INTEGER;
BEGIN
  UPDATE marche_halibaba.estimate_requests
  SET chosen_estimate = arg_estimate_id
  WHERE estimate_request_id = estimate_details.estimate_request_id;

  IF arg_chosen_options IS NULL THEN
    RETURN 0;
  END IF;

  FOREACH option IN ARRAY arg_chosen_options
  LOOP
    UPDATE marche_halibaba.estimate_options
    SET is_chosen = TRUE
    WHERE option_id = option AND
      estimate_id = arg_estimate_id;
  END LOOP;

  RETURN 0;
END;
$$ LANGUAGE 'plpgsql';


CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimates_update()
  RETURNS TRIGGER AS $$

DECLARE
    estimate_details RECORD;
BEGIN

  SELECT e.estimate_request_id as estimate_request_id,
    e.is_cancelled as is_cancelled, (er.pub_date + INTERVAL '15' day) as expiration_date,
    er.chosen_estimate as chosen_estimate
  INTO estimate_details
  FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
  WHERE er.estimate_request_id = e.estimate_request_id AND
    e.estimate_id = OLD.estimate_id;

  -- An exception is raised if the estimate doesn't exist


  -- An exception is raised if a estimate has already been approved for this estimate request
  IF estimate_details.chosen_estimate IS NOT NULL THEN
    RAISE EXCEPTION 'Un devis a déjà été approuvé pour cette demande.';
  END IF;

  -- An exception is raised because the estimate has been cancelled
  IF estimate_details.is_cancelled THEN
    RAISE EXCEPTION 'Ce devis n est pas valide.';
  END IF;

  -- An exception is raised because the estimate request has expired
  IF estimate_details.expiration_date < NOW() THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimates_update
BEFORE UPDATE ON marche_halibaba.estimates
FOR EACH ROW
EXECUTE PROCEDURE marche_halibaba.trigger_estimates_update();


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
    VALUES (arg_username, arg_pswd) RETURNING user_id INTO new_user_id;

  INSERT INTO marche_halibaba.houses(name, user_id)
    VALUES (arg_name, new_user_id) RETURNING house_id INTO new_house_id;
  RETURN new_house_id;
END;
$$ LANGUAGE 'plpgsql';


--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.add_option(TEXT, NUMERIC(12,2), INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_house_id ALIAS FOR $3;
  new_option_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.options(description, price, house_id) VALUES (arg_description, arg_price, arg_house_id) RETURNING option_id INTO new_option_id;
  RETURN new_option_id;
END;
$$ LANGUAGE 'plpgsql';

--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.waiting_for_approval_estimates_nbr(INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_house_id ALIAS FOR $1;
  number_estimates INTEGER;
BEGIN
  SELECT count(estimate_id)
  INTO number_estimates
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE e.estimate_request_id = er.estimate_request_id AND
    e.is_cancelled = FALSE AND
    er.pub_date + INTERVAL '15' day >= NOW() AND
    er.chosen_estimate IS NULL AND
    e.house_id = arg_house_id;
  RETURN number_estimates;
END;
$$ LANGUAGE 'plpgsql';


--Rajouter le temps dans la durée de la punition en print out?

--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  new_estimate_request_id INTEGER;
BEGIN
  IF arg_is_secret = TRUE
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF arg_is_hiding = TRUE
    --THEN SELECT marche_halibaba.submit_hiding_estimate(arg_description, arg_price, arg_is_secret, arg_is_hiding, arg_estimate_request_id, arg_house_id);
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF EXISTS(
    SELECT *
    FROM marche_halibaba.houses h
    WHERE h.house_id= arg_house_id
      AND h.penalty_expiration > NOW()
    )THEN
      RAISE EXCEPTION 'Vous êtes interdit de devis pour le moment.';
  END IF;

    IF EXISTS( --If the estimate_request is expired, we raise a exception;
    SELECT *
    FROM marche_halibaba.estimate_requests er
    WHERE er.estimate_request_id= arg_estimate_request_id
      AND er.deadline< NOW()
    )THEN
      RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

  INSERT INTO marche_halibaba.estimates(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
    VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_request_id;
  RETURN new_estimate_request_id;

END;
$$ LANGUAGE 'plpgsql';


--Rajouter le temps dans la durée de la punition en print out?
--Problème si on veut ajouter en secret+hiding

--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.submit_hiding_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  new_estimate_request_id INTEGER;
  caught_cheating_house_id INTEGER;
BEGIN
  IF arg_is_secret = TRUE
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF arg_is_hiding= FALSE
    THEN RAISE EXCEPTION data_exception;
  END IF;
  /*IF (arg_is_secret = TRUE --Si le devis est secret + hiding: on vérifie qu'il peut être secret
    AND ( SELECT *
          FROM marche_halibaba.houses h
          WHERE h.house_id= arg_house_id
            AND h.secret_limit_expiration) > NOW())
    THEN RAISE EXCEPTION data_exception;
  END IF;*/

  IF ( SELECT * --Si le devis est hiding: on vérifie qu'il peut l'être
          FROM marche_halibaba.houses h
          WHERE h.house_id= arg_house_id
            AND h.hiding_limit_expiration > NOW())
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF EXISTS(
    SELECT *
    FROM marche_halibaba.houses h
    WHERE h.house_id= arg_house_id
      AND h.penalty_expiration > NOW()
    )THEN
      RAISE EXCEPTION 'Vous êtes interdit de devis pour le moment.';
  END IF;

  IF EXISTS( --If the estimate_request is expired, we raise a exception;
    SELECT *
    FROM marche_halibaba.estimate_request er
    WHERE er.estimate_request_id= arg_estimate_request_id
      AND er.deadline< NOW()
    )THEN
      RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

  IF EXISTS(-- S'il y a déjà un devis masquant pour cette estimate_request
    SELECT h.house_id
      INTO caught_cheating_house_id
    FROM marche_halibaba.estimates e, marche_halibaba.houses h
    WHERE e.estimate_request_id= arg_estimate_request_id
      AND e.is_hiding= TRUE
  )
  THEN
    UPDATE marche_halibaba.houses
    SET penalty_expiration = NOW() + '1 days',
      caught_cheating_nbr = caught_cheating_nbr+1,
      caught_cheater_nbr = caught_cheater_nbr+1
    WHERE  house_id = caught_cheating_house_id;

    UPDATE marche_halibaba.estimates SET is_cancelled= TRUE
    WHERE house_id= caught_cheating_house_id
      AND submission_date >= NOW() - '1 days';

    INSERT INTO marche_halibaba.estimate(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
      VALUES (arg_description, arg_price, arg_is_secret, FALSE, NOW(), arg_estimate_request_id, arg_house_id)
      RETURNING estimate_id INTO new_estimate_request_id;
    RETURN new_estimate_request_id;

  ELSE
    INSERT INTO marche_halibaba.estimate(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
      VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
      RETURNING estimate_id INTO new_estimate_request_id;
    RETURN new_estimate_request_id;

    UPDATE marche_halibaba.houses SET secret_limit_expiration= NOW()+ '7 days'
    WHERE house_id= arg_house_id;
  END IF;

END;
$$ LANGUAGE 'plpgsql';


--Rajouter le temps dans la durée de la punition en print out?
--Problème si on veut ajouter en secret+hiding

--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.submit_secret_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  new_estimate_request_id INTEGER;
BEGIN
  IF arg_is_secret = FALSE
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF arg_is_hiding= TRUE
    THEN RAISE EXCEPTION data_exception;
  END IF;
  /*IF (arg_is_hiding = TRUE --Si le devis est secret + hiding: on vérifie qu'il peut être hiding
    AND ( SELECT *
          FROM marche_halibaba.houses h
          WHERE h.house_id= arg_house_id
            AND h.hiding_limit_expiration) > NOW())
    THEN RAISE EXCEPTION data_exception;
  END IF;*/

  IF ( SELECT * --Si le devis est secret: on vérifie qu'il peut l'être
          FROM marche_halibaba.houses h
          WHERE h.house_id= arg_house_id
            AND h.secret_limit_expiration > NOW())
    THEN RAISE EXCEPTION data_exception;
  END IF;

  IF EXISTS(
    SELECT *
    FROM marche_halibaba.houses h
    WHERE h.house_id= arg_house_id
      AND h.penalty_expiration > NOW()
    )THEN 
      RAISE EXCEPTION 'Vous êtes interdit de devis pour le moment.';
  END IF;

    IF EXISTS( --If the estimate_request is expired, we raise a exception;
    SELECT *
    FROM marche_halibaba.estimate_request er
    WHERE er.estimate_request_id= arg_estimate_request_id  
      AND er.deadline< NOW()
    )THEN 
      RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

  INSERT INTO marche_halibaba.estimate(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
    VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_request_id;
  RETURN new_estimate_request_id;

  UPDATE marche_halibaba.houses SET secret_limit_expiration= NOW()+ '1 days'
  WHERE house_id= arg_house_id;

END;
$$ LANGUAGE 'plpgsql';

DROP VIEW IF EXISTS marche_halibaba.valid_estimates_nbr;
CREATE VIEW marche_halibaba.valid_estimates_nbr AS
  SELECT h.house_id as "h_id", h.name as "h_name",
    count(e.estimate_id) as "h_valid_estimates_nbr"
  FROM marche_halibaba.houses h
    LEFT OUTER JOIN marche_halibaba.estimates e
      ON h.house_id = e.house_id AND
        e.is_cancelled = FALSE
    LEFT OUTER JOIN marche_halibaba.estimate_requests er
      ON e.estimate_request_id = er.estimate_request_id AND
        er.pub_date + INTERVAL '15' day >= NOW() AND
        er.chosen_estimate IS NULL
  GROUP BY h.house_id, h.name;


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
$$ LANGUAGE 'plpgsql';

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
    eo.estimate_id = OLD.estimate_id AND
    eo.option_id = OLD.option_id;

  UPDATE marche_halibaba.houses
  SET turnover = old_turnover + OLD.price
  WHERE house_id = house_to_update;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimate_options_update
AFTER UPDATE on marche_halibaba.estimate_options
FOR EACH ROW
WHEN (OLD.is_chosen = FALSE AND NEW.is_chosen = TRUE)
EXECUTE PROCEDURE marche_halibaba.trigger_estimate_options_update();


REVOKE ALL PRIVILEGES
ON ALL TABLES IN SCHEMA marche_halibaba
FROM app;

REVOKE ALL PRIVILEGES
ON SCHEMA marche_halibaba
FROM app;

REVOKE ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
FROM app;

REVOKE ALL PRIVILEGES
ON ALL FUNCTIONS IN SCHEMA marche_halibaba
FROM app;

DROP USER IF EXISTS app;

CREATE USER app
ENCRYPTED PASSWORD '2S5jn12JndG68hT';

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON ALL FUNCTIONS IN SCHEMA marche_halibaba
TO app;


/********************************************************************************
The PostgreSQL License

Copyright (c) 2014, Binod Nepal, Mix Open Foundation (http://mixof.org).

Permission to use, copy, modify, and distribute this software and its documentation 
for any purpose, without fee, and without a written agreement is hereby granted, 
provided that the above copyright notice and this paragraph and 
the following two paragraphs appear in all copies.

IN NO EVENT SHALL MIX OPEN FOUNDATION BE LIABLE TO ANY PARTY FOR DIRECT, INDIRECT, 
SPECIAL, INCIDENTAL, OR CONSEQUENTIAL DAMAGES, INCLUDING LOST PROFITS, 
ARISING OUT OF THE USE OF THIS SOFTWARE AND ITS DOCUMENTATION, EVEN IF 
MIX OPEN FOUNDATION HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

MIX OPEN FOUNDATION SPECIFICALLY DISCLAIMS ANY WARRANTIES, INCLUDING, 
BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS 
FOR A PARTICULAR PURPOSE. THE SOFTWARE PROVIDED HEREUNDER IS ON AN "AS IS" BASIS, 
AND MIX OPEN FOUNDATION HAS NO OBLIGATIONS TO PROVIDE MAINTENANCE, SUPPORT, 
UPDATES, ENHANCEMENTS, OR MODIFICATIONS.
***********************************************************************************/

CREATE SCHEMA IF NOT EXISTS assert;
CREATE SCHEMA IF NOT EXISTS unit_tests;

DO 
$$
BEGIN
    IF NOT EXISTS 
    (
        SELECT * FROM pg_type
        WHERE 
            typname ='test_result'
        AND 
            typnamespace = 
            (
                SELECT oid FROM pg_namespace 
                WHERE nspname ='public'
            )
    ) THEN
        CREATE DOMAIN public.test_result AS text;
    END IF;
END
$$
LANGUAGE plpgsql;


DROP TABLE IF EXISTS unit_tests.test_details CASCADE;
DROP TABLE IF EXISTS unit_tests.tests CASCADE;
CREATE TABLE unit_tests.tests
(
    test_id                                 SERIAL NOT NULL PRIMARY KEY,
    started_on                              TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT(CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    completed_on                            TIMESTAMP WITHOUT TIME ZONE NULL,
    total_tests                             integer NULL DEFAULT(0),
    failed_tests                            integer NULL DEFAULT(0)
);

CREATE INDEX unit_tests_tests_started_on_inx
ON unit_tests.tests(started_on);

CREATE INDEX unit_tests_tests_completed_on_inx
ON unit_tests.tests(completed_on);

CREATE INDEX unit_tests_tests_failed_tests_inx
ON unit_tests.tests(failed_tests);

CREATE TABLE unit_tests.test_details
(
    id                                      BIGSERIAL NOT NULL PRIMARY KEY,
    test_id                                 integer NOT NULL REFERENCES unit_tests.tests(test_id),
    function_name                           text NOT NULL,
    message                                 text NOT NULL,
    ts                                      TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT(CURRENT_TIMESTAMP AT TIME ZONE 'UTC'),
    status                                  boolean NOT NULL
);

CREATE INDEX unit_tests_test_details_test_id_inx
ON unit_tests.test_details(test_id);

CREATE INDEX unit_tests_test_details_status_inx
ON unit_tests.test_details(status);


DROP FUNCTION IF EXISTS assert.fail(message text);
CREATE FUNCTION assert.fail(message text)
RETURNS text
AS
$$
BEGIN
    IF $1 IS NULL OR trim($1) = '' THEN
        message := 'NO REASON SPECIFIED';
    END IF;
    
    RAISE WARNING 'ASSERT FAILED : %', message;
    RETURN message;
END
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

DROP FUNCTION IF EXISTS assert.pass(message text);
CREATE FUNCTION assert.pass(message text)
RETURNS text
AS
$$
BEGIN
    RAISE NOTICE 'ASSERT PASSED : %', message;
    RETURN '';
END
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

DROP FUNCTION IF EXISTS assert.ok(message text);
CREATE FUNCTION assert.ok(message text)
RETURNS text
AS
$$
BEGIN
    RAISE NOTICE 'OK : %', message;
    RETURN '';
END
$$
LANGUAGE plpgsql
IMMUTABLE STRICT;

DROP FUNCTION IF EXISTS assert.is_equal(IN have anyelement, IN want anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_equal(IN have anyelement, IN want anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 IS NOT DISTINCT FROM $2) THEN
        message := 'Assert is equal.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_EQUAL FAILED.\n\nHave -> ' || COALESCE($1::text, 'NULL') || E'\nWant -> ' || COALESCE($2::text, 'NULL') || E'\n';    
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;


DROP FUNCTION IF EXISTS assert.are_equal(VARIADIC anyarray, OUT message text, OUT result boolean);
CREATE FUNCTION assert.are_equal(VARIADIC anyarray, OUT message text, OUT result boolean)
AS
$$
    DECLARE count integer=0;
    DECLARE total_items bigint;
    DECLARE total_rows bigint;
BEGIN
    result := false;
    
    WITH counter
    AS
    (
        SELECT *
        FROM explode_array($1) AS items
    )
    SELECT
        COUNT(items),
        COUNT(*)
    INTO
        total_items,
        total_rows
    FROM counter;

    IF(total_items = 0 OR total_items = total_rows) THEN
        result := true;
    END IF;

    IF(result AND total_items > 0) THEN
        SELECT COUNT(DISTINCT $1[s.i])
        INTO count
        FROM generate_series(array_lower($1,1), array_upper($1,1)) AS s(i)
        ORDER BY 1;

        IF count <> 1 THEN
            result := FALSE;
        END IF;
    END IF;

    IF(NOT result) THEN
        message := 'ASSERT ARE_EQUAL FAILED.';  
        PERFORM assert.fail(message);
        RETURN;
    END IF;

    message := 'Asserts are equal.';
    PERFORM assert.ok(message);
    result := true;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_not_equal(IN already_have anyelement, IN dont_want anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_not_equal(IN already_have anyelement, IN dont_want anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 IS DISTINCT FROM $2) THEN
        message := 'Assert is not equal.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_NOT_EQUAL FAILED.\n\nAlready Have -> ' || COALESCE($1::text, 'NULL') || E'\nDon''t Want   -> ' || COALESCE($2::text, 'NULL') || E'\n';   
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.are_not_equal(VARIADIC anyarray, OUT message text, OUT result boolean);
CREATE FUNCTION assert.are_not_equal(VARIADIC anyarray, OUT message text, OUT result boolean)
AS
$$
    DECLARE count integer=0;
    DECLARE count_nulls bigint;
BEGIN    
    SELECT COUNT(*)
    INTO count_nulls
    FROM explode_array($1) AS items
    WHERE items IS NULL;

    SELECT COUNT(DISTINCT $1[s.i]) INTO count
    FROM generate_series(array_lower($1,1), array_upper($1,1)) AS s(i)
    ORDER BY 1;
    
    IF(count + count_nulls <> array_upper($1,1) OR count_nulls > 1) THEN
        message := 'ASSERT ARE_NOT_EQUAL FAILED.';  
        PERFORM assert.fail(message);
        RESULT := FALSE;
        RETURN;
    END IF;

    message := 'Asserts are not equal.';
    PERFORM assert.ok(message);
    result := true;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;


DROP FUNCTION IF EXISTS assert.is_null(IN anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_null(IN anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 IS NULL) THEN
        message := 'Assert is NULL.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_NULL FAILED. NULL value was expected.\n\n\n';    
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_not_null(IN anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_not_null(IN anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 IS NOT NULL) THEN
        message := 'Assert is not NULL.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_NOT_NULL FAILED. The value is NULL.\n\n\n';  
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_true(IN boolean, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_true(IN boolean, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1) THEN
        message := 'Assert is true.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_TRUE FAILED. A true condition was expected.\n\n\n';  
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_false(IN boolean, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_false(IN boolean, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF(NOT $1) THEN
        message := 'Assert is false.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_FALSE FAILED. A false condition was expected.\n\n\n';    
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_greater_than(IN x anyelement, IN y anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_greater_than(IN x anyelement, IN y anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 > $2) THEN
        message := 'Assert greater than condition is satisfied.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_GREATER_THAN FAILED.\n\n X : -> ' || COALESCE($1::text, 'NULL') || E'\n is not greater than Y:   -> ' || COALESCE($2::text, 'NULL') || E'\n';    
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.is_less_than(IN x anyelement, IN y anyelement, OUT message text, OUT result boolean);
CREATE FUNCTION assert.is_less_than(IN x anyelement, IN y anyelement, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF($1 < $2) THEN
        message := 'Assert less than condition is satisfied.';
        PERFORM assert.ok(message);
        result := true;
        RETURN;
    END IF;
    
    message := E'ASSERT IS_LESS_THAN FAILED.\n\n X : -> ' || COALESCE($1::text, 'NULL') || E'\n is not less than Y:   -> ' || COALESCE($2::text, 'NULL') || E'\n';  
    PERFORM assert.fail(message);
    result := false;
    RETURN;
END
$$
LANGUAGE plpgsql
IMMUTABLE;

DROP FUNCTION IF EXISTS assert.function_exists(function_name text, OUT message text, OUT result boolean);
CREATE FUNCTION assert.function_exists(function_name text, OUT message text, OUT result boolean)
AS
$$
BEGIN
    IF NOT EXISTS
    (
        SELECT  1
        FROM    pg_catalog.pg_namespace n
        JOIN    pg_catalog.pg_proc p
        ON      pronamespace = n.oid
        WHERE replace(nspname || '.' || proname || '(' || oidvectortypes(proargtypes) || ')', ' ' , '')::text=$1
    ) THEN
        message := format('The function %s does not exist.', $1);
        PERFORM assert.fail(message);

        result := false;
        RETURN;
    END IF;

    message := format('Ok. The function %s exists.', $1);
    PERFORM assert.ok(message);
    result := true;
    RETURN;
END
$$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS assert.if_functions_compile(VARIADIC _schema_name text[], OUT message text, OUT result boolean);
CREATE OR REPLACE FUNCTION assert.if_functions_compile
(
    VARIADIC _schema_name text[],
    OUT message text, 
    OUT result boolean
)
AS
$$
    DECLARE all_parameters              text;
    DECLARE current_function            RECORD;
    DECLARE current_function_name       text;
    DECLARE current_type                text;
    DECLARE current_type_schema         text;
    DECLARE current_parameter           text;
    DECLARE functions_count             smallint := 0;
    DECLARE current_parameters_count    int;
    DECLARE i                           int;
    DECLARE command_text                text;
    DECLARE failed_functions            text;
BEGIN
    FOR current_function IN 
        SELECT proname, proargtypes, nspname 
        FROM pg_proc 
        INNER JOIN pg_namespace 
        ON pg_proc.pronamespace = pg_namespace.oid 
        WHERE pronamespace IN 
        (
            SELECT oid FROM pg_namespace 
            WHERE nspname = ANY($1) 
            AND nspname NOT IN
            (
                'assert', 'unit_tests', 'information_schema'
            ) 
            AND proname NOT IN('if_functions_compile')
        ) 
    LOOP
        current_parameters_count := array_upper(current_function.proargtypes, 1) + 1;

        i := 0;
        all_parameters := '';

        LOOP
        IF i < current_parameters_count THEN
            IF i > 0 THEN
                all_parameters := all_parameters || ', ';
            END IF;

            SELECT 
                nspname, typname 
            INTO 
                current_type_schema, current_type 
            FROM pg_type 
            INNER JOIN pg_namespace 
            ON pg_type.typnamespace = pg_namespace.oid
            WHERE pg_type.oid = current_function.proargtypes[i];

            IF(current_type IN('int4', 'int8', 'numeric', 'integer_strict', 'money_strict','decimal_strict', 'integer_strict2', 'money_strict2','decimal_strict2', 'money','decimal', 'numeric', 'bigint')) THEN
                current_parameter := '1::' || current_type_schema || '.' || current_type;
            ELSIF(substring(current_type, 1, 1) = '_') THEN
                current_parameter := 'NULL::' || current_type_schema || '.' || substring(current_type, 2, length(current_type)) || '[]';
            ELSIF(current_type in ('date')) THEN            
                current_parameter := '''1-1-2000''::' || current_type;
            ELSIF(current_type = 'bool') THEN
                current_parameter := 'false';            
            ELSE
                current_parameter := '''''::' || quote_ident(current_type_schema) || '.' || quote_ident(current_type);
            END IF;
            
            all_parameters = all_parameters || current_parameter;

            i := i + 1;
        ELSE
            EXIT;
        END IF;
    END LOOP;

    BEGIN
        current_function_name := quote_ident(current_function.nspname)  || '.' || quote_ident(current_function.proname);
        command_text := 'SELECT * FROM ' || current_function_name || '(' || all_parameters || ');';

        EXECUTE command_text;
        functions_count := functions_count + 1;

        EXCEPTION WHEN OTHERS THEN
            IF(failed_functions IS NULL) THEN 
                failed_functions := '';
            END IF;
            
            IF(SQLSTATE IN('42702', '42704')) THEN
                failed_functions := failed_functions || E'\n' || command_text || E'\n' || SQLERRM || E'\n';                
            END IF;
    END;


    END LOOP;

    IF(failed_functions != '') THEN
        message := E'The test if_functions_compile failed. The following functions failed to compile : \n\n' || failed_functions;
        result := false;
        PERFORM assert.fail(message);
        RETURN;
    END IF;
END;
$$
LANGUAGE plpgsql 
VOLATILE;

DROP FUNCTION IF EXISTS assert.if_views_compile(VARIADIC _schema_name text[], OUT message text, OUT result boolean);
CREATE FUNCTION assert.if_views_compile
(
    VARIADIC _schema_name text[],
    OUT message text, 
    OUT result boolean    
)
AS
$$

    DECLARE message                     test_result;
    DECLARE current_view                RECORD;
    DECLARE current_view_name           text;
    DECLARE command_text                text;
    DECLARE failed_views                text;
BEGIN
    FOR current_view IN 
        SELECT table_name, table_schema 
        FROM information_schema.views
        WHERE table_schema = ANY($1) 
    LOOP

    BEGIN
        current_view_name := quote_ident(current_view.table_schema)  || '.' || quote_ident(current_view.table_name);
        command_text := 'SELECT * FROM ' || current_view_name || ' LIMIT 1;';

        RAISE NOTICE '%', command_text;
        
        EXECUTE command_text;

        EXCEPTION WHEN OTHERS THEN
            IF(failed_views IS NULL) THEN 
                failed_views := '';
            END IF;

            failed_views := failed_views || E'\n' || command_text || E'\n' || SQLERRM || E'\n';                
    END;


    END LOOP;

    IF(failed_views != '') THEN
        message := E'The test if_views_compile failed. The following views failed to compile : \n\n' || failed_views;
        result := false;
        PERFORM assert.fail(message);
        RETURN;
    END IF;

    RETURN;
END;
$$
LANGUAGE plpgsql 
VOLATILE;


DROP FUNCTION IF EXISTS unit_tests.begin(verbosity integer, format text);
CREATE FUNCTION unit_tests.begin(verbosity integer DEFAULT 9, format text DEFAULT '')
RETURNS TABLE(message text, result character(1))
AS
$$
    DECLARE this                    record;
    DECLARE _function_name          text;
    DECLARE _sql                    text;
    DECLARE _message                text;
    DECLARE _result                 character(1);
    DECLARE _test_id                integer;
    DECLARE _status                 boolean;
    DECLARE _total_tests            integer                         = 0;
    DECLARE _failed_tests           integer                         = 0;
    DECLARE _list_of_failed_tests   text;
    DECLARE _started_from           TIMESTAMP WITHOUT TIME ZONE;
    DECLARE _completed_on           TIMESTAMP WITHOUT TIME ZONE;
    DECLARE _delta                  integer;
    DECLARE _ret_val                text                            = '';
    DECLARE _verbosity              text[]                          = 
                                    ARRAY['debug5', 'debug4', 'debug3', 'debug2', 'debug1', 'log', 'notice', 'warning', 'error', 'fatal', 'panic'];
BEGIN
    _started_from := clock_timestamp() AT TIME ZONE 'UTC';

    IF(format='teamcity') THEN
        RAISE INFO '##teamcity[testSuiteStarted name=''Plpgunit'' message=''Test started from : %'']', _started_from; 
    ELSE
        RAISE INFO 'Test started from : %', _started_from; 
    END IF;
    
    IF($1 > 11) THEN
        $1 := 9;
    END IF;
    
    EXECUTE 'SET CLIENT_MIN_MESSAGES TO ' || _verbosity[$1];
    RAISE WARNING 'CLIENT_MIN_MESSAGES set to : %' , _verbosity[$1];
    
    SELECT nextval('unit_tests.tests_test_id_seq') INTO _test_id;

    INSERT INTO unit_tests.tests(test_id)
    SELECT _test_id;

    FOR this IN
        SELECT 
            nspname AS ns_name,
            proname AS function_name
        FROM    pg_catalog.pg_namespace n
        JOIN    pg_catalog.pg_proc p
        ON      pronamespace = n.oid
        WHERE
            prorettype='test_result'::regtype::oid
        ORDER BY p.oid ASC
    LOOP
        BEGIN
            _status := false;
            _total_tests := _total_tests + 1;
            
            _function_name = this.ns_name|| '.' || this.function_name || '()';
            _sql := 'SELECT ' || _function_name || ';';
            
            RAISE NOTICE 'RUNNING TEST : %.', _function_name;

            IF(format='teamcity') THEN
                RAISE INFO '##teamcity[testStarted name=''%'' message=''%'']', _function_name, _started_from; 
            ELSE
                RAISE INFO 'Running test % : %', _function_name, _started_from; 
            END IF;
            
            EXECUTE _sql INTO _message;

            IF _message = '' THEN
                _status := true;

                IF(format='teamcity') THEN
                    RAISE INFO '##teamcity[testFinished name=''%'' message=''%'']', _function_name, clock_timestamp() AT TIME ZONE 'UTC'; 
                ELSE
                    RAISE INFO 'Passed % : %', _function_name, clock_timestamp() AT TIME ZONE 'UTC'; 
                END IF;
            ELSE
                IF(format='teamcity') THEN
                    RAISE INFO '##teamcity[testFailed name=''%'' message=''%'']', _function_name, _message; 
                    RAISE INFO '##teamcity[testFinished name=''%'' message=''%'']', _function_name, clock_timestamp() AT TIME ZONE 'UTC'; 
                ELSE
                    RAISE INFO 'Test failed % : %', _function_name, _message; 
                END IF;
            END IF;
            
            INSERT INTO unit_tests.test_details(test_id, function_name, message, status, ts)
            SELECT _test_id, _function_name, _message, _status, clock_timestamp();

            IF NOT _status THEN
                _failed_tests := _failed_tests + 1;         
                RAISE WARNING 'TEST % FAILED.', _function_name;
                RAISE WARNING 'REASON: %', _message;
            ELSE
                RAISE NOTICE 'TEST % COMPLETED WITHOUT ERRORS.', _function_name;
            END IF;

        EXCEPTION WHEN OTHERS THEN
            _message := 'ERR' || SQLSTATE || ': ' || SQLERRM;
            INSERT INTO unit_tests.test_details(test_id, function_name, message, status)
            SELECT _test_id, _function_name, _message, false;

            _failed_tests := _failed_tests + 1;         

            RAISE WARNING 'TEST % FAILED.', _function_name;
            RAISE WARNING 'REASON: %', _message;

            IF(format='teamcity') THEN
                RAISE INFO '##teamcity[testFailed name=''%'' message=''%'']', _function_name, _message; 
                RAISE INFO '##teamcity[testFinished name=''%'' message=''%'']', _function_name, clock_timestamp() AT TIME ZONE 'UTC'; 
            ELSE
                RAISE INFO 'Test failed % : %', _function_name, _message; 
            END IF;
        END;
    END LOOP;

    _completed_on := clock_timestamp() AT TIME ZONE 'UTC';
    _delta := extract(millisecond from _completed_on - _started_from)::integer;
    
    UPDATE unit_tests.tests
    SET total_tests = _total_tests, failed_tests = _failed_tests, completed_on = _completed_on
    WHERE test_id = _test_id;

    IF format='junit' THEN
        SELECT 
            '<?xml version="1.0" encoding="UTF-8"?>'||
            xmlelement
            (
                name testsuites,
                xmlelement
                (
                    name                    testsuite,
                    xmlattributes
                    (
                        'plpgunit'          AS name, 
                        t.total_tests       AS tests, 
                        t.failed_tests      AS failures, 
                        0                   AS errors, 
                        EXTRACT
                        (
                            EPOCH FROM t.completed_on - t.started_on
                        )                   AS time
                    ),
                    xmlagg
                    (
                        xmlelement
                        (
                            name testcase, 
                            xmlattributes
                            (
                                td.function_name
                                            AS name, 
                                EXTRACT
                                (
                                    EPOCH FROM td.ts - t.started_on
                                )           AS time
                            ),
                            CASE 
                                WHEN td.status=false 
                                THEN 
                                    xmlelement
                                    (
                                        name failure, 
                                        td.message
                                    ) 
                                END
                        )
                    )
                )
            ) INTO _ret_val
        FROM unit_tests.test_details td, unit_tests.tests t
        WHERE
            t.test_id=_test_id
        AND 
            td.test_id=t.test_id
        GROUP BY t.test_id;
    ELSE
        WITH failed_tests AS
        (
            SELECT row_number() OVER (ORDER BY id) AS id, 
                unit_tests.test_details.function_name,
                unit_tests.test_details.message
            FROM unit_tests.test_details 
            WHERE test_id = _test_id
            AND status= false
        )
        SELECT array_to_string(array_agg(f.id::text || '. ' || f.function_name || ' --> ' || f.message), E'\n') INTO _list_of_failed_tests 
        FROM failed_tests f;

        _ret_val := _ret_val ||  'Test completed on : ' || _completed_on::text || E' UTC. \nTotal test runtime: ' || _delta::text || E' ms.\n';
        _ret_val := _ret_val || E'\nTotal tests run : ' || COALESCE(_total_tests, '0')::text;
        _ret_val := _ret_val || E'.\nPassed tests    : ' || (COALESCE(_total_tests, '0') - COALESCE(_failed_tests, '0'))::text;
        _ret_val := _ret_val || E'.\nFailed tests    : ' || COALESCE(_failed_tests, '0')::text;
        _ret_val := _ret_val || E'.\n\nList of failed tests:\n' || '----------------------';
        _ret_val := _ret_val || E'\n' || COALESCE(_list_of_failed_tests, '<NULL>')::text;
        _ret_val := _ret_val || E'\n' || E'End of plpgunit test.\n\n';
    END IF;
    
    IF _failed_tests > 0 THEN
        _result := 'N';

        IF(format='teamcity') THEN
            RAISE INFO '##teamcity[testStarted name=''Result'']'; 
            RAISE INFO '##teamcity[testFailed name=''Result'' message=''%'']', REPLACE(_ret_val, E'\n', ' |n'); 
            RAISE INFO '##teamcity[testFinished name=''Result'']'; 
            RAISE INFO '##teamcity[testSuiteFinished name=''Plpgunit'' message=''%'']', REPLACE(_ret_val, E'\n', '|n'); 
        ELSE
            RAISE INFO '%', _ret_val;
        END IF;
    ELSE
        _result := 'Y';

        IF(format='teamcity') THEN
            RAISE INFO '##teamcity[testSuiteFinished name=''Plpgunit'' message=''%'']', REPLACE(_ret_val, E'\n', '|n'); 
        ELSE
            RAISE INFO '%', _ret_val;
        END IF;
    END IF;

    SET CLIENT_MIN_MESSAGES TO notice;
    
    RETURN QUERY SELECT _ret_val, _result;
END
$$
LANGUAGE plpgsql;

DROP FUNCTION IF EXISTS unit_tests.begin_junit(verbosity integer);
CREATE FUNCTION unit_tests.begin_junit(verbosity integer DEFAULT 9)
RETURNS TABLE(message text, result character(1))
AS
$$
BEGIN
    RETURN QUERY 
    SELECT * FROM unit_tests.begin($1, 'junit');
END
$$
LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION marche_halibaba.insert_mock_data()
  RETURNS void AS $$
BEGIN
  -- Creates houses
  PERFORM marche_halibaba.signup_house('clegane', 'blublu', 'House Clegane');
  PERFORM marche_halibaba.signup_house('hornwood', 'blublu', 'House Hornwoord');
  PERFORM marche_halibaba.signup_house('cerwyn', 'blublu', 'House Cerwyn');

  -- Creates clients
  PERFORM marche_halibaba.signup_client('jeremy', '1000:8390b08bda9aaa174c8a7d839940c3831c1f72e1476909f6:c13365b0ef62f82f9ba702b1c3ecbe4ddbfb511b40757bacf7068d7bfc7b2691fa36ef9e246845f0fd3737f0d95da3cbbc9478e488fc1ed91f60b04159d9b99de6c5a081cf19b9821ab8ccf239b06499a1ad0485391fc67732081b06ee2b206c', 'Jeremy', 'Wagemans');

  -- Creates estimate requests
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 1', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 2', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 3', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 4', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

  -- Submits estimates
  PERFORM marche_halibaba.submit_estimate('Devis 1', 1600, FALSE, FALSE, 1, 1);


END;
$$ LANGUAGE plpgsql;

SELECT marche_halibaba.insert_mock_data();


CREATE OR REPLACE FUNCTION unit_tests.test_clients()
  RETURNS test_result AS $$
DECLARE
  message test_result;
BEGIN
  IF (
    SELECT count(*)
    FROM marche_halibaba.clients c, marche_halibaba.users u
    WHERE c.user_id = u.user_id
  ) <> 1 THEN
    SELECT assert.fail('Tous les clients n ont pas été insérés.') INTO message;
    RETURN message;
  END IF;

  IF NOT EXISTS (
    SELECT *
    FROM marche_halibaba.clients c, marche_halibaba.users u
    WHERE c.user_id = u.user_id AND
      c.last_name = 'Wagemans' AND
      c.first_name = 'Jeremy' AND
      u.username = 'jeremy' AND
      u.pswd = 'blublu'
    ) THEN
    SELECT assert.fail('L insertion des clients est incorrecte.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;


CREATE OR REPLACE FUNCTION unit_tests.test_houses()
  RETURNS test_result AS $$
DECLARE
  message test_result;
BEGIN

  IF (
    SELECT count(*)
    FROM marche_halibaba.houses h, marche_halibaba.users u
    WHERE h.user_id = u.user_id
  ) <> 3 THEN
    SELECT assert.fail('Toutes les maisons n ont pas été insérés.') INTO message;
    RETURN message;
  END IF;

  IF NOT EXISTS (
    SELECT *
    FROM marche_halibaba.houses h, marche_halibaba.users u
    WHERE h.user_id = u.user_id AND
      h.name = 'House Clegane' AND
      u.username = 'clegane' AND
      u.pswd = 'blublu'
  ) THEN
    SELECT assert.fail('L insertion des maisons est incorrecte.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;


