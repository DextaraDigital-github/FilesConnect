public with sharing class FileConnectService extends AWS {
    private static FileConnectService serviceClass = null; //private static instance of the class
    static FileConnectSelector selector = FileConnectSelector.getInstance();
    
    
    /**
* @description Singleton Design Pattern
* @return
*/
    public static FileConnectService getInstance(){
        if(serviceClass == null){
            serviceClass = new FileConnectService();
        }
        return serviceClass;
    }
    
    //Sharepoint Variables and method
    Public Static    string spEndpoint;
    Public Static    string contype;
    Public Static    string clientid;
    Public Static    string resource;
    Public Static    string granttype;
    Public Static    string clientsecret;
    Public Static    string foldersapi;
    Public Static    string recordapi;
    Public Static    string endpointUrl;
    Public Static    string serverurl;
    Public Static    String fileendpointUrl;
    
    /**
* @description get Authentication Data. 
* @return List<Key_Configurations__mdt>
*/  
    public List<Key_Configurations__mdt> getAuthenticationData() {
        List<Key_Configurations__mdt> s3List = new List<Key_Configurations__mdt>();
        Map<String, String> s3Map = new Map<String, String>();
        try {
            s3List = selector.getAuthenticationData('Sharepoint');
            if(s3List.size() > 0){ 
                for(Key_Configurations__mdt s3:s3List) {
                    s3Map.put(s3.Label,s3.Value__c);
                } 
                if(s3Map.size() > 0) {
                    spEndpoint = s3Map.get('SPendpoint'); 
                    contype = s3Map.get('Content-Type');  
                    clientid = s3Map.get('client_id');
                    clientsecret = s3Map.get('client_secret');
                    granttype = s3Map.get('grant_type');
                    resource = s3Map.get('resource');
                    foldersapi = s3Map.get('getfoldersapi'); 
                    recordapi = s3Map.get('getrecordfolder');
                    endpointUrl = s3Map.get('folderapi');
                    serverurl = s3Map.get('ServerRelativeUrl');
                    fileendpointUrl = s3Map.get('fileslisturl');
                    
                }           
            }
            
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
    public String makeRequest() {
        String accessToken;
        try{
            getAuthenticationData();
            
            Http https = new Http();   
            HttpRequest request = new HttpRequest();
            
            request.setEndpoint(spEndpoint);
            request.setMethod('GET');
            request.setHeader('Content-Type', contype);
            String RequestBody = 'grant_type='+granttype+'&client_id='+clientid+'&client_secret='+clientsecret+'&resource='+resource;
            request.setBody(RequestBody);
            
            HttpResponse response = new HttpResponse();
            response = https.send(request);
            
            String responseBody = response.getBody();
            Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            accessToken = (String) responseMap.get('access_token');   
        }
        catch(exception e) {
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
    public List<String> getFolderId(String recordId){
        List<String> folderIdList=new List<String>();
        try {            
            getAuthenticationData();
            
            String accessToken=makeRequest();
            HttpRequest request = new HttpRequest();
            request.setEndpoint(foldersapi);
            request.setHeader('Authorization', 'Bearer ' + accessToken);
            request.setHeader('Accept', 'application/json');
            request.setMethod('GET');
            
            Http http = new Http();
            HttpResponse response = http.send(request);
            List<String> uniqueIds = new List<String>();
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            
            if (jsonResponse.containsKey('value')) {
                List<Object> folders = (List<Object>) jsonResponse.get('value');
                
                for (Object folderObj : folders) {
                    Map<String, Object> folder = (Map<String, Object>) folderObj;
                    
                    if (folder.containsKey('Name')) {
                        String uniqueId = (String) folder.get('UniqueId');
                        uniqueIds.add(uniqueId);                        
                    }
                }
            }
            
            if(uniqueIds.contains(recordId)){
                //here we have to get the folder or files of this recordId name
                
                folderIdList.add(recordId);
                String UserID=UserInfo.getUserId()+' '+UserInfo.getUserName();
                HttpRequest request2 = new HttpRequest();
                request2.setEndpoint(recordapi.replace('recordId', recordId));
                
                
                request2.setHeader('Authorization', 'Bearer ' + accessToken);
                request2.setHeader('Accept', 'application/json');
                request2.setMethod('GET');
                
                Http http2 = new Http();
                HttpResponse response2 = http2.send(request2);
                List<String> uniqueIds2 = new List<String>();
                Map<String, Object> jsonResponse2 = (Map<String, Object>) JSON.deserializeUntyped(response2.getBody());
                
                if (jsonResponse2.containsKey('value')) {
                    List<Object> folders = (List<Object>) jsonResponse2.get('value');
                    
                    for (Object folderObj : folders) {
                        Map<String, Object> folder = (Map<String, Object>) folderObj;
                        
                        if (folder.containsKey('Name')) {
                            String uniqueId = (String) folder.get('UniqueId');
                            uniqueIds2.add(uniqueId);
                        }
                    }
                }
                if(uniqueIds2.contains(UserID)){
                    folderIdList.add(UserID);
                    HttpRequest request3 = new HttpRequest();
                    //  request3.setEndpoint('https://dextara.sharepoint.com/sites/LeadInfo/_api/web/GetFolderByServerRelativeUrl(\'Leads/'+recordId+'\')/folders');
                    request3.setEndpoint(recordapi.replace('recordId', recordId));    
                    request3.setHeader('Authorization', 'Bearer ' + accessToken);
                    request3.setHeader('Accept', 'application/json');
                    request3.setMethod('GET');
                    
                    Http http3 = new Http();
                    HttpResponse response3 = http3.send(request3);
                    
                    List<String> uniqueIds3 = new List<String>();
                    Map<String, Object> jsonResponse3 = (Map<String, Object>) JSON.deserializeUntyped(response3.getBody());
                    
                    if (jsonResponse3.containsKey('value')) {
                        List<Object> folders = (List<Object>) jsonResponse.get('value');
                        
                        for (Object folderObj : folders) {
                            Map<String, Object> folder = (Map<String, Object>) folderObj;
                            
                            if (folder.containsKey('UniqueId')) {
                                String uniqueId = (String) folder.get('UniqueId');
                                uniqueIds3.add(uniqueId);
                            }
                        }
                    }
                    
                    else{
                        
                        //String endpointUrl = 'https://dextara.sharepoint.com/sites/LeadInfo/_api/Web/folders';
                        
                        String userIdFolder=UserInfo.getUserName()+'-'+UserInfo.getUserId();
                        // Construct the request body
                        Map<String, Object> folderPayload = new Map<String, Object>{
                            '__metadata' => new Map<String, Object>{
                                'type' => 'SP.Folder'
                                    },
                                        'ServerRelativeUrl' => serverurl+recordId+'/'+userIdFolder
                                        };
                                            
                                            // Set the necessary request headers
                                            Map<String, String> headers = new Map<String, String>{
                                                'Authorization' => 'Bearer '+accesstoken,
                                                    'Content-Type' => 'application/json;odata=verbose',
                                                    'Accept' => 'application/json;odata=verbose'
                                                    
                                                    };
                                                        
                                                        // Send the POST request
                                                        HttpRequest request4 = new HttpRequest();
                        request4.setEndpoint(endpointUrl);
                        request4.setMethod('POST');
                        request4.setHeader('Authorization', headers.get('Authorization'));
                        request4.setHeader('Content-Type', headers.get('Content-Type'));
                        request4.setHeader('Accept', headers.get('Accept'));
                        request4.setBody(JSON.serialize(folderPayload));
                        HttpResponse response4 = new Http().send(request4);				 
                    }            
                }
            }
            else{
                folderIdList=makeFolder(recordId);
                
            }
        }
        catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return folderIdList;        
    }
    
    /**
* @description make the folder format.
* @param recordId This is a recordId.
* @return folder Ids.
*/   
    public List<String> makeFolder(Id recordId){
        List<String> elseFolderList=new List<String>();
        try{
            getAuthenticationData();
            
            Id myId = (Id) recordId;
            String sObjName = myId.getSObjectType().getDescribe().getName();
            //String endpointUrl = 'https://dextara.sharepoint.com/sites/LeadInfo/_api/Web/folders';
            
            // Construct the request body
            Map<String, Object> folderPayload = new Map<String, Object>{
                '__metadata' => new Map<String, Object>{
                    'type' => 'SP.Folder'
                        },
                            'ServerRelativeUrl' => serverurl+sObjName
                            };
                                String accesstoken=makeRequest();
            // Set the necessary request headers
            Map<String, String> headers = new Map<String, String>{
                'Authorization' => 'Bearer '+accesstoken,
                    'Content-Type' => 'application/json;odata=verbose',
                    'Accept' => 'application/json;odata=verbose'
                    
                    };
                        
                        // Send the POST request
                        HttpRequest request = new HttpRequest();
            request.setEndpoint(endpointUrl);
            request.setMethod('POST');
            request.setHeader('Authorization', headers.get('Authorization'));
            request.setHeader('Content-Type', headers.get('Content-Type'));
            request.setHeader('Accept', headers.get('Accept'));
            
            request.setBody(JSON.serialize(folderPayload));
            
            HttpResponse response = new Http().send(request);
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());
            Map<String, Object> uniqueIdMap = (Map<String, Object>)jsonResponse.get('d');
            //user folder inside account folder
            String userId=UserInfo.getUserId();
            String userName = UserInfo.getUserName();
            String User = userName+'-'+userId;
            String objName = recordId.getSObjectType().getDescribe().getName();
            Sobject myObj = selector.getRecordsList(objName,recordId);
            String recName = String.valueOf(myObj.get('Name'));
            String recIdname = recName+'-'+recordId;
            
            // Construct the request body
            Map<String, Object> folderPayload2 = new Map<String, Object>{
                '__metadata' => new Map<String, Object>{
                    'type' => 'SP.Folder'
                        },
                            'ServerRelativeUrl' => serverurl+sObjName+'/'+recIdname
                            };
                                
                                // Set the necessary request headers
                                Map<String, String> headers2 = new Map<String, String>{
                                    'Authorization' => 'Bearer '+accesstoken,
                                        'Content-Type' => 'application/json;odata=verbose',
                                        'Accept' => 'application/json;odata=verbose'
                                        
                                        };
                                            
                                            // Send the POST request
                                            HttpRequest request2 = new HttpRequest();
            request2.setEndpoint(endpointUrl);
            request2.setMethod('POST');
            request2.setHeader('Authorization', headers.get('Authorization'));
            request2.setHeader('Content-Type', headers.get('Content-Type'));
            request2.setHeader('Accept', headers.get('Accept'));
            
            request2.setBody(JSON.serialize(folderPayload2));
            
            HttpResponse response2 = new Http().send(request2);
            Map<String, Object> jsonResponse2 = (Map<String, Object>) JSON.deserializeUntyped(response2.getBody());
            if(jsonResponse2.get('d') != null){
                Map<String, Object> uniqueIdMap2 = (Map<String, Object>)jsonResponse2.get('d');
                if(uniqueIdMap2.size() > 0){
                    elseFolderList.add((String)uniqueIdMap2.get('UniqueId'));
                }
            }
            /// 
            
            ///        
            Map<String, Object> folderPayload3 = new Map<String, Object>{
                '__metadata' => new Map<String, Object>{
                    'type' => 'SP.Folder'
                        },
                            'ServerRelativeUrl' => serverurl+sObjName+'/'+recIdname+'/'+User
                            };
                                
                                // Set the necessary request headers
                                Map<String, String> headers3 = new Map<String, String>{
                                    'Authorization' => 'Bearer '+accesstoken,
                                        'Content-Type' => 'application/json;odata=verbose',
                                        'Accept' => 'application/json;odata=verbose'
                                        
                                        };
                                            
                                            // Send the POST request
                                            HttpRequest request3 = new HttpRequest();
            request3.setEndpoint(endpointUrl);
            request3.setMethod('POST');
            request3.setHeader('Authorization', headers.get('Authorization'));
            request3.setHeader('Content-Type', headers.get('Content-Type'));
            request3.setHeader('Accept', headers.get('Accept'));
            
            request3.setBody(JSON.serialize(folderPayload3));
            
            HttpResponse response3 = new Http().send(request3);
            Map<String, Object> jsonResponse3 = (Map<String, Object>) JSON.deserializeUntyped(response3.getBody());
            if(jsonResponse3.get('d') != null){
                Map<String, Object> uniqueIdMap3 = (Map<String, Object>)jsonResponse3.get('d');            if(uniqueIdMap3.size() > 0){
                    elseFolderList.add((String)uniqueIdMap3.get('UniqueId'));
                }
            }
            
        }
        catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return elseFolderList;
        
    }
    
    /**
* @description get files from a folder.
* @param sharefolderIds This is a folderIds.
* @param searchContent This is for serach keyword.
* @return drive files from a folder
*/   
    public Map<String,Map<String,String>> FilesList(List<String> sharefolderIds,String searchContent) {
        Map<String,Map<String,String>> downloadUrlMap=new Map<String,Map<String,String>>();
        
        try{    
            getAuthenticationData();
            
            String accessToken=makeRequest();
            
            HttpRequest request = new HttpRequest();
            request.setEndpoint(fileendpointUrl.replace('sharefolderIds', sharefolderIds[1]));
            request.setHeader('Authorization', 'Bearer '+accessToken);
            request.setHeader('Accept', 'application/json');
            request.setMethod('GET');
            
            HttpResponse response = new Http().send(request);
            String responseBody = response.getBody();
            
            // Parse the JSON response
            Map<String, Object> jsonResponse = (Map<String, Object>) JSON.deserializeUntyped(responseBody);
            if(jsonResponse.get('value') != null){
                List<Object> files = (List<Object>) jsonResponse.get('value');
                
                // Process each file and extract the download link
                if(files.size() > 0){
                    for (Object file : files) {
                        Map<String,String> fileMap=new Map<string,string>();
                        Map<String, Object> fileData = (Map<String, Object>) file;
                        String fileName = (String) fileData.get('Name');
                        // Check if the search content is null or empty
                        if (String.isBlank(searchContent) || fileName.toLowerCase().contains(searchContent.toLowerCase())) {
                            String deleteLink = (String) fileData.get('odata.id');
                            String createdTime =(( (String) fileData.get('TimeCreated')).replace('T',' ')).replace('Z','');
                            String downloadLink=(string) fileData.get('ServerRelativeUrl');
                            String length=(string) fileData.get('Length');
                            String downloadDeleteUrl=deleteLink+','+downloadLink+','+createdTime+','+length;
                            
                            fileMap.put('deleteLink',deleteLink);
                            fileMap.put('downloadLink',downloadLink);
                            fileMap.put('createdTime',createdTime);
                            fileMap.put('length',length);
                            downloadUrlMap.put(fileName, fileMap);
                        }
                    }
                }
            }
        }
        catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return downloadUrlMap;
    }  
    //Sharepoint Variables and method
    
    
    
    //google drive
    public static Map<String,Map<String,String>> filesMap=new Map<String,Map<String,String>>();
    
    /**
* @description get files from a folder.
* @param folderId This is a folderId.
* @return drive files from a folder
*/   
    public Map<String,Map<String,String>> fileList(String folderId) {
        try{
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();
            String endpoint = 'callout:Drive/files?q=\''+folderId+'\'%20in%20parents';   
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            response = http.send(request);
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                String jsonResponse = response.getBody();
                Map<String,Object> jsonmap=(Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
                if(jsonmap.get('items') != null){
                    if(((List<Object>)jsonmap.get('items')).size() > 0){
                        for (Object instance : (List<Object>)jsonmap.get('items')){
                            Map<String,String> fileMap=new Map<string,string>();
                            Map<String, Object> inst=(Map<String, Object>)instance;
                            fileMap.put('title',(string)inst.get('title'));
                            fileMap.put('createdDate',(string)inst.get('createdDate'));
                            if((string)inst.get('mimeType') == 'application/vnd.google-apps.folder'){
                                // fileList((string)inst.get('id')) ;
                            }
                            else
                            {
                                filesMap.put((string)inst.get('id'), fileMap);
                            }
                        }
                    }
                }
            }
        }
        catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return filesMap;
    }
    
    /**
* @description create a folder if not existed in the google drive.
* @param recordId This is a recordId.
* @return created folder Id.
*/   
    public String folderCreation(Id recordId) {
        String folderId;
        
        try{
            String recordFolderName;
            String userFolderName;
            String userFolderId;
            String parentRecfolderId;
            String recordFolderId;
            String objectFolderId;
            String objectName = recordId.getSObjectType().getDescribe().getName();
            String userId=UserInfo.getUserId();
            String username = UserInfo.getUserName();
            userFolderName = username+'-'+userId;
            Map<String,String> userMap=new  Map<String,String>();
            Sobject myObj = selector.getRecordsList(objectName,recordId);
            recordFolderName = String.valueOf(myObj.get('Name'))+'-'+recordId;
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();
            String endpoint = 'callout:Drive/files?q=\''+Label.MainDriveFolderId+'\'%20in%20parents%20and%20trashed=false';   
            request.setEndpoint(endpoint);
            request.setMethod('GET');
            response = http.send(request);
            Map<String,Object> instMap=new  Map<String,Object>();
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                String jsonResponse = response.getBody();
                Map<String,Object> jsonmap=(Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
                if(((List<Object>)jsonmap.get('items')) != null && (((List<Object>)jsonmap.get('items')).size() > 0) ){
                    for (Object instance : (List<Object>)jsonmap.get('items')){
                        Map<String, Object> inst=(Map<String, Object>)instance;
                        if ((string)inst.get('title') == objectName) {
                            objectFolderId  = ((string)inst.get('id')) ;
                        }
                    }
                }
                
                
                if(objectFolderId == null || objectFolderId == '') {
                    String objFolderId = createFolder(objectName,Label.MainDriveFolderId,'object');
                    if(objFolderId != null && objFolderId != ''){
                        String recFolderId =  createFolder(recordFolderName,objFolderId,'record');
                        if(recFolderId != null && recFolderId != ''){
                            return createFolder(userFolderName,recFolderId,'user');
                        }
                    }
                }
                else{
                    HttpRequest request2 = new HttpRequest();
                    HttpResponse response2 = new HttpResponse();
                    Http http2 = new Http();
                    request2.setEndpoint('callout:Drive/files?q=\''+objectFolderId+'\'%20in%20parents%20and%20trashed=false');
                    request2.setMethod('GET');
                    response2 = http2.send(request2);
                    if(response2.getStatusCode() == 200 || response2.getStatusCode() == 201){
                        Map<String,Object> jdeserializeMap=(Map<String, Object>)JSON.deserializeUntyped(response2.getBody());
                        if(((List<Object>)jdeserializeMap.get('items')).size() > 0){
                            for (Object instance : (List<Object>)jdeserializeMap.get('items')){
                                Map<String, Object> inst=(Map<String, Object>)instance;
                                if ((string)inst.get('title') == recordFolderName) {
                                    recordFolderId  = ((string)inst.get('id')) ;
                                }
                            }
                        }
                        
                        
                        if(recordFolderId == null || recordFolderId == '') {
                            String recFolderId =  createFolder(recordFolderName,objectFolderId,'record');
                            if(recFolderId != null && recFolderId != ''){
                                return createFolder(userFolderName,recFolderId,'user');
                            }
                        }
                        else{
                            HttpRequest request3 = new HttpRequest();
                            HttpResponse response3 = new HttpResponse();
                            Http http3 = new Http();
                            request3.setEndpoint('callout:Drive/files?q=\''+recordFolderId+'\'%20in%20parents%20and%20trashed=false');
                            request3.setMethod('GET');
                            response3 = http3.send(request3);
                            if(response3.getStatusCode() == 200 || response3.getStatusCode() == 201){
                                Map<String,Object> deserializeMap=(Map<String, Object>)JSON.deserializeUntyped(response3.getBody());
                                if(((List<Object>)deserializeMap.get('items')).size() > 0){
                                    for (Object instance : (List<Object>)deserializeMap.get('items')){
                                        Map<String, Object> inst=(Map<String, Object>)instance;
                                        if ((string)inst.get('title') == userFolderName) {
                                            userFolderId  = ((string)inst.get('id')) ;
                                        }
                                    }
                                }
                                
                                if(userFolderId == null || userFolderId == '' ){
                                    return createFolder(userFolderName,recordFolderId,'user');
                                }
                                else {
                                    folderId = userFolderId;
                                    return userFolderId;
                                }
                            }
                            
                        }    
                    }
                }
            }
        }
        catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
        return folderId;
    }
    
    /**
* @description create a folder in the google drive.
* @param recordId This is a recordId.
* @return created folder Id.
*/  
    public String createFolder(String folderName,String parentFolderId,String folderType){
        String folderId;
        try{
            HttpRequest request = new HttpRequest();
            HttpResponse response = new HttpResponse();
            Http http = new Http();
            String endpoint = 'callout:Drive/files';   
            request.setEndpoint(endpoint);
            request.setMethod('POST');
            request.setHeader('content-type','application/json');
            request.setTimeout(120000);
            List<String> strlst=new  List<String>();
            
            List<Parent> parentwraplst=new List<Parent>();
            Parent parentwrap=new Parent();
            parentwrap.parentid=parentFolderId;
            parentwraplst.add(parentwrap);
            Wrapper wrap=new Wrapper();
            wrap.title=folderName;
            wrap.mimeType='application/vnd.google-apps.folder';
            wrap.parents=parentwraplst;
            request.setBody((JSON.serialize(wrap)).replace('parentid','id'));
            response = http.send(request);
            if(response.getStatusCode() == 200 || response.getStatusCode() == 201){
                String jsonResponse = response.getBody();
                Map<String,Object> jsonmap=(Map<String, Object>)JSON.deserializeUntyped(jsonResponse);
                if(((String)jsonmap.get('id')) != null){
                    folderId = ((String)jsonmap.get('id'));  
                }     
            }
        }
        catch(exception e) {
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
    public void uploadFileToFolder(Blob fileBlob, String folderId, String fileName) {
        String boundary = '----WebKitFormBoundary7MA4YWxkTrZu0gW';
        String body = '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="metadata"\r\n' +
            'Content-Type: application/json; charset=UTF-8\r\n\r\n' +
            '{ "name" :"'+fileName+'" , "parents": ["' + folderId + '"] }\r\n' +
            '--' + boundary + '\r\n' +
            'Content-Disposition: form-data; name="file"\r\n\r\n';
        
        String footer = '\r\n--' + boundary + '--';
        String endPoint = 'callout:UploadtoDrive/files?uploadType=multipart';
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endPoint);
        req.setMethod('POST');
        req.setHeader('Content-Type', 'multipart/related; boundary=' + boundary);
        req.setBodyAsBlob(Blob.valueOf(body +EncodingUtil.base64Encode(fileBlob) + footer));
        
        Http http = new Http();
        HttpResponse res = http.send(req);
        
          if (res.getStatusCode() == 200) {
                System.debug('File uploaded successfully.');
            } else {
                System.debug('Error uploading file: ' + res.getStatus());
            }
        
    }
    
    /**
* @description delete a file from google drive folder.
* @param fileId This is a fileId.
*/   
    public void deleteFile(String fileId) {
        String endpoint = 'callout:Drive/files/'+fileId;
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('DELETE');
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200 || res.getStatusCode() == 201 || res.getStatusCode() == 204) {
                System.debug('File deleted successfully.');
            } else {
                System.debug('Error deleted file: ' + res.getStatus());
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());
        }
    }
    
    /**
* @description download the content of a file.
* @param fileId This is a fileId.
* @return blob content of a file.
*/   
    public Blob downloadFile(String fileId) {
        String endpoint = 'callout:Drive/files/' + fileId + '?alt=media';
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint(endpoint);
        req.setMethod('GET');
        try {
            Http http = new Http();
            HttpResponse res = http.send(req);
            
            if (res.getStatusCode() == 200) {
                return res.getBodyAsBlob();
            } else {
                return null;
            }
        } catch (Exception e) {
            System.debug('Exception: ' + e.getMessage());return null;
        }
    }
    
    public class Wrapper{
        public String title;
        public String mimeType;
        public List<Parent> parents;   
    }
    
    public class Parent{
        public String parentid;
        
    }
    
    //google drive
    
    
    //AWS
    
    public String fileName; 
    public String folderName;
    public Blob fileBody;
    public String contentType;
    public Id recordId;
    public HttpResponse res;
    public ContentVersion versionData;
    public static HttpRequest req;
    /**
* @description init method used for initialize the AWS signature and upload file.
*/ 
    public override void init() {
        List<Key_Configurations__mdt> s3List = new  List<Key_Configurations__mdt>();
        Map<String, String> s3Map = new Map<String, String>();
        s3List = selector.getAuthenticationData('AWS');
        if(s3List.size() > 0) {
            for(Key_Configurations__mdt s3:s3List) {
                s3Map.put(s3.Label,s3.Value__c);
            }
            if(s3Map.size() > 0) {
                service = s3Map.get('service'); 
                region = s3Map.get('region');        
                createSigningKey(s3Map.get('secretKey'));
                accessKey = s3Map.get('accessKey');
                endpoint = new Url(s3Map.get('endpoint'));
            }
            // this is not required but if you want to upload file to specific folder then create a folder inside S3 bucket 
            // and then put the name inside Folder
            contType = '.'+contentType;
            if(String.isBlank(folderName)) {
                resource = +this.fileName+'.'+contentType;
            }else{
                resource = this.folderName+'/'+this.fileName+'.'+contentType;
            }
            method = HttpMethod.XPUT;
            payload = this.fileBody;
            If(!Test.isRunningTest()){
                // Call this method from Abstract Class "AWS"
                req = createRequest();
                try {
                    // Send the Request and get the response
                    res = (new Http()).send(req);
                }catch(System.CalloutException ex) {
                    String errorMsg = ex.getMessage();
                    throw new AuraHandledException(ErrorMsg);
                }
            }
            else {
                HttpResponse response;
                createRequest();
                response = new HttpResponse();
                response.setHeader('Content-type', 'application/json');
                response.setBody('');
                response.setStatusCode(200);
            }
        }
    }
    
    /**
* @description get Signed Url for download file.
* @param location This is a AWS file url.
* @param file This is the keyUrl of a file. 
* @param expires This is minutes to be expired in. 
* @return Download File URL
*/
    public String getSignedURL(String location, String file, Integer expires) {
        String accessKey;
        String secretKey;
        String bucketName;
        String bucketRegion;
        Map<String, String> s3Map = new Map<String, String>();
        try {
            List<Key_Configurations__mdt> s3List = new  List<Key_Configurations__mdt>();
            s3List =selector.getAuthenticationData('AWS');
            
            for(Key_Configurations__mdt s3:s3List) {
                s3Map.put(s3.Label,s3.Value__c);
            }
            if(s3Map.size() > 0) {
                bucketName = s3Map.get('s3bucket'); 
                bucketRegion = s3Map.get('region');        
                secretKey=(s3Map.get('secretKey'));
                accessKey = s3Map.get('accessKey');
                
            }
            Datetime currentDateTime = Datetime.now();
            String dateOnly = currentDateTime.formatGmt('yyyyMMdd');
            String req =  dateOnly + '/'+ bucketRegion +'/s3/aws4_request';
            String xAmzCredentialStr = accessKey + '/' + req;
            String xAmzDate = currentDateTime.formatGmt('yyyyMMdd\'T\'HHmmss\'Z\'');
            String xAmzSignedHeaders = 'host';
            String host = bucketName + '.s3.'+ bucketRegion +'.amazonaws.com';
            
            String canonicalRequest =
                'GET\n' +
                '/' + uriEncode(file, false) + '\n' +
                uriEncode('X-Amz-Algorithm', true) + '=' + uriEncode('AWS4-HMAC-SHA256', true) + '&' +
                uriEncode('X-Amz-Credential', true) + '=' + uriEncode(xAmzCredentialStr, true) + '&' +
                uriEncode('X-Amz-Date', true) + '=' + uriEncode(xAmzDate, true) + '&' +
                uriEncode('X-Amz-Expires', true) + '=' + uriEncode(String.valueOf(expires), true) + '&' +
                uriEncode('X-Amz-SignedHeaders', true) + '=' + uriEncode(xAmzSignedHeaders, true) + '\n' +
                'host:'+host + '\n\n' +
                'host\n' +
                'UNSIGNED-PAYLOAD';
            
            String stringToSign =
                'AWS4-HMAC-SHA256\n'+
                xAmzDate + '\n' + 
                req + '\n' +
                EncodingUtil.convertToHex(
                    Crypto.generateDigest('SHA-256', Blob.valueOf(canonicalRequest))
                );
            
            
            Blob dateKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(dateOnly), Blob.valueOf('AWS4' + secretKey));
            Blob dateRegionKey = Crypto.generateMac('hmacSHA256', Blob.valueOf(bucketRegion), dateKey);
            Blob dateRegionServiceKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('s3'), dateRegionKey);
            Blob signingKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'), dateRegionServiceKey);
            
            Blob signature = Crypto.generateMac('hmacSHA256', Blob.valueOf(stringToSign), signingKey);
            String signatureStr = EncodingUtil.convertToHex(signature);
            
            return location + '?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=' + EncodingUtil.urlEncode(xAmzCredentialStr, 'UTF-8') + '&X-Amz-Date=' + xAmzDate + '&X-Amz-Expires=' + String.valueOf(expires) +'&X-Amz-Signature=' + signatureStr + '&X-Amz-SignedHeaders=host';
        }
        catch(Exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description uriEncode method used for encrypting the headers.
* @param input This is the Input String to encrypt
* @param encodeSlash This is the boolean value to encode with slash
* @return Encoded String 
*/ 
    public String uriEncode(String input, Boolean encodeSlash) {
        String result = '';
        try {
            for (Integer i = 0; i < input.length(); i++) {
                String ch = input.substring(i, i + 1);
                if ((ch >= 'A' && ch <= 'Z') || (ch >= 'a' && ch <= 'z') || (ch >= '0' && ch <= '9') || ch == '_' || ch == '-' || ch == '~' || ch == '.') {
                    result += ch;
                } else if (ch == '/') {
                    result += encodeSlash ? '%2F' : ch;
                } else {
                    result =  convertToHex(ch, result);        
                }
            }   
            return result;
        }
        catch(Exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description convertToHex method used for converting characters into hex.
* @param ch
* @param result
* @return Hexvalue String 
*/ 
    public String convertToHex(String ch, String result) {
        if(ch != null){ 
            String hexValue = EncodingUtil.convertToHex(Blob.valueOf(ch)).toUpperCase();    
            if (hexValue.length() == 2) {
                result += '%' + hexValue;
            } else if (hexValue.length() == 4) {
                result += '%' + hexValue.substring(0, 2) + '%' + hexValue.substring(2);
            }     
        }
        return result; 
    }
    /**
* @description upload File from salesforce to S3.
* @param recId This is the record Id.
* @param objectName This is the object name of a record.
* @param pathRecId This is the recordId.
* @param deleteFlag This is the deleteFlag.
* @return flag on uploaded successfully
*/ 
    public Boolean uploadFiles(Id recId, String objectName, Id pathRecId,Boolean deleteFlag, Id userId) {
        Boolean uploadedFlag = false;
        List<Id> contDocIds = new List<Id>();
        List<String> errorList = new List<String>();
        List<ContentVersion> versionData;
        String filesize;
        try {
            Set<Id> contentDocumentIds = new Set<Id>();
            if(recId != null && objectName != null) {
                List<ContentDocumentLink> condocList= [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:recId WITH SECURITY_ENFORCED];
                if(condocList.size() > 0) {
                    for(ContentDocumentLink condoc:condocList) {
                        contDocIds.add(condoc.ContentDocumentId);
                    }
                    versionData= [SELECT Id, Title, ContentSize, FileExtension, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId IN:contDocIds WITH SECURITY_ENFORCED];
                }
                for(ContentVersion conver:versionData) {
                    contentDocumentIds.add(conver.ContentDocumentId);
                    filesize = fileSizeToString(conver.ContentSize);
                    if(filesize.contains('MB')) {
                        if(Double.valueOf(filesize.remove(' MB')) > 10) {
                            uploadedFlag = false;
                            break;
                        } else {
                            uploadedFlag = true;
                        }
                        
                    } else if(filesize.contains('GB')) {
                        uploadedFlag = false;
                        break;
                    }
                    else {
                        uploadedFlag = true;
                    }
                }
                
                if(uploadedFlag == true) {
                    AWSS3ServiceQueueable awsQu=new AWSS3ServiceQueueable();
                    awsQu.recId = recId;
                    awsQu.userId = userId;
                    awsQu.objectName = objectName;
                    awsQu.pathRecId = pathRecId;
                    awsQu.deleteFlag = deleteFlag;
                    System.enqueueJob(awsQu);  
                } else {
                    List<ContentDocument> conList= [SELECT Id FROM ContentDocument where ContentAssetId = null And Id IN: contentDocumentIds WITH SECURITY_ENFORCED];
                    List<Database.DeleteResult> deleteResult = Database.delete(conList);
                    errorList = SecurityCheckController.safeClassExceptionHandlerDelete(deleteResult); 
                }
                
                
            }
            return uploadedFlag;
        }catch(exception e) {
            String errorMsg = e.getMessage();
            throw new AuraHandledException(ErrorMsg);
        }
    }
    
    /**
* @description fileSizeToString to convert bytes into actual size.
* @param value
* @return size
*/ 
    public String fileSizeToString(Long value) {
        /* string representation if a file's size, such as 2 KB, 4.1 MB, etc */
        if (value < 1024) {
            return string.valueOf(value) + ' Bytes';
        }
        else if (value >= 1024 && value < (1024*1024)) {
            //KB
            Decimal kb = Decimal.valueOf(value);
            kb = kb.divide(1024,2);
            return string.valueOf(kb) + ' KB';
        }
        else if (value >= (1024*1024) && value < (1024*1024*1024)) {
            //MB
            Decimal mb = Decimal.valueOf(value);
            mb = mb.divide((1024*1024),2);
            return string.valueOf(mb) + ' MB';
        }
        else {
            //GB
            Decimal gb = Decimal.valueOf(value);
            gb = gb.divide((1024*1024*1024),2);
            return string.valueOf(gb) + ' GB';
        }    
    }
    
    //AWS
}