public with sharing class PDL_IdentUtility {
    public static String getAktorId(List<PDL_Ident> identer) {
        return getIdentsFromList(identer).actorId;
    }

    public static String getFnr(List<PDL_Ident> identer) {
        return getIdentsFromList(identer).fnr;
    }

    public static String getDnr(List<PDL_Ident> identer) {
        return getIdentsFromList(identer).dnr;
    }

    public static String getNpid(List<PDL_Ident> identer) {
        return getIdentsFromList(identer).npid;
    }
    // prettier-ignore
    public static PersonIdent getIdentsFromList(List<PDL_Ident> identer) {
        PersonIdent pIdent = new PersonIdent();
        for (PDL_Ident ident : identer) {
            if (ident.historisk) {
                if (isDNR(ident) && String.isBlank(pIdent.dnr)) {
                    pIdent.dnr = ident.ident;
                }
            } else {
                switch on ident.gruppe {
                    when FOLKEREGISTERIDENT {
                        if (isDNR(ident)) {
                            pIdent.dnr = ident.ident;
                        } else {
                            pIdent.fnr = ident.ident;
                        }
                        continue;
                    }
                    when NPID {
                        pIdent.npid = ident.ident;
                        continue;
                    }
                    when AKTORID {
                        pIdent.actorId = ident.ident;
                        continue;
                    }
                }
            }
        }

        return pIdent;
    }
    public static Boolean isDNR(PDL_Ident ident) {
        return ident.gruppe == PDL_Ident.IdentGruppe.FOLKEREGISTERIDENT && 4 <= Integer.valueOf(ident.ident.left(1));
    }

    public class PersonIdent {
        public String actorId;
        public String fnr;
        public String dnr;
        public String npid;
    }
}
