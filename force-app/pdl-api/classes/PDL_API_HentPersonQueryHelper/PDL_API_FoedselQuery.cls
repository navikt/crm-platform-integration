public with sharing class PDL_API_FoedselQuery {

    public Boolean foedselsaar = false;
    public Boolean foedselsdato = false;
    public Boolean foedeland = false;
    public Boolean foedested = false;
    public Boolean foedekommune = false;

    public Boolean folkeregistermetadata = false;
    public Boolean metadata = false;

    public PDL_API_FoedselQuery() {

    }

    public Boolean isEmpty(){
        return !(   foedselsaar ||
                    foedselsdato ||
                    foedeland ||
                    foedested ||
                    foedekommune ||
                    folkeregistermetadata || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( foedselsaar ) selectionSet.addItem( new GQLField( 'foedselsaar' ) );
        if ( foedselsdato ) selectionSet.addItem( new GQLField( 'foedselsdato' ) );
        if ( foedeland ) selectionSet.addItem( new GQLField( 'foedeland' ) );
        if ( foedested ) selectionSet.addItem( new GQLField( 'foedested' ) );
        if ( foedekommune ) selectionSet.addItem( new GQLField( 'foedekommune' ) );
        if ( folkeregistermetadata ) selectionSet.addItem( new GQLField( 'folkeregistermetadata' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'foedsel',
            args,
            selectionSet
        );
    }
}
