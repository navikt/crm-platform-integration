public inherited sharing class KafkaSykefravaerHandler implements IKafkaMessageConsumer {

    public void processMessages(List<KafkaMessage__c> messages) {
        Map<String, PotensieltDagsverk> pdByOrgNumber = new Map<String, PotensieltDagsverk>();
        for (KafkaMessage__c msg : messages) {
            try {
                String decodedValue = EncodingUtil.base64Decode(msg.CRM_Value__c).toString();
                PotensieltDagsverk pd = (PotensieltDagsverk) JSON.deserialize(decodedValue, KafkaSykefravaerHandler.PotensieltDagsverk.class);
                pdByOrgNumber.put(pd.orgnr, pd);
            } catch (Exception e) {
                msg.CRM_Error__c = e.getMessage() + ' (' + e.getLineNumber() + ')';
            }
        }

        Map<String, Account> accountByOrgNumber = new Map<String, Account>();
        for (Account acc : [SELECT Id, INT_OrganizationNumber__c, INT_PotentialMandays__c FROM Account WHERE INT_OrganizationNumber__c IN :pdByOrgNumber.keySet()]) {
            accountByOrgNumber.put(acc.INT_OrganizationNumber__c, acc);
        }

        List<Account> accountsToUpdate = new List<Account>();
        for (String orgNr : pdByOrgNumber.keySet()) {
            Account acc = accountByOrgNumber.get(orgNr);
            Integer pd = pdByOrgNumber.get(orgNr).potensielleDagsverk;
            if(accountByOrgNumber.containsKey(orgNr) && acc.INT_PotentialMandays__c != pd) {
                acc.INT_PotentialMandays__c = pd;
                accountsToUpdate.add(acc);
            }
        }

        update accountsToUpdate;
    }

    public class PotensieltDagsverk {
        String orgnr;
        Integer potensielleDagsverk;
    }

}
