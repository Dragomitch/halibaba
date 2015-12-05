-- Insère des clients
SELECT marche_halibaba.signup_client('ramsey', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Ramsey', 'GoT');

-- Insère des maisons
SELECT marche_halibaba.signup_house('starque', 'blublu', 'Starque');
SELECT marche_halibaba.signup_house('hornwood', 'blublu', 'House Hornwoord');

-- Inserts estimate requests
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Installation de superbe sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');
SELECT marche_halibaba.submit_estimate_request('Installation d incroyable sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

UPDATE marche_halibaba.estimate_requests
  SET pub_date = '2014-12-23'
  WHERE estimate_request_id = 2;

-- Inserts options
SELECT marche_halibaba.add_option('Toilettes en or', 6000, 1);
SELECT marche_halibaba.add_option('Toilettes en argent', 4000, 1);
SELECT marche_halibaba.add_option('Toilettes en bronze', 2000, 1);


-- Inserts estimates
SELECT marche_halibaba.submit_estimate('Super toilettes 1', 1600,FALSE, FALSE, 1, 1, '{1,2,3}');
SELECT marche_halibaba.submit_estimate('Super toilettes 2', 2000,FALSE, FALSE, 1, 1, '{}');
SELECT marche_halibaba.submit_estimate('Super toilettes 3', 3000,FALSE, FALSE, 1, 1, '{1,2,3}');

SELECT marche_halibaba.submit_estimate('Super 1', 400,FALSE, FALSE, 2, 1, '{}');
SELECT marche_halibaba.submit_estimate('Super 2', 600,FALSE, FALSE, 2, 1, '{}');
SELECT marche_halibaba.submit_estimate('Super 3', 800,FALSE, FALSE, 2, 1, '{}');

SELECT marche_halibaba.submit_estimate('Super bis 1', 800,FALSE, FALSE, 3, 1, '{}');
SELECT marche_halibaba.submit_estimate('Super bis 2', 1600, TRUE, FALSE, 3, 1, '{}');
SELECT marche_halibaba.submit_estimate('Super bis 3', 3200,FALSE, FALSE, 3, 1, '{}');

SELECT marche_halibaba.approve_estimate(1, '{}', 1);
