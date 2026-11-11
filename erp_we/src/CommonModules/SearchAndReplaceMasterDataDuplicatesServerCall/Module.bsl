#Region Private

Procedure AddDuplicates(References) Export
	InformationRegisters.MasterDataDuplicatesToConfirm.AddDuplicates(References, Users.CurrentUser());
EndProcedure

// Checks whether an interactive deletion tag is available for the object.
//
// Parameters:
//   Ref - AnyRef - the object for which the right is checked.
//
// Returns:
//   Boolean - True if the interactive delete tag is available, otherwise False.
//
Function InteractiveTaggingIsAvailable(Ref) Export
	Return AccessRight("InteractiveSetDeletionMark", Ref.Metadata())
		And AccessRight("Use", Metadata.DataProcessors.DuplicateObjectsDetection);
EndFunction

// Returns the name of the main selection form for the referenced object based on its metadata.
//
// Parameters:
//   Ref - AnyRef - reference to the object for which you want to get the name of the selection form
//
// Returns:
//   String - the full name of the selection form, including the metadata path
//
Function ChoiceFormName(Ref) Export
	Return Ref.Metadata().FullName() + ".ChoiceForm";
EndFunction

// Returns the ID of the duplicate group for the specified object.
//
// Parameters:
//   Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef - the object that the duplicate group is being searched for.
//
// Returns:
//   String - ID of the duplicate group that the transferred object belongs to.
//
Function DuplicateGroup(Duplicate1) Export
	
	Selection = InformationRegisters.MasterDataDuplicatesToConfirm.ExistingDuplicates(Duplicate1);
	Selection.Next();
	
	Return Selection.DuplicatesGroup;
	
EndFunction 

#EndRegion