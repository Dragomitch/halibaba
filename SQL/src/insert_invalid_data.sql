-- Création d'un utilisateur client
-- Un utilisateur possède déjà un compte avec ce nom d'utilisateur
-- Aucun champs ne peut être vide
SELECT marche_halibaba.signup_client('dgrolaux', 'nb_iterations:salt:hash', 'Donatien', 'Grolaux');
SELECT marche_halibaba.signup_client('dgrolaux', 'nb_iterations:salt:hash', 'Petitrigolo', '123');
SELECT marche_halibaba.signup_client('Petitrigolo', 'nb_iterations:salt:hash', '', '');

-- Crée un utilisateur maison
SELECT marche_halibaba.signup_house('debouchetout', 'nb_iterations:salt:hash', 'Debouchetout Inc.');
SELECT marche_halibaba.signup_house('specialisteswc', 'nb_iterations:salt:hash', 'Les specialistes du WC');

-- Insertion d'une demandes de devis
-- La date souhaitée pour l'accomplissement des travaux doit être ultérieure à aujourd'hui
-- Aucun champs (à part l'adresse de facturation) ne peut être vide.
-- Le code postal doit être numérique
-- Une exception est levée.
SELECT marche_halibaba.submit_estimate_request('Installation de sanitaires VIP pour Mr. Grolaux', '2014-04-18', 1, 'Rue chapelle aux champs', '', 'ad', 'Bruxelles', null, null, null, null);

-- Insertion et modification des options
-- Aucun champs ne peut être vide
-- Le montant de l'option ne peut être négatif. Une exception est levée.
SELECT marche_halibaba.add_option('', 200, 1);
SELECT marche_halibaba.modify_option('Toualèt vere pom', -23.3, 1);

-- Insertion de devis
-- La description d'un devis ne peut être vide
-- Le montant d'un devis ne peut-être négatif. Une exception est levée.
SELECT marche_halibaba.submit_estimate('', 2000, FALSE, FALSE, 1, 1, '{}');
SELECT marche_halibaba.submit_estimate('', -1000, FALSE, FALSE, 1, 1, '{}');

-- Insertion d'un devis pour une demande de devis expirée
-- Pré-condition: la demande de devis est expirée. Une exception est levée.
SELECT marche_halibaba.submit_estimate('Toilettes VIP', 2000, FALSE, FALSE, 1, 1, '{}');

-- Insertion d'un devis pour une demande de devis pour laquelle un devis a déjà été accepté
-- Pré-condition: la demande de devis est expirée. Une exception est lancée.
SELECT marche_halibaba.submit_estimate('Toilettes VIP', 2000, FALSE, FALSE, 1, 1, '{}');

-- Insertion d'un devis avec option
-- Pré-condition: la maison soumissionnaire n'a pas d'option disponible
-- L'option en argument n'existe pas/la maison soumissionnaire ne possède pas cette option. Une exception est levée.
SELECT marche_halibaba.submit_estimate('Toilettes VIP', 2000, FALSE, FALSE, 1, 1, '{1}');

-- Insertion d'un devis caché
-- Pré-condition: la maison soumissionnaire a soumis un devis caché il y a moins de 24 heures
SELECT marche_halibaba.submit_estimate('Premier devis caché', 1600, TRUE, FALSE, 1, 1, '{}');
-- La maison ne peut plus poster de devis caché pendant 24h. Une exception est levée.
SELECT marche_halibaba.submit_estimate('Deuxième devis caché', 1600, TRUE, FALSE, 1, 1, '{}');

-- Insertion d'un devis masquant
-- Pré-condition: la maison soumissionnaire a soumis un devis masquant il y a moins de 7 jours
SELECT marche_halibaba.submit_estimate('Premier devis masquant', 1600, FALSE, TRUE, 1, 1, '{}');
-- La maison ne peut plus poster de devis masquant pendant 7 jours. Une exception est levée.
SELECT marche_halibaba.submit_estimate('Deuxième devis masquant', 1600, FALSE, TRUE, 1, 1, '{}');

-- Insertion d'un devis par une maison dénoncée
-- Pré-condition: une maison a soumis un devis masquant pour une demande possédant déjà un devis masquant
SELECT marche_halibaba.submit_estimate('Devis dénoncé.', 1600, FALSE, TRUE, 1, 1, '{}');
SELECT marche_halibaba.submit_estimate('Devis dénonceur.', 1600, FALSE, TRUE, 1, 2, '{}');
-- La maison dénoncée ne peut plus soumettre de devis pendant 24 heures. Une exception est levée.
SELECT marche_halibaba.submit_estimate('Nouveau devis', 600, FALSE, FALSE, 1, 1, '{}');

-- Accepter un devis pour une demande de devis expirée
-- Pré-condition: la demande de devis est expirée
-- Le devis ne peut être accepté. Une exception est levée.
SELECT marche_halibaba.approve_estimate(1, '{}', 1);

-- Accepter un devis lié à une demande pour laquelle un devis a déjà été accepté
-- Pré-condition: un devis pour la demande a déjà été accepté
-- Le devis ne peut être accepté. Une exception est levée.
SELECT marche_halibaba.approve_estimate(1, '{}', 1);

-- Accepter un devis annulé à cause d'une maison dénoncée
-- Pré-condition: le devis accepté
-- Le devis ne peut être accepté. Une exception est levée.
SELECT marche_halibaba.approve_estimate(1, '{}', 1);

-- Accepter un devis avec une option inexistante
-- Pré-condition: le devis n'offre aucune option
-- Le devis est accepté. L'option demandée est ignorée.
SELECT marche_halibaba.approve_estimate(1, '{1}', 1);
