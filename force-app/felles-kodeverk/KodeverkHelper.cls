public class KodeverkHelper {

    private final static String LANGUAGE = 'nb';

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
     * Unfortunately Name can't be longer than 80 chars.
     * So trim it. If this causes duplicates for us, fix it later.
     */
    private static String trimName(String name) {
        Integer maxLength = Schema.SObjectType.Common_Code__c.fields.getMap()
            .get('Name').getDescribe().getLength();
        return name.substring(0, name.length() > maxLength ? maxLength : name.length());
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
     * Determines whether a code meaning element is still active, based on its
     * from and to validity dates. Useful for deactivating deprecated codes,
     * e.g. like postal code 6484 was at the end of 2022.
     */
    private static Boolean testValidity(KodeverkResponse.Meaning meaning) {
        Date today = Date.today();
        return meaning.gyldigFra <= today && today <= meaning.gyldigTil;
    }

    /**
     * extracts foo, bar, baz, ... from the meanings, and stores them in a
     * Common_Code__c structure. the _meanings_ json will look like the
     * structure below. if the unique key (foobar, ...) already exists in the
     * database, just update it, otherwise create a new instance.
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
    private static Common_Code__c[] getCodesFromMeaningMap(String codeSet, Map<String, KodeverkResponse.Meaning[]> meaningsByCode) {
        Map<String, Common_Code__c> updatedCodeByKey = new Map<String, Common_Code__c>();
        Map<String, Common_Code__c> existingCodeByKey = getExistingCodeMap(codeSet);
        for (String key : meaningsByCode.keySet()) {
            KodeverkResponse.Meaning[] meanings = meaningsByCode.get(key);
            // loop through the codes associated with this key. a key may
            // contain multiple codes, each with its own gyldigFra and
            // gyldigTil, ordered by date. i.e., loop through a list where the
            // last element will tell us whether or not the code is still
            // active.
            for (KodeverkResponse.Meaning meaning : meanings) {
                String name = trimName(meaning.beskrivelser.get(LANGUAGE).term);
                Boolean isValid = testValidity(meaning);
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
}
