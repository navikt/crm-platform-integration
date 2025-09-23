public interface ITokenCache {
    void put(String key, String value, Integer ttl);
    String get(String key);
}
