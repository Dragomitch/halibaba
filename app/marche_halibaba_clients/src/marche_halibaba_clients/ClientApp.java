package marche_halibaba_clients;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.Date;
import java.util.HashMap;

public class ClientApp {
	
	private int clientId;
	
	public static void main(String[] args) {
		//TODO: trouver un beau nom pour ces variables booléennes
		boolean isRunning = true;
		
		while(isRunning) {
			ClientApp session = new ClientApp();
			
			System.out.println("********************************************");
			System.out.println("Bienvenue sur le Marche d'Halibaba - Clients");
			System.out.println("********************************************");
			System.out.println("1 - Se connecter");
			System.out.println("2 - Créer un compte");
			System.out.println("3 - Quitter");
					
			int userChoice = Utils.readAnIntegerBetween(1, 3);
			
			switch(userChoice) {
			case 1:
				
				if((session.clientId = session.login()) > 0) {
					session.menu();
				}
				
				break;
			case 2:
				
				if((session.clientId = session.signup()) > 0) {
					session.menu();
				}
				
				break;
			case 3:
				isRunning = false;
				break;
			}
			
		}
			
	}
	
	private int login() {
		
		boolean isUsing = true;
		
		while(isUsing) {
			System.out.println("Se connecter");
			System.out.println("------------");
			System.out.println("Votre nom d'utilisateur:");
			String username = Utils.scanner.nextLine();
			System.out.println("Votre mot de passe:");
			String pswd = Utils.scanner.nextLine();

			try {
				PreparedStatement ps = Db.connection.prepareStatement("SELECT c_id, u_pswd " +
						"FROM marche_halibaba.signin_users " +
						"WHERE u_username = ?");
				ps.setString(1, username);
				ResultSet result = ps.executeQuery();
				
				if(result.next() && 
						PasswordHash.validatePassword(pswd, result.getString(2))) {
					return result.getInt(1);
				}
				
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
			} catch (SQLException e) {}
			
			System.out.println("\nVotre nom d'utilisateur et/ou mot de passe est erroné.");
			System.out.println("Voulez-vous réessayer?");
			
			if(!Utils.readOorN()) {
				isUsing = false;
			}

		}
		
		return 0;
	}
	
	private int signup() {
		System.out.println("Inscription");
		System.out.println("-----------");
		
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
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
			}
			
			try {
				PreparedStatement ps = Db.connection.prepareStatement("SELECT marche_halibaba.signup_client(?, ?, ?, ?)");
				ps.setString(1, username);
				ps.setString(2, pswd);
				ps.setString(3, firstName);
				ps.setString(4, lastName);
				ResultSet rs = ps.executeQuery();
				rs.next();
				
				System.out.println("\nVotre compte a bien été créé.");
				System.out.println("Vous allez maintenant être redirigé sur la page d'accueil de l'application.");
				Utils.blockProgress();
				
				return rs.getInt(1);
			} catch (SQLException e) {
				System.out.println("\nLes données saisies sont incorrectes.");
				System.out.println("Voulez-vous réessayer?");
				
				if(!Utils.readOorN()) {
					isUsing = false;
				}
			
			}

		}
		
		return 0;
	}
	
	private void menu() {
		boolean isRunning = true;
		
		while(isRunning) {
			System.out.println("Que désirez-vous faire ?");
			
			System.out.println("1. Consulter mes demandes de devis en cours");
			System.out.println("2. Consulter mes demandes de devis acceptées");
			System.out.println("3. Soumettre une demande de devis");
			System.out.println("4. Afficher les statistiques des maisons");
			System.out.println("5. Se déconnecter");
			
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
				displayStats();
				break;
			case 5:
				isRunning = false;
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
				PreparedStatement ps = Db.connection.prepareStatement("SELECT er.estimate_request_id, er.description, er.pub_date " +
						"FROM marche_halibaba.estimate_requests er " +
						"WHERE er.pub_date + INTERVAL '15' day >= NOW() AND " +
						"er.chosen_estimate IS NULL AND " +
						"er.client_id = ? " +
						"ORDER BY er.pub_date DESC");
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
		
		System.out.println("Que voulez-vous faire ?");
		System.out.println("1. Sélectionner un devis");
		System.out.println("2. Retour");
		
		if(Utils.readAnIntegerBetween(1, 2) == 1) {
			approveEstimate();
		}
		
	}
	
	private void approveEstimate() {
		
	}
	
	private void submitEstimateRequest() {
		System.out.println("Soumettre une demande de devis");
		System.out.println("------------------------------");
		System.out.println("Description:");
		String description = Utils.scanner.nextLine();
		System.out.println("Date souhaitée de fin des travaux (jj/mm/aaaa):");
		Date deadline = Utils.readDate();
		
		HashMap<String, String> constructionAddress = enterAddress();
		
		System.out.println("L'adresse de facturation est-elle différente de l'adresse des travaux ? O (oui) - N (non)");
		
		HashMap<String, String> invoicingAddress = null;
		
		if(Utils.readOorN()) {
			invoicingAddress = enterAddress();
		}
		
		try {
			PreparedStatement ps = Db.connection.prepareStatement("SELECT marche_halibaba.submit_estimate_request(?,?,?,?,?,?,?,?,?,?,?)");
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
	
	private void displayStats() {
		System.out.println("Statistiques:");
		
		try {
			PreparedStatement ps = Db.connection.prepareStatement("SELECT h.name, h.turnover, h.acceptance_rate, " + 
					"h.caught_cheating_nbr, h.caught_cheater_nbr " +
					"FROM marche_halibaba.houses h ");
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
	
	private HashMap<String, String> enterAddress() {
		HashMap<String, String> address = new HashMap<String, String>();
		
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