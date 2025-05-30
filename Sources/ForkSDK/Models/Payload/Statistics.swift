//
//  Statistics.swift
//  HealthKitReporter
//
//  Created by Victor on 25.09.20.
//

import HealthKit

public struct Statistics: Identifiable, Sample {
    public struct Serialized: Codable {
        public let summary: Double?
        public let average: Double?
        public let recent: Double?
        public let min: Double?
        public let max: Double?
        public let unit: String

        public init(
            summary: Double?,
            average: Double?,
            recent: Double?,
            min: Double?,
            max: Double?,
            unit: String
        ) {
            self.summary = summary
            self.average = average
            self.recent = recent
            self.min = min
            self.max = max
            self.unit = unit
        }

        public func copyWith(
            summary: Double? = nil,
            average: Double? = nil,
            recent: Double? = nil,
            min: Double? = nil,
            max: Double? = nil,
            unit: String? = nil
        ) -> Serialized {
            return Serialized(
                summary: summary ?? self.summary,
                average: average ?? self.average,
                recent: recent ?? self.recent,
                min: min ?? self.min,
                max: max ?? self.max,
                unit: unit ?? self.unit
            )
        }
    }

    public let identifier: String
    public let startTimestamp: Double
    public let endTimestamp: Double
    public let serialized: Serialized
    public let sources: [Source]

    init(statistics: HKStatistics, unit: HKUnit) throws {
        self.identifier = statistics.quantityType.identifier
        self.startTimestamp = statistics.startDate.timeIntervalSince1970
        self.endTimestamp = statistics.endDate.timeIntervalSince1970
        self.sources = statistics.sources?.map { Source(source: $0) } ?? []
        if #available(iOS 12.0, *) {
            self.serialized = Serialized(
                summary: statistics.sumQuantity()?.doubleValue(for: unit),
                average: statistics.averageQuantity()?.doubleValue(for: unit),
                recent: statistics.mostRecentQuantity()?.doubleValue(for: unit),
                min: statistics.minimumQuantity()?.doubleValue(for: unit),
                max: statistics.maximumQuantity()?.doubleValue(for: unit),
                unit: unit.unitString
            )
        } else {
            self.serialized = Serialized(
                summary: statistics.sumQuantity()?.doubleValue(for: unit),
                average: statistics.averageQuantity()?.doubleValue(for: unit),
                recent: nil,
                min: statistics.minimumQuantity()?.doubleValue(for: unit),
                max: statistics.maximumQuantity()?.doubleValue(for: unit),
                unit: unit.unitString
            )
        }
    }
    init(statistics: HKStatistics) throws {
        self.identifier = statistics.quantityType.identifier
        self.startTimestamp = statistics.startDate.timeIntervalSince1970
        self.endTimestamp = statistics.endDate.timeIntervalSince1970
        self.sources = statistics.sources?.map { Source(source: $0) } ?? []
        self.serialized = try statistics.serialize()
    }
    
    private init(
        identifier: String,
        startTimestamp: Double,
        endTimestamp: Double,
        serialized: Serialized,
        sources: [Source]
    ) {
        self.identifier = identifier
        self.startTimestamp = startTimestamp
        self.endTimestamp = endTimestamp
        self.serialized = serialized
        self.sources = sources
    }
    
    public func copyWith(
        identifier: String? = nil,
        startTimestamp: Double? = nil,
        endTimestamp: Double? = nil,
        serialized: Serialized? = nil,
        sources: [Source]? = nil
    ) -> Statistics {
        return Statistics(
            identifier: identifier ?? self.identifier,
            startTimestamp: startTimestamp ?? self.startTimestamp,
            endTimestamp: endTimestamp ?? self.endTimestamp,
            serialized: serialized ?? self.serialized,
            sources: sources ?? self.sources
        )
    }
}
// MARK: - UnitConvertable
extension Statistics: UnitConvertable {
    public func converted(to unit: String) throws -> Statistics {
        guard serialized.unit != unit else {
            return self
        }
        return copyWith(serialized: serialized.copyWith(unit: unit))
    }
}
