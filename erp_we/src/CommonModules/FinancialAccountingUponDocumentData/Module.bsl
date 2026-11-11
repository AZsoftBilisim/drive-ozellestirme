#Region Public

// Generates international accounting entries directly from the document data.
// 
// Parameters:
// 	ReflectionParameters - Structure - Parameters for generating transactions.
// 	TableOfTransactions - ValueTable - The table that the generated transactions are added to.
//
Procedure Reflect(ReflectionParameters, TableOfTransactions) Export
	
	
EndProcedure

// Supplements the document registration tables to reflect in international accounting according to the document itself.
// 
// Parameters:
// 	Object - DocumentObject - The document that is being held.
// 	AdditionalProperties - Structure - Additional properties of the RS are reflected in documentsinternational Accounting.
// 	RegistrationTable - ValueTable - Table with registration data for reflection:
// 	      * Period - Date - registration period (document date);
// 	      * Organization - CatalogRef.Companies - the organization for which the document generates transactions;
// 	      * DateRecord - Date - the date on which the document forms of the transaction;
// 	      * BusinessOperation - EnumRef.BusinessTransactions - of reflected economic operation.
//
Procedure AddRegistrationTablesToReflection(Object, AdditionalProperties, RegistrationTable) Export
	
	If TypeOf(Object) = Type("DocumentObject.ExchangeDifferenceCalculation")
		And RegistrationTable.Count() = 0 Then
		
		NewRow = RegistrationTable.Add();
		NewRow.Period = Object.Date;
		NewRow.Organization = Object.Organization;
		NewRow.DateRecord = Object.Date;
		NewRow.BusinessOperation = Object.BusinessOperation;
		
	EndIf;
	
EndProcedure

// Returns document types that are reflected in accounting directly from their data.
// 
// Returns:
// 	Map - Types of documents:
// 	               Key - Type - Document Type
// 	               The value is Boolean - A sign that the document is reflected only during the execution - it cannot be reflected deferred.
// 
Function TypesOfDocumentsToReflect() Export
	
	DocumentTypes = New Map;
	
	Return DocumentTypes;
	
EndFunction

#EndRegion

