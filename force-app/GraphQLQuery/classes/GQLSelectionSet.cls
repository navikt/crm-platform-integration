public class GQLSelectionSet {
    //Simplified
    List<GQLSelectionSetItem> selectionSet;

    public GQLSelectionSet(){
        selectionSet = new List<GQLSelectionSetItem>();
    }
    public GQLSelectionSet addItem(GQLSelectionSetItem item){
        selectionSet.add(item);
        return this;
    }
    public String build(){
        if(selectionSet.isEmpty())
            return '';
        String s = '';
        for(GQLSelectionSetItem item : selectionSet){
            s += item.build();
        }
        return '{' + s + '}';
    }
}