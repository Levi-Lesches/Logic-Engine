import "dart:collection";

import "laws.dart";
import "premises.dart";

class Proof {
	final List<Law> derived, stack;
	final Premise toProve;
	final bool verbose;
	final String debugPrefix;

	const Proof({
		required this.derived, 
		required this.stack,
		required this.toProve,
		this.verbose = false,
	}) : debugPrefix = "  " * stack.length;

	/// Find all possible ways to arrive at [toProve].
	/// 
	/// Returns null if [toProve] has already been derived.
	List<Law>? findPaths() {
		final List<Law> result = [];
		for (final Law step in derived) {
			final Premise premise = step.result;
			if (premise == toProve) return null;
			final Law? law = premise.getLaw(toProve);
			if (law != null) result.add(law);
		}
		result.addAll(constructPremise(toProve, derived) ?? []);
		return result;
	}

	/// Logs an indented message to help debug [recurse].
	void log(String message) {
		if (verbose) print(debugPrefix + message);  // ignore: avoid_print
	}

	/// Tests a branch of a proof and returns the result.
	/// 
	/// Returns the completed proof, or null if the branch is unprovable. 
	List<Law>? expandPath(Law path) {
		log("Trying $path");
		final List<Law> result = [];

		// Test whether this path is viable
		for (final Premise operand in path.operands) {
			final List<Law>? subProof = Proof(
				derived: derived, toProve: operand,
				stack: stack + [path], verbose: verbose,
			).recurse();
			if (subProof == null) return null;
			result.addAll(subProof);
		}

		// Return the path
		result.add(path);  // all requirements satisfied
		if (path.result == toProve) return result;

		// Cycle back if needed
		log("Tried to prove $toProve, got ${path.result}");
		final List<Law>? sidebar = Proof(
			derived: derived + result, toProve: toProve,
			stack: stack, verbose: verbose,
		).recurse();
		if (sidebar != null) return result + sidebar;
	}

	/// Tries every possible branch of the proof and returns one that works. 
	List<Law>? recurse() {
		log("Trying to find $toProve");
		if (stack.any((law) => law.result == toProve)) return null;
		final List<Law>? paths = findPaths();
		if (paths == null) return [];
		for (final Law path in paths) {
			if (derived.contains(path)) continue;
			final List<Law>? subProof = expandPath(path);
			if (subProof != null) return subProof;
		}
	}
}

/// Proves a premise from a list of givens.
/// 
/// A convenience wrapper around [Proof].
List<Law> prove({
	required List<Premise> givens, 
	required Premise toProve, 
	bool verbose = false,
}) {
	final List<Law> derived = [
		for (final Premise given in givens) Law.given(given),
		for (final Premise given in givens)
			if (given.canBeNormalized) given.normalize()!
	];
	final List<Law>? proof = Proof(
		derived: derived,
		toProve: toProve,
		stack: [],
		verbose: verbose,
	).recurse();
	if (proof == null) throw StateError("Cannot prove $toProve");
	else return LinkedHashSet.of(derived + proof).toList();
}