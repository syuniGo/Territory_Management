public with sharing class TerritoryTriggerHandle {
    public static void territoryHandle(List<Territory__c> terrRecords) {
        Set<String> zipCodeSet = new Set<String>();

        for (Territory__c terrRecord : terrRecords) {
            zipCodeSet.add(terrRecord.Zip_Code__c);
        }

        LIst<Territory__c> terrInfos = [
            SELECT Zip_Code__c, Account_Owner__c
            FROM Territory__c
            WHERE Zip_Code__c IN :zipCodeSet
        ];
        Map<String, Integer> zipcodeWithOwnerNumMap = new Map<String, Integer>();

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
                System.debug(terrList);
                if (terrList.size() > 3) {
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
}
