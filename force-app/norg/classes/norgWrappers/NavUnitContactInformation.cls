public with sharing class NavUnitContactInformation {
    @AuraEnabled
    public String enhetNr;
    @AuraEnabled
    public String faksnummer;
    @AuraEnabled
    public Integer id;
    @AuraEnabled
    public String spesielleOpplysninger;
    @AuraEnabled
    public String telefonnummer;
    @AuraEnabled
    public String telefonnummerKommentar;
    @AuraEnabled
    public Epost epost;
    @AuraEnabled
    public Adresse besoeksadresse;
    @AuraEnabled
    public Adresse postadresse;
    @AuraEnabled
    public List<publikumsmottak> publikumsmottak;

    public class Epost {
        @AuraEnabled
        public String adresse;
        @AuraEnabled
        public String kommentar;
        @AuraEnabled
        public Boolean kunIntern;
    }

    public class Adresse {
        @AuraEnabled
        public String postnummer;
        @AuraEnabled
        public String poststed;
        @AuraEnabled
        public String adresseTilleggsnavn;
        @AuraEnabled
        public String gatenavn;
        @AuraEnabled
        public String husbokstav;
        @AuraEnabled
        public String husnummer;
        @AuraEnabled
        public String postboksnummer;
        @AuraEnabled
        public String type;
        @AuraEnabled
        public String postboksanlegg;
        @AuraEnabled
        public String concatenatedAddress {
            public get {
                return concatAddress();
            }
            private set;
        }

        public String concatAddress() {
            String address = '';
            String postalCity = '';

            address += addString(address, adresseTilleggsnavn);

            if (true == String.isNotBlank(type) && type.equalsIgnoreCase('postboksadresse')) {
                address += addString(address, 'Postboks');
            }

            address += addString(address, postboksnummer);
            address += addString(address, postboksanlegg);
            address += addString(address, gatenavn);
            address += addString(address, husnummer);
            address += addString(address, husbokstav);

            postalCity += addString(postalCity, postnummer);
            postalCity += addString(postalCity, poststed);

            address += String.isNotBlank(address) && String.isNotBlank(postalCity) ? ', ' : '';
            address += postalCity;

            return address;
        }

        private String addString(String originalString, String stringToAdd) {
            if (String.isBlank(stringToAdd)) {
                return '';
            }

            return String.isNotBlank(originalString) ? ' ' + stringToAdd : stringToAdd;
        }
    }

    public class Aapningstider {
        @AuraEnabled
        public String dag;
        @AuraEnabled
        public Date dato;
        @AuraEnabled
        public String fra;
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public String kommentar;
        @AuraEnabled
        public Boolean stengt;
        @AuraEnabled
        public String til;
    }

    public class Publikumsmottak {
        @AuraEnabled
        public Integer id;
        @AuraEnabled
        public String stedsbeskrivelse;
        @AuraEnabled
        public Adresse besoeksadresse;
        @AuraEnabled
        public List<Aapningstider> aapningstider;
    }
}
