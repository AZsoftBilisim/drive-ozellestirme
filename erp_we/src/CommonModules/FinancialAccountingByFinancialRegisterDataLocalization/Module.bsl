#Region Internal

// Complements the compliance of financial accounting objects with items of assets and liabilities.
// Parameters:
//  Sourcesdannyh accounting objects - See Enums.DeleteFinancialAccountingObjects.ComplianceOfFinancialAccountingObjectsWithItemsOfAssetsLiabilities
//
Procedure ToSupplementComplianceOfFinancialAccountingObjectsWithItemsOfAssetsLiabilities(ComplianceOfObjectsWithArticles) Export
	
	
EndProcedure

// Complements the correspondence of financial accounting objects and their data sources - the names of balance Accumulation registers.
// Parameters:
//  DataSourcesOfAccountingObjects - See Enums.DeleteFinancialAccountingObjects.DataSourcesOfFinancialAccountingObjects
//
Procedure SupplementDataSourcesOfFinancialAccountingObjects(DataSourcesOfAccountingObjects) Export
	
	
EndProcedure

// Adds entries to the description table of financial accounting objects.
// 
// Parameters:
// 	FinancialAccountingObjects - SeeEnums.DeleteFinancialAccountingObjects.DescriptionOfFinancialAccountingObjects
// 	TransactionSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
// 
Procedure AddDescriptionOfFinancialAccountingObjects(FinancialAccountingObjects, TransactionSettings) Export
	
	
EndProcedure

// Adds elements to match the extended description of financial accounting objects.
// 
// Parameters:
//  DescriptionOfAccountingObjectsForConfiguringForms - Map of KeyAndValue - data from the extended description of financial accounting objects:
//  	* Key - EnumRef.DeleteFinancialAccountingObjects - Object Of Financial Accounting
//  	* Value - See Enums.DeleteFinancialAccountingObjects.DescriptionOfAccountingObjectForConfiguringForms
//  GroupsOfAccountingObjects - See Enums.DeleteFinancialAccountingObjects.GroupsOfAccountingObjects
//  TransactionSettings - See Catalogs.FinancialAccountingPostingGenerationSetting.TransactionGenerationSettings
//
Procedure AddExtendedDescriptionOfAccountingItemsToConfigure(
	DescriptionOfAccountingObjectsForConfiguringForms, GroupsOfAccountingObjects, TransactionSettings) Export
	
	
EndProcedure

#EndRegion