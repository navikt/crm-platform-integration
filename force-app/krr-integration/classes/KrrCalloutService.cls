public class KrrCalloutService {

    private static final String API_CONFIG_NAME = 'KRR_API';
    private static final String SERVICE_AUTH_HEADER = 'Krr';
    private static final String DEFAULT_QUERY_API_SERVICE_NAME = 'POST_KRR_QUERY';

    public static List<Person> doPersonOppslag(List<String> personIdentifikatorer, String apiServiceName){
        if (personIdentifikatorer.isEmpty())
            return null;
        Map<String, String> params = new Map<String, String>();
        params.put('inkluderSikkerDigitalPost', 'false');
        
        apiServiceName = String.isBlank(apiServiceName) ? DEFAULT_QUERY_API_SERVICE_NAME : apiServiceName;

        PersonOppslagRequest requestBody = new PersonOppslagRequest();
        requestBody.personidentifikatorer = personIdentifikatorer;

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, apiServiceName, params);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER);
        apiCtrl.addHeader('Content-Type', 'application/json');
        apiCtrl.setBody(JSON.serialize(requestBody));

        apiCtrl.setLogger(new LoggerUtility('KRR'))
            .setLogCalloutRequest()
            .setLogCategory('KRR')
            .setLogDomain(CRM_ApplicationDomain.Domain.CRM)
            .setLogUuid(new Uuid().getValue())
            .addHeader('Nav-Consumer-Id', 'sf-crm')
            .addHeader('Nav-Callid', apiCtrl.getLogUuid());

        apiCtrl.doCallout();
        PersonOppslagResponse2 response = new PersonOppslagResponse2();
        response.personer = parseJSON(apiCtrl.getResponse().getBody());
        return response.personer;
    }

    public static List<Person> parseJSON(String jsonInput){
        LoggerUtility logger = new LoggerUtility();
        List<Person> out = new List<Person>();
        JSONParser parser = JSON.createParser(jsonInput);
        Person tmp;
        SikkerDigitalPostkasse tmpSDP;
        String tmpFeil;
        while (parser.nextToken() != null) {
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

    private class PersonOppslagResponse {
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
}