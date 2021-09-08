public with sharing class PDL_API_ForeldreansvarQuery {
    public Boolean historikk = false;

    public Boolean ansvar = false;
    public Boolean ansvarlig = false;
    public Boolean ansvarssubjekt = false;
    PDL_API_RelatertBiPersonQuery ansvarligUtenIdentificator;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_ForeldreansvarQuery() {
        ansvarligUtenIdentificator = new PDL_API_RelatertBiPersonQuery();
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        ansvar = true;
        ansvarlig = true;
        ansvarssubjekt = true;
        ansvarligUtenIdentificator.selectAll();
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   ansvar || 
                    ansvarlig || 
                    ansvarssubjekt || 
                    !ansvarligUtenIdentificator.isEmpty() || 
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( ansvar ) selectionSet.addItem( new GQLField( 'ansvar' ) );
        if ( ansvarlig ) selectionSet.addItem( new GQLField( 'ansvarlig' ) );
        if ( ansvarssubjekt ) selectionSet.addItem( new GQLField( 'ansvarssubjekt' ) );
        selectionSet.addItem( ansvarligUtenIdentificator.buildGQLField() );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'foreldreansvar',
            args,
            selectionSet
        );
    }
}
