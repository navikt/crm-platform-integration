public class GQLArgument {
    String name;
    GQLValue value;

    public GQLArgument(String name, GQLValue value){
        this.name = name;
        this.value = value;
    }
    public GQLArgument(String name, String value){
        this(name, new GQLValue(value));
    }
    
    public String build(){
        return name + ' : ' + value.build() + ' ';
    }
}