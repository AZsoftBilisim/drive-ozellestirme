#Region Public

#Region AttachableCommands

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	Return;
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	Return;
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	Return;
EndProcedure

#EndRegion

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	
EndProcedure

#EndRegion
#Region RegAccountingTransactions

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - The text of the reflection request in the regl. accounting.
//
Function TextOfReflectionInLocalAccounting() Export
	
	//@skip-check bsl-legacy-check-method-for-statements-after-return
	Return "";
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export
	
	//@skip-check bsl-legacy-check-method-for-statements-after-return
	Return "";
	
EndFunction
#EndRegion
#EndRegion

#Region Internal

#Region EventHandlers

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - the document being processed.
//  Cancel - Boolean - Indicates whether the document is being processed.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the document will not be processed.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure Posting(Object, Cancel, PostingMode) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - processed object
//  Cancel - Boolean - If this parameter is set to True in the body of the handler procedure,
//                   it will refuse to continue working after completing the fill check.
//  CheckedAttributes - Array of String - Array of paths to the details to be checked for.
//
Procedure FillCheckProcessing(Object, Cancel, CheckedAttributes) Export
	
	
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - The object being processed.
//  FillingData - Arbitrary - The value that is used as the basis for filling in.
//  StandardProcessing - Boolean - This parameter is passed to indicate that standard (system) event processing is performed.
//
Procedure Filling(Object, FillingData, StandardProcessing) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//
Procedure UndoPosting(Object, Cancel) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure,
//                   the record will not be executed and an exception will be thrown.
//  WriteMode - DocumentWriteMode - The current document recording mode is passed to the parameter. Allows you to define the recording mode in the procedure body.
//  PostingMode - DocumentPostingMode - this parameter is passed to the current mode of the event.
//
Procedure BeforeWrite(Object, Cancel, WriteMode, PostingMode) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - processed object
//  Cancel - Boolean - Indicates that the recording was rejected.
//                   If this parameter is set to True in the body of the handler procedure, the record will not be executed and an exception will be thrown.
//
Procedure OnWrite(Object, Cancel) Export
EndProcedure

// Called from the corresponding document handler
//
// Parameters:
//  Object - DocumentObject.VATAllocation - processed object
//  CopiedObject - DocumentObject.VATAllocation - The source document that is the copy source.
//
Procedure OnCopy(Object, CopiedObject) Export
EndProcedure

#EndRegion

Procedure SupplementComplianceOfRevenueDetailsWithVATTaxation(MatchingBankDetails) Export
EndProcedure

Procedure SupplementComplianceOfExpenditureAnalystItemsWithVATTaxation(MatchingBankDetails) Export
EndProcedure

// LongDesc
// 
// Parameters:
// 	ItemsAndDimensionsSelectionParameters - Array of See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions -
// 	Object - FormDataStructure -
// 	ItIsNecessaryToDistributeVATOnGoods - Boolean -
Procedure AddOptionsForSelectingArticlesAndAnalytics(ItemsAndDimensionsSelectionParameters, Object, ItIsNecessaryToDistributeVATOnGoods) Export
	
	#Region ExpenceItemUTII
	// The code is left temporarily, until the details are deleted
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath =    "Object";
	ChoiceParameters.AssetRef = "ExpenceItemUTII";
	ChoiceParameters.HideArticleThatIsUnavailableDueToOperation = False;
	ItSEndOfBlock = (Month(Object.Date)%3 = 0);
	ChoiceParameters.AvailabilityByOperation = 
		(ItIsNecessaryToDistributeVATOnGoods
		Or Not Object.WriteOffVATByExpensesAndAssetsToRecordItems)
		And GetFunctionalOption("UTIIPayer");
	
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "VATDebitingDimensionBySalesSubjectToUTIIActivityType";
	
	ChoiceParameters.FormItems.AssetRef.Add("UTIICostItem");
	
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("VATDebitingDimensionBySalesSubjectToUTIIActivityType");
	
	ItemsAndDimensionsSelectionParameters.Add(ChoiceParameters);
	#EndRegion
	
EndProcedure

Procedure AdjustingBaseByRowToDistribution(BasisOfDistributionByLine, RowToDistribution, Apply5PecentRule) Export
	
	
EndProcedure

// To assign the parts to other expenses on the basis of
// 
// Parameters:
// 	DistributionTables - Map of EnumRef.VATTaxationTypes, ValueTable -
// 	Attributes - Structure - It consists, among other things, of:
//		* Ref - DocumentRef -
Procedure DistributeNdskBatchesByBaseDistribution(DistributionTables, Attributes) Export
	
	
EndProcedure

// Calculates how much VAT needs to be restored and written off to otherexpenses when changing the type of activity from taxable to 
// non-taxable or distributable, if the deduction was previously claimed.
// 
// Parameters:
// 	DistributionTables - Map of EnumRef.VATTaxationTypes, ValueTable -
// 	DataForDistribution - Structure of ValueTable - 
// 	Attributes - Structure - It consists, among other things, of:
//		* Ref - DocumentRef -
Procedure CalculateRecoveryOfNDSIWriteOffForExpenses(DistributionTables, DataForDistribution, Attributes) Export
	
	
EndProcedure

// Distribute non-current assets for the export of commodities and services
// 
// Parameters:
// 	DistributionTables - Map of EnumRef.VATTaxationTypes, ValueTable -
Procedure DistributeNonCurrentAssetsExportOfCommoditiesAndServices(DistributionTables) Export
	
	
EndProcedure

Procedure AllocateToEmptyImplementationForAcceptanceToDeduction(DistributionTables) Export
	
	
EndProcedure

// Overrides the beginning of the data collection period from which VAT distribution is performed
// 
// Parameters:
// 	BeginOfPeriod - Date - Parameter to set the start date to
//	Date - Date - Date of distribution of the VAT
// 	Organization - CatalogRef.Companies - Organization of the distribution of VAT
//
Procedure SetStartOfPeriod(BeginOfPeriod, Val Date, Val Organization) Export

	
EndProcedure

// Gets revenue data to fill in the VAT database.
//
// Parameters:
// 	RevenueData - Structure - Parameter in which revenue data is returned. A structure with two keys:
// 	                            * RevenueFromVATTaxation - ValueTable - Table of values with columns:
// 	                            	* VATTaxation - EnumRef.VATTaxationTypes - VATTaxation
// 	                            	* Revenue - Number - Revenue value				
// 	                            * DocumentsExport - ValueTable - Table of revenue by export sales
// 	                            	* Document - DocumentRef - Document export
// 	                            	* RevenueAmount - Number - Revenue value
// 	                            	* RevenueAdjustment - Number - Value adjustments to revenue 
//	Date - Date - Date of distribution of the VAT
//	BeginOfPeriod - Date - Start of the period for which VAT is distributed
//  Organization - CatalogRef.Companies - Organization of the distribution of VAT
// 	AdditionalRevenueGenerationParameters - Undefined, Structure - Additional parameters for receiving revenue.
//                                 
Procedure GetRevenueData(RevenueData, Date, BeginOfPeriod, Organization, AdditionalRevenueGenerationParameters) Export
	
	
EndProcedure

// Initialisere Taobaotrends containing the objects, accepted for accounting.
//
// Parameters:
// 	TempTablesManager - TempTablesManager - Manager to initialize the table in
//	Attributes - Structure - The details of the document (See Documents.VATAllocation.GetDocumentData)
// 
Procedure InitializeTTNonCurrentAssets(TempTablesManager, Attributes) Export
	
		
EndProcedure

// Complements the table of movements of the distribution of VAT
//
// Parameters:
//	TablesForRegisteredRecords - Structure - Table of movements of the document
//	DataForDistribution - Structure - Source data for distribution
//	AllocationResult - Structure - The result of the distribution
//	Attributes - Structure - The details of the document (See Documents.VATAllocation.GetDocumentData)
//	Registers - Undefined, Array, Structure - The registers that must be formed
// 
Procedure FormRegisteredRecords(TablesForRegisteredRecords, DataForDistribution, AllocationResult, Attributes, Registers) Export
EndProcedure


#EndRegion

