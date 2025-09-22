/**
 * @description
 * Token cache backed by Salesforce Platform Cache (Org partition).
 * - Production: uses real Platform Cache. Throws on write if partition is unusable.
 * - Tests: can force a deterministic in-memory fallback without org setup.
 *
 * @author Kenneth Sørensen
 * @since August 2025 - Created.
 *
 * @group Token Cache
 *
 * @see Cache namespace & Org/OrgPartition: https://developer.salesforce.com/docs/atlas.en-us.apexref.meta/apexref/apex_namespace_cache.htm
 */
@SuppressWarnings('PMD')
public class PlatformTokenCache implements ITokenCache {
    /**
     * @description
     * Default TTL for cache entries (in seconds).
     * 5 minutes.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public static final Integer DEFAULT_TTL_SECS = 300;
    /**
     * @description
     * Maximum allowed TTL for cache entries (in seconds).
     * 48 hours hard ceiling.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public static final Integer MAX_TTL_SECS = 172800;
    /**
     * @description
     * Maximum key length for cache entries.
     * Platform Cache limit is 50 characters.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public static final Integer MAX_KEY_LEN = 50;
    /**
     * @description
     * Separator used in composite cache keys.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public static final String HASH_SEP = ':';
    /**
     * @description
     * Feature flag to allow fallback to in-memory store in non-test contexts.
     * Default is `false` to avoid silent failures in production.
     * Can be set to `true` in lower environments for convenience.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @TestVisible
    public static Boolean ALLOW_PROD_FALLBACK = false;

    /**
     * @description
     * The name of the Platform Cache partition.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private final String partitionName;
    /**
     * @description
     * The Platform Cache adapter (real or mock).
     * Initialized on first use.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @TestVisible
    private IPlatformCacheAdapter adapter;
    /**
     * @description
     * Test-only in-memory store, scoped per partition name.
     * Used when Platform Cache is unavailable during tests.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private static Map<String, Map<String, String>> testMemByPartition = new Map<String, Map<String, String>>();
    /**
     * @description
     * Test-only override for `Test.isRunningTest()`.
     * If set to non-null, this value is used instead of the actual test context.
     * Allows simulating test context in non-test code paths.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @TestVisible
    private static Boolean testOverrideIsRunningTest = null;

    /**
     * @description
     * Constructor accepting a partition name.
     * Attempts to initialize the Platform Cache partition.
     * If the partition is unavailable, sets a flag to enable fallback in tests.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param partitionName The name of the Platform Cache partition to use.
     */
    public PlatformTokenCache(String partitionName) {
        this(partitionName, new RealPlatformCacheAdapter(partitionName));
    }

    /**
     * @description
     * Constructor accepting a partition name and a cache adapter and is only used in tests.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param partitionName The name of the Platform Cache partition to use.
     * @param adapter The Platform Cache adapter to use (real or mock).
     */
    @TestVisible
    private PlatformTokenCache(String partitionName, IPlatformCacheAdapter adapter) {
        require(!String.isBlank(partitionName), 'Partition name is required.');
        this.partitionName = partitionName;
        this.adapter = adapter;
        /*
        try {
            this.partition = Cache.Org.getPartition(partitionName);
        } catch (Exception e) {
            this.partitionUnavailable = true;
        }
        */
    }

    /**
     * Store a value in the cache with a specified time-to-live (TTL).
     * In test context, if the partition is unavailable, falls back to in-memory storage.
     * In production without fallback, throw the exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The cache key to use.
     * @param value The value to store.
     * @param ttlSecs The time-to-live in seconds for the cache entry.
     * @exception PlatformTokenCacheException if the cache operation fails.
     */
    public void put(String key, String value, Integer ttlSecs) {
        String validatedKey = validateKey(key);
        Integer ttl = clampTtl(ttlSecs);

        if (this.isRunningTest() && !this.adapter.isAvailable()) {
            this.mem().put(validatedKey, value);
            return;
        }

        this.ensurePartitionUsableForWrite();

        try {
            this.adapter.put(validatedKey, value, ttl);
        } catch (Exception ex) {
            if (ALLOW_PROD_FALLBACK || this.isRunningTest()) {
                this.mem().put(validatedKey, value);
            } else {
                throw new PlatformTokenCacheException(
                    'Platform Cache put failed for partition [' + this.partitionName + '] and fallback is disabled',
                    ex
                );
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
        String validatedKey = this.validateKey(key);

        if (this.isRunningTest() && !this.adapter.isAvailable()) {
            return this.mem().get(validatedKey);
        }

        try {
            return (String) this.adapter.get(validatedKey);
        } catch (Exception ex) {
            if (ALLOW_PROD_FALLBACK || this.isRunningTest()) {
                return this.mem().get(validatedKey);
            }
            return null; // read failures behave like a miss in prod
        }
    }

    /**
     * @description
     * Remove a value from the cache using a specified key.
     * In test context, if the partition is unavailable, falls back to in-memory storage.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The cache key to remove.
     */
    public void remove(String key) {
        String validatedKey = this.validateKey(key);

        if (this.isRunningTest() && !this.adapter.isAvailable()) {
            this.mem().remove(validatedKey);
            return;
        }
        try {
            this.adapter.remove(validatedKey);
        } catch (Exception e) {
            if (ALLOW_PROD_FALLBACK || this.isRunningTest()) {
                this.mem().remove(validatedKey);
            }
        }
    }

    /**
     * @description
     * Test-only override for isRunningTest behavior.
     * Allows simulating test context in non-test code paths.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @return `Boolean` True if running in test context, else false.
     */
    private Boolean isRunningTest() {
        return testOverrideIsRunningTest != null ? testOverrideIsRunningTest : Test.isRunningTest();
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
        Map<String, String> testMemory = testMemByPartition.get(this.partitionName);
        if (testMemory == null) {
            testMemory = new Map<String, String>();
            testMemByPartition.put(this.partitionName, testMemory);
        }
        return testMemory;
    }

    /**
     * @description
     * Asserts that a condition is true.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param condition The condition to check.
     * @param message The error message to include if the assertion fails.
     * @exception PlatformTokenCacheException if the condition is false.
     */
    private static void require(Boolean condition, String message) {
        if (!condition) {
            throw new PlatformTokenCacheException(message);
        }
    }

    /**
     * @description
     * Validates a cache key, ensuring it is not null/blank and does not exceed 50 characters.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param key The cache key to validate.
     * @return `String` The validated key.
     * @exception PlatformTokenCacheException if the key is invalid (e.g., null, blank, or too long).
     */
    private String validateKey(String key) {
        require(!String.isBlank(key), 'Key must not be null/blank.');
        require(
            key.length() <= MAX_KEY_LEN,
            'Cache key exceeds 50 characters (platform limit). Provided length=' + (key == null ? 0 : key.length())
        );
        return key;
    }

    /**
     * @description
     * Clamps the TTL (time-to-live) value to ensure it is within acceptable bounds.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @param ttlSecs The requested TTL value in seconds.
     * @return `Integer` The clamped TTL value (default if null/invalid, max if too high).
     * @exception PlatformTokenCacheException if the requested TTL exceeds the maximum allowed limit.
     */
    private Integer clampTtl(Integer ttlSecs) {
        if (ttlSecs == null || ttlSecs <= 0) {
            return DEFAULT_TTL_SECS;
        }
        require(ttlSecs <= MAX_TTL_SECS, 'TTL exceeds maximum limit of ' + MAX_TTL_SECS + ' seconds.');
        return Math.min(ttlSecs, MAX_TTL_SECS);
    }

    /**
     * @description
     * Ensures that the partition is usable for write operations.
     * In production, throws if the partition is unavailable.
     * In test context, allows fallback to in-memory store.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @exception PlatformTokenCacheException if the partition is unavailable in production.
     */
    private void ensurePartitionUsableForWrite() {
        if (!this.adapter.isAvailable()) {
            if (ALLOW_PROD_FALLBACK || this.isRunningTest()) {
                return;
            }

            throw new PlatformTokenCacheException(
                'Platform Cache partition [' + this.partitionName + '] is unavailable.'
            );
        }
    }

    /**
     * @description
     * Exception class for platform token cache errors.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public class PlatformTokenCacheException extends Exception {
    }
}
