@isTest
private class PDL_API_HentPersonResponseTest {
    @isTest
    private static void fromHttpResponseTest(){
        /*
        String testJsonString = '{"data":{"hentPerson":{"adressebeskyttelse":[],"bostedsadresse":' +
                                '[{"angittFlyttedato":"1965-10-12","gyldigFraOgMed":"1965-10-12T00' +
                                ':00","gyldigTilOgMed":null,"coAdressenavn":null,"vegadresse":{"ma' +
                                'trikkelId":130534152,"husnummer":"1","husbokstav":null,"bruksenhe' +
                                'tsnummer":null,"adressenavn":"Plassavegen","kommunenummer":"1557",' +
                                '"bydelsnummer":null,"tilleggsnavn":null,"postnummer":"6636","koord' +
                                'inater":{"x":453529.0,"y":6974511.0,"z":0.0,"kvalitet":null}},"mat' +
                                'rikkeladresse":null,"utenlandskAdresse":null,"ukjentBosted":null,"' +
                                'folkeregistermetadata":{"ajourholdstidspunkt":"2021-09-02T10:17:35' +
                                '","gyldighetstidspunkt":"1965-10-12T00:00","opphoerstidspunkt":nul' +
                                'l,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":{"opply' +
                                'sningsId":"53a9f29d-0980-42a3-8e18-13ae0b01b3d7","master":"FREG","' +
                                'endringer":[{"type":"OPPRETT","registrert":"2021-09-02T10:17:35","' +
                                'registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Doll' +
                                'y"}],"historisk":false}}],"deltBosted":[],"doedfoedtBarn":[],"doed' +
                                'sfall":[],"falskIdentitet":null,"foedsel":[{"foedselsaar":1965,"fo' +
                                'edselsdato":"1965-10-12","foedeland":"NOR","foedested":"Fødested i' +
                                '/på Gjemnes","foedekommune":null,"folkeregistermetadata":{"ajourho' +
                                'ldstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09' +
                                '-02T10:17:35","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":nu' +
                                'll,"sekvens":null},"metadata":{"opplysningsId":"20e8b676-568e-4eee' +
                                '-b5ce-b57156f850f5","master":"FREG","endringer":[{"type":"OPPRETT"' +
                                ',"registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregistere' +
                                't","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"fo' +
                                'lkeregisteridentifikator":[{"identifikasjonsnummer":"12106519356",' +
                                '"status":"I_BRUK","type":"FNR","folkeregistermetadata":{"ajourhold' +
                                'stidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09-0' +
                                '2T10:17:35","opphoerstidspunkt":null,"kilde":"srvdolly","aarsak":n' +
                                'ull,"sekvens":null},"metadata":{"opplysningsId":"33be3e25-ccd5-4f9' +
                                '7-8f21-bbac3c444877","master":"FREG","endringer":[{"type":"OPPRETT"' +
                                ',"registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret' +
                                '","systemkilde":"FREG","kilde":"srvdolly"}],"historisk":false}}],"f' +
                                'olkeregisterpersonstatus":[{"status":"bosatt","forenkletStatus":"bo' +
                                'sattEtterFolkeregisterloven","folkeregistermetadata":{"ajourholdsti' +
                                'dspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"2021-09-02T10' +
                                ':17:35","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sek' +
                                'vens":null},"metadata":{"opplysningsId":"affd81b7-665c-4e82-88fb-a3' +
                                '6181b6cb65","master":"FREG","endringer":[{"type":"OPPRETT","registr' +
                                'ert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret","systemk' +
                                'ilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"forelderBarnRel' +
                                'asjon":[{"relatertPersonsIdent":"02091379875","relatertPersonsRolle"' +
                                ':"BARN","minRolleForPerson":"FAR","folkeregistermetadata":{"ajourhol' +
                                'dstidspunkt":"2021-09-02T10:17:36","gyldighetstidspunkt":"2021-09-02' +
                                'T10:17:36","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"s' +
                                'ekvens":null},"metadata":{"opplysningsId":"8c713184-ebe2-4dbe-8c6e-c' +
                                'ff4760273d6","master":"FREG","endringer":[{"type":"OPPRETT","registr' +
                                'ert":"2021-09-02T10:17:36","registrertAv":"Folkeregisteret","systemk' +
                                'ilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"foreldreansvar"' +
                                ':[{"ansvar":"far","ansvarlig":null,"ansvarssubjekt":"02091379875","a' +
                                'nsvarligUtenIdentifikator":null,"folkeregistermetadata":{"ajourholds' +
                                'tidspunkt":"2021-09-02T10:17:37","gyldighetstidspunkt":"2021-09-02T10' +
                                ':17:37","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":null,"sekv' +
                                'ens":null},"metadata":{"opplysningsId":"4b47f1b0-9316-49bf-820b-3c5b' +
                                '0080b895","master":"FREG","endringer":[{"type":"OPPRETT","registrert' +
                                '":"2021-09-02T10:17:37","registrertAv":"Folkeregisteret","systemkild' +
                                'e":"FREG","kilde":"Dolly"}],"historisk":false}}],"fullmakt":[],"iden' +
                                'titetsgrunnlag":[],"kjoenn":[{"kjoenn":"MANN","folkeregistermetadata' +
                                '":{"ajourholdstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt"' +
                                ':"2021-09-02T10:17:35","opphoerstidspunkt":null,"kilde":"Dolly","aar' +
                                'sak":null,"sekvens":null},"metadata":{"opplysningsId":"6be1bb25-2731' +
                                '-489b-ac15-49a93730ea8e","master":"FREG","endringer":[{"type":"OPPRE' +
                                'TT","registrert":"2021-09-02T10:17:35","registrertAv":"Folkeregister' +
                                'et","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"kon' +
                                'taktadresse":[],"kontaktinformasjonForDoedsbo":[],"navn":[{"fornavn"' +
                                ':"VAKKER","mellomnavn":"SLØVENDE","etternavn":"SNERK","forkortetNavn' +
                                '":"SNERK VAKKER SLØVENDE","originaltNavn":null,"gyldigFraOgMed":"202' +
                                '1-09-02","folkeregistermetadata":{"ajourholdstidspunkt":"2021-09-02T' +
                                '10:17:35","gyldighetstidspunkt":"2021-09-02T10:17:35","opphoerstidsp' +
                                'unkt":null,"kilde":"Dolly","aarsak":null,"sekvens":null},"metadata":' +
                                '{"opplysningsId":"c38343b4-2781-4bff-aa26-dc78bc46ee4d","master":"FR' +
                                'EG","endringer":[{"type":"OPPRETT","registrert":"2021-09-02T10:17:35' +
                                '","registrertAv":"Folkeregisteret","systemkilde":"FREG","kilde":"Dol' +
                                'ly"}],"historisk":false}}],"opphold":[],"oppholdsadresse":[],"sikker' +
                                'hetstiltak":[],"sivilstand":[{"type":"UGIFT","gyldigFraOgMed":null,"' +
                                'relatertVedSivilstand":null,"bekreftelsesdato":null,"folkeregisterme' +
                                'tadata":{"ajourholdstidspunkt":"2021-09-02T10:17:36","gyldighetstids' +
                                'punkt":"2021-09-02T10:17:36","opphoerstidspunkt":null,"kilde":"Dolly' +
                                '","aarsak":null,"sekvens":null},"metadata":{"opplysningsId":"6978919' +
                                '5-317e-42f7-8c28-c2cdda73901f","master":"FREG","endringer":[{"type":' +
                                '"OPPRETT","registrert":"2021-09-02T10:17:36","registrertAv":"Folkere' +
                                'gisteret","systemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}' +
                                '],"statsborgerskap":[{"land":"NOR","bekreftelsesdato":null,"gyldigFr' +
                                'aOgMed":"1965-10-12","gyldigTilOgMed":null,"folkeregistermetadata":{' +
                                '"ajourholdstidspunkt":"2021-09-02T10:17:35","gyldighetstidspunkt":"1' +
                                '965-10-12T00:00","opphoerstidspunkt":null,"kilde":"Dolly","aarsak":n' +
                                'ull,"sekvens":null},"metadata":{"opplysningsId":"dd35688f-febd-4626-' +
                                'a9b4-39ed732ad69a","master":"FREG","endringer":[{"type":"OPPRETT","r' +
                                'egistrert":"2021-09-02T10:17:35","registrertAv":"Folkeregisteret","s' +
                                'ystemkilde":"FREG","kilde":"Dolly"}],"historisk":false}}],"telefonnu' +
                                'mmer":[],"tilrettelagtKommunikasjon":[],"utenlandskIdentifikasjonsnu' +
                                'mmer":[],"vergemaalEllerFremtidsfullmakt":[]}' +
                                ',"hentIdenter":{"identer":[{"ident":"12106519356","historisk":false,"' +
                                'gruppe":"FOLKEREGISTERIDENT"},{"ident":"2762473496911","historisk":f' +
                                'alse,"gruppe":"AKTORID"}]}' +
                                '}}';
        HttpResponse httpr = new HttpResponse();
        httpr.setBody(testJsonString);
        httpr.setStatusCode(200);
        Test.startTest();
        PDL_API_Response r = PDL_API_Response.fromHttpResponse(httpr);
        Test.stopTest();
        */
        PDL_API_QueryHelper q = new PDL_API_QueryHelper('12106519356');
        q.selectAll(true);
        ApiMock.setTestMock('POST_PDL_API', 200, 'OK');
        Test.startTest();
        PDL_API_Response r = q.execute();
        Test.stopTest();
        System.assertNotEquals(null, r);
        System.assertEquals('VAKKER', r.data.hentPerson.navn[0].fornavn);
        System.assertEquals('SNERK', r.data.hentPerson.navn[0].etternavn);
    }
}
