cl = console.log
mysql = require 'mysql'

mysqlDB = mysql.createConnection
  host: 'localhost'
  port: '3306'
  user: 'dh'
  password: 'ehdgo170'
  database: 'dh'
mysqlDB.connect (err) ->
  cl err?.message or 'success'
mysqlDB.query 'select * from TEST_TABLE;', (err, rows, fields) ->
  cl err or rows
mysqlDB.end()

