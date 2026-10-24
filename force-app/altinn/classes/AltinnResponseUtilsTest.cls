/**
 * Verifies Altinn authorization decisions, status and authentication obligations.
 *
 * @author Kenneth Sørensen
 * @since 2026-10-24
 * @group Altinn Callout Service
 */
@IsTest
private with sharing class AltinnResponseUtilsTest {
    /**
     * Verifies each decision is exposed without being interpreted as another decision.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void authorization_WhenDecisionIsPresent_ExposesMatchingDecisionAndStatus() {
        System.Test.startTest();
        for (String decision : new List<String>{ 'Permit', 'Deny', 'Indeterminate', 'NotApplicable', 'Unknown' }) {
            AltinnResponseUtils.AltinnAccessResponseWrapper response = AltinnResponseUtils.parse(
                '{"response":[{"decision":"' + decision + '","status":{"statusCode":{"value":"synthetic-status"}}}]}'
            );
            System.Assert.areEqual(decision, response.getDecision());
            System.Assert.areEqual('Permit' == decision, response.isPermit());
            System.Assert.areEqual('Deny' == decision, response.isDeny());
            System.Assert.areEqual('Indeterminate' == decision, response.isIndeterminate());
            System.Assert.areEqual('NotApplicable' == decision, response.isNotApplicable());
            System.Assert.areEqual('synthetic-status', response.getStatusCode());
        }
        System.Test.stopTest();
    }

    /**
     * Verifies absent authorization data does not imply a decision or authentication level.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void authorization_WhenResponseIsMissingOrEmpty_ReturnsNoDecision() {
        System.Test.startTest();
        for (String payload : new List<String>{ '{}', '{"response":[]}' }) {
            AltinnResponseUtils.AltinnAccessResponseWrapper response = AltinnResponseUtils.parse(payload);
            System.Assert.isFalse(response.isPermit());
            System.Assert.isFalse(response.isDeny());
            System.Assert.isFalse(response.isIndeterminate());
            System.Assert.isFalse(response.isNotApplicable());
            System.Assert.isNull(response.getDecision());
            System.Assert.isNull(response.getStatusCode());
            System.Assert.isNull(response.getAuthenticationLevel());
        }
        System.Test.stopTest();
    }

    /**
     * Verifies minimum-access callers can read the matching authentication obligation.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void authorization_WhenObligationsContainAuthenticationLevel_ReturnsMatchingValue() {
        Profile minimumAccessProfile = [
            SELECT Id
            FROM Profile
            WHERE Name = 'Minimum Access - Salesforce'
            LIMIT 1
        ];
        String username = 'altinn-response-' + String.valueOf(Crypto.getRandomLong()) + '@example.invalid';
        User minimumAccessUser = new User(
            Alias = 'altresp',
            Email = username,
            EmailEncodingKey = 'UTF-8',
            LastName = 'Altinn Response Test',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = minimumAccessProfile.Id,
            TimeZoneSidKey = 'Europe/Oslo',
            Username = username
        );
        insert minimumAccessUser;

        System.runAs(minimumAccessUser) {
            System.Test.startTest();
            AltinnResponseUtils.AltinnAccessResponseWrapper response = AltinnResponseUtils.parse(
                '{"response":[{"decision":"Permit","obligations":[' +
                    '{},{"attributeAssignment":[{"category":"synthetic-unrelated","value":"ignored"}]},' +
                    '{"attributeAssignment":[{"category":"urn:altinn:minimum-authenticationlevel","value":"4"}]}' +
                    ']}]}'
            );
            String authenticationLevel = response.getAuthenticationLevel();
            System.Test.stopTest();

            System.Assert.areEqual('4', authenticationLevel);
            System.Assert.isNull(response.getStatusCode());
        }
    }

    /**
     * Verifies missing status and unrelated obligations do not fabricate response values.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void authorization_WhenOptionalDetailsAreAbsent_ReturnsNull() {
        System.Test.startTest();
        for (
            String payload : new List<String>{
                '{"response":[{"decision":"Deny"}]}',
                '{"response":[{"status":{},"obligations":[]}]}',
                '{"response":[{"obligations":[{},{"attributeAssignment":[]}]}]}',
                '{"response":[{"obligations":[{"attributeAssignment":[{"category":"synthetic-unrelated","value":"ignored"}]}]}]}'
            }
        ) {
            AltinnResponseUtils.AltinnAccessResponseWrapper response = AltinnResponseUtils.parse(payload);
            System.Assert.isNull(response.getStatusCode());
            System.Assert.isNull(response.getAuthenticationLevel());
        }
        System.Test.stopTest();
    }

    /**
     * Verifies malformed JSON raises the documented parsing exception with its cause.
     *
     * @since 2026-10-24
     */
    @IsTest
    private static void authorization_WhenJsonIsMalformed_ThrowsParsingException() {
        AltinnResponseUtils.AltinnAccessResponseWrapperException actualException;

        System.Test.startTest();
        try {
            AltinnResponseUtils.parse('{"response":[');
        } catch (AltinnResponseUtils.AltinnAccessResponseWrapperException caughtException) {
            actualException = caughtException;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(actualException);
        System.Assert.isTrue(actualException.getMessage().startsWith('Failed to parse Altinn access response JSON: '));
        System.Assert.isInstanceOfType(actualException.getCause(), System.JSONException.class);
    }
}
