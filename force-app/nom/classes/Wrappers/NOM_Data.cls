//prettier-ignore
public with sharing class NOM_Data {
    @TestVisible public NOM_Ressurs ressurs { private set; public get; }
    @TestVisible public List<NOM_RessursResult> ressurser { private set; public get; }
    @TestVisible public NOM_OrgEnhet orgEnhet { private set; public get; }
    @TestVisible public List<NOM_OrgEnhetResult> orgEnheter { private set; public get; }
}
