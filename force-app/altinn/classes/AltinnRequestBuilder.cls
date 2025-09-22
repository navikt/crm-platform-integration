/**
 * @description This class is responsible for building requests to the Altinn API.
 * It provides methods to create JSON requests for authorizing access and getting authorized parties.
 *
 * @author Kenneth Sørensen
 * @since May 2025 - Created.
 *
 * @group Altinn Callout Service
 */
public with sharing class AltinnRequestBuilder {
    /**
     * @description This method builds the request for authorizing access to a resource.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the person.
     * @param organizationNumber The organization number of the organization.
     * @param resourceValue The value of the resource to be accessed.
     * @return `String` The serialized JSON request.
     */
    public static String buildAuthorizeAccessRequest(
        String personIdent,
        String organizationNumber,
        String resourceValue
    ) {
        Map<String, Object> request = new Map<String, Object>();

        // Top-level Request
        request.put('ReturnPolicyIdList', true);

        // AccessSubject
        Map<String, Object> accessSubjectAttribute = new Map<String, Object>{
            'AttributeId' => 'urn:altinn:person:identifier-no',
            'Value' => personIdent
        };
        Map<String, Object> accessSubject = new Map<String, Object>{
            'Attribute' => new List<Object>{ accessSubjectAttribute }
        };
        request.put('AccessSubject', new List<Object>{ accessSubject });

        // Action
        Map<String, Object> actionAttribute = new Map<String, Object>{
            'AttributeId' => 'urn:oasis:names:tc:xacml:1.0:action:action-id',
            'Value' => 'access',
            'DataType' => 'http://www.w3.org/2001/XMLSchema#string'
        };
        Map<String, Object> action = new Map<String, Object>{ 'Attribute' => new List<Object>{ actionAttribute } };
        request.put('Action', new List<Object>{ action });

        // Resource
        Map<String, Object> resourceAttr1 = new Map<String, Object>{
            'AttributeId' => 'urn:altinn:resource',
            'Value' => resourceValue
        };
        Map<String, Object> resourceAttr2 = new Map<String, Object>{
            'AttributeId' => 'urn:altinn:organization:identifier-no',
            'Value' => organizationNumber
        };
        Map<String, Object> resource = new Map<String, Object>{
            'Attribute' => new List<Object>{ resourceAttr1, resourceAttr2 }
        };
        request.put('Resource', new List<Object>{ resource });

        // Wrap inside outer "Request"
        Map<String, Object> wrapper = new Map<String, Object>{ 'Request' => request };

        return JSON.serialize(wrapper);
    }

    /**
     * @description This method builds the request for getting authorized parties.
     *
     * @author Kenneth Sørensen
     * @since May 2025 - Created.
     *
     * @param personIdent The personal identification number of the person.
     * @return `String` The serialized JSON request.
     */
    public static String buildAuthorizedPartiesRequest(String personIdent) {
        Map<String, Object> request = new Map<String, Object>();

        request.put('type', 'urn:altinn:person:identifier-no');
        request.put('value', personIdent);

        return JSON.serialize(request);
    }
}
