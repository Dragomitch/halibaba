-- Custom type

/**DROP TYPE IF EXISTS marche_halibaba.estimate;
CREATE TYPE marche_halibaba.estimate
  AS (
    estimate_id INTEGER,
    description TEXT,
    price NUMERIC(12,2),
    options_nbr INTEGER,
    pub_date TIMESTAMP,
    house_id INTEGER
  );
**/

-- Procedure
CREATE OR REPLACE FUNCTION marche_halibaba.houses_list_estimates_for(INTEGER, INTEGER)
	RETURNS SETOF marche_halibaba.estimate AS $$

DECLARE
	arg_estimate_request_id ALIAS FOR $1;
	arg_house_id ALIAS FOR $2;
	cur_estimate marche_halibaba.estimate;
	out marche_halibaba.estimate;
BEGIN
	FOR cur_estimate IN (
		SELECT e.estimate_id, e.description, e.price, COUNT(DISTINCT eo.options_nbr), e.submission_date,e.house_id
		FROM marche_halibaba.estimates e, marche_halibaba.estimate_requests er 
			LEFT OUTER JOIN marche_halibaba.estimate_options eo ON eo.estimate_id= e.estimate_id
		WHERE e.estimate_request_id= arg_estimate_request_id
			AND e.is_cancelled= FALSE
			AND (e.is_secret= FALSE OR (e.is_secret= TRUE AND e.house_id= arg_house_id))-- devis par caché par la même maison, ou caché
	)	LOOP
		SELECT cur_estimate.* INTO out;
		RETURN NEXT out;
	END LOOP;
	RETURN;
END;
$$ LANGUAGE 'plpgsql';