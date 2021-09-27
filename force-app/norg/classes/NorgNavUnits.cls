public with sharing class NorgNavUnits {
    public static NavUnit getNavUnit(String unitNumber) {
        if (String.isBlank(unitNumber)) {
            String errorRef = logError('Error from NorgNavUnits.getNavUnit. Unitnumber: ' + unitNumber);

            throw new NavUnitException(
                'Kunne ikke hente enheten fra Norg. Enhetsnummer er blankt. Referanse til feil: ' + errorRef
            );
        }

        HttpResponse response = NorgService.getFilteredNavUnits(null, new List<String>{ unitNumber }, null);

        if (response.getStatusCode() == 200) {
            List<NavUnit> navUnits = (true == String.isNotBlank(response.getBody()))
                ? (List<NavUnit>) JSON.deserialize(
                      response.getBody().replaceAll('\n', '\\\\r\\\\n'),
                      List<NavUnit>.class
                  )
                : null;

            return navUnits != null && navUnits.size() > 0 ? navUnits[0] : null;
        }

        String errorRef = logError(response, 'Error from NorgService.getFilteredNavUnits. Unitnumber: ' + unitNumber);

        throw new NavUnitException('Kunne ikke hente enhets informasjon fra NORG2. Referanse til feil: ' + errorRef);
    }

    public static NavUnitContactInformation getNavUnitContactInformation(String unitNumber) {
        if (String.isBlank(unitNumber)) {
            String errorRef = logError(
                'Error from NorgNavUnits.getNavUnitContactInformation. Unitnumber: ' + unitNumber
            );

            throw new NavUnitException(
                'Kunne ikke hente enhetens kontaktinformasjon fra Norg. Enhetsnummer er blankt. Referanse til feil: ' +
                errorRef
            );
        }

        HttpResponse response = NorgService.getNavUnitContactInformation(unitNumber);
        if (response.getStatusCode() == 200) {
            return (true == String.isNotBlank(response.getBody()))
                ? (NavUnitContactInformation) JSON.deserialize(
                      response.getBody().replaceAll('\n', '\\\\r\\\\n'),
                      NavUnitContactInformation.class
                  )
                : null;
        }

        String errorRef = logError(
            response,
            'Error from NorgService.getNavUnitContactInformation. Unitnumber: ' + unitNumber
        );

        throw new NavUnitException(
            'Kunne ikke hente enhetens kontaktinformasjon fra NORG2. Referanse til feil: ' + errorRef
        );
    }

    public static NavUnit getPersonNavUnit(Person__c person) {
        Boolean isShielded = getIsShielded(person);
        String location = getLocation(person);
        String discretionCode = getDiscretionaryCode(person);

        String params =
            '[geografiskOmraade: ' +
            location +
            '| disk: ' +
            discretionCode +
            ' | skjermet: ' +
            isShielded +
            ']';

        if (String.isBlank(location)) {
            logError('Error from NorgNavUnits.getPersonNavUnit. Parameters: ' + params);
            throw new NavUnitException(
                'Kan ikke slå opp enhet. Kunne ikke finne geografisk tilhørighet eller kommunenummer på bruker.'
            );
        }

        HttpResponse response = NorgService.getNavUnitFromGeograpichLocation(location, discretionCode, isShielded);

        if (response.getStatusCode() == 200) {
            return (true == String.isNotBlank(response.getBody()))
                ? (NavUnit) JSON.deserialize(response.getBody().replaceAll('\n', '\\\\r\\\\n'), NavUnit.class)
                : null;
        }

        String errorRef = logError(
            response,
            'Error from NorgService.getNavUnitFromGeographicLocation. Parameters: ' + params
        );

        throw new NavUnitException('Kunne ikke hente enhets informasjon fra NORG2. Referanse til feil: ' + errorRef);
    }

    public static NavUnitWithContactInformation getPersonNavUnitWithContactInformation(Person__c person) {
        NavUnitWithContactInformation unit = new NavUnitWithContactInformation();
        unit.enhet = getPersonNavUnit(person);
        unit.kontaktinformasjon = getNavUnitContactInformation(unit.enhet.enhetNr);
        return unit;
    }

    public static NavUnitWithContactInformation getNavUnitWithContactInformation(String unitNumber) {
        NavUnitWithContactInformation unit = new NavUnitWithContactInformation();
        unit.enhet = getNavUnit(unitNumber);
        unit.kontaktinformasjon = getNavUnitContactInformation(unitNumber);
        return unit;
    }

    public static List<NavUnitWorkAllocation> getWorkAllocation(
        Person__c person,
        String themeGroupCode,
        String themeCode,
        String themeSubThemeCode,
        String taskType
    ) {
        NavUnitWorkAllocationInput allocationInput = new NavUnitWorkAllocationInput();

        //allocationInput.temagruppe = themeGroupCode; We don't use the correct theme group codes
        allocationInput.tema = themeCode;
        allocationInput.behandlingstema = themeSubThemeCode;
        allocationInput.oppgavetype = taskType;

        return getWorkAllocation(person, allocationInput);
    }

    public static List<NavUnitWorkAllocation> getWorkAllocation(
        Person__c person,
        NavUnitWorkAllocationInput allocationInput
    ) {
        //If no person due to sharing we can just skip these
        if (null != person) {
            allocationInput.skjermet = getIsShielded(person);
            allocationInput.geografiskOmraade = getLocation(person);
            allocationInput.diskresjonskode = getDiscretionaryCode(person);
        }

        return getWorkAllocation(allocationInput);
    }

    public static List<NavUnitWorkAllocation> getWorkAllocation(NavUnitWorkAllocationInput allocationInput) {
        HttpResponse response = NorgService.getNavUnitWorkAllocations(allocationInput);

        if (response.getStatusCode() == 200) {
            if (true == String.isNotBlank(response.getBody())) {
                return (List<NavUnitWorkAllocation>) JSON.deserialize(
                    response.getBody().replaceAll('\n', '\\\\r\\\\n'),
                    List<NavUnitWorkAllocation>.class
                );
            }
        }
        String errorRef = logError(
            response,
            'Error getting Nav Unit Work Allocation: ' + JSON.serialize(allocationInput)
        );
        throw new NavUnitException('Kunne ikke hente arbeidsfordeling. Referanse til feil: ' + errorRef);
    }

    private static Boolean getIsShielded(Person__c person) {
        if (true == person.INT_IsNavEmployee__c) {
            return true;
        }
        return false;
    }

    private static String getDiscretionaryCode(Person__c person) {
        switch on person.INT_Confidential__c {
            when 'STRENGT_FORTROLIG_UTLAND', 'STRENGT_FORTROLIG' {
                return 'SPSF';
            }
            when 'FORTROLIG' {
                return 'SPFO';
            }
            when 'UGRADERT' {
                return 'ANY';
            }
        }

        return null;
    }

    private static String getLocation(Person__c person) {
        return String.isNotBlank(person.INT_DistrictNumber__c)
            ? person.INT_DistrictNumber__c
            : person.INT_MunicipalityNumber__c;
    }

    private static String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.httpError(message, resp, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }

    private static String logError(String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }

    public class NavUnitException extends Exception {
    }
}
