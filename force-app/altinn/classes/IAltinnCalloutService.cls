/**
 * @description Interface for Altinn callout service.
 *
 * @author Kenneth Sørensen
 * @since April 2025 - Created.
 *
 * @group Altinn Callout Service
 */
public interface IAltinnCalloutService {
    /**
     * @description Get organizations for a given personIdent.
     *
     * @author Kenneth Sørensen
     * @since April 2025 - Created.
     *
     * @param personIdent The person identifier.
     * @return The Altinn Organizations Response.
     */
    Object getOrganizations(String personIdent);

    /**
     * @description Get rights for a given personIdent, organizationNumber and serviceCode.
     *
     * @author Kenneth Sørensen
     * @since April 2025 - Created.
     *
     * @param personIdent The person identifier.
     * @param organizationNumber The organization number.
     * @param serviceCode The service code.
     * @return The Altinn Rights Response.
     */
    Object getRights(String personIdent, String organizationNumber, String serviceCode);
}
