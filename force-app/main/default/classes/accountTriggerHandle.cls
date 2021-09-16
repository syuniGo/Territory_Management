public with sharing class accountTriggerHandle {
    public static void zipCodeChangeHandle(List<Account> accRecords) {
        Set<Id> accIdSet = new Set<Id>();
        Set<String> zipCodeSet = new Set<String>();

        for (Account acc : accRecords) {
            accIdSet.add(acc.id);
            zipCodeSet.add(acc.BillingPostalCode);
        }
        System.debug(zipCodeSet);

        List<Account> accInfos = [
            SELECT
                Name,
                OwnerId,
                BillingPostalCode,
                (SELECT Id, OwnerId FROM Contacts),
                (SELECT Id, OwnerId FROM Opportunities)
            FROM Account
            WHERE Id IN :accIdSet
        ];
        System.debug(accInfos.size());

        Map<String, Account> idWithAccMap = new Map<String, Account>();
        for (Account accInfo : accInfos) {
            idWithAccMap.put(accInfo.id, accInfo);
        }

        system.debug([SELECT Account_Owner__c, Zip_Code__c FROM Territory__c]);
        List<Territory__c> terrInfos = [
            SELECT Account_Owner__c, Zip_Code__c
            FROM Territory__c
            WHERE Zip_Code__c IN :zipCodeSet
        ];
        System.debug('找到的terr：' + terrInfos.size());
        if (terrInfos.size() != 0) {
            Map<String, List<Territory__c>> zipCodeWithTerrMap = new Map<String, List<Territory__c>>();
            List<String> duplicateList = new List<String>();
            for (Territory__c terr : terrInfos) {
                List<Territory__c> mapTerr = new List<Territory__c>();
                if (!duplicateList.contains(terr.Zip_Code__c)) {
                    duplicateList.add(terr.Zip_Code__c);
                    mapTerr.add(terr);
                    zipCodeWithTerrMap.put(terr.Zip_Code__c, mapTerr);
                } else {
                    zipCodeWithTerrMap.get(terr.Zip_Code__c).add(terr);
                }
            }
            system.debug(zipCodeWithTerrMap);

            List<Account> accToUpdate = new List<Account>();
            List<Contact> contToUpdate = new List<Contact>();
            List<Opportunity> oppoToUpdate = new List<Opportunity>();
            List<Assignment_History__c> ahToInsert = new List<Assignment_History__c>();
            for (Account accR : accRecords) {
                Account accInfo = idWithAccMap.get(accR.id);

                List<Territory__c> resultTerr = zipCodeWithTerrMap.get(
                    accR.BillingPostalCode
                );

                System.debug(resultTerr);
                Integer listSize = resultTerr.size();
                String ownerId;
                if (listSize == 1) {
                    ownerId = resultTerr[0].Account_Owner__c;
                } else {
                    Integer randomNumber = Integer.valueof(
                        (Math.random() * listSize)
                    );
                    System.debug('随机数' + randomNumber);
                    ownerId = resultTerr[randomNumber].Account_Owner__c;
                    System.debug('随机数' + ownerId);
                }

                accInfo.OwnerId = ownerId;
                accToUpdate.add(accInfo);

                List<Contact> conts = accInfo.Contacts;
                for (Contact cont : conts) {
                    cont.OwnerId = ownerId;
                    contToUpdate.add(cont);
                }
                List<Opportunity> oppos = accInfo.Opportunities;
                for (Opportunity oppo : oppos) {
                    oppo.OwnerId = ownerId;
                    oppoToUpdate.add(oppo);
                }

                Assignment_History__c ah = new Assignment_History__c(
                    Previous_Owner__c = accInfo.OwnerId
                );
            }
            update accToUpdate;
            update contToUpdate;
            update oppoToUpdate;
        }
    }
}
