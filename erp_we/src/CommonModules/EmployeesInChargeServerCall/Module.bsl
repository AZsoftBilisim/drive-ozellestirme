
#Region Public

// Returns a table of responsible persons formed according to a random selection.
//
// Parameters:
//  Filter - Structure of KeyAndValue - structure containing data selection parameters of the Catalog of Responsible Organizations:
//		* Key - String - name of the reference list's details
//		* Value - Arbitrary - the value for selection as the key
//	AllowedMarkedForDeletion - Boolean - output items marked for deletion to the result table.
//	SearchString - String - Search string. Optional.
//	
// Returns:
//	ValueTable - contains columns:
//		* Ref - CatalogRef.PersonsResponsibleAndCompanies - 
//		* Owner - CatalogRef.Companies - 
//		* EmployeeInCharge_ - EnumRef.PersonsResponsibleAndCompanies -
//		* Individual - CatalogRef.Persons - 
//		* JobTitle - String -
//		* SignatureRight - Boolean - 
//		* SignatureRightBasis - String -
//		* StartDate - Date -
//		* EndDate - Date -
//		* SignatureRightDocument - String - 
//		* NumberOfSignatureRightDocument - String - 
//		* DateOfDocumentSignatureRight - Date -
//
Function GetTableOfResponsiblePersonsForSelection(Val Filter, AllowedMarkedForDeletion = False, SearchString = "") Export
	
	Return ResponsiblePersonsServer.GetTableOfResponsiblePersonsForSelection(Filter, AllowedMarkedForDeletion, SearchString);
	
EndFunction

#EndRegion
