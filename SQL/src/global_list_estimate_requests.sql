-- Afficher les demandes de devis
DROP VIEW IF EXISTS marche_halibaba.list_estimate_requests;

CREATE VIEW marche_halibaba.list_estimate_requests AS
  SELECT er.estimate_request_id AS "er_id",
    er.description AS "er_description",
    er.deadline AS "er_deadline",
    er.pub_date AS "er_pub_date",
    er.chosen_estimate AS "er_chosen_estimate",
    a.street_name AS "er_construction_id",
    a.zip_code AS "er_construction_zip",
    a.city AS "er_construction_city",
    a2.street_name AS "er_invoicing_street",
    a2.zip_code AS "er_invoicing_zip",
    a2.city AS "er_invoicing_city",
    c.client_id AS "c_id",
    c.last_name AS "c_last_name",
    c.first_name AS "c_first_name",
    AGE(er.pub_date + INTERVAL '15' day, NOW()) AS "remaining_days"
  FROM marche_halibaba.clients c, marche_halibaba.addresses a, marche_halibaba.estimate_requests er
    LEFT OUTER JOIN marche_halibaba.addresses a2 ON er.invoicing_address = a2.address_id
  WHERE a.address_id = er.construction_address
    AND c.client_id = er.client_id
  ORDER BY er.pub_date DESC;
