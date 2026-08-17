import 'package:drift/drift.dart';
import '../../models/enums.dart';

class Children extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get gender => textEnum<Gender>()();
  TextColumn get birthDate => text()();
  RealColumn get birthWeight => real()();
  RealColumn get weight => real()();
  RealColumn get height => real()();
  TextColumn get emoji => text()();
  TextColumn get medicalHistory => text()();

  @override
  Set<Column> get primaryKey => {id};
}

class Vaccinations extends Table {
  TextColumn get id => text()();
  TextColumn get childId => text()();
  TextColumn get name => text()();
  TextColumn get date => text()();
  BoolColumn get done => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Screenings extends Table {
  TextColumn get id => text()();
  TextColumn get childId => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get symptoms => text()();
  IntColumn get audioDuration => integer()();
  TextColumn get riskLevel => textEnum<RiskLevel>()();
  TextColumn get disease => text()();
  IntColumn get confidence => integer()();
  TextColumn get status => textEnum<SyncStatus>()();

  @override
  Set<Column> get primaryKey => {id};
}

class ScreeningSync extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  TextColumn get payload => text()();
  TextColumn get status => textEnum<SyncStatus>()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get lastError => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class AppNotifications extends Table {
  TextColumn get id => text()();
  TextColumn get type => textEnum<NotifType>()();
  TextColumn get title => text()();
  TextColumn get body => text()();
  TextColumn get time => text()();
  BoolColumn get read => boolean()();

  @override
  Set<Column> get primaryKey => {id};
}

class Meta extends Table {
  TextColumn get key => text()();
  TextColumn get value => text()();

  @override
  Set<Column> get primaryKey => {key};
}

class Accounts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get email => text()();
  TextColumn get phone => text()();
  TextColumn get emoji => text()();
  TextColumn get role => text()();
  TextColumn get passwordHash => text()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
