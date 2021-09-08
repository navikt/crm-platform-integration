public with sharing class PDL_API_FolkeregistermetadataQuery {

    public Boolean ajourholdstidspunkt = false;
    public Boolean gyldighetstidspunkt = false;
    public Boolean opphoerstidspunkt = false;
    public Boolean kilde = false;
    public Boolean aarsak = false;
    public Boolean sekvens = false;

    public PDL_API_FolkeregistermetadataQuery() {

    }

    public void selectAll(){
        ajourholdstidspunkt = true;
        gyldighetstidspunkt = true;
        opphoerstidspunkt = true;
        kilde = true;
        aarsak = true;
        sekvens = true;
    }

    public Boolean isEmpty(){
        return !(   ajourholdstidspunkt ||
        gyldighetstidspunkt ||
        opphoerstidspunkt ||
        kilde ||
        aarsak ||
        sekvens );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( ajourholdstidspunkt ) selectionSet.addItem( new GQLField( 'ajourholdstidspunkt' ) );
        if ( gyldighetstidspunkt ) selectionSet.addItem( new GQLField( 'gyldighetstidspunkt' ) );
        if ( opphoerstidspunkt ) selectionSet.addItem( new GQLField( 'opphoerstidspunkt' ) );
        if ( kilde ) selectionSet.addItem( new GQLField( 'kilde' ) );
        if ( aarsak ) selectionSet.addItem( new GQLField( 'aarsak' ) );
        if ( sekvens ) selectionSet.addItem( new GQLField( 'sekvens' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'folkeregistermetadata',
            args,
            selectionSet
        );
    }
}
