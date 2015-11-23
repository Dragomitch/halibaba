DROP VIEW IF EXISTS marche_halibaba.valid_estimates_nbr;
CREATE VIEW marche_halibaba.valid_estimates_nbr AS
  SELECT h.house_id as "h_id", h.name as "h_name",
    count(e.estimate_id) as "h_valid_estimates_nbr"
  FROM marche_halibaba.houses h
    LEFT OUTER JOIN marche_halibaba.estimates e
      ON h.house_id = e.house_id AND
        e.is_cancelled = FALSE
    LEFT OUTER JOIN marche_halibaba.estimate_requests er
      ON e.estimate_request_id = er.estimate_request_id AND
        er.pub_date + INTERVAL '15' day >= NOW() AND
        er.chosen_estimate IS NULL
  GROUP BY h.house_id, h.name;
