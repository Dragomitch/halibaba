CREATE OR REPLACE FUNCTION unit_tests.test_signup()
  RETURNS test_result AS $$
DECLARE
  message test_result;
BEGIN
  IF (
    SELECT count(*)
    FROM marche_halibaba.clients c, marche_halibaba.users u
    WHERE c.user_id = u.user_id
  ) <> 1 THEN
    SELECT assert.fail('Tous les clients n ont pas été insérés.') INTO message;
    RETURN message;
  END IF;

  IF (
    SELECT count(*)
    FROM marche_halibaba.houses h, marche_halibaba.users u
    WHERE c.user_id = u.user_id
  ) <> 2 THEN
    SELECT assert.fail('Toutes les maisons n ont pas été insérés.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;
