CREATE OR REPLACE FUNCTION marche_halibaba.signup_client(VARCHAR(35), VARCHAR(50), VARCHAR(35), VARCHAR(35))
  RETURNS INTEGER AS $$
DECLARE
  arg_username ALIAS FOR $1;
  arg_pswd ALIAS FOR $2;
  arg_last_name ALIAS FOR $3;
  arg_first_name ALIAS FOR $4;
  new_user_id INTEGER;
  new_client_id INTEGER;
BEGIN
  INSERT INTO marche_halibaba.users(username, pswd)
    VALUES (arg_username, arg_pswd)
    RETURNING user_id INTO new_user_id;

  INSERT INTO marche_halibaba.clients(last_name, first_name, user_id)
    VALUES (arg_last_name, arg_first_name, new_user_id)
    RETURNING client_id INTO new_client_id;
  RETURN new_client_id;
END;
$$ LANGUAGE 'plpgsql';
