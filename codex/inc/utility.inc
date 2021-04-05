;;;
;;; Utility routines for the Commander 16 Assembly Language Environment
;;;
;;; Copyright 2020 Michael J. Allison
;;; License, 2-clause BSD, see license.txt in source package.
;;; 

      .psc02                    ; Enable 65c02 instructions
	   .feature labels_without_colons
	
      .ifndef __X16_UTILITY__
              __X16_UTILITY__=1

         .import util_trim_string, util_strcpy, util_strcmp, util_parse_hex
         .import util_ends_with, util_split_string, util_str_contains, util_strlen
	
      .endif