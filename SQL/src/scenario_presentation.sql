-- Insère des clients
SELECT marche_halibaba.signup_client('ramsey', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Ramsey', 'GoT');
SELECT marche_halibaba.submit_estimate_request('Nettoyer mes toilettes', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);

SELECT marche_halibaba.signup_house('starque', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Starque');
SELECT marche_halibaba.add_option('Avec le sourire', 50, 1);
SELECT marche_halibaba.submit_estimate('nettoyage', 100, FALSE, FALSE, 1, 1, '{1}');

SELECT marche_halibaba.signup_house('boltone', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Boltone');
SELECT marche_halibaba.submit_estimate('nettoyage, sourire compris', 90, TRUE, FALSE, 1, 2, '{}');


SELECT marche_halibaba.submit_estimate('99€ promo de Noël : nettoyage sans râler', 99, FALSE, TRUE, 1, 1, '{}');
SELECT marche_halibaba.submit_estimate('80€ sans sourire', 80, FALSE, TRUE, 1, 2, '{}');
SELECT marche_halibaba.submit_estimate('test 123', 10000, FALSE, FALSE, 1, 1, '{1}');

SELECT marche_halibaba.approve_estimate(4, '{}',1);
