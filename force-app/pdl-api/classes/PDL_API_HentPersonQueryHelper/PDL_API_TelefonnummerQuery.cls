public with sharing class PDL_API_TelefonnummerQuery {

    public Boolean landskode = false;
    public Boolean nummer = false;
    public Boolean prioritet = false;

    PDL_API_MetadataQuery metadata;

    public PDL_API_TelefonnummerQuery() {
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll(){
        landskode = true;
        nummer = true;
        prioritet = true;
    }

    public void selectAll(Boolean includeMetadata){
        if(includeMetadata){
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty(){
        return !(   landskode ||
                    nummer ||
                    prioritet || 
                    !metadata.isEmpty() );
    }

    public GQLField buildGQLField(){
        if(isEmpty()) return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if ( landskode ) selectionSet.addItem( new GQLField( 'landskode' ) );
        if ( nummer ) selectionSet.addItem( new GQLField( 'nummer' ) );
        if ( prioritet ) selectionSet.addItem( new GQLField( 'prioritet' ) );
        selectionSet.addItem( metadata.buildGQLField() );

        GQLArguments args = new GQLArguments();

        return new GQLField(
            'telefonnummer',
            args,
            selectionSet
        );
    }
}
