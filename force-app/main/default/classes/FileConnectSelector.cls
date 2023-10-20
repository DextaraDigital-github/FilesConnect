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
* @return List<Dx_File__Key_Configurations__mdt>
*/ 
    public List<Dx_File__Key_Configurations__mdt> getAuthenticationData(String storageType) {
        List<Dx_File__Key_Configurations__mdt> s3List = new List<Dx_File__Key_Configurations__mdt>();
        try {
            List<Dx_File__Storage_Point__mdt> parentMetadata = [SELECT Id,DeveloperName from Dx_File__Storage_Point__mdt where DeveloperName =:storageType];
            s3List = [SELECT Id,DeveloperName,Dx_File__Value__c,Label from Dx_File__Key_Configurations__mdt where Dx_File__parent_Configuration__c =: parentMetadata];
            return s3List;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
}