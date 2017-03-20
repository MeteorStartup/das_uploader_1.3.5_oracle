@libServer =
  makeLineCategories: (_start, _end, _period) ->
    categories = []
    switch _period
      when '실시간'
        return jDefine.dayTimeDiv
      when '일별'
        dayLength = jUtils.mydiff _start, _end, 'days'
        for i in [0..dayLength]
          categories.push jUtils.getStringYMDFromDate(new Date(_start).addDates(i))
        return categories
      when '월간'
        monthLength = jUtils.mydiff _start, _end, 'months'
        for i in [0..monthLength]
          categories.push jUtils.getStringYMDFromDate(new Date(_start).addMonths(i))
        return categories
      when '주간'
        startWeek = new Date(_start).getDay()
        weekLength = jUtils.mydiff _start, _end, 'weeks'
        if startWeek is 0
          startWeek = 7
          weekLength += 1
        for i in [0..weekLength]
          categories[i] = jUtils.getStringYMDFromDate(new Date(_start).addDates((7-startWeek)+i*7))
        return categories

#  input : YYYY-MM-DD
#  output : MM-DD
  changeYMDtoMD: (_arr) ->
    result = []
    _arr.forEach (ymd) ->
      str = ymd.split('-')
      result.push "#{str[1]}-#{str[2]}"
    return result

#  input : YYYY-MM-DD
#  output : MM
  changeYMDtoM: (_arr) ->
    result = []
    _arr.forEach (ymd) ->
      str = ymd.split('-')
      result.push "#{str[1]}"
    return result