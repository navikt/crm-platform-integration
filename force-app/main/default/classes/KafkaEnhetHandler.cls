public inherited sharing class KafkaEnhetHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        List<KafkaEnhet> organizations = new List<KafkaEnhet>();
        for (KafkaMessage__c msg : messages) {
            // Parse JSON payload
            try {
                List<KafkaEnhet> parsedList = KafkaEnhet.parse(msg.CRM_Value__c);
                organizations.addAll(parsedList);
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
            acc.INT_IdentType__c = 'ORGNR';
            acc.Name = org.navn;
            acc.INT_OrganizationNumber__c = org.organisasjonsnummer;
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







