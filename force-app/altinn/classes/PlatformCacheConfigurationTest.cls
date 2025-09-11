/**
 * @description
 * Unit test suite for Platform Cache Configuration.
 *
 * @author Kenneth Sørensen
 * @since August 2025 - Created.
 *
 * @group Platform Cache Configuration
 */
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
@isTest
private class PlatformCacheConfigurationTest {
    /**
     * @description
     * The default configured partition for the Platform Cache in our org.
     * What partition SHOULD be flagged as the org's Default in Setup → Platform Cache → Partitions.
     * Accepts either plain ("partition_name") or qualified ("local.partition_name" or
     * "<ns>.partition_name").
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     */
    private static final String EXPECTED_DEFAULT_PARTITION = 'tokens';

    /**
     * @description
     * The 'tokens' configured partition for the Platform Cache in our org.
     * Accepts either plain ("tokens") or qualified ("local.tokens" or "<ns>.tokens").
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     */
    private static final String TOKENS_PARTITION = 'tokens';

    /**
     * @description
     * Short TTL for probe writes; Minimum 5 minutes as required by Salesforce.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     */
    private static final Integer PROBE_TTL_SECONDS = 300;

    /**
     * @description
     * Qualifies a partition name: "partition_name" -> "local.partition_name";
     * keeps already-qualified as-is.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param partitionName The partition name to qualify.
     * @return The qualified partition name, or null if the input is blank.
     */
    private static String toQualifiedPartitionName(String partitionName) {
        if (String.isBlank(partitionName)) {
            return null;
        }
        return partitionName.contains('.') ? partitionName : 'local.' + partitionName;
    }

    /**
     * @description
     * Returns the expected default partition as a fully qualified name.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @return The qualified name of the default partition.
     */
    private static String getExpectedDefaultQualified() {
        return toQualifiedPartitionName(EXPECTED_DEFAULT_PARTITION);
    }

    /**
     * @description
     * Returns the org-configured default partition name, qualified. Returns null if none.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @return The qualified name of the default partition.
     */
    private static String getConfiguredDefaultQualifiedOrNull() {
        String configured = Cache.Org.getName(); // Name of the partition flagged "Default" in Setup

        if (String.isBlank(configured)) {
            return null;
        }

        return toQualifiedPartitionName(configured);
    }

    /**
     * @description
     * Attempts to fetch a partition object; returns `null` if invalid/missing instead of throwing.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param qualifiedName The qualified name of the partition to retrieve.
     * @return The requested partition, or null if not found.
     */
    private static Cache.OrgPartition tryGetPartition(String qualifiedName) {
        if (String.isBlank(qualifiedName)) {
            return null;
        }

        try {
            return Cache.Org.getPartition(qualifiedName);
        } catch (Cache.Org.OrgCacheException e) {
            return null;
        }
    }

    /**
     * @description
     * Write + read through `Cache.Org` (uses default).
     * Returns the read value (`null` onmiss/unallocated).
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param key The cache key to use.
     * @param value The value to write.
     * @param ttlSeconds The time-to-live for the cache entry.
     * @return The value read back from the cache, or `null` if not found.
     */
    private static String roundTripViaDefault(String key, String value, Integer ttlSeconds) {
        Cache.Org.put(key, value, ttlSeconds);
        Object out = Cache.Org.get(key);
        return (out == null) ? null : (String) out;
    }

    /**
     * @description
     * Write + read through a partition object. Returns the read value (`null` on miss/unallocated).
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     *
     * @param partition The partition to use for the operation.
     * @param key The cache key to use.
     * @param value The value to write.
     * @param ttlSeconds The time-to-live for the cache entry.
     * @return The value read back from the cache, or `null` if not found.
     */
    private static String roundTripViaPartition(
        Cache.OrgPartition partition,
        String key,
        String value,
        Integer ttlSeconds
    ) {
        if (partition == null) {
            return null;
        }

        partition.put(key, value, ttlSeconds);
        Object out = partition.get(key);
        return (out == null) ? null : (String) out;
    }

    @SuppressWarnings('PMD.MethodNamingConventions')
    @IsTest
    static void defaultPartition_isConfigured_and_matchesExpected() {
        String expectedQualified = getExpectedDefaultQualified();

        String configuredQualified = getConfiguredDefaultQualifiedOrNull();

        System.Assert.areNotEqual(
            null,
            configuredQualified,
            'No default Platform Cache partition is configured. ' +
            'Set one in Setup → Platform Cache → Partitions (check “Default Partition”).'
        );
        System.Assert.areEqual(
            expectedQualified.toLowerCase(),
            configuredQualified.toLowerCase(),
            'Default Platform Cache mismatch. Expected: ' +
                expectedQualified +
                ' but found: ' +
                configuredQualified +
                '. ' +
                'Fix in Setup → Platform Cache → Partitions by setting "' +
                EXPECTED_DEFAULT_PARTITION +
                '" as Default.'
        );
    }

    @SuppressWarnings('PMD.MethodNamingConventions')
    @IsTest
    static void defaultPartition_isAllocated_and_roundTrips_via_CacheOrg() {
        String configuredQualified = getConfiguredDefaultQualifiedOrNull();

        System.Assert.areNotEqual(
            null,
            configuredQualified,
            'No default Platform Cache partition is configured. ' +
            'Set one in Setup → Platform Cache → Partitions (check “Default Partition”).'
        );

        String probeKey = 'pcprobeorg';
        String probeValue = 'ok';

        System.Test.startTest();
        String readBack = roundTripViaDefault(probeKey, probeValue, PROBE_TTL_SECONDS);
        System.Test.stopTest();

        System.Assert.isNotNull(
            readBack,
            'Default partition "' +
                configuredQualified +
                '" exists but appears UNALLOCATED (0 MB). ' +
                'Go to Setup → Platform Cache → Org Cache Allocations and assign > 0 MB to the default partition.'
        );
        System.Assert.areEqual('ok', readBack, 'Default partition failed a simple round-trip via Cache.Org API.');
    }

    /**
     * @description
     * Tests that the default partition is correctly configured and allocated via the Cache.Org API.
     *
     * @author Kenneth Sørensen
     * @since August 2025 - Created.
     */
    /*@IsTest
    static void defaultPartition_matchesExpected_and_isAllocated_via_CacheOrg_API() {
        String expectedQualified = getExpectedDefaultQualified();

        String configuredQualified = getConfiguredDefaultQualifiedOrFail();

        System.assertEquals(
            expectedQualified.toLowerCase(),
            configuredQualified.toLowerCase(),
            'Default Platform Cache mismatch. Expected: ' +
                expectedQualified +
                ' but found: ' +
                configuredQualified +
                '. ' +
                'Fix in Setup → Platform Cache → Partitions by setting "' +
                EXPECTED_DEFAULT_PARTITION +
                '" as Default.'
        );

        Test.startTest();
        assertDefaultPartitionOperationalWithOrgApi('Default partition is "' + configuredQualified + '".');
        Test.stopTest();
    }*/
    /*
    @IsTest
    static void defaultPartition_roundTrips_via_PartitionObject_API() {
        // Arrange
        String configuredQualified = getConfiguredDefaultQualifiedOrFail();
        Cache.OrgPartition defaultPartition = getPartitionOrFail(configuredQualified);

        // Act
        Test.startTest();
        // Assert (round-trip proves allocation > 0 MB)
        assertPartitionOperationalWithPartitionApi(defaultPartition, configuredQualified);
        Test.stopTest();
    }

    @IsTest
    static void fullyQualifiedKey_roundTrips_on_defaultPartition() {
        // Arrange
        String configuredQualified = getConfiguredDefaultQualifiedOrFail();
        String key = configuredQualified + '.pc_probe_key_' + Crypto.getRandomInteger();

        // Act
        Test.startTest();
        Cache.Org.put(key, 'ok', PROBE_TTL_SECONDS);
        Object value = Cache.Org.get(key);
        Test.stopTest();

        // Assert
        System.assertNotEquals(
            null,
            value,
            'Fully-qualified key roundtrip failed on default "' +
                configuredQualified +
                '". ' +
                'Likely 0 MB allocation. Allocate > 0 MB in Org Cache Allocations.'
        );
        System.assertEquals('ok', (String) value, 'Default partition failed round-trip via fully-qualified key.');
    }*/
}
