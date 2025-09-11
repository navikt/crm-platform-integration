/**
 * @description Service class for calling Altinn APIs.
 *
 * @author Frode Hoen <frode.hoen@nav.no>
 * @since 2021-04-07 Created.
 * @author Kenneth Soerensen <kenneth.sorensen@nav.no>
 * @since 2023-11-13 Added token caching.
 *
 * @see https://docs.altinn.studio/api/
 * @see AltinnCalloutServiceTest
 *
 * @group Altinn
 */
public with sharing class Altinn2CalloutService implements IAltinnCalloutService {
    private final string API_CONFIG_NAME = 'ALTINN_API'; //API Config name to set when using the ApiController
    @TestVisible
    private static final String TEST_SERVICE_TOKEN_RESPONSE =
        '{"access_token": "TEST_ACCESS", "expires": ' +
        JSON.serialize(Datetime.now().addSeconds(3600)) +
        '}';

    private string accessToken;

    public AltinnCalloutService.AltinnOrganizationsResponse getOrganizations(String personIdent) {
        AltinnCalloutService.AltinnOrganizationsResponse resp = new AltinnCalloutService.AltinnOrganizationsResponse();

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

    public AltinnCalloutService.AltinnRightsResponse getRights(String personIdent, String organizationNumber) {
        return getRights(personIdent, organizationNumber, null);
    }
    public AltinnCalloutService.AltinnRightsResponse getRights(
        String personIdent,
        String organizationNumber,
        String serviceCode
    ) {
        AltinnCalloutService.AltinnRightsResponse resp = new AltinnCalloutService.AltinnRightsResponse();

        Map<String, String> urlParamMap = new Map<String, String>();
        urlParamMap.put('subject', personIdent);
        urlParamMap.put('reportee', organizationNumber);

        //filter on service code
        if (serviceCode != null) {
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

    /**
     * @description Gets the access token from the cache.
     * If the token is not in the cache, it will be requested from Maskinporten.
     * Note: This method is not the final method for retrieving the access token.
     *
     * @return `String` The access token
     */
    @TestVisible
    private string getMaskinportenToken() {
        String clientName = 'altinntokendata';

        LoggerUtility logger = new LoggerUtility();

        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.tokens');
        /*String tokenData = Test.isRunningTest()
            ? CryptoService.encryptString(TEST_SERVICE_TOKEN_RESPONSE)
            : (String) orgPartition.get(clientName);*/
        String tokenData = (String) orgPartition.get(clientName);

        if (String.isNotBlank(tokenData)) {
            String decryptedTokenData = CryptoService.decryptString(tokenData);
            Map<String, Object> tokenDataMap = (Map<String, Object>) JSON.deserializeUntyped(decryptedTokenData);
            Datetime createdAt = (DateTime) JSON.deserialize(
                '"' + tokenDataMap.get('created_at') + '"',
                DateTime.class
            );
            System.debug('Token created at: ' + createdAt);
            Datetime expiresAt = createdAt.addSeconds((Integer) tokenDataMap.get('expires_in'));
            Datetime timeNow = Datetime.now();

            if (expiresAt < timeNow) {
                System.debug('Token expired, requesting new token');
                logger.info('Token expired, requesting new token', null);
                accessToken = this.refreshTokenCache();
            } else {
                System.debug('Token not expired, using existing token');
                logger.info('Token not expired, using existing token', null);
                accessToken = (String) tokenDataMap.get('access_token');
            }
        } else {
            if (accessToken == null) {
                System.debug('No token in cache, requesting new token');
                logger.info('No token in cache, requesting new token', null);
                accessToken = this.refreshTokenCache();
            }
        }

        logger.publish();
        return accessToken;
    }

    /**
     * @description Refreshes the token cache.
     * Note: This method is not the final method for refreshing the token cache.
     *
     * @return `String` The access token
     */
    @TestVisible
    private String refreshTokenCache() {
        String clientDeveloperName = Test.isRunningTest() ? 'salesforce_altinn_test' : 'salesforce_altinn';
        String clientName = 'altinntokendata';
        LoggerUtility logger = new LoggerUtility();

        Cache.OrgPartition orgPartition = Cache.Org.getPartition('local.tokens');
        MaskinportenService service = new MaskinportenService(clientDeveloperName);

        MaskinportenService.AuthResponse testResponse = new MaskinportenService.AuthResponse();
        testResponse.access_token = 'access_token_test';
        testResponse.expires_in = 119;
        testResponse.created_at = Datetime.now();
        testResponse.scope = 'test_scope';

        MaskinportenService.AuthResponse response = Test.isRunningTest()
            ? testResponse
            : service.doMaskinportenJWTExchange();

        if (response == null) {
            return null;
        }
        accessToken = response.access_token;
        Integer expiresIn = 300; //response.expires_in;

        try {
            orgPartition.put(clientName, CryptoService.encryptString(JSON.serialize(response)), expiresIn);
        } catch (Exception ex) {
            logger.error('Error putting info into cache.' + '\n ' + 'Exception: ' + ex, null);
            System.debug('Error putting info into cache.' + '\n ' + 'Exception: ' + ex);
        }

        return accessToken;
    }

    // RESPONSE WRAPPERS

    private class OrganizationsWrapper {
        private embedded embedded;
    }

    private class RightsWrapper {
        private List<AltinnCalloutService.Right> rights;
    }

    private class embedded {
        private List<AltinnCalloutService.Organization> reportees;
    }
}
