/**
 * Deserializable response from Felles Kodeverk. Objects with unknown key(s),
 * i.e. the  code itself, as well as the language fetched, are represented by a
 * map.
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
