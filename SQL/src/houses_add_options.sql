--Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.add_option(TEXT, NUMERIC(12,2), INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_house_id ALIAS FOR $3;
  new_option_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.options(description, price, house_id) VALUES (arg_description, arg_price, arg_house_id) RETURNING option_id INTO new_option_id;
  RETURN new_option_id;
END;
$$ LANGUAGE 'plpgsql';