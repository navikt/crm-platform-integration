public with sharing class PDL_API_HentPersonResponse {
    public PDL_API_HentPersonData data{ get;}
    public PDL_API_Error[] errors{ get;}
    
    private PDL_API_HentPersonResponse() {

    }
    public static PDL_API_HentPersonResponse fromHttpResponse(HttpResponse response){

        if (response.getStatusCode() == 200) { 
            PDL_API_HentPersonResponse r = 
            (PDL_API_HentPersonResponse) System.JSON.deserialize(response.getBody(),
                                                                 PDL_API_HentPersonResponse.class);
            return r;  
        }

        String errorRef = logError(response, 'Error from PdlService.');
        throw new HentPersonResponseException('Kunne ikke hente data fra PDL: ' + errorRef);
    }

    public Boolean isEmpty(){
        return (data == null) && (errors == null);
    }
    public Boolean hasData(){
        return data != null;
    }
    public Boolean hasError(){
        return (errors != null) && !errors.isEmpty();
    }
    public String getError(){
        return System.JSON.serializePretty(errors, true);
    }
    public String getFornavn(){
        return this.data?.hentPerson?.navn[0]?.fornavn;
    }
    private Boolean hasForeldreansvar(){
        mustHaveForeldreanvar();
        if (this.data.hentPerson.foreldreansvar.isEmpty())
            return false;
        return true;
    }
    public Boolean isAnsvarlig(){
        if(!hasForeldreansvar())
            return false;
        for(PDL_API_Foreldreansvar fa : this.data.hentPerson.foreldreansvar){
            if (!String.isEmpty(fa.ansvarssubjekt))
                return true;
        }
        return false;
    }
    private void mustHaveForeldreanvar(){
        // we expecting the field exists in response if it was queried
        if (this.data?.hentPerson?.foreldreansvar == null) throw new MissingExpectedDataException('Unexpected: foreldreansvar==NULL');
    }
    public String[] getAnsvarssubjektList(){
        String[] ansvarssubjektList = new List<String>();
        if (!hasForeldreansvar()) return ansvarssubjektList;

        for(PDL_API_Foreldreansvar fa : this.data.hentPerson.foreldreansvar){
            if (!String.isEmpty(fa.ansvarssubjekt))
                ansvarssubjektList.add(fa.ansvarssubjekt);
        }

        return ansvarssubjektList;
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

    public class PDL_API_HentPersonData{
        public PDL_API_Person hentPerson { get;}
    }
    public class PDL_API_Person{
        public PDL_API_Adressebeskyttelse[] adressebeskyttelse{ get;}
        public PDL_API_Bostedsadresse[] bostedsadresse{ get;}
        public PDL_API_DeltBosted[] deltBosted{ get;}
        public PDL_API_DoedfoedtBarn[] doedfoedtBarn{ get;}
        public PDL_API_Doedsfall[] doedsfall{ get;}
        public PDL_API_FalskIdentitet falskIdentitet{ get;}
        public PDL_API_Foedsel[] foedsel{ get;}
        public PDL_API_Folkeregisteridentifikator[] folkeregisteridentifikator{ get;}
        public PDL_API_Folkeregisterpersonstatus[] folkeregisterpersonstatus{ get;}
        public PDL_API_ForelderBarnRelasjon[] forelderBarnRelasjon{ get;}
        public PDL_API_Foreldreansvar[] foreldreansvar{ get;}
        public PDL_API_Fullmakt[] fullmakt{ get;}
        public PDL_API_Identitetsgrunnlag[] identitetsgrunnlag{ get;}
        public PDL_API_Kjoenn[] kjoenn{ get;}
        public PDL_API_Kontaktadresse[] kontaktadresse{ get;}
        public PDL_API_KontaktinformasjonForDoedsbo[] kontaktinformasjonForDoedsbo{ get;}
        public PDL_API_Navn[] navn{ get;}
        public PDL_API_Opphold[] opphold{ get;}
        public PDL_API_Oppholdsadresse[] oppholdsadresse{ get;}
        public PDL_API_Sikkerhetstiltak[] sikkerhetstiltak{ get;}
        public PDL_API_Sivilstand[] sivilstand{ get;}
        public PDL_API_Statsborgerskap[] statsborgerskap{ get;}
        public PDL_API_Telefonnummer[] telefonnummer{ get;}
        public PDL_API_TilrettelagtKommunikasjon[] tilrettelagtKommunikasjon{ get;}
        public PDL_API_UtenlandskIdentifikasjonsnummer[] utenlandskIdentifikasjonsnummer{ get;}
        public PDL_API_InnflyttingTilNorge[] innflyttingTilNorge{ get;}
        public PDL_API_UtflyttingFraNorge[] utflyttingFraNorge{ get;}
        public PDL_API_VergemaalEllerFremtidsfullmakt[] vergemaalEllerFremtidsfullmakt{ get;}
    }
    public class PDL_API_DeltBosted{
        public Date startdatoForKontrakt{ get;}
        public Date sluttdatoForKontrakt{ get;}
    
        public String coAdressenavn{ get;}
        public PDL_API_Vegadresse vegadresse{ get;}
        public PDL_API_Matrikkeladresse matrikkeladresse{ get;}
        public PDL_API_UtenlandskAdresse utenlandskAdresse{ get;}
        public PDL_API_UkjentBosted ukjentBosted{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Bostedsadresse{
        public Date angittFlyttedato{ get;}
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
    
        public String coAdressenavn{ get;}
        public PDL_API_Vegadresse vegadresse{ get;}
        public PDL_API_Matrikkeladresse matrikkeladresse{ get;}
        public PDL_API_UtenlandskAdresse utenlandskAdresse{ get;}
        public PDL_API_UkjentBosted ukjentBosted{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Oppholdsadresse{
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
    
        public String coAdressenavn{ get;}
        public PDL_API_UtenlandskAdresse utenlandskAdresse{ get;}
        public PDL_API_Vegadresse vegadresse{ get;}
        public PDL_API_Matrikkeladresse matrikkeladresse{ get;}
        public String oppholdAnnetSted{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Kontaktadresse {
        public Date gyldigFraOgMed{ get;}
        public Date gyldigTilOgMed{ get;}
        public PDL_API_KontaktadresseType type{ get;}
    
        public String coAdressenavn{ get;}
        public PDL_API_Postboksadresse postboksadresse{ get;}
        public PDL_API_Vegadresse vegadresse{ get;}
        public PDL_API_PostadresseIFrittFormat postadresseIFrittFormat{ get;}
        public PDL_API_UtenlandskAdresse utenlandskAdresse{ get;}
        public PDL_API_UtenlandskAdresseIFrittFormat utenlandskAdresseIFrittFormat{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    
    public enum PDL_API_KontaktadresseType {
        Innland,
        Utland
    }
    public class PDL_API_Vegadresse{
        public Long matrikkelId{ get;}
        public String husnummer{ get;}
        public String husbokstav{ get;}
        public String bruksenhetsnummer{ get;}
        public String adressenavn{ get;}
        public String kommunenummer{ get;}
        public String bydelsnummer{ get;}
        public String tilleggsnavn{ get;}
        public String postnummer{ get;}
        public PDL_API_Koordinater koordinater{ get;}
    }
    public class PDL_API_Matrikkeladresse{
        public Long matrikkelId{ get;}
        public String bruksenhetsnummer{ get;}
        public String tilleggsnavn{ get;}
        public String postnummer{ get;}
        public String kommunenummer{ get;}
        public PDL_API_Koordinater koordinater{ get;}
    }
    public class PDL_API_UkjentBosted{
        public String bostedskommune{ get;}
    }
    public class PDL_API_UtenlandskAdresse{
        public String adressenavnNummer{ get;}
        public String bygningEtasjeLeilighet{ get;}
        public String postboksNummerNavn{ get;}
        public String postkode{ get;}
        public String bySted{ get;}
        public String regionDistriktOmraade{ get;}
        public String landkode{ get;}
    }
    public class PDL_API_UtenlandskAdresseIFrittFormat {
        public String adresselinje1{ get;}
        public String adresselinje2{ get;}
        public String adresselinje3{ get;}
        public String postkode{ get;}
        public String byEllerStedsnavn{ get;}
        public String landkode{ get;}
    }
    
    public class PDL_API_Postboksadresse {
        public String postbokseier{ get;}
        public String postboks{ get;}
        public String postnummer{ get;}
    }
    
    public class PDL_API_PostadresseIFrittFormat {
        public String adresselinje1{ get;}
        public String adresselinje2{ get;}
        public String adresselinje3{ get;}
        public String postnummer{ get;}
    }
    public class PDL_API_Koordinater{
        public Double x{ get;}
        public Double y{ get;}
        public Double z{ get;}
        public Integer kvalitet{ get;}
    }
    public class PDL_API_FalskIdentitet {
        public Boolean erFalsk{ get;}
        public String rettIdentitetVedIdentifikasjonsnummer{ get;}
        public Boolean rettIdentitetErUkjent{ get;}
        public PDL_API_FalskIdentitetIdentifiserendeInformasjon rettIdentitetVedOpplysninger{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    
    public class PDL_API_FalskIdentitetIdentifiserendeInformasjon {
        public PDL_API_Personnavn personnavn{ get;}
        public Date foedselsdato{ get;}
        public String[] statsborgerskap{ get;}
        public PDL_API_KjoennType kjoenn{ get;}
    }
    public class PDL_API_KontaktinformasjonForDoedsbo{
        public PDL_API_KontaktinformasjonForDoedsboSkifteform skifteform{ get;}
        public Date attestutstedelsesdato{ get;}
        public PDL_API_KontaktinformasjonForDoedsboPersonSomKontakt personSomKontakt{ get;}
        public PDL_API_KontaktinformasjonForDoedsboAdvokatSomKontakt advokatSomKontakt{ get;}
        public PDL_API_KontaktinformasjonForDoedsboOrganisasjonSomKontakt organisasjonSomKontakt{ get;}
        public PDL_API_KontaktinformasjonForDoedsboAdresse adresse{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public enum PDL_API_KontaktinformasjonForDoedsboSkifteform{
        OFFENTLIG,
        ANNET
    }
    public class PDL_API_KontaktinformasjonForDoedsboPersonSomKontakt{
        public Date foedselsdato{ get;}
        public PDL_API_Personnavn personnavn{ get;}
        public String identifikasjonsnummer{ get;}
    }
    public class PDL_API_KontaktinformasjonForDoedsboAdvokatSomKontakt{
        public PDL_API_Personnavn personnavn{ get;}
        public String organisasjonsnavn{ get;}
        public String organisasjonsnummer{ get;}
    }
    public class PDL_API_KontaktinformasjonForDoedsboOrganisasjonSomKontakt{
        public PDL_API_Personnavn kontaktperson{ get;}
        public String organisasjonsnavn{ get;}
        public String organisasjonsnummer{ get;}
    }
    public class PDL_API_KontaktinformasjonForDoedsboAdresse{
        public String adresselinje1{ get;}
        public String adresselinje2{ get;}
        public String poststedsnavn{ get;}
        public String postnummer{ get;}
        public String landkode{ get;}
    }
    public class PDL_API_UtenlandskIdentifikasjonsnummer{
        public String identifikasjonsnummer{ get;}
        public String utstederland{ get;}
        public Boolean opphoert{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Adressebeskyttelse{
        public PDL_API_AdressebeskyttelseGradering gradering{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public enum PDL_API_AdressebeskyttelseGradering{
        STRENGT_FORTROLIG_UTLAND,
        STRENGT_FORTROLIG,
        FORTROLIG,
        UGRADERT
    }
    public class PDL_API_Foedsel{
        public Integer foedselsaar{ get;}
        public Date foedselsdato{ get;}
        public String foedeland{ get;}
        public String foedested{ get;}
        public String foedekommune{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Kjoenn{
        public PDL_API_KjoennType kjoenn{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_Doedsfall{
        public Date doedsdato{ get;}
        public PDL_API_Metadata metadata{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
    }
    public class PDL_API_ForelderBarnRelasjon{
        public String relatertPersonsIdent{ get;}
        public PDL_API_ForelderBarnRelasjonRolle relatertPersonsRolle{ get;}
        public PDL_API_ForelderBarnRelasjonRolle minRolleForPerson{ get;}
    
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public class PDL_API_DoedfoedtBarn{
        public Date dato{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
    }
    public enum PDL_API_ForelderBarnRelasjonRolle {
        BARN,
        MOR,
        FAR,
        MEDMOR
    }
    public class PDL_API_Folkeregisterpersonstatus {
        public String status{ get;}
        public String forenkletStatus{ get;}
        public PDL_API_Folkeregistermetadata folkeregistermetadata{ get;}
        public PDL_API_Metadata metadata{ get;}
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
    public enum PDL_API_KjoennType{
        MANN, KVINNE, UKJENT
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
        public Date ajourholdstidspunkt{ get;}
        public Date gyldighetstidspunkt{ get;}
        public Date opphoerstidspunkt{ get;}
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
        public Date registrert{ get;}
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
