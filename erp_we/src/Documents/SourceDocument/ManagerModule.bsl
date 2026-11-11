#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	FillingValues = New Structure();
	FillingValues.Insert("BusinessOperation", Enums.BusinessTransactions.AdjustBeforeEnteringBalance);
	
	If AccessRight("Insert", Metadata.Documents.PurchaseAdjustment) Then
		Command = Documents.PurchaseAdjustment.AddGenerateCommand(GenerationCommands);
		If Command <> Undefined Then
			Command.FormParameters = New Structure("FillingValues", FillingValues);
			AttachableCommands.AddCommandVisibilityCondition(Command,"SourceDocumentType", Enums.SourceDocumentTypes.PurchaseFromVendor);
		EndIf;
		Command.FunctionalOptions = "NewOnlineARAPAccounting";
	EndIf;
	
	If AccessRight("Insert", Metadata.Documents.SaleAdjustment) Then
		Command = Documents.SaleAdjustment.AddGenerateCommand(GenerationCommands);
		If Command <> Undefined Then
			Command.FormParameters = New Structure("FillingValues", FillingValues);
			AttachableCommands.AddCommandVisibilityCondition(Command,"SourceDocumentType", Enums.SourceDocumentTypes.SaleToCustomer);
		EndIf;
		Command.FunctionalOptions = "NewOnlineARAPAccounting";
	EndIf;
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Returns an array of details available for the primary document type
//
// Parameters:
//	SourceDocumentType - EnumRef.SourceDocumentTypes - Type of primary document.
//
// Returns:
// 	Structure - structure with fields:
// 	                          * ArrayOfAllProps - Array of String - all conditionally visible Attributes
// 	                          * ArrayOfDetailsForType - Array of String - Attributes visible for the document type.
//
Function ArrayOfDetailsByPrimaryDocumentType(SourceDocumentType) Export
	
	ArrayOfAllProps = New Array; // Array of String
	ArrayOfAllProps.Add("Partner");
	ArrayOfAllProps.Add("Counterparty");
	ArrayOfAllProps.Add("Contract");
	ArrayOfAllProps.Add("FinancialAccountingGroup");
	ArrayOfAllProps.Add("LineOfBusiness");
	ArrayOfAllProps.Add("Department");
	ArrayOfAllProps.Add("ARAPObjectSettings");
	ArrayOfAllProps.Add("Currency");
	ArrayOfAllProps.Add("ARAPCurrency");
	ArrayOfAllProps.Add("IncomingDocumentNumber");
	ArrayOfAllProps.Add("IncomingDocumentDate");
	ArrayOfAllProps.Add("ExternalDocumentName");
	ArrayOfAllProps.Add("DocumentAmount");
	ArrayOfAllProps.Add("SumCompl");
	ArrayOfAllProps.Add("SumMan");
	ArrayOfAllProps.Add("AmountARAP");
	ArrayOfAllProps.Add("VATTaxation");
	
	ArrayOfDetailsForType = New Array; // Array of String
	If SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		Or SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport
		Or False Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer
		Or SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider
		Or False Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate Then
		
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate Then
		
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
		
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.InternalInvoice Then
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.VMIProcurement Then
		
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
		ArrayOfDetailsForType.Add("Partner");
		ArrayOfDetailsForType.Add("Counterparty");
		ArrayOfDetailsForType.Add("Contract");
		ArrayOfDetailsForType.Add("FinancialAccountingGroup");
		ArrayOfDetailsForType.Add("LineOfBusiness");
		ArrayOfDetailsForType.Add("Department");
		ArrayOfDetailsForType.Add("ARAPObjectSettings");
		ArrayOfDetailsForType.Add("Currency");
		ArrayOfDetailsForType.Add("ARAPCurrency");
		ArrayOfDetailsForType.Add("IncomingDocumentNumber");
		ArrayOfDetailsForType.Add("IncomingDocumentDate");
		ArrayOfDetailsForType.Add("ExternalDocumentName");
		ArrayOfDetailsForType.Add("DocumentAmount");
		ArrayOfDetailsForType.Add("SumCompl");
		ArrayOfDetailsForType.Add("SumMan");
		ArrayOfDetailsForType.Add("AmountARAP");
		ArrayOfDetailsForType.Add("VATTaxation");
		
	EndIf;
	
	Result = New Structure;
	Result.Insert("ArrayOfAllProps", ArrayOfAllProps);
	Result.Insert("ArrayOfDetailsForType", ArrayOfDetailsForType);
	
	Return Result;
	
EndFunction

// Initializes parameters for registering invoices (received)
//
// Parameters:
//  Object		- DocumentObject.SourceDocument, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived
//
Function ParametersForRegisteringInvoicesReceived(Object) Export
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	RegistrationParameters.Ref             = Object.Ref;
	RegistrationParameters.Date               = Object.Date;
	RegistrationParameters.Organization        = Object.Organization;
	RegistrationParameters.Counterparty         = Object.Counterparty;
	RegistrationParameters.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	
	If Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
		RegistrationParameters.PurchaseOfGoodsWorksServices = True;
	EndIf;
	
	
	Return RegistrationParameters;
	
EndFunction

// Initializes parameters for registering invoices (issued)
//
// Parameters:
//  Object		- DocumentObject.SourceDocument, FormDataStructure	- the document to get parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued
//
Function ParametersForRegisteringInvoicesIssued(Object) Export

	ThisIsContractWithCounterparty = (TypeOf(Object.Contract) = Type("CatalogRef.CounterpartyContracts")); 
	
	If ThisIsContractWithCounterparty Then 
		ContractStructure = Common.ObjectAttributesValues(Object.Contract, 
			"BusinessOperation, CounterpartyCommissionAgent");
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	
	RegistrationParameters.Ref             = Object.Ref;
	RegistrationParameters.Date               = Object.Date;
	RegistrationParameters.Organization        = Object.Organization;
	RegistrationParameters.Counterparty         = Object.Counterparty;
	RegistrationParameters.VATTaxation = Enums.VATTaxationTypes.SaleIsSubjectToVAT;
	RegistrationParameters.SalesViaCommissionAgent = ThisIsContractWithCounterparty 
			And ConsignmentSalesServer.SalesViaCommissionAgent(ContractStructure.BusinessOperation);

	If ThisIsContractWithCounterparty And RegistrationParameters.SalesViaCommissionAgent Then
		RegistrationParameters.Counterparty = ContractStructure.CounterpartyCommissionAgent;
	EndIf;

	If Object.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
		RegistrationParameters.GoodsSales = True;
		RegistrationParameters.ImplementationOfWorksServices = True;
	EndIf;
	
	RegistrationParameters.VATAccrualUponShipment = (Object.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer);
	
	Return RegistrationParameters;
	
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array of String - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Chứng từ gốc';
							|ru = 'Первичный документ';
							|en = 'Source document'; fa = 'سند منبع';
							|it = 'Documento primario';
							|pl = 'Podstawowy dokument';
							|tr = 'Kaynak belge'"));
	Return ArrayOfNames
EndFunction

// Returns the structure of parameters for filling in sales VAT taxation.
//
// Parameters:
//  Object - DocumentObject.SourceDocument, FormDataStructure - the document to generate parameters for.
//
// Returns:
//  See VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation
//
Function ParametersForFillingInVATTaxation_(Object) Export
	
	ObjectData = Object;
	FillParameters = New Structure;
	FillParameters.Insert("Sale", False);
	FillParameters.Insert("Purchase", False);
	
	If ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.GoodsShipmentToCustomer Then
	
		FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
		
		FillParameters.Organization = ObjectData.Organization;
		FillParameters.Date = ObjectData.Date;
		FillParameters.Contract = ObjectData.Contract;
		FillParameters.LineOfBusiness = ObjectData.LineOfBusiness;
		FillParameters.Department = ObjectData.Department;
		
		FillParameters.GoodsSales = True;
		FillParameters.ImplementationOfWorksServices = True;
		
		FillParameters.Insert("Sale", True);
		FillParameters.Insert("Purchase", False);
		
	ElsIf ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment
		Or ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
		
		FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
		
		FillParameters.Contract = ObjectData.Contract; 
		FillParameters.Period  = ObjectData.Date;
		FillParameters.Counterparty = ?(ObjectData.Counterparty = Undefined,
			Catalogs.Counterparties.EmptyRef(), ObjectData.Counterparty);
		
		If ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.PurchaseViaAdvanceHolder Then
			FillParameters.PurchaseOfGoods = True;
			FillParameters.AcquisitionOfWorks = True;
			FillParameters.PurchaseOnArticles = True;
			FillParameters.RedemptionOfReturnablePackagingFromVendor = True;
			FillParameters.ConsignmentProcurement = True;
			FillParameters.ImportOfGoods = True;
			FillParameters.RentalService = True;
			FillParameters.ImportOfGoodsFromCustomsUnion = True;
			FillParameters.ReturnOfGoodsToVendor = True;
			FillParameters.ReturnOfGoodsToConsignor = True;
			FillParameters.ReceiptOfGoodsInTransit = True;
			FillParameters.ReceiptFromProcessing = True;
			FillParameters.VMIProcurement = True;
		Else
			FillParameters.PurchaseViaAdvanceHolder = True;
		EndIf;
		
		If TypeOf(ObjectData.Counterparty) = Type("CatalogRef.Companies") Then
			FillParameters.ThisIsOperationBetweenOrganizations = True;
		EndIf;
		
		FillParameters.Insert("Sale", False);
		FillParameters.Insert("Purchase", True);
	ElsIf ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider Then
	
		FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
		FillParameters.Organization				= Object.Organization;
		FillParameters.Date					= Object.Date;
		FillParameters.Contract					= Object.Contract;
		FillParameters.LineOfBusiness	= Object.LineOfBusiness;
		FillParameters.ReportToMaterialProvider			= True;
		
		FillParameters.Insert("Sale", True);
		FillParameters.Insert("Purchase", False);
		
	
	ElsIf ObjectData.SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport Then
	
		FillParameters = VATAccountingERPClientServer.ParametersForFillingInVATTaxationPurchases();
		FillParameters.Contract = ObjectData.Contract; 
		FillParameters.Period  = ObjectData.Date;
		FillParameters.Counterparty = ?(ObjectData.Counterparty = Undefined,
			Catalogs.Counterparties.EmptyRef(), ObjectData.Counterparty);
		
		FillParameters.Insert("Sale", False);
		FillParameters.Insert("Purchase", True);
	EndIf;
	
	Return FillParameters;
	
EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ValueAllowed(Organization)";

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

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#EndRegion

#Region Private

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - The collection of elements:
//     of the assignment tables is a table of data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.SourceDocument") Then
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
		
		GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName           = "Document.SourceDocument";

	ParameterValues = New Structure;
	ParameterValues.Insert("MetadataObjectID",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
	EndIf;
	
	If RegisterName = "DocumentsRegistry" Then
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText, FullDocumentName, SynonymForDocumentTable, True);
	Else
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText, FullDocumentName, SynonymForDocumentTable);
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	
	Query.Text = "
	|SELECT
	|	DocumentData.Ref                  AS Ref,
	|	DocumentData.Date                    AS Period,
	|	DocumentData.Number                   AS Number,
	|	DocumentData.Currency                  AS Currency,
	|	DocumentData.Organization             AS Organization,
	|	DocumentData.Department           AS Department,
	|	DocumentData.Comment             AS Comment,
	|	DocumentData.DocumentAmount          AS DocumentAmount,
	|	DocumentData.Partner                 AS Partner,
	|	DocumentData.Counterparty              AS Counterparty,
	|	DocumentData.Contract                 AS Contract,
	|	DocumentData.SourceDocumentType  AS SourceDocumentType,
	|	DocumentData.DeletionMark         AS DeletionMark,
	|	DocumentData.Posted                AS Posted
	|FROM
	|	Document.SourceDocument AS DocumentData
	|	
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	For Each KeyAndValue In ValuesOfHoldingParameters(Attributes) Do
		Query.SetParameter(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;
	
	Query.SetParameter("MetadataObjectID", Common.MetadataObjectID("Document.SourceDocument"));
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Function ValuesOfHoldingParameters(Attributes = Undefined)
	
	Values = New Structure;
	Values.Insert("MetadataIdentifier",                       Common.MetadataObjectID("Document.SourceDocument"));
	Values.Insert("BusinessOperation",                         Enums.BusinessTransactions.ReceiptOfServices);
	Values.Insert("ManagementAccountingCurrency",                    Constants.ManagementAccountingCurrency.Get());
	
	If Attributes <> Undefined Then
		Coefficients = ProcessingOfExchangeRatesTM.GetCurrencyConversionRates_(
			Attributes.Currency, Undefined, Attributes.Period, Attributes.Organization);
			
		Values.Insert("ConversionRateToManCurrency",            Coefficients.ConversionRateToManCurrency);
		Values.Insert("FactorOfConversionToCurrencyOfRegul",           Coefficients.FactorOfConversionToCurrencyOfRegul);
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Attributes.Organization));
	Else
		Values.Insert("LocalAccountingCurrency", SettingsValueCached.DefaultBaseCurrency());
	EndIf;
	
	Return Values;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	ValueText_ = "
	|SELECT
	|	Operation.Date                                AS Period,
	|	Operation.Ref                              AS Ref,
	|	Operation.Organization                         AS Organization,
	|	Operation.Department                       AS Department,
	|	Operation.Counterparty                          AS Counterparty,
	|	Operation.Contract                             AS Contract,
	|	Operation.Counterparty                          AS Shipper,
	|	Operation.Ref                              AS DocumentAcquisitions,
	|	Operation.Ref                              AS OriginalTradeDocument,
	|	FALSE                                         AS ErrorCorrection,
	|	FALSE                                         AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                         AS ReduceAmountVATDeduction,
	|	UNDEFINED                                 AS PurchaseAdjustmentDocument,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATTaxation,
	|	VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT) AS VATActivityType,
	|	VALUE(Catalog.VATRates.EmptyRef)  AS VATRate,
	|	UNDEFINED                                 AS Products,
	|	UNDEFINED                                 AS InventoryOwnerAttribute,
	|	UNDEFINED                                 AS CCDNumber,
	|	Operation.Department                       AS AccountingDivision,
	|	Operation.LineOfBusiness             AS LineOfBusiness,
	|	FALSE                                         AS PurchasePerBatchOfProduction,
	|	UNDEFINED                                 AS LineOfBusinessOfProductionParty,
	|	UNDEFINED 								 AS ToExpenseAs,
	|	UNDEFINED                                 AS ExpenseItem,
	|	UNDEFINED                                 AS DimensionOfExpenses,
	|	UNDEFINED                                 AS ItemOfOtherAssets,
	|	UNDEFINED                                 AS AnalyticsOfOtherAssets,
	|	UNDEFINED                                 AS Purpose,
	|	""""                                         AS RowID,
	|	&FinRecordID                      AS FinRecordID,
	|	UNDEFINED                                 AS BusinessTransactionSetting
	|FROM
	|	Document.SourceDocument AS Operation
	|WHERE
	|	Operation.Ref IN (&Ref)
	|	AND Operation.SourceDocumentType IN (VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor),
	|										 VALUE(Enum.SourceDocumentTypes.PurchaseViaAdvanceHolder))
	|";
	
	ValueText_ = StrReplace(ValueText_, "&FinRecordID", DocumentsPosting.IDOfUnusedFinRecord());
	
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, ValueText_);
	
EndProcedure

Function GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	InitializeTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts);

	RegisterName = "DocumentAmountsInAccountingCurrency";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	Table.Ref AS Recorder,
	|	Table.Date AS Period,
	|	Table.DocumentCurrency AS DocumentCurrency,
	|	Table.ARAPCurrency AS ARAPCurrency,
	|	Table.RowID AS RowID,
	|	Table.VATRate AS VATRate,
	|	Table.AmountIncludingVAT AS AmountIncludingVAT,
	|	Table.VATAmount AS VATAmount,
	|	Table.AmountExcludingVAT AS AmountExcludingVAT,
	|	Table.AmountARAP AS AmountARAP,
	|	Table.AmountVATARAP AS AmountVATARAP,
	|	Table.AmountIncludingVATMan AS AmountIncludingVATMan,
	|	Table.VATAmountMan AS VATAmountMan,
	|	Table.AmountExcludingVATMan AS AmountExcludingVATMan,
	|	Table.AmountIncludingVATCompl AS AmountIncludingVATCompl,
	|	Table.VATAmountCompl AS VATAmountCompl,
	|	Table.VATBaseLocal AS VATBaseLocal,
	|	Table.AmountExcludingVATCompl AS AmountExcludingVATCompl,
	|	Table.ARAPObject AS ARAPObject,
	|	Table.PaymentType_ AS PaymentType_,
	|	Table.RecordedInARAPAccounting AS RecordedInARAPAccounting,
	|	DATETIME(1,1,1) AS VATBasePeriod,
	|	FALSE AS RecalculateBasedOnARAPData
	|FROM
	|	TTAmountsOfDocumentsInAccountingCurrencies AS Table";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS IBDocumentDate,
	|	DocumentData.Number AS IBDocumentNumber,
	|	&MetadataObjectID AS RefType,
	|	DocumentData.Organization        AS Organization,
	|	CASE
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.SaleToCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.GoodsShipmentToCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsShipmentToCustomer)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.CustomerBonusCertificate)
	|			THEN VALUE(Enum.BusinessTransactions.RecordCustomerBonusRebates)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.VendorBonusCertificate)
	|			THEN VALUE(Enum.BusinessTransactions.RecordVendorBonusRebate)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseFromSupplier)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.SaleAdjustment)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.PurchaseAdjustment)
	|			THEN VALUE(Enum.BusinessTransactions.ARAPAdjustment)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.PurchaseViaAdvanceHolder)
	|			THEN VALUE(Enum.BusinessTransactions.PurchaseViaAdvanceHolder)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.PaymentFromCustomer)
	|			THEN VALUE(Enum.BusinessTransactions.CashReceiptFromCustomer)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.PaymentToVendor)
	|			THEN VALUE(Enum.BusinessTransactions.PaymentToVendor)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.InternalInvoice)
	|			THEN VALUE(Enum.BusinessTransactions.GoodsRecordingAsReceived)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.VMIProcurement)
	|			THEN VALUE(Enum.BusinessTransactions.ReceiptFromMaterialProvider2_5)
	|		WHEN DocumentData.SourceDocumentType =  VALUE(Enum.SourceDocumentTypes.ReportToMaterialProvider)
	|			THEN VALUE(Enum.BusinessTransactions.TollManufacturing2_5)
	|	END AS BusinessOperation,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract  AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	UNDEFINED AS StorageLocation,
	|	DocumentData.Department AS Department,
	|	UNDEFINED AS EmployeeResponsible,
	|	UNDEFINED AS Author,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.DocumentAmount AS Sum,
	|	UNDEFINED AS Status,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	FALSE AS AdditionalRecord,
	|	UNDEFINED AS More,
	|	DocumentData.IncomingDocumentDate AS SourceDocumentDate,
	|	DocumentData.IncomingDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.Date AS RecordingInAccountingDate,
	|	UNDEFINED                            AS Priority
	|FROM
	|	Document.SourceDocument AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure InitializeTTAmountsOfDocumentsInAccountingCurrencies(Query, QueryTexts) Export
	
	If Query.Parameters.Property("TTAmountOfDocumentsInAccountingCurrenciesInitialized") Then
		Return;
	EndIf;
	
	RequestAmountOfDocumentsInAccountingCurrencies = New Query;
	RequestAmountOfDocumentsInAccountingCurrencies.TempTablesManager = Query.TempTablesManager;
	RequestAmountOfDocumentsInAccountingCurrencies.SetParameter("Ref", Query.Parameters.Ref);
	
	RequestAmountOfDocumentsInAccountingCurrencies.Text = "
	|SELECT
	|	Operation.Ref                             AS Ref,
	|	Operation.Date                               AS Date,
	|	Operation.Currency                             AS DocumentCurrency,
	|	Operation.ARAPCurrency               AS ARAPCurrency,
	|	""""                                        AS RowID,
	|	VALUE(Catalog.VATRates.EmptyRef) AS VATRate,
	|	Operation.DocumentAmount                     AS AmountIncludingVAT,
	|	0                                           AS VATAmount,
	|	Operation.DocumentAmount                     AS AmountExcludingVAT,
	|	Operation.AmountARAP                AS AmountARAP,
	|	0                                           AS AmountVATARAP,
	|	Operation.SumMan                           AS AmountIncludingVATMan,
	|	0                                           AS VATAmountMan,
	|	Operation.SumMan                           AS AmountExcludingVATMan,
	|	Operation.SumCompl                          AS AmountIncludingVATCompl,
	|	0                                           AS VATAmountCompl,
	|	Operation.SumCompl                          AS VATBaseLocal,
	|	Operation.SumCompl                          AS AmountExcludingVATCompl,
	|	CASE 
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.SaleToCustomer)
	|			OR Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.ReportToMaterialProvider)
	|			THEN Operation.ARAPObject
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor)
	|			THEN Operation.ARAPObject
	|		ELSE UNDEFINED
	|	END AS ARAPObject,
	|	CASE 
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.SaleToCustomer)
	|			OR Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.ReportToMaterialProvider)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.CustomerARAPAccounting)
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor)
	|			THEN VALUE(Enum.PartnersARAPAccountingTypes.VendorARAPAccounting)
	|		ELSE UNDEFINED
	|	END AS PaymentType_,
	|CASE 
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.SaleToCustomer)
	|			OR Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.ReportToMaterialProvider)
	|			THEN TRUE
	|		WHEN Operation.SourceDocumentType = VALUE(Enum.SourceDocumentTypes.PurchaseFromVendor)
	|			THEN TRUE
	|		ELSE UNDEFINED
	|	END AS RecordedInARAPAccounting
	|
	|INTO TTAmountsOfDocumentsInAccountingCurrencies
	|FROM
	|	Document.SourceDocument AS Operation
	|WHERE
	|	Operation.Ref IN (&Ref)
	|";
	
	RequestAmountOfDocumentsInAccountingCurrencies.Execute();
	
	Query.SetParameter("TTAmountOfDocumentsInAccountingCurrenciesInitialized", True);
	
EndProcedure

#EndRegion

#Region Other

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	See ARAPAccountingServer.MechanismParameters
//
Function SettlementParameters_(Val FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		FillingData = Common.ObjectAttributesValues(
			FillingData, 
			"SourceDocumentType,Contract,ARAPObjectSettings");
		SourceDocumentType = FillingData.SourceDocumentType;
		Contract                = FillingData.Contract;
		ARAPObjectSettings        = FillingData.ARAPObjectSettings;
	ElsIf FillingData = Undefined Then
		SourceDocumentType = Undefined;
		Contract                = Undefined;
		ARAPObjectSettings        = Undefined
	Else
		SourceDocumentType = FillingData.SourceDocumentType;
		Contract                = FillingData.Contract;
		ARAPObjectSettings        = FillingData.ARAPObjectSettings;
	EndIf;
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.IncomingDocumentNumber = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate  = "Object.IncomingDocumentDate";
	ParametersStructure.ARAPObject          = "Object.ARAPObject";
	
	If SourceDocumentType = Enums.SourceDocumentTypes.PurchaseFromVendor Then
		ParametersStructure.ThisIsSalePurchase = True;
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ModifiesDeliveryShipmentPlan = True;
		If TypeOf(Contract) = Type("CatalogRef.LeaseContract") Then
			ParametersStructure.Contract = "";
		EndIf;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PaymentToVendor Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ChangesPaymentPlan = True;
		ParametersStructure.ARAPObjectSettings = "Object.ARAPObjectSettings";
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			ParametersStructure.ARAPObject = "";
		EndIf;
		If TypeOf(Contract) = Type("CatalogRef.LeaseContract") Then
			ParametersStructure.Contract = "";
		EndIf;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PaymentFromCustomer Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ChangesPaymentPlan = True;
		ParametersStructure.ARAPObjectSettings = "Object.ARAPObjectSettings";
		If ARAPObjectSettings = Enums.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice Then
			ParametersStructure.ARAPObject = "";
		EndIf;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleToCustomer Then
		ParametersStructure.ThisIsSalePurchase = True;
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ModifiesDeliveryShipmentPlan = True;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.CustomerBonusCertificate Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ThisIsSalePurchase = True;
		ParametersStructure.ChangesPaymentPlan = True;
		ParametersStructure.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.VendorBonusCertificate Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ThisIsSalePurchase = True;
		ParametersStructure.ChangesPaymentPlan = True;
		ParametersStructure.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.ReportToMaterialProvider Then
		ParametersStructure.PaymentType_                  = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ThisIsSalePurchase            = True;
		ParametersStructure.ModifiesDeliveryShipmentPlan = True;
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SaleAdjustment Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
		ParametersStructure.ThisIsSalePurchase            = True;
		ParametersStructure.Ref                       = "";
		ParametersStructure.Contract                      = "";
		ParametersStructure.ARAPObjectSettings              = "";
		ParametersStructure.IncomingDocumentNumber      = "";
		ParametersStructure.IncomingDocumentDate       = "";
		ParametersStructure.ARAPObject               = "";
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.PurchaseAdjustment Then
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ThisIsSalePurchase            = True;
		ParametersStructure.Ref                       = "";
		ParametersStructure.Contract                      = "";
		ParametersStructure.ARAPObjectSettings              = "";
		ParametersStructure.IncomingDocumentNumber      = "";
		ParametersStructure.IncomingDocumentDate       = "";
		ParametersStructure.ARAPObject               = "";
	ElsIf SourceDocumentType = Enums.SourceDocumentTypes.SubcontractorReport Then
		ParametersStructure.ThisIsSalePurchase = True;
		ParametersStructure.PaymentType_ = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
		ParametersStructure.ModifiesDeliveryShipmentPlan = True;
	Else
		ParametersStructure.ChangesPaymentPlan = False;
		ParametersStructure.ModifiesDeliveryShipmentPlan = False;
	EndIf;
	
	ParametersStructure.ARAPCurrency                 = "Object.ARAPCurrency";
	ParametersStructure.AmountARAP                  = "Object.AmountARAP";
	
	#Region EditingCurrenciesAndCurrencyAmountsOfDocument
	
	// The course of the document is one pair for the document.
	// They are used to calculate the amount of mutual settlements and in the form of editing the currencies and exchange rates of the document.
	ParametersStructure.CourseNumerator                        = "Object.CourseNumerator";
	ParametersStructure.CourseDenominator                      = "Object.CourseDenominator";
	
	// The name of the hyperlink displaying the current exchange rate of the document and opening the corresponding form.
	ParametersStructure.FormItems.LabelCurrencies          = "CurrencyDecoration";
	ParametersStructure.DocumentCurrencyViewOnly        = True;
	
	#EndRegion
	
	ParametersStructure.ForeignCurrencyTransaction = "";
	ParametersStructure.CompanyBankAccount = "";
	ParametersStructure.CounterpartyBankAccount = "";
	ParametersStructure.CashAccount = "";
	ParametersStructure.PaymentMethod = "";
	ParametersStructure.Terms = "";
	
	Return ParametersStructure;
	
EndFunction

Procedure UpdateCalculationObject(Object, Cancel) Export
	
	If Object.ARAPObjectSettings = Enums.ARAPObjectSettings.ByARAPDocuments Then
		Documents.SourceDocument.GenerateCalculationObject(Object);
	Else
		If ValueIsFilled(Object.Ref) Then
			ARAPObject = ARAPObjectsServer.GetCalculationObjectFromLink(Object.Ref);
			If ValueIsFilled(ARAPObject) Then
				ARAPObjectsServer.CheckDeleteCalculationObject(ARAPObject, Cancel, False);
			EndIf;
		EndIf;
	EndIf;
	
EndProcedure

Function GenerateCalculationObject(Object, UseInSettlementRegisters = Undefined) Export
	
	GenerationParameter = SettlementParameters_(Object);
	
	GenerationParameter.VATTaxation        = "Object.VATTaxation";
	GenerationParameter.LineOfBusiness   = "Object.LineOfBusiness";
	
	If Object.IsNew() Then
		RefToNew = GetRef();
		Object.SetNewObjectRef(RefToNew);
		GenerationParameter.Insert("RefToNew", RefToNew);
	EndIf;
	
	GenerationParameters_ = CommonClientServer.ValueInArray(GenerationParameter);
	ARAPAccountingServer.AugmentedMechanismParameters(Object, GenerationParameters_);
	
	ARAPObject = Undefined;
	For Each GenerationParameter In GenerationParameters_ Do
		ARAPObject = ARAPObjectsServer.CheckFillInCalculationObjectByStructure(Object, GenerationParameter);
	EndDo;
	
	Return ARAPObject;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers_

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Add("Ref");
	Fields.Add("SourceDocumentType");
	Fields.Add("Number");
	Fields.Add("Date");
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	
EndProcedure

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	StandardProcessing = False;
	If ValueIsFilled(Data.Number) Then
		Presentation = StrTemplate(NStr("vi = '%1 %2 ngày %3';
										|ru = '%1 %2 от %3';
										|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
										|it = '%1 %2 del %3';
										|pl = '%1 %2 z dnia %3';
										|tr = '%3 tarihli %1 %2'"), Data.SourceDocumentType, TrimAll(Data.Number), Data.Date);
	Else
		Presentation = StrTemplate(NStr("vi = '%1 (tạo mới)';
										|ru = '%1 (создание)';
										|en = '%1 (Create)'; fa = '%1 (Create)';
										|it = '%1 (creazione)';
										|pl = '%1 (utworzenie)';
										|tr = '%1 (oluşturma)'"), Data.SourceDocumentType);
	EndIf;
	
	TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
		Data, Presentation, StandardProcessing, "SourceDocument");
	
EndProcedure

#EndRegion
