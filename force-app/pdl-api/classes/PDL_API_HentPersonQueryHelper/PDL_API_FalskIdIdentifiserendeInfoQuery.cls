public with sharing class PDL_API_FalskIdIdentifiserendeInfoQuery {

    PDL_API_PersonnavnQuery personnavn;
    public Boolean foedselsdato = false;
    public Boolean statsborgerskap = false;
    public Boolean kjoenn = false;

    public PDL_API_FalskIdIdentifiserendeInfoQuery() {
        personnavn = new PDL_API_PersonnavnQuery();
    }

    public void selectAll(){
        personnavn.selectAll();
        foedselsdato = true;
        statsborgerskap = true;
        kjoenn = true;
    }

    public Boolean isEmpty(){
        return !(   !personnavn.isEmpty() ||
                    foedselsdato ||
                    statsborgerskap ||
                    kjoenn );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( personnavn.buildGQLField() );
        if ( foedselsdato ) selectionSet.addItem( new GQLField( 'foedselsdato' ) );
        if ( statsborgerskap ) selectionSet.addItem( new GQLField( 'statsborgerskap' ) );
        if ( kjoenn ) selectionSet.addItem( new GQLField( 'kjoenn' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'rettIdentitetVedOpplysninger',
            args,
            selectionSet
        );
    }
}
