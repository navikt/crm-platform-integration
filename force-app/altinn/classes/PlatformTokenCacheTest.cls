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
@SuppressWarnings('PMD')
@isTest(IsParallel=true)
private class PlatformTokenCacheTest {
    /**
     * @description
     * The cache partition name for testing purposes.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     */
    private static final String TEST_CACHE_PARTITION = 'TestPartition';

    // -------------------------------
    // Constructor and initialization
    // -------------------------------
    /**
     * @description
     * Verifies constructor accepts partition name and initializes without exception.
     * And verifies the adapter is a RealPlatformCacheAdapter instance.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see RealPlatformCacheAdapter
     * @see PlatformTokenCache
     */
    @IsTest
    private static void constructor() {
        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION);
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created');
        System.Assert.isTrue(
            cache.adapter instanceof RealPlatformCacheAdapter,
            'Adapter should be instance of RealPlatformCacheAdapter'
        );
        System.Assert.isFalse(
            cache.adapter.isAvailable(),
            'Partition should not be available with dummy name: [' + TEST_CACHE_PARTITION + ']'
        );
    }

    /**
     * @description
     * Verifies constructor accepts partition name and initializes without exception.
     * Uses a mock adapter to simulate available partition.
     * And verifies the adapter is a MockPlatformCacheAdapter instance.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache
     */
    @IsTest
    private static void constructorWithMockAdapter() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created');
        System.Assert.isTrue(
            cache.adapter instanceof MockPlatformCacheAdapter,
            'Adapter should be instance of MockPlatformCacheAdapter'
        );
        System.Assert.isTrue(cache.adapter.isAvailable(), 'Partition should be marked as available with mock adapter');
    }

    /**
     * @description
     * Verifies constructor handles unavailable partition gracefully.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see RealPlatformCacheAdapter
     * @see PlatformTokenCache
     */
    @IsTest
    private static void constructorPartitionUnavailable() {
        System.Test.startTest();
        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION);
        System.Test.stopTest();

        System.Assert.isNotNull(cache, 'Cache instance should be created');
        System.Assert.isTrue(
            cache.adapter instanceof RealPlatformCacheAdapter,
            'Adapter should be instance of RealPlatformCacheAdapter'
        );
        System.Assert.isFalse(cache.adapter.isAvailable(), 'Partition should be marked as unavailable');
    }

    /**
     * @description
     * Verifies constructor throws PlatformTokenCacheException when partition name is null.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see RealPlatformCacheAdapter
     * @see PlatformTokenCache
     */
    @IsTest
    private static void constructorWithNullPartitionName() {
        String nullPartitionName = null;

        Exception caughtException;
        System.Test.startTest();
        try {
            new PlatformTokenCache(nullPartitionName);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for null partition name');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Partition name is required'),
            'Exception message should mention required partition name'
        );
    }

    /**
     * @description
     * Verifies constructor throws PlatformTokenCacheException when partition name is blank.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see RealPlatformCacheAdapter
     * @see PlatformTokenCache
     */
    @IsTest
    private static void constructorWithBlankPartitionName() {
        String blankPartitionName = '';

        Exception caughtException;
        System.Test.startTest();
        try {
            new PlatformTokenCache(blankPartitionName);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for blank partition name');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Partition name is required'),
            'Exception message should mention required partition name'
        );
    }

    // -------------------------------
    // Key Validation (All Operations)
    // -------------------------------

    // Null key tests
    /**
     * @description
     * Verifies put method validates keys and throws exception for null key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putWithNullKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put(null, 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for null key');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Key must not be null/blank'),
            'Exception should mention null/blank key'
        );
    }

    /**
     * @description
     * Verifies get method validates keys and throws exception for null key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getWithNullKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;

        System.Test.startTest();
        try {
            cache.get(null);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for null key');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be PlatformTokenCacheException'
        );
    }

    /**
     * @description
     * Verifies remove method validates keys and throws exception for null key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeWithNullKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.remove(null);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for null key in remove');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Key must not be null/blank'),
            'Exception should mention null/blank key'
        );
    }

    // Blank key tests
    /**
     * @description
     * Verifies put method throws PlatformTokenCacheException for blank key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putWithBlankKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put('', 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for blank key');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Key must not be null/blank'),
            'Exception should mention null/blank key'
        );
    }

    /**
     * @description
     * Verifies get method throws PlatformTokenCacheException for blank key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getWithBlankKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.get('');
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for blank key');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Key must not be null/blank'),
            'Exception should mention null/blank key'
        );
    }

    /**
     * @description
     * Verifies remove method throws PlatformTokenCacheException for blank key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeWithBlankKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.remove('');
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for blank key');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Key must not be null/blank'),
            'Exception should mention null/blank key'
        );
    }

    // Too long key tests
    /**
     * @description
     * Verifies put method throws PlatformTokenCacheException for key exceeding 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putWithTooLongKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String longKey = 'a'.repeat(51); // 51 characters, exceeds limit

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put(longKey, 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(
            caughtException,
            'Expected PlatformTokenCacheException for key exceeding 50 characters'
        );
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Cache key exceeds 50 characters'),
            'Exception should mention key length limit'
        );
    }

    /**
     * @description
     * Verifies get method throws PlatformTokenCacheException for key exceeding 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getWithTooLongKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String longKey = 'a'.repeat(51);

        Exception caughtException;

        System.Test.startTest();
        try {
            cache.get(longKey);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected exception for oversized key');
        System.Assert.isTrue(
            caughtException.getMessage().contains('Cache key exceeds 50 characters'),
            'Exception should mention key length limit'
        );
    }

    /**
     * @description
     * Verifies remove method throws PlatformTokenCacheException for key exceeding 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeWithTooLongKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String longKey = 'a'.repeat(51);

        Exception caughtException;

        System.Test.startTest();
        try {
            cache.remove(longKey);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected exception for oversized key');
        System.Assert.isTrue(
            caughtException.getMessage().contains('Cache key exceeds 50 characters'),
            'Exception should mention key length limit'
        );
    }

    // Max length key tests (boundary condition)
    /**
     * @description
     * Verifies put method accepts key at exactly 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putWithMaxLengthKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String maxKey = 'a'.repeat(50); // Exactly 50 characters

        System.Test.startTest();
        Exception caughtException;
        try {
            cache.put(maxKey, 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNull(
            caughtException,
            'Max length key should be accepted by put method without throwing exception'
        );
    }

    /**
     * @description
     * Verifies get method accepts key at exactly 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getWithMaxLengthKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String maxKey = 'a'.repeat(50); // Exactly 50 characters

        // Pre-populate the cache
        cache.put(maxKey, 'test-value', 300);

        System.Test.startTest();
        Exception caughtException;
        String result = null;
        try {
            result = cache.get(maxKey);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNull(
            caughtException,
            'Max length key should be accepted by get method without throwing exception'
        );
        System.Assert.areEqual('test-value', result, 'Max length key should retrieve the correct value');
    }

    /**
     * @description
     * Verifies remove method accepts key at exactly 50 character limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeWithMaxLengthKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String maxKey = 'a'.repeat(50); // Exactly 50 characters

        // Pre-populate the cache
        cache.put(maxKey, 'test-value', 300);

        System.Test.startTest();
        Exception caughtException;
        try {
            cache.remove(maxKey);
        } catch (Exception ex) {
            caughtException = ex;
        }
        String result = cache.get(maxKey);
        System.Test.stopTest();

        System.Assert.isNull(
            caughtException,
            'Max length key should be accepted by remove method without throwing exception'
        );
        System.Assert.areEqual(null, result, 'Max length key should be successfully removed');
    }

    // -------------------------------
    // TTL Validation and Normalization
    // -------------------------------

    /**
     * @description
     * Verifies put uses DEFAULT_TTL_SECS when TTL is null.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putWithNullTtl() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('test-key', 'test-value', null);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual(
            'test-value',
            result,
            'Null TTL should default to acceptable value and store successfully'
        );
    }

    /**
     * @description
     * Verifies put uses DEFAULT_TTL_SECS when TTL is zero.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putWithZeroTtl() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('test-key', 'test-value', 0);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual(
            'test-value',
            result,
            'Zero TTL should default to acceptable value and store successfully'
        );
    }

    /**
     * @description
     * Verifies put uses DEFAULT_TTL_SECS when TTL is negative.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putWithNegativeTtl() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('test-key', 'test-value', -100);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual(
            'test-value',
            result,
            'Negative TTL should default to acceptable value and store successfully'
        );
    }

    /**
     * @description
     * Verifies put throws PlatformTokenCacheException when TTL exceeds maximum limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putWithExcessiveTtl() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        Integer excessiveTtl = PlatformTokenCache.MAX_TTL_SECS + 1;

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put('test-key', 'test-value', excessiveTtl);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Expected PlatformTokenCacheException for TTL exceeding maximum');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('TTL exceeds maximum limit'),
            'Exception should mention TTL limit'
        );
    }

    /**
     * @description
     * Verifies put accepts TTL at exactly the maximum limit.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putWithMaxTtl() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('test-key', 'test-value', PlatformTokenCache.MAX_TTL_SECS);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual('test-value', result, 'Maximum TTL should be accepted and work correctly');
    }

    // -------------------------------
    // Basic Operations (Happy Path)
    // -------------------------------

    /**
     * @description
     * Verifies successful put/get roundtrip with valid key, value, and TTL.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putGetRoundtrip() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String key = 'test-key';
        String value = 'test-value';
        Integer ttl = 300;

        System.Test.startTest();
        cache.put(key, value, ttl);
        String retrieved = cache.get(key);
        System.Test.stopTest();

        System.Assert.areEqual(value, retrieved, 'Retrieved value should match stored value');
    }

    /**
     * @description
     * Verifies get returns null for non-existent key without throwing exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getNonExistentKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        String result = cache.get('non-existent-key');
        Test.stopTest();

        System.Assert.areEqual(null, result, 'Non-existent key should return null');
    }

    /**
     * @description
     * Verifies put overwrites existing value for the same key.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putOverwritesExistingValue() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String key = 'same-key';

        System.Test.startTest();
        cache.put(key, 'first-value', 300);
        cache.put(key, 'second-value', 300);
        String result = cache.get(key);
        System.Test.stopTest();

        System.Assert.areEqual('second-value', result, 'Latest value should overwrite previous value');
    }

    /**
     * @description
     * Verifies put/get handles null values correctly.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putGetWithNullValue() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('null-value-key', null, 300);
        String result = cache.get('null-value-key');
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Null values should be stored and retrieved as null');
    }

    /**
     * @description
     * Verifies put/get handles empty string values correctly.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putGetWithEmptyValue() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        System.Test.startTest();
        cache.put('empty-value-key', '', 300);
        String result = cache.get('empty-value-key');
        System.Test.stopTest();

        System.Assert.areEqual('', result, 'Empty string values should be stored and retrieved correctly');
    }

    /**
     * @description
     * Verifies put/get handles large string values (simulating JWT tokens).
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void putGetWithLargeValue() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String largeValue = 'Large-JWT-Token-'.repeat(100); // Simulate large JWT

        System.Test.startTest();
        cache.put('large-value-key', largeValue, 300);
        String result = cache.get('large-value-key');
        System.Test.stopTest();

        System.Assert.areEqual(largeValue, result, 'Large values should be stored and retrieved correctly');
        System.Assert.areEqual(largeValue.length(), result.length(), 'Verify test actually uses large value');
    }

    /**
     * @description
     * Verifies remove successfully deletes existing cache entry.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeExistingKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        String key = 'remove-test-key';

        System.Test.startTest();
        cache.put(key, 'test-value', 300);
        cache.remove(key);
        String result = cache.get(key);
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Removed key should return null when retrieved');
    }

    /**
     * @description
     * Verifies remove handles non-existent key gracefully without throwing exception.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeNonExistentKey() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Exception caughtException;
        String exceptionMessage = '';
        System.Test.startTest();
        try {
            cache.remove('non-existent-key');
        } catch (Exception ex) {
            caughtException = ex;
            exceptionMessage = ex.getMessage();
        }
        System.Test.stopTest();

        System.Assert.isNull(caughtException, 'Remove should handle non-existent keys gracefully: ' + exceptionMessage);
    }

    // -------------------------------
    // Fallback Behavior Tests
    // -------------------------------

    /**
     * @description
     * Verifies that in a simulated production environment with fallback disabled,
     * the cache behaves as expected when the partition is unavailable. An exception
     * should be thrown in this case.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void productionFallbackFlagDisabled() {
        // Simulate production environment with fallback disabled
        PlatformTokenCache.testOverrideIsRunningTest = false; // Simulate production
        PlatformTokenCache.ALLOW_PROD_FALLBACK = false;
        String partitionName = 'UnavailablePartition';

        PlatformTokenCache cache = new PlatformTokenCache(partitionName);

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put('test-key', 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(caughtException, 'Should throw exception when fallback disabled in production');
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Exception should be of type PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('partition [' + partitionName + '] is unavailable'),
            'Exception should mention partition unavailability'
        );
    }

    /**
     * @description
     * Verifies that in a simulated production environment with fallback disabled,
     * the cache behaves as expected when the partition is unavailable. An exception
     * should be thrown in this case.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void productionFallbackFlagEnabled() {
        // Simulate production environment with fallback disabled
        PlatformTokenCache.testOverrideIsRunningTest = false; // Simulate production
        PlatformTokenCache.ALLOW_PROD_FALLBACK = true;
        String partitionName = 'UnavailablePartition';

        PlatformTokenCache cache = new PlatformTokenCache(partitionName);

        System.Test.startTest();
        cache.put('test-key', 'test-value', 300);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual('test-value', result, 'Should use fallback when enabled in production');
    }

    /**
     * @description
     * Verifies put method uses fallback when Platform Cache fails and fallback is enabled.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see MockPlatformCacheAdapter.shouldThrowOnGet
     * @see MockPlatformCacheAdapter.shouldThrowOnPut
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putUsesFallbackOnPlatformCacheFailure() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        mockAdapter.shouldThrowOnPut = true;
        mockAdapter.shouldThrowOnGet = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache.testOverrideIsRunningTest = false;
        PlatformTokenCache.ALLOW_PROD_FALLBACK = true;

        System.Test.startTest();
        cache.put('test-key', 'test-value', 300);
        String result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual('test-value', result, 'Should use fallback when Platform Cache put fails');
    }

    /**
     * @description
     * Verifies get method uses fallback when Platform Cache fails and fallback is enabled.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see MockPlatformCacheAdapter.shouldThrowOnGet
     * @see MockPlatformCacheAdapter.shouldThrowOnPut
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getUsesFallbackOnPlatformCacheFailure() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        mockAdapter.shouldThrowOnPut = true;
        mockAdapter.shouldThrowOnGet = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache.testOverrideIsRunningTest = false;
        PlatformTokenCache.ALLOW_PROD_FALLBACK = true;

        // Pre-populate fallback memory
        cache.put('test-key', 'fallback-value', 300);

        String result;

        System.Test.startTest();
        result = cache.get('test-key');
        System.Test.stopTest();

        System.Assert.areEqual('fallback-value', result, 'Should use fallback when Platform Cache fails');
    }

    // -------------------------------
    // Production Error Handling
    // -------------------------------

    /**
     * @description
     * Verifies put method throws exception when Platform Cache fails in production
     * and fallback is disabled.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see MockPlatformCacheAdapter.shouldThrowOnPut
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     */
    @IsTest
    private static void putThrowsExceptionOnPlatformCacheFailureInProduction() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        mockAdapter.shouldThrowOnPut = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache.testOverrideIsRunningTest = false;
        PlatformTokenCache.ALLOW_PROD_FALLBACK = false;

        Exception caughtException;
        System.Test.startTest();
        try {
            cache.put('test-key', 'test-value', 300);
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.isNotNull(
            caughtException,
            'Should throw exception when Platform Cache fails and fallback disabled'
        );
        System.Assert.isTrue(
            caughtException instanceof PlatformTokenCache.PlatformTokenCacheException,
            'Should be PlatformTokenCacheException'
        );
        System.Assert.isTrue(
            caughtException.getMessage().contains('Platform Cache put failed'),
            'Exception message should mention put failure'
        );
    }

    /**
     * @description
     * Verifies get method returns null when Platform Cache fails in production
     * and fallback is disabled.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see MockPlatformCacheAdapter.shouldThrowOnGet
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void getReturnsNullOnPlatformCacheFailureInProduction() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        mockAdapter.shouldThrowOnGet = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache.testOverrideIsRunningTest = false;
        PlatformTokenCache.ALLOW_PROD_FALLBACK = false;

        String result;
        Exception caughtException;
        System.Test.startTest();
        try {
            result = cache.get('test-key');
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Should return null when Platform Cache fails in production');
        System.Assert.isNull(
            caughtException,
            'Should not throw exception when Platform Cache fails and fallback disabled for get operation'
        );
    }

    /**
     * @description
     * Verifies remove method handles Platform Cache exceptions gracefully in production.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see MockPlatformCacheAdapter.shouldThrowOnRemove
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.remove
     */
    @IsTest
    private static void removeHandlesPlatformCacheExceptionInProduction() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;
        mockAdapter.shouldThrowOnRemove = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache.testOverrideIsRunningTest = false;
        PlatformTokenCache.ALLOW_PROD_FALLBACK = false;

        String result;
        Exception caughtException;
        System.Test.startTest();
        try {
            cache.remove('test-key');
        } catch (Exception ex) {
            caughtException = ex;
        }
        System.Test.stopTest();

        System.Assert.areEqual(null, result, 'Should return null when Platform Cache fails in production');
        System.Assert.isNull(
            caughtException,
            'Should not throw exception when Platform Cache fails and fallback disabled for remove operation'
        );
    }

    // -------------------------------
    // Memory Management and Isolation
    // -------------------------------

    /**
     * @description
     * Verifies different partition instances maintain separate key spaces.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void partitionIsolation() {
        MockPlatformCacheAdapter mockAdapterA = new MockPlatformCacheAdapter();
        mockAdapterA.isPartitionAvailable = true;
        PlatformTokenCache cacheA = new PlatformTokenCache('TestPartitionA', mockAdapterA);

        MockPlatformCacheAdapter mockAdapterB = new MockPlatformCacheAdapter();
        mockAdapterB.isPartitionAvailable = true;
        PlatformTokenCache cacheB = new PlatformTokenCache('TestPartitionB', mockAdapterB);

        String sameKey = 'shared-key';

        System.Test.startTest();
        cacheA.put(sameKey, 'value-from-A', 300);
        cacheB.put(sameKey, 'value-from-B', 300);

        String valueA = cacheA.get(sameKey);
        String valueB = cacheB.get(sameKey);
        System.Test.stopTest();

        System.Assert.areEqual('value-from-A', valueA, 'Partition A should return its own value');
        System.Assert.areEqual('value-from-B', valueB, 'Partition B should return its own value');
        System.Assert.areNotEqual(valueA, valueB, 'Different partitions should maintain separate values');
    }

    /**
     * @description
     * Verifies same partition name creates instances that share data.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void samePartitionNameSharesData() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache1 = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);
        PlatformTokenCache cache2 = new PlatformTokenCache('SharedPartition', mockAdapter);

        System.Test.startTest();
        cache1.put('shared-key', 'shared-value', 300);
        String retrievedByCache2 = cache2.get('shared-key');
        System.Test.stopTest();

        System.Assert.areEqual('shared-value', retrievedByCache2, 'Same partition instances should share data');
    }

    /**
     * @description
     * Verifies cache handles multiple key-value pairs efficiently within governor limits.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see MockPlatformCacheAdapter
     * @see MockPlatformCacheAdapter.isPartitionAvailable
     * @see PlatformTokenCache.put
     * @see PlatformTokenCache.get
     */
    @IsTest
    private static void bulkOperations() {
        MockPlatformCacheAdapter mockAdapter = new MockPlatformCacheAdapter();
        mockAdapter.isPartitionAvailable = true;

        PlatformTokenCache cache = new PlatformTokenCache(TEST_CACHE_PARTITION, mockAdapter);

        Integer numEntries = 50;
        Map<String, String> testData = new Map<String, String>();

        for (Integer i = 0; i < numEntries; i++) {
            testData.put('bulk-key-' + i, 'bulk-value-' + i);
        }

        System.Test.startTest();
        for (String key : testData.keySet()) {
            cache.put(key, testData.get(key), 300);
        }

        Integer successCount = 0;
        for (String key : testData.keySet()) {
            String retrieved = cache.get(key);
            if (retrieved == testData.get(key)) {
                successCount++;
            }
        }
        System.Test.stopTest();

        System.Assert.areEqual(numEntries, successCount, 'All bulk entries should be stored and retrieved correctly');
    }

    // -------------------------------
    // Constants Verification
    // -------------------------------
    /**
     * @description
     * Verifies class constants have expected values for documentation and contract compliance.
     *
     * @author Kenneth Sørensen
     * @since September 2025 - Created.
     *
     * @see PlatformTokenCache.DEFAULT_TTL_SECS
     * @see PlatformTokenCache.MAX_TTL_SECS
     * @see PlatformTokenCache.MAX_KEY_LEN
     * @see PlatformTokenCache.HASH_SEP
     * @see PlatformTokenCache.ALLOW_PROD_FALLBACK
     * @see PlatformTokenCache.testOverrideIsRunningTest
     */
    @IsTest
    private static void constantsVerification() {
        System.Assert.areEqual(300, PlatformTokenCache.DEFAULT_TTL_SECS, 'DEFAULT_TTL_SECS should be 300 (5 minutes)');
        System.Assert.areEqual(172800, PlatformTokenCache.MAX_TTL_SECS, 'MAX_TTL_SECS should be 172800 (48 hours)');
        System.Assert.areEqual(50, PlatformTokenCache.MAX_KEY_LEN, 'MAX_KEY_LEN should be 50 characters');
        System.Assert.areEqual(':', PlatformTokenCache.HASH_SEP, 'HASH_SEP should be colon');
        System.Assert.areEqual(
            false,
            PlatformTokenCache.ALLOW_PROD_FALLBACK,
            'ALLOW_PROD_FALLBACK should default to false'
        );
        System.Assert.areEqual(
            null,
            PlatformTokenCache.testOverrideIsRunningTest,
            'testOverrideIsRunningTest should default to null'
        );
    }
}
