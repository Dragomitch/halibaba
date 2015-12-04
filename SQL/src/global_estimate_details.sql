DROP VIEW IF EXISTS marche_halibaba.estimate_details;
CREATE VIEW marche_halibaba.estimate_details AS
  SELECT e.estimate_id as "e_id", e.description as "e_description",
    e.price as "e_price", e.is_cancelled as "e_is_cancelled",
    e.submission_date as "e_submission_date",
    h.house_id as "e_house_id", h.name as "e_house_name",
    o.option_id as "e_option_id", o.description as "e_option_description",
    eo.price as "e_option_price"
  FROM marche_halibaba.estimates e
    LEFT OUTER JOIN marche_halibaba.estimate_options eo
      ON e.estimate_id = eo.estimate_id
    LEFT OUTER JOIN marche_halibaba.options o
      ON eo.option_id = o.option_id,
    marche_halibaba.houses h
  WHERE e.house_id = h.house_id;
