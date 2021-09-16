trigger TerritoryTrigger on Territory__c(
    before insert,
    before update,
    after insert,
    after update
) {
    if (Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {
        System.debug('1');

        TerritoryTriggerHandle.territoryHandle(Trigger.new);
        System.debug('2');
    }
}
