public class GQLVariable {
    // Simplified implementation
    String name;
    GQLVariableType type;

    public GQLVariable(String name, GQLVariableType type){
        this.name = name;
        this.type = type;
    }

    public String getVarName(){
        return '$' + name;
    }
    public String getName(){
        return name;
    }
    public String build(){
        return '$' + name + ': ' + type.build() +' ';
    }
}