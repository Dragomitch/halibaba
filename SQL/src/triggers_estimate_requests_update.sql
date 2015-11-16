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
