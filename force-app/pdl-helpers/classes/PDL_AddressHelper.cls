public with sharing class PDL_AddressHelper {
    public static Boolean hasSameBostedsAddress(PDL_HentPerson personA, PDL_HentPerson personB, Boolean checkDates) {
        PDL_Bostedsadresse a = (PDL_Bostedsadresse) getCurrentAdresse(personA.bostedsadresse);
        PDL_Bostedsadresse b = (PDL_Bostedsadresse) getCurrentAdresse(personB.bostedsadresse);

        PDL_DeltBosted deltBostedA = (PDL_DeltBosted) getCurrentAdresse(personA.deltBosted);
        PDL_DeltBosted deltBostedB = (PDL_DeltBosted) getCurrentAdresse(personA.deltBosted);

        if (isSameAddress(a, b) && checkDates ? validInSamePeriod(a, b) : true) {
            return true;
        }

        if (isSameAddress(a, deltBostedB) && checkDates ? validInSamePeriod(a, deltBostedB) : true) {
            return true;
        }

        if (isSameAddress(deltBostedA, b) && checkDates ? validInSamePeriod(deltBostedA, b) : true) {
            return true;
        }

        if (
            isSameAddress(deltBostedA, deltBostedB) && checkDates ? validInSamePeriod(deltBostedA, deltBostedB) : true
        ) {
            return true;
        }

        return false;
    }

    public static PDL_AdresseType getCurrentAdresse(PDL_AdresseType[] addresses) {
        if (addresses?.size() > 0) {
            for (PDL_AdresseType address : addresses) {
                if (address.metadata.historisk == false) {
                    return address;
                }
            }
        }

        return null;
    }

    public static Boolean isSameAddress(PDL_AdresseType a, PDL_AdresseType b) {
        if (hasNullAddress(a, b)) {
            return false;
        }

        if (isSameAddress(a?.vegadresse, b?.vegadresse)) {
            return true;
        }

        if (isSameAddress(a?.matrikkeladresse, b?.matrikkeladresse)) {
            return true;
        }

        // if (isSameAddress(a?.utenlandskAdresse, b?.utenlandskAdresse)) {
        //     return true;
        // }

        if (isSameAddress(a?.vegadresse, b?.matrikkeladresse)) {
            return true;
        }

        if (isSameAddress(b?.vegadresse, a?.matrikkeladresse)) {
            return true;
        }

        return false;
    }

    public static Boolean isSameAddress(PDL_Adresse a, PDL_Adresse b) {
        Boolean match = true;

        match &= !hasNullAddress(a, b);
        match &= a.matrikkelId == b.matrikkelId;
        match &= a.bruksenhetsnummer == b.bruksenhetsnummer;

        return match;
    }

    // public static Boolean isSameAddress(PDL_Bostedsadresse a, PDL_Bostedsadresse b) {
    //     if (false == validInSamePeriod(a, b)) {
    //         return false;
    //     }

    //     if (isSameAddress(a?.vegadresse, b?.vegadresse)) {
    //         return true;
    //     }

    //     if (isSameAddress(a?.matrikkeladresse, b?.matrikkeladresse)) {
    //         return true;
    //     }

    //     if (isSameAddress(a?.utenlandskAdresse, b?.utenlandskAdresse)) {
    //         return true;
    //     }

    //     if (isSameAddress(a?.vegadresse, b?.matrikkeladresse)) {
    //         return true;
    //     }

    //     if (isSameAddress(b?.vegadresse, a?.matrikkeladresse)) {
    //         return true;
    //     }

    //     return false;
    // }

    // public static Boolean isSameAddress(PDL_Vegadresse a, PDL_Matrikkeladresse b) {
    //     Boolean match = true;

    //     match &= !hasNullAddress(a, b);
    //     match &= a.matrikkelId == b.matrikkelId;
    //     match &= a.bruksenhetsnummer == b.bruksenhetsnummer;

    //     return match;
    // }

    // public static Boolean isSameAddress(PDL_Vegadresse a, PDL_Vegadresse b) {
    //     Boolean match = true;

    //     match &= !hasNullAddress(a, b);
    //     match &= a.matrikkelId == b.matrikkelId;
    //     match &= a.bruksenhetsnummer == b.bruksenhetsnummer;

    //     return match;
    // }

    // public static Boolean isSameAddress(PDL_Matrikkeladresse a, PDL_Matrikkeladresse b) {
    //     Boolean match = true;

    //     match &= !hasNullAddress(a, b);
    //     match &= a.matrikkelId == b.matrikkelId;
    //     match &= a.bruksenhetsnummer?.equalsIgnoreCase(b?.bruksenhetsnummer);

    //     return match;
    // }

    public static Boolean isDateStillValid(Datetime fromDateTime, Datetime toDateTime, Datetime dateToCompare) {
        Boolean isValid = true;

        isValid &= fromDateTime <= dateToCompare;
        isValid &= toDateTime == null || toDateTime >= dateToCompare;

        return isValid;
    }

    public static Boolean validInSamePeriod(PDL_Bostedsadresse a, PDL_Bostedsadresse b) {
        Boolean match = true;

        match &= a.gyldigFraOgMed < b.gyldigTilOgMed;
        match &= a.gyldigTilOgMed > b.gyldigFraOgMed;

        return match;
    }

    public static Boolean validInSamePeriod(PDL_DeltBosted a, PDL_Bostedsadresse b) {
        return validInSamePeriod(b, a);
    }

    public static Boolean validInSamePeriod(PDL_Bostedsadresse a, PDL_DeltBosted b) {
        Boolean match = true;

        match &= a.gyldigFraOgMed.date() < b.sluttdatoForKontrakt;
        match &= a.gyldigTilOgMed.date() > b.startdatoForKontrakt;

        return match;
    }

    public static Boolean validInSamePeriod(PDL_DeltBosted a, PDL_DeltBosted b) {
        Boolean match = true;

        match &= a.startdatoForKontrakt < b.sluttdatoForKontrakt;
        match &= a.sluttdatoForKontrakt > b.startdatoForKontrakt;

        return match;
    }

    private static Boolean hasNullAddress(Object a, Object b) {
        return (a == null || b == null);
    }
}
