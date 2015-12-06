-- Crée un utilisateur client
SELECT marche_halibaba.signup_client('dgrolaux', 'nb_iterations:salt:hash', 'Donatien', 'Grolaux');

-- Crée un utilisateur maison
SELECT marche_halibaba.signup_house('debouchetout', 'nb_iterations:salt:hash', 'Debouchetout Inc.');
SELECT marche_halibaba.signup_house('specialisteswc', 'nb_iterations:salt:hash', 'Les specialistes du WC');

-- Insère des demandes de devis
SELECT marche_halibaba.submit_estimate_request('Installation de sanitaires VIP pour Mr. Grolaux', '2016-04-18', 1, 'Rue chapelle aux champs', '43', '1200', 'Bruxelles', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Nettoyage des toilettes des étudiants', '2016-05-31', 1, 'Rue chapelle aux champs', '43', '1200', 'Bruxelles', 'Alma', '2', '1200', 'Bruxelles');

-- Insère des options
SELECT marche_halibaba.add_option('Toilettes en or massif', 6000, 1);
SELECT marche_halibaba.add_option('Toualèt vere pom', 1000, 1);
SELECT marche_halibaba.add_option('Toilettes en bronze', 2000, 2);

-- On modifie une option
SELECT marche_halibaba.modify_option('Toilettes vertes pomme', 1000, 2); -- pas très fort en orthographe ce nouveau stagiaire ;)

-- Insère des devis

-- Devis sans option
SELECT marche_halibaba.submit_estimate('Toilettes VIP', 2000, FALSE, FALSE, 1, 1, '{}');

-- Devis avec options
SELECT marche_halibaba.submit_estimate('Toilettes confortables', 1600, FALSE, FALSE, 1, 1, '{1,2}');

-- Devis masquant
SELECT marche_halibaba.submit_estimate('Nettoyage au Karcher', 400, FALSE, TRUE, 2, 2, '{}');

-- Devis caché
SELECT marche_halibaba.submit_estimate('Nettoyage avec Cillit Bang', 600, TRUE, FALSE, 2, 2, '{}');

-- Devis masquant et caché
SELECT marche_halibaba.submit_estimate('Toilettes révolutionnaires', 800, TRUE, TRUE, 1, 1, '{}');

-- Accepter un devis sans option
SELECT marche_halibaba.approve_estimate(4, '{}', 1);

-- Accepter un devis avec option
SELECT marche_halibaba.approve_estimate(2, '{1}', 1);
