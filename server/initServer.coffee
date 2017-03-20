cl = console.log
fiber = require 'fibers'

#  admin 등 기본 셋팅이 들어가야 한다

Meteor.startup ->

#  [1...10].forEach (n) ->
#    cl n
#    #MsSQL Test
#    dbInfo = "jdbc:sqlserver://52.78.177.44;user=sa;password=mStartup!24;database=dasuploader"
#    query = "select * from dasuploader.dasuploader"
#    cp = require 'child_process'
#    cl 'cd /Users/jwjin/WebstormProjects/das_uploader/tests/java-mssql && javac MsSQL.java && java MsSQL "'+ dbInfo + '" "'+ query + '"'
#    cp.exec 'cd /Users/jwjin/WebstormProjects/das_uploader/tests/java-mssql && javac MsSQL.java && java MsSQL "'+ dbInfo + '" "'+ query + '"', (err,stdout,stderr) ->
#      cl err or stdout or stderr

#  spawn = require('child_process').spawn
#  ls = spawn('cd /Users/jwjin/WebstormProjects/das_uploader/tests/java-mssql/ && java', ['MsSQL'])

#  ls.stdout.on 'data', (data) =>
#    console.log("stdout: #{data}")
#
#  ls.stderr.on 'data', (data) =>
#    console.log("stderr: #{data}")
#
#  ls.on 'close', (code) =>
#    console.log("child process exited with code #{code}}")



  #  reset 시 테스트 환경을 위한 데이터
  unless CollectionServices.findOne()
    agent = dataSchema 'Agent'
    agent.AGENT_NAME = 'dasAgent'
    agent.AGENT_URL = 'http://localhost:3000'
    agent.소멸정보절대경로 = '/home/tmax/das/dasFiles'
    agent_id = CollectionAgents.insert agent

    svcInfo = dataSchema 'Service'
    svcInfo.SERVICE_ID = 'www'
    svcInfo.SERVICE_NAME = '강릉'
    svcInfo.파일처리옵션 = '삭제'
    svcInfo.AGENT정보.push {
      agent_id: agent_id
      파일삭제기능: true
    }
    svcInfo.DB정보 = {
      DB이름: 'Oracle'      #DB 별명
      DB접속URL: 'oracle://152.99.143.198:1521/GNWEB'   #jdbc:mysql://14.63.225.39:3306/das_demo?characterEncoding=UTF8
      DBMS종류: 'Oracle'    #MsSQL/MySQL/Oracle
      DB_IP: '152.99.143.198'
      DB_PORT: '1521'
      DB_DATABASE: 'GNWEB'  #DB name (or SID)
      DB_ID: 'DAL'       #ID
      DB_PW: 'dal'
    }
    CollectionServices.insert svcInfo

#    svcInfo = dataSchema 'Service'
#    svcInfo.SERVICE_ID = 'SVC00002'
#    svcInfo.SERVICE_NAME = 'das서비스2'
#    svcInfo.파일처리옵션 = '삭제'
##    svcInfo.AGENT정보.push agent_id
#    svcInfo.DB정보 = {
#      DB이름: 'TestDB'      #DB 이름
#      DB접속URL: 'mysql://localhost:3306/test'   #jdbc:mysql://14.63.225.39:3306/das_demo?characterEncoding=UTF8
#      DBMS종류: 'MySQL'    #MsSQL/MySQL/Oracle
#      DB_IP: 'localhost'
#      DB_PORT: '3306'
#      DB_DATABASE: 'test'
#      DB_ID: 'TestID'       #ID
#      DB_PW: 'TestPW'
#    }
#    CollectionServices.insert svcInfo

#    statTotal = dataSchema '용량통계'
#    statTotal.SERVICE_ID = 'SVC00001'
#    CollectionSizeInfos.insert statTotal


  unless Meteor.users.findOne(username: 'admin')
    cl 'initServer/make admin'
    options = {}
    options.username = 'admin'
    options.password = 'admin123@'
    options.profile = dataSchema 'profile'
    options.profile['사용권한'] = '관리자'
    options.profile['이름'] = '관리자'
    options.profile['상태'] = '사용'
    Accounts.createUser options

#
    # jwjin/1609240951 agent test
#  HTTP.post "http://localhost:3000/removeFiles",
#    data:
#      DEL_FILE_LIST: 'test'
#      DEL_OPTION: 0
#      BACKUP_PATH: true
#  , (err, rslt) ->
#    cl err or rslt
