public class GQLOperationType {
    // map shoud include all values form GQLOperationType_e
    static Map<GQLOperationType_e, String> typeStringValues = 
        new Map<GQLOperationType_e,String>{
            GQLOperationType_e.QUERY => 'query',
            GQLOperationType_e.MUTATION => 'mutation',
            GQLOperationType_e.SUBSCRIPTION => 'subscription'
        };

    GQLOperationType_e type;

    /*
    *   @description: constructor for compatibility with older code, consider to use other constructors
    *   
    */
    public GQLOperationType(String type){
        if(!type.equals('query'))
            throw new InvalidOperationException('Unsupported operation type');
        this.type = GQLOperationType_e.QUERY;
    }
    public GQLOperationType(){
        type = GQLOperationType_e.QUERY;
    }
    public GQLOperationType(GQLOperationType_e t){
        type = t;
    }

    public String build(){
        return typeStringValues.get(type);
    }
    public class InvalidOperationException extends Exception {
    }
}