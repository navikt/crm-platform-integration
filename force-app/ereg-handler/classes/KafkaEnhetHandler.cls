/**
 * @description Class that process Kafka messages and update Accounts. 
 Only messages where the hash code has changed for a given org number is processed. Hash is decoded to json payload and parsed to Account sObject structure.
 Accounts are upserted with organization number as key (unique on database level).
 Parent Account Ids are maintained based on relationship between child INT_ParentOrganizationNumber__c and parent INT_OrganizationNumber fields.
 */
public without sharing class KafkaEnhetHandler implements IKafkaMessageConsumer {
    private static final Schema.RecordTypeInfo EMPLOYER_RECORD_TYPE = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName()
        .get('Employer');

    private LoggerUtility logger;

    /**
     * @description Process Kafka messages and update Accounts.
     * @param messages List of Kafka message records
     */
    public void processMessages(List<KafkaMessage__c> messages) {
        logger = new LoggerUtility();
        List<KafkaMessage__c> filteredMessages = filterByHashCode(messages);

        List<Account> accountsToUpsert = new List<Account>();
        for (KafkaMessage__c msg : filteredMessages) {
            try {
                msg.CRM_Status__c = KafkaMessageService.STATUS_PROCESSED;
                Account accountToUpsert = transformAccount(msg);
                accountsToUpsert.add(accountToUpsert);
            } catch (Exception e) {
                msg.CRM_ErrorMessage__c = e.getMessage() + ' (' + e.getLineNumber() + ')';
                msg.CRM_Status__c = KafkaMessageService.STATUS_ERROR;
                logException(e);
            }
        }

        // Upsert on organization number (unique on database level)
        try {
            upsert accountsToUpsert Account.fields.INT_OrganizationNumber__c;
        } catch (Exception e) {
            logException(e);
        }
        // Populate Account ParentIds based on relationship between child INT_ParentOrganizationNumber__c and parent INT_OrganizationNumber fields
        populateParentRelationship(accountsToUpsert);

        logger.publish();
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
            filteredMessages.add(messagesByOrgNumberMap.get(orgNumber));
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

    /**
     * @description Extract encoded message from kafka message record and map to Account.
     * @param message Kafka message record
     * @return Account record
     */
    public Account transformAccount(KafkaMessage__c message) {
        // Decode the Base64-encoded JSON-payload and parse it using a predefined Apex class
        String decodedValue = KafkaMessageUtils.base64ULSafeDecode(message.CRM_Value__c).toString();
        KafkaEnhet org = KafkaEnhet.parse(decodedValue);

        // Build account according to the mapping specification defined at https://confluence.adeo.no/display/PTC/Enhetsregisteret
        Account acc = new Account();
        // Set record type assuming a record type named "Employer" is found
        if (EMPLOYER_RECORD_TYPE != null) {
            acc.RecordTypeId = EMPLOYER_RECORD_TYPE.getRecordTypeId();
        }

        // System fields
        acc.INT_HashCode__c = extractHashCode(message.CRM_Key__c);

        // Optional for Enheter, mandatory for Underenheter
        acc.INT_ParentOrganizationNumber__c = org.overordnetEnhet;
        // Mandatory fields for both Enheter and Underenheter
        acc.INT_HasEmployees__c = org.harRegistrertAntallAnsatte != null ? org.harRegistrertAntallAnsatte : acc.INT_HasEmployees__c;
        acc.NumberOfEmployees = (Integer) org.antallAnsatte;
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
        acc.INT_IndustryCode2__c = org.Naeringskode2 != null ? org.Naeringskode2.kode : null;
        acc.INT_Industry2__c = org.Naeringskode2 != null ? org.Naeringskode2.beskrivelse : null;
        acc.INT_IndustryCode3__c = org.Naeringskode3 != null ? org.Naeringskode3.kode : null;
        acc.INT_Industry3__c = org.Naeringskode3 != null ? org.Naeringskode3.beskrivelse : null;
        acc.INT_Sector__c = org.institusjonellSektorkode != null ? org.institusjonellSektorkode.beskrivelse : null;
        acc.INT_SectorCode__c = org.institusjonellSektorkode != null ? org.institusjonellSektorkode.kode : null;
        acc.INT_EmployerEmail__c = org.epostadresse;
        acc.INT_EmployerMobilePhone__c = org.mobil;
        acc.Phone = org.telefon;
        acc.CRM_NumberOfEmployeesGrouped__c = getNumberOfEmployeesGroup(org.antallAnsatte, org.harRegistrertAntallAnsatte);

        // Reset if employers are falsely set to deleted
        acc.IsDeletedEmployer__c = false;
        acc.EmployerDeletedDate__c = null;

        // Optional fields for enheter and underenheter
        if (org.postadresse != null) {
            //If size of address array is 2, add line break and merge values. Ignore values after 2, due to max lines on address fields in Salesforce
            if (org.postadresse.adresse != null && org.postadresse.adresse.size() >= 2) {
                acc.BillingStreet = org.postadresse.adresse[0] + '\n' + org.postadresse.adresse[1];
            } else if (org.postadresse.adresse != null && org.postadresse.adresse.size() == 1) {
                acc.BillingStreet = org.postadresse.adresse[0];
            } else {
                acc.BillingStreet = null;
            }
            acc.BillingPostalCode = org.postadresse.postnummer;
            acc.BillingCity = org.postadresse.poststed;
            acc.BillingCountry = org.postadresse.land;
            acc.BillingState = org.postadresse.kommune;
            acc.INT_MunicipalityNumber__c = org.postadresse.kommunenummer;
            acc.INT_RegionNumber__c = org.postadresse.kommunenummer != null
                ? org.postadresse.kommunenummer.left(2)
                : null;
        }

        // Optional fields for enheter
        if (org.forretningsadresse != null) {
            //If size of address array is 2, add line break and merge values. Ignore values after 2, due to max lines on address fields in Salesforce
            if (org.forretningsadresse.adresse != null && org.forretningsadresse.adresse.size() >= 2) {
                acc.ShippingStreet = org.forretningsadresse.adresse[0] + '\n' + org.forretningsadresse.adresse[1];
            } else if (org.forretningsadresse.adresse != null && org.forretningsadresse.adresse.size() == 1) {
                acc.ShippingStreet = org.forretningsadresse.adresse[0];
            } else {
                acc.ShippingStreet = null;
            }
            acc.ShippingPostalCode = org.forretningsadresse.postnummer;
            acc.ShippingCity = org.forretningsadresse.poststed;
            acc.ShippingCountry = org.forretningsadresse.land;
            acc.ShippingState = org.forretningsadresse.kommune;
            acc.INT_MunicipalityNumber__c = org.forretningsadresse.kommunenummer;
            acc.INT_RegionNumber__c = org.forretningsadresse.kommunenummer != null
                ? org.forretningsadresse.kommunenummer.left(2)
                : null;
        }
        // Optional fields for underenheter
        if (org.beliggenhetsadresse != null) {
            //If size of address array is 2, add line break and merge values. Ignore values after 2, due to max lines on address fields in Salesforce
            if (org.beliggenhetsadresse.adresse != null && org.beliggenhetsadresse.adresse.size() >= 2) {
                acc.ShippingStreet = org.beliggenhetsadresse.adresse[0] + '\n' + org.beliggenhetsadresse.adresse[1];
            } else if (org.beliggenhetsadresse.adresse != null && org.beliggenhetsadresse.adresse.size() == 1) {
                acc.ShippingStreet = org.beliggenhetsadresse.adresse[0];
            } else {
                acc.ShippingStreet = null;
            }
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

    /**
     * @description Extracts Organization Number from CRM_Key__c field (the first 9 digits)
     * @param keyValue Field CRM_Key__c on KafkaMessage__c
     * @return Organisation number or nulll
     */
    public String extractOrgNumber(String keyValue) {
        if (!String.isEmpty(keyValue)) {
            return keyValue.left(9);
        } else {
            return null;
        }
    }

    private void logException(Exception e) {
        logger.logMessage(
            LoggerUtility.LogLevel.Error, // LogLevel logLevel
            '', // String referenceId
            '', // String referenceInfo
            e.getMessage(), // String logMessage,
            '', //  String payLoad,
            null, // long timeTaken,
            CRM_ApplicationDomain.Domain.POAB // Domain domain
        );
    }


     /**
     * @description Method that returns a group value of employees based on the number of employees registered by a company
     *
     * @author Andre Colle <andre.colle@nav.no>
     * @since 2025-01-08 Created.
     *
     * @param numberOfEmployees Contains the number of employees registered by the employer
     * @param hasRegisteredEmployees Contains boolean value that indicates if the employer har registered any employees
     * @return Group of number of employees.
     */
    private static String getNumberOfEmployeesGroup(Integer numberOfEmployees, Boolean hasRegisteredEmployees) {
        if (numberOfEmployees <= 4 && hasRegisteredEmployees == true) {
            return '1-4';
        } else if (numberOfEmployees >= 5 && numberOfEmployees <= 10) {
            return '5-10';
        } else if (numberOfEmployees >= 11 && numberOfEmployees <= 25) {
            return '11-25';
        } else if (numberOfEmployees >= 26 && numberOfEmployees <= 50) {
            return '26-50';
        } else if (numberOfEmployees >= 51 && numberOfEmployees <= 100) {
            return '51-100';
        } else if (numberOfEmployees >= 101 && numberOfEmployees <= 250) {
            return '101-250';
        } else if (numberOfEmployees >= 251 && numberOfEmployees <= 500) {
            return '251-500';
        } else if (numberOfEmployees >= 501 && numberOfEmployees <= 1000) {
            return '501-1000';
        } else if (numberOfEmployees >= 1001) {
            return '1000+';
        } else {
            return null;
        }
    }
}
