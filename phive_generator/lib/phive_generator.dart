/// Public API for `phive_generator`.
///
/// External packages and test code import from here.  Internal `src/` modules
/// should be imported directly by their path within the package.
library phive_generator;

export 'src/phive_generator.dart' show PhiveGenerator;
export 'src/auto_type_generator.dart' show PhiveAutoTypeGenerator;
export 'src/type_registry.dart' show TypeIdRegistry;
