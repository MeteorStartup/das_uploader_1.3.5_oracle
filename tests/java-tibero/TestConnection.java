import java.sql.Connection;
import java.sql.*;

public class TestConnection
{
    Connection        conn   = null;
    Statement         stmt   = null;
    ResultSet         rs     = null;
    String            strSQL = null;


    String DB_DRV    = "com.tmax.tibero.jdbc.TbDriver";


    //String DB_IP     = "";
    String DB_IP     = "152.99.160.22";
    String DB_PORT   = "8629";
    String DB_SID    = "tibero";
    String DB_ID     = "dasusers";
    String DB_PWD    = "dasusers123";
    String DB_URL    = "jdbc:tibero:thin:@"+DB_IP+":"+DB_PORT+":"+DB_SID;



    public TestConnection()
    {
    }



    public void connect()
    {
        try
        {
            System.out.println("=====================================");
            System.out.println("DB_DRV : " + DB_DRV);
            System.out.println("DB_PWD : " + DB_IP);
            System.out.println("DB_PWD : " + DB_PORT);
            System.out.println("DB_SID : " + DB_SID);
            System.out.println("DB_ID  : " + DB_ID);
            System.out.println("DB_PWD : " + DB_PWD);
            System.out.println("DB_URL : " + DB_URL);
            System.out.println("-------------------------------------");

            Class.forName(DB_DRV);
            conn = DriverManager.getConnection(DB_URL, DB_ID, DB_PWD);

            System.out.println("Tibero Connect Success");
            System.out.println("=====================================");
            System.out.println("");
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
        }
    }



    public void excute(String query)
    {
        try
        {
            strSQL = "select * from dual";  //test query
            stmt = conn.createStatement();
            rs = stmt.executeQuery(query);
            System.out.println("=====================================");
            System.out.println("SQL : " + strSQL);
            System.out.println("-------------------------------------");
            while ( rs.next() )
            {
                System.out.println("SID        : " + rs.getString(1));
                System.out.println("USERNAME   : " + rs.getString(2));
                System.out.println("SQL_ID     : " + rs.getString(3));
                System.out.println("LOGON_TIME : " + rs.getString(4));
                System.out.println("=====================================");
            }
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
            disconnect();
        }
    }



    public void disconnect()
    {
        try
        {
            if (rs   != null)   rs.close();
            if (stmt != null)   stmt.close();
            if (conn != null)   conn.close();
        }
        catch (Exception ex)
        {
            ex.printStackTrace();
        }
        finally
        {
            if ( rs    != null ) try { rs   .close(); } catch(Exception e) {}
            if ( stmt  != null ) try { stmt .close(); } catch(Exception e) {}
            if ( conn  != null ) try { conn .close(); } catch(Exception e) {}
        }
    }



    public static void main (String [] args)
    {
        System.out.println(args[0]);    //dbinfo 받아오긴 하지만 일단 하드코딩임
        System.out.println(args[1]);    // query
        System.out.println(args[2]);    //ID 받아오긴 하지만 일단 하드코딩임
        System.out.println(args[3]);    //PW 받아오긴 하지만 일단 하드코딩임


        TestConnection test = new TestConnection();

        test.connect();
        test.excute(args[1]);
        test.disconnect();
    }
}