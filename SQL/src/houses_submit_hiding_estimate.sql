--Rajouter le temps dans la durée de la punition en print out?
--Problème si on veut ajouter en secret+hiding

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
    UPDATE marche_halibaba.houses SET penalty_expiration= NOW()+ '1 days'
    WHERE  house_id= caught_cheating_house_id;

    UPDATE marche_halibaba.houses SET caught_cheating_nbr= caught_cheating_nbr+1
    WHERE house_id= caught_cheating_house_id;

    UPDATE marche_halibaba.houses SET caught_cheater_nbr= caught_cheater_nbr+1
    WHERE house_id= arg_house_id;

    UPDATE marche_halibaba.estimates SET is_cancelled= TRUE
    WHERE house_id= caught_cheating_house_id
      AND submission_date>= NOW() - '1 days';

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