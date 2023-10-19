/** 
* Class Name        : AWSS3ServiceQueueable
* Developer         : Priyanka         
* Created Date      : 11-07-2023
* @description      : AWSS3ServiceQueueable class is used to upload Files to AWS S3.
* Last Modified Date: 11-07-2023
*/
public class AWSS3ServiceQueueable implements Queueable, Database.AllowsCallouts {
   
    public Id recId;
    public Id userId;
    public Id pathRecId;
    public Boolean deleteFlag;
    public String objectName;
    public Set<Id> contVerIds;
    
    private static AWSS3ServiceQueueable service = null; //private static instance of the class
    
    /**
* @description Singleton Design Pattern
* @return
*/
    public static AWSS3ServiceQueueable getInstance(){
        if(service == null){
            service = new AWSS3ServiceQueueable();
        }
        return service;
    }
    
    
    /**
* @description execute method used for Execute Queueable Context.
* @param context This is the Input QueueableContext
*/ 
    public void execute(QueueableContext context) {
        try{
            List<String> errorList = new List<String>();
            List<Id> contDocIds = new List<Id>();
            Set<Id> contentDocumentIds = new Set<Id>();
            List<ContentVersion> versionData =new List<ContentVersion>();
            if( recId != null && objectName != null) {
                List<ContentDocumentLink> condocList= [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:recId];
                if(condocList.size() > 0 || contVerIds.size() > 0) {
                    if(condocList.size() > 0) { 
                        for(ContentDocumentLink condoc:condocList) {
                            contDocIds.add(condoc.ContentDocumentId);
                        }
                        versionData= [SELECT Id, Title, FileExtension, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN:contDocIds];
                    }
                    else if(contVerIds.size() > 0) {
                        versionData= [SELECT Id, Title, FileExtension, ContentDocumentId, VersionData FROM ContentVersion WHERE Id IN:contVerIds];
                    }
                    if(versionData.size() > 0) {
                        
                        for(ContentVersion conver:versionData) {
                            contentDocumentIds.add(conver.ContentDocumentId);
                            FileConnectService putAttachment = new FileConnectService();
                            putAttachment.recordId = recId;
                            if(pathRecId == null) {
                                putAttachment.folderName='/'+ objectName +'/'+ recId ;
                            }
                            else {
                                putAttachment.folderName='/'+objectName+'/'+pathRecId;  
                            }
                            if(userId != null) {
                                putAttachment.folderName= putAttachment.folderName + '/' + userId;
                            }
                            putAttachment.versionData=conver;
                            String name = conver.Title.substringBeforeLast('.');
                            name = name.replaceAll(' ','_');
                            // Name = name.replaceAll('[^a-zA-Z0-9 -]', '');
                            name = name.replace('(', '');
                            name = name.replace(')', '');
                            name = name.replaceAll('-','');
                            Datetime datetimeVal = Datetime.now(); // Returns the current Datetime based on a GMT calendar.
                            String timeStamp = datetimeVal.format('yyyyMMdd\'T\'HHmmss');
                            putAttachment.fileName =timeStamp+'_'+name;
                            putAttachment.fileBody = conver.VersionData;
                            putAttachment.ContentType = conver.FileExtension;
                            putAttachment.init();
                        }
                        if(deleteFlag == true) {
                            List<ContentDocument> conList= [SELECT Id FROM ContentDocument where ContentAssetId = null And Id IN: contentDocumentIds];
                            List<Database.DeleteResult> deleteResult = Database.delete(conList);
                        }
                    }
                    
                 
                }
            }
            
        }
        catch(Exception e)
        {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }  
    }
    

}