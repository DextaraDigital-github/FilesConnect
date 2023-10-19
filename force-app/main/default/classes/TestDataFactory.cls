/**
* Class Name   : AssessmentController
* Developer         :  Sai Koushik Nimmaturi and Reethika Velpula      
* Created Date      :
* @description       : TestDataFactory class is used to create test data.
* Last Modified Date:
*/


public with sharing class TestDataFactory{


    /**
    * @description createRecords methods is used to create the records for all objects.
    * @param records This is a list of records to insert.  
    * @param doInsert This is boolean value whether to insert record or not.
    * @param attributes This is a map which contain record data to insert.
    * @return
    */
    public static List<SObject> createRecords(List<SObject> records, Boolean doInsert, Map<String, Object> attributes){
        try{
            Integer i = 0;
            if(attributes != null){
                for (Integer j =0; j < records.size(); j ++) {
                    SObject record = records[j];
                    for (String key : attributes.keySet()) {
                        Object value = attributes.get(key);
                        if (value instanceof List<Object>) {
                            Object obj = ((List<Object>) value).get(i);
                            if( obj instanceof SObject ){
                                Id sObjectId = ((SObject) obj).Id;
                                record.put( key,sObjectId );
                            }
                            else {
                                record.put(key,obj);
                            }
                        } else {
                            record.put(key, value);
                        }
                    }
                    i++;
                }
            }
            if (doInsert) {
                Savepoint sp = Database.setSavepoint();
                Database.SaveResult[] srList1 = database.insert(records);
            }
        } catch(Exception e){
			system.debug('createRecords Exception --->'+e);
            throw new AuraHandledException(e.getMessage());
        }
        return records;
    }

    /**
    * @description createAccounts method is used to create account records.
    * @param numToInsert This is a number of records to insert.  
    * @param doInsert This is boolean value whether to insert record or not.
    * @param attributes This is a map which contain record data to insert.
    * @return
    */

    public static List<Account> createAccounts(Integer numToInsert, Boolean doInsert, Map<String, Object> attributes){
        List<Account> accountsToInsert = new List<Account>();
        for(Integer i=0; i< numToInsert; i++){
            Account acc = new Account();
            acc.Name = 'TestAccount' + i;
            accountsToInsert.add(acc);
        }
        return createRecords(accountsToInsert, doInsert, attributes);
    }
    /**
    * @description createContacts method is used to create Contacts records
    * @param numToInsert This is a number of records to insert.  
    * @param doInsert This is boolean value whether to insert record or not.
    * @param attributes This is a map which contain record data to insert.
    * @return
    */  
     
    public static List<Contact> createContacts(Integer numToInsert, Boolean doInsert, Map<String, Object> attributes){
    List<contact> contactsToInsert = new List<Contact>();
        for(Integer i=0; i< numToInsert; i++){
            Contact ct=new Contact();
            contactsToInsert.add(ct);
        }
        return createRecords(contactsToInsert, doInsert, attributes);
    }
    /**
    * @description createUser method is used to create Users records
    * @param numToInsert This is a number of records to insert.  
    * @param doInsert This is boolean value whether to insert record or not.
    * @param attributes This is a map which contain record data to insert.
    * @return
    */ 
    public static List<User> createUser(Integer numToInsert, Boolean doInsert, Map<String, Object> attributes){
        List<user> usersToInsert = new List<user>();
        for(Integer i=0; i< numToInsert; i++){
            user u=new user();
            usersToInsert.add(u);
        }
        return createRecords(usersToInsert, doInsert, attributes);
    }

     /**
    * @description createUser method is used to create Role records
    * @return
    */ 
    public static UserRole createTestRole(){
        UserRole ur = new UserRole(Name = 'CEO');
        List<UserRole> lstuserRole = new List<UserRole>();
        lstuserRole.add(ur);
        List<UserRole> retUserRole = createRecords(lstuserRole, true, new Map<String, Object>());
        return retUserRole[0];
    }
    /**
    * @description createUser method is used to create Users records
    * @return
    */ 
    public static User createTestUser(){
        UserRole ur = createTestRole();
        Profile portalProfile = [SELECT Id FROM Profile WHERE Name='Standard Platform User' WITH SECURITY_ENFORCED Limit 1];
        List<user> lstuser = new List<User>();
        String orgId = UserInfo.getOrganizationId();
        String dateString = String.valueof(Datetime.now()).replace(' ','').replace(':','').replace('-','');
        Integer randomInt = Integer.valueOf(math.rint(math.random()*1000000));
        String uniqueName = orgId + dateString + randomInt;
        String uniqueUserName = uniqueName + '@test' + orgId + '.org';
        User u = new User(Alias = 'standt', Email='standarduser@testorg.com',
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US',
        LocaleSidKey='en_US', ProfileId = portalProfile.Id,
        TimeZoneSidKey='America/Los_Angeles',
        UserName=uniqueUserName,UserRoleId =ur.Id);
        lstuser.add(u);
        set<Id> userId = new set<Id>();
        List<user> retUser = createRecords(lstuser, true, new Map<String, Object>());
        userId.add(retUser[0].Id);
        assignPermissionSetToUsers(userId);
        return retUser[0];
    }

    /**
    * @description AssignPermissionSetToUsers method is used to assign permission sets.
    * @param usersId set of userids.
    */ 
    public static void assignPermissionSetToUsers (Set<Id> usersId) {
        List<PermissionSetAssignment> permissionSetList = new List<PermissionSetAssignment>();
        List<PermissionSet> permissionstobeassigned = [SELECT Id, Label FROM PermissionSet WHERE Name IN ('Customer_Access','Additional_Access') WITH SECURITY_ENFORCED];
        for (User u : [Select Id, Name FROM User Where Id IN : usersId WITH SECURITY_ENFORCED]){
            for(PermissionSet ps : permissionstobeassigned){
                PermissionSetAssignment psa = new PermissionSetAssignment ();
                    psa.PermissionSetId = ps.Id; 
                    psa.AssigneeId = u.Id;
                permissionSetList.add(psa);
            }
        }

        Savepoint sp = Database.setSavepoint();
        Database.UpsertResult[] srList1 = database.upsert(permissionSetList);
       
    }

 

	/**
    * @description createContentVersion method is used to create contentversion records
    * @param numToInsert This is a number of records to insert.  
    * @param doInsert This is boolean value whether to insert record or not.
    * @param attributes This is a map which contain record data to insert.
    * @return
    */
    public static List<ContentVersion> createContentVersion(Integer numToInsert, Boolean doInsert, Map<String, Object> attributes){
        List<ContentVersion> insertContentVer = new List<ContentVersion>();
        for(Integer i=0; i< numToInsert; i++){
            ContentVersion cv = new ContentVersion();
            cv.Title = 'Test Document';
            cv.PathOnClient = 'TestDocument.pdf';
            cv.VersionData = Blob.valueOf('Test Content');
            cv.IsMajorVersion = true;
            insertContentVer.add(cv);
        }
        return createRecords(insertContentVer, doInsert, attributes);
    }
   

    /**
    * @description It is used to throw the exception.
    */
    public class SecurityControllerException extends Exception{
            
    }
}