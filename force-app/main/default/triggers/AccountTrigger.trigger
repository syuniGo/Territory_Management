trigger AccountTrigger on Account(
    before insert,
    before update,
    after insert,
    after update
) {
    if (Trigger.isAfter) {
        if (Trigger.isUpdate) {
            List<Account> newAccs = new List<Account>();
            List<Account> oldAccs = new List<Account>();

            for (Id accountId : Trigger.newMap.keySet()) {
                if (
                    Trigger.oldMap.get(accountId).BillingPostalCode !=
                    Trigger.newMap.get(accountId).BillingPostalCode
                ) {
                    newAccs.add(Trigger.newMap.get(accountId));
                    oldAccs.add(Trigger.oldMap.get(accountId));
                }
            }
            accountTriggerHandle.zipCodeChangeHandle(newAccs, oldAccs);
        } else if (Trigger.isInsert) {
            accountTriggerHandle.zipCodeChangeHandle(Trigger.new);
        }
    }
}
