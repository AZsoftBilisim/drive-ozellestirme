#Region Public

// Returns an array of collection elements based on an array of form table IDs.
//
// Parameters:
//  FormData1 - FormDataCollection - collection of the row which you want to
//  Rows - Array - row IDs (the selected row property of the form table).
//
// Returns:
//  Array - collection strings.
//
Function CollectionItems(FormData1, Rows) Export
	
	SelectedItems = New Array;
	For Each RowID In Rows Do
		CollectionItem = FormData1.FindByID(RowID);
		If CollectionItem <> Undefined Then
			SelectedItems.Add(CollectionItem);
		EndIf;
	EndDo;
	Return SelectedItems;
	
EndFunction

#Region StringCaching

// Returns a row stored in the cache on the form for the specified table.
// Before using it, you need to make a one-time call to work with different Parts.Initializereadwritelock().
//
// Parameters:
//  FormTable - FormTable - a form element that contains the table part.
//  Form - ClientApplicationForm - the original form.
//
// Returns:
//  FixedStructure - cached table row.
//
Function LineCache(FormTable, Form) Export
	
	Return Form.CachedLines[FormTable.Name];
	
EndFunction

#EndRegion

#EndRegion