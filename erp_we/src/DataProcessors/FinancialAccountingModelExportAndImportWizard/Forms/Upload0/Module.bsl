#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	FillInChartOfAccountsTable();
	FillInTableOfTypesOfFinancialStatements();
	FillInTransactionGenerationSettingsTable();
	FillInTableOfSetsOfFinancialReports();
	FillInTableOfAssetsLiabilitiesArticles();
	FillInTableTypicalOperations();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	ExecutedImportStatus = False;
	// Setting the current transition table
	ScriptTransitions();
	// Positioning ourselves at the first step of the assistant
	SetNavigationNumber(1);
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure ModelFileNameStartChoice(Item, ChoiceData, StandardProcessing)
	
	CallbackDescription = New CallbackDescription("ModelFileNameExtensionEnabled", ThisObject);
	FileSystemClient.AttachFileOperationsExtension(CallbackDescription);
	
EndProcedure

&AtClient
Procedure UploadAccountPlansOnChange(Item)
	Items.FilterChartOfAccounts.Enabled = UploadAccountPlans;
	MarkItemsInTable(UploadAccountPlans, TableOfAccountPlans);
	SetTitleOfSelectionHyperlink(Items.FilterChartOfAccounts, TableOfAccountPlans);
	ProcessDependentSelectionsFromChartOfAccounts();
EndProcedure

&AtClient
Procedure UploadTypesOfFinancialReportsOnChange(Item)
	Items.FilterFinancialReportTypes.Enabled = UploadTypesOfFinancialReports;
	MarkItemsInTable(UploadTypesOfFinancialReports, TableTypesOfFinancialStatements);
	SetTitleOfSelectionHyperlink(Items.FilterFinancialReportTypes, TableTypesOfFinancialStatements);
	UploadTypesOfFinancialReportsOnChangeServer();
EndProcedure

&AtClient
Procedure UploadSettingsForGeneratingTransactionsOnChange(Item)
	Items.SelectingSettingsForGeneratingTransactions.Enabled = UploadSettingsForGeneratingTransactions;
	SetTitleOfSelectionHyperlink(Items.SelectingSettingsForGeneratingTransactions, TableForSettingUpFormationOfTransactions);
EndProcedure

&AtClient
Procedure UploadSetsOfFinancialReportsOnChange(Item)
	Items.FilterFinancialReportSets.Enabled = UploadSetsOfFinancialReports;
	MarkItemsInTable(UploadSetsOfFinancialReports, TableOfSetsOfFinancialReports);
	SetTitleOfSelectionHyperlink(Items.FilterFinancialReportSets, TableOfSetsOfFinancialReports);
	UploadSetsOfFinancialReportsOnChangeServer();
EndProcedure

&AtClient
Procedure UploadTypicalOperationsOnChange(Item)
	Items.StandartOperationsFilter.Enabled = UploadTypicalOperations;
	SetTitleOfSelectionHyperlink(Items.StandartOperationsFilter, TableStandartOperations);
EndProcedure

&AtClient
Procedure UnloadItemsOfAssetsLiabilitiesOnChange(Item)
	Items.FilterAssetLiabilityItems.Enabled = UnloadItemsOfAssetsLiabilities;
	MarkItemsInTable(UnloadItemsOfAssetsLiabilities, TableOfAssetsLiabilitiesItems);
	SetTitleOfSelectionHyperlink(Items.FilterAssetLiabilityItems, TableOfAssetsLiabilitiesItems);
	UnloadItemsOfAssetsLiabilitiesOnChangeServer();
EndProcedure

&AtClient
Procedure TypesOfFinancialStatementsClickSelection(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableTypesOfFinancialStatements));
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.FinancialReportKindFilter",
		FormParameters,
		ThisObject,,,,
		New CallbackDescription("UpdateTypesOfFinancialStatementsTable", ThisObject),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FilterChartOfAccountsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", TemporaryStorageOfChartOfAccountsSelectionStructure());
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.ChartsOfAccountsFilter",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateChartOfAccountsTable", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);

	
EndProcedure

&AtClient
Procedure FilterFinancialReportSetsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableOfSetsOfFinancialReports));
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.FinancialReportSetFilter",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateFinancialReportSetsTable", ThisObject),   
				FormWindowOpeningMode.LockOwnerWindow);

	
EndProcedure

&AtClient
Procedure SelectingSettingsForGeneratingTransactionsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableForSettingUpFormationOfTransactions));
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.SelectingSettingsForGeneratingTransactions",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateTransactionGenerationSettingsTable", ThisObject), 
				FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure StandartOperationsFilterClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableStandartOperations));
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.StandartOperationsFilter",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateTypicalOperationsTable", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure FilterAssetLiabilityItemsClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("AddressInTempStorage", FormTableToTemporaryStorage(TableOfAssetsLiabilitiesItems));
	
	OpenForm("DataProcessor.FinancialAccountingModelExportAndImportWizard.Form.FilterAssetLiabilityItems",
				FormParameters,
				ThisObject,,,,
				New CallbackDescription("UpdateTableOfAssetsLiabilitiesArticles", ThisObject),
				FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure DetailedInformationClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("Data", SynonymOfProcessing());
	
	FilterByLevel = New ValueList;
	FilterByLevel.Add("Error", "Error");
	FormParameters.Insert("Level", FilterByLevel);
	
	OpenForm("DataProcessor.EventLog.Form.EventLog", FormParameters);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NextCommand(Command)
	
	ChangeNavigationNumber(+1);
	
EndProcedure

&AtClient
Procedure BackCommand(Command)
	
	ChangeNavigationNumber(-1);
	
EndProcedure

&AtClient
Procedure DoneCommand(Command)
	
	Close();
	
EndProcedure

&AtClient
Procedure CancelCommand(Command)
	
	Close();
	
EndProcedure

#EndRegion

#Region Private

#Region SectionInitializingTransitionsInAssistant

// Transition parameters.
// 
// Returns:
//  Structure - Transition Parameters:
// * NavigationNumber - Number -
// * MainPageName - String -
// * NavigationPageName - String -
// * DecorationPageName - String -
// * OnOpenHandlerName - String -
// * NameOfTheHandlerAfterOpening - String -
// * OnNavigationToNextPageHandlerName - String -
// * OnSwitchToPreviousPageHandlerName - String -
&AtClient
Function MigrationParameters()
	
	MigrationParameters = New Structure;
	MigrationParameters.Insert("NavigationNumber", 0);
	MigrationParameters.Insert("MainPageName", "");
	MigrationParameters.Insert("NavigationPageName", "");
	MigrationParameters.Insert("DecorationPageName", "");
	MigrationParameters.Insert("OnOpenHandlerName", "");
	MigrationParameters.Insert("NameOfTheHandlerAfterOpening", "");
	MigrationParameters.Insert("OnNavigationToNextPageHandlerName", "");
	MigrationParameters.Insert("OnSwitchToPreviousPageHandlerName", "");
	
	Return MigrationParameters;
	
EndFunction

&AtClient
Procedure ScriptTransitions()

	Transitions.Clear();

	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 1;
	MigrationParameters.MainPageName = "PageGreeting";
	MigrationParameters.NavigationPageName = "NavigationStartPage";
	MigrationParameters.DecorationPageName = "DecorationPageStart";
	MigrationParameters.OnOpenHandlerName = "PageGreetingOnOpen";
	MigrationParameters.OnNavigationToNextPageHandlerName = "PageGreetingOnOpenNext";
	AddTransition(MigrationParameters);

	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 2;
	MigrationParameters.MainPageName = "WaitingPage";
	MigrationParameters.NavigationPageName = "NavigationWaitPage";
	MigrationParameters.DecorationPageName = "PageSceneryWaiting";
	MigrationParameters.OnOpenHandlerName = "WaitingPageOnOpen";
	MigrationParameters.NameOfTheHandlerAfterOpening = "WaitingPageAfterOpen";
	AddTransition(MigrationParameters);

	MigrationParameters = MigrationParameters();
	MigrationParameters.NavigationNumber = 3;
	MigrationParameters.MainPageName = "PageCompletion";
	MigrationParameters.NavigationPageName = "NavigationEndPage";
	MigrationParameters.DecorationPageName = "DecorationPageEnd";
	MigrationParameters.OnOpenHandlerName = "PageCompletionOnOpen";
	AddTransition(MigrationParameters);

EndProcedure


// Add a transition.
// 
// Parameters:
//  MigrationParameters - See MigrationParameters
&AtServer
Procedure AddTransition(MigrationParameters)

	NewRow = Transitions.Add();

	NewRow.NavigationNumber = MigrationParameters.NavigationNumber;
	NewRow.MainPageName     = MigrationParameters.MainPageName;
	NewRow.DecorationPageName    = MigrationParameters.DecorationPageName;
	NewRow.NavigationPageName    = MigrationParameters.NavigationPageName;

	NewRow.OnNavigationToNextPageHandlerName = MigrationParameters.OnNavigationToNextPageHandlerName;
	NewRow.OnSwitchToPreviousPageHandlerName = MigrationParameters.OnSwitchToPreviousPageHandlerName;
	NewRow.OnOpenHandlerName      = MigrationParameters.OnOpenHandlerName;
	NewRow.NameOfTheHandlerAfterOpening    = MigrationParameters.NameOfTheHandlerAfterOpening;

EndProcedure

&AtClient
Procedure ChangeNavigationNumber(Iterator_SSLy)

	ClearMessages();
	SetNavigationNumber(NavigationNumber + Iterator_SSLy);

EndProcedure

&AtClient
Procedure SetNavigationNumber(Val Value)

	IsMoveNext = (Value > NavigationNumber);
	NavigationNumber = Value;
	If NavigationNumber < 0 Then
		NavigationNumber = 0;
	EndIf;
	NavigationNumberOnChange(IsMoveNext);

EndProcedure

&AtClient
Procedure NavigationNumberOnChange(Val IsMoveNext)
	
	// Click event handlers
	If IsMoveNext Then

		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber - 1));

		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;

		NavigationRow = NavigationRows[0];
		
		// The handler is later
		If Not IsBlankString(NavigationRow.OnNavigationToNextPageHandlerName) Then

			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnNavigationToNextPageHandlerName);

			Cancel = False;
			Result = Eval(ProcedureName);
			
			If Cancel Then
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;

		EndIf;

	Else

		NavigationRows = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber + 1));

		If NavigationRows.Count() = 0 Then
			Return;
		EndIf;

		NavigationRow = NavigationRows[0];
		
		// The handler is pre-transitioned
		If Not IsBlankString(NavigationRow.OnSwitchToPreviousPageHandlerName) Then

			ProcedureName = "Attachable_[HandlerName](Cancel)";
			ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRow.OnSwitchToPreviousPageHandlerName);

			Cancel = False;
			Result = Eval(ProcedureName);

			If Cancel Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			EndIf;

		EndIf;

	EndIf;

	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));

	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;

	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// handler for opening
	If Not IsBlankString(NavigationRowCurrent.OnOpenHandlerName) Then

		ProcedureName = "Attachable_[HandlerName](Cancel, SkipPage, IsMoveNext)";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.OnOpenHandlerName);

		Cancel = False;
		SkipPage = False;

		Result = Eval(ProcedureName);

		If Cancel Then
			SetNavigationNumber(NavigationNumber - 1);
			Return;
		ElsIf SkipPage Then
			If IsMoveNext Then
				SetNavigationNumber(NavigationNumber + 1);
				Return;
			Else
				SetNavigationNumber(NavigationNumber - 1);
				Return;
			EndIf;
		EndIf;
	EndIf;
	
	// Setting the current page display
	Items.PanelMain.CurrentPage  = Items[NavigationRowCurrent.MainPageName];
	Items.NavigationPanel.CurrentPage = Items[NavigationRowCurrent.NavigationPageName];

	AttachIdleHandler("ExecuteHandlerAfterOpening", 0.1, True);

EndProcedure

&AtClient
Procedure ExecuteHandlerAfterOpening()
	
	NavigationRowsCurrent = Transitions.FindRows(New Structure("NavigationNumber", NavigationNumber));
	
	If NavigationRowsCurrent.Count() = 0 Then
		Return;
	EndIf;
	
	NavigationRowCurrent = NavigationRowsCurrent[0];
	
	// Post-opening handler
	If Not IsBlankString(NavigationRowCurrent.NameOfTheHandlerAfterOpening) Then
		
		ProcedureName = "Attachable_[HandlerName]()";
		ProcedureName = StrReplace(ProcedureName, "[HandlerName]", NavigationRowCurrent.NameOfTheHandlerAfterOpening);
		
		Result = Eval(ProcedureName);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region TransitionEventHandlersSection

&AtClient
Function Attachable_PageGreetingOnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	Items.NextCommand.DefaultButton = True;
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageGreetingOnOpenNext(Cancel)

	ClearMessages();

	If Not ValueIsFilled(TrimAll(Object.ModelFileName)) Then
		CommonClient.MessageToUser(
			NStr("vi = 'Chưa chỉ ra đường dẫn đến tệp dữ liệu';
				|ru = 'Не указан путь к файлу с данными';
				|en = 'Path to the file with data is not specified'; fa = 'Path to the file with data is not specified';
				|it = 'Non è stato specificato il percorso al file dei dati';
				|pl = 'Nie jest podana ścieżka do pliku z danymi';
				|tr = 'Veri dosyasının yolu belirtilmemiş'"), , "ModelFileName", "ModelFileName", Cancel);
	EndIf;

	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_PageCompletionOnOpen(Cancel, SkipPage, Val IsMoveNext)

	Items.DoneCommand.DefaultButton = True;
	Items.DetailedInformation.Visible = Not ExecutedImportStatus;
	Items.DownloadStatusLabel.Title = ?(ExecutedImportStatus, NStr("vi = 'Đã kết xuất thành công';
																	|ru = 'Выгрузка успешно завершена';
																	|en = 'Successfully imported'; fa = 'Successfully imported';
																	|it = 'Upload terminato cono successo';
																	|pl = 'Ładowanie zostało pomyślnie ukończone';
																	|tr = 'Yükleme işlemi başarıyla tamamlandı'"),
		NStr("vi = 'Chưa kết xuất';
			|ru = 'Выгрузка не выполнена';
			|en = 'Export failed'; fa = 'Export failed';
			|it = 'Upload non completato';
			|pl = 'Nie wykonano eksportu';
			|tr = 'Yükleme işlemi tamamlanmadı'"));

	Items.LabelOfContinuationOptions.Title = ?(ExecutedImportStatus, NStr(
		"vi = 'Hãy nhấn nút ""Đồng ý"" để thoát khỏi trợ giúp.';
		|ru = 'Нажмите кнопку ""Готово"" для выхода из помощника.';
		|en = 'Click ""Finish"" to exit the wizard.'; fa = 'برای خروج از ویزارد روی «پایان» کلیک کنید.';
		|it = 'Cliccare il pulsante ""Completato"" per uscire dall''assistente.';
		|pl = 'Wciśnij przycisk ""Gotowe"", aby wyjść z asystenta.';
		|tr = 'Sihirbazdan çıkmak için ""Bitti"" butonuna tıklayın.'"), NStr(
		"vi = 'Để thử kết xuất một lần nữa, hãy nhấn nút ""Quay lại"", để thoát khỏi trợ giúp, hãy nhấn nút ""Đồng ý""';
		|ru = 'Для того чтобы попробовать выгрузить еще раз, нажмите ""Назад"", для выхода из помощника, нажимите ""Готово""';
		|en = 'To try to export again, click ""Back"". To exit the wizard, click ""Finish""'; fa = 'To try to export again, click ""Back"". To exit the wizard, click ""Finish""';
		|it = 'Per provare l''upload un''altra volta, cliccare su ""Indietro"" per uscire dall''assistente cliccare su ""Pronto""';
		|pl = 'Aby spróbować eksportować jeszcze raz, naciśnij przycisk ""Wstecz"", aby wyjść z kreatora, kliknij przycisk ""Zakończ""';
		|tr = 'Tekrar yüklemeyi denemek için ""Geri""ye basın, sihirbazdan çıkmak için ""Tamam""a basın'"));

	FillInSummaryInformation();

	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPageOnOpen(Cancel, SkipPage, Val IsMoveNext)
	
	If Not IsMoveNext Then
		SkipPage = True;
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtClient
Function Attachable_WaitingPageAfterOpen()
	
	TimeConsumingOperation = UploadToServer();
	If TimeConsumingOperation <> Undefined Then
		CallbackOnCompletion = New CallbackDescription("RecordResult", ThisObject, StorageAddress);
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region Other

&AtServer
Function UploadToServer()
	
	UploadData_0 = ExportImportOfFinancialAccountingAndBudgetingModels.UnloadingDataTable();
	
	If UploadAccountPlans Then
		
		SelectedAccountPlans = SelectedAccountPlans();
		
		MetadataObjectsList = Metadata.Catalogs.FinancialAccountingChartsOfAccounts;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedAccountPlans);
		
		MetadataObjectsList = Metadata.ChartsOfAccounts.International;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0,
									MetadataObjectsList,
									Undefined,
									SelectedAccountPlans,
									Metadata.ChartsOfAccounts.International.Attributes.ChartOfAccounts.Name);
		
		If UploadData_0.Find(MetadataObjectsList.FullName(), "MDName") <> Undefined
			And SelectedAccountPlans.Count() Then
			MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.FinancialExtraDimensionTypes;
			ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		EndIf;
		
	EndIf;
	
	If UploadTypesOfFinancialReports Then
		
		SelectedTypesOfFinancialStatements = SelectedTypesOfFinancialStatements();
	
		MetadataObjectsList = Metadata.Catalogs.FinancialReportTypes;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedTypesOfFinancialStatements);
		
		MetadataObjectsList = Metadata.Catalogs.FinancialReportItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedTypesOfFinancialStatements, "Owner");
		
	EndIf;
	
	If UploadSetsOfFinancialReports Then
		MetadataObjectsList = Metadata.Catalogs.FinancialReportSets;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSetsOfFinancialStatements());
	EndIf;
	
	If UnloadItemsOfAssetsLiabilities Then
		MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.AssetLiabilityItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedItemsOfAssetsLiabilities());
	EndIf;
	
	If UploadSettingsForGeneratingTransactions Then
		
		SelectedSettingsForGeneratingTransactions = SelectedSettingsForGeneratingTransactions();
		MDSelectionObject = Metadata.Catalogs.FinancialAccountingPostingGenerationSetting;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MDSelectionObject, Undefined, SelectedSettingsForGeneratingTransactions);
		
		MetadataObjectsList = Metadata.InformationRegisters.RulesOfPostingsInFinancialAccounting;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSettingsForGeneratingTransactions, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.BusinessTransactionsNotPostedInFinancialAccounting;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSettingsForGeneratingTransactions, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsForReflectingCorrespondenceInFinancialAccounting;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSettingsForGeneratingTransactions, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsOfFinancialAccountingAccountsByObject;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSettingsForGeneratingTransactions, NameOfTheDimensionToSelect);
		
		MetadataObjectsList = Metadata.InformationRegisters.SettingsForFillingExtraDimensionOnFinancialAccountingAccounts;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedSettingsForGeneratingTransactions, NameOfTheDimensionToSelect);
		
		TemplatesOfTransactionsToBeUploaded = TemplatesOfTransactionsForInternationalAccountingForUnloading(SelectedSettingsForGeneratingTransactions);
		MDSelectionObject = Metadata.Catalogs.PostingTemplatesForFinancialAccounting;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MDSelectionObject, Undefined, TemplatesOfTransactionsToBeUploaded);
		
		MetadataObjectsList = Metadata.InformationRegisters.RulesOfSpecifyingAccountsFinancialAccounting;
		NameOfTheDimensionToSelect = ExportImportOfFinancialAccountingAndBudgetingModels.NameOfTheDimensionToSelect(MDSelectionObject, MetadataObjectsList);
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, TemplatesOfTransactionsToBeUploaded, NameOfTheDimensionToSelect);
		
	EndIf;
	
	If UploadTypicalOperations Then
		MetadataObjectsList = Metadata.Catalogs.StandardTransactionsOfFinancialAccounting;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList, Undefined, SelectedStandartOperations());
	EndIf;
	
	If UnloadFinancialAccountingGroups Then
		
		MetadataObjectsList = Metadata.Catalogs.FinancialAccountingGroupsOfARAP;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
		MetadataObjectsList = Metadata.Catalogs.GroupsOfFinancialAccountingOfCash;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
		MetadataObjectsList = Metadata.Catalogs.IncomeExpensesAccountingGroups;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
		MetadataObjectsList = Metadata.Catalogs.InventoryAccountingGroups;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
	EndIf;
	
	If UnloadCashFlowItems Then
		MetadataObjectsList = Metadata.Catalogs.CashFlowReportItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
	EndIf;
	
	If UnloadIncomeAndExpenseItems Then
		
		MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.IncomeItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
		MetadataObjectsList = Metadata.ChartsOfCharacteristicTypes.ExpenseItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
	EndIf;
	
	If ToUnloadFAandIAGroups Then
		
		MetadataObjectsList = Metadata.Catalogs.IntangibleAssetsGroups;
			ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
		MetadataObjectsList = Metadata.Catalogs.FixedAssetsGroupsFinancialAccounting;
			ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
		
	EndIf;
	
	If UploadNonMonetaryIndicators Then
		MetadataObjectsList = Metadata.Catalogs.NonMonetaryItems;
		ExportImportOfFinancialAccountingAndBudgetingModels.AddRowToUploadData(UploadData_0, MetadataObjectsList);
	EndIf;
	
	JobParameters = New Structure;
	JobParameters.Insert("UploadData_0", UploadData_0);
	JobParameters.Insert("ThisIsInternationalAccountingModel", True);
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	JobParameters.Insert("StorageAddress", StorageAddress);
	
	MethodName = "ExportImportOfFinancialAccountingAndBudgetingModels.ExportAccountingModel";
	
	StartSettings1 = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	StartSettings1.BackgroundJobDescription = SynonymOfProcessing();
	StartSettings1.WaitCompletion = 0;
	
	Return TimeConsumingOperations.ExecuteProcedure(StartSettings1, MethodName, JobParameters);
	
EndFunction

&AtServer
Function SelectedAccountPlans()
	
	ReferencesArrray = New Array;
	
	For Each String In TableOfAccountPlans Do
		If String.Check Then
			ReferencesArrray.Add(String.ChartOfAccounts);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function SelectedTypesOfFinancialStatements()
	
	ReferencesArrray = New Array;
	
	For Each String In TableTypesOfFinancialStatements Do
		If String.Check Then
			ReferencesArrray.Add(String.FinancialReportType);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function SelectedSetsOfFinancialStatements()
	
	ReferencesArrray = New Array;
	
	For Each String In TableOfSetsOfFinancialReports Do
		If String.Check Then
			ReferencesArrray.Add(String.SetOfFinancialReport);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function SelectedItemsOfAssetsLiabilities()
	
	ReferencesArrray = New Array;
	
	For Each String In TableOfAssetsLiabilitiesItems Do
		If String.Check Then
			ReferencesArrray.Add(String.AssetAndLiabilityItem);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function SelectedSettingsForGeneratingTransactions()
	
	ReferencesArrray = New Array;
	
	For Each String In TableForSettingUpFormationOfTransactions Do
		If String.Check Then
			ReferencesArrray.Add(String.SettingUpFormationOfInternationalAccountingTransactions);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function SelectedStandartOperations()
	
	ReferencesArrray = New Array;
	
	For Each String In TableStandartOperations Do
		If String.Check Then
			ReferencesArrray.Add(String.StandartOperation);
		EndIf;
	EndDo;
	
	Return ReferencesArrray;
	
EndFunction

&AtServer
Function TemplatesOfTransactionsForInternationalAccountingForUnloading(SelectedSettingsForGeneratingTransactions)
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	RulesOfPostingsInFinancialAccounting.PostingTemplate AS PostingTemplate
		|FROM
		|	InformationRegister.RulesOfPostingsInFinancialAccounting AS RulesOfPostingsInFinancialAccounting
		|WHERE
		|	RulesOfPostingsInFinancialAccounting.PostingGenerationSetting IN (&PostingGenerationSetting)";
	
	Query.SetParameter("PostingGenerationSetting", SelectedSettingsForGeneratingTransactions);
	
	Return Query.Execute().Unload().UnloadColumn("PostingTemplate");
	
EndFunction

&AtServer
Procedure UploadTypesOfFinancialReportsOnChangeServer()
	
	SetProgramSelectionOfChartOfAccounts();
	
	RelatedSelectionIsEnabled = UploadTypesOfFinancialReports Or UnloadItemsOfAssetsLiabilities;
	EnableDisableUnloading(UploadAccountPlans,
							Items.UploadAccountPlans,
							Items.FilterChartOfAccounts,
							TableOfAccountPlans,
							RelatedSelectionIsEnabled);
	
EndProcedure

&AtServer
Procedure UnloadItemsOfAssetsLiabilitiesOnChangeServer()
	
	SetProgramSelectionOfChartOfAccounts();

	RelatedSelectionIsEnabled = UploadTypesOfFinancialReports Or UnloadItemsOfAssetsLiabilities;
	EnableDisableUnloading(UploadAccountPlans,
							Items.UploadAccountPlans,
							Items.FilterChartOfAccounts,
							TableOfAccountPlans,
							RelatedSelectionIsEnabled);
	
EndProcedure

&AtServer
Procedure UploadSetsOfFinancialReportsOnChangeServer()
	
	SetProgramSelectionOfTypesOfFinancialReports();
	
	EnableDisableUnloading(UploadTypesOfFinancialReports,
						Items.UploadTypesOfFinancialReports,
						Items.FilterFinancialReportTypes,
						TableTypesOfFinancialStatements);
						
	EnableDisableUnloading(UploadAccountPlans,
						Items.UploadAccountPlans,
						Items.FilterChartOfAccounts,
						TableOfAccountPlans);
EndProcedure

&AtServer
Procedure FillInSummaryInformation()

	HasErrors = Not ExecutedImportStatus;

	Items.Information.Visible = HasErrors;
	If HasErrors Then
		Information = NStr("vi = 'Lỗi:';
							|ru = 'Ошибка:';
							|en = 'Error:'; fa = 'Error:';
							|it = 'Errore:';
							|pl = 'Błąd:';
							|tr = 'Hata:'") + Chars.LF + ExchangeProtocol.GetText();
	EndIf;

EndProcedure

&AtClient
Procedure RecordResult(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Result) = Type("Structure") Then
		
		If Result.Property("Messages") And Result.Messages <> Undefined Then
			For Each Message In Result.Messages Do
				Message.Message();
			EndDo;
		EndIf;
		
		If Result.Property("Status") Then
			If Result.Status = "Error" Then
				ExecutedImportStatus = False;
				ExchangeProtocol.SetText(Result.BriefErrorDescription);
			ElsIf Result.Status = "Completed2" Then
				ExecutedImportStatus = True;
				FileSystemClient.SaveFile(Undefined, AdditionalParameters, Object.ModelFileName);
			EndIf;
			ChangeNavigationNumber(+1);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ModelFileNameExtensionEnabled(Result, AdditionalParameters) Export

	OpenFileDialog = New FileDialog(FileDialogMode.Save);
	OpenFileDialog.Filter = NStr("vi = 'Tệp kết xuất';
								|ru = 'Файл выгрузки';
								|en = 'Export file'; fa = 'فایل خروج';
								|it = 'File di upload';
								|pl = 'Plik przesyłania';
								|tr = 'Dışa aktarma dosyası'") + "(*.xml)|*.xml";
	OpenFileDialog.Multiselect = False;
	OpenFileDialog.Title = NStr("vi = 'Hãy chọn đường dẫn đến tệp kết xuất mô hình kế toán';
								|ru = 'Выберите путь к файлу выгрузки модели учета';
								|en = 'Select a path to the file of accounting model export'; fa = 'Select a path to the file of accounting model export';
								|it = 'Seleziona il percorso del file di caricamento del modello di bilancio';
								|pl = 'Wybierz ścieżkę do pliku ładowania modelu ewidencji';
								|tr = 'Muhasebe modeli yükleme dosyasının yolunu seçin'");

	CallbackDescription = New CallbackDescription("ModelFileNameShowCompletionDialog", ThisObject);

	OpenFileDialog.Show(CallbackDescription);

EndProcedure

&AtClient
Procedure ModelFileNameShowCompletionDialog(SelectedFiles, AdditionalParameters) Export

	If SelectedFiles = Undefined Then
		Return;
	EndIf;

	Object.ModelFileName = SelectedFiles[0];

EndProcedure

&AtServerNoContext
Procedure EnableDisableUnloading(FlagExports, FlagOnForm, ElementOfSelectionForm, Table, LinkedSelectionIsEnabled = False)
	
	Filter = New Structure;
	Filter.Insert("RelatedSelection", True);
	ThereIsRelatedSelection = Table.FindRows(Filter).Count() <> 0 Or LinkedSelectionIsEnabled = True;
	
	If ThereIsRelatedSelection Then
		FlagExports = True;
		FlagOnForm.Enabled = False;
		ElementOfSelectionForm.Enabled = True;
	ElsIf Not ThereIsRelatedSelection Then
		Filter = New Structure;
		Filter.Insert("Check", True);
		Enable = Table.FindRows(Filter).Count() <> 0;
		FlagExports = Enable;
		FlagOnForm.Enabled = True;
		ElementOfSelectionForm.Enabled = Enable;
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInChartOfAccountsTable()

	Selection = Catalogs.FinancialAccountingChartsOfAccounts.Select();
	While Selection.Next() Do
		NewRow = TableOfAccountPlans.Add();
		NewRow.ChartOfAccounts = Selection.Ref;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTableOfTypesOfFinancialStatements()

	Selection = Catalogs.FinancialReportTypes.Select();
	While Selection.Next() Do
		NewRow = TableTypesOfFinancialStatements.Add();
		NewRow.FinancialReportType = Selection.Ref;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTransactionGenerationSettingsTable()

	Selection = Catalogs.FinancialAccountingPostingGenerationSetting.Select();
	While Selection.Next() Do
		NewRow = TableForSettingUpFormationOfTransactions.Add();
		NewRow.SettingUpFormationOfInternationalAccountingTransactions = Selection.Ref;
		NewRow.ChartOfAccounts = Selection.Owner;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTableTypicalOperations()

	Selection = Catalogs.StandardTransactionsOfFinancialAccounting.Select();
	While Selection.Next() Do
		NewRow = TableStandartOperations.Add();
		NewRow.StandartOperation = Selection.Ref;
		NewRow.ChartOfAccounts = Selection.ChartOfAccounts;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTableOfSetsOfFinancialReports()

	Selection = Catalogs.FinancialReportSets.Select();
	While Selection.Next() Do
		NewRow = TableOfSetsOfFinancialReports.Add();
		NewRow.SetOfFinancialReport = Selection.Ref;
	EndDo;

EndProcedure

&AtServer
Procedure FillInTableOfAssetsLiabilitiesArticles()

	Selection = ChartsOfCharacteristicTypes.AssetLiabilityItems.Select();
	While Selection.Next() Do
		NewRow = TableOfAssetsLiabilitiesItems.Add();
		NewRow.AssetAndLiabilityItem = Selection.Ref;
	EndDo;

EndProcedure

&AtServer
Function FormTableToTemporaryStorage(Val Table)
	Return PutToTempStorage(Table.Unload(), UUID);
EndFunction

&AtServer
Function TemporaryStorageOfChartOfAccountsSelectionStructure()
	
	Structure = New Structure();
	Structure.Insert("SelectedTransactionSettings", SelectedSettingsForGeneratingTransactions());
	Structure.Insert("SelectedStandartOperations", SelectedStandartOperations());
	Structure.Insert("TableOfAccountPlans", TableOfAccountPlans.Unload());
	
	Return PutToTempStorage(Structure, UUID);
	
EndFunction

&AtClient
Procedure UpdateChartOfAccountsTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateChartOfAccountsTableServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateChartOfAccountsTableServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableOfAccountPlans.Load(Table);
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.FilterChartOfAccounts, TableOfAccountPlans);
	ProcessDependentSelectionsFromChartOfAccounts();
	
EndProcedure

&AtClient
Procedure UpdateTypesOfFinancialStatementsTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateTypesOfFinancialStatementsTableServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateTypesOfFinancialStatementsTableServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableTypesOfFinancialStatements.Load(Table);
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.FilterFinancialReportTypes, TableTypesOfFinancialStatements);
	SetProgramSelectionOfChartOfAccounts();
	
EndProcedure

&AtClient
Procedure UpdateFinancialReportSetsTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateFinancialReportSetsTableServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateFinancialReportSetsTableServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableOfSetsOfFinancialReports.Load(Table);
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.FilterFinancialReportSets, TableOfSetsOfFinancialReports);
	SetProgramSelectionOfTypesOfFinancialReports();
	
EndProcedure

&AtClient
Procedure UpdateTransactionGenerationSettingsTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateTransactionGenerationSettingsTableServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateTransactionGenerationSettingsTableServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableForSettingUpFormationOfTransactions.Load(Table);
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.SelectingSettingsForGeneratingTransactions, TableForSettingUpFormationOfTransactions);
	
EndProcedure

&AtClient
Procedure UpdateTableOfAssetsLiabilitiesArticles(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateTableOfAssetsLiabilitiesArticlesServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateTableOfAssetsLiabilitiesArticlesServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableOfAssetsLiabilitiesItems.Load(Table);	
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.FilterAssetLiabilityItems, TableOfAssetsLiabilitiesItems);
	SetProgramSelectionOfChartOfAccounts();
	
EndProcedure

&AtClient
Procedure UpdateTypicalOperationsTable(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;

	UpdateTypicalOperationsTableServer(Result);
	
EndProcedure

&AtServer
Procedure UpdateTypicalOperationsTableServer(Result)

	If IsTempStorageURL(Result) Then
		Table = GetFromTempStorage(Result); // ValueTable -
		TableStandartOperations.Load(Table);
	EndIf;	
	
	SetTitleOfSelectionHyperlink(Items.StandartOperationsFilter, TableStandartOperations);
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetTitleOfSelectionHyperlink(Item, Table)
	
	TotalItems = Table.Count();

	Filter = New Structure;
	Filter.Insert("Check", True);
	Count = Table.FindRows(Filter).Count();

	If Count = TotalItems Then
		Item.Title = NStr("vi = 'Tất cả';
							|ru = 'Все';
							|en = 'All'; fa = 'همه';
							|it = 'Tutti';
							|pl = 'All';
							|tr = 'Tümü'");
	Else
		TextSelected = TMCommonUseClientServer.InPlural(
				NStr("vi = 'Đã chọn';
					|ru = 'Выбраны';
					|en = 'Selected'; fa = 'انتخاب‌شده';
					|it = 'Selezionati';
					|pl = 'Wybrane';
					|tr = 'Seçilenler'"), NStr("vi = 'Đã chọn';
												|ru = 'Выбраны';
												|en = 'Selected'; fa = 'انتخاب‌شده';
												|it = 'Selezionati';
												|pl = 'Wybrane';
												|tr = 'Seçilenler'"), NStr("vi = 'Đã chọn';
																		|ru = 'Выбраны';
																		|en = 'Selected'; fa = 'انتخاب‌شده';
																		|it = 'Selezionati';
																		|pl = 'Wybrane';
																		|tr = 'Seçilenler'"), Count);
		Item.Title = StrTemplate(NStr("vi = '%1 %2';
										|ru = '%1 %2';
										|en = '%1 %2'; fa = '%1 %2';
										|it = '%1 %2';
										|pl = '%1 %2';
										|tr = '%1 %2'"), TextSelected, Count);
	EndIf;

EndProcedure

&AtServer
Procedure SetProgramSelectionOfChartOfAccounts()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.FinancialReportType AS FinancialReportType
		|INTO FinancialReportTypes
		|FROM
		|	&TableTypesOfFinancialStatements AS Table
		|WHERE
		|	Table.Check
		|
		|INDEX BY
		|	FinancialReportType
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Table.AssetAndLiabilityItem AS AssetAndLiabilityItem
		|INTO AssetLiabilityItems
		|FROM
		|	&TableOfAssetsLiabilitiesItems AS Table
		|WHERE
		|	Table.Check
		|
		|INDEX BY
		|	AssetAndLiabilityItem
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	FinancialReportTypesChartsOfAccounts.ChartOfAccounts AS ChartOfAccounts
		|FROM
		|	Catalog.FinancialReportTypes.ChartsOfAccounts AS FinancialReportTypesChartsOfAccounts
		|WHERE
		|	FinancialReportTypesChartsOfAccounts.Ref IN
		|		(SELECT
		|			T.FinancialReportType
		|		FROM
		|			FinancialReportTypes AS T)
		|
		|UNION
		|
		|SELECT DISTINCT
		|	AssetLiabilityItemsFinancialAccountingSettings.ChartOfAccounts
		|FROM
		|	ChartOfCharacteristicTypes.AssetLiabilityItems.FinancialAccountingSettings AS
		|		AssetLiabilityItemsFinancialAccountingSettings
		|WHERE
		|	AssetLiabilityItemsFinancialAccountingSettings.Ref IN
		|		(SELECT
		|			T.AssetAndLiabilityItem
		|		FROM
		|			AssetLiabilityItems AS T)";
	
	Query.SetParameter("TableTypesOfFinancialStatements", TableTypesOfFinancialStatements.Unload());
	Query.SetParameter("TableOfAssetsLiabilitiesItems", TableOfAssetsLiabilitiesItems.Unload());
	
	AccountPlansUsed = Query.Execute().Unload();
	
	For Each String In TableOfAccountPlans Do
		
		FoundRow = AccountPlansUsed.Find(String.ChartOfAccounts, "ChartOfAccounts");
		If FoundRow <> Undefined Then
			If Not String.Check Then
				String.Check = True;
				String.Software = True;
			EndIf;
			String.RelatedSelection = True;
		Else
			If String.RelatedSelection Then
				String.RelatedSelection = False;
				If String.Software Then
					String.Check = False;
					String.Software = False;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	ProcessDependentSelectionsFromChartOfAccounts();
	SetTitleOfSelectionHyperlink(Items.FilterChartOfAccounts, TableOfAccountPlans);

EndProcedure

&AtServer
Procedure SetProgramSelectionOfTypesOfFinancialReports()
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	Table.SetOfFinancialReport AS SetOfFinancialReport
		|INTO TT
		|FROM
		|	&Table AS Table
		|WHERE
		|	Table.Check
		|
		|INDEX BY
		|	SetOfFinancialReport
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	FinancialReportSetsReportsKinds.FinancialReportType AS FinancialReportType
		|FROM
		|	Catalog.FinancialReportSets.ReportsKinds AS FinancialReportSetsReportsKinds
		|WHERE
		|	FinancialReportSetsReportsKinds.Ref IN
		|			(SELECT
		|				T.SetOfFinancialReport
		|			FROM
		|				TT AS T)";
	
	Query.SetParameter("Table", TableOfSetsOfFinancialReports.Unload());
	
	TypesOfFinancialStatementsUsed = Query.Execute().Unload();
	AddElementsWithParents(TypesOfFinancialStatementsUsed);
	
	For Each String In TableTypesOfFinancialStatements Do
		
		FoundRow = TypesOfFinancialStatementsUsed.Find(String.FinancialReportType, "FinancialReportType");
		If FoundRow <> Undefined Then
			If Not String.Check Then
				String.Check = True;
				String.Software = True;
			EndIf;
			String.RelatedSelection = True;
		Else
			If String.RelatedSelection Then
				String.RelatedSelection = False;
				If String.Software Then
					String.Check = False;
					String.Software = False;
				EndIf;
			EndIf;
		EndIf;
		
	EndDo;
	
	SetTitleOfSelectionHyperlink(Items.FilterFinancialReportTypes, TableTypesOfFinancialStatements);
	SetProgramSelectionOfChartOfAccounts();
	
EndProcedure

&AtServer
Procedure AddElementsWithParents(TypesOfFinancialStatementsUsed)
	
	For Each String In TypesOfFinancialStatementsUsed Do
		FindAndAddParent(String.FinancialReportType, TypesOfFinancialStatementsUsed);
	EndDo;
	
EndProcedure

&AtServer
Procedure FindAndAddParent(FinancialReportType, TypesOfFinancialStatementsUsed)
	
	Parent = FinancialReportType.Parent; 
	
	If ValueIsFilled(Parent)
		And TypesOfFinancialStatementsUsed.Find(Parent, "FinancialReportType") = Undefined Then
		
		NewRow = TypesOfFinancialStatementsUsed.Add();
		NewRow.FinancialReportType = Parent;
		
		If ValueIsFilled(Parent.Parent) Then
			FindAndAddParent(Parent.Parent, TypesOfFinancialStatementsUsed)
		EndIf;
		
	EndIf;

EndProcedure

&AtServer
Procedure ProcessDependentSelectionsFromChartOfAccounts()
	
	ProcessFilter(UploadSettingsForGeneratingTransactions, Items.SelectingSettingsForGeneratingTransactions, TableForSettingUpFormationOfTransactions);
	ProcessFilter(UploadTypicalOperations, Items.StandartOperationsFilter, TableStandartOperations);
	
EndProcedure

&AtServer
Procedure ProcessFilter(FlagOfSelection, SelectionOnForm, FilterTable)
	
	For Each String In FilterTable Do
		
		If Not ValueIsFilled(String.ChartOfAccounts) Then
			String.Enabled = True;
			Continue;
		EndIf;
	
		Filter = New Structure;
		Filter.Insert("Check", True);
		Filter.Insert("ChartOfAccounts", String.ChartOfAccounts);
		FoundRows = TableOfAccountPlans.FindRows(Filter);
		NumberOfRowsFound = FoundRows.Count();
		If NumberOfRowsFound Then
			String.Enabled = True;
		Else
			String.Enabled = False;
			String.Check = False;
		EndIf;
		
	EndDo; 
	
	If FlagOfSelection Then
		SetTitleOfSelectionHyperlink(SelectionOnForm, FilterTable);
	EndIf;
	
EndProcedure

&AtServer
Function SynonymOfProcessing()
	Return Metadata.DataProcessors.FinancialAccountingModelExportAndImportWizard.Synonym;
EndFunction

&AtClient
Procedure MarkItemsInTable(Flag, Table);
	
	For Each String In Table Do
		String.Check = Flag;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion