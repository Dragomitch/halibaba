package marche_halibaba_clients;

import java.text.DateFormat;
import java.text.ParseException;
import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.InputMismatchException;
import java.util.Locale;
import java.util.Scanner;

public class Utils {
	public static Scanner scanner = new Scanner(System.in);
	
	public static void blockProgress() {
		System.out.println("[Appuyez sur ENTER pour continuer]");
        
		try {
            scanner.nextLine();
        } catch(Exception e) {
        	e.printStackTrace();
        }

	}	

	public static int readAnIntegerBetween(int number1, int number2){
		int number = 0;
		
		boolean isLegal = false;
        while(!isLegal) {
        	
        	try {
        		number = scanner.nextInt();
        		
        		if(number>=number1 && number<=number2) {
        			isLegal = true;
        		} else {
        			System.out.println("Le nombre doit etre compris entre " + number1 + " et " + number2 + ". Veuillez recommencer.");
        		}
        		
        		
        	} catch(InputMismatchException e) {
        		System.out.println("Vous ne pouvez entrer que des chiffres. Veuillez recommencer.");
        	} finally {
        		scanner.nextLine();
			}
        
        }

        return number;
	}
	
	public static Date readDate() {
		Date date = null;
		
		boolean isLegal = false;
		while(!isLegal) {
			String str = scanner.nextLine();
			
			DateFormat format = new SimpleDateFormat("dd/MM/yyyy", Locale.ENGLISH);
			
			try {
				date = format.parse(str);
				isLegal = true;
			} catch (ParseException e) {
				System.out.println("Veuillez entrer une date au format correct (jj/mm/aaaa).");
			}

		}
				
		return date;
	}
	
	public static boolean readOorN(){
		char response = scanner.nextLine().charAt(0);
		
		while (response != 'O' && response != 'N'){
			System.out.println("Veuillez répondre O (oui) ou N (non).");
			response = scanner.nextLine().charAt(0);
		}
		
		return response == 'O';
	}

}