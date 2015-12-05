CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate(TEXT, NUMERIC(12,2), BOOLEAN, BOOLEAN, INTEGER, INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_is_secret ALIAS FOR $3;
  arg_is_hiding ALIAS FOR $4;
  arg_estimate_request_id ALIAS FOR $5;
  arg_house_id ALIAS FOR $6;
  arg_chosen_options ALIAS FOR $7;
  new_estimate_request_id INTEGER;
  nbr_chosen_options INTEGER := array_upper(arg_chosen_options::int[], 1);
  option_price NUMERIC(12,2);
BEGIN
  INSERT INTO marche_halibaba.estimates(description, price, is_secret, is_hiding, submission_date, estimate_request_id, house_id)
  VALUES (arg_description, arg_price, arg_is_secret, arg_is_hiding, NOW(), arg_estimate_request_id, arg_house_id)
    RETURNING estimate_id INTO new_estimate_request_id;

  IF nbr_chosen_options IS NOT NULL -- If there are options selected
  THEN
    FOR i IN 1 .. nbr_chosen_options
    LOOP
      SELECT o.price INTO option_price
      FROM marche_halibaba.options o
      WHERE o.option_id= arg_chosen_options[i];

      INSERT INTO marche_halibaba.estimate_options
      VALUES (option_price, FALSE, new_estimate_request_id , arg_chosen_options[i]);
    END LOOP;
  END IF;

  RETURN new_estimate_request_id;

END;
$$ LANGUAGE 'plpgsql';