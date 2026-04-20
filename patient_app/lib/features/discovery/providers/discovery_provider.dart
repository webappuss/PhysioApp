import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/discovery_repository.dart';
import '../models/physio_model.dart';

class SearchFilters {
  final double? lat;
  final double? lng;
  final String? specialty;
  final String? bookingType;
  final double minRating;
  final double radiusKm;
  final int page;

  const SearchFilters({
    this.lat, this.lng, this.specialty, this.bookingType,
    this.minRating = 0, this.radiusKm = 10, this.page = 1,
  });

  SearchFilters copyWith({double? lat, double? lng, String? specialty,
    String? bookingType, double? minRating, double? radiusKm, int? page}) =>
    SearchFilters(
      lat: lat ?? this.lat, lng: lng ?? this.lng,
      specialty: specialty ?? this.specialty, bookingType: bookingType ?? this.bookingType,
      minRating: minRating ?? this.minRating, radiusKm: radiusKm ?? this.radiusKm,
      page: page ?? this.page,
    );
}

final searchFiltersProvider = StateProvider<SearchFilters>((ref) => const SearchFilters());

final physioSearchProvider = FutureProvider.autoDispose<PhysioSearchResult>((ref) {
  final filters = ref.watch(searchFiltersProvider);
  return ref.watch(discoveryRepositoryProvider).searchPhysios(
    lat: filters.lat, lng: filters.lng, radiusKm: filters.radiusKm,
    specialty: filters.specialty, bookingType: filters.bookingType,
    minRating: filters.minRating, page: filters.page,
  );
});

final physioDetailProvider = FutureProvider.autoDispose.family<PhysioDetail, int>((ref, physioId) {
  return ref.watch(discoveryRepositoryProvider).getPhysioDetail(physioId);
});

final availableSlotsProvider = FutureProvider.autoDispose.family<List<String>, ({int physioId, String date})>(
  (ref, args) => ref.watch(discoveryRepositoryProvider).getAvailableSlots(args.physioId, args.date),
);
