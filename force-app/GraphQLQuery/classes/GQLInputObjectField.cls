public with sharing class GQLInputObjectField {
    String name;
    GQLValue value;

    public GQLInputObjectField(String name, GQLValue value){
        this.name = name;
        this.value = value;
    }
    
    public String build(){
        return name + ' : ' + value.build() + ' ';
    }
}