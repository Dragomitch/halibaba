SELECT u.username, c.first_name, c.last_name
FROM marche_halibaba.users u, marche_halibaba.clients c
WHERE u.user_id = c.user_id AND
  u.username = 'jeremy' AND
  u.pswd = MD5('blublu')
