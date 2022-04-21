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

    public Datetime skjermetFraDatetime {
        get {
            if (skjermetFra == null)
                return null;
            return Datetime.newInstance(skjermetFra[0], skjermetFra[1], skjermetFra[2], skjermetFra[3], skjermetFra[4], 0);
        }
    }

    public Datetime skjermetTilDatetime {
        get {
            if (skjermetTil == null)
                return null;
            return Datetime.newInstance(skjermetTil[0], skjermetTil[1], skjermetTil[2], skjermetTil[3], skjermetTil[4], 0);
        }
    }

    public static KafkaSkjerming parse(String key, String json) {
        KafkaSkjerming model = (KafkaSkjerming) System.JSON.deserialize(json, KafkaSkjerming.class);
        model.personIdent = key;
        if(model.skjermetFraDatetime >= model.skjermetTilDatetime){
            throw new KafkaSkjermingInvalidValueException(
                'skjermetFra: ' +
                String.valueOf(model.skjermetFraDatetime) +
                ' skjermetTil: ' +
                String.valueOf(model.skjermetTilDatetime)
            );
        }
        return model;
    }
    public class KafkaSkjermingInvalidValueException extends Exception{}
}
