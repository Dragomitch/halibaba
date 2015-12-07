package marche_halibaba;

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
		System.out.println("\n[Appuyez sur ENTER pour continuer]");
        
		try {
            scanner.nextLine();
        } catch(Exception e) {}

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
        			System.out.println("Le nombre doit être compris entre " + number1 + " et " + number2 + ". Veuillez recommencer.");
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
	
	public static int[] readIntegersBetween(int number1, int number2) {
		int[] integers = null;
		
		boolean isLegal = false;
		while(!isLegal) {
			String str = scanner.nextLine();
			str = str.replaceAll("[^-?0-9]+", "-");
		    String[] strs = str.split("-");
		    integers = new int[strs.length];
		    
		    if(strs.length == 0) {
		    	System.out.println("Veuillez entrer des nombres compris entre " + number1 + " et " + number2 + ".");
		    } else {
		    	isLegal = true;
		    }
		    
		    for(int i=0; i<strs.length; i++) {
		    	int j = Integer.parseInt(strs[i]);
		    	
		    	if(j < number1 || j > number2) {
		    		System.out.println("Les nombres doivent être compris entre " + number1 + " et " + number2 + ". Veuillez recommencer.");
		    		isLegal = false;
		    		break;
		    	}
		    	
		    	integers[i] = j;
		    }
		    
		}

	    return integers;
	}
	
	public static String SQLIntervalToString(String interval) {
		String str = "";
		
		String days = interval.substring(0, 2).replaceAll(" ", "");
		String hours = interval.replaceAll("[0-9]{1,2} days ", "").replaceAll("[0-9] day ", "").substring(0, 2).replaceAll(":", "");
		
		str = days + " jour(s) " + hours + " heure(s) restant(s)";
	
		return str;
	}
	
	public static boolean readOorN(){
		char response = scanner.nextLine().charAt(0);
		
		while (response != 'O' && response != 'o' &&
				response != 'N' && response != 'n'){
			System.out.println("Veuillez répondre O (oui) ou N (non).");
			response = scanner.nextLine().charAt(0);
		}
		
		return response == 'O' || response == 'o';
	}

}