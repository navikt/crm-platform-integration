/**
 * Verifies the public Altinn callout facade contract.
 *
 * @author Frode Hoen
 * @author John Føreland
 * @author Kenneth Sørensen
 * @author piszosta
 * @since 2021-04-12
 * @group Altinn Callout Service
 */
@IsTest
private with sharing class AltinnCalloutServiceTest {
    /**
     * Creates the encryption key required by the existing Altinn callout tests.
     *
     * @since 2023-11-02
     */
    @TestSetup
    static void makeData() {
        BaseTestFactory.insertEncryptionKey();
    }

    /**
     * Verifies an injected provider handles both lookups and its responses are returned unchanged.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenLookupsAreRequested_DelegatesAndReturnsResponses() {
        User minimumAccessUser = createMinimumAccessUser();
        RecordingProvider provider = new RecordingProvider();
        provider.organizationsResponse = new AltinnCalloutService.AltinnOrganizationsResponse();
        provider.organizationsResponse.success = true;
        provider.organizationsResponse.organizations = new List<AltinnCalloutService.Organization>();
        provider.rightsResponse = new AltinnCalloutService.AltinnRightsResponse();
        provider.rightsResponse.success = false;
        provider.rightsResponse.errorMessage = 'Synthetic provider result';
        System.Assert.areEqual(0, [SELECT COUNT() FROM Altinn3IntegrationSetting__c]);

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            AltinnCalloutService service = new AltinnCalloutService(provider);
            AltinnCalloutService.AltinnOrganizationsResponse organizations = service.getOrganizations(
                'synthetic-person'
            );
            AltinnCalloutService.AltinnRightsResponse rights = service.getRights(
                'synthetic-person',
                'synthetic-organization',
                'synthetic-resource'
            );
            System.Assert.areEqual(0, Limits.getQueries());
            System.Assert.areEqual(0, Limits.getDmlStatements());
            System.Assert.areEqual(0, Limits.getCallouts());
            System.Test.stopTest();

            System.Assert.areEqual('Synthetic provider result', rights.errorMessage);
            provider.organizationsResponse.errorMessage = 'Response changed after delegation';
            provider.rightsResponse.errorMessage = 'Response changed after delegation';
            System.Assert.areEqual('Response changed after delegation', organizations.errorMessage);
            System.Assert.areEqual('Response changed after delegation', rights.errorMessage);
            System.Assert.areEqual(true, organizations.success);
            System.Assert.areEqual(0, organizations.organizations.size());
            System.Assert.areEqual(false, rights.success);
            System.Assert.areEqual(1, provider.organizationCallCount);
            System.Assert.areEqual('synthetic-person', provider.organizationPersonIdent);
            System.Assert.areEqual(1, provider.rightsCallCount);
            System.Assert.areEqual('synthetic-person', provider.rightsPersonIdent);
            System.Assert.areEqual('synthetic-organization', provider.rightsOrganizationNumber);
            System.Assert.areEqual('synthetic-resource', provider.rightsServiceCode);
        }
    }

    /**
     * Verifies both lookups preserve structured failures and empty lists.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenResponsesContainFailures_PreservesEveryField() {
        RecordingProvider provider = new RecordingProvider();
        provider.organizationsResponse = new AltinnCalloutService.AltinnOrganizationsResponse();
        provider.organizationsResponse.organizations = new List<AltinnCalloutService.Organization>();
        provider.organizationsResponse.errorMessage = 'Synthetic organization failure';
        provider.organizationsResponse.altinnVersion = 'synthetic-version';
        provider.rightsResponse = new AltinnCalloutService.AltinnRightsResponse();
        provider.rightsResponse.rights = new List<AltinnCalloutService.Right>();
        provider.rightsResponse.errorMessage = 'Synthetic rights failure';
        AltinnCalloutService service = new AltinnCalloutService(provider);

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse organizations = service.getOrganizations(null);
        AltinnCalloutService.AltinnRightsResponse rights = service.getRights(null, '', null);
        System.Test.stopTest();

        System.Assert.areEqual(false, organizations.success);
        System.Assert.areEqual(0, organizations.organizations.size());
        System.Assert.areEqual('Synthetic organization failure', organizations.errorMessage);
        System.Assert.areEqual('synthetic-version', organizations.altinnVersion);
        System.Assert.areEqual(false, rights.success);
        System.Assert.areEqual(0, rights.rights.size());
        System.Assert.areEqual('Synthetic rights failure', rights.errorMessage);
        System.Assert.isNull(provider.organizationPersonIdent);
        System.Assert.isNull(provider.rightsPersonIdent);
        System.Assert.areEqual('', provider.rightsOrganizationNumber);
        System.Assert.isNull(provider.rightsServiceCode);
    }

    /**
     * Verifies null provider results are passed through without response normalization.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenLookupsReturnNull_PassesNullThrough() {
        RecordingProvider provider = new RecordingProvider();
        AltinnCalloutService service = new AltinnCalloutService(provider);

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse organizations = service.getOrganizations('synthetic-person');
        AltinnCalloutService.AltinnRightsResponse rights = service.getRights(
            'synthetic-person',
            'synthetic-organization',
            'synthetic-resource'
        );
        System.Test.stopTest();

        System.Assert.isNull(organizations);
        System.Assert.isNull(rights);
    }

    /**
     * Verifies provider exceptions from both lookups are propagated unchanged.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenLookupsThrow_PropagatesProviderExceptions() {
        RecordingProvider provider = new RecordingProvider();
        provider.throwOnOrganizationLookup = true;
        provider.throwOnRightsLookup = true;
        AltinnCalloutService service = new AltinnCalloutService(provider);
        ProviderException organizationException;
        ProviderException rightsException;

        System.Test.startTest();
        try {
            service.getOrganizations('synthetic-person');
        } catch (ProviderException caughtException) {
            organizationException = caughtException;
        }
        try {
            service.getRights('synthetic-person', 'synthetic-organization', 'synthetic-resource');
        } catch (ProviderException caughtException) {
            rightsException = caughtException;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(organizationException);
        System.Assert.areEqual('Synthetic provider failure', organizationException.getMessage());
        System.Assert.isNotNull(rightsException);
        System.Assert.areEqual('Synthetic provider failure', rightsException.getMessage());
        System.Assert.areEqual(1, provider.organizationCallCount);
        System.Assert.areEqual(1, provider.rightsCallCount);
    }

    /**
     * Verifies separate facade instances keep their injected providers isolated.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenInstancesHaveDifferentProviders_KeepsThemIsolated() {
        RecordingProvider firstProvider = new RecordingProvider();
        RecordingProvider secondProvider = new RecordingProvider();
        AltinnCalloutService firstService = new AltinnCalloutService(firstProvider);
        AltinnCalloutService secondService = new AltinnCalloutService(secondProvider);

        System.Test.startTest();
        firstService.getOrganizations('first-person');
        secondService.getRights('second-person', 'second-organization', 'second-resource');
        System.Test.stopTest();

        System.Assert.areEqual(1, firstProvider.organizationCallCount);
        System.Assert.areEqual('first-person', firstProvider.organizationPersonIdent);
        System.Assert.areEqual(0, firstProvider.rightsCallCount);
        System.Assert.areEqual(0, secondProvider.organizationCallCount);
        System.Assert.areEqual(1, secondProvider.rightsCallCount);
        System.Assert.areEqual('second-person', secondProvider.rightsPersonIdent);
        System.Assert.areEqual('second-organization', secondProvider.rightsOrganizationNumber);
        System.Assert.areEqual('second-resource', secondProvider.rightsServiceCode);
    }

    /**
     * Verifies wrong-typed provider results retain the facade's direct-cast failure.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenLookupsReturnWrongTypes_ThrowsTypeException() {
        RecordingProvider provider = new RecordingProvider();
        provider.returnWrongOrganizationType = true;
        provider.returnWrongRightsType = true;
        AltinnCalloutService service = new AltinnCalloutService(provider);
        TypeException organizationException;
        TypeException rightsException;

        System.Test.startTest();
        try {
            service.getOrganizations('synthetic-person');
        } catch (TypeException caughtException) {
            organizationException = caughtException;
        }
        try {
            service.getRights('synthetic-person', 'synthetic-organization', 'synthetic-resource');
        } catch (TypeException caughtException) {
            rightsException = caughtException;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(organizationException);
        System.Assert.isNotNull(rightsException);
        System.Assert.areEqual(1, provider.organizationCallCount);
        System.Assert.areEqual(1, provider.rightsCallCount);
    }

    /**
     * Verifies the constructor rejects a null provider with its documented exception.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void injectedProvider_WhenNullIsProvided_ThrowsExplicitException() {
        AltinnCalloutService.AltinnCalloutServiceException actualException;
        System.Assert.areEqual(0, [SELECT COUNT() FROM Altinn3IntegrationSetting__c]);

        System.Test.startTest();
        try {
            new AltinnCalloutService(null);
        } catch (AltinnCalloutService.AltinnCalloutServiceException caughtException) {
            actualException = caughtException;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(actualException);
        System.Assert.areEqual('Altinn provider must not be null.', actualException.getMessage());
    }

    /**
     * Verifies the default constructor retains Altinn 3's missing-settings failure.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void defaultProvider_WhenAltinn3IsEnabledWithoutSettings_ThrowsConfigurationException() {
        setAltinn3Enabled(true);
        System.Assert.areEqual(0, [SELECT COUNT() FROM Altinn3IntegrationSetting__c]);
        Altinn3CalloutService.Altinn3CalloutServiceException actualException;

        System.Test.startTest();
        try {
            new AltinnCalloutService();
        } catch (Altinn3CalloutService.Altinn3CalloutServiceException caughtException) {
            actualException = caughtException;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(actualException);
        System.Assert.areEqual('Altinn3IntegrationSetting__c is not configured.', actualException.getMessage());
    }

    /**
     * Verifies the existing Altinn organization lookup returns a successful response.
     *
     * @since 2021-04-12
     */
    @IsTest
    private static void organizations_WhenAltinnReturnsSuccess_ReturnsOrganizations() {
        setAltinn3Enabled(false);
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 200, 'OK');

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse response = new AltinnCalloutService()
            .getOrganizations('synthetic-person');
        System.Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Expect success');
        System.Assert.isNull(response.errorMessage, 'Expect no error message');
        System.Assert.areEqual(18, response.organizations.size(), 'Expect 18 organizations');
    }

    /**
     * Verifies the existing Altinn organization lookup reports a server error.
     *
     * @since 2021-04-12
     */
    @IsTest
    private static void organizations_WhenAltinnReturnsServerError_ReturnsFailure() {
        setAltinn3Enabled(false);
        ApiMock.setTestMock('GET_ALTINN_ORGANIZATIONS', 500, 'Server error');

        System.Test.startTest();
        AltinnCalloutService.AltinnOrganizationsResponse response = new AltinnCalloutService()
            .getOrganizations('synthetic-person');
        System.Test.stopTest();

        System.Assert.areEqual(false, response.success, 'Expect failure');
        System.Assert.isTrue(
            response.errorMessage.contains('Kunne ikke hente organisasjoner fra Altinn.'),
            'Expect the organization error message'
        );
        System.Assert.isNull(response.organizations, 'Expect no organizations');
    }

    /**
     * Verifies the existing Altinn rights lookup applies the requested service code.
     *
     * @since 2021-06-03
     */
    @IsTest
    private static void rights_WhenAltinnReturnsServiceCodeResults_ReturnsRights() {
        setAltinn3Enabled(false);
        ApiMock.setTestMock('GET_ALTINN_RIGHTS', 200, 'OK');

        System.Test.startTest();
        AltinnCalloutService.AltinnRightsResponse response = new AltinnCalloutService()
            .getRights('synthetic-person', 'synthetic-organization', '5719');
        System.Test.stopTest();

        System.Assert.areEqual(true, response.success, 'Expect success');
        System.Assert.isNull(response.errorMessage, 'Expect no error message');
        System.Assert.areEqual(51, response.rights.size(), 'Expect 51 rights');
    }

    private static void setAltinn3Enabled(Boolean enabled) {
        CustomMetadataDAO.customMetadataRecordsMap.put(
            'SELECT MasterLabel, DeveloperName, Is_Enabled__c, Description__c, Required_Custom_Permission__c FROM Feature_Flag__mdt',
            new List<SObject>{ new Feature_Flag__mdt(DeveloperName = 'Altinn_Version_3', Is_Enabled__c = enabled) }
        );
    }

    private static User createMinimumAccessUser() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];
        String uniqueSuffix = String.valueOf(DateTime.now().getTime()) + String.valueOf(Crypto.getRandomInteger());
        String username = 'altinn-provider-' + uniqueSuffix + '@example.invalid';

        User minimumAccessUser = new User(
            Alias = 'altprov',
            Email = username,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Altinn Provider Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minimumAccessProfile.Id,
            TimeZoneSidKey = 'Europe/Oslo',
            Username = username
        );
        insert minimumAccessUser;
        return minimumAccessUser;
    }

    private class RecordingProvider implements IAltinnCalloutService {
        private Integer organizationCallCount = 0;
        private String organizationPersonIdent;
        private AltinnCalloutService.AltinnOrganizationsResponse organizationsResponse;
        private Boolean returnWrongOrganizationType = false;
        private Boolean throwOnOrganizationLookup = false;
        private Boolean throwOnRightsLookup = false;
        private Integer rightsCallCount = 0;
        private String rightsPersonIdent;
        private String rightsOrganizationNumber;
        private String rightsServiceCode;
        private AltinnCalloutService.AltinnRightsResponse rightsResponse;
        private Boolean returnWrongRightsType = false;

        public Object getOrganizations(String personIdent) {
            organizationCallCount++;
            organizationPersonIdent = personIdent;
            if (throwOnOrganizationLookup) {
                throw new ProviderException('Synthetic provider failure');
            }
            if (returnWrongOrganizationType) {
                return 'Synthetic invalid organization response';
            }
            return organizationsResponse;
        }

        public Object getRights(String personIdent, String organizationNumber, String serviceCode) {
            rightsCallCount++;
            rightsPersonIdent = personIdent;
            rightsOrganizationNumber = organizationNumber;
            rightsServiceCode = serviceCode;
            if (throwOnRightsLookup) {
                throw new ProviderException('Synthetic provider failure');
            }
            if (returnWrongRightsType) {
                return 'Synthetic invalid rights response';
            }
            return rightsResponse;
        }
    }

    private class ProviderException extends Exception {
    }
}
