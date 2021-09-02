public with sharing class PDL_API_HentPersonResponse {
    PDL_API_HentPersonData data;
    PDL_API_Error[] errors;
    
    private PDL_API_HentPersonResponse() {

    }
    public static PDL_API_HentPersonResponse makeFromJson(String jsonString){
        return 
            (PDL_API_HentPersonResponse) 
                System.JSON.deserialize(jsonString, PDL_API_HentPersonResponse.class);
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

    class PDL_API_HentPersonData{
        PDL_API_Person hentPerson;
    }
    class PDL_API_Person{
        PDL_API_Adressebeskyttelse[] adressebeskyttelse;
        PDL_API_Bostedsadresse[] bostedsadresse;
        PDL_API_DeltBosted[] deltBosted;
        PDL_API_DoedfoedtBarn[] doedfoedtBarn;
        PDL_API_Doedsfall[] doedsfall;
        PDL_API_FalskIdentitet falskIdentitet;
        PDL_API_Foedsel[] foedsel;
        PDL_API_Folkeregisteridentifikator[] folkeregisteridentifikator;
        PDL_API_Folkeregisterpersonstatus[] folkeregisterpersonstatus;
        PDL_API_ForelderBarnRelasjon[] forelderBarnRelasjon;
        PDL_API_Foreldreansvar[] foreldreansvar;
        PDL_API_Fullmakt[] fullmakt;
        PDL_API_Identitetsgrunnlag[] identitetsgrunnlag;
        PDL_API_Kjoenn[] kjoenn;
        PDL_API_Kontaktadresse[] kontaktadresse;
        PDL_API_KontaktinformasjonForDoedsbo[] kontaktinformasjonForDoedsbo;
        PDL_API_Navn[] navn;
        PDL_API_Opphold[] opphold;
        PDL_API_Oppholdsadresse[] oppholdsadresse;
        PDL_API_Sikkerhetstiltak[] sikkerhetstiltak;
        PDL_API_Sivilstand[] sivilstand;
        PDL_API_Statsborgerskap[] statsborgerskap;
        PDL_API_Telefonnummer[] telefonnummer;
        PDL_API_TilrettelagtKommunikasjon[] tilrettelagtKommunikasjon;
        PDL_API_UtenlandskIdentifikasjonsnummer[] utenlandskIdentifikasjonsnummer;
        PDL_API_InnflyttingTilNorge[] innflyttingTilNorge;
        PDL_API_UtflyttingFraNorge[] utflyttingFraNorge;
        PDL_API_VergemaalEllerFremtidsfullmakt[] vergemaalEllerFremtidsfullmakt;
    }
    class PDL_API_DeltBosted{
        Date startdatoForKontrakt;
        Date sluttdatoForKontrakt;
    
        String coAdressenavn;
        PDL_API_Vegadresse vegadresse;
        PDL_API_Matrikkeladresse matrikkeladresse;
        PDL_API_UtenlandskAdresse utenlandskAdresse;
        PDL_API_UkjentBosted ukjentBosted;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Bostedsadresse{
        Date angittFlyttedato;
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
    
        String coAdressenavn;
        PDL_API_Vegadresse vegadresse;
        PDL_API_Matrikkeladresse matrikkeladresse;
        PDL_API_UtenlandskAdresse utenlandskAdresse;
        PDL_API_UkjentBosted ukjentBosted;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Oppholdsadresse{
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
    
        String coAdressenavn;
        PDL_API_UtenlandskAdresse utenlandskAdresse;
        PDL_API_Vegadresse vegadresse;
        PDL_API_Matrikkeladresse matrikkeladresse;
        String oppholdAnnetSted;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Kontaktadresse {
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
        PDL_API_KontaktadresseType type;
    
        String coAdressenavn;
        PDL_API_Postboksadresse postboksadresse;
        PDL_API_Vegadresse vegadresse;
        PDL_API_PostadresseIFrittFormat postadresseIFrittFormat;
        PDL_API_UtenlandskAdresse utenlandskAdresse;
        PDL_API_UtenlandskAdresseIFrittFormat utenlandskAdresseIFrittFormat;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    
    enum PDL_API_KontaktadresseType {
        Innland,
        Utland
    }
    class PDL_API_Vegadresse{
        Long matrikkelId;
        String husnummer;
        String husbokstav;
        String bruksenhetsnummer;
        String adressenavn;
        String kommunenummer;
        String bydelsnummer;
        String tilleggsnavn;
        String postnummer;
        PDL_API_Koordinater koordinater;
    }
    class PDL_API_Matrikkeladresse{
        Long matrikkelId;
        String bruksenhetsnummer;
        String tilleggsnavn;
        String postnummer;
        String kommunenummer;
        PDL_API_Koordinater koordinater;
    }
    class PDL_API_UkjentBosted{
        String bostedskommune;
    }
    class PDL_API_UtenlandskAdresse{
        String adressenavnNummer;
        String bygningEtasjeLeilighet;
        String postboksNummerNavn;
        String postkode;
        String bySted;
        String regionDistriktOmraade;
        String landkode;
    }
    class PDL_API_UtenlandskAdresseIFrittFormat {
        String adresselinje1;
        String adresselinje2;
        String adresselinje3;
        String postkode;
        String byEllerStedsnavn;
        String landkode;
    }
    
    class PDL_API_Postboksadresse {
        String postbokseier;
        String postboks;
        String postnummer;
    }
    
    class PDL_API_PostadresseIFrittFormat {
        String adresselinje1;
        String adresselinje2;
        String adresselinje3;
        String postnummer;
    }
    class PDL_API_Koordinater{
        Double x;
        Double y;
        Double z;
        Integer kvalitet;
    }
    class PDL_API_FalskIdentitet {
        Boolean erFalsk;
        String rettIdentitetVedIdentifikasjonsnummer;
        Boolean rettIdentitetErUkjent;
        PDL_API_FalskIdentitetIdentifiserendeInformasjon rettIdentitetVedOpplysninger;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    
    class PDL_API_FalskIdentitetIdentifiserendeInformasjon {
        PDL_API_Personnavn personnavn;
        Date foedselsdato;
        String[] statsborgerskap;
        PDL_API_KjoennType kjoenn;
    }
    class PDL_API_KontaktinformasjonForDoedsbo{
        PDL_API_KontaktinformasjonForDoedsboSkifteform skifteform;
        Date attestutstedelsesdato;
        PDL_API_KontaktinformasjonForDoedsboPersonSomKontakt personSomKontakt;
        PDL_API_KontaktinformasjonForDoedsboAdvokatSomKontakt advokatSomKontakt;
        PDL_API_KontaktinformasjonForDoedsboOrganisasjonSomKontakt organisasjonSomKontakt;
        PDL_API_KontaktinformasjonForDoedsboAdresse adresse;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    enum PDL_API_KontaktinformasjonForDoedsboSkifteform{
        OFFENTLIG,
        ANNET
    }
    class PDL_API_KontaktinformasjonForDoedsboPersonSomKontakt{
        Date foedselsdato;
        PDL_API_Personnavn personnavn;
        String identifikasjonsnummer;
    }
    class PDL_API_KontaktinformasjonForDoedsboAdvokatSomKontakt{
        PDL_API_Personnavn personnavn;
        String organisasjonsnavn;
        String organisasjonsnummer;
    }
    class PDL_API_KontaktinformasjonForDoedsboOrganisasjonSomKontakt{
        PDL_API_Personnavn kontaktperson;
        String organisasjonsnavn;
        String organisasjonsnummer;
    }
    class PDL_API_KontaktinformasjonForDoedsboAdresse{
        String adresselinje1;
        String adresselinje2;
        String poststedsnavn;
        String postnummer;
        String landkode;
    }
    class PDL_API_UtenlandskIdentifikasjonsnummer{
        String identifikasjonsnummer;
        String utstederland;
        Boolean opphoert;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Adressebeskyttelse{
        PDL_API_AdressebeskyttelseGradering gradering;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    enum PDL_API_AdressebeskyttelseGradering{
        STRENGT_FORTROLIG_UTLAND,
        STRENGT_FORTROLIG,
        FORTROLIG,
        UGRADERT
    }
    class PDL_API_Foedsel{
        Integer foedselsaar;
        Date foedselsdato;
        String foedeland;
        String foedested;
        String foedekommune;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Kjoenn{
        PDL_API_KjoennType kjoenn;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Doedsfall{
        Date doedsdato;
        PDL_API_Metadata metadata;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
    }
    class PDL_API_ForelderBarnRelasjon{
        String relatertPersonsIdent;
        PDL_API_ForelderBarnRelasjonRolle relatertPersonsRolle;
        PDL_API_ForelderBarnRelasjonRolle minRolleForPerson;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_DoedfoedtBarn{
        Date dato;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    enum PDL_API_ForelderBarnRelasjonRolle {
        BARN,
        MOR,
        FAR,
        MEDMOR
    }
    class PDL_API_Folkeregisterpersonstatus {
        String status;
        String forenkletStatus;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Navn{
        String fornavn;
        String mellomnavn;
        String etternavn;
        String forkortetNavn;
        PDL_API_OriginaltNavn originaltNavn;
        Date gyldigFraOgMed;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_OriginaltNavn{
        String fornavn;
        String mellomnavn;
        String etternavn;
    }
    class PDL_API_Personnavn{
        String fornavn;
        String mellomnavn;
        String etternavn;
    }
    enum PDL_API_KjoennType{
        MANN, KVINNE, UKJENT
    }
    class PDL_API_Identitetsgrunnlag{
        PDL_API_Identitetsgrunnlagsstatus status;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    enum PDL_API_Identitetsgrunnlagsstatus {
        IKKE_KONTROLLERT,
        KONTROLLERT,
        INGEN_STATUS
    }
    class PDL_API_Foreldreansvar{
        String ansvar;
        String ansvarlig;
        String ansvarssubjekt;
        PDL_API_RelatertBiPerson ansvarligUtenIdentifikator;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_RelatertBiPerson{
        PDL_API_Personnavn navn; 
        Date foedselsdato;
        String statsborgerskap;
        PDL_API_KjoennType kjoenn; 
    }
    class PDL_API_Error{
        String message;
        PDL_API_ErrorLocation[] locations;
        String[] path;
        PDL_API_ErrorExtensions extensions;
    }
    class PDL_API_ErrorLocation{
        Integer line;
        Integer column;
    }
    class PDL_API_ErrorExtensions{
        String code;
        Map<String, String> details;
        String classification;
    }
    class PDL_API_Folkeregistermetadata{
        Date ajourholdstidspunkt;
        Date gyldighetstidspunkt;
        Date opphoerstidspunkt;
        String kilde;
        String aarsak;
        Integer sekvens;
    }
    class PDL_API_Telefonnummer{
        String landskode;
        String nummer;
        Integer prioritet;
        PDL_API_Metadata metadata;
    }
    class PDL_API_TilrettelagtKommunikasjon{
        PDL_API_Tolk talespraaktolk;
        PDL_API_Tolk tegnspraaktolk;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Tolk{
        String spraak;
    }
    enum PDL_API_FullmaktsRolle{
        FULLMAKTSGIVER,
        FULLMEKTIG
    }
    class PDL_API_Fullmakt{
        String motpartsPersonident;
        PDL_API_FullmaktsRolle motpartsRolle;
        String[] omraader;
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Folkeregisteridentifikator {
        String identifikasjonsnummer;
        String status;
        String type;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_SikkerhetstiltakKontaktperson{
        String personident;
        String enhet;
    }
    class PDL_API_Sikkerhetstiltak{
        String tiltakstype;
        String beskrivelse;
        PDL_API_SikkerhetstiltakKontaktperson kontaktperson;
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Statsborgerskap{
        String land;
        Date bekreftelsesdato;
        Date gyldigFraOgMed;
        Date gyldigTilOgMed;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Opphold{
        PDL_API_Oppholdstillatelse type;
        Date oppholdFra;
        Date oppholdTil;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    enum PDL_API_Oppholdstillatelse{
        MIDLERTIDIG,
        PERMANENT,
        OPPLYSNING_MANGLER
    }
    class PDL_API_Sivilstand {
        PDL_API_Sivilstandstype type;
        Date gyldigFraOgMed;
        String relatertVedSivilstand;
        Date bekreftelsesdato;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    
    enum PDL_API_Sivilstandstype{
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
    class PDL_API_InnflyttingTilNorge{
        String fraflyttingsland;
        String fraflyttingsstedIUtlandet;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_UtflyttingFraNorge{
        String tilflyttingsland;
        String tilflyttingsstedIUtlandet;
        String utflyttingsdato;
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_VergeEllerFullmektig{
        PDL_API_Personnavn navn;
        String motpartsPersonident;
        String omfang;
        Boolean omfangetErInnenPersonligOmraade;
    }
    class PDL_API_VergemaalEllerFremtidsfullmakt {
        String type;
        String embete;
        PDL_API_VergeEllerFullmektig vergeEllerFullmektig;
    
        PDL_API_Folkeregistermetadata folkeregistermetadata;
        PDL_API_Metadata metadata;
    }
    class PDL_API_Metadata{
        String opplysningsId;
        String master;
        PDL_API_Endring[] endringer;
        Boolean historisk;
    }
    class PDL_API_Endring{
        PDL_API_Endringstype type;
        Date registrert;
        String registrertAv;
        String systemkilde;
        String kilde;
    }
    enum PDL_API_Endringstype{
        OPPRETT,
        KORRIGER,
        OPPHOER
    }
    public class MissingExpectedDataException extends Exception{}
}
