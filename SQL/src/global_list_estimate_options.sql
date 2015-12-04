DROP VIEW IF EXISTS marche_halibaba.list_estimate_options;

CREATE VIEW marche_halibaba.list_estimate_options AS
  SELECT o.option_id as "o_id", eo.estimate_id as "e_id",
    o.description as "o_description", eo.price as "eo_price"
  FROM marche_halibaba.estimate_options eo, marche_halibaba.options o
  WHERE eo.option_id = o.option_id;
