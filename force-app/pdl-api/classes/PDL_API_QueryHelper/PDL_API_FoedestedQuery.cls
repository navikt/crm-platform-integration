public with sharing class PDL_API_FoedestedQuery {
    public Boolean foedeland = false;
    public Boolean foedested = false;
    public Boolean foedekommune = false;

    PDL_API_FolkeregistermetadataQuery folkeregistermetadata;
    PDL_API_MetadataQuery metadata;

    public PDL_API_FoedestedQuery() {
        folkeregistermetadata = new PDL_API_FolkeregistermetadataQuery();
        metadata = new PDL_API_MetadataQuery();
    }

    public void selectAll() {
        foedeland = true;
        foedested = true;
        foedekommune = true;
    }

    public void selectAll(Boolean includeMetadata) {
        if (includeMetadata) {
            folkeregistermetadata.selectAll();
            metadata.selectAll();
        }
        selectAll();
    }

    public Boolean isEmpty() {
        return !(foedeland || foedested || foedekommune || !folkeregistermetadata.isEmpty() || !metadata.isEmpty());
    }

    public GQLField buildGQLField() {
        if (isEmpty()) {
            return null;
        }

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if (foedeland) {
            selectionSet.addItem(new GQLField('foedeland'));
        }
        if (foedested) {
            selectionSet.addItem(new GQLField('foedested'));
        }
        if (foedekommune) {
            selectionSet.addItem(new GQLField('foedekommune'));
        }
        selectionSet.addItem(folkeregistermetadata.buildGQLField());
        selectionSet.addItem(metadata.buildGQLField());

        GQLArguments args = new GQLArguments();

        return new GQLField('foedested', args, selectionSet);
    }
}
