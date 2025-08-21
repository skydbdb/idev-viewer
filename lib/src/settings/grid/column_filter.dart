import 'package:idev_v1/src/util/regular_expression.dart';
import '/src/grid/trina_grid/trina_grid.dart';

class ClassYouImplemented implements TrinaFilterType {
  @override
  String get title => 'Custom contains';

  @override
  get compare => ({
        required String? base,
        required String? search,
        required TrinaColumn? column,
      }) {
        var keys = search!.split(',').map((e) => e.toUpperCase()).toList();

        return keys.contains(base!.toUpperCase());
      };

  const ClassYouImplemented();
}

class PlutoFilterTypeNumber implements TrinaFilterType {
  @override
  String get title => 'Contain Numbers';

  @override
  get compare => ({
        required String? base,
        required String? search,
        required TrinaColumn? column,
      }) {
        String find = '';
        if (RegularExpression.isNumber(search!)) {
          find = search;
        } else {
          return throw ValidateError('숫자가 아닙니다.');
        }
        return FilterHelper.compareContains(
            base: base, search: find, column: column!);
      };

  PlutoFilterTypeNumber();
}

class ValidateError extends Error implements UnsupportedError {
  @override
  final String? message;
  ValidateError([this.message]);

  @override
  String toString() {
    var message = this.message;
    return (message != null)
        ? "UnimplementedError: $message"
        : "UnimplementedError";
  }
}
