public with sharing class NOM_RessursHelper {
    static LoggerUtility logger = new LoggerUtility('NOM');

    public static NOM_Ressurs getRessursFromIdent(String navIdent) {
        NOM_Response resp = queryData(getRessursFromIdentQuery(navIdent));
        return resp?.data.ressurs;
    }

    public static NOM_Response queryData(String query){

        NOM_Response nomResponse;

        NOM_Service nom = new NOM_Service(CRM_ApplicationDomain.Domain.CRM);

        try{
            HttpResponse response = nom.queryData(query);
            if(response.getStatusCode() != 200){
                logger.httpError('Kunne ikke hente data fra NOM', response, null, null);
                logger.publish();
            }
            nomResponse = (NOM_Response) JSON.deserialize(response.getBody(), NOM_Response.class);
        }catch (Exception e){
            logger.exception(e);
        }
        logger.publish();
        return nomResponse;

    }

    public static String getRessursFromIdentQuery(String navIdent){
        GQLVariable navId = new GQLVariable(
            'navId',
            new GQLVariableType(
                'String',
                false,
                true,
                false
            )
        );

        GQLQuery query = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(),
                '',
                new GQLVariableDefinitions().addVariable(navId),
                new GQLSelectionSet().addItem(
                    new GQLField(
                        'ressurs'
                    ).addArgument(
                        new GQLArgument(
                            'where',
                            new GQLValue(
                                new GQLInputObject().addField(
                                    new GQLInputObjectField(
                                        'navident',
                                        new GQLValue(navId)
                                    )
                                )
                            )
                        )
                    ).addSelectionSetItem(
                        new GQLField(
                            'visningsnavn'
                        )
                    )
                )
            ),
            (Object)new Map<String, Object>{navId.getName() => navIdent}
        );
        return query.build();
    }
}