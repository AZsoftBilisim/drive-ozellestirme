

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Not Parameters.Filter.Property("Recorder") Then
		MessageText = NStr("vi = 'Không thể mở trực tiếp biểu mẫu này';
							|ru = 'Непосредственное открытие этой формы не предусмотрено';
							|en = 'Application cannot open this form explicitly.'; fa = 'Application cannot open this form explicitly.';
							|it = 'L''apertura diretta di questo modulo non è prevista';
							|pl = 'Bezpośrednie otwieranie tego formularza nie jest przewidziane';
							|tr = 'Bu formun doğrudan açılması sağlanamadı'");
		Raise MessageText;
	EndIf;
	
	Document = Parameters.Filter.Recorder;
	
	CompanyFieldName1 = "Organization";
	If ValueIsFilled(Parameters.CompanyFieldName1) Then
		CompanyFieldName1 = Parameters.CompanyFieldName1;
	EndIf;
	
	DocumentAttributes = Common.ObjectAttributesValues(Document, "Date, Posted," + CompanyFieldName1);
	DocumentDate = DocumentAttributes.Date;
	Organization   = DocumentAttributes[CompanyFieldName1];
	
	TypeOfMovementDebit = AccountingRecordType.Debit;
	TypeOfMovementCredit = AccountingRecordType.Credit;
	OverdueDataColor = StyleColors.OverdueDataColor;
	
	DocumentBeingPosted = (Document.Metadata().Posting <> Metadata.ObjectProperties.Posting.Deny);
	//@skip-warning
	Items.FormWriteAndClose.Enabled = DocumentBeingPosted Or DocumentAttributes.Posted;
	ReadOnly = Not (DocumentBeingPosted Or DocumentAttributes.Posted);
	
	ReadTransactions();
	
	Items.AnalysisOfTransactionsWithCorrespondence.Enabled = AccessRight("Use", Metadata.Reports.AnalysisOfTransactionsOfOperationalAccounting) And (DocumentBeingPosted Or DocumentAttributes.Posted);
	Items.AnalysisOfTransactionsWithoutCorrespondence.Enabled = AccessRight("Use", Metadata.Reports.AnalysisOfTransactionsOfOperationalAccounting) And (DocumentBeingPosted Or DocumentAttributes.Posted);
	Items.CreateBasedOn.Enabled = AccessRight("InteractiveInsert", Metadata.Documents.TransactionFinancialAccounting) And (DocumentBeingPosted Or DocumentAttributes.Posted);
	Items.FormGroupStandardCommands.Enabled = DocumentBeingPosted Or DocumentAttributes.Posted;
	Items.ManualCorrectionOfTransactionsWithCorrespondence.Enabled = DocumentBeingPosted Or DocumentAttributes.Posted;
	
	FinancialAccountingOfGeneralPurpose.SetUnitHeaders(Items.Department, "");
	
	If TypeOf(Document) = Type("DocumentRef.PeriodEndTransactionFinancialAccounting") Then
		OperationType = Common.ObjectAttributeValue(Document, "OperationType");
		If OperationType = Enums.PeriodEndTransactionsTypesFinancialAccounting.ExchangeDifferenceCalculationPresentationCurrency Then
			Items.Sum.AutoMarkIncomplete = False;
		EndIf;
	EndIf;
	
	ManualReflectionStatuses.Add(Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting);
	ManualReflectionStatuses.Add(Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting);
	
	StatusesAutomaticReflectionRequired.Add(Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting);
	StatusesAutomaticReflectionRequired.Add(Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined);
	StatusesAutomaticReflectionRequired.Add(Enums.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting);
	StatusesAutomaticReflectionRequired.Add(Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken);
	
	PrefixOfTheNameOfThePagesOnTheAccountPlans = "ChartOfAccounts_";
	
	CustomizeForm();
	
	GetStateOfDocumentReflectionOnChartOfAccounts();
	UpdateDateWhenTransactionsWereBanned();
	
EndProcedure

&AtClient
Procedure OnReopen()
	
	ReopeningServer();
	
EndProcedure

&AtClient
Procedure RecordTransactions(TransactionRecordingParameters)
	
	If TransactionRecordingParameters.GenerateTransactionsAutomatically Then
		StartAutomaticGenerationOfTransactions(TransactionRecordingParameters);
	Else
		RecordTransactionsServer(TransactionRecordingParameters);
		AfterRecordingTransactions(TransactionRecordingParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterRecordingTransactions(TransactionRecordingParameters)
	
	Notify("Write_DocumentPostingInFinancialAccounting");
	
	If TransactionRecordingParameters.CloseForm Then
		Close();
	EndIf;
	
EndProcedure

&AtServer
Procedure RecordTransactionsServer(TransactionRecordingParameters)
	
	BeginTransaction();
	
	Try
	
		Block = New DataLock;
		LockItem = Block.Add(Metadata.InformationRegisters.DocumentPostingInFinancialAccounting.FullName() + ".RecordSet");
		LockItem.SetValue("Recorder", Document);
		LockItem.Mode = DataLockMode.Exclusive;
		Block.Lock();
		
		SetOfRecordsIsInternational = AccountingRegisters.International.CreateRecordSet();
		SetOfRecordsIsInternational.AdditionalProperties.Insert("WriteEmptySet", True);
		SetOfRecordsIsInternational.Filter.Recorder.Set(Document);
		
		SetOfRecordsIsInternationalWithoutCorrespondence = AccountingRegisters.InternationalWithoutCorrespondence.CreateRecordSet();
		SetOfRecordsIsInternationalWithoutCorrespondence.AdditionalProperties.Insert("WriteEmptySet", True);
		SetOfRecordsIsInternationalWithoutCorrespondence.Filter.Recorder.Set(Document);
		
		If TransactionRecordingParameters.GenerateTransactionsAutomatically Then
			DocumentTransactions = ReflectInInternationalAccountingAutomatically(TransactionRecordingParameters);
			InternationalWithCorrespondence.Load(DocumentTransactions.WithCorrespondence);
			InternationalWithoutCorrespondence.Load(DocumentTransactions.WithoutCorrespondence);
		ElsIf ReflectionStatusesForAccountPlans.FindRows(New Structure("AStatusRecordIsRequired", True)).Count() > 0 Then
			DocumentReflectionRecords = InformationRegisters.DocumentPostingInFinancialAccounting.CreateRecordSet();
			DocumentReflectionRecords.Filter.Recorder.Set(Document);
			DocumentReflectionRecords.Read();
			
			For Each Record In DocumentReflectionRecords Do
				FilterParameters = New Structure("ChartOfAccounts, AStatusRecordIsRequired", Record.ChartOfAccounts, True);
				NoStatusRecordRequired = ReflectionStatusesForAccountPlans.FindRows(FilterParameters);
				If NoStatusRecordRequired.Count() > 0 Then
					Record.Status = NoStatusRecordRequired[0].ReflectionStatus;
					Record.Comment = "";
				EndIf;
			EndDo;
			
			DocumentReflectionRecords.Write();
		EndIf;
		
		For Each Record In InternationalWithCorrespondence Do
			NewRecord = SetOfRecordsIsInternational.Add();
			FillPropertyValues(NewRecord, Record);
			SetOfRecordsIsInternational.InstallExtdimension(NewRecord, Record, "Dr");
			SetOfRecordsIsInternational.InstallExtdimension(NewRecord, Record, "Cr");
		EndDo;
		
		For Each Record In InternationalWithoutCorrespondence Do
			NewRecord = SetOfRecordsIsInternationalWithoutCorrespondence.Add();
			FillPropertyValues(NewRecord, Record);
			SetOfRecordsIsInternationalWithoutCorrespondence.InstallExtdimension(NewRecord, Record);
		EndDo;
		
		SetOfRecordsIsInternational.Write();
		SetOfRecordsIsInternationalWithoutCorrespondence.Write();
		
		FinancialAccountingPostingServer.ReturnReverseDocumentsToReflection(, Document);
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		Raise;
		
	EndTry;
	
	ReadTransactions();

	Modified = False;
	
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	
	CustomizeForm();
	
	GetStateOfDocumentReflectionOnChartOfAccounts();
	FillInPresentationOfExtdimensionSpecies();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "DocumentIsReflectedInInternationalAccounting" And Source = Document Then
		ReopeningServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	InvoicePlanFromSettings = Settings.Get("ChartOfAccounts");
	If ValueIsFilled(InvoicePlanFromSettings)
		And ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", InvoicePlanFromSettings)).Count() = 0 Then
		Settings.Delete("ChartOfAccounts");
	EndIf;
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(ChartOfAccounts) Then
		StatusTableRow = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts))[0];
		IDOfTheChartOfAccounts = StatusTableRow.IDOfTheChartOfAccounts;
		Items.GroupPagesByAccountPlans.CurrentPage = Items[PrefixOfTheNameOfThePagesOnTheAccountPlans + IDOfTheChartOfAccounts];
		GetStateOfDocumentReflectionOnChartOfAccounts();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ManualPostingAdjustmentOnChange(Item)
	
	ManualPostingAdjustmentOnChangeServer();

EndProcedure


&AtClient
Procedure GroupPagesByAccountPlansOnCurrentPageChange(Item, CurrentPage)
	
	IDOfTheChartOfAccounts = StrReplace(CurrentPage.Name, PrefixOfTheNameOfThePagesOnTheAccountPlans, "");
	
	Filter = New Structure("IDOfTheChartOfAccounts", IDOfTheChartOfAccounts);
	SelectionResultChartsOfAccounts = ReflectionStatusesForAccountPlans.FindRows(Filter);
	ChartOfAccounts = SelectionResultChartsOfAccounts[0].ChartOfAccounts;
	GetStateOfDocumentReflectionOnChartOfAccounts();
	
EndProcedure

#EndRegion

#Region EventHandlersForTableElementsAndCorrespondenceTransactionForms

&AtClient
Procedure RecordSetSelection(Item, RowSelected, Field, StandardProcessing)

	If Not ManualPostingAdjustment Then
		DataPath = DataPath(Field.Name);
		PathParts = StrSplit(DataPath, ".");
		Value = Item.CurrentData[PathParts[1]];
		If ValueIsFilled(Value) 
			And TypeOf(Value) <> Type("Number") 
			And TypeOf(Value) <> Type("Date")
			And TypeOf(Value) <> Type("Boolean") Then
			ShowValue(, Value);
			StandardProcessing = False;
		EndIf;
	EndIf;

EndProcedure

&AtClient
Procedure RecordSetBeforeRowChange(Item, Cancel)
		
	ChangeExtdimensionFieldSelectionParameters(Item, "Dr");
	ChangeExtdimensionFieldSelectionParameters(Item, "Cr");
	
EndProcedure

&AtClient
Procedure RecordSetOnStartEdit(Item, NewRow, Copy)
	
	If NewRow And Not Copy Then
		Item.CurrentData.Organization = Organization;
		Item.CurrentData.ChartOfAccounts = ChartOfAccounts;
		Item.CurrentData.Period = DocumentDate;
	EndIf;
	
EndProcedure

&AtClient
Procedure AccountDrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	FillPropertyValues(CurrentData, AccountProperties(CurrentData.AccountDr, "Dr"));
	
EndProcedure

&AtClient
Procedure AccountDrStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", CurrentData.Organization);
	FormParameters.Insert("ChartOfAccounts",  CurrentData.ChartOfAccounts);
	FormParameters.Insert("RecordType", PredefinedValue("Enum.AccountingMovementKinds.Debit"));
	FormParameters.Insert("Account",        CurrentData.AccountDr);
	OpenForm("ChartOfAccounts.International.Form.ChoiceFormWithAccountSelection", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure AccountCrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	FillPropertyValues(CurrentData, AccountProperties(CurrentData.AccountCr, "Cr"));
	
EndProcedure

&AtClient
Procedure AccountCrStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	FormParameters = New Structure;
	FormParameters.Insert("Organization", CurrentData.Organization);
	FormParameters.Insert("ChartOfAccounts",  CurrentData.ChartOfAccounts);
	FormParameters.Insert("RecordType", PredefinedValue("Enum.AccountingMovementKinds.Credit"));
	FormParameters.Insert("Account",        CurrentData.AccountDr);
	OpenForm("ChartOfAccounts.International.Form.ChoiceFormWithAccountSelection", FormParameters, Item);
	
EndProcedure

&AtClient
Procedure CurrencyDrOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "Dr");
EndProcedure

&AtClient
Procedure CurrencyCrOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "Cr");
EndProcedure

&AtClient
Procedure CurrencyAmountDrOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "Dr");
EndProcedure

&AtClient
Procedure CurrencyAmountCrOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "Cr");
EndProcedure

&AtClient
Procedure SumOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentRow = FormTable.CurrentData;
	CurrentRow.PresentationAmount
		= CalculateSumOfPresentation(CurrentRow.ChartOfAccounts, CurrentRow.Organization, CurrentRow.Sum, CurrentRow.Period);
	
EndProcedure

&AtClient
Procedure ExtDimensionDr1OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr2OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr3OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Dr");
EndProcedure

&AtClient
Procedure ExtDimensionDr1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionDr2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionDr3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr1OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr2OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr3OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "Cr");
EndProcedure

&AtClient
Procedure ExtDimensionCr1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimensionCr3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(CurrentData, TypesConnectedWithTheCompany, "Dr"); 
	GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(CurrentData, TypesConnectedWithTheCompany, "Cr"); 
	ChangeExtdimensionFieldSelectionParameters(FormTable);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTransactionsWithoutCorrespondence

&AtClient
Procedure InternationalWithoutCorrespondenceBeforeRowChange(Item, Cancel)
	
	ChangeExtdimensionFieldSelectionParameters(Item, "");

EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceOnEditEnd(Item, NewRow, CancelEdit)
	If Not CancelEdit Then
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	EndIf;
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceOnStartEdit(Item, NewRow, Copy)
	
	CurrentRow = Item.CurrentData;
	If NewRow And Not Copy Then
		CurrentRow.Organization = Organization;
		CurrentRow.ChartOfAccounts = ChartOfAccounts;
		CurrentRow.Period = DocumentDate;
		
		If TotalAmount_5Dr >= TotalAmount_5Cr Then
			CurrentRow.RecordType = TypeOfMovementCredit;
			CurrentRow.SumCr = TotalAmount_5Dr - TotalAmount_5Cr;
			CurrentRow.Sum = CurrentRow.SumCr;
			
			CurrentRow.PresentationAmountCr = CalculateSumOfPresentation(CurrentRow.ChartOfAccounts, CurrentRow.Organization, CurrentRow.Sum, CurrentRow.Period);
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountCr;
		Else
			CurrentRow.RecordType = TypeOfMovementDebit;
			CurrentRow.SumDr = TotalAmount_5Cr - TotalAmount_5Dr;
			CurrentRow.Sum = CurrentRow.SumDr;
			
			CurrentRow.PresentationAmountDr = CalculateSumOfPresentation(CurrentRow.ChartOfAccounts, CurrentRow.Organization, CurrentRow.Sum, CurrentRow.Period);
			CurrentRow.PresentationAmount = CurrentRow.PresentationAmountDr;
		EndIf;
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
		CurrentRow.TypeOfMovementIndex = 
			TypeOfMovementIndexOfImage(CurrentRow.RecordType, CurrentRow.Active, CurrentRow.Sum, ThisObject);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceAfterDeleteRow(Item)
	CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
EndProcedure

&AtClient
Procedure AccountOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	FillPropertyValues(CurrentData, AccountProperties(CurrentData.Account, ""));
EndProcedure

&AtClient
Procedure SumDrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	CurrentData.RecordType = TypeOfMovementDebit;
	CurrentData.Sum = CurrentData.SumDr;
	CurrentData.SumCr = 0;
	
	CurrentData.PresentationAmountDr = CalculateSumOfPresentation(CurrentData.ChartOfAccounts, CurrentData.Organization, CurrentData.Sum, CurrentData.Period);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.PresentationAmountCr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
	
EndProcedure

&AtClient
Procedure SumCrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	CurrentData.RecordType = TypeOfMovementCredit;
	CurrentData.Sum = CurrentData.SumCr;
	CurrentData.SumDr = 0;
	
	CurrentData.PresentationAmountCr = CalculateSumOfPresentation(CurrentData.ChartOfAccounts, CurrentData.Organization, CurrentData.Sum, CurrentData.Period);
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.PresentationAmountDr = 0;
	
	CurrentData.TypeOfMovementIndex = 
		TypeOfMovementIndexOfImage(CurrentData.RecordType, CurrentData.Active, CurrentData.Sum, ThisObject);
		
EndProcedure

&AtClient
Procedure PresentationAmountDrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	CurrentData.PresentationAmount = CurrentData.PresentationAmountDr;
	CurrentData.RecordType = TypeOfMovementDebit;
	If CurrentData.SumCr <> 0 Then
		CurrentData.SumCr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountCr <> 0 Then
		CurrentData.PresentationAmountCr = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationAmountCrOnChange(Item)
	
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	
	CurrentData.PresentationAmount = CurrentData.PresentationAmountCr;
	CurrentData.RecordType = TypeOfMovementCredit;
	If CurrentData.SumDr <> 0 Then
		CurrentData.SumDr = 0;
		CurrentData.Sum = 0;
	EndIf;
	If CurrentData.PresentationAmountDr <> 0 Then
		CurrentData.PresentationAmountDr = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure CurrencyAmountOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "");
EndProcedure

&AtClient
Procedure CurrencyOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrencyOnChangeClient(FormTable, "");
EndProcedure

&AtClient
Procedure ExtDimension1OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "");
EndProcedure

&AtClient
Procedure ExtDimension1ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimension2OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "");
EndProcedure

&AtClient
Procedure ExtDimension2ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure ExtDimension3OnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	ChangeExtdimensionFieldSelectionParameters(FormTable, "");
EndProcedure

&AtClient
Procedure ExtDimension3ChoiceProcessing(Item, ValueSelected, StandardProcessing)
	ClearSelectionOptions(Item);
EndProcedure

&AtClient
Procedure InternationalWithoutCorrespondenceOrganizationOnChange(Item)
	FormTable = TMCommonUseClientServer.ElementShapeTable(Item);
	CurrentData = FormTable.CurrentData;
	GLAccountSettingsClient.ProcessingTransactionsWhenOrganizationChanges(CurrentData, TypesConnectedWithTheCompany, ""); 
	ChangeExtdimensionFieldSelectionParameters(FormTable);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Write(Command)
	
	ClearMessages();
	
	WriteParameters = TransactionRecordingParameters();
	RecordTransactions(WriteParameters);
	
EndProcedure

&AtClient
Procedure WriteAndClose(Command)
	
	ClearMessages();
	
	WriteParameters = TransactionRecordingParameters();
	WriteParameters.CloseForm = True;
	
	RecordTransactions(WriteParameters);
	
EndProcedure

&AtClient
Procedure RecordInInternationalAccounting(Command)
	
	ClearMessages();
	WriteParameters = TransactionRecordingParameters();
	WriteParameters.GenerateTransactionsAutomatically = True;
	
	RecordTransactions(WriteParameters);
	
EndProcedure

&AtClient
Procedure FillInPostingsAutomatically(Command)
	
	If ThereAreTwoDocumentsOnInternationalAccounting() Then
		QueryText = NStr("vi = 'Các bút toán hiện tại sẽ bị xóa. Tiếp tục?';
						|ru = 'Существующие проводки будут удалены. Продолжить?';
						|en = 'Existing entries will be deleted. Continue?'; fa = 'Existing entries will be deleted. Continue?';
						|it = 'Le voci di registro esistenti saranno eliminate. Continuare?';
						|pl = 'Istniejące dekretowania zostaną usunięte. Kontynuować?';
						|tr = 'Mevcut girişler silinecek. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("IssueAlertHandlerBeforeAutomaticallyFillingInTransactions", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	Else
		StartAutomaticGenerationOfTransactions();
	EndIf;
	
EndProcedure

&AtClient
Procedure ConfirmPostingRelevance(Command)
	
	ConfirmPostingRelevanceServer();
	
EndProcedure

&AtClient
Procedure ReversePostings(Command)
	
	FillingValues = New Structure();
	FillingValues.Insert("Basis", Document);
	FillingValues.Insert("ChartOfAccounts", ChartOfAccounts);
	
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	OpenForm("Document.TransactionFinancialAccounting.ObjectForm", FormParameters);
	
EndProcedure

&AtClient
Procedure UpdateRecordState(Command)
	UpdateReflectionStateOnServer();
EndProcedure

&AtClient
Procedure AnalysisOfTransactionsOfOperationalAccounting(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("VariantKey", "AnalysisOfTransactionsOfOperationalAccounting");
	FormParameters.Insert("GenerateOnOpen", True);
	
	SelectionParameter = New Structure();
	If ValueIsFilled(ChartOfAccounts) Then
		SelectionParameter.Insert("ChartOfAccounts", ChartOfAccounts);
	EndIf;
	If ValueIsFilled(Document) Then
		SelectionParameter.Insert("Recorder", Document);
	EndIf;
	
	FormParameters.Insert("Filter", SelectionParameter);
	
	UserSettingsValues = New Structure();
	UserSettingsValues.Insert("ReportPeriod", StandardPeriodVariant.Custom);
	UserSettings = CustomSettingsForTransactionAnalysisReport(
		"AnalysisOfTransactionsOfOperationalAccounting", UserSettingsValues);
	
	FormParameters.Insert("UserSettings", UserSettings);
	
	OpenForm("Report.AnalysisOfTransactionsOfOperationalAccounting.ObjectForm", FormParameters, ThisForm);
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Function TransactionRecordingParameters()
	
	WriteParameters = New Structure();
	WriteParameters.Insert("CloseForm", False);
	WriteParameters.Insert("GenerateTransactionsAutomatically", False);
	WriteParameters.Insert("AccountingStatuses", New Array());
	WriteParameters.Insert("AddressOfTransactionTable", "");
	WriteParameters.Insert("AttemptsNumber", 3);
	
	Return WriteParameters;
	
EndFunction

&AtServer
Procedure SetSetConditionalRegistrationOfTransactionsWithCorrespondence(IDOfTheChartOfAccounts)
	
	#Region DisplayCurrencyAmount
		
	NameOfCurrencyFieldDr = "CurrencyDr" + IDOfTheChartOfAccounts;
	NameCurrencyAmountDr = "CurrencyAmountDr" + IDOfTheChartOfAccounts;

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfCurrencyFieldDr);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameCurrencyAmountDr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.Currency1Dr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
		
	#EndRegion
	
	#Region DisplayingQuantity
	FieldNameLabelNumberOfDr = "LabelQuantityDr"  + IDOfTheChartOfAccounts;
	FieldNameQuantityDr = "CountDr" + IDOfTheChartOfAccounts;

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameLabelNumberOfDr);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameQuantityDr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.QuantitativeDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region DisplayingQuantity
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameLabelNumberOfDr);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Số lượng:';
													|ru = 'Кол.:';
													|en = 'Qty:'; fa = 'Qty:';
													|it = 'Quant.:';
													|pl = 'Qty:';
													|tr = 'Miktar:'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	#EndRegion
	
	#Region DisplayingExtdimensionViewOfDr1
	
	FieldNamePresentationViewExtdimensionDr1 = "PresentationViewOfExtdimensionDr1" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
	
	#Region DisplayingExtdimensionViewOfDr2
		
	FieldNamePresentationViewExtdimensionDr2 = "PresentationViewOfExtdimensionDr2" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region DisplayingExtdimensionDr3View
	
	FieldNamePresentationViewExtdimensionDr3 = "PresentationViewOfExtdimensionDr3" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionDr3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionDr3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region DisplayCurrencyAmount
		
	NameOfCurrencyFieldCr = "CurrencyCr" + IDOfTheChartOfAccounts;
	NameCurrencyAmountCr = "CurrencyAmountCr" + IDOfTheChartOfAccounts;

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfCurrencyFieldCr);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameCurrencyAmountCr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.Currency1Cr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("Visible", False);
		
	#EndRegion
	
	#Region DisplayingQuantity
	FieldNameLabelNumberOfCr = "LabelQuantityCr" + IDOfTheChartOfAccounts;
	FieldNameQuantityCr = "CountCr" + IDOfTheChartOfAccounts;

	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameLabelNumberOfCr);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameQuantityCr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.QuantitativeCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	Item.Appearance.SetParameterValue("Visible", False);
		
	#EndRegion
	
	#Region DisplayingQuantity
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameLabelNumberOfCr);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Số lượng:';
													|ru = 'Кол.:';
													|en = 'Qty:'; fa = 'Qty:';
													|it = 'Quant.:';
													|pl = 'Qty:';
													|tr = 'Miktar:'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion

	#Region FormatCurrencyAmount
		Item = ConditionalAppearance.Items.Add();
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameCurrencyAmountDr);
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameCurrencyAmountCr);
		
		Item.Appearance.SetParameterValue("Format", "NFD=2;");	
	
	#EndRegion


	#Region ExtdimensionViewDisplayCr1
		
	FieldNamePresentationViewExtdimensionCR1 = "PresentationViewOfExtdimensionCr1" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCR1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCR1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region DisplayOfViewOfExtdimensionOfCR2
		
	FieldNamePresentationViewExtdimensionCR2 = "PresentationViewOfExtdimensionCr2" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCR2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCR2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region DisplayOfViewOfExtdimensionOfCR3
		
	FieldNamePresentationViewExtdimensionCr3 = "PresentationViewOfExtdimensionCr3" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCr3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNamePresentationViewExtdimensionCr3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.ExtDimensionCr3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region TextNormalPosting
		
	FieldNameTransactionType = "PostingType" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameTransactionType);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Standard'; fa = 'استاندارد';
													|it = 'Regolare';
													|pl = 'Standard';
													|tr = 'Normal'"));
	#EndRegion
	
	#Region PostingTemplate
		
	FieldNameTransactionTemplate = "PostingTemplate" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameTransactionTemplate);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	MatchSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	MatchSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ComplianceOfAccountsAndTurnover
		
	NameOfInvoiceMatchingFieldDr = "AccountComplianceDr" + IDOfTheChartOfAccounts;
	NameOfInvoiceMatchingFieldCr = "AccountComplianceCr" + IDOfTheChartOfAccounts;
	NameOfRotationMatchingField = "EqualityOfTurnoverTotals" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfInvoiceMatchingFieldDr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfInvoiceMatchingFieldCr);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceCr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.AccountComplianceDr");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfRotationMatchingField);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure InstallInstallConditionalRegistrationOfTransactionsWithoutCorrespondence(IDOfTheChartOfAccounts)
	
	#Region DisplayingExtDimensionView1
	
	FieldNameViewViewExtDimension1 = "PresentationViewOfExtdimension1" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.Account");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension1);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension1");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	
	#EndRegion
	
	#Region DisplayingExtDimensionView2
		
	FieldNameViewViewExtDimension2 = "PresentationViewOfExtdimension2" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.Account");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension2);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension2");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region DisplayingExtDimensionView3
	
	FieldNameViewViewExtDimension3 = "PresentationViewOfExtdimension3" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.Account");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EntryHelpTextColor);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameViewViewExtDimension3);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.ExtDimension3");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	Item.Appearance.SetParameterValue("Show", False);
	#EndRegion
	
	#Region TextNormalPosting
		
	FieldNameTransactionType = "InternationalWithoutCorrespondencePostingType" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameTransactionType);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.PostingType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.EmptyTableField);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Thường';
													|ru = 'Обычная';
													|en = 'Standard'; fa = 'استاندارد';
													|it = 'Regolare';
													|pl = 'Standard';
													|tr = 'Normal'"));
	#EndRegion
	
	#Region PostingTemplate
		
	FieldNameTransactionTemplate = "PostingTemplate" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(FieldNameTransactionTemplate);
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.PostingTemplate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	MatchSelectionGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	MatchSelectionGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.AccountCompliance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	ItemFilter = MatchSelectionGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
	#Region ComplianceOfAccountsAndTurnover
		
	NameOfInvoiceMatchingField = "AccountCompliance" + IDOfTheChartOfAccounts;
	NameOfRotationMatchingField = "EqualityOfTurnoverTotals" + IDOfTheChartOfAccounts;
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfInvoiceMatchingField);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.AccountCompliance");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	Item = ConditionalAppearance.Items.Add();
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(NameOfRotationMatchingField);
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("InternationalWithoutCorrespondence.EqualityOfTurnoverTotals");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("Visible", False);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure ReadTransactions()
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	*
	|FROM
	|	AccountingRegister.International.RecordsWithExtDimensions(,, Recorder = &Document,,) AS International
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	*
	|FROM
	|	AccountingRegister.InternationalWithoutCorrespondence.RecordsWithExtDimensions(,, Recorder = &Document,,) AS InternationalWithoutCorrespondence";
	Query.SetParameter("Document", Document);
	
	QueryResult = Query.ExecuteBatch();
	InternationalWithCorrespondence.Load(QueryResult[0].Unload());
	InternationalWithoutCorrespondence.Load(QueryResult[1].Unload());
	
	FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	
	InternationalWithCorrespondence.Sort(TransactionSortingFields());
	InternationalWithoutCorrespondence.Sort(TransactionSortingFields());
	
	FillInPresentationOfExtdimensionSpecies();
	
EndProcedure

&AtServer
Procedure ReopeningServer()

	GetStateOfDocumentReflectionOnChartOfAccounts();
	SetPropertiesOfCurTabItems();
	//@skip-warning
	DocumentPosted = Common.ObjectAttributeValue(Document, "Posted");
	If Not DocumentPosted Or (DocumentPosted And Not ManualPostingAdjustment) Then
		ReadTransactions();
	EndIf;

EndProcedure

&AtClient
Procedure IssueAlertHandlerBeforeAutomaticallyFillingInTransactions(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		StartAutomaticGenerationOfTransactions();
	EndIf;

EndProcedure

&AtClient
Procedure StartAutomaticGenerationOfTransactions(TransactionRecordingParameters = Undefined)
	
	TimeConsumingOperation = StartReflectingDocumentInInternationalAccounting(Document, TransactionRecordingParameters, UUID);
	
	NotificationParameters = New Structure();
	
	If TransactionRecordingParameters = Undefined Then
		NotificationParameters.Insert("Action", "AutomaticFillingOfTransactions");
	Else
		NotificationParameters.Insert("Action", "AutomaticReflectionInAccounting");
		NotificationParameters.Insert("TransactionRecordingParameters", TransactionRecordingParameters);
	EndIf;
	
	CallbackOnCompletion = New CallbackDescription("ProcessResultOfDocumentReflection", ThisObject, NotificationParameters);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("vi = 'Tự động tạo bút toán';
								|ru = 'Автоматическое формирование проводок';
								|en = 'Automatic entry generation'; fa = 'Automatic entry generation';
								|it = 'Автоматическое формирование проводок';
								|pl = 'Automatic entry generation';
								|tr = 'Girişlerin otomatik oluşturulması'");
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function ReflectionStatus()
	
	LinesOnChartOfAccounts = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts));
	If LinesOnChartOfAccounts.Count() > 0 Then
		Return LinesOnChartOfAccounts[0].ReflectionStatus;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Function OptionForGeneratingTransactions()
	
	LinesOnChartOfAccounts = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts));
	If LinesOnChartOfAccounts.Count() > 0 Then
		Return LinesOnChartOfAccounts[0].OptionForGeneratingTransactions;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure ConfirmPostingRelevanceServer()
	
	StatusTableRow = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts))[0];
	StatusTableRow.ReflectionStatus = PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting");
	StatusTableRow.AStatusRecordIsRequired = True;
	
	GetStateOfDocumentReflectionOnChartOfAccounts();
	SetStatusImageToServer(StatusTableRow);
	
EndProcedure

&AtServer
Procedure ManualPostingAdjustmentOnChangeServer()

	StatusTableRow = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts))[0];
	If ManualPostingAdjustment 
		And ManualReflectionStatuses.FindByValue(StatusTableRow.ReflectionStatus) = Undefined Then
		StatusTableRow.ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting;
		StatusTableRow.AStatusRecordIsRequired = True;
	ElsIf Not ManualPostingAdjustment 
		And ManualReflectionStatuses.FindByValue(StatusTableRow.ReflectionStatus) <> Undefined Then
		StatusTableRow.ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting;
		StatusTableRow.AStatusRecordIsRequired = True;
	EndIf;
	
	GetStateOfDocumentReflectionOnChartOfAccounts();
	SetStatusImageToServer(StatusTableRow);

EndProcedure

&AtServer
Function ThisIsManualAdjustmentOfPostings(Status)
	
	If ManualReflectionStatuses.FindByValue(Status) <> Undefined Then
		Return True;
	EndIf;
	
	Return False;
	
EndFunction

&AtServer
Function Comment()
	
	LinesOnChartOfAccounts = ReflectionStatusesForAccountPlans.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts));
	If LinesOnChartOfAccounts.Count() > 0 Then
		Return StrConcat(LinesOnChartOfAccounts[0].Comments, Chars.LF);
	EndIf;
	
	Return "";
	
EndFunction

&AtServerNoContext
Function StartReflectingDocumentInInternationalAccounting(Document, TransactionRecordingParameters, FormIdentifier)
	
	If TransactionRecordingParameters <> Undefined Then
		FinancialAccountingPostingServer.PerformOfflineCalculations(,, Document);
		TransactionRecordingParameters.AccountingStatuses = AccountingStatuses(Document);
	EndIf;
	
	ReflectionParameters = FinancialAccountingPostingServer.ReflectionParametersInInternationalAccounting();
	ReflectionParameters.Documents = Document;
	ReflectionParameters.PerformRecalculations = False;
	ReflectionParameters.ToRecordTransactions = False;
	ReflectionParameters.CheckREFLECTIONStatus = False;
	
	Return FinancialAccountingPostingServer.StartReflectionInInternationalAccounting(ReflectionParameters, FormIdentifier);
	
EndFunction

&AtClient
Procedure ProcessResultOfDocumentReflection(Result, AdditionalParameters) Export
	
	If Result = Undefined Or Result.Status = "Error" Then
		MessageText = NStr("vi = 'Khi tạo bút toán kế toán quốc tế, đã xảy ra lỗi:
			|%1';
			|ru = 'При формировании проводок международного учета произошла ошибка:
			|%1';
			|en = 'An error occurred when generating financial accounting entries:
			|%1'; fa = 'An error occurred when generating financial accounting entries:
			|%1';
			|it = 'При формировании проводок международного учета произошла ошибка:
			|%1';
			|pl = 'An error occurred when generating financial accounting entries:
			|%1';
			|tr = 'Uluslararası gönderiler oluşturulurken bir hata oluştu:
			|%1'");
		
		If Result = Undefined Then
			DecryptionText = NStr("vi = 'Không tìm thấy nhiệm vụ đang thực hiện.';
									|ru = 'Не найдено выполняемое задание.';
									|en = 'Job in progress is not found.'; fa = 'Job in progress is not found.';
									|it = 'Не найдено выполняемое задание.';
									|pl = 'Job in progress is not found.';
									|tr = 'Yürütülmekte olan görev bulunamadı.'");
		ElsIf ValueIsFilled(Result.BriefErrorDescription) Then
			DecryptionText = Result.BriefErrorDescription;
		Else
			DecryptionText = NStr("vi = 'Chi tiết xem trong Nhật ký sự kiện.';
									|ru = 'Подробности см. в Журнале регистрации.';
									|en = 'For more information, see the event log.'; fa = 'For more information, see the event log.';
									|it = 'Подробности см. в Журнале регистрации.';
									|pl = 'For more information, see the event log.';
									|tr = 'Ayrıntılar için Olay günlüğüne bakın.'");
		EndIf;
		
		MessageText = StrTemplate(MessageText, DecryptionText);

		Raise MessageText;
	EndIf;
	
	If AdditionalParameters.Action = "AutomaticFillingOfTransactions" Then
		FillInPostingsAutomaticallyServer(Result.ResultAddress);
	ElsIf AdditionalParameters.Action = "AutomaticReflectionInAccounting" Then
		TransactionRecordingParameters = AdditionalParameters.TransactionRecordingParameters;
		TransactionRecordingParameters.AddressOfTransactionTable = Result.ResultAddress;
		
		If TransactionRecordingParameters.AttemptsNumber < 0 Then
			TransactionRecordingParameters.AttemptsNumber = -TransactionRecordingParameters.AttemptsNumber;
			RepeatDocumentReflection = False;
		Else
			RepeatDocumentReflection = True;
		EndIf;
		
		For AttemptNumber = 1 To TransactionRecordingParameters.AttemptsNumber Do
			Try
				RecordTransactionsServer(TransactionRecordingParameters);
				AfterRecordingTransactions(TransactionRecordingParameters);
				Break;
			Except
				If AttemptNumber < TransactionRecordingParameters.AttemptsNumber Then
				ElsIf RepeatDocumentReflection Then
					TransactionRecordingParameters.AttemptsNumber = -TransactionRecordingParameters.AttemptsNumber;
					RecordTransactions(TransactionRecordingParameters);
				Else
					Raise;
				EndIf;
			EndTry;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInPostingsAutomaticallyServer(AddressOfTransactionTable)
	
	TableOfTransactions = GetFromTempStorage(AddressOfTransactionTable);
	TableOfTransactions = FinancialAccountingPostingServer.RecordedTransactions(TableOfTransactions, ChartOfAccounts);
	
	TransactionsParameters = FinancialAccountingPostingServer.NewParametersForGeneratingTransactions();
	OptionForGeneratingTransactions = OptionForGeneratingTransactions();
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		RecordSet = InternationalWithoutCorrespondence;
		FinancialAccountingPostingServer.DeleteCorrespondenceTransactions(TableOfTransactions, TransactionsParameters);
	Else
		RecordSet = InternationalWithCorrespondence;
	EndIf;
	
	ChartOfAccountsEntries = RecordSet.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts));
	
	For Each ChartOfAccountsEntry In ChartOfAccountsEntries Do
		RecordSet.Delete(ChartOfAccountsEntry);
	EndDo;
	
	For Each AccountingEntry In TableOfTransactions Do
		Record = RecordSet.Add();
		FillPropertyValues(Record, AccountingEntry);
		Record.Active = True;
	EndDo;
	
	RecordSet.Sort(TransactionSortingFields());
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence();
	EndIf;
	
	FillInPresentationOfExtdimensionSpecies();
	
EndProcedure

&AtServer
Function ReflectInInternationalAccountingAutomatically(TransactionRecordingParameters)
	
	TableOfTransactions = GetFromTempStorage(TransactionRecordingParameters.AddressOfTransactionTable);
	TransactionsParameters = FinancialAccountingPostingServer.NewParametersForGeneratingTransactions();
	
	TransactionsWithCorrespondence = TableOfTransactions.CopyColumns();
	TransactionsWithoutCorrespondence = TransactionsWithCorrespondence.Copy();
	
	EmptyChartOfAccounts = Catalogs.FinancialAccountingChartsOfAccounts.EmptyRef();
	EmptyViewOfExtdimension = ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes.EmptyRef();
	
	For Each ReflectionStatuses In ReflectionStatusesForAccountPlans Do
		TheStructureOfTheSearch = New Structure("ChartOfAccounts", ReflectionStatuses.ChartOfAccounts);
		
		If ReflectionStatuses.ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting
		 Or ReflectionStatuses.ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting Then
			
			If ReflectionStatuses.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
				TransactionsGeneratedManually = InternationalWithoutCorrespondence.FindRows(TheStructureOfTheSearch);
				For Each AccountingEntry In TransactionsGeneratedManually Do
					NewRow = TransactionsWithoutCorrespondence.Add();
					FillPropertyValues(NewRow, AccountingEntry);
					FillInValuesOfUnbalancedFields(NewRow, AccountingEntry, TransactionsParameters);
					SetExtDimensionTypesOfEntry(NewRow, "Dr", EmptyViewOfExtdimension);
					SetExtDimensionTypesOfEntry(NewRow, "Cr", EmptyViewOfExtdimension);
					NewRow.Status = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting;
				EndDo;
			Else
				TransactionsGeneratedManually = InternationalWithCorrespondence.FindRows(TheStructureOfTheSearch);
				For Each AccountingEntry In TransactionsGeneratedManually Do
					NewRow = TransactionsWithCorrespondence.Add();
					FillPropertyValues(NewRow, AccountingEntry);
					SetExtDimensionTypesOfEntry(NewRow, "Dr", EmptyViewOfExtdimension);
					SetExtDimensionTypesOfEntry(NewRow, "Cr", EmptyViewOfExtdimension);
					NewRow.Status = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting;
				EndDo;
			EndIf;
			
		Else
			
			TransactionsGeneratedAutomatically = TableOfTransactions.FindRows(TheStructureOfTheSearch);
			
			For Each AccountingEntry In TransactionsGeneratedAutomatically Do
				If ReflectionStatuses.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
					NewRow = TransactionsWithoutCorrespondence.Add();
				Else
					NewRow = TransactionsWithCorrespondence.Add();
				EndIf;
				FillPropertyValues(NewRow, AccountingEntry);
			EndDo;
			
		EndIf;
	EndDo;
	
	ReflectionStatuses = TMCommonUse.ArrayToValueTable(TransactionRecordingParameters.AccountingStatuses);
	ReflectionStatusTransactions = TransactionsWithCorrespondence.Copy();
	CommonClientServer.SupplementTable(TransactionsWithoutCorrespondence, ReflectionStatusTransactions);
	
	If Not FinancialAccountingPostingServer.UpdateDocumentReflectionStatus(Document, ReflectionStatuses, ReflectionStatusTransactions) Then
		MessageText = NStr("vi = 'Không thể tự động phản ánh (có thể là chứng từ đã thay đổi hoặc bị xóa)';
							|ru = 'Автоматическое отражение не может быть выполнено (возможно документ был изменен или удален)';
							|en = 'Cannot record the document automatically as it might have been changed or deleted'; fa = 'Cannot record the document automatically as it might have been changed or deleted';
							|it = 'Автоматическое отражение не может быть выполнено (возможно документ был изменен или удален)';
							|pl = 'Cannot record the document automatically as it might have been changed or deleted';
							|tr = 'Otomatik kaydetme gerçekleştirilemiyor (belge değiştirilmiş veya silinmiş olabilir)'");
		Raise MessageText;
	EndIf;
	
	If TransactionsWithCorrespondence.Count() > 0 Then
		TransactionsWithCorrespondence = FinancialAccountingPostingServer.RecordedTransactions(TransactionsWithCorrespondence, EmptyChartOfAccounts, False);
		TransactionsWithCorrespondence.Sort(TransactionSortingFields());
		SetSignOfTransactionActivity(TransactionsWithCorrespondence);
	EndIf;
	
	If TransactionsWithoutCorrespondence.Count() > 0 Then
		TransactionsWithoutCorrespondence = FinancialAccountingPostingServer.RecordedTransactions(TransactionsWithoutCorrespondence, EmptyChartOfAccounts, False);
		FinancialAccountingPostingServer.DeleteCorrespondenceTransactions(TransactionsWithoutCorrespondence, TransactionsParameters);
		TransactionsWithoutCorrespondence.Sort(TransactionSortingFields());
		SetSignOfTransactionActivity(TransactionsWithoutCorrespondence);
	EndIf;
	
	DocumentTransactions = New Structure();
	DocumentTransactions.Insert("WithCorrespondence", TransactionsWithCorrespondence);
	DocumentTransactions.Insert("WithoutCorrespondence", TransactionsWithoutCorrespondence);
	
	Return DocumentTransactions;

EndFunction

&AtServer
Procedure SetExtDimensionTypesOfEntry(AccountingEntry, DrCr, EmptyViewOfExtdimension)
	
	If ValueIsFilled(AccountingEntry["Account" + DrCr]) Then
		AccountProperties = FinancialAccountingServerCached.AccountProperties(AccountingEntry["Account" + DrCr]);
		
		For ExtDimensionNumber = 1 To FinancialAccountingServerCached.MaxExtDimensionCount() Do
			AccountingEntry["ExtDimensionType" + DrCr + ExtDimensionNumber] = ?(
				AccountProperties["ExtDimensionType" + ExtDimensionNumber] <> Undefined,
				AccountProperties["ExtDimensionType" + ExtDimensionNumber],
				EmptyViewOfExtdimension);
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInValuesOfUnbalancedFields(NewRow, AccountingEntry, TransactionsParameters)
	
	If AccountingEntry.RecordType = AccountingRecordType.Debit Then
		DrCr = "Dr";
	ElsIf AccountingEntry.RecordType = AccountingRecordType.Credit Then
		DrCr = "Cr";
	Else
		Return;
	EndIf;
	
	For Each FieldName In TransactionsParameters.InvertedFields Do
		If FieldName = "ExtDimension" Or FieldName = "ExtDimensionType" Then
			For ExtDimensionNumber = 1 To TransactionsParameters.ExtDimensionCount Do
				NewRow[FieldName + DrCr + ExtDimensionNumber] = AccountingEntry[FieldName + ExtDimensionNumber];
			EndDo;
		Else
			NewRow[FieldName + DrCr] = AccountingEntry[FieldName];
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSignOfTransactionActivity(TableOfTransactions)
	
	TableOfTransactions.Columns.Add("Active", New TypeDescription("Boolean"));
	TableOfTransactions.FillValues(True, "Active");
	
EndProcedure

&AtServer
Procedure GetStateOfDocumentReflectionOnChartOfAccounts()

	DocumentsFormTransactionsWhenConducting = New Map;
	DocumentsFormTransactionsWhenConducting.Insert(Type("DocumentRef.PeriodEndTransactionFinancialAccounting"), True);
	CommonClientServer.SupplementMap(
		DocumentsFormTransactionsWhenConducting, FinancialAccountingUponDocumentData.TypesOfDocumentsToReflect());
	
	ReflectionStatus = ReflectionStatus();
	ManualPostingAdjustment = ThisIsManualAdjustmentOfPostings(ReflectionStatus);
	ThereAreTransactions = ThereAreTwoDocumentsOnInternationalAccounting();
	Comment = Comment();
	
	If ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting Then
			
		State = New FormattedString(
						NStr("vi = 'Phản ánh thủ công vào kế toán.';
							|ru = 'Отражен в учете вручную.';
							|en = 'Manually posted to accounting.'; fa = 'Manually posted to accounting.';
							|it = 'Riflettere riportato in contabilità manualmente.';
							|pl = 'Odzwierciedlono w ewidencji ręcznie.';
							|tr = 'Muhasebede manuel kaydedildi.'"),
						,
						StyleColors.HelpText);
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting Then
		
		State = New FormattedString(
						NStr("vi = 'Dự kiến ​​phản ánh vào kế toán pháp quy.';
							|ru = 'Ожидается отражение в регл. учете.';
							|en = 'Pending posting in local accounting.'; fa = 'Pending posting in local accounting.';
							|it = 'È prevista la registrazione nella contabilità regolamentata.';
							|pl = 'Oczekiwanie odzwierciedlenia w ewidencji regl.';
							|tr = 'Yerel muhasebede kaydetme bekleniyor.'"),
						,
						StyleColors.ErrorNoteText);
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken Then
		
		State = New FormattedString(
						NStr("vi = 'Vi phạm ghi trùng biểu ghi tài chính.';
							|ru = 'Нарушена двойная запись в финансовых регистрах.';
							|en = 'Double entry of financial registers is violated.'; fa = 'Double entry of financial registers is violated.';
							|it = 'Violato il metodo di partita doppia nei registri finanziari.';
							|pl = 'Został naruszony podwójny wpis w rejestrach finansowych.';
							|tr = 'Mali kayıtlarda çift girişi ihlal edildi'"),
						,
						StyleColors.ErrorNoteText);
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined Then
		
		State = New FormattedString(
						NStr("vi = 'Không có quy tắc phản ánh vào kế toán.';
							|ru = 'Отсутствуют правила отражения в учете.';
							|en = 'No rules of recording in accounting.'; fa = 'No rules of recording in accounting.';
							|it = 'Regole assenti di visualizzazione in contabilità.';
							|pl = 'Brak zasad wykazu w ewidencji.';
							|tr = 'Muhasebede kaydetme kuralları bulunmuyor.'"),
						,
						StyleColors.ErrorNoteText);
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting Then
		
		State = New FormattedString(
						NStr("vi = 'Được phản ánh vào kế toán.';
							|ru = 'Отражен в учете.';
							|en = 'Posted to accounting.'; fa = 'Posted to accounting.';
							|it = 'Riflettere in contabilità.';
							|pl = 'Uwzględniono w rejestrze.';
							|tr = 'Muhasebede kaydedildi.'"),
						,
						StyleColors.HelpText);
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting Then
		If ThereAreTransactions Then
			State = New FormattedString(
						NStr("vi = 'Dự kiến ​​sẽ phản ánh lại vào kế toán. Các bút toán có thể chưa được cập nhật.';
							|ru = 'Ожидается повторное отражение в учете. Проводки могут быть неактуальными.';
							|en = 'Re-recording in accounting is pending. Entries may be irrelevant.'; fa = 'Re-recording in accounting is pending. Entries may be irrelevant.';
							|it = 'È attesa la registrazione ripetuta in contabilità. Le transazioni possono essere non più attuali.';
							|pl = 'Oczekiwane jest ponowne odzwierciedlenie w ewidencji. Księgowania mogą być nieaktualne.';
							|tr = 'Muhasebe yeniden kaydetme bekleniyor. Girişler güncel olmayabilir.'"),
						,
						StyleColors.ModifiedAttributeValueColor);
		Else
			State = New FormattedString(
						NStr("vi = 'Dự kiến ​​sẽ phản ánh vào kế toán';
							|ru = 'Ожидается отражение в учете';
							|en = 'Pending posting in accounting.'; fa = 'Pending posting in accounting.';
							|it = 'È attesa la registrazione in contabilità';
							|pl = 'Oczekiwanie odzwierciedlenia w ewidencji regl.';
							|tr = 'Muhasebede kaydetme bekleniyor.'"),
						,
						StyleColors.HelpText);
		EndIf;
		
	ElsIf ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting Then
		If ThereAreTransactions Then
			State = New FormattedString(
						NStr("vi = 'Nếu cần, hãy điều chỉnh bút toán và xác nhận tính cập nhật.';
							|ru = 'При необходимости скорректируйте проводки и подтвердите актуальность.';
							|en = 'Correct the entries and confirm relevance, if required.'; fa = 'Correct the entries and confirm relevance, if required.';
							|it = 'In caso di necessità, correggere le transazioni e confermare la loro veridicità.';
							|pl = 'W razie potrzeby skoryguj księgowania i potwierdź aktualność.';
							|tr = 'Gerekirse, kayıtları düzenleyin ve güncel olduklarını onaylayın.'"),
						,
						StyleColors.ModifiedAttributeValueColor);
		Else
			State = New FormattedString(
						NStr("vi = 'Cần hạch toán thủ công.';
							|ru = 'Требуется ручное отражение в учете.';
							|en = 'Manual recording in accounting.'; fa = 'Manual recording in accounting.';
							|it = 'È richiesta la registrazione manuale in contabilità.';
							|pl = 'Jest wymagane odzwierciedlenie ręczne w ewidencji.';
							|tr = 'Muhasebede manuel kaydetme gerekiyor.'"),
						,
						StyleColors.HelpText);
		EndIf;
	Else
		If ThereAreTransactions Then
			State = New FormattedString(
						NStr("vi = 'Được phản ánh vào kế toán.';
							|ru = 'Отражен в учете.';
							|en = 'Posted to accounting.'; fa = 'Posted to accounting.';
							|it = 'Riflettere in contabilità.';
							|pl = 'Uwzględniono w rejestrze.';
							|tr = 'Muhasebede kaydedildi.'"),
						,
						StyleColors.HelpText);
		ElsIf DocumentsFormTransactionsWhenConducting[TypeOf(Document)] <> Undefined Then
			State = New FormattedString(
						NStr("vi = 'Chứng từ chưa kết chuyển.';
							|ru = 'Документ не проведен.';
							|en = 'Document is not posted.'; fa = 'Document is not posted.';
							|it = 'Il documento non è stato registrato nella contabilità.';
							|pl = 'Nie zatwierdzono dokumentu.';
							|tr = 'Belge kaydedilmedi.'"),
						,
						StyleColors.HelpText);
		Else
			State = New FormattedString(
						NStr("vi = 'Chứng từ không được phản ánh vào kế toán hoặc không có tùy chỉnh cho doanh nghiệp..';
							|ru = 'Документ не отражается в учете или отсутствует настройка для организации..';
							|en = 'The document is not posted to accounting or there is no setting for the company..'; fa = 'The document is not posted to accounting or there is no setting for the company..';
							|it = 'Il documento non è registrato in contabilità o manca tale impostazione per l''organizzazione..';
							|pl = 'Dokument nie jest odzwierciedlany w ewidencji lub nie ma ustawienia dla firmy..';
							|tr = 'Belge muhasebede yansıtılmıyor veya iş yeri için herhangi bir ayar bulunmuyor..'"),
						,
						StyleColors.HelpText);
			
			Items.FillInCorrespondenceTransactionsAutomatically.Visible = False;
			Items.ManualCorrectionOfTransactionsWithCorrespondence.Visible = False;
		EndIf;
	EndIf;
	
	TransactionsMayChange = "";
	
	If ReflectionStatus = Enums.StatusesOfPostingsInFinancialAccounting.PostedToAccounting Then
		TasksNotCompleted = FinancialAccountingOfMonthEndClosing.OutstandingDeferredTasks(
			Undefined, Undefined, Undefined, Document);
		If TasksNotCompleted.Count() > 0 Then
			TasksNotCompleted.Add(NStr("vi = 'Có thể thay đổi bút toán chứng từ.';
										|ru = 'Проводки документа могут измениться.';
										|en = 'Document entries might change.'; fa = 'Document entries might change.';
										|it = 'Проводки документа могут измениться.';
										|pl = 'Document entries might change.';
										|tr = 'Belge girişleri değişebilir.'"));
			TransactionsMayChange = New FormattedString(
				StrConcat(TasksNotCompleted, " "),,
				StyleColors.HelpText);
		EndIf;
	EndIf;
	
	SetPropertiesOfHeaderElements();
	SetPropertiesOfCurTabItems();
	SetPropertiesOfBasementElements();
	
EndProcedure

&AtServer
Procedure SetPropertiesOfHeaderElements()
	
	ThereIsManualReflection = False;
	AutomaticReflectionInAccountingIsRequired = False;
	
	For Each StatusTableRow In ReflectionStatusesForAccountPlans Do
		
		If ManualReflectionStatuses.FindByValue(StatusTableRow.ReflectionStatus) <> Undefined Then
			ThereIsManualReflection = True;
		ElsIf StatusesAutomaticReflectionRequired.FindByValue(StatusTableRow.ReflectionStatus) <> Undefined Then
			AutomaticReflectionInAccountingIsRequired = True;
		EndIf;
		
	EndDo;
	
	Items.FormWriteAndClose.Visible = ThereIsManualReflection;
	Items.FormWrite.Visible = ThereIsManualReflection;
	Items.FormWriteAndClose.DefaultButton = ThereIsManualReflection;
	
	Items.FormRecordInInternationalAccounting.Visible =  AutomaticReflectionInAccountingIsRequired Or Not ThereIsManualReflection;
	Items.FormRecordInInternationalAccounting.Enabled = AutomaticReflectionInAccountingIsRequired;
	Items.FormRecordInInternationalAccounting.DefaultButton = AutomaticReflectionInAccountingIsRequired;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfCurTabItems()
	
	ReflectionStatuses = Enums.StatusesOfPostingsInFinancialAccounting;
	
	TypesOfParallelAccountingDocuments = Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Commands.FinancialAccountingEntries.CommandParameterType.Types();
	ParallelAccountingDocument = TypesOfParallelAccountingDocuments.Find(TypeOf(Document)) <> Undefined;
	
	OptionForGeneratingTransactions = OptionForGeneratingTransactions();
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		ManualAdjustmentOfTransactionsElement = FormElementForCurChartOfAccounts(Items.ManualCorrectionOfTransactionsWithoutCorrespondence, ThisObject);
		CommentElement = FormElementForCurChartOfAccounts(Items.CommentsOnTransactionsWithoutCorrespondence, ThisObject);
		CheckReflectionRulesElement = FormElementForCurChartOfAccounts(Items.CheckRulesForReflectingTransactionsWithoutCorrespondence, ThisObject);
		TransactionTableElement =  FormElementForCurChartOfAccounts(Items.InternationalWithoutCorrespondence, ThisObject);
		ElementIsFilledInAutomatically =  FormElementForCurChartOfAccounts(Items.FillInTransactionsAutomaticallyWithoutCorrespondence, ThisObject);
		ConfirmTransactionsUpToDateElement = FormElementForCurChartOfAccounts(Items.ConfirmRelevanceOfTransactionsWithoutCorrespondence, ThisObject);
		ElementAnalysisOfOperationalAccounting = FormElementForCurChartOfAccounts(Items.AnalysisOfTransactionsWithoutCorrespondence, ThisObject);
		TransactionCorrectionOperationElement = FormElementForCurChartOfAccounts(Items.FormCorrectionOfTransactionsWithoutCorrespondence, ThisObject);
		ElementEntryType = FormElementForCurChartOfAccounts(Items.InternationalWithoutCorrespondencePostingType, ThisObject);
	Else
		ManualAdjustmentOfTransactionsElement = FormElementForCurChartOfAccounts(Items.ManualCorrectionOfTransactionsWithCorrespondence, ThisObject);
		CommentElement = FormElementForCurChartOfAccounts(Items.CommentsOnTransactionsWithCorrespondence, ThisObject);
		CheckReflectionRulesElement = FormElementForCurChartOfAccounts(Items.CheckRulesForReflectingTransactionsWithCorrespondence, ThisObject);
		TransactionTableElement =  FormElementForCurChartOfAccounts(Items.InternationalWithCorrespondence, ThisObject);
		ElementIsFilledInAutomatically =  FormElementForCurChartOfAccounts(Items.FillInCorrespondenceTransactionsAutomatically, ThisObject);
		ConfirmTransactionsUpToDateElement = FormElementForCurChartOfAccounts(Items.ConfirmRelevanceOfTransactionsWithCorrespondence, ThisObject);
		ElementAnalysisOfOperationalAccounting = FormElementForCurChartOfAccounts(Items.AnalysisOfTransactionsWithCorrespondence, ThisObject);
		TransactionCorrectionOperationElement = FormElementForCurChartOfAccounts(Items.FormCorrectionOfTransactionsWithCorrespondence, ThisObject);
		ElementEntryType = FormElementForCurChartOfAccounts(Items.PostingType, ThisObject);
	EndIf;
	
	ManualAdjustmentOfTransactionsElement.Visible = Not ParallelAccountingDocument;
	CommentElement.Visible = ValueIsFilled(Comment);
	CheckReflectionRulesElement.Visible = (ReflectionStatus = ReflectionStatuses.RulesOfRecordingInAccountingAreNotdefined);
	
	TransactionTableElement.ReadOnly = Not ManualPostingAdjustment;
	ElementIsFilledInAutomatically.Visible = ManualPostingAdjustment;
	
	ConfirmTransactionsUpToDateElement.Visible = ManualPostingAdjustment And ReflectionStatus = ReflectionStatuses.ForManualPostingInAccounting;
	
	ElementAnalysisOfOperationalAccounting.LocationInCommandBar =
		?(ReflectionStatus = ReflectionStatuses.PostedToAccounting Or ReflectionStatus = ReflectionStatuses.ManuallyPostedToAccounting,
			ButtonLocationInCommandBar.InAdditionalSubmenu,
			ButtonLocationInCommandBar.InCommandBarAndInAdditionalSubmenu);
	
	PostingGenerationSetting = FinancialAccountingServerCached.UsedSettingsForGeneratingTransactions(
		BegOfMonth(DocumentDate), ChartOfAccounts, Organization);
	MethodOfCancelingTransactions = Common.ObjectAttributeValue(PostingGenerationSetting, "MethodOfCancelingTransactions");
	
	FinancialAccountingOfGeneralPurpose.AddTypesOfInvalidTransactions(MethodOfCancelingTransactions,
		ElementEntryType.ChoiceList);
	
	If MethodOfCancelingTransactions = Enums.MethodsOfCancelingPostingsInFinancialAccounting.ByReversePostings Then
		TransactionCorrectionOperationElement.Title = NStr("vi = 'Reverse: Giao dịch (Kế toán quốc tế)';
															|ru = 'Реверс: Операция (Международный учет)';
															|en = 'Reverse: Transaction (Financial accounting)'; fa = 'Reverse: Transaction (Financial accounting)';
															|it = 'Retro: Operazione (Contabilità internazionale)';
															|pl = 'Rewers: Operacja (Ewidencja międzynarodowa)';
															|tr = 'Ters: İşlem (Finansal muhasebe)'");
	Else
		TransactionCorrectionOperationElement.Title = NStr("vi = 'Đảo ngược: Giao dịch (Kế toán quốc tế)';
															|ru = 'Сторно: Операция (Международный учет)';
															|en = 'Storno: Transaction (Financial accounting)'; fa = 'Storno: Transaction (Financial accounting)';
															|it = 'Storno: Operazione (Contabilità internazionale)';
															|pl = 'Storno: Operacja (Ewidencja międzynarodowa):';
															|tr = 'İptal: İşlem (Finansal muhasebe)'");
	EndIf;
	
	If OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
		CalculateResultsOfTransactionsWithoutCorrespondence(ThisObject);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetPropertiesOfBasementElements()
	
	If Items.GroupPagesByAccountPlans.CurrentPage = Items.NoRegistrationToReflectionGroup Then
		VisibilityOfTransactionChangeAlerts = False;
	Else
		VisibilityOfTransactionChangeAlerts = ValueIsFilled(TransactionsMayChange);
	EndIf;
	
	Items.TransactionGroupMayChange.Visible = VisibilityOfTransactionChangeAlerts;
	
EndProcedure

&AtServer
Function ThereAreTwoDocumentsOnInternationalAccounting()
	
	If ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccountsEntries = InternationalWithCorrespondence.FindRows(New Structure("ChartOfAccounts", ChartOfAccounts));
	Else
		ChartOfAccountsEntries = InternationalWithCorrespondence;
	EndIf;
	Return ChartOfAccountsEntries.Count() > 0;

EndFunction

&AtServerNoContext
Function AccountingStatuses(Document)
	
	Query = New Query();
	Query.Text = "
	|SELECT
	|	ReflectionOfDocumentsInAccounting.ChartOfAccounts AS ChartOfAccounts,
	|	ReflectionOfDocumentsInAccounting.Organization AS Organization,
	|	ReflectionOfDocumentsInAccounting.DateRecord AS DateRecord,
	|	ReflectionOfDocumentsInAccounting.StatusID AS StatusID
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionOfDocumentsInAccounting
	|WHERE
	|	ReflectionOfDocumentsInAccounting.Recorder = &Document
	|";
	
	Query.SetParameter("Document", Document);
	Result = Query.Execute();
	
	Return Common.ValueTableToArray(Result.Unload());
	
EndFunction

&AtClientAtServerNoContext
Function StatusPriorities()

	StatusPriorities = New Map;
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken"), 0);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting"), 1);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting"), 2);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting"), 3);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined"), 4);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting"), 5);
	StatusPriorities.Insert(PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting"), 6);
	
	Return StatusPriorities;

EndFunction

&AtClientAtServerNoContext
Function FormElementForCurChartOfAccounts(FormItem, ThisForm)
	
	Return ThisForm.Items[FormItem.Name + ThisForm.IDOfTheChartOfAccounts];
	
EndFunction

&AtClientAtServerNoContext
Function DetermineStatus(StatusPriorities, CurrentStatus, NewStatus)

	CurStatusPriority = StatusPriorities.Get(CurrentStatus);
	PriorityOfNewStatus = StatusPriorities.Get(NewStatus);
	Return ?(CurStatusPriority = Undefined Or PriorityOfNewStatus < CurStatusPriority, NewStatus, CurrentStatus);

EndFunction

&AtServer
Procedure FillInPresentationOfExtdimensionSpecies()

	For Each Record In InternationalWithCorrespondence Do
		FillPropertyValues(Record, AccountProperties(Record.AccountDr, "Dr"));
		FillPropertyValues(Record, AccountProperties(Record.AccountCr, "Cr"));
	EndDo;
	
	For Each Record In InternationalWithoutCorrespondence Do
		FillPropertyValues(Record, AccountProperties(Record.Account, ""));
	EndDo;
	
EndProcedure

&AtServer
Function AccountProperties(Account, RecordType)

	Result = New Structure;
	
	MaxExtDimensionCount = FinancialAccountingServerCached.MaxExtDimensionCount();
	AccountProperties = FinancialAccountingServerCached.AccountProperties(Account);
	
	Result.Insert("Quantitative" + RecordType, AccountProperties.Quantitative); 
	Result.Insert("Currency1" + RecordType, AccountProperties.Currency1); 
	
	For ExtDimensionNumber = 1 To MaxExtDimensionCount Do
		PropertyExtDimensionType = "ExtDimensionType" + RecordType + ExtDimensionNumber;
		PropertyExtDimensionTypePresentation = "PresentationViewOfExtdimension" + RecordType + ExtDimensionNumber;
		PropertyExtDimensionTypeDescription = "ExtDimensionType" + ExtDimensionNumber + "Description";
		
		If AccountProperties[PropertyExtDimensionTypeDescription] <> Undefined Then
			Result.Insert(PropertyExtDimensionType, AccountProperties["ExtDimensionType" + ExtDimensionNumber]);
			Result.Insert(PropertyExtDimensionTypePresentation, "<" + AccountProperties[PropertyExtDimensionTypeDescription] + ">");
		Else
			Result.Insert(PropertyExtDimensionTypePresentation, "");
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure HandlerAlertQuestionBeforeRecording(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		AdditionalParameters.Insert("AutomaticReflection", True);
		Write(AdditionalParameters);
		If AdditionalParameters.Property("CloseWhenRecording") Then
			Close();
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateDateWhenTransactionsWereBanned()

	If Common.HasObjectAttribute("Organization", Document.Metadata()) Then
		Attributes = Common.ObjectAttributesValues(Document,"Organization,Date");
	Else
		Attributes = Common.ObjectAttributesValues(Document, "Date");
		Attributes.Insert("Organization", Organization);
	EndIf;
	
	PeriodEndClosingDate = FinancialAccountingOfGeneralPurpose.ClosingDateOfPostingGeneration(Attributes.Organization);
	Items.CreateBasedOn.Visible = Attributes.Date <= PeriodEndClosingDate And ValueIsFilled(PeriodEndClosingDate);
	
EndProcedure

&AtClient
Procedure CheckRulesOfRecordingInAccounting(Command)
	
	AddressValidationResult = "";
	YouNeedToConfigureRules = CheckConfigurationOfReflectionRulesInServerAccounting(AddressValidationResult);
	
	If Not YouNeedToConfigureRules Then
		CallbackDescription = New CallbackDescription("NotificationHandlerShouldBeReflectedInReport", ThisObject);
		MessageTemplate = NStr("vi = 'Đã tùy chỉnh tất cả quy tắc phản ánh cần thiết theo hệ thống tài khoản ""%1"". Thử phản ánh chứng từ vào kế toán?';
								|ru = 'Настроены все необходимые правила отражения по плану счетов ""%1"". Попробовать отразить документ в учете?';
								|en = 'All the necessary recording rules for the ""%1"" chart of accounts have been configured. Try to record the document in accounting?'; fa = 'All the necessary recording rules for the ""%1"" chart of accounts have been configured. Try to record the document in accounting?';
								|it = 'Sono state impostate tutte le regole necessarie alla registrazione per il piano di conti ""%1"". Provare a registrare il documento nella contabilità?';
								|pl = 'Skonfigurowano wszystkie konieczne reguły odzwierciedlenia wg planu kont ""%1"". Spróbować odzwierciedlić dokument w ewidencji?';
								|tr = '""%1"" hesap planı için gerekli tüm yansıtma kuralları yapılandırıldı. Belgenin muhasebeye yansıtılmasın denensin mi?'");
		MessageText = StrTemplate(MessageTemplate, ChartOfAccounts);
		ShowQueryBox(CallbackDescription, MessageText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChartOfAccounts", ChartOfAccounts);
	FormParameters.Insert("Document", Document);
	FormParameters.Insert("AddressValidationResult", AddressValidationResult);
	
	CallbackDescriptionOnClose = New CallbackDescription("NotificationHandlerFormsRequiredRulesForReflectionInAccounting", ThisObject);
	OpenForm("DataProcessor.DocumentPostingInFinancialAccounting.Form.RequiredRecordingRules", 
		FormParameters, ThisForm, , , , CallbackDescriptionOnClose);
	
EndProcedure

&AtServer
Function CheckConfigurationOfReflectionRulesInServerAccounting(AddressInTempStorage)
	
	CheckParameters= DataProcessors.DocumentPostingInFinancialAccounting.ParametersForCheckingReflectionRules();
	CheckParameters.ChartOfAccounts = ChartOfAccounts;
	CheckParameters.Document = Document;
	CheckResult = DataProcessors.DocumentPostingInFinancialAccounting.CheckAccountingRulesSettings(CheckParameters);
	
	AddressInTempStorage = PutToTempStorage(CheckResult, UUID);
	
	YouNeedToConfigureRules = 
		CheckResult.BusinessTransactionsWithoutRecordingRules.Count() 
		Or CheckResult.AccountsWithoutRecordingRules.Count()
		Or CheckResult.AccountingObjectsThatRequireConfiguration.Count();
		
	Return YouNeedToConfigureRules;
	
EndFunction

&AtClient
Procedure NotificationHandlerShouldBeReflectedInReport(Result, AdditionalParameters) Export
	
	If Result = DialogReturnCode.Yes Then
		WriteParameters = TransactionRecordingParameters();
		WriteParameters.GenerateTransactionsAutomatically = True;
		RecordTransactions(WriteParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationHandlerFormsRequiredRulesForReflectionInAccounting(ClosingParameters, AdditionalParameters) Export
	
	RecordTheDocumentInInternationalAccounting = False;
	If TypeOf(ClosingParameters) = Type("Structure")
		 And ClosingParameters.Property("RecordTheDocumentInInternationalAccounting") Then
		RecordTheDocumentInInternationalAccounting = ClosingParameters.RecordTheDocumentInInternationalAccounting; 
	EndIf;
	
	If RecordTheDocumentInInternationalAccounting Then
		WriteParameters = TransactionRecordingParameters();
		WriteParameters.GenerateTransactionsAutomatically = True;
		RecordTransactions(WriteParameters);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateReflectionStateOnServer()
	
	//@skip-warning
	DocumentPosted = Common.ObjectAttributeValue(Document, "Posted");
	If Not DocumentPosted Or (DocumentPosted And Not ManualPostingAdjustment) Then
		ReadTransactions();
	EndIf;
	CustomizeForm();
	GetStateOfDocumentReflectionOnChartOfAccounts();
	
EndProcedure

&AtClient
Procedure CurrencyOnChangeClient(FormTable, DrCr)
	
	CurrentRow = FormTable.CurrentData;
	OnDate = CurrentRow.Period;
	TransactionAmounts = CalculateAmounts(ChartOfAccounts, CurrentRow.Organization, CurrentRow["CurrencyAmount"+DrCr], CurrentRow["Currency"+DrCr], OnDate);
	FillPropertyValues(CurrentRow, TransactionAmounts);
	If DrCr = "" Then
		FillInAuxiliaryAttributesOfTransaction(CurrentRow, ThisObject);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function CalculateAmounts(ChartOfAccounts, Organization, CurrencyAmount, Currency, OnDate)
	
	TransactionAmounts = New Structure("Sum,PresentationAmount",0,0);
	ConversionFactor = FinancialAccountingOfGeneralPurpose.GetCurrencyConversionRates_(ChartOfAccounts, Organization, Currency, OnDate);
	TransactionAmounts.Sum = CurrencyAmount * ConversionFactor.ToFunctionalCurrency;
	TransactionAmounts.PresentationAmount = CurrencyAmount * ConversionFactor.CurrencyOfPresentation;
	
	Return TransactionAmounts;
	
EndFunction

&AtServerNoContext
Function CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum, Date)
	
	Return FinancialAccountingOfGeneralPurpose.CalculateSumOfPresentation(ChartOfAccounts, Organization, Sum, Date);
	
EndFunction

&AtClient
Procedure ChangeExtdimensionFieldSelectionParameters(FormTable, DrCr="")
	
	CurrentData = FormTable.CurrentData;
	If CurrentData <> Undefined Then
		GLAccountSettingsClient.ChangeExtdimensionFieldSelectionParameters(ThisObject, CurrentData, CurrentData.Organization, DrCr);
	EndIf;
	
EndProcedure 

&AtServerNoContext
Function CustomSettingsForTransactionAnalysisReport(ReportName, UserSettingsValues)
	
	Return FinancialAccountingByFinancialRegisterDataServerCall.CustomSettingsForAnalysisOfOperationalAccounting(
		ReportName, UserSettingsValues);
	
EndFunction

&AtServer
Procedure CustomizeForm()
	
	FillInReflectionStatusesByAccountPlans();
	
	RegisteringForMultipleAccountPlans = (ReflectionStatusesForAccountPlans.Count() > 1);
	ThereIsRegistrationForReflection = (ReflectionStatusesForAccountPlans.Count() > 0);
	
	If ThereIsRegistrationForReflection And Not ValueIsFilled(ChartOfAccounts) Then
		ChartOfAccounts = ReflectionStatusesForAccountPlans[0].ChartOfAccounts;
		IDOfTheChartOfAccounts = ReflectionStatusesForAccountPlans[0].IDOfTheChartOfAccounts
	EndIf;
	
	If ThereIsRegistrationForReflection And RegisteringForMultipleAccountPlans Then
		Items.GroupPagesByAccountPlans.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	Else
		Items.GroupPagesByAccountPlans.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
	ConditionalAppearance.Items.Clear();
	For Each StatusTableRow In ReflectionStatusesForAccountPlans Do
		If StatusTableRow.OptionForGeneratingTransactions = Enums.EntryGenerationOptions.WithoutCorrespondence Then
			CreatePostingPageWithoutCorrespondence(StatusTableRow);
		Else
			CreatePageOfTransactionsWithCorrespondence(StatusTableRow);
		EndIf
	EndDo;
	
	Items.TransactionsWithCorrespondence.Visible = False;
	Items.TransactionsWithoutCorrespondence.Visible = False;
	Items.NoRegistrationToReflectionGroup.Visible = ReflectionStatusesForAccountPlans.Count() = 0;
	If Items.NoRegistrationToReflectionGroup.Visible Then
		Items.GroupPagesByAccountPlans.PagesRepresentation = FormPagesRepresentation.None;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInReflectionStatusesByAccountPlans()

	ReflectionStatusesForAccountPlans.Clear();
	
	Query = New Query;
	Query.Text = 
	"SELECT DISTINCT
	|	Postings.ChartOfAccounts AS ChartOfAccounts
	|INTO TransactionsWithCorrespondence
	|FROM
	|	&TransactionsWithCorrespondence AS Postings
	|;
	|
	|//////////////////////////////////////
	|SELECT DISTINCT
	|	Postings.ChartOfAccounts AS ChartOfAccounts
	|INTO TransactionsWithoutCorrespondence
	|FROM
	|	&TransactionsWithoutCorrespondence AS Postings
	|;
	|
	|/////////////////////////////////////
	|SELECT
	|	ReflectionStatuses.ChartOfAccounts AS ChartOfAccounts,
	|	ReflectionStatuses.ChartOfAccounts.OptionForGeneratingTransactions AS OptionForGeneratingTransactions,
	|	PRESENTATION(ReflectionStatuses.ChartOfAccounts) AS ChartOfAccountsPresentation,
	|	ReflectionStatuses.Comment AS Comment,
	|	ReflectionStatuses.Status  AS ReflectionStatus
	|FROM
	|	InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|WHERE
	|	ReflectionStatuses.Recorder = &Recorder
	|
	|UNION ALL
	|
	|SELECT
	|	Postings.ChartOfAccounts AS ChartOfAccounts,
	|	VALUE(Enum.EntryGenerationOptions.WithCorrespondence) AS OptionForGeneratingTransactions,
	|	PRESENTATION(Postings.ChartOfAccounts) AS ChartOfAccountsPresentation,
	|	"""" AS Comment,
	|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting) AS ReflectionStatus
	|FROM
	|	TransactionsWithCorrespondence AS Postings
	|	LEFT JOIN
	|		InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|	ON
	|		Postings.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		AND ReflectionStatuses.Recorder = &Recorder
	|WHERE
	|	ReflectionStatuses.Recorder IS NULL
	|
	|UNION ALL
	|
	|SELECT
	|	Postings.ChartOfAccounts AS ChartOfAccounts,
	|	VALUE(Enum.EntryGenerationOptions.WithoutCorrespondence) AS OptionForGeneratingTransactions,
	|	PRESENTATION(Postings.ChartOfAccounts) AS ChartOfAccountsPresentation,
	|	"""" AS Comment,
	|	VALUE(Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting) AS ReflectionStatus
	|FROM
	|	TransactionsWithoutCorrespondence AS Postings
	|	LEFT JOIN
	|		InformationRegister.DocumentPostingInFinancialAccounting AS ReflectionStatuses
	|	ON
	|		Postings.ChartOfAccounts = ReflectionStatuses.ChartOfAccounts
	|		AND ReflectionStatuses.Recorder = &Recorder
	|WHERE
	|	ReflectionStatuses.Recorder IS NULL
	|
	|ORDER BY
	|	ReflectionStatuses.ChartOfAccounts";
	Query.SetParameter("Recorder", Document);
	Query.SetParameter("TransactionsWithCorrespondence", InternationalWithCorrespondence.Unload());
	Query.SetParameter("TransactionsWithoutCorrespondence", InternationalWithoutCorrespondence.Unload());
	Selection = Query.Execute().Select();
	
	StatusPriorities = StatusPriorities();
	CurrentAccountPlan = Undefined;
	While Selection.Next() Do
		If CurrentAccountPlan <> Selection.ChartOfAccounts Then
			CurrentAccountPlan = Selection.ChartOfAccounts;
			StatusTableRow = ReflectionStatusesForAccountPlans.Add();
			FillPropertyValues(StatusTableRow, Selection);
			StatusTableRow.IDOfTheChartOfAccounts = StrReplace(StatusTableRow.ChartOfAccounts.UUID(), "-", "");
			StatusTableRow.Comments = New FixedArray(New Array());
		Else
			StatusTableRow.ReflectionStatus = DetermineStatus(StatusPriorities, StatusTableRow.ReflectionStatus, Selection.ReflectionStatus);
		EndIf;
		
		If Not IsBlankString(Selection.Comment) Then
			Comments = New Array(StatusTableRow.Comments);
			NumberOfComments = Comments.Count();
			AddComment = True;
			
			For ReverseIndex = 1 To NumberOfComments Do
				CurrentIndex = NumberOfComments - ReverseIndex;
				If Comments[CurrentIndex] = Selection.Comment
				 Or StrFind(Comments[CurrentIndex], Selection.Comment) > 0 Then
					AddComment = False;
					Break;
				ElsIf StrFind(Selection.Comment, Comments[CurrentIndex]) > 0 Then
					Comments.Delete(CurrentIndex);
				EndIf;
			EndDo;
			
			If AddComment Then
				Comments.Add(Selection.Comment);
			EndIf;
			
			StatusTableRow.Comments = New FixedArray(Comments);
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure CreatePageOfTransactionsWithCorrespondence(StatusTableRow)
	
	GroupName = PrefixOfTheNameOfThePagesOnTheAccountPlans + StatusTableRow.IDOfTheChartOfAccounts;
	
	If Items.Find(GroupName) = Undefined Then
		
		NewPage = Items.Add(
								GroupName, 
								Type("FormGroup"),
								Items.GroupPagesByAccountPlans);
		NewPage.Type = FormGroupType.Page;
		NewPage.Title = StatusTableRow.ChartOfAccountsPresentation;
		
		TMCommonUse.CopyFormElementsRecursively(
			ThisObject,
			Items.TransactionsWithCorrespondence,
			NewPage,
			StatusTableRow.IDOfTheChartOfAccounts);
		
	EndIf;
	
	CurrenciesOfInternationalAccounting = FinancialAccountingServerCached.AccountingCurrencies(StatusTableRow.ChartOfAccounts, Organization);
	CurrenciesDoNotMatch = (CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfInternationalAccounting.Functional);
	
	If CurrenciesDoNotMatch Then
		AmountHeader = NStr("vi = 'Số tiền (%1)';
							|ru = 'Сумма (%1)';
							|en = 'Amount (%1)'; fa = 'Amount (%1)';
							|it = 'Importo (%1)';
							|pl = 'Wartość (%1)';
							|tr = 'Tutar (%1)'");
	Else
		AmountHeader = NStr("vi = 'Số tiền chức năng (%1)';
							|ru = 'Сумма функц. (%1)';
							|en = 'Funct. currency amount (%1)'; fa = 'Funct. currency amount (%1)';
							|it = 'Importo funz. (%1)';
							|pl = 'Wartość funkc. (%1)';
							|tr = 'Tutar, fonks. para birimi (%1)'");
	EndIf;
	FormItem = Items[Items.Sum.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title = StrTemplate(AmountHeader, CurrenciesOfInternationalAccounting.Functional);
	
	PresentationAmountHeader = NStr("vi = 'Số tiền trình bày (%1)';
									|ru = 'Сумма предст. (%1)';
									|en = 'Present. amount (%1)'; fa = 'Present. amount (%1)';
									|it = 'Importo pres. (%1)';
									|pl = 'Wartość prez. (%1)';
									|tr = 'Tutar sunum para birimi (%1)'");
	FormItem = Items[Items.PresentationAmount.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title  = StrTemplate(PresentationAmountHeader, CurrenciesOfInternationalAccounting.Presentations);
	FormItem.Visible = Not CurrenciesDoNotMatch;
	
	SelectionAccordingToChartOfAccounts = New FixedStructure("ChartOfAccounts", StatusTableRow.ChartOfAccounts);
	FormItem = Items[Items.InternationalWithCorrespondence.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.RowFilter = SelectionAccordingToChartOfAccounts;
	
	FormItem = Items[Items.PostingType.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.ListChoiceMode = True;
	For Each ListItem In Items.PostingType.ChoiceList Do
		FormItem.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;
	
	SetStatusImageToServer(StatusTableRow);
	
	SetSetConditionalRegistrationOfTransactionsWithCorrespondence(StatusTableRow.IDOfTheChartOfAccounts);
	
EndProcedure

&AtServer
Procedure CreatePostingPageWithoutCorrespondence(StatusTableRow)
	
	GroupName = PrefixOfTheNameOfThePagesOnTheAccountPlans + StatusTableRow.IDOfTheChartOfAccounts;
	
	If Items.Find(GroupName) = Undefined Then
		
		NewPage = Items.Add(
								GroupName, 
								Type("FormGroup"),
								Items.GroupPagesByAccountPlans);
		NewPage.Type = FormGroupType.Page;
		NewPage.Title = StatusTableRow.ChartOfAccountsPresentation;
		
		TMCommonUse.CopyFormElementsRecursively(
			ThisObject,
			Items.TransactionsWithoutCorrespondence,
			NewPage,
			StatusTableRow.IDOfTheChartOfAccounts);
		
	EndIf;
	
	CurrenciesOfInternationalAccounting = FinancialAccountingServerCached.AccountingCurrencies(StatusTableRow.ChartOfAccounts, Organization);
	CurrenciesDoNotMatch = (CurrenciesOfInternationalAccounting.Presentations = CurrenciesOfInternationalAccounting.Functional);
	
	If CurrenciesDoNotMatch Then
		AmountHeader = NStr("vi = 'Số tiền Nợ (%1)';
							|ru = 'Сумма Дт (%1)';
							|en = 'Dr amount (%1)'; fa = 'Dr amount (%1)';
							|it = 'Importo Db (%1) ';
							|pl = 'Wartość Wn (%1)';
							|tr = 'Tutar Borç (%1)'")
	Else
		AmountHeader = NStr("vi = 'Số tiền chức năng Nợ (%1)';
							|ru = 'Сумма функц. Дт (%1)';
							|en = 'Dr funct. currency amount (%1)'; fa = 'Dr funct. currency amount (%1)';
							|it = 'Importo funz. Db (%1)';
							|pl = 'Wartość funkc. Wn (%1)';
							|tr = 'Tutar (fonks. para birimi) Borç (%1)'")
	EndIf;
	FormItem = Items[Items.SumDr.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title = StrTemplate(AmountHeader, CurrenciesOfInternationalAccounting.Functional);
	
	PresentationAmountHeader = NStr("vi = 'Số tiền trình bày Nợ (%1)';
									|ru = 'Сумма предст. Дт (%1)';
									|en = 'Dr present. amount (%1)'; fa = 'Dr present. amount (%1)';
									|it = 'Importo pres. Db (%1)';
									|pl = 'Wartość prez. Wn (%1)';
									|tr = 'Tutar sunum para birimi Borç (%1)'");
	FormItem = Items[Items.PresentationAmountDr.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title  = StrTemplate(PresentationAmountHeader, CurrenciesOfInternationalAccounting.Presentations);
	FormItem.Visible = Not CurrenciesDoNotMatch;
	
	If CurrenciesDoNotMatch Then
		AmountHeader = NStr("vi = 'Số tiền Có (%1)';
							|ru = 'Сумма Кт (%1)';
							|en = 'Cr amount (%1)'; fa = 'Cr amount (%1)';
							|it = 'Importo Cd (%1)';
							|pl = 'Wartość Ma (%1)';
							|tr = 'Tutar Alacak (%1)'")
	Else
		AmountHeader = NStr("vi = 'Số tiền chức năng Có (%1)';
							|ru = 'Сумма функц. Кт (%1)';
							|en = 'Cr funct. currency amount (%1)'; fa = 'Cr funct. currency amount (%1)';
							|it = 'Importo funz. Cd (%1)';
							|pl = 'Wartość funkc. Ma (%1)';
							|tr = 'Tutar (fonks. para birimi) Alacak (%1)'")
	EndIf;
	FormItem = Items[Items.SumCr.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title = StrTemplate(AmountHeader, CurrenciesOfInternationalAccounting.Functional);
	
	PresentationAmountHeader = NStr("vi = 'Số tiền trình bày Có (%1)';
									|ru = 'Сумма предст. Кт (%1)';
									|en = 'Cr present. amount (%1)'; fa = 'Cr present. amount (%1)';
									|it = 'Importo pres. Cd (%1)';
									|pl = 'Wartość prez. Ma (%1)';
									|tr = 'Tutar sunum para birimi Alacak (%1)'");
	FormItem = Items[Items.PresentationAmountCr.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.Title  = StrTemplate(PresentationAmountHeader, CurrenciesOfInternationalAccounting.Presentations);
	FormItem.Visible = Not CurrenciesDoNotMatch;
	
	SelectionAccordingToChartOfAccounts = New FixedStructure("ChartOfAccounts", StatusTableRow.ChartOfAccounts);
	FormItem = Items[Items.InternationalWithoutCorrespondence.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.RowFilter = SelectionAccordingToChartOfAccounts;
	
	FormItem = Items[Items.InternationalWithoutCorrespondencePostingType.Name + StatusTableRow.IDOfTheChartOfAccounts];
	FormItem.ListChoiceMode = True;
	For Each ListItem In Items.InternationalWithoutCorrespondencePostingType.ChoiceList Do
		FormItem.ChoiceList.Add(ListItem.Value, ListItem.Presentation);
	EndDo;
	
	SetStatusImageToServer(StatusTableRow);
	
	InstallInstallConditionalRegistrationOfTransactionsWithoutCorrespondence(StatusTableRow.IDOfTheChartOfAccounts);
	
EndProcedure

&AtServer
Procedure SetStatusImageToServer(ReflectionStatusesForAccountPlans)
	
	StatusImages =  StatusImages();
	Items[PrefixOfTheNameOfThePagesOnTheAccountPlans + ReflectionStatusesForAccountPlans.IDOfTheChartOfAccounts].Picture 
		= StatusImages[ReflectionStatusesForAccountPlans.ReflectionStatus];
	
EndProcedure

&AtClientAtServerNoContext
Function StatusImages()
	
	StatusImages = New Map();
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForPostingInAccounting"),
		PictureLib.PendingExecution);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PostedToAccounting"),
		PictureLib.Success);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.PendingPostingInLocalAccounting"),
		PictureLib.PendingExecution);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ManuallyPostedToAccounting"),
		PictureLib.ManualAdjustment32);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.RulesOfRecordingInAccountingAreNotdefined"), 
		PictureLib.ExclamationPointRed);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.ForManualPostingInAccounting"), 
		PictureLib.ManualAdjustment32);
	StatusImages.Insert(
		PredefinedValue("Enum.StatusesOfPostingsInFinancialAccounting.DoubleEntryOfFinancialRegistersIsBroken"),
		PictureLib.PendingExecution);
	
	Return StatusImages;
	
EndFunction

&AtServer
Function DataPath(TagName) 
	
	Return Items[TagName].DataPath;
	
EndFunction

&AtClient
Procedure ClearSelectionOptions(Item)
	Item.ChoiceParameters = New FixedArray(New Array);
EndProcedure

&AtClientAtServerNoContext
Procedure CalculateResultsOfTransactionsWithoutCorrespondence(ThisForm)
	
	Items = ThisForm.Items;
	
	ThisForm.TotalAmount_5Dr = 0;
	ThisForm.TotalAmount_5Cr = 0;
	ThisForm.ResultIsSumOfDrSubmission = 0;
	ThisForm.ResultIsSumOfCrRepresentation = 0;
	
	ChartOfAccountsEntries = ThisForm.InternationalWithoutCorrespondence.FindRows(New Structure("ChartOfAccounts", ThisForm.ChartOfAccounts));
	
	For Each Record In ChartOfAccountsEntries Do
		ThisForm.TotalAmount_5Dr = ThisForm.TotalAmount_5Dr + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.Sum, 0);
		ThisForm.TotalAmount_5Cr = ThisForm.TotalAmount_5Cr + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.Sum, 0);
		ThisForm.ResultIsSumOfDrSubmission = ThisForm.ResultIsSumOfDrSubmission + ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.PresentationAmount, 0);
		ThisForm.ResultIsSumOfCrRepresentation = ThisForm.ResultIsSumOfCrRepresentation + ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.PresentationAmount, 0);
	EndDo;
	
	SumDrElement = FormElementForCurChartOfAccounts(Items.SumDr, ThisForm);
	SumCrElement = FormElementForCurChartOfAccounts(Items.SumCr, ThisForm);
	If ThisForm.TotalAmount_5Dr <> ThisForm.TotalAmount_5Cr Then
		SumDrElement.FooterTextColor = ThisForm.OverdueDataColor;
		SumCrElement.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		SumDrElement.FooterTextColor = New Color();
		SumCrElement.FooterTextColor = New Color();
	EndIf;
	
	SumElementOfDrRepresentation = FormElementForCurChartOfAccounts(Items.PresentationAmountDr, ThisForm);
	ElementIsSumOfCrRepresentation = FormElementForCurChartOfAccounts(Items.PresentationAmountCr, ThisForm);
	If ThisForm.ResultIsSumOfDrSubmission <> ThisForm.ResultIsSumOfCrRepresentation Then
		SumElementOfDrRepresentation.FooterTextColor = ThisForm.OverdueDataColor;
		ElementIsSumOfCrRepresentation.FooterTextColor = ThisForm.OverdueDataColor;
	Else
		SumElementOfDrRepresentation.FooterTextColor = New Color();
		ElementIsSumOfCrRepresentation.FooterTextColor = New Color();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAuxiliaryAttributesOfTransactionsWithoutCorrespondence()
	
	For Each Record In InternationalWithoutCorrespondence Do
		
		FillInAuxiliaryAttributesOfTransaction(Record, ThisObject);
		
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInAuxiliaryAttributesOfTransaction(Record, ThisForm)
	Record.SumDr = ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.Sum, 0);
	Record.SumCr = ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.Sum, 0);
	Record.PresentationAmountDr = ?(Record.RecordType = ThisForm.TypeOfMovementDebit, Record.PresentationAmount, 0);
	Record.PresentationAmountCr = ?(Record.RecordType = ThisForm.TypeOfMovementCredit, Record.PresentationAmount, 0);
	Record.TypeOfMovementIndex = TypeOfMovementIndexOfImage(Record.RecordType, Record.Active, Record.Sum, ThisForm);
EndProcedure

&AtClientAtServerNoContext
Function TypeOfMovementIndexOfImage(RecordType, Active, Sum, ThisForms)
	
	If RecordType = ThisForms.TypeOfMovementDebit Then
		Return ?(Active, 1, 3);
	ElsIf RecordType = ThisForms.TypeOfMovementCredit Then
		Return ?(Active, 2, 4);
	Else
		Return 0;
	EndIf;
	
EndFunction

&AtServer
Function TransactionSortingFields()
	
	Return "ChartOfAccounts, ReversingEntry Desc, Period, Organization";
	
EndFunction

#EndRegion
