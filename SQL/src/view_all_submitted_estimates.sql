-- Afficher les devis en cours de soumission par les maisons
-- Exemple d'exécution:
-- SELECT *
-- FROM marche_halibaba.valid_estimates_list
-- WHERE er_estimate_request_id = ? AND
--  (e_is_secret= FALSE OR (e_is_secret = TRUE AND e_house_id= ?));

DROP VIEW IF EXISTS marche_halibaba.valid_estimates_list;

CREATE VIEW marche_halibaba.valid_estimates_list AS
  SELECT e.estimate_id AS "e_estimate_id",
         e.description AS "e_description",
         e.price AS "e_price",
         e.house_id AS "e_house_id",
         e.submission_date AS "e_submission_date",
         e.is_secret AS "e_is_secret",
         er.estimate_request_id AS "er_estimate_request_id",
         er.deadline AS "er_deadline",
         er.description AS "er_description",
         h.name AS "h_name"
  FROM marche_halibaba.estimates e,
    marche_halibaba.estimate_requests er,
    marche_halibaba.houses h
  WHERE e.estimate_request_id= er.estimate_request_id
    AND e.house_id = h.house_id
    AND er.pub_date + INTERVAL '15' day > NOW()
    AND e.is_cancelled = FALSE
    AND er.chosen_estimate IS NULL
  ORDER BY e.submission_date DESC;
