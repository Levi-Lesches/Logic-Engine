import "laws.dart";

abstract class Premise {
	final bool isPositive;
	const Premise({required this.isPositive});

	String format(Premise left, Premise right, String operator) {
		String formatInternal(Premise prem) => prem is Symbol || !prem.isPositive
			? prem.toString() : "($prem)";

		final String _left = formatInternal(left);
		final String _right = formatInternal(right);
		if (isPositive) return "$_left $operator $_right";
		else return "~($_left $operator $_right)";
	}

	bool get canBeNormalized;
	Law? normalize();
	Premise negate();
	bool contains(Premise other);
	Law? getLaw(Premise other);
}

class Symbol extends Premise {
	final String symbol;
	const Symbol(this.symbol, {bool isPositive = true}) : 
		super(isPositive: isPositive);

	@override
	String toString() => isPositive ? symbol : "~$symbol";

	@override
	bool operator ==(Object other) => other is Symbol
		&& other.symbol == symbol
		&& other.isPositive == isPositive;

	@override
	int get hashCode => toString().hashCode;

	@override
	Premise negate() => Symbol(symbol, isPositive: !isPositive);

	@override
	bool contains(Premise other) => other == this;

	@override
	Law? getLaw(Premise other) => null;  // use == instead

	@override
	bool get canBeNormalized => false;

	@override
	Law? normalize() => null;
}

class Conditional extends Premise {
	final Premise hypothesis, conclusion;
	const Conditional(
		this.hypothesis, 
		this.conclusion, 
		{bool isPositive = true}
	) : super(isPositive: isPositive);

	@override
	String toString() => format(hypothesis, conclusion, "-->");

	@override
	bool operator ==(Object other) => other is Conditional
		&& other.hypothesis == hypothesis
		&& other.conclusion == conclusion
		&& other.isPositive == isPositive;

	@override
	int get hashCode => toString().hashCode;

	@override
	bool contains(Premise other) => isPositive && (
		conclusion.contains(other) 
		|| hypothesis.negate().contains(other)
	);

	@override
	Conditional negate() => Conditional(
		hypothesis, conclusion, isPositive: !isPositive
	);

	@override
	Law? getLaw(Premise other) {
		if (!isPositive) return null;
		else if (conclusion.contains(other)) return Law(
			basis: this,
			operands: [hypothesis], 
			result: conclusion, 
			name: Laws.detachment
		); else if (hypothesis.negate().contains(other)) return Law(
			basis: this,
			operands: [conclusion.negate()], 
			result: hypothesis.negate(), 
			name: Laws.modusTollens
		);
	}

	@override
	bool get canBeNormalized => !isPositive;

	@override
	Law? normalize() {
		if (!isPositive) return Law(
			basis: this,
			operands: [],
			result: Conjunction(hypothesis, conclusion.negate()),
			name: Laws.conditionalNormalization,
		);
	}
}

abstract class BinaryPremise extends Premise {
	final Premise left, right; 
	final String operator;
	const BinaryPremise(
		this.left, this.right, 
		{required this.operator, bool isPositive = true}
	) : 
		super(isPositive: isPositive);

	@override
	String toString() => format(left, right, operator);

	@override
	bool operator ==(Object other) => other is BinaryPremise
		&& other.runtimeType == runtimeType
		&& other.isPositive == isPositive
		&& (
			(other.left == left && other.right == right) ||
			(other.left == right && other.right == left)
		);

	@override
	int get hashCode => toString().hashCode;

	@override
	bool contains(Premise other) => isPositive
		&& (left.contains(other) || right.contains(other));

	@override
	BinaryPremise negate() => this is Conjunction 
		? Conjunction(left, right, isPositive: !isPositive)
		: Disjunction(left, right, isPositive: isPositive);

	Law deMorgans() => Law(
		basis: this,
		operands: [],
		result: this is Conjunction
			? Disjunction(left.negate(), right.negate(), isPositive: !isPositive)
			: Conjunction(left.negate(), right.negate(), isPositive: !isPositive),
		name: Laws.deMorgans,
	);

	@override
	bool get canBeNormalized => !isPositive;

	@override
	Law? normalize() => isPositive ? null : deMorgans();
}

class Disjunction extends BinaryPremise {
	const Disjunction(
		Premise left, Premise right, 
		{bool isPositive = true}
	) : super(left, right, isPositive: isPositive, operator: "V");

	@override
	Law? getLaw(Premise other) {
		if (!isPositive) return null;
		else if (left.contains(other)) return Law(
			basis: this,
			operands: [right.negate()],
			result: left,
			name: Laws.disjunctiveInference,
		); else if (right.contains(other)) return Law(
			basis: this,
			operands: [left.negate()],
			result: right, 
			name: Laws.disjunctiveInference,
		);
	}
}

class Conjunction extends BinaryPremise {
	const Conjunction(
		Premise left, Premise right,
		{bool isPositive = true}
	) : super(left, right, isPositive: isPositive, operator: "^");

	@override
	Law? getLaw(Premise other) {
		if (!isPositive) return null;
		else if (left.contains(other)) return Law(
			basis: this,
			operands: [],
			result: left,
			name: Laws.conjunctiveInference,
		); else if (right.contains(other)) return Law(
			basis: this,
			operands: [],
			result: right,
			name: Laws.conjunctiveInference,
		);
	}
}
