// ignore_for_file: avoid_print

import "dart:collection";

import "laws.dart";
import "premises.dart";

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
			Law(
				basis: null,
				operands: [target.left, target.right],
				result: target,
				name: Laws.conjunctiveAddition,
			),
		];
	} 
}

const debug = [Disjunction(Symbol("s"), Symbol("r")), Conditional(Symbol("s", isPositive: false), Symbol("r"))];

bool recurse(
	List<Law> givens,  // already proven for sure 
	Premise toProve,  // what we're trying to prove
	List<Law> proven,  // premises proven on this branch of the proof
	List<Premise> stack,  // a "stack trace" of what we're trying to prove
) {
	final bool verbose = debug.contains(toProve);
	if (verbose) print("\nFinding $toProve. Stack = $stack");
	if (stack.contains(toProve)) {
		if (verbose) print("  Stuck in a cycle.");
		return false;  // cycle
	}

	// Check for possible paths in the proof
	final List<Law> possibleSteps = [];
	for (final Law step in givens + proven) {
		final Premise premise = step.result;
		if (premise == toProve) return true;
		if (verbose) {
		}
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
		proven.add(step);
		return true;
	}

	// Recurse through all possible remaining paths
	for (final Law step in possibleSteps) {
		final List<Premise> operands = step.operands;
		if (operands.isEmpty) continue;  // handled above
		final List<Law> restOfProof = [];
		bool canProveOperands = true;
		if (verbose) print("  Found: $step");
		for (final Premise operand in operands) {
			final List<Law> operandProof = [];
			if (verbose) print("    Need to prove $operand");
			final bool isProvable = recurse(
				givens + proven, 
				operand, 
				operandProof, 
				stack + [toProve]
			);
			if (!isProvable) {
				canProveOperands = false;
				restOfProof.clear();
				break;
			}
			restOfProof.addAll(operandProof);
		}
		if (!canProveOperands) continue;
		proven..addAll(restOfProof)..add(step);
		if (step.result == toProve) return true;
		final List<Law> continuation = [];
		final bool isProvable = recurse(
			givens + proven, 
			toProve, continuation, stack + [step.result],
		);
		if (isProvable) {
			proven.addAll(continuation);
			return true;
		}
	}
	if (verbose) print("Cannot prove $toProve");
	return false;  // unprovable
}

List<Law> prove(List<Premise> premises, Premise target) {
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
	else return LinkedHashSet.of(givens + derived).toList();  // keeps order
}
