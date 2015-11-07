-- Inserts clients
SELECT marche_halibaba.signup_client('jeremy', 'blublu', 'Jeremy', 'Wagemans');
SELECT marche_halibaba.signup_client('philippe', 'blublu', 'Philippe', 'Dragomir');

-- Inserts estimate requests
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
SELECT marche_halibaba.submit_estimate_request('Installation de nouveaux sanitaires', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

UPDATE marche_halibaba.estimate_requests
  SET pub_date = '2014-12-23'
  WHERE estimate_request_id = 2;

-- Inserts houses (temporary)
INSERT INTO marche_halibaba.houses(name, user_id)
  VALUES ('Blaaaaa', 2);

-- Inserts estimates (temporary)
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super toilettes 6000', 1600, 1, 1);

INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 1', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 2', 1600, 2, 1);
INSERT INTO marche_halibaba.estimates(description, price, estimate_request_id, house_id)
  VALUES ('Super 3', 1600, 2, 1);

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
