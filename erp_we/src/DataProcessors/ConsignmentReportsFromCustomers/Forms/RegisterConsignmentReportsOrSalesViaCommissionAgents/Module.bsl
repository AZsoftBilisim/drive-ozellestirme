
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	// Refund upon receipt of the form for analysis.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	If ValueIsFilled(Parameters.FormCaption) Then
		Title = Parameters.FormCaption;
	EndIf;
	
	QuickFilterStructure = Common.CopyRecursive(Parameters.QuickFilterStructure);
	
	Items.ListForRegistrationIssueReport.Enabled = AccessRight("Insert",Metadata.Documents.ConsignmentReportFromCustomer);
	Items.ListForRegistrationCounterparty.Visible = GetFunctionalOption("UsePartnersAndCounterparties");
	
	UpdateHyperlinkToLayout();
	
	// Installation of selections.
	SetDynamicListSelection();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ConnectHyperlinkWaitingHandlerToLayout();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_TransferOfGoodsToBailee"
		Or EventName = "Write_RecognitionOfStockSurplusShippedToCustomer"
		Or EventName = "Write_WriteOffOfShippedGoods"
		Or EventName = "Write_CustomerInvoice"
		Or EventName = "Write_ReceiptOfGoodsFromCustodian"
		Or EventName = "Write_ConsignmentReportFromCustomer" Then
		
		Items.ListForRegistration.Refresh();
		
		ConnectHyperlinkWaitingHandlerToLayout();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Property("Consignee", Consignee);
		Settings.Delete("Consignee");
		QuickFilterStructure.Property("Organization", Organization);
		Settings.Delete("Organization");
	Else
		Consignee = Settings.Get("Consignee");
		Organization = Settings.Get("Organization");
	EndIf;
	
	SetDynamicListSelection();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ConsigneeOnChange(Item)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Partner", Consignee);
	EndIf;
	
	SetDynamicListSelection();
	UpdateHyperlinkToLayout();
	UpdateAvailabilityOfCommissionAgentReportCreation();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	If QuickFilterStructure <> Undefined Then
		QuickFilterStructure.Insert("Organization", Organization);
	EndIf;
	
	SetDynamicListSelection();
	UpdateHyperlinkToLayout();
	UpdateAvailabilityOfCommissionAgentReportCreation();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListForRegistration

&AtClient
Procedure ListForRegistrationOnActivateRow(Item)
	
	UpdateAvailabilityOfCommissionAgentReportCreation();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure IssueCommissionAgentSReport(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.ConsignmentReportsFromCustomers.RegisterConsignmentReportsOrSalesViaCommissionAgents");
	
	IssueCommissionAgentReportOnClient();
		
EndProcedure
	
&AtClient
Procedure IssueSaleThroughCommissionAgent(Command)
	
	// &PerformanceMeasurement
	PerformanceMonitorClient.TimeMeasurement("DataProcessor.ConsignmentReportsFromCustomers.ToRegistrationOfImplementationThroughCommissionAgent");
	
	ArrangeSaleOfGoodsAndServicesOnClient();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	// Conditional design of the dynamic list "List of assignments"
	ListOfConditionalAppearance = ListForRegistration.SettingsComposer.Settings.ConditionalAppearance;
	ListOfConditionalAppearance.Items.Clear();
	
EndProcedure

#Region CreatingNewDocuments

&AtClient
Procedure IssueCommissionAgentReportOnClient()
	
	ClearMessages();
	
	SelectedRows = Items.ListForRegistration.SelectedRows;
	FilterList.Clear();
	ErrorNumber = 0;
	
	For Each String In SelectedRows Do
		FoundRow = Items.ListForRegistration.RowData(String);
		If FoundRow.ConductARAPAccountingThroughEndCustomers Then 
			ErrorNumber = 1;
			Break;
		ElsIf FoundRow.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice") Then
			ErrorNumber = 2;
			Break;
		EndIf;
		AddedRow = FilterList.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	If ErrorNumber = 0 Then
		ParametersOfCreatedDocuments = IssueCommissionAgentReportOnServer();
		IssueCommissionAgentReportOnClientCompletion(Undefined, ParametersOfCreatedDocuments);
	ElsIf ErrorNumber = 1 Then
		ErrorText = NStr("vi = 'Đã chọn dòng mà theo đó không cần tạo bảng kê hàng bán của người nhận ký gửi, bởi vì tiến hành hạch toán qua người nhận ký gửi.';
						|ru = 'Выбрана строка, по которой нельзя оформить отчет комиссионера, т.к. ведутся расчеты через комиссионера.';
						|en = 'The selected line cannot be used to register a consignment issue notification, as AR/AP accounting is carried out via consignee.'; fa = 'The selected line cannot be used to register a consignment issue notification, as AR/AP accounting is carried out via consignee.';
						|it = 'The selected line cannot be used to register a consignment issue notification, as AR/AP accounting is carried out via consignee.';
						|pl = 'The selected line cannot be used to register a consignment issue notification, as AR/AP accounting is carried out via consignee.';
						|tr = 'Konsinye acentesi raporu tanzim edilmesi mümkün olmadığı için bir hat seçilmiş, zira ödemeler bir konsinye acentesi aracılığıyla yapılmaktadır.'");
		CommonClient.MessageToUser(ErrorText);
	ElsIf ErrorNumber = 2 Then
		ErrorText = NStr("vi = 'Đã chọn dòng mà theo đó không cần tạo bảng kê hàng bán của người nhận ký gửi, bởi vì đã chọn trình tự hạch toán ""Ứng trước theo hợp đồng, công nợ theo hóa đơn (chỉ bán hàng)"".';
						|ru = 'Выбрана строка, по которой нельзя оформить отчет комиссионера, т.к. выбран порядок расчетов ""Аванс по договорам, долг по накладным (только реализация)"".';
						|en = 'The selected line cannot be used to register a consignment  issue notification, as the ""Invoice for debt, Contract for prepayment (sales only)"" payment terms are selected.'; fa = 'The selected line cannot be used to register a consignment  issue notification, as the ""Invoice for debt, Contract for prepayment (sales only)"" payment terms are selected.';
						|it = 'The selected line cannot be used to register a consignment  issue notification, as the ""Invoice for debt, Contract for prepayment (sales only)"" payment terms are selected.';
						|pl = 'The selected line cannot be used to register a consignment  issue notification, as the ""Invoice for debt, Contract for prepayment (sales only)"" payment terms are selected.';
						|tr = '""Sözleşmelerde avans, faturalarda borç (sadece satışlarda)"" mutabakat isteği seçili olduğu için, konsinye raporunun düzenlenemeyeceği satır seçilmiş.'");
		CommonClient.MessageToUser(ErrorText);
	EndIf;
	
EndProcedure

&AtClient
Procedure ArrangeSaleOfGoodsAndServicesOnClient()
	
	ClearMessages();
	
	SelectedRows = Items.ListForRegistration.SelectedRows;
	FilterList.Clear();
	
	For Each String In SelectedRows Do
		FoundRow = Items.ListForRegistration.RowData(String);
		AddedRow = FilterList.Add();
		FillPropertyValues(AddedRow, FoundRow);
	EndDo;
	
	ParametersOfCreatedDocuments = IssueSaleThroughCommissionAgentOnServer();
	IssueCommissionAgentReportOnClientCompletion(Undefined, ParametersOfCreatedDocuments);
	
EndProcedure

&AtClient
Procedure IssueCommissionAgentReportOnClientCompletion(Result, AddlParameters)
	
	If Result = Undefined Then
		ParametersOfCreatedDocuments = AddlParameters;
	Else
		ParametersOfCreatedDocuments = GetFromTempStorage(Result.ResultAddress);
	EndIf;
	
	CommonClientServer.ReportErrorsToUser(ParametersOfCreatedDocuments.ErrorList);
	
	If ParametersOfCreatedDocuments.Property("TextOfQuestionToUser") Then
		ShowQueryBox(
			New CallbackDescription(ParametersOfCreatedDocuments.UserResponseProcessingProcedure, 
				ThisObject,
				ParametersOfCreatedDocuments),
			ParametersOfCreatedDocuments.TextOfQuestionToUser,
			QuestionDialogMode.YesNo);
	ElsIf ParametersOfCreatedDocuments.Property("FormName") Then
		
		OpenForm(ParametersOfCreatedDocuments.FormName, 
			ParametersOfCreatedDocuments.Parameters,
			ThisForm,,,,,);
	EndIf;
	
	Items.ListForRegistration.Refresh();
	
EndProcedure

&AtServer
Function IssueCommissionAgentReportOnServer()
	
	Var ErrorList;
	
	FormParameters = New Structure();
	FormParameters.Insert("IssueNumberOfCommissionAgentReports", False);
	FormParameters.Insert("TimeConsumingOperation", Undefined);
	FormParameters.Insert("ErrorList", ErrorList);
	
	BreakdownByDocuments = FilterList.Unload();
	
	If BreakdownByDocuments.Count() = 1 Then
		
		FormParameters = IssueReportOfCommissionAgentAccordingToTable(BreakdownByDocuments, ErrorList);
		
	ElsIf BreakdownByDocuments.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Chưa chọn lệnh để lập chứng từ';
						|ru = 'Не выбрано распоряжение для оформления документа';
						|en = 'Reference for the document registration is not selected'; fa = 'Reference for the document registration is not selected';
						|it = 'Ordine non selezionato per la registrazione del documento';
						|pl = 'Nie wybrano zamówienia do utworzenia dokumentu';
						|tr = 'Belgenin düzenlenmesi için emir seçilmedi'");
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		Items.ListForRegistration.Refresh();
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

&AtServer
Function IssueReportOfCommissionAgentAccordingToTable(BreakdownByDocuments, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	FirstRow = BreakdownByDocuments[0];
	
	MetadataOfCommissionAgentSReport = Metadata.Documents.ConsignmentReportFromCustomer;
	NameOfCommissionAgentSReport        = MetadataOfCommissionAgentSReport.Name;
	
	FormSettings = New Structure();
	FormParameters = New Structure();

	TheStructureOfTheSearch = Documents.ConsignmentReportFromCustomer.StructureOfMeaningfulProps();
	
	FillPropertyValues(TheStructureOfTheSearch, FirstRow);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
	AdditionalParameters.Insert("EmptyDocumentLink", Documents.ConsignmentReportFromCustomer.EmptyRef());
	AdditionalParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.TransferToCommissionAgent);
	AdditionalParameters.Insert("ConsignmentSales25", True);
	AdditionalParameters.Insert("Currency", Common.ObjectAttributeValue(TheStructureOfTheSearch.Contract, "ARAPCurrency"));
	
	DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
		TheStructureOfTheSearch.Partner, AdditionalParameters);
	
	If Not DefaultSalesTerms = Undefined
		And DefaultSalesTerms.Property("Terms") Then
		FillPropertyValues(TheStructureOfTheSearch, DefaultSalesTerms, 
			"Terms");
	EndIf;
	
	HeaderAttributes = New Structure();
	TMCommonUseClientServer.SupplementStructure(HeaderAttributes, TheStructureOfTheSearch, True);
	
	FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
	FormParameters.Insert("FillInAccordingToDataForRegistration", True);
	FormParameters.Insert("BusinessOperation", Enums.BusinessTransactions.SalesViaCommissionAgent);
	
	FormSettings.Insert("FormName", "Document." + NameOfCommissionAgentSReport + ".Form.DocumentForm");
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document." + MetadataOfCommissionAgentSReport.Name + ".EmptyRef"));
	
	FormParameters.Insert("CreatedDocuments", CreatedDocuments);
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	Return FormSettings;
	
EndFunction

&AtServer
Function ArrangeSaleOfGoodsAndServicesAccordingToTable(BreakdownByDocuments, ErrorList)
	
	CreatedDocuments = New ValueList();
	
	FirstRow = BreakdownByDocuments[0];
	
	MetadataSalesOfGoodsServices = Metadata.Documents.CustomerInvoice;
	NameSalesOfGoodsServices        = MetadataSalesOfGoodsServices.Name;
	
	FormSettings = New Structure();
	FormParameters = New Structure();

	TheStructureOfTheSearch = SalesServer.StructureOfMeaningfulProps();
	
	FillPropertyValues(TheStructureOfTheSearch, FirstRow);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ExcludeWarehouseGroupsAvailableInOrders", True);
	AdditionalParameters.Insert("EmptyDocumentLink", Documents.CustomerInvoice.EmptyRef());
	AdditionalParameters.Insert("BusinessTransactions", Enums.BusinessTransactions.TransferToCommissionAgent);
	AdditionalParameters.Insert("ConsignmentSales25", True);
	AdditionalParameters.Insert("Currency", Common.ObjectAttributeValue(TheStructureOfTheSearch.Contract, "ARAPCurrency"));
	
	DefaultSalesTerms = SalesServer.GetDefaultSalesTerms(
		TheStructureOfTheSearch.Partner, AdditionalParameters);
	
	If Not DefaultSalesTerms = Undefined
		And DefaultSalesTerms.Property("Terms") Then
		FillPropertyValues(TheStructureOfTheSearch, DefaultSalesTerms, 
			"Terms");
	EndIf;
	
	HeaderAttributes = New Structure();
	TMCommonUseClientServer.SupplementStructure(HeaderAttributes, TheStructureOfTheSearch, True);
	
	FormParameters.Insert("HeaderAttributes",    HeaderAttributes);
	FormParameters.Insert("FillInAccordingToDataForRegistration", True);
	FormParameters.Insert("BusinessOperation", Enums.BusinessTransactions.SalesViaCommissionAgent);
	
	FormSettings.Insert("FormName", "Document." + NameSalesOfGoodsServices + ".Form.DocumentForm");
	
	// To display a message about the number of documents created
	CreatedDocuments.Add(PredefinedValue("Document." + MetadataSalesOfGoodsServices.Name + ".EmptyRef"));
	
	FormParameters.Insert("CreatedDocuments", CreatedDocuments);
	ParametersWithBase = New Structure("Basis", FormParameters);
	
	FormSettings.Insert("Parameters", ParametersWithBase);
	
	Return FormSettings;
	
EndFunction

&AtServer
Function IssueSaleThroughCommissionAgentOnServer()
	
	Var ErrorList;
	
	FormParameters = New Structure();
	FormParameters.Insert("IssueNumberOfCommissionAgentReports", False);
	FormParameters.Insert("TimeConsumingOperation", Undefined);
	FormParameters.Insert("ErrorList", ErrorList);
	
	BreakdownByDocuments = FilterList.Unload();
	
	If BreakdownByDocuments.Count() = 1 Then
		
		FormParameters = ArrangeSaleOfGoodsAndServicesAccordingToTable(BreakdownByDocuments, ErrorList);
		
	ElsIf BreakdownByDocuments.Count() = 0 Then
		
		ErrorText = NStr("vi = 'Chưa chọn lệnh để lập chứng từ';
						|ru = 'Не выбрано распоряжение для оформления документа';
						|en = 'Reference for the document registration is not selected'; fa = 'Reference for the document registration is not selected';
						|it = 'Ordine non selezionato per la registrazione del documento';
						|pl = 'Nie wybrano zamówienia do utworzenia dokumentu';
						|tr = 'Belgenin düzenlenmesi için emir seçilmedi'");
		CommonClientServer.AddUserError(ErrorList, "Object.ListReferencesForRegistration",ErrorText, Undefined);
		
	EndIf;
	
	If Not ValueIsFilled(FormParameters) Then
		FormParameters = New Structure();
	Else 
		Items.ListForRegistration.Refresh();
	EndIf;
	
	FormParameters.Insert("ErrorList", ErrorList);
	
	Return FormParameters;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure SetDynamicListSelection()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListForRegistration,
		"Partner",
		Consignee,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Consignee));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListForRegistration,
		"Organization",
		Organization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(Organization));

EndProcedure

#Region HyperlinkToDesign

&AtClient
Procedure ConnectHyperlinkWaitingHandlerToLayout()
		
	If ResultOfFormationOfHyperlinksToDesign <> Undefined Then
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		CallbackOnCompletion = New CallbackDescription("UpdateHyperlinkToNotificationDesign", ThisObject);
	
		TimeConsumingOperationsClient.WaitCompletion(
			ResultOfFormationOfHyperlinksToDesign, CallbackOnCompletion, IdleParameters);
	EndIf;

EndProcedure

&AtClient
Procedure UpdateHyperlinkToNotificationDesign(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If Result.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(
			Result.ResultAddress,
			Items.SeeAlsoInProgress.Visible,
			SeeAlsoInProgress);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateHyperlinkToLayout()
	
	GenerationParameters = New Structure;
	GenerationParameters.Insert("Organization", Organization);
	GenerationParameters.Insert("Counterparty", Consignee);

	JobParameters = New Array;
	JobParameters.Add(GenerationParameters);

	CalculationProcedure_ = "DataProcessors.ConsignmentReportsFromCustomers.CreateHyperlinkToBackgroundTaskLayout";

	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	CalculationResult2 = TimeConsumingOperations.ExecuteInBackground(CalculationProcedure_,
	                                                     JobParameters,
	                                                     ExecutionParameters);
	

	If CalculationResult2.Status = "Completed2" Then
		UpdateHyperlinkToLayoutCompletion(
			CalculationResult2.ResultAddress,
			Items.SeeAlsoInProgress.Visible,
			SeeAlsoInProgress);
		ResultOfFormationOfHyperlinksToDesign = Undefined;
	Else
		ResultOfFormationOfHyperlinksToDesign = CalculationResult2;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
//
// Parameters:
// 	Storage address - String - address of the data in the temporary storage
// 	Smtakzhevodevision - Boolean - visibility of the Attribute SmTakzhEVision
// 	smtakzhevrabotesvalue - String - value of the Attribute SmTakzhEVrabot
// 		
Procedure UpdateHyperlinkToLayoutCompletion(
	Val StorageAddress,
	SeeAlsoInVisibility, 
	SeeAlsoInWorkValue)

	Result = GetFromTempStorage(StorageAddress);

	If Not ValueIsFilled(Result.SeeAlsoInProgress) Then
		SeeAlsoInVisibility = False;
	Else
		SeeAlsoInVisibility = True;
		SeeAlsoInWorkValue = Result.SeeAlsoInProgress;
	EndIf;

EndProcedure

&AtClient
Procedure SeeAlsoInProgressURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	// &PerformanceMeasurement
	KeyOperationName = StrTemplate("DataProcessor.ConsignmentReportsFromCustomers.Form.RegisterConsignmentReportsOrSalesViaCommissionAgents.SeeAlso.%1",
									FormattedStringURL);
	PerformanceMonitorClient.StartTimeMeasurement(True, KeyOperationName);
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	QuickFilterStructure = New Structure;
	QuickFilterStructure.Insert("Organization",Organization);
	QuickFilterStructure.Insert("Counterparty", Consignee);
	QuickFilterStructure.Insert("BusinessOperation", PredefinedValue("Enum.BusinessTransactions.SalesViaCommissionAgent"));
	FormParameters.Insert("QuickFilterStructure", QuickFilterStructure);
	
	OpenForm(FormattedStringURL, FormParameters, ThisForm, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure UpdateAvailabilityOfCommissionAgentReportCreation()
	
	CurrentListLine = Items.ListForRegistration.CurrentData;
	
	If Not CurrentListLine = Undefined Then
		Items.ListForRegistrationIssueReport.Enabled = Not (CurrentListLine.ConductARAPAccountingThroughEndCustomers
			Or CurrentListLine.ARAPObjectSettings = PredefinedValue("Enum.ARAPObjectSettings.ContractForPrepaymentInvoiceForInvoice"));
	EndIf;

EndProcedure

#EndRegion

#EndRegion

#EndRegion
