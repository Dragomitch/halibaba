CREATE OR REPLACE VIEW marche_halibaba.valid_estimates AS
  SELECT e.estimate_id AS "ID Devis", e.description AS "Description", e.price AS "Prix",
    er.estimate_request_id AS "Request ID", er.deadline AS "Limite de Soumission",
    er.description AS "Description de la Requete"
  FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
  WHERE e.estimate_request_id= er.estimate_request_id
    AND er.deadline> NOW() AND e.is_secret= FALSE
    AND e.is_cancelled= FALSE AND er.chosen_estimate IS NULL
  ORDER BY e.estimate_id;

--Comment introduire la house en paramètre pour afficher ses devis secrets?
--Adresse(s) ?
--Utilisation d’une vue → toute les demandes de devis non périmées (pub_date + 15 jours > now()) et dont aucun devis n’a encore été accepté.