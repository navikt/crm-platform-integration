public with sharing class NKS_SkattekortWrapper {
    @AuraEnabled
    @TestVisible
    public String utstedtDato { get; private set; }

    @AuraEnabled
    @TestVisible
    public Integer inntektsaar { get; private set; }

    @AuraEnabled
    @TestVisible
    public String resultatForSkattekort { get; private set; }

    @AuraEnabled
    @TestVisible
    public List<Forskuddstrekk> forskuddstrekkList { get; private set; }

    @AuraEnabled
    @TestVisible
    public List<String> tilleggsopplysningList { get; private set; }

    public class Frikort {
        @AuraEnabled
        @TestVisible
        public Integer frikortBeloep { get; private set; }
    }

    public class Prosentkort {
        @AuraEnabled
        @TestVisible
        public Double prosentSats { get; private set; }

        @AuraEnabled
        @TestVisible
        public Double antallMndForTrekk { get; private set; }
    }

    public class Trekktabell {
        @AuraEnabled
        @TestVisible
        public String tabell { get; private set; }

        @AuraEnabled
        @TestVisible
        public Double prosentSats { get; private set; }

        @AuraEnabled
        @TestVisible
        public Double antallMndForTrekk { get; private set; }
    }

    public class Forskuddstrekk {
        @AuraEnabled
        @TestVisible
        public String trekkode { get; private set; }

        @AuraEnabled
        @TestVisible
        public Frikort frikort { get; private set; }

        @AuraEnabled
        @TestVisible
        public Prosentkort prosentkort { get; private set; }

        @AuraEnabled
        @TestVisible
        public Trekktabell trekktabell { get; private set; }
    }
}