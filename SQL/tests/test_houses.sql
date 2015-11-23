CREATE OR REPLACE FUNCTION unit_tests.test_houses()
  RETURNS test_result AS $$
DECLARE
  message test_result;
BEGIN

  IF (
    SELECT count(*)
    FROM marche_halibaba.houses h, marche_halibaba.users u
    WHERE h.user_id = u.user_id
  ) <> 3 THEN
    SELECT assert.fail('Toutes les maisons n ont pas été insérés.') INTO message;
    RETURN message;
  END IF;

  IF NOT EXISTS (
    SELECT *
    FROM marche_halibaba.houses h, marche_halibaba.users u
    WHERE h.user_id = u.user_id AND
      h.name = 'House Clegane' AND
      u.username = 'clegane' AND
      u.pswd = 'blublu'
  ) THEN
    SELECT assert.fail('L insertion des maisons est incorrecte.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;
