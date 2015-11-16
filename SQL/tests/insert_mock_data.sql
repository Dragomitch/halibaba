CREATE OR REPLACE FUNCTION marche_halibaba.insert_mock_data()
  RETURNS void AS $$
BEGIN;
  -- Creates houses
  SELECT marche_halibaba.signup_house('clegane', 'blublu', 'House Clegane');
  SELECT marche_halibaba.signup_house('hornwood', 'blublu', 'House Hornwoord');
  SELECT marche_halibaba.signup_house('cerwyn', 'blublu', 'House Cerwyn');

  -- Creates clients
  SELECT marche_halibaba.signup_client('jeremy', 'blublu', 'Jeremy', 'Wagemans');

  -- Creates estimate requests
  SELECT marche_halibaba.submit_estimate_request('Demande de devis 1', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  SELECT marche_halibaba.submit_estimate_request('Demande de devis 2', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  SELECT marche_halibaba.submit_estimate_request('Demande de devis 3', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  SELECT marche_halibaba.submit_estimate_request('Demande de devis 4', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

END;
$$ AS LANGUAGE plpgsql;
