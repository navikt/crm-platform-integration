public with sharing class PDL_API_FoedselsdatoQuery {
    public Boolean foedselsaar = false;
    public Boolean foedselsdato = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_FoedselsdatoQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll() {
        foedselsaar = true;
        foedselsdato = true;
    }

    public void selectAll(Boolean includeMetadata) {
        if (includeMetadata) {
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty() {
        return !(foedselsaar || foedselsdato || !folkeregistermetadata.isEmpty() || !metadata.isEmpty());
    }

    public GQLField buildGQLField() {
        if (isEmpty()) {
            return null;
        }

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if (foedselsaar) {
            selectionSet.addItem(new GQLField('foedselsaar'));
        }
        if (foedselsdato) {
            selectionSet.addItem(new GQLField('foedselsdato'));
        }
        selectionSet.addItem(folkeregistermetadata.buildGQLField());
        selectionSet.addItem(metadata.buildGQLField());

        GQLArguments args = new GQLArguments();

        return new GQLField('foedsel', args, selectionSet);
    }
}
