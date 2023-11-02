public with sharing class GQLInputObject {
    List<GQLInputObjectField> fields;

    public GQLInputObject(){
        fields = new List<GQLInputObjectField>();
    }
    public GQLInputObject(List<GQLInputObjectField> fields){
        this.fields = fields;
    }

    public GQLInputObject addField(GQLInputObjectField field){
        fields.add(field);
        return this;
    }

    public String build(){
        String s = '';
        for(GQLInputObjectField field : fields){
            s += field.build();
        }
        return '{' + s + '}';
    }
}