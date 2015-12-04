CREATE OR REPLACE FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  option INTEGER;
BEGIN
  UPDATE marche_halibaba.estimate_requests
  SET chosen_estimate = arg_estimate_id
  WHERE estimate_request_id = estimate_details.estimate_request_id;

  IF arg_chosen_options IS NULL THEN
    RETURN 0;
  END IF;

  FOREACH option IN ARRAY arg_chosen_options
  LOOP
    UPDATE marche_halibaba.estimate_options
    SET is_chosen = TRUE
    WHERE option_id = option AND
      estimate_id = arg_estimate_id;
  END LOOP;

  RETURN 0;
END;
$$ LANGUAGE 'plpgsql';
