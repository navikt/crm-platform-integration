public inherited sharing class KafkaEnhetFilter implements IKafkaMessageFilter {
    @TestVisible
    public static Boolean bypassFilter = false;
    public static Integer maxOrganizationsAllowed = 50000;
    private static List<Id> recordIdsToDelete = new List<Id>();
    private static Boolean isSandbox = [
        SELECT Id, InstanceName, IsSandbox, Name, OrganizationType
        FROM Organization
        LIMIT 1
    ]
    .IsSandbox;

    public Set<Id> filterMessages(List<KafkaMessage__c> messages) {
        // Return full set of message ids if we are in a production environment
        if (!isSandbox)
            return new Map<Id, SObject>(messages).keySet();
        // Otherwise filter messages by type and based on number of Employer Account records already in the environment
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
        if (messages.size() == 0)
            return messages;
        List<KafkaMessage__c> messagesToKeep = new List<KafkaMessage__c>();
        // If we will be at record limit after this insert
        // we check if the accounts already exist in the org
        System.debug('xxx');
        System.debug(messages.size());
        Integer accCount = [
            SELECT COUNT()
            FROM Account
            WHERE
                RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                    .get('Employer')
                    .getRecordTypeId()
        ];
        System.debug(accCount);
        System.debug(maxOrganizationsAllowed);
        if (
            [
                SELECT COUNT()
                FROM Account
                WHERE
                    RecordTypeId = :Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
                        .get('Employer')
                        .getRecordTypeId()
            ] > maxOrganizationsAllowed - messages.size()
        ) {
            Map<String, KafkaMessage__c> msgByOrgNumber = new Map<String, KafkaMessage__c>();
            Set<String> existingOrgNumbers = new Set<String>();
            for (KafkaMessage__c msg : messages) {
                msgByOrgNumber.put(msg.CRM_Key__c.left(9), msg);
            }

            for (Account acc : [
                SELECT Id, INT_OrganizationNumber__c
                FROM Account
                WHERE INT_OrganizationNumber__c IN :msgByOrgNumber.keySet()
            ]) {
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
