public with sharing class PDL_Metadata {
    public String opplysningsId { get; }
    public String master { get; }
    public PDL_Endring[] endringer { get; }
    @TestVisible
    public Boolean historisk { get; }
}
