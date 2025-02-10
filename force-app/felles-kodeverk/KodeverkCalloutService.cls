/**
 * Fetches codes from Felles Kodeverk (FKV) and stores them as Common_Code__c
 * records. Active codes are inserted or updated, and inactive codes are skipped
 * over (if not already in database) or updated (if already in database).
 */
public class KodeverkCalloutService implements Schedulable {

    private final static String LANGUAGE = 'nb';

    /**
     * Fetches meanings from kodeverk-api. The fetched json should have only one
     * key, named _betydninger_.
     */
    private static Map<String, Object> getMeanings(String full) {
        HttpRequest req = new HttpRequest();
        req.setEndpoint(String.format(
            'callout:kodeverk/api/v1/kodeverk/{0}/koder/betydninger?spraak={1}&ekskluderUgyldige=true',
            new Object[]{
                // urlEncode turns ' ' into '+', which kodeverk does not
                // understand, so manually handle that
                EncodingUtil.urlEncode(full, 'UTF-8').replace('+', '%20'),
                LANGUAGE
                }));
        req.setMethod('GET');
        HTTPResponse res = new Http().send(req);
        if (res.getStatusCode() != 200) {
            throw new CalloutException(String.format(
            'Got response other than 200 when fetching codes from https://kodeverk-api.nav.no/: {0} {1}',
            new Object[]{res.getStatusCode(), res.getStatus()}
            ));
        }
        Map<String, Object> json = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());
        return (Map<String, Object>) json.get('betydninger');
    }

    /**
     * picks out .beskrivelser.nb.term from the json object given
     */
    private static String getTermFromJson(Map<String, Object> json) {
        Map<String, Object> descriptions = (Map<String, Object>) json.get('beskrivelser');
        Map<String, Object> descNb = (Map<String, Object>) descriptions.get(LANGUAGE);
        return (String) descNb.get('term');
    }

    /**
     * Unfortunately CRM_Code__c can't be longer than 32 chars.
     * So trim it. If this causes duplicates for us, fix it later.
     */
    private static String trimCode(String code) {
        Integer maxLength = Schema.SObjectType.Common_Code__c.fields.getMap()
            .get('CRM_Code__c').getDescribe().getLength();
        return code.substring(0, code.length() > maxLength ? maxLength : code.length());
    }

    /**
     * maps unique keys (codeSet + name) to existing common codes
     */
    private static Map<String, Common_Code__c> getExistingCodeMap(String codeSet) {
        Common_Code__c[] existingCodes = [
            SELECT Id, Name, CRM_Code_Set__c, CRM_Code__c, CRM_Active__c, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = :codeSet
        ];
        Map<String, Common_Code__c> codeByKey = new Map<String, Common_Code__c>();
        for (Common_Code__c c: existingCodes) {
            codeByKey.put(c.CRM_UniqueKey__c, c);
        }
        return codeByKey;
    }

    /**
     * Determines whether a code is still active. Useful for deactivating
     * deprecated codes, e.g. like postal code 6484 was at the end of 2022.
     */
    private static Boolean testValidity(Map<String, Object> json) {
        Date validFrom = Date.valueOf((String)json.get('gyldigFra'));
        Date validTo = Date.valueOf((String)json.get('gyldigTil'));
        Date today = Date.today();
        return validFrom <= today && today <= validTo;
    }

    /**
     * extracts foo, bar, gyldigTil, gyldigFra, ... from the meanings, and
     * stores them in a Common_Code__c structure. the _meanings_ json will look
     * like the structure below. if the unique key (foobar, ...) already exists
     * in the database, just update it, otherwise create a new instance.
     * {
     * "foo": [
     *   {
     *     "beskrivelser": {
     *       "nb": {
     *         "tekst": "longer description of bar",
     *         "term": "bar"
     *       }
     *     },
     *     "gyldigTil": "9999-12-31",
     *     "gyldigFra": "2006-07-01"
     *   }
     * ],
     * "baz": [
     *   {
     *     "beskrivelser": {
     *         ...
     */
    @TestVisible
    private static Common_Code__c[] getCodesFromMeanings(String codeSet, Map<String, Object> meanings) {
        Map<String, Common_Code__c> updatedCodeByKey = new Map<String, Common_Code__c>();
        Map<String, Common_Code__c> existingCodeByKey = getExistingCodeMap(codeSet);
        for (String key : meanings.keySet()) {
            Object[] jsonList = (Object[]) meanings.get(key);
            // loop through the codes associated with this key. a key may
            // contain multiple codes, each with its own gyldigFra and
            // gyldigTil, ordered by date. i.e., loop through a list where the
            // last element will tell us whether or not the code is still
            // active.
            for (Object jsonObj : jsonList) {
                Map<String, Object> json = (Map<String, Object>) jsonObj;
                String name = getTermFromJson(json);
                Boolean isValid = testValidity(json);
                String shortCode = trimCode(key);
                String uniqueKey = codeSet + shortCode;
                Common_Code__c code = existingCodeByKey.get(uniqueKey);
                // create a new code if it doesn't already exist and is valid
                if (code == null) {
                    if (isValid) {
                        // CRM_UniqueKey__c is set in trigger.
                        // see Common_Code_created_or_edited.flow-meta.xml
                        code = new Common_Code__c();
                        code.Name = name;
                        code.CRM_Code_Set__c = codeSet;
                        code.CRM_Code__c = shortCode;
                        code.CRM_Active__c = true;
                    }
                }
                // return updated code if it already exists, including when it
                // is no longer valid
                else {
                    code.Name = name;
                    code.CRM_Code_Set__c = codeSet;
                    code.CRM_Code__c = shortCode;
                    code.CRM_Active__c = isValid;
                }
                if (code != null) {
                    updatedCodeByKey.put(uniqueKey, code);
                }
            }
        }
        return updatedCodeByKey.values();
    }

    /**
     * gets codes from a given kodeverk and returns a list of appropriately
     * mapped Common_Code__c instances
     */
    @TestVisible
    public static Common_Code__c[] fetchCodes(String label) {
        return getCodesFromMeanings(label, getMeanings(label));
    }

    /**
     * updates the codes given. note that spaces are allowed in common code
     * names, so use the Label rather than the DeveloperName
     */
    @Future(callout=true)
    public static void fetchAndStoreCodes(String[] labels) {
        Common_Code__c[] codes = new List<Common_Code__c>();
        for (String label : labels) {
            codes.addAll(fetchCodes(label));
        }
        upsert codes;
    }

    /**
     * updates all codesets. TODO: expand metadata with info about teams etc
     */
    public static void fetchAndStoreAllCodes() {
        Kodeverk_Codeset__mdt[] codeSetEntries = [SELECT Label FROM Kodeverk_Codeset__mdt];
        Set<Kodeverk_Codeset__mdt> codeSets = new Set<Kodeverk_Codeset__mdt>(codeSetEntries);
        String[] labels = new List<String>();
        for (Kodeverk_Codeset__mdt m : codeSets) {
            labels.add(m.Label);
        }
        fetchAndStoreCodes(labels);
    }

    public static void execute(SchedulableContext sc) {
        fetchAndStoreAllCodes();
    }
}
