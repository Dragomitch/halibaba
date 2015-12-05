CREATE OR REPLACE FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[], INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  arg_client_id ALIAS FOR $3;
  er_id INTEGER;
  er_client_id INTEGER;
  option INTEGER;
BEGIN
  SELECT e.estimate_request_id, er.client_id
  INTO er_id, er_client_id
  FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
  WHERE e.estimate_request_id = er.estimate_request_id AND
    e.estimate_id = arg_estimate_id;

  IF er_client_id <> arg_client_id THEN
    RAISE EXCEPTION 'Vous n etes pas autorise a accepter ce devis';
  END IF;

  UPDATE marche_halibaba.estimate_requests er
  SET chosen_estimate = arg_estimate_id
  WHERE estimate_request_id = er_id;

  IF arg_chosen_options IS NOT NULL THEN
    FOREACH option IN ARRAY arg_chosen_options
    LOOP
      UPDATE marche_halibaba.estimate_options
      SET is_chosen = TRUE
      WHERE option_id = option AND
        estimate_id = arg_estimate_id;
    END LOOP;
  END IF;

  RETURN 0;
END;
$$ LANGUAGE 'plpgsql';
