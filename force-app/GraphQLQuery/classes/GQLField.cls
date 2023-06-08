public class GQLField implements GQLSelectionSetItem{
    //Simplified
    String name;
    GQLArguments args;
    GQLSelectionSet selectionSet;

    public GQLField(String name){
        this.name = name;
    }
    public GQLField(String name, GQLArguments args){
        this.name = name;
        this.args = args;
    }
    public GQLField(String name, GQLSelectionSet selectionSet){
        this.name = name;
        this.selectionSet = selectionSet;
    }
    public GQLField(String name, GQLArguments args, GQLSelectionSet selectionSet){
        this.name = name;
        this.args = args;
        this.selectionSet = selectionSet;
    }

    public GQLField addArgument(GQLArgument arg){
        if (args == null){
            args = new GQLArguments();
        }
        args.addArgument(arg);
        return this;
    }

    public GQLField addSelectionSetItem(GQLSelectionSetItem item){
        if(selectionSet == null){
            selectionSet = new GQLSelectionSet();
        }
        selectionSet.addItem(item);
        return this;
    }

    public String build(){
        return ' ' + name 
                   + ((args!=null)?args.build():'') 
                   + ((selectionSet!=null)?selectionSet.build():'');
    }

}