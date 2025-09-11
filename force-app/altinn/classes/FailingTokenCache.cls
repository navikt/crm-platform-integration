@isTest
public class FailingTokenCache implements ITokenCache {
    public void put(String key, String value, Integer ttl) {
        throw new FailingTokenCacheException('Simulated cache failure');
    }

    public String get(String key) {
        throw new FailingTokenCacheException('Simulated cache failure');
    }

    public class FailingTokenCacheException extends Exception {
    }
}
