UPDATE marche_halibaba.estimates
  SET status = 'expired'
  WHERE estimate_id IN (
    SELECT e.estimate_id
      FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
      WHERE e.estimate_request_id = er.estimate_request_id AND
        er.pub_date + INTERVAL '15 days' < NOW() AND
        e.status = 'submitted' AND
        NOT EXISTS (
          SELECT *
            FROM marche_halibaba.estimates e2
            WHERE e2.estimate_request_id = e.estimate_request_id AND
              e2.status = 'approved'
));
