DROP VIEW IF EXISTS marche_halibaba.signin_client;
CREATE VIEW marche_halibaba.signin_client AS
  SELECT c.client_id as "c_id", c.first_name as "c_first_name", c.last_name as "c_last_name",
    u.username as "c_username", u.pswd as "c_pswd"
  FROM marche_halibaba.users u, marche_halibaba.clients c
  WHERE u.user_id = c.user_id;
