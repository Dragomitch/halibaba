package marche_halibaba_houses;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.util.HashMap;
import java.util.Map;

import marche_halibaba_houses.Utils;

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
		//String url = "jdbc:postgresql://172.24.2.6:5432/projet?user=app&password=2S5jn12JndG68hT";
		
		try {
			this.dbConnection = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			System.exit(1);
		}
		
		this.preparedStmts = new HashMap<String, PreparedStatement>();
		
		try {
			preparedStmts.put("signup", dbConnection.prepareStatement(
					"SELECT marche_halibaba.signup_house(?, ?, ?)"));
			
			preparedStmts.put("signin", dbConnection.prepareStatement(
					"SELECT h_id, u_pswd " +
					"FROM marche_halibaba.signin_users " +
					"WHERE u_username = ?"));
			
			preparedStmts.put("estimates", dbConnection.prepareStatement(
					"SELECT *"+
					"FROM marche_halibaba.valid_estimates_list, "+
					"marche_halibaba.houses h "+ 
					"WHERE ?= h.house_id AND "+
					"(e_is_secret= FALSE OR (e_is_secret= TRUE AND e_house_id= ?))"));//vérifier les hidings aussi
			
			preparedStmts.put("estimateRequests", dbConnection.prepareStatement(
					"SELECT * " +
					"FROM marche_halibaba.submitted_requests "));

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
				System.out.println("\nLes données saisies sont incorrectes.");
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
			System.out.println("1. Lister tous les devis soumis en attente d'acceptation");
			System.out.println("2. Lister les demandes de devis en cours");
			System.out.println("3. Ajouter des options au catalogue d'options");
			System.out.println("4. Statistiques");
			//nombre de devis en cours ?
			System.out.println("5. Se déconnecter");
			
			System.out.println("\nQue désirez-vous faire ? (1 - 5)");
			int choice = Utils.readAnIntegerBetween(1, 5);
			
			switch(choice) {
			case 1:
				displayEstimates();
				break;
			case 2:
				displayEstimateRequests();
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

private void displayEstimates() {
	HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>(); 
	String estimateStr = "";
	
	try {
		PreparedStatement ps = preparedStmts.get("estimates");
		ps.setInt(1, houseId);
		ps.setInt(2, houseId);
		ResultSet rs = ps.executeQuery();
		
		int i = 1;
		while(rs.next()) {
			estimates.put(i, rs.getInt(1));
			estimateStr += i + ". " + rs.getString(2) + "\nPrix: " + rs.getDouble(3) +
					",  soumis le : "+rs.getDate(4)+"\n";
			i++;
		}
		
	} catch (SQLException e) {
		e.printStackTrace();
	}
	
	if(estimates.size() > 0) {
		System.out.println(estimateStr);
		Utils.blockProgress();

	} else {
		System.out.println("Il n'y a aucun devis en cours");
		Utils.blockProgress();
	}
		
}

private void displayEstimatesForRequest(int requestId) {

	HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>(); 
	String estimateStr = "";
	
	try {
		PreparedStatement ps = preparedStmts.get("estimates");
		ps.setInt(1, houseId);
		ps.setInt(2, houseId);
		ResultSet rs = ps.executeQuery();
		
		int j=  1;
		while(rs.next()) {

			if(rs.getInt(7)== requestId){
				estimates.put(j, rs.getInt(7));
				estimateStr += j+ ". "+ rs.getString(2) + "\nPrix: " + rs.getDouble(3) +
					", soumis le : "+rs.getDate(4)+", date de fin des travaux: "+rs.getDate(8)+"\n";
				j++;
			}
			
		}
		
	} catch (SQLException e) {
		e.printStackTrace();
	}
	
	if(estimates.size() > 0) {
		System.out.println(estimateStr);
		System.out.println("Que voulez-vous faire ?");
		System.out.println("1. Soumettre un nouveau devis pour cette demande");
		System.out.println("2. Retour");
		int userChoice= Utils.readAnIntegerBetween(1, 2);
		
		if(userChoice== 1)
			submitEstimate(requestId);

	} else {
		System.out.println("Il n'y a aucun devis pour la demande en question");
		Utils.blockProgress();
	}
		
}


private void displayEstimateRequests() {
	
	HashMap<Integer, Integer> estimateRequests = new HashMap<Integer, Integer>(); 
	String estimateRequestsStr = "";
	
	try {
		PreparedStatement ps = preparedStmts.get("estimateRequests");
		ResultSet rs = ps.executeQuery();
		
		int i = 1;
		while(rs.next()) {
			estimateRequests.put(i, rs.getInt(1));
			estimateRequestsStr += i + ". " + rs.getString(2) + " - Poste le " + rs.getDate(3) + "\n";
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
			System.out.println("Pour quelle demande voulez-vous voir les devis soumis?");
			int userChoice = Utils.readAnIntegerBetween(1, estimateRequests.size());
			displayEstimatesForRequest(estimateRequests.get(userChoice));
			
		}
		
	} else {
		System.out.println("Il n'y a aucune demande de devis en cours");
		Utils.blockProgress();
	}
		
}

/**
 * 
 * @param requestId 	The requestId thus the user want to see the estimates
 */
/*private void displayEstimateRequest(int requestId) {
	HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>();
	String estimatesStr = "";
		
	try {
		PreparedStatement ps = preparedStmts.get("estimateRequest");
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
*/ // XXX USELESS Same as displayEstimatesForRequest?



private void submitEstimate(int estimateRequest){
	boolean isUsing= true;
	
}


}
