/**
 * Tests for KodeverkCalloutService and associated classes:
 *   KodeverkResponse
 *   KodeverkHelper
 */
@IsTest
private class KodeverkCalloutServiceTest {

    @IsTest
    static void responseIsDeserializable() {
        String jsonString = '{"betydninger":{"6484":[{"gyldigFra":"2009-02-25","gyldigTil":"2022-12-31","beskrivelser":{"nb":{"term":"SANDØY","tekst":"SANDØY"}}}]}}';
        KodeverkResponse response = KodeverkResponse.parse(jsonString);
        Assert.isTrue(response.betydninger.keySet().contains('6484'));
        //Assert.areEqual('SANDØY', response.betydninger.get('6484')[0].beskrivelser.get('nb').term);
    }

    @IsTest
    static void inactiveCodeIsNotAdded() {
        String jsonString = '{"betydninger":{"6484":[{"gyldigFra":"2009-02-25","gyldigTil":"2022-12-31","beskrivelser":{"nb":{"term":"SANDØY","tekst":"SANDØY"}}}]}}';
        KodeverkResponse response = KodeverkResponse.parse(jsonString);
        Common_Code__c[] codes = KodeverkHelper.getCodesFromMeaningMap('Postnummer', response.betydninger);
        Assert.areEqual(0, codes.size());
    }

    @IsTest
    static void inactiveCodeIsDeactivated() {
        Common_Code__c before = new Common_Code__c(
            Name = 'Forente kolonier',
            CRM_Code_Set__c = 'Landkoder',
            CRM_Code__c = 'UC',
            CRM_Active__c = true
        );
        insert before;
        String jsonString = '{"betydninger":{"UC":[{"gyldigFra":"1-12-25","gyldigTil":"33-04-18","beskrivelser":{"nb":{"term":"Under Kristus","tekst":"Lenge siden"}}},{"gyldigFra":"1620-09-06","gyldigTil":"1776-09-08","beskrivelser":{"nb":{"term":"Forente kolonier","tekst":"Den nye verden"}}}]}}';
        KodeverkResponse response = KodeverkResponse.parse(jsonString);
        Common_Code__c[] codes = KodeverkHelper.getCodesFromMeaningMap('Landkoder', response.betydninger);
        Test.startTest();
        upsert codes;
        Common_Code__c[] all = [SELECT CRM_Active__c FROM Common_Code__c];
        Common_Code__c after = all[0];
        Test.stopTest();
        Assert.areEqual(1, all.size());
        Assert.isTrue(before.CRM_Active__c);
        Assert.isFalse(after.CRM_Active__c);
    }

    @IsTest
    static void lastCodeTakesPrecedence() {
        String jsonString = '{"betydninger":{"4934":[{"gyldigFra":"1900-01-01","gyldigTil":"2013-09-12","beskrivelser":{"nb":{"term":"NESGRENDA","tekst":"NESGRENDA"}}},{"gyldigFra":"2013-09-13","gyldigTil":"9999-12-31","beskrivelser":{"nb":{"term":"NES VERK","tekst":"NES VERK"}}}]}}';
        KodeverkResponse response = KodeverkResponse.parse(jsonString);
        Common_Code__c[] codes = KodeverkHelper.getCodesFromMeaningMap('Postnummer', response.betydninger);
        Assert.areEqual(1, codes.size());
        Assert.areEqual('NES VERK', codes[0].Name);
    }

    /**
     * Runs a start-to-finish test with mock data. Note that even though this
     * data contains currencies, the code set used must exist in the picklist
     * for Common_Code__c.CRM_Code_Set__c, so we use one that does.
     */
    @IsTest
    static void entireChainWithMockCallout() {
        Test.setMock(HttpCalloutMock.class, new KodeverkMockCallout());
        Test.startTest();
        KodeverkCalloutService.storeCodes(new Set<String>{'Postnummer'});
        Test.stopTest();
        Common_Code__c[] inserted = [
            SELECT Name, CRM_Code_Set__c, CRM_Code__c, CRM_UniqueKey__c
            FROM Common_Code__c
            ];
        Common_Code__c[] active = [
            SELECT Name, CRM_Code_Set__c, CRM_Code__c, CRM_UniqueKey__c
            FROM Common_Code__c
            WHERE CRM_Active__c = true
            ];
        Common_Code__c brl = [SELECT Name FROM Common_Code__c WHERE CRM_Code__c = 'BRL'];
        System.debug(JSON.serializePretty(inserted));
        Assert.areEqual(2, inserted.size());
        Assert.areEqual(active.size(), inserted.size());
        Assert.areEqual('Real', brl.Name);
    }

    /**
     * Tests that trying to get a nonexistent kodeverk throws a
     * CalloutException, due to the response being a 404.
     */
    @IsTest
    static void getNonExistentCodeThrowsException() {
        Test.setMock(HttpCalloutMock.class, new KodeverkMockCallout());
        Test.startTest();
        try {
            KodeverkHelper.getMeaningMap(KodeverkMockCallout.BAD_KODEVERK);
            Assert.fail();
        } catch (CalloutException ce) {
            System.debug(ce);
        } catch (Exception e) {
            Assert.fail();
        }
        Test.stopTest();
    }
}
