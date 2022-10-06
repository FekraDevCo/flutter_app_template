import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:json_annotation/json_annotation.dart';

class FirebaseTimestampConverter implements JsonConverter<DateTime, Object?> {
  // signals a DateTime that should be assigned from server.
  // the value of this instance itself isn't used and is an arbitrary value.
  static final serverDateTime = DateTime.fromMillisecondsSinceEpoch(0);

  const FirebaseTimestampConverter();

  @override
  // the response from server of a DateTime field is always a Timestamp
  DateTime fromJson(Object? timestamp) =>
      (timestamp as Timestamp?)?.toDate() ?? DateTime.now();

  @override
  Object toJson(DateTime datetime) {
    if (identical(datetime, serverDateTime)) {
      return FieldValue.serverTimestamp();
    } else {
      return Timestamp.fromDate(datetime);
    }
  }
}

class NullableFirebaseTimestampConverter
    implements JsonConverter<DateTime?, Object?> {
  const NullableFirebaseTimestampConverter();

  @override
  // the response from server of a DateTime field is always a Timestamp
  DateTime? fromJson(Object? timestamp) => (timestamp as Timestamp?)?.toDate();

  @override
  Object? toJson(DateTime? datetime) {
    if (datetime == null) {
      return null;
    } else if (identical(datetime, FirebaseTimestampConverter.serverDateTime)) {
      return FieldValue.serverTimestamp();
    } else {
      return Timestamp.fromDate(datetime);
    }
  }
}
