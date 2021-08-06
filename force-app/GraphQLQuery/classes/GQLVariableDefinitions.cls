public class GQLVariableDefinitions {
    List<GQLVariable> variableList;

    public GQLVariableDefinitions(){
        variableList = new List<GQLVariable>();
    }
    public GQLVariableDefinitions(List<GQLVariable> variableList){
        this.variableList = variableList;
    }
    public GQLVariableDefinitions addVariable(GQLVariable var){
        variableList.add(var);
        return this;
    }
    public String build(){
        if(variableList.isEmpty())
            return '';
        String s = '';
        for(GQLVariable var : variableList){
            s += var.build();
        }
        return '(' + s + ')';
    }
}