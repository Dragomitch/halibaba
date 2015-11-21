CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER[], INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  arg_chosen_options ALIAS FOR $7;
  arg_price_options ALIAS FOR $8;
  new_estimate_request_id INTEGER;
  caught_cheating_house_id INTEGER;
  option INTEGER;
  price INTEGER;
  house_times_record RECORD;
BEGIN
  
  SELECT h.penalty_expiration AS penalty_expiration, 
    h.secret_limit_expiration AS secret_limit_expiration,
    h.hiding_limit_expiration AS hiding_limit_expiration
  INTO house_times_record
  FROM marche_halibaba.houses h
  WHERE h.house_id= arg_house_id;

  IF house_times_record.penalty_expiration IS NOT NULL 
  THEN 
      RAISE EXCEPTION 'Vous êtes interdit de devis pour encore % heures.', age( house_times_record.penalty_expiration, NOW());
  END IF;

  IF EXISTS( --If the estimate_request is expired, we raise a exception;
  SELECT *
  FROM marche_halibaba.estimate_requests er
  WHERE er.estimate_request_id= arg_estimate_request_id  
    AND er.deadline< NOW()
  )THEN 
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  END IF;

  SELECT h.house_id 
    INTO caught_cheating_house_id
  FROM marche_halibaba.estimates e, marche_halibaba.houses h
  WHERE e.estimate_request_id= arg_estimate_request_id
    AND e.house_id= h.house_id
    AND e.is_hiding= TRUE AND e.is_cancelled= FALSE;
  
  IF arg_is_hiding= TRUE
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
      WHERE house_id= arg_house_id;

      UPDATE marche_halibaba.estimates
      SET is_cancelled= TRUE
      WHERE house_id= caught_cheating_house_id
        AND estimate_request_id= arg_estimate_request_id
        AND is_hiding= TRUE;

      UPDATE marche_halibaba.estimates 
      SET is_cancelled= TRUE
      WHERE house_id= caught_cheating_house_id
        AND submission_date >= NOW() - INTERVAL '1' day;

      arg_is_hiding:=FALSE;
      arg_is_secret:=FALSE; --Justifier dans le rapport que si on ne set pas secret à false, on ne pourrait pas poster, juste après celui-ci, un devis secret & hiding  mais seulement hiding. Et qu'ainsi on a réellement un devis normal soumis.
    ELSE
      UPDATE marche_halibaba.houses 
      SET hiding_limit_expiration= NOW()+ INTERVAL '7' day 
      WHERE house_id= arg_house_id;
    END IF;
  END IF;

  IF arg_is_secret= TRUE --Si le devis est secret:
  THEN
    IF house_times_record.secret_limit_expiration> NOW() --On vérifie que l'on peut soumettre un devis secret actuellement
    THEN
      RAISE EXCEPTION 'Vous ne pouvez pas poster de devis secret pour encore % heures.',age( house_times_record.secret_limit_expiration, NOW()) ;
    ELSE
      UPDATE marche_halibaba.houses 
      SET secret_limit_expiration= NOW()+ INTERVAL '1' day 
      WHERE house_id= arg_house_id;
    END IF;
  END IF;
  
  INSERT INTO marche_halibaba.estimates(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
  VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_request_id;

  FOREACH option, price IN ARRAY arg_chosen_options, arg_price_options
  LOOP
    INSERT INTO marche_halibaba.estimate_options
    VALUES (price, FALSE, new_estimate_id, option);
  END LOOP;

  RETURN new_estimate_request_id;

END;
$$ LANGUAGE 'plpgsql';