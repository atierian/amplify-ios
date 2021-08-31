//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine
import Foundation

@available(iOS 13.0, *)
final class InitialSyncOperation: AsynchronousOperation {
    typealias SyncQueryResult = PaginatedList<AnyModel>

    private weak var api: APICategoryGraphQLBehavior?
    private weak var reconciliationQueue: IncomingEventReconciliationQueue?
    private weak var storageAdapter: StorageEngineAdapter?
    private let dataStoreConfiguration: DataStoreConfiguration
    private let authModeStrategy: AuthModeStrategy

    private let modelSchema: ModelSchema

    private var recordsReceived: UInt

    private var syncMaxRecords: UInt {
        return dataStoreConfiguration.syncMaxRecords
    }
    private var syncPageSize: UInt {
        return dataStoreConfiguration.syncPageSize
    }

    private let initialSyncOperationTopic: PassthroughSubject<InitialSyncOperationEvent, DataStoreError>
    var publisher: AnyPublisher<InitialSyncOperationEvent, DataStoreError> {
        return initialSyncOperationTopic.eraseToAnyPublisher()
    }

    init(modelSchema: ModelSchema,
         api: APICategoryGraphQLBehavior?,
         reconciliationQueue: IncomingEventReconciliationQueue?,
         storageAdapter: StorageEngineAdapter?,
         dataStoreConfiguration: DataStoreConfiguration,
         authModeStrategy: AuthModeStrategy) {
        self.modelSchema = modelSchema
        self.api = api
        self.reconciliationQueue = reconciliationQueue
        self.storageAdapter = storageAdapter
        self.dataStoreConfiguration = dataStoreConfiguration
        self.authModeStrategy = authModeStrategy

        self.recordsReceived = 0
        self.initialSyncOperationTopic = PassthroughSubject<InitialSyncOperationEvent, DataStoreError>()
    }

    override func main() {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        log.info("Beginning sync for \(modelSchema.name)")
        let modelSyncMetadata = getModelSyncMetadata()
        saveModelSyncMetadata(lastSync: modelSyncMetadata?.lastSync,
                              initialSyncTime: Int(Date().timeIntervalSince1970),
                              modelSyncedTime: modelSyncMetadata?.modelSyncedTime) {
            let lastSyncTime = self.getLastSyncTime(modelSyncMetadata: modelSyncMetadata)
            let syncType: SyncType = lastSyncTime == nil ? .fullSync : .deltaSync
            self.initialSyncOperationTopic.send(.started(modelName: self.modelSchema.name, syncType: syncType))
            self.query(lastSyncTime: lastSyncTime)
        }
    }

    private func getLastSyncTime(modelSyncMetadata: ModelSyncMetadata?) -> Int? {
        guard let lastSync = modelSyncMetadata?.lastSync else {
            return nil
        }

        //TODO: Update to use TimeInterval.milliseconds when it is pushed to main branch
        // https://github.com/aws-amplify/amplify-ios/issues/398
        let lastSyncDate = Date(timeIntervalSince1970: TimeInterval(lastSync) / 1_000)
        let secondsSinceLastSync = (lastSyncDate.timeIntervalSinceNow * -1)
        if secondsSinceLastSync < 0 {
            log.info("lastSyncTime was in the future, assuming base query")
            return nil
        }

        let shouldDoDeltaQuery = secondsSinceLastSync < dataStoreConfiguration.syncInterval
        return shouldDoDeltaQuery ? lastSync : nil
    }

    private func query(lastSyncTime: Int?, nextToken: String? = nil) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let api = api else {
            finish(result: .failure(DataStoreError.nilAPIHandle()))
            return
        }
        let minSyncPageSize = Int(min(syncMaxRecords - recordsReceived, syncPageSize))
        let limit = minSyncPageSize < 0 ? Int(syncPageSize) : minSyncPageSize
        let syncExpression = dataStoreConfiguration.syncExpressions.first {
            $0.modelSchema.name == modelSchema.name
        }
        let queryPredicate = syncExpression?.modelPredicate()

        let completionListener: GraphQLOperation<SyncQueryResult>.ResultListener = { result in
            switch result {
            case .failure(let apiError):
                if self.isAuthSignedOutError(apiError: apiError) {
                    self.dataStoreConfiguration.errorHandler(DataStoreError.api(apiError))
                }
                // TODO: Retry query on error
                self.finish(result: .failure(DataStoreError.api(apiError)))
            case .success(let graphQLResult):
                self.handleQueryResults(lastSyncTime: lastSyncTime, graphQLResult: graphQLResult)
            }
        }

        var authTypes = authModeStrategy.authTypesFor(schema: modelSchema,
                                                                             operation: .read)

        RetryableGraphQLOperation(requestFactory: {
            GraphQLRequest<SyncQueryResult>.syncQuery(modelSchema: self.modelSchema,
                                                      where: queryPredicate,
                                                      limit: limit,
                                                      nextToken: nextToken,
                                                      lastSync: lastSyncTime,
                                                      authType: authTypes.next())
        },
                                  maxRetries: authTypes.count,
                                  resultListener: completionListener) { nextRequest, wrappedCompletionListener in
            api.query(request: nextRequest, listener: wrappedCompletionListener)
        }.main()
    }

    /// Disposes of the query results: Stops if error, reconciles results if success, and kick off a new query if there
    /// is a next token
    private func handleQueryResults(lastSyncTime: Int?,
                                    graphQLResult: Result<SyncQueryResult, GraphQLResponseError<SyncQueryResult>>) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let reconciliationQueue = reconciliationQueue else {
            finish(result: .failure(DataStoreError.nilReconciliationQueue()))
            return
        }

        let syncQueryResult: SyncQueryResult
        switch graphQLResult {
        case .failure(let graphQLResponseError):
            finish(result: .failure(DataStoreError.api(graphQLResponseError)))
            return
        case .success(let queryResult):
            syncQueryResult = queryResult
        }

        let items = syncQueryResult.items
        recordsReceived += UInt(items.count)

        reconciliationQueue.offer(items, modelSchema: modelSchema)
        for item in items {
            initialSyncOperationTopic.send(.enqueued(item))
        }

        if let nextToken = syncQueryResult.nextToken, recordsReceived < syncMaxRecords {
            DispatchQueue.global().async {
                self.query(lastSyncTime: lastSyncTime, nextToken: nextToken)
            }
        } else {
            initialSyncOperationTopic.send(.finished(modelName: modelSchema.name))
            let modelSyncMetadata = getModelSyncMetadata()
            saveModelSyncMetadata(lastSync: syncQueryResult.startedAt,
                                  initialSyncTime: modelSyncMetadata?.initialSyncTime,
                                  modelSyncedTime: modelSyncMetadata?.modelSyncedTime) {
                self.finish(result: .successfulVoid)
            }
        }
    }

    // MARK: - ModelSyncMetadata

    private func getModelSyncMetadata() -> ModelSyncMetadata? {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return nil
        }

        guard let storageAdapter = storageAdapter else {
            log.error(error: DataStoreError.nilStorageAdapter())
            return nil
        }

        do {
            let modelSyncMetadata = try storageAdapter.queryModelSyncMetadata(for: modelSchema)
            return modelSyncMetadata
        } catch {
            log.error(error: error)
            return nil
        }
    }

    private func saveModelSyncMetadata(lastSync: Int?,
                                       initialSyncTime: Int?,
                                       modelSyncedTime: Int?,
                                       onComplete: @escaping () -> Void) {
        guard !isCancelled else {
            finish(result: .successfulVoid)
            return
        }

        guard let storageAdapter = storageAdapter else {
            finish(result: .failure(DataStoreError.nilStorageAdapter()))
            return
        }
        let syncMetadata = ModelSyncMetadata(id: modelSchema.name,
                                             lastSync: lastSync,
                                             initialSyncTime: initialSyncTime,
                                             modelSyncedTime: modelSyncedTime)
        storageAdapter.save(syncMetadata, condition: nil) { result in
            switch result {
            case .failure(let dataStoreError):
                self.finish(result: .failure(dataStoreError))
            case .success:
                onComplete()
            }
        }
    }

    private func isAuthSignedOutError(apiError: APIError) -> Bool {
        if case let .operationError(_, _, underlyingError) = apiError,
            let authError = underlyingError as? AuthError,
            case .signedOut = authError {
            return true
        }

        return false
    }

    private func finish(result: AWSInitialSyncOrchestrator.SyncOperationResult) {
        switch result {
        case .failure(let error):
            initialSyncOperationTopic.send(completion: .failure(error))
        case .success:
            initialSyncOperationTopic.send(completion: .finished)
        }
        super.finish()
    }

}

@available(iOS 13.0, *)
extension InitialSyncOperation: DefaultLogger { }
