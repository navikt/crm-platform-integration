public without sharing class CRM_PersonMerge {
    private Account masterAccount;
    private Id masterPersonId;
    private String masterActorId;
    private Set<String> actorIdsToMerge;
    private Set<String> personIdentsToMerge;
    private Set<Id> accountsToMerge;
    private Set<Id> personsToDelete;
    private Set<Id> usersToDisable;
    private List<Database.MergeResult> mergeAccountResults;
    private List<Database.DeleteResult> personDeleteResults;
    Map<Id, User> userByAccountMap;
    private Savepoint sp;
    private Boolean hasErrors {
        get {
            return !(this.errors == null || this.errors.isEmpty());
        }
    }
    private List<String> errors;
    private LoggerUtility logger;

    public CRM_PersonMerge() {
        this.logger = new LoggerUtility('Person merge');
        this.actorIdsToMerge = new Set<String>();
        this.personIdentsToMerge = new Set<String>();
        this.accountsToMerge = new Set<Id>();
        this.personsToDelete = new Set<Id>();
        this.userByAccountMap = new Map<Id, User>();
        this.errors = new List<String>();
    }

    public Boolean isMergeSuccess() {
        return !hasErrors;
    }

    public CRM_PersonMerge startMerge() {
        sp = Database.setSavepoint();

        try {
            this.addPersonsRelatedToAccounts()
                .findAccountRecords()
                .findRecordsRelatedToActorIds()
                .getCommunityUsers()
                .setMasterAccountFromUser()
                .mergeAccounts()
                .updatePerson()
                .deletePersons()
                .removeThirdPartyAccountLinkKey();
        } catch (CRM_PersonMergeException e) {
            this.errors.add(e.getMessage());
            logMergeError(e.getMessage());
        } catch (Exception e) {
            this.errors.add(e.getMessage());
            logger.exception(e, masterAccount);
        } finally {
            if (logger.peek() != null) {
                logger.publish();
            }
            if (this.hasErrors) {
                Database.rollback(sp);
            }
        }

        return this;
    }

    public CRM_PersonMerge getIdentsFromPDL(String actorId) {
        PDL_API_QueryHelper pdlQuery = new PDL_API_QueryHelper(actorId, true, false);
        pdlQuery.addIdentGruppe(PDL_API_IdentGruppeQuery.AKTORID);
        pdlQuery.selectAll();

        PDL_API_Response response = pdlQuery.execute();

        for (PDL_IdentInformasjon ident : response.data.hentIdenter.identer) {
            if (ident.gruppe == PDL_IdentGruppe.AKTORID) {
                if (ident.historisk) {
                    this.addActorIdToMerge(ident.ident);
                } else {
                    this.setMasterActor(ident.ident);
                }
            }
        }

        return this;
    }

    public CRM_PersonMerge addPersonIdentToMerge(String personIdent) {
        this.personIdentsToMerge.add(personIdent);
        return this;
    }

    public CRM_PersonMerge addActorIdToMerge(String actorId) {
        return this.addActorIdToMerge(new List<String>{ actorId });
    }

    public CRM_PersonMerge addActorIdToMerge(List<String> actorIds) {
        this.actorIdsToMerge.addAll(actorIds);
        return this;
    }

    public CRM_PersonMerge setMasterActor(String actorId) {
        this.masterActorId = actorId;
        this.actorIdsToMerge.add(this.masterActorId);
        return this;
    }

    public CRM_PersonMerge addAccountToMerge(Account acc) {
        return this.addAccountToMerge(acc.Id);
    }

    public CRM_PersonMerge addAccountToMerge(Id accountId) {
        if (accountId != masterAccount?.Id) {
            this.accountsToMerge.add(accountId);
        }
        return this;
    }

    public CRM_PersonMerge addPersonToMerge(Person__c person) {
        return this.addPersonToMerge(person.Id);
    }

    public CRM_PersonMerge addPersonToMerge(Id personId) {
        if (String.isNotBlank(personId)) {
            this.personsToDelete.add(personId);
        }
        return this;
    }

    public CRM_PersonMerge setMasterAccount(Account acc) {
        return this.setMasterAccount(acc.Id);
    }

    public CRM_PersonMerge setMasterAccount(Id accId) {
        if (masterAccount != null) {
            this.accountsToMerge.add(masterAccount.Id);
        }

        this.accountsToMerge.remove(accId);
        this.masterAccount = new Account(Id = accId);

        return this;
    }

    public CRM_PersonMerge setMasterPerson(Person__c person) {
        return this.setMasterPerson(person.Id);
    }

    public CRM_PersonMerge setMasterPerson(Id personId) {
        this.addPersonToMerge(this.masterPersonId);
        this.masterPersonId = personId;

        if (this.personsToDelete.contains(this.masterPersonId)) {
            this.personsToDelete.remove(this.masterPersonId);
        }

        return this;
    }

    public List<String> getMergeErrors() {
        return this.errors;
    }

    private CRM_PersonMerge getCommunityUsers() {
        this.userByAccountMap = new Map<Id, User>();
        List<Id> accountIdList = new List<Id>();
        if (this.masterAccount != null) {
            accountIdList.add(this.masterAccount.Id);
        }
        accountIdList.addAll(accountsToMerge);

        if (accountIdList.isEmpty() == false) {
            for (User u : [
                SELECT Id, AccountId, Account.INT_IsHasTombstone__c
                FROM User
                WHERE AccountId IN :accountIdList AND IsActive = TRUE
            ]) {
                this.userByAccountMap.put(u.AccountId, u);
            }
        }

        return this;
    }

    private CRM_PersonMerge setMasterAccountFromUser() {
        if (this.userByAccountMap.isEmpty()) {
            return this;
        }

        if (this.userByAccountMap.size() == 1) {
            this.setMasterAccount(new List<Id>(this.userByAccountMap.keySet())[0]);
            return this;
        }

        Id tempMasterAccount;
        for (Id accountId : this.userByAccountMap.keySet()) {
            if (
                this.userByAccountMap.get(accountId).Account.INT_IsHasTombstone__c == false &&
                this.masterAccount?.Id == accountId
            ) {
                return this;
            }
        }
        this.setMasterAccount(tempMasterAccount);

        return this;
    }

    private CRM_PersonMerge removeThirdPartyAccountLinkKey() {
        List<User> userList = new List<User>();
        for (ThirdPartyAccountLink tpal : [
            SELECT Id, Provider, ThirdPartyAccountLinkKey, UserId, SsoProviderId
            FROM ThirdPartyAccountLink
            WHERE UserId IN :usersToDisable
        ]) {
            if (
                false ==
                Auth.AuthToken.revokeAccess(
                    tpal.SsoProviderId,
                    tpal.Provider,
                    tpal.UserId,
                    tpal.ThirdPartyAccountLinkKey
                )
            ) {
                this.errors.add('Could not revoke access for ThirdPartyAccountLink with Id: ' + tpal.Id);
                this.logger.error(
                    'Could not revoke access for ThirdPartyAccountLink when merging person accounts',
                    tpal
                );
            }
        }
        return this.checkForErrors('Failed to remove third party account link key');
    }

    private CRM_PersonMerge findRecordsRelatedToActorIds() {
        for (Person__c person : [
            SELECT Id, INT_IsHasTombstone__c, CRM_Account__c, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :new List<String>(actorIdsToMerge)
        ]) {
            if (person.INT_IsHasTombstone__c == false || this.masterActorId == person.INT_ActorId__c) {
                this.setMasterPerson(person);
                this.setMasterAccount(person.CRM_Account__c);
            } else {
                this.addPersonToMerge(person);
                this.addAccountToMerge(person.CRM_Account__c);
            }
        }

        return this;
    }

    private CRM_PersonMerge addPersonsRelatedToAccounts() {
        List<Id> accountIdList = new List<Id>(this.accountsToMerge);
        accountIdList.add(masterAccount?.Id);

        if (accountIdList.isEmpty()) {
            return this;
        }

        for (Person__c person : [SELECT Id, INT_ActorId__c FROM Person__c WHERE CRM_Account__c IN :accountIdList]) {
            this.addActorIdToMerge(person.INT_ActorId__c);
        }

        return this;
    }

    private CRM_PersonMerge findAccountRecords() {
        List<Id> personIdList = new List<Id>(this.personsToDelete);

        if (String.isNotBlank(this.masterPersonId)) {
            personIdList.add(this.masterPersonId);
        }

        if (personIdList.isEmpty() && this.personIdentsToMerge.isEmpty()) {
            return this;
        }

        for (Account acc : [
            SELECT Id, CRM_Person__c, CRM_Person__r.INT_ActorId__c
            FROM Account
            WHERE CRM_Person__c IN :PersonIdList OR INT_PersonIdent__c IN :this.personIdentsToMerge
        ]) {
            if (acc.CRM_Person__c == null) {
                this.addAccountToMerge(acc);
            } else {
                this.addActorIdToMerge(acc.CRM_Person__r.INT_ActorId__c);
            }
        }

        return this;
    }

    private CRM_PersonMerge mergeAccounts() {
        this.masterAccount.CRM_Person__c = this.masterPersonId;
        mergeAccountResults = Database.merge(masterAccount, new List<Id>(accountsToMerge), false);

        for (Database.MergeResult res : mergeAccountResults) {
            if (res.isSuccess()) {
                continue;
            }
            this.handleDatabaseErrors(res.getErrors());
        }

        return this.checkForErrors('Failed to merge PersonAccounts');
    }

    private CRM_PersonMerge checkForErrors(String errorMessage) {
        if (this.hasErrors) {
            throw new CRM_PersonMergeException(errorMessage);
        }
        return this;
    }

    private CRM_PersonMerge deletePersons() {
        personDeleteResults = Database.Delete(new List<Id>(personsToDelete), false);

        for (Database.DeleteResult res : personDeleteResults) {
            if (res.isSuccess()) {
                continue;
            }
            this.handleDatabaseErrors(res.getErrors());
        }

        return this.checkForErrors('Failed to delete Person__c records');
    }

    private CRM_PersonMerge updatePerson() {
        Database.SaveResult sr = Database.update(
            new Person__c(Id = this.masterPersonId, CRM_Account__c = this.masterAccount.Id)
        );

        if (sr.isSuccess()) {
            return this;
        }

        this.handleDatabaseErrors(sr.getErrors());
        return this.checkForErrors('Failed to update Person__c with Account');
    }

    @TestVisible
    private void handleDatabaseErrors(List<Database.Error> databaseErrors) {
        for (Database.Error err : databaseErrors) {
            errors.add(err.getMessage());
        }
    }

    @TestVisible
    private void logMergeError(String message) {
        logger.error(message, masterAccount);
        logger.peek().Payload__c =
            '{' +
            '\r\n\t"mergeAccountResult": ' +
            JSON.serializePretty(this.mergeAccountResults) +
            ',\r\n\t"deleteAccountResult": ' +
            JSON.serializePretty(this.personDeleteResults) +
            ',\r\n\t"masterPersonId": ' +
            this.masterPersonId +
            ',\r\n\t"masterActorId": ' +
            this.masterActorId +
            ',\r\n\t"actorIdsToMerge": ' +
            JSON.serializePretty(this.actorIdsToMerge) +
            ',\r\n\t"personIdentsToMerge": ' +
            JSON.serializePretty(this.personIdentsToMerge) +
            ',\r\n\t"accountsToMerge": ' +
            JSON.serializePretty(this.accountsToMerge) +
            ',\r\n\t"personsToDelete": ' +
            JSON.serializePretty(this.personsToDelete) +
            ',\r\n\t"usersToDisable": ' +
            JSON.serializePretty(this.usersToDisable) +
            ',\r\n\t"errors": ' +
            JSON.serializePretty(this.errors) +
            '\r\n}';
    }
}
