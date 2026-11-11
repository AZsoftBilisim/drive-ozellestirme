#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
//
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1, "Department");
	
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("PlanningCashControl");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.CashTransferReferenceOrder") Then
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
		
		QueryTextTableCashToBePaid(Query, QueryTexts, Registers);
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
	
	Documents.CashAccountReceiptNote.AddGenerateCommand(GenerationCommands);
	
	Documents.CashVoucher.AddGenerateCommand(GenerationCommands);
	
	Documents.BankAccountIssue.AddGenerateCommand(GenerationCommands);
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the command to create the "Order" document.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//	ValueTable, Undefined - generated commands for output to the submenu.
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.CashTransferReferenceOrder) Then
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.CashTransferReferenceOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.CashTransferReferenceOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UsePaymentRequests";
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
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

// The procedure fills in arrays of details that depend on the business operation of the document.
//
// Parameters:
//	BusinessOperation - EnumRef.BusinessTransactions - The selected business transaction
//	ArrayOfAllProps - Array - Array of all names of banking details that depend on the business operation
//	ArrayOfOperationDetails - Array - Array of names of banking details used in the selected business operation.
//
Procedure FillInNamesOfBusinessTransactionDetails(BusinessOperation, ArrayOfAllProps, ArrayOfOperationDetails) Export
	
	ArrayOfAllProps = New Array;
	ArrayOfAllProps.Add("BankAccount");
	ArrayOfAllProps.Add("CashAccount");
	ArrayOfAllProps.Add("BankAccountBeneficiary");
	ArrayOfAllProps.Add("CashAccountRecipient");
	ArrayOfAllProps.Add("Department");
	
	ArrayOfOperationDetails = New Array;
	If BusinessOperation = Enums.BusinessTransactions.CashDepositToBankAccount Then
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashCollectionToBank Then
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashIssueToAnotherCashAccount Then
		ArrayOfOperationDetails.Add("CashAccount");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.TransferCashToAnotherAccount Then
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("BankAccountBeneficiary");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.CashReceiptFromBank Then
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("Department");
		
	ElsIf BusinessOperation = Enums.BusinessTransactions.WithdrawalFromBankAccount Then
		ArrayOfOperationDetails.Add("BankAccount");
		ArrayOfOperationDetails.Add("CashAccountRecipient");
		ArrayOfOperationDetails.Add("Department");
		
	EndIf;
	
EndProcedure

// The function defines the details of the document.
//
// Parameters:
//  DocumentRef - DocumentRef - Link to the document.
//
// Returns:
//	Structure - details of the selected document.
//
Function DocumentAttributes(DocumentRef) Export
	
	Query = New Query("
	|SELECT
	|	DocumentData.Organization AS Organization,
	|	DocumentData.Department AS Department,
	|	DocumentData.Status AS Status,
	|	DocumentData.Currency AS Currency
	|FROM
	|	Document.CashTransferReferenceOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &DocumentRef
	|");
	
	Query.SetParameter("DocumentRef", DocumentRef);
	
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Organization = Selection.Organization;
		Department = Selection.Department;
		Status = Selection.Status;
		Currency = Selection.Currency;
	Else
		Organization = Catalogs.Companies.EmptyRef();
		Department = Catalogs.BusinessStructure.EmptyRef();
		Status = Enums.CashTransferOrderStatuses.EmptyRef();
		Currency = Catalogs.Currencies.EmptyRef();
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Organization", Organization);
	AttributesStructure1.Insert("Department", Department);
	AttributesStructure1.Insert("Status", Status);
	AttributesStructure1.Insert("Currency", Currency);
	
	Return AttributesStructure1;
	
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
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(BusinessOperation)
	|	AND CASE WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashDepositToBankAccount)                 OR BusinessOperation = VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount) THEN ValueAllowed(CashAccount)
	|	WHEN BusinessOperation = VALUE(Enum.BusinessTransactions.CashReceiptFromBank) THEN ValueAllowed(CashAccountRecipient)
	|	ELSE TRUE END ";

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

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export
	
	DataSources = New Map;
	
	Return DataSources;
	
EndFunction

Function AdaptedCaseSensitiveQueryText(RegisterName) Export
	
	Query = New Query();
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.CashTransferReferenceOrder";
	
	If RegisterName = "CashToBePaid" Then
		
		QueryText = QueryTextTableCashToBePaid(Query, QueryTexts, RegisterName);
		SynonymForDocumentTable = "DocumentData";
		
	Else
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydında hareketlerin oluşturulması talebinin metninin uyarlanması uygulanmamıştır.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.ParameterValues.Insert("UsePaymentRequests",
		GetFunctionalOption("UsePaymentRequests"));
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
		QueryText, FullDocumentName, SynonymForDocumentTable);
	
	Return Result;
	
EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	DocumentData.Currency AS Currency,
	|	DocumentData.BusinessOperation AS BusinessOperation,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.BankAccount AS BankAccount,
	|	DocumentData.CashAccount AS CashAccount,
	|	VALUE(Catalog.Partners.EmptyRef) AS Partner,
	|	VALUE(Catalog.Counterparties.EmptyRef) AS Counterparty,
	|	VALUE(Catalog.CounterpartyContracts.EmptyRef) AS Contract,
	|	VALUE(Catalog.LinesOfBusiness.EmptyRef) AS LineOfBusiness
	|FROM
	|	Document.CashTransferReferenceOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|";
	
	Result = Query.Execute();
	Attributes = Result.Select();
	Attributes.Next();
	
	For Each Column In Result.Columns Do
		Query.SetParameter(Column.Name, Attributes[Column.Name]);
	EndDo;
	
	Query.SetParameter("AccountingDimensionByPartners",
		InformationRegisters.AccountingDimensionByPartners.AnalyticsKeyValue(Attributes));
	Query.SetParameter("UsePaymentRequests",
		GetFunctionalOption("UsePaymentRequests"));
	Query.SetParameter("CashFlowItem",
		Catalogs.CashFlowReportItems.PredefinedCFItem(Attributes.BusinessOperation, Attributes.Currency));
	
EndProcedure

Function QueryTextTableCashToBePaid(Query, QueryTexts, Registers)
	
	RegisterName = "CashToBePaid";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText = "
	|SELECT
	|	CASE WHEN DocumentData.PaymentDate <> DATETIME(1,1,1) THEN
	|		DocumentData.PaymentDate
	|	ELSE
	|		DocumentData.Date
	|	END AS Period,
	|	VALUE(AccumulationRecordType.Receipt) AS RecordType,
	|	&Ref AS PaymentRequest,
	|	
	|	CASE WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.CashDepositToBankAccount),
	|		VALUE(Enum.BusinessTransactions.CashCollectionToBank),
	|		VALUE(Enum.BusinessTransactions.CashIssueToAnotherCashAccount))
	|	THEN
	|		&CashAccount
	|	WHEN &BusinessOperation IN (
	|		VALUE(Enum.BusinessTransactions.TransferCashToAnotherAccount),
	|		VALUE(Enum.BusinessTransactions.CashReceiptFromBank),
	|		VALUE(Enum.BusinessTransactions.WithdrawalFromBankAccount))
	|	THEN
	|		&BankAccount
	|	END AS BankAccountCashAccount,
	|	
	|	&Organization AS Recipient,
	|	&Organization AS Organization,
	|	
	|	DocumentData.DocumentAmount AS Sum,
	|	
	|	DocumentData.BusinessOperation AS BusinessOperation
	|	
	|FROM
	|	Document.CashTransferReferenceOrder AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref
	|	AND &UsePaymentRequests
	|	AND DocumentData.Status <> VALUE(Enum.CashTransferOrderStatuses.TurnDown)
	|";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function GenerateVerificationRequestWhenStatusChanges(DocumentsArray, NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.CashTransferOrderStatuses[NewStatus];
	
	QueryText =
	"SELECT
	|	DocumentsTable.Ref AS Ref,
	|	PRESENTATION(DocumentsTable.Ref) AS Presentation,
	|	PRESENTATION(DocumentsTable.Status) AS PresentationOfCurStatus,
	|	PRESENTATION(&Status) AS PresentationOfNewStatus,
	|	CASE
	|		WHEN DocumentsTable.Status = &Status
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS StatusMatches,
	|	DocumentsTable.Posted AS Posted,
	|	DocumentsTable.DeletionMark AS DeletionMark,
	|	TRUE AS Recording
	|FROM
	|	Document.CashTransferReferenceOrder AS DocumentsTable
	|WHERE
	|	DocumentsTable.Ref IN(&DocumentsArray)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Status", MeaningOfNewStatus);
	Query.SetParameter("DocumentsArray", DocumentsArray);
	
	Return Query;
	
EndFunction

Function CheckingBeforeChangingStatus(ValidationSample, NewStatus, AdditionalParameters) Export
	
	Return True; // There are no additional checks for the document "Disposition of Monetary funds"
	
EndFunction

// Defines the properties of form fields depending on the data
//
// Parameters:
//	Settings - ValueTable - table with columns:
//		* Fields - Array - fields for which display settings are defined
//		* Condition - DataCompositionFilter - terms of use settings
//		* Properties - Structure - property names and values
//
Procedure FillInFormFieldSettings(Settings) Export
	
	Finances = FinancialReportingServer;
	Operations = Enums.BusinessTransactions;
	
	// BankAccount
	Item = Settings.Add();
	Item.Fields.Add("BankAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashToAnotherAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.WithdrawalFromBankAccount);
	Item.Properties.Insert("Visible");
	
	// CashAccount
	Item = Settings.Add();
	Item.Fields.Add("CashAccount");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashDepositToBankAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionToBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueToAnotherCashAccount);
	Item.Properties.Insert("Visible");
	
	// BankAccountBeneficiary
	Item = Settings.Add();
	Item.Fields.Add("BankAccountBeneficiary");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashDepositToBankAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashCollectionToBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.TransferCashToAnotherAccount);
	Item.Properties.Insert("Visible");
	
	// CashAccountRecipient
	Item = Settings.Add();
	Item.Fields.Add("CashAccountRecipient");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashIssueToAnotherCashAccount);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.CashReceiptFromBank);
	Finances.NewFilter(OrGroup, "BusinessOperation", Operations.WithdrawalFromBankAccount);
	Item.Properties.Insert("Visible");
	
	// WhoDecided
	Item = Settings.Add();
	Item.Fields.Add("WhoDecided");
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.CashTransferOrderStatuses.Approved);
	Finances.NewFilter(OrGroup, "Status", Enums.CashTransferOrderStatuses.AmountDue);
	Item.Properties.Insert("Visible");
	
	// ReadOnly
	Item = Settings.Add();
	Item.Fields.Add("Number");
	Item.Fields.Add("Date");
	Item.Fields.Add("BankAccount");
	Item.Fields.Add("CashAccount");
	Item.Fields.Add("DocumentAmount");
	Item.Fields.Add("Currency");
	Item.Fields.Add("BusinessOperation");
	Item.Fields.Add("BankAccountBeneficiary");
	Item.Fields.Add("CashAccountRecipient");
	Item.Fields.Add("PaymentDate");
	Item.Fields.Add("Department");
	
	OrGroup = Finances.NewFilter(Item.Condition,,, Type("DataCompositionFilterItemGroup"));
	OrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	Finances.NewFilter(OrGroup, "Status", Enums.CashTransferOrderStatuses.Approved);
	Finances.NewFilter(OrGroup, "Status", Enums.CashTransferOrderStatuses.AmountDue);
	Finances.NewFilter(Item.Condition, "Posted", True);
	Finances.NewFilter(Item.Condition, "More.Modified", False);
	Item.Properties.Insert("ReadOnly");
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
