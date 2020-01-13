public inherited sharing class KafkaEnhetHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        Map<Id, KafkaMessage__c> messagesByIds = new Map<Id, KafkaMessage__c>();
        for (KafkaMessage__c msg : messages) {
            messagesByIds.put(msg.Id, msg);
        }

        Map<Id, List<Account>> accountsToUpdateByKafkaMessageId  = new Map<Id, List<Account>>();
        for (KafkaMessage__c msg : messages) {
            try {
                msg.CRM_IsProcessed__c = true;
                accountsToUpdateByKafkaMessageId.put(msg.Id, transformAccounts(KafkaEnhet.parse(msg.CRM_Value__c)));
            } catch (Exception e) {
                msg.CRM_Error__c = e.getMessage();
            }
        }

        // Update collection of Accounts related to each Kafka Message independently in order to
        // allow partial successes across Kafka Message records but not within a record.
        List<KafkaMessage__c> messagesToUpdateWithDMLError = new List<KafkaMessage__c>();
        for (Id msgId : accountsToUpdateByKafkaMessageId.keySet()) {
            // Keep a buffer of dml statements in order to allow the async framework to clean up
            if( (Limits.getLimitDmlStatements() - Limits.getDmlStatements()) > 50) {
                upsert accountsToUpdateByKafkaMessageId.get(msgId) INT_OrganizationNumber__c;
            } else {
                messagesByIds.get(msgId).CRM_Error__c = 'Max number of DML statements reached for one async job';
            }
        }
    }

    private List<Account> transformAccounts(List<KafkaEnhet> organizations) {
        List<Account> accounts = new List<Account>();
        for (KafkaEnhet org : organizations) {
            Account acc = new Account();
            acc.INT_IdentType__c = 'ORGNR';
            acc.Name = org.navn;
            acc.INT_OrganizationNumber__c = org.organisasjonsnummer;
            acc.INT_ParentOrganizationNumber__c = org.overordnetEnhet;
            acc.INT_OrganizationalStructureDesc__c = org.organisasjonsform.beskrivelse;
            acc.INT_OrganizationalStructure__c = org.organisasjonsform.kode;
            acc.INT_IndustryCode__c = org.Naeringskode1.kode;
            acc.INT_Industry__c = org.Naeringskode1.beskrivelse;
            acc.INT_MunicipalityNumber__c = org.beliggenhetsadresse.kommunenummer;
            acc.INT_IsNavEmployee__c = false;
            acc.INT_RegDateEreg__c = Date.valueOf(org.registreringsdatoEnhetsregisteret);
            acc.NumberOfEmployees = org.antallAnsatte;
            acc.ShippingCity = org.beliggenhetsadresse.poststed;
            acc.ShippingPostalCode = org.beliggenhetsadresse.postnummer;
            acc.ShippingCountry = org.beliggenhetsadresse.land;
            acc.ShippingState = org.beliggenhetsadresse.kommune;
            acc.ShippingStreet = org.beliggenhetsadresse.adresse.isEmpty() ? '' : org.beliggenhetsadresse.adresse[0];
            // TODO: Verify mapping for these fields
//            acc.INT_IsBankrupt__c = '';
//            acc.INT_IsInForcedSettlementOrResolution__c = '';
//            acc.INT_IsInLiquidation__c = '';
            accounts.add(acc);

        }
        return accounts;
    }

}







