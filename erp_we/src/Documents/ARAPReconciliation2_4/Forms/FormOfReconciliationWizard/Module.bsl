
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If GetFunctionalOption("BaseVersion") Then
		Items.Counterparty.TypeRestriction = New TypeDescription("CatalogRef.Counterparties");
		Items.IntercompanyARAP.Visible = False;
	EndIf;
	
	SetConditionalAppearance();
	SettlementsOnFinancialInstrumentsAreAvailable = AccessRight("View", Metadata.AccumulationRegisters.FinancialInstrumentsARAP);
	LoanAndDepositAgreementsAreAvailable = AccessRight("View", Metadata.Catalogs.LoanAndDepositContracts);
	LeaseAgreementsAreAvailable = False;
	LeaseAgreementsAreAvailable = AccessRight("View", Metadata.Catalogs.LeaseContract);
	Items.DebtorARAPAccounting.Visible = False;
	Items.CreditorARAPAccounting.Visible = False;
	Items.LeaseContractARAPWithLessor.Visible = False;
	If SettlementsOnFinancialInstrumentsAreAvailable Then
		If LoanAndDepositAgreementsAreAvailable Then
			Items.DebtorARAPAccounting.Visible = True;
			Items.CreditorARAPAccounting.Visible = True;
		EndIf;
		If LeaseAgreementsAreAvailable Then
			Items.LeaseContractARAPWithLessor.Visible = True;
		EndIf;
	EndIf;
	
	Documents.ARAPReconciliation2_4.InitializeSettingsComposer(LinkerSelection, UUID);
	
	ReconciliationPeriod.Variant = StandardPeriodVariant.LastMonth;
	
	DateOfDocuments = CurrentSessionDate();
	
	NewOnlineARAPAccounting = GetFunctionalOption("NewOnlineARAPAccounting");
	
	AvailableToSaveUserData = AccessRight("SaveUserData", Metadata);

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	PartnersAndCounterparties.HeaderOfPropsDependingOnFOUsePartnersAsCounterparties(
		ThisObject, "PartnersARAPAccounting", NStr("vi = 'Mở báo cáo ""Hạch toán với đối tác"":';
													|ru = 'Открыть отчет ""Расчеты с контрагентами"":';
													|en = 'Open the ""Settlements with counterparties"" report:'; fa = 'Open the ""Settlements with counterparties"" report:';
													|it = 'Открыть отчет ""Расчеты с контрагентами"":';
													|pl = 'Otwórz raport ""Rozliczenia z kontrahentami"":';
													|tr = '""Cari hesap ödemeleri"" raporunu aç:'"));

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	SettingAvailabilityOfFormElements();
	
	ButtonControlBasement();
	
EndProcedure

&AtServer
Procedure OnSaveDataInSettingsAtServer(Settings)
	
	Common.CommonSettingsStorageSave(
		Documents.ARAPReconciliation2_4.UserSettingsObjectKey(),
		"Filter_Settings",
		LinkerSelection.GetSettings());
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	Filter_Settings = Common.CommonSettingsStorageLoad(
							Documents.ARAPReconciliation2_4.UserSettingsObjectKey(),
							"Filter_Settings");
	
	If Filter_Settings <> Undefined Then
		DataCompositionClientServer.CopyElements(LinkerSelection.Settings.Filter, Filter_Settings.Filter);
		If GetFunctionalOption("UsePartnersAsCounterparties") Then
			Documents.ARAPReconciliation2_4.CompletePartnerSelectionByCounterparty(LinkerSelection.Settings.Filter);
		EndIf;
		UpdateSelectionsOnForm();
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

&AtClient
Procedure BeforeClosingQuestionEnds(Result, AdditionalParameters) Export 
	
	If Result = DialogReturnCode.Yes Then
		AskAQuestionAboutClosing = False;
		Close();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ReconciliationPeriodOptionOnChange(Item)
	
	SettingAvailabilityOfFormElements();
		
EndProcedure

&AtClient
Procedure SendDocumentsToPrintOnChange(Item)
	
	SettingAvailabilityOfFormElements();
	
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
		ThisForm,
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
		
		If CustomersARAPAccounting Then
			FormParameters.VariantKey = "SalesPayments";
			FormParameters.Filter.Insert("Seller", Organization);
			If ValueIsFilled(Counterparty) Then
				FormParameters.Filter.Insert("Customer", Counterparty);
			EndIf;
		ElsIf VendorsARAPAccounting Then
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
		ThisForm,
		True); 
	
EndProcedure

&AtClient
Procedure AddSelectionElementToSelection(FilterReceiver,FilterElement)
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
	OpenForm("Document.ARAPReconciliation2_4.Form.AdvancedFilter",
	            OpeningParameters,
	            ThisForm,
	            ,
	            ,
	            , 
	            CloseHandler,
                FormWindowOpeningMode.LockOwnerWindow);
	
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
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

#Region HandlersOfFirstStepOfHelper

&AtServer
Procedure FillInCalculationTable()
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "BeginOfPeriod", ReconciliationPeriod.StartDate);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "EndOfPeriod", EndOfDay(ReconciliationPeriod.EndDate));
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "Period", ReconciliationPeriod.StartDate);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "ReceiveReconciliationDocuments", True);
	
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByARAPTypes", SplitByARAPTypes);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByPartners", SplitByPartners);
	DataCompositionClientServer.SetParameter(LinkerSelection.Settings, "SplitByContracts", SplitByContracts);
	
	SetBasicSelections();
	
	DCSResultTable = Documents.ARAPReconciliation2_4.GetSettlements(LinkerSelection);
	
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
			
		DCSResultTable.GroupBy(Groups);
		If SplitByARAPTypes Then
			Groups = StrReplace(Groups, "PaymentType_, ", "");
		EndIf;
		DCSResultTable.Sort(Groups);
		CalculationTable.Load(DCSResultTable);
	EndIf;

EndProcedure

&AtServer
Function ThereAreTasksForDistribution()
	
	DimensionToCalculation = Documents.ARAPReconciliation2_4.DimensionToCalculation(
							Organization, Counterparty, Undefined, EndOfDay(ReconciliationPeriod.EndDate));
	HasJobs = DimensionToCalculation.Count() > 0;
	
	If HasJobs Then
		CancelJobExecution(JobID);
		
		JobDescription = NStr("vi = 'Đang tiến hành phân bổ hạch toán theo chứng từ.';
								|ru = 'Выполняется распределение расчетов по документам.';
								|en = 'Allocating settlements by documents...'; fa = 'Allocating settlements by documents...';
								|it = 'Выполняется распределение расчетов по документам.';
								|pl = 'Jest wykonywany podział rozliczeń według dokumentów.';
								|tr = 'Hesaplamaların belgeler üzerinde dağıtımını gerçekleştirir.'");
		ProcedureName        = "Documents.ARAPReconciliation2_4.DistributionOfCalculationsByDocuments";
		
		ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
		ExecutionParameters.BackgroundJobDescription = JobDescription;
		ExecutionParameters.WaitCompletion = 0;
		ExecutionParameters.RunInBackground = True;
		
		Companies = Undefined;
		If ValueIsFilled(Organization) Then
			Companies = CommonClientServer.ValueInArray(Organization);
		EndIf;
		StructureOfCalculations = New Structure("AccountingAnalyticsForPartners, Companies", DimensionToCalculation, Companies);
		
		MethodParameters = New Structure;
		MethodParameters.Insert("CalculationAnalysts", StructureOfCalculations);
		MethodParameters.Insert("EndOfPeriod", EndOfDay(ReconciliationPeriod.EndDate));
		
		TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, MethodParameters, ExecutionParameters);
		
		JobID = TimeConsumingOperation.JobID;
	EndIf;
	
	Return HasJobs;
	
EndFunction

&AtClient
Procedure FillInCalculationTableEnd(Result, AdditionalParameters) Export
	
	FillInCalculationTable();
	RecalculateNumberOfRowsInCalculationTable();
	Items.CalculationTablePaymentType_.Visible = SplitByARAPTypes;
	Items.CalculationTablePartner.Visible = SplitByPartners;
	Items.CalculationTableContract.Visible = SplitByContracts;
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
		
		If  CalculationTableRow.CreateADocument  Then
			
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

&AtClient
Procedure PrintSetupDecorationClick(Item)
	
	OpenForm(
		"Document.ARAPReconciliation2_4.Form.PrintSettings",, 
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
		
EndProcedure

#EndRegion

#Region HandlersOfThirdHelperStep

&AtServer
Procedure CreateInBackgroundJobOnServer()
	
	CancelJobExecution(JobID);
	
	JobDescription = NStr("vi = 'Tạo chứng từ ""Biên bản đối chiếu công nợ""';
							|ru = 'Создание документов ""Сверка взаиморасчетов""';
							|en = 'Creating AR/AP reconciliation'; fa = 'Creating AR/AP reconciliation';
							|it = 'Создание документов ""Сверка взаиморасчетов""';
							|pl = 'Tworzenie dokumentów „Uzgodnienie rozliczeń”';
							|tr = 'Alacak/Borç mutabakatı"" belgelerinin oluşturulması'");
	ProcedureName        = "Documents.ARAPReconciliation2_4.CreateDocuments";
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = JobDescription;
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
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteInBackground(ProcedureName, MethodParameters, ExecutionParameters);
	
	JobID = TimeConsumingOperation.JobID;

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

	CommonClientServer.SetDynamicListFilterItem(
		ReconciliationDocumentList, "Ref", CreationResult.ArrayOfAllReconciliationDocuments, DataCompositionComparisonType.InList);
	
	ResultingText = NStr("vi = 'Đã tạo %CreatedItemsCount% trong số %TotalCount1% chứng từ';
						|ru = 'Создано %CreatedItemsCount% из %TotalCount1% документов';
						|en = 'Created: %CreatedItemsCount% out of %TotalCount1%'; fa = 'Created: %CreatedItemsCount% out of %TotalCount1%';
						|it = 'Создано %CreatedItemsCount% из %TotalCount1% документов';
						|pl = 'Utworzono %CreatedItemsCount% z %TotalCount1% dokumentów';
						|tr = '%TotalCount1% belgeden %CreatedItemsCount%oluşturuldu'");
	ResultingText = StrReplace(ResultingText, "%CreatedItemsCount%", CreatedItemsCount);
	ResultingText = StrReplace(ResultingText, "%TotalCount1%",     NumberOfSelected);
	
	Items.DecorationResult.Title = ResultingText;
	
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
// 	ProtocolString - See Documents.ARAPReconciliation2_4.ProtocolString
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

&AtServer
Function PrintingDocuments()
	
	Query = New Query(
	"SELECT
	|	ARAPReconciliation.Ref AS Ref
	|FROM
	|	Document.ARAPReconciliation2_4 AS ARAPReconciliation
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
	QueryText = NStr("vi = 'Thay đổi dấu xóa đối với các phần tử được chọn?';
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
	
	JobDescription = NStr("vi = 'Thay đổi đánh dấu xóa chứng từ ""Biên bản đối chiếu công nợ""';
							|ru = 'Изменение пометки на удаление документов ""Сверка взаиморасчетов""';
							|en = 'Inverting deletion marks'; fa = 'Inverting deletion marks';
							|it = 'Изменение пометки на удаление документов ""Сверка взаиморасчетов""';
							|pl = 'Zmiana znaku do usunięcia dokumentów „Uzgodnienie rozliczeń”';
							|tr = '""Alacak/Borç mutabakatı"" belgelerini silmek için işaretlemenin değiştirilmesi'");
	ProcedureName        = "Documents.ARAPReconciliation2_4.SetDeletionMark_";
	
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

&AtClient
Procedure SettingAvailabilityOfFormElements()

	Items.WizardPages.PagesRepresentation = FormPagesRepresentation.None;
	
	ArbitraryPeriodIsSelected = (ReconciliationPeriod.Variant = StandardPeriodVariant.Custom);
	Items.ReconciliationPeriodStartDate.Enabled    = ArbitraryPeriodIsSelected;
	Items.ReconciliationPeriodEndDate.Enabled = ArbitraryPeriodIsSelected;
	
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
		
		If Not (CustomersARAPAccounting Or VendorsARAPAccounting Or CreditorARAPAccounting Or DebtorARAPAccounting Or LeaseContractARAPWithLessor) Then
			MessageText = NStr("vi = 'Không có loại tính toán được chọn để đối chiếu.';
								|ru = 'Не выбран тип расчетов для сверки.';
								|en = 'Payment type is required.'; fa = 'Payment type is required.';
								|it = 'Не выбран тип расчетов для сверки.';
								|pl = 'Nie wybrano żadnego typu kalkulacji do uzgodnienia.';
								|tr = 'Mutabakat için mutabakat türü seçilmemiştir.'");
			CommonClient.MessageToUser(MessageText, , "CustomersARAPAccounting");
			Return;
		EndIf;
		
		If TypeOf(Counterparty) = Type("CatalogRef.Companies")
			And ValueIsFilled(MainManager) Then
			MessageText = NStr("vi = 'Đã đặt bộ lọc theo người quản lý chính, sẽ không tạo giao dịch đối chiếu giữa các doanh nghiệp.';
								|ru = 'Установлен отбор по основному менеджеру, сверка между организациями не будет создана.';
								|en = 'The filter by employee in charge is set. A reconciliation between companies will not be created.'; fa = 'The filter by employee in charge is set. A reconciliation between companies will not be created.';
								|it = 'Установлен отбор по основному менеджеру, сверка между организациями не будет создана.';
								|pl = 'Jest ustawiony filtr według podstawowego menedżera, uzgodnienie między firmami nie będzie utworzone.';
								|tr = 'Ana yönetici tarafından seçim ayarlandığında, iş yerleri arasında mutabakat oluşturulmayacaktır.'");
			CommonClient.MessageToUser(MessageText, , "MainManager");
			Return;
		EndIf;
		
		Items.WizardPages.CurrentPage = Items.SettingPage;
		
	ElsIf Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.SettingPage Then
				
		If ParametersFilledIn() Then
			
			If Not NewOnlineARAPAccounting Then
				If ThereAreTasksForDistribution() Then
					Items.Next.Enabled = False;
					AttachIdleHandler("Attachable_CheckTaskCompletion", 0.1, True);
					Return;
				EndIf;
			EndIf;
			CallbackOnCompletion = New CallbackDescription("FillInCalculationTableEnd", ThisObject);
			RunCallback(CallbackOnCompletion, True);
		EndIf;
		
	ElsIf Command.Name = "Next"
		And Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		If ParametersFilledIn() Then
			
			AskAQuestionAboutClosing = True;
			If ParametersFilledIn() Then
				Items.Next.Enabled = False;
				CreateInBackgroundJobOnServer();
				AttachIdleHandler("Attachable_CheckTaskCompletion", 0.3, True);
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
				"Document.ARAPReconciliation2_4",
				TemplatesNames,
				ArrayOfDocumentsToPrint,
				Undefined,
				Undefined);
			
		EndIf;
		Close();
		
	ElsIf Command.Name = "Back"
		And Items.WizardPages.CurrentPage = Items.ResultPage Then
		
		Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3;
		
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

		If ReconciliationPeriod.EndDate = '00010101' Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa chỉ định cuối kỳ đối chiếu';
											|ru = 'Не указано окончание периода сверки';
											|en = 'Period end date not specified'; fa = 'Period end date not specified';
											|it = 'Не указано окончание периода сверки';
											|pl = 'Nieokreślony koniec okresu uzgadniania';
											|tr = 'Mutabakat döneminin sonu belirtilmemiştir'"),,"ReconciliationPeriod.EndDate");
			Cancel = True;
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		RecalculateNumberOfRowsInCalculationTable();
		
		If WillBeCreated = 0 And WillBeRefilled = 0 Then
			CommonClient.MessageToUser(NStr("vi = 'Chưa đánh dấu dòng nào để tạo mới hoặc điền lại';
											|ru = 'Не отмечена ни одна строка для создания или перезаполнения';
											|en = 'No item selected'; fa = 'No item selected';
											|it = 'Не отмечена ни одна строка для создания или перезаполнения';
											|pl = 'Żadne wiersze nie są zaznaczone do utworzenia lub ponownego wypełnienia';
											|tr = 'Oluşturma veya yeniden doldurma için işaretlenmiş satır yok'"),,"CalculationTable");
			Cancel = True;
		EndIf;
		
	ElsIf Items.WizardPages.CurrentPage = Items.SettingPage Then
		
		If DateOfDocuments = '00010101' Then
			CommonClient.MessageToUser(NStr("vi = 'Đã chỉ định ngày chứng từ trống';
											|ru = 'Указана пустая дата документов';
											|en = 'Date is empty'; fa = 'Date is empty';
											|it = 'Указана пустая дата документов';
											|pl = 'Data dokumentu jest pusta';
											|tr = 'Belgelerin tarihi boş bırakılmış'"),,"DateOfDocuments");
			Cancel = True;
		EndIf;
		
	EndIf;

	Return Not Cancel;
	
EndFunction

&AtClient
Procedure ButtonControlBasement()
	
	Items.Back.Enabled = True;
	Items.Cancel.Visible = True;
	If Items.WizardPages.CurrentPage = Items.FilterSettingsPage_3 Then
		
		Items.Next.Title = NStr("vi = 'Tiếp theo';
								|ru = 'Далее';
								|en = 'Next'; fa = 'بعدی';
								|it = 'Далее';
								|pl = 'Dalej';
								|tr = 'İleri'") + " >>";
		Items.Back.Title = NStr("vi = 'Quay lại';
								|ru = 'Назад';
								|en = 'Back'; fa = 'بازگشت';
								|it = 'Назад';
								|pl = 'Wróć';
								|tr = 'Geri'");
		Items.Back.Enabled = False;

	ElsIf Items.WizardPages.CurrentPage = Items.SettingPage Then
		
		Items.Next.Title = NStr("vi = 'Tiếp theo';
								|ru = 'Далее';
								|en = 'Next'; fa = 'بعدی';
								|it = 'Далее';
								|pl = 'Dalej';
								|tr = 'İleri'") + " >>";
		Items.Back.Title = "<< " + NStr("vi = 'Quay lại';
										|ru = 'Назад';
										|en = 'Back'; fa = 'بازگشت';
										|it = 'Назад';
										|pl = 'Wróć';
										|tr = 'Geri'");

	ElsIf Items.WizardPages.CurrentPage = Items.CalculationTablePage Then
		
		Items.Next.Title = NStr("vi = 'Thực hiện';
								|ru = 'Выполнить';
								|en = 'Run'; fa = 'اجرا';
								|it = 'Выполнить';
								|pl = 'Wykonaj';
								|tr = 'Yürüt'");
		Items.Back.Title = "<< " + NStr("vi = 'Quay lại';
										|ru = 'Назад';
										|en = 'Back'; fa = 'بازگشت';
										|it = 'Назад';
										|pl = 'Wróć';
										|tr = 'Geri'");

	ElsIf Items.WizardPages.CurrentPage = Items.ResultPage Then
		
		Items.Next.Title = NStr("vi = 'Hoàn thành';
								|ru = 'Завершить';
								|en = 'Complete'; fa = 'تکمیل';
								|it = 'Завершить';
								|pl = 'Zakończ';
								|tr = 'Tamamla'");
		Items.Back.Title = "<< " + NStr("vi = 'Về đầu trang';
										|ru = 'Вернуться в начало';
										|en = 'To step 1'; fa = 'به مرحله 1';
										|it = 'Вернуться в начало';
										|pl = 'Wróć na początek';
										|tr = 'Başa dön'");
		Items.Cancel.Visible = False;

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
		FilterContractsWithoutTurnover.Presentation = NStr("vi = 'Bao gồm các hợp đồng không có phát sinh trong kỳ';
															|ru = 'Включать договора без оборотов в периоде';
															|en = 'Include contracts without cash transactions during the given period'; fa = 'Include contracts without cash transactions during the given period';
															|it = 'Включать договора без оборотов в периоде';
															|pl = 'Uwzględnij umowy bez obrotu w tym okresie';
															|tr = 'Cirosu olmayan sözleşmeleri döneme dahil edin'");
	EndIf;
	FilterContractsWithoutTurnover.Use = ContractsWithoutTurnover;
	
	SetBasicSelections();
	
	OpeningParameters = New Structure("Filter_Settings", LinkerSelection.GetSettings());
	
	Return OpeningParameters;
	
EndFunction

&AtServer
Procedure SetBasicSelections()
	
	FilterContractsWithoutTurnover = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "ContractsWithoutTurnover");
	FilterContractsWithoutTurnover.Use = ContractsWithoutTurnover;
	
	SetComposerSelection("Organization", Organization);
	SetComposerSelection("Counterparty", Counterparty);
	SetComposerSelection("MainManager", MainManager);
	
	#Region SelectionByTypeOfCalculations
	ListOfCalculations_ = New ValueList();
	If CustomersARAPAccounting Then
		ListOfCalculations_.Add(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting);
	EndIf;
	
	If VendorsARAPAccounting Then
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
Procedure SetComposerSelection(FilterName, FilterValue)
	
	FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, FilterName);
	
	If FilterName = "Counterparty"
		And GetFunctionalOption("UsePartnersAsCounterparties") Then
		
		If TypeOf(FilterValue) = Type("CatalogRef.Companies") Then
			FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter,
																			"CompanyCounterparty");
		Else
			FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "Partner");
		EndIf;
		
	EndIf;
	
	If FilterElement = Undefined
		And Not ValueIsFilled(FilterValue) Then
		
		Return;
		
	EndIf;
	
	If ValueIsFilled(FilterValue)
		Or (Not ValueIsFilled(FilterValue)
			And FilterElement.ComparisonType = DataCompositionComparisonType.Equal) Then
		
		If FilterName = "Counterparty"
			And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			If TypeOf(FilterValue) = Type("CatalogRef.Counterparties") Then
				Partner = Common.ObjectAttributeValue(FilterValue, "Partner");
				
				DataCompositionClientServer.AddFilter(LinkerSelection, "Partner", Partner, , ValueIsFilled(Partner));
				DataCompositionClientServer.AddFilter(LinkerSelection, "CompanyCounterparty", , , False);
			Else
				DataCompositionClientServer.AddFilter(LinkerSelection,
															"CompanyCounterparty",
															FilterValue,
															,
															ValueIsFilled(FilterValue));
				DataCompositionClientServer.AddFilter(LinkerSelection, "Partner", , , False);
			EndIf;
			
		Else
			DataCompositionClientServer.AddFilter(LinkerSelection,
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
	
	UpdateSelectionHyperlink(Items.SetFilterSettings, LinkerSelection.Settings.Filter);
	
EndProcedure

&AtServer
Procedure UpdateSelectionHyperlink(AdvancedSelectionButton, Filter)
	
	VisibleLineSelections = "ContractsWithoutTurnover,PaymentType_,Organization,Counterparty,MainManager";
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		VisibleLineSelections = StrReplace(VisibleLineSelections, "Counterparty", "Partner");
	EndIf;
	VisibleSelections = StrSplit(VisibleLineSelections, ",");
	AdvancedSelectionIsInstalled = False;
	AdvancedSelectionButton.Title = NStr("vi = 'Bộ lọc nâng cao';
										|ru = 'Расширенный отбор';
										|en = 'Advanced filter'; fa = 'فیلتر پیشرفته';
										|it = 'Расширенный отбор';
										|pl = 'Rozszerzony filtr';
										|tr = 'Genişletilmiş seçim'");
	AdvancedSelectionButton.TextColor = New Color;
	
	AdvancedSelectionIsInstalled = AdvancedSelectionIsInstalled(VisibleSelections, LinkerSelection.Settings.Filter.Items);
	If AdvancedSelectionIsInstalled Then
		AdvancedSelectionButton.Title = NStr("vi = 'Đã đặt bộ lọc nâng cao';
											|ru = 'Установлен расширенный отбор';
											|en = 'Advanced filter is applied'; fa = 'Advanced filter is applied';
											|it = 'Установлен расширенный отбор';
											|pl = 'Ustawiono zaawansowany wybór';
											|tr = 'Genişletilmiş seçim oluşturuldu'");
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
	
	SelectionFlags = New Map;
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.CustomerARAPAccounting, "CustomersARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.VendorARAPAccounting, "VendorsARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.CreditorARAPAccounting, "CreditorARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.DebtorARAPAccounting, "DebtorARAPAccounting");
	SelectionFlags.Insert(Enums.PartnersARAPAccountingTypes.LeaseContractARAPWithLessor, "LeaseContractARAPWithLessor");
	
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
Procedure SetSelectionOnForm(FilterName)
	
	FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, FilterName);
	If FilterName = "Counterparty" And GetFunctionalOption("UsePartnersAsCounterparties") Then
		FilterElement = FinancialReportingServer.FindSelectionElement(LinkerSelection.Settings.Filter, "Partner");
	EndIf;
	ThisObject[FilterName] = Undefined;
	Item = Items[FilterName]; // FormField - 
	Item.Enabled = True;
	Item.InputHint = NStr("vi = 'Hãy chỉ định giá trị lọc';
							|ru = 'Укажите значение отбора';
							|en = 'Specify filter value'; fa = 'مقدار فیلتر را مشخص کنید';
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
			
		Else
			
			ElementInSelectionGroupUsed = FilterElement.Parent <> Undefined And FilterElement.Parent.Use;
			If FilterElement.Use Or ElementInSelectionGroupUsed Then
				Item = Items[FilterName]; // FormField - 
				Item.Enabled = False;
				Item.InputHint = NStr("vi = 'Đã thiết lập bộ lọc nâng cao';
										|ru = 'Установлен расширенный отбор';
										|en = 'Advanced filter is applied'; fa = 'Advanced filter is applied';
										|it = 'Установлен расширенный отбор';
										|pl = 'Ustawiono zaawansowany wybór';
										|tr = 'Gelişmiş filtre yapılandırıldı'");
			EndIf;
			
		EndIf;
	EndIf;
	
EndProcedure

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
