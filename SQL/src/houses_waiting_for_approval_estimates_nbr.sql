--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.waiting_for_approval_estimates_nbr(INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_house_id ALIAS FOR $1;
  number_estimates INTEGER;
BEGIN
  SELECT count(estimate_id)
  INTO number_estimates
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE e.estimate_request_id = er.estimate_request_id AND
    e.is_cancelled = FALSE AND
    er.pub_date + INTERVAL '15' day >= NOW() AND
    er.chosen_estimate IS NULL AND
    e.house_id = arg_house_id;
  RETURN number_estimates;
END;
$$ LANGUAGE 'plpgsql';
