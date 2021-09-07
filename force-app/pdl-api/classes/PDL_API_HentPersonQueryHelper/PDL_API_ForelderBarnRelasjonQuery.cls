public with sharing class PDL_API_ForelderBarnRelasjonQuery {

    public Boolean relatertPersonsIdent = false;
    public Boolean relatertPersonsRolle = false;
    public Boolean minRolleForPerson = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_ForelderBarnRelasjonQuery() {

    }
    
    public void selectAll(){
        relatertPersonsIdent = true;
        relatertPersonsRolle = true;
        minRolleForPerson = true;
    }

    public void selectAll(Boolean metadata){
        if(metadata){
            folkeregistermetadata = true;
            metadata = true;
        }
        selectAll();
    }
    public Boolean isEmpty(){
        return !(   relatertPersonsIdent ||
                    relatertPersonsRolle ||
                    minRolleForPerson ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( relatertPersonsIdent ) selectionSet.addItem( new GQLField( 'relatertPersonsIdent' ) );
        if ( relatertPersonsRolle ) selectionSet.addItem( new GQLField( 'relatertPersonsRolle' ) );
        if ( minRolleForPerson ) selectionSet.addItem( new GQLField( 'minRolleForPerson' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'forelderBarnRelasjon',
            args,
            selectionSet
        );
    }
}
