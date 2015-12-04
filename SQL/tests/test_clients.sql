CREATE OR REPLACE FUNCTION unit_tests.test_clients()
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

  IF NOT EXISTS (
    SELECT *
    FROM marche_halibaba.clients c, marche_halibaba.users u
    WHERE c.user_id = u.user_id AND
      c.last_name = 'Wagemans' AND
      c.first_name = 'Jeremy' AND
      u.username = 'jeremy' AND
      u.pswd = 'blublu'
    ) THEN
    SELECT assert.fail('L insertion des clients est incorrecte.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;
