-- Lists submitted estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er
WHERE er.pub_date + INTERVAL '15' day >= NOW() AND
  NOT EXISTS (
    SELECT *
    FROM marche_halibaba.estimates e
    WHERE e.estimate_request_id = er.estimate_request_id AND
      e.status = 'approved'
  )
GROUP BY er.estimate_request_id, er.description, er.deadline, er.pub_date
ORDER BY er.pub_date DESC

-- Lists approved estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
WHERE er.estimate_request_id = e.estimate_request_id AND
  e.status = 'approved' AND
  er.client_id = 1
GROUP BY er.estimate_request_id, er.description, er.deadline, er.pub_date
ORDER BY er.pub_date DESC

-- Lists expired estimate requests
SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date
FROM marche_halibaba.estimate_requests er
WHERE er.pub_date + INTERVAL '15' day < NOW() AND
  NOT EXISTS (
    SELECT *
    FROM marche_halibaba.estimates e
    WHERE e.estimate_request_id = er.estimate_request_id AND
      e.status = 'approved'
  )
ORDER BY er.pub_date DESC
