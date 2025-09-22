/**
 * @description
 * Handles secure integration with Altinn 3.0 APIs for fetching organizations and access rights.
 * Manages access token lifecycle with caching, decryption, and expiration control.
 * Retrieves configuration from Altinn3IntegrationSetting__c and logs errors using LoggerUtility.
 * Supports callouts to authorization and organizational endpoints.
 * Implements IAltinnCalloutService for standardized usage across the platform.
 *
 * @group Altinn Callout Service
 *
 * @author Kenneth Sørensen
 * @since May 2025 - Created.
 *
 * @see IAltinnCalloutService
 * @see Altinn3IntegrationSetting__c
 */
@SuppressWarnings('PMD.CyclomaticComplexity')
public with sharing class Altinn3CalloutService implements IAltinnCalloutService {
    /**
     * @description
     * The category for the Altinn callout service.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    public static final String CATEGORY = 'Altinn';
    /**
     * @description
     * The cache partition name for storing tokens.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    public static final String CACHE_PARTITION = 'local.tokens';

    /**
     * @description
     * Minimum cache expiration times for the Altinn access token supported by the
     * Salesforce platform caching.
     * The token will be cached for a minimum of 5 minutes.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    private static final Integer CACHE_EXPIRATION_MINIMUM_TIME = 300;
    /**
     * @description
     * Maximum cache expiration times for the Altinn access token supported by the
     * Salesforce platform caching.
     * The token will be cached for a maximum of 1 hour.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    private static final Integer CACHE_EXPIRATION_MAXIMUM_TIME = 3600;

    /**
     * @description
     * The name of the callout used for token retrieval.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestVisible
    private String calloutName;
    /**
     * @description The cache key name for storing tokens.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestVisible
    private String cacheKeyName;
    /**
     * @description
     * The Altinn endpoint URL for API calls.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestVisible
    private String altinnEndpoint;
    /**
     * @description
     * The logger utility instance for logging errors and information.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     * @see LoggerUtility
     */
    @TestVisible
    private LoggerUtility logger;
    /**
     * @description The token cache instance for caching access tokens.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     * @see ITokenCache
     */
    @TestVisible
    private ITokenCache tokenCache;
    /**
     * @description
     * The current access token used for API calls.
     * This is set to null initially and will be populated when the token is retrieved or refreshed
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestVisible
    private String currentAccessToken;
    /**
     * @description The subscription key used for API calls.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestVisible
    private String subscriptionKey;

    /**
     * @description
     * Constructor for the Altinn3CalloutService class.
     * Initializes the logger, token cache, and retrieves settings from Altinn3IntegrationSetting__c.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @throws Altinn3CalloutServiceException if any required setting is not configured.
     *
     * @see Altinn3IntegrationSetting__c
     */
    public Altinn3CalloutService() {
        this.logger = new LoggerUtility(CRM_ApplicationDomain.Domain.PLATFORCE, CATEGORY);
        Altinn3IntegrationSetting__c settings = Altinn3IntegrationSetting__c.getInstance();

        if (String.isBlank(settings.Name)) {
            logAndThrow('Altinn3IntegrationSetting__c is not configured.');
        }

        this.tokenCache = new PlatformTokenCache(
            validateAndGet(settings.CachePartitionName__c, 'Cache partition name')
        );
        this.calloutName = validateAndGet(settings.CalloutName__c, 'Callout name');
        this.altinnEndpoint = validateAndGet(settings.Endpoint__c, 'Altinn endpoint');
        this.cacheKeyName = validateAndGet(settings.CacheKeyName__c, 'Cache key name');
        this.subscriptionKey = validateAndGet(settings.SubscriptionKey__c, 'Subscription key');
    }

    /**
     * @description
     * This method is used to get the Altinn endpoint.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the user.
     * @return `Organization` The organization information for the given person identification number.
     */
    public AltinnCalloutService.AltinnOrganizationsResponse getOrganizations(String personIdent) {
        List<AltinnCalloutService.Organization> orgs = this.authorizedPartiesServiceCallout(personIdent);

        AltinnCalloutService.AltinnOrganizationsResponse resp = new AltinnCalloutService.AltinnOrganizationsResponse();
        resp.organizations = orgs != null ? orgs : new List<AltinnCalloutService.Organization>();
        return resp;
    }

    /**
     * @description
     * Retrieves access rights for a given person, organization, and resource from the Altinn 3.0 API.
     * Performs a callout to the authorization endpoint and returns the rights information in a
     * standardized response object.
     * Handles token management and error handling internally.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the user whose rights are being queried.
     * @param organizationNumber The organization number for which access rights are requested.
     * @param resource The specific resource to check access rights for.
     * @return AltinnCalloutService.AltinnRightsResponse The response containing access rights details or error information.
     *
     * @See AltinnCalloutService.AltinnRightsResponse
     * @see AltinnCalloutService.Right
     * @see AltinnResponseUtils.AltinnAccessResponseWrapper
     * @see [Altinn Platform Authorization / Decision / authorize](https://docs.altinn.studio/nb/api/authorization/spec/#/Decision/post_authorize)
     * @see [JSON Profile of XACML 3.0 Version 1.0](https://docs.oasis-open.org/xacml/xacml-json-http/v1.0/cos01/xacml-json-http-v1.0-cos01.html)
     */
    public AltinnCalloutService.AltinnRightsResponse getRights(
        String personIdent,
        String organizationNumber,
        String resource
    ) {
        AltinnResponseUtils.AltinnAccessResponseWrapper result = this.authorizeServiceCallout(
            personIdent,
            organizationNumber,
            resource
        );

        AltinnCalloutService.AltinnRightsResponse resp = new AltinnCalloutService.AltinnRightsResponse();
        if (result != null && result.isPermit()) {
            resp.success = true;
            resp.rights = new List<AltinnCalloutService.Right>();
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access'; //TODO: This should be dynamic based on the actual action requested.
            right.Decision = result.getDecision();
            right.Resource = resource;
            resp.rights.add(right);
        } else if (result != null && result.isDeny()) {
            // TODO: Handle the case where access is denied in a more user-friendly way when we have removed the use of Altinn 2.0
            // This could mean that the user does not have the necessary permissions to access the resource.
            // We should log this and inform the user appropriately.
            resp.success = false; // TODO: Change to true to indicate that the request was successful and use the other fields to indicate the status. Is not possible to change that with Altinn version 2 and how it is used in Aa-Reg today.
            resp.errorMessage = 'Access denied';
            resp.rights = new List<AltinnCalloutService.Right>();
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access'; //TODO: This should be dynamic based on the actual action requested.
            right.Decision = result.getDecision();
            right.Resource = resource;
            resp.rights.add(right);
        } else if (result != null && result.isIndeterminate()) {
            // TODO: Handle the case where access is indeterminate in a more user-friendly way when we have removed the use of Altinn 2.0
            // This could mean that the access status is not clear, possibly due to missing data or configuration issues.
            // We should log this and inform the user appropriately.
            resp.success = false; // TODO: Change to true to indicate that the request was successful and use the other fields to indicate the status. Is not possible to change that with Altinn version 2 and how it is used in Aa-Reg today.
            resp.errorMessage = 'Indeterminate access status';
            resp.rights = new List<AltinnCalloutService.Right>();
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access'; //TODO: This should be dynamic based on the actual action requested.
            right.Decision = result.getDecision();
            right.Resource = resource;
            resp.rights.add(right);
        } else if (result != null && result.isNotApplicable()) {
            // TODO: Handle the case where access is not applicable in a more user-friendly way when we have removed the use of Altinn 2.0
            // This could mean that the resource is not applicable for the requested access rights.
            // We should log this and inform the user appropriately.
            resp.success = false; // TODO: Change to true to indicate that the request was successful and use the other fields to indicate the status. Is not possible to change that with Altinn version 2 and how it is used in Aa-Reg today.
            resp.errorMessage = 'Not applicable for the requested resource';
            resp.rights = new List<AltinnCalloutService.Right>();
            AltinnCalloutService.Right right = new AltinnCalloutService.Right();
            right.Action = 'Access'; //TODO: This should be dynamic based on the actual action requested.
            right.Decision = result.getDecision();
            right.Resource = resource;
            resp.rights.add(right);
        } else {
            // TODO: Handle the case where the result is null or does not match any of the expected conditions.
            // This could mean that the callout failed or returned an unexpected response.
            // We should log this and inform the user appropriately.
            // This could be due to various reasons such as network issues, API changes, or unexpected
            // responses from the Altinn API.
            resp.success = false;
            resp.errorMessage = 'Access denied';
        }

        return resp;
    }

    /**
     * @description
     * Performs a callout to the Altinn v3 authorization API to check if a user has access to a specific resource
     * on behalf of an organization.
     * Logs a warning if the callout fails and returns the parsed access response if successful.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the user.
     * @param organizationNumber The organization number for which access is requested.
     * @param resource The specific resource to check access rights for.
     * @return `AltinnResponseUtils.AltinnAccessResponseWrapper` The response wrapper containing access rights information.
     *
     * @see AltinnResponseUtils.AltinnAccessResponseWrapper
     * @see AltinnRequestBuilder.buildAuthorizeAccessRequest
     * @see [Altinn Platform Authorization / Decision / authorize](https://docs.altinn.studio/nb/api/authorization/spec/#/Decision/post_authorize)
     * @see [JSON Profile of XACML 3.0 Version 1.0](https://docs.oasis-open.org/xacml/xacml-json-http/v1.0/cos01/xacml-json-http-v1.0-cos01.html)
     */
    @TestVisible
    private AltinnResponseUtils.AltinnAccessResponseWrapper authorizeServiceCallout(
        String personIdent,
        String organizationNumber,
        String resource
    ) {
        if (this.currentAccessToken == null) {
            this.currentAccessToken = getAltinnAccessToken();
        }

        String requestBody = AltinnRequestBuilder.buildAuthorizeAccessRequest(
            personIdent,
            organizationNumber,
            resource
        );

        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + this.altinnEndpoint + '/authorization/api/v1/authorize');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Ocp-Apim-Subscription-Key', this.subscriptionKey);
        request.setHeader('Authorization', 'Bearer ' + this.currentAccessToken);
        request.setHeader('Accept', 'application/json');
        request.setBody(requestBody);

        Http http = new Http();
        HttpResponse response = http.send(request);

        AltinnResponseUtils.AltinnAccessResponseWrapper result = null;
        if (response.getStatusCode() == 200) {
            try {
                result = AltinnResponseUtils.parse(response.getBody());
            } catch (Exception ex) {
                this.logger.exception(ex, CRM_ApplicationDomain.Domain.PLATFORCE);
                this.logger.publish();
                return result;
            }
        } else {
            this.logger.logMessage(
                LoggerUtility.LogLevel.WARNING,
                null,
                null,
                'Altinn v.3 Service Callout for authorization failed. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        }

        return result;
    }

    /**
     * @description
     * This method is used to get the authorized parties for a given person identity.
     * It performs a callout to the Altinn Access Management Resource Owner API to retrieve the list
     * of organizations that the user has access to.
     * Logs a warning if the callout fails and returns the list of organizations.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the user.
     * @return `List<AltinnCalloutService.Organization>` The list of organizations that the user has access to.
     *
     * @see AltinnResponseUtils.AltinnAccessResponseWrapper
     * @see AltinnRequestBuilder.buildAuthorizeAccessRequest
     * @see [Altinn Access Management / Resource Owner / Authorized Parties](https://docs.altinn.studio/nb/api/accessmanagement/resourceowneropenapi/#/Authorized%20Parties)
     * @see [JSON Profile of XACML 3.0 Version 1.0](https://docs.oasis-open.org/xacml/xacml-json-http/v1.0/cos01/xacml-json-http-v1.0-cos01.html)
     */
    @TestVisible
    private List<AltinnCalloutService.Organization> authorizedPartiesServiceCallout(String personIdent) {
        if (this.currentAccessToken == null) {
            this.currentAccessToken = getAltinnAccessToken();
        }

        String requestBody = AltinnRequestBuilder.buildAuthorizedPartiesRequest(personIdent);

        HttpRequest request = new HttpRequest();
        request.setEndpoint(
            'callout:' +
                this.altinnEndpoint +
                '/accessmanagement/api/v1/resourceowner/authorizedparties?includeAltinn2=true'
        );
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setHeader('Ocp-Apim-Subscription-Key', this.subscriptionKey);
        request.setHeader('Authorization', 'Bearer ' + this.currentAccessToken);
        request.setHeader('Accept', 'application/json');
        request.setBody(requestBody);

        Http http = new Http();
        HttpResponse response = http.send(request);

        List<AltinnCalloutService.Organization> orgs = new List<AltinnCalloutService.Organization>();
        if (response.getStatusCode() == 200) {
            try {
                orgs = (List<AltinnCalloutService.Organization>) JSON.deserialize(
                    response.getBody(),
                    List<AltinnCalloutService.Organization>.class
                );
            } catch (Exception ex) {
                this.logger.exception(ex, CRM_ApplicationDomain.Domain.PLATFORCE);
                this.logger.publish();
                return orgs;
            }
        } else {
            this.logger.logMessage(
                LoggerUtility.LogLevel.WARNING,
                null,
                null,
                'Altinn v.3 Service Callout for authorization failed. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        }

        return orgs;
    }

    /**
     * @description
     * Retrieves the Altinn access token from cache or refreshes it if necessary.
     * Validates the token's presence and expiration before returning.
     * Ensures that a valid and non-expired token is always provided for API calls.
     * Returns `null` if unable to obtain a valid token.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @return `String` The Altinn access token if successful, `null` otherwise.
     *
     * @see refreshAndCacheAccessToken
     * @see parseTokenData
     */
    @TestVisible
    private String getAltinnAccessToken() {
        System.debug('Retrieving Altinn access token from cache.');
        System.debug('Cache key: ' + this.cacheKeyName);
        System.debug('Token Cache: ' + this.tokenCache);
        String tokenData = (String) this.tokenCache.get(this.cacheKeyName);
        if (String.isBlank(tokenData)) {
            System.debug('No token data found in cache, refreshing token.');
            return refreshAndCacheAccessToken();
        }

        Map<String, Object> tokenDataMap = parseTokenData(tokenData);
        if (tokenDataMap == null) {
            return refreshAndCacheAccessToken();
        }

        String accessToken = (String) tokenDataMap.get('accessToken');
        Integer issuedAt = (Integer) tokenDataMap.get('issuedAt');
        Integer expiresAt = (Integer) tokenDataMap.get('expiresAt');

        if (String.isBlank(accessToken) || issuedAt == null || expiresAt == null) {
            return refreshAndCacheAccessToken();
        }

        Integer now = (Integer) (DateTime.now().getTime() / 1000);
        if (expiresAt > now && (expiresAt - issuedAt > CACHE_EXPIRATION_MINIMUM_TIME)) {
            return accessToken;
        }

        return refreshAndCacheAccessToken();
    }

    /**
     * @description This method is used to parse the token data.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param tokenData The token data to be parsed.
     * @return `Map<String, Object>` The parsed token data as a map.
     *
     * @see CryptoService.decryptString
     */
    @TestVisible
    private Map<String, Object> parseTokenData(String tokenData) {
        try {
            String decryptedTokenData = CryptoService.decryptString(tokenData);
            return (Map<String, Object>) JSON.deserializeUntyped(decryptedTokenData);
        } catch (Exception ex) {
            this.logger.exception(ex, CRM_ApplicationDomain.Domain.PLATFORCE);
            this.logger.publish();
            return null;
        }
    }

    /**
     * @description
     * Retrieves a new Altinn access token via callout and attempts to cache it securely.
     * Logs an error if caching fails, but always returns the token obtained from Altinn regardless of cache outcome.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @return `String` The access token if the callout is successful, `null` otherwise - per `altinnAccessTokenCallout`.
     *
     * @see altinnAccessTokenCallout
     * @see refreshTokenCache
     */
    @TestVisible
    private String refreshAndCacheAccessToken() {
        String accessToken = altinnAccessTokenCallout();
        if (accessToken != null) {
            Boolean cacheSuccess = refreshTokenCache(accessToken);
            if (!cacheSuccess) {
                this.logger.error(
                    'Failed to cache the Altinn access token.',
                    null,
                    CRM_ApplicationDomain.Domain.PLATFORCE
                );
                this.logger.publish();
            }
        }

        return accessToken;
    }

    /**
     * @description
     * Makes a callout to the Altinn access token endpoint to retrieve an access token.
     * Handles various HTTP response codes, including success, rate limiting, unauthorized access,
     * and bad requests, and logs appropriate messages for each scenario using the logger utility.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @return `String` The access token if the callout is successful, `null` otherwise.
     */
    @TestVisible
    private String altinnAccessTokenCallout() {
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + this.calloutName);
        request.setMethod('GET');
        request.setHeader('Content-Type', 'application/json');

        Http http = new Http();
        HttpResponse response = http.send(request);

        String accessToken = null;
        if (response.getStatusCode() == 200) {
            accessToken = (String) response.getBody();
        } else if (response.getStatusCode() == 429) {
            // Handle rate limit error/Too many requests
            // This could be due to too many requests in a short time.
            this.logger.logMessage(
                LoggerUtility.LogLevel.WARNING,
                null,
                null,
                'Rate limit exceeded/Too many requests. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        } else if (response.getStatusCode() == 401) {
            // Handle unauthorized error
            // This could be due to an expired token or invalid credentials.
            this.logger.logMessage(
                LoggerUtility.LogLevel.WARNING,
                null,
                null,
                'Unauthorized. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        } else if (response.getStatusCode() == 400) {
            // Handle bad request error
            // This could be due to invalid request parameters.
            this.logger.logMessage(
                LoggerUtility.LogLevel.WARNING,
                null,
                null,
                'Bad Request. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        } else {
            // Handle error response
            this.logger.logMessage(
                LoggerUtility.LogLevel.ERROR,
                null,
                null,
                'Error. ' +
                    'Endpoint: ' +
                    request.getEndpoint() +
                    'Status code: ' +
                    response.getStatusCode() +
                    ', Status message: ' +
                    response.getStatus(),
                response.getBody(),
                null
            );
            this.logger.publish();
        }

        return accessToken;
    }

    /**
     * @description
     * Refreshes and updates the token cache with a new access token, recalculating its expiration time based on JWT claims.
     * Handles parsing and validation of the JWT, manages cache expiration boundaries, and securely stores the token data.
     * Returns `true` if the cache was updated successfully, or `false` if any error occurs during processing.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param accessToken The JWT access token to be cached.
     * @return `Boolean` Return `true` if the token cache was refreshed successfully, `false` otherwise.
     */
    @TestVisible
    private Boolean refreshTokenCache(String accessToken) {
        if (String.isEmpty(accessToken)) {
            return false;
        }

        Integer iat = 0;
        Integer exp = 0;
        try {
            Auth.JWT jwt = Auth.JWTUtil.parseJWTFromStringWithoutValidation(accessToken);

            Map<String, Object> jwtMap = (Map<String, Object>) JSON.deserializeUntyped(jwt.toJSONString());
            Object iatObj = jwtMap.get('iat');
            Object expObj = jwtMap.get('exp');
            if (iatObj == null || expObj == null || !(iatObj instanceof Integer) || !(expObj instanceof Integer)) {
                this.logger.error(
                    'JWT claims "iat" or "exp" are missing or not integers.',
                    null,
                    CRM_ApplicationDomain.Domain.PLATFORCE
                );
                this.logger.publish();
                return false;
            }
            iat = (Integer) iatObj;
            exp = (Integer) expObj;
        } catch (Exception ex) {
            this.logger.exception(ex, CRM_ApplicationDomain.Domain.PLATFORCE);
            this.logger.publish();
            return false;
        }

        Integer expiresIn = CACHE_EXPIRATION_MINIMUM_TIME;

        if ((exp - iat) < CACHE_EXPIRATION_MINIMUM_TIME) {
            expiresIn = CACHE_EXPIRATION_MINIMUM_TIME;
        } else if ((exp - iat) > CACHE_EXPIRATION_MAXIMUM_TIME) {
            expiresIn = CACHE_EXPIRATION_MAXIMUM_TIME;
        } else {
            expiresIn = exp - iat;
        }

        AltinnAccessToken altinnTokenData = new AltinnAccessToken();
        altinnTokenData.accessToken = accessToken;
        altinnTokenData.issuedAt = iat;
        altinnTokenData.expiresAt = exp;
        altinnTokenData.expiresIn = expiresIn;

        try {
            this.tokenCache.put(
                this.cacheKeyName,
                CryptoService.encryptString(JSON.serialize(altinnTokenData)),
                expiresIn
            );
        } catch (Exception ex) {
            this.logger.exception(ex, CRM_ApplicationDomain.Domain.PLATFORCE);
            this.logger.publish();
            return false;
        }

        return true;
    }

    /**
     * @description
     * Validates that the provided setting value is not blank and returns it.
     * If the value is blank, logs an error message including the setting name and throws an exception.
     *
     * This method is intended for internal use to ensure that required configuration
     * settings are present before proceeding with further logic. It helps prevent
     * runtime errors caused by missing or misconfigured settings.
     *
     * @author Kenneth Sørensen
        if (String.isBlank(value)) {
            logAndThrow(settingName + ' is not configured in Altinn3IntegrationSetting__c.');
            return null; // This line is unreachable, but improves clarity for maintainers
        }
        return value;
     * @return `String` The validated setting value.
     * @throws Altinn3CalloutServiceException if the value is blank.
     *
     * @see logAndThrow
     */
    @TestVisible
    private String validateAndGet(String value, String settingName) {
        if (String.isBlank(value)) {
            logAndThrow(settingName + ' is not configured in Altinn3IntegrationSetting__c.');
        }
        return value;
    }

    /**
     * @description
     * Logs an error and throws an `Altinn3CalloutServiceException`.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param message The error message to log and include in the exception.
     * @throws Altinn3CalloutServiceException with the provided message.
     */
    @TestVisible
    private void logAndThrow(String message) {
        this.logger.error(message, null, CRM_ApplicationDomain.Domain.PLATFORCE);
        this.logger.publish();
        throw new Altinn3CalloutServiceException(message);
    }

    /**
     * @description
     * Custom exception class for handling errors in the Altinn3CalloutService.
     * This exception is thrown when there are issues with the Altinn callout service,
     * such as missing configuration settings or errors during API calls.
     *
     * @group Altinn Callout Service
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    public class Altinn3CalloutServiceException extends Exception {
    }

    /**
     * @description
     * Represents the access token information returned from the Altinn API.
     * This class is used for deserializing the JSON response containing the access token and its metadata.
     * It includes fields for the token value, expiration timestamps, and the time the token was issued.
     *
     * Use this class to manage and track the lifecycle of an Altinn access token within the integration process.
     *
     * @group Altinn Callout Service
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    public class AltinnAccessToken {
        public String accessToken;
        public Integer expiresAt;
        public Integer expiresIn;
        public Integer issuedAt;
    }
}
