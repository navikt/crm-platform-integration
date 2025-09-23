/**
 * @description Altinn Callout Service implementation.
 *
 * @author Kenneth Sørensen
 * @since April 2025 - Initial Release.
 *
 * Group: Altinn Callout Service
 */
public with sharing class AltinnCalloutService {
    @TestVisible
    private IAltinnCalloutService altinnCalloutService;

    public AltinnCalloutService() {
        if (new FeatureToggleBase().isFeatureEnabled('altinn-version3', FeatureToggle.ToggleType.FEATURE_FLAG)) {
            altinnCalloutService = new Altinn3CalloutService();
        } else {
            altinnCalloutService = new Altinn2CalloutService();
        }
    }

    public AltinnOrganizationsResponse getOrganizations(String personIdent) {
        return (AltinnOrganizationsResponse) altinnCalloutService.getOrganizations(personIdent);
    }

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

        public AltinnOrganizationsResponse() {
            this.success = false;
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
        public List<String> authorizedInstances;
        @AuraEnabled
        public List<Organization> subunits;
    }
}
