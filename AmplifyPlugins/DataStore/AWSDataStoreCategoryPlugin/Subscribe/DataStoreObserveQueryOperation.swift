//
// Copyright Amazon.com Inc. or its affiliates.
// All Rights Reserved.
//
// SPDX-License-Identifier: Apache-2.0
//

import Amplify
import AWSPluginsCore
import Combine

///
protocol DataStoreObseverQueryOperation {
    func resetState()
    func startObserveQuery()
}

///
@available(iOS 13.0, *)
public class ObserveQueryPublisher<M: Model>: Publisher {
    public typealias Output = DataStoreQuerySnapshot<M>
    public typealias Failure = DataStoreError

    weak var operation: AWSDataStoreObseverQueryOperation<M>?

    func configure(operation: AWSDataStoreObseverQueryOperation<M>) {
        self.operation = operation
    }

    public func receive<S>(subscriber: S)
    where S: Subscriber, ObserveQueryPublisher.Failure == S.Failure, ObserveQueryPublisher.Output == S.Input {
        let subscription = ObserveQuerySubscription<S, M>(operation: operation)
        subscription.target = subscriber
        subscriber.receive(subscription: subscription)
    }
}

@available(iOS 13.0, *)
class ObserveQuerySubscription<Target: Subscriber, M: Model>: Subscription
where Target.Input == DataStoreQuerySnapshot<M>, Target.Failure == DataStoreError {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.ObserveQuerySubscription.serialQueue",
                                            target: DispatchQueue.global())
    var target: Target?
    var sink: AnyCancellable?
    weak var operation: AWSDataStoreObseverQueryOperation<M>?

    init(operation: AWSDataStoreObseverQueryOperation<M>?) {
        self.operation = operation
        self.sink = operation?
            .passthroughPublisher
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onReceiveValue(snapshot:))
    }

    func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        serialQueue.async {
            self.target?.receive(completion: completed)
            self.target = nil
            self.sink = nil
            self.operation = nil
        }
    }

    func onReceiveValue(snapshot: DataStoreQuerySnapshot<M>) {
        _ = target?.receive(snapshot)
    }

    /// This subscription doesn't respond to demand, since it'll
    /// simply emit events according to its underlying operation
    /// but we still have to implement this method
    /// in order to conform to the Subscription protocol:
    func request(_ demand: Subscribers.Demand) {}

    /// When the subscription is cancelled, cancel the underlying operation
    func cancel() {
        serialQueue.async {
            self.operation?.cancel()
        }
    }

    /// When app code recreates the subscription, the previous subscription
    /// will be deallocated. At this time, cancel the underlying operation
    deinit {
        self.operation?.cancel()
        self.target = nil
        self.sink = nil
        self.operation = nil
    }
}

/// Publishes a stream of `DataStoreQuerySnapshot` events.
///
/// Flow:
///
@available(iOS 13.0, *)
public class AWSDataStoreObseverQueryOperation<M: Model>: AsynchronousOperation, DataStoreObseverQueryOperation {

    private let serialQueue = DispatchQueue(label: "com.amazonaws.AWSDataStoreObseverQueryOperation.serialQueue",
                                            target: DispatchQueue.global())
    private let itemsChangedPeriodicPublishTimeInSeconds: DispatchQueue.SchedulerTimeType.Stride = 2
    private let itemsChangedMaxSize = 1_000

    let modelType: M.Type
    let modelSchema: ModelSchema
    let predicate: QueryPredicate?
    let sortInput: QuerySortInput?

    let storageEngine: StorageEngineBehavior
    var dataStorePublisher: ModelSubcriptionBehavior

    let observeQueryStarted: AtomicValue<Bool>
    let isSynced: AtomicValue<Bool>
    let modelsSyncedEventCount: AtomicValue<Int>
    let modelsSyncedEventReceived: AtomicValue<Bool>
    var unfilteredItemChangedCount: AtomicValue<Int>
    var currentItemsMap: [Model.Identifier: M] = [:]
    var itemsChangedSink: AnyCancellable?
    var modelSyncedEventSink: AnyCancellable?

    /// Internal publisher for `ObserveQueryPublisher` to pass events back to subscribers
    let passthroughPublisher: PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>

    /// External subscribers subscribe to this publisher
    private let observeQueryPublisher: ObserveQueryPublisher<M>
    public var publisher: AnyPublisher<DataStoreQuerySnapshot<M>, DataStoreError> {
        return observeQueryPublisher.eraseToAnyPublisher()
    }

    init(modelType: M.Type,
         modelSchema: ModelSchema,
         predicate: QueryPredicate?,
         sortInput: QuerySortInput?,
         storageEngine: StorageEngineBehavior,
         dataStorePublisher: ModelSubcriptionBehavior) {
        self.modelType = modelType
        self.modelSchema = modelSchema
        self.predicate = predicate
        self.sortInput = sortInput
        self.storageEngine = storageEngine
        self.dataStorePublisher = dataStorePublisher

        self.observeQueryStarted = AtomicValue(initialValue: false)
        self.isSynced = AtomicValue(initialValue: false)
        self.modelsSyncedEventCount = AtomicValue(initialValue: 0)
        self.modelsSyncedEventReceived = AtomicValue(initialValue: false)
        self.unfilteredItemChangedCount = AtomicValue(initialValue: 0)
        self.passthroughPublisher = PassthroughSubject<DataStoreQuerySnapshot<M>, DataStoreError>()
        self.observeQueryPublisher = ObserveQueryPublisher()
        super.init()
        observeQueryPublisher.configure(operation: self)
    }

    override public func main() {
        startObserveQuery()
    }

    override public func cancel() {
        if let itemsChangedSink = itemsChangedSink {
            itemsChangedSink.cancel()
        }
        passthroughPublisher.send(completion: .finished)
        super.cancel()
        finish()
    }

    func resetState() {
        serialQueue.async {
            self.log.verbose("resetState")
            self.isSynced.set(false)
            self.currentItemsMap.removeAll()
            self.unfilteredItemChangedCount.set(0)
            self.modelsSyncedEventCount.set(0)
            self.modelsSyncedEventReceived.set(false)
            self.itemsChangedSink = nil
            self.modelSyncedEventSink = nil
            self.observeQueryStarted.set(false)
        }
    }

    func startObserveQuery() {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            if self.observeQueryStarted.get() {
                return
            }
            self.observeQueryStarted.set(true)
            self.log.verbose("startObserveQuery")
            self.modelSyncedEventSink = Amplify.Hub.publisher(for: .dataStore)
                .filter { $0.eventName == HubPayload.EventName.DataStore.modelSynced }
                .sink(receiveValue: self.onModelSyncedEvent(hubPayload:))
            self.subscribeToItemChanges()
            self.initialIsSyncState {
                self.initialQuery()
            }
        }
    }

    // MARK: - isSynced State

    func initialIsSyncState(complete: () -> Void) {
        getModelSyncMetadata { modelSyncMetadata in
            guard let metadata = modelSyncMetadata else {
                complete()
                return
            }

            if self.log.logLevel == .verbose {
                self.log.verbose("initialSync: \(String(describing: metadata.initialSyncTime))) modelSynced: \(String(describing: metadata.modelSyncedTime))")
            }
            if let initialSyncTime = metadata.initialSyncTime,
               let modelSyncTime = metadata.modelSyncedTime,
               initialSyncTime <= modelSyncTime {
                isSynced.set(true)
            }
            complete()
        }
    }

    private func getModelSyncMetadata(complete: (ModelSyncMetadata?) -> Void) {
        storageEngine.query(ModelSyncMetadata.self,
                            predicate: ModelSyncMetadata.keys.id == modelSchema.name,
                            sort: nil,
                            paginationInput: nil) { result in
            switch result {
            case .success(let modelSyncMetadatas):
                complete(modelSyncMetadatas.first)
            case .failure(let error):
                log.error(error: error)
                complete(nil)
            }
        }
    }

    // MARK: - ModelSynced event

    func onModelSyncedEvent(hubPayload: HubPayload) {
        if isCancelled || isFinished {
            finish()
            return
        }
        guard let modelSynced = hubPayload.data as? ModelSyncedEvent else {
            log.error("Failed to retrieve modelSynced payload")
            return
        }
        serialQueue.async {
            self.modelsSyncedEventReceived.set(true)
            let totalCount = modelSynced.added + modelSynced.updated + modelSynced.deleted
            self.modelsSyncedEventCount.set(totalCount)
            self.log.verbose("Received modelsSynced event with count \(totalCount)")
        }
    }

    // MARK: - Query

    func initialQuery() {
        if isCancelled || isFinished {
            finish()
            return
        }

        storageEngine.query(
            modelType,
            modelSchema: modelSchema,
            predicate: predicate,
            sort: sortInput?.asSortDescriptors(),
            paginationInput: nil,
            completion: { queryResult in
                if isCancelled || isFinished {
                    finish()
                    return
                }

                switch queryResult {
                case .success(let queriedModels):
                    storeCurrentItems(queriedModels: queriedModels)
                    generateQuerySnapshot()
                case .failure(let error):
                    self.passthroughPublisher.send(completion: .failure(error))
                    self.finish()
                    return
                }
            })
    }

    func storeCurrentItems(queriedModels: [M]) {
        for model in queriedModels {
            currentItemsMap.updateValue(model, forKey: model.id)
        }
    }

    // MARK: Observe

    func subscribeToItemChanges() {
        itemsChangedSink = dataStorePublisher.publisher
            .filter(onItemChangedFilter(mutationEvent:))
            .collect(.byTimeOrCount(serialQueue, itemsChangedPeriodicPublishTimeInSeconds, itemsChangedMaxSize))
            .sink(receiveCompletion: onReceiveCompletion(completed:),
                  receiveValue: onItemChanges(mutationEvents:))
    }

    func onItemChangedFilter(mutationEvent: MutationEvent) -> Bool {
        guard mutationEvent.modelName == modelSchema.name else {
            return false
        }
        if !isSynced.get() {
            _ = unfilteredItemChangedCount.increment(by: 1)
        }

        guard let predicate = self.predicate else {
            return true
        }

        do {
            let model = try mutationEvent.decodeModel(as: modelType)
            return predicate.evaluate(target: model)
        } catch {
            log.error(error: error)
            return false
        }
    }

    func onItemChanges(mutationEvents: [MutationEvent]) {
        serialQueue.async {
            if self.isCancelled || self.isFinished {
                self.finish()
                return
            }
            guard !mutationEvents.isEmpty else {
                return
            }

            if !self.isSynced.get() && self.modelsSyncedEventReceived.get() {
                self.log.verbose("unfilteredItemsCount: \(self.unfilteredItemChangedCount.get()) modelsSynced: \(self.modelsSyncedEventCount.get())")
                if self.unfilteredItemChangedCount.get() >= self.modelsSyncedEventCount.get() {
                    self.isSynced.set(true)
                }
            }

            self.generateQuerySnapshot(itemsChanged: mutationEvents)
        }
    }

    func generateQuerySnapshot(itemsChanged: [MutationEvent] = []) {
        updateCurrentItems(with: itemsChanged)
        var currentItems = Array(currentItemsMap.values.map { $0 }) as [M]
        if let sort = sortInput {
            sort.inputs.forEach { currentItems.sortModels(by: $0, modelSchema: modelSchema) }
        }
        publish(items: currentItems, isSynced: isSynced.get(), itemsChanged: itemsChanged)
    }

    func updateCurrentItems(with itemsChanged: [MutationEvent]) {
        for item in itemsChanged {
            do {
                let model = try item.decodeModel(as: modelType)
                if item.mutationType == MutationEvent.MutationType.delete.rawValue {
                    currentItemsMap.removeValue(forKey: model.id)
                } else {
                    currentItemsMap.updateValue(model, forKey: model.id)
                }
            } catch {
                log.error(error: error)
                continue
            }
        }
    }

    func onReceiveCompletion(completed: Subscribers.Completion<DataStoreError>) {
        if isCancelled || isFinished {
            finish()
            return
        }
        switch completed {
        case .finished:
            passthroughPublisher.send(completion: .finished)
        case .failure(let error):
            passthroughPublisher.send(completion: .failure(error))
        }
        finish()
    }

    // MARK: - Helpers

    func publish(items: [M], isSynced: Bool, itemsChanged: [MutationEvent]) {
        let querySnapshot = DataStoreQuerySnapshot(items: items,
                                                   isSynced: isSynced,
                                                   itemsChanged: dedup(mutationEvents: itemsChanged))
        log.verbose("items: \(querySnapshot.items.count) changed: \(querySnapshot.itemsChanged.count) isSynced: \(querySnapshot.isSynced)")
        passthroughPublisher.send(querySnapshot)
    }

    /// Remove duplicate MutationEvents based on the model identifier, keeping the latest one.
    func dedup(mutationEvents: [MutationEvent]) -> [MutationEvent] {
        var itemsChangedMap: [Model.Identifier: MutationEvent] = [:]
        for mutationEvent in mutationEvents {
            itemsChangedMap.updateValue(mutationEvent, forKey: mutationEvent.modelId)
        }
        return Array(itemsChangedMap.values.map { $0 })
    }
}

@available(iOS 13.0, *)
extension AWSDataStoreObseverQueryOperation: DefaultLogger { }
