public with sharing class PDL_API_IdentifiserendeInformasjonQuery {
    
    PDL_API_PersonnavnQuery navn;
    public Boolean kjoenn  = false;
    public Boolean foedselsdato  = false;
    public boolean statsborgerskap  = false;
    
    public PDL_API_IdentifiserendeInformasjonQuery() {
        navn = new PDL_API_PersonnavnQuery('navn');
    }

    public void selectAll(){
        navn.selectAll();
        kjoenn = true;
        foedselsdato = true;
        statsborgerskap = true;
    }

    public Boolean isEmpty(){
        return !(   !navn.isEmpty() ||
                    kjoenn ||
                    foedselsdato ||
                    statsborgerskap);
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        selectionSet.addItem( navn.buildGQLField() );
        if ( kjoenn ) selectionSet.addItem( new GQLField( 'kjoenn' ) );
        if ( foedselsdato ) selectionSet.addItem( new GQLField( 'foedselsdato' ) );
        if ( statsborgerskap ) selectionSet.addItem( new GQLField( 'statsborgerskap' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'identifiserendeInformasjon',
            args,
            selectionSet
        );
    }
}
