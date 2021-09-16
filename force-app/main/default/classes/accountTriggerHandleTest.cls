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
                acc.BillingPostalCode = '91000';
            } else if (accName > 50 && accName <= 80) {
                acc.BillingPostalCode = '91001';
            } else if (accName > 80 && accName <= 100) {
                acc.BillingPostalCode = '91010';
            } else if (accName > 100 && accName <= 150) {
                acc.BillingPostalCode = '92010';
            } else {
                acc.BillingPostalCode = '92020';
            }
        }
        update accrList;

        List<String> accNameList = new List<String>();
        accNameList.add('test50');
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
        System.debug(accResult.size());

        List<String> userName = new List<String>();
        userName.add('Blake');
        userName.add('Jacqueline');
        userName.add('Denise');
        userName.add('Aaron');

        for (Integer i = 0; i < 4; i++) {
            String uName = userName[i];
            Account accRe = accResult[i];
            Contact contRe = accResult[i].contacts[0];
            Opportunity oppoRe = accResult[i].Opportunities[0];
            System.assertEquals(uName, contRe.Owner.Name);
            System.assertEquals(uName, accRe.Owner.Name);
            System.assertEquals(uName, oppoRe.Owner.Name);
        }
    }
}
