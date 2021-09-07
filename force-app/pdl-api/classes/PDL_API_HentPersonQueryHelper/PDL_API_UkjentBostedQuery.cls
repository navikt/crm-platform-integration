public with sharing class PDL_API_UkjentBostedQuery {
    public Boolean bostedskommune = false;

    public PDL_API_UkjentBostedQuery() {

    }

    public void selectAll(){
        bostedskommune = true;
    }

    public Boolean isEmpty(){
        return !(   bostedskommune  );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( bostedskommune ) selectionSet.addItem( new GQLField( 'bostedskommune' ) );
        
        GQLArguments args = new GQLArguments();

        return new GQLField(
            'ukjentBosted',
            args,
            selectionSet
        );
    }
}
