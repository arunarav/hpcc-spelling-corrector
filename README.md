Spelling Corrector on HPCC/ ECL
=================================

Implements Peter Norvig's spelling corrector (see norvig.com/spell-correct.html)

Source Code
=============
ECL Source file: 

* CorrectSpelling.ecl

Data files (both in the 'data' folder):

* alphabet - Spray this file to '~spellcheck::hpcc::lexicon'
* lexicon - Spray this file to '~spellcheck::hpcc::alphabet'
    
Notes:

* Assumes that the alphabet, incorrectly spelled word and the dictionary are all in UPPER case.

Further refactoring to do:
    
    (1) Optimize the table operation - currently takes 2+ seconds even if the operation is marked as "UNSORTED".
    
    (2) Handle the situation where the word passed by the user is indeed a correctly spelled word. 
