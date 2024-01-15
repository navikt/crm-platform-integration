@IsTest
private with sharing class KafkaPdlPersondokumentHandlerTest {
    @TestSetup
    static void makeData() {
        // record for setting correct Country from Country ISO code
        List<Common_Code__c> commonCodes = new List<Common_Code__c>();

        Common_Code__c ccIND = new Common_Code__c();
        ccIND.Name = 'India';
        ccIND.CRM_Code_Set__c = 'Landkoder';
        ccIND.CRM_Code__c = 'IND';
        ccIND.CRM_Active__c = true;
        commonCodes.add(ccIND);

        Common_Code__c ccNOR = new Common_Code__c();
        ccNOR.Name = 'Norge';
        ccNOR.CRM_Code_Set__c = 'Landkoder';
        ccNOR.CRM_Code__c = 'NOR';
        ccNOR.CRM_Active__c = true;
        commonCodes.add(ccNOR);

        insert commonCodes;
    }

    @isTest
    static void testCreatePersonFromPersonDokument() {
        List<KafkaMessage__c> kafkaMessages = new List<KafkaMessage__c>();
        kafkaMessages.add(
            new KafkaMessage__c(
                CRM_Topic__c = 'pdl.pdl-persondokument-tagged-v1',
                CRM_Key__c = '2594819806563',
                //{
                //  "hentPerson": {
                //    "adressebeskyttelse": [],
                //    "bostedsadresse": [
                //      {
                //        "angittFlyttedato": "1972-07-01",
                //        "gyldigFraOgMed": "1972-07-01T00:00:00",
                //        "gyldigTilOgMed": null,
                //        "coAdressenavn": null,
                //        "vegadresse": {
                //          "matrikkelId": 138391329,
                //          "husnummer": "11",
                //          "husbokstav": null,
                //          "bruksenhetsnummer": null,
                //          "adressenavn": "Marihandstien",
                //          "kommunenummer": "1806",
                //          "tilleggsnavn": null,
                //          "postnummer": "8515",
                //          "bydelsnummer": null,
                //          "koordinater": {
                //            "x": 599891.371546,
                //            "y": 7592866.900335,
                //            "z": null
                //          }
                //        },
                //        "matrikkeladresse": null,
                //        "ukjentBosted": null,
                //        "utenlandskAdresse": null,
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:37.045",
                //          "gyldighetstidspunkt": "1972-07-01T00:00:00",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "e52735a2-be2f-4b2a-b578-dec2f032e8dd",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:37.045",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "doedsfall": [],
                //    "foedsel": [
                //      {
                //        "foedselsaar": 1972,
                //        "foedselsdato": "1972-07-01",
                //        "foedeland": "BEL",
                //        "foedested": "Fødested i/på BELGIA",
                //        "foedekommune": null,
                //        "metadata": {
                //          "opplysningsId": "fadd61cf-0da2-4df1-9492-a5fb1532f50f",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:35.412",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        },
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:35.412",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:35.412",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        }
                //      }
                //    ],
                //    "folkeregisteridentifikator": [
                //      {
                //        "identifikasjonsnummer": "01077211027",
                //        "type": "FNR",
                //        "status": "I_BRUK",
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:34.945",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:34.945",
                //          "opphoerstidspunkt": null,
                //          "kilde": "srvdolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "4ed45e87-e02b-4aa0-8601-689bbd58f20f",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:35.058",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "srvdolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "folkeregisterpersonstatus": [
                //      {
                //        "status": "bosatt",
                //        "forenkletStatus": "bosattEtterFolkeregisterloven",
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:37.899",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:37.899",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "37065f2d-5f9e-4046-a6d3-9f6856961cd6",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:37.899",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "forelderBarnRelasjon": [],
                //    "fullmakt": [],
                //    "kjoenn": [
                //      {
                //        "kjoenn": "KVINNE",
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:36.62",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:36.62",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "0847b543-0847-4494-9fca-857a1ca51a73",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:36.62",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "navn": [
                //      {
                //        "fornavn": "ARTIG",
                //        "mellomnavn": null,
                //        "etternavn": "SNERK",
                //        "forkortetNavn": "SNERK ARTIG",
                //        "originaltNavn": null,
                //        "gyldigFraOgMed": "2022-01-14",
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:36.237",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:36.237",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "44fbf7a6-6885-48ad-a303-e9d90fa4567f",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:36.237",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "oppholdsadresse": [],
                //    "sikkerhetstiltak": [],
                //    "sivilstand": [
                //      {
                //        "type": "UGIFT",
                //        "gyldigFraOgMed": null,
                //        "relatertVedSivilstand": null,
                //        "bekreftelsesdato": null,
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:38.684",
                //          "gyldighetstidspunkt": "2022-01-14T15:41:38.684",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "2d7f6623-3ba4-44d3-8e04-efced8cd77e3",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:38.684",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "statsborgerskap": [
                //      {
                //        "land": "NOR",
                //        "bekreftelsesdato": null,
                //        "gyldigFraOgMed": "1972-07-01",
                //        "gyldigTilOgMed": null,
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:38.327",
                //          "gyldighetstidspunkt": "1972-07-01T00:00:00",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "672b293a-b18e-4cd1-9a16-d4a03eb8581d",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:38.326",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "tilrettelagtKommunikasjon": [],
                //    "telefonnummer": [],
                //    "innflyttingTilNorge": [
                //      {
                //        "fraflyttingsland": "BEL",
                //        "fraflyttingsstedIUtlandet": null,
                //        "folkeregistermetadata": {
                //          "ajourholdstidspunkt": "2022-01-14T15:41:37.532",
                //          "gyldighetstidspunkt": "1972-07-01T00:00:00",
                //          "opphoerstidspunkt": null,
                //          "kilde": "Dolly",
                //          "aarsak": null,
                //          "sekvens": null
                //        },
                //        "metadata": {
                //          "opplysningsId": "5345af76-ac03-4461-9d5c-f17c42ea8a32",
                //          "master": "FREG",
                //          "endringer": [
                //            {
                //              "type": "OPPRETT",
                //              "registrert": "2022-01-14T15:41:37.532",
                //              "registrertAv": "Folkeregisteret",
                //              "systemkilde": "FREG",
                //              "kilde": "Dolly"
                //            }
                //          ],
                //          "historisk": false
                //        }
                //      }
                //    ],
                //    "utflyttingFraNorge": [],
                //    "vergemaalEllerFremtidsfullmakt": []
                //  },
                //  "hentIdenter": {
                //    "identer": [
                //      {
                //        "ident": "01077211027",
                //        "historisk": false,
                //        "gruppe": "FOLKEREGISTERIDENT",
                //        "metadata": null,
                //        "folkeregistermetadata": null
                //      },
                //      {
                //        "ident": "2594819806563",
                //        "historisk": false,
                //        "gruppe": "AKTORID",
                //        "metadata": null,
                //        "folkeregistermetadata": null
                //      }
                //    ]
                //  }
                //}
                CRM_Value__c = 'eyJoZW50UGVyc29uIjp7ImFkcmVzc2ViZXNreXR0ZWxzZSI6W10sImJvc3RlZHNhZHJlc3NlIjpbeyJhbmdpdHRGbHl0dGVkYXRvIjoiMTk3Mi0wNy0wMSIsImd5bGRpZ0ZyYU9nTWVkIjoiMTk3Mi0wNy0wMVQwMDowMDowMCIsImd5bGRpZ1RpbE9nTWVkIjpudWxsLCJjb0FkcmVzc2VuYXZuIjpudWxsLCJ2ZWdhZHJlc3NlIjp7Im1hdHJpa2tlbElkIjoxMzgzOTEzMjksImh1c251bW1lciI6IjExIiwiaHVzYm9rc3RhdiI6bnVsbCwiYnJ1a3NlbmhldHNudW1tZXIiOm51bGwsImFkcmVzc2VuYXZuIjoiTWFyaWhhbmRzdGllbiIsImtvbW11bmVudW1tZXIiOiIxODA2IiwidGlsbGVnZ3NuYXZuIjpudWxsLCJwb3N0bnVtbWVyIjoiODUxNSIsImJ5ZGVsc251bW1lciI6bnVsbCwia29vcmRpbmF0ZXIiOnsieCI6NTk5ODkxLjM3MTU0NiwieSI6NzU5Mjg2Ni45MDAzMzUsInoiOm51bGx9fSwibWF0cmlra2VsYWRyZXNzZSI6bnVsbCwidWtqZW50Qm9zdGVkIjpudWxsLCJ1dGVubGFuZHNrQWRyZXNzZSI6bnVsbCwiZm9sa2VyZWdpc3Rlcm1ldGFkYXRhIjp7ImFqb3VyaG9sZHN0aWRzcHVua3QiOiIyMDIyLTAxLTE0VDE1OjQxOjM3LjA0NSIsImd5bGRpZ2hldHN0aWRzcHVua3QiOiIxOTcyLTA3LTAxVDAwOjAwOjAwIiwib3BwaG9lcnN0aWRzcHVua3QiOm51bGwsImtpbGRlIjoiRG9sbHkiLCJhYXJzYWsiOm51bGwsInNla3ZlbnMiOm51bGx9LCJtZXRhZGF0YSI6eyJvcHBseXNuaW5nc0lkIjoiZTUyNzM1YTItYmUyZi00YjJhLWI1NzgtZGVjMmYwMzJlOGRkIiwibWFzdGVyIjoiRlJFRyIsImVuZHJpbmdlciI6W3sidHlwZSI6Ik9QUFJFVFQiLCJyZWdpc3RyZXJ0IjoiMjAyMi0wMS0xNFQxNTo0MTozNy4wNDUiLCJyZWdpc3RyZXJ0QXYiOiJGb2xrZXJlZ2lzdGVyZXQiLCJzeXN0ZW1raWxkZSI6IkZSRUciLCJraWxkZSI6IkRvbGx5In1dLCJoaXN0b3Jpc2siOmZhbHNlfX1dLCJkb2Vkc2ZhbGwiOltdLCJmb2Vkc2VsIjpbeyJmb2Vkc2Vsc2FhciI6MTk3MiwiZm9lZHNlbHNkYXRvIjoiMTk3Mi0wNy0wMSIsImZvZWRlbGFuZCI6IkJFTCIsImZvZWRlc3RlZCI6IkbDuGRlc3RlZCBpL3DDpSBCRUxHSUEiLCJmb2VkZWtvbW11bmUiOm51bGwsIm1ldGFkYXRhIjp7Im9wcGx5c25pbmdzSWQiOiJmYWRkNjFjZi0wZGEyLTRkZjEtOTQ5Mi1hNWZiMTUzMmY1MGYiLCJtYXN0ZXIiOiJGUkVHIiwiZW5kcmluZ2VyIjpbeyJ0eXBlIjoiT1BQUkVUVCIsInJlZ2lzdHJlcnQiOiIyMDIyLTAxLTE0VDE1OjQxOjM1LjQxMiIsInJlZ2lzdHJlcnRBdiI6IkZvbGtlcmVnaXN0ZXJldCIsInN5c3RlbWtpbGRlIjoiRlJFRyIsImtpbGRlIjoiRG9sbHkifV0sImhpc3RvcmlzayI6ZmFsc2V9LCJmb2xrZXJlZ2lzdGVybWV0YWRhdGEiOnsiYWpvdXJob2xkc3RpZHNwdW5rdCI6IjIwMjItMDEtMTRUMTU6NDE6MzUuNDEyIiwiZ3lsZGlnaGV0c3RpZHNwdW5rdCI6IjIwMjItMDEtMTRUMTU6NDE6MzUuNDEyIiwib3BwaG9lcnN0aWRzcHVua3QiOm51bGwsImtpbGRlIjoiRG9sbHkiLCJhYXJzYWsiOm51bGwsInNla3ZlbnMiOm51bGx9fV0sImZvbGtlcmVnaXN0ZXJpZGVudGlmaWthdG9yIjpbeyJpZGVudGlmaWthc2pvbnNudW1tZXIiOiIwMTA3NzIxMTAyNyIsInR5cGUiOiJGTlIiLCJzdGF0dXMiOiJJX0JSVUsiLCJmb2xrZXJlZ2lzdGVybWV0YWRhdGEiOnsiYWpvdXJob2xkc3RpZHNwdW5rdCI6IjIwMjItMDEtMTRUMTU6NDE6MzQuOTQ1IiwiZ3lsZGlnaGV0c3RpZHNwdW5rdCI6IjIwMjItMDEtMTRUMTU6NDE6MzQuOTQ1Iiwib3BwaG9lcnN0aWRzcHVua3QiOm51bGwsImtpbGRlIjoic3J2ZG9sbHkiLCJhYXJzYWsiOm51bGwsInNla3ZlbnMiOm51bGx9LCJtZXRhZGF0YSI6eyJvcHBseXNuaW5nc0lkIjoiNGVkNDVlODctZTAyYi00YWEwLTg2MDEtNjg5YmJkNThmMjBmIiwibWFzdGVyIjoiRlJFRyIsImVuZHJpbmdlciI6W3sidHlwZSI6Ik9QUFJFVFQiLCJyZWdpc3RyZXJ0IjoiMjAyMi0wMS0xNFQxNTo0MTozNS4wNTgiLCJyZWdpc3RyZXJ0QXYiOiJGb2xrZXJlZ2lzdGVyZXQiLCJzeXN0ZW1raWxkZSI6IkZSRUciLCJraWxkZSI6InNydmRvbGx5In1dLCJoaXN0b3Jpc2siOmZhbHNlfX1dLCJmb2xrZXJlZ2lzdGVycGVyc29uc3RhdHVzIjpbeyJzdGF0dXMiOiJib3NhdHQiLCJmb3JlbmtsZXRTdGF0dXMiOiJib3NhdHRFdHRlckZvbGtlcmVnaXN0ZXJsb3ZlbiIsImZvbGtlcmVnaXN0ZXJtZXRhZGF0YSI6eyJham91cmhvbGRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozNy44OTkiLCJneWxkaWdoZXRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozNy44OTkiLCJvcHBob2Vyc3RpZHNwdW5rdCI6bnVsbCwia2lsZGUiOiJEb2xseSIsImFhcnNhayI6bnVsbCwic2VrdmVucyI6bnVsbH0sIm1ldGFkYXRhIjp7Im9wcGx5c25pbmdzSWQiOiIzNzA2NWYyZC01ZjllLTQwNDYtYTZkMy05ZjY4NTY5NjFjZDYiLCJtYXN0ZXIiOiJGUkVHIiwiZW5kcmluZ2VyIjpbeyJ0eXBlIjoiT1BQUkVUVCIsInJlZ2lzdHJlcnQiOiIyMDIyLTAxLTE0VDE1OjQxOjM3Ljg5OSIsInJlZ2lzdHJlcnRBdiI6IkZvbGtlcmVnaXN0ZXJldCIsInN5c3RlbWtpbGRlIjoiRlJFRyIsImtpbGRlIjoiRG9sbHkifV0sImhpc3RvcmlzayI6ZmFsc2V9fV0sImZvcmVsZGVyQmFyblJlbGFzam9uIjpbXSwiZnVsbG1ha3QiOltdLCJram9lbm4iOlt7Imtqb2VubiI6IktWSU5ORSIsImZvbGtlcmVnaXN0ZXJtZXRhZGF0YSI6eyJham91cmhvbGRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozNi42MiIsImd5bGRpZ2hldHN0aWRzcHVua3QiOiIyMDIyLTAxLTE0VDE1OjQxOjM2LjYyIiwib3BwaG9lcnN0aWRzcHVua3QiOm51bGwsImtpbGRlIjoiRG9sbHkiLCJhYXJzYWsiOm51bGwsInNla3ZlbnMiOm51bGx9LCJtZXRhZGF0YSI6eyJvcHBseXNuaW5nc0lkIjoiMDg0N2I1NDMtMDg0Ny00NDk0LTlmY2EtODU3YTFjYTUxYTczIiwibWFzdGVyIjoiRlJFRyIsImVuZHJpbmdlciI6W3sidHlwZSI6Ik9QUFJFVFQiLCJyZWdpc3RyZXJ0IjoiMjAyMi0wMS0xNFQxNTo0MTozNi42MiIsInJlZ2lzdHJlcnRBdiI6IkZvbGtlcmVnaXN0ZXJldCIsInN5c3RlbWtpbGRlIjoiRlJFRyIsImtpbGRlIjoiRG9sbHkifV0sImhpc3RvcmlzayI6ZmFsc2V9fV0sIm5hdm4iOlt7ImZvcm5hdm4iOiJBUlRJRyIsIm1lbGxvbW5hdm4iOm51bGwsImV0dGVybmF2biI6IlNORVJLIiwiZm9ya29ydGV0TmF2biI6IlNORVJLIEFSVElHIiwib3JpZ2luYWx0TmF2biI6bnVsbCwiZ3lsZGlnRnJhT2dNZWQiOiIyMDIyLTAxLTE0IiwiZm9sa2VyZWdpc3Rlcm1ldGFkYXRhIjp7ImFqb3VyaG9sZHN0aWRzcHVua3QiOiIyMDIyLTAxLTE0VDE1OjQxOjM2LjIzNyIsImd5bGRpZ2hldHN0aWRzcHVua3QiOiIyMDIyLTAxLTE0VDE1OjQxOjM2LjIzNyIsIm9wcGhvZXJzdGlkc3B1bmt0IjpudWxsLCJraWxkZSI6IkRvbGx5IiwiYWFyc2FrIjpudWxsLCJzZWt2ZW5zIjpudWxsfSwibWV0YWRhdGEiOnsib3BwbHlzbmluZ3NJZCI6IjQ0ZmJmN2E2LTY4ODUtNDhhZC1hMzAzLWU5ZDkwZmE0NTY3ZiIsIm1hc3RlciI6IkZSRUciLCJlbmRyaW5nZXIiOlt7InR5cGUiOiJPUFBSRVRUIiwicmVnaXN0cmVydCI6IjIwMjItMDEtMTRUMTU6NDE6MzYuMjM3IiwicmVnaXN0cmVydEF2IjoiRm9sa2VyZWdpc3RlcmV0Iiwic3lzdGVta2lsZGUiOiJGUkVHIiwia2lsZGUiOiJEb2xseSJ9XSwiaGlzdG9yaXNrIjpmYWxzZX19XSwib3BwaG9sZHNhZHJlc3NlIjpbXSwic2lra2VyaGV0c3RpbHRhayI6W10sInNpdmlsc3RhbmQiOlt7InR5cGUiOiJVR0lGVCIsImd5bGRpZ0ZyYU9nTWVkIjpudWxsLCJyZWxhdGVydFZlZFNpdmlsc3RhbmQiOm51bGwsImJla3JlZnRlbHNlc2RhdG8iOm51bGwsImZvbGtlcmVnaXN0ZXJtZXRhZGF0YSI6eyJham91cmhvbGRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozOC42ODQiLCJneWxkaWdoZXRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozOC42ODQiLCJvcHBob2Vyc3RpZHNwdW5rdCI6bnVsbCwia2lsZGUiOiJEb2xseSIsImFhcnNhayI6bnVsbCwic2VrdmVucyI6bnVsbH0sIm1ldGFkYXRhIjp7Im9wcGx5c25pbmdzSWQiOiIyZDdmNjYyMy0zYmE0LTQ0ZDMtOGUwNC1lZmNlZDhjZDc3ZTMiLCJtYXN0ZXIiOiJGUkVHIiwiZW5kcmluZ2VyIjpbeyJ0eXBlIjoiT1BQUkVUVCIsInJlZ2lzdHJlcnQiOiIyMDIyLTAxLTE0VDE1OjQxOjM4LjY4NCIsInJlZ2lzdHJlcnRBdiI6IkZvbGtlcmVnaXN0ZXJldCIsInN5c3RlbWtpbGRlIjoiRlJFRyIsImtpbGRlIjoiRG9sbHkifV0sImhpc3RvcmlzayI6ZmFsc2V9fV0sInN0YXRzYm9yZ2Vyc2thcCI6W3sibGFuZCI6Ik5PUiIsImJla3JlZnRlbHNlc2RhdG8iOm51bGwsImd5bGRpZ0ZyYU9nTWVkIjoiMTk3Mi0wNy0wMSIsImd5bGRpZ1RpbE9nTWVkIjpudWxsLCJmb2xrZXJlZ2lzdGVybWV0YWRhdGEiOnsiYWpvdXJob2xkc3RpZHNwdW5rdCI6IjIwMjItMDEtMTRUMTU6NDE6MzguMzI3IiwiZ3lsZGlnaGV0c3RpZHNwdW5rdCI6IjE5NzItMDctMDFUMDA6MDA6MDAiLCJvcHBob2Vyc3RpZHNwdW5rdCI6bnVsbCwia2lsZGUiOiJEb2xseSIsImFhcnNhayI6bnVsbCwic2VrdmVucyI6bnVsbH0sIm1ldGFkYXRhIjp7Im9wcGx5c25pbmdzSWQiOiI2NzJiMjkzYS1iMThlLTRjZDEtOWExNi1kNGEwM2ViODU4MWQiLCJtYXN0ZXIiOiJGUkVHIiwiZW5kcmluZ2VyIjpbeyJ0eXBlIjoiT1BQUkVUVCIsInJlZ2lzdHJlcnQiOiIyMDIyLTAxLTE0VDE1OjQxOjM4LjMyNiIsInJlZ2lzdHJlcnRBdiI6IkZvbGtlcmVnaXN0ZXJldCIsInN5c3RlbWtpbGRlIjoiRlJFRyIsImtpbGRlIjoiRG9sbHkifV0sImhpc3RvcmlzayI6ZmFsc2V9fV0sInRpbHJldHRlbGFndEtvbW11bmlrYXNqb24iOltdLCJ0ZWxlZm9ubnVtbWVyIjpbXSwiaW5uZmx5dHRpbmdUaWxOb3JnZSI6W3siZnJhZmx5dHRpbmdzbGFuZCI6IkJFTCIsImZyYWZseXR0aW5nc3N0ZWRJVXRsYW5kZXQiOm51bGwsImZvbGtlcmVnaXN0ZXJtZXRhZGF0YSI6eyJham91cmhvbGRzdGlkc3B1bmt0IjoiMjAyMi0wMS0xNFQxNTo0MTozNy41MzIiLCJneWxkaWdoZXRzdGlkc3B1bmt0IjoiMTk3Mi0wNy0wMVQwMDowMDowMCIsIm9wcGhvZXJzdGlkc3B1bmt0IjpudWxsLCJraWxkZSI6IkRvbGx5IiwiYWFyc2FrIjpudWxsLCJzZWt2ZW5zIjpudWxsfSwibWV0YWRhdGEiOnsib3BwbHlzbmluZ3NJZCI6IjUzNDVhZjc2LWFjMDMtNDQ2MS05ZDVjLWYxN2M0MmVhOGEzMiIsIm1hc3RlciI6IkZSRUciLCJlbmRyaW5nZXIiOlt7InR5cGUiOiJPUFBSRVRUIiwicmVnaXN0cmVydCI6IjIwMjItMDEtMTRUMTU6NDE6MzcuNTMyIiwicmVnaXN0cmVydEF2IjoiRm9sa2VyZWdpc3RlcmV0Iiwic3lzdGVta2lsZGUiOiJGUkVHIiwia2lsZGUiOiJEb2xseSJ9XSwiaGlzdG9yaXNrIjpmYWxzZX19XSwidXRmbHl0dGluZ0ZyYU5vcmdlIjpbXSwidmVyZ2VtYWFsRWxsZXJGcmVtdGlkc2Z1bGxtYWt0IjpbXX0sImhlbnRJZGVudGVyIjp7ImlkZW50ZXIiOlt7ImlkZW50IjoiMDEwNzcyMTEwMjciLCJoaXN0b3Jpc2siOmZhbHNlLCJncnVwcGUiOiJGT0xLRVJFR0lTVEVSSURFTlQiLCJtZXRhZGF0YSI6bnVsbCwiZm9sa2VyZWdpc3Rlcm1ldGFkYXRhIjpudWxsfSx7ImlkZW50IjoiMjU5NDgxOTgwNjU2MyIsImhpc3RvcmlzayI6ZmFsc2UsImdydXBwZSI6IkFLVE9SSUQiLCJtZXRhZGF0YSI6bnVsbCwiZm9sa2VyZWdpc3Rlcm1ldGFkYXRhIjpudWxsfV19fQo=',
                CRM_Status__c = KafkaMessageService.STATUS_PENDING
            )
        );
        Test.startTest();
        KafkaPdlPersondokumentHandler handler = new KafkaPdlPersondokumentHandler();
        handler.processMessages(kafkaMessages);
        List<Person__c> pl = [SELECT Id from Person__c where INT_ActorId__c = '2594819806563'];
        Assert.areEqual(1, pl.size(), 'Expected one person inserted.');
        Test.stopTest();
    }
}
