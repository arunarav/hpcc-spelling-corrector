Spelling Corrector on HPCC/ ECL
=================================

Implements Peter Norvig's spelling corrector (see norvig.com/spell-correct.html)

Source Code
=============
ECL Source file: 

* CorrectSpelling.ecl (Corrects the spelling with a distance of 1 - eg. 'introductin' would be corrected as 'introduction')
* CorrectSpelling_distance2.ecl (Corrects the spelling with a distance of 2 - eg. 'introdctin' would be corrected as 'introduction')

Data files (both in the 'data' folder):

* alphabet - Spray this file to '~spellcheck::hpcc::lexicon'
* lexicon - Spray this file to '~spellcheck::hpcc::alphabet'
    
Notes:

* Assumes that the alphabet, incorrectly spelled word and the dictionary are all in UPPER case.

Further refactoring todo-
    
    (1) Optimize the lexicon table operation in 'distance 1' - currently takes 2+ seconds even if the operation is marked as "UNSORTED".
	
	(2) The PROJECT function in  'distance 2' takes 25+ seconds.
    
    (3) Handle the situation where the word passed by the user is indeed a correctly spelled word. 
