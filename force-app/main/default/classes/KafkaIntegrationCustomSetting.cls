public without sharing class KafkaIntegrationCustomSetting {

    @TestVisible
    private static KafkaIntegrationConfig__c testKafkaConfig = null;

    public static KafkaIntegrationConfig__c getKafkaConfig() {
        if (Test.isRunningTest() && testKafkaConfig != null) {
            return testKafkaConfig;
        }

        KafkaIntegrationConfig__c config = KafkaIntegrationConfig__c.getOrgDefaults();
        if (config.Name == null || Test.isRunningTest()) {
            config.SetupOwnerId = UserInfo.getOrganizationId();
            config.ProcessingEnabled__c = true;
            config.DeleteProcessedRecords__c = false;
            config.IntegrationUserId__c = null;
            if (!Test.isRunningTest()) {
                insert config;
            } else {
                testKafkaConfig = config;
            }
        }
        return config;
    }

    public static Boolean processingEnabled {
        get {
            return getKafkaConfig().ProcessingEnabled__c;
        }
    }

    public static Boolean deleteProcessedRecords {
        get {
            return getKafkaConfig().DeleteProcessedRecords__c;
        }
    }

    public static String integrationUserId {
        get {
            return getKafkaConfig().IntegrationUserId__c;
        }
    }
}