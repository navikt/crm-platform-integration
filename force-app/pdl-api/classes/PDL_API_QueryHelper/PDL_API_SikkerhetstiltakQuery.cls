public with sharing class PDL_API_SikkerhetstiltakQuery {

    public Boolean tiltakstype = false;
    public Boolean beskrivelse = false;
    PDL_API_SikkerhetstiltakKontaktpersonQ kontaktperson;
    public Boolean gyldigFraOgMed = false;
    public Boolean gyldigTilOgMed = false;

    PDL_API_MetadataQuery metadata;

    public PDL_API_SikkerhetstiltakQuery() {
        kontaktperson = new PDL_API_SikkerhetstiltakKontaktpersonQ();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        tiltakstype = true;
        beskrivelse = true;
        kontaktperson.selectAll();
        gyldigFraOgMed = true;
        gyldigTilOgMed = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   tiltakstype ||
                    beskrivelse ||
                    !kontaktperson.isEmpty() ||
                    gyldigFraOgMed ||
                    gyldigTilOgMed || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( tiltakstype ) selectionSet.addItem( new GQLField( 'tiltakstype' ) );
        if ( beskrivelse ) selectionSet.addItem( new GQLField( 'beskrivelse' ) );
        selectionSet.addItem(kontaktperson.buildGQLField());
        if ( gyldigFraOgMed ) selectionSet.addItem( new GQLField( 'gyldigFraOgMed' ) );
        if ( gyldigTilOgMed ) selectionSet.addItem( new GQLField( 'gyldigTilOgMed' ) );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'sikkerhetstiltak',
            args,
            selectionSet
        );
    }
}
