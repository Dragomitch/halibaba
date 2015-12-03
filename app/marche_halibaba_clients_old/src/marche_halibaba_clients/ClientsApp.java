package marche_halibaba_clients;

import java.io.UnsupportedEncodingException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.SQLException;
import java.util.Scanner;

public class ClientsApp {
	
	static String environment;
	static Client authenticatedClient;
	static Scanner scanner = new Scanner(System.in);

	public static void main(String[] args) throws SQLException, NoSuchAlgorithmException, InvalidKeySpecException, UnsupportedEncodingException {
		
		if(args.length == 2 && args[0].equals("--env") && args[1].equals("dev")) {
			ClientsApp.environment = "dev";
		} else {
			ClientsApp.environment = "prod";
		}
		
		authenticatedClient = Db.getInstance().signIn("jeremy", "blublu");
		System.out.println(authenticatedClient);
		
		EstimateRequest[] er = Db.getInstance().listEstimateRequests("submitted", authenticatedClient);
		
		for(int i = 0; i<er.length; i++)
			System.out.println(er[i]);
		
		/*System.out.println("Bienvenue sur le marché d'Halibaba - Application clients");
		System.out.println("--------------------------------------------------------");
		System.out.println("1. Se connecter");
		System.out.println("2. S'enregistrer");
		System.out.println("Que voulez-vous faire ? (1 - 2)");
		scanner.nextInt();*/
	}

}
