/**
 * Basically a deserializable PDL_Data
 */
public with sharing class KafkaPerson3 {
    public PDL_HentPerson hentPerson{get;}
    public HentIdenter hentIdenter{get;}

    public class HentIdenter {
        public PDL_IdentInformasjon[] identer{get;}
    }

    public static KafkaPerson3 parse(String json) {
        return (KafkaPerson3) System.JSON.deserialize(json, KafkaPerson3.class);
    }
}
