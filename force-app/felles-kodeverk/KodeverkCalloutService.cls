/**
 * Fetches codes from Felles Kodeverk (FKV). Can either just return the response
 * JSON (getCodes) or also store them as Common_Code__c records (storeCodes,
 * storeAllCodes). In the latter cases, active codes are inserted or updated,
 * and inactive codes are skipped over (if not already in database) or updated
 * (if already in database).
 */
public class KodeverkCalloutService implements Schedulable {

    /**
     * instantly gets codes from a given kodeverk and returns a list of
     * appropriately mapped Common_Code__c instances. TODO: consider if this is
     * too slow, and returning the KodeverkResponse instances instead would be
     * sensible.
     */
    public static Common_Code__c[] getCodes(String label) {
        return KodeverkHelper.getCodesFromMeaningMap(label, KodeverkHelper.getMeaningMap(label));
    }

    /**
     * updates the codes given. note that spaces are allowed in common code
     * names, so use the Label rather than the DeveloperName
     */
    public static void storeCodes(Set<String> labels) {
        for (String label : labels) {
            System.enqueueJob(new KodeverkQueueable(label));
        }
    }

    /**
     * updates all codesets.
     */
    public static void storeAllCodes() {
        Kodeverk_Codeset__mdt[] codeSetEntries = [SELECT Label FROM Kodeverk_Codeset__mdt];
        Set<String> labels = new Set<String>();
        for (Kodeverk_Codeset__mdt m : codeSetEntries) {
            labels.add(m.Label);
        }
        storeCodes(labels);
    }

    /**
     * allows scheduling a full update.
     */
    public static void execute(SchedulableContext sc) {
        storeAllCodes();
    }
}
