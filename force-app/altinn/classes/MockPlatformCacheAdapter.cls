/**
 * @description
 * Mock implementation of a Platform Cache Adapter for testing purposes.
 *
 * @author Kenneth Sørensen
 * @since September 2025 - Created.
 */
public class MockPlatformCacheAdapter implements IPlatformCacheAdapter {
    /**
     * @description
     * Internal map to simulate cache storage.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private Map<String, Object> store = new Map<String, Object>();
    /**
     * @description
     * Flag to control `put` mock behavior. If `true`, `put` will throw an exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public Boolean shouldThrowOnPut = false;
    /**
     * @description
     * Flag to control `get` mock behavior. If `true`, `get` will throw an exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public Boolean shouldThrowOnGet = false;
    /**
     * @description
     * Flag to control `remove` mock behavior. If `true`, `remove` will throw an exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public Boolean shouldThrowOnRemove = false;
    /**
     * @description
     * Flag to simulate partition availability.
     * If `false`, `isAvailable` will return `false`.
     * Default is `true`.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public Boolean isPartitionAvailable = true;

    public void put(String key, Object value, Integer ttl) {
        if (shouldThrowOnPut) {
            throw new System.CalloutException('Mock put failure');
        }
        store.put(key, value);
    }

    public Object get(String key) {
        if (shouldThrowOnGet) {
            throw new System.CalloutException('Mock get failure');
        }
        return store.get(key);
    }

    public void remove(String key) {
        if (shouldThrowOnRemove) {
            throw new System.CalloutException('Mock remove failure');
        }
        store.remove(key);
    }

    public Boolean isAvailable() {
        return isPartitionAvailable;
    }
}
