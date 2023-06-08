public with sharing class NOM_OrgEnhetHelper {

    private static final String ROOT_UNIT_TEST = 'sa312u';
    private static final String ROOT_UNIT_PROD = 'ny410s';

    public static NomUnit__c orgEnhetToNomUnit(NOM_OrgEnhet enhet){
        NomUnit__c unit = new NomUnit__c();
        unit.INT_NomId__c = enhet.id;
        unit.Name = enhet.navn;
        unit.INT_UnitType__c = enhet.orgEnhetsType?.name();
        unit.INT_NomLevel__c = enhet.nomNivaa?.name();
        unit.INT_OrgLevel__c = enhet.orgNiv;
        return unit;
    }

    public static NOM_OrgEnhet nomUnitToOrgEnhet(NomUnit__c unit){
        NOM_OrgEnhet enhet = new NOM_OrgEnhet();
        enhet.Id = unit.INT_NomId__c;
        enhet.navn = unit.Name;
        enhet.orgEnhetsType = unit.INT_UnitType__c != null ? NOM_OrgEnhetsType.valueOf(unit.INT_UnitType__c) : null;
        enhet.nomNivaa = unit.INT_NomLevel__c != null ? NOM_OrgEnhetsKategori.valueOf(unit.INT_NomLevel__c) : null;
        enhet.orgNiv = unit.INT_OrgLevel__c;
        return enhet;
    }
    
    public static NomUnit__c updateNomUnitFromOrgEnhet(NomUnit__c unit, NOM_OrgEnhet enhet){
        unit.Name = enhet.navn;
        unit.INT_UnitType__c = enhet.orgEnhetsType?.name();
        unit.INT_NomLevel__c = enhet.nomNivaa?.name();
        unit.INT_OrgLevel__c = enhet.orgNiv;
        return unit;
    }
    public static Boolean isUpdated(NomUnit__c unit, NOM_OrgEnhet enhet){
        if(
            unit.INT_IsActive__c == true &&
            unit.INT_NomId__c == enhet.id &&
            unit.Name == enhet.navn &&
            unit.INT_UnitType__c == enhet.orgEnhetsType?.name() &&
            unit.INT_NomLevel__c == enhet.nomNivaa?.name() &&
            unit.INT_OrgLevel__c == enhet.orgNiv
        ){
            return false;
        }
        return true;
    }

    public static NOM_OrgEnhet getEnhetHierarchy(String enhetId, NOM_Retning direction, Integer depth){
        
        NOM_OrgEnhet enhet;

        String query = getEnhetQuery(enhetId, direction, depth);

        NOM_Service nom = new NOM_Service(CRM_ApplicationDomain.Domain.CRM);

        try{
            HttpResponse response = nom.queryData(query);
            if(response.getStatusCode() != 200){
                handleError('Kunne ikke hente hierarki for enhet',response);
            }
            enhet = parseEnhetResponse(response.getBody());
        }catch(NOM_HelperException e){
            throw e;
        }catch (Exception e){
            String uuid = logException(e);
            throw new NOM_HelperException(e.getMessage() + ' LoggId: ' + uuid);
        }
        return enhet;
    }

    public static List<NOM_OrgEnhet> getFlatHierarchy(NOM_OrgEnhet hierarchy, NOM_Retning direction){
        List<NOM_OrgEnhet> flatHierarchy = new List<NOM_OrgEnhet>();
        if(hierarchy == null){
            return flatHierarchy;
        }
        flatHierarchy.add(hierarchy);
        List<NOM_OrgEnhet> relatedEnhets = getRelatedEnhets(hierarchy,direction);
        if(relatedEnhets.size() == 0 ){
            return flatHierarchy;
        }
    for(NOM_OrgEnhet e : relatedEnhets){
        flatHierarchy.addAll(getFlatHierarchy(e,direction));
    }
        return flatHierarchy;
    }

    public static Map<String,NOM_OrgEnhet> getFlatMapHierarchy(NOM_OrgEnhet hierarchy, NOM_Retning direction){
        Map<String,NOM_OrgEnhet> flatHierarchy = new Map<String,NOM_OrgEnhet>();
        if(hierarchy == null){
            return flatHierarchy;
        }
        flatHierarchy.put(hierarchy.id, hierarchy);
        List<NOM_OrgEnhet> relatedEnhets = getRelatedEnhets(hierarchy,direction);
        if(relatedEnhets.size() == 0 ){
            return flatHierarchy;
        }
    for(NOM_OrgEnhet e : relatedEnhets){
        flatHierarchy.putAll(getFlatMapHierarchy(e,direction));
    }
        return flatHierarchy;
    }

    public static List<NOM_OrgEnhet> getRelatedEnhets(NOM_OrgEnhet enhet, NOM_Retning direction){
		List<NOM_OrgEnhet> enhets = new List<NOM_OrgEnhet>();
        if(enhet?.organiseringer == null){
            return enhets;
        }

        for(NOM_Organisering org : enhet.organiseringer){
            if(org.orgEnhet == null){
                continue;
            }
            if(direction == null){
                 enhets.add(org.orgEnhet);
            }else if(org.retning == direction){
                enhets.add(org.orgEnhet);
            }
        }
        return enhets;
    }

    public static NOM_OrgEnhet parseEnhetResponse(String body){
        NOM_Response response = (NOM_Response) JSON.deserialize(body,NOM_Response.class);
        if(response?.errors != null && response.errors.size() > 0){
            throw new NOM_HelperException('Error from NOM:\n' + JSON.serializePretty(response.errors));
        }
        if(response?.data?.orgEnhet == null){
            throw new NOM_HelperException('No unit data in response.');
        }
        return response.data.orgEnhet;
    }

    public static String getEnhetQuery(String enhetId, NOM_Retning direction, Integer depth){
        //String enhetId = 'sa312u';
        GQLVariable varEnhetid = new GQLVariable(
            'id',
            new GQLVariableType('String',false, true, false)
        );

        GQLField organisering = new GQLField('organiseringer').addSelectionSetItem(
                            makeEnhetHierarchy(direction, depth-1)
                        ).addSelectionSetItem(
                            new GQLField('retning')
                        ).addSelectionSetItem(
                            new GQLField('gyldigFom')
                        ).addSelectionSetItem(
                            new GQLField('gyldigTom')
                        );
        if(direction != null){
            organisering.addArgument(
                new GQLArgument(
                    'retning',
                    new GQLValue(new GQLEnum(direction.name()))
                )
            );
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
                                new GQLInputObject().addField(
                                    new GQLInputObjectField(
                                        'id',
                                        new GQLValue(varEnhetid)
                                    )
                                )
                            )
                        )
                    


                    ).addSelectionSetItem(
                        new GQLField('leder').addSelectionSetItem(
                            new GQLField('ressurs').addSelectionSetItem(
                                new GQLField('navident')
                            ).addSelectionSetItem(
                                new GQLField('epost')
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
                        organisering
                    )

                )
            ),
            (Object)new Map<String, Object>{varEnhetid.getName() => enhetId}
        );
        return query.build();
    }
    public static GQLField makeEnhetHierarchy(NOM_Retning direction, Integer depth){
        GQLField leder = new GQLField('leder').addSelectionSetItem(
            new GQLField('ressurs').addSelectionSetItem(
                new GQLField('navident')
            ).addSelectionSetItem(
                new GQLField('epost')
            )
        );
        GQLField enhetHierarchy = new GQLField('orgEnhet').addSelectionSetItem(
            new GQLField('agressoId')
        ).addSelectionSetItem(
            new GQLField('id')
        ).addSelectionSetItem(
            new GQLField('navn')
        ).addSelectionSetItem(
            new GQLField('orgNiv')
        ).addSelectionSetItem(
            new GQLField('nomNivaa')
        ).addSelectionSetItem(
            leder
        );
        
       

        for(Integer i = 0; i < depth; i++){

            GQLField organisering = new GQLField('organiseringer').addSelectionSetItem(
                enhetHierarchy
            ).addSelectionSetItem(
                new GQLField('retning')
            ).addSelectionSetItem(
                new GQLField('gyldigFom')
            ).addSelectionSetItem(
                new GQLField('gyldigTom')
            );
            if(direction != null){
                organisering.addArgument(
                    new GQLArgument(
                        'retning',
                        new GQLValue(new GQLEnum(direction.name()))
                    )
                );
            }

            GQLField enhet = new GQLField('orgEnhet').addSelectionSetItem(
                new GQLField('agressoId')
            ).addSelectionSetItem(
                new GQLField('id')
            ).addSelectionSetItem(
                new GQLField('navn')
            ).addSelectionSetItem(
                new GQLField('orgNiv')
            ).addSelectionSetItem(
                new GQLField('nomNivaa')
            ).addSelectionSetItem(
                new GQLField('orgEnhetsType')
            ).addSelectionSetItem(
                leder
            ).addSelectionSetItem(
                organisering
            );
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

    public static String getRootUnit(){
        Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
        if(isSandbox){
            return ROOT_UNIT_TEST;
        }
        return ROOT_UNIT_PROD;
    }

    public class NOM_HelperException extends Exception{}
}