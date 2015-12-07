CREATE OR REPLACE FUNCTION marche_halibaba.modify_option(TEXT, NUMERIC(12,2), INTEGER, INTEGER)
  RETURNS INTEGER AS $$

DECLARE
  arg_description ALIAS FOR $1;
  arg_price ALIAS FOR $2;
  arg_option_id ALIAS FOR $3;
  arg_house_id ALIAS FOR $4;
BEGIN
  UPDATE marche_halibaba.options
  SET description= arg_description, price= arg_price
  WHERE arg_option_id= option_id
  	AND arg_house_id= house_id;
RETURN arg_option_id;
END;
$$ LANGUAGE 'plpgsql';