hpcc-spelling-corrector
=======================

Implements Peter Norvig's spelling corrector. This initial version computes the corrected spelling at a distance of 1.

Assumes that the alphabet, incorrectly spelled word and the dictionary are all in UPPER case.

Further refactoring todo:
(1) Optimize the join - currently this is taking 10-20 seconds on a single node virtual machine
(2) Distance of 2
(3) Handle the situation where the word passed by the user is indeed a correctly spelled word.


Source Code
=============
ECL Source file: CorrectSpelling.ec

Data files (both in the 'data' folder):

	(1) alphabet - Spray this file to '~spellcheck::hpcc::lexicon'
	(2) lexicon - Spray this file to '~spellcheck::hpcc::alphabet'