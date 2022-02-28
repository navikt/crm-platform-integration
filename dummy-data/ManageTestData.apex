//Start executing AsyncRequests => Trigger handle the KafkaMessages
Database.executeBatch(new AsyncRequestBatchable(),50);