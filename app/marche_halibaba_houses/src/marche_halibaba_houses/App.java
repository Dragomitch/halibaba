package marche_halibaba_houses;

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.SQLException;
import java.util.Map;

public abstract class App {
	
	Connection dbConnection;
	Map<String, PreparedStatement> preparedStmts;
	
	public App(String dbUser, String dbPswd) {
		
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver PostgreSQL manquant !");
			System.exit(1);
		}
		
		// Dev
		String url = "jdbc:postgresql://localhost:5432/projet?user=" + dbUser + "&password=" + dbPswd;
		
		// Prod
		//String url = "jdbc:postgresql://localhost:5432/projet?user=app&password=2S5jn12JndG68hT";
		
		try {
			this.dbConnection = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			System.exit(1);
		}
		
	}

}
