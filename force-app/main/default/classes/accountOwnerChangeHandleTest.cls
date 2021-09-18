@isTest(SeeAllData=true)
public with sharing class accountOwnerChangeHandleTest {
    @isTest
    static void makeData() {
        List<Account> accList = new List<Account>();
        for (Integer i = 0; i < 200; i++) {
            Account newAcc = new Account(
                Name = 'test' + i,
                BillingPostalCode = '91010'
            );
            accList.add(newAcc);
        }

        insert accList;

        Territory__c testTerr1 = [
            SELECT Account_Owner__c, Account_Owner__r.Name
            FROM Territory__c
            WHERE Zip_Code__c = '91010'
        ];
        testTerr1.Account_Owner__c = '0055g00000CzuSvAAJ';
        update testTerr1;

        Territory__c testTerr2 = [
            SELECT Account_Owner__c, Account_Owner__r.Name
            FROM Territory__c
            WHERE Zip_Code__c = '91010'
        ];

        System.debug(
            'test terr update name:' + testTerr2.Account_Owner__r.Name
        );
        List<Account> testAccList = [
            SELECT Owner.Name
            FROM Account
            WHERE name LIKE 'test%' AND Owner.Name = 'test user'
        ];
        System.debug('更新后的list' + testAccList);

        System.assertEquals('test user', testAccList[0].Owner.Name);
    }
}
