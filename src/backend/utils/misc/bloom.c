#include "postgres.h"
#include <stdlib.h>
#include <string.h>
#include <math.h>
#include <stdint.h>
#include <ctype.h>
/* MurmurHash3 implementation for simplicity */
uint32_t murmurhash(const char *key, size_t len, uint32_t seed)
{
    uint32_t h = seed;
    for (size_t i = 0; i < len; i++)
    {
        h ^= key[i];
        h *= 0x5bd1e995;
        h ^= h >> 15;
    }
    return h;
}

/* Initialize the Bloom filter */
CustomBloomFilter *bloom_filter_create(size_t n, double p)
{
    CustomBloomFilter *filter = (CustomBloomFilter *)malloc(sizeof(CustomBloomFilter));
    if (!filter)
    {
        perror("Failed to allocate memory for Bloom filter");
        exit(EXIT_FAILURE);
    }

    // Calculate the size of the bit array (in bits)
    filter->size = ceil(-(n * log(p)) / (log(2) * log(2)));

    // Calculate the number of hash functions
    filter->hash_count = ceil((filter->size / (double)n) * log(2));

    // Allocate the bit array
    size_t byte_size = (filter->size + 7) / 8; // Convert bits to bytes
    filter->bit_array = (uint8_t *)calloc(byte_size, sizeof(uint8_t));
    if (!filter->bit_array)
    {
        perror("Failed to allocate memory for Bloom filter bit array");
        free(filter);
        exit(EXIT_FAILURE);
    }
    // elog(INFO, "CREATED FILTER SIZE %d HASH %d\n", filter->size, filter->hash_count);
    return filter;
}
/* Add an item to the Bloom filter */
void bloom_filter_add(CustomBloomFilter *filter, const char *item)
{
    size_t len = strlen(item);
    // elog(INFO, "ADDING item %s to filter\n", item);
    for (int i = 0; i < filter->hash_count; i++)
    {
        uint32_t hash = murmurhash(item, len, i);
        size_t index = hash % filter->size;
        filter->bit_array[index / 8] |= (1 << (index % 8)); // Set the bit
    }
}

/* Check if an item is in the Bloom filter */
int bloom_filter_check(CustomBloomFilter *filter, const char *item)
{
    size_t len = strlen(item);
    for (int i = 0; i < filter->hash_count; i++)
    {
        uint32_t hash = murmurhash(item, len, i);
        size_t index = hash % filter->size;
        if (!(filter->bit_array[index / 8] & (1 << (index % 8))))
        {
            return 0; // Definitely not in the set
        }
    }
    return 1; // Possibly in the set
}

/* Free the Bloom filter */
void bloom_filter_free(CustomBloomFilter *filter)
{
    if (filter)
    {
        free(filter->bit_array);
        free(filter);
    }
}

/* Encode Bloom filter to Hexadecimal */
char *bloom_filter_encode_hex_with_metadata(CustomBloomFilter *filter)
{
    size_t byte_size = (filter->size + 7) / 8;                       // Bits to bytes
    size_t metadata_size = 8 + 2;                                    // 8 chars for size, 2 chars for hash_count
    char *hex = (char *)malloc(metadata_size + (byte_size * 2) + 1); // +1 for null terminator
    if (!hex)
        return NULL;

    // Encode metadata: size (8 hex chars) and hash count (2 hex chars)
    sprintf(hex, "%08lx%02x", filter->size, filter->hash_count);

    // Append bit array as hex
    for (size_t i = 0; i < byte_size; i++)
    {
        sprintf(hex + metadata_size + (i * 2), "%02x", filter->bit_array[i]);
    }

    hex[metadata_size + (byte_size * 2)] = '\0'; // Null-terminate the string
    return hex;
}

/* Decode Bloom filter from Hexadecimal */
CustomBloomFilter *bloom_filter_decode_hex_with_metadata(const char *hex)
{
    if (!hex || strlen(hex) < 10)
    {
        elog(WARNING, "Invalid hex string for filter\n");
        return NULL;
    }

    // Decode metadata: size and hash count
    size_t size;
    int hash_count;
    sscanf(hex, "%08lx%02x", &size, &hash_count);

    // Calculate bit array size
    size_t byte_size = (size + 7) / 8;

    // Allocate memory for bit array
    uint8_t *bit_array = (uint8_t *)malloc(byte_size);
    if (!bit_array)
    {
        perror("Failed to allocate memory for bit array");
        return NULL;
    }

    // Decode bit array
    const char *bit_array_hex = hex + 10; // Skip metadata (8 + 2 = 10 chars)
    for (size_t i = 0; i < byte_size; i++)
    {
        unsigned int byte_val;
        sscanf(bit_array_hex + (i * 2), "%02x", &byte_val);
        bit_array[i] = (uint8_t)byte_val;
    }

    // Create BloomFilter
    CustomBloomFilter *filter = (CustomBloomFilter *)malloc(sizeof(CustomBloomFilter));
    if (!filter)
    {
        perror("Failed to allocate memory for CustomBloomFilter");
        free(bit_array);
        return NULL;
    }

    filter->size = size;
    filter->hash_count = hash_count;
    filter->bit_array = bit_array;
    return filter;
}