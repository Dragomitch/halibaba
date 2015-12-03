package marche_halibaba_clients;

import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.security.NoSuchAlgorithmException;
import java.security.spec.InvalidKeySpecException;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Timestamp;
import java.util.Date;
import java.util.Properties;

public final class Db {
	private static Db instance = null;
	private Connection connection;
	
	private Db(){
		
		Properties props = new Properties();
		FileInputStream input = null;
		
		try {
			input = new FileInputStream("config.properties");
			props.load(input);
		} catch (FileNotFoundException e) {
			e.printStackTrace();
			System.exit(1);
		} catch (IOException e) {
			e.printStackTrace();
			System.exit(2);
		} finally {
			
			if (input != null) {
			
				try {
					input.close();
				} catch (IOException ignore) {}
			
			}
			
		}
		
		try {
			Class.forName("org.postgresql.Driver");
		} catch (ClassNotFoundException e) {
			System.out.println("Driver PostgreSQL manquant !"); System.exit(1);
		}
		
		String url = "";
		
		if(ClientsApp.environment.equals("prod")) {
			url = "jdbc:postgresql://" + props.getProperty("prod_db_host") + ":" +
					props.getProperty("prod_db_port") + "/" +
					props.getProperty("prod_db_name") +
					"?user=" + props.getProperty("prod_db_username") +
					"&password=" + props.getProperty("prod_db_password");
		} else {
			url = "jdbc:postgresql://" + props.getProperty("dev_db_host") + ":" +
					props.getProperty("dev_db_port") + "/" +
					props.getProperty("dev_db_name") +
					"?user=" + props.getProperty("dev_db_username") +
					"&password=" + props.getProperty("dev_db_password");
		}
		
		System.out.println(url);
		
		try {
			this.connection = DriverManager.getConnection(url);
		} catch (SQLException e) {
			System.out.println("Impossible de joindre le server !");
			System.exit(1);
		}
		
	} 
	
	public final static Db getInstance() {
		
		if(Db.instance == null) {
			synchronized (Db.class) {
				if(Db.instance == null) {
					Db.instance = new Db();
				}
			}
		} 
		
		return Db.instance;		
	}
	
	
	/**
	 * Authenticates an user
	 * @param username
	 * @param pswd
	 * @return a Client Object; null if the authentication was unsuccessful
	 * @throws SQLException if a database access error occurs
	 */
	public Client signIn(String username, String pswd) throws SQLException {
		PreparedStatement ps = connection.prepareStatement("SELECT c_id, c_first_name, c_last_name, c_pswd " +
				"FROM marche_halibaba.signin_client " +
				"WHERE c_username = ?");
		ps.setString(1, username);
		ResultSet result = ps.executeQuery();
		
		if(!result.next()) {
			return null;
		}
		
		try {
			if(!PasswordHash.validatePassword(pswd, result.getString(4))) {
				return null;
			}
		} catch (NoSuchAlgorithmException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		} catch (InvalidKeySpecException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
		
		return new Client(result.getInt(1), result.getString(2), result.getString(3));
	}
	
	
	public Client signUp(String username, String pswd, String firstName, String lastName) throws SQLException {
		
		try {
			pswd = PasswordHash.createHash(pswd);
		} catch (NoSuchAlgorithmException e) {
			e.printStackTrace();
		} catch (InvalidKeySpecException e) {
			e.printStackTrace();
		}
		
		PreparedStatement ps = connection.prepareStatement("SELECT marche_halibaba.signup_client(?, ?, ?, ?)");
		ps.setString(1, username);
		ps.setString(2, pswd);
		ps.setString(3, firstName);
		ps.setString(4, lastName);
		ResultSet result = ps.executeQuery();
		result.next();
		
		return new Client(result.getInt(1), firstName, lastName);
	}
	
	public EstimateRequest[] listEstimateRequests(String status, Client client) throws SQLException {
		String query = "SELECT er.estimate_request_id, er.description, er.deadline, er.pub_date " +
				"FROM marche_halibaba.estimate_requests er ";
		
		if(status.equals("approved")) {
			query += "WHERE er.chosen_estimate IS NOT NULL AND " +
					"er.client_id = ? ";
		} else if(status.equals("expired")) {
			query += "WHERE er.pub_date + INTERVAL '15' day < NOW() AND " +
					"er.chosen_estimate IS NULL AND " +
					"er.client_id = ? ";			
		} else {
			query += "WHERE er.pub_date + INTERVAL '15' day >= NOW() AND " +
					"er.chosen_estimate IS NULL AND " +
					"er.client_id = ? ";
		}
	
		query += "ORDER BY er.pub_date DESC";
		PreparedStatement ps = connection.prepareStatement(query, ResultSet.TYPE_SCROLL_SENSITIVE, 
                ResultSet.CONCUR_UPDATABLE);
		ps.setInt(1, client.getId());
		ResultSet rs = ps.executeQuery();
		
		int rowsNbr = getRowsNbr(rs);
		EstimateRequest[] estimateRequests = new EstimateRequest[rowsNbr];
		
		for(int i=0; rs.next(); i++) {
			estimateRequests[i] = new EstimateRequest(rs.getInt(1), rs.getString(2), null, null);
		}
		
		return estimateRequests;
	}
	
	public Estimate[] listEstimatesFor(int estimateRequestId) throws SQLException {
		String query = "SELECT e_id, e_description, e_price, e_submission_date, e_house_id, e_house_name" +
				"FROM marche_halibaba.clients_list_estimates " +
				"WHERE e_estimate_request_id = ?" +
				"ORDER BY e_submission_date DESC";
		PreparedStatement ps = connection.prepareStatement(query, ResultSet.TYPE_SCROLL_SENSITIVE, 
                ResultSet.CONCUR_UPDATABLE);
		ps.setInt(1, estimateRequestId);
		ResultSet rs = ps.executeQuery();
		
		int rowsNbr = getRowsNbr(rs);
		Estimate[] estimates = new Estimate[rowsNbr];
		
		for(int i=0; rs.next(); i++) {
			estimates[i] = new Estimate();
		}
		
		return estimates;
	}
	
	public Estimate getEstimateDetails(int estimateId) {
		
		
		return null;
	}
	
	private int getRowsNbr(ResultSet rs) throws SQLException {
		int rowsNbr = 0;
		
		while(rs.next()) {
			rowsNbr++;
		}
		
		rs.beforeFirst();
		return rowsNbr;
	}
 	

}
