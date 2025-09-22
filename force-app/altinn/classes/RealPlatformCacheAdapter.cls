/**
 * @description
 * Real implementation of a Platform Cache Adapter.
 *
 * @author Kenneth Sørensen
 * @since September 2025 - Created.
 */
public with sharing class RealPlatformCacheAdapter implements IPlatformCacheAdapter {
    /**
     * @description
     * The Platform Cache partition instance.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private Cache.OrgPartition partition;
    /**
     * @description
     * Indicates whether the Platform Cache partition was successfully initialized during
     * construction. Set to `false` if partition creation fails due to missing configuration,
     * insufficient capacity, or access permissions. Used by `isAvailable()` to determine adapter
     * usability.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private Boolean available = true;
    /**
     * @description
     * Constructor that initializes the Platform Cache partition.
     * If the partition cannot be obtained, the adapter is marked as unavailable.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param partitionName The name of the Platform Cache partition to use.
     */
    public RealPlatformCacheAdapter(String partitionName) {
        try {
            this.partition = Cache.Org.getPartition(partitionName);
        } catch (Exception e) {
            this.available = false;
        }
    }

    /**
     * @description
     * Puts a value into the cache.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The key to identify the cached value.
     * @param value The value to cache.
     * @param ttl The time-to-live for the cached value.
     */
    public void put(String key, Object value, Integer ttl) {
        partition.put(key, value, ttl);
    }

    /**
     * @description
     * Retrieves a value from the cache.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The key to retrieve the cached value.
     * @return The cached value, or `null` if not found.
     */
    public Object get(String key) {
        return partition.get(key);
    }

    /**
     * @description
     * Removes a value from the cache.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The key to remove from the cache.
     */
    public void remove(String key) {
        partition.remove(key);
    }

    /**
     * @description
     * Checks if the cache adapter is available.
     * Returns `true` if the partition was successfully initialized, `false` otherwise.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @return `true` if the cache adapter is available, `false` otherwise.
     */
    public Boolean isAvailable() {
        return available && partition != null;
    }
}
