#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	GenerateSelectionOfListData();
	
	If Parameters.Filter.Property("LineOfBusiness") Then
		CommonClientServer.SetDynamicListParameter(List, "FieldOfActivitySelection", Parameters.Filter.LineOfBusiness);
	EndIf;
	
	ContractTypes = New Array;
	ContractTypes.Add(Type("CatalogRef.CounterpartyContracts"));
	If AccessRight("View", Metadata.Catalogs.IntercompanyContracts) Then
		ContractTypes.Add(Type("CatalogRef.IntercompanyContracts"));
	EndIf;
	If AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts) Then
		ContractTypes.Add(Type("CatalogRef.LoanAndDepositContracts"));
	EndIf;
	If AccessRight("View", Metadata.Catalogs.AcquiringContracts) Then
		ContractTypes.Add(Type("CatalogRef.AcquiringContracts"));
	EndIf;
	
	// StandardSubsystems.AttachableCommands
	PlacementParameter = AttachableCommands.PlacementParameters();
	PlacementParameter.Sources = New TypeDescription(ContractTypes);
	PlacementParameter.CommandBar = Items.ListCommandBar;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameter);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersDocumentsList

&AtClient
Procedure ListWhenFieldIsActivated(Item)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
    AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.List);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
    ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
    AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
    AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure GenerateSelectionOfListData()

	QueriesTexts = New Array;
	
	QueryText = 
	"SELECT
	|	CounterpartyContracts.Ref AS Ref,
	|	&TextOfContractOfCounterparty AS ContractType,
	|	CounterpartyContracts.DeletionMark AS DeletionMark,
	|	CounterpartyContracts.Approved AS Approved,
	|	CounterpartyContracts.Status AS Status,
	|	CounterpartyContracts.Organization AS Organization,
	|	CounterpartyContracts.Number AS Number,
	|	CounterpartyContracts.NameForPrinting AS NameForPrinting,
	|	CounterpartyContracts.ValidityStartDate AS ValidityStartDate,
	|	CounterpartyContracts.ValidityEndDate AS ValidityEndDate,
	|	CounterpartyContracts.ARAPCurrency AS ARAPCurrency
	|FROM
	|	Catalog.CounterpartyContracts AS CounterpartyContracts
	|WHERE
	|	CounterpartyContracts.LineOfBusiness = &FieldOfActivitySelection";
	QueriesTexts.Add(QueryText);
	
	If AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts) Then
		QueryText = "SELECT
		|	LoanAndDepositContracts.Ref AS Ref,
		|	&TextContractOfLoansDeposits AS ContractType,
		|	LoanAndDepositContracts.DeletionMark AS DeletionMark,
		|	LoanAndDepositContracts.Approved AS Approved,
		|	LoanAndDepositContracts.Status AS Status,
		|	LoanAndDepositContracts.Organization AS Organization,
		|	LoanAndDepositContracts.Number AS Number,
		|	LoanAndDepositContracts.NameForPrinting AS NameForPrinting,
		|	DATETIME(1,1,1) AS ValidityStartDate,
		|	DATETIME(1,1,1) AS ValidityEndDate,
		|	LoanAndDepositContracts.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Catalog.LoanAndDepositContracts AS LoanAndDepositContracts
		|WHERE
		|	LoanAndDepositContracts.LineOfBusiness = &FieldOfActivitySelection";
		QueriesTexts.Add(QueryText);
	EndIf;
	
	If AccessRight("View", Metadata.Catalogs.IntercompanyContracts) Then
		QueryText = "SELECT
		|	IntercompanyContracts.Ref AS Ref,
		|	&TextContractBetweenOrganizations AS ContractType,
		|	IntercompanyContracts.DeletionMark AS DeletionMark,
		|	IntercompanyContracts.Approved AS Approved,
		|	IntercompanyContracts.Status AS Status,
		|	IntercompanyContracts.Organization AS Organization,
		|	IntercompanyContracts.Number AS Number,
		|	IntercompanyContracts.NameForPrinting AS NameForPrinting,
		|	IntercompanyContracts.ValidityStartDate AS ValidityStartDate,
		|	IntercompanyContracts.ValidityEndDate AS ValidityEndDate,
		|	IntercompanyContracts.ARAPCurrency AS ARAPCurrency
		|FROM
		|	Catalog.IntercompanyContracts AS IntercompanyContracts
		|WHERE
		|	IntercompanyContracts.LineOfBusiness = &FieldOfActivitySelection";
		QueriesTexts.Add(QueryText);
	EndIf;
	
	If AccessRight("View", Metadata.Catalogs.AcquiringContracts) Then
		QueryText = "SELECT
		|	AcquiringContracts.Ref AS Ref,
		|	&TextOfAcquiringContract AS ContractType,
		|	AcquiringContracts.DeletionMark AS DeletionMark,
		|	AcquiringContracts.Approved AS Approved,
		|	AcquiringContracts.Status AS Status,
		|	AcquiringContracts.Organization AS Organization,
		|	AcquiringContracts.Number AS Number,
		|	AcquiringContracts.Description AS NameForPrinting,
		|	DATETIME(1,1,1) AS ValidityStartDate,
		|	DATETIME(1,1,1) AS ValidityEndDate,
		|	VALUE(Catalog.Currencies.EmptyRef) AS ARAPCurrency
		|FROM
		|	Catalog.AcquiringContracts AS AcquiringContracts
		|WHERE
		|	AcquiringContracts.LineOfBusiness = &FieldOfActivitySelection";
		QueriesTexts.Add(QueryText);
	EndIf;
	
	QueryText = StrConcat(QueriesTexts, TMCommonUse.QuerySeparatorInJoin());
	List.QueryText = StrReplace(List.QueryText, "Catalog.CounterpartyContracts", "(" + QueryText + ")");
	
	CommonClientServer.SetDynamicListParameter(List, "TextOfContractOfCounterparty", NStr("vi = 'Hợp đồng đối tác';
																							|ru = 'Договор контрагента';
																							|en = 'Counterparty contract'; fa = 'قرارداد طرف حساب';
																							|it = 'Contratto della controparte';
																							|pl = 'Umowa kontrahenta';
																							|tr = 'Cari hesap sözleşmesi'"));
	CommonClientServer.SetDynamicListParameter(List, "TextContractOfLoansDeposits", NStr("vi = 'Hợp đồng tín dụng và tiền gửi';
																						|ru = 'Договор кредитов и депозитов';
																						|en = 'Credit and deposit contract'; fa = 'Credit and deposit contract';
																						|it = 'Contratto di prestiti e depositi';
																						|pl = 'Umowa kredytowa i depozytowa';
																						|tr = 'Kredi ve mevduat sözleşmesi'"));
	CommonClientServer.SetDynamicListParameter(List, "TextContractBetweenOrganizations", NStr("vi = 'Hợp đồng giữa các doanh nghiệp';
																								|ru = 'Договор между организациями';
																								|en = 'Intercompany contract'; fa = 'قرارداد بین‌شرکتی';
																								|it = 'Accordo tra le società';
																								|pl = 'Kontrakt między firmami';
																								|tr = 'Şirketler arası sözleşme'"));
	CommonClientServer.SetDynamicListParameter(List, "TextOfAcquiringContract", NStr("vi = 'Hợp đồng kết nối đến hệ thống thanh toán';
																					|ru = 'Договор подключения к платежной системе';
																					|en = 'Payment system contract'; fa = 'قرارداد سیستم پرداخت';
																					|it = 'Contratto di connessione a un sistema di pagamento';
																					|pl = 'Umowa o podłączenie do systemu płatniczego';
																					|tr = 'Ödeme sistemine bağlama sözleşmesi'"));

EndProcedure

#EndRegion