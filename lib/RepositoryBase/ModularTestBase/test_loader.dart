import 'package:yaml/yaml.dart';
import 'test_definition.dart';

List<TestDefinition> loadTestDefinitionsFromYaml(String yamlString) {
  final yamlData = loadYaml(yamlString);
  final definitions = <TestDefinition>[];

  if (yamlData is YamlMap && yamlData.containsKey('tests')) {
    final testsList = yamlData['tests'] as YamlList;
    for (final t in testsList) {
      if (t is YamlMap) {
        definitions.add(TestDefinition.fromYaml(t));
      }
    }
  } else if (yamlData is YamlList) {
    for (final t in yamlData) {
      if (t is YamlMap) {
        definitions.add(TestDefinition.fromYaml(t));
      }
    }
  } else if (yamlData is YamlMap) {
    definitions.add(TestDefinition.fromYaml(yamlData));
  }

  return definitions;
}
