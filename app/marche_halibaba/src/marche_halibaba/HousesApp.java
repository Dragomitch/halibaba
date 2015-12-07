package marche_halibaba;

import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Array;
import java.util.ArrayList;
import java.math.BigDecimal;
import java.util.HashMap;

public class HousesApp extends App{

	private int houseId;
	
	public static void main(String[] args) {
		
		try{
			
			HousesApp session = new HousesApp("app_houses", "2S5jn12JndG68hT");
			
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
					
					if(session.signin()) {
						session.menu();
					}
					
					session.houseId = 0;
					break;
				case 2:
					
					if(session.signup()) {
						session.menu();
					}
					
					session.houseId = 0;
					break;
				case 3:
					isUsing = false;
					break;
				}
				
			}
		
			System.out.println("\nMerci de votre visite.À bientôt!");
			session.dbConnection.close();
			
		} catch(SQLException e) {
			e.printStackTrace();
			System.exit(1);
		}
		
			
	}
	
	public HousesApp(String dbUser, String dbPswd) throws SQLException{
		super(dbUser, dbPswd);
		
		this.preparedStmts = new HashMap<String, PreparedStatement>();
		
		preparedStmts.put("signup", dbConnection.prepareStatement(
				"SELECT marche_halibaba.signup_house(?, ?, ?)"));
		
		preparedStmts.put("signin", dbConnection.prepareStatement(
				"SELECT h_id, u_pswd " +
				"FROM marche_halibaba.signin_users " +
				"WHERE u_username = ?"));

		preparedStmts.put("estimates", dbConnection.prepareStatement(
				"SELECT e_description, e_price, e_submission_date, "+
						"er_estimate_request_id,  h_name "+
				"FROM marche_halibaba.valid_estimates_list "+
				"WHERE er_estimate_request_id = ? AND "+
				"(e_is_secret= FALSE OR (e_is_secret = TRUE AND e_house_id= ?))"));
		
		preparedStmts.put("estimateRequests", dbConnection.prepareStatement(
				"SELECT er_id, er_description, remaining_days " +
				"FROM marche_halibaba.list_estimate_requests " +
				"WHERE er_pub_date + INTERVAL '15' day >= NOW() AND " +
				"er_chosen_estimate IS NULL "));
		
		preparedStmts.put("submit_estimate", dbConnection.prepareStatement(
				"SELECT marche_halibaba.submit_estimate(?, ?, ?, ?, ?, ?, ?)"
				));
		
		preparedStmts.put("add_option", dbConnection.prepareStatement(
				"SELECT marche_halibaba.add_option(?, ?, ?)"));

		preparedStmts.put("list_options", dbConnection.prepareStatement(
				"SELECT o.option_id, o.description, o.price "+
				"FROM marche_halibaba.options o "+
				"WHERE house_id= ?"));
		
		preparedStmts.put("statistics", dbConnection.prepareStatement(
				"SELECT h.name, h.turnover, h.acceptance_rate, " + 
				"h.caught_cheating_nbr, h.caught_cheater_nbr " +
				"FROM marche_halibaba.houses h "));
		
		preparedStmts.put("valid_estimates", dbConnection.prepareStatement(
				"SELECT h_valid_estimates_nbr "+
				"FROM marche_halibaba.valid_estimates_nbr "+
				"WHERE h_id= ?"));
		
		preparedStmts.put("modify_option", dbConnection.prepareStatement(
				"SELECT marche_halibaba.modify_option(?,?,?,?) "));

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
					houseId= rs.getInt(1);
					isUsing= false;
				} else {
					System.out.println("\nVotre nom d'utilisateur et/ou mot de passe est errone.");
					System.out.println("Voulez-vous reessayer? Oui (O) - Non (N)");
					
					if(!Utils.readOorN()) {
						isUsing = false;
					}
				}
				
				rs.close();
			} catch (NoSuchAlgorithmException e) {
				e.printStackTrace();
			} catch (InvalidKeySpecException e) {
				e.printStackTrace();
			}
		}
		
		return houseId > 0;
	}
	
	private boolean signup() throws SQLException{
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
			
			PreparedStatement ps = preparedStmts.get("signup");
			ps.setString(1, username);
			ps.setString(2, pswd);
			ps.setString(3, name);
			ResultSet rs = null;
			
			try {
				rs = ps.executeQuery();
				rs.next();
				
				System.out.println("\nVotre compte a bien été créé.");
				System.out.println("Vous allez maintenant être redirigé vers la page d'accueil de l'application.");
				Utils.blockProgress();
				
				houseId = rs.getInt(1);
				isUsing = false;
			} catch (SQLException e){
				
				e.printStackTrace();
				
				if(e.getSQLState().equals("23505")){
					System.out.println("\nCe nom d'utilisateur est déjà utilise.");
				} else {
					System.out.println("\nLes données saisies sont incorrectes.");
				}
				
				System.out.println("Voulez-vous reessayer? Oui (O) - Non (N)");
				
				if(!Utils.readOorN()) {
					isUsing = false;
				}
			
			} finally {
				
				if(rs != null){
					rs.close();
				}
				
			}
	
		}
		
		return houseId > 0;
	}
	
	private void menu() throws SQLException{
				
		boolean isUsing = true;
		while(isUsing) {
			System.out.println("\nMenu");
			System.out.println("************************************************\n");

			System.out.println("1. Lister les demandes de devis en cours");
			System.out.println("2. Ajouter des options au catalogue d'options");
			System.out.println("3. Modifier des options du catalogue d'options");
			System.out.println("4. Statistiques");
			System.out.println("5. Se déconnecter");
			
			System.out.println("\nQue désirez-vous faire ? (1 - 5)");
			int choice = Utils.readAnIntegerBetween(1, 5);
			
			switch(choice) {
			case 1:
				displayEstimateRequests();
				break;
			case 2:
				addOption();
				break;
			case 3:
				modifyOption();
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


private void displayEstimatesForRequest(int requestId) throws SQLException {

	HashMap<Integer, Integer> estimates = new HashMap<Integer, Integer>(); 
	String estimateStr = "";
	

	PreparedStatement ps = preparedStmts.get("estimates");
	ps.setInt(1, requestId);
	ps.setInt(2, houseId);
	ResultSet rs = ps.executeQuery();
	
	int j=  1;
	while(rs.next()) {
		if(rs.getInt(4)== requestId){
			estimates.put(j, rs.getInt(4));
			estimateStr += j+ ". "+ rs.getString(1) + 
					"\n\tPrix: " + rs.getDouble(2) +
				"\n\tSoumis le : "+rs.getDate(3)+
				"\n\tDevis soumis par la maison: "+rs.getString(5)+"\n\n";
			j++;
		}
		
	}
	rs.close();
		

	
	if(estimates.size() > 0) {
		System.out.println(estimateStr);
		System.out.println("Que voulez-vous faire ? (1 - 2)");
		System.out.println("1. Soumettre un nouveau devis pour cette demande");
		System.out.println("2. Retour");
		int userChoice= Utils.readAnIntegerBetween(1, 2);
		
		if(userChoice== 1)
			submitEstimate(requestId);

	} else {
		System.out.println("Il n'y a aucun devis pour la demande en question\n");
		System.out.println("Que voulez-vous faire ?(1 - 2)\n");
		System.out.println("1. Soumettre un nouveau devis pour cette demande");
		System.out.println("2. Retour au menu");
		int userChoice= Utils.readAnIntegerBetween(1, 2);
		
		if(userChoice== 1)
			submitEstimate(requestId);
		
	}
		
}


private void displayEstimateRequests() throws SQLException{
	
	HashMap<Integer, Integer> estimateRequests = new HashMap<Integer, Integer>(); 
	String estimateRequestsStr = "";
	
	PreparedStatement ps = preparedStmts.get("estimateRequests");
	ResultSet rs = ps.executeQuery();
	
	int i = 1;
	while(rs.next()) {
		estimateRequests.put(i, rs.getInt(1));
		estimateRequestsStr += i + ". " + rs.getString(2) + 
		"\n\tTemps restant: " + Utils.SQLIntervalToString(rs.getString(3)) + "\n\n";
		i++;
	}
	rs.close();

	if(estimateRequests.size() > 0) {
		System.out.println(estimateRequestsStr);
		
		System.out.println("Que voulez-vous faire ? (1 - 2)");
		System.out.println("1. Consulter les devis soumis pour une demande");
		System.out.println("2. Retour");
		
		if(Utils.readAnIntegerBetween(1, 2) == 1) {
			System.out.println(estimateRequestsStr);
			System.out.println("Pour quelle demande voulez-vous voir les devis soumis?");
			int userChoice = Utils.readAnIntegerBetween(1, estimateRequests.size());
			displayEstimatesForRequest(estimateRequests.get(userChoice));
			
		}
		
	} else {
		System.out.println("Il n'y a aucune demande de devis en cours\n");
		Utils.blockProgress();
	}
		
}


private void submitEstimate(int estimateRequest) throws SQLException{
	
	System.out.println("Soumettre un devis");
	System.out.println("******************");
	
	System.out.println("Description:");
	String description = Utils.scanner.nextLine();
	
	System.out.println("Prix du devis:");
	double price= Utils.readADoubleBetween(0, 1000000000.0);
	
	System.out.println("Voulez-vous que le devis soit caché? Oui (O) - Non (N)");
	boolean secret= Utils.readOorN();
	
	System.out.println("Voulez-vous que le devis soit masquant? Oui (O) - Non (N)");
	boolean hiding= Utils.readOorN();
	
	System.out.println("Voulez-vous rajouter des options ? Oui (O) - Non (N)");
	boolean options= Utils.readOorN();
	
	ArrayList<Integer> choosedOptions= new ArrayList<>();
	
	while(options){

		System.out.println("Menu des options");
		System.out.println("****************");
		System.out.println("1.Sélectionner une option existante dans le catalogue d'options");
		System.out.println("2.Ajouter une nouvelle option au calatogue et l'utiliser pour le devis");
		System.out.println("3.Soumettre le devis avec les options sélectionnées");
		
		System.out.println("\nQue désirez-vous faire ? (1 - 3)");
		int userChoice= Utils.readAnIntegerBetween(1, 3);
		switch(userChoice){
			case 1:
				
				int selectedOption= selectOption();
				if(choosedOptions.contains(selectedOption)){
					System.out.println("Veuillez choisir des options pas encore choisies\n");
				
				}else if(selectedOption == -1){
					
				}else{
					choosedOptions.add(selectedOption);
					System.out.println("L'option a correctement été ajoutée pour le devis\n");
				}
			
				break;
				
			case 2:
				
				int optionId = addOption();
				if(optionId != -1)
					choosedOptions.add(optionId);
				else
					System.out.println("L'ajout d'option a échoué");
				break;
				
			case 3:
				options= false;
				break;
		}
			
	}
	
	try{
		
		PreparedStatement ps = preparedStmts.get("submit_estimate");
		ps.setString(1, description);
		ps.setBigDecimal(2, new BigDecimal(price));
		ps.setBoolean(3, secret);
		ps.setBoolean(4, hiding);
		ps.setInt(5, estimateRequest);
		ps.setInt(6, houseId);
		
		Object[] userChoices= new Object[choosedOptions.size()];
		for (int i = 0; i < choosedOptions.size(); i++) {
			userChoices[i]= choosedOptions.get(i);
		}
		
		Array chosenOptions= dbConnection.createArrayOf("integer", userChoices);
		
		ps.setArray(7, chosenOptions);
				
		ps.executeQuery();
		
		System.out.println("Le devis a été soumis correctement !\n");
		Utils.blockProgress();
		
		
	}catch(SQLException e){
		String message= e.getMessage();
		System.out.println(message.split("\n")[0]);
		
	}
	
}

private int selectOption() throws SQLException{
	
	HashMap<Integer, Integer> options = new HashMap<Integer, Integer>(); 
	String optionsStr = "";
	
	PreparedStatement ps = preparedStmts.get("list_options");
	ps.setInt(1, houseId);
	ResultSet rs = ps.executeQuery();
	
	int i = 1;
	while(rs.next()) {
		options.put(i, rs.getInt(1));
		optionsStr += i + ". " + rs.getString(2) + 
			"\n\tPrix de l'option: " + rs.getDouble(3) + "\n\n";
		i++;
	}
	rs.close();
	
	if(options.size() > 0){
		System.out.println(optionsStr);
		
		System.out.println("Voulez-vous ajouter une de ces options? Oui (O) - Non (N)");
		if(Utils.readOorN()){
			
			System.out.println(optionsStr);
			System.out.println("Quelle option voulez-vous ajouter? 1 - "+ options.size());
			return options.get(Utils.readAnIntegerBetween(1, options.size()));
			
		}
		
	}else{
		System.out.println("Vous n'avez pas encore d'options dans votre catalogue");
	}
	
	return -1;
	
}

private int addOption() throws SQLException{
	
	System.out.println("Ajout d'une nouvelle option");
	System.out.println("***************************");
	System.out.println("Veuillez entrer une description pour l'option");
	String description = Utils.scanner.nextLine();
	System.out.println("Veuillez entrer un prix pour cette option");
	double price= Utils.readADoubleBetween(0, 1000000000.0);
	
	PreparedStatement ps = preparedStmts.get("add_option");
	
	ps.setString(1,description);
	
	ps.setBigDecimal(2, new BigDecimal(price));
	
	ps.setInt(3, houseId);
	
	ResultSet result= ps.executeQuery();
	result.next();
	
	int optionId= result.getInt(1);
	result.close();
	
	System.out.println("Votre option a bien été ajoutée !\n\n");
	
	return optionId;

}

private void displayStatistics() throws SQLException {

	System.out.println("\nStatistiques des maisons");
	System.out.println("************************************************");
	
	PreparedStatement ps = preparedStmts.get("statistics");
	ResultSet rs = ps.executeQuery();
		
	while(rs.next()) {
		System.out.println("\n" + rs.getString(1));
		System.out.println("\tChiffre d'affaire: " + rs.getDouble(2) + " €");
		System.out.println("\tTaux d'acceptation: " + (rs.getDouble(3)*100) + " %");
		System.out.println("\tNombre de fois que la maison s'est fait attraper en train de tricher : " + rs.getInt(4) + " fois");
		System.out.println("\tNombre de fois que la maison a attrapé un tricheur : " + rs.getInt(5) + " fois");
	}
	rs.close();
	
	ps = preparedStmts.get("valid_estimates");
	ps.setInt(1, houseId);
	rs = ps.executeQuery();
	rs.next();
	
	System.out.println("\nVous avez actuellement "+
	rs.getBigDecimal(1)+" devis en cours de soumission.");
	rs.close();
	
	Utils.blockProgress();		
}

private void modifyOption() throws SQLException{
	
	System.out.println("Modification d'une option");
	System.out.println("*************************");
	
	HashMap<Integer, Integer> options = new HashMap<Integer, Integer>(); 
	String optionsStr = "";
	
	PreparedStatement ps = preparedStmts.get("list_options");
	ps.setInt(1, houseId);
	ResultSet rs = ps.executeQuery();
	
	int i = 1;
	while(rs.next()) {
		options.put(i, rs.getInt(1));
		optionsStr += i + ". " + rs.getString(2) + 
			"\n\tPrix de l'option: " + rs.getDouble(3) + "\n\n";
		i++;
	}
	rs.close();
	
	if(options.size() > 0){
		System.out.println(optionsStr);
		
		System.out.println("Quelle option voulez-vous modifier? 1 - "+ options.size());
		int userChoice= options.get(Utils.readAnIntegerBetween(1, options.size()));
		
		System.out.println("\nModification de l'option");
		System.out.println("***************************");
		System.out.println("Veuillez entrer une description pour l'option");
		String description = Utils.scanner.nextLine();
		
		System.out.println("Veuillez entrer un prix pour cette option");
		double price= Utils.readADoubleBetween(0, 1000000000.0);
		
		ps = preparedStmts.get("modify_option");
		
		ps.setString(1,description);
		ps.setBigDecimal(2, new BigDecimal(price));
		ps.setInt(3, userChoice);
		ps.setInt(4, houseId);
		
		ps.executeQuery();
		System.out.println("L'option a été modifiée avec succès !\n");
		
	}else{
		
		System.out.println("Vous n'avez pas encore d'options dans votre catalogue");
		Utils.blockProgress();
		System.out.println("\n\n");
		
	}
	
}


}
