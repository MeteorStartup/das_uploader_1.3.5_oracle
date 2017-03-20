@libClient =
  getRealtimeDate: ->
    today = $.datepicker.formatDate('yy-mm-dd', new Date());
    return {
      start: today
      end: today
    }

#  result = [
#    {
#      cate: ''
#      up: ''
#      del: ''
#      err: ''
#    }
#    ...
#  ]
  getTableTotalStats: (_data) ->
#    cl _data
    result = []
    _data.categories.forEach (cate, idx) ->
      tempObj = {}
      tempObj['cate'] = cate
      serviceCnt = _data.seriesUp.length
      tempObj['up'] = 0
      tempObj['del'] = 0
      tempObj['err'] = 0
      for i in [0...serviceCnt]
#        cl i
        tempObj['up'] += _data.seriesUp[i].data[idx]
        tempObj['del'] += _data.seriesDel[i].data[idx]
        tempObj['err'] += _data.seriesErr[i].data[idx]
#      cl tempObj
      result.push tempObj
#    cl result
    return result

  calForPercent: (_arr) ->
    total = 0
    temps = []
    arr = _.clone(_arr);
    arr.forEach (_obj) ->
      total += _obj.y
#    cl total

    #total이 0인경우는 그래프가 안그려질수 있으므로, 첫번째값은 100 나머지를 다 0 으로 초기설정
    unless total is 0
      arr.forEach (_obj) ->
        obj = {}
        obj['name'] = _obj.name
        obj['y'] = parseInt(((_obj.y/total)*100).toFixed(2))
        temps.push obj
    else
      arr.forEach (_obj, idx) ->
        if idx is 0
          obj = {}
          obj['name'] = _obj.name
          obj['y'] = 100
          temps.push obj
        else
          obj = {}
          obj['name'] = _obj.name
          obj['y'] = 0
          temps.push obj
    return temps

  calForPercentByBoard: (_arr, option) ->
    total = 0
    temps = []
    arr = _.clone(_arr);
    arr.forEach (_obj) ->
      total += _obj[option]
#    cl total

    #total이 0인경우는 그래프가 안그려질수 있으므로, 첫번째값은 100 나머지를 다 0 으로 초기설정
    unless total is 0
      arr.forEach (_obj) ->
        obj = {}
        obj['name'] = _obj.BOARD_ID
        obj['y'] = parseInt(((_obj[option]/total)*100).toFixed(2))
        temps.push obj
    else
      obj_1 = {}
      obj_1['name'] = '게시판_1'
      obj_1['y'] = 30
      temps.push obj_1
      obj_2 = {}
      obj_2['name'] = '게시판_2'
      obj_2['y'] = 70
      temps.push obj_2
    return temps
