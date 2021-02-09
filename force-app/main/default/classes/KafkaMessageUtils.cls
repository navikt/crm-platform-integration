public with sharing class KafkaMessageUtils {
    // Provides decoding for url encoded base64 strings which otherwise fails with EncodingUtil
    public static Blob base64ULSafeDecode(String input) {
        if (String.isBlank(input)) {
            return null;
        }

        return EncodingUtil.base64Decode(
            input.replace('-', '+')
                .replace('_', '/')
                .rightPad(
                    math.mod(
                        input.length() + (math.mod(4 - input.length(), 4)),
                        4
                    )
                )
                .replace(' ', '=')
        );
    }
}
