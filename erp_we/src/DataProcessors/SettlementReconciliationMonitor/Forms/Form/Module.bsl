
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	SetConditionalAppearance();
	
	//Initialize The Form
	If Not GetFunctionalOption("UseMultipleCompanies") Then
		Object.Organization = Catalogs.Companies.GetDefaultOrganization();
	EndIf;
	FillInListOfOrganizations();
	UsePartnersAsCounterparties = GetFunctionalOption("UsePartnersAsCounterparties");
	FillInCalculationTypes();
	FillInReconciliationStatus();
	AutoUpdatingListONChangingSettings = True;
	StartFromConfiguration = TypeOf(FormAttributeToValue("Object")) = Type("DataProcessorObject.SettlementReconciliationMonitor");
	
	DecryptionReports.Add(Metadata.Reports.CustomersARAPStatement.Name, Metadata.Reports.CustomersARAPStatement.Synonym);//0
	DecryptionReports.Add(Metadata.Reports.VendorsARAPStatement.Name, Metadata.Reports.VendorsARAPStatement.Synonym);//1
	DecryptionReports.Add(Metadata.Reports.FinancialInstrumentsARAPStatement.Name, Metadata.Reports.FinancialInstrumentsARAPStatement.Synonym);//2
	DecryptionReports.Add(Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany.Name, Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany.Synonym);//3
	DecryptionReports.Add(Metadata.Reports.PartnersARAPAccountingStatement.Name, Metadata.Reports.PartnersARAPAccountingStatement.Synonym);//4
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject, Items.GlobalCommandsGroup);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	Items.ListOfCounterparties_.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	SetVisibilityOfQuickSelections(Items.QuickFilters, Items.GroupFilters, ShowQuickSelections);
	SetDateOfBalances(Items.ReconciliationWithCounterpartiesGroupBalances, Settings["Object.EndOfPeriod"]);
	SetVisibilityOfServices();
	If Not GetFunctionalOption("UseMultipleCompanies")
		And Not ValueIsFilled(Object.Organization) Then
		Object.Organization = Catalogs.Companies.GetDefaultOrganization();
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If AutoUpdatingListONChangingSettings 
			And ValueIsFilled(Object.BeginOfPeriod) And ValueIsFilled(Object.EndOfPeriod)
			And ValueIsFilled(Object.Organization) Then
		AttachIdleHandler("FillInAccordingToCalculationsWithExpectation", 0.2, True);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	OnChangeSettings();
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	SetDateOfBalances(Items.ReconciliationWithCounterpartiesGroupBalances, Object.EndOfPeriod);
	OnChangeSettings();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	SetVisibilityOfServices();
	OnChangeSettings();
	
EndProcedure

&AtClient
Procedure ManagerOnChange(Item)
	OnChangeSettings();
EndProcedure

&AtClient
Procedure ThisIsOurCompanyOnChange(Item)
	
	If ThisIsOurCompany Then
		Items.ListOfCounterparties_.TypeRestriction = New TypeDescription("CatalogRef.Companies");
	Else
		Items.ListOfCounterparties_.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	EndIf;
	Items.ReconciliationWithCounterpartiesManager.Visible = Not ThisIsOurCompany;
	ListOfCounterparties_.Clear();
	OnChangeSettings();
	
EndProcedure

&AtClient
Procedure ListOfCounterparties_OnChange(Item)
	OnChangeSettings();
EndProcedure

&AtClient
Procedure IncludeContractsWithoutTurnoverOnChange(Item)
	OnChangeSettings();
EndProcedure

&AtClient
Procedure ThereAreDiscrepanciesOnChange(Item)
	OnChangeSettings();
EndProcedure

&AtClient
Procedure SortOnChange(Item)
	OnChangeSettings();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTypesOfCalculations_

&AtClient
Procedure TypesOfCalculations_OnActivateRow(Item)
	Items.TypesOfCalculations_.SelectedRows.Clear();
EndProcedure

&AtClient
Procedure TypesOfCalculations_UseOnChange(Item)
	OnChangeSettings();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReconciliationStatuses

&AtClient
Procedure ReconciliationStatusesOnActivateRow(Item)
	Items.ReconciliationStatuses.SelectedRows.Clear();
EndProcedure

&AtClient
Procedure ReconciliationStatusesUseOnChange(Item)
	OnChangeSettings();
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReconciliationWithCounterparties

&AtClient
Procedure ReconciliationWithCounterpartiesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If StartFromConfiguration Then
		FormObject = "DataProcessor.";
	Else
		FormObject = "ExternalDataProcessor.";
	EndIf;
	
	CurrentRow = Item.CurrentData;
	
	FormParameters = New Structure("Filter", New Structure);
	FormParameters.Insert("UUID", UUID);
	FormParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FormParameters.Insert("EndOfPeriod", Object.EndOfPeriod);
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Counterparty", CurrentRow.Counterparty);
	FormParameters.Insert("Manager", CurrentRow.Manager);
	FormParameters.Insert("Currency", CurrentRow.Currency);
	FormParameters.Insert("IncludeContractsWithoutTurnover", IncludeContractsWithoutTurnover);
	TypesOfCalculations_ = New Array;
	For Each Filter In FilterTypesOfCalculations_ Do
		If Filter.Use Then
			TypesOfCalculations_.Add(Filter.PaymentType_);
		EndIf;
	EndDo;
	FormParameters.Insert("TypesOfCalculations_", TypesOfCalculations_);
	
	If Field.Name = "ReconciliationWithCounterpartiesCounterparty" Then
		OpenValueAsync(CurrentRow.Counterparty);
		
	ElsIf Field.Name = "ReconciliationWithCounterpartiesCounterpartySDebt"
			Or Field.Name = "ReconciliationWithCounterpartiesAccountsPayableOfCompany" Then
		OpenCalculationSheet(Item, CurrentRow);
	
	ElsIf (Field.Name = "ReconciliationWithCounterpartiesStatusOfReconciliationPresentation"
			Or Field.Name = "ReconciliationWithCounterpartiesReconciliation20") Then
		OpenForm(FormObject + "SettlementReconciliationMonitor.Form.ReconciliationState",FormParameters,,True);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ReconciliationWithCounterpartiesCommentTextOnChange(Item)
	
	CurrentRow = Items.ReconciliationWithCounterparties.CurrentData;
	Filter = New Structure("Counterparty", CurrentRow.Counterparty);
	FoundRows = ReconciliationWithCounterparties.FindRows(Filter);
	If FoundRows.Count() > 1 Then
		For Each String In FoundRows Do
			String.Comment = CurrentRow.Comment;
		EndDo;
	EndIf;
	WriteCommentOnCrossSection(CurrentRow.Counterparty, CurrentRow.Comment);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetPeriodInterval(Command)
	
	CallbackOnCompletion = New CallbackDescription("SetDateIntervalCompletion", ThisObject);
	PeriodParameters_ = New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod");
	TMCommonUseClient.EditPeriod(Object, PeriodParameters_, CallbackOnCompletion);
	
EndProcedure

&AtClient
Procedure UpdateReconciliationData(Command)
	
	ClearMessages();
	Cancel = False;
	If Not ValueIsFilled(Object.BeginOfPeriod) Then
		TextMessage = NStr("vi = 'Chưa chỉ định ""Bắt đầu kỳ""';
							|ru = 'Не указано ""Начало периода""';
							|en = 'The ""Period start"" is not specified'; fa = 'The ""Period start"" is not specified';
							|it = 'The ""Period start"" is not specified';
							|pl = 'The ""Period start"" is not specified';
							|tr = '""Dönem başlangıcı"" belirtilmemiş'");
		CommonClient.MessageToUser(TextMessage,,"BeginOfPeriod","Object.BeginOfPeriod",Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.EndOfPeriod) Then
		TextMessage = NStr("vi = 'Chưa chỉ định ""Kết thúc kỳ""';
							|ru = 'Не указан ""Конец периода""';
							|en = 'The ""Period end"" is not specified'; fa = 'The ""Period end"" is not specified';
							|it = 'The ""Period end"" is not specified';
							|pl = 'The ""Period end"" is not specified';
							|tr = '""Dönem sonu"" belirtilmemiş'");
		CommonClient.MessageToUser(TextMessage,,"EndOfPeriod","Object.EndOfPeriod",Cancel);
	EndIf;
	
	If Not ValueIsFilled(Object.Organization) Then
		TextMessage = NStr("vi = 'Chưa chỉ định ""Tổ chức""';
							|ru = 'Не указана ""Организация""';
							|en = 'The ""Company"" is not specified'; fa = 'The ""Company"" is not specified';
							|it = 'The ""Company"" is not specified';
							|pl = 'The ""Company"" is not specified';
							|tr = '""İş yeri"" belirtilmemiş'");
		CommonClient.MessageToUser(TextMessage,,"Organization","Object.Organization",Cancel);
	EndIf;
	
	If Not Cancel Then
		FillInAccordingToCalculations();
	EndIf;
	
EndProcedure

&AtClient
Procedure ShowQuickFilters(Command)
	
	ShowQuickSelections = Not Items.GroupFilters.Visible;
	SetVisibilityOfQuickSelections(Items.QuickFilters, Items.GroupFilters, ShowQuickSelections);
	
EndProcedure

&AtClient
Procedure CreateReconciliationDocument(Command)
	
	CreateReconciliationDocumentForSettlements();
	
EndProcedure

&AtClient
Procedure ReconciliationCreationAssistant(Command)
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CurrentRow = Items.ReconciliationWithCounterparties.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", Object.Organization);
	FormParameters.Insert("Counterparty", ListOfCounterparties_);
	FormParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FormParameters.Insert("EndOfPeriod", Object.EndOfPeriod);
	FormParameters.Insert("ContractsWithoutTurnover", IncludeContractsWithoutTurnover);
	FormParameters.Insert("MainManager", Manager);
	FormParameters.Insert("ReplaceFormSettings", True);
	SelectedTypesOfCalculations = New ValueList;
	For Each Filter In FilterTypesOfCalculations_ Do
		If Filter.Use Then
			SelectedTypesOfCalculations.Add(Filter.PaymentType_);
		EndIf;
	EndDo;
	FormParameters.Insert("TypesOfCalculations_", SelectedTypesOfCalculations);
	
	OpenForm("Document.ARAPReconciliation2_5_11.Form.FormOfReconciliationWizard", FormParameters);
	
EndProcedure

#Region SettingStatus

&AtClient
Procedure SetStatusCreated(Command)
	SetReconciliationStatus("CreatedOn_");
EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliation(Command)
	SetReconciliationStatus("OnReconciliation");
EndProcedure

&AtClient
Procedure SetStatusCheckedWithDisagreements(Command)
	SetReconciliationStatus("ReconciledWithDisputes");
EndProcedure

&AtClient
Procedure SetStatusVerifiedWithoutDisagreement(Command)
	SetReconciliationStatus("ReconciledWithoutDisputes");
EndProcedure

&AtClient
Procedure ToSetTheStatusToRejected(Command)
	SetReconciliationStatus("IsRejected");
EndProcedure

#EndRegion

&AtClient
Procedure ReconciliationComment(Command)
	
	If StartFromConfiguration Then
		FormObject = "DataProcessor.";
	Else
		FormObject = "ExternalDataProcessor.";
	EndIf;
	
	CurrentRow = Items.ReconciliationWithCounterparties.CurrentData;
	If CurrentRow = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn đối tác';
										|ru = 'Не выбран контрагент';
										|en = 'Select the counterparty'; fa = 'Select the counterparty';
										|it = 'Select the counterparty';
										|pl = 'Select the counterparty';
										|tr = 'Cari hesap seçilmemiş'"));
		Return;
	EndIf;
	
	ParametersOfForm = New Structure("Comment", CurrentRow.Comment);
	AdditionalParameters = New Structure("Counterparty", CurrentRow.Counterparty);
	CloseHandler = New CallbackDescription("ClosingCommentFormEnd",ThisObject,AdditionalParameters);
	OpenForm(FormObject + "SettlementReconciliationMonitor.Form.ReconciliationComment",ParametersOfForm,,,,,CloseHandler,FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ClosingCommentFormEnd(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	Filter = New Structure("Counterparty", AdditionalParameters.Counterparty);
	FoundRows = ReconciliationWithCounterparties.FindRows(Filter);
	For Each String In FoundRows Do
		String.Comment = Result;
	EndDo;
	WriteCommentOnCrossSection(AdditionalParameters.Counterparty, Result);
	
EndProcedure

&AtClient
Procedure ReconciliationRequest(Command)
	
	CurrentRowID = Items.ReconciliationWithCounterparties.CurrentRow;
	If CurrentRowID = Undefined Then
		Return;
	EndIf;
	
	EmailSendOptions = EmailOperationsClient.EmailSendOptions();
	
	FillInParametersForSendingEmailATServer(EmailSendOptions, CurrentRowID);
	
	EmailOperationsClient.CreateNewEmailMessage(EmailSendOptions);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//AccountsPayableOfCompany
	
	// If the final debt is 0
	//  and there is turnover or there is an expanded balance, 
	//then we will print zero to open the decryption report
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesAccountsPayableOfCompany");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.CounterpartySDebt", DataCompositionComparisonType.Equal, 0);
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.AccountsPayableOfCompany", DataCompositionComparisonType.Equal, 0);
	SelectionGroupOr = CommonClientServer.CreateFilterItemGroup(Item.Filter,"ThereAreBalancesOrTurnover",DataCompositionFilterItemsGroupType.OrGroup);
		CommonClientServer.AddCompositionItem(SelectionGroupOr,
			"ReconciliationWithCounterparties.ThereIsExpandedBalance", DataCompositionComparisonType.Equal, True);
		CommonClientServer.AddCompositionItem(SelectionGroupOr,
			"ReconciliationWithCounterparties.ThereAreRevolutions", DataCompositionComparisonType.Equal, True);
	Item.Appearance.SetParameterValue("Text", "0");
	
	// If the balance is zero and there were no revolutions, then we will simply display a hint that there were no operations.
	// In this case, we will hide the hyperlink Our debt, and instead we will display a column with the text of the explanation.
	
	//hide the Balance column
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesAccountsPayableOfCompany");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ThereIsExpandedBalance", DataCompositionComparisonType.Equal, False);
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ThereAreRevolutions", DataCompositionComparisonType.Equal, False);
	Item.Appearance.SetParameterValue("Visible", False);
	
	//print the hint text
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesOurDebtNoTransactions");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ThereAreRevolutions", DataCompositionComparisonType.Equal, False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Không có giao dịch';
													|ru = 'Нет операций';
													|en = 'There are no operations'; fa = 'There are no operations';
													|it = 'There are no operations';
													|pl = 'There are no operations';
													|tr = 'İşlem yok'"));
	Item.Appearance.SetParameterValue("TextColor", StyleColors.UnavailableTextColor);
	
	//we will display the hint column without a hyperlink if there are no Balances and revolutions
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesOurDebtNoTransactions");
	SelectionGroupOr = CommonClientServer.CreateFilterItemGroup(Item.Filter,"ThereAreCalculations",DataCompositionFilterItemsGroupType.OrGroup);
	CommonClientServer.AddCompositionItem(SelectionGroupOr,
		"ReconciliationWithCounterparties.ThereIsExpandedBalance", DataCompositionComparisonType.Equal, True);
	CommonClientServer.AddCompositionItem(SelectionGroupOr,
		"ReconciliationWithCounterparties.ThereAreRevolutions", DataCompositionComparisonType.Equal, True);
	Item.Appearance.SetParameterValue("Visible", False);
	//End AccountsPayableOfCompany
	
	
	//Comment
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesCommentPicture_2");
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesCommentText");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.Comment", DataCompositionComparisonType.NotFilled);
	Item.Appearance.SetParameterValue("Visible", False);
	
	
	//ThereAreDiscrepancies
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesStatusOfReconciliationPresentation");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ThereAreDiscrepancies", DataCompositionComparisonType.Equal, True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValueTextColor);
	
	
	//Incomplete Interchange - Hyperlink
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesDocumentsOnEDIHaveNotBeenReceived");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.EDIExchangeHasNotBeenCompleted", DataCompositionComparisonType.Greater, 0);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Font", New Font(,,,,True));
	
	
	//SverkaSKontragentamiSverka20 - Hyperlink
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesReconciliation20");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ReconciliationServiceThereAreDiscrepancies", DataCompositionComparisonType.Equal, True);
	Item.Appearance.SetParameterValue("Visible", True);
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesReconciliation20");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ReconciliationServiceThereAreDiscrepancies", DataCompositionComparisonType.Equal, False);
	Item.Appearance.SetParameterValue("Visible", False);
	
	
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesReconciliationWithoutHyperlink");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ReconciliationServiceThereAreDiscrepancies", DataCompositionComparisonType.Equal, True);
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, "ReconciliationWithCounterpartiesReconciliationWithoutHyperlink");
	CommonClientServer.AddCompositionItem(Item.Filter,
		"ReconciliationWithCounterparties.ReconciliationServiceThereAreDiscrepancies", DataCompositionComparisonType.Equal, False);
	Item.Appearance.SetParameterValue("Visible", True);
	
EndProcedure

// Parameters:
//  Result - StandardPeriod, Undefined -
//  AdditionalParameters - Undefined
//
&AtClient
Async Procedure SetDateIntervalCompletion(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		SetDateOfBalances(Items.ReconciliationWithCounterpartiesGroupBalances, Object.EndOfPeriod);
		OnChangeSettings();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetDateOfBalances(ColumnGroup, DateOfRemainingGoods)
	ColumnGroup.Title = NStr("vi = 'Tồn kho tại';
							|ru = 'Остаток на';
							|en = 'Balance on'; fa = 'مانده در';
							|it = 'Balance on';
							|pl = 'Balance on';
							|tr = 'Bakiye tarihi'") + ": " + Format(DateOfRemainingGoods, "DLF=D");
EndProcedure

&AtClientAtServerNoContext
Procedure SetVisibilityOfQuickSelections(Button, GroupFilters, NewVisibility)
	
	GroupFilters.Visible = NewVisibility;
	Button.Check = NewVisibility;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfServices()
	
	VisibilityOfEDO = False;
	CompanyIsConnectedToReconciliation20 = False;
	Items.ReconciliationWithCounterpartiesEDIReconciliation.Visible = VisibilityOfEDO;
	Items.ReconciliationWithCounterpartiesDocumentsOnEDIHaveNotBeenReceived.Visible = VisibilityOfEDO;
	Items.ReconciliationWithCounterpartiesReconciliationGroup20.Visible = CompanyIsConnectedToReconciliation20;
	
EndProcedure

&AtServer
Procedure FillInCalculationTypes()
	
	FilterTypesOfCalculations_.Clear();
	ProhibitedPaymentTypes = Documents.ARAPReconciliation2_5_11.ProhibitedPaymentTypes();
	
	AddCalculationType(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	AddCalculationType(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	
	If ProhibitedPaymentTypes.Find(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting) = Undefined Then
		AddCalculationType(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
	EndIf;
	If ProhibitedPaymentTypes.Find(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting) = Undefined Then
		AddCalculationType(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	EndIf;
	If ProhibitedPaymentTypes.Find(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor) = Undefined Then
		AddCalculationType(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	EndIf;
EndProcedure

&AtServer
Procedure AddCalculationType(PaymentType_, Check = True);
	
	NewRow = FilterTypesOfCalculations_.Add();
	NewRow.Use = Check;
	NewRow.PaymentType_ = PaymentType_;
	
EndProcedure

&AtServer
Procedure FillInListOfOrganizations()
	
	Query = New Query;
	Query.Text =
	"SELECT ALLOWED
	|	CatalogData.Ref AS Organization,
	|	CatalogData.Description AS Description
	|FROM
	|	Catalog.Companies AS CatalogData
	|WHERE
	|	NOT CatalogData.DeletionMark
	|	AND CatalogData.Status = VALUE(Enum.BusinessUnitCompanyStatuses.Valid)
	|	AND CatalogData.Ref <> VALUE(Catalog.Companies.ManagementCompany)
	|
	|ORDER BY
	|	Description";
	
	AvailableCompanies = Query.Execute().Unload().UnloadColumn("Organization");
	
	Items.Organization.ChoiceList.LoadValues(AvailableCompanies);
	
EndProcedure

&AtServer
Procedure FillInReconciliationStatus()
	
	DescriptionOfReconciliationStatus = DataProcessors.SettlementReconciliationMonitor.ReconciliationStatuses();
	StatusThereAreDiscrepancies = DataProcessors.SettlementReconciliationMonitor.StatusThereAreDiscrepancies();
	
	FilterReconciliationStatuses.Clear();
	For Each ReconciliationStatus In DescriptionOfReconciliationStatus Do
		
		NewRow = FilterReconciliationStatuses.Add();
		NewRow.Use = True;
		NewRow.Name = ReconciliationStatus.Name;
		NewRow.Presentation = ReconciliationStatus.Presentation;
		NewRow.Picture = ReconciliationStatus.Picture;
		
	EndDo;
	
	Items.ThereAreDiscrepancies.Title = StatusThereAreDiscrepancies.Presentation;
	
EndProcedure

&AtServer
Procedure FillInNumberOfStatuses(ResultsByStatus)
	
	DescriptionOfStatuses = DataProcessors.SettlementReconciliationMonitor.ReconciliationStatuses(True);
	For Each Filter In FilterReconciliationStatuses Do
		Status = DescriptionOfStatuses[Filter.Name];
		Count = ResultsByStatus[Filter.Name];
		If ValueIsFilled(Count) Then
			Filter.Presentation = StrTemplate("%1 (%2)", Status.Presentation, Count);
		Else
			Filter.Presentation = Status.Presentation;
		EndIf;
	EndDo;
	
	StatusThereAreDiscrepancies = DataProcessors.SettlementReconciliationMonitor.StatusThereAreDiscrepancies();
	Count = ResultsByStatus[StatusThereAreDiscrepancies.Name];
	If ValueIsFilled(Count) Then
		Items.ThereAreDiscrepancies.Title = StrTemplate("%1 (%2)", StatusThereAreDiscrepancies.Presentation, Count);
	Else
		Items.ThereAreDiscrepancies.Title = StatusThereAreDiscrepancies.Presentation;
	EndIf;
	
EndProcedure

&AtServer
Procedure WriteCommentOnCrossSection(Counterparty, Comment)
	
	Set = InformationRegisters.CommentsOnReconciliationOfSettlements.CreateRecordSet();
	Set.Filter.Organization.Set(Object.Organization);
	Set.Filter.Counterparty.Set(Counterparty);
	If ValueIsFilled(Comment) Then
		Record = Set.Add();
		Record.Organization = Object.Organization;
		Record.Counterparty = Counterparty;
		Record.Comment = Comment;
	EndIf;
	Set.Write();
	
EndProcedure

&AtServer
Procedure FillInParametersForSendingEmailATServer(EmailSendOptions, CurrentRowID)
	
	CurrentData = ReconciliationWithCounterparties.FindByID(CurrentRowID);
	
	Recipients = Emails(CurrentData.Counterparty);
	
	If Recipients.Count() = 0 Then
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Địa chỉ email chưa được chỉ định cho đối tác %1';
				|ru = 'Для контрагента %1 не указан адрес электронной почты';
				|en = 'No email address is specified for the %1 counterparty'; fa = 'No email address is specified for the %1 counterparty';
				|it = 'No email address is specified for the %1 counterparty';
				|pl = 'No email address is specified for the %1 counterparty';
				|tr = '%1 cari hesabı için e-posta adresi belirtilmemiş'"),
			String(CurrentData.Counterparty));
		Common.MessageToUser(MessageText);
		Return;
	EndIf;
	
	EmailSendOptions.Recipient = Recipients;
	
	CompanyInformation = PrintFormGeneration.InformationAboutLegalEntity(Object.Organization, CurrentSessionDate());
	RepresentationOfTheOrganization = PrintFormGeneration.OrganizationDescription(CompanyInformation, 
								"FullDescr");
	CounterpartyInformation_  = PrintFormGeneration.InformationAboutLegalEntity(CurrentData.Counterparty, CurrentSessionDate());
	PresentationOfCounterparty = PrintFormGeneration.OrganizationDescription(CounterpartyInformation_, 
							  "FullDescr");
	
	EmailSendOptions.Subject = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'So sánh thanh toán giữa %1 và %2';
			|ru = 'Сверка расчетов между %1 и %2';
			|en = 'AR/AP reconciliation between %1 and %2 '; fa = 'AR/AP reconciliation between %1 and %2 ';
			|it = 'AR/AP reconciliation between %1 and %2 ';
			|pl = 'AR/AP reconciliation between %1 and %2 ';
			|tr = '%1 ile %2 arasında hesap mutabakatı'"),
		RepresentationOfTheOrganization,
		PresentationOfCounterparty);
		
	MessageText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Xin chào.
		|Chúng tôi đề xuất thực hiện đối chiếu thanh toán giữa %1 và %2 từ %3 đến %4.
		|Vui lòng gửi biên bản đối chiếu thanh toán dựa trên dữ liệu kế toán của bạn.';
		|ru = 'Добрый день.
		|Предлагаем провести сверку расчетов между %1 и %2 с %3 по %4.
		|Просьба прислать акт сверки расчетов исходя из ваших учетных данных.';
		|en = 'Hello.
		|We propose to reconcile AR/AP between %1 and %2 from %3 to %4.
		|Please send a reconciliation statement based on your credentials.'; fa = 'Hello.
		|We propose to reconcile AR/AP between %1 and %2 from %3 to %4.
		|Please send a reconciliation statement based on your credentials.';
		|it = 'Hello.
		|We propose to reconcile AR/AP between %1 and %2 from %3 to %4.
		|Please send a reconciliation statement based on your credentials.';
		|pl = 'Hello.
		|We propose to reconcile AR/AP between %1 and %2 from %3 to %4.
		|Please send a reconciliation statement based on your credentials.';
		|tr = 'İyi günler.
		|%3 ve %4 tarıhleri arasındaki %1 ile %2 arasında  hesap mutabakatı yapmayı teklif ediyoruz. 
		|Kendi muhasebe verilerinize göre hesap mutabakatı tutanağını göndermenizi rica ederiz.'"),
		RepresentationOfTheOrganization, PresentationOfCounterparty,
		Format(Object.BeginOfPeriod, "DLF=D"), Format(Object.EndOfPeriod, "DLF=D"));
	
	EmailSendOptions.Text = MessageText;
	
EndProcedure

&AtServer
Function Emails(Counterparty)
	
	Recipients = New Array;
	
	TypesOfCI = New Array;
	TypesOfCI.Add(Enums.ContactInformationTypes.Email);
	
	Objects = New Array();
	Objects.Add(Counterparty);
	RecipientAddresses = ContactsManager.ObjectsContactInformation(Objects, TypesOfCI, , CurrentSessionDate());
	
	CounterpartyName_ = Common.ObjectAttributeValue(Counterparty, "Description");
	
	For Each RecipientAddress In RecipientAddresses Do

		RecipientParameters = NewRecipientParameters();
		RecipientParameters.ContactInformationSource = Counterparty;
		RecipientParameters.Address = RecipientAddress.Presentation;
		RecipientParameters.Presentation = CounterpartyName_;
		Recipients.Add(RecipientParameters);

	EndDo;
		
	Return Recipients;
	
EndFunction

&AtServer
Function NewRecipientParameters()
	
	Result = New Structure;
	Result.Insert("Selected"                      , False);
	Result.Insert("ContactInformationSource", Catalogs.Counterparties.EmptyRef());
	Result.Insert("Address"                       , "");
	Result.Insert("Presentation"               , "");
	
	Return Result;
	
EndFunction

&AtClient
Procedure OnChangeSettings()
	
	If AutoUpdatingListONChangingSettings Then
		DetachIdleHandler("FillInAccordingToCalculationsWithExpectation");
		AttachIdleHandler("FillInAccordingToCalculationsWithExpectation", 1, True);
	EndIf;
	
EndProcedure

&AtClient
Async Procedure OpenCalculationSheet(Item, CurrentRow)
	
	ReportsNames = New Map;
	ReportsNames.Insert("1", DecryptionReports[0]);//CustomersARAPStatement
	ReportsNames.Insert("2", DecryptionReports[1]);//VendorsARAPStatement
	ReportsNames.Insert("3", DecryptionReports[2]);//FinancialInstrumentsARAPStatement
	ReportsNames.Insert("4", DecryptionReports[2]);//FinancialInstrumentsARAPStatement
	ReportsNames.Insert("5", DecryptionReports[2]);//FinancialInstrumentsARAPStatement
	ReportsNames.Insert("6", DecryptionReports[4]);//PartnersARAPAccountingStatement
	
	CodeTypeOfCalculations = StrReplace(CurrentRow.CodeTypeOfCalculations,"21","6");
	SelectingReports = New ValueList;
	For IndexOf = 1 To StrLen(CodeTypeOfCalculations) Do
		Number = Mid(CodeTypeOfCalculations, IndexOf, 1);
		Report = ReportsNames[Number];
		If Report <> Undefined Then
			SelectingReports.Insert(0, Report.Value, Report.Presentation);
		EndIf;
	EndDo;
	
	Period = New StandardPeriod;
	Period.Variant = StandardPeriodVariant.Custom;
	Period.StartDate = Object.BeginOfPeriod;
	Period.EndDate = Object.EndOfPeriod;
	
	FormParameters = New Structure();
	FormParameters.Insert("Filter", New Structure);
	FormParameters.Filter.Insert("Period", Period);
	FormParameters.Filter.Insert("Organization", Object.Organization);
	ThisIsOurCompany = TypeOf(CurrentRow.Counterparty) = Type("CatalogRef.Companies");
	If Not ThisIsOurCompany Then
		FormParameters.Filter.Insert("Partner", CounterpartySPartner(CurrentRow.Counterparty));
	EndIf;
	If Not UsePartnersAsCounterparties Then
		FormParameters.Filter.Insert("Counterparty", CurrentRow.Counterparty);
	EndIf;
	FormParameters.Insert("GenerateOnOpen", True);
	
	ReportName = Undefined;
	If ThisIsOurCompany Then
		ReportName = "AccountsPayablesAndReceivablesByIntercompany";
		FormParameters.Filter.Insert("Seller", Object.Organization);
		FormParameters.Filter.Insert("Customer", CurrentRow.Counterparty);
		If CodeTypeOfCalculations = "1" Then
			FormParameters.Insert("VariantKey", "SalesPayments");
		ElsIf CodeTypeOfCalculations = "2" Then
			FormParameters.Insert("VariantKey", "ProcurementPayments");
		EndIf;
		FormParameters.Filter.Delete("Organization");
		FormParameters.Filter.Delete("Counterparty");
	ElsIf SelectingReports.Count() = 1 Then
		ReportName = SelectingReports[0].Value;
	ElsIf SelectingReports.Count() > 1 Then
		Response = Await ChooseFromMenuAsync(SelectingReports, Item);
		If Response <> Undefined Then
			ReportName = Response.Value;
		EndIf;
	EndIf;
	
	If ReportName <> Undefined Then
		OpenForm("Report." + ReportName + ".Form", FormParameters, ThisObject);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CounterpartySPartner(Counterparty)
	Return Common.ObjectAttributeValue(Counterparty, "Partner");
EndFunction

#Region FillingInMonitorData

&AtClient
Procedure FillInAccordingToCalculations(QuietMode = True, Counterparty = Undefined)
	
	ClearMessages();
	Result = FillInAccordingToCalculationDataATServer(QuietMode, Counterparty);
	If Result = Undefined Then
		Return;
	EndIf;
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	CallbackOnCompletion = New CallbackDescription(
		"FillInAccordingToCalculationsCompletion",
		ThisObject,
		Counterparty);
	TimeConsumingOperationsClient.WaitCompletion(Result, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtClient
Procedure FillInAccordingToCalculationsWithExpectation() Export
	FillInAccordingToCalculations();
EndProcedure

&AtClient
Procedure FillInAccordingToCalculationsCompletion(Result, Counterparty) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	ExecutionResult = LoadPreparedData(Result, Counterparty);
	
	If Not ExecutionResult.Success Then
		
	EndIf;
	
EndProcedure

&AtServer
Function FillInAccordingToCalculationDataATServer(QuietMode = True, Counterparty = Undefined)
	
	// Check the fullness of the required Attributes
	If Not CheckFilling() Then
		If QuietMode Then
			// Hide messages about filling errors
			GetUserMessages(True);
		EndIf;
		Return Undefined;
	EndIf;
	
	If IsBlankString(Sort) Then
		Sort = "CounterpartyName_";
	EndIf;
	
	TimeConsumingOperations.CancelJobExecution(JobID);
	
	JobID = Undefined;
	
	ReconciliationParameters = New Structure;
	
	ReconciliationParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	ReconciliationParameters.Insert("EndOfPeriod", EndOfDay(Object.EndOfPeriod));
	ReconciliationParameters.Insert("Organization", Object.Organization);
	ReconciliationParameters.Insert("Counterparty", ListOfCounterparties_.UnloadValues());
	ReconciliationParameters.Insert("Manager", Manager);
	ReconciliationParameters.Insert("IncludeContractsWithoutTurnover", IncludeContractsWithoutTurnover);
	ReconciliationParameters.Insert("ThereAreDiscrepancies", ThereAreDiscrepancies);
	ReconciliationParameters.Insert("OnlyOurCompanies", ThisIsOurCompany);
	
	TypesOfCalculations_ = New Array;
	For Each Filter In FilterTypesOfCalculations_ Do
		If Filter.Use Then
			TypesOfCalculations_.Add(Filter.PaymentType_);
		EndIf;
	EndDo;
	ReconciliationParameters.Insert("TypesOfCalculations_", TypesOfCalculations_);
	
	ReconciliationStatuses = New Map;
	For Each Filter In FilterReconciliationStatuses Do
		ReconciliationStatuses.Insert(Filter.Name, Filter.Use);
	EndDo;
	ReconciliationParameters.Insert("ReconciliationStatuses", ReconciliationStatuses);
	
	ReconciliationParameters.Insert("Sort", Sort);
	ReconciliationParameters.Insert("AllSortingFields", Items.Sort.ChoiceList.UnloadValues());
	
	If IsTempStorageURL(AddressOfExecutionErrors) Then
		DeleteFromTempStorage(AddressOfExecutionErrors);
		AddressOfExecutionErrors = "";
	EndIf;
	
	AddressOfExecutionErrors = PutToTempStorage(Undefined, UUID);
	ReconciliationParameters.Insert("AddressOfExecutionErrors", AddressOfExecutionErrors);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = "FillInCounterpartiesForReconciliation";
	
	Result = TimeConsumingOperations.ExecuteInBackground(
		"DataProcessors.SettlementReconciliationMonitor.GetReconciliationData",
		ReconciliationParameters,
		ExecutionParameters);
	
	JobID = Result.JobID;
	
	Return Result;
	
EndFunction

&AtServer
Function LoadPreparedData(Result, Counterparty)
	
	ReconciliationData = GetFromTempStorage(Result.ResultAddress);
	
	ExecutionResult = New Structure;
	ExecutionResult.Insert("JobCompleted", True);
	ExecutionResult.Insert("Success", False);
	
	If TypeOf(ReconciliationData) <> Type("Structure") Then
		Return ExecutionResult;
	EndIf;
	
	ExecutionResult.Success = True;
	
	ReconciliationWithCounterparties.Load(ReconciliationData.Counterparties);
	
	InterestConfirmedCounterpartyDebt = 0;
	CounterpartySDebt = ReconciliationData.DebtTotals.CounterpartySDebt;
	If CounterpartySDebt.Total > 0 Then
		InterestConfirmedCounterpartyDebt = Round(CounterpartySDebt.Verified_ / CounterpartySDebt.Total * 100, 0);
	EndIf;
	
	InterestConfirmedOurDebt = 0;
	AccountsPayableOfCompany = ReconciliationData.DebtTotals.AccountsPayableOfCompany;
	If AccountsPayableOfCompany.Total > 0 Then
		InterestConfirmedOurDebt = Round(AccountsPayableOfCompany.Verified_ / AccountsPayableOfCompany.Total * 100, 0);
	EndIf;
	
	FillInNumberOfStatuses(ReconciliationData.ReconciliationStatusResults);
	
	Return ExecutionResult;
	
EndFunction

#EndRegion

&AtClient
Procedure CreateReconciliationDocumentForSettlements()
	
	ClearMessages();
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	CurrentRow = Items.ReconciliationWithCounterparties.CurrentData;
	
	FillingValues = New Structure;
	FillingValues.Insert("Organization", Object.Organization);
	If CurrentRow <> Undefined Then
		FillingValues.Insert("Counterparty", CurrentRow.Counterparty);
	EndIf;
	FillingValues.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FillingValues.Insert("EndOfPeriod", Object.EndOfPeriod);
	ByContracts = PredefinedValue("Enum.ModeOfARAPTotalsReconciliation.ByContracts");
	FillingValues.Insert("ModeOfARAPTotalsReconciliation", ByContracts);
	FormParameters = New Structure("FillingValues", FillingValues);
	OpenForm("Document.ARAPReconciliation2_5_11.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Async Procedure SetReconciliationStatus(StatusName)
	
	ClearMessages();
	CurrentRow = Items.ReconciliationWithCounterparties.CurrentData;
	
	If CurrentRow = Undefined Then
		CommonClient.MessageToUser(NStr("vi = 'Chưa chọn đối tác';
										|ru = 'Не выбран контрагент';
										|en = 'Select the counterparty'; fa = 'Select the counterparty';
										|it = 'Select the counterparty';
										|pl = 'Select the counterparty';
										|tr = 'Cari hesap seçilmemiş'"));
		Return;
	EndIf;
	
	If CurrentRow.ReconciliationStatus = "ReconciliationIsRequired" Then
		If StatusName = "IsRejected" Then
			CommonClient.MessageToUser(NStr("vi = 'Không có chứng từ đối chiếu nào được tạo';
											|ru = 'Нет созданных документов сверки';
											|en = 'There are no reconciliation documents created'; fa = 'There are no reconciliation documents created';
											|it = 'There are no reconciliation documents created';
											|pl = 'There are no reconciliation documents created';
											|tr = 'Oluşturulmuş hesap mutabakatı belgeleri yok'"));
			Return;
		EndIf;
		
		QueryText = NStr("vi = 'Cần tạo chứng từ đối chiếu cho đối tác ""%1"".
		|Tạo?';
		|ru = 'Для контрагента ""%1"" требуется создать документ сверки.
		|Создать?';
		|en = 'For the ""%1"" counterparty, a reconciliation document is required.
		|Create?'; fa = 'For the ""%1"" counterparty, a reconciliation document is required.
		|Create?';
		|it = 'For the ""%1"" counterparty, a reconciliation document is required.
		|Create?';
		|pl = 'For the ""%1"" counterparty, a reconciliation document is required.
		|Create?';
		|tr = '""%1""  cari hesabı için hesap mutabakatı belgesi oluşturulması gerekiyor.
		|Oluşturulsun mu?'");
		QueryText = StrReplace(QueryText, "%1", CurrentRow.CounterpartyName_);
		Response = Await DoQueryBoxAsync(QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		If Response = DialogReturnCode.Yes Then
			CreateReconciliationDocumentForSettlements();
		EndIf;
		
	Else
		Status = String(PredefinedValue("Enum.StatusesOfARAPReconciliation2_5_11."+StatusName));
		QueryText = StrReplace(TextOfStatusSettingQuestion(), "%1", Status);
		Response = Await DoQueryBoxAsync(QueryText,QuestionDialogMode.YesNo,,DialogReturnCode.Yes);
		If Response = DialogReturnCode.Yes Then
			SetReconciliationStatusATServer(StatusName, CurrentRow.Counterparty);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Function TextOfStatusSettingQuestion()
	
	Return NStr("vi = 'Đối với tất cả các chứng từ đối chiếu của đối tác đã chọn trong kỳ đã chọn, sẽ được thiết lập trạng thái ""%1"".
	|Tiếp tục?';
	|ru = 'Для всех документов сверки по выбранному контрагенту, за выбранный период будет установлен статус ""%1"".
	|Продолжить?';
	|en = 'For all reconciliation documents for the selected counterparty, the ""%1"" status will be set for the selected period.
	|Continue?'; fa = 'For all reconciliation documents for the selected counterparty, the ""%1"" status will be set for the selected period.
	|Continue?';
	|it = 'For all reconciliation documents for the selected counterparty, the ""%1"" status will be set for the selected period.
	|Continue?';
	|pl = 'For all reconciliation documents for the selected counterparty, the ""%1"" status will be set for the selected period.
	|Continue?';
	|tr = 'Seçilen cari hesap bazında, seçilen dönem için tüm mutabakat belgelerine ""%1"" durumu atanacaktır.
	|Devam edilsin mi?'");
	
EndFunction

&AtServer
Procedure SetReconciliationStatusATServer(StatusName, Counterparty)
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.Text = 
	"SELECT
	|	ARAPReconciliation.Ref AS Ref
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation
	|WHERE
	|	ARAPReconciliation.Posted
	|	AND ARAPReconciliation.Organization = &Organization
	|	AND ARAPReconciliation.Counterparty = &Counterparty
	|	AND ARAPReconciliation.BeginOfPeriod <= &EndOfPeriod
	|	AND ARAPReconciliation.EndOfPeriod >= &BeginOfPeriod";
	
	Query.SetParameter("Organization", Object.Organization);
	Query.SetParameter("Counterparty", Counterparty);
	Query.SetParameter("BeginOfPeriod", Object.BeginOfPeriod);
	Query.SetParameter("EndOfPeriod", Object.EndOfPeriod);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ObjectReconciliation = Selection.Ref.GetObject();// DocumentObject.ARAPReconciliation2_5_11 -
		ObjectReconciliation.Status = Enums.StatusesOfARAPReconciliation2_5_11[StatusName];
		ObjectReconciliation.Write(DocumentWriteMode.Posting);
	EndDo;
	
EndProcedure

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_EndOfPeriod" Then
		EndOfPeriodOnChange(Items.EndOfPeriod);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
