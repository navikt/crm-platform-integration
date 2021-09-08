public with sharing class PDL_API_UtflyttingFraNorgeQuery {

    public Boolean historikk = false;

    public Boolean tilflyttingsland = false;
    public Boolean tilflyttingsstedIUtlandet = false;
    public Boolean utflyttingsdato = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_UtflyttingFraNorgeQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        tilflyttingsland = true;
        tilflyttingsstedIUtlandet = true;
        utflyttingsdato = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   tilflyttingsland ||
                    tilflyttingsstedIUtlandet ||
                    utflyttingsdato ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( tilflyttingsland ) selectionSet.addItem( new GQLField( 'tilflyttingsland' ) );
        if ( tilflyttingsstedIUtlandet ) selectionSet.addItem( new GQLField( 'tilflyttingsstedIUtlandet' ) );
        if ( utflyttingsdato ) selectionSet.addItem( new GQLField( 'utflyttingsdato' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments().addArgument( 
            new GQLArgument(
                'historikk', new GQLValue(historikk)
            )
        );

        return new GQLField(
            'utflyttingFraNorge',
            args,
            selectionSet
        );
    }
}
