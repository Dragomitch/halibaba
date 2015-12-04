-- Insère des clients
SELECT marche_halibaba.signup_client('ramsey', 'blublu', 'Ramsey', 'GoT');

-- Insère des maisons
SELECT marche_halibaba.signup_house('starque', 'blublu', 'Starque');
SELECT marche_halibaba.signup_house('boltone', 'blublu', 'Boltone');

-- Insére une demande de devis
SELECT marche_halibaba.submit_estimate_request('Nettoyer mes toilettes', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);

-- Insère des devis

--
