@SuppressWarnings('PMD')
public class AltinnResponseUtils {
    public class AltinnAccessResponseWrapper {
        public List<AltinnAccessResponse> response;

        public Boolean isPermit() {
            return response != null && !response.isEmpty() && response[0].decision == 'Permit';
        }

        public Boolean isDeny() {
            return response != null && !response.isEmpty() && response[0].decision == 'Deny';
        }

        public Boolean isIndeterminate() {
            return response != null && !response.isEmpty() && response[0].decision == 'Indeterminate';
        }

        public Boolean isNotApplicable() {
            return response != null && !response.isEmpty() && response[0].decision == 'NotApplicable';
        }

        public String getDecision() {
            return (response != null && !response.isEmpty()) ? response[0].decision : null;
        }

        public String getStatusCode() {
            return (response != null && !response.isEmpty()) ? response[0].status?.statusCode?.value : null;
        }

        public String getAuthenticationLevel() {
            if (response != null && !response.isEmpty()) {
                List<AltinnObligation> obligations = response[0].obligations;
                if (obligations != null) {
                    for (AltinnObligation obligation : obligations) {
                        if (obligation.attributeAssignment != null) {
                            for (AltinnAttributeAssignment assignment : obligation.attributeAssignment) {
                                if (assignment.category == 'urn:altinn:minimum-authenticationlevel') {
                                    return assignment.value;
                                }
                            }
                        }
                    }
                }
            }
            return null;
        }
    }

    public class AltinnAccessResponse {
        public String decision;
        public AltinnStatus status;
        public List<AltinnObligation> obligations;
        public Object associateAdvice;
        public Object category;
        public Object policyIdentifierList;
    }

    public class AltinnStatus {
        public String statusMessage;
        public String statusDetails;
        public AltinnStatusCode statusCode;
    }

    public class AltinnStatusCode {
        public String value;
        public AltinnStatusCode statusCode;
    }

    public class AltinnObligation {
        public String id;
        public List<AltinnAttributeAssignment> attributeAssignment;
    }

    public class AltinnAttributeAssignment {
        public String attributeId;
        public String value;
        public String category;
        public String dataType;
        public String issuer;
    }

    // Static method to parse JSON string into a wrapper instance
    public static AltinnAccessResponseWrapper parse(String jsonString) {
        try {
            return (AltinnAccessResponseWrapper) JSON.deserialize(jsonString, AltinnAccessResponseWrapper.class);
        } catch (Exception ex) {
            throw new AltinnAccessResponseWrapperException(
                'Failed to parse Altinn access response JSON: ' + ex.getMessage(),
                ex
            );
        }
    }

    public class AltinnAccessResponseWrapperException extends Exception {
    }
}
