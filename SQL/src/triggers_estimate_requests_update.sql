CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimate_requests_update()
  RETURNS TRIGGER AS $$

DECLARE
  estimate_details RECORD;
  approved_estimates_nbr NUMERIC(16,2);
  estimates_nbr NUMERIC(16,2);
BEGIN
  SELECT e.estimate_request_id as "estimate_request_id",
    e.is_cancelled as "is_cancelled", (er.pub_date + INTERVAL '15' day) as "expiration_date",
    e.price as "price",
    e.house_id as "house_id"
  INTO estimate_details
  FROM marche_halibaba.estimates e
  WHERE e.estimate_request_id = OLD.estimate_request_id AND -- Sert à vérifier que le devis est bien lié à cette demande de devis
    e.estimate_id = NEW.chosen_estimate;

  IF estimate_details IS NULL THEN
    RAISE EXCEPTION 'Ce devis n appartient pas à cette demande de devis';
  END IF;

  -- An exception is raised if a estimate has already been approved for this estimate request
  IF OLD.chosen_estimate IS NOT NULL THEN
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

  -- Updates house statistics
  SELECT count(estimate_id)
  INTO approved_estimates_nbr
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE e.estimate_id = er.chosen_estimate AND
    e.house_id = estimate_details.house_id;

  SELECT count(estimate_id)
  INTO estimates_nbr
  FROM marche_halibaba.estimates e
  WHERE e.house_id = estimate_details.house_id;

  UPDATE marche_halibaba.houses
  SET turnover = turnover + estimate_details.price,
    acceptance_rate = approved_estimates_nbr/estimates_nbr
  WHERE house_id = approved_estimate_house_id;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimate_requests_update
BEFORE UPDATE on marche_halibaba.estimate_requests
FOR EACH ROW
WHEN (OLD.chosen_estimate IS NULL AND NEW.chosen_estimate IS NOT NULL)
EXECUTE PROCEDURE marche_halibaba.trigger_estimate_requests_update();
