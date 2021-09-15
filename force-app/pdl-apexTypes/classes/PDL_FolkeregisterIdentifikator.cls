public with sharing class PDL_FolkeregisterIdentifikator {
    public enum Status {
        I_BRUK,
        OPPHOERT
    }
    public enum Type {
        FNR,
        DNR
    }

    public String identifikasjonsnummer;
    public Status status;
    public Type type;
    public PDL_Metadata metadata;
    public PDL_FolkeregisterMetadata folkeregisterMetadata;
}
