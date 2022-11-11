public class KrrCalloutService {

    private static final String API_CONFIG_NAME = 'KRR_API';
    private static final String SERVICE_AUTH_HEADER = 'Krr';
    private static final String DEFAULT_QUERY_API_SERVICE_NAME = 'POST_KRR_QUERY';

    public static List<KrrCalloutService.Person> doPersonOppslag2(List<String> personidenter, String apiServiceName){
        return doPersonOppslag2(personidenter, apiServiceName, false);
    }
    
    public static List<KrrCalloutService.Person> doPersonOppslag2(List<String> personidenter, String apiServiceName, Boolean isSystemContext){
        if (personidenter.isEmpty())
            return null;
        Map<String, String> params = new Map<String, String>();
        params.put('inkluderSikkerDigitalPost', 'false');
        
        apiServiceName = String.isBlank(apiServiceName) ? DEFAULT_QUERY_API_SERVICE_NAME : apiServiceName;

        PersonOppslagRequest2 requestBody = new PersonOppslagRequest2();
        requestBody.personidenter = personidenter;

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, apiServiceName, params);
        if(isSystemContext) apiCtrl.setSystemContext();
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(JSON.serialize(requestBody));

        apiCtrl.setLogger(new LoggerUtility('KRR'))
            .setLogCalloutRequest()
            .setLogCategory('KRR')
            .setLogDomain(CRM_ApplicationDomain.Domain.CRM)
            .setLogUuid(new Uuid().getValue())
            .addHeader('Nav-Call-Id', apiCtrl.getLogUuid());

        apiCtrl.doCallout();
        PersonOppslagResponse2 response = new PersonOppslagResponse2();
        response.personer = parseJSON(apiCtrl.getResponse().getBody());
        return response.personer;
    }

    public static List<KrrCalloutService.Person> parseJSON(String jsonInput){
        LoggerUtility logger = new LoggerUtility();
        logger.error('JSON INPUT KRR: ' +  jsonInput, null, CRM_ApplicationDomain.Domain.NKS);
        System.debug('JSON INPUT KRR: ' +  jsonInput);
        List<Person> out = new List<Person>();
        JSONParser parser = JSON.createParser(jsonInput);
        Person tmp;
        SikkerDigitalPostkasse tmpSDP;
        String tmpFeil;    
        while (parser.nextToken() != null){
            if(parser.getCurrentToken() != JSONToken.FIELD_NAME) continue;
            String txt = parser.getText();
            parser.nextToken();

            switch on txt {
                when 'personident' {
                    if(tmpSDP != null) tmp.sikkerDigitalPostkasse = tmpSDP;
                    if(tmp != null) out.add(tmp);
                    tmp = new Person();                       
                    tmp.personident = parser.getText();                        
                }
                when 'aktiv' {
                    tmp.aktiv = parser.getBooleanValue();                    }
                when 'kanVarsles' {
                    tmp.kanVarsles = parser.getBooleanValue();
                }
                when 'reservert' {
                    tmp.reservert = parser.getBooleanValue();
                }
                when 'spraak' {                        
                    tmp.spraak = parser.getText();                        
                }
                when 'spraakOppdatert' {
                    tmp.spraakOppdatert = parser.getDateTimeValue();
                }
                when 'epostadresse' {
                    tmp.epostadresse = parser.getText();
                }
                when 'epostadresseOppdatert' {
                    tmp.epostadresseOppdatert = parser.getDateTimeValue();
                }
                when 'epostadresseVerifisert' {
                    tmp.epostadresseVerifisert = parser.getDateTimeValue();
                }
                when 'mobiltelefonnummer' {
                    tmp.mobiltelefonnummer = parser.getText();
                }
                when 'mobiltelefonnummerOppdatert' {
                    tmp.mobiltelefonnummerOppdatert = parser.getDateTimeValue();
                }
                when 'mobiltelefonnummerVerifisert' {
                    tmp.mobiltelefonnummerVerifisert = parser.getDateTimeValue();
                }
                when 'sikkerDigitalPostkasse' {
                    tmpSDP = new SikkerDigitalPostkasse();
                }
                when 'adresse' {
                    tmpSDP.adresse = parser.getText();
                }
                when 'leverandoerAdresse' {
                    tmpSDP.leverandoerAdresse = parser.getText();
                }
                when 'leverandoerSertifikat' {
                    tmpSDP.leverandoerSertifikat = parser.getText();
                }
                when 'feil' {
                    while(parser.nextToken() != null && parser.getCurrentToken() != JSONToken.END_OBJECT){
                        if(parser.getCurrentToken() == JSONToken.VALUE_STRING){
                            logger.error('Received error from KRR: ' + tmpFeil + ' : ' + parser.getText(), null, CRM_ApplicationDomain.Domain.CRM);
                        }
                        tmpFeil = parser.getText();                        
                    }
                    if(logger.peek() != null) logger.publish();
                }
            }
        }
        if(tmpSDP != null) tmp.sikkerDigitalPostkasse = tmpSDP;
        if(tmp != null) out.add(tmp);
        return out;
    }

    private class PersonOppslagRequest {
        List<String> personidentifikatorer;
    }
    
    private class PersonOppslagRequest2 {
        List<String> personidenter;
    }

    private class PersonOppslagResponse {
        List<Personer> personer;
    }

    private class PersonOppslagResponse2 {
        List<Person> personer;
    }

    public class Person {
		public String personident;
		public Boolean aktiv;
		public Boolean kanVarsles;
		public Boolean reservert;
		public String spraak;
		public Datetime spraakOppdatert;
		public String epostadresse;
		public Datetime epostadresseOppdatert;
		public Datetime epostadresseVerifisert;
		public String mobiltelefonnummer;
		public Datetime mobiltelefonnummerOppdatert;
		public Datetime mobiltelefonnummerVerifisert;
		public SikkerDigitalPostkasse sikkerDigitalPostkasse;
	}

    public class SikkerDigitalPostkasse {
		public String adresse;
		public String leverandoerAdresse;
		public String leverandoerSertifikat;
	}


    // OLD CODE FOR TRANSITION TO NEW INTEGRATION
    public static List<Personer> doPersonOppslag(List<String> personIdentifikatorer) {
        // Initialize request format
        if (personIdentifikatorer.isEmpty())
            return null;
        PersonOppslagRequest requestBody = new PersonOppslagRequest();
        requestBody.personidentifikatorer = personIdentifikatorer;

        // Obtain access token from Maskinporten
        String access_token = new MaskinportenService(Test.isRunningTest() ? 'salesforce_krr_test' : 'salesforce_krr')
            .doMaskinportenJWTExchange()
            .access_token;

        // Initialize HttpRequest
        HttpRequest req = new HttpRequest();
        String endpoint = Test.isRunningTest()
            ? 'https://difiKrrExampleEndpoint.no'
            : 'callout:Kontaktregisteret_Oppslagstjenesten_REST'; // Use sample endpoint for tests in order to be able to mock response
        req.setEndpoint(endpoint);
        req.setMethod('POST');
        req.setHeader('Content-type', 'application/json;charset=UTF-8');
        req.setHeader('Accept', '*/*');
        req.setHeader('Authorization', 'Bearer ' + access_token);
        req.setBody(JSON.serialize(requestBody));
        HttpResponse res = new Http().send(req);
        PersonOppslagResponse response = (PersonOppslagResponse) Json.deserialize(
            res.getBody(),
            PersonOppslagResponse.class
        );
        return response.personer;
    }

    public class Personer {
        public String personidentifikator;
        public String reservasjon;
        String status;
        String varslingsstatus;
        public Kontaktinformasjon kontaktinformasjon;
    }

    public class Kontaktinformasjon {
        public String epostadresse;
        public Datetime epostadresse_oppdatert;
        public Datetime epostadresse_sist_verifisert;
        public String mobiltelefonnummer;
        public Datetime mobiltelefonnummer_oppdatert;
        public Datetime mobiltelefonnummer_sist_verifisert;
    }
}