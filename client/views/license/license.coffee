licenseRv = new ReactiveVar()

Router.route 'license'

Template.license.onCreated ->
  Meteor.call 'getLicenceInfo', (err, rslt) ->
    if err then alert err
    else
      licenseRv.set rslt

Template.license.helpers
  licenseInfo: -> licenseRv.get()

Template.license.events
  'click .btn_serial': (e, tmpl) ->
    $('.modal').removeClass('hide')
  'click .btn_close': (e, tmpl) ->
    $('#serialInp').val('')
    $('.modal').addClass('hide')
  'click .btn_serial_check': (e, tmpl) ->
    Meteor.call 'saveSerialNo', $('#serialInp').val(), (err, rslt) ->
      if err
        $('.modal').addClass('hide')
        $('#serialInp').val('')
        alert err
      else if rslt is 'success'
        $('.modal').addClass('hide')
        $('#serialInp').val('')
        Meteor.call 'getLicenceInfo', (err, rslt) ->
          if err then alert err
          else
            licenseRv.set rslt
        alert '라이센스가 갱신되었습니다.'
      else
        alert '라이센스 프로세스 오류. 개발자에게 문의 바랍니다.'
        $('.modal').addClass('hide')
        $('#serialInp').val('')
