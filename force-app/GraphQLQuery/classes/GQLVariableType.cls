public class GQLVariableType {
    // Simplified implementation
    String name;
    Boolean listType;
    Boolean nonNullType;
    Boolean nonNullListType;

    public GQLVariableType(String name, Boolean listType, Boolean nonNullType, Boolean nonNullListType){
        this.name = name;
        this.listType = listType;
        this.nonNullType = nonNullType;
        this.nonNullListType = nonNullListType;
    }
    public GQLVariableType(String name){
        this(name, false,false,false);
    }

    public String build(){
        String s = name;
        if(nonNullType) 
            s = s + '!';
        if(listType) 
            s = '[' + s + ']';
        if(nonNullListType) 
            s = s + '!';
        return s;
    }
}