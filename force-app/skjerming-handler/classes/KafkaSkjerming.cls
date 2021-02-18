public with sharing class KafkaSkjerming {
    public String personIdent;
    public List<Integer> skjermetFra;
    public List<Integer> skjermetTil;

    public Date skjermetFraDate {
        get {
            if (skjermetFra == null)
                return null;
            return Date.newInstance(skjermetFra[0], skjermetFra[1], skjermetFra[2]);
        }
    }

    public Date skjermetTilDate {
        get {
            if (skjermetTil == null)
                return null;
            return Date.newInstance(skjermetTil[0], skjermetTil[1], skjermetTil[2]);
        }
    }

    public static KafkaSkjerming parse(String key, String json) {
        KafkaSkjerming model = (KafkaSkjerming) System.JSON.deserialize(json, KafkaSkjerming.class);
        model.personIdent = key;
        return model;
    }
}
