public without sharing class CRM_PersonMerge {
    private Account masterAccount;
    private Id masterPersonId;
    private String masterActorId;
    private Set<String> actorIdsToMerge;
    private Set<String> personIdentsToMerge;
    private Set<Id> accountsToMerge;
    private Set<Id> personsToDelete;
    private Set<Id> usersToRevokeAccess;
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
        this.usersToRevokeAccess = new Set<Id>();
        this.userByAccountMap = new Map<Id, User>();
        this.errors = new List<String>();
    }

    /**
     * @description Indicate if the merge is successfull or not
     * @author Tor Håkon Sigurdsen
     * @return   return true if no errors are reported
     */
    public Boolean isMergeSuccess() {
        return !hasErrors;
    }
    /**
     * @description Merges all the accounts, persons and idents that is reported.
     * Order of execution:
     * 1. Find all persons related to the reported accounts
     * 2. Find all accounts related to persons and reported idents
     * 3. Find all records related to actor Id's
     * 4. Get all the community users related to the accounts
     * 5. If any users are present, override master account based on this
     * 6. Update the master person with the related account
     * 7. Merge accounts
     * 8. Delete all the persons not related to the account
     * 9. Remove ThirdPartyAccountLinks if present
     *
     * If any errors are reported a rollback is performed
     * @author Tor Håkon Sigurdsen
     * @return   CRM_PersonMerge
     */
    public CRM_PersonMerge startMerge() {
        sp = Database.setSavepoint();

        try {
            this.findAccountRecords()
                .findRecordsRelatedToActorIds()
                .getCommunityUsers()
                .setMasterAccountFromUser()
                .updatePerson()
                .mergeAccounts()
                .deletePersons()
                .removeThirdPartyAccountLink();
        } catch (CRM_PersonMergeException e) {
            this.errors.add(e.getMessage());
            this.logMergeError(e.getMessage());
        } catch (Exception e) {
            this.errors.add(e.getMessage());
            this.logger.exception(e, masterAccount);
        } finally {
            if (this.logger.peek() != null) {
                this.logger.publish();
            }
            if (this.hasErrors) {
                Database.rollback(sp);
            }
        }

        return this;
    }

    /**
     * @description Call hentIdenter from PDL and get all actorIds related to the supplied actorId
     * @author Tor Håkon Sigurdsen
     * @param  actorId actorId to base PDL query on
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge getIdentsFromPDL(String actorId) {
        PDL_API_QueryHelper pdlQuery = new PDL_API_QueryHelper(actorId, true, false);
        pdlQuery.addIdentGruppe(PDL_API_IdentGruppeQuery.AKTORID);
        pdlQuery.hentIdenter.historikk = true;
        pdlQuery.selectAll();

        PDL_API_Response response = pdlQuery.execute();

        if (response.errors?.size() > 0) {
            for (PDL_Error error : response.errors) {
                this.errors.add(JSON.serializePretty(error));
            }
            this.checkForErrors('Failed to retrieve Idents: ' + JSON.serializePretty(response.errors[0]));
        }

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

    /**
     * @description Add an ident to user in the merge
     * @author Tor Håkon Sigurdsen
     * @param  personIdent any valid ident. Fodselsnummer, D-nummer or NPID
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge addPersonIdentToMerge(String personIdent) {
        this.personIdentsToMerge.add(personIdent);
        return this;
    }

    /**
     * @description Add an actorId to user in the merge
     * @author Tor Håkon Sigurdsen
     * @param  actorId ActorId only, not Fodselsnummer, D-nummer or NPID
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge addActorIdToMerge(String actorId) {
        this.actorIdsToMerge.add(actorId);
        return this;
    }

    /**
     * @description set the actorId to use as master actor
     * @author Tor Håkon Sigurdsen
     * @param  actorId ActorId only, not Fodselsnummer, D-nummer or NPID
     * @return         CRM_PersonMerge
     */
    public CRM_PersonMerge setMasterActor(String actorId) {
        this.masterActorId = actorId;
        this.actorIdsToMerge.add(this.masterActorId);
        return this;
    }

    /**
     * @description Add SF id of an Account to merge
     * @author Tor Håkon Sigurdsen
     * @param  accountId SF Account Id
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge addAccountToMerge(Id accountId) {
        if (accountId != masterAccount?.Id) {
            this.accountsToMerge.add(accountId);
        }
        return this;
    }

    /**
     * @description Add SF id of a Person__c to merge
     * @author Tor Håkon Sigurdsen
     * @param  personId SF Person__c Id
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge addPersonToMerge(Id personId) {
        if (String.isNotBlank(personId)) {
            this.personsToDelete.add(personId);
        }
        return this;
    }

    /**
     * @description Set the Account ID of the master account record
     * @author Tor Håkon Sigurdsen
     * @param  accId Account SF record id
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge setMasterAccount(Id accId) {
        if (masterAccount != null) {
            this.accountsToMerge.add(masterAccount.Id);
        }

        this.accountsToMerge.remove(accId);
        this.masterAccount = new Account(Id = accId);

        return this;
    }

    /**
     * @description Set the Person__c ID of the master person record
     * @author Tor Håkon Sigurdsen
     * @param  personId Person__c SF record id
     * @return CRM_PersonMerge
     */
    public CRM_PersonMerge setMasterPerson(Id personId) {
        this.addPersonToMerge(this.masterPersonId);
        this.masterPersonId = personId;

        if (this.personsToDelete.contains(this.masterPersonId)) {
            this.personsToDelete.remove(this.masterPersonId);
        }

        return this;
    }

    /**
     * @description Get all the errors from the merge process
     * @author Tor Håkon Sigurdsen
     * @return List<String>
     */
    public List<String> getMergeErrors() {
        return this.errors;
    }

    /**
     * @description Get the active community users related to the accounts to merge and put them in a Map<Id,User> based of User.AccountId
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    private CRM_PersonMerge getCommunityUsers() {
        this.userByAccountMap = new Map<Id, User>();
        List<Id> accountIdList = new List<Id>();
        if (this.masterAccount != null) {
            accountIdList.add(this.masterAccount.Id);
        }
        accountIdList.addAll(this.accountsToMerge);

        if (accountIdList.isEmpty() == false) {
            for (User u : [
                SELECT Id, AccountId, Account.INT_IsHasTombstone__c, IsActive
                FROM User
                WHERE AccountId IN :accountIdList AND IsActive = TRUE
            ]) {
                this.usersToRevokeAccess.add(u.Id);
                this.userByAccountMap.put(u.AccountId, u);
            }
        }

        return this;
    }

    /**
     * @description Check if we have any active users. And if we do, use the related account as the master account in order to keep the user.
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
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
            tempMasterAccount = accountId;
        }
        this.setMasterAccount(tempMasterAccount);

        return this;
    }

    /**
     * @description check if we need to remove any third party account link and then call future.
     * @author Tor Håkon Sigurdsen
     * @return  CRM_PersonMerge
     */
    private CRM_PersonMerge removeThirdPartyAccountLink() {
        if (this.usersToRevokeAccess.size() > 0) {
            if (System.isBatch()) {
                CRM_PersonMerge.removeThirdPartyAccountLink(this.usersToRevokeAccess);
            } else {
                CRM_PersonMerge.removeThirdPartyAccountLinkAsync(this.usersToRevokeAccess);
            }
        }
        return this;
    }
    /**
     * @description If any ThirdPartyAccountLink records related to the users, remove them
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    @Future(callout=true)
    private static void removeThirdPartyAccountLinkAsync(Set<Id> userIds) {
        CRM_PersonMerge.removeThirdPartyAccountLink(userIds);
        // LoggerUtility log = new LoggerUtility('Person merge');
        // List<User> userList = new List<User>();
        // for (ThirdPartyAccountLink tpal : [
        //     SELECT Id, Provider, RemoteIdentifier, UserId, SsoProviderId
        //     FROM ThirdPartyAccountLink
        //     WHERE UserId IN :userIds
        // ]) {
        //     if (
        //         false ==
        //         Auth.AuthToken.revokeAccess(tpal.SsoProviderId, tpal.Provider, tpal.UserId, tpal.RemoteIdentifier)
        //     ) {
        //         log.error('Could not revoke access for ThirdPartyAccountLink when merging person accounts', tpal);
        //     }
        // }

        // if (log.peek() != null) {
        //     log.publish();
        // }
    }

    /**
     * @description If any ThirdPartyAccountLink records related to the users, remove them
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    public static void removeThirdPartyAccountLink(Set<Id> userIds) {
        LoggerUtility log = new LoggerUtility('Person merge');
        List<User> userList = new List<User>();
        for (ThirdPartyAccountLink tpal : [
            SELECT Id, Provider, RemoteIdentifier, UserId, SsoProviderId
            FROM ThirdPartyAccountLink
            WHERE UserId IN :userIds
        ]) {
            if (
                false ==
                Auth.AuthToken.revokeAccess(tpal.SsoProviderId, tpal.Provider, tpal.UserId, tpal.RemoteIdentifier)
            ) {
                log.error('Could not revoke access for ThirdPartyAccountLink when merging person accounts', tpal);
            }
        }

        if (log.peek() != null) {
            log.publish();
        }
    }

    /**
     * @description Query for Person__c records related to the actorIds including the related Accounts. Use them to set persons and accounts to merge.
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    private CRM_PersonMerge findRecordsRelatedToActorIds() {
        for (Person__c person : [
            SELECT Id, INT_IsHasTombstone__c, CRM_Account__c, INT_ActorId__c
            FROM Person__c
            WHERE INT_ActorId__c IN :new List<String>(actorIdsToMerge)
        ]) {
            if (person.INT_IsHasTombstone__c == false || this.masterActorId == person.INT_ActorId__c) {
                this.setMasterPerson(person.Id);
                this.setMasterAccount(person.CRM_Account__c);
            } else {
                this.addPersonToMerge(person.Id);
                this.addAccountToMerge(person.CRM_Account__c);
            }
        }

        return this;
    }

    /**
     * @description Find Account records based on the supplied accountIds, personIds and personIdents in order to add any accounts/persons that might be missing.
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    private CRM_PersonMerge findAccountRecords() {
        List<Id> personIdList = new List<Id>(this.personsToDelete);
        List<Id> accountIdList = new List<Id>(this.accountsToMerge);

        if (String.isNotBlank(this.masterAccount?.Id)) {
            accountIdList.add(this.masterAccount.Id);
        }
        if (String.isNotBlank(this.masterPersonId)) {
            personIdList.add(this.masterPersonId);
        }

        if (personIdList.isEmpty() && this.personIdentsToMerge.isEmpty()) {
            return this;
        }

        for (Account acc : [
            SELECT Id, CRM_Person__c, CRM_Person__r.INT_ActorId__c
            FROM Account
            WHERE
                Id IN :accountIdList
                OR CRM_Person__c IN :PersonIdList
                OR INT_PersonIdent__c IN :this.personIdentsToMerge
        ]) {
            if (acc.CRM_Person__c == null) {
                this.addAccountToMerge(acc.Id);
            } else {
                this.addActorIdToMerge(acc.CRM_Person__r.INT_ActorId__c);
            }
        }

        return this;
    }

    /**
     * @description Call Database.merge on the accounts
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
    private CRM_PersonMerge mergeAccounts() {
        this.masterAccount.CRM_Person__c = this.masterPersonId;
        this.mergeAccountResults = new List<Database.MergeResult>();
        List<Id> accountList = new List<Id>();

        //We can only merge a master account with two other accounts at the time so if we have more than 3 accounts to merge we need to run it in a loop
        for (Id accId : accountsToMerge) {
            accountList.add(accId);
            if (accountList.size() == 2) {
                this.mergeAccountResults.addAll(Database.merge(masterAccount, accountList, false));
                accountList.clear();
            }
        }

        if (accountList.size() > 0) {
            this.mergeAccountResults.addAll(Database.merge(masterAccount, accountList, false));
        }

        for (Database.MergeResult res : mergeAccountResults) {
            if (res.isSuccess()) {
                continue;
            }
            this.handleDatabaseErrors(res.getErrors());
        }

        return this.checkForErrors('Failed to merge PersonAccounts');
    }

    /**
     * @description Throws CRM_PersonMergeException if any errors are added
     * @author Tor Håkon Sigurdsen
     * @param  errorMessage Message to add to exception if any errors are detected
     * @return CRM_PersonMerge
     */
    private CRM_PersonMerge checkForErrors(String errorMessage) {
        if (this.hasErrors) {
            throw new CRM_PersonMergeException(errorMessage);
        }
        return this;
    }

    /**
     * @description Delete the persons not added as master account in order to avoid duplicate persons
     * @author Tor Håkon Sigurdsen
     * @return CRM_PersonMerge
     */
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

    /**
     * @description Add master account to master person in order to trigger a correct update of the master account.
     * @author Tor Håkon Sigurdsen
     * @return  CRM_PersonMerge
     */
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

    /**
     * @description Method to log errors with extended payload
     * @author Tor Håkon Sigurdsen
     * @param  message to add to application log
     */
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
            ',\r\n\t"usersToRevokeAccess": ' +
            JSON.serializePretty(this.usersToRevokeAccess) +
            ',\r\n\t"errors": ' +
            JSON.serializePretty(this.errors) +
            '\r\n}';
    }
}
