DROP VIEW IF EXISTS marche_halibaba.submitted_requests;

CREATE VIEW marche_halibaba.submitted_requests AS
  SELECT er.estimate_request_id AS "er_id", er.description AS "er_description",
    a.street_name AS "er_construction_id",
    a.zip_code AS "er_construction_zip",
    a.city AS "er_construction_city",
    er.deadline AS "er_deadline",
    er.pub_date AS "er_publish_date",
    a2.street_name AS "er_invoicing_street",
    a2.zip_code AS "er_invoicing_zip",
    a2.city AS "er_invoicing_city",
    c.client_id AS "er_client_id",
    c.last_name AS "er_client_last_name",
    c.first_name AS "er_client_first_name",
    c.user_id AS "client_user_id"
  FROM marche_halibaba.clients c, marche_halibaba.addresses a, marche_halibaba.estimate_requests er
    LEFT OUTER JOIN marche_halibaba.addresses a2 ON er.invoicing_address= a2.address_id
  WHERE a.address_id=er.construction_address AND er.pub_date< NOW()+ INTERVAL '15' day
    AND chosen_estimate IS NULL AND c.client_id= er.client_id
  ORDER BY er.pub_date;
