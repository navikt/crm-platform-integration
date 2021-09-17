public with sharing class PDL_Error {

    public String message{ get;}
    public PDL_ErrorLocation[] locations{ get;}
    public String[] path{ get;}
    public PDL_ErrorExtensions extensions{ get;}

    public PDL_Error() {

    }
}
