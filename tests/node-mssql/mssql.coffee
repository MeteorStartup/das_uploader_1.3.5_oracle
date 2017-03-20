cl = console.log
mssql = require 'mssql'

config =
  user: 'samUser'
  password: '!@#User'
  server: '152.99.147.11'
  port: '1433'
  database: 'samcheok_2009'

mssql.connect(config).then ->
  new mssql.Request().query('select count(*) from DUAL').then (recordset) ->
    cl 'recordset'
    cl recordset
    mssql.close()
  .catch (err) ->
    cl 'err'
    cl err.toString()
    mssql.close()
.catch (err) ->
  cl err.toString()
  mssql.close()



