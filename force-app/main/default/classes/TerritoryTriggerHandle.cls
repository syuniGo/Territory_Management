public with sharing class TerritoryTriggerHandle {
    public static void territoryHandle(
        List<Territory__c> terrRecords,
        Boolean isUpdate
    ) {
        Set<String> zipCodeSet = new Set<String>();

        for (Territory__c terrRecord : terrRecords) {
            zipCodeSet.add(terrRecord.Zip_Code__c);
        }

        LIst<Territory__c> terrInfos = [
            SELECT Zip_Code__c, Account_Owner__c
            FROM Territory__c
            WHERE Zip_Code__c IN :zipCodeSet
        ];

        Map<String, List<Territory__c>> zipCodeWithTerrMap = new Map<String, List<Territory__c>>();
        List<String> duplicateList = new List<String>();
        for (Territory__c terrInfo : terrInfos) {
            List<Territory__c> mapTerr = new List<Territory__c>();
            if (!duplicateList.contains(terrInfo.Zip_Code__c)) {
                duplicateList.add(terrInfo.Zip_Code__c);
                mapTerr.add(terrInfo);
                zipCodeWithTerrMap.put(terrInfo.Zip_Code__c, mapTerr);
            } else {
                zipCodeWithTerrMap.get(terrInfo.Zip_Code__c).add(terrInfo);
            }
        }

        for (Territory__c terrRecord : terrRecords) {
            System.debug(terrRecord);
            if (terrRecord.Account_Owner__c != null) {
                List<Territory__c> terrList = zipCodeWithTerrMap.get(
                    terrRecord.Zip_Code__c
                );

                List<String> accOwnerIdList = new List<String>();
                for (Territory__c terr : terrList) {
                    accOwnerIdList.add(terr.Account_Owner__c);
                }

                System.debug(terrList);
                if (terrList.size() > 3 && isUpdate) {
                    terrRecord.addError(
                        'This zip code already have 3 account owner'
                    );
                    terrRecord.Account_Owner__c.addError(
                        'This zip code already have 3 account owner'
                    );
                }
                if (terrList.size() >= 3 && !isUpdate) {
                    terrRecord.addError(
                        'This zip code already have 3 account owner'
                    );
                    terrRecord.Account_Owner__c.addError(
                        'This zip code already have 3 account owner'
                    );
                }
            }
        }
    }

    public static void accountOwnerChangeHandle(
        List<Territory__c> newRecords,
        List<Territory__c> oldRecords
    ) {
        Set<String> terrZipCodeSet = new Set<String>();
        for (Territory__c newRecord : newRecords) {
            terrZipCodeSet.add(newRecord.Zip_Code__c);
        }
        Map<String, Territory__c> oldRecordMap = new Map<String, Territory__c>();
        for (Territory__c oldRecord : oldRecords) {
            oldRecordMap.put(oldRecord.id, oldRecord);
        }

        List<Account> relateAccs = [
            SELECT OwnerId, BillingPostalCode, Owner.Name
            FROM Account
            WHERE BillingPostalCode IN :terrZipCodeSet
        ];

        Map<String, Map<String, List<Account>>> zipCodeWithOwnIdWithAccMap = new Map<String, Map<String, List<Account>>>();

        Set<String> duplicateZipCode = new Set<String>();
        Set<String> duplicateOwnId = new Set<String>();

        for (Account relateAcc : relateAccs) {
            Map<String, List<Account>> valueMap = new Map<String, List<Account>>();
            List<Account> newValueList = new List<Account>();

            if (!duplicateZipCode.contains(relateAcc.BillingPostalCode)) {
                //如果第一层map的不包括这个acc的zipcode的情况下 创建新的valueMap
                duplicateZipCode.add(relateAcc.BillingPostalCode);
                duplicateOwnId.add(relateAcc.OwnerId);

                newValueList.add(relateAcc);
                valueMap.put(relateAcc.OwnerId, newValueList);
                zipCodeWithOwnIdWithAccMap.put(
                    relateAcc.BillingPostalCode,
                    valueMap
                );
            } else if (!duplicateOwnId.contains(relateAcc.OwnerId)) {
                //如果第一层包含acc的zipcode则判断是否包含ownerid 如果不包含这根据zipcode找到之前创建的valuemap 添加新值
                newValueList.add(relateAcc);
                zipCodeWithOwnIdWithAccMap.get(relateAcc.BillingPostalCode)
                    .put(relateAcc.OwnerId, newValueList);
            } else {
                //如果ownerid 也存在 这找到valueMap内的 valueList添加新值
                zipCodeWithOwnIdWithAccMap.get(relateAcc.BillingPostalCode)
                    .get(relateAcc.OwnerId)
                    .add(relateAcc);
            }
        }

        System.debug('找到relative accs:' + relateAccs);
        System.debug('map！！:' + zipCodeWithOwnIdWithAccMap);

        List<Account> accToUpdate = new List<Account>();
        for (Territory__c newRecord : newRecords) {
            //根据zipcode和ownerid找到关联的accList
            System.debug(newRecord.Account_Owner__c);
            Territory__c oldTerr = oldRecordMap.get(newRecord.id);
            System.debug(
                '旧owner名1' +
                oldRecordMap.get(newRecord.id).Account_Owner__r.name
            );
            List<Account> relateAccList = zipCodeWithOwnIdWithAccMap.get(
                    oldTerr.Zip_Code__c
                )
                .get(oldTerr.Account_Owner__c);

            System.debug('实际relative accs:' + relateAccList);
            if (relateAccList != null) {
                for (Account relateAcc : relateAccList) {
                    System.debug('旧owner名2' + relateAcc.Owner.Name);
                    System.debug('新owner名' + newRecord.Account_Owner__c);
                    relateAcc.OwnerId = newRecord.Account_Owner__c;
                    accToUpdate.add(relateAcc);
                }
            }
        }
        system.debug(accToUpdate);
        update accToUpdate;
    }
}
