DROP VIEW IF EXISTS marche_halibaba.valid_estimates_nbr;

CREATE VIEW marche_halibaba.valid_estimates_nbr AS
  SELECT h.house_id as "h_id", h.name as "h_name",
    count(e_id) as "h_valid_estimates_nbr"
  FROM marche_halibaba.houses h
    LEFT OUTER JOIN (
        SELECT e.estimate_id as "e_id", e.house_id as "e_house_id"
        FROM marche_halibaba.estimates e,
          marche_halibaba.estimate_requests er
        WHERE e.estimate_request_id = er.estimate_request_id AND
          e.is_cancelled = FALSE AND
          er.pub_date + INTERVAL '15' day >= NOW() AND
          er.chosen_estimate IS NULL) e
      ON h.house_id = e.e_house_id
  GROUP BY h.house_id, h.name;
