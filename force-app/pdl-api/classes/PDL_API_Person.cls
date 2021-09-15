public with sharing class PDL_API_Person{
    
    public PDL_API_Person() {

    }

    public static String getAktoerId(PDL_API_Response response){
        if(response?.data?.hentIdenter?.identer == null) return null;
        for(PDL_API_Response.PDL_API_IdentInformasjon ident : response.data.hentIdenter.identer){
            if(ident.gruppe == PDL_API_Response.PDL_API_IdentGruppe.AKTORID && 
                ident.historisk == false || ident.historisk)
        }
    }
}
