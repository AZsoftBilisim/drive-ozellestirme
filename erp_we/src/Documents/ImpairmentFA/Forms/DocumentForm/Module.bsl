#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);

	#Region StandardSubsystems

	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisForm);
	// End StandardSubsystems.ObjectsVersioning

	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	#EndRegion
	
	ItemsAndDimensionsSelectionParameters = Documents.ImpairmentFA.ItemsAndDimensionsSelectionParameters(Catalogs.BusinessTransactionsSettings.EmptyRef());
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	ManagementAccountingCurrency = Constants.ManagementAccountingCurrency.Get();
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		ManagementAccountingCurrency,
		LocalAccountingCurrency,
		Object.Date);
	ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency,
		ManagementAccountingCurrency,
		Object.Date);
		
	FormItemsManagementServer();
	SetConditionalAppearance();
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement

	PeriodClosingDates.ObjectOnReadAtServer(ThisForm, CurrentObject);

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ItemsAndDimensionsSelectionParameters = Documents.ImpairmentFA.ItemsAndDimensionsSelectionParameters(Catalogs.BusinessTransactionsSettings.EmptyRef());
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)

	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_ImpairmentFA", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	NonCurrentAssetsClient.NotifyAboutEntryOfDocumentInJournalOfIA();
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement

	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers
	
&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpenseItemOnChangeServer(Item.Name);
	
EndProcedure

&AtClient
Procedure IncomeItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, Var_Parameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, Var_Parameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, Var_Parameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	FormItemsManagementServer();
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	FactorOfConversionToCurrencyOfRegul = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		ManagementAccountingCurrency,
		LocalAccountingCurrency,
		Object.Date);
	ConversionRateToManCurrency = ProcessingOfExchangeRatesTM.GetConversionFactorFromCurrencyToCurrency(
		LocalAccountingCurrency,
		ManagementAccountingCurrency,
		Object.Date);
		
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersCashGeneratingUnits

&AtClient
Procedure CashGeneratingUnitsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.CashGeneratingUnits, "CGU", ValueSelected);
	
EndProcedure

&AtClient
Procedure CashGeneratingUnitsRecoverableAmountLocalOnChange(Item)
	
	CurrentData = Items.CashGeneratingUnits.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountLocal, CurrentData.RecoverableAmountMan, ConversionRateToManCurrency);
	
EndProcedure

&AtClient
Procedure CashGeneratingUnitsRecoverableAmountManOnChange(Item)
	
	CurrentData = Items.CashGeneratingUnits.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountMan, CurrentData.RecoverableAmountLocal, FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFixedAssets

&AtClient
Procedure FixedAssetsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FixedAssets, "FixedAsset", ValueSelected);

EndProcedure


&AtClient
Procedure FixedAssetsRecoverableAmountLocalOnChange(Item)
	
	CurrentData = Items.FixedAssets.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountLocal, CurrentData.RecoverableAmountMan, ConversionRateToManCurrency);
	
EndProcedure

&AtClient
Procedure FixedAssetsRecoverableAmountManOnChange(Item)
	
	CurrentData = Items.FixedAssets.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountMan, CurrentData.RecoverableAmountLocal, FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersIntangibleAssets

&AtClient
Procedure IntangibleAssetsChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	NonCurrentAssetsClientServer.ProcessingElementSelection(Object.IntangibleAssets, "IntangibleAsset", ValueSelected);

EndProcedure


&AtClient
Procedure IntangibleAssetsRecoverableAmountLocalOnChange(Item)
	
	CurrentData = Items.IntangibleAssets.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountLocal, CurrentData.RecoverableAmountMan, ConversionRateToManCurrency);
	
EndProcedure

&AtClient
Procedure IntangibleAssetsRecoverableAmountManOnChange(Item)
	
	CurrentData = Items.IntangibleAssets.CurrentData;
	UpdateAmount(CurrentData.RecoverableAmountMan, CurrentData.RecoverableAmountLocal, FactorOfConversionToCurrencyOfRegul);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure WriteDocument(Command)

	TMCommonUseClient.Write(ThisForm, True);

EndProcedure

&AtClient
Procedure PostDocument(Command)

	TMCommonUseClient.Post(ThisForm, True);

EndProcedure

&AtClient
Procedure PostAndClose(Command)

	TMCommonUseClient.PostAndClose(ThisForm, False);

EndProcedure

&AtClient
Procedure FASelection(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FixedAssetsFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FixedAssets,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure SelectionOfIA(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.IntangibleAssetsIntangibleAsset, ThisObject);
	
	OpenForm("Catalog.IntangibleAssets.ChoiceForm", 
					PickingParameters, Items.IntangibleAssets,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure SelectionOfCGU(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.CashGeneratingUnitsCGU, ThisObject);
	PickingParameters.Filter.Insert("OnlyForSpecifiedOrganization", True);
	
	OpenForm("Catalog.CashGeneratingUnits.ChoiceForm", 
					PickingParameters, Items.CashGeneratingUnits,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("EventName", "FillType");
	
	If Object.IntangibleAssets.Count() 
			Or Object.FixedAssets.Count()
			Or Object.CashGeneratingUnits.Count() Then
		NotificationParameters = FillParameters;
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Trước khi điền, phần bảng sẽ bị xóa. Tiếp tục?';
						|ru = 'Перед заполнением табличные части будут очищены. Продолжить?';
						|en = 'The tables will be cleared before population. Continue?'; fa = 'The tables will be cleared before population. Continue?';
						|it = 'The tables will be cleared before population. Continue?';
						|pl = 'The tables will be cleared before population. Continue?';
						|tr = 'Tablo bölümleri doldurulmadan önce temizlenecektir. Devam edilsin mi?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		FillInVNAOnClient();
	EndIf	
	
EndProcedure

&AtClient
Procedure DownloadCGU(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("EventName", "ImportDataFromFile");
	FillParameters.Insert("TSName", "CashGeneratingUnits");
	FillParameters.Insert("Catalog", "CashGeneratingUnits");
	FillParameters.Insert("ColumnName", "CGU");
	FillParameters.Insert("Title", NStr("vi = 'Kết nhập đơn vị tạo tiền từ tệp';
										|ru = 'Загрузка единиц генерирующих денежные средства из файла';
										|en = 'Import cash-generating units from the file'; fa = 'Import cash-generating units from the file';
										|it = 'Download unità generatrici di cassa da file';
										|pl = 'Wczytywanie jednostek generujących środki pieniężne z pliku';
										|tr = 'Nakit yaratan birimlerin bir dosyadan yüklenmesi'"));
	
	If Object.CashGeneratingUnits.Count() Then
		NotificationParameters = FillParameters;
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Xóa bảng đơn vị tạo tiền trước khi điền theo dữ liệu từ tệp?';
						|ru = 'Очистить таблицу ЕГДС перед заполнением по данным из файла?';
						|en = 'Clear the table of the cash-generating unit before filling in according to the data from the file?'; fa = 'Clear the table of the cash-generating unit before filling in according to the data from the file?';
						|it = 'Cancellare tabella unità generatrice di cassa prima di compilare in base ai dati del file?';
						|pl = 'Wyczyścić tabelę jednostek generujących środki pieniężne przed wypełnieniem według danych z pliku?';
						|tr = 'Dosyadaki verileri kullanarak doldurmadan önce NYB tablosu temizlensin mi?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		LoadDataFromStartFile(FillParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure DownloadIA(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("EventName", "ImportDataFromFile");
	FillParameters.Insert("TSName", "IntangibleAssets");
	FillParameters.Insert("Catalog", "IntangibleAssets");
	FillParameters.Insert("ColumnName", "IntangibleAsset");
	FillParameters.Insert("Title", NStr("vi = 'Kết nhập tài sản vô hình từ tệp';
										|ru = 'Загрузка нематериальных активов из файла';
										|en = 'Import intangible assets from the file'; fa = 'Import intangible assets from the file';
										|it = 'Download attivi immateriali da file';
										|pl = 'Wczytywania aktywów niematerialnych z pliku';
										|tr = 'Maddi olmayan varlıkların bir dosyadan yüklenmesi'"));
	
	If Object.IntangibleAssets.Count() Then
		NotificationParameters = FillParameters;
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Xóa bảng tài sản vô hình trước khi điền theo dữ liệu từ tệp?';
						|ru = 'Очистить таблицу нематериальных активов перед заполнением по данным из файла?';
						|en = 'Clear the table of intangible assets before filling in according to the data from the file?'; fa = 'Clear the table of intangible assets before filling in according to the data from the file?';
						|it = 'Cancellare tabella attivi immateriale prima della compilazione in base ai dati del file?';
						|pl = 'Wyczyścić tabelę aktywów niematerialnych przed wypełnieniem według danych z pliku?';
						|tr = 'Dosyadaki verileri kullanarak doldurmadan önce maddi olmayan varlıklar tablosu temizlensin mi?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		LoadDataFromStartFile(FillParameters);
	EndIf;

EndProcedure

&AtClient
Procedure DownloadFA(Command)
	
	FillParameters = New Structure();
	FillParameters.Insert("EventName", "ImportDataFromFile");
	FillParameters.Insert("TSName", "FixedAssets");
	FillParameters.Insert("Catalog", "Assets");
	FillParameters.Insert("ColumnName", "FixedAsset");
	FillParameters.Insert("Title", NStr("vi = 'Kết nhập tài sản cố định từ tệp';
										|ru = 'Загрузка основных средств из файла';
										|en = 'Import fixed assets from the file'; fa = 'Import fixed assets from the file';
										|it = 'Download cespiti da file';
										|pl = 'Wczytywanie środków trwałych z pliku';
										|tr = 'Sabit kıymetlerin bir dosyadan yüklenmesi'"));
	
	If Object.FixedAssets.Count() Then
		NotificationParameters = FillParameters;
		CleaningTSDescriptionOfAlert = New CallbackDescription("IssueOfClearingTheTablePartCompletion", ThisObject, NotificationParameters);
		QueryText = NStr("vi = 'Xóa bảng tài sản cố định trước khi điền theo dữ liệu từ tệp?';
						|ru = 'Очистить таблицу основных средств перед заполнением по данным из файла?';
						|en = 'Clear the table of fixed assets before filling in according to the data from the file?'; fa = 'Clear the table of fixed assets before filling in according to the data from the file?';
						|it = 'Cancellare tabella cespiti prima della compilazione con i dati da file?';
						|pl = 'Wyczyścić tabelę środków trwałych przed wypełnieniem według danych z pliku?';
						|tr = 'Dosyadaki verileri kullanarak doldurmadan önce sabit kıymetler tablosu temizlensin mi?'");
		ShowQueryBox(CleaningTSDescriptionOfAlert, QueryText, QuestionDialogMode.YesNoCancel);
	Else
		LoadDataFromStartFile(FillParameters);
	EndIf;

EndProcedure

#Region StandardSubsystems

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand,
		Var_URL = Undefined, StandardProcessing = Undefined)

	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);

EndProcedure
// End StandardSubsystems.Properties

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)

	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);

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
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

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

#EndRegion

#EndRegion

#Region Private

#Region TimeConsumingOperations
&AtClient
Procedure FillInVNAOnClient()
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("EventName", "FillInImpairmentOfVNA");
		
	TimeConsumingOperation = FillInVNA();
		
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	
	CallbackDescription = New CallbackDescription("AfterFillingImpairmentOfVNA", ThisObject, AdditionalParameters);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);

EndProcedure

&AtServer
Function FillInVNA()
	
	Object.CashGeneratingUnits.Clear();
	Object.FixedAssets.Clear();
	Object.IntangibleAssets.Clear();

	FillParameters = New Structure();
	FillParameters.Insert("Period", EndOfMonth(Object.Date));
	FillParameters.Insert("Organization", Object.Organization);
	
	ExecutionParameters = TimeConsumingOperations.BackgroundExecutionParameters(UUID);
	ExecutionParameters.BackgroundJobDescription = NStr("vi = 'điền chứng từ giảm giá tài sản dài hạn';
														|ru = 'заполнение документа обесценения ВНА';
														|en = 'filling a fixed asset impairment document'; fa = 'filling a fixed asset impairment document';
														|it = 'compilazione documento svalutazione attivi non correnti';
														|pl = 'wypełnienie dokumentu utraty wartości aktywów niematerialnych';
														|tr = 'duran varlık değer kaybı belgesinin tamamlanması'");
	
	ExecutionResult = TimeConsumingOperations.ExecuteInBackground(
		"Documents.ImpairmentFA.FillInVNA",
		FillParameters, ExecutionParameters);
	
	Return ExecutionResult;
	
EndFunction

&AtClient
Procedure AfterFillingImpairmentOfVNA(Result, AdditionalParameters) Export
	
	If Result <> Undefined Then
		
		If Result.Status = "Error" Then
			MessageText = NStr("vi = 'Đã xảy ra lỗi cập nhật danh sách:';
								|ru = 'Произошла ошибка обновления списка:';
								|en = 'Error when updating list:'; fa = 'Error when updating list:';
								|it = 'Si è verificato un errore di aggiornamento di elenco:';
								|pl = 'Zaistniał błąd aktualizacji listy:';
								|tr = 'Listeyi güncellerken bir hata oluştu:'") + Chars.LF + Result.BriefErrorDescription;
			CommonClient.MessageToUser(MessageText);
			Return;
		EndIf;
		
		LoadPreparedData(Result.ResultAddress, AdditionalParameters);
		
	EndIf;
	
EndProcedure

&AtServer
Procedure LoadPreparedData(ResultAddress, AdditionalParameters)
	
	Data = GetFromTempStorage(ResultAddress);
	
	For Each DataString1 In Data Do
		If TypeOf(DataString1.NonCurrentAsset) = Type("CatalogRef.CashGeneratingUnits") Then
			String = Object.CashGeneratingUnits.Add();
			String.CGU = DataString1.NonCurrentAsset;
		ElsIf TypeOf(DataString1.NonCurrentAsset) = Type("CatalogRef.Assets") Then
			String = Object.FixedAssets.Add();
			String.FixedAsset = DataString1.NonCurrentAsset;
		ElsIf TypeOf(DataString1.NonCurrentAsset) = Type("CatalogRef.IntangibleAssets") Then
			String = Object.IntangibleAssets.Add();
			String.IntangibleAsset = DataString1.NonCurrentAsset;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

&AtServer
Procedure IncomeAndExpenseItemOnChangeServer(TagName)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items[TagName]);
	
EndProcedure

// StandardSubsystems.Properties 
&AtServer
Procedure UpdateAdditionalAttributesItems()
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
EndProcedure

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
	
EndProcedure
// End StandardSubsystems.Properties

&AtServer
Procedure SetConditionalAppearance()

	//CashGeneratingUnits
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashGeneratingUnitsRecoverableAmountLocal.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashGeneratingUnits.RecoverableAmountLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.CashGeneratingUnitsRecoverableAmountMan.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.CashGeneratingUnits.RecoverableAmountMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));
	
	//FixedAssets
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsRecoverableAmountLocal.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedAssets.RecoverableAmountLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FixedAssetsRecoverableAmountMan.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FixedAssets.RecoverableAmountMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));
	
	//IntangibleAssets
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntangibleAssetsRecoverableAmountLocal.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntangibleAssets.RecoverableAmountLocal");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();

	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.IntangibleAssetsRecoverableAmountMan.Name);

	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.IntangibleAssets.RecoverableAmountMan");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = 0;

	ConditionalAppearanceItem.Appearance.SetParameterValue("Text", NStr("vi = '<không có dấu hiệu giảm giá>';
																		|ru = '<нет признаков обесценения>';
																		|en = '<there are no signs of impairment>'; fa = '<there are no signs of impairment>';
																		|it = '<non ci sono segni di svalutazione>';
																		|pl = '<brak oznak utraty wartości>';
																		|tr = '<değer kaybı belirtisi yok'"));

EndProcedure

#Region FillingInTablePart

&AtClient
Procedure LoadDataFromStartFile(FillParameters)
	
	ImportParameters = ImportDataFromFileClient.DataImportParameters();
	ImportParameters.FullTabularSectionName = "ImpairmentFA." + FillParameters.TSName;
	ImportParameters.Title = FillParameters.Title;
	ImportParameters.DataStructureTemplateName = FillParameters.TSName;
	ImportParameters.AdditionalParameters = FillParameters;
	
	Notification = New CallbackDescription("DownloadDataFromAFileCompletion", ThisObject, FillParameters);
	ImportDataFromFileClient.ShowImportForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure DownloadDataFromAFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ImportedDataAddress = Undefined Then 
		Return;
	EndIf;
	
	UploadDataFromFileOnServer(ImportedDataAddress, AdditionalParameters);
	
EndProcedure

&AtServer
Procedure UploadDataFromFileOnServer(ImportedDataAddress, AdditionalParameters)
	
	ImportedData = GetFromTempStorage(ImportedDataAddress);
	
	LinesChanged = False;
	
	If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("TSName") Then
		For Each String In ImportedData Do
			If ValueIsFilled(String[AdditionalParameters.ColumnName]) Then
				TSRow = Object[AdditionalParameters.TSName].Add();
				FillPropertyValues(TSRow, String);
				LinesChanged = True;
			EndIf;
		EndDo;
	EndIf;
	
	If LinesChanged Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure IssueOfClearingTheTablePartCompletion(Result, AdditionalParameters = Undefined) Export
	
	If Result = DialogReturnCode.Yes Then
		If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("TSName") Then
			TabularSectionName = AdditionalParameters.TSName; // String
			Object[TabularSectionName].Clear();
		EndIf;
	EndIf;
	
	If TypeOf(AdditionalParameters) = Type("Structure") And AdditionalParameters.Property("EventName") Then
		If AdditionalParameters.EventName = "ImportDataFromFile" Then
			LoadDataFromStartFile(AdditionalParameters);
		ElsIf AdditionalParameters.EventName = "FillType" And Result = DialogReturnCode.Yes Then 
			FillInVNAOnClient();
		EndIf;
	EndIf;

EndProcedure

&AtServer
Procedure FormItemsManagementServer()

	LocalAccountingCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	ManagementAccountingCurrency = SettingsValueCached.ManagementAccountingCurrency();
	
	RecoverableAmountMan = StrTemplate(NStr("vi = 'Giá trị quản trị (%1)';
											|ru = 'Стоимость упр.(%1)';
											|en = 'Mgmt cost (%1)'; fa = 'Mgmt cost (%1)';
											|it = 'Costo gest. (%1)';
											|pl = 'Wartość zarz.(%1)';
											|tr = 'Net başlangıç maliyeti (yönetim). (%1)'"), ManagementAccountingCurrency);
	RecoverableAmountLocal = StrTemplate(NStr("vi = 'Giá trị tài chính (%1)';
												|ru = 'Стоимость регл.(%1)';
												|en = 'Local cost (%1)'; fa = 'Local cost (%1)';
												|it = 'Costo reg. (%1)';
												|pl = 'Wartość regl.(%1)';
												|tr = 'Net başlangıç maliyeti, yerel (%1)'"), LocalAccountingCurrency);
	
	Items.CashGeneratingUnitsRecoverableAmountMan.Title = RecoverableAmountMan;
	Items.FixedAssetsRecoverableAmountMan.Title = RecoverableAmountMan;
	Items.IntangibleAssetsRecoverableAmountMan.Title = RecoverableAmountMan;
	
	Items.CashGeneratingUnitsRecoverableAmountLocal.Title = RecoverableAmountLocal;
	Items.FixedAssetsRecoverableAmountLocal.Title = RecoverableAmountLocal;
	Items.IntangibleAssetsRecoverableAmountLocal.Title = RecoverableAmountLocal;

EndProcedure

#EndRegion

&AtClient
Procedure UpdateAmount(Sum, ConversionAmount_, ZoomRatio)
		
	If Sum <> 0 And ConversionAmount_ = 0 Then
		ConversionAmount_ = Sum * ZoomRatio;
	EndIf;
	
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
