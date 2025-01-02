@IsTest
public class KodeverkMockCallout implements HttpCalloutMock {

    public HTTPResponse respond(HTTPRequest req) {
        //System.debug(JSON.serializePretty(req));
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        // 1 invalid, 1 invalid+valid, 1 valid
        String mockingJson = '{"betydninger":{"IMP":[{"gyldigFra":"1900-01-01","gyldigTil":"2023-10-31","beskrivelser":{"nb":{"term":"Pounds Isle of Man","tekst":""}}}],"BRL":[{"gyldigFra":"1900-01-01","gyldigTil":"2023-10-31","beskrivelser":{"nb":{"term":"Brazil Real Brazil","tekst":"Brazil Real Brazil"}}},{"gyldigFra":"2023-11-01","gyldigTil":"9999-12-31","beskrivelser":{"nb":{"term":"Real","tekst":"986"}}}],"BTC":[{"gyldigFra":"2009-01-03","gyldigTil":"9999-12-31","beskrivelser":{"nb":{"term":"Bitcoin","tekst":"Chancellor on brink of second bailout for banks"}}}]}}';
        res.setBody(mockingJson);
        res.setStatusCode(200);
        return res; 
    }
}