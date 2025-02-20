# crm-platform-integration

This package contains sObjects and related Apex logic in order to receive JSON
payloads.

## Kafka messages

This package contains the `KafkaMessage__c` sObject and related Apex logic in
order to receive JSON payloads representing changes from the Kafka CDC pipeline.
A trigger on the `KafkaMessage__c` sObject will enqueue asynchronous processing
requests through the asynchronous processing framework that is part of the
**crm-platform-base** package.

### Custom Metadata Bindings

The framework depends on two custom metadata objects in order to dynamically
instruct the application how to handle the message payload.

#### `AsyncRequestHandlerBinding__mdt`

Binding between the asynchronous processing request (`AsyncRequest__c`) type
created by this package and the `KafkaMessageAsyncJob` class in order to
instruct the asynchronous processing framework to call the
`KafkaMessageAsyncJob` class in order to handle requests originating from this
package.

#### `KafkaMessageHandlerBinding__mdt`

Binding between the `KafkaMessage__c.Topic__c` field and an Apex handler class
for a given Topic in order to instruct the application on how to handle a
message payload related to a specific Kafka topic.

### Execution Flow

1. An external application inserts a record or batch or records into the
   `KafkaMessage__c` sObject
2. A trigger on the `KafkaMessage__c` object insert one record into the
   `AsyncRequest__c` object for each batch of up to 200 `KafkaMessage__c`
   records created in a single transaction, representing a request for
   asynchronous processing of the new messages.
3. When the asynchronous processing framework processes the request, the custom
   metadata binding `AsyncRequestHandlerBinding__mdt` instructs the application
   to handle the request using the `KafkaMessageAsyncJob` Apex class. - If no
   `AsyncRequestHandlerBinding__mdt` record is found corresponding to the "Kafka
   Message" `AsyncRequestType__c` value, the `AsyncRequest__c` record is updated
   with an error.
4. The `KafkaMessageAsyncJob` queries for the relevant `KafkaMessage__c` records
   by the Ids stored in the async processing request and queries the
   `KafkaMessageHandlerBinding__mdt` custom metadata object for registered
   bindings between `KafkaMessage__c.Topic__c` values and corresponding Apex
   classes to handle payloads corresponding to `Topic__c` values. - If no
   `KafkaMessageHandlerBinding__mdt` record is found corresponding to the
   `Topic__c` value, the relevant `KafkaMessage__c` record is updated with an
   error. The message can then be retried after the error has been addressed.
   i. If `KafkaMessageHandlerBinding__mdt.SandboxOverrideTopic__c` exists, it is
      its value which will correspond with `KafkaMessage__c.Topic__c` in scratch
      orgs and sandboxes. `KafkaMessageHandlerBinding__mdt.Topic__c` will in this
      case remain unused.
5. The Apex class registered by the `KafkaMessageHandlerBinding__mdt` binding
   executes the business logic corresponding to the `Topic__c` value. If an
   exception occurs, the relevant `KafkaMessage__c` record is updated with an
   error. The message can then be retried after the error has been addressed.

### Synchronous kafka message handling

To process incoming kafka messages in a synchronous context the following
pattern should be followed:
1. Definition of a separate platform event with the exact data model as i.e.
   defined
   [here](https://github.com/navikt/crm-platform-oppgave/tree/master/force-app/main/default/objects/Kafka_Oppgave_Event__e).
2. Create a trigger and separate trigger handler to process the incoming events.
3. The processing itself should be implemented using the `IKafkaMessageConsumer`
   interface such that error handling can be performed easily storing failed
   events as `KafkaMessage__c` records. An example of this can be viewed
   [here](https://github.com/navikt/crm-platform-oppgave/blob/master/force-app/main/default/classes/kafka/CRM_KafkaOppgaveEventHandler.cls)
   where *doEventTransform* performs the transformation from the custom event to
   the `KafkaMessage__c` model and the failed events are stored as
   `KafkaMessage__c` records in an error status.

## Felles kodeverk

`KodeverkCalloutService` contains methods for fetching codes from Felles
kodeverk for ad hoc use or for storing them as `Common_Code__c` records. For
details, see [kodeverk](/runbooks/kodeverk/index.md).
