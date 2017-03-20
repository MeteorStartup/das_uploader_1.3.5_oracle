import java.io.OutputStream;
import java.net.HttpURLConnection;
import java.net.URL;
import java.net.URLConnection;
import java.nio.charset.StandardCharsets;

public class Test {

    public static void main(String[] args) {
        try {
            URL url = new URL("http://152.99.160.20:4000/DASInfo");
            URLConnection con = url.openConnection();
            HttpURLConnection http = (HttpURLConnection)con;
            http.setRequestMethod("POST"); // PUT is another valid option
            http.setDoOutput(true);

            // 아래 out 변수의 데이터들을 \n로 구분하셔서 항목별로 채워주시면 됩니다.
            byte[] out = "REQ_DATE=20160102010101001\nCUR_IP=10.0.0.24\nSERVICE_ID=SVC00001\nBOARD_ID=BRD00001\nPOST_ID=b3899283\nDEL_FILE_LIST=/Users/jwjin/data/images/11.jpg, /Users/jwjin/data/images/2.jpg\nDEL_DB_URL=\nDEL_DB_QRY=delete * from Table where condition;\nDEL_DB_CHECK_QRY=SELECT COUNT(column_name) FROM table_name;\nUP_FSIZE=3038920\nDEL_DATE=20160102000000000\nLOG=\n".getBytes(StandardCharsets.UTF_8);
            int length = out.length;

            http.setFixedLengthStreamingMode(length);
            http.setRequestProperty("Content-Type", "text/plain; charset=UTF-8");
            http.connect();
            try(OutputStream os = http.getOutputStream()) {
                os.write(out);
            }

        }
        catch(Exception e) {
            System.out.println(e.toString());
        }
    }
}
