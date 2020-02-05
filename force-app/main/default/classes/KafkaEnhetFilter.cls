public inherited sharing class KafkaEnhetFilter implements IKafkaMessageFilter {

    @TestVisible
    public static Boolean bypassSandboxFilter = false;

    public Set<Id> filterMessages(List<KafkaMessage__c> messages) {
        List<KafkaMessage__c> filteredMessages = new List<KafkaMessage__c>();
        filteredMessages = filterBySandboxCriteria(messages);
        return new Map<Id, KafkaMessage__c>(filteredMessages).keySet();
    }

    private List<KafkaMessage__c> filterBySandboxCriteria(List<KafkaMessage__c> messages) {
        List<KafkaMessage__c> filteredMessages = new List<KafkaMessage__c>();
        List<KafkaMessage__c> messagesToDelete = new List<KafkaMessage__c>();
        // Perform filtering if we are in a sandbox environment
        if (!bypassSandboxFilter && [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox) {
            // Don't perform any handling of messages if we are already over 90k Accounts
            if ([SELECT COUNT() FROM Account] > 100000) {
                messagesToDelete.addAll(messages);
            } else {
                // If we are below record # treshold, only process records of of type 'BEDR'
                for (KafkaMessage__c msg : messages) {
                    Account acc = new KafkaEnhetHandler().transformAccount(msg);
                    if (acc.INT_OrganizationalStructure__c != 'BEDR') {
                        messagesToDelete.add(msg);
                    } else {
                        filteredMessages.add(msg);
                    }
                }
            }
        } else {
            // Return entire list if we are not in a sandbox environment
            return messages;
        }

        List<Id> recordIdsToDelete = new List<Id>(new Map<Id, SObject>(messagesToDelete).keySet());
        if (recordIdsToDelete.size() > 0) {
            Database.delete(recordIdsToDelete);
            Database.emptyRecycleBin(recordIdsToDelete);
        }
        return filteredMessages;
    }

}
