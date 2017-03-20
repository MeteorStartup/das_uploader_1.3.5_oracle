#!/bin/sh
javac MsSQL.java
java MsSQL "jdbc:sqlserver://152.99.147.11:1433;user=samUser;password=!@#User;database=samcheok_2009" "select top 1 * from fbcb_board_file;"