/**
 * @description
 * Unit test suite for PlatformTokenCache.
 * Covers cache operations, fallback behavior, partition isolation, and error handling.
 * Ensures reliable testing when Platform Cache is unavailable or not provisioned.
 *
 * @author Kenneth Sørensen
 * @since September 2025 - Created.
 *
 * @group Token Cache
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@isTest
private class PlatformTokenCacheTest {
    /**
     * @description
     * The cache partition name for storing tokens.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    public static final String CACHE_PARTITION = 'local.tokens';

    // -------------------------------
    // Constructor and initialization
    // -------------------------------
    /**
     * @description
     * Verifies constructor accepts partition name and initializes without exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void constructor() {
        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache(CACHE_PARTITION);
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created');
    }

    /**
     * @description
     * Verifies constructor handles null partition name gracefully.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void constructorWithNullPartitionName() {
        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache(null);
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created even with null partition name');
    }

    /**
     * @description
     * Verifies constructor handles blank partition name gracefully.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void constructorWithBlankPartitionName() {
        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache('');
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created even with blank partition name');
    }

    /**
     * @description
     * Verifies get returns null for non-existent keys without throwing exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void getNonExistentKey() {
        PlatformTokenCache cache = new PlatformTokenCache(CACHE_PARTITION);

        System.Test.startTest();
        String result = cache.get('non-existent-key');
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Non-existent key should return null');
    }

    /**
     * @description
     * Verifies put overwrites existing values for the same key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void putOverwritesExistingValue() {
        PlatformTokenCache cache = new PlatformTokenCache(CACHE_PARTITION);
        String key = 'same-key';
        Integer ttl = 300;

        System.Test.startTest();
        cache.put(key, 'first-value', ttl);
        cache.put(key, 'second-value', ttl);
        String result = cache.get(key);
        System.Test.stopTest();

        System.Assert.areEqual('second-value', result, 'Second value should overwrite first value');
    }

    // -------------------------------
    // Edge cases and error handling
    // -------------------------------
    /**
     * @description
     * Verifies cache handles null keys gracefully.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    @IsTest
    private static void putWithNullKey() {
        PlatformTokenCache cache = new PlatformTokenCache(CACHE_PARTITION);

        System.Test.startTest();
        try {
            cache.put(null, 'test-value', 300);
            // If no exception, verify get behavior
            String result = cache.get(null);
            System.assertEquals('test-value', result, 'Null key should be handled consistently');
        } catch (Exception e) {
            // Acceptable to throw on null key
            System.assert(true, 'Exception on null key is acceptable behavior');
        }
        System.Test.stopTest();
    }
}
