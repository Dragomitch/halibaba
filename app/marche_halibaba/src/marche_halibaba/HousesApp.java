package marche_halibaba;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

public class HousesApp {
	private int houseId;
	private Connection dbConnection;
	private Map<String, PreparedStatement> preparedStmts;
	
	public static void main(String[] args) {
		HousesApp session = new HousesApp();
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("\n************************************************");
			System.out.println("* Bienvenue sur le Marche d'Halibaba - Maisons *");
			System.out.println("************************************************");
			System.out.println("1 - Se connecter");
			System.out.println("2 - Créer un compte");
			System.out.println("3 - Quitter");
			
			System.out.println("\nQuel est votre choix? (1-3)");	
			int userChoice = Utils.readAnIntegerBetween(1, 3);
			
			switch(userChoice) {
			case 1:
				
				if((session.houseId = session.signin()) > 0) {
					session.menu();
				}
				
				session.houseId = 0;
				break;
			case 2:
				
				if((session.houseId = session.signup()) > 0) {
					session.menu();
				}
				
				session.houseId = 0;
				break;
			case 3:
				isUsing = false;
				break;
			}
			
		}
		
		try {
			session.dbConnection.close();
		} catch(SQLException e) {
			e.printStackTrace();
		}
		
			
	}
	
	public HousesApp() {
		
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver PostgreSQL manquant !");
			System.exit(1);
		}
		
		// Dev
		String url = "jdbc:postgresql://localhost:5432/projet?user=app&password=2S5jn12JndG68hT";
		
		// Prod
		//String url = "jdbc:postgresql://localhost:5432/projet?user=app&password=2S5jn12JndG68hT";
		
		try {
			this.dbConnection = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			System.exit(1);
		}
		
		this.preparedStmts = new HashMap<String, PreparedStatement>();
		
		try {
			preparedStmts.put("signup", dbConnection.prepareStatement("SELECT marche_halibaba.signup_house(?, ?, ?)"));
			
			preparedStmts.put("signin", dbConnection.prepareStatement("SELECT h_id, u_pswd " +
					"FROM marche_halibaba.signin_users " +
					"WHERE u_username = ?"));

		} catch (SQLException e) {
			e.printStackTrace();
			System.exit(1);
		}

	}
	
	private int signin() {
		System.out.println("\nSe connecter");
		System.out.println("************************************************\n");
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.print("Votre nom d'utilisateur : ");
			String username = Utils.scanner.nextLine();
			System.out.print("Votre mot de passe : ");
			String pswd = Utils.scanner.nextLine();

			try {
				PreparedStatement ps = preparedStmts.get("signin");
				ps.setString(1, username);
				ResultSet result = ps.executeQuery();
				
				if(result.next() && 
						result.getInt(1) > 0 &&
						PasswordHash.validatePassword(pswd, result.getString(2))) {
					return result.getInt(1);
				}
				
				System.out.println(result.getInt(1));
				
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
			} catch (SQLException e) {}
			
			System.out.println("\nVotre nom d'utilisateur et/ou mot de passe est erroné.");
			System.out.println("Voulez-vous réessayer? Oui (O) - Non (N)");
			
			if(!Utils.readOorN()) {
				isUsing = false;
			}

		}
		
		return 0;
	}
	
	private int signup() {
		System.out.println("\nInscription");
		System.out.println("************************************************\n");
		
		boolean isUsing = true;
		while (isUsing) {
			System.out.print("Nom de votre maison : ");
			String name = Utils.scanner.nextLine();
			System.out.print("Votre nom d'utilisateur : ");
			String username = Utils.scanner.nextLine();
			System.out.print("Votre mot de passe : ");
			String pswd = Utils.scanner.nextLine();
			
			try {
				pswd = PasswordHash.createHash(pswd);
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
				System.exit(1);
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
				System.exit(1);
			}
			
			try {
				PreparedStatement ps = preparedStmts.get("signup");
				ps.setString(1, username);
				ps.setString(2, pswd);
				ps.setString(3, name);
				ResultSet rs = ps.executeQuery();
				rs.next();
				
				System.out.println("\nVotre compte a bien été créé.");
				System.out.println("Vous allez maintenant être redirigé vers la page d'accueil de l'application.");
				Utils.blockProgress();
				
				return rs.getInt(1);
			} catch (SQLException e) {
				
				if(e.getSQLState().equals("23505")) {
					System.out.println("\nCe nom d'utilisateur est déjà utilisé.");
				} else {
					System.out.println("\nLes données saisies sont incorrectes.");
				}
				
				System.out.println("Voulez-vous réessayer? Oui (O) - Non (N)");
				
				if(!Utils.readOorN()) {
					isUsing = false;
				}
	
			}

		}
		
		return 0;
	}
	
	private void menu() {
		System.out.println("\nMenu");
		System.out.println("************************************************\n");
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("1. option 1");
			System.out.println("2. option 2");
			System.out.println("3. option 3");
			System.out.println("4. option 4");
			System.out.println("5. Se déconnecter");
			
			System.out.println("\nQue désirez-vous faire ? (1 - 5)");
			int choice = Utils.readAnIntegerBetween(1, 5);
			
			switch(choice) {
			case 1:
				break;
			case 2:
				break;
			case 3:
				break;
			case 4:
				break;
			case 5:
				isUsing = false;
				break;
			}
			
		}
		
	}

}
