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
