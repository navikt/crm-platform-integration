public with sharing class PDL_API_KoordinaterQuery {
    
    public Boolean x = false;
    public Boolean y = false;
    public Boolean z = false;
    public Boolean kvalitet = false;

    public PDL_API_KoordinaterQuery() {

    }

    public void selectAll(){
        x = true;
        y = true;
        z = true;
        kvalitet = true;
    }

    public Boolean isEmpty(){
        return !(   x || 
                    y || 
                    z || 
                    kvalitet );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( x ) selectionSet.addItem( new GQLField( 'x' ) );
        if ( y ) selectionSet.addItem( new GQLField( 'y' ) );
        if ( z ) selectionSet.addItem( new GQLField( 'z' ) );
        if ( kvalitet ) selectionSet.addItem( new GQLField( 'kvalitet' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'koordinater',
            args,
            selectionSet
        );
    }
}
