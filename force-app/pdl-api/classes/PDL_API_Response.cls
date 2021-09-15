public with sharing class PDL_API_Response {
    public PDL_API_Data data{ get;}
    public PDL_API_Error[] errors{ get;}
    
    private PDL_API_Response() {
        
    }
    
    public static PDL_API_Response fromHttpResponse(HttpResponse response){

        if (response.getStatusCode() == 200) { 
            PDL_API_Response r = 
            (PDL_API_Response) System.JSON.deserialize(response.getBody(),
                                                                 PDL_API_Response.class);
            return r;  
        }

        String errorRef = logError(response, 'Error from PdlService.');
        throw new HentPersonResponseException('Kunne ikke hente data fra PDL: ' + errorRef);
    }

    private static String logError(HttpResponse resp, String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.httpError(message, resp, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }

    private static String logError(String message) {
        String errorRef = '';

        LoggerUtility logger = new LoggerUtility();
        logger.error(message, null, null);
        errorRef = logger.peek().UUID__c;
        logger.publish();

        return errorRef;
    }
    public class PDL_API_Navn{
        public String fornavn{ get;}
        public String mellomnavn{ get;}
        public String etternavn{ get;}
        public String forkortetNavn{ get;}
        public PDL_API_OriginaltNavn originaltNavn{ get;}
        public Date gyldigFraOgMed{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_OriginaltNavn{
        public String fornavn{ get;}
        public String mellomnavn{ get;}
        public String etternavn{ get;}
    }
    public class PDL_API_Personnavn{
        public String fornavn{ get;}
        public String mellomnavn{ get;}
        public String etternavn{ get;}
    }
    
    
    
    public class PDL_API_Identitetsgrunnlag{
        public PDL_API_Identitetsgrunnlagsstatus status{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public enum PDL_API_Identitetsgrunnlagsstatus {
        IKKE_KONTROLLERT,
        KONTROLLERT,
        INGEN_STATUS
    }
    public class PDL_API_Foreldreansvar{
        public String ansvar{ get;}
        public String ansvarlig{ get;}
        public String ansvarssubjekt{ get;}
        public PDL_API_RelatertBiPerson ansvarligUtenIdentifikator{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_RelatertBiPerson{
        public PDL_API_Personnavn navn{ get;} 
        public Date foedselsdato{ get;}
        public String statsborgerskap{ get;}
        public PDL_API_KjoennType kjoenn{ get;} 
    }
    public class PDL_API_Error{
        public String message{ get;}
        public PDL_API_ErrorLocation[] locations{ get;}
        public String[] path{ get;}
        public PDL_API_ErrorExtensions extensions{ get;}
    }
    public class PDL_API_ErrorLocation{
        public Integer line{ get;}
        public Integer column{ get;}
    }
    public class PDL_API_ErrorExtensions{
        public String code{ get;}
        public Map<String, String> details{ get;}
        public String classification{ get;}
    }
    public class PDL_API_Folkeregistermetadata{
        public Datetime ajourholdstidspunkt{ get;}
        public Datetime gyldighetstidspunkt{ get;}
        public Datetime opphoerstidspunkt{ get;}
        public String kilde{ get;}
        public String aarsak{ get;}
        public Integer sekvens{ get;}
    }
    public class PDL_API_Telefonnummer{
        public String landskode{ get;}
        public String nummer{ get;}
        public Integer prioritet{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_TilrettelagtKommunikasjon{
        public PDL_API_Tolk talespraaktolk{ get;}
        public PDL_API_Tolk tegnspraaktolk{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Tolk{
        public String spraak{ get;}
    }
    public enum PDL_API_FullmaktsRolle{
        FULLMAKTSGIVER,
        FULLMEKTIG
    }
    public class PDL_API_Fullmakt{
        public String motpartsPersonident{ get;}
        public PDL_API_FullmaktsRolle motpartsRolle{ get;}
        public String[] omraader{ get;}
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Folkeregisteridentifikator {
        public String identifikasjonsnummer{ get;}
        public String status{ get;}
        public String type{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_SikkerhetstiltakKontaktperson{
        public String personident{ get;}
        public String enhet{ get;}
    }
    public class PDL_API_Sikkerhetstiltak{
        public String tiltakstype{ get;}
        public String beskrivelse{ get;}
        public PDL_API_SikkerhetstiltakKontaktperson kontaktperson{ get;}
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Statsborgerskap{
        public String land{ get;}
        public Date bekreftelsesdato{ get;}
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Opphold{
        public PDL_API_Oppholdstillatelse type{ get;}
        public Date oppholdFra{ get;}
        public Date oppholdTil{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public enum PDL_API_Oppholdstillatelse{
        MIDLERTIDIG,
        PERMANENT,
        OPPLYSNING_MANGLER
    }
    public class PDL_API_Sivilstand {
        public PDL_API_Sivilstandstype type{ get;}
        public Date gyldigFraOgMed{ get;}
        public String relatertVedSivilstand{ get;}
        public Date bekreftelsesdato{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    
    public enum PDL_API_Sivilstandstype{
        UOPPGITT,
        UGIFT,
        GIFT,
        ENKE_ELLER_ENKEMANN,
        SKILT,
        SEPARERT,
        REGISTRERT_PARTNER,
        SEPARERT_PARTNER,
        SKILT_PARTNER,
        GJENLEVENDE_PARTNER
    }
    public class PDL_API_InnflyttingTilNorge{
        public String fraflyttingsland{ get;}
        public String fraflyttingsstedIUtlandet{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_UtflyttingFraNorge{
        public String tilflyttingsland{ get;}
        public String tilflyttingsstedIUtlandet{ get;}
        public String utflyttingsdato{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_VergeEllerFullmektig{
        public PDL_API_Personnavn navn{ get;}
        public String motpartsPersonident{ get;}
        public String omfang{ get;}
        public Boolean omfangetErInnenPersonligOmraade{ get;}
    }
    public class PDL_API_VergemaalEllerFremtidsfullmakt {
        public String type{ get;}
        public String embete{ get;}
        public PDL_API_VergeEllerFullmektig vergeEllerFullmektig{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Metadata{
        public String opplysningsId{ get;}
        public String master{ get;}
        public PDL_API_Endring[] endringer{ get;}
        public Boolean historisk{ get;}
    }
    public class PDL_API_Endring{
        public PDL_API_Endringstype type{ get;}
        public Datetime registrert{ get;}
        public String registrertAv{ get;}
        public String systemkilde{ get;}
        public String kilde{ get;}
    }
    public enum PDL_API_Endringstype{
        OPPRETT,
        KORRIGER,
        OPPHOER
    }
    public class MissingExpectedDataException extends Exception{}
    public class HentPersonResponseException extends Exception{}
}
