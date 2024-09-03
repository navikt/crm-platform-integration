public with sharing class PDL_API_HentGeografiskTilknytningQuery {
    GQLVariable ident;

    public Boolean gtType = false;
    public Boolean gtKommune = false;
    public Boolean gtBydel = false;
    public Boolean gtLand = false;

    public PDL_API_HentGeografiskTilknytningQuery(GQLVariable ident) {
        this.ident = ident;
    }

    public void selectAll() {
        gtType = true;
        gtKommune = true;
        gtBydel = true;
        gtLand = true;
    }

    public Boolean isEmpty() {
        return !(gtType || gtKommune || gtBydel || gtLand);
    }

    public GQLField buildGQLField() {
        if (isEmpty() || ident == null)
            return null;

        GQLSelectionSet selectionSet = new GQLSelectionSet();
        if (gtType)
            selectionSet.addItem(new GQLField('gtType'));
        if (gtKommune)
            selectionSet.addItem(new GQLField('gtKommune'));
        if (gtBydel)
            selectionSet.addItem(new GQLField('gtBydel'));
        if (gtLand)
            selectionSet.addItem(new GQLField('gtLand'));

        GQLArguments args = new GQLArguments().addArgument(new GQLArgument('ident', new GQLValue(ident)));

        return new GQLField('hentGeografiskTilknytning', args, selectionSet);
    }
}
