
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


DROP VIEW IF EXISTS marche_halibaba.signin_users;

CREATE VIEW marche_halibaba.signin_users AS
  SELECT u.username as "u_username", u.pswd as "u_pswd", c.client_id as "c_id",
    c.first_name as "c_first_name", c.last_name as "c_last_name",
      h.house_id as "h_id", h.name as "h_name"
  FROM marche_halibaba.users u
    LEFT OUTER JOIN marche_halibaba.clients c
      ON u.user_id = c.user_id
    LEFT OUTER JOIN marche_halibaba.houses h
      ON u.user_id = h.user_id;


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


DROP VIEW IF EXISTS marche_halibaba.list_estimate_requests;

CREATE VIEW marche_halibaba.list_estimate_requests AS
  SELECT er.estimate_request_id AS "er_id",
    er.description AS "er_description",
    er.deadline AS "er_deadline",
    er.pub_date AS "er_pub_date",
    er.chosen_estimate AS "er_chosen_estimate",
    a.street_name AS "er_construction_id",
    a.zip_code AS "er_construction_zip",
    a.city AS "er_construction_city",
    a2.street_name AS "er_invoicing_street",
    a2.zip_code AS "er_invoicing_zip",
    a2.city AS "er_invoicing_city",
    c.client_id AS "c_id",
    c.last_name AS "c_last_name",
    c.first_name AS "c_first_name",
    AGE(er.pub_date + INTERVAL '15' day, NOW()) AS "remaining_days"
  FROM marche_halibaba.clients c, marche_halibaba.addresses a, marche_halibaba.estimate_requests er
    LEFT OUTER JOIN marche_halibaba.addresses a2 ON er.invoicing_address = a2.address_id
  WHERE a.address_id = er.construction_address
    AND c.client_id = er.client_id
  ORDER BY er.pub_date DESC;


DROP VIEW IF EXISTS marche_halibaba.list_estimate_options;

CREATE VIEW marche_halibaba.list_estimate_options AS
  SELECT o.option_id as "o_id", eo.estimate_id as "e_id",
    o.description as "o_description", eo.price as "eo_price"
  FROM marche_halibaba.estimate_options eo, marche_halibaba.options o
  WHERE eo.option_id = o.option_id;


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
          e2.is_hiding = TRUE AND
          e2.is_cancelled = FALSE
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
    )) view
  ORDER BY view.submission_date DESC;


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


CREATE OR REPLACE FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[], INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  arg_client_id ALIAS FOR $3;
  er_id INTEGER;
  er_client_id INTEGER;
  option INTEGER;
BEGIN
  SELECT e.estimate_request_id, er.client_id
  INTO er_id, er_client_id
  FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
  WHERE e.estimate_request_id = er.estimate_request_id AND
    e.estimate_id = arg_estimate_id;

  IF er_client_id <> arg_client_id THEN
    RAISE EXCEPTION 'Vous n etes pas autorise a accepter ce devis';
  END IF;

  UPDATE marche_halibaba.estimate_requests er
  SET chosen_estimate = arg_estimate_id
  WHERE estimate_request_id = er_id;

  IF arg_chosen_options IS NOT NULL THEN
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
$$ LANGUAGE 'plpgsql';


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


CREATE OR REPLACE FUNCTION marche_halibaba.modify_option(TEXT, NUMERIC(12,2), INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_option_id ALIAS FOR $3;
BEGIN
  UPDATE marche_halibaba.options
  SET description= arg_description, price= arg_price
  WHERE arg_option_id= option_id;
RETURN arg_option_id;
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
  INSERT INTO marche_halibaba.options(description, price, house_id) 
  VALUES (arg_description, arg_price, arg_house_id) RETURNING option_id INTO new_option_id;
  RETURN new_option_id;
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


CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  arg_chosen_options ALIAS FOR $7;
  new_estimate_id INTEGER;
  option INTEGER;
  option_price NUMERIC(12,2);
BEGIN
  INSERT INTO marche_halibaba.estimates(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
  VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_id;

  IF arg_chosen_options IS NOT NULL THEN
    FOREACH option IN ARRAY arg_chosen_options
    LOOP
      SELECT o.price INTO option_price
      FROM marche_halibaba.options o
      WHERE o.option_id = option;

      INSERT INTO marche_halibaba.estimate_options(price, is_chosen, estimate_id, option_id)
      VALUES (option_price, FALSE, new_estimate_id, option);
    END LOOP;
  END IF;

  RETURN new_estimate_id;
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


CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimate_insert()
  RETURNS TRIGGER AS $$

DECLARE 
  new_estimate_request_id INTEGER;
  caught_cheating_house_id INTEGER;
  house_times_record RECORD;

BEGIN
  
  SELECT h.penalty_expiration AS penalty_expiration, 
    h.secret_limit_expiration AS secret_limit_expiration,
    h.hiding_limit_expiration AS hiding_limit_expiration
  INTO house_times_record
  FROM marche_halibaba.houses h
  WHERE h.house_id= NEW.house_id;

  SELECT h.house_id 
    INTO caught_cheating_house_id
  FROM marche_halibaba.estimates e, marche_halibaba.houses h
  WHERE e.estimate_request_id= NEW.estimate_request_id
    AND e.house_id= h.house_id
    AND e.is_hiding= TRUE AND e.is_cancelled= FALSE;

  IF house_times_record.penalty_expiration > NOW() 
  THEN 
    RAISE EXCEPTION 'Vous êtes interdit de devis pour encore % heures.', age( house_times_record.penalty_expiration, NOW());
  END IF;

  IF EXISTS( --If the estimate_request is expired, we raise a exception;
  SELECT *
  FROM marche_halibaba.estimate_requests er
  WHERE er.estimate_request_id= NEW.house_id  
    AND er.deadline< NOW()
  )THEN 
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;
  
  IF NEW.is_hiding= TRUE
  THEN
    IF house_times_record.hiding_limit_expiration > NOW() --On vérifie que l'on peut soumettre un devis hiding actuellement
    THEN 
      RAISE EXCEPTION 'Vous ne pouvez pas poster de devis masquant pour encore %.',age( house_times_record.hiding_limit_expiration, NOW()) ;
    ELSEIF caught_cheating_house_id IS NOT NULL --S'il y a déjà un devis masquant pour cette estimate_request
    THEN 
      UPDATE marche_halibaba.houses
      SET penalty_expiration = NOW() + INTERVAL '1' day,
        caught_cheating_nbr = caught_cheating_nbr+1
      WHERE  house_id = caught_cheating_house_id;

      UPDATE marche_halibaba.houses
      SET caught_cheater_nbr = caught_cheater_nbr+1
      WHERE house_id= NEW.house_id;

      UPDATE marche_halibaba.estimates
      SET is_cancelled= TRUE
      WHERE house_id= caught_cheating_house_id
        AND estimate_request_id= NEW.estimate_request_id
        AND is_hiding= TRUE;

      UPDATE marche_halibaba.estimates 
      SET is_cancelled= TRUE
      WHERE house_id= caught_cheating_house_id
        AND submission_date >= NOW() - INTERVAL '1' day;

      NEW.is_hiding:=FALSE;
      NEW.is_secret:=FALSE; --Justifier dans le rapport que si on ne set pas secret à false, on ne pourrait pas poster, juste après celui-ci, un devis secret & hiding  mais seulement hiding. Et qu'ainsi on a réellement un devis normal soumis.

    ELSE
      UPDATE marche_halibaba.houses 
      SET hiding_limit_expiration= NOW()+ INTERVAL '7' day 
      WHERE house_id= NEW.house_id;
    END IF;
  END IF;

  IF NEW.is_secret= TRUE
  THEN
    IF house_times_record.secret_limit_expiration > NOW() 
    THEN
      RAISE EXCEPTION 'Vous ne pouvez pas poster de devis secret pour encore % heures.',age( house_times_record.secret_limit_expiration, NOW()) ;
    ELSE
      UPDATE marche_halibaba.houses 
      SET secret_limit_expiration= NOW()+ INTERVAL '1' day 
      WHERE house_id= NEW.house_id;
    END IF;
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimate_insert
BEFORE INSERT ON marche_halibaba.estimates
FOR EACH ROW
EXECUTE PROCEDURE marche_halibaba.trigger_estimate_insert();

CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimate_requests_update()
  RETURNS TRIGGER AS $$

DECLARE
  var_estimate_details RECORD;
  var_acceptance_rate NUMERIC(3,2);
BEGIN
  SELECT e.estimate_request_id as "estimate_request_id",
    e.is_cancelled as "is_cancelled", e.price as "price",
    e.house_id as "house_id"
  INTO var_estimate_details
  FROM marche_halibaba.estimates e
  WHERE e.estimate_id = NEW.chosen_estimate;

  -- An exception is raised if a estimate has already been approved for this estimate request
  IF OLD.chosen_estimate IS NOT NULL THEN
    RAISE EXCEPTION 'Un devis a déjà été approuvé pour cette demande.';
  END IF;

  -- An exception is raised because the estimate has been cancelled
  IF var_estimate_details.is_cancelled THEN
    RAISE EXCEPTION 'Ce devis n est plus valide. Il a été annulé.';
  END IF;

  -- An exception is raised because the estimate request has expired
  IF (OLD.pub_date + INTERVAL '15' day) < NOW() THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

  -- Updates house statistics
  SELECT ((
    SELECT count(estimate_id)
    FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
    WHERE e.estimate_id = er.chosen_estimate AND
      e.house_id = var_estimate_details.house_id)::numeric(16,2)/(
    SELECT count(estimate_id)
    FROM marche_halibaba.estimates e
    WHERE e.house_id = var_estimate_details.house_id)::numeric(16,2))::numeric(3,2)
  INTO var_acceptance_rate;

  UPDATE marche_halibaba.houses
  SET turnover = turnover + var_estimate_details.price,
    acceptance_rate = var_acceptance_rate
  WHERE house_id = var_estimate_details.house_id;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimate_requests_update
AFTER UPDATE OF chosen_estimate ON marche_halibaba.estimate_requests
FOR EACH ROW
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
WHEN (OLD.is_chosen IS DISTINCT FROM NEW.is_chosen)
EXECUTE PROCEDURE marche_halibaba.trigger_estimate_options_update();


/* DEV ENVIRONMENT */
/*
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
TO app;*/

/* Clients app user */

DROP USER IF EXISTS app_clients;

CREATE USER app_clients
ENCRYPTED PASSWORD '2S5jn12JndG68hT';

GRANT USAGE
ON SCHEMA marche_halibaba
TO app_clients;

GRANT SELECT
ON marche_halibaba.clients_list_estimates,
  marche_halibaba.estimate_details,
  marche_halibaba.list_estimate_requests,
  marche_halibaba.signin_users,
  marche_halibaba.houses,
  marche_halibaba.estimates,
  marche_halibaba.options
TO app_clients;

GRANT SELECT, INSERT
ON marche_halibaba.users,
  marche_halibaba.clients,
  marche_halibaba.estimate_requests,
  marche_halibaba.addresses
TO app_clients;

GRANT SELECT, UPDATE, TRIGGER
ON marche_halibaba.estimate_requests,
  marche_halibaba.estimate_options,
  marche_halibaba.houses
TO app_clients;

GRANT EXECUTE
ON FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[], INTEGER),
  marche_halibaba.signup_client(VARCHAR(35), VARCHAR(50), VARCHAR(35), VARCHAR(35)),
  marche_halibaba.submit_estimate_request(TEXT, DATE, INTEGER, VARCHAR(50),
    VARCHAR(8), VARCHAR(5), VARCHAR(35), VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35)),
  marche_halibaba.trigger_estimate_requests_update(),
  marche_halibaba.trigger_estimate_options_update()
TO app_clients;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO app_clients;

/* PROD ENVIRONMENT

GRANT CONNECT
ON DATABASE dbjwagema15
TO pdragom15;

GRANT SELECT
ON ALL TABLES IN SCHEMA marche_halibaba
TO pdragom15;

--GRANT INSERT
--ON TABLE users, clients, estimate_requests, addresses

--GRANT UPDATE
--ON estimate_options, estimate_requests

GRANT ALL PRIVILEGES
ON SCHEMA marche_halibaba
TO pdragom15;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO pdragom15;

GRANT EXECUTE
ON ALL FUNCTIONS IN SCHEMA marche_halibaba
TO pdragom15; */


-- Insère des clients
SELECT marche_halibaba.signup_client('ramsey', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Ramsey', 'GoT');
SELECT marche_halibaba.submit_estimate_request('Nettoyer mes toilettes', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);

SELECT marche_halibaba.signup_house('starque', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Starque');
SELECT marche_halibaba.add_option('Avec le sourire', 50, 1);
SELECT marche_halibaba.submit_estimate('nettoyage', 100, FALSE, FALSE, 1, 1, '{1}');

SELECT marche_halibaba.signup_house('boltone', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Boltone');
SELECT marche_halibaba.submit_estimate('nettoyage, sourire compris', 90, TRUE, FALSE, 1, 2, '{}');

SELECT marche_halibaba.submit_estimate('99€ promo de Noël : nettoyage sans râler', 99, FALSE, TRUE, 1, 1, '{}');
SELECT marche_halibaba.submit_estimate('80€ sans sourire', 80, FALSE, TRUE, 1, 2, '{}');
SELECT marche_halibaba.submit_estimate('test 123', 10000, FALSE, FALSE, 1, 1, '{1}');

SELECT marche_halibaba.approve_estimate(4, '{}',1);


