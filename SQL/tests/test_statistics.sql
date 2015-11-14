CREATE OR REPLACE FUNCTION unit_tests.test_statistics()
  RETURNS test_result AS $$
DECLARE
  statistics RECORD;
  message test_result;
BEGIN

  SELECT h.turnover, h.acceptance_rate
  INTO statistics
  FROM marche_halibaba.houses h
  WHERE h.house_id = 1;

  IF statistics.turnover <> 11600 THEN
    SELECT assert.fail('Turnover is incorrect.') INTO message;
    RETURN message;
  END IF;

  IF statistics.acceptance_rate <> 0.11 THEN
    SELECT assert.fail('Acceptance rate is incorrect.') INTO message;
    RETURN message;
  END IF;

  IF (
    SELECT count(estimate_id)
    FROM marche_halibaba.houses h, marche_halibaba.estimates e,
      marche_halibaba.estimate_requests er
    WHERE h.house_id = e.house_id AND
      e.estimate_request_id = er.estimate_request_id AND
      e.is_cancelled = FALSE AND
      er.pub_date + INTERVAL '15' day >= NOW() AND
      er.chosen_estimate IS NULL AND
      h.house_id = 1
  ) <> 3 THEN
    SELECT assert.fail('Number of submitted estimates is incorrect.') INTO message;
    RETURN message;
  END IF;

  SELECT assert.ok('End of test.') INTO message;
  RETURN message;
END;
$$ LANGUAGE plpgsql;
