public with sharing class PDL_API_VergeEllerFullmektigQuery {
    
    public Boolean motpartsPersonident = false;
    public Boolean omfang = false;
    public Boolean omfangetErInnenPersonligOmraade = false;
    PDL_API_TjenesteomraadeQuery tjenesteomraade;
    PDL_API_IdentifiserendeInformasjonQuery identifiserendeInformasjon;
    
    public PDL_API_VergeEllerFullmektigQuery() {
        tjenesteomraade = new PDL_API_TjenesteomraadeQuery();
        identifiserendeInformasjon = new PDL_API_IdentifiserendeInformasjonQuery();
        
    }

    public void selectAll(){
        motpartsPersonident = true;
        omfang = true;
        omfangetErInnenPersonligOmraade = true;
        tjenesteomraade.selectAll();
        identifiserendeInformasjon.selectAll();
    }

    public Boolean isEmpty(){
        return !(   !tjenesteomraade.isEmpty() ||
                    !identifiserendeInformasjon.isEmpty() ||
                    motpartsPersonident ||
                    omfang ||
                    omfangetErInnenPersonligOmraade );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( motpartsPersonident ) selectionSet.addItem( new GQLField( 'motpartsPersonident' ) );
        if ( omfang ) selectionSet.addItem( new GQLField( 'omfang' ) );
        if ( omfangetErInnenPersonligOmraade ) selectionSet.addItem( new GQLField( 'omfangetErInnenPersonligOmraade' ) );
        selectionSet.addItem( tjenesteomraade.buildGQLField() );
        selectionSet.addItem( identifiserendeInformasjon.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'vergeEllerFullmektig',
            args,
            selectionSet
        );
    }
}
