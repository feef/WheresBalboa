import MapKit

class TripAnnotation: MKPointAnnotation {
    let user: User
    let trip: Trip
    
    init(_ balbabe: User, _ trip: Trip, isLoggedInUser: Bool = false) {
        self.user = balbabe
        self.trip = trip
        super.init()
        coordinate = trip.metadata.address.location.coordinate
        title = isLoggedInUser ? "You" : balbabe.metadata.name
        let startDate = trip.metadata.dateInterval.start
        let endDate = trip.metadata.dateInterval.end
        let startDateString = startDate.isDistantPast ? "∞" : DateFormatter.fullDateShortenedYear.string(from: startDate)
        let endDateString = endDate.isDistantFuture ? "∞" : DateFormatter.fullDateShortenedYear.string(from: endDate)
        subtitle = startDateString + " - " + endDateString
    }
}
