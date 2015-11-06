CREATE OR REPLACE FUNCTION approve_estimate(INTEGER, INTEGER[])
  RETURNS INTEGER AS $$

DECLARE
  arg_estimate_id ALIAS FOR $1;
  arg_chosen_options ALIAS FOR $2;
  estimate_details RECORD;
  option INTEGER;
BEGIN

  -- An exception is raised if a estimate has already been approved for this estimate request
  IF EXISTS(
    SELECT *
    FROM estimates e
    WHERE e.estimate_request_id = (
        SELECT e2.estimate_request_id
        FROM estimates e2
        WHERE e2.estimate_id = arg_estimate_id
      ) AND e.status = 'approved'
  )THEN
    RAISE EXCEPTION 'Un devis a déjà été approuvé pour cette demande.';
  END IF;

  SELECT e.status as status, (er.pub_date + INTERVAL '15 days') as expiration_date
  INTO estimate_details
  FROM estimate_requests er, estimates e
  WHERE er.estimate_request_id = e.estimate_request_id AND
    e.estimate_id = arg_estimate_id;

  -- An exception is raised because the estimate has been cancelled
  IF estimate_details.status <> 'submitted' THEN
    RAISE EXCEPTION 'Ce devis n est pas valide.';
  -- An exception is raised because the estimate request has expired
  ELSIF estimate_details.expiration_date < NOW() THEN
    RAISE EXCEPTION 'Cette demande de devis est expirée.';
  -- The estimate and the chosen options are succesfully approved
  ELSE
    UPDATE estimates
    SET status = 'approved'
    WHERE estimate_id = arg_estimate_id;

    FOREACH option IN ARRAY arg_chosen_options
    LOOP
      UPDATE options
      SET is_chosen = TRUE
      WHERE option_id = option;
    END LOOP;

  END IF;

  RETURN 0;
END;
$$ LANGUAGE plpgsql;
