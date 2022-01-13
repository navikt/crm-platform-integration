public with sharing class NorgKodeverkUtils {
    public static Map<String, Integer> pushPostcodesToCommonCodes() {
        Map<String, String> postcodes = getPostcodes();
        List<Common_Code__c> toUpdate = new List<Common_Code__c>();
        List<Common_Code__c> toDelete = new List<Common_Code__c>();
        List<Common_Code__c> toInsert = new List<Common_Code__c>();
        for (List<Common_Code__c> ccs : [
            SELECT Id, CRM_Active__c, CRM_Code__c, CRM_Code_Set__c, Name
            FROM Common_Code__c
            WHERE CRM_Code_Set__c = 'Postnummer'
        ]) {
            for (Common_Code__c cc : ccs) {
                if (postcodes.containsKey(cc.CRM_Code__c)) {
                    String pcName = postcodes.get(cc.CRM_Code__c);
                    if (pcName != cc.Name) {
                        cc.Name = pcName;
                        toUpdate.add(cc);
                    }
                    postcodes.remove(cc.CRM_Code__c);
                } else {
                    toDelete.add(cc);
                }
            }
        }
        for (String key : postcodes.keySet()) {
            toInsert.add(
                new Common_Code__c(
                    CRM_Active__c = true,
                    Name = postcodes.get(key),
                    CRM_Code_Set__c = 'Postnummer',
                    CRM_Code__c = key
                )
            );
        }
        delete toDelete;
        update toUpdate;
        insert toInsert;

        Map<String, Integer> m = new Map<String, Integer>{
            'Insert' => toInsert.size(),
            'Update' => toUpdate.size(),
            'Delete' => toDelete.size()
        };
        return m;
    }
    public static Map<String, String> getPostcodes() {
        List<NorgKodeverk> codesList = getCodes(NorgService.KodeverkNavn.Postnummer);
        Map<String, String> postCodes = new Map<String, String>();

        for (NorgKodeverk code : codesList) {
            postCodes.put(code.navn, code.term);
        }
        return postCodes;
    }
    public static List<NorgKodeverk> getCodes(NorgService.KodeverkNavn codeName) {
        HttpResponse response = NorgService.getCodes(codeName);
        if (response.getStatusCode() == 200) {
            return (List<NorgKodeverk>) JSON.deserialize(response.getBody(), List<NorgKodeverk>.class);
        }
        String errorRef = logError(response, 'Error from NorgService.getCodes: ' + codeName.name());
        throw new NorgKodeverkException(
            'Kunne ikke hente enhets informasjon fra NORG2. Referanse til feil: ' + errorRef
        );
    }
    private static String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.httpError(message, resp, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }
    public class NorgKodeverkException extends Exception {
    }
}
