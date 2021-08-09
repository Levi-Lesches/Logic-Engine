import "premises.dart";

class Laws {
	static const String given = "Given";

	static const String modusTollens = "Modus Tollens";
	static const String detachment = "Detachment";
	static const String contrapositive = "Constrapositive";
	static const String conditionalNormalization = "Conditional Normalization";

	static const String disjunctiveInference = "Disjunctive Inference";
	static const String conjunctiveInference = "Conjunctive Inference";
	static const String deMorgans = "De Morgan's Law";
	static const String disjunctiveAddition = "Disjunctive Addition";
	static const String conjunctiveAddition = "Conjunctive Addition";
}

// Get [result] by applying [law] to [basis] with [operands].
// 
// Example: 
// - name: detachment
// - basis: p --> q
// - operands: p
// - result: q
class Law {
	final String name;
	final Premise? basis;
	final Premise result;
	final List<Premise> operands;

	final List<Premise> _prems;
	Law({
		required this.name, 
		required this.basis, 
		required this.operands, 
		required this.result
	}) : _prems = [
		if (basis != null) basis,
		...operands,
	];

	@override
	String toString() => "$result: Applied $name to $basis with $operands";

	@override
	bool operator ==(Object other) => other is Law 
		&& other.basis == basis
		// && other.operands == operands
		&& other.name == name
		&& other.result == result;

	@override
	int get hashCode => toString().hashCode;

	String format(List<Law> proof) {
		if (name == Laws.given) {
			return "$result -- $name";
		} else {
			final List<int> indices = [
				for (final Premise prem in _prems) 
					proof.indexWhere((law) => law.result == prem) + 1
			];
			return "$result -- $name (${indices.join(', ')})";
		}
	}
}

String formatProof(List<Law> proof) {
	final StringBuffer result = StringBuffer();
	for (int index = 0; index < proof.length; index++) {
		final Law step = proof[index];
		result.write("${index + 1}. ${step.format(proof)}\n");
	}
	return result.toString();
}

