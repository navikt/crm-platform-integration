public with sharing class NKS_SkattekortWrapper {
    @AuraEnabled
    @TestVisible
    public List<Arbeidstaker> data { get; private set; }
    
    @AuraEnabled
    @TestVisible
    public String message { get; private set; }

    public class Arbeidstaker {
        @AuraEnabled
        @TestVisible
        public Integer inntektsaar { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public String arbeidstakeridentifikator { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public String resultatPaaForespoersel { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public Skattekort skattekort { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public List<String> tilleggsopplysning { get; private set; }
    }

    public class Skattekort {
        @AuraEnabled
        @TestVisible
        public String utstedtDato { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public Integer skattekortidentifikator { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public List<Forskuddstrekk> forskuddstrekk { get; private set; }
    }

    public class Forskuddstrekk {
        @AuraEnabled
        @TestVisible
        public String type { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public String trekkode { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public Double prosentsats { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public Double frikortbeloep { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public String tabellnummer { get; private set; }
        
        @AuraEnabled
        @TestVisible
        public Double antallMaanederForTrekk { get; private set; }
    }
}
