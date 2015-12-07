-- Afficher les utilisateurs

DROP VIEW IF EXISTS marche_halibaba.signin_users;

CREATE VIEW marche_halibaba.signin_users AS
  SELECT u.username as "u_username", u.pswd as "u_pswd", c.client_id as "c_id",
    c.first_name as "c_first_name", c.last_name as "c_last_name",
      h.house_id as "h_id", h.name as "h_name"
  FROM marche_halibaba.users u
    LEFT OUTER JOIN marche_halibaba.clients c
      ON u.user_id = c.user_id
    LEFT OUTER JOIN marche_halibaba.houses h
      ON u.user_id = h.user_id;
