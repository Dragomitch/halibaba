package marche_halibaba;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class ClientsApp {
	
	private int clientId;
	private Connection dbConnection;
	private Map<String, PreparedStatement> preparedStmts;
	
	public static void main(String[] args) {
		ClientsApp session = new ClientsApp();
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("\n************************************************");
			System.out.println("* Bienvenue sur le Marche d'Halibaba - Clients *");
			System.out.println("************************************************");
			System.out.println("1 - Se connecter");
			System.out.println("2 - Créer un compte");
			System.out.println("3 - Quitter");
			
			System.out.println("\nQuel est votre choix? (1-3)");	
			int userChoice = Utils.readAnIntegerBetween(1, 3);
			
			switch(userChoice) {
			case 1:
				
				if((session.clientId = session.signin()) > 0) {
					session.menu();
				}
				
				session.clientId = 0;
				break;
			case 2:
				
				if((session.clientId = session.signup()) > 0) {
					session.menu();
				}
				
				session.clientId = 0;
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
	
	public ClientsApp() {
		
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
			preparedStmts.put("signup", dbConnection.prepareStatement("SELECT marche_halibaba.signup_client(?, ?, ?, ?)"));
			
			preparedStmts.put("signin", dbConnection.prepareStatement("SELECT c_id, u_pswd " +
					"FROM marche_halibaba.signin_users " +
					"WHERE u_username = ?"));
			
			preparedStmts.put("estimateRequests", dbConnection.prepareStatement("SELECT er.estimate_request_id, er.description, er.pub_date " +
					"FROM marche_halibaba.estimate_requests er " +
					"WHERE er.pub_date + INTERVAL '15' day >= NOW() AND " +
					"er.chosen_estimate IS NULL AND " +
					"er.client_id = ? " +
					"ORDER BY er.pub_date DESC"));
			
			preparedStmts.put("submitEstimateRequests",  dbConnection.prepareStatement("SELECT marche_halibaba.submit_estimate_request(?,?,?,?,?,?,?,?,?,?,?)"));
			
			preparedStmts.put("estimates", dbConnection.prepareStatement("SELECT e_id, e_description, e_price, " +
					"e_submission_date, e_estimate_request_id, e_house_id, e_house_name " +
					"FROM marche_halibaba.clients_list_estimates " +
					"WHERE e_estimate_request_id = ?"));
			
			preparedStmts.put("estimate", null);
			
			preparedStmts.put("approveEstimateRequests", dbConnection.prepareStatement("SELECT marche_halibaba.approve_estimate(?, [])"));

			preparedStmts.put("statistics", dbConnection.prepareStatement("SELECT h.name, h.turnover, h.acceptance_rate, " + 
					"h.caught_cheating_nbr, h.caught_cheater_nbr " +
					"FROM marche_halibaba.houses h "));
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
			System.out.print("Votre nom: ");
			String lastName = Utils.scanner.nextLine();
			System.out.print("Votre prénom: ");
			String firstName = Utils.scanner.nextLine();
			System.out.print("Votre nom d'utilisateur: ");
			String username = Utils.scanner.nextLine();
			System.out.print("Votre mot de passe: ");
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
				ps.setString(3, firstName);
				ps.setString(4, lastName);
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
			System.out.println("1. Consulter mes demandes de devis en cours");
			System.out.println("2. Consulter mes demandes de devis acceptées");
			System.out.println("3. Soumettre une demande de devis");
			System.out.println("4. Afficher les statistiques des maisons");
			System.out.println("5. Se déconnecter");
			
			System.out.println("\nQue désirez-vous faire ? (1 - 5)");
			int choice = Utils.readAnIntegerBetween(1, 5);
			
			switch(choice) {
			case 1:
				displayEstimateRequests();
				break;
			case 2:
				break;
			case 3:
				submitEstimateRequest();
				break;
			case 4:
				displayStatistics();
				break;
			case 5:
				isUsing = false;
				break;
			}
			
		}
		
	}
	
	private void displayEstimateRequests() {
		
		boolean isUsing = true;
		while(isUsing) {
			HashMap<Integer, Integer> estimateRequests = new HashMap<Integer, Integer>(); 
			String estimateRequestsStr = "";
			
			try {
				PreparedStatement ps = preparedStmts.get("estimateRequests");
				ps.setInt(1, clientId);
				ResultSet rs = ps.executeQuery();
				
				int i = 1;
				while(rs.next()) {
					estimateRequests.put(i, rs.getInt(1));
					estimateRequestsStr += i + ". " + rs.getString(2) + " - Posté le " + rs.getDate(3) + "\n";
					i++;
				}
				
			} catch (SQLException e) {
				e.printStackTrace();
			}
			
			if(estimateRequests.size() > 0) {
				System.out.println(estimateRequestsStr);
				Utils.blockProgress();
				
				System.out.println("Que voulez-vous faire ?");
				System.out.println("1. Consulter les devis soumis pour une demande");
				System.out.println("2. Retour");
				
				if(Utils.readAnIntegerBetween(1, 2) == 1) {
					System.out.println(estimateRequestsStr);
					System.out.println("Quel devis voulez-vous voir ?");
					int userChoice = Utils.readAnIntegerBetween(1, estimateRequests.size());
					displayEstimateRequest(estimateRequests.get(userChoice));
				} else {
					isUsing = false;
				}
				
			} else {
				System.out.println("Il n'y a aucune demande de devis en cours");
				Utils.blockProgress();
				isUsing = false;
			}
			
		}

					
	}
	
	private void displayEstimateRequest(int id) {
		HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>();
		String estimatesStr = "";
			
		try {
			PreparedStatement ps = preparedStmts.get("estimateRequest");
			ps.setInt(1, id);
			ResultSet rs = ps.executeQuery();
			
			int i = 1;
			while(rs.next()) {
				estimates.put(i, rs.getInt(1));
				estimatesStr += i + ". " + rs.getString(2) + " - Prix: " + rs.getDate(3) + "€\n";
				i++;
			}
			
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		System.out.println(estimatesStr);
		
		if(estimates.size() > 0) {
			System.out.println("Que voulez-vous faire ?");
			System.out.println("1. Accepter un devis");
			System.out.println("2. Retour");
			
			if(Utils.readAnIntegerBetween(1, 2) == 1) {
				System.out.println(estimatesStr);
				System.out.println("Quel devis voulez-vous accepter ?");
				int userChoice = Utils.readAnIntegerBetween(1, estimates.size());
				approveEstimate(estimates.get(userChoice));	
			}
			
		} else {
			System.out.println("Il n'y a aucun devis soumis pour cette demande.\n");
			Utils.blockProgress();
		}
		
	}
	
	private void approveEstimate(int id) {
		System.out.println("Etes-vous sûr de vouloir accepter ce devis ? Oui (O) - Non (N)");
		
		if(Utils.readOorN()) {

			try {
				PreparedStatement ps = preparedStmts.get("approveEstimateRequests");
				ps.setInt(1, id);
				ResultSet rs = ps.executeQuery();
				rs.next();
				System.out.println("Le devis a bien été accepté");
			} catch (SQLException e) {
				System.out.println("Vous ne pouvez pas accepter ce devis.");
			}
			
		}
		
	}
	
	private void submitEstimateRequest() {
		System.out.println("Soumettre une demande de devis");
		System.out.println("------------------------------");
		System.out.println("Description:");
		String description = Utils.scanner.nextLine();
		System.out.println("Date souhaitée de fin des travaux (jj/mm/aaaa):");
		Date deadline = Utils.readDate();
		
		Map<String, String> constructionAddress = enterAddress();
		
		System.out.println("L'adresse de facturation est-elle différente de l'adresse des travaux ? O (oui) - N (non)");
		
		Map<String, String> invoicingAddress = null;
		
		if(Utils.readOorN()) {
			invoicingAddress = enterAddress();
		}
		
		try {
			PreparedStatement ps = preparedStmts.get("estimate_requests");
			ps.setString(1, description);
			ps.setDate(2, new java.sql.Date(deadline.getTime()));
			ps.setInt(3, clientId);
			ps.setString(4, constructionAddress.get("streetName"));
			ps.setString(5, constructionAddress.get("streetNbr"));
			ps.setString(6, constructionAddress.get("zipCode"));
			ps.setString(7, constructionAddress.get("city"));
			
			if(invoicingAddress == null) {
				ps.setString(8, null);
				ps.setString(9, null);
				ps.setString(10, null);
				ps.setString(11, null);
			} else {
				ps.setString(8, invoicingAddress.get("streetName"));
				ps.setString(9, invoicingAddress.get("streetNbr"));
				ps.setString(10, invoicingAddress.get("zipCode"));
				ps.setString(11, invoicingAddress.get("city"));
			}
			
			ResultSet result = ps.executeQuery();
		} catch (SQLException e) {
			e.printStackTrace();
		}

	}
	
	private void displayStatistics() {
		System.out.println("Statistiques:");
		
		try {
			PreparedStatement ps = preparedStmts.get("statistics");
			ResultSet rs = ps.executeQuery();
			
			while(rs.next()) {
				System.out.println(rs.getString(1));
				System.out.println("\tChiffre d'affaire: " + rs.getDouble(2) 
					+ "€\tTaux d'acceptation: " + rs.getDouble(3)  + "\tNbr de fois attrapé: " + rs.getInt(4) + "\tNbr de fois a attrapé: " + rs.getInt(5));
			}
			
		} catch (SQLException e) {
			e.printStackTrace();
		}
		
		Utils.blockProgress();		
	}
	
	private Map<String, String> enterAddress() {
		Map<String, String> address = new HashMap<String, String>();
		
		System.out.println("Nom de la rue: ");
		address.put("streetName", Utils.scanner.nextLine());
		
		System.out.println("Numéro: ");
		address.put("streetNbr", Utils.scanner.nextLine());
		
		System.out.println("Code postal: ");
		address.put("zipCode", Utils.scanner.nextLine());
		
		System.out.println("Ville: ");
		address.put("city", Utils.scanner.nextLine());
		
		return address;
	}

	
}