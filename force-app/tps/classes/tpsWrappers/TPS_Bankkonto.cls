public inherited sharing class TPS_Bankkonto {
    @AuraEnabled
    @TestVisible
    public BankkontonummerNorge bankkontoNorge { get; private set; }
    @AuraEnabled
    @TestVisible
    public BankkontonummerUtland bankkontoUtland { get; private set; }
    @AuraEnabled
    @TestVisible
    public String endretAv { get; private set; }
    @AuraEnabled
    @TestVisible
    public Date endretTidspunkt { get; private set; }
    @AuraEnabled
    @TestVisible
    public String endringsType { get; private set; }

    public class BankkontonummerNorge {
        @AuraEnabled
        @TestVisible
        public String bankkontoummer { get; private set; }
        @AuraEnabled
        @TestVisible
        public String banknavn { get; private set; }
    }

    public class BankkontonummerUtland {
        @AuraEnabled
        @TestVisible
        public UstrukturertAdresse bankadresse { get; private set; }
        @AuraEnabled
        @TestVisible
        public String bankkode { get; private set; }
        @AuraEnabled
        @TestVisible
        public String bankkontoummer { get; private set; }
        @AuraEnabled
        @TestVisible
        public String banknavn { get; private set; }
        @AuraEnabled
        @TestVisible
        public String landkode { get; private set; }
        @AuraEnabled
        @TestVisible
        public String swift { get; private set; }
        @AuraEnabled
        @TestVisible
        public String valuta { get; private set; }
    }

    public class UstrukturertAdresse {
        @AuraEnabled
        @TestVisible
        public String adresselinje1 { get; private set; }
        @AuraEnabled
        @TestVisible
        public String adresselinje2 { get; private set; }
        @AuraEnabled
        @TestVisible
        public String adresselinje3 { get; private set; }
        @AuraEnabled
        @TestVisible
        public String adresselinje4 { get; private set; }
        @AuraEnabled
        @TestVisible
        public String landkode { get; private set; }
        @AuraEnabled
        @TestVisible
        public String postnr { get; private set; }
        @AuraEnabled
        @TestVisible
        public String poststed { get; private set; }
    }
}
