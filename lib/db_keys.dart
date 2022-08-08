// ignore_for_file: constant_identifier_names

class DBKeys {
  final String userCollection;
  final String testCollection;
  final String subUserCollection;
  final String responseCollection;

  //User fields

  final String uidField;
  final String emailField;

  //Sub user fields

  final String subId;
  final String nameField;
  final String genderField;
  final String birthYearField;
  final String controlField;

  //Response constants

  final String stampField;
  final String idField;
  final String responseField;
  final String selectedField;
  final String selectedFields;
  final String numericResponseField;
  final String detailResponseKey;
  final String descriptionField;

  const DBKeys(
      {required this.userCollection,
      required this.testCollection,
      required this.subUserCollection,
      required this.responseCollection,
      required this.uidField,
      required this.emailField,
      required this.subId,
      required this.nameField,
      required this.genderField,
      required this.birthYearField,
      required this.controlField,
      required this.stampField,
      required this.idField,
      required this.responseField,
      required this.selectedField,
      required this.selectedFields,
      required this.numericResponseField,
      required this.detailResponseKey,
      required this.descriptionField});
}

const defaultKeys = DBKeys(
    userCollection: USER_COLLECTION,
    testCollection: TEST_COLLECTION,
    subUserCollection: SUB_USER_COLLECTION,
    responseCollection: RESPONSE_COLLECTION,
    uidField: UID_FIELD,
    emailField: EMAIL_FIELD,
    subId: SUB_ID,
    nameField: NAME_FIELD,
    genderField: GENDER_FIELD,
    birthYearField: BIRTH_YEAR_FIELD,
    controlField: CONTROL_FIELD,
    stampField: STAMP_FIELD,
    idField: ID_FIELD,
    responseField: RESPONSE_FIELD,
    selectedField: SELECTED_FIELD,
    selectedFields: SELECTED_FIELDS,
    numericResponseField: NUMERIC_RESPONSE_FIELD,
    detailResponseKey: DETAIL_TYPE_KEY,
    descriptionField: DESCRIPTION_FIELD);

const String USER_COLLECTION = 'user_col';
const String TEST_COLLECTION = 'test_col';
const String SUB_USER_COLLECTION = 'sub_user_col';
const String RESPONSE_COLLECTION = 'user_responses';

//User fields

const String UID_FIELD = 'uid';
const String EMAIL_FIELD = 'email';

//Sub user fields

const String SUB_ID = 'sub_uid';
const String NAME_FIELD = 'name';
const String GENDER_FIELD = 'gender';
const String BIRTH_YEAR_FIELD = 'birth_year';
const String CONTROL_FIELD = 'control';

//Response constants

const String STAMP_FIELD = 'stamp';
const String TYPE_FIELD = 'type';
const String ID_FIELD = 'qid';
const String RESPONSE_FIELD = 'response';
const String SELECTED_FIELD = 'selected';
const String SELECTED_FIELDS = 'all_selected';
const String NUMERIC_RESPONSE_FIELD = 'numeric_reponse';
const String DETAIL_TYPE_KEY = 'detailTypeKey';

const String DESCRIPTION_FIELD = 'desc';
