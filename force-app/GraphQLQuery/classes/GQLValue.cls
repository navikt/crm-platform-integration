public class GQLValue {
    //Simplified implementation
    GQLValueType_e type;
    GQLVariable varValue;
    String stringValue;
    Integer intValue;
    Double floatValue;
    Boolean boolValue;
    GQLInputObject objectValue;

    public GQLValue(String value){
        type = GQLValueType_e.TYPE_STRING;
        stringValue = value;
    }
    public GQLValue(Integer value){
        type = GQLValueType_e.TYPE_INT;
        intValue = value;
    }
    public GQLValue(GQLVariable value){
        type = GQLValueType_e.TYPE_VARIABLE;
        varValue = value;
    }
    public GQLValue(Boolean value){
        type = GQLValueType_e.TYPE_BOOL;
        boolValue = value;
    }
    public GQLValue(GQLInputObject value){
        type = GQLValueType_e.TYPE_OBJECT;
        objectValue = value;
    }
    public GQLValue(GQLEnum value){
        type = GQLValueType_e.TYPE_ENUM;
        stringValue = value.build();
    }

    public String build(){
        if(type == GQLValueType_e.TYPE_STRING)
            return '"' + stringValue + '"';
        if(type == GQLValueType_e.TYPE_INT)
            return '' + intValue;
        if(type == GQLValueType_e.TYPE_VARIABLE)
            return varValue.getVarName();
        if(type == GQLValueType_e.TYPE_BOOL)
            return '' + boolValue;
        if(type == GQLValueType_e.TYPE_OBJECT)
            return objectValue.build();
        if(type == GQLValueType_e.TYPE_ENUM)
            return stringValue;
        return '';
    }
}