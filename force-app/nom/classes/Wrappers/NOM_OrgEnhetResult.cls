// prettier-ignore
public with sharing class NOM_OrgEnhetResult {
    @TestVisible public NOM_ResultCode code { private set; public get; }
    @TestVisible public String id { private set; public get; }
    @TestVisible public String nomId { private set; public get; }
    @TestVisible public String orgNiv { private set; public get; }
    @TestVisible public NOM_OrgEnhet orgEnhet { private set; public get; }

    public NOM_OrgEnhetResult() {}
}
