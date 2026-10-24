/**
 * Delegates Altinn lookups to the selected or explicitly supplied provider with sharing.
 *
 * @author Frode Hoen
 * @author Kenneth Sørensen
 * @since 2021-04-07
 * @group Altinn Callout Service
 */
public with sharing class AltinnCalloutService {
    /** Exposes the selected provider for existing tests without adding a public setter. */
    @TestVisible
    private IAltinnCalloutService altinnCalloutService;

    /**
     * Selects Altinn 3 when its feature flag is enabled, otherwise Altinn 2.
     *
     * @throws Altinn3CalloutService.Altinn3CalloutServiceException If Altinn 3 configuration is missing or invalid.
     * @since 2025-09-11
     */
    public AltinnCalloutService() {
        if (new FeatureToggleBase().isFeatureEnabled('Altinn_Version_3', FeatureToggle.ToggleType.FEATURE_FLAG)) {
            altinnCalloutService = new Altinn3CalloutService();
        } else {
            altinnCalloutService = new Altinn2CalloutService();
        }
    }

    /**
     * Creates the facade with the supplied provider, without initializing the default provider.
     *
     * @param provider The implementation used for organization and rights lookups.
     * @throws AltinnCalloutServiceException If provider is null.
     * @example {@code AltinnCalloutService service = new AltinnCalloutService(provider);}
     * @since 2026-10-24
     */
    public AltinnCalloutService(IAltinnCalloutService provider) {
        if (provider == null) {
            throw new AltinnCalloutServiceException('Altinn provider must not be null.');
        }
        altinnCalloutService = provider;
    }

    /**
     * Signals that the Altinn callout facade was constructed with an invalid provider.
     *
     * @author Kenneth Sørensen
     * @since 2026-10-24
     * @group Altinn Callout Service
     */
    public class AltinnCalloutServiceException extends Exception {
    }

    /**
     * Returns the provider's organization response without normalization or exception wrapping.
     *
     * @param personIdent The person identifier forwarded unchanged to the provider.
     * @return The same organization response, including null when returned by the provider.
     * @throws TypeException If the provider returns an incompatible response type.
     */
    public AltinnOrganizationsResponse getOrganizations(String personIdent) {
        return (AltinnOrganizationsResponse) altinnCalloutService.getOrganizations(personIdent);
    }

    /**
     * Returns the provider's rights response without normalization or exception wrapping.
     *
     * @param personIdent The person identifier forwarded unchanged.
     * @param organizationNumber The organization number forwarded unchanged.
     * @param serviceCode The service code or resource forwarded unchanged.
     * @return The same rights response, including null when returned by the provider.
     * @throws TypeException If the provider returns an incompatible response type.
     */
    public AltinnRightsResponse getRights(String personIdent, String organizationNumber, String serviceCode) {
        return (AltinnRightsResponse) altinnCalloutService.getRights(personIdent, organizationNumber, serviceCode);
    }

    public class AltinnOrganizationsResponse {
        @AuraEnabled
        public Boolean success;
        @AuraEnabled
        public List<Organization> organizations;
        @AuraEnabled
        public String errorMessage;
        @AuraEnabled
        public String altinnVersion;

        public AltinnOrganizationsResponse() {
            this.success = false;
            this.altinnVersion = 'v2';
            this.organizations = null;
            this.errorMessage = null;
        }
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

    public class Right {
        @AuraEnabled
        public String ServiceCode;
        @AuraEnabled
        public String Action;
        @AuraEnabled
        public String Decision;
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
        @AuraEnabled
        public String Resource;
    }

    public class Organization {
        public String partyUuid;
        @AuraEnabled
        public String name;
        @AuraEnabled
        public String organizationNumber;
        public String personId;
        public String partyId;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String unitType;
        @AuraEnabled
        public String isDeleted;
        public String onlyHierarchyElementWithNoAccess;
        @AuraEnabled
        public List<String> authorizedResources;
        @AuraEnabled
        public List<String> authorizedRoles;
        //public List<String> authorizedInstances; // Not included in the current implementation as it is not used in the current scope of work, but can be added in the future if needed. TODO: Evaluate the need for this field in future iterations.
        @AuraEnabled
        public List<Organization> subunits;
    }
}
