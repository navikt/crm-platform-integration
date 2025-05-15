/**
 * @description Service class for making callouts to the KRR API.
 *
 * @author Tor Håkon Sigurdsen
 * @since 2025 May - Refactor entire class
 */
public class KrrCalloutService {
    private static final String API_CONFIG_NAME = 'KRR_API';
    private static final String SERVICE_AUTH_HEADER = 'gcpsaasproxy';
    private static final String POST_KRR_QUERY = 'POST_KRR_QUERY';

    private LoggerUtility logger;
    private string callId;
    private String includeSecureDigitalPost;

    /**
     * @description Constructor for the KrrCalloutService class.
     * Initializes the logger and generates a unique call ID.
     */
    public KrrCalloutService() {
        logger = new LoggerUtility(CRM_ApplicationDomain.Domain.PLATFORCE, 'KRR').setCategory('KRR');
        callId = System.UUID.randomUUID().toString();
        includeSecureDigitalPost = 'false';
    }

    /**
     * @description Sets the includeSecureDigitalPost parameter for the KRR API call.
     * @param includeSecureDigitalPost Indicates if secure digital post should be included in the response.
     * @return The current instance of KrrCalloutService.
     */
    public KrrCalloutService setIncludeSecureDigitalPost(Boolean includeSecureDigitalPost) {
        this.includeSecureDigitalPost = includeSecureDigitalPost ? 'true' : 'false';
        return this;
    }

    /**
     * @description Calls the KRR API to get person information.
     * @param personIdents List of person identifiers to look up.
     * @return A map of person identifiers to PersonResponse objects containing the information retrieved from the KRR API.
     */
    public KrrResponse getPersons(List<String> personIdents) {
        return this.getPersons(personIdents, false);
    }

    /**
     * @description Calls the KRR API to get person information.
     * @param personIdents List of person identifiers to look up.
     * @param isSystemContext Indicates if the call should be made in system context.
     * @return A map of person identifiers to PersonResponse objects containing the information retrieved from the KRR API.
     */
    public KrrResponse getPersons(List<String> personIdents, Boolean isSystemContext) {
        if (personIdents == null || personIdents.isEmpty()) {
            throw new IllegalArgumentException('Person identifier list cannot be empty.');
        }
        KrrResponse krrResponse = null;

        try {
            ApiController apiCtrl = new ApiController();
            apiCtrl.initRequest(
                API_CONFIG_NAME,
                POST_KRR_QUERY,
                new Map<String, String>{ 'inkluderSikkerDigitalPost' => this.includeSecureDigitalPost }
            );

            apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER)
                .addHeader('Content-Type', 'application/json')
                .setLogger(logger)
                .setLogCalloutRequest()
                .setLogUuid(callId)
                .addHeader('Nav-Call-Id', callId)
                .setBody(JSON.serialize(new PersonOppslagRequest(personIdents)));
            if (isSystemContext) {
                apiCtrl.setSystemContext();
            }

            apiCtrl.doCallout();

            HttpResponse response = apiCtrl.getResponse();
            if (response.getStatusCode() == 200) {
                krrResponse = (KrrResponse) JSON.deserialize(response.getBody(), KrrResponse.class);
            } else {
                this.logger.error(
                    'Error from KRR: ' + response.getStatusCode() + ' - ' + response.getBody() + '\nCallId: ' + callId,
                    null
                );
            }
        } catch (CalloutException e) {
            this.logger.exception(e);
            this.logger.publish();
            throw e;
        }
        this.logger.publish();
        return krrResponse;
    }

    /**
     * @description Calls the KRR API to get person information.
     * @param personidenter List of person identifiers to look up.
     * @param apiServiceName The name of the API service to use.
     * @return A list of Person objects containing the information retrieved from the KRR API.
     */
    public static List<KrrCalloutService.Person> doPersonOppslag2(List<String> personidenter, String apiServiceName) {
        return doPersonOppslag2(personidenter, apiServiceName, false);
    }

    /**
     * @description Calls the KRR API to get person information.
     * @param personidenter List of person identifiers to look up.
     * @param apiServiceName The name of the API service to use.
     * @param isSystemContext Indicates if the call should be made in system context.
     * @return A list of Person objects containing the information retrieved from the KRR API.
     */
    public static List<KrrCalloutService.Person> doPersonOppslag2(
        List<String> personidenter,
        String apiServiceName,
        Boolean isSystemContext
    ) {
        if (personidenter == null || personidenter.isEmpty()) {
            return new List<KrrCalloutService.Person>();
        }

        KrrCalloutService service = new KrrCalloutService();
        KrrResponse response = service.getPersons(personidenter, isSystemContext);

        List<KrrCalloutService.Person> persons = new List<KrrCalloutService.Person>();
        if (response != null && response.personer != null) {
            // Maintain order of original personidenter list
            for (String personId : personidenter) {
                if (response.personer.containsKey(personId) && response.personer.get(personId) != null) {
                    persons.add(response.personer.get(personId));
                }
            }
        }
        return persons;
    }

    /**
     * @description Represents a request to the KRR API for person information.
     */
    private class PersonOppslagRequest {
        List<String> personidenter;
        PersonOppslagRequest(List<String> personidenter) {
            this.personidenter = personidenter;
        }
    }
    /**
     * @description Represents a response from the KRR API for a person.
     */
    public class KrrResponse {
        /**
         * @description A map of person identifiers to Person objects.
         * @example {"12345678901": {"personident": "12345678901", "aktiv": true, ...}}
         */
        public Map<String, KrrCalloutService.Person> personer { public get; private set; }

        /**
         * @description A map of error messages for person identifiers that could not be found.
         * @example {"12345678902": "person_ikke_funnet", "12345678903": "person_ikke_funnet"}
         */
        public Map<String, String> feil { public get; private set; }
    }

    /**
     * @description Represents a person in the KRR system.
     */
    public class Person {
        /**
         * @description The unique identifier for the person in the KRR system.
         * @example "12345678901"
         */
        @TestVisible
        public String personident { public get; private set; }
        /**
         * @description Indicates if the person is active in the KRR system.
         * @example true
         */
        @TestVisible
        public Boolean aktiv { public get; private set; }

        /**
         * @description Indicates if the person can be notified.
         * @example true
         */
        @TestVisible
        public Boolean kanVarsles { public get; private set; }
        /**
         * @description The date and time when the reservation was last updated.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime reservasjonOppdatert { public get; private set; }

        /**
         * @description Indicates if the person has reserved their information.
         * @example true
         */
        @TestVisible
        public Boolean reservert { public get; private set; }

        /**
         * @description The preferred language of the person.
         * Possible values: "nb" (Norwegian Bokmål), "nn" (Norwegian Nynorsk), "en" (English), se (Northern Sami).
         * @example "nb"
         */
        @TestVisible
        public String spraak { public get; private set; }
        /**
         * @description The date and time when the preferred language was last updated.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime spraakOppdatert { public get; private set; }

        /**
         * @description The email address of the person.
         * @example "example@example.com"
         */
        @TestVisible
        public String epostadresse { public get; private set; }

        /**
         * @description The date and time when the email address was last updated.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime epostadresseOppdatert { public get; private set; }

        /**
         * @description The date and time when the email address was verified.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime epostadresseVerifisert { public get; private set; }

        /**
         * @description The mobile phone number of the person.
         * @example "+4712345678"
         */
        @TestVisible
        public String mobiltelefonnummer { public get; private set; }
        /**
         * @description The date and time when the mobile phone number was last updated.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime mobiltelefonnummerOppdatert { public get; private set; }

        /**
         * @description The date and time when the mobile phone number was verified.
         * @example "2025-04-01T12:00:00Z"
         */
        @TestVisible
        public DateTime mobiltelefonnummerVerifisert { public get; private set; }

        /**
         * @description The secure digital mailbox of the person.
         * @since April 2025 - Initial version
         */
        @TestVisible
        public SikkerDigitalPostkasse sikkerDigitalPostkasse { public get; private set; }
    }

    /**
     * @description Represents a secure digital mailbox for the person.
     * @since April 2025 - Added comments
     */
    public class SikkerDigitalPostkasse {
        /**
         * @description The address of the secure digital mailbox.
         * @example "ola.nordmann#9YDT"
         */
        @TestVisible
        public String adresse { public get; private set; }

        /**
         * @description The address of the mailbox provider.
         * Possible values: "984661185" (Posten Norge AS), "922020175" (E-boks Norge NUF).
         * @example "984661185"
         */
        @TestVisible
        public String leverandoeradresse { public get; private set; }

        /**
         * @description The certificate of the mailbox provider.
         * @example "MIIGTzCCBDegAwIBAgILAZdzsvHu7xp9XY..."
         */
        @TestVisible
        public String leverandoerSertifikat { public get; private set; }
    }
}
