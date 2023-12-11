/**
 * @description
 * CV-wrapper class
 */
public with sharing class CV {
    @AuraEnabled
    public Datetime sistEndret;
    @AuraEnabled
    public Boolean synligForArbeidsgiver;
    @AuraEnabled
    public Boolean sistEndretAvNav;
    @AuraEnabled
    public String sammendrag;
    @AuraEnabled
    public List<CV_Arbeidserfaring> arbeidserfaring;
    @AuraEnabled
    public List<CV_Utdanning> utdanning;
    @AuraEnabled
    public List<CV_Fagdokumentasjon> fagdokumentasjoner;
    @AuraEnabled
    public List<CV_Godkjenning> godkjenninger;
    @AuraEnabled
    public List<CV_AnnenErfaring> annenErfaring;
    @AuraEnabled
    public List<CV_Forerkort> forerkort;
    @AuraEnabled
    public List<CV_Kurs> kurs;
    @AuraEnabled
    public List<CV_Sertifikat> sertifikater;
    @AuraEnabled
    public List<CV_Sertifikat> andreGodkjenninger;
    @AuraEnabled
    public List<CV_Sprak> sprak;
    @AuraEnabled
    public CV_Jobbprofil jobbprofil;
}
