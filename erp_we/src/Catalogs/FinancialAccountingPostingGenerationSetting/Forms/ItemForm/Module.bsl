#Region FormEventHandlers

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)

	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations
	
	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);
	
	ManagingFormElementsDuringCreation();
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	If CurrentObject.LongDesc <> Undefined Then
		HTMLDetails = CurrentObject.LongDesc.Get();
		If HTMLDetails <> Undefined Then
			LongDesc.SetHTML(HTMLDetails.Text, HTMLDetails.Attachments);
		EndIf;
	EndIf;
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)

	If Not IsBlankString(AddressOfClosingAccounts) Then
		ClosingAccounts = GetFromTempStorage(AddressOfClosingAccounts);
		FillPropertyValues(CurrentObject, ClosingAccounts,,"IncomeAccounts,ExpenseAccounts,AccountsOfProfitLoss");
		CurrentObject.IncomeAccounts.Load(ClosingAccounts.IncomeAccounts);
		CurrentObject.ExpenseAccounts.Load(ClosingAccounts.ExpenseAccounts);
		CurrentObject.AccountsOfProfitLoss.Load(ClosingAccounts.AccountsOfProfitLoss);
		DeleteFromTempStorage(AddressOfClosingAccounts);
		AddressOfClosingAccounts = "";
	EndIf;
	
	If Not IsBlankString(AddressOfExchangeRateDifferenceAccounts) Then
		ForeignExchangeAccounts = GetFromTempStorage(AddressOfExchangeRateDifferenceAccounts);
		FillPropertyValues(CurrentObject, ForeignExchangeAccounts,,"ExcludeFromRecalculationToPresentationCurrency");
		Catalogs.FinancialAccountingPostingGenerationSetting.RecordInvoicesForCalculatingKr(
			Object.Owner,
			ForeignExchangeAccounts.ExcludeFromTheCalculationOfTheKR);
		CurrentObject.ExcludeFromRecalculationToPresentationCurrency.Load(ForeignExchangeAccounts.ExcludeFromRecalculationToPresentationCurrency);
		DeleteFromTempStorage(AddressOfExchangeRateDifferenceAccounts);
		AddressOfExchangeRateDifferenceAccounts = "";
	EndIf;
	
	HTMLDetails = New Structure("Text, Attachments","",New Structure);
	LongDesc.GetHTML(HTMLDetails.Text, HTMLDetails.Attachments);
	CurrentObject.LongDesc = New ValueStorage(HTMLDetails,New Deflation(9));
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtClient
Procedure  AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

	// Handler of the subsystem prohibiting editing of object details
	ObjectAttributesLock.LockAttributes(ThisObject);

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	ManagingFormElementsWhenOpening();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ClosingOfIncomeAndExpenseAccountsOnChange(Item)
	
	ManagingVisibilityOfAccountSettingsForClosingPeriod(ThisObject);
	
EndProcedure

&AtClient
Procedure CommentStartChoice(Item, ChoiceData, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(
		Item.EditText, 
		ThisObject, 
		"Object.Comment");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)
	 FilesOperationsClient.PreviewFieldDrag(ThisObject, Item, DragParameters, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)
	 FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);
EndProcedure
// End StandardSubsystems.FilesOperations

// StandardSubsystems.ObjectAttributesLock
&AtClient
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	FullFormName = "Catalog.FinancialAccountingPostingGenerationSetting.Form.AttributeUnlocking";
	FormParameters = New Structure("PostingGenerationSetting", Object.Ref);
	NotificationForms = New CallbackDescription("Attachable_AllowObjectAttributeEditCompletion", ThisObject);
	
	OpenForm(
		FullFormName,
		FormParameters,
		ThisObject,,,,
		NotificationForms,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Attachable_AllowObjectAttributeEditCompletion(Result, AdditionalParameters) Export
	
	If TypeOf(Result) = Type("Array") And Result.Count() > 0 Then
		ObjectAttributesLockClient.SetFormItemEnabled(ThisObject, Result);
	EndIf;
	
EndProcedure
// End StandardSubsystems.ObjectAttributesLock

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Object);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Object, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure
// End StandardSubsystems.AttachableCommands

&AtClient
Procedure OpenTheSetupOfTransactionsBasedOnOperationalAccountingData(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.ChartOfAccounts = Object.Owner;
	FormParameters.PostingGenerationSetting = Object.Ref;
	FinancialAccountingUponOperationalAccountingDataClient.OpenSettingsForTransactionTemplates(FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTheSetupOfTransactionsBasedOnTheAccountingReglData(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.ChartOfAccounts = Object.Owner;
	FormParameters.PostingGenerationSetting = Object.Ref;
	FinancialAccountingUponLocalAccountingClient.OpenAccountsAndTurnoverMatchingSettings(FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure OpenTransactionSettingsForAccountingItems(Command)
	
	FormParameters = FinancialAccountingClient.ParametersForOpeningTransactionConfigurationForms();
	FormParameters.ChartOfAccounts = Object.Owner;
	FormParameters.PostingGenerationSetting = Object.Ref;
	FinancialAccountingByFinancialRegisterDataClient.OpenInvoiceSettingsForAccountingObjects(FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure ConfigureOfMonthEndClosingGLAccounts(Command)
	
	CheckObjectRecord(NStr("vi = 'Tùy chỉnh tài khoản đóng kỳ';
							|ru = 'Настройке счетов закрытия периода';
							|en = 'Set up period-end closing accounts'; fa = 'Set up period-end closing accounts';
							|it = 'Impostazione dei conti di chiusura del periodo';
							|pl = 'Ustawienia rachunków zamknięcia okresu';
							|tr = 'Dönem sonu kapanış hesap ayarlarına'"), Command.Name);
	
EndProcedure

&AtClient
Procedure SetUpExchangeRateDifferences(Command)
	
	CheckObjectRecord(NStr("vi = 'Thiết lập chênh lệch tỷ giá';
							|ru = 'Настройке курсовых разниц';
							|en = 'Setting of exchange differences'; fa = 'Setting of exchange differences';
							|it = 'Impostazione delle differenza dei tassi di cambio';
							|pl = 'Ustawienia różnic kursowych';
							|tr = 'Döviz kuru farkları ayarına'"), Command.Name);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure ManagingFormElementsDuringCreation()
	
	Items.Owner.Visible = GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting");
	
	ManagingVisibilityOfAccountSettingsForClosingPeriod(ThisObject);
	
EndProcedure

&AtClient
Procedure ManagingFormElementsWhenOpening()
	
	If TypeOf(ThisObject.FormOwner) = Type("ClientApplicationForm") Then
		OwnerFormName = ThisObject.FormOwner.FormName;
		If StrStartsWith(OwnerFormName, "DataProcessor.SettingUpFinancialAccountingAccounts")
		 Or StrStartsWith(OwnerFormName, "DataProcessor.PostingTemplatesSetupForFinancialAccounting") Then
			Items.OpenTransactionSettingsForAccountingItems.Visible = False;
			Items.OpenTheSettingForGeneratingTransactionsBasedOnOperationalAccountingData.Visible = False;
			Items.ToOpenTheConfigurationOfTheFormationTransactionsAccordingToTheAccountingREP.Visible = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure CheckObjectRecord(Var_FormName, CommandName)
	
	If Not ValueIsFilled(Object.Ref) Then
		
		QueryText = NStr("vi = 'Dữ liệu vẫn chưa được ghi lại.
								|Chỉ có thể chuyển đến ""%FormName%"" sau khi ghi lại dữ liệu.
								|Dữ liệu sẽ được ghi lại.';
								|ru = 'Данные еще не записаны.
								|Переход к ""%FormName%"" возможен только после записи данных.
								|Данные будут записаны.';
								|en = 'Data is not saved yet.
								|You can go to ""%FormName%"" only after saving the data.
								|Data will be saved.'; fa = 'Data is not saved yet.
								|You can go to ""%FormName%"" only after saving the data.
								|Data will be saved.';
								|it = 'I dati non sono ancora stati registrati.
								|Il passaggio a ""%FormName%"" è possibile solo dopo la registrazione dei dati.
								|I dati verranno registrati.';
								|pl = 'Dane nie zostały jeszcze zapisane.
								|Przejście do ""%FormName%"" jest możliwe tylko po zapisaniu danych.
								|Dane zostaną zapisane.';
								|tr = 'Veriler henüz kaydedilmedi.
								|""%FormName%"" geçiş sadece verilerin kaydından sonra mümkündür.
								|Veriler kaydedilecektir.'");
		QueryText = StrReplace(QueryText, "%FormName%", Var_FormName);
		
		ShowQueryBox(New CallbackDescription("ProcessingResponseToQuestionSave", ThisObject, CommandName),
						QueryText,
						QuestionDialogMode.OKCancel);
		
		Return;
		
	EndIf;
	
	ConfigureAccounts_(CommandName);
	
EndProcedure

&AtClient
Procedure ProcessingResponseToQuestionSave(Response, CommandName) Export
	
	If Response = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	ItemRecorded = Write();
	If Not ItemRecorded Then
		Return;
	EndIf;
	
	ConfigureAccounts_(CommandName);
	
EndProcedure

&AtClient
Procedure ConfigureAccounts_(CommandName)
	
	If CommandName = "ConfigureOfMonthEndClosingGLAccounts" Then
	
		If IsBlankString(AddressOfClosingAccounts) Then
			PlaceClosingAccountsInVault();
		EndIf;
		
		FormParameters = New Structure();
		FormParameters.Insert("ChartOfAccounts", Object.Owner);
		FormParameters.Insert("AddressOfAccountSettings", AddressOfClosingAccounts);
		Handler = New CallbackDescription("SaveAccountSettings",ThisForm);
		OpenForm("Catalog.FinancialAccountingPostingGenerationSetting.Form.ConfigureOfMonthEndClosingGLAccounts", FormParameters, ThisForm,,,,Handler);
		
	ElsIf CommandName = "SetUpExchangeRateDifferences" Then
	
		If IsBlankString(AddressOfExchangeRateDifferenceAccounts) Then
			PlaceExchangeRateAccountsInVault();
		EndIf;
	
		FormParameters = New Structure();
		FormParameters.Insert("ChartOfAccounts", Object.Owner);
		FormParameters.Insert("AddressOfAccountSettings", AddressOfExchangeRateDifferenceAccounts);
		Handler = New CallbackDescription("SaveAccountSettings",ThisForm);
		OpenForm("Catalog.FinancialAccountingPostingGenerationSetting.Form.ConfigureOfExchangeDifferenceGLAccounts", FormParameters, ThisForm,,,,Handler);
		
	EndIf;
	
EndProcedure

&AtClient
Function SaveAccountSettings(Result, Parameter) Export

	If Result = QuestionDialogMode.OK Then
		Modified = True;
	EndIf;

EndFunction // Save the account of the closure()

&AtServer
Procedure PlaceClosingAccountsInVault()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TransactionGenerationSettings.GLAccountOfIncome,
	|	TransactionGenerationSettings.GLAccountOfExpenses,
	|	TransactionGenerationSettings.GLAccountOfRetainedProfitLoss,
	|	TransactionGenerationSettings.IncomeAccounts.(
	|		Account
	|	),
	|	TransactionGenerationSettings.ExpenseAccounts.(
	|		Account
	|	),
	|	TransactionGenerationSettings.AccountsOfProfitLoss.(
	|		Account
	|	)
	|FROM
	|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|WHERE
	|	TransactionGenerationSettings.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.Ref);
	
	Selection = Query.Execute().Select();
	ClosingAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ClosingAccounts();
	If Selection.Next() Then
		FillPropertyValues(ClosingAccounts, Selection,,"IncomeAccounts,ExpenseAccounts,AccountsOfProfitLoss");
		ClosingAccounts.IncomeAccounts = Selection.IncomeAccounts.Unload();
		ClosingAccounts.ExpenseAccounts = Selection.ExpenseAccounts.Unload();
		ClosingAccounts.AccountsOfProfitLoss = Selection.AccountsOfProfitLoss.Unload();
	EndIf;
	AddressOfClosingAccounts = PutToTempStorage(ClosingAccounts, UUID);
	
EndProcedure

&AtServer
Procedure PlaceExchangeRateAccountsInVault()
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TransactionGenerationSettings.ForeignExchangeGain,
	|	TransactionGenerationSettings.IncomeItemForExchangeDifferences,
	|	TransactionGenerationSettings.GLAccountOfExchangeLoss,
	|	TransactionGenerationSettings.ExpenseItemForExchangeLoss,
	|	TransactionGenerationSettings.IncomeFromTranslationToPresentationCurrency,
	|	TransactionGenerationSettings.IncomeExpenseItemForRecalculationVariances,
	|	TransactionGenerationSettings.ExpensesDifferencesArisingFromConversionToPresentationCurrency,
	|	TransactionGenerationSettings.ExpenseItemForTranslationsReserve,
	|	TransactionGenerationSettings.ExcludeFromRecalculationToPresentationCurrency.(
	|		Account
	|	)
	|FROM
	|	Catalog.FinancialAccountingPostingGenerationSetting AS TransactionGenerationSettings
	|WHERE
	|	TransactionGenerationSettings.Ref = &Ref";
	
	Query.SetParameter("Ref", Object.Ref);
	
	Selection = Query.Execute().Select();
	ClosingAccounts = Catalogs.FinancialAccountingPostingGenerationSetting.ForeignExchangeAccounts();
	If Selection.Next() Then
		FillPropertyValues(ClosingAccounts, Selection,,"ExcludeFromRecalculationToPresentationCurrency");
		ClosingAccounts.ExcludeFromTheCalculationOfTheKR = Catalogs.FinancialAccountingPostingGenerationSetting.AccountsForCalculationOfKR(Object.Owner);
		ClosingAccounts.ExcludeFromRecalculationToPresentationCurrency = Selection.ExcludeFromRecalculationToPresentationCurrency.Unload();
	EndIf;
	AddressOfExchangeRateDifferenceAccounts = PutToTempStorage(ClosingAccounts, UUID);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ManagingVisibilityOfAccountSettingsForClosingPeriod(Form)
	
	Object = Form.Object;
	Items = Form.Items;
	
	ThereIsClosingOfAccounts = Object.ClosingOfIncomeAndExpenseAccounts = PredefinedValue("Enum.ClosingOfIncomeAndExpenseAccounts.Monthly")
		Or Object.ClosingOfIncomeAndExpenseAccounts = PredefinedValue("Enum.ClosingOfIncomeAndExpenseAccounts.AtYearEnd");
	
	Items.ConfigureOfMonthEndClosingGLAccounts.Visible = ThereIsClosingOfAccounts;
	
EndProcedure


#EndRegion