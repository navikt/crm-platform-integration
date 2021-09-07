public class GQLArguments {
    List<GQLArgument> arguments;

    public GQLArguments(){
        arguments = new List<GQLArgument>();
    }
    public GQLArguments(List<GQLArgument> arguments){
        this.arguments = arguments;
    }

    public GQLArguments addArgument(GQLArgument argument){
        arguments.add(argument);
        return this;
    }

    public String build(){
        if(arguments.isEmpty())
            return '';
        String s = '';
        for(GQLArgument argument : arguments){
            s += argument.build();
        }
        return '(' + s + ')';
    }
}