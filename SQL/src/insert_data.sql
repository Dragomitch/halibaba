-- Inserts clients
SELECT marche_halibaba.signup_client('jeremy', 'blublu', 'Jeremy', 'Wagemans');
SELECT marche_halibaba.signup_client('philippe', 'blublu', 'Philippe', 'Dragomir');

-- Inserts estimate requests
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');
