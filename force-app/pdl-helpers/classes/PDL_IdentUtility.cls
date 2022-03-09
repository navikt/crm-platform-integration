public with sharing class PDL_IdentUtility {
    public static String getAktorId(List<PDL_IdentInformasjon> identer) {
        return getIdentsFromList(identer).actorId;
    }

    public static String getAktorId(PDL_API_Response person) {
        return getIdByType(person, PDL_IdentGruppe.AKTORID);
    }

    public static String getFnr(List<PDL_IdentInformasjon> identer) {
        return getIdentsFromList(identer).fnr;
    }

    public static String getFNR(PDL_API_Response person) {
        return getIdByType(person, PDL_IdentType.FNR);
    }

    public static String getDnr(List<PDL_IdentInformasjon> identer) {
        return getIdentsFromList(identer).dnr;
    }

    public static String getDNR(PDL_API_Response person) {
        return getIdByType(person, PDL_IdentType.DNR);
    }

    public static String getNpid(List<PDL_IdentInformasjon> identer) {
        return getIdentsFromList(identer).npid;
    }

    public static String getNPID(PDL_API_Response person) {
        return getIdByType(person, PDL_IdentGruppe.NPID);
    }

    // prettier-ignore
    public static PersonIdent getIdentsFromList(List<PDL_IdentInformasjon> identer) {
        PersonIdent pIdent = new PersonIdent();
        for (PDL_IdentInformasjon ident : identer) {
            if(String.isBlank(ident.ident)){continue;}
            if (ident.gruppe == PDL_IdentGruppe.FOLKEREGISTERIDENT && ident.historisk == true) {
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
    public static Boolean isDNR(PDL_IdentInformasjon ident) {
        return ident.gruppe == PDL_IdentGruppe.FOLKEREGISTERIDENT && typeOfId(ident.ident) == PDL_IdentType.DNR;
    }

    private static PDL_IdentType typeOfId(String ident) {
        if (ident == null) {
            return null;
        }
        return (4 <= Integer.valueOf(ident.left(1))) ? PDL_IdentType.DNR : PDL_IdentType.FNR;
    }

    /**
     * Extracts current Ident from PDL_API_Response.data.hentIdenter of specified type.
     * @param person person data from pdl
     * @param type  PDL_IdentGruppe.AKTORID,PDL_IdentGruppe.FOLKEREGISTERIDENT,PDL_IdentGruppe.NPID
     * @return String value of ident or null if ident not found
     */
    public static String getIdByType(PDL_API_Response person, PDL_IdentGruppe type) {
        if (person?.data?.hentIdenter?.identer == null)
            return null;
        for (PDL_IdentInformasjon ident : person.data.hentIdenter.identer) {
            if (ident.gruppe == type && (!ident.historisk || ident.historisk == null)) {
                return ident.ident;
            }
        }
        return null;
    }

    /**
     * Extracts current Ident from PDL_API_Response.data.hentPerson of specified type.
     * If missing there, then trying to extraxt from PDL_API.data.hentIdenter
     * @param person person data from pdl
     * @param type PDL_IdentType.DNR,PDL_IdentType.FNR
     * @return String value of ident or null if ident not found
     */
    public static String getIdByType(PDL_API_Response person, PDL_IdentType type) {
        if (person?.data?.hentPerson?.folkeregisteridentifikator != null) {
            for (PDL_FolkeregisterIdentifikator ident : person.data.hentPerson.folkeregisteridentifikator) {
                if (ident.identifikasjonsnummer == null)
                    continue;
                if (ident.metadata?.historisk == true || ident.status == PDL_IdentStatus.OPPHOERT)
                    continue;
                if ((ident.type == type) || (ident.type == null && typeOfId(ident.identifikasjonsnummer) == type)) {
                    return ident.identifikasjonsnummer;
                }
            }
        }
        String fIdent = getIdByType(person, PDL_IdentGruppe.FOLKEREGISTERIDENT);
        if (fIdent == null)
            return null;
        if (typeOfId(fIdent) == type)
            return fIdent;
        return null;
    }

    public class PersonIdent {
        public String actorId;
        public String fnr;
        public String dnr;
        public String npid;
    }
}
