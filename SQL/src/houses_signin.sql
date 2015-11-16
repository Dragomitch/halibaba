SELECT u.username, h.house_id, h.name
FROM marche_halibaba.users u, marche_halibaba.houses h
WHERE u.user_id = h.user_id AND
  u.username = 'philippe' AND
  u.pswd = 'blublu'
