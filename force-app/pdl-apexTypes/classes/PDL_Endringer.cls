public with sharing class PDL_Endringer {
    public enum Endringstype {
        OPPRETT,
        KORRIGER,
        OPPHOER
    }

    public Endringstype type;
    public String registrert;
    public String registrertAv;
    public String systemKilde;
    public String kilde;
}
