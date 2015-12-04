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
