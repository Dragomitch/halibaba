-- Lists submitted estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er
WHERE er.pub_date + INTERVAL '15' day >= NOW() AND
  er.chosen_estimate IS NULL AND
  er.client_id = 1
GROUP BY er.estimate_request_id, er.description, er.deadline, er.pub_date
ORDER BY er.pub_date DESC

-- Lists approved estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er
WHERE er.chosen_estimate IS NOT NULL AND
  er.client_id = 1
GROUP BY er.estimate_request_id, er.description, er.deadline, er.pub_date
ORDER BY er.pub_date DESC

-- Lists expired estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er
WHERE er.pub_date + INTERVAL '15' day < NOW() AND
  er.chosen_estimate IS NULL AND
  er.client_id = 1
ORDER BY er.pub_date DESC
