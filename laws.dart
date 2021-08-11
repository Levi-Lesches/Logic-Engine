import "premises.dart";

class Laws {
	static const String given = "Given";

	// Conditionals
	static const String modusTollens = "Modus Tollens";
	static const String detachment = "Detachment";
	static const String contrapositive = "Constrapositive";
	static const String conditionalNormalization = "Conditional Normalization";
	static const String chainRule = "Chain Rule";

	// Disjunctions and Conjunctions
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
// - operands: [p]
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
		required this.result,
	}) : _prems = [
		if (basis != null) basis,
		...operands,
	];

	const Law.given(this.result) : 
		name = Laws.given,
		basis = null, 
		operands = const [],
		_prems = const [];

	@override
	String toString() => "$result: Apply $name to [$basis] with $operands";

	@override
	bool operator ==(Object other) => other is Law 
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

List<Law>? constructPremise(Premise target, List<Law> premises) {
	if (target is Conditional && target.isPositive) return [
		Law(
			basis: null,
			operands: [
				Conditional(target.conclusion.negate(), target.hypothesis.negate())
			],
			result: target,
			name: Laws.contrapositive
		),
		Law(
			basis: null,
			operands: [Disjunction(target.hypothesis.negate(), target.conclusion)],
			result: target,
			name: Laws.conditionalNormalization,
		)
	]; else if (target is BinaryPremise) {
		final Law deMorgans = Law(
			basis: null,
			operands: [target.deMorgans().result],  // transitive property
			result: target,
			name: Laws.deMorgans,
		);

		if (target is Disjunction) return [
			deMorgans,
			for (var terms in [
				[target.left, target.right],  [target.right, target.left]
			]) ...[
				if (target.isPositive) Law(
					basis: null,
					operands: [terms [0]],
					result: target,
					name: Laws.disjunctiveAddition,
				),
				if (target.isPositive) Law(
					basis: null,
					operands: [Conditional(terms [0].negate(), terms [1])],
					result: target,
					name: Laws.conditionalNormalization,
				),
			],
		]; else if (target is Conjunction) return [
			deMorgans,
			if (target.isPositive) Law(
				basis: null,
				operands: [target.left, target.right],
				result: target,
				name: Laws.conjunctiveAddition,
			),
		];
	} 
}
