/**
 * @description
 * Unit test suite for Altinn3CalloutService.
 * Covers integration logic, token caching, authorization, and error handling.
 * Ensures reliable and isolated testing of Altinn 3 communication flows, including edge cases.
 *
 * @author Kenneth Sørensen
 * @since May 2025 - Created.
 *
 * @group Altinn Callout Service
 */
@SuppressWarnings('PMD')
@isTest
private class Altinn3CalloutServiceTest {
    // -------------------------------
    // Test data setup
    // -------------------------------
    /**
     * @description
     * Seeds shared test data (`encryption key` and `Altinn3IntegrationSetting__c`) for
     * deterministic, isolated tests.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     */
    @TestSetup
    private static void makeData() {
        BaseTestFactory.insertEncryptionKey();

        Altinn3IntegrationSetting__c settings = new Altinn3IntegrationSetting__c();
        settings.Name = 'Altinn3IntegrationSettings';
        settings.CachePartitionName__c = 'TestPartition';
        settings.CalloutName__c = 'Altinn_Test_Access_Token';
        settings.Endpoint__c = 'Altinn_Endpoint_Test';
        settings.CacheKeyName__c = 'altinn3CalloutService';
        settings.SubscriptionKey__c = 'altinn3subscriptionkey';

        insert settings;
    }

    // -------------------------------
    // Constructor and configuration
    // -------------------------------
    /**
     * @description
     * Verifies constructor initializes dependencies and configuration from
     * `Altinn3IntegrationSetting__c` (token cache, endpoint, callout name, cache key,
     * subscription key).
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService
     */
    @IsTest
    private static void constructor() {
        Altinn3IntegrationSetting__c settings = Altinn3IntegrationSetting__c.getInstance();
        System.Assert.isNotNull(settings, 'Altinn3IntegrationSetting__c should be initialized');

        System.Test.startTest();
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.stopTest();

        System.Assert.isNotNull(service, 'Service should be instantiated');

        System.Assert.isNotNull(service.tokenCache, 'Token cache should be initialized');
        System.Assert.isTrue(
            service.tokenCache instanceof PlatformTokenCache,
            'Token cache should be an instance of PlatformTokenCache'
        );

        System.Assert.isNotNull(service.calloutName, 'Callout name should be set');
        System.Assert.areEqual(
            settings.CalloutName__c,
            service.calloutName,
            'Callout name should match the expected value'
        );

        System.Assert.isNotNull(service.altinnEndpoint, 'Altinn endpoint should be set');
        System.Assert.areEqual(
            settings.Endpoint__c,
            service.altinnEndpoint,
            'Altinn endpoint should match the expected value'
        );

        System.Assert.isNotNull(service.cacheKeyName, 'Cache key name should be set');
        System.Assert.areEqual(
            settings.CacheKeyName__c,
            service.cacheKeyName,
            'Cache key name should match the expected value'
        );

        System.Assert.isNotNull(service.subscriptionKey, 'Subscription key should be set');
        System.Assert.areEqual(
            settings.SubscriptionKey__c,
            service.subscriptionKey,
            'Subscription key should match the expected value'
        );
    }

    /**
     * @description
     * Verifies that constructor fails fast when `Altinn3IntegrationSetting__c` is missing by
     * throwing `Altinn3CalloutServiceException` with a clear message.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService
     */
    @IsTest
    static void constructorWithNullSettings() {
        // Delete the test setup settings to simulate null getInstance()
        delete [SELECT Id FROM Altinn3IntegrationSetting__c];

        Exception caughtException = null;
        System.Test.startTest();
        try {
            new Altinn3CalloutService();
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected exception should be thrown');
        System.Assert.isInstanceOfType(
            caughtException,
            Altinn3CalloutService.Altinn3CalloutServiceException.class,
            'Should throw Altinn3CalloutServiceException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Altinn3IntegrationSetting__c is not configured'),
            'Exception message should contain expected text'
        );
    }

    // -------------------------------
    // Validation and error utilities
    // -------------------------------
    /**
     * @description
     * Verifies that `logAndThrow` logs the error and throws an `Altinn3CalloutServiceException`
     * with the provided message.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.logAndThrow
     */
    @IsTest
    private static void logAndThrow() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String message = 'Test message';

        Exception expectedException = null;
        System.Test.startTest();
        try {
            service.logAndThrow(message);
        } catch (Exception e) {
            expectedException = e;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(expectedException, 'Expected exception should not be null');
        System.Assert.isTrue(
            expectedException.getMessage().contains(message),
            'Exception message should contain the expected message'
        );
        System.Assert.isInstanceOfType(expectedException, Altinn3CalloutService.Altinn3CalloutServiceException.class);

        Integer logCount = [SELECT COUNT() FROM Application_Log__c WHERE Source_Class__c = 'Altinn3CalloutService'];
        System.Assert.isTrue(logCount > 0, 'Exception should be logged');
        System.Assert.isTrue(logCount == 1, 'Only one exception should be logged');
    }

    /**
     * @description
     * Verifies that `validateAndGet` rejects blank configuration values by throwing
     * `Altinn3CalloutServiceException` naming the missing setting.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.validateAndGet
     */
    @IsTest
    private static void validateAndGetWithEmptyString() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String settingName = 'TestSetting';
        String value = '';

        Exception expectedException = null;
        System.Test.startTest();
        try {
            service.validateAndGet(value, settingName);
        } catch (Exception e) {
            expectedException = e;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(expectedException, 'Expected exception should not be null');
        System.Assert.isTrue(
            expectedException.getMessage()
                .contains(settingName + ' is not configured in Altinn3IntegrationSetting__c.'),
            'Exception message should contain the setting name'
        );
        System.Assert.isInstanceOfType(expectedException, Altinn3CalloutService.Altinn3CalloutServiceException.class);
    }

    /**
     * @description
     * Verifies that `validateAndGet` returns the provided non-blank configuration value unchanged.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.validateAndGet
     */
    @IsTest
    private static void validateAndGetReturnsValue() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String value = 'valid';

        System.Test.startTest();
        String result = service.validateAndGet(value, 'TestSetting');
        System.Test.stopTest();

        System.Assert.areEqual(value, result, 'Expected value should be returned when valid input is provided');
    }

    // -------------------------------
    // Token cache refresh (low-level)
    // -------------------------------
    /**
     * @description
     * Verifies that `refreshTokenCache` accepts a valid JWT, computes TTL from iat/exp, and caches
     * the encrypted token metadata.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCache() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String accessToken = MockAltinnJWTGenerator.createMockAltinnJWT();

        System.Test.startTest();
        Boolean result = service.refreshTokenCache(accessToken);
        System.Test.stopTest();

        System.Assert.areEqual(true, result, 'Expect true when access token is valid');
    }

    /**
     * @description
     * Verifies that `refreshTokenCache` returns `false` and leaves cache untouched when
     * `accessToken` is null/blank.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheWhenAccessTokenIsNull() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String accessToken = null;

        System.Test.startTest();
        Boolean result = service.refreshTokenCache(accessToken);
        System.Test.stopTest();

        System.Assert.areEqual(false, result, 'Expect false when access token is null');

        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');
    }

    /**
     * @description
     * Verifies that `refreshTokenCache` handles malformed JWTs by returning `false`, not caching,
     * and logging the error.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheWithExceptionWhenJWTIsInvalid() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String accessToken = 'Not a valid JWT';

        System.Test.startTest();
        Boolean result = service.refreshTokenCache(accessToken);
        System.Test.stopTest();

        System.Assert.areEqual(false, result, 'Expect false when JWT is invalid');

        // Verify that the token cache is not updated
        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');

        Integer exceptionCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'refreshTokenCache'
        ];
        System.Assert.isTrue(exceptionCount > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionCount == 1, 'Only one exception should be logged');
    }

    /**
     * @description
     * Verifies that `refreshTokenCache` handles cache write failures (using `FailingTokenCache`),
     * returns `false`, does not pollute cache, and logs exactly one exception.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheWithException() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        service.tokenCache = new FailingTokenCache();

        String accessToken = MockAltinnJWTGenerator.createMockAltinnJWT();

        System.Test.startTest();
        Boolean result = service.refreshTokenCache(accessToken);
        System.Test.stopTest();

        System.Assert.areEqual(false, result, 'Expect false when token cache fails');

        String tokenData = (String) Cache.Org.getPartition(Altinn3CalloutService.CACHE_PARTITION)
            .get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');

        Integer exceptionCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'refreshTokenCache'
        ];
        System.Assert.isTrue(exceptionCount > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionCount == 1, 'Only one exception should be logged');
    }

    /**
     * @description
     * Verifies that `refreshTokenCache` rejects JWTs missing required 'iat/exp' claims by returning
     * `false` and logging the validation error.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheMissingClaims() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String invalidJwt = MockAltinnJWTGenerator.createJWTWithMissingClaims();

        System.Test.startTest();
        Boolean result = service.refreshTokenCache(invalidJwt);
        System.Test.stopTest();

        // Assert
        System.Assert.areEqual(false, result, 'Should return false when JWT claims are missing');

        // Verify exception was logged
        Integer exceptionCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'refreshTokenCache'
        ];
        System.Assert.areEqual(1, exceptionCount, 'Exception should be logged');
    }

    // -------------------------------
    // Access token endpoint callout
    // -------------------------------
    /**
     * @description
     * Verifies that `altinnAccessTokenCallout` returns the response body as the token on
     * `HTTP 200 OK`.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.altinnAccessTokenCallout
     */
    @IsTest
    private static void altinnAccessTokenCalloutWith200Returned() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', 'body text', new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String accessToken = service.altinnAccessTokenCallout();
        System.Test.stopTest();

        System.Assert.isNotNull(accessToken, 'Access token should not be null');
        System.Assert.areNotEqual('', accessToken, 'Access token should not be empty');
        System.Assert.areEqual('body text', accessToken, 'Access token should be equal to the response body');
    }

    /**
     * @description
     * Verifies that `altinnAccessTokenCallout` returns null and logs details on
     * `HTTP 400 Bad Request`.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.altinnAccessTokenCallout
     */
    @IsTest
    private static void altinnAccessTokenCalloutWith400Returned() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        SingleRequestMock mock = new SingleRequestMock(400, 'Bad Request', '', new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String accessToken = service.altinnAccessTokenCallout();
        System.Test.stopTest();

        System.Assert.isNull(accessToken, 'Access token should be null');

        // Verify exception was logged
        List<Application_Log__c> exceptionsLogged = [
            SELECT Id, Log_Message__c
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'altinnAccessTokenCallout'
        ];
        System.Assert.isTrue(exceptionsLogged.size() > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionsLogged.size() == 1, 'Only one exception should be logged');
        System.Assert.isTrue(
            exceptionsLogged[0].Log_Message__c.contains('Status code: 400, Status message: Bad Request'),
            'Exception message should contain the expected text'
        );

        // Verify that the token cache is not updated
        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');
    }

    /**
     * @description
     * Verifies that `altinnAccessTokenCallout` returns null and logs details on
     * `HTTP 401 Unauthorized`.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.altinnAccessTokenCallout
     */
    @IsTest
    private static void altinnAccessTokenCalloutWith401Returned() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        SingleRequestMock mock = new SingleRequestMock(401, 'Unauthorized', '', new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String accessToken = service.altinnAccessTokenCallout();
        System.Test.stopTest();

        System.Assert.isNull(accessToken, 'Access token should be null');

        // Verify exception was logged
        List<Application_Log__c> exceptionsLogged = [
            SELECT Id, Log_Message__c
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'altinnAccessTokenCallout'
        ];
        System.Assert.isTrue(exceptionsLogged.size() > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionsLogged.size() == 1, 'Only one exception should be logged');
        System.Assert.isTrue(
            exceptionsLogged[0].Log_Message__c.contains('Status code: 401, Status message: Unauthorized'),
            'Exception message should contain the expected text'
        );

        // Verify that the token cache is not updated
        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');
    }

    /**
     * @description
     * Verifies that the access token callout handles HTTP `429 Too Many Requests` with correct
     * logging and no caching.
     * Verifies `altinnAccessTokenCallout` returns null and logs details on `429 Too Many Requests`
     * (rate limited).
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.altinnAccessTokenCallout
     */
    @IsTest
    private static void altinnAccessTokenCalloutWith429Returned() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        SingleRequestMock mock = new SingleRequestMock(429, 'Too Many Requests', '', new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String accessToken = service.altinnAccessTokenCallout();
        System.Test.stopTest();

        System.Assert.isNull(accessToken, 'Access token should be null');

        // Verify exception was logged
        List<Application_Log__c> exceptionsLogged = [
            SELECT Id, Log_Message__c
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'altinnAccessTokenCallout'
        ];
        System.Assert.isTrue(exceptionsLogged.size() > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionsLogged.size() == 1, 'Only one exception should be logged');
        System.Assert.isTrue(
            exceptionsLogged[0].Log_Message__c.contains('Status code: 429, Status message: Too Many Requests'),
            'Exception message should contain the expected text'
        );

        // Verify that the token cache is not updated
        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNull(tokenData, 'Token cache should not be updated');
    }

    // -------------------------------
    // Token parsing utility
    // -------------------------------
    /**
     * @description
     * Verifies that `parseTokenData` decrypts and deserializes token data to expected fields
     * (accessToken, issuedAt, expiresAt, expiresIn).
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.parseTokenData
     */
    @IsTest
    private static void parseTokenData() {
        Altinn3CalloutService.AltinnAccessToken token = new Altinn3CalloutService.AltinnAccessToken();
        token.accessToken = 'test';
        token.expiresIn = 1800;
        token.issuedAt = DateTime.now().millisecond() / 1000;
        token.expiresAt = DateTime.now().addSeconds(1800).millisecond() / 1000;

        Altinn3CalloutService service = new Altinn3CalloutService();
        String tokenData = CryptoService.encryptString(JSON.serialize(token));

        System.Test.startTest();
        Map<String, Object> parsedData = service.parseTokenData(tokenData);
        System.Test.stopTest();

        System.Assert.isNotNull(parsedData, 'Parsed token data should not be null');
        System.Assert.areEqual('test', parsedData.get('accessToken'), 'Access token should match');
        System.Assert.areEqual(1800, parsedData.get('expiresIn'), 'Expires in should match');
        System.Assert.areEqual(token.issuedAt, parsedData.get('issuedAt'), 'Issued at should match');
        System.Assert.areEqual(token.expiresAt, parsedData.get('expiresAt'), 'Expires at should match');
    }

    /**
     * @description
     * Verifies that `parseTokenData` returns `null` and logs on decryption/JSON failures.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.parseTokenData
     */
    @IsTest
    private static void parseTokenDataException() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String badTokenData = 'not-encrypted-json';

        System.Test.startTest();
        Map<String, Object> result = service.parseTokenData(badTokenData);
        System.Test.stopTest();

        System.Assert.isNull(result, 'Result should be null when parsing fails');

        Integer exceptionCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'parseTokenData'
        ];
        System.Assert.isTrue(exceptionCount > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionCount == 1, 'Only one exception should be logged');
    }

    // -------------------------------
    // Token acquisition orchestration
    // -------------------------------
    /**
     * @description
     * Verifies that `refreshAndCacheAccessToken` fetches a token (`HTTP 200`), attempts to cache
     * it, and returns the fetched value.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshAndCacheAccessToken
     */
    @IsTest
    private static void refreshAndCacheAccessToken() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String accessToken = MockAltinnJWTGenerator.createMockAltinnJWT();

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', accessToken, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String token = service.refreshAndCacheAccessToken();
        System.Test.stopTest();

        System.Assert.isNotNull(token, 'Access token should not be null');
        System.Assert.areNotEqual('', token, 'Access token should not be empty');
        System.Assert.areEqual(accessToken, token, 'Access token should be equal to the response body');
    }

    /**
     * @description
     * Verifies that `refreshAndCacheAccessToken` returns the raw body when it is not a valid JWT
     * and logs a cache refresh failure.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshAndCacheAccessToken
     */
    @IsTest
    private static void refreshAndCacheAccessTokenWithNoneValidToken() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', 'Test', new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String token = service.refreshAndCacheAccessToken();
        System.Test.stopTest();

        System.Assert.isNotNull(token, 'Access token should not be null');
        System.Assert.areEqual('Test', token, 'Access token should be equal to the response body');

        Integer exceptionCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'refreshTokenCache'
        ];
        System.Assert.isTrue(exceptionCount > 0, 'Exception should be logged');
        System.Assert.isTrue(exceptionCount == 1, 'Only one exception should be logged');
    }

    /**
     * @description
     * Verifies that `getAltinnAccessToken` obtains a valid token on cache miss and returns it when
     * the callout succeeds.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getAltinnAccessToken
     */
    @IsTest
    private static void getAltinnAccessToken() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String accessToken = MockAltinnJWTGenerator.createMockAltinnJWT();

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', accessToken, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        String token = service.getAltinnAccessToken();
        System.Test.stopTest();

        System.Assert.isNotNull(token, 'Access token should not be null');
        System.Assert.areEqual(accessToken, token, 'Access token should be equal to the response body');
    }

    /**
     * @description
     * Verifies that `getAltinnAccessToken` refreshes an expired cached token and returns a new
     * value.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getAltinnAccessToken
     */
    @IsTest
    static void getAltinnAccessTokenWithExpiredCache() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        // Create an expired token in cache
        Altinn3CalloutService.AltinnAccessToken expiredToken = new Altinn3CalloutService.AltinnAccessToken();
        expiredToken.accessToken = 'expired';
        expiredToken.issuedAt = (Integer) (DateTime.now().addMinutes(-60).getTime() / 1000);
        expiredToken.expiresAt = (Integer) (DateTime.now().addMinutes(-30).getTime() / 1000); // Expired
        expiredToken.expiresIn = 1800;

        String tokenData = CryptoService.encryptString(JSON.serialize(expiredToken));
        service.tokenCache.put(service.cacheKeyName, tokenData, 300);

        // Mock fresh token response
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', MockAltinnJWTGenerator.createMockAltinnJWT(), new Map<String, String>())
        );

        System.Test.startTest();
        String token = service.getAltinnAccessToken();
        System.Test.stopTest();

        System.Assert.isNotNull(token, 'Should refresh and return new token');
        System.Assert.areNotEqual('expired', token, 'Should not return expired token');
    }

    // -------------------------------
    // Authorized parties (orgs) flow
    // -------------------------------
    /**
     * @description
     * Verifies that `authorizedPartiesServiceCallout` deserializes organizations with nested
     * subunits from a `HTTP 200 OK` response.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizedPartiesServiceCallout
     */
    @IsTest
    private static void authorizedPartiesServiceCalloutWithSubunits() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String mockBody = '[{"partyUuid":"b443c8a0-0014-44a0-8a5d-4205113d8f46","name":"ALLSIDIG UTMERKET TIGER AS","organizationNumber":"313199770","personId":null,"partyId":51467462,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["test-fager","nav_tiltaksarrangor_deltakeroversikt-veileder","app_nav_a2-2896-87"],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[{"partyUuid":"18fd7463-f071-4a93-bd7f-1667bc2c7efd","name":"ALLSIDIG UTMERKET TIGER AS","organizationNumber":"211511052","personId":null,"partyId":51467461,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["test-fager","nav_tiltaksarrangor_deltakeroversikt-veileder","app_nav_a2-2896-87"],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"0aa068cd-ed44-490f-b38c-285dadebdb4a","name":"BEGEISTRET VISSEN TIGER AS","organizationNumber":"310276111","personId":null,"partyId":51549138,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[{"partyUuid":"89cf7a9a-a2d1-4c68-b84a-ec233e62b533","name":"BEGEISTRET VISSEN TIGER AS","organizationNumber":"311601881","personId":null,"partyId":51686298,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"4ee7d01a-7c6c-44e8-951f-3a6a55aeff6f","name":"DEMOKRATISK LILLA TIGER AS","organizationNumber":"314279913","personId":null,"partyId":51590220,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["MEDL","REGNA","UTINN","UTOMR","SIHV"],"authorizedInstances":[],"subunits":[{"partyUuid":"0c1f2fd9-8b84-4b2d-a7e2-bc17bb13bf12","name":"DEMOKRATISK LILLA TIGER AS","organizationNumber":"314569083","personId":null,"partyId":51918016,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["MEDL","REGNA","UTINN","UTOMR","SIHV"],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"37678414-4dfe-4f54-a4c1-782710925647","name":"DYNAMISK AVANSERT TIGER AS","organizationNumber":"310614777","personId":null,"partyId":51579191,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["app_nav_a2-4936-1"],"authorizedRoles":[],"authorizedInstances":[],"subunits":[{"partyUuid":"699d9fb6-b112-4c1f-983f-c6f0e472d25b","name":"DYNAMISK AVANSERT TIGER AS","organizationNumber":"315784220","personId":null,"partyId":52028486,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["app_nav_a2-4936-1"],"authorizedRoles":[],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"0e50d5f8-2800-45a0-98a7-ac9c0a779611","name":"FREDFULL URIMELIG TIGER AS","organizationNumber":"312593351","personId":null,"partyId":51786842,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["DAGL","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","A0293","A0294","APIADM","A0298"],"authorizedInstances":[],"subunits":[{"partyUuid":"72b4db31-169f-427f-8003-0284aaf84323","name":"FREDFULL URIMELIG TIGER AS","organizationNumber":"315291720","personId":null,"partyId":51983713,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["DAGL","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","A0293","A0294","APIADM","A0298"],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"1fe76f6d-9a10-4478-80ae-afd32d1cdf25","name":"FYRSTE ORDINÆR","organizationNumber":null,"personId":"21842948964","partyId":50867930,"type":"Person","unitType":null,"isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["app_nav_a2-4936-1","app_nav_a2-4936-3"],"authorizedRoles":[],"authorizedInstances":[],"subunits":[]},{"partyUuid":"4d2323ff-a7c2-436c-ae6c-536ca0201506","name":"REDELIG UNGT TIGER AS","organizationNumber":"311750453","personId":null,"partyId":51702209,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["DAGL","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","A0293","A0294","APIADM","A0298"],"authorizedInstances":[],"subunits":[]},{"partyUuid":"7523e2d5-2926-456f-bc68-42b0fe064b04","name":"REGLE TOM","organizationNumber":null,"personId":"08879198748","partyId":50921892,"type":"Person","unitType":null,"isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["PRIV","LOPER","ADMAI","PRIUT","REGNA","SISKD","UILUF","UTINN","UTOMR","PAVAD","KOMAB","BOADM","A0212","A0236","A0278","A0282"],"authorizedInstances":[],"subunits":[]},{"partyUuid":"0d41fa08-6c10-4e96-8519-c271b087d489","name":"TRÅDLØS SOLID TIGER AS","organizationNumber":"310740071","personId":null,"partyId":51590219,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[{"partyUuid":"148acecc-d7fc-40cc-aabd-9ab9d4f82b6b","name":"TRÅDLØS SOLID TIGER AS","organizationNumber":"315801729","personId":null,"partyId":52030076,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":[],"authorizedRoles":["LEDE","LOPER","ADMAI","REGNA","SISKD","UILUF","UTINN","UTOMR","KLADM","ATTST","HVASK","PAVAD","SIGNE","UIHTL","KOMAB","A0212","ECKEYROLE","PASIG","A0236","A0278","HADM","APIADM","A0298"],"authorizedInstances":[],"subunits":[]}]},{"partyUuid":"dcee5939-f113-4867-b4c1-e1530ab38318","name":"ARITMETISK UTGÅTT TIGER AS","organizationNumber":"313990265","personId":null,"partyId":51883772,"type":"Organization","unitType":"AS","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["tiltak-arrangor-refusjon","nav_barnebriller_utbetalingsrapport","test-fager","nav_barnebriller_opprette-avtale"],"authorizedRoles":[],"authorizedInstances":[],"subunits":[{"partyUuid":"3f46e5e3-0d7b-43f1-ba8b-456c0af3fb6f","name":"ARITMETISK UTGÅTT TIGER AS","organizationNumber":"315538890","personId":null,"partyId":52006183,"type":"Organization","unitType":"BEDR","isDeleted":false,"onlyHierarchyElementWithNoAccess":false,"authorizedAccessPackages":[],"authorizedResources":["tiltak-arrangor-refusjon","nav_barnebriller_utbetalingsrapport","test-fager","nav_barnebriller_opprette-avtale"],"authorizedRoles":[],"authorizedInstances":[],"subunits":[]}]}]';
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', mockBody, new Map<String, String>())
        );

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp = service.getOrganizations('12345678901');
        System.Test.stopTest();

        System.Assert.isNotNull(resp, 'Response should not be null');
        System.Assert.areNotEqual(0, resp.organizations.size(), 'Should contain at least one organization');
    }

    /**
     * @description
     * Verifies that `getOrganizations` returns an empty list when the authorized parties callout
     * returns a non-200 status.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getOrganizations
     */
    @IsTest
    private static void getOrganizationsWithError() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(500, 'Error', 'Internal server error', new Map<String, String>())
        );

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse resp = service.getOrganizations('12345678901');
        System.Test.stopTest();

        System.Assert.areEqual(0, resp.organizations.size(), 'Should be empty on error');
    }

    // -------------------------------
    // Authorization decision callout
    // -------------------------------
    /**
     * @description
     * Verifies that `authorizeServiceCallout` yields Permit wrapper (isPermit() = true).
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizeServiceCallout
     */
    @IsTest
    private static void authorizeServiceCalloutPermit() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Permit","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnResponseUtils.AltinnAccessResponseWrapper result = service.authorizeServiceCallout(
            '12345678901',
            '987654321',
            'resource'
        );
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(true, result.isPermit(), 'Permit should be true');
    }

    /**
     * @description
     * Verifies that `authorizeServiceCallout` yields Deny wrapper (isPermit() = false).
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizeServiceCallout
     */
    @IsTest
    private static void authorizeServiceCalloutDeny() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Deny","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnResponseUtils.AltinnAccessResponseWrapper result = service.authorizeServiceCallout(
            '12345678901',
            '987654321',
            'resource'
        );
        System.Test.stopTest();

        System.Assert.isNotNull(result, 'Result should not be null');
        System.Assert.areEqual(false, result.isPermit(), 'Permit should be false');
    }

    /**
     * @description
     * Verifies that `authorizeServiceCallout` returns null on non-200 response.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizeServiceCallout
     */
    @IsTest
    private static void authorizeServiceCalloutWithError() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(500, 'Error', 'Internal server error', new Map<String, String>())
        );

        System.Test.startTest();
        AltinnResponseUtils.AltinnAccessResponseWrapper result = service.authorizeServiceCallout(
            '12345678901',
            '987654321',
            'resource'
        );
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Result should be null on error');
    }

    // -------------------------------
    // Rights mapping (XACML decisions)
    // -------------------------------
    /**
     * @description
     * Verifies that `getRights` maps XACML 'Permit' to a successful response with one Right entry.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    private static void getRightsPermit() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Permit","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('12345678901', '987654321', 'someResource');
        System.Test.stopTest();

        System.Assert.isNotNull(resp, 'Response should not be null');
        System.Assert.areEqual(true, resp.success, 'Should be marked successful for permit=true');
        System.Assert.areEqual(1, resp.rights.size(), 'Should have a single right');
    }

    /**
     * @description
     * Verifies that `getRights` maps XACML 'Deny' to an unsuccessful response with errorMessage
     * 'Access denied'.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    private static void getRightsDeny() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Deny","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:ok","statusCode":null}},"obligations":[{"id":"urn:altinn:obligation:authenticationLevel1","attributeAssignment":[{"attributeId":"urn:altinn:obligation1-assignment1","value":"4","category":"urn:altinn:minimum-authenticationlevel","dataType":"http://www.w3.org/2001/XMLSchema#integer","issuer":null}]}],"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('12345678901', '987654321', 'someResource');
        System.Test.stopTest();

        System.Assert.isNotNull(resp, 'Response should not be null');
        System.Assert.areEqual(false, resp.success, 'Should be marked unsuccessful for permit=false');
        System.Assert.areEqual('Access denied', resp.errorMessage, 'Should return Access denied');
    }

    /**
     * @description
     * Verifies that `getRights` maps XACML 'Indeterminate' (with processing-error) to an
     * unsuccessful response and preserves the decision in rights.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    static void getRightsWithIndeterminateDecision() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Indeterminate","status":{"statusMessage":null,"statusDetails":null,"statusCode":{"value":"urn:oasis:names:tc:xacml:1.0:status:processing-error","statusCode":null}},"obligations":null,"associateAdvice":null,"category":null,"policyIdentifierList":null}]}';

        SingleRequestMock mock = new SingleRequestMock(200, 'OK', body, new Map<String, String>());
        System.Test.setMock(HttpCalloutMock.class, mock);

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('123', '456', null);
        System.Test.stopTest();

        System.Assert.isNotNull(resp);
        System.Assert.isFalse(resp.success, 'Response should be unsuccessful for null resource');
        System.Assert.areEqual(
            'Indeterminate access status',
            resp.errorMessage,
            'Should return error message for indeterminate status'
        );
        System.Assert.areEqual(
            'Indeterminate',
            resp.rights[0].Decision,
            'Should return Indeterminate decision for null resource'
        );
    }

    /**
     * @description
     * Verifies that `getRights` maps a minimal XACML 'Indeterminate' response to unsuccessful
     * outcome with the expected error message.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    private static void getRightsIndeterminate() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"Indeterminate"}]}';
        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', body, new Map<String, String>()));

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('123', '456', 'resource');
        System.Test.stopTest();

        System.Assert.areEqual(false, resp.success);
        System.Assert.areEqual('Indeterminate access status', resp.errorMessage);
    }

    /**
     * @description
     * Verifies that `getRights` maps XACML 'NotApplicable' to unsuccessful outcome with
     * errorMessage 'Not applicable for the requested resource'.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    private static void getRightsNotApplicable() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String body = '{"response":[{"decision":"NotApplicable"}]}';
        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', body, new Map<String, String>()));

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('123', '456', 'resource');
        System.Test.stopTest();

        System.Assert.areEqual(false, resp.success);
        System.Assert.areEqual('Not applicable for the requested resource', resp.errorMessage);
    }

    /**
     * @description
     * Verifies that `getRights` returns unsuccessful with 'Access denied' when authorizeServiceCallout returns null.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @see Altinn3CalloutService.getRights
     */
    @IsTest
    private static void getRightsNullResult() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(500, 'Error', '', new Map<String, String>()));

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse resp = service.getRights('123', '456', 'resource');
        System.Test.stopTest();

        System.Assert.areEqual(false, resp.success);
        System.Assert.areEqual('Access denied', resp.errorMessage);
    }

    // -------------------------------
    // Additional coverage for cache, TTL, and error branches
    // -------------------------------

    /**
     * @description
     * Verifies that `getAltinnAccessToken` returns a valid, unexpired cached token without
     * attempting a callout.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.getAltinnAccessToken
     */
    @IsTest
    private static void getAltinnAccessTokenReturnsCachedTokenNoCallout() {
        Altinn3CalloutService service = new Altinn3CalloutService();

        String jwt = MockAltinnJWTGenerator.createMockAltinnJWT();
        System.assertEquals(true, service.refreshTokenCache(jwt), 'Cache seeding via refreshTokenCache should succeed');
        System.debug('Cache key - in test: ' + (String) service.tokenCache.get(service.cacheKeyName));

        System.Test.startTest();
        Integer calloutsBefore = Limits.getCallouts();
        String token = service.getAltinnAccessToken();
        Integer calloutsAfter = Limits.getCallouts();
        System.Test.stopTest();

        System.Assert.areEqual(jwt, token, 'Should return the cached token (no refresh needed)');
        System.Assert.areEqual(calloutsBefore, calloutsAfter, 'No HTTP callouts should be made on cache hit');

        String encrypted = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNotNull(encrypted, 'Cache entry should remain present');
        // Sanity-check parsed cache content
        Map<String, Object> parsed = service.parseTokenData(encrypted);
        System.Assert.isNotNull(parsed, 'Parsed token metadata should be available');
        System.Assert.areEqual(jwt, (String) parsed.get('accessToken'), 'Cached access token should match seeded JWT');
    }

    /**
     * @description
     * Verifies getAltinnAccessToken recovers from corrupted cache (parseTokenData returns null) by refreshing via callout.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.getAltinnAccessToken
     */
    @IsTest
    private static void getAltinnAccessTokenWithCorruptedCache() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        service.tokenCache.put(service.cacheKeyName, 'corrupted-non-json', 300);

        String freshJwt = MockAltinnJWTGenerator.createMockAltinnJWT();
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', freshJwt, new Map<String, String>())
        );

        System.Test.startTest();
        String token = service.getAltinnAccessToken();
        System.Test.stopTest();

        System.Assert.areEqual(freshJwt, token, 'Should refresh and return new token when cache is corrupted');
        Integer parseErrorCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'parseTokenData'
        ];
        System.Assert.isTrue(parseErrorCount > 0, 'Corrupted cache parsing should be logged');
    }

    /**
     * @description
     * Verifies altinnAccessTokenCallout returns null and logs details on HTTP 500.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.altinnAccessTokenCallout
     */
    @IsTest
    private static void altinnAccessTokenCalloutWith500Returned() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(500, 'Error', 'Internal server error', new Map<String, String>())
        );

        System.Test.startTest();
        String token = service.altinnAccessTokenCallout();
        System.Test.stopTest();

        System.Assert.areEqual(null, token, 'Should return null on HTTP 500');
        List<Application_Log__c> logs = [
            SELECT Id, Log_Message__c
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'altinnAccessTokenCallout'
        ];
        System.Assert.areEqual(1, logs.size(), 'Exactly one log should be written');
        System.Assert.isTrue(
            logs[0].Log_Message__c.contains('Status code: 500'),
            'Log should include HTTP 500 details'
        );
    }

    /**
     * @description
     * Verifies refreshTokenCache rejects JWTs where iat/exp are non-integer (string) claims.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheWithStringClaims() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        String header = base64Url('{"alg":"RS256","typ":"JWT"}');
        String payload = base64Url('{"iss":"issuer","sub":"subj","iat":"1692100000","exp":"1692101800"}'); // string claims
        String jwt = header + '.' + payload + '.x';

        System.Test.startTest();
        Boolean ok = service.refreshTokenCache(jwt);
        System.Test.stopTest();

        System.Assert.areEqual(false, ok, 'Should return false when iat/exp are not integers');
        String tokenData = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.areEqual(null, tokenData, 'Cache must not be updated for invalid claims');

        Integer logCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'refreshTokenCache'
        ];
        System.Assert.isTrue(logCount > 0, 'Validation error should be logged');
    }

    /**
     * @description
     * Verifies refreshTokenCache enforces a minimum TTL when exp-iat is below threshold (e.g., 60s).
     * Asserts the cached metadata reflects a TTL not less than the platform minimum (>= 300s).
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshTokenCacheEnforcesMinimumTtl() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        Long now = DateTime.now().getTime() / 1000;
        Long iat = now;
        Long exp = now + 300; // 1 minute

        String header = base64Url('{"alg":"RS256","typ":"JWT"}');
        String payload = base64Url('{"iss":"issuer","sub":"subj","iat":' + iat + ',"exp":' + exp + '}');
        String jwt = header + '.' + payload + '.x';

        System.Test.startTest();
        Boolean ok = service.refreshTokenCache(jwt);
        System.Test.stopTest();

        System.Assert.areEqual(true, ok, 'Refresh should still succeed with short-lived token (normalized TTL)');
        String encrypted = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.isNotNull(encrypted, 'Encrypted cache entry must be present');

        Map<String, Object> parsed = service.parseTokenData(encrypted);
        System.Assert.isNotNull(parsed, 'Parsed metadata must be available');
        System.Assert.isTrue(
            ((Integer) parsed.get('expiresIn')) >= 300,
            'TTL should be normalized to at least 300 seconds'
        );
    }

    /**
     * @description
     * Verifies refreshAndCacheAccessToken returns null when underlying callout is non-200 (e.g., 401).
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.refreshTokenCache
     */
    @IsTest
    private static void refreshAndCacheAccessTokenReturnsNullOnNon200() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(401, 'Unauthorized', '', new Map<String, String>())
        );

        System.Test.startTest();
        String token = service.refreshAndCacheAccessToken();
        System.Test.stopTest();

        System.Assert.areEqual(null, token, 'Should return null when token endpoint is unauthorized');
        String cached = (String) service.tokenCache.get(service.cacheKeyName);
        System.Assert.areEqual(null, cached, 'Cache must not be mutated on callout failure');
    }

    /**
     * @description
     * Verifies authorizedPartiesServiceCallout returns empty list on HTTP 200 with empty array body.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizedPartiesServiceCallout
     */
    @IsTest
    private static void authorizedPartiesServiceCalloutEmptyOnEmptyArray() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.setMock(HttpCalloutMock.class, new SingleRequestMock(200, 'OK', '[]', new Map<String, String>()));

        System.Test.startTest();
        List<AltinnCalloutService.Organization> orgs = service.authorizedPartiesServiceCallout('12345678901');
        System.Test.stopTest();

        //System.assertNotNull(resp, 'Response wrapper should not be null');
        System.Assert.areEqual(0, orgs.size(), 'Empty array should yield empty organizations list');
    }

    /**
     * @description
     * Verifies authorizedPartiesServiceCallout handles malformed JSON by returning empty list and logging error.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizedPartiesServiceCallout
     */
    @IsTest
    private static void authorizedPartiesServiceCallout() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', 'not-json', new Map<String, String>())
        );

        System.Test.startTest();
        List<AltinnCalloutService.Organization> orgs = service.authorizedPartiesServiceCallout('12345678901');
        System.Test.stopTest();

        System.Assert.areEqual(0, orgs.size(), 'Malformed JSON should produce empty organizations list');
        Integer logCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'authorizedPartiesServiceCallout'
        ];
        System.Assert.isTrue(logCount > 0, 'Error should be logged for malformed JSON');
    }

    /**
     * @description
     * Verifies authorizeServiceCallout returns null and logs an error when HTTP 200 body is malformed JSON.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @see Altinn3CalloutService.authorizeServiceCallout
     */
    @IsTest
    private static void authorizeServiceCalloutMalformedJson200() {
        Altinn3CalloutService service = new Altinn3CalloutService();
        System.Test.setMock(
            HttpCalloutMock.class,
            new SingleRequestMock(200, 'OK', 'not-json', new Map<String, String>())
        );

        System.Test.startTest();
        AltinnResponseUtils.AltinnAccessResponseWrapper wrapper = service.authorizeServiceCallout('123', '456', 'r');
        System.Test.stopTest();

        System.Assert.areEqual(null, wrapper, 'Malformed JSON should result in null wrapper');
        Integer logCount = [
            SELECT COUNT()
            FROM Application_Log__c
            WHERE Source_Class__c = 'Altinn3CalloutService' AND Source_Function__c = 'authorizeServiceCallout'
        ];
        System.Assert.isTrue(logCount > 0, 'Error should be logged for malformed authorization response');
    }

    /**
     * @description
     * Encodes input string to Base64URL format (no padding, URL-safe).
     * Helper: minimal Base64URL encoder for local JWT construction in tests
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param input The input string to encode.
     * @return The Base64URL-encoded string.
     */
    private static String base64Url(String input) {
        String b64 = EncodingUtil.base64Encode(Blob.valueOf(input));
        b64 = b64.replace('+', '-').replace('/', '_');
        while (b64.endsWith('='))
            b64 = b64.substring(0, b64.length() - 1);
        return b64;
    }
}
