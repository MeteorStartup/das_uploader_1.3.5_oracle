Meteor.methods({
  'oraTest': function() {
    var connectData, oracle;

    oracle = require('oracle');

    connectData = {
      hostname: '152.99.176.114',
      port: 15997,
      database: 'ORAGS',
      user: 'daldas',
      password: 'daldas'
    };

    oracle.connect(connectData, function (err, connection) {
      if (err) {
        console.log('Error connecting to db:', err);
        return;
      }
      connection.execute('SELECT systimestamp FROM dual', [], function (err, results) {
        if (err) {
          console.log('Error executing query:', err);
          return;
        }
        console.log(results);
        connection.close();
      });
    });
  }
});