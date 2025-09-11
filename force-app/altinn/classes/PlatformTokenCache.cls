/**
 * @description
 * Implements a token cache using Salesforce Platform Cache.
 *
 * @author Kenneth Sørensen
 * @since August 2025 - Created.
 *
 * @group Token Cache
 */
@SuppressWarnings('PMD.CognitiveComplexity')
public class PlatformTokenCache implements ITokenCache {
    private Cache.OrgPartition partition;
    private String partitionName;
    // Test-only fallback store per partition
    private static Map<String, Map<String, String>> testMemByPartition = new Map<String, Map<String, String>>();
    private Boolean partitionUnavailable = false;

    /**
     * @description
     * Constructs a token cache for a specific Platform Cache partition.
     * If the partition is unavailable or not configured, falls back to in-memory storage for tests.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param partitionName The name of the Platform Cache partition to use.
     */
    public PlatformTokenCache(String partitionName) {
        this.partitionName = partitionName;
        try {
            this.partition = Cache.Org.getPartition(partitionName);
            // Some orgs return a non-null partition that still throws on get/put; lazily detect in methods.
        } catch (Exception e) {
            // Partition not configured or cache not provisioned
            this.partitionUnavailable = true;
        }
    }

    /**
     * @description
     * Store a value in the cache with a specified time-to-live (TTL).
     * In test context, if the partition is unavailable, falls back to in-memory storage.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param key The cache key to use.
     * @param value The value to store.
     * @param ttl The time-to-live in seconds for the cache entry.
     */
    public void put(String key, String value, Integer ttl) {
        if (Test.isRunningTest() && (partitionUnavailable || partition == null)) {
            mem().put(key, value);
            return;
        }

        try {
            partition.put(key, value, ttl);
        } catch (Exception e) {
            if (Test.isRunningTest()) {
                // Fall back to in-memory store so tests don’t fail when Platform Cache is unavailable
                mem().put(key, value);
            } else {
                // In production, surface the failure
                throw e;
            }
        }
    }

    /**
     * @description
     * Retrieve a value from the cache using a specified key.
     * In test context, if the partition is unavailable, falls back to in-memory storage.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param key The cache key to retrieve.
     * @return `String` The cached value, or `null` if not found.
     */
    public String get(String key) {
        if (Test.isRunningTest() && (partitionUnavailable || partition == null)) {
            return mem().get(key);
        }
        try {
            return (String) partition.get(key);
        } catch (Exception e) {
            if (Test.isRunningTest()) {
                return mem().get(key);
            }
            // In production, prefer returning null to avoid hard failures on read
            return null;
        }
    }

    /**
     * @description
     * Test-only in-memory store (scoped per partition name).
     * Returns the in-memory store for the current partition.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @return `Map<String, String>` The in-memory key-value store for the current partition.
     */
    private Map<String, String> mem() {
        Map<String, String> m = testMemByPartition.get(partitionName);
        if (m == null) {
            m = new Map<String, String>();
            testMemByPartition.put(partitionName, m);
        }
        return m;
    }
}
