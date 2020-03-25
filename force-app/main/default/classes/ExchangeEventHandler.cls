public class ExchangeEventHandler {

public static void createEvent(){
	Http http = new Http();
	HttpRequest request = new HttpRequest();
	request.setEndpoint('callout:Exchange_Online');
	request.setMethod('POST');
	request.setHeader('Content-Type', 'application/json');
	request.setHeader('Accept', 'application/json');

	request.setBody('{"Subject": "Discuss the Calendar REST API"}');
	HttpResponse response = http.send(request);

	if (response.getStatusCode() != 201) {
		System.debug('The status code returned was not expected: ' +
		             response.getStatusCode() + ' ' + response.getStatus());
	} else {
		System.debug(response.getBody());
	}
}


private static String getJson(){
	return '{"Subject": "Discuss the Calendar REST API","Body": {"ContentType": "HTML","Content": "I think it will meet our requirements!"},"Start": {"DateTime": "2014-02-02T18:00:00","TimeZone": "Pacific Standard Time"},"End": {"DateTime": "2014-02-02T19:00:00","TimeZone": "Pacific Standard Time"},"Attendees": [{"EmailAddress": {"Address": "janets@a830edad9050849NDA1.onmicrosoft.com","Name": "Janet Schorr"},"Type": "Required"}]}}';
}
}
