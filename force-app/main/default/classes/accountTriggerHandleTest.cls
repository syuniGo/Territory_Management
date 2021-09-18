@isTest(SeeAllData=true)
public with sharing class accountTriggerHandleTest {
    @isTest
    static void makeData() {
        List<Account> accList = new List<Account>();
        List<Contact> contList = new List<Contact>();
        List<Opportunity> oppoList = new List<Opportunity>();
        for (Integer i = 0; i < 200; i++) {
            Account newAcc = new Account(
                Name = 'test' + i,
                BillingPostalCode = '11111'
            );
            accList.add(newAcc);
        }
        insert accList;

        for (Account acc : accList) {
            for (Integer i = 0; i < 5; i++) {
                Contact newCont = new Contact(
                    LastName = 'test contact ' + i,
                    AccountId = acc.id
                );
                contList.add(newCont);
                Opportunity newOppo = new Opportunity(
                    Name = 'test oppo ' + i,
                    AccountId = acc.id,
                    StageName = 'Needs Analysis',
                    CloseDate = system.today() + 3
                );
                oppoList.add(newOppo);
            }
        }
        insert contList;
        insert oppoList;

        List<Account> accrList = [
            SELECT
                Name,
                OwnerId,
                BillingPostalCode,
                (SELECT Id, OwnerId FROM Contacts),
                (SELECT Id, OwnerId FROM Opportunities)
            FROM Account
            WHERE Name LIKE 'test%'
        ];
        System.assertEquals(200, accList.size());
        for (Account acc : accrList) {
            integer accName = integer.valueof(acc.name.substring(4));
            if (accName <= 50) {
                //Blake
                acc.BillingPostalCode = '91000';
            } else if (accName > 50 && accName <= 90) {
                //Integration User test user Aaron
                acc.BillingPostalCode = '91002';
            } else if (accName > 90 && accName <= 100) {
                //Jacqueline
                acc.BillingPostalCode = '91010';
            } else if (accName > 100 && accName <= 150) {
                // Jacqueline
                acc.BillingPostalCode = '92010';
            } else {
                //Aaron
                acc.BillingPostalCode = '92020';
            }
        }
        update accrList;

        List<String> accNameList = new List<String>();
        accNameList.add('test50');
        accNameList.add('test80');
        accNameList.add('test81');
        accNameList.add('test82');
        accNameList.add('test83');
        accNameList.add('test84');
        accNameList.add('test85');
        accNameList.add('test86');
        accNameList.add('test100');
        accNameList.add('test150');
        accNameList.add('test199');

        List<Account> accResult = [
            SELECT
                Name,
                Owner.Name,
                (SELECT Id, Owner.Name FROM Contacts),
                (SELECT Id, Owner.Name FROM Opportunities)
            FROM Account
            WHERE Name IN :accNameList
        ];
        Map<String, Account> accNameWithAccMap = new Map<String, Account>();

        for (Account accR : accResult) {
            accNameWithAccMap.put(accR.Name, accR);
        }

        System.debug(accResult.size());

        System.assertEquals(
            'Blake',
            accNameWithAccMap.get('test50').Owner.Name
        );
        System.assertEquals(
            'Aaron',
            accNameWithAccMap.get('test199').Contacts[0].Owner.Name
        );

        for (Integer i = 1; i < 8; i++) {
            String accName = accNameList[i];
            System.debug(
                '随机分配名称：' +
                accNameWithAccMap.get(accNameList[i])
                    .Opportunities[0]
                    .Owner.Name
            );
        }

        Account testAcc1 = [
            SELECT BillingPostalCode
            FROM Account
            WHERE Name = 'test199'
        ];
        System.debug('test199:' + testAcc1);
        testAcc1.BillingPostalCode = '91010';
        update testAcc1;

        Assignment_History__c testAh = [
            SELECT
                Previous_Owner__r.Name,
                New_Owner__r.Name,
                Previous_Territory__c,
                New_Territory__c,
                Changed_By__c,
                Account__c
            FROM Assignment_History__c
            WHERE Account__c = :testAcc1.id
            ORDER BY CreatedDate DESC
            LIMIT 1
        ];

        System.assertEquals('Jacqueline', testAh.New_Owner__r.Name);
        System.assertEquals('Aaron', testAh.Previous_Owner__r.Name);
        System.assertEquals('a015g00000XzTzsAAF', testAh.Previous_Territory__c);
        System.assertEquals('a015g00000XzTzpAAF', testAh.New_Territory__c);

        system.debug('Current User' + testAh.Changed_By__c);
    }
}
