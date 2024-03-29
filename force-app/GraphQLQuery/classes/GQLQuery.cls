public class GQLQuery {
    GQLOperation operation;
    Object variables;

    public GQLQuery(GQLOperation operation, Object variables){
        this.operation = operation;
        this.variables = variables;
    }

    public GQLQuery addVariable(GQLVariable var){
        operation.addVariable(var);
        return this;
    } 
    public GQLQuery addSelectionSetItem(GQLSelectionSetItem item){
        operation.addSelectionSetItem(item);
        return this;
    }

    public String build(){
        GQLOutput output = new GQLOutput(operation.build(), variables);
        return JSON.serialize(output, true);
    }

    private class GQLOutput {
        private String query;
        private Object variables;

        public GQLOutput(String query, Object variables) {
            this.query = query;
            this.variables = variables;
        }
    }    
}