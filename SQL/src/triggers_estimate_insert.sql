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
  WHERE er.estimate_request_id = NEW.estimate_request_id AND
    (er.pub_date + INTERVAL '15' day < NOW() OR er.chosen_estimate IS NOT NULL)
  ) THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée/un devis a déjà été accepté pour cette demande.';
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
