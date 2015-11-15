-- Estimate details
SELECT e.estimate_id, e.description, e.price, e.submission_date, h.house_id, h.name
FROM marche_halibaba.estimates e, marche_halibaba.houses h
WHERE e.house_id = h.house_id AND
  e.estimate_id = 1

-- Estimate options
SELECT eo.options_id, o.description, eo.price, eo.is_chosen
FROM marche_halibaba.options o, marche_halibaba.estimate_options eo
WHERE o.option_id = eo.option_id AND
  eo.estimate_id = 1
