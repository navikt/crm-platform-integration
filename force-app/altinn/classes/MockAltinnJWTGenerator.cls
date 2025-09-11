/**
 * @description Mock class to generate a mock Altinn JWT token for testing purposes.
 */
@isTest
public class MockAltinnJWTGenerator {
    public static String createMockAltinnJWT() {
        // Generate dynamic UUIDs
        String fakeClientId = generateFakeUUID();
        String fakeJti = generateFakeUUID();
        String fakeOrgId = String.valueOf(Math.mod(Crypto.getRandomInteger(), 900000000) + 100000000);

        // Current time
        Long now = DateTime.now().getTime() / 1000;
        Long iat = now;
        Long exp = now + 1800; // 30 minutes ahead
        Long nbf = now;

        // Header
        Map<String, Object> header = new Map<String, Object>{ 'alg' => 'RS256', 'typ' => 'JWT' };

        // Payload - mock values, but same structure
        Map<String, Object> payload = new Map<String, Object>{
            'scope' => 'altinn:authorization/authorize altinn:accessmanagement/authorizedparties.resourceowner',
            'token_type' => 'Bearer',
            'exp' => exp,
            'iat' => iat,
            'client_id' => fakeClientId,
            'consumer' => new Map<String, Object>{ 'authority' => 'iso6523-actorid-upis', 'ID' => '0192:' + fakeOrgId },
            'urn:altinn:orgNumber' => fakeOrgId,
            'urn:altinn:authenticatemethod' => 'maskinporten',
            'urn:altinn:authlevel' => 3,
            'iss' => 'https://platform.test.altinn.no/mock-issuer/',
            'jti' => fakeJti,
            'nbf' => nbf
        };

        // Encode
        String encodedHeader = base64UrlEncode(JSON.serialize(header));
        String encodedPayload = base64UrlEncode(JSON.serialize(payload));
        String dummySignature = base64UrlEncode('dummy-signature');

        return String.join(new List<String>{ encodedHeader, encodedPayload, dummySignature }, '.');
    }

    /**
     * @description
     * Creates a mock JWT with missing iat/exp claims for testing error scenarios.
     * This JWT will have a valid structure but lacks the required issued at (iat)
     * and expires at (exp) claims that the token cache validation expects.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @return String A JWT token with missing claims for testing purposes
     */
    public static String createJWTWithMissingClaims() {
        // Generate dynamic values
        String fakeClientId = generateFakeUUID();
        String fakeJti = generateFakeUUID();
        String fakeOrgId = String.valueOf(Math.mod(Crypto.getRandomInteger(), 900000000) + 100000000);

        // Header
        Map<String, Object> header = new Map<String, Object>{ 'alg' => 'RS256', 'typ' => 'JWT' };

        // Payload - intentionally missing 'iat' and 'exp' claims
        Map<String, Object> payload = new Map<String, Object>{
            'scope' => 'altinn:authorization/authorize altinn:accessmanagement/authorizedparties.resourceowner',
            'token_type' => 'Bearer',
            'client_id' => fakeClientId,
            'consumer' => new Map<String, Object>{ 'authority' => 'iso6523-actorid-upis', 'ID' => '0192:' + fakeOrgId },
            'urn:altinn:orgNumber' => fakeOrgId,
            'urn:altinn:authenticatemethod' => 'maskinporten',
            'urn:altinn:authlevel' => 3,
            'iss' => 'https://platform.test.altinn.no/mock-issuer/',
            'jti' => fakeJti
            // Intentionally missing 'iat', 'exp', and 'nbf' claims
        };

        // Encode
        String encodedHeader = base64UrlEncode(JSON.serialize(header));
        String encodedPayload = base64UrlEncode(JSON.serialize(payload));
        String dummySignature = base64UrlEncode('dummy-signature');

        return String.join(new List<String>{ encodedHeader, encodedPayload, dummySignature }, '.');
    }

    private static String base64UrlEncode(String input) {
        String base64 = EncodingUtil.base64Encode(Blob.valueOf(input));
        return base64.replace('+', '-').replace('/', '_').replace('=', '');
    }

    public static String generateFakeUUID() {
        String input = String.valueOf(Crypto.getRandomInteger()) + DateTime.now().getTime();
        String raw = EncodingUtil.convertToHex(Crypto.generateDigest('SHA-256', Blob.valueOf(input)));
        return raw.substring(0, 8) +
            '-' +
            raw.substring(8, 12) +
            '-' +
            raw.substring(12, 16) +
            '-' +
            raw.substring(16, 20) +
            '-' +
            raw.substring(20, 32);
    }
}
