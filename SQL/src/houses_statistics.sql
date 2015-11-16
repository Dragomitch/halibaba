SELECT count(estimate_id)
FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
WHERE e.estimate_request_id = er.estimate_request_id AND
  e.is_cancelled = FALSE AND
  er.pub_date + INTERVAL '15' day >= NOW() AND
  er.chosen_estimate IS NULL AND
  e.house_id = 1
