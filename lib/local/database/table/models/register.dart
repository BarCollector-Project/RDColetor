enum RegiterID {
  collect,
}

abstract class Register {
  RegiterID get id;
  DateTime get timestamp;
}
