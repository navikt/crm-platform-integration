public with sharing class NKS_SkattekortWrapper {
    @AuraEnabled
    @TestVisible
    public String navn { get; private set; }

    @AuraEnabled
    @TestVisible
    public List<Arbeidsgiver> arbeidsgiver { get; private set; }

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
        public Integer inntektsaar { get; private set; }
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

    public class Arbeidsgiveridentifikator {
        @AuraEnabled
        @TestVisible
        public String organisasjonsnummer { get; private set; }
        @AuraEnabled
        @TestVisible
        public String personidentifikator { get; private set; }
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
        public String frikortbeloep { get; private set; }
        @AuraEnabled
        @TestVisible
        public String tabelltype { get; private set; }
        @AuraEnabled
        @TestVisible
        public String tabellnummer { get; private set; }
        @AuraEnabled
        @TestVisible
        public Double prosentsats { get; private set; }
        @AuraEnabled
        @TestVisible
        public Double antallMaanederForTrekk { get; private set; }
    }
}
