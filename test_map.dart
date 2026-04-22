import 'package:google_maps_flutter/google_maps_flutter.dart';
void test() {
  GoogleMap(
    initialCameraPosition: const CameraPosition(target: LatLng(0,0)),
    cloudMapId: 'DEMO_MAP_ID',
  );
}
