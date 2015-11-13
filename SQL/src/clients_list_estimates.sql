-- Custom type
DROP TYPE IF EXISTS marche_halibaba.estimate;
CREATE TYPE marche_halibaba.estimate
  AS (
    estimate_id INTEGER,
    description TEXT,
    price NUMERIC(12,2),
    options_nbr INTEGER,
    pub_date TIMESTAMP,
    house_id INTEGER
  );

-- Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.list_estimates_for(INTEGER)
  RETURNS SETOF marche_halibaba.estimate AS $$

DECLARE
  arg_estimate_request_id ALIAS FOR $1;
  cur_estimate marche_halibaba.estimate;
  out marche_halibaba.estimate;
BEGIN

  -- If an estimate has already been approved for this estimate request,
  -- that estimate is returned
  IF (
    SELECT chosen_estimate
    FROM estimate_requests
    WHERE estimate_request_id = arg_estimate_request_id
  ) IS NOT NULL THEN
    SELECT e.estimate_id, e.description, e.price,
        count(DISTINCT eo.option_id), e.submission_date, e.house_id
      INTO out
      FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
      LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
        eo.estimate_id = e.estimate_id
      WHERE er.chosen_estimate = e.estimate_id AND
        er.estimate_request_id = arg_estimate_request_id
      GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id;
    RETURN NEXT out;
    RETURN;
  END IF;

  -- If an hiding estimate has been submitted for this estimate request,
  -- that estimate is returned
  IF EXISTS (
    SELECT *
      FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
      WHERE er.estimate_request_id = e.estimate_request_id AND
        e.is_hiding = TRUE AND
        e.is_cancelled = FALSE AND
        er.estimate_request_id = arg_estimate_request_id
  ) THEN
    SELECT e.estimate_id, e.description, e.price,
        count(DISTINCT eo.option_id), e.submission_date, e.house_id
      INTO out
      FROM marche_halibaba.estimate_requests er, marche_halibaba.estimates e
        LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
          eo.estimate_id = e.estimate_id
      WHERE er.estimate_request_id = e.estimate_request_id AND
        e.is_hiding = TRUE AND
        e.is_cancelled = FALSE AND
        er.estimate_request_id = arg_estimate_request_id
      GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id;
    RETURN NEXT out;
    RETURN;
  END IF;

  -- All estimates for this estimate request are returned
  FOR cur_estimate IN (
    SELECT e.estimate_id, e.description, e.price,
        count(DISTINCT eo.option_id), e.submission_date, e.house_id
      FROM marche_halibaba.estimates e
        LEFT OUTER JOIN marche_halibaba.estimate_options eo ON
          eo.estimate_id = e.estimate_id
      WHERE er.estimate_request_id = e.estimate_request_id AND
        e.is_cancelled = FALSE AND
        e.estimate_request_id = arg_estimate_request_id
      GROUP BY e.estimate_id, e.description, e.price, e.submission_date, e.house_id
  ) LOOP
    SELECT cur_estimate.* INTO out;
    RETURN NEXT out;
  END LOOP;
  RETURN;

END;
$$ LANGUAGE 'plpgsql';
