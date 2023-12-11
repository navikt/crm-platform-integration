public with sharing class NOM_OrgEnhetHelper implements Callable{
    private static final String ROOT_UNIT_TEST = 'sa312u';
    private static final String ROOT_UNIT_PROD = 'ny410s';

    public NOM_OrgEnhetHelper(){}

    public Object call(String action, Map<String, Object> args){
        switch on action {
            when 'getLederForEnhetIds' {
                if(args.keySet().contains('navId') && (args.get('navId') instanceof String)){
                    return getLederForEnhetIds(
                        parseRessurs(
                            queryData(
                                getEnhetIdForNavIdQuery(
                                    (String)args.get('navId')
                                )
                            )
                        )
                    );

                }
                throw new NomIntHelperMalformedCallException('Bad argument for method getLederForEnhetIds, should be type of String.');
            }
            when else {
             throw new NomIntHelperMalformedCallException('Method not implemented');
            }
        }
    }

    public static NomUnit__c orgEnhetToNomUnit(NOM_OrgEnhet enhet) {
        NomUnit__c unit = new NomUnit__c();
        unit.INT_NomId__c = enhet.id;
        unit.Name = enhet.navn;
        unit.INT_UnitType__c = enhet.orgEnhetsType?.name();
        unit.INT_NomLevel__c = enhet.nomNivaa?.name();
        unit.INT_OrgLevel__c = enhet.orgNiv;
        return unit;
    }

    public static NOM_OrgEnhet nomUnitToOrgEnhet(NomUnit__c unit) {
        NOM_OrgEnhet enhet = new NOM_OrgEnhet();
        enhet.Id = unit.INT_NomId__c;
        enhet.navn = unit.Name;
        enhet.orgEnhetsType = unit.INT_UnitType__c != null ? NOM_OrgEnhetsType.valueOf(unit.INT_UnitType__c) : null;
        enhet.nomNivaa = unit.INT_NomLevel__c != null ? NOM_OrgEnhetsKategori.valueOf(unit.INT_NomLevel__c) : null;
        enhet.orgNiv = unit.INT_OrgLevel__c;
        return enhet;
    }

    public static NomUnit__c updateNomUnitFromOrgEnhet(NomUnit__c unit, NOM_OrgEnhet enhet) {
        unit.Name = enhet.navn;
        unit.INT_UnitType__c = enhet.orgEnhetsType?.name();
        unit.INT_NomLevel__c = enhet.nomNivaa?.name();
        unit.INT_OrgLevel__c = enhet.orgNiv;
        return unit;
    }
    public static Boolean isUpdated(NomUnit__c unit, NOM_OrgEnhet enhet) {
        if (
            unit.INT_IsActive__c == true &&
            unit.INT_NomId__c == enhet.id &&
            unit.Name == enhet.navn &&
            unit.INT_UnitType__c == enhet.orgEnhetsType?.name() &&
            unit.INT_NomLevel__c == enhet.nomNivaa?.name() &&
            unit.INT_OrgLevel__c == enhet.orgNiv
        ) {
            return false;
        }
        return true;
    }
    public static Boolean isUpdated(NomRole__c role, NOM_Ressurs leder){
        if(
            role.CRM_RoleHoldersNAVIdent__c == leder.navident &&
            role.CRM_RoleHoldersEmail__c == leder.epost &&
            role.Name == leder.visningsnavn
        ){
            return false;
        }
        return true;
    }
    public static NOM_Response queryData(String query){

        NOM_Response nomResponse;

        NOM_Service nom = new NOM_Service(CRM_ApplicationDomain.Domain.CRM);

        try{
            HttpResponse response = nom.queryData(query);
            if(response.getStatusCode() != 200){
                handleError('Kunne ikke hente data fra NOM',response);
            }
            nomResponse = (NOM_Response) JSON.deserialize(response.getBody(),NOM_Response.class);
        }catch(NOM_HelperException e){
            throw e;
        }catch (Exception e){
            String uuid = logException(e);
            throw new NOM_HelperException(e.getMessage() + ' LoggId: ' + uuid);
        }
        return nomResponse;

    }

    

    public static NOM_OrgEnhet getEnhetHierarchy(String enhetId, NOM_Retning direction, Integer depth){
        
        NOM_OrgEnhet enhet;

        String query = getEnhetQuery(enhetId, direction, depth);

        NOM_Response response = queryData(query);

        enhet = parseEnhetResponse(response);
        return enhet;
    }

    /**
     * Get a map containing NOM_OrgEnhet units with the NOM Unit Id as key. Each entry is a separate hierarchy that can be traversed by going through the NOM_OrgEnhet.
     *
     * The NOM GraphQL query orgEnheter is used as the basis via the method getOrgEnheterQuery() in this class.
     *
     * If NOM returns ERROR or NOT_FOUND the result will not be added to the map and a warning will be logged.
     *
     * @param `enhetIdList` list of NOM Unit ids
     * @param `direction` can be over or under
     * @param `depth` how many levels up or down to get
     *
     * @return `Map<String, NOM_OrgEnhet>`
     */
    public static Map<String, NOM_OrgEnhet> getEnhetHierarchiesMap(
        List<String> enhetIdList,
        NOM_Retning direction,
        Integer depth
    ) {
        LoggerUtility logger = new LoggerUtility('NOM');
        Map<String, NOM_OrgEnhet> hierarchyMap = new Map<String, NOM_OrgEnhet>();

        for (NOM_OrgEnhetResult enhetResult : getEnhetHierarchies(enhetIdList, direction, depth)) {
            if (enhetResult.code == NOM_ResultCode.OK) {
                hierarchyMap.put(enhetResult.nomId, enhetResult.orgEnhet);
            } else {
                logger.logMessage(
                    LoggerUtility.LogLevel.Warning,
                    enhetResult.nomId,
                    null,
                    String.format('Received {0}', new List<String>{ enhetResult.code.name() }),
                    JSON.serialize(enhetResult),
                    null,
                    CRM_ApplicationDomain.Domain.CRM
                );
            }
            logger.publish();
        }

        return hierarchyMap;
    }

    /**
     * Get a list of NOM_OrgEnhetResults Each entry is a separate hierarchy that can be traversed by going through the NOM_OrgEnhet.
     *
     * The NOM GraphQL query orgEnheter is used as the basis via the method getOrgEnheterQuery() in this class.
     *
     * @param `enhetIdList` list of NOM Unit ids
     * @param `direction` can be over or under
     * @param `depth` how many levels up or down to get
     *
     * @return `List<NOM_OrgEnhetResult>`
     */
    public static List<NOM_OrgEnhetResult> getEnhetHierarchies(
        List<String> enhetIdList,
        NOM_Retning direction,
        Integer depth
    ) {
        List<NOM_OrgEnhetResult> enheter;

        String query = getOrgEnheterQuery(enhetIdList, direction, depth);

        NOM_Response response = queryData(query);

        enheter = parseEnheterResponse(response);
       
        return enheter;
    }

    public static List<NOM_OrgEnhet> getFlatHierarchy(NOM_OrgEnhet hierarchy, NOM_Retning direction) {
        List<NOM_OrgEnhet> flatHierarchy = new List<NOM_OrgEnhet>();
        if (hierarchy == null) {
            return flatHierarchy;
        }
        flatHierarchy.add(hierarchy);
        List<NOM_OrgEnhet> relatedEnhets = getRelatedEnhets(hierarchy, direction);
        if (relatedEnhets.size() == 0) {
            return flatHierarchy;
        }
        for (NOM_OrgEnhet e : relatedEnhets) {
            flatHierarchy.addAll(getFlatHierarchy(e, direction));
        }
        return flatHierarchy;
    }

    public static Map<String, NOM_OrgEnhet> getFlatMapHierarchy(NOM_OrgEnhet hierarchy, NOM_Retning direction) {
        Map<String, NOM_OrgEnhet> flatHierarchy = new Map<String, NOM_OrgEnhet>();
        if (hierarchy == null) {
            return flatHierarchy;
        }
        flatHierarchy.put(hierarchy.id, hierarchy);
        List<NOM_OrgEnhet> relatedEnhets = getRelatedEnhets(hierarchy, direction);
        if (relatedEnhets.size() == 0) {
            return flatHierarchy;
        }
        for (NOM_OrgEnhet e : relatedEnhets) {
            flatHierarchy.putAll(getFlatMapHierarchy(e, direction));
        }
        return flatHierarchy;
    }

    public static List<NOM_OrgEnhet> getRelatedEnhets(NOM_OrgEnhet enhet, NOM_Retning direction) {
        List<NOM_OrgEnhet> enhets = new List<NOM_OrgEnhet>();
        if (enhet?.organiseringer == null) {
            return enhets;
        }

        for (NOM_Organisering org : enhet.organiseringer) {
            if (org.orgEnhet == null) {
                continue;
            }
            if (direction == null) {
                enhets.add(org.orgEnhet);
            } else if (org.retning == direction) {
                enhets.add(org.orgEnhet);
            }
        }
        return enhets;
    }

   public static NOM_OrgEnhet parseEnhetResponse(NOM_Response response){
        if(response?.data?.orgEnhet == null){
            throw new NOM_HelperException('No unit data in response.');
        }
        return response.data.orgEnhet;
    }
    public static NOM_Ressurs parseRessurs(NOM_Response response){
        if(response?.data?.ressurs == null){
            throw new NOM_HelperException('No ressurs data in response.'+ JSON.serializePretty(response));
        }
        return response.data.ressurs;
    }
    public static List<NOM_OrgEnhetResult> parseEnheterResponse(NOM_Response response) {
        if (response?.data?.orgEnheter == null) {
            throw new NOM_HelperException('No unit data in response.');
        }
        return response.data.orgEnheter;
    }
    public static String getOrgEnheterQuery(List<String> enhetIds, NOM_Retning direction, Integer depth) {
        GQLVariable varEnhetid = new GQLVariable('ider', new GQLVariableType('String', true, true, false));

        GQLQuery query = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(),
                'HentHierarkiFlere',
                new GQLVariableDefinitions().addVariable(varEnhetid),
                new GQLSelectionSet()
                    .addItem(
                        new GQLField('orgEnheter')
                            .addArgument(
                                new GQLArgument(
                                    'where',
                                    new GQLValue(
                                        new GQLInputObject()
                                            .addField(new GQLInputObjectField('ider', new GQLValue(varEnhetid)))
                                    )
                                )
                            )
                            .addSelectionSetItem(new GQLField('code'))
                            .addSelectionSetItem(new GQLField('id'))
                            .addSelectionSetItem(new GQLField('nomId'))
                            .addSelectionSetItem(new GQLField('orgNiv'))
                            .addSelectionSetItem(makeEnhetHierarchy(direction, depth))
                    )
            ),
            (Object) new Map<String, Object>{ varEnhetid.getName() => enhetIds }
        );
        return query.build();
    }
    public static String getEnhetIdForNavIdQuery(String navIdent){
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
                            'orgTilknytning'
                        ).addSelectionSetItem(
                            new GQLField(
                                'orgEnhet'
                            ).addSelectionSetItem(
                                new GQLField('id')
                            ).addSelectionSetItem(
                                new GQLField('navn')
                            )
                        ).addSelectionSetItem(
                            new GQLField('gyldigFom')
                        ).addSelectionSetItem(
                            new GQLField('gyldigTom')
                        ).addSelectionSetItem(
                            new GQLField('erDagligOppfolging')
                        )
                    ).addSelectionSetItem(
                        new GQLField(
                            'lederFor'
                        ).addSelectionSetItem(
                            new GQLField(
                                'orgEnhet'
                            ).addSelectionSetItem(
                                new GQLField('id')
                            ).addSelectionSetItem(
                                new GQLField('navn')
                            )
                        ).addSelectionSetItem(
                            new GQLField('gyldigFom')
                        ).addSelectionSetItem(
                            new GQLField('gyldigTom')
                        )
                    )
                )
            ),
            (Object)new Map<String, Object>{navId.getName() => navIdent}
        );
        return query.build();
    }
    public static String getEnhetQuery(String enhetId, NOM_Retning direction, Integer depth){
        //String enhetId = 'sa312u';
        GQLVariable varEnhetid = new GQLVariable('id', new GQLVariableType('String', false, true, false));

        GQLField organisering = new GQLField('organiseringer')
            .addSelectionSetItem(makeEnhetHierarchy(direction, depth - 1))
            .addSelectionSetItem(new GQLField('retning'))
            .addSelectionSetItem(new GQLField('gyldigFom'))
            .addSelectionSetItem(new GQLField('gyldigTom'));
        if (direction != null) {
            organisering.addArgument(new GQLArgument('retning', new GQLValue(new GQLEnum(direction.name()))));
        }

        GQLQuery query = new GQLQuery(
            new GQLOperation(
                new GQLOperationType(),
                'HentHierarki',
                new GQLVariableDefinitions().addVariable(varEnhetid),
                new GQLSelectionSet().addItem(
                    new GQLField('orgEnhet').addArgument(
                        new GQLArgument(
                            'where',
                            new GQLValue(
                                new GQLInputObject().addField(new GQLInputObjectField('id', new GQLValue(varEnhetid)))
                            )
                        )
                    ).addSelectionSetItem(
                        new GQLField('leder').addSelectionSetItem(
                            new GQLField('ressurs').addSelectionSetItem(
                                new GQLField('navident')
                            ).addSelectionSetItem(
                                new GQLField('epost')
                            ).addSelectionSetItem(
                                new GQLField('visningsnavn')
                            )
                        )
                    ).addSelectionSetItem(
                        new GQLField('id')
                    ).addSelectionSetItem(
                        new GQLField('agressoId')
                    ).addSelectionSetItem(
                        new GQLField('navn')
                    ).addSelectionSetItem(
                        new GQLField('orgNiv')
                    ).addSelectionSetItem(
                        new GQLField('nomNivaa')
                    ).addSelectionSetItem(
                        new GQLField('orgEnhetsType')
                    ).addSelectionSetItem(
                        organisering
                    )
                )
            ),
            (Object) new Map<String, Object>{ varEnhetid.getName() => enhetId }
        );
        return query.build();
    }
    public static GQLField makeEnhetHierarchy(NOM_Retning direction, Integer depth){
        GQLField leder = new GQLField('leder')
        .addSelectionSetItem(
            new GQLField('ressurs')
                .addSelectionSetItem(new GQLField('navident'))
                .addSelectionSetItem(new GQLField('epost'))
                .addSelectionSetItem(new GQLField('visningsnavn'))
        );

        


        GQLField enhetHierarchy = new GQLField('orgEnhet')
            .addSelectionSetItem(new GQLField('agressoId'))
            .addSelectionSetItem(new GQLField('id'))
            .addSelectionSetItem(new GQLField('navn'))
            .addSelectionSetItem(new GQLField('orgNiv'))
            .addSelectionSetItem(new GQLField('nomNivaa'))
            .addSelectionSetItem(new GQLField('orgEnhetsType'))
            .addSelectionSetItem(leder);

        for (Integer i = 0; i < depth; i++) {
            GQLField organisering = new GQLField('organiseringer')
                .addSelectionSetItem(enhetHierarchy)
                .addSelectionSetItem(new GQLField('retning'))
                .addSelectionSetItem(new GQLField('gyldigFom'))
                .addSelectionSetItem(new GQLField('gyldigTom'));
            if (direction != null) {
                organisering.addArgument(new GQLArgument('retning', new GQLValue(new GQLEnum(direction.name()))));
            }

            GQLField enhet = new GQLField('orgEnhet')
                .addSelectionSetItem(new GQLField('agressoId'))
                .addSelectionSetItem(new GQLField('id'))
                .addSelectionSetItem(new GQLField('navn'))
                .addSelectionSetItem(new GQLField('orgNiv'))
                .addSelectionSetItem(new GQLField('nomNivaa'))
                .addSelectionSetItem(new GQLField('orgEnhetsType'))
                .addSelectionSetItem(leder)
                .addSelectionSetItem(organisering);
            enhetHierarchy = enhet;
        }
        return enhetHierarchy;
    }

    private static void handleError(String message, HttpResponse resp) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('NOM');
        logger.httpError(message, resp, null, null);
        uuid = logger.peek().UUID__c;
        logger.publish();
        throw new NOM_HelperException(message + ' LoggId: ' + uuid);
    }

    public static String logException(Exception e) {
        String uuid;
        LoggerUtility logger = new LoggerUtility('NOM');
        logger.exception(e);
        uuid = logger.peek().UUID__c;
        logger.publish();
        return uuid;
    }

    public static String getRootUnit() {
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if (isSandbox) {
            return ROOT_UNIT_TEST;
        }
        return ROOT_UNIT_PROD;
    }

    public static Set<String> getLederForEnhetIds(NOM_Ressurs ressurs){
        Set<String> enhetIds = new Set<String>();
        if(ressurs.lederFor == null || ressurs.lederFor.size() < 1){
            return enhetIds;
        }
        for(NOM_LederOrgEnhet leder : ressurs.lederFor){
            if(leder.orgEnhet?.Id != null){
                enhetIds.add(leder.orgEnhet.id);
            }
        }
        return enhetIds;
    }

    public class NOM_HelperException extends Exception {
    }
    public class NomIntHelperMalformedCallException extends Exception {}
}
