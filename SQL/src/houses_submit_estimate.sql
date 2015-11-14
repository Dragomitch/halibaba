-- Custom type

/**DROP TYPE IF EXISTS marche_halibaba.estimate;
CREATE TYPE marche_halibaba.estimate
  AS (
    estimate_id INTEGER,
    description TEXT,
    price NUMERIC(12,2),
    options_nbr INTEGER,
    pub_date TIMESTAMP,
    house_id INTEGER
  );
**/

--Rajouter le temps dans la durée de la punition ?

--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, BOOLEAN, INTEGER, INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_cancelled ALIAS FOR $3;
  arg_is_secret ALIAS FOR $4;
  arg_is_hiding ALIAS FOR $5;
  arg_estimate_request_id ALIAS FOR $6;
  arg_house_id ALIAS FOR $7;
  new_estimate_request_id INTEGER;
BEGIN
  IF EXISTS( --If the estimate_request is expired, we raise a exception;
    SELECT *
    FROM marche_halibaba.estimate_request er
    WHERE er.estimate_request_id= arg_estimate_request_id  
      AND er.deadline< NOW()
    )THEN 
      RAISE EXCEPTION 'Cette demande de devis est expirée.';

  IF EXISTS(
    SELECT *
    FROM marche_halibaba.houses h
    WHERE h.house_id= arg_house_id
      AND h.penalty_expiration > NOW()
    )THEN 
      RAISE EXCEPTION 'Vous êtes interdit de devis pour le moment.';

  INSERT INTO marche_halibaba.estimate(description, price, is_cancelled, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
    VALUES (arg_description, arg_price, arg_is_cancelled, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_request_id;
  RETURN new_estimate_request_id;

END;
$$ LANGUAGE 'plpgsql';