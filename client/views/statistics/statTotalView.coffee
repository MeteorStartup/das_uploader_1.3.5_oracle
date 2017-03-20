servicesRv = new ReactiveVar()  #select용 서비스
searchFlag = new ReactiveVar()  #버튼중복클릭금지 flag
lineStatDatas = new ReactiveVar() #꺽은선그래프 datas
pieStatDatas = new ReactiveVar()  #기간별 pieGraph datas
delPerErrDatas = new ReactiveVar()  #처리대오류 Graph datas
tabId = new ReactiveVar() #꺽은선그래프 탭명

Router.route 'statTotalView'

Template.statTotalView.onCreated ->
  tabId.set 'seriesUp'
  searchFlag.set false
  Meteor.call 'getServiceLists', (err, rslt) ->
    if err then alert err
    else
      servicesRv.set rslt

Template.statTotalView.onRendered ->
  todayObj = libClient.getRealtimeDate()
  $('#date01').datepicker({dateFormat: 'yy-mm-dd'})
  $('#date02').datepicker({dateFormat: 'yy-mm-dd'})
  $('#date01').val(todayObj.start)
  $('#date02').val(todayObj.end)
  @autorun ->
#    cl 'run autorun'
#    cl lineStatDatas.get()
    $('#line-chart-1').highcharts
      colors: ['#058DC7', '#50B432', '#ED561B', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4']
      title:
        text: ''
  #      x: -20
  #    subtitle:
  #      text: 'Source: WorldClimate.com'
  #      x: -20
      xAxis: categories: lineStatDatas.get()?.categories
      yAxis:
        title: text: '(건)'
        plotLines: [ {
          value: 0
          width: 1
          color: '#808080'
        } ]
      tooltip: valueSuffix: '건'
      legend:
        layout: 'vertical'
        align: 'right'
        verticalAlign: 'middle'
        borderWidth: 0
      series: do ->
        switch tabId.get()
          when 'seriesUp'
            lineStatDatas.get()?.seriesUp
          when 'seriesDel'
            lineStatDatas.get()?.seriesDel
          when 'seriesErr'
            lineStatDatas.get()?.seriesErr
      credits:
        enabled: false

  @autorun ->
    # Build the chart
    $('#pie-chart-1').highcharts
      colors: ['#058DC7', '#50B432', '#ED561B', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4']
      chart:
        backgroundColor: 'transparent'
#        plotBackgroundColor: "#d2dfe9"
        plotBorderWidth: 0
        borderWidth: 0
        plotShadow: false
        type: 'pie'
#      title: text: 'Browser market shares January, 2015 to May, 2015'
      title: text: null
      tooltip: pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
      plotOptions: pie:
        allowPointSelect: true
        cursor: 'pointer'
        dataLabels:
          enabled: false
#        showInLegend: true
      series: [ {
        name: 'Brands'
        colorByPoint: true
        data: do -> if pieStatDatas.get()? then libClient.calForPercent pieStatDatas.get()
      } ]
      credits:
        enabled: false
  @autorun ->
    # Build the chart
    $('#pie-chart-2').highcharts
      colors: ['#058DC7', '#50B432', '#ED561B', '#DDDF00', '#24CBE5', '#64E572', '#FF9655', '#FFF263', '#6AF9C4']
      chart:
        backgroundColor: 'transparent'
#        plotBackgroundColor: "#d2dfe9"
        plotBorderWidth: 0
        borderWidth: 0
        plotShadow: false
        type: 'pie'
#      title: text: 'Browser market shares January, 2015 to May, 2015'
      title: text: null
      tooltip: pointFormat: '{series.name}: <b>{point.percentage:.1f}%</b>'
      plotOptions: pie:
        allowPointSelect: true
        cursor: 'pointer'
        dataLabels:
          enabled: false
#        showInLegend: true
      series: [ {
        name: 'Brands'
        colorByPoint: true
        data: do -> if delPerErrDatas.get()? then libClient.calForPercent delPerErrDatas.get()
      } ]
      credits:
        enabled: false

  Meteor.setTimeout ->
    $('[name=btn_search]').trigger('click')
  ,100

Template.statTotalView.helpers
  services: -> servicesRv?.get()
  disabled: ->
    if searchFlag.get() then return 'disabled'
    else return ''
  statTotalInfos: ->
    if lineStatDatas.get()?
      libClient.getTableTotalStats lineStatDatas.get()
  periodStats: ->
    if pieStatDatas.get()?
      pieStatDatas.get()
  delPerErrStats: ->
    if delPerErrDatas.get()?
      delPerErrDatas.get()
  합계: ->
    if pieStatDatas.get()?
      total = 0
      pieStatDatas.get().forEach (obj) ->
        total += obj.y
      return total
    else return 0
  percentage: ->
    total = 0
    delPerErrDatas.get().forEach (obj) ->
      total += obj.y
    if total is 0 then return 0
    else return ((@y/total)*100).toFixed(2)
Template.statTotalView.events
  'click #btnExcel': (e, tmpl) ->
    e.preventDefault()
    alert '업데이트 예정입니다.'
    return

#  ##실시간차트를 위한 임시 코드, 나중에 다른 조회조건도 들어갈떈 조건에 따라 별도처리
#  'click #date01, click #date02': (e, tmpl) ->
#    e.preventDefault()
#    alert '실시간차트는 오늘 날짜만 선택가능합니다.'
#    return false
  'change #date01': (e, tmpl) ->
    #실시간아닌공통1 date02 보다 클 수 없습니다.
    #실시간 오늘만 선택가능
    #일별 31일 이내만 선택가능
    #주간, 3달 이내만 선택가능
    #월간, 12개월 이내만 가능
    today = libClient.getRealtimeDate().end
    unless $('.btn_box > .on').text() is '실시간'
      if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') < 0
        alert '조회종료일보다 클수 없습니다.'
        $('#date01').val(
          jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(0))
        )
    switch $('.btn_box > .on').text()
      when '실시간'
        unless $(e.target).val() is today
          alert '실시간차트는 오늘 날짜만 선택가능합니다.'
          $(e.target).val(today)
          return false
      when '일별'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 31
          alert '일별조회는 31일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-31))
          )
      when '주간'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 90
          alert '주간조회는 90일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-90))
          )
      when '월간'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 365
          alert '월간조회는 365일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-365))
          )
      else
        alert '기간선택 버튼을 클릭하세요.'

  'change #date02': (e, tmpl) ->
    #실시간아닌공통1 today-1일 까지  검색할수 있습니다.
    #실시간아닌공통2 date01 보다 작을 수 없습니다.
    #실시간 오늘만 선택가능
    #일별 31일 이내만 선택가능
    #주간, 3달 이내만 선택가능
    #월간, 12개월 이내만 가능
    today = libClient.getRealtimeDate().end
    unless $('.btn_box > .on').text() is '실시간'
      if $(e.target).val() >= today
        alert 'today-1일 까지 검색할수 있습니다.'
        $(e.target).val(
          jUtils.getStringYMDFromDate(new Date(today).addDates -1)
        )
      if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') < 0
        alert '조회시작일보다 작을수 없습니다.'
        $('#date01').val(
          jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(0))
        )
    switch $('.btn_box > .on').text()
      when '실시간'
        unless $(e.target).val() is today
          alert '실시간차트는 오늘 날짜만 선택가능합니다.'
          $(e.target).val(today)
          return false
      when '일별'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 31
          alert '일별조회는 31일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-31))
          )
      when '주간'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 90
          alert '주간조회는 90일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-90))
          )
      when '월간'
        if jUtils.mydiff($('#date01').val(), $('#date02').val(), 'days') > 365
          alert '월간조회는 365일 이내로만 검색이 가능합니다.'
          $('#date01').val(
            jUtils.getStringYMDFromDate(new Date("#{$('#date02').val()}").addDates(-365))
          )
      else
        alert '기간선택 버튼을 클릭하세요.'

  'click .tab li': (e, tmpl) ->
    $('.tab li').removeClass('on')
    (target=$(e.target).parent()).addClass('on')
    tabId.set target.attr('id')

  'click .btn_box .btn_inner': (e, tmpl) ->
#    if $(e.target).text() in ['일별', '주간', '월간']
#      e.preventDefault()
#      alert '업데이트 예정입니다.'
#      return
    $('.btn_inner').removeClass('on')
    if (target=$(e.target)).hasClass('btn_inner') or (target=target.parent()).hasClass('btn_inner')
      target.addClass('on')

    today = libClient.getRealtimeDate().end
    switch $(e.target).text()
      when '실시간'
        $('#date01').val(today)
        $('#date02').val(today)
      when '일별' #초기세팅 14일
        $('#date01').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-15))
        )
        $('#date02').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-1))
        )
      when '주간' #초기세팅 60일
        $('#date01').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-61))
        )
        $('#date02').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-1))
        )

      when '월간' #초기세팅 180일
        $('#date01').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-181))
        )
        $('#date02').val(
          jUtils.getStringYMDFromDate(new Date(today).addDates(-1))
        )


  'click [name=btn_search]': (e, tmpl) ->
    startDay = $('#date01').val()
    endDay = $('#date02').val()
    serviceId = $('[name=selectedService]').val()
    period = $('.btn_box > .on').text() #실시간/일별/주간/월간
    switch period
      when '실시간' then $('#select_term_dv').text('실시간(시간별)')
      when '일별' then $('#select_term_dv').text('일자')
      when '주간' then $('#select_term_dv').text('주간표시(마지막날짜)')
      when '실시간' then $('#select_term_dv').text('월')
    unless searchFlag.get()
      searchFlag.set true
      Meteor.call 'getLineStats', startDay, endDay, period, serviceId, (err, rslt) ->
        if err
          alert err
          searchFlag.set false
        else
          lineStatDatas.set rslt
          searchFlag.set false
      Meteor.call 'getPeriodStats', startDay, endDay, period, serviceId, (err, rslt) ->
        if err
          alert err
        else
          pieStatDatas.set rslt
      Meteor.call 'getDelPerErrStats', startDay, endDay, period, serviceId, (err, rslt) ->
        if err
          alert err
        else
          delPerErrDatas.set rslt

    else
      alert '통계데이터 생성중입니다. 잠시만 기다려주세요.'
