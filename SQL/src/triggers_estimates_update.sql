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
BEFORE UPDATE on marche_halibaba.estimates
FOR EACH ROW
WHEN NEW.chosen_estimate IS NOT NULL
EXECUTE PROCEDURE marche_halibaba.trigger_estimates_update();
