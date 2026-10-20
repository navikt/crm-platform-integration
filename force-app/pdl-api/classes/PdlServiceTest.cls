@isTest
private class PdlServiceTest {
    private class PdlRequestMock implements HttpCalloutMock {
        public Integer calls = 0;
        private String expectedBody;

        PdlRequestMock(String expectedBody) {
            this.expectedBody = expectedBody;
        }

        public HttpResponse respond(HttpRequest request) {
            calls++;
            Assert.areEqual('B999', request.getHeader('behandlingsnummer'));
            Assert.areEqual('GEN', request.getHeader('Tema'));
            Assert.areEqual('application/json', request.getHeader('Content-Type'));
            Assert.areEqual('POST', request.getMethod());
            if (expectedBody != null) {
                Assert.areEqual(expectedBody, request.getBody());
            }
            return new ApiMock().initMock('POST_PDL_API', 200, 'OK').respond();
        }
    }

    @isTest
    private static void PdlApiTest() {
        String query = '{"query":"query { hentPerson { navn { fornavn } } }"}';
        PdlRequestMock mock = new PdlRequestMock(query);
        Test.setMock(HttpCalloutMock.class, mock);
        Assert.areEqual(200, PdlService.queryData('B999', query).getStatusCode());
        Assert.areEqual(1, mock.calls);
    }

    @isTest
    private static void rejectsMissingBehandlingsnummer() {
        for (String behandlingsnummer : new List<String>{ null, '', ' ' }) {
            try {
                PdlService.queryData(behandlingsnummer, '{}');
                Assert.isTrue(false, 'Expected missing behandlingsnummer to be rejected.');
            } catch (IllegalArgumentException e) {
                Assert.areEqual('behandlingsnummer is required for PDL queries.', e.getMessage());
            }
        }
        Assert.areEqual(0, Limits.getCallouts());
    }

    @isTest
    private static void helperConstructorsPropagateBehandlingsnummer() {
        List<PDL_API_QueryHelper> queries = new List<PDL_API_QueryHelper>{
            new PDL_API_QueryHelper('B999', '12106519356'),
            new PDL_API_QueryHelper('B999', '12106519356', true, false),
            new PDL_API_QueryHelper('B999', '12106519356', true, true, true)
        };
        for (PDL_API_QueryHelper query : queries) {
            query.selectAll();
            PdlRequestMock mock = new PdlRequestMock(query.build());
            Test.setMock(HttpCalloutMock.class, mock);
            Assert.isNotNull(query.execute().data);
            Assert.areEqual(1, mock.calls);
        }
    }

    @isTest
    private static void wrappersPropagateBehandlingsnummer() {
        PdlRequestMock mock = new PdlRequestMock(null);
        Test.setMock(HttpCalloutMock.class, mock);
        PDL_API_Query.getRelationsByRole('B999', '12106519356', PDL_ForelderBarnRelasjonRolle.BARN);
        PDL_API_Query.getChildData('B999', '12106519356');
        PDL_API_Query.getChildren('B999', '12106519356');
        Assert.areEqual(
            4,
            mock.calls,
            'Relations, child data, parent relations and child lookup must all call PDL.'
        );
    }

    @isTest
    private static void mergePropagatesBehandlingsnummer() {
        PdlRequestMock mock = new PdlRequestMock(null);
        Test.setMock(HttpCalloutMock.class, mock);
        new CRM_PersonMerge().getIdentsFromPDL('B999', '12106519356');
        Assert.areEqual(1, mock.calls);
    }

    @isTest
    private static void batchRequiresBehandlingsnummer() {
        try {
            new CRM_PersonMergeBatch(null);
            Assert.isTrue(false, 'Expected missing behandlingsnummer to be rejected.');
        } catch (IllegalArgumentException e) {
            Assert.areEqual('behandlingsnummer is required for PDL queries.', e.getMessage());
        }
    }
}
