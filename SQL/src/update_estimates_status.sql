-- DEPRECATED
CREATE OR REPLACE FUNCTION update_estimates_status()
  RETURNS void AS $$
BEGIN
  UPDATE marche_halibaba.estimates
    SET status = 'expired'
    WHERE estimate_id IN (
      SELECT e.estimate_id
        FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er
        WHERE e.estimate_request_id = er.estimate_request_id AND
          er.pub_date + INTERVAL '15 days' < NOW() AND
          e.status = 'submitted');
END;
$$ LANGUAGE 'plpgsql';
