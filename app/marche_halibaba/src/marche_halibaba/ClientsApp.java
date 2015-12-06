package marche_halibaba;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.Array;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.HashMap;
import java.util.Map;

public class ClientsApp extends App {
	
	private int clientId;	
	
	public static void main(String[] args) {
						
		try {
			ClientsApp session = new ClientsApp("app_clients", "2S5jn12JndG68hT");
			
			boolean isUsing = true;
			while(isUsing) {
				System.out.println("\n************************************************");
				System.out.println("* Bienvenue sur le Marche d'Halibaba - Clients *");
				System.out.println("************************************************");
				System.out.println("1 - Se connecter");
				System.out.println("2 - Creer un compte");
				System.out.println("3 - Quitter");
				
				System.out.println("\nQuel est votre choix? (1-3)");	
				int userChoice = Utils.readAnIntegerBetween(1, 3);
				
				switch(userChoice) {
				case 1:
					
					if(session.signin()) {
						session.menu();
					}
					
					session.clientId = 0;
					break;
				case 2:
					
					if(session.signup()) {
						session.menu();
					}
					
					session.clientId = 0;
					break;
				case 3:
					isUsing = false;
					break;
				}
				
			}
			
			System.out.println("\nMerci de votre visite. A bientot!");
			session.dbConnection.close();
			
		} catch(SQLException e) {
			e.printStackTrace();
			System.exit(1);
		}
			
	}
	
	public ClientsApp(String dbUser, String dbPswd) throws SQLException {
		super(dbUser, dbPswd);
		
		this.preparedStmts = new HashMap<String, PreparedStatement>();
		
		preparedStmts.put("signup", dbConnection.prepareStatement("SELECT marche_halibaba.signup_client(?, ?, ?, ?)"));
		
		preparedStmts.put("signin", dbConnection.prepareStatement("SELECT c_id, u_pswd " +
				"FROM marche_halibaba.signin_users " +
				"WHERE u_username = ?"));
		
		preparedStmts.put("estimateRequests", dbConnection.prepareStatement("SELECT er_id, er_description, remaining_days " +
				"FROM marche_halibaba.list_estimate_requests " +
				"WHERE er_pub_date + INTERVAL '15' day >= NOW() AND " +
				"er_chosen_estimate IS NULL AND " +
				"c_id = ?"));
		
		preparedStmts.put("approvedEstimateRequests", dbConnection.prepareStatement("SELECT er_id, er_description, er_pub_date, remaining_days " +
				"FROM marche_halibaba.list_estimate_requests " +
				"WHERE er_chosen_estimate IS NOT NULL AND " +
				"c_id = ?"));
		
		preparedStmts.put("submitEstimateRequests",
				dbConnection.prepareStatement("SELECT marche_halibaba.submit_estimate_request(?,?,?,?,?,?,?,?,?,?,?)"));
		
		preparedStmts.put("estimates", dbConnection.prepareStatement("SELECT e_id, e_description, e_price, " +
				"e_house_name " +
				"FROM marche_halibaba.clients_list_estimates " +
				"WHERE e_estimate_request_id = ?"));
		
		preparedStmts.put("estimate", dbConnection.prepareStatement("SELECT e_description, e_price, e_house_name, " +
				"e_option_id, e_option_description, e_option_price " +
				"FROM marche_halibaba.estimate_details " +
				"WHERE e_id = ?"));
		
		preparedStmts.put("approveEstimateRequests", dbConnection.prepareStatement("SELECT marche_halibaba.approve_estimate(?, ?, ?)"));

		preparedStmts.put("statistics", dbConnection.prepareStatement("SELECT h.name, h.turnover, h.acceptance_rate, " + 
				"h.caught_cheating_nbr, h.caught_cheater_nbr " +
				"FROM marche_halibaba.houses h "));

	}
	
	private boolean signin() throws SQLException {
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
				ResultSet rs = ps.executeQuery();
				
				if(rs.next() && 
						rs.getInt(1) > 0 &&
						PasswordHash.validatePassword(pswd, rs.getString(2))) {
					clientId = rs.getInt(1);
					rs.close();
					isUsing = false;
				} else {
					System.out.println("\nVotre nom d'utilisateur et/ou mot de passe est errone.");
					System.out.println("Voulez-vous reessayer? Oui (O) - Non (N)");
					
					if(!Utils.readOorN()) {
						isUsing = false;
					}
				}
				
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
			}

		}
		
		return clientId > 0;
	}
	
	private boolean signup() throws SQLException {
		System.out.println("\nInscription");
		System.out.println("************************************************\n");
		
		boolean isUsing = true;
		while (isUsing) {
			System.out.print("Votre nom: ");
			String lastName = Utils.scanner.nextLine();
			System.out.print("Votre prenom: ");
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
			
			PreparedStatement ps = preparedStmts.get("signup");
			ps.setString(1, username);
			ps.setString(2, pswd);
			ps.setString(3, firstName);
			ps.setString(4, lastName);
			ResultSet rs = null;
			
			try {
				rs = ps.executeQuery();
				rs.next();
				
				System.out.println("\nVotre compte a bien ete cree.");
				System.out.println("Vous allez maintenant etre redirige vers la page d'accueil de l'application.");
				Utils.blockProgress();
				
				clientId = rs.getInt(1);
				isUsing = false;
			} catch (SQLException e) {
				
				e.printStackTrace();
				
				if(e.getSQLState().equals("23505")) {
					System.out.println("\nCe nom d'utilisateur est déjà utilise.");
				} else {
					System.out.println("\nLes données saisies sont incorrectes.");
				}
				
				System.out.println("Voulez-vous reessayer? Oui (O) - Non (N)");
				
				if(!Utils.readOorN()) {
					isUsing = false;
				}
	
			} finally {
				
				if(rs != null) {
					rs.close();
				}
				
			}

		}
		
		return clientId > 0;
	}
	
	private void menu() throws SQLException {
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("\nMenu");
			System.out.println("************************************************\n");
			
			System.out.println("1. Consulter mes demandes de devis en cours");
			System.out.println("2. Consulter mes demandes de devis acceptees");
			System.out.println("3. Soumettre une demande de devis");
			System.out.println("4. Afficher les statistiques des maisons");
			System.out.println("5. Se deconnecter");
			
			System.out.println("\nQue desirez-vous faire ? (1 - 5)");
			int choice = Utils.readAnIntegerBetween(1, 5);
			
			switch(choice) {
			case 1:
				displayEstimateRequests();
				break;
			case 2:
				displayApprovedEstimateRequests();
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
	
	private void displayEstimateRequests() throws SQLException {
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("\nListe des demandes de devis en cours : ");
			System.out.println("************************************************\n");
			
			HashMap<Integer, Integer> estimateRequests = new HashMap<Integer, Integer>(); 
			String estimateRequestsStr = "";
			
			PreparedStatement ps = preparedStmts.get("estimateRequests");
			ps.setInt(1, clientId);
			ResultSet rs = ps.executeQuery();
			
			int i = 1;
			while(rs.next()) {
				estimateRequests.put(i, rs.getInt(1));
				estimateRequestsStr += i + ". " + rs.getString(2) + " - " +
						Utils.SQLIntervalToString(rs.getString(3)) + "\n";
				i++;
			}
			
			rs.close();
			
			if(estimateRequests.size() > 0) {
				System.out.println(estimateRequestsStr);
				
				System.out.println("Que voulez-vous faire ?");
				System.out.println("1. Consulter les devis soumis pour une demande");
				System.out.println("2. Retour");
				
				if(Utils.readAnIntegerBetween(1, 2) == 1) {
					System.out.println("\n" + estimateRequestsStr);
					System.out.println("Pour quelle demande voulez-vous voir les devis soumis?");
					int userChoice = Utils.readAnIntegerBetween(1, estimateRequests.size());
					displayEstimates(estimateRequests.get(userChoice));
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
	
	private void displayApprovedEstimateRequests() throws SQLException {
		System.out.println("\nListe des demandes de devis acceptées : ");
		System.out.println("************************************************\n");
		
		HashMap<Integer, Integer> approvedEstimateRequests = new HashMap<Integer, Integer>(); 
		String estimateRequestsStr = "";
			
		PreparedStatement ps = preparedStmts.get("approvedEstimateRequests");
		ps.setInt(1, clientId);
		ResultSet rs = ps.executeQuery();
		
		int i = 1;
		while(rs.next()) {
			approvedEstimateRequests.put(i, rs.getInt(1));
			estimateRequestsStr += i + ". " + rs.getString(2) + "\n";
			i++;
		}
			
		rs.close();
		
		if(approvedEstimateRequests.size() > 0) {
			System.out.println(estimateRequestsStr);
			Utils.blockProgress();
		} else {
			System.out.println("Il n'y a aucune demande de devis acceptées.");
			Utils.blockProgress();
		}
			
	}
	
	private void displayEstimates(int id) throws SQLException {
		
		boolean isUsing = true;
		while(isUsing) {
			HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>();
			String estimatesStr = "";
			
			PreparedStatement ps = preparedStmts.get("estimates");
			ps.setInt(1, id);
			ResultSet rs = ps.executeQuery();
			
			int i = 1;
			while(rs.next()) {
				estimates.put(i, rs.getInt(1));
				estimatesStr += i + ". " + rs.getString(2) + " - Prix: " + rs.getDouble(3) + " euros - Maison: " + rs.getString(4) + "\n";
				i++;
			}
			
			rs.close();
			
			System.out.println("\nListe des devis soumis : ");
			System.out.println("************************************************\n");
			
			if(estimates.size() > 0) {
				System.out.println(estimatesStr);
				System.out.println("Que voulez-vous faire ?");
				System.out.println("1. Afficher les détails d'un devis");
				System.out.println("2. Retour");
				
				if(Utils.readAnIntegerBetween(1, 2) == 1) {
					System.out.println(estimatesStr);
					System.out.println("Quel devis voulez-vous consulter ?");
					int userChoice = Utils.readAnIntegerBetween(1, estimates.size());
					isUsing = !displayEstimate(estimates.get(userChoice));	
				} else {
					isUsing = false;
				}
				
			} else {
				System.out.println("Il n'y a aucun devis soumis pour cette demande.");
				Utils.blockProgress();
				isUsing = false;
			}
			
		}
		
	}
	
	private boolean displayEstimate(int estimateId) throws SQLException {
		String optionsStr = "";
		Map<Integer, Integer> options = new HashMap<Integer, Integer>();
		
		PreparedStatement ps = preparedStmts.get("estimate");
		ps.setInt(1, estimateId);
		ResultSet rs = ps.executeQuery();
		
		if(rs.next()) {
			System.out.println("\nDevis : " + rs.getString(1));
			System.out.println("************************************************\n");
			System.out.println("Prix : " + rs.getDouble(2) + " euros");
			System.out.println("Maison : " + rs.getString(3));
						
			int i = 1;
			do {
				
				if(rs.getInt(4) != 0) {
					optionsStr += i + ". " + rs.getString(5) + " - prix : " + rs.getDouble(6) + " euros\n";
					options.put(i, rs.getInt(4));
					i++;
				}
				
			} while(rs.next());
			
			if(options.size() > 0) {
				System.out.println("\nListes des options disponibles : ");
				System.out.println(optionsStr);
			}

		}
		
		rs.close();
		
		System.out.println("\nQue voulez-vous faire ?");
		System.out.println("1. Accepter ce devis");
		System.out.println("2. Retour");
		
		if(Utils.readAnIntegerBetween(1, 2) == 1) {
			return approveEstimate(estimateId, optionsStr, options);
		}
		
		return false;
	}
	
	private boolean approveEstimate(int estimateId, String optionsStr, Map<Integer, Integer> options) throws SQLException {
		System.out.println("\nEtes-vous sur de vouloir accepter ce devis ? Oui (O) - Non (N)");
		
		if(Utils.readOorN()) {
			boolean status = false;
			Array chosenOptions = null;
			
			if(options.size() > 0) {
				System.out.println("Voulez-vous choisir des options ?");
				
				if(Utils.readOorN()) {
					System.out.println("Quels options voulez-vous choisir? (exemple: 1, 2, 3)");
					int[] integers = Utils.readIntegersBetween(1, options.size());
					Object[] userChoices = new Object[integers.length];
					
					for(int i = 0; i < integers.length; i++) {
						userChoices[i] = (Object) options.get(integers[i]);
					}
					
					chosenOptions = dbConnection.createArrayOf("integer", userChoices);
				}
				
			}
			
			PreparedStatement ps = preparedStmts.get("approveEstimateRequests");
			ps.setInt(1, estimateId);
			ps.setArray(2, chosenOptions);
			ps.setInt(3, clientId);
			ResultSet rs = null;
			
			try {
				rs = ps.executeQuery();
				rs.next();
				System.out.println("\nLe devis a bien ete accepte!");
				Utils.blockProgress();
				status = true;
			} catch (SQLException e) {
				System.out.println("Malheureusement, ce devis ne peut-etre accepte.\n");
			} finally {
				
				if(rs != null) {
					rs.close();
				}
				
			}
			
			return status;
		}
		
		return false;
	}
	
	private void submitEstimateRequest() throws SQLException {
		System.out.println("\nSoumettre une demande de devis");
		System.out.println("************************************************\n");
		
		boolean isUsing = true;
		while(isUsing) {
			System.out.print("Description : ");
			String description = Utils.scanner.nextLine();
			System.out.print("Date souhaitee de fin des travaux (jj/mm/aaaa) : ");
			Date deadline = Utils.readDate();
			Map<String, String> constructionAddress = enterAddress();
			
			System.out.println("L'adresse de facturation est-elle differente de l'adresse des travaux ? O (oui) - N (non)");
			Map<String, String> invoicingAddress = null;
			
			if(Utils.readOorN()) {
				invoicingAddress = enterAddress();
			}
			
			PreparedStatement ps = preparedStmts.get("submitEstimateRequests");
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
			
			ResultSet rs = null;
			
			try {	
				rs = ps.executeQuery();		
				System.out.println("\nFelicitations! Votre demande de devis a bien ete publiee.");
				Utils.blockProgress();
				isUsing = false;
			} catch (SQLException e) {
				System.out.println("Les donnees entrees sont erronnées. Veuillez recommencer.\n");
			} finally {
				
				if(rs != null) {
					rs.close();
				}
				
			}
			
		}

	}
		
	private void displayStatistics() throws SQLException {
		System.out.println("\nStatistiques des maisons");
		System.out.println("************************************************");
		
		PreparedStatement ps = preparedStmts.get("statistics");
		ResultSet rs = ps.executeQuery();
			
		while(rs.next()) {
			System.out.println("\n" + rs.getString(1));
			System.out.println("\tChiffre d'affaire: " + rs.getDouble(2) + " euros");
			System.out.println("\tTaux d'acceptation: " + (rs.getDouble(3)*100) + " pourcent");
			System.out.println("\tNombre de fois que la maison s'est fait attraper en train de tricher : " + rs.getInt(4) + " fois");
			System.out.println("\tNombre de fois que la maison a attrape un tricheur : " + rs.getInt(5) + " fois");
		}
		
		rs.close();
		Utils.blockProgress();		
	}
	
	private Map<String, String> enterAddress() {
		Map<String, String> address = new HashMap<String, String>();
		
		System.out.print("Nom de la rue: ");
		address.put("streetName", Utils.scanner.nextLine());
		
		System.out.print("Numero: ");
		address.put("streetNbr", Utils.scanner.nextLine());
		
		System.out.print("Code postal: ");
		address.put("zipCode", Utils.scanner.nextLine());
	
		System.out.print("Ville: ");
		address.put("city", Utils.scanner.nextLine());
		
		return address;
	}
	
}