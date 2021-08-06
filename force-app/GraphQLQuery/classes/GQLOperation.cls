/* OperationDefinition
    OperationType NameoptVariable Definitions.opt Directives.opt SelectionSet
    SelectionSet
*/
public class GQLOperation {
    GQLOperationType type;
    String name;
    GQLVariableDefinitions def;
    GQLSelectionSet selectionSet;

    public GQLOperation(GQLOperationType type, 
                     String name, 
                     GQLVariableDefinitions def, 
                     GQLSelectionSet selectionSet){
        this.type = type;
        this.name = name;
        this.def = def;
        this.selectionSet = selectionSet;
    }

    public String build() {
        return type.build() + name + def.build() + selectionSet.build();
    }
}