-- DEPRECATED
CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimates_update()
  RETURNS TRIGGER AS $$

DECLARE
  approved_estimates_nbr NUMERIC(16,2);
  estimates_nbr NUMERIC(16,2);
BEGIN

  IF OLD.status = 'submitted' AND NEW.status = 'approved' THEN
    SELECT count(estimate_id)
      INTO approved_estimates_nbr
      FROM marche_halibaba.estimates
      WHERE status = 'approved' AND
        house_id = OLD.house_id;

    SELECT count(estimate_id)
      INTO estimates_nbr
      FROM marche_halibaba.estimates
      WHERE house_id = OLD.house_id;

    -- Updates house statistics
    UPDATE marche_halibaba.houses
      SET turnover = turnover + OLD.price,
        acceptance_rate = approved_estimates_nbr/estimates_nbr,
        /** DEPRECATED
        submitted_estimates_nbr = submitted_estimates_nbr - 1
        **/
      WHERE house_id = OLD.house_id;
  /** DEPRECATED
  ELSIF OLD.status = 'submitted' AND NEW.status <> 'approved' THEN
    UPDATE marche_halibaba.houses
      SET submitted_estimates_nbr = submitted_estimates_nbr - 1
      WHERE house_id = OLD.house_id;
  **/
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE 'plpgsql';

CREATE TRIGGER trigger_estimates_update
  AFTER UPDATE on marche_halibaba.estimates
  FOR EACH ROW
  WHEN (OLD.status IS DISTINCT FROM NEW.status)
  EXECUTE PROCEDURE marche_halibaba.trigger_estimates_update();
