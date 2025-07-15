public with sharing class NorgService {
    private final static string API_CONFIG_NAME = 'NORG2_API'; //API Config name to set when using the ApiController
    private final static string SERVICE_AUTH_HEADER = 'Norg2';

    public static HttpResponse getNavUnitsFromSatuses(List<String> unitStatuses) {
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('statuser', String.join(unitStatuses, ','));

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_UNITS_FROM_STATUSES', pathParamMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER).addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getFilteredNavUnits(
        List<String> unitStatuses,
        List<String> unitNumbers,
        String navTaskFilter
    ) {
        Map<String, String> urlParams = new Map<String, String>();

        if (null != unitStatuses && 0 < unitStatuses.size()) {
            urlParams.put('enhetStatusListe', String.join(unitStatuses, ','));
        }
        if (null != unitNumbers && 0 < unitNumbers.size()) {
            urlParams.put('enhetsnummerListe', String.join(unitNumbers, ','));
        }
        if (String.isNotBlank(navTaskFilter)) {
            urlParams.put('oppgavebehandlerFilter', navTaskFilter);
        }

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_FILTERED_NAV_UNITS');
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER)
            .addHeader('Content-Type', 'application/json')
            .setUrlParams(urlParams);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getNavUnitWorkAllocations(NavUnitWorkAllocationInput allocationInput) {
        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'POST_NAV_UNIT_WORK_ALLOCATION');
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER)
            .addHeader('Content-Type', 'application/json')
            .setBody(JSON.serialize(allocationInput, true));
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getNavUnitFromGeograpichLocation(
        String geographicLocation,
        String discretionCode,
        Boolean shielded
    ) {
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('geografiskOmraade', geographicLocation);

        Map<String, String> urlParams = new Map<String, String>();
        if (String.isNotBlank(discretionCode)) {
            urlParams.put('disk', discretionCode);
        }
        if (null != shielded) {
            urlParams.put('skjermet', String.valueOf(shielded));
        }

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_NAV_UNIT_BY_LOCATION', pathParamMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER)
            .addHeader('Content-Type', 'application/json')
            .setUrlParams(urlParams);
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getNavUnitContactInformation(String unitNumber) {
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('enhetsnummer', unitNumber);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_NAV_UNIT_CONTACT_INFORMATION', pathParamMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER).addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getNavOfficeInfo(String unitNumber) {
        Map<String, String> pathParamMap = new Map<String, String>();
        pathParamMap.put('enhetsnummer', unitNumber);

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_NAV_OFFICES_BY_UNIT', pathParamMap);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER).addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public static HttpResponse getCodes(KodeverkNavn kodeverkNavn) {
        Map<String, String> pathParam = new Map<String, String>();
        pathParam.put('kodeverkNavn', kodeverkNavn.name());

        ApiController apiCtrl = new ApiController();
        apiCtrl.initRequest(API_CONFIG_NAME, 'GET_KODEVERK', pathParam);
        apiCtrl.addServiceAuthHeader(SERVICE_AUTH_HEADER).addHeader('Content-Type', 'application/json');
        apiCtrl.doCallout();

        return apiCtrl.getResponse();
    }

    public enum KodeverkNavn {
        Diskresjonskoder,
        Oppgavetyper,
        Behandlingstyper,
        Behandlingstema,
        Tema,
        Temagrupper,
        Geografi,
        EnhetstyperNorg,
        Postnummer,
        Orgniva,
        Organiseringstype
    }
}
