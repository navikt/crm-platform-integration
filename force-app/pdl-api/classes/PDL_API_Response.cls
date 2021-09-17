public with sharing class PDL_API_Response {
    public PDL_Data data{ get;}
    public PDL_Error[] errors{ get;}
    
    private PDL_API_Response() {
        
    }
    
    public static PDL_API_Response fromHttpResponse(HttpResponse response){

        if (response.getStatusCode() == 200) { 
            PDL_API_Response r = 
            (PDL_API_Response) System.JSON.deserialize(response.getBody(),
                                                                 PDL_API_Response.class);
            return r;  
        }

        String errorRef = logError(response, 'Error from PdlService.');
        throw new HentPersonResponseException('Kunne ikke hente data fra PDL: ' + errorRef);
    }

    private static String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.httpError(message, resp, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }

    private static String logError(String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }
    public class MissingExpectedDataException extends Exception{}
    public class HentPersonResponseException extends Exception{}
}
