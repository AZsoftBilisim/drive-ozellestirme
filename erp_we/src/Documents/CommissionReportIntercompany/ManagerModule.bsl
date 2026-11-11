#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Organization");
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Organization";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Manager", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Manager";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Consignee";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Consignee";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ExternalDocumentName", Parameters);
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Organization";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Organization";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"CompanyBankAccount", Parameters);

	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "Consignee";
	Parameters.StatisticsCollectionSections.UseOnlyCompletedFields = "Contract, Currency";
	Parameters.FillInIf.ObjectFieldsFilledIn = "Consignee";
	Parameters.StatisticsCollectionParameters.SelectionSize = 2;
	Parameters.StatisticsCollectionParameters.IfThereIsNoDataGetValueWithoutTakingIntoAccountAuthor = True;
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"RecipientCompanyBankAccount", Parameters);
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("ARAPAccounting");
	DocumentMechanisms.Add("Purchases");
	DocumentMechanisms.Add("FinancialAccounting");
	DocumentMechanisms.Add("CirculatingRegistersOfManagementAccounting");
	DocumentMechanisms.Add("HandoverForSafekeeping");
	DocumentMechanisms.Add("ReceivingForSafekeeping");
	DocumentMechanisms.Add("DocumentsRegistry");
	DocumentMechanisms.Add("CostAndBatchAccounting");
	DocumentMechanisms.Add("AccountingOfIncomeExpenses");
	DocumentMechanisms.Add("DocumentAmountsInAccountingCurrency");
	DocumentMechanisms.Add("VATAccounting");
	DocumentMechanisms.Add("AccountingForOtherAssetsLiabilities");
	DocumentMechanisms.Add("DocumentCorrection");
	
	CommissionReportIntercompanyLocalization.RegisterAccountingMechanisms(DocumentMechanisms);
	
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
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CommissionReportIntercompany") Then
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
		
		QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers);
		QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers);
		QueryTextTablePurchases(Query, QueryTexts, Registers);
		QueryTextGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers);
		QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers);
		QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers);
		QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers);
		
		CostCalculationDocumentsPosting.ReflectInCostAndCostAccountingMechanism(DocumentRef, Query, QueryTexts, Registers);
		
		ReflectVATInAccounting_(Query, QueryTexts, Registers);
		
		AddTextsToReflectSettlements(Query, QueryTexts, Registers);
		
		CommissionReportIntercompanyLocalization.AddRequestTexts(Query, QueryTexts, Registers);
	EndIf;
	
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
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	NewCommand = Documents.PaymentRequest.AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands);
	If NewCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(NewCommand, "KeepCommissionFee", False);
	EndIf;
	
	NewCommand = Documents.BankAccountIssue.AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands);
	If NewCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(NewCommand, "KeepCommissionFee", False);
	EndIf;
	
	NewCommand = Documents.BankAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Presentation = NStr("vi = 'Thu tiền vào tài khoản ngân hàng cho người đặt ký gửi (thanh toán từ đại lý hoa hồng)';
										|ru = 'Поступление безналичных ДС комитенту (оплата от комиссионера)';
										|en = 'Incoming payment to consignor'; fa = 'Incoming payment to consignor';
										|it = 'Entrata dei mezzi monetari cashless al committente (pagamento dal commissionario)';
										|pl = 'Odbiór bezgotówkowego SP od zleceniodawcy (płatność od komisanta)';
										|tr = 'Göndericiye gayri Nakit tahsilatı (konsinyeden ödeme)'");
	EndIf;
	
	NewCommand = Documents.PaymentRequest.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Presentation = NStr("vi = 'Giấy đề nghị thanh toán của người nhận ký gửi (thanh toán cho người đặt ký gửi)';
										|ru = 'Заявка на расходование ДС комиссионера (оплата комитенту)';
										|en = 'Payment request from consignee''s account'; fa = 'Payment request from consignee''s account';
										|it = 'Domanda di spesa dei mezzi monetari del commissionario (pagamento al committente)';
										|pl = 'Wniosek o wydatki SP komisanta (wypłata komisanta)';
										|tr = 'Konsinyenin Nakit harcanması için başvuru (göndericiye ödeme)'");
	EndIf;
	
	NewCommand = Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	If NewCommand <> Undefined Then
		NewCommand.Presentation = NStr("vi = 'Chi tiền từ tài khoản ngân hàng của người nhận ký gửi (thanh toán cho tiền gốc)';
										|ru = 'Списание безналичных ДС комиссионера (оплата комитенту)';
										|en = 'Payment from consignee''s bank account'; fa = 'Payment from consignee''s bank account';
										|it = 'Storno dei mezzi monetari cashless del commissionario (pagamento al committente)';
										|pl = 'Obciążenie bezgotówkowych SP komisanta (wypłata komitenta)';
										|tr = 'Konsinyenin giden ödeme — banka hesabı (göndericiye ödeme)'");
	EndIf;
	
	NewCommand = Documents.BankAccountReceiptNote.AddCreateBasedOnCommissionReportCommand_Remuneration(GenerationCommands);
	If NewCommand <> Undefined Then
		AttachableCommands.AddCommandVisibilityCondition(NewCommand, "KeepCommissionFee", False);
	EndIf;
	
	Documents.ARAPAccountingScheduleAdjustment.AddGenerateCommand(GenerationCommands);
	
	DocumentCorrection.AddCorrectionCommand(GenerationCommands, EmptyRef().Metadata());
	DocumentCorrection.AddReverseCommand(GenerationCommands, EmptyRef().Metadata());
	
	CommissionReportIntercompanyLocalization.AddGenerationCommands(GenerationCommands, Parameters);
	
EndProcedure

// Adds the command to create the document "report on Commission between organizations".
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  Undefined, ValueTableRow - Add a create command based on
Function AddGenerateCommand(GenerationCommands) Export
	If AccessRight("Insert", Metadata.Documents.CommissionReportIntercompany) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CommissionReportIntercompany.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CommissionReportIntercompany);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseCustomerInvoiceIntercompany";
	

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
	
	Reports.ControlOfCustomerInvoicesIntercompany.AddReportGenerationCommand(ReportsCommands);
	
	CommissionReportIntercompanyLocalization.AddReportCommands(ReportsCommands, Parameters);

EndProcedure

// The procedure fills in arrays of details that depend on the method of calculating remuneration.
//
// Parameters:
//	CommissionFeeCalculationMethod - EnumRef.CommissionFeeCalculationMethods - Selected method for calculating remuneration
//	ArrayOfAllProps - Array - Array of all the names of Bank details that depend on the method of calculating remuneration
//	ArrayOfOperationDetails - Array - Array of names of details used in the selected method of calculating remuneration.
//
Procedure FillInNamesOfDetailsAccordingToMethodOfCalculatingRemuneration(CommissionFeeCalculationMethod, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("RemunerationPercentage");
	ArrayOfAllProps.Add("CommissionAmount");
	ArrayOfAllProps.Add("VATRateOfRemuneration");
	ArrayOfAllProps.Add("AmountVATRemuneration");
	ArrayOfAllProps.Add("KeepCommissionFee");
	ArrayOfAllProps.Add("OperationService");
	ArrayOfAllProps.Add("Goods.CommissionAmount");
	ArrayOfAllProps.Add("ExpenseItem");
	
	ArrayOfOperationDetails = New Array;
	If CommissionFeeCalculationMethod <> Enums.CommissionFeeCalculationMethods.NotCalculating Then
		ArrayOfOperationDetails.Add("RemunerationPercentage");
		ArrayOfOperationDetails.Add("CommissionAmount");
		ArrayOfOperationDetails.Add("VATRateOfRemuneration");
		ArrayOfOperationDetails.Add("AmountVATRemuneration");
		ArrayOfOperationDetails.Add("KeepCommissionFee");
		ArrayOfOperationDetails.Add("OperationService");
		ArrayOfOperationDetails.Add("Goods.CommissionAmount");
		ArrayOfOperationDetails.Add("ExpenseItem");
	EndIf;
	
EndProcedure

// This function defines the document details.
//
// Parameters:
//  DocumentRef - DocumentRef.CommissionReportIntercompany - link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Date AS Date,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Consignee AS CompanyRecipient,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|
	|	CASE WHEN DocumentData.KeepCommissionFee THEN
	|   	DocumentData.DocumentAmount - DocumentData.CommissionAmount
	|	ELSE
	|		DocumentData.DocumentAmount
	|	END AS AmountARAP,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|
	|	DocumentData.BeginOfPeriod AS BeginOfPeriod,
	|	DocumentData.EndOfPeriod AS EndOfPeriod,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Partner AS Partner,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.LineOfBusiness AS LineOfBusiness,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.ARAPObjectSettings AS ARAPObjectSettings,
	|	DocumentData.SalesContract AS SalesContract,
	|	DocumentData.PurchasingContract AS PurchasingContract
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Date = Selection.Date;
		Organization = Selection.Organization;
		CompanyRecipient = Selection.CompanyRecipient;
		ARAPCurrency = Selection.ARAPCurrency;
		DocumentAmount = Selection.DocumentAmount;
		AmountARAP = ?(Selection.Posted, Selection.AmountARAP, 0);
		CommissionAmount = ?(Selection.Posted, Selection.CommissionAmount, 0);
		BeginOfPeriod = Selection.BeginOfPeriod;
		EndOfPeriod = Selection.EndOfPeriod;
		ARAPAccountingViaSeparateCounterparty = Selection.ARAPAccountingViaSeparateCounterparty;
		Partner = ?(ARAPAccountingViaSeparateCounterparty, Selection.Partner, Catalogs.Partners.OurEnterprise);
		Counterparty = ?(ARAPAccountingViaSeparateCounterparty, Selection.Counterparty, Selection.Organization);
		LineOfBusiness = Selection.LineOfBusiness;
		ARAPObjectSettings = Selection.ARAPObjectSettings;
		Contract = Selection.Contract;
		SalesContract = Selection.SalesContract;
		PurchasingContract = Selection.PurchasingContract;
	Else
		Date = Date(1,1,1);
		Organization = Catalogs.Companies.EmptyRef();
		CompanyRecipient = Catalogs.Companies.EmptyRef();
		ARAPCurrency = Catalogs.Currencies.EmptyRef();
		DocumentAmount = 0;
		AmountARAP = 0;
		CommissionAmount = 0;
		BeginOfPeriod = Undefined;
		EndOfPeriod = Undefined;
		ARAPAccountingViaSeparateCounterparty = False;
		Partner = Catalogs.Partners.EmptyRef();
		Counterparty = Catalogs.Counterparties.EmptyRef();
		LineOfBusiness = Catalogs.LinesOfBusiness.EmptyRef();
		Contract = Catalogs.IntercompanyContracts.EmptyRef();
		ARAPObjectSettings = Enums.ARAPObjectSettings.EmptyRef();
		SalesContract = Catalogs.CounterpartyContracts.EmptyRef();
		PurchasingContract = Catalogs.CounterpartyContracts.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure();
	AttributesStructure1.Insert("Date", Date);
	AttributesStructure1.Insert("Organization", CompanyRecipient);
	AttributesStructure1.Insert("ARAPCurrency", ARAPCurrency);
	AttributesStructure1.Insert("BusinessOperation", Enums.BusinessTransactions.CommissionReportIntercompany);
	AttributesStructure1.Insert("DocumentAmount", DocumentAmount);
	AttributesStructure1.Insert("AmountARAP", AmountARAP);
	AttributesStructure1.Insert("CommissionAmount", CommissionAmount);
	AttributesStructure1.Insert("SenderOrganization", Organization);
	AttributesStructure1.Insert("CompanyRecipient", CompanyRecipient);
	AttributesStructure1.Insert("BeginOfPeriod", BeginOfPeriod);
	AttributesStructure1.Insert("EndOfPeriod", EndOfPeriod);
	AttributesStructure1.Insert("ARAPAccountingViaSeparateCounterparty", ARAPAccountingViaSeparateCounterparty);
	AttributesStructure1.Insert("Partner", Partner);
	AttributesStructure1.Insert("Counterparty", Counterparty);
	AttributesStructure1.Insert("LineOfBusiness", LineOfBusiness);
	AttributesStructure1.Insert("SalesContract", SalesContract);
	AttributesStructure1.Insert("PurchasingContract", PurchasingContract);
	If Not ARAPAccountingViaSeparateCounterparty Then
		AttributesStructure1.Insert("Contract", Contract);
	EndIf;
	AttributesStructure1.Insert("ARAPObjectSettings", ARAPObjectSettings);
	Return AttributesStructure1;
EndFunction

// Returns an array of valid names for incoming documents.
// 
// Returns:
// 	Array - array of names.
Function NamesOfIncomingDocuments() Export
	ArrayOfNames = New Array();
	ArrayOfNames.Add(NStr("vi = 'Báo cáo ký gửi';
							|ru = 'Отчет по комиссии';
							|en = 'Report on commission'; fa = 'گزارش حق‌العمل';
							|it = 'Report sulla commissione';
							|pl = 'Raport o prowizji';
							|tr = 'Komisyon raporu'"));
	CommissionReportIntercompanyLocalization.AddNamesOfIncomingDocuments(ArrayOfNames);
	Return ArrayOfNames
EndFunction

// The function returns the request text to reflect the document in regulated accounting.
//
// Returns:
//	String - Query text
//
Function TextOfReflectionInLocalAccounting() Export

	Return CommissionReportIntercompanyLocalization.TextOfReflectionInLocalAccounting();

EndFunction

// The function returns the request text for additional temporary tables
// that are required for reflection in regulated accounting.
//
// Returns:
//	String - The text of the request to create temporary tables.
//
Function RequestTextTTReflectedInLocalAccounting() Export

	Return CommissionReportIntercompanyLocalization.RequestTextTTReflectedInLocalAccounting();

EndFunction

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export

	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	( ValueAllowed(Organization)
	|	OR ValueAllowed(Consignee)
	|	) AND ValueAllowed(Partner)
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

// Returns parameters for filling in VAT taxation.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CommissionReportIntercompany, DocumentObject.CommissionReportIntercompany - document of the Commission report between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.The parameters of the filling of the taxable sales().
//
Function ParametersForFillingInVATTaxation_(Document) Export
	
	DocumentAttributes = New Structure("Date, Organization, Contract, SalesContract, 
										|ARAPAccountingViaSeparateCounterparty, LineOfBusiness");
	
	If TypeOf(Document) = Type("DocumentRef.CommissionReportIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	FillParameters = VATAccountingERPClientServer.ParametersForFillingInSalesVATTaxation();
	FillPropertyValues(FillParameters, DocumentAttributes, "Date, Organization, LineOfBusiness");
	
	FillParameters.Contract    = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.SalesContract,
										DocumentAttributes.Contract);
	
	FillParameters.ConsignmentReportFromCustomer = True;
	
	FillParameters.ThisIsOperationBetweenOrganizations = True;
	
	Return FillParameters;
	
EndFunction

// Returns the parameters to register the issued invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CommissionReportIntercompany, DocumentObject.CommissionReportIntercompany - document of the Commission report between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of the Invoice data().
//
Function ParametersForRegisteringInvoicesIssued(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, Consignee, Counterparty, VATTaxation, 
										|ARAPAccountingViaSeparateCounterparty, CommissionFeeCalculationMethod, CommissionAmount");
	
	If TypeOf(Document) = Type("DocumentRef.CommissionReportIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesIssued();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, VATTaxation");
	
	RegistrationParameters.Organization = DocumentAttributes.Consignee;
	RegistrationParameters.Counterparty  = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.Organization);
	
	RemunerationIsCalculated = ValueIsFilled(DocumentAttributes.CommissionAmount)
									And Not (DocumentAttributes.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	
	RegistrationParameters.ImplementationOfWorksServices = RemunerationIsCalculated;
	
	Return RegistrationParameters;
	
EndFunction

// Returns the parameters for the registration of invoices to the Commission.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CommissionReportIntercompany, DocumentObject.CommissionReportIntercompany - document of the Commission report between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the account registration to the Invoice Commissioner().
//
Function ParametersForRegisteringInvoicesToCommissionAgent(Document) Export
	
	DocumentAttributes = New Structure("Ref, Organization, Consignee, Counterparty, VATTaxation, 
										|ARAPAccountingViaSeparateCounterparty");
	
	If TypeOf(Document) = Type("DocumentRef.CommissionReportIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesToCommissionAgent();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Organization, VATTaxation");
	
	RegistrationParameters.Counterparty = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.Consignee);
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters for registering received invoices.
//
// Parameters:
//	Document - FormDataStructure, DocumentRef.CommissionReportIntercompany, DocumentObject.CommissionReportIntercompany - document of the Commission report between organizations.
//
// Returns:
//	Structure - the composition of the fields is set in the Accountingsupplientserver function.Parameters of the registration of invoices received().
//
Function ParametersForRegisteringInvoicesReceived(Document) Export
	
	DocumentAttributes = New Structure("Ref, Date, Organization, Consignee, Counterparty, VATTaxation, 
										|ARAPAccountingViaSeparateCounterparty, CommissionFeeCalculationMethod, CommissionAmount");
	
	If TypeOf(Document) = Type("DocumentRef.CommissionReportIntercompany") Then
		DocumentAttributes = Common.ObjectAttributesValues(Document, DocumentAttributes);
	Else
		FillPropertyValues(DocumentAttributes, Document);
	EndIf;
	
	RegistrationParameters = VATAccountingERPClientServer.ParametersForRegisteringInvoicesReceived();
	FillPropertyValues(RegistrationParameters, DocumentAttributes, "Ref, Date, Organization, VATTaxation");
	
	RegistrationParameters.Counterparty = ?(DocumentAttributes.ARAPAccountingViaSeparateCounterparty,
										DocumentAttributes.Counterparty,
										DocumentAttributes.Consignee);
	
	RemunerationIsCalculated = ValueIsFilled(DocumentAttributes.CommissionAmount)
									And Not (DocumentAttributes.CommissionFeeCalculationMethod = Enums.CommissionFeeCalculationMethods.NotCalculating);
	
	RegistrationParameters.PurchaseOfGoodsWorksServices = RemunerationIsCalculated;
	
	Return RegistrationParameters;
	
EndFunction

// Returns parameters of the settlement mechanism.
//
// Parameters:
// 	FillingData - DocumentObject, CatalogObject, DocumentRef, CatalogRef, Structure, FormDataStructure - An object or collection for
//              calculating settlement parameters.
//
// Returns:
// 	Array of See ARAPAccountingServer.MechanismParameters - Array of parameters of the functions of the settlement mechanism.
//
Function SettlementParameters_(FillingData = Undefined) Export
	
	If Common.RefTypeValue(FillingData) Then
		StructureFillingData = Common.ObjectAttributesValues(
			FillingData, 
			"ARAPAccountingViaSeparateCounterparty,
			|KeepCommissionFee,
			|SalesContract,
			|PurchasingContract");
		ARAPAccountingViaSeparateCounterparty = StructureFillingData.ARAPAccountingViaSeparateCounterparty;
		KeepCommissionFee            = StructureFillingData.KeepCommissionFee;
		SalesContract                    = StructureFillingData.SalesContract;
		PurchasingContract                    = StructureFillingData.PurchasingContract;
	ElsIf FillingData = Undefined Then
		ARAPAccountingViaSeparateCounterparty = False;
		KeepCommissionFee            = False;
		SalesContract                    = Undefined;
		PurchasingContract                    = Undefined;
	Else
		ARAPAccountingViaSeparateCounterparty = FillingData.ARAPAccountingViaSeparateCounterparty;
		KeepCommissionFee            = FillingData.KeepCommissionFee;
		SalesContract                    = FillingData.SalesContract;
		PurchasingContract                    = FillingData.PurchasingContract;
	EndIf;
	
	StructuresArray = New Array;
	
	#Region ConsignmentReportFromCustomer
	
	// On the part of the Committee's Organization
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.SalesContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Consignee";
	EndIf;
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSAmountWithVAT          = "SalesAmount";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	ContractSettlementProcedure = ?(ValueIsFilled(SalesContract),"Object.SalesContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroup";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroup";
	ParametersStructure.FormItems.LineOfBusiness = "LineOfBusiness";
	
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetSenderForm";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesSender";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesSender";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	ParametersStructure.PaymentSchedule                     = "Object.PaymentSchedule";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithCommissionAgent";
	
	StructuresArray.Add(ParametersStructure);
	
	// On the part of the commission agent organization
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.Organization                      = "Object.Consignee";
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.PurchasingContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Organization";
	EndIf;
	
	ContractSettlementProcedure = ?(ValueIsFilled(PurchasingContract),"Object.PurchasingContract.ARAPObjectSettings", Enums.ARAPObjectSettings.ByARAPDocuments);
	ParametersStructure.ARAPObjectSettings = ?(ARAPAccountingViaSeparateCounterparty,
											ContractSettlementProcedure,
											"Object.ARAPObjectSettings");
	
	ParametersStructure.PathToTSData                    = "Object.Goods";
	ParametersStructure.PropsNameTSAmountWithVAT          = "SalesAmount";
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithCustomer";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	ParametersStructure.CompanyBankAccount        = "Object.RecipientCompanyBankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashAccountRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.FinancialAccountingGroup           = "Object.FinancialAccountingGroupOfRecipient";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.FinancialAccountingGroup = "FinancialAccountingGroupOfRecipient";
	
	ParametersStructure.FormItems.PaymentSettlement        = "PaymentOffsetRecipientForm";
	ParametersStructure.FormItems.InscriptionStages       = "DecorationPaymentStagesRecipient";
	ParametersStructure.PaymentStepsText               = "Form.PaymentStagesRecipient";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithConsignor";
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion
	
	#Region Remuneration
	
	// On the part of the Organization of the buyer of the service
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.VendorARAPAccounting;
	ParametersStructure.ChangesPaymentPlan               = Not KeepCommissionFee;
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		ParametersStructure.ModifiesDeliveryShipmentPlan = Not KeepCommissionFee;
	EndIf;
	
	ParametersStructure.Organization                      = "Object.Organization";
	ParametersStructure.DocumentAmount                   = "Object.CommissionAmount";
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.SalesContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Consignee";
	EndIf;
	
	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
	
	ParametersStructure.CompanyBankAccount        = "Object.RecipientCompanyBankAccount";
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.CashAccount                            = "Object.CashAccountRecipient";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
	
	ParametersStructure.FormItems.PaymentSettlement        = "OffsetOfPaymentOnTheSideOfTheCommitee";
	ParametersStructure.FormItems.InscriptionStages       = "";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithCommissionAgentRemuneration";
	
	ParametersStructure.KeepCommissionFee           = KeepCommissionFee;
	
	StructuresArray.Add(ParametersStructure);
	
	// On the part of the service provider Organization
	
	ParametersStructure = ARAPAccountingServer.MechanismParameters();
	ParametersStructure.ThisIsSalePurchase                = True;
	ParametersStructure.PaymentType_                      = Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting;
	If Not GetFunctionalOption("NewOnlineARAPAccounting") Then
		ParametersStructure.ChangesPaymentPlan           = Not KeepCommissionFee;
	EndIf;
	ParametersStructure.ModifiesDeliveryShipmentPlan     = Not KeepCommissionFee;
	
	ParametersStructure.Organization                      = "Object.Consignee";
	ParametersStructure.DocumentAmount                   = "Object.CommissionAmount";
	
	If ARAPAccountingViaSeparateCounterparty Then
		ParametersStructure.Contract                      = "Object.PurchasingContract";
		ParametersStructure.Partner                      = "Object.Partner";
		ParametersStructure.Counterparty                   = "Object.Counterparty";
	Else
		ParametersStructure.Contract                      = "Object.Contract";
		ParametersStructure.Partner                      = Catalogs.Partners.OurEnterprise;
		ParametersStructure.Counterparty                   = "Object.Organization";
	EndIf;

	ParametersStructure.CourseNumerator                    = "";
	ParametersStructure.CourseDenominator                  = "";
	
	ParametersStructure.PathToTSDataPaymentDecryption  = "Object.ARAPDetailsWithVendor";
	
	// It is used to fill in the default values, fill in the schedule of scheduled payments and the payment date.
	ParametersStructure.Terms                       = "";
		
	ParametersStructure.CounterpartyBankAccount        = "";
	ParametersStructure.Manager                         = "Object.Manager";
	ParametersStructure.IncomingDocumentNumber          = "Object.IncomingDocumentNumber";
	ParametersStructure.IncomingDocumentDate           = "Object.IncomingDocumentDate";
	ParametersStructure.SourceDocumentName  = "Object.ExternalDocumentName";
		
	ParametersStructure.FormItems.PaymentSettlement        = "OffsetOfPaymentOnTheSideOfTheCommissionAgent";
	ParametersStructure.FormItems.InscriptionStages       = "";
	
	ParametersStructure.PaymentDate                      = "Object.PaymentDate";
	
	ParametersStructure.ARAPObject                   = "Object.ARAPObjectForSettlementsWithConsignorRemuneration";
	
	ParametersStructure.KeepCommissionFee           = KeepCommissionFee;
	
	StructuresArray.Add(ParametersStructure);
	
	#EndRegion

	Return StructuresArray;
	
EndFunction

// Returns a structure with the name of the tabular parts of the document that store information about the goods.
//
// Returns:
//	Structure - a collection containing the following names of table parts:
//		* Goods - ValueTable, TabularSection, Undefined - data about the goods of the document.
//	
Function CollectionOfTabularPartsOfGoods() Export
	
	DocumentTables = New Structure("Goods");
	
	Return DocumentTables;
	
EndFunction

// Creates a representation of the metadata object in the main language.
// 
// Returns:
//  String - Representation of the metadata object in the main language.
//
Function PresentationOfObjectInMainLanguage() Export
	
	DefaultLanguageCode = Common.DefaultLanguageCode();
	
	SynonymForInformationDatabaseEntry = NStr(
		"vi = 'Bảng kê hàng bán ký gửi giữa các doanh nghiệp';
		|ru = 'Отчет по комиссии между организациями';
		|en = 'Commission sales report — Intercompany'; fa = 'گزارش فروش حق‌العملی — بین‌شرکتی';
		|it = 'Report sulla commissione tra le organizzazioni';
		|pl = 'Raport po komisji sprawdzającej pomiędzy firmami';
		|tr = 'İşyerleri arası komisyon satış raporu'",
		DefaultLanguageCode);
		
	Return SynonymForInformationDatabaseEntry;
	
EndFunction
#EndRegion

#EndIf

#Region EventHandlers

Procedure PresentationGetProcessing(Data, Presentation, StandardProcessing)
	
	If Data.ARAPAccountingViaSeparateCounterparty Then
		TMCommonUseClientServer.ProcessingReceivingPresentationOfIncomingDocument(
			Data, Presentation, StandardProcessing, "CommissionReportIntercompany");
	EndIf;
	
EndProcedure

Procedure PresentationFieldsGetProcessing(Fields, StandardProcessing)
	
	StandardProcessing = False;
	Fields.Clear();
	Fields.Add("ExternalDocumentName");
	Fields.Add("IncomingDocumentNumber");
	Fields.Add("IncomingDocumentDate");
	Fields.Add("Date");
	Fields.Add("Number");
	Fields.Add("ARAPAccountingViaSeparateCounterparty");
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("Ref", DocumentRef);
	Query.Text = 
	"SELECT
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Period,
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.Currency AS ARAPCurrency,
	|	DocumentData.Organization AS Consignor,
	|	DocumentData.Organization.LocalAccountingCurrency AS LocalAccountingCurrency,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Department AS Department,
	|	DocumentData.VATTaxation AS VATTaxation,
	|	DocumentData.OperationService AS Products,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
	|	VALUE(Catalog.ItemsBatches.EmptyRef) AS Series,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Warehouse,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|	DocumentData.ARAPAccountingViaSeparateCounterparty AS ARAPAccountingViaSeparateCounterparty,
	|	DocumentData.Counterparty AS Counterparty,
	|	DocumentData.Contract AS Contract,
	|	DocumentData.SalesContract AS SalesContract,
	|	DocumentData.PurchasingContract AS PurchasingContract,
	|	DocumentData.Manager AS Manager,
	|	CASE
	|		WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
	|			THEN DocumentData.Partner
	|		ELSE VALUE(Catalog.Partners.OurEnterprise)
	|	END AS Partner,
	|	CASE
	|		WHEN DocumentData.EndOfPeriod = DATETIME(1, 1, 1)
	|				OR DocumentData.EndOfPeriod > DocumentData.Date
	|			THEN DocumentData.Date
	|		ELSE DocumentData.EndOfPeriod
	|	END AS EndOfPeriod,
	|	DocumentData.VATRateOfRemuneration,
	|	DocumentData.AmountVATRemuneration,
	|	DocumentData.CommissionAmount,
	|	DocumentData.LineOfBusiness,
	|	ISNULL(DocumentData.LineOfBusiness.CostAccounting, FALSE) AS AccountingForLBCosts,
	|	ISNULL(DocumentData.LineOfBusiness.IncomeAccounting, FALSE) AS AccountingForIncomeUnderLB,
	|	ISNULL(DocumentData.LineOfBusiness.VendorARAP, FALSE) AS AccountingForSettlementsWithSuppliersUnderLB,
	|	DocumentData.IncomingDocumentNumber AS IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate AS IncomingDocumentDate,
	|	DocumentData.ExternalDocumentName AS ExternalDocumentName,
	|	DocumentData.Comment AS Comment,
	|	DocumentData.DocumentAmount AS DocumentAmount,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObjectForSettlementsWithCommissionAgent,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObjectForSettlementsWithCommissionAgentRemuneration,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor AS ARAPObjectForSettlementsWithConsignor,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent.UUID AS IDOfPaymentObjectWithCommissionAgent,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration.UUID AS IDOfPaymentObjectWithCommissionAgentReward,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor.UUID AS IDOfPaymentObjectWithPrincipal,
	|	DocumentData.PaymentDate,
	|	DocumentData.Author,
	|	DocumentData.KeepCommissionFee,
	|	UNDEFINED AS AdjustmentPeriod_
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Attributes = Query.Execute().Select();
	Attributes.Next();
	
	MetadataIdentifier = Common.MetadataObjectID("Document.CommissionReportIntercompany");
	
	CommitteeInformation = "vi = 'Báo cáo ngày ""%1""';
							|ru = 'Отчет от ""%1""';
							|en = 'Report from ""%1""';
							|it = 'Report da ""%1""';
							|pl = 'Raport od ""%1""';
							|tr = '""%1""''dan rapor'"; // @NStr
	CommitteeInformation = StringFunctionsClientServer.SubstituteParametersToString(CommitteeInformation, Attributes.Consignor);
	
	CommissionAgentInformation = "vi = 'Báo cáo trước ""%1""';
								|ru = 'Отчет перед ""%1""';
								|en = 'Report to ""%1""';
								|it = 'Report per ""%1""';
								|pl = 'Raport dla ""%1""';
								|tr = '""%1"" karşısında rapor'"; // @NStr
	CommissionAgentInformation = StringFunctionsClientServer.SubstituteParametersToString(CommissionAgentInformation, Attributes.Consignee);
	
	DocumentNumber          = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.Number);
	IncomingDocumentNumber = ObjectsPrefixesClientServer.NumberForPrinting(Attributes.IncomingDocumentNumber);
	
	Query.SetParameter("Period",                                          Attributes.Period);
	Query.SetParameter("Number",                                           Attributes.Number);
	Query.SetParameter("EndOfPeriod",                                    EndOfDay(Attributes.EndOfPeriod));
	Query.SetParameter("Currency",                                          Attributes.Currency);
	Query.SetParameter("ARAPCurrency",                            Attributes.ARAPCurrency);
	Query.SetParameter("Organization",                                     Attributes.Consignor);
	Query.SetParameter("Consignor",                                        Attributes.Consignor);
	Query.SetParameter("Consignee",                                     Attributes.Consignee);
	Query.SetParameter("CompanyRecipient",                           Attributes.Consignee);
	Query.SetParameter("Department",                                   Attributes.Department);
	Query.SetParameter("Products",                                    Attributes.Products);
	Query.SetParameter("Characteristic",                                  Attributes.Characteristic);
	Query.SetParameter("Series",                                           Attributes.Series);
	Query.SetParameter("Purpose",                                      Attributes.Purpose);
	Query.SetParameter("VATTaxation",                              Attributes.VATTaxation);
	Query.SetParameter("BusinessOperation",                           Enums.BusinessTransactions.CommissionReportIntercompany);
	Query.SetParameter("VATRateOfRemuneration",                         Attributes.VATRateOfRemuneration);
	Query.SetParameter("AmountVATRemuneration",                          Attributes.AmountVATRemuneration);
	Query.SetParameter("CommissionAmount",                             Attributes.CommissionAmount);	
	Query.SetParameter("ConsignmentReportFromCustomer",                               Enums.BusinessTransactions.ConsignmentReportFromCustomer);
	Query.SetParameter("ConsignmentReportToVendor",                                  Enums.BusinessTransactions.ConsignmentReportToVendor);
	Query.SetParameter("CommissionAgentSReportCatalog",                     Catalogs.BusinessTransactionsSettings.ConsignmentReportFromCustomer);
	Query.SetParameter("ReportToCommitteeCatalog",                        Catalogs.BusinessTransactionsSettings.ConsignmentReportToVendor);
	Query.SetParameter("EconomicOperationRetentionOfCommissionAgent",      Enums.BusinessTransactions.CommissionAgentSRemunerationDeduction);
	Query.SetParameter("BusinessOperationRetentionByPrincipal",        Enums.BusinessTransactions.RemunerationDeductionByConsignor);
	Query.SetParameter("LocalAccountingCurrency",                  Attributes.LocalAccountingCurrency);
	Query.SetParameter("ManagementAccountingCurrency",                      Constants.ManagementAccountingCurrency.Get());
	Query.SetParameter("ARAPAccountingViaSeparateCounterparty",               Attributes.ARAPAccountingViaSeparateCounterparty);
	Query.SetParameter("Counterparty",                                      Attributes.Counterparty);
	Query.SetParameter("Contract",                                         Attributes.Contract);
	Query.SetParameter("SalesContract",                                  Attributes.SalesContract);
	Query.SetParameter("PurchasingContract",                                  Attributes.PurchasingContract);
	Query.SetParameter("ARAPObjectForSettlementsWithCommissionAgent",                    Attributes.ARAPObjectForSettlementsWithCommissionAgent);
	Query.SetParameter("ARAPObjectForSettlementsWithCommissionAgentRemuneration",      Attributes.ARAPObjectForSettlementsWithCommissionAgentRemuneration);
	Query.SetParameter("ARAPObjectForSettlementsWithConsignor",                       Attributes.ARAPObjectForSettlementsWithConsignor);
	Query.SetParameter("IDOfPaymentObjectWithCommissionAgent",      Attributes.IDOfPaymentObjectWithCommissionAgent);
	Query.SetParameter("IDOfPaymentObjectWithCommissionAgentReward", Attributes.IDOfPaymentObjectWithCommissionAgentReward);
	Query.SetParameter("IDOfPaymentObjectWithPrincipal",         Attributes.IDOfPaymentObjectWithPrincipal);
	Query.SetParameter("Manager",                                        Attributes.Manager);
	Query.SetParameter("Partner",                                         Attributes.Partner);
	Query.SetParameter("GenerateInventoryOwnerAttributesByFinancialAccountingGroups", GetFunctionalOption("GenerateInventoryOwnerAttributesByFinancialAccountingGroups"));
	Query.SetParameter("UseAgentServiceSale",               GetFunctionalOption("UseAgentServiceSale"));
	Query.SetParameter("LineOfBusiness",                         Attributes.LineOfBusiness);
	Query.SetParameter("IncomingDocumentDate",                          Attributes.IncomingDocumentDate);
	Query.SetParameter("Comment",                                     Attributes.Comment);
	Query.SetParameter("DocumentAmount",                                  Attributes.DocumentAmount);
	Query.SetParameter("Posted",                                        Attributes.Posted);
	Query.SetParameter("DeletionMark",                                 Attributes.DeletionMark);
	Query.SetParameter("MetadataIdentifier",                         MetadataIdentifier);
	Query.SetParameter("CommitteeInformation",                           CommitteeInformation);
	Query.SetParameter("CommissionAgentInformation",                        CommissionAgentInformation);
	Query.SetParameter("DocumentNumber",                                  DocumentNumber);
	Query.SetParameter("IncomingDocumentNumber",                         IncomingDocumentNumber);
	Query.SetParameter("ExternalDocumentName",                  Attributes.ExternalDocumentName);
	Query.SetParameter("PaymentDate",                                     Attributes.PaymentDate);
	Query.SetParameter("KeepCommissionFee",                          Attributes.KeepCommissionFee);
	Query.SetParameter("AccountingForLBCosts",                                  Attributes.AccountingForLBCosts);
	Query.SetParameter("AccountingForIncomeUnderLB",                                 Attributes.AccountingForIncomeUnderLB);
	Query.SetParameter("AccountingForSettlementsWithSuppliersUnderLB",                   Attributes.AccountingForSettlementsWithSuppliersUnderLB);
	Query.SetParameter("Author",                                           Attributes.Author);
	Query.SetParameter("NewOnlineARAPAccounting", GetFunctionalOption("NewOnlineARAPAccounting"));
	Query.SetParameter("AdjustmentPeriod_",                             Attributes.AdjustmentPeriod_);
	
	CostCalculationAppliedAlgorithms.FillInInitializationParameters(Query, Attributes);
	
EndProcedure

Procedure InitializeProductAccountingAnalyticsKeys(Query)
	
	If Query.Parameters.Property("ProductTrackingAnalyticsKeysInitialized") Then
		Return;
	EndIf;
	
	RequestPreliminary = New Query("
	|SELECT
	|	GoodsTable.Products	 AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Purpose	 AS Purpose,
	|	GoodsTable.Series			 AS Series,
	|	GoodsTable.Warehouse			 AS Warehouse
	|FROM (
	|	SELECT DISTINCT
	|		TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|		TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		&Series AS Series,
	|		&Consignee AS Warehouse
	|	FROM
	|		Document.CommissionReportIntercompany.InventoryKinds AS TableTypesOfStocks_
	|	WHERE
	|		TableTypesOfStocks_.Ref = &Ref
	|
	|	UNION ALL
	|	SELECT
	|		Services.Products AS Products,
	|		Services.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		&Series AS Series,
	|		ISNULL(Services.Characteristic.Principal, Services.Products.Principal) AS Warehouse
	|	FROM
	|		Document.CommissionReportIntercompany.Goods AS Services
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Services.Products = Dimension.Products
	|			AND Services.Characteristic = Dimension.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|			AND &Series = Dimension.Series
	|			AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Services.Ref = &Ref
	|		AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> UNDEFINED
	|		AND ISNULL(Services.Characteristic.Principal, Services.Products.Principal) <> &Consignee
	|		AND Dimension.DimensionKey IS NULL
	|		AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|	UNION ALL
	|	SELECT
	|		Services.Products AS Products,
	|		Services.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		&Series AS Series,
	|		&Department AS Warehouse
	|	FROM
	|		Document.CommissionReportIntercompany.Goods AS Services
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON Services.Products = Dimension.Products
	|			AND Services.Characteristic = Dimension.Characteristic
	|			AND VALUE(Catalog.Assignments.EmptyRef) = Dimension.Purpose
	|			AND &Series = Dimension.Series
	|			AND &Department = Dimension.StorageLocation
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	WHERE
	|		Services.Ref = &Ref
	|		AND (ISNULL(Services.Characteristic.Principal, Services.Products.Principal) = UNDEFINED
	|			OR ISNULL(Services.Characteristic.Principal, Services.Products.Principal) = Services.Ref.Organization)
	|		AND Dimension.DimensionKey IS NULL
	|		AND Services.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|
	|	UNION ALL
	|	SELECT
	|		Rows.ItemsLocationAttributes.Products AS Products,
	|		Rows.ItemsLocationAttributes.Characteristic AS Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
	|		&Series AS Series,
	|		Rows.InventoryAttributesOfConsignor.GoodsOwner AS Warehouse
	|	FROM
	|		Document.CommissionReportIntercompany.InventoryKinds AS Rows
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalytics
	|			ON CommitteeAnalytics.Products = Rows.ItemsLocationAttributes.Products
	|			AND CommitteeAnalytics.Characteristic = Rows.ItemsLocationAttributes.Characteristic
	|			AND CommitteeAnalytics.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND CommitteeAnalytics.Series = Rows.ItemsLocationAttributes.Series
	|			AND CommitteeAnalytics.StorageLocation = Rows.InventoryAttributesOfConsignor.GoodsOwner
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Rows.ItemsLocationAttributes.ProductCostElement
	|	WHERE
	|		Rows.Ref = &Ref
	|		AND CommitteeAnalytics.Products IS NULL
	|		AND NOT Rows.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|		AND Rows.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	) AS GoodsTable
	|
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|		ON GoodsTable.Products = Dimension.Products
	|		AND GoodsTable.Characteristic = Dimension.Characteristic
	|		AND GoodsTable.Purpose = Dimension.Purpose
	|		AND GoodsTable.Series = Dimension.Series
	|		AND GoodsTable.Warehouse = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|WHERE
	|	Dimension.Products IS NULL 
	|
	|GROUP BY
	|	GoodsTable.Warehouse,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Purpose,
	|	GoodsTable.Series
	|");
	
	RequestPreliminary.SetParameter("Ref",          Query.Parameters.Ref);
	RequestPreliminary.SetParameter("Consignee",     Query.Parameters.Consignee);
	RequestPreliminary.SetParameter("Department",   Query.Parameters.Department);
	RequestPreliminary.SetParameter("Series",           Catalogs.ItemsBatches.EmptyRef());
	
	Selection = RequestPreliminary.Execute().Select();
	While Selection.Next() Do
		InformationRegisters.ItemsLocationAttributes.CreateAnalyticsKey(Selection)
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
		Undefined, // ARAPCurrency
		Query.Parameters.Period,
		Query.Parameters.Organization);
	
	Query.SetParameter("ConversionRateToManCurrency",           Coefficients.ConversionRateToManCurrency);
	Query.SetParameter("FactorOfConversionToCurrencyOfRegul",          Coefficients.FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

Procedure SetSettlementAnalyticsParameters(Query)
	
	If Query.Parameters.Property("AnalyticsCommitteeCommissioner")
		And Query.Parameters.Property("AnalyticsCommissionerCommittee")
		And Query.Parameters.Property("SettlementAnalyticsCommitteeCommissioner")
		And Query.Parameters.Property("MutualSettlementAnalyticsCommissionAgentCommittee") Then
		Return;
	EndIf;
	
	StructureCommitteeCommissioner = New Structure();
	StructureCommitteeCommissioner.Insert("Organization", Query.Parameters.Consignor);
	StructureCommitteeCommissioner.Insert("Partner", Catalogs.Partners.OurEnterprise);
	StructureCommitteeCommissioner.Insert("Counterparty", Query.Parameters.Consignee);
	StructureCommitteeCommissioner.Insert("Contract", Query.Parameters.Contract);
	StructureCommitteeCommissioner.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AnalyticsCommitteeCommissioner = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommitteeCommissioner);
	
	StructureCommissionerCommittee = New Structure();
	StructureCommissionerCommittee.Insert("Organization", Query.Parameters.Consignee);
	StructureCommissionerCommittee.Insert("Partner", Catalogs.Partners.OurEnterprise);
	StructureCommissionerCommittee.Insert("Counterparty", Query.Parameters.Consignor);
	StructureCommissionerCommittee.Insert("Contract", Query.Parameters.Contract);
	StructureCommissionerCommittee.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
	
	AnalyticsCommissionerCommittee = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommissionerCommittee);

	If Query.Parameters.ARAPAccountingViaSeparateCounterparty Then
		
		StructureCommitteeCommissioner.Insert("Organization", Query.Parameters.Consignor);
		StructureCommitteeCommissioner.Insert("Partner", Query.Parameters.Partner);
		StructureCommitteeCommissioner.Insert("Counterparty", Query.Parameters.Counterparty);
		StructureCommitteeCommissioner.Insert("Contract", Query.Parameters.SalesContract);
		StructureCommitteeCommissioner.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);
		
		SettlementAnalyticsCommitteeCommissioner = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommitteeCommissioner);
		
		StructureCommissionerCommittee.Insert("Organization", Query.Parameters.Consignee);
		StructureCommissionerCommittee.Insert("Partner", Query.Parameters.Partner);
		StructureCommissionerCommittee.Insert("Counterparty", Query.Parameters.Counterparty);
		StructureCommissionerCommittee.Insert("Contract", Query.Parameters.PurchasingContract);
		StructureCommissionerCommittee.Insert("LineOfBusiness", Query.Parameters.LineOfBusiness);

		MutualSettlementAnalyticsCommissionAgentCommittee = InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(StructureCommissionerCommittee);
	Else
		SettlementAnalyticsCommitteeCommissioner = AnalyticsCommitteeCommissioner;
		MutualSettlementAnalyticsCommissionAgentCommittee = AnalyticsCommissionerCommittee;
	EndIf;
	
	Query.SetParameter("AnalyticsCommitteeCommissioner",               AnalyticsCommitteeCommissioner);
	Query.SetParameter("AnalyticsCommissionerCommittee",               AnalyticsCommissionerCommittee);
	Query.SetParameter("SettlementAnalyticsCommitteeCommissioner", SettlementAnalyticsCommitteeCommissioner);
	Query.SetParameter("MutualSettlementAnalyticsCommissionAgentCommittee", MutualSettlementAnalyticsCommissionAgentCommittee);
	
EndProcedure

Procedure SetProductAccountingAnalyticsParameter(Query)
	
	If Query.Parameters.Property("ItemsLocationAttributes") Then
		Return;
	EndIf;
	
	If ValueIsFilled(Query.Parameters.Products) Then
		
		StructureOfProductAccountingAnalytics = New Structure();
		StructureOfProductAccountingAnalytics.Insert("Products", Query.Parameters.Products);
		StructureOfProductAccountingAnalytics.Insert("Characteristic", Query.Parameters.Characteristic);
		StructureOfProductAccountingAnalytics.Insert("Purpose", Query.Parameters.Purpose);
		StructureOfProductAccountingAnalytics.Insert("Series", Query.Parameters.Series);
		StructureOfProductAccountingAnalytics.Insert("Warehouse", Query.Parameters.Department);
		
		Query.SetParameter("ItemsLocationAttributes", InformationRegisters.ItemsLocationAttributes.AnalyticsKeyValue(StructureOfProductAccountingAnalytics));
	Else
		Query.SetParameter("ItemsLocationAttributes", Undefined);
	EndIf;
	
EndProcedure

Function QueryTextTTTableTypesOfStocks(Query, QueryTexts)
	
	RegisterName = "TTTableTypesOfStocks";
	
	SetRequestParametersCurrencyCoefficients(Query);
	InitializeProductAccountingAnalyticsKeys(Query);
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber						AS LineNumber,
	|	TableTypesOfStocks_.InventoryOwnerAttribute						AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.Currency				AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType			AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner	AS InventoryOwnerAttributeOfCompanyGoodsOwner,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory AS SaleOfAnotherCompanyInventory,
	|	CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor <> VALUE(Catalog.InventoryKinds.EmptyRef)
	|			THEN TableTypesOfStocks_.InventoryAttributesOfConsignor
	|		WHEN TableTypesOfStocks_.InventoryOwnerAttribute.SaleOfAnotherCompanyInventory
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute.InventoryOwnerAttributeOfCompanyGoodsOwner
	|		ELSE TableTypesOfStocks_.InventoryOwnerAttribute
	|	END												AS InventoryAttributesOfConsignor,
	|	TableTypesOfStocks_.ItemsLocationAttributes		AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Purpose.LineOfBusiness AS LineOfBusiness,
	|	AnalyticsOfTransferredProduct.DimensionKey			AS AnalysisOfAccountingForTransmittedProducts,
	|	AnalyticsOfTransferredProduct.Purpose.LineOfBusiness AS LineOfBusinessTransferred,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Products AS Products,
	|	TableTypesOfStocks_.ItemsLocationAttributes.Characteristic AS Characteristic,
	|	TableTypesOfStocks_.CCDNumber							AS CCDNumber,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent		AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """")	AS CommissionAgentSTaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer						AS Customer,
	|	TableTypesOfStocks_.Count						AS Count,
	|	TableTypesOfStocks_.QuantityByGBRN					AS QuantityByGBRN,
	|	TableTypesOfStocks_.AmountIncludingVAT						AS AmountIncludingVAT,
	|	TableTypesOfStocks_.VATAmount							AS VATAmount,
	|	TableTypesOfStocks_.CommissionAmount				AS CommissionAmount,
	|	TableTypesOfStocks_.AmountVATRemuneration			AS AmountVATRemuneration,
	|	ISNULL(Amounts.AmountIncludingVATMan, 0)						AS AmountIncludingVATMan,
	|	ISNULL(Amounts.AmountExcludingVATMan, 0)					AS AmountExcludingVATMan,
	|	ISNULL(Amounts.AmountIncludingVATCompl, 0)					AS AmountIncludingVATCompl,
	|	ISNULL(Amounts.AmountExcludingVATCompl, 0)					AS AmountExcludingVATCompl,
	|	ISNULL(Amounts.VATAmountCompl, 0)						AS VATAmountCompl,
	|	TableTypesOfStocks_.VATRate						AS VATRate,
	|	TableTypesOfStocks_.RowID				AS RowID,
	|	TableTypesOfStocks_.ItemsLocationAttributes.StorageLocation AS Warehouse
	|INTO TTTypesOfStocks
	|FROM
	|	Document.CommissionReportIntercompany.InventoryKinds AS TableTypesOfStocks_
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableTypesOfStocks_.IssuedTaxInvoiceOfCommissionAgent = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|		
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS AnalyticsOfTransferredProduct
	|		ON TableTypesOfStocks_.ItemsLocationAttributes.Products = AnalyticsOfTransferredProduct.Products
	|			AND TableTypesOfStocks_.ItemsLocationAttributes.Characteristic = AnalyticsOfTransferredProduct.Characteristic
	|			AND &Consignee = AnalyticsOfTransferredProduct.StorageLocation
	|			AND VALUE(Catalog.ItemsBatches.EmptyRef) = AnalyticsOfTransferredProduct.Series
	|			AND VALUE(Catalog.Assignments.EmptyRef) = AnalyticsOfTransferredProduct.Purpose
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = AnalyticsOfTransferredProduct.ProductCostElement
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON TableTypesOfStocks_.Ref = Amounts.Ref
	|		AND TableTypesOfStocks_.RowID = Amounts.RowID
	|
	|WHERE
	|	TableTypesOfStocks_.Ref = &Ref
	|	AND TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)";
	
	QueryTexts.Add(QueryText, RegisterName); 
	
	Return QueryText;
	
EndFunction

Function QueryTextTTAgencyServices(Query, QueryTexts)
	
	RegisterName = "TTTableAgencyServices";
	
	QueryText = "
	|SELECT DISTINCT
	|	CASE WHEN NOT Services.Ref IS NULL
	|			THEN Services.Ref
	|		WHEN NOT Terms.Ref IS NULL
	|			THEN Terms.Ref
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|			THEN ServicesAgreementClosed.Ref
	|		ELSE ISNULL(AgreementClosed.Ref, UNDEFINED)
	|	END AS Terms,
	|	CASE WHEN NOT Services.Ref IS NULL
	|				THEN Services.Ref.Currency
	|		WHEN NOT Terms.Ref IS NULL
	|				THEN Terms.Currency
	|		WHEN NOT ServicesAgreementClosed.Ref IS NULL
	|				THEN ServicesAgreementClosed.Ref.Currency
	|		ELSE ISNULL(AgreementClosed.Currency, &Currency)
	|	END AS Currency,
	|	ToRegister.Products AS Products,
	|	ToRegister.Characteristic AS Characteristic,
	|	ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) AS Principal
	|INTO TTAgencyServices
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS ToRegister
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS Terms
	|	ON Terms.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND Terms.Organization = &Consignor
	|		AND Terms.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND Terms.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|		AND (&Period >= Terms.ValidityStartDate
	|			AND (&Period <= Terms.ValidityEndDate
	|			OR Terms.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS Services
	|	ON Terms.Ref = Services.Ref
	|		AND ToRegister.Products = Services.Products
	|		AND ToRegister.Characteristic = Services.Characteristic
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors AS AgreementClosed
	|	ON AgreementClosed.Partner = ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal)
	|		AND AgreementClosed.Organization = &Consignor
	|		AND AgreementClosed.BusinessOperation
	|				= VALUE(Enum.BusinessTransactions.AgentServicesDelivery)
	|		AND AgreementClosed.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Closed)
	|		AND (&Period >= AgreementClosed.ValidityStartDate
	|			AND (&Period <= AgreementClosed.ValidityEndDate
	|			OR AgreementClosed.ValidityEndDate = DATETIME(1,1,1))
	|		)
	|
	|	LEFT JOIN Catalog.TermsOfPurchaseFromVendors.AgentServices AS ServicesAgreementClosed
	|	ON AgreementClosed.Ref = ServicesAgreementClosed.Ref
	|		AND ToRegister.Products = ServicesAgreementClosed.Products
	|		AND ToRegister.Characteristic = ServicesAgreementClosed.Characteristic
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ToRegister.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND &UseAgentServiceSale";
	
	QueryTexts.Add(QueryText, RegisterName); 
	Return QueryText;
	
EndFunction

Procedure ReflectVATInAccounting_(Query, QueryTexts, Registers)
	
	If Not VATAccountingERP.VATRegistrationRequired(Registers) Then
		Return;
	EndIf;
	
	TextProducts_1 =
	"SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Consignee
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	UNDEFINED                       AS Shipper,
	|	HeaderData_.Ref                 AS ConsignmentReportFromCustomer,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	HeaderData_.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	InventoryTable.VATRate           AS VATRate,
	|	InventoryTable.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|	InventoryTable.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS CommissionAgentSTaxInvoiceNumber,
	|	InventoryTable.Customer          AS ConsignedGoodsCustomer,
	|	InventoryTable.RowID AS RowID,
	|	InventoryTable.RowID AS FinRecordID,
	|	&ErrorCorrectionInventoryField AS ErrorCorrection,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting
	|FROM
	|	Document.CommissionReportIntercompany.InventoryKinds AS InventoryTable
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON InventoryTable.IssuedTaxInvoiceOfCommissionAgent = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|		
	|		LEFT JOIN Document.CommissionReportIntercompany AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	HeaderData_.Date                   AS Period,
	|	TableOfGoods.Ref              AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Organization            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Consignee
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	UNDEFINED                       AS Shipper,
	|	HeaderData_.Ref                 AS ConsignmentReportFromCustomer,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	HeaderData_.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	TableOfGoods.Products        AS Products,
	|	TableOfGoods.Characteristic      AS Characteristic,
	|	TableOfGoods.VATRate           AS VATRate,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS CommissionAgentSTaxInvoiceNumber,
	|	TableOfGoods.Customer          AS ConsignedGoodsCustomer,
	|	TableOfGoods.RowID AS RowID,
	|	TableOfGoods.RowID AS FinRecordID,
	|	&ErrorCorrectionProductsField AS ErrorCorrection,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS TableOfGoods
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|		ON TableOfGoods.IssuedTaxInvoiceOfCommissionAgent = DocumentsRegistry.Ref
	|			AND NOT DocumentsRegistry.AdditionalRecord
	|		LEFT JOIN Document.CommissionReportIntercompany AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|WHERE
	|	TableOfGoods.Ref IN (&Ref)
	|	AND ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|";
	CommissionReportIntercompanyLocalization.RequestTextVATReportingCommissionAgentSReport(TextProducts_1);
	
	VATAccountingERP.ReflectCommissionAgentSReport(Query, QueryTexts, Registers, TextProducts_1);
	
	TextReward =
	"SELECT
	|	HeaderData_.Date                    AS Period,
	|	HeaderData_.Ref                  AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Organization             AS Organization,
	|	HeaderData_.Department           AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Consignee
	|	END                               AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.SalesContract
	|		ELSE HeaderData_.Contract
	|	END                               AS Contract,
	|	UNDEFINED                        AS Shipper,
	|	HeaderData_.Ref                  AS DocumentAcquisitions,
	|	HeaderData_.Ref                  AS OriginalTradeDocument,
	|	FALSE                                AS ErrorCorrection,
	|	FALSE                                AS AdjustmentUnderApprovalOfParties,
	|	FALSE                                AS ReduceAmountVATDeduction,
	|	UNDEFINED                        AS PurchaseAdjustmentDocument,
	|	CASE WHEN VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                               AS VATTaxation,
	|	HeaderData_.VATTaxation      AS VATActivityType,
	|
	|	HeaderData_.OperationService                  AS Products,
	|	UNDEFINED                        AS Characteristic,
	|	HeaderData_.VATRateOfRemuneration AS VATRate,
	|	UNDEFINED                        AS InventoryOwnerAttribute,
	|	UNDEFINED                        AS CCDNumber,
	|	
	|	CASE 
	|		WHEN ISNULL(HeaderData_.LineOfBusiness.CostAccounting, FALSE) THEN
	|			HeaderData_.LineOfBusiness
	|	END                               AS LineOfBusiness,
	|	FALSE                                AS PurchasePerBatchOfProduction,
	|	UNDEFINED                        AS LineOfBusinessOfProductionParty,
	|
	|	UNDEFINED 						AS ToExpenseAs,
	|	UNDEFINED                        AS ExpenseItem,
	|	UNDEFINED                        AS DimensionOfExpenses,
	|	UNDEFINED                        AS ItemOfOtherAssets,
	|	UNDEFINED                        AS AnalyticsOfOtherAssets,
	|	UNDEFINED                        AS Purpose,
	|	HeaderData_.Department           AS AccountingDivision,
	|	""""                                AS RowID,
	|	&IDOfPaymentObjectWithCommissionAgentReward AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncomingVATOnAcquisition) AS BusinessTransactionSetting
	|FROM
	|	Document.CommissionReportIntercompany AS HeaderData_
	|WHERE
	|	HeaderData_.Ref IN(&Ref)
	|";
	VATAccountingERP.ReflectPurchaseFromSupplier(Query, QueryTexts, Registers, TextReward);
	
	TextProducts_1 =
	"SELECT
	|	HeaderData_.Date                   AS Period,
	|	InventoryTable.Ref              AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Consignee            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	HeaderData_.Ref                 AS ConsignmentReportToVendor,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	Dimension.Products             AS Products,
	|	Dimension.Characteristic           AS Characteristic,
	|	InventoryTable.VATRate           AS VATRate,
	|	InventoryTable.InventoryOwnerAttribute          AS InventoryOwnerAttribute,
	|	InventoryTable.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfInvoiceIssuedToBuyer,
	|	InventoryTable.Customer          AS ConsignedGoodsCustomer,
	|	InventoryTable.IssuedTaxInvoiceOfCommissionAgent AS InvoiceIssuedToBuyer,
	|	InventoryTable.RowID AS RowID,
	|	FALSE AS ErrorCorrection
	|FROM
	|	Document.CommissionReportIntercompany.InventoryKinds AS InventoryTable
	|		LEFT JOIN Document.CommissionReportIntercompany AS HeaderData_
	|		ON InventoryTable.Ref = HeaderData_.Ref
	|		
	|		LEFT JOIN Catalog.InventoryLocationAttributeKeys AS Dimension
	|		ON InventoryTable.ItemsLocationAttributes = Dimension.Ref
	|WHERE
	|	InventoryTable.Ref IN(&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	HeaderData_.Date                   AS Period,
	|	TableOfGoods.Ref              AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Consignee            AS Organization,
	|	HeaderData_.Department          AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                              AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                              AS Contract,
	|	HeaderData_.Ref                 AS ConsignmentReportToVendor,
	|	HeaderData_.VATTaxation     AS VATTaxation,
	|	TableOfGoods.Products        AS Products,
	|	TableOfGoods.Characteristic      AS Characteristic,
	|	TableOfGoods.VATRate           AS VATRate,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	TableOfGoods.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfInvoiceIssuedToBuyer,
	|	TableOfGoods.Customer          AS ConsignedGoodsCustomer,
	|	TableOfGoods.IssuedTaxInvoiceOfCommissionAgent AS InvoiceIssuedToBuyer,
	|	TableOfGoods.RowID AS RowID,
	|	FALSE AS ErrorCorrection
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS TableOfGoods
	|		LEFT JOIN Document.CommissionReportIntercompany AS HeaderData_
	|		ON TableOfGoods.Ref = HeaderData_.Ref
	|		
	|		INNER JOIN Catalog.Products AS ProductsTable
	|		ON TableOfGoods.Products = ProductsTable.Ref
	|WHERE
	|	TableOfGoods.Ref IN (&Ref)
	|	AND ProductsTable.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|";
	CommissionReportIntercompanyLocalization.RequestTextVATAccountingReportToCommittee(TextProducts_1);
	
	VATAccountingERP.ReflectReportToCommittee(Query, QueryTexts, Registers, TextProducts_1);
	
	TextReward =
	"SELECT
	|	HeaderData_.Date                       AS Period,
	|	HeaderData_.Ref                     AS Ref,
	|	VALUE(Enum.BusinessTransactions.CommissionReportIntercompany) AS BusinessOperation,
	|	HeaderData_.Consignee                AS Organization,
	|	HeaderData_.Department              AS Department,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.Counterparty
	|		ELSE HeaderData_.Organization
	|	END                                  AS Counterparty,
	|	CASE
	|		WHEN HeaderData_.ARAPAccountingViaSeparateCounterparty
	|			THEN HeaderData_.PurchasingContract
	|		ELSE HeaderData_.Contract
	|	END                                  AS Contract,
	|	UNDEFINED                           AS Shipper,
	|	UNDEFINED                           AS GoodsRecipient,
	|	UNDEFINED                           AS ConsignedGoodsCustomer,
	|	FALSE                                   AS SalesViaCommissionAgent,
	|	FALSE                                   AS RetailSaleOfGoods,
	|	HeaderData_.Ref                     AS DocumentSalesOfGoodsAndServices,
	|	FALSE                                   AS ErrorCorrection,
	|	FALSE                                   AS AdjustmentUnderApprovalOfParties,
	|	UNDEFINED                           AS ImplementationAdjustmentDocument,
	|	HeaderData_.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
	|	CASE WHEN VATRateOfRemuneration = VALUE(Catalog.VATRates.EXCLUDINGVAT)
	|		THEN VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|		ELSE VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END                                  AS VATTaxation,
	|	
	|	HeaderData_.OperationService                     AS Products,
	|	UNDEFINED                           AS Characteristic,
	|	VALUE(Catalog.ProductCrossReferences.EmptyRef) AS PartnerProducts,
	|	VALUE(Catalog.Products.EmptyRef) AS ProductsInSet,
	|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS ItemVariantOfSet,
	|	UNDEFINED                           AS Series,
	|	""""                                   AS Content,
	|	0                                      AS Count,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	0                                      AS QuantityByGBRN,
	|	0                                      AS ExciseTaxAmount,
	|	VALUE(Catalog.CCDNumbers.EmptyRef) AS CCDNumber,
	|	HeaderData_.VATRateOfRemuneration    AS VATRate,
	|	UNDEFINED                           AS FEACNCode,
	|	UNDEFINED                           AS InventoryOwnerAttribute,
	|	1                                      AS LineNumber,
	|	""""                                   AS RowID,
	|	HeaderData_.DocumentID AS FinRecordID,
	|	&ReportToCommitteeCatalog AS BusinessTransactionSetting
	|FROM
	|	Document.CommissionReportIntercompany AS HeaderData_
	|WHERE
	|	HeaderData_.Ref IN(&Ref)
	|	AND HeaderData_.CommissionAmount <> 0
	|	AND NOT (HeaderData_.CommissionFeeCalculationMethod = VALUE(Enum.CommissionFeeCalculationMethods.NotCalculating))
	|";
	VATAccountingERP.ReflectImplementationToClient(Query, QueryTexts, Registers, TextReward);
	
EndProcedure

Function QueryTextTableGoodsToBeRegisteredInReportsToConsignor(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsToBeRegisteredInReportsToConsignor";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&EndOfPeriod AS Period,
	|	&Consignee AS Organization,
	|	TableTypesOfStocks_.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber AS TaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer AS Customer,
	|	&ConsignmentReportToVendor AS BusinessOperation,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountMan,
	|	TableTypesOfStocks_.Count AS QuantityToRegister,
	|	TableTypesOfStocks_.QuantityByGBRN AS QuantityForRegistrationByProductBatchID,
	|	TableTypesOfStocks_.AmountIncludingVAT AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		ON TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	TableTypesOfStocks_.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense) AS RecordType,
	|	&Period AS Period,
	|	&Consignee AS Organization,
	|	TableTypesOfStocks_.Currency AS Currency,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.CCDNumber AS CCDNumber,
	|	TableTypesOfStocks_.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	TableTypesOfStocks_.CommissionAgentSTaxInvoiceNumber AS TaxInvoiceNumber,
	|	TableTypesOfStocks_.Customer AS Customer,
	|	&ConsignmentReportToVendor AS BusinessOperation,
	|	TableTypesOfStocks_.Count AS Count,
	|	TableTypesOfStocks_.AmountIncludingVAT AS RevenueAmount,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(TableTypesOfStocks_.InventoryOwnerAttribute.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN TableTypesOfStocks_.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	0 AS QuantityToRegister,
	|	0 AS QuantityForRegistrationByProductBatchID,
	|	0 AS RevenueAmountToRegister,
	|	TableTypesOfStocks_.CommissionAmount AS CommissionAmount,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS CorInventoryOwnerAttribute,
	|	TableTypesOfStocks_.Products AS Products,
	|	TableTypesOfStocks_.Characteristic AS Characteristic,
	|	
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.RowID AS RowID
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|		LEFT JOIN Catalog.InventoryKinds AS TypesOfOwnerStocks
	|		ON TableTypesOfStocks_.InventoryOwnerAttributeOfCompanyGoodsOwner = TypesOfOwnerStocks.Ref
	|
	|WHERE
	|	TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|
	|UNION ALL
	|
	|SELECT
	|	Rows.LineNumber AS LineNumber,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&EndOfPeriod AS Period,
	|	&Organization AS Organization,
	|	Rows.Currency,
	|	Rows.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|	Dimension.DimensionKey AS ItemsLocationAttributes,
	|	Rows.CCDNumber,
	|	Rows.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	Rows.CommissionAgentSTaxInvoiceNumber AS TaxInvoiceNumber,
	|	Rows.Customer,
	|	&ConsignmentReportToVendor AS BusinessOperation,
	|	Rows.Count,
	|	Rows.AmountIncludingVAT AS RevenueAmount,
	|	CASE WHEN ISNULL(Rows.InventoryAttributesOfConsignor.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN Rows.AmountIncludingVATCompl
	|		ELSE 0
	|	END AS RevenueAmountExclVATLocal,
	|	CASE WHEN ISNULL(Rows.InventoryAttributesOfConsignor.Contract.RevalueGoodsAndServicesForConsignmentNotification, FALSE)
	|		THEN Rows.AmountIncludingVATMan
	|		ELSE 0
	|	END AS RevenueAmountMan,
	|	Rows.Count,
	|	Rows.QuantityByGBRN,
	|	Rows.AmountIncludingVAT,
	|	Rows.CommissionAmount AS CommissionAmount,
	|	Rows.InventoryAttributesOfConsignor AS CorInventoryOwnerAttribute,
	|	Rows.Products,
	|	Rows.Characteristic,
	|	
	|	&IDOfPaymentObjectWithCommissionAgent AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	Rows.RowID AS RowID
	|FROM
	|	TTTypesOfStocks AS Rows
	|		LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|			ON Dimension.Products = Rows.Products
	|			AND Dimension.Characteristic = Rows.Characteristic
	|			AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|			AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|			AND Dimension.StorageLocation = Rows.InventoryAttributesOfConsignor.GoodsOwner
	|			AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|
	|WHERE
	|	Rows.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|	AND (Rows.InventoryOwnerAttributeOfCompanyGoodsOwner = VALUE(Catalog.InventoryKinds.EmptyRef)
	|		OR Rows.InventoryOwnerAttributeOfCompanyGoodsOwner = Rows.InventoryAttributesOfConsignor)
	|	AND Rows.InventoryAttributesOfConsignor <> Rows.InventoryOwnerAttribute
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Procedure AddTextsToReflectSettlements(Query, QueryTexts, Registers)
	
	#Region DocumentExchangeRates
	
	RegisterName = "TemporaryTableCurrencyExchangeRatesOfDocument";

	QueryTextDocumentExchangeRates = 
		"SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithConsignor AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany.ARAPDetailsWithVendor AS Table
		|		LEFT JOIN Document.CommissionReportIntercompany AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Consignee AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	DocumentDataHeader.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany AS DocumentDataHeader
		|WHERE
		|	DocumentDataHeader.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentDataHeader.Ref AS Ref,
		|	DocumentDataHeader.Organization AS Organization,
		|	DocumentDataHeader.Date AS DateOfCourse,
		|	Table.ARAPObject AS ARAPObject,
		|	DocumentDataHeader.Currency AS DocumentCurrency,
		|	DocumentDataHeader.Currency AS ARAPCurrency
		|FROM
		|	Document.CommissionReportIntercompany.ARAPDetailsWithCustomer AS Table
		|		LEFT JOIN Document.CommissionReportIntercompany AS DocumentDataHeader
		|		ON Table.Ref = DocumentDataHeader.Ref
		|WHERE
		|	Table.Ref IN (&Ref)";
		
	QueryTextDocumentExchangeRates = ARAPAccountingPosting.GetTableOfExchangeRatesLinesOfBusiness(QueryTextDocumentExchangeRates);

	QueryTexts.Add(QueryTextDocumentExchangeRates, RegisterName);
	
	#EndRegion
	
	#Region AddTextsToReflectMutualSettlements
	
	#Region Purchase
	
	TextPurchase = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|
		|	Table.ARAPObjectForSettlementsWithConsignor AS ARAPObject,
		|	Table.PaymentDate             AS PaymentDate,
		|	UNDEFINED                    AS PaymentOption,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.DocumentAmount          AS Sum,
		|	Table.DocumentAmount          AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	Table.Date                    AS DateOfCourse,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	
		|	Table.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
		|	
		|	Table.PaymentDate             AS PaymentDate,
		|	UNDEFINED                    AS PaymentOption,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.CommissionAmount     AS Sum,
		|	Table.CommissionAmount     AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.Currency                  AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|	END                           AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	Table.Date                    AS DateOfCourse,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (NOT Table.KeepCommissionFee AND Table.CommissionAmount > 0 OR &NewOnlineARAPAccounting)
		|	AND Table.CommissionAmount <> 0";
	
	#EndRegion
	
	#Region IncreasePaymentPlan_
	
	TextPaymentPlan_ = "
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.PaymentDate             AS PaymentDate,
		|	
		|	Table.ARAPObjectForSettlementsWithConsignor      AS ARAPObject,
		|	Table.ARAPObjectSettings                AS ARAPObjectSettings,
		|	FALSE                                   AS InvoiceForOrders,
		|	FALSE                                   AS ExceedingOrder,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.DocumentAmount          AS AmountDue,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor) AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment) AS PaymentOption,
		|	UNDEFINED                           AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.PaymentDate             AS PaymentDate,
		|	
		|	Table.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
		|	Table.ARAPObjectSettings                AS ARAPObjectSettings,
		|	FALSE                                   AS InvoiceForOrders,
		|	FALSE                                   AS ExceedingOrder,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(ContractsOfCounterpartiesSupplier.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS PurchaseOrder_,
		|	Table.CommissionAmount          AS AmountDue,
		|	Table.Currency                  AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)
		|	END                           AS BusinessOperation,
		|	Table.PaymentMethod             AS PaymentMethod,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment) AS PaymentOption,
		|	UNDEFINED                           AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS ContractsOfCounterpartiesSupplier
		|	ON Table.PurchasingContract = ContractsOfCounterpartiesSupplier.Ref
		|		AND ContractsOfCounterpartiesSupplier.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (NOT Table.KeepCommissionFee AND Table.CommissionAmount > 0 OR &NewOnlineARAPAccounting)
		|	AND Table.CommissionAmount <> 0
		|";

	#EndRegion
	
	#Region PrepaymentsSettlement
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                                           AS Ref,
		|	Table.Ref.Consignee                                               AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                                    AS Partner,
		|	
		|	Table.ARAPObject                                                   AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectForSettlementsWithConsignor                                 AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                                    AS ARAPCurrency,
		|	Table.AmountARAP                                              AS AmountARAP,
		|	Table.Ref.Currency                                                    AS DocumentCurrency,
		|	Table.Sum                                                            AS Sum,
		|
		|	Table.Ref.Date                                                      AS DateOfCourse,
		|	Table.Ref.Date                                                      AS RecorderDate,
		|	Table.Ref.Number                                                     AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment)               AS BusinessOperation
		|	
		|FROM
		|	Document.CommissionReportIntercompany.ARAPDetailsWithVendor AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.Procurement(Query, QueryTexts, Registers, TextPurchase, TextPaymentPlan_, TextAdvancePaymentOffset);
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
	
	#Region CommissionDeduction
	
		TextOfClientSObligation = 
			"SELECT
			|	Table.Ref                                                                   AS Ref,
			|	Table.Organization                                                              AS Organization,
			|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
			|		THEN Table.Partner
			|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
			|	END                                                                            AS Partner,
			|	
			|	Table.Currency                                                                   AS ARAPCurrency,
			|	Table.ARAPObjectForSettlementsWithCommissionAgent                                             AS ARAPObject,
			|	
			|	Table.CommissionAmount                                                      AS AmountARAP,
			|	Table.CommissionAmount                                                      AS Sum,
			|	0                                                                                AS IncreaseIsPaid,
			|	0                                                                                AS ReductionIsPaid,
			|	
			|	Table.Date                                                                     AS RecorderDate,
			|	Table.Date                                                                     AS DateOfCourse,
			|	Table.Number                                                                    AS RecorderNumber,
			|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
			|	UNDEFINED                                                                     AS PaymentMethod,
			|	UNDEFINED                                                                     AS CashFlowItem,
			|	UNDEFINED                                                                     AS ProformaInvoice,
			|	Table.Currency                                                                   AS DocumentCurrency,
			|	UNDEFINED                                                                     AS LinkedDocument,
			|	Table.DocumentID                                                   AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
			|FROM
			|	Document.CommissionReportIntercompany AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.KeepCommissionFee
			|	AND Table.CommissionAmount <> 0";
		
		TextOfObligationToSupplier = 
			"SELECT
			|	Table.Ref                                                 AS Ref,
			|	Table.Organization                                            AS Organization,
			|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
			|		THEN Table.Partner
			|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
			|	END                                                          AS Partner,
			|	Table.Date                                                   AS RecorderDate,
			|	Table.Number                                                  AS RecorderNumber,
			|	
			|	Table.ARAPObjectForSettlementsWithCommissionAgentRemuneration             AS ARAPObject,
			|	Table.Currency                                                 AS ARAPCurrency,
			|	Table.CommissionAmount                                    AS Sum,
			|	Table.CommissionAmount                                    AS AmountARAP,
			|	0                                                              AS ReductionIsPaid,
			|	0                                                              AS IncreaseIsPaid,
			|
			|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
			|	UNDEFINED                                                   AS CashFlowItem,
			|	UNDEFINED                                                   AS PaymentRequest,
			|	UNDEFINED                                                   AS PaymentMethod,
			|	Table.Currency                                                 AS DocumentCurrency,
			|	Table.Date                                                   AS DateOfCourse,
			|	UNDEFINED                                                   AS LinkedDocument,
			|	Table.DocumentID                                 AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
			|FROM
			|	Document.CommissionReportIntercompany AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.KeepCommissionFee
			|	AND Table.CommissionAmount <> 0";
			
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier);
	
	#EndRegion
	
	Else
	
	#Region WithholdingAndNonWithholdingCommission
		TextPayment = "
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Table.Organization                                            AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                          AS Partner,
		|	Table.Date                                                   AS RecorderDate,
		|	Table.Number                                                  AS RecorderNumber,
		|	
		|	Table.ARAPObjectForSettlementsWithCommissionAgentRemuneration             AS ARAPObject,
		|	Table.Currency                                                 AS ARAPCurrency,
		|	-Table.CommissionAmount                                   AS Sum,
		|	-Table.CommissionAmount                                   AS AmountARAP,
		|	0                                                              AS ReductionIsPaid,
		|	0                                                              AS IncreaseIsPaid,
		|	0                                                              AS SumMan,
		|	0                                                              AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
		|	UNDEFINED                                                   AS CashFlowItem,
		|	UNDEFINED                                                   AS PaymentRequest,
		|	UNDEFINED                                                   AS PaymentMethod,
		|	Table.Currency                                                 AS DocumentCurrency,
		|	Table.Date                                                   AS DateOfCourse,
		|	DATETIME(1,1,1)                                               AS MaturityDate,
		|	UNDEFINED                                                   AS LinkedDocument,
		|	Table.DocumentID                                 AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.ConsignmentReportFromCustomer) AS BusinessTransactionSetting
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND NOT Table.KeepCommissionFee
		|	AND Table.CommissionAmount < 0
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                                                 AS Ref,
		|	Table.Consignee                                            AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                          AS Partner,
		|	Table.Date                                                   AS RecorderDate,
		|	Table.Number                                                  AS RecorderNumber,
		|	
		|	Table.ARAPObjectForSettlementsWithConsignor                              AS ARAPObject,
		|	Table.Currency                                                 AS ARAPCurrency,
		|	Table.CommissionAmount                                    AS Sum,
		|	Table.CommissionAmount                                    AS AmountARAP,
		|	0                                                              AS ReductionIsPaid,
		|	0                                                              AS IncreaseIsPaid,
		|	0                                                              AS SumMan,
		|	0                                                              AS SumCompl,
		|
		|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
		|	UNDEFINED                                                   AS CashFlowItem,
		|	UNDEFINED                                                   AS PaymentRequest,
		|	UNDEFINED                                                   AS PaymentMethod,
		|	Table.Currency                                                 AS DocumentCurrency,
		|	Table.Date                                                   AS DateOfCourse,
		|	DATETIME(1,1,1)                                               AS MaturityDate,
		|	UNDEFINED                                                   AS LinkedDocument,
		|	Table.DocumentID                                 AS FinRecordID,
		|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND Table.KeepCommissionFee
		|	AND Table.CommissionAmount <> 0
		|";
	
	#EndRegion
	
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.MakingPaymentToSupplier(Query, QueryTexts, Registers, TextPayment,"2");
	
	EndIf;
	
	#EndRegion
	
	#Region AddTextsToReflectSalesSettlements
	
	#Region Sale
	
	TextSale =
		"SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Organization             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	
		|	Table.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	Table.PaymentDate             AS PaymentDate,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS SalesOrder_,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.DocumentAmount          AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|	Table.DocumentAmount          AS Sum,
		|	
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.Currency                  AS ARAPCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
		|	Table.Date                    AS DateOfCourse,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment) AS PaymentOption,
		|	FALSE                            AS ExceedingOrder,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                  AS Ref,
		|	Table.Consignee             AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                           AS Partner,
		|	Table.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
		|	
		|	Table.PaymentDate             AS PaymentDate,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                           AS SalesOrder_,
		|	FALSE                            AS InvoiceForOrders,
		|	Table.CommissionAmount     AS AmountARAP,
		|	0                               AS AmountARAPByPackage,
		|	Table.CommissionAmount     AS Sum,
		|	
		|	Table.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Date                    AS RecorderDate,
		|	Table.Number                   AS RecorderNumber,
		|	Table.Currency                  AS ARAPCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.ConsignmentNotificationCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)
		|	END                           AS BusinessOperation,
		|	Table.Date                    AS DateOfCourse,
		|	Table.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment) AS PaymentOption,
		|	FALSE                            AS ExceedingOrder,
		|	UNDEFINED                    AS LinkedDocument
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (NOT Table.KeepCommissionFee AND Table.CommissionAmount > 0 OR &NewOnlineARAPAccounting)
		|	AND Table.CommissionAmount <> 0
		|";
	
	#EndRegion
	
	#Region IncreasePaymentPlan
	
	TextPaymentPlanning = "
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Organization                    AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                  AS Partner,
		|	
		|	Table.Ref.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Ref.Currency                  AS ARAPCurrency,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer) AS BusinessOperation,
		|	Table.Ref.PaymentMethod             AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate             AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment) AS PaymentOption,
		|	Table.DocumentAmount                 AS AmountDue,
		|	
		|	TRUE                                 AS ExcludeDuringControl,
		|	FALSE                                   AS InvoiceForOrders,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                                  AS SalesOrder_,
		|	FALSE                                   AS ExceedingOrder,
		|	UNDEFINED                           AS LinkedDocument
		|	
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|
		|UNION ALL
		|
		|SELECT
		|	Table.Ref                         AS Ref,
		|	Table.Organization                    AS Organization,
		|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                  AS Partner,
		|	
		|	Table.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
		|	Table.Ref.Date                    AS RecorderDate,
		|	Table.Ref.Number                   AS RecorderNumber,
		|	Table.Ref.ARAPObjectSettings         AS ARAPObjectSettings,
		|	Table.Ref.Currency                  AS ARAPCurrency,
		|	Table.Ref.Currency                  AS DocumentCurrency,
		|	CASE WHEN &NewOnlineARAPAccounting
		|		THEN VALUE(Enum.BusinessTransactions.ConsignmentNotificationCommissionFee)
		|		ELSE VALUE(Enum.BusinessTransactions.ConsignmentReportToVendor)
		|	END                                  AS BusinessOperation,
		|	Table.Ref.PaymentMethod             AS PaymentMethod,
		|	
		|	Table.Ref.PaymentDate             AS PaymentDate,
		|	VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment) AS PaymentOption,
		|	Table.CommissionAmount            AS AmountDue,
		|	
		|	TRUE                                 AS ExcludeDuringControl,
		|	FALSE                                   AS InvoiceForOrders,
		|	CASE 
		|		WHEN Table.ARAPAccountingViaSeparateCounterparty 
		|			THEN ISNULL(CounterpartyContractsClient.Ref, Table.Ref)
		|		ELSE ISNULL(IntercompanyContracts.Ref, Table.Ref)
		|	END                                  AS SalesOrder_,
		|	FALSE                                   AS ExceedingOrder,
		|	UNDEFINED                           AS LinkedDocument
		|	
		|FROM
		|	Document.CommissionReportIntercompany AS Table
		|
		|	LEFT JOIN Catalog.CounterpartyContracts AS CounterpartyContractsClient
		|	ON Table.SalesContract = CounterpartyContractsClient.Ref
		|		AND CounterpartyContractsClient.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|	LEFT JOIN Catalog.IntercompanyContracts AS IntercompanyContracts
		|	ON Table.Contract = IntercompanyContracts.Ref
		|		AND IntercompanyContracts.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		|
		|WHERE
		|	Table.Ref IN (&Ref)
		|	AND (NOT Table.KeepCommissionFee AND Table.CommissionAmount > 0 OR &NewOnlineARAPAccounting)
		|	AND Table.CommissionAmount <> 0
		|";
	
	#EndRegion
	
	#Region ApplyingPrepayment
	
	TextAdvancePaymentOffset = "
		|SELECT
		|	Table.Ref                                             AS Ref,
		|	Table.Ref.Organization                                 AS Organization,
		|	CASE WHEN Table.Ref.ARAPAccountingViaSeparateCounterparty
		|		THEN Table.Ref.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
		|	END                                                      AS Partner,
		|	
		|	Table.ARAPObject                                     AS CalculationObjectSource,
		|	Table.Ref.ARAPObjectForSettlementsWithCommissionAgent                AS CalculationObjectReceiver,
		|
		|	Table.Ref.Currency                                      AS ARAPCurrency,
		|	Table.AmountARAP                                AS AmountARAP,
		|	Table.Ref.Currency                                      AS DocumentCurrency,
		|	Table.Sum                                              AS Sum,
		|	
		|	Table.Ref.Date                                        AS DateOfCourse,
		|	Table.Ref.Date                                        AS RecorderDate,
		|	Table.Ref.Number                                       AS RecorderNumber,
		|	VALUE(Enum.BusinessTransactions.SettlementOfPrepayment) AS BusinessOperation
		|	
		|FROM
		|	Document.CommissionReportIntercompany.ARAPDetailsWithCustomer AS Table
		|WHERE
		|	Table.Ref IN (&Ref)
		|";
	
	#EndRegion
	
	ARAPAccountingPostingCustomers.ConductingSale(Query, QueryTexts, Registers, TextSale, TextPaymentPlanning, TextAdvancePaymentOffset);
	
	If GetFunctionalOption("NewOnlineARAPAccounting") Then
	
	#Region CommissionDeduction
	
		TextOfClientSObligation = 
			"SELECT
			|	Table.Ref                                                                   AS Ref,
			|	Table.Consignee                                                              AS Organization,
			|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
			|		THEN Table.Partner
			|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
			|	END                                                                            AS Partner,
			|	
			|	Table.Currency                                                                   AS ARAPCurrency,
			|	Table.ARAPObjectForSettlementsWithConsignorRemuneration                                  AS ARAPObject,
			|	
			|	Table.CommissionAmount                                                      AS AmountARAP,
			|	Table.CommissionAmount                                                      AS Sum,
			|	0                                                                                AS IncreaseIsPaid,
			|	0                                                                                AS ReductionIsPaid,
			|	
			|	Table.Date                                                                     AS RecorderDate,
			|	Table.Date                                                                     AS DateOfCourse,
			|	Table.Number                                                                    AS RecorderNumber,
			|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor)   AS BusinessOperation,
			|	UNDEFINED                                                                     AS PaymentMethod,
			|	UNDEFINED                                                                     AS CashFlowItem,
			|	UNDEFINED                                                                     AS ProformaInvoice,
			|	Table.Currency                                                                   AS DocumentCurrency,
			|	UNDEFINED                                                                     AS LinkedDocument,
			|	Table.ARAPObjectForSettlementsWithConsignorRemuneration.UUID          AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
			|FROM
			|	Document.CommissionReportIntercompany AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.CommissionAmount <> 0
			|	AND Table.KeepCommissionFee";
			
		TextOfObligationToSupplier = 
			"SELECT
			|	Table.Ref                                                 AS Ref,
			|	Table.Consignee                                            AS Organization,
			|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
			|		THEN Table.Partner
			|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
			|	END                                                          AS Partner,
			|	Table.Date                                                   AS RecorderDate,
			|	Table.Number                                                  AS RecorderNumber,
			|	
			|	Table.ARAPObjectForSettlementsWithConsignor                              AS ARAPObject,
			|	Table.Currency                                                 AS ARAPCurrency,
			|	Table.CommissionAmount                                    AS Sum,
			|	Table.CommissionAmount                                    AS AmountARAP,
			|	0                                                              AS ReductionIsPaid,
			|	0                                                              AS IncreaseIsPaid,
			|
			|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
			|	UNDEFINED                                                   AS CashFlowItem,
			|	UNDEFINED                                                   AS PaymentRequest,
			|	UNDEFINED                                                   AS PaymentMethod,
			|	Table.Currency                                                 AS DocumentCurrency,
			|	Table.Date                                                   AS DateOfCourse,
			|	UNDEFINED                                                   AS LinkedDocument,
			|	Table.ARAPObjectForSettlementsWithConsignorRemuneration.UUID AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.RemunerationDeductionByConsignor) AS BusinessTransactionSetting
			|FROM
			|	Document.CommissionReportIntercompany AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.KeepCommissionFee
			|	AND Table.CommissionAmount <> 0";
		
		#EndRegion
		
		MutualSettlementsAreCarriedOutBySuppliersARAPAccounting.OffsettingOfCounterDebt(Query, QueryTexts, Registers, TextOfClientSObligation, TextOfObligationToSupplier);
		
	Else
		
	#Region CommissionDeduction
	
		TextPayment = 
			"SELECT
			|	Table.Ref                                                                   AS Ref,
			|	Table.Organization                                                              AS Organization,
			|	CASE WHEN Table.ARAPAccountingViaSeparateCounterparty
			|		THEN Table.Partner
			|		ELSE VALUE(Catalog.Partners.OurEnterprise)  
			|	END                                                                            AS Partner,
			|	
			|	Table.Currency                                                                   AS ARAPCurrency,
			|	Table.ARAPObjectForSettlementsWithCommissionAgent                                             AS ARAPObject,
			|	
			|	Table.CommissionAmount                                                      AS AmountARAP,
			|	Table.CommissionAmount                                                      AS Sum,
			|	0                                                                                AS IncreaseIsPaid,
			|	0                                                                                AS ReductionIsPaid,
			|	
			|	Table.Date                                                                     AS RecorderDate,
			|	Table.Date                                                                     AS DateOfCourse,
			|	DATETIME(1,1,1)                                                                 AS MaturityDate,
			|	Table.Number                                                                    AS RecorderNumber,
			|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
			|	UNDEFINED                                                                     AS PaymentMethod,
			|	UNDEFINED                                                                     AS CashFlowItem,
			|	UNDEFINED                                                                     AS ProformaInvoice,
			|	Table.Currency                                                                   AS DocumentCurrency,
			|	UNDEFINED                                                                     AS LinkedDocument,
			|	Table.DocumentID                                                   AS FinRecordID,
			|	VALUE(Catalog.BusinessTransactionsSettings.CommissionAgentSRemunerationDeduction) AS BusinessTransactionSetting
			|FROM
			|	Document.CommissionReportIntercompany AS Table
			|WHERE
			|	Table.Ref IN (&Ref)
			|	AND Table.CommissionAmount <> 0
			|	AND Table.KeepCommissionFee";
	
	#EndRegion	
		
		ARAPAccountingPostingCustomers.CarryingOutPaymentFromClient(Query, QueryTexts, Registers, TextPayment,"2");
		
	EndIf;
	
	#EndRegion
	
EndProcedure

Function QueryTextTableRevenueAndCOGS(Query, QueryTexts, Registers)
	
	RegisterName = "RevenueAndCOGS";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts);
	SetSettlementAnalyticsParameters(Query);
	SetProductAccountingAnalyticsParameter(Query);
	SetRequestParametersCurrencyCoefficients(Query);
	
	VATAccountingERP.SetParametersForVATRateRequest(Query.Parameters, Query.Parameters.Organization, Query.Parameters.Period);
	
	QueryText = "
	|SELECT // Sale of goods from the commitee
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	&Period                                       AS Period,
	|	&Department                                AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusinessTransferred AS ProductLineOfBusiness,
	|	&AnalyticsCommitteeCommissioner                 AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END) AS AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|		CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS Cost,
	|
	|	CASE WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			CAST((TableTypesOfStocks_.AmountIncludingVAT
	|					- TableTypesOfStocks_.VATAmount)
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS CostExcludingVAT,
	|
	|	CASE WHEN &CompanyManagementAccounting
	|		AND TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods) THEN
	|			CAST((TableTypesOfStocks_.AmountIncludingVAT
	|					- TableTypesOfStocks_.VATAmount)
	|					* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS CostMan,
	|
	|	CAST(
	|		(CASE WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount
	|			ELSE 0
	|		END
	|		+ CASE WHEN &BatchAccountingVersion22
	|			THEN 0
	|		WHEN &VATTaxation = VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|			THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END) * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalCost,
	|
	|	TableTypesOfStocks_.Count AS Count,
	|	ISNULL(Amounts.AmountIncludingVATMan, CAST(TableTypesOfStocks_.AmountIncludingVAT
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			- TableTypesOfStocks_.VATAmount)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl, CAST((TableTypesOfStocks_.AmountIncludingVAT
	|			- TableTypesOfStocks_.VATAmount)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, CAST(TableTypesOfStocks_.AmountIncludingVAT
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|	0 AS SellingExpensesExcludingVAT,
	|	0 AS SellingExpensesLocal,
	|	0 AS SellingExpensesMan,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	&Consignee AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	ISNULL(Amounts.AmountARAP, TableTypesOfStocks_.AmountIncludingVAT) AS AmountInARAPCurrency,
	|	ISNULL(Amounts.AmountARAP - Amounts.AmountVATARAP, TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation AS VATTaxation,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.BusinessTransactions.ConsignmentSale)
	|		ELSE &ConsignmentReportFromCustomer
	|	END) AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithCommissionAgent AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	TableTypesOfStocks_.RowID AS FinRecordID,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref
	|		AND Amounts.RowID = TableTypesOfStocks_.RowID
	|
	|UNION ALL
	|
	|SELECT // Sale of goods from the commitee, remuneration
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	&Period                                       AS Period,
	|	&Department                                AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusinessTransferred AS ProductLineOfBusiness,
	|	&AnalyticsCommitteeCommissioner                 AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END) AS AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	CAST(TableTypesOfStocks_.CommissionAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesIncludingVAT,
	|
	|	CAST((TableTypesOfStocks_.CommissionAmount
	|		- TableTypesOfStocks_.AmountVATRemuneration)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesExcludingVAT,
	|
	|	CAST(
	|		CASE WHEN NOT &BatchAccountingVersion22
	|			THEN 0
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|			THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CAST(CASE
	|		WHEN NOT &CompanyManagementAccounting
	|		THEN 0
	|		WHEN &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|			AND NOT &GenerateVATChargedWhenIncludingInCost
	|		THEN TableTypesOfStocks_.CommissionAmount
	|		ELSE TableTypesOfStocks_.CommissionAmount - TableTypesOfStocks_.AmountVATRemuneration
	|		END * &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	&Consignee AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation AS VATTaxation,
	|	&ConsignmentReportFromCustomer AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithCommissionAgentRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDOfPaymentObjectWithCommissionAgentReward AS FinRecordID,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|
	|UNION ALL
	|
	|SELECT // Sale of goods from the commitee, remuneration
	|	TableTypesOfStocks_.LineNumber                AS LineNumber,
	|	&Period                                       AS Period,
	|	&Department                                AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	TableTypesOfStocks_.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusinessTransferred AS ProductLineOfBusiness,
	|	&AnalyticsCommitteeCommissioner                 AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor AS InventoryOwnerAttribute,
	|	(CASE
	|		WHEN TableTypesOfStocks_.InventoryAttributesOfConsignor.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|			THEN VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsReceivedByCommissionAgent)
	|		ELSE VALUE(Enum.SectionsOfInventoryCostAccounting.GoodsTransferredToCommissionAgent)
	|	END) AS AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|
	|	0 AS SellingExpensesExcludingVAT,
	|
	|	CAST(TableTypesOfStocks_.AmountVATRemuneration
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CAST(TableTypesOfStocks_.AmountVATRemuneration
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	&Consignee AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation AS VATTaxation,
	|	&ConsignmentReportFromCustomer AS BusinessOperation,
	|
	|	CASE WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups THEN
	|		TableTypesOfStocks_.InventoryOwnerAttribute
	|	ELSE
	|		TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithCommissionAgentRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDOfPaymentObjectWithCommissionAgentReward AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.IncludeVATInCostExpenses) AS BusinessTransactionSetting,
	|	TableTypesOfStocks_.VATRate AS VATRate
	|	
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|WHERE
	|	&BatchAccountingVersion22
	|	AND &GenerateVATChargedWhenIncludingInCost
	|	AND &VATTaxation IN (&TypesOfTaxationVATIsIncludedInCost)
	|
	|UNION ALL
	|
	|SELECT // Sale of agency services from the principal
	|	Goods.LineNumber                            AS LineNumber,
	|	&Period                                       AS Period,
	|	&Department                                AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	CASE 
	|		WHEN  ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignor
	|		THEN Goods.ItemsLocationAttributes
	|		ELSE CommitteeAnalysts.DimensionKey
	|	END                                         AS ItemsLocationAttributes,
	|	Goods.ItemsLocationAttributes.Purpose.LineOfBusiness  AS ProductLineOfBusiness,
	|	&AnalyticsCommitteeCommissioner                 AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	CASE
	|		WHEN  ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignor
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|
	|	Goods.Count AS Count,
	|	ISNULL(Amounts.AmountIncludingVATMan, CAST(Goods.SalesAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, CAST((Goods.SalesAmount
	|			- Goods.VATAmount)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl, CAST((Goods.SalesAmount
	|			- Goods.AmountSalesVAT)
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, CAST(Goods.SalesAmount
	|			* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|	0 AS SellingExpensesExcludingVAT,
	|	0 AS SellingExpensesLocal,
	|	0 AS SellingExpensesMan,
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	Goods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	ISNULL(Amounts.AmountARAP, Goods.SalesAmount) AS AmountInARAPCurrency,
	|	ISNULL(Amounts.AmountARAP - Amounts.AmountVATARAP, Goods.SalesAmount - Goods.AmountSalesVAT) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	Goods.SalesAmount AS AmountInDocumentCurrency,
	|	Goods.SalesAmount - Goods.AmountSalesVAT AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation AS VATTaxation,
	|	&ConsignmentReportFromCustomer AS BusinessOperation,
	|
	|	Goods.Products AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithCommissionAgent AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	Goods.RowID AS FinRecordID,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting,
	|	Goods.VATRate AS VATRate
	|	
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS Goods
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalysts
	|	ON Goods.ItemsLocationAttributes.Products = CommitteeAnalysts.Products
	|		AND Goods.ItemsLocationAttributes.Characteristic = CommitteeAnalysts.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalysts.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalysts.Series
	|		AND &Department = CommitteeAnalysts.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalysts.ProductCostElement
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = &Ref
	|		AND Amounts.RowID = Goods.RowID
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> UNDEFINED
	|	AND ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignee
	|
	|UNION ALL
	|
	|SELECT // Sale of agency services from the principal, remuneration
	|	Goods.LineNumber                            AS LineNumber,
	|	&Period                                       AS Period,
	|	&Department                                AS Department,
	|	&AdjustmentPeriod_                          AS AdjustmentPeriod_,
	|	CASE 
	|		WHEN  ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignor
	|		THEN Goods.ItemsLocationAttributes
	|		ELSE CommitteeAnalysts.DimensionKey
	|	END                                         AS ItemsLocationAttributes,
	|	Goods.ItemsLocationAttributes.Purpose.LineOfBusiness  AS ProductLineOfBusiness,
	|	&AnalyticsCommitteeCommissioner                 AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	CASE
	|		WHEN  ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignor
	|		THEN VALUE(Enum.InventoryTypes.AgentService)
	|		ELSE VALUE(Enum.InventoryTypes.OperationService)
	|	END AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS CostMan,
	|	0 AS LocalCost,
	|	0 AS Count,
	|	0 AS RevenueAmount,
	|	0 AS RevenueAmountExcludingVAT,
	|	0 AS RevenueAmountExclVATLocal,
	|	0 AS RevenueAmountIncludingVATLocal,
	|
	|	CAST(Goods.CommissionAmount
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesIncludingVAT,
	|
	|	CAST((Goods.CommissionAmount
	|		- Goods.AmountVATRemuneration)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS SellingExpensesExcludingVAT,
	|
	|	CAST((Goods.CommissionAmount
	|		- Goods.AmountVATRemuneration)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SellingExpensesLocal,
	|
	|	CASE WHEN &CompanyManagementAccounting THEN
	|		CAST((Goods.CommissionAmount
	|			- Goods.AmountVATRemuneration)
	|			* &ConversionRateToManCurrency AS NUMBER(31,2))
	|	ELSE
	|		0
	|	END AS SellingExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|
	|	Goods.ItemsLocationAttributes.StorageLocation AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	0 AS AmountInARAPCurrency,
	|	0 AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	0 AS AmountInDocumentCurrency,
	|	0 AS AmountExcludingVATInDocumentCurrency,
	|
	|	&VATTaxation AS VATTaxation,
	|	&ConsignmentReportFromCustomer AS BusinessOperation,
	|
	|	Goods.Products AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithCommissionAgentRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	&IDOfPaymentObjectWithCommissionAgentReward AS FinRecordID,
	|	&CommissionAgentSReportCatalog AS BusinessTransactionSetting,
	|	Goods.VATRate AS VATRate
	|	
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS Goods
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS CommitteeAnalysts
	|	ON Goods.ItemsLocationAttributes.Products = CommitteeAnalysts.Products
	|		AND Goods.ItemsLocationAttributes.Characteristic = CommitteeAnalysts.Characteristic
	|		AND VALUE(Catalog.Assignments.EmptyRef) = CommitteeAnalysts.Purpose
	|		AND VALUE(Catalog.ItemsBatches.EmptyRef) = CommitteeAnalysts.Series
	|		AND &Department = CommitteeAnalysts.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = CommitteeAnalysts.ProductCostElement
	|WHERE
	|	Goods.Ref = &Ref
	|	AND Goods.Products.ItemsType = VALUE(Enum.ItemsTypes.OperationService)
	|	AND ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> UNDEFINED
	|	AND ISNULL(Goods.Characteristic.Principal, Goods.Products.Principal) <> &Consignee
	|
	|UNION ALL
	|
	|SELECT // Commission fee from the commission agent
	|	0 AS LineNumber,
	|	&Period AS Period,
	|	&Department AS Department,
	|	&AdjustmentPeriod_ AS AdjustmentPeriod_,
	|	&ItemsLocationAttributes AS ItemsLocationAttributes,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS ProductLineOfBusiness,
	|	&AnalyticsCommissionerCommittee AS AccountingDimensionByPartners,
	|	CASE 
	|		WHEN &AccountingForIncomeUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	VALUE(Enum.InventoryTypes.OperationService) AS InventoryType,
	|	VALUE(Catalog.InventoryKinds.EmptyRef) AS InventoryOwnerAttribute,
	|	VALUE(Enum.SectionsOfInventoryCostAccounting.EmptyRef) AccountingSection,
	|	&VATTaxation AS VATActivityType,
	|	&Manager AS Manager,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS CostMan,
	|	0 AS Count,
	|	ISNULL(Amounts.AmountIncludingVATMan, CAST(DocumentData.CommissionAmount
	|		* &ConversionRateToManCurrency
	|		AS NUMBER(31,2))) AS RevenueAmount,
	|
	|	ISNULL(Amounts.AmountExcludingVATMan, CAST((DocumentData.CommissionAmount
	|			- DocumentData.AmountVATRemuneration)
	|		* &ConversionRateToManCurrency
	|		AS NUMBER(31,2))) AS RevenueAmountExcludingVAT,
	|
	|	ISNULL(Amounts.AmountExcludingVATCompl, CAST((DocumentData.CommissionAmount
	|			- DocumentData.AmountVATRemuneration)
	|		* &FactorOfConversionToCurrencyOfRegul
	|		AS NUMBER(31,2))) AS RevenueAmountExclVATLocal,
	|
	|	ISNULL(Amounts.AmountIncludingVATCompl, CAST(DocumentData.CommissionAmount
	|		* &FactorOfConversionToCurrencyOfRegul
	|		AS NUMBER(31,2))) AS RevenueAmountIncludingVATLocal,
	|
	|	0 AS SellingExpensesIncludingVAT,
	|	0 AS SellingExpensesExcludingVAT,
	|	0 AS SellingExpensesLocal,
	|	0 AS SellingExpensesMan,
	|
	|	0 AS ManualDiscount,
	|	0 AS DiscountMarkupAmount,
	|	VALUE(Catalog.Partners.OurEnterprise) AS Warehouse,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &SalesContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS Terms,
	|
	|	&Currency AS ARAPCurrency,
	|	ISNULL(Amounts.AmountARAP, DocumentData.CommissionAmount) AS AmountInARAPCurrency,
	|	ISNULL(Amounts.AmountARAP - Amounts.AmountVATARAP, DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) AS AmountExcludingVATInARAPCurrency,
	|
	|	&Currency AS DocumentCurrency,
	|	DocumentData.CommissionAmount AS AmountInDocumentCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInDocumentCurrency,
	|
	|	CASE &VATRateOfRemuneration
	|	WHEN VALUE(Catalog.VATRates.EXCLUDINGVAT) THEN
	|		VALUE(Enum.VATTaxationTypes.SaleIsNotSubjectToVAT)
	|	WHEN &ExportVATRate THEN
	|		VALUE(Enum.VATTaxationTypes.ExportSale)
	|	ELSE
	|		VALUE(Enum.VATTaxationTypes.SaleIsSubjectToVAT)
	|	END,
	|	&ConsignmentReportToVendor AS BusinessOperation,
	|	DocumentData.OperationService AS SourceOfProductFinancialAccountingGroup,
	|	DocumentData.ARAPObjectForSettlementsWithConsignorRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	
	|	DocumentData.DocumentID AS FinRecordID,
	|	&ReportToCommitteeCatalog AS BusinessTransactionSetting,
	|	Amounts.VATRate AS VATRate
	|	
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|	ON Amounts.Ref = DocumentData.Ref
	|		AND Amounts.RowID = """"
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Procedure GenerateDocumentAmountsInAccountingCurrencies(Query, QueryTexts, Registers = Undefined) Export
	
	QueryTextdata_ = "
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.SalesAmount - DocumentTable.AmountSalesVAT AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.AmountSalesVAT AS VATAmount,
	|	DocumentTable.SalesAmount AS AmountARAP,
	|	DocumentTable.AmountSalesVAT AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.Products.ItemsType IN (
	|		VALUE(Enum.ItemsTypes.OperationService),
	|		VALUE(Enum.ItemsTypes.Work_5))
	|
	|UNION ALL
	|
	|SELECT
	|	""Covariability"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	DocumentTable.LineNumber AS LineNumber,
	|	DocumentTable.RowID AS RowID,
	|	DocumentTable.AmountIncludingVAT - DocumentTable.VATAmount AS AmountExcludingVAT,
	|	DocumentTable.VATRate AS VATRate,
	|	DocumentTable.VATAmount AS VATAmount,
	|	DocumentTable.AmountIncludingVAT AS AmountARAP,
	|	DocumentTable.VATAmount AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.Ref.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|FROM
	|	Document.CommissionReportIntercompany.InventoryKinds AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|
	|UNION ALL
	|
	|SELECT
	|	""Remuneration"" AS DataSource,
	|	TRUE AS DistributeTotalAmount,
	|	DocumentTable.Ref AS Ref,
	|	DocumentTable.Ref.Date AS Date,
	|	DocumentTable.Ref.Organization AS Organization,
	|	DocumentTable.Ref.Currency AS DocumentCurrency,
	|	DocumentTable.Ref.Currency AS ARAPCurrency,
	|	DocumentTable.Ref.Date AS VATBasePeriod,
	|	DocumentTable.Ref.Date AS DateOfCourse,
	|
	|	0 AS LineNumber,
	|	UNDEFINED AS RowID,
	|	DocumentTable.CommissionAmount - DocumentTable.AmountVATRemuneration AS AmountExcludingVAT,
	|	DocumentTable.VATRateOfRemuneration AS VATRate,
	|	DocumentTable.AmountVATRemuneration AS VATAmount,
	|	DocumentTable.CommissionAmount AS AmountARAP,
	|	DocumentTable.AmountVATRemuneration AS AmountVATARAP,
	|	0 AS AmountExcludingVATCompl,
	|	0 AS AmountExcludingVATMan,
	|	
	|	TRUE AS RecordedInARAPAccounting,
	|	DocumentTable.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
	|	TRUE AS RecalculateBasedOnARAPData
	|
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentTable
	|
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND DocumentTable.CommissionAmount <> 0
	|";
	
	InformationRegisters.DocumentAmountsInAccountingCurrency.GenerateAccordingToDocument(
		Query, QueryTexts, Registers, QueryTextdata_);

EndProcedure

Function QueryTextTablePurchases(Query, QueryTexts, Registers)
	
	RegisterName = "Purchases";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText =
	// Record debt to the consignor 
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RecordDebtToConsignor) AS BusinessOperation,
	|	&Consignee AS Organization,
	|	&Department AS Department,
	|	&Manager AS Manager,
	|
	|	TableTypesOfStocks_.ItemsLocationAttributes AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.LineOfBusiness AS ProductLineOfBusiness,
	|	TableTypesOfStocks_.Warehouse AS Warehouse,
	|	TableTypesOfStocks_.InventoryOwnerAttribute.InventoryType AS InventoryType,
	|	TableTypesOfStocks_.InventoryOwnerAttribute AS InventoryOwnerAttribute,
	|
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignor
	|	END AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	UNDEFINED AS Terms,
	|	CASE WHEN &ARAPAccountingViaSeparateCounterparty 
	|		THEN &PurchasingContract
	|		ELSE &Contract
	|	END AS Contract,
	|	UNDEFINED AS OrderDocument,
	|
	|	0 AS Count,
	|
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	CAST(TableTypesOfStocks_.AmountIncludingVAT * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST((TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount)
	|		* &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	0 AS DiscountAmount,
	|
	|	0 AS Cost,
	|	0 AS CostExcludingVAT,
	|	0 AS LocalCost,
	|	0 AS AddExpensesForGoods,
	|	0 AS AdditionalExpensesExcludingVAT,
	|
	|	&Currency AS DocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInDocumentCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInDocumentCurrency,
	|
	|	&Currency AS ARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT AS AmountInARAPCurrency,
	|	TableTypesOfStocks_.AmountIncludingVAT - TableTypesOfStocks_.VATAmount AS AmountExcludingVATInARAPCurrency,
	|
	|	CASE
	|		WHEN &GenerateInventoryOwnerAttributesByFinancialAccountingGroups
	|			THEN TableTypesOfStocks_.InventoryOwnerAttribute
	|		ELSE TableTypesOfStocks_.Products
	|	END AS SourceOfProductFinancialAccountingGroup,
	|	&ARAPObjectForSettlementsWithConsignor AS SourceOfARAPFinancialAccountingGroup
	|FROM
	|	TTTypesOfStocks AS TableTypesOfStocks_
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextGoodsTransferredToCommissionAgent(Query, QueryTexts, Registers)
	
	RegisterName = "GoodsTransferredToCommissionAgent";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableTypesOfStocks", QueryTexts) Then
		QueryTextTTTableTypesOfStocks(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	MIN(InventoryKinds.LineNumber)		AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)	AS RecordType,
	|	&Period									AS Period,
	|	InventoryKinds.CCDNumber					AS CCDNumber,
	|	InventoryKinds.AnalysisOfAccountingForTransmittedProducts AS ItemsLocationAttributes,
	|	UNDEFINED							AS Terms,
	|	&Consignor								AS Organization,
	|	InventoryKinds.InventoryAttributesOfConsignor			AS InventoryOwnerAttribute,
	|	CASE
	|		WHEN InventoryKinds.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END									AS Character,
	|	SUM(InventoryKinds.Count)			AS Count,
	|	SUM(InventoryKinds.QuantityByGBRN)		AS QuantityByGBRN,
	|	&ConsignmentReportFromCustomer						AS BusinessOperation
	|FROM
	|	TTTypesOfStocks AS InventoryKinds
	|
	|GROUP BY
	|	InventoryKinds.AnalysisOfAccountingForTransmittedProducts,
	|	InventoryKinds.InventoryAttributesOfConsignor,
	|	InventoryKinds.CCDNumber,
	|	CASE
	|		WHEN InventoryKinds.Count < 0
	|			THEN -1
	|		ELSE 1
	|	END
	|
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTableServicesForRegistrationOfReportsToPrincipal(Query, QueryTexts, Registers)
	
	RegisterName = "ServicesForRegistrationOfReportsToPrincipal";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTTableAgencyServices", QueryTexts) Then
		QueryTextTTAgencyServices(Query, QueryTexts);
	EndIf;
	
	QueryText = "
	|SELECT
	|	ToRegister.LineNumber                     AS LineNumber,
	|	VALUE(AccumulationRecordType.Expense)      AS RecordType,
	|	&Period                                     AS Period,
	|	&Consignee                                AS Organization,
	|	Dimension.DimensionKey                     AS ItemsLocationAttributes,
	|	ISNULL(AgentServices.Terms,
	|				UNDEFINED)                   AS Terms,
	|	ISNULL(AgentServices.Currency,
	|				&Currency)                        AS Currency,
	|	ToRegister.Count                      AS Count,
	|	ToRegister.SalesAmount                    AS RevenueAmount,
	|	ToRegister.AmountSalesVAT                 AS VATAmount,
	|	CASE
	|		WHEN ISNULL(AgentServices.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ISNULL(Amounts.AmountIncludingVATCompl, 0)
	|		ELSE 0
	|	END                                       AS RevenueAmountExclVATLocal,
	|	CASE
	|		WHEN ISNULL(AgentServices.Terms.RevalueServicesForConsignmentNotification, FALSE)
	|			THEN ISNULL(Amounts.AmountIncludingVATMan, 0)
	|		ELSE 0
	|	END                                       AS RevenueAmountMan,
	|
	|	ToRegister.DateOfTaxInvoiceIssuedByCommissionAgent    AS TaxInvoiceDate,
	|	ISNULL(DocumentsRegistry.IBDocumentNumber, """") AS TaxInvoiceNumber,
	|	ToRegister.Customer                            AS Customer,
	|	
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID,
	|	VALUE(Catalog.BusinessTransactionsSettings.RecordDebtToConsignor) AS BusinessTransactionSetting,
	|	ToRegister.RowID AS RowID
	|FROM
	|	Document.CommissionReportIntercompany.Goods AS ToRegister
	|	LEFT JOIN TTAgencyServices AS AgentServices
	|	ON ToRegister.Products = AgentServices.Products
	|		AND ToRegister.Characteristic = AgentServices.Characteristic
	|	
	|	LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistry
	|	ON ToRegister.IssuedTaxInvoiceOfCommissionAgent = DocumentsRegistry.Ref
	|		AND NOT DocumentsRegistry.AdditionalRecord
	|	
	|	LEFT JOIN InformationRegister.ItemsLocationAttributes AS Dimension
	|	ON Dimension.Products = ToRegister.Products
	|		AND Dimension.Characteristic = ToRegister.Characteristic
	|		AND Dimension.Series = VALUE(Catalog.ItemsBatches.EmptyRef)
	|		AND Dimension.Purpose = VALUE(Catalog.Assignments.EmptyRef)
	|		AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) = Dimension.StorageLocation
	|		AND VALUE(Catalog.ProductCostElements.EmptyRef) = Dimension.ProductCostElement
	|	LEFT JOIN TTAmountsOfDocumentsInAccountingCurrencies AS Amounts
	|		ON ToRegister.Ref = Amounts.Ref
	|		AND ToRegister.RowID = Amounts.RowID
	|WHERE
	|	ToRegister.Ref = &Ref
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> UNDEFINED
	|	AND ISNULL(ToRegister.Characteristic.Principal, ToRegister.Products.Principal) <> &Consignee
	|ORDER BY
	|	LineNumber";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;
	
EndFunction

Function QueryTextTableRecordsCounterpartyIncomeExpenses(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyIncomeExpenses";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.AccountSalesFromCommissionAgentCommissionFee) AS BusinessOperation,
	|	&Consignor AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignee
	|	END AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS ARAPObject,
	|	
	|	DocumentData.ExpenseItem AS IncomeAndExpenseItem,
	|	UNDEFINED AS DimensionOfExpenses,
	|	
	|	CAST(DocumentData.CommissionAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	
	|	CAST(DocumentData.CommissionAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CommissionAmount AS AmountInCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInCurrency,
	|	
	|	&Currency AS ARAPCurrency,
	|	DocumentData.CommissionAmount AS AmountInARAPCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableRecordsCounterpartyCounterparty(Query, QueryTexts, Registers)
	
	RegisterName = "RecordsCounterpartyCounterparty";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	SetRequestParametersCurrencyCoefficients(Query);
	
	QueryText =
	"SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.CommissionAgentSRemunerationDeduction) AS BusinessOperation,
	|	&Consignor AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignee
	|	END AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent AS ARAPObject,
	|	
	|	&Partner AS CorPartner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignee
	|	END AS CorCounterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CorLineOfBusiness,
	|	&Contract AS CorContract,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS CorARAPObject,
	|	
	|	CAST(DocumentData.CommissionAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	
	|	CAST(DocumentData.CommissionAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CommissionAmount AS AmountInCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInCurrency,
	|	
	|	&Currency AS ARAPCurrency,
	|	DocumentData.CommissionAmount AS AmountInARAPCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgentRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObjectForSettlementsWithCommissionAgent AS CorSourceOfARAPFinancialAccountingGroup,
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	VALUE(Enum.BusinessTransactions.RemunerationDeductionByConsignor) AS BusinessOperation,
	|	&Consignee AS Organization,
	|	&Department AS Department,
	|	
	|	&Partner AS Partner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignor
	|	END AS Counterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CounterpartyLineOfBusiness,
	|	&Contract AS Contract,
	|	DocumentData.ARAPObjectForSettlementsWithConsignorRemuneration AS ARAPObject,
	|	
	|	&Partner AS CorPartner,
	|	CASE
	|		WHEN &ARAPAccountingViaSeparateCounterparty
	|			THEN &Counterparty
	|		ELSE &Consignor
	|	END AS CorCounterparty,
	|	CASE
	|		WHEN &AccountingForSettlementsWithSuppliersUnderLB THEN
	|			&LineOfBusiness
	|	END AS CorLineOfBusiness,
	|	&Contract AS CorContract,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor AS CorARAPObject,
	|	
	|	CAST(DocumentData.CommissionAmount * &ConversionRateToManCurrency AS NUMBER(31,2)) AS Sum,
	|	CAST((DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration) * &ConversionRateToManCurrency AS NUMBER(31,2)) AS AmountExcludingVAT,
	|	
	|	CAST(DocumentData.CommissionAmount * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS SumCompl,
	|	CAST(DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration * &FactorOfConversionToCurrencyOfRegul AS NUMBER(31,2)) AS LocalAmountExcludingVAT,
	|	
	|	&Currency AS Currency,
	|	DocumentData.CommissionAmount AS AmountInCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInCurrency,
	|	
	|	&Currency AS ARAPCurrency,
	|	DocumentData.CommissionAmount AS AmountInARAPCurrency,
	|	DocumentData.CommissionAmount - DocumentData.AmountVATRemuneration AS AmountExcludingVATInARAPCurrency,
	|	
	|	DocumentData.ARAPObjectForSettlementsWithConsignorRemuneration AS SourceOfARAPFinancialAccountingGroup,
	|	DocumentData.ARAPObjectForSettlementsWithConsignor AS CorSourceOfARAPFinancialAccountingGroup,
	|	&IDOfPaymentObjectWithPrincipal AS FinRecordID
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND DocumentData.CommissionAmount <> 0
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	Return QueryText;

EndFunction

Function QueryTextTableDocumentsRegistry(Query, QueryTexts, Registers)
	
	RegisterName = "DocumentsRegistry";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	If Not DocumentsPosting.ThereIsQueryTable("TTBases", QueryTexts) Then
		QueryTextTTBases(Query, QueryTexts);
	EndIf;
	
	QueryText = 
	"SELECT
	|	DocumentData.RefType                AS RefType,
	|	DocumentData.Organization              AS Organization,
	|	DocumentData.BusinessOperation    AS BusinessOperation,
	|	DocumentData.Partner                  AS Partner,
	|	DocumentData.Counterparty               AS Counterparty,
	|	DocumentData.Contract                  AS Contract,
	|	DocumentData.LineOfBusiness  AS LineOfBusiness,
	|	DocumentData.AdditionalRecord     AS AdditionalRecord,
	|	DocumentData.Department            AS Department,
	|	DocumentData.StorageLocation            AS StorageLocation,
	|	DocumentData.IBDocumentDate          AS IBDocumentDate,
	|	DocumentData.Ref                   AS Ref,
	|	DocumentData.IBDocumentNumber         AS IBDocumentNumber,
	|	DocumentData.EmployeeResponsible            AS EmployeeResponsible,
	|	DocumentData.Author                    AS Author,
	|	DocumentData.Comment              AS Comment,
	|	DocumentData.Currency                   AS Currency,
	|	DocumentData.Sum                    AS Sum,
	|	DocumentData.Status                   AS Status,
	|	DocumentData.Posted                 AS Posted,
	|	DocumentData.DeletionMark          AS DeletionMark,
	|	DocumentData.More            AS More,
	|	DocumentData.SourceDocumentDate  AS SourceDocumentDate,
	|	DocumentData.SourceDocumentNumber AS SourceDocumentNumber,
	|	DocumentData.ExternalDocumentName AS SourceDocumentName,
	|	DocumentData.IBDocumentDate          AS RecordingInAccountingDate,
	|	UNDEFINED                             AS Priority
	|FROM
	|	TTBases AS DocumentData";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBases(Query, QueryTexts)
	
	RegisterName = "TTBases";
	
	QueryText =
	"SELECT
	|	TableDocumentRegistry.RefType                          AS RefType,
	|	TableDocumentRegistry.Organization                        AS Organization,
	|	TableDocumentRegistry.BusinessOperation              AS BusinessOperation,
	|	TableDocumentRegistry.Partner                            AS Partner,
	|	TableDocumentRegistry.Counterparty                         AS Counterparty,
	|	MAX(TableDocumentRegistry.Contract)                  AS Contract,
	|	TableDocumentRegistry.LineOfBusiness            AS LineOfBusiness,
	|	MIN(TableDocumentRegistry.AdditionalRecord)      AS AdditionalRecord,
	|	TableDocumentRegistry.Department                      AS Department,
	|	TableDocumentRegistry.StorageLocation                      AS StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate                    AS IBDocumentDate,
	|	TableDocumentRegistry.Ref                             AS Ref,
	|	MAX(TableDocumentRegistry.IBDocumentNumber)         AS IBDocumentNumber,
	|	MAX(TableDocumentRegistry.EmployeeResponsible)            AS EmployeeResponsible,
	|	MAX(TableDocumentRegistry.Author)                    AS Author,
	|	MAX(TableDocumentRegistry.Comment)              AS Comment,
	|	MAX(TableDocumentRegistry.Currency)                   AS Currency,
	|	MAX(TableDocumentRegistry.Sum)                    AS Sum,
	|	MAX(TableDocumentRegistry.Status)                   AS Status,
	|	MAX(TableDocumentRegistry.Posted)                 AS Posted,
	|	MAX(TableDocumentRegistry.DeletionMark)          AS DeletionMark,
	|	MAX(TableDocumentRegistry.More)            AS More,
	|	MAX(TableDocumentRegistry.SourceDocumentDate)  AS SourceDocumentDate,
	|	MAX(TableDocumentRegistry.ExternalDocumentName) AS ExternalDocumentName,
	|	MAX(TableDocumentRegistry.SourceDocumentNumber) AS SourceDocumentNumber
	|INTO TTBases
	|	FROM
	|	(SELECT
	|		DocumentData.Ref             AS Ref,
	|		&Period                            AS IBDocumentDate,
	|		&Number                             AS IBDocumentNumber,
	|		&MetadataIdentifier           AS RefType,
	|		&Consignor                          AS Organization,
	|		&BusinessOperation             AS BusinessOperation,
	|		&Partner                           AS Partner,
	|		&Counterparty                        AS Counterparty,
	|		&Contract                           AS Contract,
	|		UNDEFINED                       AS LineOfBusiness,
	|		UNDEFINED                       AS StorageLocation,
	|		&Department                     AS Department,
	|		&Manager                          AS EmployeeResponsible,
	|		&Author                             AS Author,
	|		CAST(&Comment AS STRING (100)) AS Comment,
	|		&Currency                            AS Currency,
	|		&DocumentAmount                    AS Sum,
	|		UNDEFINED                       AS Status,
	|		&Posted                          AS Posted,
	|		&DeletionMark                   AS DeletionMark,
	|		FALSE                               AS AdditionalRecord,
	|		CAST(&CommissionAgentInformation AS STRING (100)) AS More,
	|		&Period                            AS SourceDocumentDate,
	|		&ExternalDocumentName    AS ExternalDocumentName,
	|		&DocumentNumber                    AS SourceDocumentNumber
	|	FROM
	|		Document.CommissionReportIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		DocumentData.Ref   AS Ref,
	|		&Period                  AS IBDocumentDate,
	|		&Number                   AS IBDocumentNumber,
	|		&MetadataIdentifier AS RefType,
	|		&Consignee             AS Organization,
	|		&BusinessOperation   AS BusinessOperation,
	|		&Partner                 AS Partner,
	|		&Counterparty              AS Counterparty,
	|		&Contract                 AS Contract,
	|		UNDEFINED             AS LineOfBusiness,
	|		UNDEFINED             AS StorageLocation,
	|		&Department           AS Department,
	|		&Manager                AS EmployeeResponsible,
	|		&Author                   AS Author,
	|		CAST(&Comment AS STRING (100)) AS Comment,
	|		&Currency                  AS Currency,
	|		&DocumentAmount          AS Sum,
	|		UNDEFINED             AS Status,
	|		&Posted                AS Posted,
	|		&DeletionMark         AS DeletionMark,
	|		TRUE                   AS AdditionalRecord,
	|		CAST(&CommitteeInformation AS STRING (100)) AS More,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &Period
	|			ELSE &IncomingDocumentDate
	|		END                    AS SourceDocumentDate,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN UNDEFINED
	|			ELSE &ExternalDocumentName
	|		END                    AS ExternalDocumentName,
	|		CASE
	|			WHEN &Counterparty = VALUE(Catalog.Counterparties.EmptyRef)
	|				THEN &DocumentNumber
	|			ELSE &IncomingDocumentNumber
	|		END                    AS SourceDocumentNumber
	|	FROM
	|		Document.CommissionReportIntercompany AS DocumentData
	|	WHERE
	|		DocumentData.Ref = &Ref) AS TableDocumentRegistry
	|
	|GROUP BY
	|	TableDocumentRegistry.RefType,
	|	TableDocumentRegistry.Organization,
	|	TableDocumentRegistry.BusinessOperation,
	|	TableDocumentRegistry.Partner,
	|	TableDocumentRegistry.Counterparty,
	|	TableDocumentRegistry.LineOfBusiness,
	|	TableDocumentRegistry.Department,
	|	TableDocumentRegistry.StorageLocation,
	|	TableDocumentRegistry.IBDocumentDate,
	|	TableDocumentRegistry.Ref";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName      = "Document.CommissionReportIntercompany";
	SynonymForDocumentTable = "";
	RequestHasSource    = True;
	TemporaryTableQueryTexts = New Map();
	
	RequestTextPartenr = "
		|	CASE
		|		WHEN DocumentData.ARAPAccountingViaSeparateCounterparty
		|			THEN DocumentData.Partner
		|		ELSE VALUE(Catalog.Partners.OurEnterprise)
		|	END";
	
	RedefiningParameterCalculation = New Structure;
	RedefiningParameterCalculation.Insert("DocumentNumber",           """""");
	RedefiningParameterCalculation.Insert("CommitteeInformation",    """""");
	RedefiningParameterCalculation.Insert("IncomingDocumentNumber",  """""");
	RedefiningParameterCalculation.Insert("CommissionAgentInformation", """""");
	RedefiningParameterCalculation.Insert("Consignor",                 "DocumentData.Ref.Organization");
	RedefiningParameterCalculation.Insert("Partner",                  RequestTextPartenr);
	
	ParameterValues = New Structure;
	ParameterValues.Insert("BusinessOperation",
		Enums.BusinessTransactions.CommissionReportIntercompany);
	ParameterValues.Insert("MetadataIdentifier",
		Common.MetadataObjectID(FullDocumentName));
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = QueryTextTableDocumentsRegistry(Query, QueryTexts, RegisterName);
		TemporaryTableQueryTexts.Insert("TTBases", QueryTextTTBases(Query, QueryTexts));
		SynonymForDocumentTable = "DocumentData";
		
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
	
	If RegisterName = "DocumentsRegistry" Then
		
		QueryText = InfobaseUpdateTM.AdaptRequestForIndependentRegister(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RequestHasSource,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	Else
		
		QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
			QueryText,
			FullDocumentName,
			SynonymForDocumentTable,
			RedefiningParameterCalculation,
			TemporaryTableQueryTexts);
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues = ParameterValues;
	Result.QueryText = QueryText;
	
	Return Result;
	
EndFunction

#Region BatchAccounting

Function DescriptionOfCostAndCostRegisters(Document) Export
	
	DescriptionOfRegisters = New Array;
	DescriptionOfRegisters.Add(Metadata.AccumulationRegisters.InventoryCost);
	
	Return DescriptionOfRegisters;
	
EndFunction

Function SetAdditionalParametersForCostAndCostAccountingOperations(Document, Query = Undefined) Export
	
	AdditionalParameters = New Array;
	AdditionalParameters.Add("AnalyticsCommitteeCommissioner");
	
	If Query <> Undefined Then
		SetSettlementAnalyticsParameters(Query);
	EndIf;
	
	Return AdditionalParameters;
	
EndFunction

Function GenerateAdditionalTablesOfCostAndCostAccountingOperations(Document, Query = Undefined, QueryTexts = Undefined) Export
	
	AdditionalTables = New Array;
	AdditionalTables.Add("TTTableTypesOfStocks");
	
	If Query <> Undefined Then
	
		If Not DocumentsPosting.ThereIsQueryTable(AdditionalTables[0], QueryTexts) Then
			QueryTextTTTableTypesOfStocks(Query, QueryTexts);
		EndIf;
		
	EndIf;
	
	Return AdditionalTables;
	
EndFunction

Function DescriptionOfCostAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region Sales_Product
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_    AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 							AS Organization,
	|	TableTypesOfStocks_.AnalysisOfAccountingForTransmittedProducts	AS ItemsLocationAttributes,
	|	TableTypesOfStocks_.InventoryAttributesOfConsignor 					AS InventoryOwnerAttribute,
	|	&VATTaxation 									AS VATActivityType,
	|	DocumentTable.VATTaxation						AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    		AS CorCompany,
	|	UNDEFINED   											AS CorItemsLocationAttributes,
	|	UNDEFINED											AS CorInventoryOwnerAttribute,
	|	UNDEFINED 											AS CorLot,
	|	UNDEFINED											AS LotVendorAttributesCorr,
	|	&AnalyticsCommitteeCommissioner							AS AccountingDimensionByPartners,
	|	UNDEFINED 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	UNDEFINED						AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 			AS Count,
	|	UNDEFINED 							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.ConsignmentReportFromCustomer)					AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 											AS FinRecordID,
	|	&CommissionAgentSReportCatalog													AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentTable
	|	INNER JOIN TTTypesOfStocks AS TableTypesOfStocks_
	|		ON TRUE
	|	LEFT JOIN Catalog.InventoryKinds AS TypesOfCommitteeStocks
	|		ON TypesOfCommitteeStocks.Ref = TableTypesOfStocks_.InventoryAttributesOfConsignor
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND (TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.OwnGoods)
	|		OR TableTypesOfStocks_.InventoryType = VALUE(Enum.InventoryTypes.ConsignedGoods)
	|		OR TypesOfCommitteeStocks.InventoryType IS NULL)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion

	Return DescriptionOfOperations;
	
EndFunction

Function DescriptionOfRevenueAccountingOperations(Document) Export
	
	DescriptionOfOperations = New Array;
	
	#Region SaleOfGoodsAndServices
	
	QueryText = 
	"SELECT
	// Document description
	|	DocumentTable.Date 	AS Period,
	|	DocumentTable.Ref AS Ref,
	|	UNDEFINED			AS DocumentSource,
	|	UNDEFINED			AS SourceDocumentPeriod,
	|	UNDEFINED 			AS DocumentToBeCorrected,
	|	&AdjustmentPeriod_	AS VariancePeriod,
	|
	// Item accounting fields
	|	DocumentTable.Organization 					AS Organization,
	|	TableTypesOfStocks_.ItemsLocationAttributes 	AS ItemsLocationAttributes,
	|	UNDEFINED 									AS InventoryOwnerAttribute,
	|	TableTypesOfStocks_.VATTaxation 			AS VATActivityType,
	|	TableTypesOfStocks_.VATTaxation			AS DocumentVATActivityType,
	|
	// Corresponding fields
	|	UNDEFINED                                    AS CorCompany,
	|	UNDEFINED   									AS CorItemsLocationAttributes,
	|	UNDEFINED									AS CorInventoryOwnerAttribute,
	|	UNDEFINED 									AS CorLot,
	|	UNDEFINED									AS LotVendorAttributesCorr,
	|	&AccountingDimensionByPartners						AS AccountingDimensionByPartners,
	|	CASE WHEN &InvoiceByOrders THEN
	|		TableTypesOfStocks_.SalesOrder
	|	ELSE
	|		DocumentTable.Ref
	|	END 											AS SalesOrder,
	|
	// Financial Accounting Analysis Fields
	|	DocumentTable.SalesOpportunity				AS SalesOpportunity,
	|	DocumentTable.Department		AS Department,
	|	DocumentTable.Manager			AS Manager,
	|	UNDEFINED 						AS ProductsGroup,
	|
	// Quantitative and summary indicators
	|	TableTypesOfStocks_.Count 									AS Count,
	|	TableTypesOfStocks_.RowID							AS RowID,
	|
	// Other fields
	|	VALUE(Enum.BusinessTransactions.SaleToCustomer)	AS BusinessOperation,
	|	TableTypesOfStocks_.RowID 							AS FinRecordID,
	|	&BusinessTransactionSetting									AS BusinessTransactionSetting
	|
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentTable
	|	INNER JOIN TTOperationServices AS TableTypesOfStocks_
	|		ON TRUE
	|WHERE
	|	DocumentTable.Ref IN (&Ref)
	|	AND TableTypesOfStocks_.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)";
	
	CostCalculationDocumentsPosting.AddDescriptionOfTransactionForCostAccounting(
		DescriptionOfOperations,
		Enums.CostAccountingTransactions.SaleOfGoodsAndServices,
		QueryText);
	
	#EndRegion
	
EndFunction

#EndRegion

#Region Print

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

	// Commission agent's report on sales
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "DataProcessor.PrintCommissionReports";
	PrintCommand.Id = "ConsignmentReportFromCustomer";
	PrintCommand.Presentation = NStr("vi = 'Bảng kê hàng hóa của người nhận bán hộ';
									|ru = 'Отчет комиссионера о продажах';
									|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
									|it = 'Report del commissionario sulle vendite';
									|pl = 'Raport komisanta ze sprzedaży';
									|tr = 'Konsinye satış raporu'");
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.DefaultPrintForm = True;
	PrintCommand.PrintFormDescription = NStr("vi = 'Bảng kê hàng hóa của người nhận ký gửi';
											|ru = 'Отчет комиссионера о продажах';
											|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
											|it = 'Report del commissionario sulle vendite';
											|pl = 'Raport komisanta ze sprzedaży';
											|tr = 'Konsinye satış raporu'");

	CommissionReportIntercompanyLocalization.AddPrintCommands(PrintCommands);

EndProcedure

// Generates a printable form.
//
// Parameters:
//  ObjectsArray  - Array    - references to objects that should be printed;
//  PrintParameters - Structure - advanced print settings;
//  PrintFormsCollection - ValueTable - generated table documents (output parameter)
//  PrintObjects         - ValueList  - value - the object reference;
//                                            view - name of the area where the object was output (output parameter);
//  OutputParameters       - Structure       - additional parameters of generated table documents (output parameter).
//
Procedure Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters) Export
	CommissionReportIntercompanyLocalization.Print(ObjectsArray, PrintParameters, PrintFormsCollection, PrintObjects, OutputParameters);
EndProcedure

Function GetDataForPrintedCommissionReportForm(PrintParameters, ObjectsArray) Export
	
	Query = New Query(
	"
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Number AS Number,
	|	DocumentData.Date AS Date,
	|	DocumentData.Consignee AS Consignee,
	|	DocumentData.Organization AS Consignor,
	|	DocumentData.Organization.Prefix AS Prefix,
	|	DocumentData.Currency AS Currency,
	|	DocumentData.CommissionAmount AS CommissionAmount,
	|	"""" AS CommitteeRepresentative,
	|	DocumentData.Manager.Individual AS RepresentativeOfCommissionAgent
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND (NOT DocumentData.ARAPAccountingViaSeparateCounterparty)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.Number,
	|	DocumentData.Date,
	|	DocumentData.Consignee,
	|	DocumentData.Counterparty,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Currency,
	|	DocumentData.CommissionAmount,
	|	"""",
	|	DocumentData.Manager.Individual
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.Consignee <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentData.Ref,
	|	DocumentData.IncomingDocumentNumber,
	|	DocumentData.IncomingDocumentDate,
	|	DocumentData.Counterparty,
	|	DocumentData.Organization,
	|	DocumentData.Organization.Prefix,
	|	DocumentData.Currency,
	|	DocumentData.CommissionAmount,
	|	"""",
	|	DocumentData.Manager.Individual
	|FROM
	|	Document.CommissionReportIntercompany AS DocumentData
	|WHERE
	|	DocumentData.Ref IN(&DocumentsArray)
	|	AND DocumentData.Posted
	|	AND DocumentData.ARAPAccountingViaSeparateCounterparty
	|	AND DocumentData.Organization <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|
	|SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.Products AS Products,
	|	NestedQuery.Products.DescriptionFull AS ProductItemName,
	|	NestedQuery.Products.Code AS Code,
	|	NestedQuery.Products.SKU AS SKU,
	|	NestedQuery.UnitOfMeasure.Presentation AS UnitOfMeasurementName,
	|	NestedQuery.Characteristic.DescriptionFull AS Characteristic,
	|	CASE
	|		WHEN ISNULL(NestedQuery.Package, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END AS Package,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent AS TaxInvoiceDate,
	|	NestedQuery.Customer AS Customer,
	|	NestedQuery.Price AS Price,
	|	SUM(NestedQuery.Count) AS Count,
	|	SUM(NestedQuery.ConsignorAmount) AS ConsignorAmount,
	|	SUM(NestedQuery.SalesAmount) AS SalesAmount,
	|	SUM(NestedQuery.CommissionAmount) AS CommissionAmount,
	|	MAX(NestedQuery.LineNumber) AS LineNumber
	|FROM
	|	(SELECT
	|		GoodsTable.Ref AS Ref,
	|		GoodsTable.Products AS Products,
	|		&QueryTextUnitOfMeasure AS UnitOfMeasure,
	|		GoodsTable.Characteristic AS Characteristic,
	|		GoodsTable.Package AS Package,
	|		GoodsTable.DateOfTaxInvoiceIssuedByCommissionAgent AS DateOfTaxInvoiceIssuedByCommissionAgent,
	|		GoodsTable.Customer AS Customer,
	|		GoodsTable.NumberOfPackages AS Count,
	|		GoodsTable.Price AS Price,
	|		GoodsTable.AmountIncludingVAT AS ConsignorAmount,
	|		GoodsTable.SalesAmount AS SalesAmount,
	|		GoodsTable.CommissionAmount AS CommissionAmount,
	|		GoodsTable.LineNumber AS LineNumber
	|	FROM
	|		Document.CommissionReportIntercompany.Goods AS GoodsTable
	|	WHERE
	|		GoodsTable.Ref IN(&DocumentsArray)
	|	) AS NestedQuery
	|
	|GROUP BY
	|	NestedQuery.Ref,
	|	NestedQuery.Products,
	|	NestedQuery.UnitOfMeasure,
	|	NestedQuery.Characteristic,
	|	NestedQuery.Package,
	|	NestedQuery.Price,
	|	NestedQuery.Products.DescriptionFull,
	|	NestedQuery.Products.Code,
	|	NestedQuery.Products.SKU,
	|	NestedQuery.UnitOfMeasure.Presentation,
	|	NestedQuery.Characteristic.DescriptionFull,
	|	CASE
	|		WHEN ISNULL(NestedQuery.Package, 1) = 1
	|			THEN UNDEFINED
	|		ELSE NestedQuery.Package.Description
	|	END,
	|	NestedQuery.DateOfTaxInvoiceIssuedByCommissionAgent,
	|	NestedQuery.Customer
	|
	|ORDER BY
	|	Ref,
	|	LineNumber
	|TOTALS
	|	SUM(ConsignorAmount),
	|	SUM(SalesAmount),
	|	SUM(CommissionAmount)
	|BY
	|	Ref");
	
	Query.Text = StrReplace(
		Query.Text,
		"&QueryTextUnitOfMeasure",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"Ref",
			"GoodsTable.Package",
			"GoodsTable.Products"));
			
	Query.SetParameter("DocumentsArray", ObjectsArray);
	
	Title = NStr("vi = 'Bảng kê hàng hóa của người nhận bán hộ';
				|ru = 'Отчет комиссионера о продажах';
				|en = 'Consignment issue notification'; fa = 'اعلان صدور امانی';
				|it = 'Report del commissionario sulle vendite';
				|pl = 'Raport komisanta ze sprzedaży';
				|tr = 'Konsinye satış raporu'");
	ResultsArray 			= Query.ExecuteBatch();
	HeaderResults			= ResultsArray[0];
	ResultForTabularPart 	= ResultsArray[1];
	DataStructureForPrinting 	= New Structure(
		"HeaderResults, ResultForTabularPart, Title",
		HeaderResults,
		ResultForTabularPart,
		Title);
	
	Return DataStructureForPrinting;
	
EndFunction

// Fills in the structure with data about recipients of printed forms.
// Parameters:
// 	PrintObjectDataStructure - See PrintFormGeneration.FillInRecipientStructureDataByObjectType.PrintObjectDataStructure
// 
Procedure FillInStructureOfRecipientsOfPrintedForms(PrintObjectDataStructure) Export
	
	PrintObjectDataStructure.PrimaryRecipient = "Partner";
		
		PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Partner");
		If GetFunctionalOption("UsePartnersAndCounterparties") Then 
			PrintObjectDataStructure.ArrayOfRecipientDetails.Add("Counterparty");
		EndIf;
	
EndProcedure

#EndRegion

#Region State

// Calculates the current status of the Commission report on the recipient's side.
//
// Parameters:
//	ReportOnCommission         - DocumentRef.CommissionReportIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//	Organization             - Undefined, CatalogRef.Companies - Organization.
//
Procedure CalculateRecipientState(Val ReportOnCommission, Val Contract, StateOfCalculations, Organization=Undefined) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusRecipient());
	
	If ValueIsFilled(ReportOnCommission) And AccessRight("Read", Metadata.AccumulationRegisters.VendorsARAPAccounting) Then
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0)
		                      |					END AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS PaymentAmountRecipient,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0) - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE ISNULL(VendorsARAPAccountingBalance.AmountDueReceipt, 0)
		                      |					END * 100 / CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0)
		                      |					END AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PaymentPercentageRecipient,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |				AND ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) < 0
		                      |			THEN CAST(-ISNULL(SettlementsWithSuppliersBalancesAsOfDate.AmountDueBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfOverduePaymentRecipient,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0)
		                      |				END
		                      |		ELSE 0
		                      |	END AS OrderReceiptAmount,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PercentageOfOrderReceipt,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.Posted
		                      |				AND (ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |					OR DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		                      |			THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfDebtRecipient,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) > 0
		                      |			THEN CASE
		                      |					WHEN ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) > 0
		                      |						THEN CAST(ISNULL(VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |					ELSE CAST(ISNULL(-VendorsARAPAccountingBalance.SumClosingBalance, 0) * 100 / ISNULL(VendorsARAPAccountingBalance.AmountDueExpense, 0) AS NUMBER(15, 0))
		                      |				END
		                      |		ELSE 0
		                      |	END AS PercentageOfDebtRecipient,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.Posted
		                      |				AND DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |			THEN -VendorsARAPAccountingBalance.AmountDueClosingBalance
		                      |		ELSE 0
		                      |	END AS AmountPayableRecipient
		                      |FROM
		                      |	Document.CommissionReportIntercompany AS DocumentReportOnCommission
		                      |		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.BalanceAndTurnovers(
		                      |				,
		                      |				,
		                      |				,
		                      |				,
		                      |				ARAPObject.Object = &ReportOnCommission
		                      |					AND ARAPObject.Organization = &Organization
		                      |					AND (AccountingDimensionByPartners.Organization = &Organization
		                      |						OR &Organization = UNDEFINED)) AS VendorsARAPAccountingBalance
		                      |		ON (TRUE)
		                      |		LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
		                      |				ENDOFPERIOD(&CurrentDate, DAY),
		                      |				ARAPObject.Object = &ReportOnCommission
		                      |				AND ARAPObject.Organization = &Organization
		                      |					AND (AccountingDimensionByPartners = &Organization
		                      |						OR &Organization = UNDEFINED)) AS SettlementsWithSuppliersBalancesAsOfDate
		                      |		ON (TRUE)
		                      |WHERE
		                      |	DocumentReportOnCommission.Ref = &ReportOnCommission");
		
		Query.SetParameter("ReportOnCommission", ReportOnCommission);
		Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Calculates the current status of the Commission report on the sender's side.
//
// Parameters:
//	ReportOnCommission  - DocumentRef.CommissionReportIntercompany - Document whose state needs to be calculated
//	Contract                 - CatalogRef.CounterpartyContracts    - Customer agreement
//	StateOfCalculations       - ClientApplicationForm - The form in which the calculated state will be placed.
//	Organization             - CatalogRef.Companies - Organization.
//
Procedure CalculateSenderState(Val ReportOnCommission, Val Contract, StateOfCalculations, Organization) Export
	
	FillPropertyValues(StateOfCalculations, StructureOfSettlementStatusSender());
	
	If ValueIsFilled(ReportOnCommission) And AccessRight("Read", Metadata.AccumulationRegisters.CustomersARAPAccounting) Then
		SetPrivilegedMode(True);
		Query = New Query("SELECT
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0) - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0)
		                      |				END
		                      |		ELSE 0
		                      |	END AS PaymentAmountSender,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CAST(CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0) - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE ISNULL(CustomersARAPAccountingBalance.AmountDueExpense, 0)
		                      |					END * 100 / CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE DocumentReportOnCommission.DocumentAmount
		                      |					END AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS PaymentPercentageSender,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CAST(ISNULL(SettlementsWithCustomersBalancesAsOfDateOfRelevance.AmountDueBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOfOverduePaymentSender,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0) - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0)
		                      |				END
		                      |		ELSE 0
		                      |	END AS AmountByShipment,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CAST(CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0) - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE ISNULL(CustomersARAPAccountingBalance.SumReceipt, 0)
		                      |					END * 100 / CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE DocumentReportOnCommission.DocumentAmount
		                      |					END AS NUMBER(15, 0))
		                      |		ELSE 0
		                      |	END AS OrderShipmentPercentage,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.Posted
		                      |				AND (CASE
		                      |						WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |							THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |						ELSE DocumentReportOnCommission.DocumentAmount
		                      |					END > 0
		                      |					OR DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts))
		                      |			THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) AS NUMBER(31,2))
		                      |		ELSE 0
		                      |	END AS AmountOwedSender,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.ARAPObjectSettings <> VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |				AND DocumentReportOnCommission.Posted
		                      |				AND CASE
		                      |					WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |						THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |					ELSE DocumentReportOnCommission.DocumentAmount
		                      |				END > 0
		                      |			THEN CASE
		                      |					WHEN ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) > 0
		                      |						THEN CAST(ISNULL(CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / CASE
		                      |									WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |										THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |									ELSE DocumentReportOnCommission.DocumentAmount
		                      |								END AS NUMBER(15, 0))
		                      |					ELSE CAST(ISNULL(-CustomersARAPAccountingBalance.SumClosingBalance, 0) * 100 / CASE
		                      |								WHEN DocumentReportOnCommission.KeepCommissionFee
		                      |									THEN DocumentReportOnCommission.DocumentAmount - DocumentReportOnCommission.CommissionAmount
		                      |								ELSE DocumentReportOnCommission.DocumentAmount
		                      |							END AS NUMBER(15, 0))
		                      |				END
		                      |		ELSE 0
		                      |	END AS PercentageOfDebtSender,
		                      |	CASE
		                      |		WHEN DocumentReportOnCommission.Posted
		                      |				AND DocumentReportOnCommission.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByCounterpartyContracts)
		                      |			THEN CustomersARAPAccountingBalance.AmountDueClosingBalance
		                      |		ELSE 0
		                      |	END AS AmountPayableSender
		                      |FROM
		                      |	Document.CommissionReportIntercompany AS DocumentReportOnCommission
		                      |		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.BalanceAndTurnovers(
		                      |				,
		                      |				,
		                      |				,
		                      |				,
		                      |				ARAPObject.Object = &ReportOnCommission
		                      |					AND ARAPObject.Organization = &Organization
		                      |					AND (AccountingDimensionByPartners.Organization = &Organization
		                      |						OR &Organization = UNDEFINED)) AS CustomersARAPAccountingBalance
		                      |		ON (TRUE)
		                      |		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		                      |				ENDOFPERIOD(&CurrentDate, DAY),
		                      |				ARAPObject.Object = &ReportOnCommission
		                      |				AND ARAPObject.Organization = &Organization
		                      |					AND (AccountingDimensionByPartners.Organization = &Organization
		                      |						OR &Organization = UNDEFINED)) AS SettlementsWithCustomersBalancesAsOfDateOfRelevance
		                      |		ON (TRUE)
		                      |WHERE
		                      |	DocumentReportOnCommission.Ref = &ReportOnCommission");
		
		Query.SetParameter("ReportOnCommission", ReportOnCommission);
		Query.SetParameter("CurrentDate",  BegOfDay(CurrentSessionDate()));
		Query.SetParameter("Organization", Organization);
		
		Selection = Query.Execute().Select();
		Selection.Next();
		
		FillPropertyValues(StateOfCalculations, Selection);
		
	EndIf;
	
EndProcedure

// Initializes the calculation state structure.
Function StructureOfSettlementStatusRecipient()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountRecipient", 0);
	StructureOfStateOfCalculations.Insert("OrderReceiptAmount", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfOrderReceipt", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtRecipient", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableRecipient", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

// Initializes the calculation state structure.
//
Function StructureOfSettlementStatusSender()
	
	StructureOfStateOfCalculations = New Structure;
	StructureOfStateOfCalculations.Insert("PaymentAmountSender", 0);
	StructureOfStateOfCalculations.Insert("AmountByShipment", 0);
	StructureOfStateOfCalculations.Insert("PaymentPercentageSender", 0);
	StructureOfStateOfCalculations.Insert("OrderShipmentPercentage", 0);
	StructureOfStateOfCalculations.Insert("AmountOfOverduePaymentSender", 0);
	StructureOfStateOfCalculations.Insert("AmountOwedSender", 0);
	StructureOfStateOfCalculations.Insert("PercentageOfDebtSender", 0);
	StructureOfStateOfCalculations.Insert("AmountPayableSender", 0);
	
	Return StructureOfStateOfCalculations
	
EndFunction

#EndRegion

#Region Posting

#EndRegion

#EndRegion

#EndIf
