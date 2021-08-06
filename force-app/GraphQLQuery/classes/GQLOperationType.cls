public class GQLOperationType {
    // map shoud include all values form GQLOperationType_e
    static Map<GQLOperationType_e, String> typeStringValues = 
        new Map<GQLOperationType_e,String>{
            GQLOperationType_e.QUERY => 'query',
            GQLOperationType_e.MUTATION => 'mutation',
            GQLOperationType_e.SUBSCRIPTION => 'subscription'
        };

    GQLOperationType_e type;

    public GQLOperationType(){
        type = GQLOperationType_e.QUERY;
    }
    public GQLOperationType(GQLOperationType_e t){
        type = t;
    }

    public String build(){
        return typeStringValues.get(type);
    }
}