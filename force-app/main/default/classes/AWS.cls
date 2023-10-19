/** 
* Class Name        : AWS
* Developer         : Priyanka         
* Created Date      : 11-07-2023
* @description      : AWS This is the base class that has all the required method to generate the signature for Amazon S3 and is also used it to sign that signature for sending the request to Amazon S3.
* Last Modified Date: 11-07-2023
*/
public abstract class AWS {
     
    //  Things we need to know about the service. Set these values in init()
    protected String host;
    protected String region;
    protected String service;
    protected String resource;
    protected String accessKey;
    protected String contType;
    protected Url endpoint;
    protected HttpMethod method;
    protected Blob payload;
    // Not used externally, so we hide these values
    String payloadSha256;
    Blob signingKey;
    DateTime requestTime;
    Map<String, String> queryParams;
    Map<String, String> headerParams;
    /**
* @description Post initialization logic (after constructor, before call)
*/ 
    @TestVisible protected abstract void init();
    
    /**
* @description  XML Node utility methods that will help read elements.
* @param node This a ChildNode.
* @param ns 
* @param name
* @return Flag.
*/ 
    public static Boolean getChildNodeBoolean(Dom.XmlNode node, String ns, String name) {
        try {
            if(!Test.isRunningTest()){
            return Boolean.valueOf(node.getChildElement(name, ns).getText());
            }
            else{
                return false;
            }
        } catch(Exception e) {
            return null;
        }
    }
    
    /**
* @description Turns an Amazon exception into something we can present to the user/catch.
*/   
    public class ServiceException extends Exception {
        public String code;
        public String message;
        public String resource;
        public String requestId;
        
        /**
* @description ServiceException an Amazon exception into something we can present to the user/catch.
* @param node
*/   
        public ServiceException(Dom.XmlNode node) {
            String ns = node.getNamespace();
            code = getChildNodeText(node, ns, 'Code');
            message = getChildNodeText(node, ns, 'Message');
            resource = getChildNodeText(node, ns, 'Resource');
            requestId = getChildNodeText(node, ns, 'RequestId');
        }
    }
    
    
    /**
* @description Http Methods.
*/ 
    public enum HttpMethod { XGET, XPUT, XHEAD, XOPTIONS, XDELETE, XPOST }
    
    /**
* @description Add a Header.
* @param key
* @param value
*/ 
    @TestVisible protected void setHeader(String key, String value) {
        headerParams.put(key.toLowerCase(), value);
    }
    
    /**
* @description Add parameter to API.
* @param key
* @param value
*/     @TestVisible protected void setQueryParam(String key, String value) {
    queryParams.put(key, uriEncode(value));
}
    
    /**
* @description Call this constructor with super() in subclasses.
*/ 
    @TestVisible protected AWS() {
        requestTime = DateTime.now();
        queryParams = new Map<String, String>();
        headerParams = new Map<String, String>();
        payload = Blob.valueOf('');
    }
    
    /**
* @description Create a canonical query string (used during signing).
* @return String
*/   
    String createCanonicalQueryString() {
        String[] results = new String[0];
        String[] keys = new List<String>(queryParams.keySet());
        keys.sort();
        for(String key: keys) {
            results.add(key+'='+queryParams.get(key));
        }
        return String.join(results, '&');
    }
    
    /**
* @description Create the canonical headers (used for signing).
* @param keys
* @return String
*/ 
    String createCanonicalHeaders(String[] keys) {
        keys.addAll(headerParams.keySet());
        keys.sort();
        String[] results = new String[0];
        for(String key: keys) {
            results.add(key+':'+headerParams.get(key));
        }
        return String.join(results, '\n')+'\n';
    }
    
    /**
* @description Create the entire canonical request.
* @param headerKeys
* @return String
*/ 
    String createCanonicalRequest(String[] headerKeys) {
        String resource ;
                If(!Test.isRunningTest())
                   resource  = new Url(endpoint, resource).getPath();
                 else
                     resource  = String.valueOf(endpoint);
        return String.join(
            new String[] {
                method.name().removeStart('X'),    //  METHOD
                  resource ,  //  RESOURCE
                    createCanonicalQueryString(),    //  CANONICAL QUERY STRING
                    createCanonicalHeaders(headerKeys),  //  CANONICAL HEADERS
                    String.join(headerKeys, ';'),    //  SIGNED HEADERS
                    payloadSha256        //  SHA256 PAYLOAD
                    },
            '\n'
        );
    }
    
    /**
* @description We have to replace ~ and " " correctly, or we'll break AWS on those two characters.
* @param value
* @return string
*/ 
    protected string uriEncode(String value) {
        return value==null? null: EncodingUtil.urlEncode(value, 'utf-8').replaceAll('%7E','~').replaceAll('\\+','%20');
    }
    
    /**
* @description  XML Node utility methods that will help read elements.
* @param node
* @param ns
* @param name
* @return Integer Value.
*/ 
    public static Integer getChildNodeInteger(Dom.XmlNode node, String ns, String name) {
        try {
             if(!Test.isRunningTest()){
            return Integer.valueOf(node.getChildElement(name, ns).getText());
             }
              else{
                return 0;
            }
        } catch(Exception e) {
            return null;
        }
    }
    
    /**
* @description  XML Node utility methods that will help read elements.
* @param node
* @param ns 
* @param name
* @return String.
*/ 
    public static String getChildNodeText(Dom.XmlNode node, String ns, String name) {
        try {
            if(!Test.isRunningTest()){
            return node.getChildElement(name, ns).getText();
            }
            else{
                return 'test';
            }
        } catch(Exception e) {
            return null;
        }
    }
    /**
* @description Create the entire string to sign.
* @param signedHeaders
* @return String
*/ 
    String createStringToSign(String[] signedHeaders) {
        String result = createCanonicalRequest(signedHeaders);
        return String.join(
            new String[] {
                'AWS4-HMAC-SHA256',
                    headerParams.get('x-amz-date'),
                    String.join(new String[] { requestTime.formatGMT('YYYYMMdd'), region, service, 'aws4_request' },'/'),
                    EncodingUtil.convertToHex(Crypto.generateDigest('sha256', Blob.valueof(result)))
                    },
            '\n'
        );
    }
    
    /**
* @description Create our signing key.
* @param secretKey
*/ 
    protected void createSigningKey(String secretKey) {
        signingKey = Crypto.generateMac('hmacSHA256', Blob.valueOf('aws4_request'),
                                        Crypto.generateMac('hmacSHA256', Blob.valueOf(service),
                                                           Crypto.generateMac('hmacSHA256', Blob.valueOf(region),
                                                                              Crypto.generateMac('hmacSHA256', Blob.valueOf(requestTime.formatGMT('YYYYMMdd')), Blob.valueOf('AWS4'+secretKey))
                                                                             )
                                                          )
                                       );
    }
    
    /**
* @description Create all of the bits and pieces using all utility functions above.
* @return HttpRequest
*/ 
    public HttpRequest createRequest() {
        //init();
        payloadSha256 = EncodingUtil.convertToHex(Crypto.generateDigest('sha-256', payload));
        setHeader('x-amz-date', requestTime.formatGMT('YYYYMMdd\'T\'HHmmss\'Z\''));
        if(host == null) {
            host = endpoint.getHost();
        }
        setHeader('host', host);
        HttpRequest request = new HttpRequest();
        request.setMethod(method.name().removeStart('X'));
        setHeader('x-amz-content-sha256', payloadSha256);
        if(payload.size() > 0) {
            setHeader('x-amz-content-sha256', payloadSha256);
            setHeader('Content-Length', String.valueOf(payload.size()));
            setHeader('Content-Type', contType);
            request.setBodyAsBlob(payload);
        } 
                String finalEndpoint;
        If(!Test.isRunningTest())
        finalEndpoint = new Url(endpoint, resource).toExternalForm();
        else
          finalEndpoint =  String.valueOf(endpoint);         
        String queryString = createCanonicalQueryString();
        
        if(queryString != '') {
            finalEndpoint += '?'+queryString;
        }
        request.setEndpoint(finalEndpoint);
        for(String key: headerParams.keySet()) {
            request.setHeader(key, headerParams.get(key));
        }
        String[] headerKeys = new String[0];
        String stringToSign = createStringToSign(headerKeys);
        request.setHeader(
            'Authorization',
            String.format(
                'AWS4-HMAC-SHA256 Credential={0}, SignedHeaders={1}, Signature={2}',
                new String[] {
                    String.join(new String[] { accessKey, requestTime.formatGMT('YYYYMMdd'), region, service, 'aws4_request' },'/'),
                        String.join(headerKeys,';'), EncodingUtil.convertToHex(Crypto.generateMac('hmacSHA256', Blob.valueOf(stringToSign), signingKey))}
            ));
        return request;
    }
    
    /**
* @description Actually perform the request, and throw exception if response code is not valid.
* @param validCodes
* @return HttpResponse
*/ 
    public HttpResponse sendRequest(Set<Integer> validCodes) {
        HttpResponse response = new Http().send(createRequest());
        return response;
    }
    
    /**
* @description This method exists because most of the time, 200 is what we expect.
* @return HttpResponse
*/ 
    public HttpResponse sendRequest() {
        return sendRequest(new Set<Integer> { 200 });
    }
}