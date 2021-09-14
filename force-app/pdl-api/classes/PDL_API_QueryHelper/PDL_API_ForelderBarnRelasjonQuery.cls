public with sharing class PDL_API_ForelderBarnRelasjonQuery {

    public Boolean relatertPersonsIdent = false;
    public Boolean relatertPersonsRolle = false;
    public Boolean minRolleForPerson = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_ForelderBarnRelasjonQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }
    
    public void selectAll(){
        relatertPersonsIdent = true;
        relatertPersonsRolle = true;
        minRolleForPerson = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }
    public Boolean isEmpty(){
        return !(   relatertPersonsIdent ||
                    relatertPersonsRolle ||
                    minRolleForPerson ||
                    !folkeregistermetadata.isEmpty() || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( relatertPersonsIdent ) selectionSet.addItem( new GQLField( 'relatertPersonsIdent' ) );
        if ( relatertPersonsRolle ) selectionSet.addItem( new GQLField( 'relatertPersonsRolle' ) );
        if ( minRolleForPerson ) selectionSet.addItem( new GQLField( 'minRolleForPerson' ) );
        selectionSet.addItem( folkeregistermetadata.buildGQLField() );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'forelderBarnRelasjon',
            args,
            selectionSet
        );
    }
}
