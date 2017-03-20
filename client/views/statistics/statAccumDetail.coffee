servicesRv = new ReactiveVar()  #select용 서비스
listRv = new ReactiveVar()  #누적데이터

Router.route 'statAccumDetail',
  path: '/statAccumDetail/:SERVICE_ID',
  template: 'statAccumDetail'

Template.statAccumDetail.onCreated ->
  Meteor.call 'getServiceLists', (err, rslt) ->
    if err then alert err
    else
      servicesRv.set rslt
  Meteor.call 'getAccumStatsByBoard', Router.current().params.SERVICE_ID, (err, rslt) ->
    if err then alert err
    else
#      cl rslt
      listRv.set rslt

Template.statAccumDetail.onRendered ->
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
        data: do -> if listRv.get()? then (libClient.calForPercentByBoard listRv.get(), 'upCnt')
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
        data: do -> if listRv.get()? then (libClient.calForPercentByBoard listRv.get(), 'delCnt')
      } ]
      credits:
        enabled: false

  Meteor.setTimeout ->
    $("[value=#{Router.current().params.SERVICE_ID}]").attr("selected","selected")
  ,500

Template.statAccumDetail.helpers
  services: -> servicesRv.get()
  lists: -> listRv.get()
  업로드합계: ->
    sum = 0
    if listRv.get()?
      listRv.get().forEach (obj) ->
        sum += obj.upCnt
    return sum
  처리합계: ->
    sum = 0
    if listRv.get()?
      listRv.get().forEach (obj) ->
        sum += obj.delCnt
    return sum

Template.statAccumDetail.events
  'click #btnExcel': (e, tmpl) ->
    e.preventDefault()
    alert '업데이트 예정입니다.'
    return
  'change [name=SERVICE_ID]': (e, tmpl) ->
    serviceId = $('[name=SERVICE_ID]').val()
    Meteor.call 'getAccumStatsByBoard', serviceId, (err, rslt) ->
      if err then alert err
      else
#        cl rslt
        listRv.set rslt

  'click [name=goToBack]': (e, tmpl) ->
    e.preventDefault()
    Router.go 'statAccumView'

