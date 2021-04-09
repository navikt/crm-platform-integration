public with sharing class AltinnCalloutService {
    private final string API_CONFIG_NAME = 'ALTINN_API'; //API Config name to set when using the ApiController
    public AltinnResponse getOrganizations(String personIdent){

        AltinnResponse resp=new AltinnResponse();

        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('userId', personIdent);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_ALTINN_ORGANIZATIONS', new Map<String,String>());
        //apiCtrl.addHeader('Authorization', 'Bearer ' + getMaskinportenToken());
        apiCtrl.addHeader('Ocp-apim-subscription-key','c89a44b7-76b4-44b4-9279-ae2e7a15c63b');
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');

        system.debug(statusCode);
        system.debug(bodyString);
        if (statusCode == 200) {
            resp.success = true;
            if (true == String.isNotBlank(bodyString)) {
                resp.organizations = (List<Organization>) JSON.deserialize(
                    bodyString,
                    List<Organization>.class
                );
            }
        } else {
            String errorRef = logError(
                apiCtrl.getResponse(),
                'Error from AltinnCalloutService.getOrganizations'
            );
            resp.errorMessage =
                'Kunne ikke hente organisasjoner fra Altinn. Referanse til feil: ' +
                errorRef;
            resp.success = false;
        }

        return resp;
    }

    public AltinnResponse getRoles(String personIdent, String organizationNumber){
        return new AltinnResponse();
    }

    private String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(
            message +
            '\n ' +
            'Status: ' +
            resp.getStatus() +
            '\n' +
            'Body: ' +
            resp.getBody(),
            null
        );
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();

        return errorRef;
    }

    // RESPONSE WRAPPERS
    public class AltinnResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public List<Organization> organizations;
        @AuraEnabled
        public List<Role> roles;
        @AuraEnabled
        public String errorMessage;

        public AltinnResponse() {
            this.success = false;
            this.organizations = null;
            this.roles=null;
            this.errorMessage = null;
        }
    }

    private string getMaskinportenToken(){
        String clientDeveloperName='salesforce_altinn_test';
        MaskinportenService service = new MaskinportenService(clientDeveloperName);
        return service.doMaskinportenJWTExchange().access_token;
    }

    public class Organization{
        @AuraEnabled
        public String Name {get;set;}
        @AuraEnabled
        public String Type {get;set;}
        @AuraEnabled
        public String OrganizationNumber {get;set;}
        @AuraEnabled
        public String ParentOrganizationNumber {get;set;}
        @AuraEnabled
        public String OrganizationForm {get;set;}
        @AuraEnabled
        public String Status {get;set;}
    }

    public class Role{
        @AuraEnabled
        public String RoleType {get;set;}
        @AuraEnabled
        public String RoleDefinitionId {get;set;}
        @AuraEnabled
        public String RoleName {get;set;}
        @AuraEnabled
        public String RoleDescription {get;set;}   
    }
}
