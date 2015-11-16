--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.estimates_in_waiting_for_approval(INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_house_id ALIAS FOR $1;
  number_estimates INTEGER;
BEGIN
  SELECT count(*) INTO number_estimates
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE arg_house_id= e.house_id
    AND e.estimate_requests_id= er.estimate_requests_id
    AND er.chosen_estimate IS NULL AND er.deadline> NOW();

  RETURN number_estimates;
END;
$$ LANGUAGE 'plpgsql';