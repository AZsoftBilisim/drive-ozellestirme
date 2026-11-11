///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Public

// On get number for printing event handler.
// The event occurs before standard processing of getting a number.
// The handler can override the default application behavior upon getting a number for printing.
//
// Parameters:
//  ObjectNumber                     - String - an object number or code being processed.
//  StandardProcessing             - Boolean - standard processing flag, if the flag value is set to False,
//                                              the standard processing of generating a number for printing
//                                              will not be executed.
//  DeleteInfobasePrefix - Boolean - shows whether an infobase prefix is to be removed.
//                                              By default, it is equal to False.
//  DeleteCustomPrefix   - Boolean - shows whether a custom prefix is to be removed.
//                                              By default, it is equal to False.
//
// Example:
//
//   ObjectNumber = ObjectsPrefixesClientServer.DeleteCustomPrefixesFromObjectNumber(ObjectNumber);
//   StandardProcessing = False.
//
Procedure OnGetNumberForPrinting(ObjectNumber, StandardProcessing,
	DeleteInfobasePrefix, DeleteCustomPrefix) Export
	// If the document number does not contain a "-", then remove all prefixes from the number.
	PositionMinus = Find(ObjectNumber, "-");
	If PositionMinus = 0 Then
		
		StandardProcessing = False;
	
		// Removing all character prefixes.
		While Find("0123456789", Left(ObjectNumber, 1)) = 0 Do
			ObjectNumber = Mid(ObjectNumber, 2);
		EndDo;
		
		// We remove the leading zeros on the left in the number.
		ObjectNumber = StringFunctionsClientServer.DeleteDuplicateChars(ObjectNumber, "0");
		
	EndIf;
EndProcedure

#EndRegion
