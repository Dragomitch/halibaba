CREATE OR REPLACE FUNCTION marche_halibaba.insert_mock_data()
  RETURNS void AS $$
BEGIN
  -- Creates houses
  PERFORM marche_halibaba.signup_house('clegane', 'blublu', 'House Clegane');
  PERFORM marche_halibaba.signup_house('hornwood', 'blublu', 'House Hornwoord');
  PERFORM marche_halibaba.signup_house('cerwyn', 'blublu', 'House Cerwyn');

  -- Creates clients
  PERFORM marche_halibaba.signup_client('jeremy', '1000:8390b08bda9aaa174c8a7d839940c3831c1f72e1476909f6:c13365b0ef62f82f9ba702b1c3ecbe4ddbfb511b40757bacf7068d7bfc7b2691fa36ef9e246845f0fd3737f0d95da3cbbc9478e488fc1ed91f60b04159d9b99de6c5a081cf19b9821ab8ccf239b06499a1ad0485391fc67732081b06ee2b206c', 'Jeremy', 'Wagemans');

  -- Creates estimate requests
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 1', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 2', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 3', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', null, null, null, null);
  PERFORM marche_halibaba.submit_estimate_request('Demande de devis 4', '2016-05-31', 1, 'In de Poort', '26', '1970', 'Wezembeek-Oppem', 'Ebre', '29b', '17487', 'Empuriabrava');

  -- Submits estimates
  PERFORM marche_halibaba.submit_estimate('Devis 1', 1600, FALSE, FALSE, 1, 1);


END;
$$ LANGUAGE plpgsql;

SELECT marche_halibaba.insert_mock_data();
