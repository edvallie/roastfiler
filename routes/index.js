var express = require('express');
var router = express.Router();
var path = require('path');
var fs = require('fs');

var jsonBeanPath = path.join(__dirname, '/../public/beans');
/* GET home page. */
router.get('/', function(req, res, next) {
    
    var beanList = [];
    var fileList = fs.readdirSync(jsonBeanPath)
    fileList.forEach(function (file) {
        var filePath = __dirname + '/../public/beans/' + file;
        console.log('Reading ' + filePath);
        var obj = JSON.parse(fs.readFileSync(filePath, 'utf8'));
        beanList.push(obj);
    });
    console.log(beanList);
  res.render('index', { title: 'Roastfiler', beans: beanList });
});

module.exports = router;
