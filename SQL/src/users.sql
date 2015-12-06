/* DEV ENVIRONMENT */
/*
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
TO app;*/

/* Clients app user */

DROP USER IF EXISTS app_clients;

CREATE USER app_clients
ENCRYPTED PASSWORD '2S5jn12JndG68hT';

GRANT USAGE
ON SCHEMA marche_halibaba
TO app_clients;

GRANT SELECT
ON marche_halibaba.clients_list_estimates,
  marche_halibaba.estimate_details,
  marche_halibaba.list_estimate_requests,
  marche_halibaba.signin_users,
  marche_halibaba.houses,
  marche_halibaba.estimates,
  marche_halibaba.options
TO app_clients;

GRANT SELECT, INSERT
ON marche_halibaba.users,
  marche_halibaba.clients,
  marche_halibaba.estimate_requests,
  marche_halibaba.addresses
TO app_clients;

GRANT SELECT, UPDATE, TRIGGER
ON marche_halibaba.estimate_requests,
  marche_halibaba.estimate_options,
  marche_halibaba.houses
TO app_clients;

GRANT EXECUTE
ON FUNCTION marche_halibaba.approve_estimate(INTEGER, INTEGER[], INTEGER),
  marche_halibaba.signup_client(VARCHAR(35), VARCHAR(50), VARCHAR(35), VARCHAR(35)),
  marche_halibaba.submit_estimate_request(TEXT, DATE, INTEGER, VARCHAR(50),
    VARCHAR(8), VARCHAR(5), VARCHAR(35), VARCHAR(50), VARCHAR(8), VARCHAR(5), VARCHAR(35)),
  marche_halibaba.trigger_estimate_requests_update(),
  marche_halibaba.trigger_estimate_options_update()
TO app_clients;

GRANT ALL PRIVILEGES
ON ALL SEQUENCES IN SCHEMA marche_halibaba
TO app_clients;

/* Clients app user */

DROP USER IF EXISTS app_houses;

CREATE USER app_houses
ENCRYPTED PASSWORD '2S5jn12JndG68hT';

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
