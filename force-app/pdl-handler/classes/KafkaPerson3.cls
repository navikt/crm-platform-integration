/**
 * Basically a deserializable PDL_Data
 */
public with sharing class KafkaPerson3 {
    @TestVisible
    public PDL_HentPerson hentPerson{get;}
    @TestVisible
    public HentIdenter hentIdenter{get;}

    public class HentIdenter {
        @TestVisible
        public PDL_IdentInformasjon[] identer{get;}
    }

    public static KafkaPerson3 parse(String json) {
        return (KafkaPerson3) System.JSON.deserialize(json, KafkaPerson3.class);
    }
}
