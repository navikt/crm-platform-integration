public with sharing class PDL_API_UtenlandskAdresseIFrittFormatQ {

    public Boolean adresselinje1 = false;
    public Boolean adresselinje2 = false;
    public Boolean adresselinje3 = false;
    public Boolean postkode = false;
    public Boolean byEllerStedsnavn = false;
    public Boolean landkode = false;

    public PDL_API_UtenlandskAdresseIFrittFormatQ() {

    }

    public void selectAll(){
        adresselinje1 = true;
        adresselinje2 = true;
        adresselinje3 = true;
        postkode = true;
        byEllerStedsnavn = true;
        landkode = true;
    }

    public Boolean isEmpty(){
        return !(   adresselinje1 ||
                    adresselinje2 ||
                    adresselinje3 ||
                    postkode ||
                    byEllerStedsnavn ||
                    landkode  );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( adresselinje1 ) selectionSet.addItem( new GQLField( 'adresselinje1' ) );
        if ( adresselinje2 ) selectionSet.addItem( new GQLField( 'adresselinje2' ) );
        if ( adresselinje3 ) selectionSet.addItem( new GQLField( 'adresselinje3' ) );
        if ( postkode ) selectionSet.addItem( new GQLField( 'postkode' ) );
        if ( byEllerStedsnavn ) selectionSet.addItem( new GQLField( 'byEllerStedsnavn' ) );
        if ( landkode ) selectionSet.addItem( new GQLField( 'landkode' ) );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'utenlandskAdresseIFrittFormat',
            args,
            selectionSet
        );
    }
}
