CREATE OR REPLACE FUNCTION marche_halibaba.submit_estimate_request(TEXT, DATE, INTEGER, VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35), VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_description ALIAS FOR $1;
  arg_deadline ALIAS FOR $2;
  arg_client ALIAS FOR $3;
  arg_cons_street_name ALIAS FOR $4;
  arg_cons_street_nbr ALIAS FOR $5;
  arg_cons_zip_code ALIAS FOR $6;
  arg_cons_city ALIAS FOR $7;
  arg_inv_street_name ALIAS FOR $8;
  arg_inv_street_nbr ALIAS FOR $9;
  arg_inv_zip_code ALIAS FOR $10;
  arg_inv_city ALIAS FOR $11;
  new_construction_address_id INTEGER;
  new_invoicing_address_id INTEGER;
  new_estimate_request_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.addresses(street_name, street_number, zip_code, city)
    VALUES (arg_cons_street_name, arg_cons_street_nbr, arg_cons_zip_code, arg_cons_city)
    RETURNING address_id INTO new_construction_address_id;

  new_invoicing_address_id := NULL;

  IF arg_inv_street_name IS NOT NULL AND
    arg_inv_street_nbr IS NOT NULL AND
    arg_inv_zip_code IS NOT NULL AND
    arg_inv_city IS NOT NULL THEN

    INSERT INTO marche_halibaba.addresses(street_name, street_number, zip_code, city)
      VALUES (arg_inv_street_name, arg_inv_street_nbr, arg_inv_zip_code, arg_inv_city)
      RETURNING address_id INTO new_invoicing_address_id;

  END IF;

  INSERT INTO marche_halibaba.estimate_requests(description, construction_address, invoicing_address, deadline, client_id)
    VALUES (arg_description, new_construction_address_id, new_invoicing_address_id, arg_deadline, arg_client)
    RETURNING estimate_request_id INTO new_estimate_request_id;

  RETURN new_estimate_request_id;
END;
$$ LANGUAGE plpgsql;
