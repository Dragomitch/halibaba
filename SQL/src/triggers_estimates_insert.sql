-- DEPRECATED
CREATE OR REPLACE FUNCTION marche_halibaba.trigger_estimates_insert()
  RETURNS TRIGGER AS $$

DECLARE
BEGIN
  UPDATE marche_halibaba.houses
    SET submitted_estimates_nbr = submitted_estimates_nbr + 1
    WHERE house_id = NEW.house_id;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

/**
CREATE TRIGGER trigger_estimates_insert
  AFTER INSERT on marche_halibaba.estimates
  FOR EACH ROW
  EXECUTE PROCEDURE marche_halibaba.trigger_estimates_insert();
**/
