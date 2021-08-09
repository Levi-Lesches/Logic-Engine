// ignore_for_file: avoid_print

import "dart:collection";

import "laws.dart";
import "premises.dart";

typedef Proof = List<Law>;

Iterable<Symbol> getUniqueSymbols(List<Law> laws) sync* {
	final Set<String> result = {};

	void recurse(Premise premise) {
		if (premise is Conditional) {
			recurse(premise.hypothesis);
			recurse(premise.conclusion);
		} else if (premise is BinaryPremise) {
			recurse(premise.left);
			recurse(premise.right);
		} else if (premise is Symbol) {
			result.add(premise.symbol);
		}
	} 

	for (final Law law in laws) {
		final Premise premise = law.result;
		recurse(premise);
	}
	for (final String symbol in result) {
		yield Symbol(symbol);
		yield Symbol(symbol, isPositive: false);
	}
}

List<Law>? constructPremise(Premise target, List<Law> premises) {
	if (target is Conditional && target.isPositive) return [
		for (final Symbol symbol in getUniqueSymbols(premises))
			if (
				symbol != target.hypothesis 
				&& symbol != target.conclusion
				&& symbol != target.hypothesis.negate()
				&& symbol != target.conclusion.negate()
			) Law(
				basis: null,
				operands: [
					Conditional(target.hypothesis, symbol),
					Conditional(symbol, target.conclusion),
				],
				result: target,
				name: Laws.chainRule,
			),
		Law(
			basis: null,
			operands: [Disjunction(target.hypothesis.negate(), target.conclusion)],
			result: target,
			name: Laws.conditionalNormalization,
		),
		Law(
			basis: null,
			operands: [Disjunction(target.hypothesis, target.conclusion.negate())],
			result: target,
			name: Laws.conditionalNormalization,
		),
		Law(
			basis: null,
			operands: [
				Conditional(target.conclusion.negate(), target.hypothesis.negate())
			],
			result: target,
			name: Laws.contrapositive
		),
	]; else if (target is BinaryPremise) {
		final Law deMorgans = Law(
			basis: null,
			operands: [target.deMorgans().result],  // transitive property
			result: target,
			name: Laws.deMorgans,
		);

		if (target is Disjunction) return [
			deMorgans,
			if (target.isPositive) Law(
				basis: null,
				operands: [target.left],
				result: target,
				name: Laws.disjunctiveAddition,
			),
			if (target.isPositive) Law(
				basis: null,
				operands: [target.right],
				result: target,
				name: Laws.disjunctiveAddition
			),
			if (target.isPositive) Law(
				basis: null,
				operands: [Conditional(target.left.negate(), target.right)],
				result: target,
				name: Laws.conditionalNormalization,
			),
			if (target.isPositive) Law(
				basis: null,
				operands: [Conditional(target.right.negate(), target.left)],
				result: target,
				name: Laws.conditionalNormalization,
			),
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

const debug = [
	Disjunction(Symbol("s"), Symbol("r")),
	Conditional(Symbol("s", isPositive: false), Symbol("r")),
	Conditional(Symbol("s", isPositive: false), Symbol("p")),
	Conditional(Symbol("s", isPositive: false), Symbol("q", isPositive: false)),
	Conditional(Symbol("q", isPositive: false), Symbol("p")),
	Conditional(Symbol("p", isPositive: false), Symbol("q")),
	Disjunction(Symbol("p"), Symbol("q")),



];

bool recurse(
	List<Law> givens,  // already proven for sure 
	Premise toProve,  // what we're trying to prove
	List<Law> proven,  // premises proven on this branch of the proof
	List<Premise> stack,  // a "stack trace" of what we're trying to prove
	{int debugLevel = 1}  // makes debugging easier
) {
	// if (debugLevel > 15) return false;
	// final bool verbose = debug.contains(toProve);
	final bool verbose = true;
	if (verbose) 
		print("\n[$debugLevel] Finding $toProve, $stack");

	if (stack.contains(toProve)) {
		if (verbose) print("[$debugLevel] Stuck in a cycle.\n");
		return false;  // cycle
	}

	// Check for possible paths in the proof
	final List<Law> possibleSteps = [];
	for (final Law step in givens + proven) {
		final Premise premise = step.result;
		if (verbose) print("[$debugLevel]- Considering $premise");
		if (verbose && premise == toProve) print("[$debugLevel]  Found as a given");
		if (premise == toProve) return true;
		final Law? law = premise.getLaw(toProve);
		if (law == null || givens.contains(law) || proven.contains(law)) continue;
		possibleSteps.add(law);
	}

	// Try to construct the premise 
	final List<Law> construction = constructPremise(
		toProve, givens + proven
	) ?? [];
	possibleSteps.addAll(construction);

	// Check for any steps that indicate we're done
	// 
	// Do this before going any further to prevent extra work
	for (final Law step in possibleSteps) {
		final List<Premise> operands = step.operands;
		if (operands.isNotEmpty) continue;
		if (verbose) print("[$debugLevel]  Dependency found as a given");
		proven.add(step);
		return true;
	}

	// Recurse through all possible remaining paths
	for (final Law step in possibleSteps) {
		final List<Premise> operands = step.operands;
		if (operands.isEmpty) continue;  // handled above
		final List<Law> restOfProof = [];
		bool canProveOperands = true;
		if (verbose) print("[$debugLevel]  Found: $step");
		for (final Premise operand in operands) {
			final List<Law> operandProof = [];
			if (verbose) print("[$debugLevel]    Need to prove $operand");
			final bool isProvable = recurse(
				givens + proven, 
				operand, 
				operandProof, 
				stack + [toProve],
				debugLevel: debugLevel + 1,
			);
			if (!isProvable) {
				if (verbose) print("[$debugLevel]      Didn't work");
				canProveOperands = false;
				restOfProof.clear();
				break;
			}
			restOfProof.addAll(operandProof);
		}
		if (!canProveOperands) continue;
		proven..addAll(restOfProof)..add(step);
		if (step.result == toProve) return true;
		if (verbose) print("[$debugLevel]  Tried to prove $toProve, ended up with ${step.result}");
		final List<Law> continuation = [];
		final bool isProvable = recurse(
			givens + proven, 
			toProve, continuation, stack + [step.result],
			// toProve, continuation, stack + [toProve],
			debugLevel: debugLevel + 1
		);
		if (isProvable) {
			proven.addAll(continuation);
			return true;
		}
	}
	if (verbose) print("[$debugLevel] Cannot prove $toProve");
	return false;  // unprovable
}

Proof prove(List<Premise> premises, Premise target) {
	final List<Law> givens = [
		for (final Premise given in premises)  
			Law(basis: given, operands: [], result: given, name: Laws.given),
	];
	final List<Law> derived = [];
	for (final Law given in givens) {
		final Law? normal = given.result.normalize();
		if (normal != null) {
			derived.add(normal);
		}
	}

	final bool isProvable = recurse(givens, target, derived, []);
	if (!isProvable) throw StateError("Cannot prove: $target");
	// keep the order and remove duplicates
	else return LinkedHashSet.of(givens + derived).toList();  
}
