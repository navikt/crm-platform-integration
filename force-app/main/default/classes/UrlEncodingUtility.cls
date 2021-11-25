public with sharing class UrlEncodingUtility {
    
    public static string encodeUrl(string url){
        url=url.replaceAll('/', '%2F');
        url=url.replaceAll(' ', '%20');
        url=url.replaceAll('&', '%26');
        url=url.replaceAll('=', '%3D');
        url=url.replaceAll('/', '%2F');
        url=url.replaceAll(',', '%2C');
        url=url.replaceAll('\\+', '%2B');
        url=url.replaceAll('!','%21');
        url=url.replaceAll('æ', '%C3%A6');
        url=url.replaceAll('ø', '%C3%B8');
        url=url.replaceAll('å', '%C3%A5');
        url=url.replaceAll('Æ', '%C3%86');
        url=url.replaceAll('Ø', '%C3%98');
        url=url.replaceAll('Å', '%C3%85');

        return url;
    }
}
