@isTest
public with sharing class accOwnerLimitHanldeTest {
    @TestSetup
    static void makeData() {
        List<Territory__c> terrToInsert = new List<Territory__c>();
        List<String> userId = new List<String>();
        userId.add('0055g00000CzuSvAAJ');
        userId.add('0055g00000DV9k7AAD');
        userId.add('0055g00000DV9jxAAD');
        for (Integer i = 0; i < 3; i++) {
            Territory__c testTerr = new Territory__c(
                Zip_Code__c = '94665',
                Account_Owner__c = userId[i]
            );
            terrToInsert.add(testTerr);
        }

        insert terrToInsert;
    }
    @isTest
    public static void accOwnerLimitHanldeTest() {
        Territory__c testTerr = new Territory__c(
            Zip_Code__c = '94665',
            Account_Owner__c = '0055g00000Cx58kAAB'
        );
        insert testTerr;
    }
}
