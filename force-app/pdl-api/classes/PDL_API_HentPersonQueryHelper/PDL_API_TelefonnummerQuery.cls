public with sharing class PDL_API_TelefonnummerQuery {

    public Boolean landskode = false;
    public Boolean nummer = false;
    public Boolean prioritet = false;

    public Boolean metadata = false;

    public PDL_API_TelefonnummerQuery() {

    }

    public Boolean isEmpty(){
        return !(   landskode ||
                    nummer ||
                    prioritet || 
                    metadata );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( landskode ) selectionSet.addItem( new GQLField( 'landskode' ) );
        if ( nummer ) selectionSet.addItem( new GQLField( 'nummer' ) );
        if ( prioritet ) selectionSet.addItem( new GQLField( 'prioritet' ) );
        if ( metadata ) selectionSet.addItem( new GQLField( 'metadata' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'telefonnummer',
            args,
            selectionSet
        );
    }
}
