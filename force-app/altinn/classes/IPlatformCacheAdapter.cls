/**
 * @description
 * Interface for Platform Cache Adapter.
 *
 * @author Kenneth Sørensen
 * @since September 2025 - Created.
 */
public interface IPlatformCacheAdapter {
    void put(String key, Object value, Integer ttl);
    Object get(String key);
    void remove(String key);
    Boolean isAvailable();
}
