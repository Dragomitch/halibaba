CREATE OR REPLACE FUNCTION unit_tests.test()
  RETURNS test_result AS $$
BEGIN
    assert.ok('Le test1 a bien réussi :)');
END
$$ LANGUAGE plpgsql;
