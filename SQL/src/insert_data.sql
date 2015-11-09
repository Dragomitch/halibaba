-- Inserts clients
SELECT marche_halibaba.signup_client('jeremy', 'blublu', 'Jeremy', 'Wagemans');

-- Inserts houses
SELECT marche_halibaba.signup_house('philippe', 'blublu', 'Noble House');

-- Inserts estimate requests
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Installation de superbe sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');
SELECT marche_halibaba.submit_estimate_request('Installation d incroyable sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

UPDATE marche_halibaba.estimate_requests
  SET pub_date = '2014-12-23'
  WHERE estimate_request_id = 2;

-- Inserts estimates (temporary)
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 1', 1600, 1, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 2', 1600, 1, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 3', 1600, 1, 1);

INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 1', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 2', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 3', 1600, 2, 1);

INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super bis 1', 1600, 3, 1);
INSERT INTO marche_halibaba.estimates(description, price, is_hiding, estimate_request_id, house_id)
  VALUES ('Super bis 2', 1600, TRUE, 3, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super bis 3', 1600, 3, 1);

-- Inserts options (temporary)
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en or', 6000, 1);
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en argent', 4000, 1);
INSERT INTO marche_halibaba.options(description, price, house_id)
  VALUES ('Toilettes en bronze', 2000, 1);

-- Inserts estimate options (temporary)
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (6000, 1, 1);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (4000, 1, 2);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (2000, 1, 3);

INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (6000, 3, 1);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (4000, 3, 2);
INSERT INTO marche_halibaba.estimate_options(price, estimate_id, option_id)
  VALUES (2000, 3, 3);

-- Approves estimate 1 (temporary)
SELECT marche_halibaba.approve_estimate(1, '{1,2}');

SELECT * FROM marche_halibaba.list_estimates_for(1);
