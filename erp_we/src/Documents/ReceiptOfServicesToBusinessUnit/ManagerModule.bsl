#If Not MobileStandaloneServer Then
#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Partner, Terms";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Author, Manager";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Author";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Counterparty";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Counterparty";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("AddressWarehouse");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("PricesAndDiscounts");
	DocumentMechanisms.Add("Supply");
	DocumentMechanisms.Add("AccountingOfWorks");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("DocumentCorrection");
	
	ReceiptOfServicesToBusinessUnitLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList, Structure - Data of the document for conducting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.ReceiptOfServicesToBusinessUnit") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers);
		QueryTextTableOtherExpenses(Query, QueryTexts, Registers);
		QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers); 
		QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers);
		QueryTextTableVATInvoiced(Query, QueryTexts, Registers);
		
		ReceiptOfServicesToBusinessUnitLocalization.AddRequestTexts(Query, QueryTexts, Registers);
		
	EndIf;
	
	ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, "GoodsToReceive");
	ReflectStockDistribution(Query, QueryTexts, Registers);
	
	DocumentsPosting.AddRequestsStornow(
		Query, QueryTexts, Registers, Metadata.Documents.ReceiptOfServicesToBusinessUnit);
	CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(
		DocumentRef, Query, QueryTexts, Registers);
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export

	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	ReceiptOfServicesToBusinessUnitLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
	Documents.VendorInvoice.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Populates the list of creation commands based on.
//
// Parameters:
//   CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//   ValueTable - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
Function AddGenerateCommand(CreateCommandsBasedOn) Export
	
	If AccessRight("Insert", Metadata.Documents.ReceiptOfServicesToBusinessUnit)
		And GetFunctionalOption("UseUninvoicedDeliveries") Then
		
		CreateBasedOnCommand = CreateCommandsBasedOn.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.ReceiptOfServicesToBusinessUnit.FullName();
		CreateBasedOnCommand.Id = Metadata.Documents.ReceiptOfServicesToBusinessUnit.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.ReceiptOfServicesToBusinessUnit);
		CreateBasedOnCommand.WriteMode = "Post";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	ReceiptOfServicesToBusinessUnitLocalization.AddReportCommands(ReportsCommands, Parameters);
	
EndProcedure
#Region PostingsOfReglAccounting

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export
	
	Return ReceiptOfServicesToBusinessUnitLocalization.TextOfReflectionInLocalAccounting();
	
EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//   String - the generated request text.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return ReceiptOfServicesToBusinessUnitLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#EndRegion
#Region Other
// Fills in the parameters of a request that retrieves data about business operations used in the document.
//
// Parameters:
//	QueryOptions - Structure - request parameters to initialize:
//		* BusinessTransactionsPurchasingFromSupplier				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsImportPurchase				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsProcurementInEAEUCountries			 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsAdmissionToCommission				 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsGoodsInTransit					 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsUnfacturedDeliveries		 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//		* BusinessTransactionsDoNotShareProcurementProcessing	 - Array, Undefined - array of elements with the type
//														Enum link.Economic operations.
//
Procedure FillInParametersOfBusinessOperations(QueryOptions) Export
	
	UseImportOfGoodsFromCustomsUnion = GetFunctionalOption("UseImportOfGoodsFromCustomsUnion");
	UseUninvoicedDeliveries = GetFunctionalOption("UseUninvoicedDeliveries");
	
	BusinessTransactionsPurchasingFromSupplier = New Array;
	
	If UseUninvoicedDeliveries Then
		BusinessTransactionsPurchasingFromSupplier.Add(Enums.BusinessTransactions.
			PurchaseFromVendorUninvoicedDelivery);
	EndIf;
	
	BusinessTransactionsProcurementInEAEUCountries = New Array;
	If UseImportOfGoodsFromCustomsUnion Then
		If UseUninvoicedDeliveries Then
			BusinessTransactionsProcurementInEAEUCountries.Add(
				Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		EndIf;
	EndIf;
	
	BusinessTransactionsUnfacturedDeliveries = New Array;
	If UseUninvoicedDeliveries Then
		BusinessTransactionsUnfacturedDeliveries.Add(
			Enums.BusinessTransactions.PurchaseFromVendorUninvoicedDelivery);
		
		If UseImportOfGoodsFromCustomsUnion Then
			BusinessTransactionsUnfacturedDeliveries.Add(
				Enums.BusinessTransactions.ImportFromEAEUUninvoicedDelivery);
		EndIf;
	EndIf;
	
	QueryOptions.BusinessTransactionsPurchasingFromSupplier           = BusinessTransactionsPurchasingFromSupplier;
	QueryOptions.BusinessTransactionsProcurementInEAEUCountries          = BusinessTransactionsProcurementInEAEUCountries;
	QueryOptions.BusinessTransactionsUnfacturedDeliveries    = BusinessTransactionsUnfacturedDeliveries;
	
EndProcedure

// Returns the value of the receipt or shipment order.
//
// Parameters:
//  FieldValuesToIdentifyReferences - Structure - the composition of the fields is determined by the value
//  of the field name field to determine the Distribution of parameters for specifying series in this document.
//
// Returns:
//  DocumentRef - a link to an order for performing a warehouse operation.
//
Function OrderToPerformWarehouseOperation(FieldValuesToIdentifyReferences) Export
	
	ServiceReceiptOption = FieldValuesToIdentifyReferences.ServiceReceiptOption;
	
	If Not ValueIsFilled(FieldValuesToIdentifyReferences.Terms)
		And Not ValueIsFilled(FieldValuesToIdentifyReferences.Contract) Then
		Return FieldValuesToIdentifyReferences.Ref;
	ElsIf Catalogs.TermsOfPurchaseFromVendors.AgreementIsUsedForAcceptance(ServiceReceiptOption) Then
		Return FieldValuesToIdentifyReferences.Terms;
	ElsIf Catalogs.CounterpartyContracts.AgreementIsUsedDuringAcceptance(ServiceReceiptOption) Then
		Return FieldValuesToIdentifyReferences.Contract;
	EndIf;
	
EndFunction

// The procedure for processing the document when changing the direction of activity.
// 
// Parameters:
//  Form - ClientApplicationForm
// 
// Returns:
// See LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity
//
Function ProcedureForProcessingDocumentWhenChangingDirectionOfActivity(Form) Export
	
	DocumentProcessingProcedure = LinesOfBusinessServer.ProcedureForProcessingDocumentWhenChangingDirectionOfActivity();
	DocumentProcessingProcedure.NamesOfTablePartsToCleanUpIncorrectAssignments = "Services";
	TableOfConditions = LinesOfBusinessServer.ConditionsForProcessingAssignmentsInRows("ItemsType");
	DocumentProcessingProcedure.StringProcessingConditions.Insert("Services", TableOfConditions);
	
	Return DocumentProcessingProcedure;
	
EndFunction

// Initializes parameters that serve the selection of assignments in document forms.
//
// Returns:
//	See Catalogs.Assignments.AssignmentSelectionFormTemplate.
//
Function AssignmentSelectionFormTemplate() Export
	
	FormTemplate = Catalogs.Assignments.AssignmentSelectionFormTemplate();
	
	DestinationPattern = Catalogs.Assignments.AddAppointmentTemplate(FormTemplate);
	DestinationPattern.LineOfBusiness  = "Object.LineOfBusiness";
	DestinationPattern.AssignmentTypes.Delete(DestinationPattern.AssignmentTypes.Find(Enums.AssignmentTypes.SuppliedProducts22));
	// The needs for work in the recipient department.

	DescriptionOfColumns = Catalogs.Assignments.AddColumnDescription_(FormTemplate, "FulfillOrdersWithWorks", True, "Object.Services.Purpose");
	DescriptionOfColumns.Columns.FindByValue("Demand").Check = True;
	DescriptionOfColumns.TermsOfUse_ = "Object.Services.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	DescriptionOfColumns.DataPaths.Products     = "Object.Services.Products";
	DescriptionOfColumns.DataPaths.Characteristic   = "Object.Services.Characteristic";
	DescriptionOfColumns.DataPaths.Department    = "Object.Services.Department";
	DescriptionOfColumns.DataPaths.Currency           = "Object.Currency";
	
	Return FormTemplate;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Thu';
							|ru = 'Поступление';
							|en = 'Receipt'; fa = 'دریافت';
							|it = 'Поступление';
							|pl = 'Receipt';
							|tr = 'Tahsilat'"));
	ReceiptOfServicesToBusinessUnitLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Services - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Services");
	
	Return DocumentTables;
	
EndFunction

#EndRegion

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(Partner)
	|	AND ValueAllowed(Department)";

EndProcedure

// End StandardSubsystems.AccessManagement

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#Region VATAccounting

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ReceiptOfServicesToBusinessUnit, DocumentObject.ReceiptOfServicesToBusinessUnit - 
//				document of receipt of goods to the warehouse.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the tax levy of the Purchase order().
//
Function ParametersForFillingInVATTaxationPurchases(Document) Export
	
	DocumentAttributes = New Structure("Counterparty, Contract, BusinessOperation, Date");
	
	If TypeOf(Document) = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
	FillPropertyValues(FillParameters, DocumentAttributes);
	FillParameters.Period  = DocumentAttributes.Date;
	BusinessTransactionsPurchasingFromSupplier  = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseFromSupplier);
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.ImportFromEAEU);
	BusinessTransactionsImportPurchase    = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseByImport);
	
	If BusinessTransactionsPurchasingFromSupplier.Find(DocumentAttributes.BusinessOperation) <> Undefined Then
		FillParameters.PurchaseOfGoods = True;
	ElsIf BusinessTransactionsProcurementInEAEUCountries.Find(DocumentAttributes.BusinessOperation) <> Undefined Then
		FillParameters.ImportOfGoodsFromCustomsUnion = True;
	EndIf;
	
	Return FillParameters;
	
EndFunction

// Returns parameters for filling in the VAT activity type.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.ReceiptOfServicesToBusinessUnit, DocumentObject.ReceiptOfServicesToBusinessUnit - 
//				document of receipt of goods to the warehouse.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the Activity Index().
//
Function ParametersForFillingInVATActivityType(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Contract, LineOfBusiness, Department");
	
	If TypeOf(Document) = Type("DocumentRef.ReceiptOfServicesToBusinessUnit") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATActivityType();
	FillPropertyValues(FillParameters, DocumentAttributes);
	
	BusinessTransactionsPurchasingFromSupplier = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseFromSupplier);
	
	BusinessTransactionsProcurementInEAEUCountries = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.ImportFromEAEU);
	
	BusinessTransactionsImportPurchase = PurchasesServer.BusinessOperationsOnMain(
										Enums.BusinessTransactions.PurchaseByImport);
	
	If BusinessTransactionsPurchasingFromSupplier.Find(Document.BusinessOperation) <> Undefined
		Or BusinessTransactionsProcurementInEAEUCountries.Find(Document.BusinessOperation) <> Undefined
		Or BusinessTransactionsImportPurchase.Find(Document.BusinessOperation) <> Undefined Then
		
		FillParameters.PurchaseOfGoods = True;
		
	EndIf;
	
	Return FillParameters;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "ReceiptOfServicesToBusinessUnit");
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

// Returns parameters for selecting articles in the document.
// 
// Parameters:
// 	BusinessOperation - EnumRef.BusinessTransactions - business operation of the document.
//  Contract - CatalogRef.CounterpartyContracts - Counterparty Contract
// 
// Returns:
// 	Array - Array of accounting account settings (See IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions)
//
Function ItemsAndDimensionsSelectionParameters(BusinessOperation, Contract) Export
	
	ChoiceParametersArray = New Array;
	
	#Region ServicesExpenseItem
	ChoiceParameters = IncomeAndExpensesServer.ArticleSelectionAndAnalyticsOptions();
	ChoiceParameters.DataPath = "Object.Services";
	ChoiceParameters.AssetRef = "ExpenseItem";
	ChoiceParameters.ChoosingExpenseItem = True;
	ChoiceParameters.DimensionOfExpenses = "DimensionOfExpenses";
	
	ChoiceParameters.FormItems.AssetRef.Add("ServicesExpenseItem");
	ChoiceParameters.FormItems.DimensionOfExpenses.Add("ServicesDimensionOfExpenses");
	ChoiceParameters.ArticleAvailabilityCriteriaInLines.Insert("ToExpenseAs", True);
	
	ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = Undefined;
	
	OptionForRegisteringServiceReceiptDocuments = Common.ObjectAttributeValue(Contract, "OptionForRegisteringServiceReceiptDocuments");
	
	If OptionForRegisteringServiceReceiptDocuments = Enums.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed Then
		ListOfCostAllocationOptions = New Array;
		
		For Each EnumerationValue In Enums.CostAllocationOptions Do
			If EnumerationValue = Enums.CostAllocationOptions.ToNonCurrentAssetCost Then
				Continue;
			EndIf;
			
			ListOfCostAllocationOptions.Add(EnumerationValue);
		EndDo;
		
		ChoiceParameters.SelectionOfExpenditureItems.CostAllocationOption = ListOfCostAllocationOptions;
	EndIf;
	
	ChoiceParametersArray.Add(ChoiceParameters);
	#EndRegion
	
	Return ChoiceParametersArray;
	
EndFunction

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Terms.Currency AS AgreementCurrency,
	|	DocumentData.VendorPriceKind.Currency AS CurrencyOfSupplierSPriceType,
	|	DocumentData.VendorPriceKind,
	|	DocumentData.PriceIncludesVAT AS PriceIncludesVAT,
	|	DocumentData.Terms.PriceIncludesVAT AS PriceIncludesVATTerms,
	|	DocumentData.RegisterVendorPrices AS RegisterVendorPrices,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Department AS Department,
	|	DocumentData.ServiceReceiptOption AS ServiceReceiptOption,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.Contract.ProcedureToRecordUninvoicedDeliveriesTA AS ProcedureToRecordUninvoicedDeliveriesTA,
	|	DocumentData.Manager AS Manager,
	|	DocumentData.Author AS Author,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Number AS Number,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Patch AS Patch,
	|	DocumentData.ReversedDocument AS ReversedDocument,
	|	DocumentData.CorrectedDocument AS CorrectedDocument,
	|	DocumentData.CorrectedDocument.Date AS AdjustmentPeriod_,
	|	BusinessTransactionsSettings.Ref AS BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit AS DocumentData
	|		LEFT JOIN Catalog.BusinessTransactionsSettings AS BusinessTransactionsSettings
	|		ON DocumentData.BusinessOperation = BusinessTransactionsSettings.BusinessOperation
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Attributes.Organization, Attributes.Period);
	
	Query.SetParameter("Period", 							Attributes.Period);
	Query.SetParameter("Ref", 							Attributes.Ref);
	
	Query.SetParameter("Organization", 						Attributes.Organization);
	Query.SetParameter("AdjustmentPeriod_",				Attributes.AdjustmentPeriod_);
	Query.SetParameter("Partner", 							Attributes.Partner);
	Query.SetParameter("Counterparty", 						Attributes.Counterparty);
	Query.SetParameter("Currency", 							Attributes.Currency);
	Query.SetParameter("AgreementCurrency", 					Attributes.AgreementCurrency);
	Query.SetParameter("CurrencyOfSupplierSPriceType",			Attributes.CurrencyOfSupplierSPriceType);
	Query.SetParameter("VendorPriceKind",					Attributes.VendorPriceKind);
	Query.SetParameter("PriceIncludesVATOfDocument", 			Attributes.PriceIncludesVAT);
	Query.SetParameter("PriceIncludesVATTerms", 			Attributes.PriceIncludesVATTerms);
	Query.SetParameter("RegisterVendorPrices", 		Attributes.RegisterVendorPrices);
	Query.SetParameter("BusinessOperation", 				Attributes.BusinessOperation);
	Query.SetParameter("Department", 						Attributes.Department);
	Query.SetParameter("Contract", 							Attributes.Contract);
	Query.SetParameter("Manager", 							Attributes.Manager);
	Query.SetParameter("Author", 								Attributes.Author);
	Query.SetParameter("LineOfBusiness", 			Attributes.LineOfBusiness); 
	Query.SetParameter("DocumentAmount", 					Attributes.DocumentAmount);
	Query.SetParameter("Number", 								Attributes.Number);
	Query.SetParameter("Comment", 						Attributes.Comment);
	Query.SetParameter("DeletionMark", 					Attributes.DeletionMark);
	Query.SetParameter("Posted", 							Attributes.Posted);
	Query.SetParameter("Patch", 						Attributes.Patch);
	Query.SetParameter("ReversedDocument", 				Attributes.ReversedDocument);
	Query.SetParameter("CorrectedDocument", 				Attributes.CorrectedDocument);
	Query.SetParameter("MetadataIdentifier",       		Common.MetadataObjectID(FullObjectName()));
	Query.SetParameter("TaxationOfOrganization",			AccountingParametersForOrganization.BasicTaxationVATSales);
	Query.SetParameter("BusinessTransactionSetting",     Attributes.BusinessTransactionSetting);
	Query.SetParameter("ProcedureToRecordUninvoicedDeliveriesTA", Attributes.ProcedureToRecordUninvoicedDeliveriesTA);
	
	ServiceReceiptOption = Attributes.ServiceReceiptOption;
	
	ContractInformation = Undefined;
	If ValueIsFilled(Attributes.Contract) Then
		StringPattern = "vi = 'Theo hợp đồng ""%1""';
						|ru = 'По договору ""%1""';
						|en = 'Under the ""%1"" contract';
						|it = 'In base al contratto ""%1""';
						|pl = 'Wg kontraktu ""%1""';
						|tr = '""%1"" sözleşmesi kapsamında'"; // @NStr
		ContractInformation = StringFunctionsClientServer.SubstituteParametersToString(StringPattern, Attributes.Contract);
	EndIf;
	Query.SetParameter("ContractInformation", ContractInformation);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
	// The document is an internal document and does not reflect the presentation of VAT by the supplier.
	// At the same time, it should take into account the planned inclusion of VAT in the cost for the correct reflection of charges in costs (the amount with VAT should be reflected).
	// Therefore, we redefine the setting of the accounting policy in the document when forming movements on the registers of other expenses and the cost of goods.
	Query.SetParameter("GenerateVATChargedWhenIncludingInCost", False);
	
EndProcedure

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	&Ref AS Ref,
	|	&Period AS IBDocumentDate,
	|	&Number AS IBDocumentNumber,
	|	&MetadataIdentifier AS RefType,
	|	&Organization AS Organization,
	|	&BusinessOperation AS BusinessOperation,
	|	&Partner AS Partner,
	|	&Counterparty AS Counterparty,
	|	&Contract AS Contract,
	|	&LineOfBusiness AS LineOfBusiness,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS StorageLocation,
	|	&Department AS Department,
	|	&Manager AS EmployeeResponsible,
	|	&Author AS Author,
	|	&Comment AS Comment,
	|	&Currency AS Currency,
	|	&DocumentAmount AS Sum,
	|	UNDEFINED AS Status,
	|	&Posted AS Posted,
	|	&DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	&ContractInformation AS More,
	|	UNDEFINED AS SourceDocumentDate,
	|	UNDEFINED AS SourceDocumentNumber,
	|	UNDEFINED AS SourceDocumentName,
	|	&Patch AS ReverseTransactionCorrection,
	|	&ReversedDocument AS ReversedDocument,
	|	&CorrectedDocument AS CorrectedDocument,
	|	&Period AS RecordingInAccountingDate,
	|	UNDEFINED AS Priority";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.ReceiptOfServicesToBusinessUnit";
	SynonymForDocumentTable = "";
	RequestHasSource    = False;
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("NumberForPrinting", """""");
	RedefiningParameterCalculation.Insert("ContractInformation",    """""");
	RedefiningParameterCalculation.Insert("CorrectionInformation", """""");
	
	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName%belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", 	FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", 		RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
		QueryText,
		FullDocumentName,
		SynonymForDocumentTable,
		RequestHasSource,
		RedefiningParameterCalculation);
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure ToIssueReceiptOfGoodsOnDvukhodovka(Query, QueryTexts, Registers)
	
	QueryTextDocument_ = 
	"SELECT
	|	DataSource.Ref AS Ref,
	|	CASE
	|		WHEN DataSource.Ref.ReferenceOrder IN
	|		(
	|		UNDEFINED,
	|		VALUE(Document.VendorInvoice.EmptyRef),
	|		VALUE(Document.PurchaseOrder.EmptyRef)
	|		)
	|		THEN
	|			DataSource.Ref
	|		ELSE
	|			DataSource.Ref.ReferenceOrder
	|	END AS Invoice,
	|	DataSource.Ref.ReferenceOrder AS OrderDocument,
	|	DataSource.Ref.Contract AS Contract,
	|	DataSource.Ref.Terms AS Terms,
	|	DataSource.Ref.ServiceReceiptOption AS ServiceReceiptOption,
	|	DataSource.Ref.Date AS Date,
	|	DataSource.Products AS Products,
	|	DataSource.Characteristic AS Characteristic,
	|	DataSource.Purpose AS Purpose,
	|	FALSE AS ToControlQuality,
	|	FALSE AS RecordOfAPreviouslyReceivedLot,
	|	UNDEFINED AS ControlledLotReference,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	0 AS BatchesIndicationStatus,
	|	0 AS BatchesIndicationStatusInWarehouses,
	|	0 AS BatchesIndicationStatusGoodsAtPartners,
	|	FALSE AS ExceedingOrder,
	|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
	|	DataSource.Ref.Partner AS Sender,
	|	DataSource.Ref.BusinessOperation AS BusinessOperation,
	|	DataSource.Count AS Count,
	|	TRUE AS ThisIsAnInvoice,
	|	NOT DataSource.Ref.ReferenceOrder IN
	|		(
	|		UNDEFINED,
	|		VALUE(Document.VendorInvoice.EmptyRef),
	|		VALUE(Document.PurchaseOrder.EmptyRef)
	|		)
	|	AS ReceiptUnderOrders
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS DataSource
	|WHERE
	|	DataSource.Ref IN(&Ref)
	|	AND NOT DataSource.Ref.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed)
	|
	|";
	
	CurrentMetadataObject1 = Metadata.Documents.ReceiptOfServicesToBusinessUnit;
	
	
	MethodParameters = WarehousesServer.ParametersOfModularHolding();
	MethodParameters.ServicesAndWorksAreCountedInRegisteredRecords = True;
	MethodParameters.ThisIsReceiptOfServicesToUnit = True;
	
	WarehousesServer.ArrangeReceiptOfGoodsOnTwoWayBasisWithWorksAndServices(
		Query,
		QueryTexts,
		Registers,
		QueryTextDocument_,
		CurrentMetadataObject1,
		MethodParameters);

EndProcedure

Procedure ReflectStockDistribution(Query, QueryTexts, Registers)
	
	QueryTextTabPart =
		"SELECT
		|	TabPart.Ref AS Ref,
		|	TabPart.Ref.Date AS Period,
		|	TabPart.Products AS Products,
		|	TabPart.Characteristic AS Characteristic,
		|	TabPart.Department AS Warehouse,
		|	TabPart.Purpose AS Purpose,
		|	VALUE(Catalog.ControlledLots.EmptyRef) AS ControlledLotReference,
		|	FALSE AS ToControlQuality,
		|	FALSE AS SubjectToUnlocking,
		|	DATETIME(1, 1, 1) AS QualityConfirmationDate,
		|	TabPart.Count AS Count,
		|	TRUE AS OnSchedule,
		|	TabPart.Ref.ReferenceOrder AS OrderInSchedule
		|FROM
		|	Document.ReceiptOfServicesToBusinessUnit.Services AS TabPart
		|WHERE
		|	TabPart.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|	AND NOT TabPart.ToExpenseAs";
	
	StockAllocationRecords.StockArrival(Query, QueryTexts, Registers, QueryTextTabPart, True, False);
	
EndProcedure

Function QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts)
	
	// Let's create a temporary table "Vttablitsaanalytikuchetaparties"
	
	LineNumberText = RequestTextStringCodesForBatchAccountingAnalytics();
	
	TextSelectionOfAnalystField = LineNumberText + "
	|SELECT
	|	""Services""							AS TabularSectionName,
	|	DocumentTable.LineNumber 			AS LineNumber,
	|	DocumentData.Partner					AS Vendor,
	|	DocumentData.Counterparty				AS Counterparty,
	|	DocumentTable.VATRate 				AS VATRate,
	|	CASE
	|	 	WHEN ISNULL(ARTICLES__.VATAssetTaxClass, UNDEFINED) IN (VALUE(Enum.AssetKinds.FA), VALUE(Enum.AssetKinds.IA))
	|				AND ISNULL(ARTICLES__.CostAllocationOptionLocal, UNDEFINED) = VALUE(Enum.CostAllocationOptions.ToNonCurrentAssetCost)
	|				AND ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.FixedAssetsCommissioning)
	|		WHEN ISNULL(ARTICLES__.SeparateVATAccountingOption, UNDEFINED) = VALUE(Enum.SeparateVATAccountingOptions.Allocation)
	|			THEN VALUE(Enum.VATTaxationTypes.DeterminedByAllocation)
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentTable.Purpose.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		WHEN ISNULL(DocumentTable.Purpose.VATActivityType, VALUE(Enum.VATTaxationTypes.EmptyRef)) <> VALUE(Enum.VATTaxationTypes.EmptyRef)
	|		 AND NOT DocumentTable.ToExpenseAs
	|			THEN DocumentTable.Purpose.VATActivityType
	|		WHEN DocumentData.VATTaxation = VALUE(Enum.VATTaxationTypes.VATTaxAgent)
	|				AND DocumentData.VATActivityType = VALUE(Enum.VATTaxationTypes.ByActualUsage)
	|			THEN &TaxationOfOrganization
	|		ELSE DocumentData.VATActivityType
	|	END                               	AS VATTaxation,
	|	VALUE(Enum.AssetKinds.OtherWorksAndServices) AS AssetTaxClass,
	|	LineCodes.RowCode						AS RowCode
	|INTO TTBatchAccountingAnalyst
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS DocumentTable
	|	INNER JOIN Document.ReceiptOfServicesToBusinessUnit AS DocumentData
	|		ON DocumentData.Ref = DocumentTable.Ref
	|	INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Ref = DocumentTable.ItemsLocationAttributesGoodsAtPartners.Products
	|	INNER JOIN TTLineCodesForBatchAccountingAnalytics AS LineCodes
	|		ON DocumentTable.LineNumber = LineCodes.LineNumber
	|	LEFT JOIN ChartOfCharacteristicTypes.ExpenseItems AS ARTICLES__
	|		ON DocumentTable.ExpenseItem = ARTICLES__.Ref
	|WHERE
	|	DocumentTable.Ref = &Ref
	|";
	
	QueryText = Catalogs.KeysForLotVendorAttributes.QueryTextTTTableOfPartyAccountingAnalysts(TextSelectionOfAnalystField, Query, QueryTexts);
	
	Return QueryText;
	
EndFunction

Function RequestTextStringCodesForBatchAccountingAnalytics()
	
	// Requests for line codes should be similar to the requests 
	// for the calculation function of the cost of document processing.The text of the query code for the analysis of the accounting of parties()
	// taking into account the features of the document.  
	
	SampleRequestTemplate =
	"SELECT
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	(CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN T.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef) END) AS Purpose,
	|	T.Department AS Department,
	|	T.ExpenseItem AS ExpenseItem,
	|	T.DimensionOfExpenses AS DimensionOfExpenses,
	|	MAX(T.LineNumber) AS LineNumber, // Line number for the same type of analytics
	|	SUM(1) AS RowsCount
	|INTO TTDocumentProducts
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS T
	|WHERE
	|	T.Ref = &Ref
	|GROUP BY
	|	T.Products,
	|	T.Characteristic,
	|	(CASE
	|		WHEN &KeepRecordsOfInventoryCostByAssignments
	|			THEN T.Purpose
	|		ELSE VALUE(Catalog.Assignments.EmptyRef) END),
	|	T.Department,
	|	T.ExpenseItem,
	|	T.DimensionOfExpenses
	|";
	
	QueryTextOfSelectionIsSummarized = "
	|SELECT
	|	T.Products AS Products,
	|	T.Characteristic AS Characteristic,
	|	SUM(T.RowsCount) AS RowsCount
	|INTO ItemOfTTDocumentIsSummarized
	|FROM
	|	TTDocumentProducts AS T
	|GROUP BY
	|	T.Products,
	|	T.Characteristic
	|";
	
	// The Line code field is filled in if there is more than one line in the document with the same nomenclature and characteristics,
	// but different assignments, divisions, expense items, or expense analysts.
	// For all lines with the same nomenclature, characteristics, division, purpose, article and analytics, one
	// common line code is filled in to form one common batch for all such lines.
	// Checking the filling in of the line code in the batch accounting analytics is performed in the procedure to correct the problem of movement in the documents()
	// of the general module of the calculation of the cost of data preparation.
	// The allocation of individual batches is necessary to correctly reflect deviations in the invoice delivery. 
	ResultRequestTemplate = "
	|SELECT
	|	T.LineNumber AS LineNumber,
	|	CASE WHEN Totals.RowsCount > 1
	|	 AND Totals.RowsCount <> ResultsInDetail.RowsCount
	|		THEN ResultsInDetail.LineNumber
	|		ELSE 0
	|	END AS RowCode
	|INTO TTLineCodesForBatchAccountingAnalytics
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS T
	|	INNER JOIN ItemOfTTDocumentIsSummarized AS Totals
	|		ON T.Products = Totals.Products
	|		AND T.Characteristic = Totals.Characteristic
	|	INNER JOIN TTDocumentProducts AS ResultsInDetail
	|		ON T.Products = ResultsInDetail.Products
	|		AND T.Characteristic = ResultsInDetail.Characteristic
	|		AND (T.Purpose = ResultsInDetail.Purpose
	|			OR NOT &KeepRecordsOfInventoryCostByAssignments)
	|		AND T.Department = ResultsInDetail.Department
	|		AND T.ExpenseItem = ResultsInDetail.ExpenseItem
	|		AND T.DimensionOfExpenses = ResultsInDetail.DimensionOfExpenses
	|WHERE
	|	T.Ref = &Ref
	|";
	
	QueryText = SampleRequestTemplate + "
		|;
		|" + QueryTextOfSelectionIsSummarized + "
		|;
		|" + ResultRequestTemplate + "
		|;
		|
		|";
	
	Return QueryText;
	
EndFunction

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	QueryAnalyst = New Query;
	QueryAnalyst.Text = "
	|SELECT DISTINCT
	|	TableServices.ItemsLocationAttributes.Products AS Products,
	|	TableServices.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	TableServices.ItemsLocationAttributes.Series AS Series,
	|	TableServices.ItemsLocationAttributes.StorageLocation AS StorageLocation
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS TableServices
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON TableServices.ItemsLocationAttributes.Products = Dimension.Products
	|			AND TableServices.ItemsLocationAttributes.Characteristic = Dimension.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|			AND TableServices.ItemsLocationAttributes.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TableServices.ItemsLocationAttributesGoodsAtPartners.Products AS Products,
	|	TableServices.ItemsLocationAttributesGoodsAtPartners.Characteristic AS Characteristic,
	|	&EmptyAssignment AS Purpose,
	|	TableServices.ItemsLocationAttributesGoodsAtPartners.Series AS Series,
	|	TableServices.ItemsLocationAttributesGoodsAtPartners.StorageLocation AS StorageLocation
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS TableServices
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON TableServices.ItemsLocationAttributesGoodsAtPartners.Products = Dimension.Products
	|			AND TableServices.ItemsLocationAttributesGoodsAtPartners.Characteristic = Dimension.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = Dimension.Series
	|			AND TableServices.ItemsLocationAttributesGoodsAtPartners.StorageLocation = Dimension.StorageLocation
	|			AND (&EmptyAssignment = Dimension.Purpose)
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	TableServices.Ref = &Ref
	|	AND Dimension.DimensionKey IS NULL
	|	AND NOT &KeepRecordsOfInventoryCostByAssignments
	|";
	
	QueryAnalyst.SetParameter("Ref", Query.Parameters.Ref);
	QueryAnalyst.SetParameter("EmptyAssignment", Catalogs.Assignments.EmptyRef());
	QueryAnalyst.SetParameter("KeepRecordsOfInventoryCostByAssignments", Query.Parameters.KeepRecordsOfInventoryCostByAssignments);
	
	Selection = QueryAnalyst.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection);
	EndDo;
	
	Query.SetParameter("ProductTrackingAnalyticsKeysInitialized", True);
EndProcedure

Procedure SetRequestParametersCurrencyCoefficients(Query)
	
	If Query.Parameters.Property("ConversionRateToManCurrency")
		And Query.Parameters.Property("FactorOfConversionToCurrencyOfRegul") Then
		Return;
	EndIf;
	
	Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
		Query.Parameters.Currency,
	    Query.Parameters.Currency,
	    Query.Parameters.Period,
	    Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",  Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul", Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetRequestParametersForInventoryOwnerAttributes(Query)
	
	If Query.Parameters.Property("InventoryOwnerAttribute") Then
		Return;
	EndIf;
	
	InventoryTypeDetails = New Structure();
	InventoryTypeDetails.Insert("Organization", Query.Parameters.Organization);
	InventoryTypeDetails.Insert("InventoryType", Enums.InventoryTypes.Work_5);
	InventoryOwnerAttribute = Catalogs.InventoryKinds.DocumentInventoryView(Query.Parameters.Organization, 
		Query.Parameters.BusinessOperation,
		InventoryTypeDetails);
	
	Query.SetParameter("InventoryOwnerAttribute", InventoryOwnerAttribute);
	
EndProcedure

Function QueryTextTableOtherExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "OtherExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTOtherExpenses_", QueryTexts) Then
		QueryTextTableTTOtherExpenses_(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableOtherExpenses("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTOtherExpenses_(Query, QueryTexts) Export
	
	RegisterName = "TTOtherExpenses_";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.OtherExpenses.QueryTextTableTTOtherExpenses_("RowID,VariancePeriod");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableServices", QueryTexts) Then
		QueryTextTTTableServices(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	&AdjustmentPeriod_ AS VariancePeriod,
	|	GoodsTable.Department AS Department,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	|	SUM(GoodsTable.AmountIncludingVATMan) AS AmountIncludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVAT,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS AmountExcludingVATMan,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl + GoodsTable.VATAmountCompl) AS AmountIncludingVATCompl,
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS AmountExcludingVATCompl,
	|	0 AS PermanentDifference,
	|	SUM(CASE
	|		WHEN GoodsTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN GoodsTable.TimeDifferenceWithVAT
	|		ELSE GoodsTable.TemporaryDifferenceExcludingVAT END) AS CostTD,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	GoodsTable.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting 
	|
	|INTO TTInitialOtherExpenses
	|FROM
	|	TTTableServices AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs 
	|		OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.ItemsLocationAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.RowID
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableItemisedExpensesLots(Query, QueryTexts, Registers)
	
	RegisterName = "ItemisedExpensesLots";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTLotsOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableItemisedExpensesLots("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableTTLotsOfOtherExpenses(Query, QueryTexts) Export
	
	RegisterName = "TTLotsOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTInitialBatchesOfOtherExpenses", QueryTexts) Then
		QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts);
	EndIf;
	
	QueryText = AccumulationRegisters.ItemisedExpensesLots.QueryTextTableTTLotsOfOtherExpenses("RowID");
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableTTInitialBatchesOfOtherExpenses(Query, QueryTexts)
	
	RegisterName = "TTInitialBatchesOfOtherExpenses";
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableServices", QueryTexts) Then
		QueryTextTTTableServices(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	// Expenses
	|SELECT
	|	&Period AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Organization AS Organization,
	|	GoodsTable.Department AS Department,
	|	&Ref AS ExpenseReceiptDocument,
	|	GoodsTable.ExpenseItem AS ExpenseItem,
	|	GoodsTable.DimensionOfExpenses AS DimensionOfExpenses,
	|	UNDEFINED AS AssetsLiabilitiesDimension,
	|	GoodsTable.LotVendorAttributes AS LotVendorAttributes,
	|	GoodsTable.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS ItemsLocationAttributes,
	|	GoodsTable.VATActivityType AS VATActivityType,
	|
	// This document is not used for VAT accounting purposes, because there cannot be an incoming invoice for it.
	// VAT will be taken into account further in the document Acquirement of service providers
	|	SUM(GoodsTable.AmountExcludingVATMan) AS Cost,
	|	SUM(GoodsTable.AmountExcludingVATMan) AS CostExcludingVAT,
	|	0 AS VATManag,
	|
	|	SUM(GoodsTable.AmountExcludingVATCompl) AS LocalCost,
	|	0 AS PermanentDifference,
	|	SUM(CASE
	|		WHEN GoodsTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN GoodsTable.TimeDifferenceWithVAT
	|		ELSE GoodsTable.TemporaryDifferenceExcludingVAT END) AS CostTD,
	|	0 AS VATLocal,
	|
	|	&BusinessOperation AS BusinessOperation,
	|	
	|	GoodsTable.RowID AS RowID,
	|	GoodsTable.RowID AS FinRecordID,
	|	&BusinessTransactionSetting   AS BusinessTransactionSetting
	|
	|INTO TTInitialBatchesOfOtherExpenses
	|FROM
	|	TTTableServices AS GoodsTable
	|WHERE
	|	(GoodsTable.ToExpenseAs 
	|		OR GoodsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService))
	|GROUP BY
	|	GoodsTable.ExpenseItem,
	|	GoodsTable.DimensionOfExpenses,
	|	GoodsTable.LotVendorAttributes,
	|	GoodsTable.Department,
	|	GoodsTable.LineOfBusiness,
	|	GoodsTable.VATActivityType,
	|	GoodsTable.RowID
	|";

	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTTTableServices(Query, QueryTexts)
	
	RegisterName = "TTTableServices";
	
	SetRequestParametersCurrencyCoefficients(Query);
	SetRequestParametersForInventoryOwnerAttributes(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableOfPartyAccountingAnalysts", QueryTexts) Then
		QueryTextTTTableOfPartyAccountingAnalysts(Query, QueryTexts);
	EndIf;
	
	InitializeProductAccountingAnalyticsKeys(Query);
	
	QueryText = "
	|SELECT
	|	TableOfWorkServices.ItemsLocationAttributes.Products AS Products, 
	|	TableOfWorkServices.Products.ItemsType AS ItemsType,
	|	TableOfWorkServices.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableOfWorkServices.ItemsLocationAttributes.Series AS Series,
	|	TableOfWorkServices.ItemsLocationAttributes.WarehouseArea.ShopFloorStockroom AS ShopFloorStockroom,
	|	TableOfWorkServices.ItemsLocationAttributes.Purpose AS Purpose,
	|	&LineOfBusiness AS LineOfBusiness,
	|
	|	TableOfWorkServices.Ref.Contract.OptionForRegisteringServiceReceiptDocuments AS OptionForRegisteringServiceReceiptDocuments,
	|	TableOfWorkServices.Ref.VATActivityType AS DocumentVATActivityType,
	|	ItemsLocationAttributesGoodsAtPartners.Products AS PartnerProducts_,
	|	ItemsLocationAttributesGoodsAtPartners.Characteristic AS CharacteristicsOfPartners,
	|	ItemsLocationAttributesGoodsAtPartners.Series AS SeriesWithPartners,
	|	ItemsLocationAttributesGoodsAtPartners.Purpose AS AppointmentWithPartners,
	|	TableOfWorkServices.ItemsLocationAttributes AS DimensionOfProductItem,
	|	AnalyticsWithoutAssignment.DimensionKey AS AnalysisOfProductsWithoutAssignment,
	|	TableOfWorkServices.ItemsLocationAttributesGoodsAtPartners AS AnalyticsProductsFromPartners,
	|	AnalyticsForPartnersWithoutAppointment.DimensionKey AS AnalyticsProductsFromPartnersWithoutDestination,
	|
	|	TableOfBatchAccountingAnalysts.VATTaxation AS VATActivityType,
	|	TableOfBatchAccountingAnalysts.LotVendorAttributes AS LotVendorAttributes,
	|
	|	&InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS WarehouseInventoryAttributes,
	|	VALUE(Enum.InventoryTypes.EmptyRef) AS TypeOfStockInStock,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	TableOfWorkServices.VATRate AS VATRate,
	|	TableOfWorkServices.Count AS Count,
	|
	|	CAST(TableOfWorkServices.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountIncludingVATMan,
	|	CAST(TableOfWorkServices.VATAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS VATAmountMan,	
	|	CAST((TableOfWorkServices.AmountIncludingVAT - TableOfWorkServices.VATAmount) * &ConversionRateToManCurrency AS NUMBER(31, 2)) AS AmountExcludingVATMan,	
	|	CAST(TableOfWorkServices.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountIncludingVATCompl,
	|	CAST((TableOfWorkServices.AmountIncludingVAT - TableOfWorkServices.VATAmount)	* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS AmountExcludingVATCompl,	
	|	CAST(TableOfWorkServices.VATAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS VATAmountCompl,	
	|	
	|	TableOfWorkServices.ToExpenseAs AS ToExpenseAs,
	|	TableOfWorkServices.ExpenseItem AS ExpenseItem,
	|	TableOfWorkServices.DimensionOfExpenses AS DimensionOfExpenses,
	|	TableOfWorkServices.Department AS Department,
	|	TableOfWorkServices.RowID AS RowID,
	|	CASE
	|		WHEN NOT ISNULL(TableOfWorkServices.ExpenseItem.EnteredInTaxAccounting, TRUE)
	// If the document indicates an expense item that is not accepted for income tax accounting, then a permanent difference should be reflected.
	|		THEN 0
	|		ELSE CASE
	|			WHEN TableOfWorkServices.Ref.Contract.OptionForRegisteringServiceReceiptDocuments
	|				= VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed) 
	|			THEN CASE
	|						WHEN TableOfBatchAccountingAnalysts.VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|							THEN CAST(TableOfWorkServices.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|							ELSE CAST((TableOfWorkServices.AmountIncludingVAT - TableOfWorkServices.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31, 2))
	|					END
	|		ELSE CASE
	|			WHEN &ProcedureToRecordUninvoicedDeliveriesTA = VALUE(Enum.OptionsToRecordUninvoicedDeliveriesTA.RecordOnInvoiceEntry)
	|				THEN CAST(TableOfWorkServices.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31, 2))
	|			ELSE 0
	|		END
	|	END
	|	END AS TimeDifferenceWithVAT,
	|	CASE
	|		WHEN (&ProcedureToRecordUninvoicedDeliveriesTA = VALUE(Enum.OptionsToRecordUninvoicedDeliveriesTA.RecordOnInvoiceEntry)
	|			OR TableOfWorkServices.Ref.Contract.OptionForRegisteringServiceReceiptDocuments
	|				= VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed))
	|		 AND (NOT TableOfWorkServices.ToExpenseAs	OR ISNULL(TableOfWorkServices.ExpenseItem.EnteredInTaxAccounting, FALSE))
	// If the document indicates an expense item that is not accepted for income tax accounting, then a permanent difference should be reflected.
	|			THEN CAST((TableOfWorkServices.AmountIncludingVAT - TableOfWorkServices.VATAmount) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))
	|		ELSE 0
	|	END AS TemporaryDifferenceExcludingVAT,
	|	TableOfWorkServices.ItemsLocationAttributes AS ItemsLocationAttributes
	|
	|INTO TTTableServices
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit.Services AS TableOfWorkServices
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsWithoutAssignment
	|		ON TableOfWorkServices.ItemsLocationAttributes.Products = AnalyticsWithoutAssignment.Products
	|			AND TableOfWorkServices.ItemsLocationAttributes.Characteristic = AnalyticsWithoutAssignment.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsWithoutAssignment.Series
	|			AND TableOfWorkServices.ItemsLocationAttributes.StorageLocation = AnalyticsWithoutAssignment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsWithoutAssignment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsForPartnersWithoutAppointment
	|		ON TableOfWorkServices.ItemsLocationAttributesGoodsAtPartners.Products = AnalyticsForPartnersWithoutAppointment.Products
	|			AND TableOfWorkServices.ItemsLocationAttributesGoodsAtPartners.Characteristic = AnalyticsForPartnersWithoutAppointment.Characteristic
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsForPartnersWithoutAppointment.Series
	|			AND TableOfWorkServices.ItemsLocationAttributesGoodsAtPartners.StorageLocation = AnalyticsForPartnersWithoutAppointment.StorageLocation
	|			AND (VALUE(Catalog.Assignments.EmptyRef) = AnalyticsForPartnersWithoutAppointment.Purpose)
	|			AND (VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsWithoutAssignment.ProductCostElement)
	|	LEFT JOIN TTTableOfPartyAccountingAnalysts AS TableOfBatchAccountingAnalysts
	|		ON TableOfBatchAccountingAnalysts.LineNumber = TableOfWorkServices.LineNumber
	|		AND TableOfBatchAccountingAnalysts.TabularSectionName = ""Services""
	|WHERE
	|	TableOfWorkServices.Ref = &Ref
	|";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTableItemsPricesOfVendor(Query, QueryTexts, Registers)
	
	RegisterName = "ItemsPricesOfVendor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryServiceTable", QueryTexts) Then
		QueryTextTemporaryServiceTable(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("ServicesWithDifferentPrices", QueryTexts) Then
		QueryTextServicesWithDifferentPrices(Query, QueryTexts);
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	MAX(Services.PartnerProducts) AS PartnerProducts,
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	&VendorPriceKind AS VendorPriceKind,
	|	&CurrencyOfSupplierSPriceType AS Currency,
	|	&Period AS Period,
	|	&Partner AS Partner,
	|	MIN(Services.Package) AS Package,
	|	CAST(AVG(Services.Price * CASE
	|				WHEN &Currency <> Services.VendorPriceKind.Currency
	|					THEN CASE
	|							WHEN ISNULL(CurrencyRatesPrices.CourseDenominator, 0) > 0
	|									AND ISNULL(CurrencyRatesPrices.CourseNumerator, 0) > 0
	|									AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
	|									AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
	|								THEN Currency_Rates.CourseNumerator * CurrencyRatesPrices.CourseDenominator / (CurrencyRatesPrices.CourseNumerator * Currency_Rates.CourseDenominator)
	|							ELSE 0
	|						END
	|				ELSE 1
	|			END) AS NUMBER(31, 2)) AS Price
	|FROM
	|	TemporaryServiceTable AS Services
	|		LEFT JOIN ServicesWithDifferentPrices AS ServicesWithDifferentPrices
	|		ON Services.Products = ServicesWithDifferentPrices.Products
	|			AND Services.Characteristic = ServicesWithDifferentPrices.Characteristic
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
	|		ON (Currency_Rates.Currency = &Currency)
	|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS CurrencyRatesPrices
	|		ON (CurrencyRatesPrices.Currency = &CurrencyOfSupplierSPriceType)
	|WHERE
	|	NOT Services.VendorPriceKind = VALUE(Catalog.VendorPriceTypes.EmptyRef)
	|
	|GROUP BY
	|	Services.Products,
	|	Services.Characteristic";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryServiceTable(Query, QueryTexts)
	
	RegisterName = "TemporaryServiceTable";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryTableCurrencyExchangeRates", QueryTexts) Then
		QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts);
	EndIf; 
	
	QueryText =
		"SELECT
		|	Services.PartnerProducts AS PartnerProducts,
		|	Services.Products AS Products,
		|	Services.Characteristic AS Characteristic,
		|	&VendorPriceKind AS VendorPriceKind,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	CAST(Services.Price * CASE
		|			WHEN &PriceIncludesVATOfDocument
		|					AND NOT &PriceIncludesVATTerms
		|				THEN 100 / (100 + Services.VATRate.Rate1)
		|			WHEN NOT &PriceIncludesVATOfDocument
		|					AND &PriceIncludesVATTerms
		|				THEN (Services.VATRate.Rate1 + 100) / 100
		|			ELSE 1
		|		END * CASE
		|			WHEN &Currency <> &AgreementCurrency
		|				THEN CASE
		|						WHEN ISNULL(ExchangeRatesOfAgreement_.CourseDenominator, 0) > 0
		|								AND ISNULL(ExchangeRatesOfAgreement_.CourseNumerator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseDenominator, 0) > 0
		|								AND ISNULL(Currency_Rates.CourseNumerator, 0) > 0
		|							THEN Currency_Rates.CourseNumerator * ExchangeRatesOfAgreement_.CourseDenominator / (ExchangeRatesOfAgreement_.CourseNumerator * Currency_Rates.CourseDenominator)
		|						ELSE 0
		|					END
		|			ELSE 1
		|		END AS NUMBER(31, 2)) AS Price
		|INTO TemporaryServiceTable
		|FROM
		|	Document.ReceiptOfServicesToBusinessUnit.Services AS Services
		|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS Currency_Rates
		|		ON (Currency_Rates.Currency = &Currency)
		|		LEFT JOIN TemporaryTableCurrencyExchangeRates AS ExchangeRatesOfAgreement_
		|		ON (ExchangeRatesOfAgreement_.Currency = &AgreementCurrency)
		|WHERE
		|	Services.Ref = &Ref
		|	AND &RegisterVendorPrices";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextServicesWithDifferentPrices(Query, QueryTexts)
	
	RegisterName = "ServicesWithDifferentPrices";
	
	If Not DocumentsPosting.ThereIsQueryTable("TemporaryServiceTable", QueryTexts) Then
		QueryTextTemporaryServiceTable(Query, QueryTexts);
	EndIf; 
	
	QueryText = 
	"SELECT
	|	Services.Products AS Products,
	|	Services.Characteristic AS Characteristic,
	|	&VendorPriceKind AS VendorPriceKind,
	|	AVG(Services.Price) AS PricePerBaseUnit,
	|	COUNT(DISTINCT Services.Package) AS NumberOfDifferentPackages
	|INTO ServicesWithDifferentPrices
	|FROM
	|	TemporaryServiceTable AS Services
	|
	|GROUP BY
	|	Services.Products,
	|	Services.Characteristic";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTemporaryTableCurrencyExchangeRates(Query, QueryTexts)
	
	RegisterName = "TemporaryTableCurrencyExchangeRates";
	
	QueryText = "
	|SELECT
	|	RelativeExchangeRatesSliceLast.Currency AS Currency,
	|	RelativeExchangeRatesSliceLast.CourseNumerator AS CourseNumerator,
	|	RelativeExchangeRatesSliceLast.CourseDenominator AS CourseDenominator
	|INTO TemporaryTableCurrencyExchangeRates
	|FROM
	|	InformationRegister.RelativeExchangeRates.SliceLast(&Period, BaseCurrency IN (SELECT
	|				DefaultBaseCurrency.Value AS Value
	|			FROM
	|				Constant.DefaultBaseCurrency AS DefaultBaseCurrency)) AS
	|		RelativeExchangeRatesSliceLast
	|INDEX BY
	|	Currency
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableMaterialsAndWorksInProduction(Query, QueryTexts, Registers)
	
	RegisterName = "MaterialsAndWorksInProduction";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableServices", QueryTexts) Then
		QueryTextTTTableServices(Query, QueryTexts);
	EndIf; 
	
	QueryText = "
	|SELECT
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Period AS Period,
	|	&Period AS RecorderDate,
	|	&Organization AS Organization,
	|	TableServices.Department,
	|	TableServices.Products,
	|	TableServices.Characteristic,
	|	TableServices.Series,
	|	TableServices.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableServices.Count AS Count,
	|	TableServices.Purpose AS Purpose,
	|	TRUE AS Primary
	|FROM
	|	TTTableServices AS TableServices
	|WHERE
	|	TableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TableServices.Products.TracedGoods
	|	AND NOT TableServices.ToExpenseAs
	|	AND (TableServices.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		OR TableServices.Purpose.AssignmentType <> VALUE(Enum.AssignmentTypes.DeliveryForPrincipal))
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableVATInvoiced(Query, QueryTexts, Registers)
	
	RegisterName = "VATInvoiced";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentTable.Ref AS Recorder,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	DocumentTable.Date AS Period,
	|	DocumentTable.Organization AS Organization,
	|	CASE
	|		WHEN DocumentTable.Patch
	|			THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END AS TaxInvoice,
	|	DocumentTable.Counterparty AS Vendor,
	|	VALUE(Enum.AssetKinds.UninvoicedVAT) AS AssetTaxClass,
	|	TTTableServices.VATRate AS VATRate,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	UNDEFINED AS CorrectedTaxInvoice,
	|	UNDEFINED AS SaleExport,
	|	DocumentTable.Contract.LineOfBusiness AS LineOfBusiness,
	|	SUM(TTTableServices.AmountExcludingVATCompl) AS AmountExcludingVAT,
	|	SUM(TTTableServices.VATAmountCompl) AS VAT,
	|	SUM(TTTableServices.VATAmountMan) AS VATManag,
	|	UNDEFINED AS Event,
	|	UNDEFINED AS CorVATActivityTypes,
	|	UNDEFINED AS Department,
	|	UNDEFINED AS ExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	"""" AS RowID,
	|	FALSE AS PeriodEndTransaction,
	|	TTTableServices.RowID AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromVendorUninvoicedDelivery) AS
	|		BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit AS DocumentTable
	|		INNER JOIN TTTableServices AS TTTableServices
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref = &Ref
	|	AND DocumentTable.VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	AND NOT DocumentTable.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|	AND DocumentTable.Contract.OptionForRegisteringServiceReceiptDocuments = VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed)
	|GROUP BY
	|	DocumentTable.Ref,
	|	DocumentTable.Date,
	|	DocumentTable.Organization,
	|	DocumentTable.Counterparty,
	|	TTTableServices.VATRate,
	|	DocumentTable.Contract.LineOfBusiness,
	|	VALUE(AccumulationRecordType.Receipt),
	|	CASE
	|		WHEN DocumentTable.Patch
	|			THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END,
	|	TTTableServices.RowID,
	|	VALUE(Enum.AssetKinds.UninvoicedVAT),
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT),
	|	VALUE(Catalog.BusinessTransactionsSettings.PurchaseFromVendorUninvoicedDelivery)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	
	If Query <> Undefined Then
		// There are no additional parameters.
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableServices");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableServices(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	// For works and services, the "Expense" movements are formed according to the "Cost of goods" register according to the "Unfactured deliveries" section of accounting.
	// in the item accounting analytics, the Contract must be filled in in the "place of accounting" field.
	// the Local and Man price includes the amount of vat if the purchase is for an activity with vat included in the price.
	// Financial accounting analysts are not filled in.
	// in the Attributes of the box... analytics are indicated to reflect discrepancies in the invoice of the delivery.
	// For jobs filled in:
	//	- Cor analytics of item accounting
	//	- Cor accounting section
	// For services and works charged to expenses, fill in:
	//	- Division
	//	- Write-off expense item
	//	- Cost analytics
	//	- Cor direction of activity
	// For an expense item that is not accepted for income tax accounting, there should always be a constant difference  
	
	#Region ExternalReceipt_Product_UnfactatedDeliveryIEAES_Expense
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TTTableServices.AnalyticsProductsFromPartners		AS ItemsLocationAttributes,
	|	TTTableServices.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	CASE WHEN &Patch
	|		THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END 											AS Lot,
	|	TTTableServices.VATActivityType				AS VATActivityType,
	|	TTTableServices.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TTTableServices.LotVendorAttributes			AS LotVendorAttributes,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	TTTableServices.VATRate 						AS VATRate,
	|
	// Corresponding fields
	|	TTTableServices.DimensionOfProductItem			AS CorItemsLocationAttributes,
	|	TTTableServices.InventoryOwnerAttribute						AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED									AS SalesOpportunity,
	|	TTTableServices.Department					AS Department,
	|	UNDEFINED 									AS Manager,
	|	TTTableServices.AnalyticsProductsFromPartners.Products.AnalyticalGroup AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTableServices.Count						AS Count,
	|	UNDEFINED 									AS RowID,
	|
	|	TTTableServices.AmountIncludingVATMan 					AS Cost,
	|	CASE
	|		WHEN TTTableServices.OptionForRegisteringServiceReceiptDocuments 
	|			IN (VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed))
	|		THEN
	|			CASE
	|				WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN
	|				TTTableServices.AmountIncludingVATMan
	|			ELSE
	|				TTTableServices.AmountExcludingVATMan
	|			END
	|		ELSE 
	|			TTTableServices.AmountExcludingVATMan
	|		END
	|	AS CostExcludingVAT,
	|	CASE
	|		WHEN TTTableServices.OptionForRegisteringServiceReceiptDocuments 
	|			IN (VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed))
	|		THEN 
	|			CASE
	|				WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN TTTableServices.AmountIncludingVATCompl
	|				ELSE 
	|					CASE
	|						WHEN TTTableServices.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|							AND TTTableServices.DocumentVATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|							THEN TTTableServices.AmountExcludingVATCompl
	|						ELSE TTTableServices.AmountIncludingVATCompl
	|					END
	|			END
	|		ELSE 
	|			CASE
	|				WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN TTTableServices.AmountIncludingVATCompl
	|				ELSE 
	|					TTTableServices.AmountExcludingVATCompl 
	|			END
	|	END 											AS LocalCost,
	|	0												AS VATLocal,
	|	CASE
	|		WHEN TTTableServices.OptionForRegisteringServiceReceiptDocuments 
	|			IN (VALUE(Enum.OptionsForRegisteringServiceDocuments.ReceiptOfServicesIsReversed))
	|		THEN 
	|			CASE
	|				WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN TTTableServices.AmountIncludingVATMan
	|				ELSE 
	|					CASE
	|						WHEN TTTableServices.VATActivityType = VALUE(Enum.VATTaxationTypes.DeterminedByAllocation) 
	|							AND TTTableServices.DocumentVATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|							THEN TTTableServices.AmountExcludingVATMan
	|						ELSE TTTableServices.AmountIncludingVATMan
	|					END
	|			END
	|		ELSE 
	|			CASE
	|				WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|					THEN TTTableServices.AmountIncludingVATMan
	|				ELSE TTTableServices.AmountExcludingVATMan 
	|			END
	|	END 											AS CostMan,
	|	0 												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0 												AS AddExpensesForGoods,
	|	0 												AS AdditionalExpensesExcludingVAT,
	|	0 												AS AddExpensesLocal,
	|	0 												AS AddExpensesMan,
	// By 60.NP and in the cost of goods should never be formed PD.
	// Depending on the flag, the order in which the actual deliveries are reflected in the Contract is either TA or TD.
	|	0												AS PermanentDifference,
	|	(CASE
	|		WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN TTTableServices.TimeDifferenceWithVAT
	|		ELSE TTTableServices.TemporaryDifferenceExcludingVAT END) AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.UninvoicedDeliveries) AS AccountingSection,
	|	CASE
	|		WHEN TTTableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5) 
	|		 AND NOT TTTableServices.ToExpenseAs
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.ProductionCosts)
	|		ELSE UNDEFINED
	|	END 											AS CorAccountingSection,
	|	DocumentTable.BusinessOperation 			AS BusinessOperation,
	|	TTTableServices.RowID				AS FinRecordID,
	|	&BusinessTransactionSetting					AS BusinessTransactionSetting,
	|
	// Optional fields
	|	TTTableServices.DimensionOfExpenses				AS DimensionOfExpenses,
	|	TTTableServices.ExpenseItem					AS ExpenseItemOfWriteOff,
	|	TTTableServices.LineOfBusiness			AS CorLineOfBusiness
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit AS DocumentTable
	|	INNER JOIN TTTableServices AS TTTableServices
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion

	// For works that are not written off as expenses, the "Arrival" movements are formed according to the "Cost of goods" register
	// according to the "Production costs" section of accounting.
	// In the item accounting analytics, the division is indicated in the "Place of accounting" field.
	// the Local and Man price includes the amount of vat if the purchase is for an activity with vat included in the price.
	
	#Region ExternalReceipt_Work_5_ProductionCosts_Receipt
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 		AS Period,
	|	DocumentTable.Ref 	AS Ref,
	|	UNDEFINED				AS DocumentSource,
	|	UNDEFINED				AS SourceDocumentPeriod,
	|	UNDEFINED 				AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_		AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization					AS Organization,
	|	TTTableServices.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TTTableServices.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	CASE WHEN &Patch
	|		THEN DocumentTable.CorrectedDocument
	|		ELSE DocumentTable.Ref
	|	END 											AS Lot,
	|	TTTableServices.VATActivityType				AS VATActivityType,
	|	TTTableServices.VATActivityType				AS DocumentVATActivityType,
	|
	// Batch Accounting Analysis Fields
	|	TTTableServices.LotVendorAttributes			AS LotVendorAttributes,
	|	TTTableServices.LotVendorAttributes			AS LotVendorAttributesCorr,
	|	DocumentTable.Partner						AS Vendor,
	|	DocumentTable.Counterparty 					AS Counterparty,
	|	TTTableServices.VATRate 						AS VATRate,
	|
	// Corresponding fields
	|	TTTableServices.DimensionOfProductItem			AS CorItemsLocationAttributes,
	|	TTTableServices.WarehouseInventoryAttributes				AS CorInventoryOwnerAttribute,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED									AS SalesOpportunity,
	|	UNDEFINED				 					AS Department,
	|	UNDEFINED									AS Manager,
	|	TTTableServices.AnalyticsProductsFromPartners.Products.AnalyticalGroup AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TTTableServices.Count						AS Count,
	|	UNDEFINED 									AS RowID,
	|
	|	TTTableServices.AmountIncludingVATMan					AS Cost,
	|	TTTableServices.AmountExcludingVATMan					AS CostExcludingVAT,
	|	CASE
	|		WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN TTTableServices.AmountIncludingVATCompl
	|		ELSE TTTableServices.AmountExcludingVATCompl
	|	END 											AS LocalCost,
	|	0												AS VATLocal,
	|	CASE
	|		WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN TTTableServices.AmountIncludingVATMan
	|		ELSE TTTableServices.AmountExcludingVATMan
	|	END 											AS CostMan,
	|	0												AS VATManag,
	|	0												AS OffBalanceCost,
	|	0												AS OffBalanceCostLocal,
	|	0												AS AddExpensesForGoods,
	|	0												AS AdditionalExpensesExcludingVAT,
	|	0												AS AddExpensesLocal,
	|	0												AS AddExpensesMan,
	// By 60.NP and in the cost of goods should never be formed PD.
	// Depending on the flag, the order in which the actual deliveries are reflected in the Contract is either TA or TD.
	|	0												AS PermanentDifference,
	|	(CASE
	|		WHEN TTTableServices.VATActivityType IN (&TypesOfTaxationVATIsIncludedInCost)
	|			THEN TTTableServices.TimeDifferenceWithVAT
	|		ELSE TTTableServices.TemporaryDifferenceExcludingVAT END) AS CostTD,
	|	0												AS CorGrossInitialCostENT,
	|
	// Other fields
	|	DocumentTable.BusinessOperation			AS BusinessOperation,
	|	TTTableServices.RowID				AS FinRecordID,
	|	&BusinessTransactionSetting					AS BusinessTransactionSetting
	|FROM
	|	Document.ReceiptOfServicesToBusinessUnit AS DocumentTable
	|	INNER JOIN TTTableServices AS TTTableServices
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TTTableServices.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
	|	AND NOT TTTableServices.ToExpenseAs
	|";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.ExternalReceipt,
		QueryText);
	
	#EndRegion
	
	Return DescriptionOfOperations;
	
EndFunction

#EndRegion

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	ReceiptOfServicesToBusinessUnitLocalization.AddPrintCommands(PrintCommands);
	
EndProcedure

#EndRegion

#Region Other

Function FullObjectName()
	Return "Document.ReceiptOfServicesToBusinessUnit";
EndFunction

#EndRegion

#EndRegion

#EndIf
#EndIf
