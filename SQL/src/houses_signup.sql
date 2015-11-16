CREATE OR REPLACE FUNCTION marche_halibaba.signup_house(VARCHAR(35), VARCHAR(50), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_username ALIAS FOR $1;
  arg_pswd ALIAS FOR $2;
  arg_name ALIAS FOR $3;
  new_user_id INTEGER;
  new_house_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.users(username, pswd)
    VALUES (arg_username, arg_pswd) RETURNING user_id INTO new_user_id;

  INSERT INTO marche_halibaba.houses(name, user_id)
    VALUES (arg_name, new_user_id) RETURNING house_id INTO new_house_id;
  RETURN new_house_id;
END;
$$ LANGUAGE 'plpgsql';
