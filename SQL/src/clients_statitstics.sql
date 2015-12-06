-- House details
SELECT h.house_id, h.name, h.turnover, h.acceptance_rate,
    h.caught_cheating_nbr, h.caught_cheater_nbr
  FROM marche_halibaba.houses h
  WHERE h.house_id = 1
