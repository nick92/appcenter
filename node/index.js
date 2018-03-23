var http = require("http");

http.createServer(function (request, response) {
	// Send the HTTP header 
	// HTTP Status: 200 : OK
	// Content Type: text/plain
	response.writeHead(200, {'Content-Type': 'application/json'});
   
   	var o = {} // empty Object
	var key = 'data';
	o[key] = []; // empty Array, which you can push() values into


	var data = 'firefox';
	var data1 = 'bluefish';
	var data2 = 'mousepad';
	var data3 = 'gallery';
	var data4 = 'leafpad';
	var data5 = 'arora';
	/*var data2 = {
	    sampleTime: '1450632410296',
	    data: '78.15431:0.5247617:-0.20050584'
	};*/
	o[key].push(data);
	o[key].push(data1);
	o[key].push(data2);
	o[key].push(data3);
	o[key].push(data4);
	o[key].push(data5);
	//o[key].push(data2);
	// Send the response body as "Hello World"
	response.end(JSON.stringify(o));
}).listen(8081);

// Console will print the message
console.log('Server running at http://127.0.0.1:8081/');