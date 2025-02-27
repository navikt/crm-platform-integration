public with sharing class NOM_RessursResult {
    @TestVisible public NOM_ResultCode code { private set; public get; }
    @TestVisible public String id { private set; public get; }
    @TestVisible public NOM_Ressurs ressurs { private set; public get; }

    public NOM_RessursResult() {}
}