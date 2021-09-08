public with sharing class PDL_API_EndringQuery {

    public Boolean type = false;
    public Boolean registrert = false;
    public Boolean registrertAv = false;
    public Boolean systemkilde = false;
    public Boolean kilde = false;

    public PDL_API_EndringQuery() {

    }

    public void selectAll(){
        type = true;
        registrert = true;
        registrertAv = true;
        systemkilde = true;
        kilde = true;
        
    }

    public Boolean isEmpty(){
        return !(   type || 
                    registrert ||
                    registrertAv ||
                    systemkilde || 
                    kilde );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( type ) selectionSet.addItem( new GQLField( 'type' ) );
        if ( registrert ) selectionSet.addItem( new GQLField( 'registrert' ) );
        if ( registrertAv ) selectionSet.addItem( new GQLField( 'registrertAv' ) );
        if ( systemkilde ) selectionSet.addItem( new GQLField( 'systemkilde' ) );
        if ( kilde ) selectionSet.addItem( new GQLField( 'kilde' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'endringer',
            args,
            selectionSet
        );
    }
}
