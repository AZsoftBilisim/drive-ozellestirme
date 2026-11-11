////////////////////////////////////////////////////////////////////////////////
// The module contains procedures and functions for the user
// to work with document logs.
//
////////////////////////////////////////////////////////////////////////////////

#Region Public

// Search for the Cur row data in the list.
// 
// Parameters:
//  DocumentReference - DocumentRef - link to the document
//  KeyStructure1 - Structure of String - Key structure
//  ListKeys - Map of String -List Keys
Procedure FindDataOfCurrentLineInList(DocumentReference, KeyStructure1, ListKeys) Export
	
	Query = New Query;
	Query.Text = "
	|SELECT
	|	DocumentsRegistry.RefType AS RefType,
	|	DocumentsRegistry.BusinessOperation AS BusinessOperation,
	|	DocumentsRegistry.IBDocumentDate AS IBDocumentDate
	|FROM
	|	InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|WHERE
	|	DocumentsRegistry.Ref = &Ref
	|	AND DocumentsRegistry.RecordID = &RecordID";
	Query.SetParameter("Ref", DocumentReference);
	Query.SetParameter("RecordID", KeyStructure1.RecordID);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	If Selection.Next() Then
		KeyStructure1.Insert(ListKeys.Get("Date"), Selection.IBDocumentDate);
		KeyStructure1.Insert(ListKeys.Get("RefType"), Selection.RefType);
		KeyStructure1.Insert(ListKeys.Get("BusinessOperation"), Selection.BusinessOperation);
	EndIf;
	
EndProcedure

// Saving the settings of the productive list update mode.
// 
// Parameters:
//  ProductiveUpdateMode - Boolean -List acceleration mode is enabled
Procedure SaveSettingProductiveListUpdateMode(ProductiveUpdateMode) Export

	KeysForSavedSettings = OperationsWithDocumentJournals.KeysForSavedSettingsProductiveListUpdateMode();
	Common.CommonSettingsStorageSave(KeysForSavedSettings.ObjectKey,
		KeysForSavedSettings.SettingsKey, ProductiveUpdateMode);

EndProcedure

#EndRegion