import java.sql.DriverManager;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class MsSQL {

	public static void main(String[] args) throws SQLException, ClassNotFoundException {
		//System.out.println(args.length);
		System.out.println(args[0]);
		System.out.println(args[1]);
		Class.forName("com.microsoft.sqlserver.jdbc.SQLServerDriver");
		Connection conn = DriverManager.getConnection(args[0]);
		Statement sta = conn.createStatement();
		String Sql = args[1];
		ResultSet rs = sta.executeQuery(Sql);
		while (rs.next()) {
			System.out.println(rs.getString("req_date"));
		}
	}
}