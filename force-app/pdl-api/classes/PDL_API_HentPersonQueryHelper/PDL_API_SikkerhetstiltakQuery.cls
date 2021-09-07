public with sharing class PDL_API_SikkerhetstiltakQuery {

    public Boolean tiltakstype = false;
    public Boolean beskrivelse = false;
    PDL_API_SikkerhetstiltakKontaktpersonQ kontaktperson;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    public Boolean metadata = false;

    public PDL_API_SikkerhetstiltakQuery() {
        kontaktperson = new PDL_API_SikkerhetstiltakKontaktpersonQ();
    }

    public void selectAll(){
        tiltakstype = true;
        beskrivelse = true;
        kontaktperson.selectAll();
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            metadata = true;
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   tiltakstype ||
                    beskrivelse ||
                    !kontaktperson.isEmpty() ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( tiltakstype ) selectionSet.addItem( new GQLField( 'tiltakstype' ) );
        if ( beskrivelse ) selectionSet.addItem( new GQLField( 'beskrivelse' ) );
        selectionSet.addItem(kontaktperson.buildGQLField());
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'sikkerhetstiltak',
            args,
            selectionSet
        );
    }
}
