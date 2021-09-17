public with sharing class accountTriggerHandle {
    public static void zipCodeChangeHandle(
        List<Account> newAccs,
        List<Account> oldAccs
    ) {
        Set<Id> accIdSet = new Set<Id>();
        Set<String> zipCodeSet = new Set<String>();

        for (Account acc : newAccs) {
            accIdSet.add(acc.id);
            zipCodeSet.add(acc.BillingPostalCode);
        }
        System.debug(zipCodeSet);
        Map<Id, Account> oldAccsMap = new Map<Id, Account>();
        for (Account oldAcc : oldAccs) {
            oldAccsMap.put(oldAcc.id, oldAcc);
        }

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

        List<Territory__c> terrInfos = [
            SELECT Account_Owner__c, Zip_Code__c
            FROM Territory__c
        ];
        System.debug('找到的terr：' + terrInfos.size());

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
        for (Account accR : newAccs) {
            if (zipCodeWithTerrMap.keySet().contains(accR.BillingPostalCode)) {
                Account accInfo = idWithAccMap.get(accR.id);
                Account oldAcc = oldAccsMap.get(accR.id);
                List<Territory__c> resultTerr = zipCodeWithTerrMap.get(
                    accR.BillingPostalCode
                );

                System.debug(resultTerr);
                Integer listSize = resultTerr.size();
                Territory__c newTerr = new Territory__c();
                if (listSize == 1) {
                    newTerr = resultTerr[0];
                } else {
                    Integer randomNumber = Integer.valueof(
                        (Math.random() * listSize)
                    );

                    newTerr = resultTerr[randomNumber];
                }
                String ownerId = newTerr.Account_Owner__c;
                accInfo.OwnerId = ownerId;
                accToUpdate.add(accInfo);
                Territory__c oldTerr = new Territory__c();
                if (
                    oldAcc.BillingPostalCode != null &&
                    zipCodeWithTerrMap.keySet()
                        .contains(oldAcc.BillingPostalCode)
                ) {
                    List<Territory__c> oldTerrResult = zipCodeWithTerrMap.get(
                        oldAcc.BillingPostalCode
                    );
                    for (Territory__c oldTerrR : oldTerrResult) {
                        if (oldTerrR.Account_Owner__c == oldAcc.Owner.Name) {
                            oldTerr = oldTerrR;
                        }
                    }
                }

                Assignment_History__c ah = new Assignment_History__c(
                    Previous_Owner__c = accR.OwnerId,
                    New_Owner__c = accInfo.OwnerId,
                    Previous_Territory__c = oldTerr.id,
                    New_Territory__c = newTerr.id,
                    Account__c = accR.id,
                    Changed_By__c = UserInfo.getUserId()
                );
                ahToInsert.add(ah);

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
            }
        }

        update accToUpdate;
        update contToUpdate;
        update oppoToUpdate;
        insert ahToInsert;
    }
}
