public with sharing class FileConnectSelector {
    
    private static FileConnectSelector selector = null; //private static instance of the class
    /**
* @description Singleton Design Pattern 
* @return
*/
    public static FileConnectSelector getInstance(){
        if(selector == null){
            selector = new FileConnectSelector();
        }
        return selector;
    }
    
    /**
* @description To get the records.
* @param objectName and recordId.
* @return
*/
    public Sobject getRecordsList(string objectName, String recordId){
        String query = 'Select Name FROM '+objectName+ ' WHERE Id=:recordId WITH SECURITY_ENFORCED LIMIT 1';
        Sobject myObj = Database.query(query);
        return myObj;
    }
    
    /**
* @description get Authentication Data. 
* @return List<Key_Configurations__mdt>
*/ 
    public List<Key_Configurations__mdt> getAuthenticationData(String storageType) {
        List<Key_Configurations__mdt> s3List = new List<Key_Configurations__mdt>();
        try {
            List<Storage_Point__mdt> parentMetadata = [SELECT Id,DeveloperName from Storage_Point__mdt where DeveloperName =:storageType];
            s3List = [SELECT Id,DeveloperName,Value__c,Label from Key_Configurations__mdt where parent_Configuration__c =: parentMetadata];
            return s3List;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
}