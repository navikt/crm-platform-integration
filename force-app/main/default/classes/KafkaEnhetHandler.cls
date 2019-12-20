public inherited sharing class KafkaEnhetHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<KafkaEnhet> organizations = new List<KafkaEnhet>();
        for (KafkaMessage__c msg : messages) {
            // Parse JSON payload
            try {
//                List<KafkaEnhet> parsedList = KafkaEnhet.parse(msg.CRM_Payload__c);
//                organizations.addAll(parsedList);
                msg.CRM_IsProcessed__c = true; // TODO: Move this down to actual processing
            } catch (Exception e) {
                msg.CRM_Error__c = e.getMessage();
            }
        }


        for (KafkaEnhet org : organizations) {
            System.debug(org);
        }

        upsert transformAccounts(organizations) INT_Ident__c;
    }

    private List<Account> transformAccounts(List<KafkaEnhet> organizations) {
        List<Account> accounts = new List<Account>();
        for (KafkaEnhet org : organizations) {
            Account acc = new Account();
            acc.INT_Ident__c = org.organisasjonsnummer;
            acc.INT_IdentType__c = 'ORGNR';
            acc.Name = org.navn;
            acc.BillingCity = org.beliggenhetsadresse.poststed;
            acc.BillingPostalCode = org.beliggenhetsadresse.postnummer;
            acc.BillingCountry = org.beliggenhetsadresse.land;
            acc.BillingState = org.beliggenhetsadresse.kommune;
            acc.INT_MunicipalityNumber__c = org.beliggenhetsadresse.kommunenummer;
            accounts.add(acc);
        }
        return accounts;
    }

}







