trigger TerritoryTrigger on Territory__c(
    before insert,
    before update,
    after insert,
    after update
) {
    if (Trigger.isBefore) {
        Boolean isUpdate;
        if (Trigger.isInsert) {
            System.debug('TerritoryTriggerHandle excute');
            isUpdate = false;
            TerritoryTriggerHandle.territoryHandle(Trigger.new, isUpdate);
        }
        if (Trigger.isUpdate) {
            isUpdate = true;
            TerritoryTriggerHandle.territoryHandle(Trigger.new, isUpdate);
        }
    }

    if (Trigger.isAfter && Trigger.isUpdate) {
        System.debug('if territory account_owner  change relate account owner');
        List<Territory__c> newTerrs = new List<Territory__c>();
        List<Territory__c> oldTerrs = new List<Territory__c>();
        for (Id terrId : Trigger.newMap.keySet()) {
            if (
                Trigger.oldMap.get(terrId).Account_Owner__c !=
                Trigger.newMap.get(terrId).Account_Owner__c
            ) {
                newTerrs.add(Trigger.newMap.get(terrId));
                oldTerrs.add(Trigger.oldMap.get(terrId));
            }
        }
        TerritoryTriggerHandle.accountOwnerChangeHandle(newTerrs, oldTerrs);
    }
}
