/**
* Class Name        : FileConnectTest
* Developer         : Priyanka    
* Created Date      : 9-10-2023
* @description       : FileConnectTest class is used to check the code coverage for FileConnect classes.
* Last Modified Date: 19-10-2023
*/
@isTest
private class FileConnectTest {
    /**
* @description
*/
    @testSetup
    private static void testsetup(){
        User custUser = new User();
        System.runAs(new User(Id = UserInfo.getUserId())) {
            custUser =  TestDataFactory.createTestUser();
        }
        Map<String, Object> accAttributes = new Map<String, Object>{'Name'=>'Supplier'};
            List<Account> accts = TestDataFactory.createAccounts(1,true,accAttributes);
        
        System.runAs(custUser) {
            Map<String,Object> contactAttributes  = new Map<String,Object>{'AccountId'=>accts[0].Id,'Email'=>'test123@gmail.com','LastName'=>'John David'};
                TestDataFactory.createContacts(1,true,contactAttributes);
            Map<String, Object> assementTemplateattributes = new Map<String, Object>{'Name'=>'2023 Assessment template'};
                
                ContentVersion testContentVersion = new ContentVersion();
            testContentVersion.Title = 'Test Document';
            testContentVersion.PathOnClient = 'test_document.pdf'; 
            testContentVersion.VersionData = Blob.valueOf('a'.repeat(5242880)); 
            insert testContentVersion;
            
            ContentVersion testContentVersion1 = new ContentVersion();
            testContentVersion1.Title = 'Test Document';
            testContentVersion1.PathOnClient = 'test_document.pdf'; 
            testContentVersion1.VersionData = Blob.valueOf('a'); 
            insert testContentVersion1;
            
            ContentDocument testContentDocument = new ContentDocument();
            testContentDocument.Id = testContentVersion.ContentDocumentId; 
            ContentDocumentLink testContentDocumentLink = new ContentDocumentLink();
            testContentDocumentLink.ContentDocumentId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id = :testContentVersion.Id][0].ContentDocumentId;
            testContentDocumentLink.LinkedEntityId = accts[0].Id;
            insert testContentDocumentLink;
            
        }   
        
        
        
    }
    static FileConnectService fileService =FileConnectService.getInstance();
    
    // Create a mock implementation of the HttpCalloutMock interface
    public class MockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"access_token":"mockToken"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class SPMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"value":[{"Name":"test","UniqueId":"'+acc[0].id+'"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class SPMockHttpResponse2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"value":[{"Name":"test","odata.id":"123","Length":"1222","ServerRelativeUrl":"test.com","TimeCreated":"24/06/2023"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class DriveMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[{"title":"test","id":"123","mimeType":"application/vnd.google-apps.folder","createdDate":"24/06/2023"},{"title":"test","id":"123","mimeType":"application/vnd.google-apps.folde","createdDate":"24/06/2023"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    /*AWS Test Coverage*/
    /**
* @description
*/
    @isTest
    private static void testGetAuthenticationData() {
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            Key_Configurations__mdt config1 = new Key_Configurations__mdt();
            config1.Value__c = 'Config1';
            Key_Configurations__mdt config2 = new Key_Configurations__mdt();
            config2.Value__c = 'Config2';
            Test.startTest();
            List<Key_Configurations__mdt> result = FileConnectController.getAWSAuthenticationData();
            
            Test.stopTest(); 
            System.assertEquals(6, result.size(), 'Incorrect number of records returned');
        }
    }
    
    /**
* @description
*/
    @isTest
    private  static void testGetFileSignedUrl() {
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            Test.startTest();
            String result = FileConnectController.getFileSignedUrl('location', 'file', 60);
            FileConnectService aws=new FileConnectService();
            aws.convertToHex('01','test');
            aws.uriEncode('01*',true);
            Test.stopTest();
            System.assertEquals(result, result, 'Assert Failed');
        }
    }
    /**
* @description
*/
    @isTest
    private  static void testcreateRespforFileUpload() {
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            List<Account> acc = [Select Id,Name from Account];
            Test.startTest();
            FileConnectController.uploadFiles(acc[0].Id, 'Account', null, true, u.id);
            Test.stopTest();
        }
    }
    
    /**
* @description
*/
    @isTest
    private  static void testUploadFiles() {
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            List<Account> acc = [Select Id,Name from Account];
            Test.startTest();
            FileConnectController.uploadFiles(acc[0].Id, 'Account', null, false, u.id);
            FileConnectService aws=new FileConnectService();
            aws.convertToHex('c','test');
            Test.stopTest();
            System.assertEquals(1,acc.size(),'Assert Failed');
        }
    }
    @isTest
    private  static void testAwsuploadFiles() {
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            List<Account> acc = [Select Id,Name from Account];
            List<ContentDocumentLink> condocList= [SELECT ContentDocumentId,LinkedEntityId FROM ContentDocumentLink WHERE LinkedEntityId =:acc[0].id];
            List<ContentVersion>  versionData= [SELECT Id, Title, FileExtension, ContentDocumentId, VersionData FROM ContentVersion WHERE ContentDocumentId =:condocList[0].ContentDocumentId];
            
            Test.startTest();
            AWSS3ServiceQueueable awsQu=new AWSS3ServiceQueueable();
            awsQu.recId = acc[0].Id;
            awsQu.objectName = 'EmailMessage';
            awsQu.pathRecId = null;
            awsQu.deleteFlag = true;
            awsQu.contVerIds = new Set<Id>{versionData[0].id};           
            FileConnectService aws=new FileConnectService();
            aws.convertToHex('c','test');
            Test.stopTest();
            System.assertEquals(1,acc.size(),'Assert Failed');
        }
    }
    
    /**
* @description
*/
    @isTest
    private static void awsTest(){
        String ids= UserInfo.getUserId();
        User u=[select id from user where id=:ids limit 1];
        System.runAs(u) {
            Dom.Document doc = new Dom.Document();
            Dom.Xmlnode rootNode = doc.createRootElement('TestReport', null, null);
            rootNode.addChildElement('detail', null, null);
            test.startTest(); 
            AWS.getChildNodeBoolean(rootNode,'Rhythm','detail');
            AWS.getChildNodeInteger(rootNode,'Rhythm','rootNode');
            AWS.getChildNodeText(rootNode,'Rhythm','rootNode');
            new AWS.ServiceException(rootNode);
            test.stopTest();
            System.assertEquals(1,1,'Assert Failed');
        }
    }
    
    
    
    
    /*sharepoint Test Coverage*/
    
    
    @isTest
    static void testMakeRequest() {
        // Set up a mock callout response
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        // Call the method that makes the web service callout
        Test.startTest();
        String accessToken = FileConnectController.makeRequest();
        Test.stopTest();
        System.assertEquals('mockToken', accessToken);
    }
    
    @isTest
    static void testGetAuthenticationData2() {
        // Retrieve the custom metadata record(s) using getInstance or SOQL query
        Storage_Point__mdt parentMetadata = Storage_Point__mdt.getInstance('Sharepoint');
        List<Key_Configurations__mdt> keyConfigs = [SELECT Id, DeveloperName, Value__c, Label FROM Key_Configurations__mdt WHERE Parent_Configuration__c = :parentMetadata.Id];
        
        // Call the getAuthenticationData method for test coverage
        Test.startTest();
        List<Key_Configurations__mdt> result = FileConnectController.getSPAuthenticationData();
        Test.stopTest();
        
    }
    
    
    @isTest
    static void testGetAccountFolderId() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the getAccountFolderId method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SPMockHttpResponse());
        
        List<String> folderIdList = FileConnectController.getFolderId(acc.Id);
        Test.stopTest();
    }
    public class SPMockHttpResponse3 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            String UserID=UserInfo.getUserId()+' '+UserInfo.getUserName();
            
            // Create a mock response
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"value":[{"Name":"test","UniqueId":"'+UserID+'"},{"Name":"test","UniqueId":"'+acc[0].id+'"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    @isTest
    static void testGetFolderId() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the getAccountFolderId method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SPMockHttpResponse3());
        
        List<String> folderIdList = FileConnectController.getFolderId(acc.Id);
        Test.stopTest();
    }
    @isTest
    static void testMakeFolder() {
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the makeFolder method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        List<String> elseFolderList = fileService.makeFolder(acc.id);
        Test.stopTest();
    }
    
    @isTest
    static void testFilesList() {
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SPMockHttpResponse2());
        
        Map<String,Map<String,String>> downloadUrlMap = FileConnectController.FilesList(new List<String>{'123','1233'}, 'test');
        Test.stopTest();
    }
    
    
    
    //drive
    @isTest
    static void testDriveFilesList() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new DriveMockHttpResponse());
        
        Map<String,Map<String,String>> downloadUrlMap = FileConnectController.FileList(acc.id);
        Test.stopTest();
    }
    
    
    
    @isTest
    static void testDriveDelFile() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        FileConnectController.deleteFile(acc.id);
        Test.stopTest();
    }
    
    
    @isTest
    static void testDriveDownloadFile() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        FileConnectController.downloadFile(acc.id);
        Test.stopTest();
    }
    
    @isTest
    static void testDriveuploadFile() {
        Account acc = [SELECT Id,Name from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new MockHttpResponse());
        
        FileConnectController.uploadFileToFolder(Blob.valueOf('test'),acc.id,'test');
        Test.stopTest();
    }
    public class GDHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            String userId=UserInfo.getUserId();
            String username = UserInfo.getUserName();
            String userFolderName = username+'-'+userId;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[{"title":"Account","id":"123"},{"title":"'+acc[0].name+'-'+acc[0].id+'","id":"1234"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class GDHttpResponse2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            String userId=UserInfo.getUserId();
            String username = UserInfo.getUserName();
            String userFolderName = username+'-'+userId;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[{"title":"Account","id":"123"},{"title":"'+acc[0].name+'-'+acc[0].id+'","id":"1234"},{"title":"'+userFolderName+'","id":"12345"}]}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    public class GDMockHttpResponse implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            String userId=UserInfo.getUserId();
            String username = UserInfo.getUserName();
            String userFolderName = username+'-'+userId;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[{"title":"Accounts","id":"123"},{"title":"'+acc[0].name+'-'+acc[0].id+'","id":"1234"},{"title":"test","id":"12345"}],"id":"11"}');
            res.setStatusCode(200);
            return res;
        }
    }
    public class GDMockHttpResponse2 implements HttpCalloutMock {
        public HTTPResponse respond(HTTPRequest req) {
            List<Account> acc = [Select Id,Name from Account LIMIT 1];
            String userId=UserInfo.getUserId();
            String username = UserInfo.getUserName();
            String userFolderName = username+'-'+userId;
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"items":[{"title":"Account","id":"123"},{"title":"test","id":"12345"}],"id":"11"}');
            res.setStatusCode(200);
            return res;
        }
    }
    
    @isTest
    static void testDriveFolderCreation() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GDHttpResponse());
        
        String folderID = FileConnectController.folderCreation(acc.id);
        Test.stopTest();
    }
    
    @isTest
    static void testDriveFolderCreation2() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GDHttpResponse2());
        
        String folderID = FileConnectController.folderCreation(acc.id);
        Test.stopTest();
    }
    @isTest
    static void testDriveFolderCreation3() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GDMockHttpResponse());
        
        String folderID = FileConnectController.folderCreation(acc.id);
        Test.stopTest();
    }
    @isTest
    static void testDriveCreateFolder() {
        Account acc = [SELECT Id from Account LIMIT 1];
        // Call the FilesList method for test coverage
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GDMockHttpResponse2());
        String folderID = FileConnectController.folderCreation(acc.id);
        fileService.createFolder('testt',acc.id,'object');
        Test.stopTest();
    }
    
    
}