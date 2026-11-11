#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	// Skip initialization to ensure that the form is received when passing the "AutoTest" parameter.
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	UseOtherExpenseAccounting = GetFunctionalOption("UseAccountingOfOtherIncomeExpenses");
	If Not UseOtherExpenseAccounting Then
		Return;
	EndIf;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	MultipleOrganizationsAreUsed = GetFunctionalOption("UseMultipleCompanies");
	If Not (MultipleOrganizationsAreUsed Or ValueIsFilled(Object.Organization)) Then
		Object.Organization = SettingsValueCached.GetDefaultOrganization();
	EndIf;
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrencyRow = String(ManagementAccountingCurrency);
	FactorOfConversionFromManCurrencyToRegulCurrency = ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, Object.Date);
	
	TitleLine = "%1 (%2)";
	HeaderAmount = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Tổng số';
																							|ru = 'Сумма';
																							|en = 'Amount'; fa = 'مبلغ';
																							|it = 'Importo';
																							|pl = 'Wartość';
																							|tr = 'Tutar'"), CurrencyRow);
	Items.OtherExpensesSum.Title = HeaderAmount;
	HeaderAmount = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Số tiền không thuế GTGT';
																							|ru = 'Сумма без НДС';
																							|en = 'Amount excluding VAT'; fa = 'مبلغ بدون مالیات بر ارزش افزوده';
																							|it = 'Importo IVA esclusa';
																							|pl = 'Wartość bez VAT';
																							|tr = 'KDV hariç tutar'"), CurrencyRow);
	Items.OtherExpensesAmountExcludingVAT.Title = HeaderAmount;
	VATHeader = StringFunctionsClientServer.SubstituteParametersToString(TitleLine, NStr("vi = 'Thuế GTGT';
																						|ru = 'НДС';
																						|en = 'VAT'; fa = 'مالیات بر ارزش افزوده';
																						|it = 'IVA';
																						|pl = 'VAT';
																						|tr = 'KDV'"), CurrencyRow);
	Items.OtherExpensesVATAmount.Title = VATHeader;
	
	SetAvailabilityOfClipboardCommands();
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnCreateAtServer(ThisForm, Items.LineCorrection);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);
	
	OnReadCreateAtServer();
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	StructureOfActions.Insert("RecalculateAmountTa");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions);
	
	ItemsAndDimensionsSelectionParameters = Documents.OBEntryOtherExpenses.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	DocumentCorrection.OnReadAtServer(ThisForm, Items.LineCorrection);
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	WriteParameters.Insert("BusinessOperation", Object.BusinessOperation);
	Notify("Write_OBEntry", WriteParameters, Object.Ref);
	DocumentCorrectionClient.AfterWrite(Object);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommandsOnClient();
		
	EndIf;
	
	DocumentCorrectionClient.NotificationProcessing(ThisForm, EventName, Parameter, Source);
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	If Common.SubsystemExists("StandardSubsystems.AccessManagement") Then
		ModuleAccessManagement = Common.CommonModule("AccessManagement");
		ModuleAccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	EndIf;
	// End StandardSubsystems.AccessManagement
	
	SetHeader();
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInAttributeAcceptedByCNU");
	StructureOfActions.Insert("RecalculateAmountTa");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationOnChangeServer();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	DateOnChangeServer();
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordInOperationalAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure PostInFinancialAndTaxAccountingOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordInMAOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure RecordAITOnChange(Item)
	SetVisibility1();
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

&AtClient
Procedure LineCorrectionURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	DocumentCorrectionClient.StringFixHandlingNavigationLinks(
		ThisObject, FormattedStringURL, StandardProcessing);
	
EndProcedure

#EndRegion


#Region FormTableItemsEventHandlersOtherExpenses

&AtClient
Procedure OtherExpensesExpenseItemOnChange(Item)
	
	TableRow = Items.OtherExpenses.CurrentData;
	If ValueIsFilled(TableRow.ExpenseItem) Then
		ItemOfOtherExpensesInCaseOfChangeOfBudget(CachedValues);
	EndIf;
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure OtherExpensesExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	TableRow = Items.OtherExpenses.CurrentData;
	If TableRow.DimensionOfExpensesOrderImplementation Then
		IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);		
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	TableRow = Items.OtherExpenses.CurrentData;
	If TypeOf(ValueSelected) = Type("Structure") Then
		FillPropertyValues(TableRow, ValueSelected);
		StandardProcessing = False;
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) And Items.OtherExpenses.CurrentData.DimensionOfExpensesOrderImplementation Then
		StandardProcessing = False;
		IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);		
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesDimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If ValueIsFilled(Text) And Items.OtherExpenses.CurrentData.DimensionOfExpensesOrderImplementation Then
		StandardProcessing = False;
		IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	EndIf;
	
EndProcedure

&AtClient
Procedure OtherExpensesSumOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	LocalSumRecalculationStructure = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	LocalSumRecalculationStructure.PriceIncludesVAT = False;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", LocalSumRecalculationStructure);
	If ValueIsFilled(CurrentRow.ExpenseItem) Then
		StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	EndIf;
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure OtherExpensesVATRateOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;

	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	LocalSumRecalculationStructure = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	LocalSumRecalculationStructure.PriceIncludesVAT = False;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", LocalSumRecalculationStructure);
	If ValueIsFilled(CurrentRow.ExpenseItem) Then
		StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	EndIf;
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);

EndProcedure

&AtClient
Procedure OtherExpensesSumComplOnChange(Item)
	
	CurrentRow = Items.OtherExpenses.CurrentData;
	If ValueIsFilled(CurrentRow.ExpenseItem) Then
		StructureOfActions = New Structure;
		StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
		StructureOfActions.Insert("RecalculateAmountTa");
		StructureOfActions.Insert("RecalculateAmountOfTD");
		BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	EndIf;
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForConvertingAmountOfNDSVToTS(Object);
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateLocalVAT", StructureOfRecalculationOfAmount);
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure OtherExpensesAmountFAOnChange(Item)
	CurrentRow = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

&AtClient
Procedure OtherExpensesAmountPermanentDifferencesOnChange(Item)
	CurrentRow = Items.OtherExpenses.CurrentData;
	StructureOfActions = New Structure;
	If CurrentRow.AcceptedByTheKNU Then
		StructureOfActions.Insert("RecalculateAmountTa");
	EndIf;
	StructureOfActions.Insert("RecalculateAmountOfTD");
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.AttachableCommands
&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure


&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure


&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure FillInByBalance(Command)
	If Object.OtherExpenses.Count() Then
		AlertQuestionFillInByBalances = New CallbackDescription("AlertHandlerIssueFillInByBalances", ThisObject);
		QueryText = NStr("vi = 'Khi điền, dữ liệu hiện tại của phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'При заполнении текущие данные табличной части будут очищены. Продолжить?';
						|en = 'Current table data will be cleared. Continue?'; fa = 'Current table data will be cleared. Continue?';
						|it = 'I dati correnti della parte tabulare verranno cancellati durante la compilazione. Continuare?';
						|pl = 'Przy wypełnieniu bieżące dane części tabelarycznej będą oczyszczone. Kontynuować?';
						|tr = 'Tablo bölümünün mevcut verileri tamamlandığında silinecektir. Devam edilsin mi?'");
		ShowQueryBox(AlertQuestionFillInByBalances, QueryText, QuestionDialogMode.YesNo,,,  NStr("vi = 'Nhập số dư kế toán theo hoạt động';
																								|ru = 'Ввод остатков регл. учета по данным оперативного';
																								|en = 'Enter local accounting balance according to real-time accounting data'; fa = 'Enter local accounting balance according to real-time accounting data';
																								|it = 'Immissione delle rimanenze della contabilità regolamentare in base ai dati di contabilità operativa';
																								|pl = 'Wprowadzenie ostatków ewidencji reglamentowanej według danych operacyjnej';
																								|tr = 'Operasyonel verilere dayalı olarak yerel muhasebe bakiyelerinin girilmesi'"));
	Else
		FillByBalancesOnServer();
	EndIf;
	Return;
EndProcedure

&AtClient
Procedure InsertRows(Command)
	
	NumberOfRowsBeforeInsertion = Object.OtherExpenses.Count();
	GetLinesFromClipboard();
	NumberOfInserted = Object.OtherExpenses.Count()-NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtClient
Procedure CopyRows(Command)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items.OtherExpenses) Then
		CopyLinesOnServer();
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items.OtherExpenses.SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.Department.Name);
	
	DataCompositionClientServer.AddFilter(Item.Filter, "Object.BusinessOperation", Enums.BusinessTransactions.OBEntryOfOtherExpenses);

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
		
	// Removing the blank mark in the "Regulated" accounting section
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesVATRate.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesSum.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesAmountExcludingVAT.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.OtherExpensesVATAmount.Name);
	
	FilterGroup = DataCompositionClientServer.AddSelectionGroup(Item.Filter.Items, DataCompositionFilterItemsGroupType.AndGroup);
	DataCompositionClientServer.AddFilter(FilterGroup, "Object.RecordInOperationalAccounting", False);
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	SetVisibility1();
	SetHeader();
	
EndProcedure

&AtServer
Procedure SetHeader()
	
	AutoTitle = False;
	
	Title = OBEntryServerCall.DocumentTitleEnteringBalancesForBusinessTransaction(Object.Ref,
		Object.Number,
		Object.Date,
		Object.BusinessOperation);
		
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	VisibilityOfAccountingGroups = Documents.OBEntryOtherExpenses.VisibilityOfAccountingGroups(Object);
	
	Items.GroupEnterBalanceBy.Visible  = VisibilityOfAccountingGroups;
	Items.PostInCostAccounting.Visible = CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(BegOfMonth(Object.Date), True);
	
	If Not VisibilityOfAccountingGroups Then
		
		// If the accounting type settings are not available, then the document can only be reflected in operational accounting.
		Object.RecordInOperationalAccounting = True;
		Items.RecordInOperationalAccounting.Visible = True;
		
		Object.PostInFinancialAndTaxAccounting = False;
		Object.RecordInMA = False;
		Object.RecordAIT = False;
		
	EndIf;
	
	Object.PostInCostAccounting = Object.RecordInOperationalAccounting; // for this operation of entering balances, it does not make sense to set these checkboxes separately
	
	CalculationOfPermanentAndTemporaryDifferencesIsKept = False;
	
	
	Items.OtherExpensesFillInByBalance.Visible = Not Object.RecordInOperationalAccounting 
		And (Object.PostInFinancialAndTaxAccounting Or Object.RecordInMA) And Not Object.Patch;
	
	
	ShowLocalAccountingDetails = Object.RecordInOperationalAccounting Or Object.PostInFinancialAndTaxAccounting;
	Items.OtherExpensesSumCompl.Visible = ShowLocalAccountingDetails;
	Items.OtherExpensesVATLocal.Visible  = ShowLocalAccountingDetails;
	Items.OtherExpensesAmountFA.Visible  = ShowLocalAccountingDetails;
	Items.OtherExpensesAmountPermanentDifferences.Visible  = ShowLocalAccountingDetails And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	Items.OtherExpensesAmountTemporaryDifferences.Visible  = ShowLocalAccountingDetails And CalculationOfPermanentAndTemporaryDifferencesIsKept;
	
	RecordsAreKeptAccordingToAIT = CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	Object.RecordAIT             = ?(RecordsAreKeptAccordingToAIT, Object.RecordAIT, False);
	Items.RecordAIT.Visible = RecordsAreKeptAccordingToAIT;
	
	ShowAITDetails = Object.RecordAIT;
	Items.OtherExpensesAITAmount.Visible = ShowAITDetails And RecordsAreKeptAccordingToAIT;
	
	ShowManAccountDetails = Object.RecordInOperationalAccounting Or Object.RecordInMA;
	Items.OtherExpensesSum.Visible = ShowManAccountDetails;
	Items.OtherExpensesAmountExcludingVAT.Visible = ShowManAccountDetails;
	Items.OtherExpensesVATAmount.Visible = ShowManAccountDetails;
	
EndProcedure

&AtServerNoContext
Function ConversionFactor_(ManagementAccountingCurrency, LocalAccountingCurrency, DocumentDate)
	
	Return ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
											ManagementAccountingCurrency,
											LocalAccountingCurrency,
											?(DocumentDate = Date(1,1,1), CurrentSessionDate(), DocumentDate));
	
EndFunction

&AtServer
Procedure OrganizationOnChangeServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	Object.Currency                  = SettingsValueCached.ManagementAccountingCurrency();
	
	If ValueIsFilled(Object.Organization) Then
		CompleteVATTaxation();
		VATTaxationOnChangeServer();
	EndIf;
	SetVisibility1();

EndProcedure

&AtServer
Procedure DateOnChangeServer()
	
	CompleteVATTaxation();
	VATTaxationOnChangeServer();
	
EndProcedure

&AtServer
Procedure ItemOfOtherExpensesInCaseOfChangeOfBudget(CachedValues)
	
	TableRow = Object.OtherExpenses.FindByID(Items.OtherExpenses.CurrentRow);
	
	StructureOfActions = New Structure("FillInAttributeAcceptedByCNU");
	BatchProcessingOfTablePartServer.ProcessTSString(TableRow, StructureOfActions, CachedValues);
	FillInPDAmount(TableRow);
	FillInAITAmount(TableRow);
	
EndProcedure

&AtServer
Procedure FillInPDAmount(TableRow)

	If Not TableRow.AcceptedByTheKNU And CalculationOfPermanentAndTemporaryDifferencesIsKept Then
		TableRow.AmountPermanentDifferences = TableRow.SumCompl;
	EndIf;

EndProcedure

&AtServer
Procedure FillInAITAmount(TableRow)
	
	RecordsAreKeptAccordingToAIT = CalculationOfCostLocalization.RecordsAreKeptAccordingToAIT(Object.Date, Object.Organization);
	ItemOfExpensesIsRecognizedInAITExpenses = ItemOfExpensesIsRecognizedInAITExpenses(TableRow.ExpenseItem);
	If RecordsAreKeptAccordingToAIT And ItemOfExpensesIsRecognizedInAITExpenses Then
		TableRow.AITAmount = TableRow.AmountFA;
	Else
		TableRow.AITAmount = 0;
	EndIf;

EndProcedure

&AtServerNoContext
Function ItemOfExpensesIsRecognizedInAITExpenses(ExpenseItem)
	
	Return CalculationOfCostLocalization.ItemOfExpensesIsRecognizedInAITExpenses(ExpenseItem);

EndFunction

#Region WorkingWithClipboard

&AtServer
Procedure CopyLinesOnServer()
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object.OtherExpenses, Items.OtherExpenses.SelectedRows);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboard()
	
	Columns = "LineOfBusiness,ExpenseItem,DimensionOfExpenses,Sum,AmountExcludingVAT,SumCompl,AmountPermanentDifferences,AmountTemporaryDifferences";
	
	TableOfRows = ProcessingOfTabularForms.RowsFromClipboard(, Columns);
	
	If Not ValueIsFilled(TableOfRows) Then
		Return;
	EndIf;
	
	For Each String In TableOfRows Do
		CurrentRow = Object.OtherExpenses.Add();
		FillPropertyValues(CurrentRow, String);
	EndDo;

EndProcedure

&AtServer
Procedure SetAvailabilityOfClipboardCommands()
	
	ItemArray = New Array();
	ItemArray.Add("OtherExpensesInsertRows");
	ItemArray.Add("OtherExpensesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled",
		ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfClipboardCommandsOnClient()
	
	ItemArray = New Array();
	ItemArray.Add("OtherExpensesInsertRows");
	ItemArray.Add("OtherExpensesContextMenuInsertRows");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "Enabled", True);
	
EndProcedure

#EndRegion

&AtServer
Procedure FillByBalancesOnServer()
	
	TabPart = FormAttributeToValue("Object.OtherExpenses");
	TabPart.Clear();
	KeyFields = Documents.OBEntryOtherExpenses.KeyFieldsOfLocalAccountingByTypeOfOperation(Object.BusinessOperation);
	Filter = New Structure;
	For Each KeyField In KeyFields Do
		If Not KeyField = "Organization" And ValueIsFilled(Object[KeyField]) Then
			Filter.Insert(KeyField, Object[KeyField]);
		EndIf;
	EndDo;
	
	Balance = Documents.OBEntryOtherExpenses.BalancesByTypeOfOperation(Object.Date, Object.BusinessOperation, Object.Organization, Filter);
	
	For Each Var_59_Balance In Balance Do
		Page1 = TabPart.Add();
		FillPropertyValues(Page1, Var_59_Balance);
	EndDo;
		
EndProcedure

&AtClient
Procedure AlertHandlerIssueFillInByBalances(QuestionResult, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillByBalancesOnServer();		
	EndIf;
	
EndProcedure

&AtServer
Procedure VATTaxationOnChangeServer()
	
	StructureOfRecalculationOfAmount = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	LocalSumRecalculationStructure = BatchProcessingOfTablePartClientServer.ParametersForRecalculatingNDSWTCHAmount(Object);
	LocalSumRecalculationStructure.PriceIncludesVAT = False;

	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInVATRate", BatchProcessingOfTablePartClientServer.ParametersForFillingInVATRate(Object));
	StructureOfActions.Insert("RecalculateVATAmount", StructureOfRecalculationOfAmount);
	StructureOfActions.Insert("RecalculateAmountWithoutVAT");
	StructureOfActions.Insert("RecalculateLocalAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateLocalVAT", LocalSumRecalculationStructure);
	StructureOfActions.Insert("RecalculatePDAmount", FactorOfConversionFromManCurrencyToRegulCurrency);
	StructureOfActions.Insert("RecalculateAmountTa");
	StructureOfActions.Insert("RecalculateAmountOfTD");
	
	BatchProcessingOfTablePartServer.TreatTS(Object.OtherExpenses, StructureOfActions, Undefined);
	
EndProcedure

&AtServer
Procedure CompleteVATTaxation()
	
	AccountingParametersForOrganization = VATAccountingERP.AccountingParametersForOrganization(Object.Organization, Object.Date);
	Object.VATActivityType = AccountingParametersForOrganization.BasicTaxationVATSales;
	
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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
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
