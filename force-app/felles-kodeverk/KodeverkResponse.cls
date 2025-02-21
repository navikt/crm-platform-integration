/**
 * Deserializable response from Felles Kodeverk, to the extent possible.
 * The top level key is known, the keys of its value are not.
 */
public with sharing class KodeverkResponse {

    public Class LanguagedDescriptions {
        public String term{get;}
        public String tekst{get;}
    }

    public Class Meaning {
        public Date gyldigFra{get;}
        public Date gyldigTil{get;}
        public Map<String, LanguagedDescriptions> beskrivelser{get;}
    }

    public Map<String, Meaning[]> betydninger{get;}

    public static KodeverkResponse parse(String json) {
        return (KodeverkResponse) System.JSON.deserialize(json, KodeverkResponse.class);
    }
}
