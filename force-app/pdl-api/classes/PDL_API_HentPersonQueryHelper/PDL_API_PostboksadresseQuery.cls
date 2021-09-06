public with sharing class PDL_API_PostboksadresseQuery {

    public Boolean postbokseier = false;
    public Boolean postboks = false;
    public Boolean postnummer = false;

    public PDL_API_PostboksadresseQuery() {

    }

    public Boolean isEmpty(){
        return !(   postbokseier ||
                    postboks ||
                    postnummer );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( postbokseier ) selectionSet.addItem( new GQLField( 'postbokseier' ) );
        if ( postboks ) selectionSet.addItem( new GQLField( 'postboks' ) );
        if ( postnummer ) selectionSet.addItem( new GQLField( 'postnummer' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'postboksadresse',
            args,
            selectionSet
        );
    }
}
