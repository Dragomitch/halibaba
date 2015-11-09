-- Turnover
SELECT h.house_id, h.name, h.turnover
  FROM marche_halibaba.houses h
  ORDER BY h.turnover DESC, h.name ASC

-- Acceptance rate
SELECT h.house_id, h.name, h.acceptance_rate
  FROM marche_halibaba.houses h
  ORDER BY h.acceptance_rate DESC, h.name ASC

-- Number of times houses have heen caught cheating
SELECT h.house_id, h.name, h.caught_cheating_nbr
  FROM marche_halibaba.houses h
  ORDER BY h.caught_cheating_nbr DESC, h.name ASC

-- Number of times houses have caught a cheater
SELECT h.house_id, h.name, h.caught_cheater_nbr
  FROM marche_halibaba.houses h
  ORDER BY h.caught_cheater_nbr DESC, h.name ASC

-- House details
SELECT h.house_id, h.name, h.turnover, h.acceptance_rate,
    h.caught_cheating_nbr, h.caught_cheater_nbr
  FROM marche_halibaba.houses h
  WHERE h.house_id = 1
