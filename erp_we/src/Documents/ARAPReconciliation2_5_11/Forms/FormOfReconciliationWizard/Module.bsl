
#Region Variables

&AtClient
Var PreviousValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	UseMultipleCompanies = GetFunctionalOption("UseMultipleCompanies");
	ThisIsTradeManagement = GetFunctionalOption("TradeManagement");
	AvailableToSaveUserData = AccessRight("SaveUserData", Metadata);
	
	SetConditionalAppearance();
	SetVisibilityOfElementsOnServer();
	
	Documents.ARAPReconciliation2_5_11.InitializeSettingsComposer(LinkerSelection, UUID);
	
	ReconciliationPeriod.Variant = StandardPeriodVariant.LastMonth;
	ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
	DateOfDocuments = CurrentSessionDate();
	Items.Counterparty.ChooseType = UseMultipleCompanies;
	Items.ThisIsReconciliationBetweenOrganizations.Visible = UseMultipleCompanies;
	Items.DecorationCounterparty.Visible = Not UseMultipleCompanies;
	Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	SetPassedParameters(ThisObject);

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "PartnersARAPAccounting", NStr("vi = 'Mở báo cáo ""Hạch toán với đối tác""';
													|ru = 'Открыть отчет ""Расчеты с контрагентами""';
													|en = 'Open the ""Settlements with counterparties"" report'; fa = 'Open the ""Settlements with counterparties"" report';
													|it = 'Открыть отчет ""Расчеты с контрагентами""';
													|pl = 'Open the ""Settlements with counterparties"" report';
													|tr = '""Cari hesap ödemeleri"" raporunu aç'"));

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SettingAvailabilityOfFormElements();
	ButtonControlBasement();
	PreviousValues = New Structure;
	PreviousValues.Insert("ExternalCounterparty_");
	PreviousValues.Insert("CounterpartyIsOurCompany");

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)


EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave(
		Documents.ARAPReconciliation2_5_11.UserSettingsObjectKey(),
		"Filter_Settings",
		LinkerSelection.GetSettings());
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Filter_Settings = Common.CommonSettingsStorageLoad(
						Documents.ARAPReconciliation2_5_11.UserSettingsObjectKey(),
						"Filter_Settings");
	If Filter_Settings <> Undefined Then
		If Not Parameters.ReplaceFormSettings Then
			DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
		EndIf;
		SetPassedParameters(Settings);
		DataCompositionClientServer.CopyElements(Settings["LinkerSelection.Settings.Filter"], LinkerSelection.Settings.Filter);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		Cancel = True;
		Return;
	EndIf;
	
	If AskAQuestionAboutClosing Then
		
		QueryText = NStr("vi = 'Đóng biểu mẫu trợ giúp? Dữ liệu vừa nhập sẽ bị mất.';
						|ru = 'Закрыть форму помощника? Введенные данные будут потеряны.';
						|en = 'Close the wizard? The data entered will be lost.'; fa = 'Close the wizard? The data entered will be lost.';
						|it = 'Закрыть форму помощника? Введенные данные будут потеряны.';
						|pl = 'Zamknąć formularz asystenta? Wprowadzone dane zostaną utracone.';
						|tr = 'Asistan formu kapatılsın mı? Girilen veriler kaybolacaktır.'");
		Cancel = True;
		ShowQueryBox(
			New CallbackDescription("BeforeClosingQuestionEnds", ThisObject),
			QueryText,
			QuestionDialogMode.YesNo);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReconciliationPeriodOnChange(Item)
	
	ClearMessages();
	
	If Not ValueIsFilled(ReconciliationPeriod.EndDate) Then
		MessageText = NStr("vi = 'Cần điền ngày cuối kỳ đối chiếu.';
							|ru = 'Дата окончания периода сверки должна быть заполнена.';
							|en = 'Specify a reconciliation end date.'; fa = 'Specify a reconciliation end date.';
							|it = 'Дата окончания периода сверки должна быть заполнена.';
							|pl = 'Specify a reconciliation end date.';
							|tr = 'Mutabakat döneminin bitiş tarihi doldurulmalıdır.'");
		
		CommonClient.MessageToUser(MessageText, , "ReconciliationPeriod");
		
		If ValueIsFilled(ReconciliationPeriod.StartDate) Then
			ReconciliationPeriod.EndDate = EndOfDay(ReconciliationPeriod.StartDate);
		Else
			ReconciliationPeriod.EndDate = EndOfDay(CommonClient.SessionDate());
		EndIf;
	ElsIf ReconciliationPeriod.StartDate > ReconciliationPeriod.EndDate
		And ValueIsFilled(ReconciliationPeriod.EndDate) Then
		
		MessageText = NStr("vi = 'Ngày đầu kỳ không thể lớn hơn ngày cuối kỳ.';
							|ru = 'Дата начала периода не может быть больше даты окончания периода.';
							|en = 'The period start date cannot be greater than the period end date.'; fa = 'The period start date cannot be greater than the period end date.';
							|it = 'Дата начала периода не может быть больше даты окончания периода.';
							|pl = 'Data początku okresu nie może być dłuższa niż data zakończenia okresu.';
							|tr = 'Dönemin başlangıç tarihi, dönemin bitiş tarihinden büyük olamaz.'");
		CommonClient.MessageToUser(MessageText, , "ReconciliationPeriod");
		ReconciliationPeriod.EndDate = EndOfDay(ReconciliationPeriod.StartDate);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	ReconciliationPeriod.StartDate = BeginOfPeriod;
	If ReconciliationPeriod.StartDate > ReconciliationPeriod.EndDate
		And ValueIsFilled(ReconciliationPeriod.EndDate) Then
		ReconciliationPeriod.EndDate = EndOfDay(ReconciliationPeriod.StartDate);
		EndOfPeriod = ReconciliationPeriod.EndDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure EndOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	ReconciliationPeriod.EndDate = EndOfDay(EndOfPeriod);
	If ReconciliationPeriod.StartDate > ReconciliationPeriod.EndDate
		And ValueIsFilled(ReconciliationPeriod.EndDate) Then
		ReconciliationPeriod.EndDate = EndOfDay(ReconciliationPeriod.StartDate);
		EndOfPeriod = ReconciliationPeriod.EndDate;
	EndIf;
EndProcedure

&AtClient
Procedure ThisIsReconciliationBetweenOrganizationsOnChange(Item)
	
	If TypeOf(Counterparty) = Type("CatalogRef.Counterparties") Then
		PreviousValues.ExternalCounterparty_ = Counterparty;
	ElsIf TypeOf(Counterparty) = Type("CatalogRef.Companies") Then
		PreviousValues.CounterpartyIsOurCompany = Counterparty;
	EndIf;
	
	If ThisIsReconciliationBetweenOrganizations Then
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Companies");
		Counterparty = PreviousValues.CounterpartyIsOurCompany;
	Else
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
		Counterparty = PreviousValues.ExternalCounterparty_;
	EndIf;
	
EndProcedure

&AtClient
Procedure SendDocumentsToPrintOnChange(Item)
	
	SettingAvailabilityOfFormElements();
	
EndProcedure

&AtClient
Procedure PrintSetupDecorationClick(Item)
	
	ReconciliationSettings = New Structure;
	ReconciliationSettings.Insert("TotalReconciliationMode", ModeOfARAPTotalsReconciliation);
	ReconciliationSettings.Insert("ThereAreContractsForLoansDepositsLoansLeases", CreditorARAPAccounting Or DebtorARAPAccounting Or LeaseContractARAPWithLessor);
	FormParameters = New Structure("ReconciliationSettings", ReconciliationSettings);
	OpenForm(
		"Document.ARAPReconciliation2_5_11.Form.PrintSettings",
		FormParameters,
		ThisObject,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

&AtClient
Procedure InscriptionHasDiscrepanciesProcessingNavigationLink(Item, FormattedStringURL, StandardProcessing)
	
	StandardProcessing = False;
	
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCalculationTable

&AtClient
Procedure CalculationTableCreateADocumentOnChange(Item)
	
	RecalculateNumberOfRowsInCalculationTable();
	AskAQuestionAboutClosing = True;
	
EndProcedure

&AtClient
Procedure CalculationTableOrganizationStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CalculationTableCounterpartyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CalculationTableOrganizationClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure CalculationTableCounterpartyClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Next(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure Cancel(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	NavigateThroughPages(Command);
	
EndProcedure

&AtClient
Procedure PartnersARAPAccounting(Command)
	
	ClearMessages();
	
	ParametersOfExtendedSelectionForm();
	
	FormParameters = New Structure("Filter, FixedSettings, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	FormParameters.Insert("PurposeUseKey", "AssistantForCreatingReconciliationOfSettlements");
	
	FormParameters.Filter = New Structure("Period", ReconciliationPeriod);
	
	If Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3 Then
		
		FixedSettings = New DataCompositionSettings();
		
		ReportSelectionFields = "Organization, Partner, Counterparty, PartnersSegment";
		For Each FilterElement In LinkerSelection.Settings.Filter.Items Do
			
			If StrFind(ReportSelectionFields, String(FilterElement.LeftValue)) <> 0
				And FilterElement.Use Then
				
				If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
					AddSelectionElementToSelection(FixedSettings.Filter, FilterElement);
				Else
					AddGroupOfSelectionElementsToSelection(FixedSettings.Filter, FilterElement);
				EndIf;
				
			EndIf;
			
		EndDo;
		
		FormParameters.FixedSettings = FixedSettings;
		
	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		If Items.CalculationTable.CurrentData = Undefined Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa chọn dòng nào';
											|ru = 'Не выбрана ни одна строка';
											|en = 'No line is selected'; fa = 'هیچ سطری انتخاب نشده است';
											|it = 'Не выбрана ни одна строка';
											|pl = 'Nie wybrano ani jednego wiersza';
											|tr = 'Hiçbir satır seçilmedi'"),,"CalculationTable");
			Return;
		EndIf;
		
		FormParameters.Filter.Insert("Organization", Items.CalculationTable.CurrentData.Organization);
		FormParameters.Filter.Insert("Counterparty",  Items.CalculationTable.CurrentData.Counterparty);
		
	EndIf;
	
	FormParameters.VariantKey = "ReconciliationOfSettlements";
	
	NameOfReportFormForSettlementsWithPartners = ?(NewOnlineARAPAccounting, "Report.PartnersARAPAccountingStatement.Form", "Report.PartnersARAPAccounting.Form");
	
	OpenForm(NameOfReportFormForSettlementsWithPartners,
		FormParameters,
		ThisObject,
		True);
	
EndProcedure

&AtClient
Procedure IntercompanyARAP(Command)
	
	ClearMessages();
	
	FormParameters = New Structure("Filter, FixedSettings, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	FormParameters.Insert("PurposeUseKey", "AssistantForCreatingReconciliationOfSettlements");
	
	FormParameters.Filter = New Structure("Period", ReconciliationPeriod);
	
	If ValueIsFilled(Organization) Then
		
		If CustomerARAPAccounting Then
			FormParameters.VariantKey = "SalesPayments";
			FormParameters.Filter.Insert("Seller", Organization);
			If ValueIsFilled(Counterparty) Then
				FormParameters.Filter.Insert("Customer", Counterparty);
			EndIf;
		ElsIf VendorARAPAccounting Then
			FormParameters.VariantKey = "ProcurementPayments";
			FormParameters.Filter.Insert("Customer", Organization);
			If ValueIsFilled(Counterparty) Then
				FormParameters.Filter.Insert("Seller", Counterparty);
			EndIf;
		EndIf;
		
	EndIf;
	
	NameOfReportFormForSettlementsBetweenOrganizations = ?(NewOnlineARAPAccounting, "Report.AccountsPayablesAndReceivablesByIntercompany.Form", "Report.IntercompanyARAP.Form");
	
	OpenForm(NameOfReportFormForSettlementsBetweenOrganizations,
		FormParameters,
		ThisObject,
		True); 
	
EndProcedure

&AtClient
Procedure CardForFinancialInstruments(Command)
	
	FormParameters = New Structure("Filter, FixedSettings, VariantKey, GenerateOnOpen");
	FormParameters.GenerateOnOpen = True;
	FormParameters.Insert("PurposeUseKey", "AssistantForCreatingReconciliationOfSettlements");
	
	FormParameters.Filter = New Structure("ReportPeriod", ReconciliationPeriod);
	FixedSettings = New DataCompositionSettings();
	
	If ValueIsFilled(Organization) Then
		FormParameters.Filter.Insert("Organization", Organization);
	EndIf;
	If ValueIsFilled(Counterparty) Then
		FormParameters.Filter.Insert("Counterparty", Counterparty);
	EndIf;
	ReportSelectionFields = "Organization, Partner, Counterparty, PartnersSegment";
	For Each FilterElement In LinkerSelection.Settings.Filter.Items Do
		
		If StrFind(ReportSelectionFields, String(FilterElement.LeftValue)) <> 0
			And FilterElement.Use Then
			
			If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
				AddSelectionElementToSelection(FixedSettings.Filter, FilterElement);
			Else
				AddGroupOfSelectionElementsToSelection(FixedSettings.Filter, FilterElement);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	If ThisIsTradeManagement Then
		FormParameters.VariantKey = "CardOfSettlementsOnFinancialInstrumentsTMContext";
	Else
		FormParameters.VariantKey = "SettlementCardForFinancialInstrumentsContext";
	EndIf;
	
	FormParameters.FixedSettings = FixedSettings;
	
	OpenForm("Report.FinancialInstrumentsARAPCard.Form",
		FormParameters,
		ThisObject,
		True);

EndProcedure

&AtClient
Procedure SetDoNotChange(Command)
	
	SetActionWithExistingDocument("DontChange");
	
EndProcedure

&AtClient
Procedure InstallForDeletion(Command)
	
	SetActionWithExistingDocument("DeleteCreateNew");
	
EndProcedure

&AtClient
Procedure SetDoNotRefill(Command)
	
	SetActionWithExistingDocument("ReFill_");
	
EndProcedure

&AtClient
Procedure SetToCreate(Command)
	
	SetActionWithNewDocument("Create");
	
EndProcedure

&AtClient
Procedure SetDoNotCreate(Command)
	
	SetActionWithNewDocument("NotCreate");
	
EndProcedure

&AtClient
Procedure SetFilterSettings(Command)
	
	OpeningParameters = ParametersOfExtendedSelectionForm();
	
	CloseHandler = New CallbackDescription("SetFilterSettingsCompletion", ThisObject);
	OpenForm("Document.ARAPReconciliation2_5_11.Form.AdvancedFilter",
		OpeningParameters,
		ThisObject,
		,
		,
		, 
		CloseHandler,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliation(Command)
	
	SelectedRows = TMCommonUseClient.CheckGetLinksHighlightedInList(Items.ReconciliationDocumentList);
	If SelectedRows.Count() = 0 Then
		Return;
	EndIf;

	ShowQueryBox(New CallbackDescription("SetTheStatusOnReconciliationCompletion", ThisObject, New Structure("SelectedRows", SelectedRows)), NStr("vi = 'Các chứng từ được chọn trong danh sách sẽ đặt trạng thái ""Đang đối chiếu"". Tiếp tục?';
																																					|ru = 'У выделенных в списке документов будет установлен статус ""На сверке"". Продолжить?';
																																					|en = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?'; fa = 'Status of the documents selected in the list will be set to ""In reconciliation"". Continue?';
																																					|it = 'У выделенных в списке документов будет установлен статус ""На сверке"". Продолжить?';
																																					|pl = 'Dla dokumentów zaznaczonych na liście zostanie ustawiony status ""Na weryfikacji"". Kontynuować?';
																																					|tr = 'Listedeki seçili belgelerin durumu ""Mutabakatta"" olarak ayarlanacaktır. Devam edilsin mi?'"), QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure SetPeriodInterval(Command)
	
	Notification = New CallbackDescription(
		"SetPeriodIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		ThisObject, 
		New Structure("StartDate, EndDate", "BeginOfPeriod", "EndOfPeriod"),
		Notification);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure


// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)

	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ReconciliationDocumentList);

EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export

	ExecuteCommandAtServer(ExecutionParameters);

EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()

	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ReconciliationDocumentList);

EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

#Region HandlersOfFirstStepOfHelper

&AtServer
Procedure FillInCalculationTable()
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BeginOfPeriod", ReconciliationPeriod.StartDate);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "EndOfPeriod", EndOfDay(ReconciliationPeriod.EndDate));
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "Period", ReconciliationPeriod.StartDate);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReceiveReconciliationDocuments", True);
	
	ContractReconciliationMode = ModeOfARAPTotalsReconciliation = Enums.ModeOfARAPTotalsReconciliation.ByContracts;
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ContractReconciliationMode", ContractReconciliationMode);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByARAPTypes", SplitByARAPTypes);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByPartners", SplitByPartners);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByContracts", SplitByContracts);
	
	If NewOnlineARAPAccounting Then
		DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReconciliationInCurrency", ReconciliationInCurrency);
		SetBasicSelections();
		DCSResultTable = Documents.ARAPReconciliation2_5_11.GetSettlements(LinkerSelection);
		
	Else
		ComposerSelectionFinTools = New DataCompositionSettingsComposer;
		Documents.ARAPReconciliation2_4.InitializeSettingsComposer(ComposerSelectionFinTools, UUID);
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "BeginOfPeriod", ReconciliationPeriod.StartDate);
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "EndOfPeriod", EndOfDay(ReconciliationPeriod.EndDate));
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "Period", ReconciliationPeriod.StartDate);
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "ReceiveReconciliationDocuments", True);
		
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "SplitByARAPTypes", SplitByARAPTypes);
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "SplitByPartners", SplitByPartners);
		DataCompositionClientServer.SetParameter(ComposerSelectionFinTools.Settings, "SplitByContracts", SplitByContracts);
		
		SetBasicSelections(ComposerSelectionFinTools);
		
		DCSResultTable = Documents.ARAPReconciliation2_4.GetSettlements(ComposerSelectionFinTools);
	EndIf;
	
	If DCSResultTable.Count() > 0 Then
		Groups = "Organization, Counterparty, ThereAreDocuments, ChangeDocument, CreateADocument, ReconciliationDocument";
		Items.ReconciliationDocumentListPaymentType_.Visible = SplitByARAPTypes;
		Items.ReconciliationDocumentListPartner.Visible = SplitByPartners;
		Items.ReconciliationDocumentListContract.Visible = SplitByContracts;
		If SplitByContracts Then
			Groups = "Contract, " + Groups;
		EndIf;
		If SplitByPartners Then
			Groups = "Partner, " + Groups;
		EndIf;
		If SplitByARAPTypes Then
			Groups = "PaymentTypeOrder, PaymentType_, " + Groups;
		EndIf;
		If Not FinToolsAreUsed And NewOnlineARAPAccounting Then
			Groups = "ReconciliationCurrency, " + Groups;
		EndIf;

		DCSResultTable.GroupBy(Groups);
		If SplitByARAPTypes Then
			Groups = StrReplace(Groups, "PaymentType_, ", "");
		EndIf;
		DCSResultTable.Sort(Groups);
		CalculationTable.Load(DCSResultTable);
		
		Filter = New Structure("ThereAreDocuments",True);
		StringsThereAreDocuments = CalculationTable.FindRows(Filter);
		For Each String In StringsThereAreDocuments Do
			String.ChangeDocument = "DontChange";
		EndDo;
		For Each String In CalculationTable Do
			If Not String.ThereAreDocuments Then
				String.DescriptionOfOutgoingDocuments = DescriptionOfOutgoingDocuments;
			EndIf;
		EndDo;
	EndIf;

EndProcedure

&AtClient
Procedure FillInCalculationTableEnd(Result, AdditionalParameters) Export
	
	FillInCalculationTable();
	RecalculateNumberOfRowsInCalculationTable();
	Items.CalculationTablePaymentType_.Visible = SplitByARAPTypes;
	Items.CalculationTablePartner.Visible = SplitByPartners;
	Items.CalculationTableContract.Visible = SplitByContracts;
	Items.CalculationTableReconciliationCurrency.Visible = NewOnlineARAPAccounting And Not FinToolsAreUsed;
	Items.WizardPages.CurrentPage = Items.CalculationTablePage;
	Items.Next.Enabled = True;
	
EndProcedure

#EndRegion

#Region SecondStepHelperHandlers

&AtClient
Procedure RecalculateNumberOfRowsInCalculationTable()
	
	CreatedItemsCount = 0;
	DeletedItemsCount = 0;
	NumberOfRefills = 0;
	
	For Each CalculationTableRow In CalculationTable Do
		
		If CalculationTableRow.CreateADocument Then
			
			CreatedItemsCount = CreatedItemsCount + 1;
			
		ElsIf CalculationTableRow.ChangeDocument = "DeleteCreateNew" Then
			CreatedItemsCount = CreatedItemsCount + 1;
			DeletedItemsCount = DeletedItemsCount + 1;
			
		ElsIf CalculationTableRow.ChangeDocument = "ReFill_" Then
			NumberOfRefills = NumberOfRefills + 1;
			
		EndIf;
		
	EndDo;

	TotalRows = CalculationTable.Count();
	WillBeCreated = CreatedItemsCount;
	WillBeDeleted = DeletedItemsCount;
	WillBeRefilled = NumberOfRefills;
	NumberOfSelected = CreatedItemsCount + NumberOfRefills;

EndProcedure

#EndRegion

#Region HandlersOfThirdHelperStep

&AtServer
Procedure CreateInBackgroundJobOnServer()
	
	CancelJobExecution(JobID);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'Tạo chứng từ ""Biên bản đối chiếu công nợ""';
														|ru = 'Создание документов ""Сверка взаиморасчетов""';
														|en = 'Creating AR/AP reconciliation'; fa = 'Creating AR/AP reconciliation';
														|it = 'Создание документов ""Сверка взаиморасчетов""';
														|pl = 'Tworzenie dokumentów „Uzgodnienie rozliczeń”';
														|tr = '""Alacak/Borç mutabakatı"" belgelerinin oluşturulması'");
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("CalculationTable", CalculationTable.Unload());
	MethodParameters.Insert("DateOfDocuments", DateOfDocuments);
	MethodParameters.Insert("ReconciliationPeriod", ReconciliationPeriod);
	MethodParameters.Insert("Filter_Settings", LinkerSelection.GetSettings());
	MethodParameters.Insert("ContractsWithoutTurnover", ContractsWithoutTurnover);
	MethodParameters.Insert("SplitByARAPTypes", SplitByARAPTypes);
	MethodParameters.Insert("SplitByPartners", SplitByPartners);
	MethodParameters.Insert("SplitByContracts", SplitByContracts);
	MethodParameters.Insert("ModeOfARAPTotalsReconciliation", ModeOfARAPTotalsReconciliation);
	MethodParameters.Insert("ReconciliationInCurrency", ReconciliationInCurrency);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(
							"Documents.ARAPReconciliation2_5_11.CreateDocuments",
							MethodParameters,
							ExecutionParameters);
	
	JobID = TimeConsumingOperation.JobID;

EndProcedure

&AtClient
Procedure MoveDocumentsToResult()
	
	SpentDocuments = New Array;
	ArrayOfAllReconciliationDocuments = New Array;
	For Each CalculationLine_ In CalculationTable Do
		Data = New Structure("ReconciliationDocument,Action", CalculationLine_.ReconciliationDocument, "DontChange");
		SpentDocuments.Add(Data);
		ArrayOfAllReconciliationDocuments.Add(CalculationLine_.ReconciliationDocument);
	EndDo;
	
	ReconciliationDocuments = New Structure;
	ReconciliationDocuments.Insert("SpentDocuments", SpentDocuments);
	ReconciliationDocuments.Insert("ArrayOfAllReconciliationDocuments", ArrayOfAllReconciliationDocuments);
	Address = PutToTempStorage(ReconciliationDocuments, UUID);
	
	Result = New Structure("ResultAddress", Address);
	CreateDocumentsCompletion(Result, Undefined);
	
EndProcedure

&AtClient
Procedure CreateDocumentsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Items.Next.Enabled = True;
		Return;
	EndIf;
	
	CreationResult = GetFromTempStorage(Result.ResultAddress);
	
	If CreationResult = Undefined Then
		Items.Next.Enabled = True;
		Return;
	EndIf;
	
	ProcessedDocumentsTable.Clear();
	CreatedItemsCount = 0;
	SpentDocuments = CreationResult.SpentDocuments;
	For Each ProtocolString In SpentDocuments Do
		
		TableRow = ProcessedDocumentsTable.Add();
		FillPropertyValues(TableRow, ProtocolString);
		ProcessProtocolString(ProtocolString, CreatedItemsCount);
		
	EndDo;

	ResultingText = NStr("vi = 'Đã tạo %CreatedItemsCount% trong số %TotalCount1% chứng từ';
						|ru = 'Создано %CreatedItemsCount% из %TotalCount1% документов';
						|en = 'Created: %CreatedItemsCount% out of %TotalCount1%'; fa = 'Created: %CreatedItemsCount% out of %TotalCount1%';
						|it = 'Создано %CreatedItemsCount% из %TotalCount1% документов';
						|pl = 'Utworzono %CreatedItemsCount% z %TotalCount1% dokumentów';
						|tr = '%TotalCount1%belgeden %CreatedItemsCount% oluşturuldu'");
	ResultingText = StrReplace(ResultingText, "%CreatedItemsCount%", CreatedItemsCount);
	ResultingText = StrReplace(ResultingText, "%TotalCount1%",     NumberOfSelected);
	Items.DecorationResult.Title = ResultingText;
	
	ShowResultPage(CreationResult.ArrayOfAllReconciliationDocuments);
	
EndProcedure

// Show the result page.
// 
// Parameters:
//  ReconciliationDocuments - Array of DocumentRef.ARAPReconciliation2_5_11
// 
&AtClient
Procedure ShowResultPage(ReconciliationDocuments)
	
	CommonClientServer.SetDynamicListFilterItem(
		ReconciliationDocumentList, "Ref", ReconciliationDocuments, DataCompositionComparisonType.InList);
	
	AskAQuestionAboutClosing = False;
		
	Items.WizardPages.CurrentPage = Items.ResultPage;
	Items.Next.Enabled = True;
	SettingAvailabilityOfFormElements();
	ButtonControlBasement();
	
	If FormOwner <> Undefined Then
		List = FormOwner.Items.List; // FormTable -
		List.Refresh();
	EndIf;
	
EndProcedure

// LongDesc
// 
// Parameters:
// 	ProtocolString - See Documents.ARAPReconciliation2_5_11.ProtocolString
// 	CreatedItemsCount - Number - 
// 	
&AtClient
Procedure ProcessProtocolString(ProtocolString, CreatedItemsCount)
	
	If ProtocolString.Action = "Creating" Then 
		
		NotifyOfAction(ProtocolString.ReconciliationDocument, NStr("vi = 'Tạo mới:';
																	|ru = 'Создание:';
																	|en = 'Create:'; fa = 'ایجاد:';
																	|it = 'Создание:';
																	|pl = 'Create:';
																	|tr = 'Oluşturma:'"));
		CreatedItemsCount = CreatedItemsCount + 1;
		
	ElsIf ProtocolString.Action = "MarkForDeletion_" Then 
		
		NotifyOfAction(ProtocolString.ReconciliationDocument, NStr("vi = 'Đã đặt dấu xóa:';
																	|ru = 'Пометка удаления установлена:';
																	|en = 'Marked for deletion:'; fa = 'Marked for deletion:';
																	|it = 'Пометка удаления установлена:';
																	|pl = 'Ustawiono znacznik usunięcia:';
																	|tr = 'Silme işareti yerleştirildi:'"));
		
	ElsIf ProtocolString.Action = "Refilling" Then 
		
		NotifyOfAction(ProtocolString.ReconciliationDocument, NStr("vi = 'Điền lại:';
																	|ru = 'Перезаполнение:';
																	|en = 'Refill:'; fa = 'Refill:';
																	|it = 'Перезаполнение:';
																	|pl = 'Refill:';
																	|tr = 'Dolduruldu:'"));
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotifyOfAction(ReconciliationDocument, Text)
	
	URL = GetURL(ReconciliationDocument);

	ShowUserNotification(
		Text,
		URL,
		String(ReconciliationDocument),
		PictureLib.Information32);
	
	If AvailableToSaveUserData Then
		UserWorkHistory.Add(URL);
	EndIf; 
	
EndProcedure

#EndRegion

#Region HandlersOfFourthHelperStep

&AtClient
Procedure ReconciliationDocumentListSelection(Item, RowSelected, Field, StandardProcessing)


EndProcedure

&AtClient
Procedure ReconciliationDocumentListOnActivateRow(Item)

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Function PrintingDocuments()
	
	Query = New Query(
	"SELECT
	|	ARAPReconciliation.Ref AS Ref
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation
	|WHERE
	|	ARAPReconciliation.Posted = TRUE
	|	AND ARAPReconciliation.Ref IN(&ReferencesArrray)
	|
	|ORDER BY
	|	ARAPReconciliation.Date,
	|	ARAPReconciliation.Number");
	
	ReferencesArrray = ReconciliationDocumentList.Filter.Items[0].RightValue;
	Query.SetParameter("ReferencesArrray", ReferencesArrray);
	
	Result = Query.Execute().Unload().UnloadColumn("Ref");
	
	Return Result;
	
EndFunction

&AtClient
Procedure SetDeletionMark_(Command)
	
	CallbackDescription = New CallbackDescription("ProcessingResponseAboutMarkingDeletion", ThisObject);
	QueryText = NStr("vi = 'Thay đổi dấu xóa cho các mục được chọn?';
					|ru = 'Изменить пометку удаления для выделенных элементов?';
					|en = 'Invert deletion marks for the selected items?'; fa = 'Invert deletion marks for the selected items?';
					|it = 'Изменить пометку удаления для выделенных элементов?';
					|pl = 'Zmień flagę usuwania dla wybranych elementów?';
					|tr = 'Seçili öğeler için silme işareti değiştirilsin mi?'");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure ProcessingResponseAboutMarkingDeletion(Response, AdditionalParameters) Export
	
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	SetMarkForDeletionOnServer();
	AttachIdleHandler("Attachable_CheckTaskCompletion", 1, True);
	
EndProcedure

&AtServer
Procedure SetMarkForDeletionOnServer()
	
	CancelJobExecution(JobID);
	
	JobDescription = NStr("vi = 'Thay đổi đặt dấu xóa chứng từ ""Biên bản đối chiếu công nợ""';
							|ru = 'Изменение пометки на удаление документов ""Сверка взаиморасчетов""';
							|en = 'Inverting deletion marks'; fa = 'Inverting deletion marks';
							|it = 'Изменение пометки на удаление документов ""Сверка взаиморасчетов""';
							|pl = 'Zmiana znaku do usunięcia dokumentów „Uzgodnienie rozliczeń”';
							|tr = '""Alacak/Borç mutabakatı"" belgelerini silmek için işaretlemenin değiştirilmesi'");
	ProcedureName        = "Documents.ARAPReconciliation2_5_11.SetDeletionMark_";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
	ExecutionParameters.WaitCompletion = 0;
	ExecutionParameters.RunInBackground = True;
	
	MethodParameters = New Structure;
	MethodParameters.Insert("SelectedDocuments_", Items.ReconciliationDocumentList.SelectedRows);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, MethodParameters, ExecutionParameters);
	
	JobID = TimeConsumingOperation.JobID;
	
EndProcedure

&AtClient
Procedure SetDeletionMark_Completion(Result, AdditionalParameters) Export
	
	Items.Next.Enabled = True;
	Items.ReconciliationDocumentList.Refresh();
	
EndProcedure

&AtClient
Procedure GoBackToBegin(Command)
	
	Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3;
	ButtonControlBasement();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// CalculationTableCreateADocument
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationTableCreateADocument.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CalculationTable.CreateADocument");
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CalculationTable.ThereAreDocuments");
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Visible", False);

	// CalculationTableChangeDocument
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CalculationTableChangeDocument.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("CalculationTable.ThereAreDocuments");
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Texts of the field of the tableaccount to change the document
	For Each FieldText In Items.CalculationTableChangeDocument.ChoiceList Do
		
		Item = ConditionalAppearance.Items.Add();

		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.CalculationTableChangeDocument.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("CalculationTable.ChangeDocument");
		ItemFilter.RightValue = FieldText.Value;
		
		Item.Appearance.SetParameterValue("Text", FieldText.Presentation);
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfElementsOnServer()
	
	SettlementsOnFinancialInstrumentsAreAvailable = AccessRight("View", Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
	LoanAndDepositAgreementsAreAvailable = AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts);
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	LeaseAgreementsAreAvailable = AccessRight("View", Metadata.Catalogs.LeaseContract);
	Items.CalculationTableEDIState.Visible = False;
	Items.DebtorARAPAccounting.Visible = False;
	Items.CreditorARAPAccounting.Visible = False;
	Items.LeaseContractARAPWithLessor.Visible = False;
	Items.CardForFinancialInstruments.Visible = False;
	If SettlementsOnFinancialInstrumentsAreAvailable And Not ThisIsBasic Then
		Items.CardForFinancialInstruments.Visible = AccessRight("View", Metadata.Reports.FinancialInstrumentsARAPCard);
		If LoanAndDepositAgreementsAreAvailable Then
			Items.DebtorARAPAccounting.Visible = True;
			Items.CreditorARAPAccounting.Visible = True;
		EndIf;
		If LeaseAgreementsAreAvailable Then
			Items.LeaseContractARAPWithLessor.Visible = True;
		EndIf;
	EndIf;
	
	Items.EDOSubmenu.Visible = Not ThisIsBasic;
	Items.StatusPresentation.Visible = Not ThisIsBasic;
	If ThisIsBasic Then
		Items.DecorationResultTable.Title = NStr("vi = 'Hãy in biên bản đối chiếu';
												|ru = 'Распечатайте акты сверки';
												|en = 'Print AR/AP reconciliations'; fa = 'Print AR/AP reconciliations';
												|it = 'Распечатайте акты сверки';
												|pl = 'Print AR/AP reconciliations';
												|tr = 'Mutabakat raporlarını yazdırın'");
	EndIf;
	
	Items.PartnersARAPAccounting.Visible = ?(
		NewOnlineARAPAccounting,
			AccessRight("View", Metadata.Reports.PartnersARAPAccountingStatement),
			AccessRight("View", Metadata.Reports.PartnersARAPAccounting));
	Items.IntercompanyARAP.Visible = Not ThisIsBasic 
		And ?(NewOnlineARAPAccounting,
				AccessRight("View", Metadata.Reports.AccountsPayablesAndReceivablesByIntercompany),
				AccessRight("View", Metadata.Reports.IntercompanyARAP));
	
	Items.ReconciliationServiceDataGroup20.Visible = ReconciliationServiceIsUsed;
	
EndProcedure

&AtClient
Procedure SettingAvailabilityOfFormElements()

	Items.WizardPages.PagesRepresentation = FormPagesRepresentation.None;
	
	Items.Copies.Enabled = SendDocumentsToPrint;
	Items.PrintSetupDecoration.Enabled = SendDocumentsToPrint;
	
	If Not SendDocumentsToPrint Then
		Copies = 0;
	ElsIf Copies = 0 Then
		Copies = 1;
	EndIf;
	
EndProcedure

&AtClient
Procedure NavigateThroughPages(Command)
	
	ClearMessages();
	Items.Next.Enabled = True;
	If Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3 Then
		
		If Not (CustomerARAPAccounting Or VendorARAPAccounting Or CreditorARAPAccounting Or DebtorARAPAccounting Or LeaseContractARAPWithLessor) Then
			MessageText = NStr("vi = 'Chưa chọn kiểu hạch toán để đối chiếu.';
								|ru = 'Не выбран тип расчетов для сверки.';
								|en = 'Payment type is required.'; fa = 'Payment type is required.';
								|it = 'Не выбран тип расчетов для сверки.';
								|pl = 'Nie wybrano żadnego typu kalkulacji do uzgodnienia.';
								|tr = 'Mutabakat için mutabakat türü seçilmemiştir.'");
			CommonClient.MessageToUser(MessageText, , "CustomerARAPAccounting");
			Return;
		EndIf;
		
		Cancel = False;
		If TypeOf(Counterparty) = Type("CatalogRef.Companies")
			And ValueIsFilled(MainManager) Then
			MessageText = NStr("vi = 'Đã đặt bộ lọc theo người quản lý chính, sẽ không tạo giao dịch đối chiếu giữa các doanh nghiệp.';
								|ru = 'Установлен отбор по основному менеджеру, сверка между организациями не будет создана.';
								|en = 'The filter by employee in charge is set. A reconciliation between companies will not be created.'; fa = 'The filter by employee in charge is set. A reconciliation between companies will not be created.';
								|it = 'Установлен отбор по основному менеджеру, сверка между организациями не будет создана.';
								|pl = 'Jest ustawiony filtr według podstawowego menedżera, uzgodnienie między firmami nie będzie utworzone.';
								|tr = 'Ana yönetici tarafından seçim ayarlandığında, iş yerleri arasında mutabakat oluşturulmayacaktır.'");
			CommonClient.MessageToUser(MessageText, , "MainManager",, Cancel);
		EndIf;

		If Not FinToolsAreUsed Then
			If ModeOfARAPTotalsReconciliation.IsEmpty() Then
				MessageText = NStr("vi = 'Chưa điền chế độ đối chiếu tổng số hạch toán công nợ.';
									|ru = 'Не заполнен режим сверки итогов взаиморасчетов.';
									|en = 'Specify the mode of AR/AP totals reconciliation.'; fa = 'Specify the mode of AR/AP totals reconciliation.';
									|it = 'Не заполнен режим сверки итогов взаиморасчетов.';
									|pl = 'Specify the mode of AR/AP totals reconciliation.';
									|tr = 'Alacak/Borç mutabakatı toplamlarının mutabakat modu doldurulmadı.'");
				CommonClient.MessageToUser(MessageText, , "ModeOfARAPTotalsReconciliation",, Cancel);
			EndIf;
		EndIf;
		If Cancel Then
			Return;
		EndIf;

		
		Items.WizardPages.CurrentPage = Items.SettingPage;
		
	ElsIf Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.SettingPage Then
				
		If DateOfDocumentsInClosedPeriod() Then
			CommonClient.MessageToUser(
				NStr("vi = 'Ngày chứng từ đối chiếu được tạo nhỏ hơn ngày cấm soạn chứng từ';
					|ru = 'Дата формируемых документов сверки меньше даты запрета редактирования документов';
					|en = 'The date of the generated reconciliation documents is less than period-end closing date of editing documents'; fa = 'The date of the generated reconciliation documents is less than period-end closing date of editing documents';
					|it = 'Дата формируемых документов сверки меньше даты запрета редактирования документов';
					|pl = 'The date of the generated reconciliation documents is less than period-end closing date of editing documents';
					|tr = 'Oluşturulan mutabakat belgelerinin tarihi, belgenin dönem sonu kapanış tarihinden küçüktür'"),,
				"DateOfDocuments");
			Return;
		EndIf;
		
		If ParametersFilledIn() Then
			CallbackOnCompletion = New CallbackDescription("FillInCalculationTableEnd", ThisObject);
			RunCallback(CallbackOnCompletion, True);
		EndIf;
		
	ElsIf Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		AskAQuestionAboutClosing = True;
		If ParametersFilledIn() And CalculationTable.Count() > 0 Then
			Items.Next.Enabled = False;
			DocumentsWithoutChanges = CalculationTable.FindRows(New Structure("ChangeDocument", "DontChange"));
			If CalculationTable.Count() = DocumentsWithoutChanges.Count() Then
				MoveDocumentsToResult();
			ElsIf CalculationTable.Count() > 0 Then
				CreateInBackgroundJobOnServer();
				AttachIdleHandler("Attachable_CheckTaskCompletion", 0.3, True);
			Else
				ShowResultPage(New Array);
			EndIf;
		EndIf;


	ElsIf Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.ResultPage Then

		If SendDocumentsToPrint Then
			
			ArrayOfDocumentsToPrint = PrintingDocuments();
			
			TemplatesNames = "APARAccountsReconciliationStatement";
			For IndexOf = 2 To Copies Do
				TemplatesNames = TemplatesNames + ",APARAccountsReconciliationStatement";
			EndDo;
			
			PrintManagementClient.ExecutePrintCommand(
				"Document.ARAPReconciliation2_5_11",
				TemplatesNames,
				ArrayOfDocumentsToPrint,
				Undefined,
				Undefined);
			
		EndIf;
		Notify("ReconciliationCreatedByAssistant2_5_11");
		Close();
		
	ElsIf Command.Name = "Back"
		And Items.WizardPages.CurrentPage = Items.ResultPage Then
		
		Items.WizardPages.CurrentPage = Items.CalculationTablePage;
		
	ElsIf Command.Name = "Back"
		And Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		Items.WizardPages.CurrentPage = Items.SettingPage;
		CalculationTable.Clear();
		
	ElsIf Command.Name = "Back"
		And Items.WizardPages.CurrentPage = Items.SettingPage Then
		
		Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3;
			
	ElsIf Command.Name = "Cancel" Then
		
		Close();
		
	EndIf;
	
	ButtonControlBasement();
	
EndProcedure

&AtClient
Function ParametersFilledIn()
	
	Cancel = False;
	ClearMessages();
	
	If Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3 Then
		If Not ValueIsFilled(ReconciliationPeriod.EndDate) Then
			MessageText = NStr("vi = 'Chưa chỉ ra cuối kỳ đối chiếu.';
								|ru = 'Не указано окончание периода сверки.';
								|en = 'Reconciliation end date is not specified.'; fa = 'Reconciliation end date is not specified.';
								|it = 'Не указано окончание периода сверки.';
								|pl = 'Reconciliation end date is not specified.';
								|tr = 'Mutabakat döneminin bitişi belirtilmedi.'");
			CommonClient.MessageToUser(MessageText, ,"ReconciliationPeriod", , Cancel);
		EndIf;
	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		RecalculateNumberOfRowsInCalculationTable();
		
		If WillBeCreated = 0 And WillBeRefilled = 0 Then
			MessageText = NStr("vi = 'Chưa đánh dấu dòng nào để tạo mới hoặc điền lại.';
								|ru = 'Не отмечена ни одна строка для создания или перезаполнения.';
								|en = 'No lines to create or refill are selected.'; fa = 'No lines to create or refill are selected.';
								|it = 'Не отмечена ни одна строка для создания или перезаполнения.';
								|pl = 'No lines to create or refill are selected.';
								|tr = 'Oluşturma veya yeniden doldurma için herhangi bir satır işaretlenmedi.'");
			CommonClient.MessageToUser(MessageText, ,"CalculationTable", , Cancel);
		EndIf;
	ElsIf Items.WizardPages.CurrentPage = Items.SettingPage Then
		If Not ValueIsFilled(DateOfDocuments) Then
			MessageText = NStr("vi = 'Đã chỉ ra ngày chứng từ trống.';
								|ru = 'Указана пустая дата документов.';
								|en = 'Empty document date is specified.'; fa = 'Empty document date is specified.';
								|it = 'Указана пустая дата документов.';
								|pl = 'Empty document date is specified.';
								|tr = 'Belgelerin boş tarihi belirtildi.'");
			
			CommonClient.MessageToUser(MessageText, ,"DateOfDocuments", , Cancel);
		EndIf;
	EndIf;
	
	Return Not Cancel;
	
EndFunction

&AtClient
Procedure ButtonControlBasement()
	
	Items.Back.Visible = True;
	Items.Cancel.Visible = True;
	Items.GoBackToBegin.Visible = False;
	TextNext = NStr("vi = 'Tiếp theo';
					|ru = 'Далее';
					|en = 'Next'; fa = 'بعدی';
					|it = 'Далее';
					|pl = 'Dalej';
					|tr = 'İleri'");
	TextBack = NStr("vi = 'Quay lại';
					|ru = 'Назад';
					|en = 'Back'; fa = 'بازگشت';
					|it = 'Назад';
					|pl = 'Wróć';
					|tr = 'Geri'");
	If Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3 Then
		
		Items.Next.Title = TextNext + " >>";
		Items.Back.Title = TextBack;
		Items.Back.Visible = False;

	ElsIf Items.WizardPages.CurrentPage = Items.SettingPage Then
		
		Items.Next.Title = TextNext + " >>";
		Items.Back.Title = "<< " + TextBack;

	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		Items.Next.Title = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Выполнить';
								|pl = 'Wykonaj';
								|tr = 'Yürüt'");
		Items.Back.Title = "<< " + TextBack;

	ElsIf Items.WizardPages.CurrentPage = Items.ResultPage Then
		
		Items.Next.Title = NStr("vi = 'Hoàn thành';
								|ru = 'Завершить';
								|en = 'Complete'; fa = 'تکمیل';
								|it = 'Завершить';
								|pl = 'Zakończ';
								|tr = 'Tamamla'");
		Items.Back.Title = "<< " + TextBack;
		Items.Cancel.Visible = False;
		Items.GoBackToBegin.Visible = True;

	EndIf;
	
EndProcedure

&AtClient
Procedure SetActionWithExistingDocument(Val CommandName)
	
	If Items.CalculationTable.SelectedRows.Count() > 1 Then
		For Each ID In Items.CalculationTable.SelectedRows Do
			Page1 = CalculationTable.FindByID(ID);
			If Page1 <> Undefined And Page1.ThereAreDocuments Then
				Page1.ChangeDocument = CommandName;
			EndIf;
		EndDo;
	Else
		For Each Page1 In CalculationTable Do
			If Page1.ThereAreDocuments Then
				Page1.ChangeDocument = CommandName;
			EndIf;
		EndDo;
	EndIf;
	RecalculateNumberOfRowsInCalculationTable();
	
EndProcedure

&AtClient
Procedure SetActionWithNewDocument(Val CommandName)
	
	If Items.CalculationTable.SelectedRows.Count() > 1 Then
		For Each ID In Items.CalculationTable.SelectedRows Do
			Page1 = CalculationTable.FindByID(ID);
			If Page1 <> Undefined And Not Page1.ThereAreDocuments Then
				Page1.CreateADocument = CommandName = "Create";
			EndIf;
		EndDo;
	Else
		For Each Page1 In CalculationTable Do
			If Not Page1.ThereAreDocuments Then
				Page1.CreateADocument = CommandName = "Create";
			EndIf;
		EndDo;
	EndIf;
	RecalculateNumberOfRowsInCalculationTable();
	
EndProcedure

&AtServer
Function ParametersOfExtendedSelectionForm()
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
	If FilterContractsWithoutTurnover = Undefined Then
		FinancialReportingServer.SetFilter(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover", True);
		FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
		FilterContractsWithoutTurnover.Presentation = NStr("vi = 'Bao gồm hợp đồng không có phát sinh trong kỳ';
															|ru = 'Включать договора без оборотов в периоде';
															|en = 'Include contracts without cash transactions during the given period'; fa = 'Include contracts without cash transactions during the given period';
															|it = 'Включать договора без оборотов в периоде';
															|pl = 'Uwzględnij umowy bez obrotu w tym okresie';
															|tr = 'Cirosu olmayan sözleşmeleri döneme dahil edin'");
	EndIf;
	FilterContractsWithoutTurnover.Use = ContractsWithoutTurnover;
	
	SetBasicSelections();
	
	OpeningParameters = New Structure;
	OpeningParameters.Insert("Filter_Settings", LinkerSelection.GetSettings());
	OpeningParameters.Insert("HideServiceSelections", False);
	OpeningParameters.Insert("ThisIsReconciliationBetweenOrganizations", ThisIsReconciliationBetweenOrganizations);
	
	Return OpeningParameters;
	
EndFunction

&AtServer
Procedure SetBasicSelections(SettingsComposer = Undefined)
	
	If SettingsComposer = Undefined Then
		SettingsComposer = LinkerSelection;
	EndIf;
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(SettingsComposer.Settings.Filter, "ContractsWithoutTurnover");
	FilterContractsWithoutTurnover.Use = ContractsWithoutTurnover;
	
	SetComposerSelection("Organization", Organization, SettingsComposer);
	SetComposerSelection("Counterparty", Counterparty, SettingsComposer);
	SetComposerSelection("MainManager", MainManager, SettingsComposer);
	
	#Region SelectionByTypeOfCalculations
	ListOfCalculations_ = New ValueList();
	If CustomerARAPAccounting Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	EndIf;
	
	If VendorARAPAccounting Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting);
	EndIf;
	
	If CreditorARAPAccounting Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting);
	EndIf;
	
	If DebtorARAPAccounting Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting);
	EndIf;
	
	If LeaseContractARAPWithLessor Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor);
	EndIf;
	
	TypeOfComparisonOfCalculationType = DataCompositionComparisonType.InList;
	If ListOfCalculations_.Count() = 1 Then
		TypeOfComparisonOfCalculationType = DataCompositionComparisonType.Equal;
		ListOfCalculations_ = ListOfCalculations_[0].Value;
	EndIf;
	DataCompositionClientServer.AddFilter(
		LinkerSelection,
		"PaymentType_",
		ListOfCalculations_,
		TypeOfComparisonOfCalculationType,
		ValueIsFilled(ListOfCalculations_));
	#EndRegion
	
EndProcedure

&AtServer
Procedure SetComposerSelection(FilterName, FilterValue, SettingsComposer = Undefined)
	
	If SettingsComposer = Undefined Then
		SettingsComposer = LinkerSelection;
	EndIf;
	
	FilterElement = FinancialReportingServer.FindSelectionElement(SettingsComposer.Settings.Filter, FilterName);
	
	If FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties") Then
		If TypeOf(FilterValue) = Type("CatalogRef.Companies") Then
			FilterElement = FinancialReportingServer.FindSelectionElement(
				SettingsComposer.Settings.Filter, "CompanyCounterparty");
		Else
			FilterElement = FinancialReportingServer.FindSelectionElement(SettingsComposer.Settings.Filter, "Partner");
		EndIf;
	EndIf;
	
	If FilterElement = Undefined And Not ValueIsFilled(FilterValue) Then
		Return;
	EndIf;
	
	If ValueIsFilled(FilterValue)
		Or (Not ValueIsFilled(FilterValue)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal) Then
		
		If FilterName = "Counterparty"
			And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			If TypeOf(FilterValue) = Type("CatalogRef.Counterparties") Then
				Partner = Common.ObjectAttributeValue(FilterValue, "Partner");
				DataCompositionClientServer.AddFilter(SettingsComposer, "Partner", Partner, , ValueIsFilled(Partner));
				DataCompositionClientServer.AddFilter(SettingsComposer, "CompanyCounterparty", , , False);
			Else
				DataCompositionClientServer.AddFilter(SettingsComposer,
					"CompanyCounterparty",
					FilterValue,
					,
					ValueIsFilled(FilterValue));
				DataCompositionClientServer.AddFilter(SettingsComposer, "Partner", , , False);
			EndIf;
			
		Else
			DataCompositionClientServer.AddFilter(SettingsComposer,
				FilterName,
				FilterValue,
				,
				ValueIsFilled(FilterValue));
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateSelectionsOnForm()
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
	ContractsWithoutTurnover = FilterContractsWithoutTurnover.Use;
	
	SetTypeOfCalculationsOnForm();
	SetSelectionOnForm("Organization");
	SetSelectionOnForm("Counterparty");
	SetSelectionOnForm("MainManager");
	
	ThisIsReconciliationBetweenOrganizations = TypeOf(Counterparty) = Type("CatalogRef.Companies");
	If ThisIsReconciliationBetweenOrganizations Then
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Companies");
	Else
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
	EndIf;
	
	UpdateSelectionHyperlink(Items.SetFilterSettings, LinkerSelection.Settings.Filter);
	
EndProcedure

&AtServer
Procedure UpdateSelectionHyperlink(AdvancedSelectionButton, Filter)
	
	VisibleLineSelections = "ContractsWithoutTurnover,PaymentType_,Organization,Counterparty,MainManager";
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		VisibleLineSelections = StrReplace(VisibleLineSelections, "Counterparty", "Partner");
	EndIf;
	VisibleSelections = StrSplit(VisibleLineSelections, ",");
	VisibleSelections.Add("CompanyCounterparty");
	AdvancedSelectionIsInstalled = False;
	AdvancedSelectionButton.Title = NStr("vi = 'Bộ lọc nâng cao';
										|ru = 'Расширенный отбор';
										|en = 'Advanced filter'; fa = 'فیلتر پیشرفته';
										|it = 'Расширенный отбор';
										|pl = 'Rozszerzony filtr';
										|tr = 'Gelişmiş filtre'");
	AdvancedSelectionButton.TextColor = New Color;
	
	AdvancedSelectionIsInstalled = AdvancedSelectionIsInstalled(VisibleSelections, LinkerSelection.Settings.Filter.Items);
	If AdvancedSelectionIsInstalled Then
		AdvancedSelectionButton.Title = NStr("vi = 'Đã đặt bộ lọc nâng cao';
											|ru = 'Установлен расширенный отбор';
											|en = 'Advanced filter is applied'; fa = 'Advanced filter is applied';
											|it = 'Установлен расширенный отбор';
											|pl = 'Ustawiono zaawansowany wybór';
											|tr = 'Gelişmiş filtre oluşturuldu'");
		AdvancedSelectionButton.TextColor = StyleColors.TextColorSuccess;
	EndIf;
	
EndProcedure

&AtServer
Function AdvancedSelectionIsInstalled(VisibleSelections, FilterItems1)
	
	For Each FilterElement In FilterItems1 Do
		
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			If AdvancedSelectionIsInstalled(VisibleSelections, FilterElement.Items) Then
				Return True;
			EndIf;
			Continue;
		EndIf;
		
		Visible = VisibleSelections.Find(String(FilterElement.LeftValue)) <> Undefined;
		VisibleSelectionChanged = Visible And FilterElement.ComparisonType <> DataCompositionComparisonType.Equal
								And String(FilterElement.LeftValue) <> "PaymentType_";
		
		If FilterElement.Use And (VisibleSelectionChanged Or Not Visible) Then
			Return True;
		EndIf;
		
	EndDo;
	
	Return False;
	
EndFunction

&AtServer
Procedure SetTypeOfCalculationsOnForm()
	
	SelectionFlags = FlagsForCalculationTypes();
	
	FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "PaymentType_");
	SelectionSet = FilterElement <> Undefined And FilterElement.Use;
	For Each FlagOfSelection In SelectionFlags Do
		
		ThisObject[FlagOfSelection.Value] = False;
		If SelectionSet Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				IsInList = FilterElement.RightValue.FindByValue(FlagOfSelection.Key) <> Undefined;
				ThisObject[FlagOfSelection.Value] = IsInList;
			ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.Equal Then
				ThisObject[SelectionFlags[FilterElement.RightValue]] = True;
			EndIf;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure SetPassedParameters(Settings)
	
	If ValueIsFilled(Parameters.BeginOfPeriod) Then
		Settings["ReconciliationPeriod"].Variant = StandardPeriodVariant.Custom;
		Settings["ReconciliationPeriod"].StartDate = Parameters.BeginOfPeriod;
		BeginOfPeriod = Parameters.BeginOfPeriod;
	EndIf;
	If ValueIsFilled(Parameters.EndOfPeriod) Then
		Settings["ReconciliationPeriod"].Variant = StandardPeriodVariant.Custom;
		Settings["ReconciliationPeriod"].EndDate = Parameters.EndOfPeriod;
		EndOfPeriod = Parameters.EndOfPeriod;
	EndIf;
	If Parameters.ContractsWithoutTurnover Then
		FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
		FilterContractsWithoutTurnover.Use = True;
	EndIf;
	If ValueIsFilled(Parameters.Organization) And GetFunctionalOption("UseMultipleCompanies")Then
		FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "Organization");
		FilterElement.Use = True;
		FilterElement.RightValue = Parameters.Organization;
	EndIf;
	If ValueIsFilled(Parameters.Counterparty) Then
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Documents.ARAPReconciliation2_5_11.CompletePartnerSelectionByCounterparty(LinkerSelection.Settings.Filter, Parameters.Counterparty);
		Else
			FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "Counterparty");
			FilterElement.Use = True;
			If TypeOf(Parameters.Counterparty) = Type("ValueList") Then
				FilterElement.ComparisonType = DataCompositionComparisonType.InList;
			Else
				FilterElement.ComparisonType = DataCompositionComparisonType.Equal;
			EndIf;
			FilterElement.RightValue = Parameters.Counterparty;
		EndIf;
	EndIf;
	If ValueIsFilled(Parameters.MainManager) Then
		FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "MainManager");
		If FilterElement <> Undefined Then
			FilterElement.Use = True;
			FilterElement.RightValue = Parameters.MainManager;
		EndIf;
	EndIf;
	If Parameters.TypesOfCalculations_.Count() > 0 Then
		SetTransmittedPaymentTypes(Settings);
	EndIf;
	
	UpdateSelectionsOnForm();
	
EndProcedure

&AtServer
Procedure SetTransmittedPaymentTypes(Settings)
	
	FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "PaymentType_");
	FilterElement.Use = False;
	FilterElement.RightValue = Parameters.TypesOfCalculations_;
	For Each FlagOfSelection In FlagsForCalculationTypes() Do
		ThereIsTypeOfCalculations = Parameters.TypesOfCalculations_.FindByValue(FlagOfSelection.Key) <> Undefined;
		Settings[FlagOfSelection.Value] = ThereIsTypeOfCalculations;
		FilterElement.Use = FilterElement.Use Or ThereIsTypeOfCalculations;
	EndDo;
	
EndProcedure

&AtServer
Function FlagsForCalculationTypes()
	
	SelectionFlags = New Map;
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, "CustomerARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting, "VendorARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting, "CreditorARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting, "DebtorARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor, "LeaseContractARAPWithLessor");
	
	Return SelectionFlags;
	
EndFunction

&AtServer
Procedure SetSelectionOnForm(FilterName)
	
	FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, FilterName);
	If FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties") Then
		FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "Partner");
	EndIf;
	ThisObject[FilterName] = Undefined;
	Item = Items[FilterName]; // FormField - 
	Item.Enabled = True;
	Item.InputHint = NStr("vi = 'Hãy chỉ ra giá trị lọc';
							|ru = 'Укажите значение отбора';
							|en = 'Specify the filter value'; fa = 'Specify the filter value';
							|it = 'Укажите значение отбора';
							|pl = 'Wprowadź wartość filtru';
							|tr = 'Seçimin anlamını belirtin'");
	
	If FilterElement <> Undefined Then
		
		If FilterElement.ComparisonType = DataCompositionComparisonType.Equal And FilterElement.Parent = Undefined Then
			If FilterElement.Use Then
				ThisObject[FilterName] = FilterElement.RightValue;
				If FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties")
					And TypeOf(FilterElement.RightValue) = Type("CatalogRef.Partners") Then
					Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(FilterElement.RightValue);
					ThisObject[FilterName] = Counterparty;
				EndIf;
			ElsIf FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties") Then
				FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "CompanyCounterparty");
				If FilterElement <> Undefined
					And FilterElement.Use 
					And FilterElement.ComparisonType = DataCompositionComparisonType.Equal 
					And FilterElement.Parent = Undefined Then
					ThisObject[FilterName] = FilterElement.RightValue;
				EndIf;
			EndIf;
			
		ElsIf FilterElement.ComparisonType = DataCompositionComparisonType.InList And FilterElement.Parent = Undefined Then
			If FilterElement.Use Then
				If FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties")
					And TypeOf(FilterElement.RightValue) = Type("ValueList")
					And TypeOf(FilterElement.RightValue[0]) = Type("CatalogRef.Partners") Then
					For Each ListItem In FilterElement.RightValue Do
						If TypeOf(ListItem.Value) = Type("CatalogRef.Partners") Then
							Counterparty = PartnersAndCounterparties.GetPartnerSDefaultCounterparty(ListItem.Value);
							ListItem.Value = Counterparty;
						EndIf;
					EndDo;
				EndIf;
				Item = Items[FilterName]; // FormField - 
				Item.Enabled = False;
				Item.InputHint = NStr("vi = 'Đã đặt bộ lọc nâng cao';
										|ru = 'Установлен расширенный отбор';
										|en = 'Advanced filter is applied'; fa = 'Advanced filter is applied';
										|it = 'Установлен расширенный отбор';
										|pl = 'Ustawiono zaawansowany wybór';
										|tr = 'Gelişmiş filtre oluşturuldu'");
			EndIf;
		Else
			
			ElementInSelectionGroupUsed = FilterElement.Parent <> Undefined And FilterElement.Parent.Use;
			If FilterElement.Use Or ElementInSelectionGroupUsed Then
				Item = Items[FilterName]; // FormField - 
				Item.Enabled = False;
				Item.InputHint = NStr("vi = 'Đã đặt bộ lọc nâng cao';
										|ru = 'Установлен расширенный отбор';
										|en = 'Advanced filter is applied'; fa = 'Advanced filter is applied';
										|it = 'Установлен расширенный отбор';
										|pl = 'Ustawiono zaawansowany wybór';
										|tr = 'Gelişmiş filtre oluşturuldu'");
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)

	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.ReconciliationDocumentList);

EndProcedure

&AtClient
Procedure BeforeClosingQuestionEnds(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		AskAQuestionAboutClosing = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure AddSelectionElementToSelection(FilterReceiver, FilterElement)
	NewItem = FilterReceiver.Items.Add(Type("DataCompositionFilterItem"));
	FillPropertyValues(NewItem,FilterElement);
EndProcedure

&AtClient
Procedure AddGroupOfSelectionElementsToSelection(FilterReceiver, Items_Group)
	
	NewFolder = FilterReceiver.Items.Add(Type("DataCompositionFilterItemGroup"));
	FillPropertyValues(NewFolder,Items_Group);
	
	For Each FilterElement In Items_Group.Items Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItem") Then
			AddSelectionElementToSelection(NewFolder, FilterElement);
		Else
			AddGroupOfSelectionElementsToSelection(NewFolder, FilterElement);
		EndIf;
	EndDo;
EndProcedure

&AtClient
Procedure SetFilterSettingsCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	LinkerSelection.LoadSettings(Result.Filter_Settings);
	UpdateSelectionsOnForm();
	
EndProcedure

&AtClient
Procedure SetTheStatusOnReconciliationCompletion(QuestionResult, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;

	Response = QuestionResult;
	If Response <> DialogReturnCode.Yes Then
		Return;
	EndIf;

	ClearMessages();
	ProcessedItemsCount = GeneralPurposeTMServerCall.SetStatusOfDocuments(SelectedRows, "OnReconciliation");
	TMCommonUseClient.NotifyUserAboutSettingStatus(Items.ReconciliationDocumentList, ProcessedItemsCount, SelectedRows.Count(), NStr("vi = 'Đang đối chiếu';
																																	|ru = 'На сверке';
																																	|en = 'In reconciliation'; fa = 'در حال تطبیق';
																																	|it = 'На сверке';
																																	|pl = 'Na weryfikacji';
																																	|tr = 'Mutabakatta'"));
	Items.ReconciliationDocumentList.Refresh();

EndProcedure

&AtClient
Procedure SetPeriodIntervalCompletion(Period, AdditionalParameters) Export 
	
	ReconciliationPeriod.Variant = StandardPeriodVariant.Custom;
	ReconciliationPeriod.StartDate = BeginOfPeriod;
	ReconciliationPeriod.EndDate = EndOfDay(EndOfPeriod);
	
EndProcedure

&AtServer
Function DateOfDocumentsInClosedPeriod()
	
	DocObject = Documents.ARAPReconciliation2_5_11.CreateDocument();
	DocObject.Date = DateOfDocuments;
	ThereIsBan = PeriodClosingDates.DataChangesDenied(DocObject);
	Return ThereIsBan;
	
EndFunction

#Region MaintenanceOfLongOperations

&AtClient
Procedure Attachable_CheckTaskCompletion()
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	If ValueIsFilled(JobID) And JobCompleted(JobID) Then 
		IdleParameters.OutputIdleWindow = False;
		Items.ReconciliationDocumentList.Refresh();
	EndIf;
	
	If Items.WizardPages.CurrentPage = Items.SettingPage Then
		CallbackOnCompletion = New CallbackDescription("FillInCalculationTableEnd", ThisObject);
	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		CallbackOnCompletion = New CallbackDescription("CreateDocumentsCompletion", ThisObject);
	ElsIf Items.WizardPages.CurrentPage = Items.ResultPage Then
		CallbackOnCompletion = New CallbackDescription("SetDeletionMark_Completion", ThisObject);
	EndIf;
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServerNoContext
Function JobCompleted(JobID)
	
	Return TimeConsumingOperations.JobCompleted(JobID);
	
EndFunction

&AtServer
Procedure CancelJobExecution(JobID)
	
	If ValueIsFilled(JobID) Then
		TimeConsumingOperations.CancelJobExecution(JobID);
		JobID = Undefined;
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion
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
	If Item.Name = "sh_ShamsiInput_F_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
	ElsIf Item.Name = "sh_ShamsiInput_F_EndOfPeriod" Then
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
