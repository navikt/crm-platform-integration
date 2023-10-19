public with sharing class AltinnCalloutService {
    private final string API_CONFIG_NAME = 'ALTINN_API'; //API Config name to set when using the ApiController

    private string accessToken;

    public AltinnOrganizationsResponse getOrganizations(String personIdent) {
        AltinnOrganizationsResponse resp = new AltinnOrganizationsResponse();

        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('subject', personIdent);
        urlParamMap.put('$filter', 'Status%20eq%20\'Active\'%20and%20OrganizationForm%20ne%20\'BEDR\'');
        
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_ALTINN_ORGANIZATIONS', new Map<String, String>());
        apiCtrl.addHeader('Authorization', 'Bearer ' + getMaskinportenToken());
        apiCtrl.addHeader('ApiKey', '{!$Credential.Password}');
        apiCtrl.addHeader('Accept', 'application/hal+json');
        apiCtrl.setUrlParams(urlParamMap);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();

        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');
        bodyString = bodyString.replaceAll('_embedded', 'embedded');

        if (statusCode == 200) {
            resp.success = true;
            if (true == String.isNotBlank(bodyString)) {
                OrganizationsWrapper wrapper = (OrganizationsWrapper) JSON.deserialize(
                    bodyString,
                    OrganizationsWrapper.class
                );
                if (wrapper.embedded.reportees != null) {
                    resp.organizations = wrapper.embedded.reportees;
                }
            }
        } else {
            String errorRef = logError(apiCtrl.getResponse(), 'Error from AltinnCalloutService.getOrganizations');
            resp.errorMessage = 'Kunne ikke hente organisasjoner fra Altinn. Referanse til feil: ' + errorRef;
            resp.success = false;
        }

        return resp;
    }

    public AltinnRightsResponse getRights(String personIdent, String organizationNumber) {
        	return getRights(personIdent,organizationNumber,null);
    }
    public AltinnRightsResponse getRights(String personIdent, String organizationNumber, String serviceCode) {
        AltinnRightsResponse resp = new AltinnRightsResponse();

        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('subject', personIdent);
        urlParamMap.put('reportee', organizationNumber);
        
       	//filter on service code
        if(serviceCode!=null){
            urlParamMap.put('$filter', 'ServiceCode%20eq%20\'' + serviceCode + '\'');
        } 

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_ALTINN_RIGHTS', new Map<String, String>());
        apiCtrl.addHeader('Authorization', 'Bearer ' + getMaskinportenToken());
        apiCtrl.addHeader('ApiKey', '{!$Credential.Password}');
        apiCtrl.addHeader('Accept', 'application/hal+json');
        apiCtrl.setUrlParams(urlParamMap);
        apiCtrl.doCallout();

        Integer statusCode = apiCtrl.getResponse().getStatusCode();
        String bodyString = apiCtrl.getResponse().getBody();
        bodyString = bodyString.replaceAll('\n', '\\\\r\\\\n');

        if (statusCode == 200) {
            resp.success = true;
            if (true == String.isNotBlank(bodyString)) {
                RightsWrapper wrapper = (RightsWrapper) JSON.deserialize(bodyString, RightsWrapper.class);
                if (wrapper.rights != null) {
                    resp.rights = wrapper.rights;
                }
            }
        } else {
            String errorRef = logError(apiCtrl.getResponse(), 'Error from AltinnCalloutService.getRights');
            resp.errorMessage = 'Kunne ikke hente rettigheter fra Altinn. Referanse til feil: ' + errorRef;
            resp.success = false;
        }

        return resp;
    }

    private String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message + '\n ' + 'Status: ' + resp.getStatus() + '\n' + 'Body: ' + resp.getBody(), null);
        errorRef = logger.peek().UUID__c; //Unique error reference for troubleshooting
        logger.publish();

        return errorRef;
    }

    private string getMaskinportenToken() {
        String clientDeveloperName = Test.isRunningTest() ? 'salesforce_altinn_test' : 'salesforce_altinn';
        MaskinportenService service = new MaskinportenService(clientDeveloperName);

        if (accessToken == null) {
            MaskinportenService.AuthResponse response = service.doMaskinportenJWTExchange();
            if (response == null) {
                return null;
            }
            accessToken = response.access_token;
        }
        return accessToken;
    }

    // RESPONSE WRAPPERS
    public class AltinnOrganizationsResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public List<Organization> organizations;
        @AuraEnabled
        public String errorMessage;

        public AltinnOrganizationsResponse() {
            this.success = false;
            this.organizations = null;
            this.errorMessage = null;
        }
    }

    private class OrganizationsWrapper {
        private embedded embedded;
    }

    private class RightsWrapper {
        private List<Right> rights;
    }

    private class embedded {
        private List<Organization> reportees;
    }

    public class AltinnRightsResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public List<Right> rights;
        @AuraEnabled
        public String errorMessage;

        public AltinnRightsResponse() {
            this.success = false;
            this.rights = null;
            this.errorMessage = null;
        }
    }

    public class Organization {
        @AuraEnabled
        public String Name;
        @AuraEnabled
        public String Type;
        @AuraEnabled
        public String OrganizationNumber;
        @AuraEnabled
        public String ParentOrganizationNumber;
        @AuraEnabled
        public String OrganizationForm;
        @AuraEnabled
        public String Status;
    }

    public class Right {
        @AuraEnabled
        public String ServiceCode;
        @AuraEnabled
        public String Action;
        @AuraEnabled
        public String RightID;
        @AuraEnabled
        public String RightType;
        @AuraEnabled
        public String ServiceEditionCode;
        @AuraEnabled
        public String RightSourceType;
        @AuraEnabled
        public String IsDelegatable;
    }
}
