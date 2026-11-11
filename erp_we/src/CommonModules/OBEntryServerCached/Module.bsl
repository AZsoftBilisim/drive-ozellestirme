#Region Internal

// Returns the available types of input residues
// 
// Returns:
// 	Array - Available types of balance input
//
Function AvailableTypesOfResidueInput() Export
	Return OBEntryServer.PrepareAvailableDocumentTypes();
EndFunction

// Returns descriptions of sections and business operations for entering balances.
// 
// Returns:
// 	ValueTable - Description: a table of values containing a description of business operations for entering Balances:
// * AccountingSection - String  - Text representation of the accounting section 
// * BusinessOperation - EnumRef.BusinessTransactions - the value of the economic operation of entering Balances
// * ExplanationOfAccountingSection - String - textual representation of the description of the business operation of entering Balances 
// * OrderInTree        - Number - hierarchy of business operations in the Balance entry tree 
// * InputAvailability      - Boolean - allows or disables the entry of a Balance entry document
// * BalanceInputDocument - CatalogRef.MetadataObjectIDs - id of the Balance entry document
// * DocumentHeaderTemplate - String - The template used to create the document view.
// 
Function DescriptionOfBalanceEntrySections() Export
	Return OBEntryServer.DescriptionOfBalanceEntrySections();
EndFunction
	
#EndRegion