public with sharing class NKS_SkattekortWrapper {
    @AuraEnabled
    @TestVisible
    public List<SkattekortListe> skattekortListe { get; private set; }
    
    public class SkattekortListe {
        @AuraEnabled
        @TestVisible
        public List<Arbeidsgiver> arbeidsgiver { get; private set; }
    }
    
    public class Arbeidsgiver {
        @AuraEnabled
        @TestVisible
        public List<Arbeidstaker> arbeidstaker { get; private set; }
        @AuraEnabled
        @TestVisible
        public Arbeidsgiveridentifikator arbeidsgiveridentifikator { get; private set; }
    }

    public class Arbeidstaker {
        @AuraEnabled
        @TestVisible
        public String inntektsaar { get; private set; }
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
        public String tilleggsopplysning { get; private set; }
    }

    public class Forskuddstrekk {}

    public class Skattekort {
        @AuraEnabled
        @TestVisible
        public String inntektsaar { get; private set; }
        @AuraEnabled
        @TestVisible
        public String utstedtDato { get; private set; }
        @AuraEnabled
        @TestVisible
        public String skattekortidentifikator { get; private set; }
        @AuraEnabled
        @TestVisible
        public String forskuddstrekk { get; private set; }
    }

    public class Arbeidsgiveridentifikator {
        @AuraEnabled
        @TestVisible
        public String organisasjonsnummer { get; private set; }
        @AuraEnabled
        @TestVisible
        public String personidentifikator { get; private set; }
    }
}