import 'package:latlong2/latlong.dart';

import '../models/station.dart';

/// Hardcoded station data for the prototype.
///
/// The first station is real data from InfoBanjir (publicinfobanjir.water.gov.my).
/// The others are SAMPLE stations with made-up readings and thresholds, only
/// there so the map and list have something to compare against. They are
/// labelled "Sample data" everywhere in the app.
///
/// metLocationId is the MET Malaysia forecast district for each station
/// (from api.data.gov.my/weather/forecast).
List<Station> buildStations() => [
      Station(
        id: '0670341WL',
        name: 'Sg. Terengganu di Drawbridge (F1)',
        district: 'Kuala Terengganu',
        river: 'Sungai Terengganu',
        basin: 'Sg. Terengganu',
        location: const LatLng(5.3344, 103.1418),
        normalLevel: 0.30,
        alertLevel: 1.40,
        warningLevel: 1.60,
        dangerLevel: 1.80,
        realLevel: -0.30,
        realReadingTime: DateTime(2026, 11, 24, 14, 0),
        metLocationId: 'Ds048',
      ),
      Station(
        id: 'SAMPLE-01',
        name: 'Sg. Besut di Jerteh',
        district: 'Besut',
        river: 'Sungai Besut',
        basin: 'Sg. Besut',
        location: const LatLng(5.7370, 102.4910),
        normalLevel: 1.00,
        alertLevel: 2.50,
        warningLevel: 3.00,
        dangerLevel: 3.50,
        realLevel: 1.20,
        realReadingTime: DateTime(2026, 11, 24, 14, 0),
        metLocationId: 'Ds037',
        isSample: true,
      ),
      Station(
        id: 'SAMPLE-02',
        name: 'Sg. Dungun di Bandar Dungun',
        district: 'Dungun',
        river: 'Sungai Dungun',
        basin: 'Sg. Dungun',
        location: const LatLng(4.7570, 103.4140),
        normalLevel: 0.50,
        alertLevel: 1.60,
        warningLevel: 2.00,
        dangerLevel: 2.40,
        realLevel: 1.75,
        realReadingTime: DateTime(2026, 11, 24, 14, 0),
        metLocationId: 'Ds056',
        isSample: true,
      ),
      Station(
        id: 'SAMPLE-03',
        name: 'Sg. Kemaman di Chukai',
        district: 'Kemaman',
        river: 'Sungai Kemaman',
        basin: 'Sg. Kemaman',
        location: const LatLng(4.2330, 103.4240),
        normalLevel: 0.80,
        alertLevel: 2.00,
        warningLevel: 2.60,
        dangerLevel: 3.10,
        realLevel: 0.95,
        realReadingTime: DateTime(2026, 11, 24, 14, 0),
        metLocationId: 'Ds065',
        isSample: true,
      ),
    ];
