
#Region Public

#Region Fiscalization


#EndRegion

//Supplements the passed array of allowed types for crediting payments with gift certificates.
//
// Parameters:
//  Allowed_Types - Array of DocumentRef, CatalogRef - Types of allowed links to check.
//
Procedure AddAllowedTypesForCreditingPaymentsWithGiftCertificates(Allowed_Types) Export
	Allowed_Types.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	Allowed_Types.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));

EndProcedure

// Checks that the transmitted type belongs to the types of documents in the billing scheme.
//
// Parameters:
//  DocumentType - Type - the type being checked.
//
// Returns:
//  Boolean -
Function TypeRefersToDocumentsOfTollingScheme(DocumentType) Export
	Result = False;
	
	If DocumentType = Type("DocumentRef.MaterialProviderOrder2_5")
			Or DocumentType = Type("DocumentRef.ReportToMaterialProvider2_5") Then
		Result = True;
	EndIf;
	
	
	Return Result;
EndFunction

#EndRegion

#Region Internal

// Code of procedures and functions


#EndRegion

#Region Private

// Code of procedures and functions

#EndRegion
