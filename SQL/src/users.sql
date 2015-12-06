/* DEV ENVIRONMENT */

DROP USER IF EXISTS app;

CREATE USER app
ENCRYPTED PASSWORD '2S5jn12JndG68hT';

GRANT ALL PRIVILEGES
ON ALL TABLES IN SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON ALL FUNCTIONS IN SCHEMA marche_halibaba
TO app;

GRANT ALL PRIVILEGES
ON ALL VIEWS IN SCHEMA marche_halibaba
TO app;

GRANT SELECT ON marche_halibaba.valid_estimates_list 
TO app;

GRANT SELECT ON marche_halibaba.submitted_requests
TO app;

GRANT SELECT ON marche_halibaba.valid_estimates_nbr
TO app;

/* PROD ENVIRONMENT

GRANT CONNECT
ON DATABASE dbjwagema15
TO pdragom15;

GRANT SELECT
ON ALL TABLES IN SCHEMA marche_halibaba
TO pdragom15;

--GRANT INSERT
--ON TABLE users, clients, estimate_requests, addresses

--GRANT UPDATE
--ON estimate_options, estimate_requests

GRANT ALL PRIVILEGES
ON SCHEMA marche_halibaba
TO pdragom15;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO pdragom15;

GRANT EXECUTE
ON ALL FUNCTIONS IN SCHEMA marche_halibaba
TO pdragom15; */
