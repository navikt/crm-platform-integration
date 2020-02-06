public inherited sharing class KafkaEnhetFilter implements IKafkaMessageFilter {

    @TestVisible
    public static Boolean bypassFilter = false;

    private static List<Id> recordIdsToDelete = new List<Id>();

    // This is the pre insert filter
    // We check for UNDERENHET only
    // We check for total records < 50k, but not if they already exists (orgid exists for an account)
    // We do NOT check if hash is different (it will be different for ALL accounts on insert)
    // We check hash in async
    // For initial, hash will always be diff and inserted in async
    // For new ones, they are exempt from total record check if they already exist and then hash checked in async


    // 1. Hash updated, new name, org nr exists - should update
    // 2. Hash updated, new name, org nr doesnt exist - shouldnt insert

    public Set<Id> filterMessages(List<KafkaMessage__c> messages) {
        List<KafkaMessage__c> filteredMessages = new List<KafkaMessage__c>();
        filteredMessages = filterByType(messages);
        filteredMessages = filterByTotalRecordCount(filteredMessages);

        if (recordIdsToDelete.size() > 0) {
            Database.delete(recordIdsToDelete);
            Database.emptyRecycleBin(recordIdsToDelete);
        }


        return new Map<Id, KafkaMessage__c>(filteredMessages).keySet();
    }

    private List<KafkaMessage__c> filterByType(List<KafkaMessage__c> messages) {
        List<KafkaMessage__c> filteredMessages = new List<KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            if (msg.CRM_Key__c.contains('UNDERENHET')) {
                filteredMessages.add(msg);
            } else {
                recordIdsToDelete.add(msg.Id);
            }
        }

        return filteredMessages;
    }

    private List<KafkaMessage__c> filterByTotalRecordCount(List<KafkaMessage__c> messages) {
        if(messages.size() == 0) return messages;
        List<KafkaMessage__c> messagesToKeep = new List<KafkaMessage__c>();
        // If we will be at record limit after this insert
        // we check if the accounts already exist in the org
        if ([SELECT COUNT() FROM Account] > 49799) {
            Map<String, KafkaMessage__c> msgByOrgNumber = new Map<String, KafkaMessage__c>();
            Set<String> existingOrgNumbers = new Set<String>();
            for (KafkaMessage__c msg : messages) {
                msgByOrgNumber.put(msg.CRM_Key__c.left(9), msg);
            }

            for (Account acc : [SELECT Id, INT_OrganizationNumber__c FROM Account WHERE INT_OrganizationNumber__c IN :msgByOrgNumber.keySet()]) {
                existingOrgNumbers.add(acc.INT_OrganizationNumber__c);
            }
            for (String orgNr : msgByOrgNumber.keySet()) {
                if (existingOrgNumbers.contains(orgNr)) {
                    messagesToKeep.add(msgByOrgNumber.get(orgNr));
                } else {
                    recordIdsToDelete.add(msgByOrgNumber.get(orgNr).Id);
                }
            }

        } else {
            messagesToKeep.addAll(messages);
        }
        return messagesToKeep;
    }


}
