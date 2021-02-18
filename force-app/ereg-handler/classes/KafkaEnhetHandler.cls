public without sharing class KafkaEnhetHandler implements IKafkaMessageConsumer {
    private final Schema.RecordTypeInfo EMPLOYER_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Employer');

    public void processMessages(List<KafkaMessage__c> messages) {
        // Only process messages where the hash code has changed for a given org number
        List<KafkaMessage__c> filteredMessages = filterByHashCode(messages);

        // Decode and parse payload, map to Account sObject structure
        List<Account> accountsToUpsert = new List<Account>();
        for (KafkaMessage__c msg : filteredMessages) {
            try {
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                Account accountToUpsert = transformAccount(msg);
                accountsToUpsert.add(accountToUpsert);
            } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
            }
        }

        // Upsert on organization number (unique on database level)
        upsert accountsToUpsert Account.fields.INT_OrganizationNumber__c;
        // Populate Account ParentIds based on relationship between child INT_ParentOrganizationNumber__c and parent INT_OrganizationNumber fields
        populateParentRelationship(accountsToUpsert);
    }

    private List<KafkaMessage__c> filterByHashCode(List<KafkaMessage__c> messages) {
        Map<String, KafkaMessage__c> messagesByOrgNumberMap = new Map<String, KafkaMessage__c>();
        Map<String, String> newHashCodeByOrgNumberMap = new Map<String, String>();
        for (KafkaMessage__c msg : messages) {
            newHashCodeByOrgNumberMap.put(extractOrgNumber(msg.CRM_Key__c), extractHashCode(msg.CRM_Key__c));
            messagesByOrgNumberMap.put(extractOrgNumber(msg.CRM_Key__c), msg);
        }

        Map<String, String> existingHashCodeByOrgNumberMap = new Map<String, String>();
        for (Account acc : [
            SELECT Id, INT_HashCode__c, INT_OrganizationNumber__c
            FROM Account
            WHERE INT_OrganizationNumber__c IN :newHashCodeByOrgNumberMap.keySet()
        ]) {
            existingHashCodeByOrgNumberMap.put(acc.INT_OrganizationNumber__c, acc.INT_HashCode__c);
        }

        List<KafkaMessage__c> filteredMessages = new List<KafkaMessage__c>();
        for (String orgNumber : newHashCodeByOrgNumberMap.keySet()) {
            if (newHashCodeByOrgNumberMap.get(orgNumber) != existingHashCodeByOrgNumberMap.get(orgNumber)) {
                filteredMessages.add(messagesByOrgNumberMap.get(orgNumber));
            } else {
                messagesByOrgNumberMap.get(orgNumber).CRM_Status__c = KafkaMessageService.STATUS_PROCESSED; // Do nothing, but mark the record as processed (updated by calling class)
            }
        }
        return filteredMessages;
    }

    // Pass a set of ids for accounts that are are new or where parent org is changed
    private void populateParentRelationship(List<Account> upsertedAccounts) {
        Set<String> parentOrgNumbers = new Set<String>();
        for (Account acc : upsertedAccounts) {
            parentOrgNumbers.add(acc.INT_ParentOrganizationNumber__c);
        }

        Map<String, Id> parentAccountIdsByOrganizationNumber = new Map<String, Id>();
        for (Account acc : [
            SELECT Id, INT_OrganizationNumber__c
            FROM Account
            WHERE
                RecordTypeId = :EMPLOYER_RECORD_TYPE.getRecordTypeId()
                AND INT_OrganizationNumber__c != NULL
                AND INT_OrganizationNumber__c IN :parentOrgNumbers
        ]) {
            parentAccountIdsByOrganizationNumber.put(acc.INT_OrganizationNumber__c, acc.Id);
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (Account acc : upsertedAccounts) {
            if (parentAccountIdsByOrganizationNumber.containsKey(acc.INT_ParentOrganizationNumber__c)) {
                acc.ParentId = parentAccountIdsByOrganizationNumber.get(acc.INT_ParentOrganizationNumber__c);
                accountsToUpdate.add(acc);
            }
        }
        update accountsToUpdate;
    }

    public Account transformAccount(KafkaMessage__c message) {
        // Decode the Base64-encoded JSON-payload and parse it using a predefined Apex class
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaEnhet org = KafkaEnhet.parse(decodedValue);

        // Build account according to the mapping specification defined at https://confluence.adeo.no/display/PTC/Enhetsregisteret
        Account acc = new Account();
        // Set record type assuming a record type named "Employer" is found
        if (this.EMPLOYER_RECORD_TYPE != null) {
            acc.RecordTypeId = this.EMPLOYER_RECORD_TYPE.getRecordTypeId();
        }
        // Set owner id if set in custom settings
        if (KafkaIntegrationCustomSetting.integrationUserId != null) {
            acc.OwnerId = KafkaIntegrationCustomSetting.integrationUserId;
        }
        // System fields
        acc.INT_HashCode__c = extractHashCode(message.CRM_Key__c);

        // Optional for Enheter, mandatory for Underenheter
        acc.INT_ParentOrganizationNumber__c = org.overordnetEnhet;
        // Mandatory fields for both Enheter and Underenheter
        acc.NumberOfEmployees = org.antallAnsatte;
        acc.Name = org.navn;
        acc.INT_OrganizationNumber__c = org.organisasjonsnummer;
        acc.INT_OrganizationalStructure__c = org.organisasjonsform.kode;
        acc.INT_OrganizationalStructureDesc__c = org.organisasjonsform.beskrivelse;
        acc.INT_RegDateEreg__c = Date.valueOf(org.registreringsdatoEnhetsregisteret);
        // Mandatory fields for Enheter
        acc.INT_IsBankrupt__c = org.konkurs != null && org.konkurs == true ? true : false;
        acc.INT_IsInLiquidation__c = org.underAvvikling != null & org.underAvvikling == true ? true : false;
        acc.INT_IsInForcedSettlementOrResolution__c = org.underTvangsavviklingEllerTvangsopplosning != null &
            org.underTvangsavviklingEllerTvangsopplosning == true
            ? true
            : false;
        // Optional fields for both Enheter and Underenheter
        acc.Website = org.hjemmeside != null ? org.hjemmeside.left(255) : null;
        acc.INT_IndustryCode__c = org.Naeringskode1 != null ? org.Naeringskode1.kode : null;
        acc.INT_Industry__c = org.Naeringskode1 != null ? org.Naeringskode1.beskrivelse : null;
        // Optional fields for enheter
        if (org.forretningsadresse != null) {
            acc.ShippingStreet = org.forretningsadresse.adresse.size() > 0 ? org.forretningsadresse.adresse[0] : null;
            acc.ShippingPostalCode = org.forretningsadresse.postnummer;
            acc.ShippingCity = org.forretningsadresse.poststed;
            acc.ShippingCountry = org.forretningsadresse.land;
            acc.ShippingState = org.forretningsadresse.kommune;
            acc.INT_MunicipalityNumber__c = org.forretningsadresse.kommunenummer;
            acc.INT_RegionNumber__c = org.forretningsadresse.kommunenummer != null
                ? org.forretningsadresse.kommunenummer.left(2)
                : null;
        }
        // Optional fields for Underenheter
        if (org.beliggenhetsadresse != null) {
            acc.ShippingStreet = org.beliggenhetsadresse.adresse.size() > 0 ? org.beliggenhetsadresse.adresse[0] : null;
            acc.ShippingPostalCode = org.beliggenhetsadresse.postnummer;
            acc.ShippingCity = org.beliggenhetsadresse.poststed;
            acc.ShippingCountry = org.beliggenhetsadresse.land;
            acc.ShippingState = org.beliggenhetsadresse.kommune;
            acc.INT_MunicipalityNumber__c = org.beliggenhetsadresse.kommunenummer;
            acc.INT_RegionNumber__c = org.beliggenhetsadresse.kommunenummer != null
                ? org.beliggenhetsadresse.kommunenummer.left(2)
                : null;
        }
        return acc;
    }

    // Extract hash from CRM_Key__c field (the value after the last occurance of #)
    private String extractHashCode(String keyValue) {
        Integer keyLength = keyValue.length();
        Integer hashStartPosition = keyValue.lastIndexOf('#') + 1;
        return keyValue.mid(hashStartPosition, keyLength);
    }

    // Extract Organization Number from CRM_Key__c field (the first 9 digits)
    public String extractOrgNumber(String keyValue) {
        if (!String.isEmpty(keyValue)) {
            return keyValue.left(9);
        } else {
            return null;
        }
    }
}
