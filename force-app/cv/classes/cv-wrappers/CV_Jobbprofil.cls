public with sharing class CV_Jobbprofil {
    @AuraEnabled
    public Datetime sistEndret;
    @AuraEnabled
    public List<CV_Yrke> onsketYrke;
    @AuraEnabled
    public List<CV_Arbeidssted> onsketArbeidssted;
    @AuraEnabled
    public List<CV_Ansettelsesform> onsketAnsettelsesform;
    @AuraEnabled
    public List<CV_Arbeidstidsordning> onsketArbeidstidsordning;
    @AuraEnabled
    public CV_HeltidDeltid heltidDeltid;
    @AuraEnabled
    public List<CV_Kompetanse> kompetanse;
}
