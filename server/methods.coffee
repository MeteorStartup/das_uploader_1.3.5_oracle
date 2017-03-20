mysql = require 'mysql'
future = require 'fibers/future'
mssql = require 'mssql'
#oracle = require('oracle')

Meteor.startup ->
  cl 'methods'
  HTTP.methods
    'getAgentSetting': (data) ->
      cl 'getAgentSetting'
      try
        agent = CollectionAgents.findOne('AGENT_URL': data.AGENT_URL)
      catch err
        return throw new Meteor.Error err
      return agent
    'DASInfo': (data) ->
#      cl data
      bufUTF8 = new Buffer(data, 'utf8');
      console.log(bufUTF8.toString());
#      dasInfo = 'REQ_DATE=20160102010101001\nCUR_IP=10.0.0.24\nSERVICE_ID=SVC00001\nBOARD_ID=BRD00001\nPOST_ID=b3899283\nDEL_FILE_LIST=/Users/jwjin/data/images/11.jpg, /Users/jwjin/data/images/2.jpg\nDEL_DB_URL=\nDEL_DB_QRY=delete * from Table where condition;\nDEL_DB_CHECK_QRY=SELECT COUNT(column_name) FROM table_name;\nUP_FSIZE=3038920\nDEL_DATE=20160102000000000\nLOG=\n'
#      data = {
#        dasInfo: 'REQ_DATE=20160102010101001\nCUR_IP=10.0.0.24\nSERVICE_ID=SVC00001\nBOARD_ID=BRD00001\nPOST_ID=b3899283\nDEL_FILE_LIST=/Users/jwjin/data/images/11.jpg, /Users/jwjin/data/images/2.jpg\nDEL_DB_URL=\nDEL_DB_QRY=delete * from Table where condition;\nDEL_DB_CHECK_QRY=SELECT COUNT(column_name) FROM table_name;\nUP_FSIZE=3038920\nDEL_DATE=20160102000000000\nLOG=\n',
#        AGENT_URL: 'http://localhost:3000'
#      }
#      cl data
      HTTP.post "http://localhost:4000/insertDAS",
        data:
          dasInfo: bufUTF8.toString()
          AGENT_URL: 'http://localhost:3000'
      , (err, rslt) ->
        console.log err or rslt
    'insertDAS': (data) ->
      cl data.dasInfo
      dasInfo = dataSchema 'DASInfo'
      dasInfo.origin = data.dasInfo

      arrDasInfo =  data.dasInfo.split '\n'
#      cl arrDasInfo
#      originError = []  #연동파일 검증시 나는 오류를 담아놓는 array ## jwjin/1609250331 지워도 될 듯?
      arrDasInfo.forEach (line) ->
#      add field to object
        pos = line.indexOf '='
        key = line.substring 0, pos
        val = line.substring pos + 1
        val = val.trim()
#        cl val
#        cl val.length

        switch key
          when 'DEL_DB_QRY'
            arr_qry = val.split ';'
            arr_qry.forEach (qry, i) ->
              arr_qry[i] = qry.trim()
            arr_qry = arr_qry.filter (str) -> (str.length > 0)
            arr_qry.forEach (qry, i) ->
              arr_qry[i] = qry.trim()
            val = arr_qry
          when 'UP_FSIZE'
            val = val-0
          when 'REQ_DATE', 'DEL_DATE'
            unless val.length is 17
              unless Array.isArray dasInfo.STATUS
                dasInfo.STATUS = [dasInfo.STATUS]
              dasInfo.STATUS.push [key + ' length is not 17. check your .das file']
            val = val.trim()
            year = val.substring(0,4)
            month = val.substring(4,6) - 1
            date = val.substring(6,8)
            hour = val.substring(8,10)
            minute = val.substring(10,12)
            second = val.substring(12,14)
            mil = val.substring(14,17)

            val = new Date(year, month, date, hour, minute, second, mil)
          when 'DEL_FILE_LIST'
            val = val.split(',')
            val.forEach (path, i) -> return val[i] = path.trim()
            val = val.filter (str) -> (str.length > 0)
            val.forEach (path, i) -> return val[i] = path.trim()

        if key isnt '' and val isnt ''
          dasInfo[key] = val
#          #dasInfo was made

      try
        cl 'serviceID'
        cl dasInfo.SERVICE_ID
        service = CollectionServices.findOne(SERVICE_ID: dasInfo.SERVICE_ID)
        agent = CollectionAgents.findOne(AGENT_URL: data.AGENT_URL)
        dasInfo.AGENT_NAME = agent.AGENT_NAME or ''
        dasInfo.AGENT_URL = agent.AGENT_URL       #Unique value
        dasInfo.AGENT_URL_FROM_AGENT = data.AGENT_URL
        dasInfo.KEEP_PERIOD = Math.round(Math.abs((dasInfo.DEL_DATE.getTime() - dasInfo.REQ_DATE.getTime())/(24*60*60*1000)))
        unless service
#          #요청에 해당하는 서비스가 없다면 에러로 처리 및 기록
          unless Array.isArray dasInfo.STATUS
            dasInfo.STATUS = [dasInfo.STATUS]
          dasInfo.STATUS.push 'service not found when inserted'
        else
          dasInfo.SERVICE_NAME = service.SERVICE_NAME or ''
      catch err
#        서비스/에이전트 확인 에러 발생 시 status를 미리 결정 짓고 더 이상 처리 하지 않는다
        cl err
        dasInfo.STATUS = [err_when_inserted: err]

      # 2016.08.30 추가 POST_ID가 있으면 POST_ID로 먼저 동일 파일 검사 없으면 기존대로 처리
      #      #REQ_DATE / SERVICE_ID / BOARD_ID 이고 STATUS가 'wait'인놈은 DEL_DATE 수정으로 처리
      if (dasInfo.POST_ID? and (exist = CollectionDasInfos.findOne POST_ID: dasInfo.POST_ID, REQ_DATE: dasInfo.REQ_DATE, SERVICE_ID: dasInfo.SERVICE_ID, BOARD_ID: dasInfo.BOARD_ID)) or (exist = CollectionDasInfos.findOne REQ_DATE: dasInfo.REQ_DATE, SERVICE_ID: dasInfo.SERVICE_ID, BOARD_ID: dasInfo.BOARD_ID)
        if exist.STATUS is 'wait'
          CollectionDasInfos.update _id: exist._id, dasInfo
        else  #wait 일때만 업데이트하고 에러 혹은 이미 처리 된 건이라면 들어와서는 안되는 데이터라서 에러
          #이미처리된 건의 상태는 'success' 이거나 오류라면 array []
          if exist.STATUS is 'success' || Array.isArray exist.STATUS
            dasInfo.STATUS = exist.STATUS
            unless Array.isArray dasInfo.STATUS
              dasInfo.STATUS = [dasInfo.STATUS]
            dasInfo.STATUS.push '이미 처리 된 건이 수정으로 재 요청 되었습니다. 홈페이지 서버를 확인 해 주세요.'
          CollectionDasInfos.update _id: exist._id, dasInfo

      else
        #      #dasInfo 최종 입력
        CollectionDasInfos.insert dasInfo

        #boardID 수집, 처음 보는 BOARD_ID 가 들어오면 services.BOARD_IDS 에 push
        if dasInfo.BOARD_ID?.length > 0 and CollectionServices.find({SERVICE_ID:dasInfo.SERVICE_ID, BOARD_IDS: dasInfo.BOARD_ID}).count() is 0
          # jwjin/1609200356 board_ids가 최초에 없어도 빈 어레이를 넣을 수 있도록 수정.
          cl 'service??'
          cl service
          service.BOARD_IDS.push dasInfo.BOARD_ID
  #      #용량 통계 업데이트
        service.용량통계.업로드용량 += dasInfo.UP_FSIZE
        CollectionServices.update _id: service._id, service


#      #     용량 통계 추가
#      CollectionServices.findOne dasInfo.SERVICE_ID
#      sizeInfo = CollectionSizeInfos.findOne SERVICE_ID: dasInfo.SERVICE_ID
#      if sizeInfo?
#        sizeInfo.업로드용량 += dasInfo.UP_FSIZE
#        CollectionSizeInfos.update _id: sizeInfo._id, sizeInfo
#      else
#        sizeStatus = dataSchema '용량통계'
#        sizeStatus.SERVICE_ID = dasInfo.SERVICE_ID
#        sizeStatus.업로드용량 = dasInfo.UP_FSIZE
#        CollectionSizeInfos.insert sizeStatus
      return 'success'

Meteor.methods
  'runDMS': ->
    runDMS()
  'dbConnectionTest': (_dbObj) ->
    cl _dbObj
    switch _dbObj.DBMS종류
      when 'MsSQL'
      #MsSQL Test
#        dbInfo = "jdbc:sqlserver://52.78.177.44;user=sa;password=mStartup!24;database=dasuploader"
        cl "jdbc:sqlserver://#{_dbObj.DB_IP}:#{_dbObj.DB_PORT};user=#{_dbObj.DB_ID};password=#{_dbObj.DB_PW};database=#{_dbObj.DB_DATABASE}"
        dbInfo = "jdbc:sqlserver://#{_dbObj.DB_IP};user=#{_dbObj.DB_ID};password=#{_dbObj.DB_PW};database=#{_dbObj.DB_DATABASE}"
        query = "select * from dasuploader.dasuploader"
        cp = require 'child_process'
        fut = new future()
        cp.exec 'cd /Users/jwjin/WebstormProjects/das_uploader/tests/java-mssql && javac MsSQL.java && java MsSQL "'+ dbInfo + '" "'+ query + '"', (err,stdout,stderr) ->
          cl err or stderr or stdout
          fut.return err or stderr or 'success'
        return fut.wait()




#        try
#          connectUrl = "mssql://#{_dbObj.DB_ID}:#{_dbObj.DB_PW}@#{_dbObj.DB_IP}:#{_dbObj.DB_PORT}/#{_dbObj.DB_DATABASE}"
#          mssql.connect(connectUrl).then ->
#            new mssql.Request().query("").then (recordset) ->
#              mssql.close()
#              return 'success'
#            .catch (err) ->
#              mssql.close()
#              return err.toString()
#          .catch (err) ->
#            mssql.close() # close timing이 더럽다. future로 sync로 바꿔얄 듯. 일단은 메모리를 믿자
#            return err.toString()
#        catch err
#          cl err.toString()
      when 'MySQL'
        mysqlDB = mysql.createConnection
          host: _dbObj.DB_IP
          port: _dbObj.DB_PORT
          user: _dbObj.DB_ID
          password: _dbObj.DB_PW
          database: _dbObj.DB_DATABASE
        fut = new future()
        mysqlDB.connect (err) ->
          fut.return err?.message or 'success'
        mysqlDB.query 'select * from TEST_TABLE;', (err, rows, fields) ->
          cl err or rows
        mysqlDB.end()
        return fut.wait()
      when 'Oracle'
        try
          connectData =
            hostname: '152.99.176.114'
            port: 15997
            database: 'ORAGS'
            user: 'oracle'
            password: 'oracle'


          oracle.connect connectData, (err, connection) ->
            if err
              console.log 'Error connecting to db:', err
              return
            dasInfo.DEL_DB_QRY.forEach (query) ->
              connection.execute query, [], (err, results) ->
                if err
                  console.log 'Error executing query:', err
                  unless Array.isArray dasInfo.STATUS then dasInfo.STATUS = [dasInfo.STATUS]
                  dasInfo.STATUS.push err.toString()
                  return
                console.log results
                connection.close()
                # call only when query is finished executing
                return
              return
        catch err
          cl '####### DB ERROR #######'
          #        cl dasInfo.STATUS = err.toString()
          unless Array.isArray dasInfo.STATUS then dasInfo.STATUS = [dasInfo.STATUS]
          dasInfo.STATUS.push err.toString()




  'insertAgentInfo': (_agent) ->
    CollectionAgents.insert _agent

  updateAgentInfo: (_id, _agent) ->
    CollectionAgents.update _id: _id, _agent

  'getAgentLists': ->
    CollectionAgents.find({},{sort:'AGENT_NAME':1}).fetch()

  removeAgent: (_id) ->
    CollectionAgents.remove _id: _id

  getAgentInfoById: (_id) ->
    CollectionAgents.findOne _id: _id

  insertServiceInfo: (_service) ->
    CollectionServices.insert _service

  updateServiceInfo: (_id, _service) ->
    service = CollectionServices.findOne _id: _id
    _service.용량통계 = service.용량통계
    CollectionServices.update _id: _id, _service

  getServiceInfoById: (_id) ->
    CollectionServices.findOne _id: _id

  getServiceLists: ->
    CollectionServices.find({},{sort:'SERVICE_NAME':1}).fetch()

  getUserLists: (condition) ->
#    cl condition
    if condition.search? and condition.search.length >0
      _.extend condition.where,
        $or: [
          {'username': new RegExp condition.search, 'i'}
          ,{'profile.이름': new RegExp condition.search, 'i'}
        ]

    Meteor.users.find(condition.where, condition.options).fetch()


  addUser: (obj) ->
    options = {}
    options.username = obj.아이디
    options.email = obj.이메일 or ''
    options.password = obj.비밀번호
    options.profile = dataSchema 'profile',
      이름: obj.이름
      이메일: obj.이메일
      휴대폰: obj.휴대폰
      사용권한: obj.사용권한
      상태: obj.상태
    rslt = Accounts.createUser options
    unless rslt then return throw new Meteor.Error '사용자 생성 실패'
    else return '사용자 생성 완료'

  idDuplCheck: (id) ->
    count = Meteor.users.find(username: id).count()
    if count > 0
      throw new Meteor.Error '이미 사용중인 아이디입니다.'
    else
      return '사용가능합니다.'

  getUserInfoById: (_id) ->
#    cl _id
    Meteor.users.findOne({_id: _id}, {
      fields:
        username: 1
        profile: 1
    })

  removeUserById: (_id) ->
    Meteor.users.remove _id: _id

  userProfileUpdate: (_pass, _obj) ->
    if _pass.length > 0
      Accounts.setPassword(@userId, _pass, {logout: false})
    profile = Meteor.user().profile
    _.extend profile, _obj
    Meteor.users.update _id: @userId,
      $set: profile: profile

#  series:[
#    {
#      name: '서비스명'
#      data: [
#        1
#        2
#        3
#      ]
#    }
#  ]
#  result = {
#    categories: []
#    series: []
#  }
  getLineStats: (_start, _end, _period, _serviceId) ->
    result = {}
    seriesUp = []
    seriesDel = []
    seriesErr = []
    serviceIds = []
    categories = libServer.makeLineCategories _start, _end, _period

    if categories.length is 0 then throw new Meteor.Error '기간선택이 잘못되었습니다. 확인후 조회바랍니다.'
#    cl categories

    ## 입력 파라미터는 _id 이지만, SERVICE_ID 로 변경해서 조회 -> DasInfo 에 서비스의 _id 가 없고 SERVICE_ID 만 있다.
    if _serviceId is 'all'
      CollectionServices.find().forEach (service) ->
        serviceIds.push service.SERVICE_ID
    else serviceIds.push CollectionServices.findOne(_id: _serviceId).SERVICE_ID

#    cl serviceIds

#    point1 = (new Date()).getTime()

    serviceIds.forEach (serviceId) ->
      dataUp = []
      dataDel = []
      dataErr = []
      tempObjUp = {}
      tempObjDel = {}
      tempObjErr = {}
      categories.forEach (cate, idx) ->
        count = CollectionDasInfos.find({
          SERVICE_ID: serviceId
          REQ_DATE: do ->
            if _period is '실시간'
              $gte: new Date("#{_start} #{cate}:00:00"),
              $lt: new Date("#{_end} #{parseInt(cate)+1}:00:00")
            else if _period is '일별'
              $gte: new Date("#{cate} 00:00:00"),
              $lt: new Date("#{cate} 00:00:00").addDates(1)
            else if _period is '월간'
              if idx is 0
                date = new Date(cate);
                nextMonth = jUtils.getStringYMDFromDate(date.addMonths(1)).split('-')
                $gte: new Date("#{cate} 00:00:00"),
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
              else
                date = new Date(cate);
                nextDate = new Date(cate)
                nextMonth = jUtils.getStringYMDFromDate(nextDate.addMonths(1)).split('-')
                $gte: new Date(date.getFullYear(), date.getMonth(), 1);
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
            else if _period is '주간'
              $gte: new Date("#{cate} 00:00:00").addDates(-7),
              $lt: new Date("#{cate} 00:00:00")
        }).count()
        dataUp.push count
        dataDel.push CollectionDasInfos.find({
          SERVICE_ID: serviceId
          REQ_DATE: do ->
            if _period is '실시간'
              $gte: new Date("#{_start} #{cate}:00:00"),
              $lt: new Date("#{_end} #{parseInt(cate)+1}:00:00")
            else if _period is '일별'
              $gte: new Date("#{cate} 00:00:00"),
              $lt: new Date("#{cate} 00:00:00").addDates(1)
            else if _period is '월간'
              if idx is 0
                date = new Date(cate);
                nextMonth = jUtils.getStringYMDFromDate(date.addMonths(1)).split('-')
                $gte: new Date("#{cate} 00:00:00"),
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
              else
                date = new Date(cate);
                nextDate = new Date(cate)
                nextMonth = jUtils.getStringYMDFromDate(nextDate.addMonths(1)).split('-')
                $gte: new Date(date.getFullYear(), date.getMonth(), 1);
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
            else if _period is '주간'
              $gte: new Date("#{cate} 00:00:00").addDates(-7),
              $lt: new Date("#{cate} 00:00:00")
          STATUS: 'success'
        }).count()
        dataErr.push CollectionDasInfos.find({
          SERVICE_ID: serviceId
          REQ_DATE: do ->
            if _period is '실시간'
              $gte: new Date("#{_start} #{cate}:00:00"),
              $lt: new Date("#{_end} #{parseInt(cate)+1}:00:00")
            else if _period is '일별'
              $gte: new Date("#{cate} 00:00:00"),
              $lt: new Date("#{cate} 00:00:00").addDates(1)
            else if _period is '월간'
              if idx is 0
                date = new Date(cate);
                nextMonth = jUtils.getStringYMDFromDate(date.addMonths(1)).split('-')
                $gte: new Date("#{cate} 00:00:00"),
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
              else
                date = new Date(cate);
                nextDate = new Date(cate)
                nextMonth = jUtils.getStringYMDFromDate(nextDate.addMonths(1)).split('-')
                $gte: new Date(date.getFullYear(), date.getMonth(), 1);
                $lt: new Date("#{nextMonth[0]}-#{nextMonth[1]}-01 00:00:00");
            else if _period is '주간'
              $gte: new Date("#{cate} 00:00:00").addDates(-7),
              $lt: new Date("#{cate} 00:00:00")
          STATUS: $nin: ['wait', 'success']
        }).count()
      tempObjUp['name'] = tempObjDel['name'] = tempObjErr['name'] = CollectionServices.findOne(SERVICE_ID: serviceId).SERVICE_NAME
#      tempObj['data'] = dataUp
      tempObjUp['data'] = dataUp
      tempObjDel['data'] = dataDel
      tempObjErr['data'] = dataErr
#      cl dataUp
      seriesUp.push tempObjUp
      seriesDel.push tempObjDel
      seriesErr.push tempObjErr

#    point2 = (new Date()).getTime()
#    cl point2 - point1
#    cl series
    result['categories'] = do ->
      if _period is '실시간' then return categories
      else if _period is '월간' then libServer.changeYMDtoM categories
      else libServer.changeYMDtoMD categories
    result['seriesUp'] = seriesUp
    result['seriesDel'] = seriesDel
    result['seriesErr'] = seriesErr
#    cl JSON.stringify result
    return result

#  result = [
#    {
#      name: ''
#      y: number
#    }
#    ...
#  ]
  getPeriodStats: (_start, _end, _period, _serviceId) ->
    serviceIds = []

    ## 입력 파라미터는 _id 이지만, SERVICE_ID 로 변경해서 조회 -> DasInfo 에 서비스의 _id 가 없고 SERVICE_ID 만 있다.
    if _serviceId is 'all'
      CollectionServices.find().forEach (service) ->
        serviceIds.push service.SERVICE_ID
    else serviceIds.push CollectionServices.findOne(_id: _serviceId).SERVICE_ID

    categories = jDefine.periodCateForPie

    p1 = new Date().getTime()

    results = []
    categories.forEach (cate) ->
      tempObj = {}
      yVal = 0
      serviceIds.forEach (serviceId) ->
        yVal += CollectionDasInfos.find({
          SERVICE_ID: serviceId
          KEEP_PERIOD: cate.period
          REQ_DATE:
            $gte: new Date(_start+' 00:00:00')
            $lt: new Date(_end+' 00:00:00').addDates(2)
        }).count()
      tempObj['name'] = cate.name
      tempObj['y'] = yVal
      results.push tempObj
#    cl results
#    cl (new Date().getTime()) - p1
    return results

  getDelPerErrStats: (_start, _end, _period, _serviceId) ->
    serviceIds = []
    ## 입력 파라미터는 _id 이지만, SERVICE_ID 로 변경해서 조회 -> DasInfo 에 서비스의 _id 가 없고 SERVICE_ID 만 있다.
    if _serviceId is 'all'
      CollectionServices.find().forEach (service) ->
        serviceIds.push service.SERVICE_ID
    else serviceIds.push CollectionServices.findOne(_id: _serviceId).SERVICE_ID

    p1 = new Date().getTime()

    categories = [
      {
        name: '처리'
        STATUS: 'success'
      }
      {
        name: '오류'
        STATUS: $nin: ['success', 'wait']
      }
    ]

    results = []

    categories.forEach (cate) ->
      tempObj = {}
      yVal = 0
      serviceIds.forEach (serviceId) ->
        yVal += CollectionDasInfos.find({
          SERVICE_ID: serviceId
          STATUS: cate.STATUS
          REQ_DATE:
            $gte: new Date(_start+' 00:00:00')
            $lt: new Date(_end+' 00:00:00').addDates(1)
        }).count()
      tempObj['name'] = cate.name
      tempObj['y'] = yVal
      results.push tempObj
#    cl results
#    cl (new Date().getTime()) - p1
    return results


  getDasHistory: (_condition) ->
    #_condition.where.SERVICE_ID 는 _id 이므로 dasInfo 에 있는 SERVICE_ID 로 교체
#    cl _condition
    if (_id = _condition.where.SERVICE_ID)?
      _condition.where['SERVICE_ID'] = CollectionServices.findOne(_id: _id).SERVICE_ID
    CollectionDasInfos.find(_condition.where, _condition.options).fetch()

#  result = [
#    {
#      SERVICE_ID: ''
#      SERVICE_NAME: ''
#      upCnt: num
#      delCnt: num
#      waitCnt: num
#      errCnt: num
#    }
#    ...
#  ]
  getAccumStats: ->
    result = []
    services = CollectionServices.find()
    services.forEach (service) ->
      obj = {}
      obj['SERVICE_ID'] = service.SERVICE_ID
      obj['SERVICE_NAME'] = service.SERVICE_NAME
      obj['upCnt'] = CollectionDasInfos.find({SERVICE_ID:service.SERVICE_ID}).count()
      obj['delCnt'] = CollectionDasInfos.find({SERVICE_ID:service.SERVICE_ID, STATUS: 'success'}).count()
      obj['waitCnt'] = CollectionDasInfos.find({SERVICE_ID:service.SERVICE_ID, STATUS: 'wait'}).count()
      obj['errCnt'] = CollectionDasInfos.find({SERVICE_ID:service.SERVICE_ID, STATUS: $nin: ['wait', 'success']}).count()
      result.push obj
#    cl result
    return result

#  result = [
#    {
#      BOARD_ID: ''
#      upCnt: num
#      delCnt: num
#      waitCnt: num
#      errCnt: num
#    }
#    ...
#  ]
  getAccumStatsByBoard: (_serviceId) ->
    result = []
    boardIds = CollectionServices.findOne(SERVICE_ID: _serviceId).BOARD_IDS.sort()
    boardIds.forEach (boardId) ->
      obj = {}
      obj['BOARD_ID'] = boardId
      obj['upCnt'] = CollectionDasInfos.find({SERVICE_ID:_serviceId, BOARD_ID: boardId}).count()
      obj['delCnt'] = CollectionDasInfos.find({SERVICE_ID:_serviceId, BOARD_ID: boardId, STATUS: 'success'}).count()
      obj['waitCnt'] = CollectionDasInfos.find({SERVICE_ID:_serviceId, BOARD_ID: boardId, STATUS: 'wait'}).count()
      obj['errCnt'] = CollectionDasInfos.find({SERVICE_ID:_serviceId, BOARD_ID: boardId, STATUS: $nin: ['wait', 'success']}).count()
      result.push obj
    #    cl result
    return result


#  result = [
#    {
#      SERVICE_ID: ''
#      SERVICE_NAME: ''
#      upCnt: num
#      delCnt: num
#      waitCnt: num
#    }
#    ...
#  ]
  getCapaStats: ->
    result = []
    services = CollectionServices.find()
    services.forEach (service) ->
      obj = {}
      obj['SERVICE_ID'] = service.SERVICE_ID
      obj['SERVICE_NAME'] = service.SERVICE_NAME
      obj['upCnt'] = service.용량통계.업로드용량
      obj['delCnt'] = service.용량통계.처리용량
      obj['waitCnt'] = service.용량통계.업로드용량 - service.용량통계.처리용량
      result.push obj
#    cl result
    return result

#  result = {
#    categories: []
#    series: [
#      {
#        name: ''
#        y: [
#
#        ]
#      }
#      ...
#    ]
#  }
  getSimpleRealTimeStats: (_today) ->
    result = {}
    categories = jDefine.dashBoardDayTimeDiv
    series = []

    #    point1 = (new Date()).getTime()

    dataUp = []
    tempObjUp = {}
    categories.forEach (cate) ->
      dataUp.push CollectionDasInfos.find({
        REQ_DATE:
          $gte: new Date("#{_today} #{cate}:00:00"),
          $lt: new Date("#{_today} #{parseInt(cate)+1}:00:00")
      }).count()
    tempObjUp['name'] = '요청건수'
    #      tempObj['data'] = dataUp
    tempObjUp['data'] = dataUp
    series.push tempObjUp

    #    point2 = (new Date()).getTime()
    #    cl point2 - point1
    #    cl series
    result['categories'] = categories
    result['series'] = series
#    cl JSON.stringify result
    return result

  getSimmpleCapaStats: ->
    result = []
    obj = {}
    obj2 = {}
    services = CollectionServices.find()
    waitCnt = 0
    delCnt = 0
    services.forEach (service) ->
      waitCnt += service.용량통계.업로드용량 - service.용량통계.처리용량
      delCnt += service.용량통계.처리용량
    obj['name'] = '대기현황'
    obj['y'] = waitCnt
    obj2['name'] = '처리현황'
    obj2['y'] = delCnt
    result.push obj
    result.push obj2
#    cl result
    return result

#  result = {
#    사용: num
#    미사용: num
#    data: [
#      agentObj
#      ..
#    ]
#  }
  getAgentInfos: ->
    use = 0
    unUse = 0
    agents = CollectionAgents.find({},{sort: AGENT_NAME: 1})
    agents.forEach (agent) ->
      if agent.STATUS then use += 1
      else unUse += 1
    result = {
      사용: use
      미사용: unUse
      data: agents.fetch()
    }

  editUserInfo: (_obj, _id) ->

    profile = Meteor.users.findOne(_id: _id).profile
    _.extend profile,
      이름: _obj.이름
      이메일: _obj.이메일
      휴대폰: _obj.휴대폰
      상태: _obj.상태
      사용권한: _obj.사용권한
    Meteor.users.update _id: _id,
      $set:
        profile: profile

  checkLoginPermission: (_username) ->
    user = Meteor.users.findOne username: _username
    if user.profile.상태 is '사용' then return 'success'
    else if user.profile.상태 is '사용안함' then return 'denied'
    else
      throw new Meteor.Error '로그인 이상. 개발자에게 문의바랍니다.(error log : #loginFailed)'

  saveSerialNo: (_serialNo) ->
    unless _serialNo then throw new Meteor.Error '아무것도 입력되지 않았습니다.'

    #todo CryptoJs.AES.decrypy 가 들어가는곳에는 private key 가 들어가므로 나중에 별도 서버로 이관후 수정해야함
    decrypted = CryptoJS.AES.decrypt(_serialNo, CLIENT_NAME)
    startYMD = decrypted.toString(CryptoJS.enc.Utf8)  #YYYY-MM-DD 형태의 string
#    cl startYMD.length
#    cl startYMD
    limitYMD = jUtils.getStringYMDFromDate(new Date(startYMD).addMonths(12))

    unless startYMD.length is 10 then throw new Meteor.Error '올바른 형식의 키가 아닙니다. 확인 후 재입력 바랍니다.'

    CollectionSettings.upsert set_key: 'serial',
      {
        set_key: 'serial'
        value: _serialNo
        시작일: startYMD
        종료일: limitYMD
      }
    return 'success'

  getLicenceInfo: ->
    CollectionSettings.findOne(set_key: 'serial')