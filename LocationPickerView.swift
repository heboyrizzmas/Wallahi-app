//
//  LocationPickerView.swift
//  TaskFlow
//
//  iOS 16 compatible — the new SwiftUI `Map`/`MapReader`/`Marker` APIs
//  are iOS 17+ only, so this wraps the classic UIKit MKMapView instead
//  via UIViewRepresentable. Still uses free Apple MapKit, no API key.
//

import SwiftUI
import MapKit
import CoreLocation

struct LocationPickerView: View {
    @Environment(\.dismiss) private var dismiss

    var initialCoordinate: CLLocationCoordinate2D?
    var onConfirm: (CLLocationCoordinate2D, String) -> Void

    @State private var selectedCoordinate: CLLocationCoordinate2D?
    @State private var selectedName: String = ""
    @State private var searchText: String = ""
    @StateObject private var searchCompleter = SearchCompleterModel()

    init(initialCoordinate: CLLocationCoordinate2D?, onConfirm: @escaping (CLLocationCoordinate2D, String) -> Void) {
        self.initialCoordinate = initialCoordinate
        self.onConfirm = onConfirm
        _selectedCoordinate = State(initialValue: initialCoordinate)
    }

    var body: some View {
        NavigationView {
            ZStack(alignment: .top) {
                MapViewRepresentable(
                    initialCoordinate: initialCoordinate ?? CLLocationCoordinate2D(latitude: 37.3349, longitude: -122.0090),
                    selectedCoordinate: $selectedCoordinate,
                    pinTitle: selectedName.isEmpty ? "Selected spot" : selectedName,
                    onTap: { coord in
                        selectedCoordinate = coord
                        selectedName = "Dropped pin"
                        searchText = ""
                        searchCompleter.results = []
                    }
                )
                .ignoresSafeArea(edges: .bottom)

                VStack(spacing: 8) {
                    searchBar
                    if !searchCompleter.results.isEmpty {
                        resultsList
                    }
                }
                .padding(.top, 8)
            }
            .safeAreaInset(edge: .bottom) {
                confirmBar
            }
            .navigationTitle("Choose Location")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .onChange(of: searchText) { newValue in
                searchCompleter.update(query: newValue)
            }
        }
        .navigationViewStyle(.stack)
    }

    private var searchBar: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundColor(.secondary)
            TextField("Search for a place", text: $searchText)
                .textFieldStyle(.plain)
            if !searchText.isEmpty {
                Button {
                    searchText = ""
                    searchCompleter.results = []
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(Color(.tertiaryLabel))
                }
            }
        }
        .padding(12)
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
        .shadow(color: .black.opacity(0.08), radius: 6, y: 2)
    }

    private var resultsList: some View {
        VStack(spacing: 0) {
            ForEach(searchCompleter.results, id: \.self) { completion in
                Button {
                    resolve(completion)
                } label: {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(completion.title)
                            .font(.subheadline.weight(.medium))
                            .foregroundColor(.primary)
                        if !completion.subtitle.isEmpty {
                            Text(completion.subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 10)
                }
                Divider()
            }
        }
        .background(Color(.secondarySystemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .padding(.horizontal)
    }

    private var confirmBar: some View {
        VStack {
            if selectedCoordinate != nil {
                Button {
                    if let coord = selectedCoordinate {
                        onConfirm(coord, selectedName.isEmpty ? "Selected location" : selectedName)
                        dismiss()
                    }
                } label: {
                    Text("Confirm Location")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.indigo)
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .padding(.horizontal)
                .padding(.bottom, 8)
            }
        }
        .background(Color(.systemBackground).opacity(0.9))
    }

    private func resolve(_ completion: MKLocalSearchCompletion) {
        let request = MKLocalSearch.Request(completion: completion)
        let search = MKLocalSearch(request: request)
        search.start { response, _ in
            guard let coordinate = response?.mapItems.first?.placemark.coordinate else { return }
            selectedCoordinate = coordinate
            selectedName = completion.title
            searchText = completion.title
            searchCompleter.results = []
        }
    }
}

/// UIViewRepresentable wrapper around the classic MKMapView (works iOS 13+),
/// replacing the iOS 17+-only SwiftUI `Map` view.
struct MapViewRepresentable: UIViewRepresentable {
    var initialCoordinate: CLLocationCoordinate2D
    @Binding var selectedCoordinate: CLLocationCoordinate2D?
    var pinTitle: String
    var onTap: (CLLocationCoordinate2D) -> Void

    func makeUIView(context: Context) -> MKMapView {
        let mapView = MKMapView()
        mapView.delegate = context.coordinator
        mapView.showsUserLocation = true

        let region = MKCoordinateRegion(
            center: selectedCoordinate ?? initialCoordinate,
            span: MKCoordinateSpan(latitudeDelta: 0.02, longitudeDelta: 0.02)
        )
        mapView.setRegion(region, animated: false)

        let tapGesture = UITapGestureRecognizer(target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
        mapView.addGestureRecognizer(tapGesture)

        if let coord = selectedCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = pinTitle
            mapView.addAnnotation(annotation)
        }

        return mapView
    }

    func updateUIView(_ mapView: MKMapView, context: Context) {
        mapView.removeAnnotations(mapView.annotations)
        if let coord = selectedCoordinate {
            let annotation = MKPointAnnotation()
            annotation.coordinate = coord
            annotation.title = pinTitle
            mapView.addAnnotation(annotation)

            // Recenter only if the coordinate moved from a search result,
            // not on every SwiftUI re-render.
            if !context.coordinator.isDraggingOrTapping {
                let region = MKCoordinateRegion(
                    center: coord,
                    span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                )
                mapView.setRegion(region, animated: true)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    final class Coordinator: NSObject, MKMapViewDelegate {
        var parent: MapViewRepresentable
        var isDraggingOrTapping = false

        init(_ parent: MapViewRepresentable) {
            self.parent = parent
        }

        @objc func handleTap(_ gesture: UITapGestureRecognizer) {
            guard let mapView = gesture.view as? MKMapView else { return }
            let point = gesture.location(in: mapView)
            let coordinate = mapView.convert(point, toCoordinateFrom: mapView)
            isDraggingOrTapping = true
            parent.onTap(coordinate)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                self.isDraggingOrTapping = false
            }
        }

        func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
            guard !(annotation is MKUserLocation) else { return nil }
            let identifier = "pin"
            var view = mapView.dequeueReusableAnnotationView(withIdentifier: identifier) as? MKMarkerAnnotationView
            if view == nil {
                view = MKMarkerAnnotationView(annotation: annotation, reuseIdentifier: identifier)
            }
            view?.annotation = annotation
            view?.markerTintColor = .systemIndigo
            view?.canShowCallout = true
            return view
        }
    }
}

/// Wraps MKLocalSearchCompleter for SwiftUI, providing live autocomplete
/// results as the user types.
final class SearchCompleterModel: NSObject, ObservableObject, MKLocalSearchCompleterDelegate {
    @Published var results: [MKLocalSearchCompletion] = []
    private let completer = MKLocalSearchCompleter()

    override init() {
        super.init()
        completer.delegate = self
        completer.resultTypes = [.pointOfInterest, .address]
    }

    func update(query: String) {
        if query.isEmpty {
            results = []
        } else {
            completer.queryFragment = query
        }
    }

    func completerDidUpdateResults(_ completer: MKLocalSearchCompleter) {
        results = completer.results
    }

    func completer(_ completer: MKLocalSearchCompleter, didFailWithError error: Error) {
        print("Search completer error: \(error.localizedDescription)")
    }
}
