CREATE OR REPLACE FUNCTION marche_halibaba.remove_all()
	RETURNS void AS $$
DECLARE
	statements CURSOR FOR
		SELECT tablename FROM pg_tables
		WHERE schemaname = 'marche_halibaba';
BEGIN
	FOR stmt IN statements LOOP
		EXECUTE 'TRUNCATE TABLE marche_halibaba.' || quote_ident(stmt.tablename) || ' CASCADE;';
        END LOOP;

	PERFORM marche_halibaba.signup_house('starque', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Starque');
	PERFORM marche_halibaba.signup_house('boltone', '1000:ce2723bacc00ffd71a3c3dd7a712d16cfc023aa781d5fec5:b77f9f0e005c806c6577a0e5a423e4095c70f7a33b16d7a057c76237e4628adc8349555c6c314b6f08b115d45efe44643089823f849e2b27b55a353879b42895928c1ffb9f12b7b51a1b166c947b643c43716bc2a1a3996d185e00937c993454', 'Boltone');
END;
$$ LANGUAGE plpgsql;
