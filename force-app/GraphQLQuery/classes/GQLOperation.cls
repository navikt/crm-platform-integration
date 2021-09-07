/* OperationDefinition
    OperationType NameoptVariable Definitions.opt Directives.opt SelectionSet
    SelectionSet
*/
public class GQLOperation {
    private GQLOperationType type;
    private String name;
    private GQLVariableDefinitions def;
    private GQLSelectionSet selectionSet;

    public GQLOperation(GQLOperationType type, 
                     String name, 
                     GQLVariableDefinitions def, 
                     GQLSelectionSet selectionSet){
        this.type = type;
        this.name = name;
        this.def = def;
        this.selectionSet = selectionSet;
    }

    public GQLOperation addVariable(GQLVariable var){
        def.addVariable(var);
        return this;
    }
    public GQLOperation addSelectionSetItem(GQLSelectionSetItem item){
        selectionSet.addItem(item);
        return this;
    }

    public String build() {
        return type.build() + ' ' + name + + def.build() + selectionSet.build();
    }
}