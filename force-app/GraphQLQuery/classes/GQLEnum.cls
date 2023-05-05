public with sharing class GQLEnum {
    String value;
    public GQLEnum(String value) {
        this.value = value;
    }
    public String build(){
        return value;
    }
}