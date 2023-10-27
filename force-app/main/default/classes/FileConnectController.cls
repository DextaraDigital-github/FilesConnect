/**
* Class Name        : FileConnectController
* Developer         : Priyanka    
* Created Date      : 9-10-2023
* @description       : FileConnectController class is controller class for component.
* Last Modified Date: 19-10-2023
*/
public with sharing class FileConnectController {
    
    static FileConnectSelector selector = FileConnectSelector.getInstance();
    static FileConnectService fileService = FileConnectService.getInstance();
    
    // GoogleDrive controllers  
    /**
* @description get files from a folder.
* @param folderId This is a folderId.
* @return drive files fromm a folder
*/   
    @AuraEnabled
    public static Map<String,Map<String,String>> fileList(String folderId) {
        Map<String,Map<String,String>> filesMap = new  Map<String,Map<String,String>>();
        try {
            if(folderId != null){
                filesMap = fileService.fileList(folderId);
            }
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return filesMap;
    }
    
    /**
* @description create a folder in the google drive.
* @param recordId This is a recordId.
* @return created folder Id.
*/   
    @AuraEnabled 
    public static String folderCreation(Id recordId) {
        String folderId;
        try {
            if(recordId != null ){
                folderId = fileService.folderCreation(recordId);
            }
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return folderId;
    }
    
    /**
* @description upload a file a folder in the google drive.
* @param fileBlob This is a blob file for uploading.
* @param folderId This is a folderId.
* @param fileName This is the file name. 
*/   
    @AuraEnabled(Cacheable= true)
    public static void uploadFileToFolder(Blob fileBlob, String folderId, String fileName,String fileType) {
        try {
            if(folderId != null && fileBlob != null && fileName != null){
                fileService.UploadFile(fileBlob,folderId,fileName,fileType);
            }
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }  
    }
    
    /**
* @description delete a file from google drive folder.
* @param fileId This is a fileId.
*/   
    @AuraEnabled
    public static void deleteFile(String fileId) {
        try {
            if(fileId != null ){
                fileService.deleteFile(fileId);
            }
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }  
    }
    
    /**
* @description download the content of a file.
* @param fileId This is a fileId.
* @return blob content of a file.
*/   
    @AuraEnabled
    public static Blob downloadFile(String fileId) {
        try {
            if(fileId != null ) {
                return fileService.downloadFile(fileId);
            }
            else {
                return null; 
            }
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        
    }
    // GoogleDrive controllers  
    
    
    //AWS Controllers
    
    /**
* @description get Authentication Data. 
* @return List<Dx_File__Key_Configurations__mdt>
*/ 
    @AuraEnabled
    public static List<Dx_File__Key_Configurations__mdt> getAWSAuthenticationData() {
        List<Dx_File__Key_Configurations__mdt> s3List = new List<Dx_File__Key_Configurations__mdt>();
        try {
            s3List = selector.getAuthenticationData('AWS');
            return s3List;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description get Signed Url for download file.
* @param location This is a AWS file url.
* @param file This is the keyUrl of a file. 
* @param expires This is minutes to be expired in. 
* @return Download File URL
*/ 
    @AuraEnabled
    public static String getFileSignedUrl(String location, String file, Integer expires) {
        try {
            String signedURL;
            if(location != null && file != null && expires > 0) {
                signedURL = fileService.getSignedURL(location, file, expires); 
            }
            return signedURL;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description upload File from salesforce to S3.
* @param recId This is the record Id.
* @param objectName This is the object name of a record.
* @param pathRecId This is the recordId.
* @param deleteFlag This is the deleteFlag.
* @return flag on uploaded successfully
*/ 
    @AuraEnabled
    /* sfge-disable-stack ApexFlsViolationRule */
    public static Boolean uploadFiles(Id recId, String objectName,Id pathRecId,Boolean deleteFlag, Id userId) {
        Boolean uploadedFlag = false;
        try {
            if(recId != null && objectName != null && userId != null) {
                
                uploadedFlag=fileService.uploadFiles(recId, objectName, pathRecId, deleteFlag, userId);
            }
            return uploadedFlag;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    //AWS Controllers
    
    
    //Sharepoint controllers
    /**
* @description get Authentication Data. 
* @return List<Dx_File__Key_Configurations__mdt>
*/ 
    @AuraEnabled
    public static List<Dx_File__Key_Configurations__mdt> getSPAuthenticationData() {
        List<Dx_File__Key_Configurations__mdt> s3List = new List<Dx_File__Key_Configurations__mdt>();
        try {
            s3List = selector.getAuthenticationData('Sharepoint');
            return s3List;
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description get Access token. 
* @return acesstoken.
*/ 
    @AuraEnabled
    public static String makeRequest() 
    {
        String accessToken;
        try {
            accessToken = fileService.makeRequest();
            
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return accessToken;
    }
    
    /**
* @description get the folder Id.
* @param recordId This is a recordId.
* @return folder Ids.
*/   
    @AuraEnabled
    public static List<String> getFolderId(String recordId) {
        List<String> folderIdList =new List<String>();
        try {
            if(recordId != null){
                folderIdList = fileService.getFolderId(recordId);
            }
            
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return folderIdList;
    }
    
    /**
* @description get files from a folder.
* @param sharefolderIds This is a folderIds.
* @param searchContent This is for serach keyword.
* @return drive files fromm a folder
*/   
    @AuraEnabled
    public static Map<String,Map<String,String>> FilesList(List<String> sharefolderIds,String searchContent){
        Map<String,Map<String,String>> filesMap=new Map<String,Map<String,String>>();
        try {
            if(sharefolderIds.size() > 0){
                filesMap = fileService.FilesList(sharefolderIds,searchContent);
            }
            
        } catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return filesMap;
    }
    
   
}