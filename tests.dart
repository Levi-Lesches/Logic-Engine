import "laws.dart";
import "logic.dart";
import "premises.dart";

// ignore_for_file: avoid_print

class Test {
	final String? name, result;
	final List<Premise> givens;
	final Premise toProve;

	const Test({
		required this.givens, 
		required this.toProve, 
		this.result,
		this.name, 
	});

	void test() {
		if (name != null) print("Testing $name...");
		final List<Law> proof = prove(givens, toProve);
		final String formatted = formatProof(proof);
		final String test = formatted.replaceAll("\t", "");
		// Don't use asserts, since they don't compile
		if (result != null && test != result!.replaceAll("\t", "")) {
			print("Test failed.");
			print("  Got: ");
			print(formatted);
			print("  but expected: ");
			print(result);
			throw AssertionError("Test failed");
		} else {
			print(formatted);
		}
		print("");
	}
}

const List<Test> tests = [
	Test(
		name: "Nested Detachment",
		givens: [
			Conditional(Symbol("a"), Symbol("b")),
			Conditional(Symbol("b"), Symbol("c")),
			Symbol("a"),
		],
		toProve: Symbol("c"),
		result: """
			1. a --> b -- Given
			2. b --> c -- Given
			3. a -- Given
			4. b -- Detachment (1, 3)
			5. c -- Detachment (2, 4)
		""",
	),
	Test(
		givens: [
		 	Conditional(Symbol("d", isPositive: false), Symbol("b", isPositive: false)),
		 	Conditional(Symbol("x", isPositive: false), Symbol("c", isPositive: false)),
		 	Conditional(
		 		Disjunction(Symbol("b", isPositive: false), Symbol("h")),
		 		Disjunction(Symbol("q"), Symbol("r"))
		 	),
			Conjunction(Symbol("c", isPositive: false), Symbol("d"), isPositive: false),
		 	Conjunction(Symbol("d"), Symbol("b", isPositive: false)),
			Symbol("r", isPositive: false),
		 	Symbol("q", isPositive: false),
		],
		toProve: Symbol("x"),
		result: """
			1. ~d --> ~b -- Given
			2. ~x --> ~c -- Given
			3. (~b V h) --> (q V r) -- Given
			4. ~(~c ^ d) -- Given
			5. d ^ ~b -- Given
			6. ~r -- Given
			7. ~q -- Given
			8. c V ~d -- De Morgan's Law (4)
			9. d -- Conjunctive Inference (5)
			10. c -- Disjunctive Inference (8, 9)
			11. x -- Modus Tollens (2, 10)
		"""
	),
	Test(
		givens: [
			Conditional(Symbol("a", isPositive: false), Symbol("m")),
			Conditional(Symbol("m"), Symbol("w")),
			Conditional(Symbol("a"), Symbol("b")),
			Symbol("w", isPositive: false),
		],
		toProve: Symbol("b"),
		result: """
			1. ~a --> m -- Given
			2. m --> w -- Given
			3. a --> b -- Given
			4. ~w -- Given
			5. ~m -- Modus Tollens (2, 4)
			6. a -- Modus Tollens (1, 5)
			7. b -- Detachment (3, 6)
		"""
	),
	Test(
		givens: [
			Conditional(Symbol("p"), Symbol("q", isPositive: false)),
			Disjunction(Symbol("q"), Symbol("r")),
			Disjunction(Symbol("p"), Symbol("u")),
			Symbol("r", isPositive: false),
		], 
		toProve: Symbol("u"),
		result: """
			1. p --> ~q -- Given
			2. q V r -- Given
			3. p V u -- Given
			4. ~r -- Given
			5. q -- Disjunctive Inference (2, 4)
			6. ~p -- Modus Tollens (1, 5)
			7. u -- Disjunctive Inference (3, 6)
		"""
	),
	Test(
		givens: [
			Disjunction(Symbol("p", isPositive: false), Symbol("q"), isPositive: false),
			Conditional(Symbol("z", isPositive: false), Symbol("s", isPositive: false)),
			Conditional(
				Conjunction(Symbol("p"), Symbol("q", isPositive: false)),
				Symbol("s"),
			),
			Disjunction(Symbol("z", isPositive: false), Symbol("r")),
		], 
		toProve: Symbol("r"),
		result: """
			1. ~(~p V q) -- Given
			2. ~z --> ~s -- Given
			3. (p ^ ~q) --> s -- Given
			4. ~z V r -- Given
			5. p ^ ~q -- De Morgan's Law (1)
			6. s -- Detachment (3, 5)
			7. z -- Modus Tollens (2, 6)
			8. r -- Disjunctive Inference (4, 7)
		"""
	),
	Test(
		givens: [
			Conditional(Symbol("u"), Symbol("r")),
			Conditional(
				Conjunction(Symbol("r"), Symbol("s")),
				Disjunction(Symbol("p"), Symbol("t")),
			),
			Conditional(
				Symbol("q"),
				Conjunction(Symbol("u"), Symbol("s")),
			),
			Symbol("t", isPositive: false),
			Symbol("q"),
		],
		toProve: Symbol("p"),
		result: """
			1. u --> r -- Given
			2. (r ^ s) --> (p V t) -- Given
			3. q --> (u ^ s) -- Given
			4. ~t -- Given
			5. q -- Given
			6. u ^ s -- Detachment (3, 5)
			7. u -- Conjunctive Inference (6)
			8. r -- Detachment (1, 7)
			9. s -- Conjunctive Inference (6)
			10. r ^ s -- Conjunctive Addition (8, 9)
			11. p V t -- Detachment (2, 10)
			12. p -- Disjunctive Inference (11, 4)
		"""
	),
	Test(
		givens: [
			Conditional(Symbol("p"), Symbol("r")),
			Conditional(Symbol("q"), Symbol("s")),
			Disjunction(Symbol("p"), Symbol("q")),
		],
		toProve: Disjunction(Symbol("s"), Symbol("r")),
	)
];

void main() {
	for (final Test test in tests) test.test();
}