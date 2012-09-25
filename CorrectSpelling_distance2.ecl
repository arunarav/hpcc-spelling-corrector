/*
The following sample implements Peter Norvig's spelling corrector. This version computes the corrected spelling
at a distance of 2.

This sample assumes that the alphabet, incorrectly spelled word and the dictionary are all in UPPER case.

*/

import std;

spellCheckRec := RECORD
            string word;
END;

dictionaryDS := DATASET('~sentilyze::hpcc::lexicon',spellCheckRec,CSV);

wordCountRec := RECORD
            string word := dictionaryDS.word; 
            integer count_wrd := COUNT(GROUP);
END;

/* 

We need to train a probability model (per Norvig fancy way of saying we count how many times each word occurs).
This table operation gives us the count for each word. 

*/

dictWordsWithCount := TABLE(dictionaryDS,wordCountRec,word, UNSORTED, LOCAL);

output(dictWordsWithCount);

/*
The 'edits' function enumerates the possible corrections c of a given word w at a distance of one.
To find further distances (eg distance of 2), invoke the edits recursively.

There are 4 possible corrections:
            (a)deletion
            (b)transposition
            (c)replacement
            (d)insertion

*/
edits(string OrigWrd) := FUNCTION

            // We define a record set for the word that has to be corrected
            originalWordRec := RECORD
                        string word;
            END;


            // ECL has an elegant feature of referring to the data that is passed to the function
            test := dataset([{OrigWrd}],originalWordRec);


            originalWordRec delete_one_letter(originalWordRec Le, unsigned4 c) := TRANSFORM
                                                SELF.word := Le.word[1..c-1] + le.word[c+1..];
            END;

            // Expect n deletions
            delete_result := normalize(test, length(left.word), delete_one_letter(LEFT,COUNTER)); 

            originalWordRec transpose_one_letter(originalWordRec Le, unsigned4 c) := TRANSFORM
                        SELF.word := Le.word[1..c-1] + le.word[c+1..c+1] + le.word[c..c] + le.word[c+2..];
            END;

            transpose_result := normalize(test, length(left.word)-1, transpose_one_letter(LEFT,COUNTER));

            /* Recordset to contain list of alphabets  26 letters (a - z) */
            alphabet_RS := RECORD
                        string letter;
            END;

            alphabet := DATASET('~sentilyze::hpcc::alphabet',alphabet_RS,CSV);

            testRecWithSetOfStrings := RECORD
                                    DATASET(recordof(test)) aBunchOfWords;
            END;

            /*
                        For inserts, we need a nested loop - hence we PROJECT (for the alphabet) and subsequently NORMALIZE
               over the length of the word.
            
            */

            recordof(test)  transformForReplace(alphabet_RS alphabet, integer C, STRING word, integer N) := TRANSFORM 
                                                                                                                        self.word := MAP(C=1 => alphabet.letter + word [2..],
                                                                                                                                                                                                                        C=N => word[1..N-1] + alphabet.letter,  
                                                                                                                                                                                                                        word[1..C-1] + alphabet.letter + word[C+1..]);
            END;

            testRecWithSetOfStrings  replaceWordWithAlphabetLetter(originalWordRec L) := TRANSFORM 
                                    Len := LENGTH(TRIM(L.word));
                                    SELF.aBunchOfWords := NORMALIZE(alphabet , Len, transformForReplace(LEFT,COUNTER,L.word,Len)); 
            END;

            result_of_replace := PROJECT(test,replaceWordWithAlphabetLetter(LEFT));
            Words_as_replaced := result_of_replace.aBunchOfWords;

		/*
                        For inserts, we need a nested loop - hence we PROJECT (for the alphabet) and subsequently NORMALIZE
               over the length of the word plus one. The reason we need the 'plus one' is because we are inserting
              a letter from the alphabet [A-Z] as the last letter in the word.
            
            */
            recordof(test)  transformForInsert(alphabet_RS alphabet, integer C, STRING word, integer N) := TRANSFORM 
                                                            self.word := MAP(C=1 => alphabet.letter + word [1..],
                                                                                                                                                            C=N+1 => word[1..N] + alphabet.letter,  
                                                                                                                                                            word[1..C-1] + alphabet.letter + word[c..]);
                                                                                                                                                                                                                                    
            END;

            testRecWithSetOfStrings  insertAlphabetLetter(originalWordRec L) := TRANSFORM 
                                                                        Len := LENGTH(TRIM(L.word));
                                                                        SELF.aBunchOfWords := NORMALIZE(alphabet , Len+1, transformForInsert(LEFT,COUNTER,L.word,Len)); 
            END;

            result_of_insert := PROJECT(test,insertAlphabetLetter(LEFT));
            Words_as_inserted := result_of_insert.aBunchOfWords;

// For a word of length n, there will be n deletions, n-1 transpositions, 26n replacement, and 26(n+1) insertions
            distance_of_one := delete_result  +  transpose_result  + Words_as_replaced + Words_as_inserted;
            return distance_of_one;
END;


correctTheSpelling(string given_word) := FUNCTION

            originalWordRec := RECORD
                        string word;
            END;

            wordToBeCorrected := dataset([{given_word}],originalWordRec);
            
            // Invoke the edits function to obtain a recordset of candidate words within a distance of one
            candidateWordsWithDistanceOfOne := edits(given_word);
            
            /*

                                    The matched_wrd recordset contains this:

                                    COR    1
                                    FOR    5995
                                    NOR    248
                                    OR      5024
                                    WAR   617
                                    WOE   1
                                    WON   26
                                    WORD            288
                                    WORE            56
                                    WORK            339
                                    WORM            3
                                    WORN            58

            */

            // This join is taking atleast 15 seconds on the single node virtual machine - how do we speed this up?
            matched_wrd := JOIN(dictWordsWithCount, candidateWordsWithDistanceOfOne, LEFT.word= RIGHT.word);
            
            // Clarification: If NOSORT is included, the number of matched words is exactly one. Why is NOSORT interfering with the
            // functionality of the resultset?
            //matched_wrd := JOIN(dictWordsWithCount, candidateWordsWithDistanceOfOne, LEFT.word= RIGHT.word, NOSORT);
            
            
            // Determine how many candidates were found
            Count_matched_wrd := COUNT(matched_wrd); 
            
            /*
            If multiple words were found, determine the word with the highest occurence. If the candidates have equal counts, the first word
  as it appears in the dictionary will be returned.
            
            */
            wordAndCountWithHighestOccurence := if( Count_matched_wrd > 1,matched_wrd(count_wrd = MAX(matched_wrd,count_wrd)),matched_wrd);
            
            
            wordWithDistanceOfOne := TABLE(wordAndCountWithHighestOccurence,{word});
						
						
						
			testRecWithSetOfStringsDist2 := RECORD 
						DATASET(recordof(candidateWordsWithDistanceOfOne)) aBunchDist2Words;
			END;
			
			
			testRecWithSetOfStringsDist2 transformDistance2(candidateWordsWithDistanceOfOne L) := transform
							self.aBunchDist2Words := edits(L.word);
			END;
			
			candidateWordsWithDistanceOfTwo := PROJECT(candidateWordsWithDistanceOfOne,transformDistance2(LEFT));
			
			candidateWordsWithDistOfTwoFinal := candidateWordsWithDistanceOfTwo.aBunchDist2Words;
			
			

			Matched_wrd_dist2 := JOIN(dictWordsWithCount, candidateWordsWithDistOfTwoFinal, LEFT.word = 	RIGHT.word);
			Count_matched_wrd_dist2 := COUNT(Matched_wrd_dist2);

			wordAndCountWithHighestOccurenceForDist2 := IF( Count_matched_wrd_dist2 > 1,Matched_wrd_dist2(count_wrd = MAX(Matched_wrd_dist2,count_wrd)),Matched_wrd_dist2);
			
			wordWithDistanceOfTwo := TABLE(wordAndCountWithHighestOccurenceForDist2,{word});


			return wordWithDistanceOfTwo;

END;


// Invoke the function and pass the wrongly spelled word
Spelling_Check := correctTheSpelling('INTRODUTON');


output(Spelling_Check,NAMED('Spelling_Corrector_Results'));
