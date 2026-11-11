
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountSettings_ = Documents.FixedAssetCostAndDepreciationAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnCreateAtServer(ThisObject, AccountSettings_);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	EquipmentManagerClient.StartConnectingDevicesWhenYouOpenForm(Undefined, ThisObject, "BarcodeScanner");
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	EquipmentManagerClient.StartDisablingHardwareWhenClosingForm(Undefined, ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	AccountingAccountSettings_ = Documents.FixedAssetCostAndDepreciationAdjustment.AccountingAccountSettings_();
	GLAccountSettingsServer.OnReadAtServer(ThisObject, AccountingAccountSettings_);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	GLAccountSettingsServer.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_FixedAssetCostAndDepreciationAdjustment", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)

	FillInServiceDetailsOfTS();
	
	// StandardSubsystems.AccessManagement
	AccessManagement.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End StandardSubsystems.AccessManagement
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Peripherals
	If Source = "Peripherals" And IsInputAvailable() Then
		If EventName = "ScanData" And EquipmentManagerTMClient.ThereIsRawEvent() Then
			ProcessBarcodes(EquipmentManagerTMClient.ConvertDataFromScannerToStructure(Parameter));
		EndIf;
	EndIf;
	// End Peripherals
	
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region PageGeneral

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	ChangedBankingDetails = "Date";
	
	MaximumStartOfPeriod = MaximumStartOfPeriod(Object.Date);
	
	If Object.AdjustmentModeFromPreviousDate
		And Object.BeginOfPeriod > MaximumStartOfPeriod Then
		
		Object.BeginOfPeriod = MaximumStartOfPeriod;
		ChangedBankingDetails = ChangedBankingDetails + ",BeginOfPeriod";
	EndIf;
	
	ConfigureDependentFormElements(ChangedBankingDetails);
	
	If StrFind(ChangedBankingDetails, "BeginOfPeriod") <> 0 Then
		StartFillingInDepreciationCalculationParameters();
	EndIf;
	
EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElementsOnServer("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnServer("RecordInManAccounting");

EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If Object.AdjustmentModeFromPreviousDate = AttributesValuesBeforeChange.AdjustmentModeFromPreviousDate Then
		Return;
	EndIf;
	
	If Not Object.AdjustmentModeFromPreviousDate 
		And Object.FinancialDetailsForThePeriod.Count() <> 0 Then
		
		QueryText = NStr("vi = 'Sẽ xóa tham số kế toán. Tiếp tục?';
						|ru = 'Параметры учета будут очищены. Продолжить?';
						|en = 'Accounting parameters will be cleared. Continue?'; fa = 'Accounting parameters will be cleared. Continue?';
						|it = 'Параметры учета будут очищены. Продолжить?';
						|pl = 'Parametry ewidencji zostaną wyczyszczone. Kontynuować?';
						|tr = 'Muhasebe parametreleri temizlenecektir. Devam edilsin mi?'");
		CallbackDescription = New CallbackDescription("AdjustmentModeFromPreviousDateOnChangeCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	Else
		
		AdjustmentModeFromPreviousDateOnChangeCompletion(DialogReturnCode.Yes, Undefined);
		
	EndIf;

EndProcedure

&AtClient
Procedure BeginOfPeriodOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi

	If Not CheckBeginningOfPeriod() Then
		Return;
	EndIf;
	
	ConfigureDependentFormElementsOnServer("BeginOfPeriod");

	StartFillingInDepreciationCalculationParameters();
	
EndProcedure

&AtClient
Procedure BeginOfPeriodStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("BeginOfPeriodStartChoiceCompletion", ThisObject);
	
	PeriodSelectionFormParameters = New Structure("Value, PeriodSelectionMode", Object.BeginOfPeriod, "MONTH");
	OpenForm("CommonForm.PeriodSelection",
		PeriodSelectionFormParameters, 
		ThisObject, 
		UUID,,, 
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);

EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ChoiceList = New ValueList();
		ChoiceList.Add(Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4"), NStr("vi = 'Thay đổi cài đặt TSCĐ hữu hình';
																					|ru = 'Изменение параметров ОС';
																					|en = 'Adjust fixed asset financial details'; fa = 'تعدیل جزئیات مالی دارایی ثابت';
																					|it = 'Modifica dei parametri dei capitali fissi';
																					|pl = 'Zmiana parametrów środków trwałych';
																					|tr = 'SV finansal bilgi düzeltmesi'"));
		ChoiceList.Add(Type("DocumentRef.FixedAssetsCostAdditions2_4"), NStr("vi = 'Nâng cấp TSCĐ';
																			|ru = 'Модернизация ОС';
																			|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
																			|it = 'Модернизация ОС';
																			|pl = 'Modernizacja środków trwałych';
																			|tr = 'SV modernizasyonu'"));
		ChoiceList.Add(Type("DocumentRef.AllocateVariancesToFixedAssetCost"), NStr("vi = 'Đưa các chênh lệch vào giá trị tài sản cố định';
																					|ru = 'Отнесение отклонений в стоимость ОС';
																					|en = 'Allocate variances to fixed asset cost'; fa = 'تسهیم انحرافات به بهای تمام‌شده دارایی ثابت';
																					|it = 'Allocate variances to fixed asset cost';
																					|pl = 'Allocate variances to fixed asset cost';
																					|tr = 'Farkların sabit kıymet maliyetine yüklenmesi'"));
		ChoiceList.Add(Type("DocumentRef.MergeOfFixedAssets"), NStr("vi = 'Hợp nhất TSCĐ hữu hình';
																	|ru = 'Объединение ОС';
																	|en = 'Merge fixed assets'; fa = 'ادغام دارایی‌های ثابت';
																	|it = 'Объединение ОС';
																	|pl = 'Połączenie ŚT';
																	|tr = 'SV birleşmesi'"));
		ChoiceList.Add(Type("DocumentRef.FARevaluation2_4"), NStr("vi = 'Đánh giá lại TSCĐ hữu hình';
																	|ru = 'Переоценка ОС';
																	|en = 'Revaluate fixed assets'; fa = 'تجدید ارزیابی دارایی‌های ثابت';
																	|it = 'Rivalutazione Capitale Fisso';
																	|pl = 'Przeszacowanie środków trwałych';
																	|tr = 'Sabit kıymet yeniden değerlemesi'"));
		ChoiceList.Add(Type("DocumentRef.ReceiveLeasedAssets"), NStr("vi = 'Nhận TSCĐ thuê (ngoại bảng)';
																	|ru = 'Поступление арендованных ОС (забалансовый учет)';
																	|en = 'Receive leased assets (off-balance)'; fa = 'دریافت دارایی‌های اجاره‌ای (خارج از ترازنامه)';
																	|it = 'Ricezione delle immobilizzazioni in affitto (contabilità fuori bilancio)';
																	|pl = 'Wpływ wynajmowanych środków trwałych (ewidencja pozabilansowa)';
																	|tr = 'Kiralanan varlıkların teslim alınması (bilanço dışı)'"));
		ChoiceList.Add(Type("DocumentRef.FixedAssetsInitialRecognition2_4"), NStr("vi = 'Tiếp nhận vào kế toán TSCĐ';
																					|ru = 'Принятие к учету ОС';
																					|en = 'Fixed assets — Initial recognition'; fa = 'دارایی‌های ثابت — شناسایی اولیه';
																					|it = 'Scrittura nei libri contabili Cespiti';
																					|pl = 'Przyjęcie do ewidencji środków trwałych';
																					|tr = 'Sabit kıymetler - İlk tahakkuk'"));
		ChoiceList.Add(Type("DocumentRef.SplitFixedAssets"), NStr("vi = 'Tách bộ TSCĐ hữu hình';
																	|ru = 'Разукомплектация ОС';
																	|en = 'Split fixed assets'; fa = 'تفکیک دارایی‌های ثابت';
																	|it = 'smantellamento Capitale fisso';
																	|pl = 'Zdekompletowanie ST';
																	|tr = 'SV''lerin bölünmesi'"));
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		ChoiceList.ShowChooseItem(CallbackDescription, NStr("vi = 'Hãy chọn dạng chứng từ';
															|ru = 'Выберите вид документа';
															|en = 'Select a document kind'; fa = 'Select a document kind';
															|it = 'Select a document kind';
															|pl = 'Select a document kind';
															|tr = 'Belge türünü seçin'"));
		
	Else
		
		Object.DocumentBasis = Undefined;
		
	EndIf; 
	
EndProcedure

#EndRegion

#Region ParametersPage

&AtClient
Procedure CurrentParametersOnChange(Item)
	
	ConfigureDependentFormElements(Item);

EndProcedure

#EndRegion

#Region ExpensesAndIncomePage

#Region CostIncrease

&AtClient
Procedure IncomeLiabilityItemCostIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemCostIncreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionCostIncreaseClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncreaseOnChange(Item)
	
	ConfigureDependentFormElements(
		"WayToReflectExpensesIsToIncreaseCost,BusinessUnitAndLineOfBusinessMatchAccountingDataCostIncrease");
	
EndProcedure

#EndRegion

#Region CostReduction

&AtClient
Procedure ExpenseRecordMethodCostDecreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodCostDecrease,
	|AssetExpenseItemCostReduction,BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodCostDecrease, 
		Object.AssetExpenseItemCostReduction, 
		Object.DimensionOfExpensesCostReduction, 
		Object.BusinessUnitCostDecrease, 
		Object.LineOfBusinessCostDecrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.AssetExpenseItemCostReduction);

	ConfigureDependentFormElements(ChangedBankingDetails);

EndProcedure

&AtClient
Procedure AssetExpenseItemCostReductionOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCostDecrease,AssetExpenseItemCostReduction");
	
EndProcedure

&AtClient
Procedure AssetExpenseItemCostReductionStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesCostReductionTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionCostReductionClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCostDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCostDecrease) Then
		Object.ExpenseRecordMethodCostDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCostDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease");
	
EndProcedure

#EndRegion

#Region IncreasedDepreciation

&AtClient
Procedure ExpenseRecordMethodDepreciationIncreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodDepreciationIncrease,
	|AssetExpenseItemDepreciationIncrease,BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodDepreciationIncrease, 
		Object.AssetExpenseItemDepreciationIncrease, 
		Object.DimensionOfExpensesDepreciationIncrease, 
		Object.BusinessUnitDepreciationIncrease, 
		Object.LineOfBusinessDepreciationIncrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.AssetExpenseItemDepreciationIncrease);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure AssetExpenseItemDepreciationIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodDepreciationIncrease,AssetExpenseItemDepreciationIncrease");
	
EndProcedure

&AtClient
Procedure AssetExpenseItemDepreciationIncreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDepreciationIncreaseTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionIncreaseInDepreciationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodDepreciationIncrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodDepreciationIncrease) Then
		Object.ExpenseRecordMethodDepreciationIncrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodDepreciationIncrease,BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease");
	
EndProcedure

#EndRegion

#Region DecreaseInDepreciationOfCurrentYear

&AtClient
Procedure ExpenseRecordMethodCurrentYearDepreciationDecreaseOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodCurrentYearDepreciationDecrease,
	|ExpenseItemThisYearDepreciationDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease, 
		Object.ExpenseItemThisYearDepreciationDecrease, 
		Object.DimensionThisYearDepreciationDecrease, 
		Object.BusinessUnitThisYearDepreciationDecrease, 
		Object.LineOfBusinessThisYearDepreciationDecrease, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemThisYearDepreciationDecrease);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemThisYearDepreciationDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCurrentYearDepreciationDecrease,ExpenseItemThisYearDepreciationDecrease");
	
EndProcedure

&AtClient
Procedure ExpenseItemThisYearDepreciationDecreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionThisYearDepreciationDecreaseTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusinessThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodCurrentYearDepreciationDecrease");
	EndIf;
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecreaseOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodCurrentYearDepreciationDecrease) Then
		Object.ExpenseRecordMethodCurrentYearDepreciationDecrease = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodCurrentYearDepreciationDecrease,BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease");
	
EndProcedure

#EndRegion

#Region DecreaseInDepreciationOfPreviousYears

&AtClient
Procedure IncomeLiabilityItemDepreciationDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemDepreciationDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionReductionOfDepreciationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecreaseOnChange(Item)
	
	ConfigureDependentFormElements(
		"BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationDecrease");
	
EndProcedure

#EndRegion

#Region IncreaseInDepreciationPremium

&AtClient
Procedure ExpenseRecordMethodBonusDepreciationOnChange(Item)
	
	ChangedBankingDetails = 
	"ExpenseRecordMethodBonusDepreciation,
	|AssetExpenseItemCostDecrease,ExpenseParametersMatchAccountingDataBonusDepreciation";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpenseRecordMethodBonusDepreciation, 
		Object.AssetExpenseItemCostDecrease, 
		Object.DimensionBonusDepreciation, 
		Object.Business_UnitBonusDepreciation, 
		Object.LineOfBusiness_BonusDepreciation, 
		Object.ExpenseParametersMatchAccountingDataBonusDepreciation);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.AssetExpenseItemCostDecrease);

	ConfigureDependentFormElements(ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemIncreaseInBonusDepreciationInEventOfChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpenseRecordMethodBonusDepreciation) Then
		Object.ExpenseRecordMethodBonusDepreciation = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodBonusDepreciation,ExpenseItemIncreaseInDepreciationPremium");
	
EndProcedure

&AtClient
Procedure ExpenseItemIncreaseInBonusDepreciationBeginningOfChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionBonusDepreciationOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodBonusDepreciation) Then
		Object.ExpenseRecordMethodBonusDepreciation = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElements("ExpenseRecordMethodBonusDepreciation");
	EndIf;
	
EndProcedure

&AtClient
Procedure AnalyticsOfExpensesIncreaseInBonusDepreciationBeginningOfChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AnalyticsOfExpensesIncreaseInBonusDepreciationAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure AnalyticsOfExpensesIncreaseInBonusDepreciationEndOfTextInput(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure Business_UnitBonusDepreciationOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodBonusDepreciation) Then
		Object.ExpenseRecordMethodBonusDepreciation = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure LineOfBusiness_BonusDepreciationOnChange(Item)

	If ValueIsFilled(Object.ExpenseRecordMethodBonusDepreciation) Then
		Object.ExpenseRecordMethodBonusDepreciation = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
EndProcedure

&AtClient
Procedure ExpenseParametersMatchAccountingDataBonusDepreciationOnChange(Item)
	
	If ValueIsFilled(Object.ExpenseRecordMethodBonusDepreciation) Then
		Object.ExpenseRecordMethodBonusDepreciation = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElements(
		"ExpenseRecordMethodBonusDepreciation,ExpenseParametersMatchAccountingDataBonusDepreciation");
	
EndProcedure

#EndRegion

#Region DecreaseInBonusDepreciation

&AtClient
Procedure IncomeLiabilityItemBonusDepreciationDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemBonusDepreciationDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionReductionOfBonusDepreciationClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecreaseOnChange(Item)
	
	ConfigureDependentFormElements(
		"BusinessUnitAndLineOfBusinessMatchAccountingDataBonusDepreciationDecrease");
	
EndProcedure

#EndRegion

#Region IncreaseInCFRevenues

&AtClient
Procedure AssetExpenseItemTargetFinancingIncomeIncreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure AssetExpenseItemTargetFinancingIncomeIncreaseStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesDecreaseInIncomeTFTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionIncreaseInCFRevenuesClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeIncreaseOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region DecreaseInIncomeOfTF

&AtClient
Procedure IncomeLiabilityItemTargetFinancingIncomeDecreaseOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeLiabilityItemTargetFinancingIncomeDecreaseStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure PresentationOfReflectionOfDecreaseInIncomeOfCFClick(Item, StandardProcessing)
	
	GLAccountSettingsClient.OnClick(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecreaseOnChange(Item)
	
	ConfigureDependentFormElements("BusinessUnitAndLineOfBusinessMatchAccountingDataTargetFinancingIncomeDecrease");
	
EndProcedure

#EndRegion

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	FixedAssetCostAndDepreciationAdjustmentClientLocalization.OnChangeAttribute(Item, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	FixedAssetCostAndDepreciationAdjustmentClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_TableFieldSelection(Item, RowSelected, Field, StandardProcessing)
	
	FixedAssetCostAndDepreciationAdjustmentClientLocalization.TableFieldSelection(Item, RowSelected, Field, StandardProcessing, ThisObject);

EndProcedure

#EndRegion

#Region StandardSubsystems

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_PreviewFieldClick(Item, StandardProcessing)

	FilesOperationsClient.PreviewFieldClick(ThisObject, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldCheckDragging(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldCheckDragging(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure

&AtClient
Procedure Attachable_PreviewFieldDrag(Item, DragParameters, StandardProcessing)

	FilesOperationsClient.PreviewFieldDrag(ThisObject, Item,
				DragParameters, StandardProcessing);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	SelectionOnServer(ValueSelected);
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	FAIsPrimaryMeansWhenChangingOnServer();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFinancialDetailsForThePeriodAC

&AtClient
Procedure FinancialDetailsForThePeriodACOnChange(Item)
	
	ConfigureDependentFormElements("FinancialDetailsForThePeriod");
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodACBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)

	Cancel = True;
	
	TMCommonUseClient.ShowDateSelection(
		Object.BeginOfPeriod,
		NStr("vi = 'Hãy nhập ngày tham số';
			|ru = 'Введите дату параметров';
			|en = 'Enter parameter date'; fa = 'Enter parameter date';
			|it = 'Inserire data parametri';
			|pl = 'Podaj datę parametrów';
			|tr = 'Parametrelerin tarihini giriniz'"),
		DateFractions.Date,
		New CallbackDescription("FinancialDetailsForThePeriodACBeforeAddRowCompletion", ThisObject),
		Object.BeginOfPeriod,
		BegOfMonth(Object.Date) - 1);
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodACBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	TotalSelected = Items.FinancialDetailsForThePeriodAC.SelectedRows.Count();
	If TotalSelected = 0 Then
		Return;
	EndIf;
	
	LinesToDelete = New Array;
	
	For Each RowID In Items.FinancialDetailsForThePeriodAC.SelectedRows Do
		RowData = Object.FinancialDetailsForThePeriodAC.FindByID(RowID);
		If RowData.CanDelete Then
			LinesToDelete.Add(RowData);
		EndIf;
	EndDo;
	
	For Each RowData In LinesToDelete Do
		Object.FinancialDetailsForThePeriodAC.Delete(RowData);
	EndDo;
	
	If LinesToDelete.Count() = 0 Then
		WarningText = NStr("vi = 'Được phép xóa các dòng mà trong đó ngày không phải là cuối tháng';
							|ru = 'Допускается удаление строк, у которых дата не в конце месяца';
							|en = 'It is allowed to delete lines whose date is not at the end of the month'; fa = 'It is allowed to delete lines whose date is not at the end of the month';
							|it = 'Concedere l''eliminazione delle righe presso le quali la data non è alla fine del mese';
							|pl = 'Dopuszczalne jest usunięcie wierszy, data których jest nie w końcu miesiąca';
							|tr = 'Ay sonundan farklı bir tarihe sahip satırların silinmesine izin verilir'");
		ShowMessageBox(, WarningText);
	ElsIf LinesToDelete.Count() <> TotalSelected Then
		WarningText = NStr("vi = 'Chỉ xóa khỏi các dòng đã chọn những chỗ có ngày vào cuối tháng';
							|ru = 'Из выбранных строк удалены только те, у которых дата в конце месяца';
							|en = 'Only lines with a date at the end of the month are deleted from the selected lines'; fa = 'Only lines with a date at the end of the month are deleted from the selected lines';
							|it = 'Delle righe selezionate sono eliminate solo quelle la cui data non è alla fine del mese';
							|pl = 'Z wybranych wierszy są usunięte tylko te, które mają datę w końcu miesiąca';
							|tr = 'Seçilen satırlardan yalnızca ay sonunda tarihi olanlar silinir'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodACSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ReadOnly Then
		Return;
	EndIf;

	If Field = Items.FinancialDetailsForThePeriodACDoNotCalculateDepreciationAC Then
		RowData = Object.FinancialDetailsForThePeriodAC.FindByID(RowSelected);
		RowData.DoNotCalculateDepreciationAC = Not RowData.DoNotCalculateDepreciationAC;
		Modified = True;
	EndIf;

EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersFinancialDetailsForThePeriod

&AtClient
Procedure FinancialDetailsForThePeriodOnChange(Item)
	
	ConfigureDependentFormElements("FinancialDetailsForThePeriod");

EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodBeforeAddRow(Item, Cancel, Copy, Parent, IsFolder, Parameter)
	
	Cancel = True;
	
	TMCommonUseClient.ShowDateSelection(
		Object.BeginOfPeriod,
		NStr("vi = 'Hãy nhập ngày tham số';
			|ru = 'Введите дату параметров';
			|en = 'Enter parameter date'; fa = 'Enter parameter date';
			|it = 'Inserire data parametri';
			|pl = 'Podaj datę parametrów';
			|tr = 'Parametrelerin tarihini giriniz'"),
		DateFractions.Date,
		New CallbackDescription("FinancialDetailsForThePeriodBeforeAddRowCompletion", ThisObject),
		Object.BeginOfPeriod,
		BegOfMonth(Object.Date) - 1);

EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	TotalSelected = Items.FinancialDetailsForThePeriod.SelectedRows.Count();
	If TotalSelected = 0 Then
		Return;
	EndIf;
	
	LinesToDelete = New Array;
	
	For Each RowID In Items.FinancialDetailsForThePeriod.SelectedRows Do
		RowData = Object.FinancialDetailsForThePeriod.FindByID(RowID);
		If RowData.CanDelete Then
			LinesToDelete.Add(RowData);
		EndIf;
	EndDo;
	
	For Each RowData In LinesToDelete Do
		Object.FinancialDetailsForThePeriod.Delete(RowData);
	EndDo;
	
	If LinesToDelete.Count() = 0 Then
		WarningText = NStr("vi = 'Được phép xóa các dòng mà trong đó ngày không phải là cuối tháng';
							|ru = 'Допускается удаление строк, у которых дата не в конце месяца';
							|en = 'It is allowed to delete lines whose date is not at the end of the month'; fa = 'It is allowed to delete lines whose date is not at the end of the month';
							|it = 'Concedere l''eliminazione delle righe presso le quali la data non è alla fine del mese';
							|pl = 'Dopuszczalne jest usunięcie wierszy, data których jest nie w końcu miesiąca';
							|tr = 'Ay sonundan farklı bir tarihe sahip satırların silinmesine izin verilir'");
		ShowMessageBox(, WarningText);
	ElsIf LinesToDelete.Count() <> TotalSelected Then
		WarningText = NStr("vi = 'Chỉ xóa khỏi các dòng đã chọn những chỗ có ngày vào cuối tháng';
							|ru = 'Из выбранных строк удалены только те, у которых дата в конце месяца';
							|en = 'Only lines with a date at the end of the month are deleted from the selected lines'; fa = 'Only lines with a date at the end of the month are deleted from the selected lines';
							|it = 'Delle righe selezionate sono eliminate solo quelle la cui data non è alla fine del mese';
							|pl = 'Z wybranych wierszy są usunięte tylko te, które mają datę w końcu miesiąca';
							|tr = 'Seçilen satırlardan yalnızca ay sonunda tarihi olanlar silinir'");
		ShowMessageBox(, WarningText);
	EndIf;
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodSelection(Item, RowSelected, Field, StandardProcessing)
	
	If ReadOnly Then
		Return;
	EndIf;
	
	If Field = Items.FinancialDetailsForThePeriodDoNotCalculateDepreciation Then
		RowData = Object.FinancialDetailsForThePeriod.FindByID(RowSelected);
		RowData.DoNotCalculateDepreciation = Not RowData.DoNotCalculateDepreciation;
		Modified = True;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	
	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure FillInTheAccountingForm(Command)
	
	If Items.FA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
												|ru = 'Заполнить';
												|en = 'Fill'; fa = 'پرکردن';
												|it = 'Compilare';
												|pl = 'Fill';
												|tr = 'Doldur'"));
	ButtonsList.Add(DialogReturnCode.No);
	
	If Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Leased") Then
		
		QueryText = NStr("vi = 'Điền giá trị tài sản thế chấp theo dữ liệu kế toán vào các hàng đã chọn?';
						|ru = 'Заполнить залоговую стоимость по данным учета в выбранных строках?';
						|en = 'Fill in collateral value according to accounting data in the selected lines?'; fa = 'Fill in collateral value according to accounting data in the selected lines?';
						|it = 'Compilare il costo cauzionale in base ai dati contabili nelle righe selezionate?';
						|pl = 'Wypełnij wartość kaucyjną wg danych ewidencji w wybranych wierszach?';
						|tr = 'Seçilen satırlardaki muhasebe verilerine göre teminat değerini doldurulsun mu?'");
				
	ElsIf (Object.CostAdjustment Or Object.AdjustmentOfInitialCost)
		And Object.DepreciationAdjustment
		And Not Object.DepreciationAdjustmentForPeriod Then
		
		QueryText = NStr("vi = 'Điền giá trị và khấu hao theo dữ liệu kế toán trong các hàng đã chọn?';
						|ru = 'Заполнить стоимость и амортизацию по данным учета в выбранных строках?';
						|en = 'Fill in the cost and depreciation according to accounting data in the selected lines?'; fa = 'Fill in the cost and depreciation according to accounting data in the selected lines?';
						|it = 'Compilare il costo e l''ammortamento in base ai dati contabili nelle righe selezionate?';
						|pl = 'Wypełnić wartość i amortyzację wg danych ewidencji w wybranych wierszach?';
						|tr = 'Seçilen satırlardaki muhasebe verilerine göre maliyet ve amortismanı doldur'");
				
	ElsIf Object.CostAdjustment Or Object.AdjustmentOfInitialCost Then
		
		QueryText = NStr("vi = 'Điền giá trị theo dữ liệu kế toán trong các dòng được chọn?';
						|ru = 'Заполнить стоимость по данным учета в выбранных строках?';
						|en = 'Do you want to fill the cost by accounting data in the selected lines?'; fa = 'Do you want to fill the cost by accounting data in the selected lines?';
						|it = 'Заполнить стоимость по данным учета в выбранных строках?';
						|pl = 'Do you want to fill the cost by accounting data in the selected lines?';
						|tr = 'Seçilen satırlardaki muhasebe verilerine göre maliyet doldurulsun mu?'");
				
	ElsIf Object.DepreciationAdjustment
		And Not Object.DepreciationAdjustmentForPeriod Then
		
		QueryText = NStr("vi = 'Điền khấu hao theo dữ liệu kế toán trong các dòng được chọn?';
						|ru = 'Заполнить амортизацию по данным учета в выбранных строках?';
						|en = 'Do you want to fill the depreciation by accounting data in the selected lines?'; fa = 'Do you want to fill the depreciation by accounting data in the selected lines?';
						|it = 'Заполнить амортизацию по данным учета в выбранных строках?';
						|pl = 'Do you want to fill the depreciation by accounting data in the selected lines?';
						|tr = 'Seçilen satırlardaki muhasebe verilerine göre amortisman doldurulsun mu?'");
		
	Else
		
		QueryText = NStr("vi = 'Điền giá trị theo dữ liệu kế toán trong các dòng được chọn?';
						|ru = 'Заполнить по данным учета в выбранных строках?';
						|en = 'Do you want to fill it in by accounting data in the selected lines?'; fa = 'Do you want to fill it in by accounting data in the selected lines?';
						|it = 'Do you want to fill it in by accounting data in the selected lines?';
						|pl = 'Do you want to fill it in by accounting data in the selected lines?';
						|tr = 'Seçili satırlar muhasebe verilerine göre doldurulsun mu?'");
		
	EndIf;
			
	CallbackDescription = New CallbackDescription("FillInTheAccountingFormCompletion", ThisObject);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure FillInDepreciationBasedOnAccountingParameters(Command)
	
	If Items.FA.SelectedRows.Count() = 0 Then
		Return;
	EndIf;
	
	DepreciationIsFull = False;
	
	For Each Item In Items.FA.SelectedRows Do
		
		RowData = Items.FA.RowData(Item);
		
		If RowData.DepreciationInAccounting <> 0
				And (Items.FADepreciationInAccounting.Visible
					Or Items.OsamortizatsiyaUsedSeparately.Visible)
			Or RowData.DepreciationInTaxAccounting <> 0
				And Items.FADepreciationInTaxAccounting.Visible
			Or RowData.DepreciationManagementAccounting <> 0
				And (Items.FADepreciationManagementAccounting.Visible
					Or Items.OsamortizatsiyaUUSeparately.Visible)
			Or RowData.FixedAssetDepreciationTargetFinancing <> 0 
				And Items.FAFixedAssetDepreciationTargetFinancing.Visible Then
				
			DepreciationIsFull = True;
			Break;
		EndIf;
		
	EndDo;
	
	If DepreciationIsFull Then
		
		ButtonsList = New ValueList;
		ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
													|ru = 'Заполнить';
													|en = 'Fill'; fa = 'پرکردن';
													|it = 'Fill';
													|pl = 'Fill';
													|tr = 'Doldur'"));
		ButtonsList.Add(DialogReturnCode.No);
		
		QueryText = NStr("vi = 'Điền khấu hao trong các dòng được chọn dựa trên tính toán theo tham số kế toán?';
						|ru = 'Заполнить амортизацию в выбранных строках на основании расчета по параметрам учета?';
						|en = 'Fill in depreciation in the selected lines based on the calculation by accounting parameters?'; fa = 'Fill in depreciation in the selected lines based on the calculation by accounting parameters?';
						|it = 'Fill in depreciation in the selected lines based on the calculation by accounting parameters?';
						|pl = 'Fill in depreciation in the selected lines based on the calculation by accounting parameters?';
						|tr = 'Seçili satırlarda amortisman, muhasebe parametrelerine göre hesaplama esas alınarak doldurulsun mu?'");
					
		CallbackDescription = New CallbackDescription("FillInDepreciationBasedOnAccountingParametersCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
		
	Else
		FillInDepreciationBasedOnAccountingParametersCompletion(DialogReturnCode.Yes, Undefined);
	EndIf;
	
EndProcedure

&AtClient
Procedure CalculateMaDepreciation(Command)
	
	QueryText = NStr("vi = 'Tính khấu hao trong toàn kỳ?';
					|ru = 'Рассчитать амортизацию за весь период?';
					|en = 'Calculate depreciation for the whole period?'; fa = 'Calculate depreciation for the whole period?';
					|it = 'Calcolare ammortamento per tutto il periodo?';
					|pl = 'Obliczyć amortyzację za cały okres?';
					|tr = 'Tüm dönem için amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("CalculateDepreciationCompletion", ThisObject, "MA");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure CalculateACDepreciation(Command)
	
	QueryText = NStr("vi = 'Tính khấu hao trong toàn kỳ?';
					|ru = 'Рассчитать амортизацию за весь период?';
					|en = 'Calculate depreciation for the whole period?'; fa = 'Calculate depreciation for the whole period?';
					|it = 'Calcolare ammortamento per tutto il periodo?';
					|pl = 'Obliczyć amortyzację za cały okres?';
					|tr = 'Tüm dönem için amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("CalculateDepreciationCompletion", ThisObject, "ACC");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure CalculateTaDepreciation(Command)
	
	QueryText = NStr("vi = 'Tính khấu hao trong toàn kỳ?';
					|ru = 'Рассчитать амортизацию за весь период?';
					|en = 'Calculate depreciation for the whole period?'; fa = 'Calculate depreciation for the whole period?';
					|it = 'Calcolare ammortamento per tutto il periodo?';
					|pl = 'Obliczyć amortyzację za cały okres?';
					|tr = 'Tüm dönem için amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("CalculateDepreciationCompletion", ThisObject, "TA");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);

EndProcedure

&AtClient
Procedure CalculateDepreciationAll(Command)
	
	QueryText = NStr("vi = 'Tính khấu hao cho toàn bộ kỳ trong tất cả các hệ thống kế toán?';
					|ru = 'Рассчитать амортизацию за весь период во всех учетах?';
					|en = 'Calculate depreciation for the whole period in all types of accounting?'; fa = 'Calculate depreciation for the whole period in all types of accounting?';
					|it = 'Calculate depreciation for the whole period in all types of accounting?';
					|pl = 'Calculate depreciation for the whole period in all types of accounting?';
					|tr = 'Tüm dönem için tüm muhasebelerde amortisman hesaplansın mı?'");
	CallbackDescription = New CallbackDescription("CalculateDepreciationCompletion", ThisObject, Undefined);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInParametersForCalculatingDepreciationOfAC(Command)
	
	QueryText = NStr("vi = 'Điền lại tham số và tính khấu hao?';
					|ru = 'Перезаполнить параметры и рассчитать амортизацию?';
					|en = 'Refill financial details and calculate depreciation?'; fa = 'Refill financial details and calculate depreciation?';
					|it = 'Ricompilare i parametri e calcolare ammortamento?';
					|pl = 'Ponownie wypełnić parametry i obliczyć amortyzację?';
					|tr = 'Parametreleri yeniden doldurun ve amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("FillInDepreciationCalculationParametersEnd", ThisObject, "ACC");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInDepreciationCalculationParametersTA(Command)
	
	QueryText = NStr("vi = 'Điền lại tham số và tính khấu hao?';
					|ru = 'Перезаполнить параметры и рассчитать амортизацию?';
					|en = 'Refill financial details and calculate depreciation?'; fa = 'Refill financial details and calculate depreciation?';
					|it = 'Ricompilare i parametri e calcolare ammortamento?';
					|pl = 'Ponownie wypełnić parametry i obliczyć amortyzację?';
					|tr = 'Parametreleri yeniden doldurun ve amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("FillInDepreciationCalculationParametersEnd", ThisObject, "TA");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInParametersForCalculatingDepreciationOfMA(Command)
	
	QueryText = NStr("vi = 'Điền lại tham số và tính khấu hao?';
					|ru = 'Перезаполнить параметры и рассчитать амортизацию?';
					|en = 'Refill financial details and calculate depreciation?'; fa = 'Refill financial details and calculate depreciation?';
					|it = 'Ricompilare i parametri e calcolare ammortamento?';
					|pl = 'Ponownie wypełnić parametry i obliczyć amortyzację?';
					|tr = 'Parametreleri yeniden doldurun ve amortismanı hesaplayın'");
	CallbackDescription = New CallbackDescription("FillInDepreciationCalculationParametersEnd", ThisObject, "MA");
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInDepreciationCalculationParametersAll(Command)
	
	StartFillingInDepreciationCalculationParameters();
		
EndProcedure

&AtClient
Procedure CopyACParameterValues(Command)

	CurrentData = Items.FinancialDetailsForThePeriodAC.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Cần chọn dòng có tham số cần sao chép';
								|ru = 'Необходимо выбрать строку, параметры которой, нужно скопировать';
								|en = 'Select the line whose parameters you need to copy'; fa = 'Select the line whose parameters you need to copy';
								|it = 'È necessario selezionare la riga i cui parametri devono essere copiati';
								|pl = 'Należy wybrać wiersz, którego parametry należy skopiować';
								|tr = 'Parametreleri kopyalanması gereken satırı seçmek gereklidir'"));
		Return;
	EndIf;
	
	ListOfDates_ = New Array;
	For Each RowData In Object.FinancialDetailsForThePeriodAC Do
		If RowData.Date <> CurrentData.Date Then
			ListOfDates_.Add(RowData.Date);
		EndIf;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("ListOfDates_", ListOfDates_);
	
	CallbackDescription = New CallbackDescription("CopyValuesOfCompletionParameters", ThisObject, "FinancialDetailsForThePeriodAC");
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.Form.SelectLinesFinancialDetails", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure CopyMaParameterValues(Command)
	
	CurrentData = Items.FinancialDetailsForThePeriod.CurrentData;
	
	If CurrentData = Undefined Then
		ShowMessageBox(, NStr("vi = 'Cần chọn dòng mà có tham số cần sao chép';
								|ru = 'Необходимо выбрать строку, параметры которой, нужно скопировать';
								|en = 'Select the line whose parameters you need to copy'; fa = 'Select the line whose parameters you need to copy';
								|it = 'È necessario selezionare la riga i cui parametri devono essere copiati';
								|pl = 'Należy wybrać wiersz, którego parametry należy skopiować';
								|tr = 'Parametreleri kopyalanması gereken satırı seçmek gereklidir'"));
		Return;
	EndIf;
	
	ListOfDates_ = New Array;
	For Each RowData In Object.FinancialDetailsForThePeriod Do
		If RowData.Date <> CurrentData.Date Then
			ListOfDates_.Add(RowData.Date);
		EndIf;
	EndDo;
	
	FormParameters = New Structure;
	FormParameters.Insert("ListOfDates_", ListOfDates_);
	
	CallbackDescription = New CallbackDescription("CopyValuesOfCompletionParameters", ThisObject, "FinancialDetailsForThePeriod");
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.Form.SelectLinesFinancialDetails", FormParameters,,,,, CallbackDescription);

EndProcedure
 
&AtClient
Procedure AdjustAdjustmentParameters(Command)
	
	FormParameters = New Structure(AdjustmentParameters());
	FillPropertyValues(FormParameters, Object);
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("Date", Object.Date);
	FormParameters.Insert("FixedAssetKind", Object.FixedAssetKind);
	FormParameters.Insert("IncomeTaxPayer", FormServiceParameters.IncomeTaxPayer);
	FormParameters.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", FormServiceParameters.CalculationOfPermanentAndTemporaryDifferencesIsKept);
	FormParameters.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	FormParameters.Insert("AccountingPolicyForFixedAssets", FormServiceParameters.AccountingPolicyForFixedAssets);
	FormParameters.Insert("FSB6IsApplied", FormServiceParameters.FSB6IsApplied);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	FormParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FormParameters.Insert("RecordInTA", Object.RecordInTA);
	FormParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FormParameters.Insert("AdjustmentModeFromPreviousDate", Object.AdjustmentModeFromPreviousDate);
	FormParameters.Insert("AdjustmentParameters", AdjustmentParameters());

	CallbackDescription = New CallbackDescription("AdjustAdjustmentParametersCompletion", ThisObject);
	
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.Form.AdjustmentParameters", FormParameters,,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject, True);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

#Region BarcodesAndTradeEquipment

&AtClient
Procedure ImportDataFromPDT(Command)
	
	LoadDataFromTSD();
	
EndProcedure

#EndRegion

#Region AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

// End StandardSubsystems.AttachableCommands

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(
		Command,
		ThisObject,
		Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

// StandardSubsystems.FilesOperations
&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)

	FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);

EndProcedure
// End StandardSubsystems.FilesOperations

#EndRegion

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedDetailsOrElement = "")

	If TypeOf(ChangedDetailsOrElement) = Type("String") Then
		ChangedBankingDetails = ChangedDetailsOrElement;
	Else
		ChangedBankingDetails = ChangedDetailsOrElement.Name;
	EndIf;
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, ChangedBankingDetails)

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("AccountingPolicyForFixedAssets", FormServiceParameters.AccountingPolicyForFixedAssets);
	AuxiliaryAttributes.Insert("FSB6IsApplied", FormServiceParameters.FSB6IsApplied);
	AuxiliaryAttributes.Insert("FSB6_IsAppliedForPeriod", FormServiceParameters.FSB6_IsAppliedForPeriod);
	AuxiliaryAttributes.Insert("UseFixedAssetAccountingByActivities", FormServiceParameters.UseFixedAssetAccountingByActivities);
	AuxiliaryAttributes.Insert("IncomeTaxPayer", False);
	AuxiliaryAttributes.Insert("SupportPBU18", False);
	AuxiliaryAttributes.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", False);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("ReglVNAAccountingIsConductedIndependently_ForPeriod", FormServiceParameters.ReglVNAAccountingIsConductedIndependently_ForPeriod);
	FixedAssetCostAndDepreciationAdjustmentClientServerLocalization.AddAuxiliaryDetails(Form, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.WhenChangingDetails_AdjustmentOfCostAndDepreciationOfFA(Form, AuxiliaryAttributes, ChangedBankingDetails);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentProps_AdjustmentOfCostAndDepreciationOfFA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
									
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);

	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(
			Object, ItemDetailsParameters, "FA,FinancialDetailsForThePeriod,FinancialDetailsForThePeriodAC,FinancialDetailsForThePeriodTA");
		
		ChangedBankingDetails = FillInDetailsDependingOnProperties(Form, ItemDetailsParameters);
		
		If ValueIsFilled(ChangedBankingDetails) Then
			ItemDetailsParameters = NonCurrentAssetsClientServer.ValuesOfPropertiesOfDependentProps_AdjustmentOfCostAndDepreciationOfFA(
											Object, AuxiliaryAttributes, ChangedBankingDetails);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
		EndIf;
		
	EndIf;
	
	AvailableParametersForPeriod = 
		Object.AdjustmentModeFromPreviousDate
		And Object.FixedAssetKind <> PredefinedValue("Enum.PropertyKinds.Leased");
	
	CurrencyOfManPresentation = FormServiceParameters.CurrencyOfManPresentation;
	ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;
	
	#Region PageGeneral
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInManAccounting = True;
			Object.RecordInLocalAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = False;
		EndIf;
		
	EndIf;

	If StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInTA")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
		
		Items.AdjustAdjustmentParameters.Visible = 
			Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Own")
			Or Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.EmptyRef");
			
	EndIf;
	
	#EndRegion
	
	#Region OSPage
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or StructureOfChangedProps.Property("IncludesDepreciationOfCurrentMonth")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
		
		If Object.DepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod
			And Object.FixedAssetKind <> PredefinedValue("Enum.PropertyKinds.Leased") Then
			
			Items.PictureInformation.Visible = True;
			Items.TipDepreciation.Visible = True;
			
			If Object.IncludesDepreciationOfCurrentMonth Then
				Items.TipDepreciation.Title = 
					NStr("vi = 'Số tiền khấu hao cuối tháng sẽ như chỉ ra trong chứng từ.
						 |Khi đóng tháng, sẽ không thực hiện trích khấu hao.';
						 |ru = 'Сумма амортизации на конец месяца будет, как указано в документе.
						 |При закрытии месяца не будет выполняться начисление амортизации.';
						 |en = 'The depreciation amount at the end of the month will be the same as specified in the document.
						 |Upon month-end closing, depreciation will not be accrued.'; fa = 'The depreciation amount at the end of the month will be the same as specified in the document.
						 |Upon month-end closing, depreciation will not be accrued.';
						 |it = 'Сумма амортизации на конец месяца будет, как указано в документе.
						 |При закрытии месяца не будет выполняться начисление амортизации.';
						 |pl = 'The depreciation amount at the end of the month will be the same as specified in the document.
						 |Upon month-end closing, depreciation will not be accrued.';
						 |tr = 'Ay sonu amortisman tutarı belgede belirtildiği gibi olacaktır.
						 |Ay sonu kapanışında, amortisman tahakkuku gerçekleşmeyecektir.'");
			Else
				Items.TipDepreciation.Title = 
					NStr("vi = 'Số tiền khấu hao vào cuối tháng sẽ bao gồm số tiền được chỉ ra trong chứng từ và số tiền được tính khi trích khấu hao.';
						|ru = 'Сумма амортизации на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
						|en = 'The depreciation amount at the end of the month will consist of the amount specified in the document and the amount calculated upon depreciation accrual.'; fa = 'The depreciation amount at the end of the month will consist of the amount specified in the document and the amount calculated upon depreciation accrual.';
						|it = 'Сумма амортизации на конец месяца будет складываться из суммы, указанной в документе и суммы, рассчитанной при начислении амортизации.';
						|pl = 'The depreciation amount at the end of the month will consist of the amount specified in the document and the amount calculated upon depreciation accrual.';
						|tr = 'Ay sonu amortisman tutarı, belgede gösterilen tutar ile amortisman tahakkukunda hesaplanan tutarın toplamı olacaktır.'");
			EndIf;
			
		Else
			
			Items.PictureInformation.Visible = False;
			Items.TipDepreciation.Visible = False;
			
		EndIf;	
		
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("AdjustmentOfInitialCost")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		Items.FAFillInTheAccountingForm.Visible = 
			Object.CostAdjustment
			Or Object.AdjustmentOfInitialCost
			Or Object.DepreciationAdjustment
				And Not Object.DepreciationAdjustmentForPeriod;
		
		If Object.FixedAssetKind = PredefinedValue("Enum.PropertyKinds.Leased") Then
			
			Items.FAFillInTheAccountingForm.Title = 
					NStr("vi = 'Giá trị tài sản thế chấp theo dữ liệu kế toán';
						|ru = 'Залоговую стоимость по данным учета';
						|en = 'Collateral value by accounting data'; fa = 'Collateral value by accounting data';
						|it = 'Залоговую стоимость по данным учета';
						|pl = 'Collateral value by accounting data';
						|tr = 'Muhasebe verilerine göre teminat değeri'");
					
			Items.FAFillInTheAccountingForm.ExtendedTooltip.Title = 
					NStr("vi = 'Điền giá trị tài sản thế chấp theo dữ liệu kế toán trong các dòng được chọn';
						|ru = 'Заполнить залоговую стоимость по данным учета в выбранных строках';
						|en = 'Fill the collateral value by accounting data in the selected lines'; fa = 'Fill the collateral value by accounting data in the selected lines';
						|it = 'Заполнить залоговую стоимость по данным учета в выбранных строках';
						|pl = 'Fill the collateral value by accounting data in the selected lines';
						|tr = 'Seçilen satırlardaki muhasebe verilerine göre teminat değerini doldur'");
					
		ElsIf (Object.CostAdjustment Or Object.AdjustmentOfInitialCost)
			And Object.DepreciationAdjustment
				And Not Object.DepreciationAdjustmentForPeriod Then
			
			Items.FAFillInTheAccountingForm.Title = 
				NStr("vi = 'Giá trị và khấu hao theo dữ liệu kế toán';
					|ru = 'Стоимость и амортизацию по данным учета';
					|en = 'Cost and depreciation by accounting data'; fa = 'بهای تمام‌شده و استهلاک بر اساس داده‌های حسابداری';
					|it = 'Costo e ammortamento in base ai dati della contabilità';
					|pl = 'Wartość i amortyzację wg danych ewidencji';
					|tr = 'Muhasebe verilerine göre maliyet ve amortisman'");
					
			Items.FAFillInTheAccountingForm.ExtendedTooltip.Title = 
				NStr("vi = 'Điền giá trị và khấu hao theo dữ liệu kế toán trong các hàng đã chọn';
					|ru = 'Заполнить стоимость и амортизацию по данным учета в выбранных строках';
					|en = 'Fill in the cost and depreciation according to accounting data in the selected lines'; fa = 'تکمیل بهای تمام‌شده و استهلاک طبق داده‌های حسابداری در سطرهای انتخاب‌شده';
					|it = 'Compilare il costo di pegno e l''ammortamento secondo i dati contabili nelle righe selezionate';
					|pl = 'Zapamiętaj wartość i amortyzację wg danych ewidencji w wybranych wierszach';
					|tr = 'Seçilen satırlardaki muhasebe verilerine göre maliyet ve amortismanı doldur'");
					
		ElsIf Object.CostAdjustment Or Object.AdjustmentOfInitialCost Then
			
			Items.FAFillInTheAccountingForm.Title = 
				NStr("vi = 'Giá trị theo dữ liệu kế toán';
					|ru = 'Стоимость по данным учета';
					|en = 'Cost by accounting data'; fa = 'بهای تمام‌شده بر اساس داده‌های حسابداری';
					|it = 'Стоимость по данным учета';
					|pl = 'Cost by accounting data';
					|tr = 'Muhasebe verilerine göre maliyet'");
					
			Items.FAFillInTheAccountingForm.ExtendedTooltip.Title = 
				NStr("vi = 'Điền giá trị theo dữ liệu kế toán trong các dòng được chọn';
					|ru = 'Заполнить стоимость по данным учета в выбранных строках';
					|en = 'Fill the cost by accounting data in the selected lines'; fa = 'Fill the cost by accounting data in the selected lines';
					|it = 'Заполнить стоимость по данным учета в выбранных строках';
					|pl = 'Fill the cost by accounting data in the selected lines';
					|tr = 'Seçilen satırlardaki muhasebe verilerine göre maliyeti doldur'");
					
		ElsIf Object.DepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod Then
			
			Items.FAFillInTheAccountingForm.Title = 
				NStr("vi = 'Khấu hao theo dữ liệu kế toán';
					|ru = 'Амортизацию по данным учета';
					|en = 'Depreciation by accounting data'; fa = 'Depreciation by accounting data';
					|it = 'Амортизацию по данным учета';
					|pl = 'Depreciation by accounting data';
					|tr = 'Muhasebe verilerine göre amortisman'");
					
			Items.FAFillInTheAccountingForm.ExtendedTooltip.Title = 
				NStr("vi = 'Điền khấu hao theo dữ liệu kế toán trong các dòng được chọn';
					|ru = 'Заполнить амортизацию по данным учета в выбранных строках';
					|en = 'Fill depreciation by accounting data in the selected lines'; fa = 'Fill depreciation by accounting data in the selected lines';
					|it = 'Заполнить амортизацию по данным учета в выбранных строках';
					|pl = 'Fill depreciation by accounting data in the selected lines';
					|tr = 'Seçilen satırlardaki muhasebe verilerine göre amortismanı doldur'");
					
		EndIf;
				
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or StructureOfChangedProps.Property("BonusDepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording")
		Or UpdateAll Then
			
			ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;
			
			PropertyValue = ?(Object.BonusDepreciationIncreaseRecording,
					NStr("vi = 'Khấu hao (tăng) (%1)';
						|ru = 'Амортизационная премия (увеличение) (%1)';
						|en = 'Bonus depreciation (increase) (%1)'; fa = 'Bonus depreciation (increase) (%1)';
						|it = 'Амортизационная премия (увеличение) (%1)';
						|pl = 'Bonus depreciation (increase) (%1)';
						|tr = 'Amortisman primi (artış) (%1)'"),
					NStr("vi = 'Khấu hao (giảm) (%1)';
						|ru = 'Амортизационная премия (уменьшение) (%1)';
						|en = 'Bonus depreciation (decrease) (%1)'; fa = 'Bonus depreciation (decrease) (%1)';
						|it = 'Амортизационная премия (уменьшение) (%1)';
						|pl = 'Bonus depreciation (decrease) (%1)';
						|tr = 'Amortisman primi (azalması) (%1)'"));
					
			PropertyValue = StrTemplate(PropertyValue, ComplCurrencyPresentation);
			Items.FADepreciationAllowance.Title = PropertyValue;

			Items.FADepreciationAllowance.ToolTip = 
				?(Object.BonusDepreciationIncreaseRecording,
					NStr("vi = 'Khấu hao sẽ được tăng với số tiền là bao nhiêu';
						|ru = 'На какую сумму будет увеличена амортизационная премия';
						|en = 'Amount to increase the depreciation bonus by'; fa = 'Amount to increase the depreciation bonus by';
						|it = 'На какую сумму будет увеличена амортизационная премия';
						|pl = 'Amount to increase the depreciation bonus by';
						|tr = 'Amortisman primi ne kadar artırılacak?'"),
					NStr("vi = 'Khấu hao sẽ được giảm với số tiền là bao nhiêu';
						|ru = 'На какую сумму будет уменьшена амортизационная премия';
						|en = 'Amount to decrease the depreciation bonus by'; fa = 'Amount to decrease the depreciation bonus by';
						|it = 'На какую сумму будет уменьшена амортизационная премия';
						|pl = 'Amount to decrease the depreciation bonus by';
						|tr = 'Amortisman primi ne kadar azaltılacak?'"));
			
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentForPeriod")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then

		Items.FAFillInDepreciationBasedOnAccountingParameters.Visible = 
			Object.DepreciationAdjustment
			And Not Object.DepreciationAdjustmentForPeriod
			And AvailableParametersForPeriod;
	
	EndIf;

	#EndRegion

	#Region ParametersPage
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("PostInAccounting")
		Or StructureOfChangedProps.Property("RecordInTA")
		Or UpdateAll Then
		
		Items.CurrentParameters.ChoiceList.Clear();
		Items.CurrentParameters.ChoiceList.Add("AsOfThePeriodStart", NStr("vi = 'Đầu kỳ';
																			|ru = 'На начало периода';
																			|en = 'As of the period start'; fa = 'در ابتدای دوره';
																			|it = 'All''inizio del periodo';
																			|pl = 'Na początek okresu';
																			|tr = 'Açılış'"));
		
		If Object.PostInAccounting 
			And FormServiceParameters.FALocalAccountingIsConductedIndependently Then
			Items.CurrentParameters.ChoiceList.Add("ACC", NStr("vi = 'Trong toàn kỳ (kế toán doanh nghiệp)';
																|ru = 'За весь период (бух. учет)';
																|en = 'For the whole period (local accounting)'; fa = 'برای کل دوره (حسابداری محلی)';
																|it = 'Per tutto il periodo (contabilità)';
																|pl = 'Za cały okres (ewidencja księgowa)';
																|tr = 'Tüm dönem boyunca (genel muhasebe)'"));
		EndIf;
		
		If Object.RecordInTA 
			And FormServiceParameters.ComplianceCAAccountingIsKept Then
			Items.CurrentParameters.ChoiceList.Add("TA", NStr("vi = 'Trong toàn kỳ (kế toán thuế)';
																|ru = 'За весь период (нал. учет)';
																|en = 'For the whole period (tax accounting)'; fa = 'برای کل دوره (حسابداری مالیاتی)';
																|it = 'Per tutto il periodo (contabilità fis.)';
																|pl = 'Za cały okres (ewidencja podatkowa)';
																|tr = 'Tüm dönem boyunca (vergi muhasebesi)'"));
		EndIf;
		
		If Object.RecordInManAccounting Then
			
			ValuePresentation = 
			?(Object.RecordInLocalAccounting And FormServiceParameters.FALocalAccountingIsConductedIndependently,
				NStr("vi = 'Trong toàn kỳ (kế toán quản trị)';
					|ru = 'За весь период (упр. учет)';
					|en = 'For the whole period (mgmt accounting)'; fa = 'For the whole period (mgmt accounting)';
					|it = 'Per tutto il periodo (contabilità gest.)';
					|pl = 'Za cały okres (ewidencja zarządcza)';
					|tr = 'Tüm dönem için (yönetim muhasebesi)'"),
				NStr("vi = 'Trong toàn kỳ';
					|ru = 'За весь период';
					|en = 'For the whole period'; fa = 'برای کل دوره';
					|it = 'Per tutto il periodo';
					|pl = 'Za cały okres';
					|tr = 'Tüm dönem için'"));
				
			Items.CurrentParameters.ChoiceList.Add("MA", ValuePresentation);
			
		EndIf;

		Items.FillInDepreciationCalculationParametersAll.Visible = 
			Object.AdjustmentModeFromPreviousDate
			And Items.CurrentParameters.ChoiceList.Count() > 2;
			
		Items.CalculateDepreciationAll.Visible = 
			Object.AdjustmentModeFromPreviousDate
			And Items.CurrentParameters.ChoiceList.Count() > 2;
		
	EndIf;

	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or UpdateAll Then
		
		Items.CurrentParameters.Visible = AvailableParametersForPeriod;
			
	EndIf;
	
	If StructureOfChangedProps.Property("CurrentParameters")
		Or UpdateAll Then
			
		If Form.CurrentParameters = "MA" Then
			Items.ParametersPage2.CurrentPage = Items.ParametersPageForEntireMaPeriod;
		ElsIf Form.CurrentParameters = "ACC" Then
			Items.ParametersPage2.CurrentPage = Items.ParametersPageForEntireACPeriod;
		ElsIf Form.CurrentParameters = "TA" Then
			Items.ParametersPage2.CurrentPage = Items.ParametersPageForEntirePeriodTa;
		Else
			Items.ParametersPage2.CurrentPage = Items.ParametersPageAtBeginningOfPeriod;
		EndIf;
			
	EndIf;
	
	#EndRegion
	
	#Region BUParameters
	If StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
			
		ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;
		Items.FinancialDetailsForThePeriodACDepreciationInAccounting.Title = StrTemplate(NStr("vi = 'Khấu hao (%1)';
																								|ru = 'Амортизация (%1)';
																								|en = 'Depreciation (%1)'; fa = 'Depreciation (%1)';
																								|it = 'Ammortamento (%1)';
																								|pl = 'Amortyzacja (%1)';
																								|tr = 'Amortisman (%1)'"), ComplCurrencyPresentation);
		Items.FinancialDetailsForThePeriodACCostUsedToCalculateDepreciationInAccounting.Title = StrTemplate(NStr("vi = 'Giá trị (%1)';
																												|ru = 'Стоимость (%1)';
																												|en = 'Cost (%1)'; fa = 'Cost (%1)';
																												|it = 'Costo (%1)';
																												|pl = 'Wartość (%1)';
																												|tr = 'Maliyet (%1)'"), ComplCurrencyPresentation);
		Items.FinancialDetailsForThePeriodACCostInAccounting.Title = StrTemplate(NStr("vi = 'Giá trị (%1)';
																						|ru = 'Стоимость (%1)';
																						|en = 'Cost (%1)'; fa = 'Cost (%1)';
																						|it = 'Costo (%1)';
																						|pl = 'Wartość (%1)';
																						|tr = 'Maliyet (%1)'"), ComplCurrencyPresentation);
				
		Items.ParametersForPeriodACGroupChangeInDepreciation.ShowInHeader = False;
		Items.FinancialDetailsForThePeriodACDepreciationLocalUpdate.Title = StrTemplate(NStr("vi = 'Thay đổi khấu hao (%1)';
																							|ru = 'Изменение амортизации (%1)';
																							|en = 'Depreciation change (%1)'; fa = 'Depreciation change (%1)';
																							|it = 'Modifica ammortamento (%1)';
																							|pl = 'Zmiana amortyzacji (%1)';
																							|tr = 'Amortisman değişimi (%1)'"), ComplCurrencyPresentation);
			
	EndIf;	
	#EndRegion
	
	#Region MaParameters

	If UpdateAll Then
		
		PropertyValue =
			Items.FinancialDetailsForThePeriodDepreciationLocalUpdate.Visible
			And Items.FinancialDetailsForThePeriodDepreciationUpdate.Visible;
			 
		Items.ParametersForPeriodGroupDepreciationChange.ShowTitle = PropertyValue;
		Items.ParametersForPeriodGroupDepreciationChange.ShowInHeader = PropertyValue;
				
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
			
		Items.FinancialDetailsForThePeriodDepreciationLocal.Title = StrTemplate(NStr("vi = 'Khấu hao (%1)';
																					|ru = 'Амортизация (%1)';
																					|en = 'Depreciation (%1)'; fa = 'Depreciation (%1)';
																					|it = 'Ammortamento (%1)';
																					|pl = 'Amortyzacja (%1)';
																					|tr = 'Amortisman (%1)'"), ComplCurrencyPresentation);
		Items.FinancialDetailsForThePeriodDepreciation.Title = StrTemplate(NStr("vi = 'Khấu hao (%1)';
																				|ru = 'Амортизация (%1)';
																				|en = 'Depreciation (%1)'; fa = 'Depreciation (%1)';
																				|it = 'Ammortamento (%1)';
																				|pl = 'Amortyzacja (%1)';
																				|tr = 'Amortisman (%1)'"), CurrencyOfManPresentation);
		
		If Items.FinancialDetailsForThePeriodDepreciationLocalUpdate.Visible
			And Items.FinancialDetailsForThePeriodDepreciationUpdate.Visible Then
			
			Items.FinancialDetailsForThePeriodDepreciationLocalUpdate.Title = ComplCurrencyPresentation;
			Items.FinancialDetailsForThePeriodDepreciationUpdate.Title = CurrencyOfManPresentation;
			
		Else
			
			Items.FinancialDetailsForThePeriodDepreciationLocalUpdate.Title = StrTemplate(NStr("vi = 'Thay đổi khấu hao (%1)';
																								|ru = 'Изменение амортизации (%1)';
																								|en = 'Depreciation change (%1)'; fa = 'Depreciation change (%1)';
																								|it = 'Modifica ammortamento (%1)';
																								|pl = 'Zmiana amortyzacji (%1)';
																								|tr = 'Amortisman değişimi (%1)'"), ComplCurrencyPresentation);
			Items.FinancialDetailsForThePeriodDepreciationUpdate.Title = StrTemplate(NStr("vi = 'Thay đổi khấu hao (%1)';
																							|ru = 'Изменение амортизации (%1)';
																							|en = 'Depreciation change (%1)'; fa = 'Depreciation change (%1)';
																							|it = 'Modifica ammortamento (%1)';
																							|pl = 'Zmiana amortyzacji (%1)';
																							|tr = 'Amortisman değişimi (%1)'"), CurrencyOfManPresentation);
			
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("UsefulLifeForCalculatingDepreciationMonth")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("BeginOfPeriod")
		Or StructureOfChangedProps.Property("FinancialDetailsForThePeriod")
		Or UpdateAll Then
		
		If Object.FinancialDetailsForThePeriod.Count() > 0 Then
			Form.UsefulLifeMAExplanation = 
				NonCurrentAssetsClientServer.PresentationOfNumberOfMonthsByString(Object.FinancialDetailsForThePeriod[0].UsefulLifeForCalculatingDepreciationMonth);
		Else
			Form.UsefulLifeMAExplanation =  "";
		EndIf;
			
	EndIf;
	
	If StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Items.UUParametersGroup.ShowTitle = Object.RecordInLocalAccounting;
			
	EndIf;
	
	#EndRegion
	
	#Region ExpensesAndIncomePage

	If StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("CostIncreaseRecording")
		Or StructureOfChangedProps.Property("CostDecreaseRecording") Then
			
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemCostIncrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemCostReduction);
	EndIf;
	
	If StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("DepreciationIncreaseRecording")
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording")
		Or StructureOfChangedProps.Property("RecordThisYearDepreciationDecreaseAsStorno") Then
			
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemDepreciationIncrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.ExpenseItemThisYearDepreciationDecrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemDepreciationDecrease);
	EndIf;

	If StructureOfChangedProps.Property("BonusDepreciationAdjustment")
		Or StructureOfChangedProps.Property("BonusDepreciationIncreaseRecording") 
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording") Then
			
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemCostDecrease);
		IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemBonusDepreciationDecrease);
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodCostDecrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"AssetExpenseItemCostReduction,DimensionOfExpensesCostReduction,
			|BusinessUnitCostDecrease,LineOfBusinessCostDecrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataCostDecrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodCostDecrease,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodDepreciationIncrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"AssetExpenseItemDepreciationIncrease,DimensionOfExpensesDepreciationIncrease,
			|BusinessUnitDepreciationIncrease,LineOfBusinessDepreciationIncrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataDepreciationIncrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodDepreciationIncrease,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodCurrentYearDepreciationDecrease") 
		Or UpdateAll Then
			
		FieldsNames = 
			"ExpenseItemThisYearDepreciationDecrease,DimensionThisYearDepreciationDecrease,
			|BusinessUnitThisYearDepreciationDecrease,LineOfBusinessThisYearDepreciationDecrease,
			|BusinessUnitAndLineOfBusinessMatchAccountingDataThisYearDepreciationDecrease";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodCurrentYearDepreciationDecrease,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("BonusDepreciationAdjustment") 
		Or StructureOfChangedProps.Property("BonusDepreciationIncreaseRecording") 
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording") 
		Or StructureOfChangedProps.Property("ExpenseRecordMethodBonusDepreciation") 
		Or UpdateAll Then
			
		FieldsNames = 
			"AssetExpenseItemCostDecrease,DimensionBonusDepreciation,
			|Business_UnitBonusDepreciation,LineOfBusiness_BonusDepreciation,
			|ExpenseParametersMatchAccountingDataBonusDepreciation";
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpenseRecordMethodBonusDepreciation,
			Form, 
			FieldsNames);
	
	EndIf;

	If StructureOfChangedProps.Property("CostAdjustment") 
		Or StructureOfChangedProps.Property("CostDecreaseRecording") 
		Or StructureOfChangedProps.Property("RecordCostDecreaseByReversal") 
		Or UpdateAll Then

		If Object.RecordCostDecreaseByReversal Then
			Items.CostReductionGroup.Title = NStr("vi = 'Giảm giá trị (đảo ngược)';
													|ru = 'Уменьшение стоимости (сторно)';
													|en = 'Cost decrease (storno)'; fa = 'Cost decrease (storno)';
													|it = 'Уменьшение стоимости (сторно)';
													|pl = 'Cost decrease (storno)';
													|tr = 'Maliyet düşüşü (YM)'");
		Else
			Items.CostReductionGroup.Title = NStr("vi = 'Giảm giá trị';
													|ru = 'Уменьшение стоимости';
													|en = 'Cost decrease'; fa = 'کاهش بهای تمام‌شده';
													|it = 'Уменьшение стоимости';
													|pl = 'Zmniejszenie kosztów';
													|tr = 'Maliyet düşüşü'");
		EndIf;

	EndIf;

	If StructureOfChangedProps.Property("DepreciationAdjustment") 
		Or StructureOfChangedProps.Property("DepreciationDecreaseRecording") 
		Or StructureOfChangedProps.Property("RecordThisYearDepreciationDecreaseAsStorno") 
		Or UpdateAll Then

		If Object.RecordThisYearDepreciationDecreaseAsStorno Then
			Items.GroupDecreaseInDepreciationOfPreviousYears.Title = NStr("vi = 'Giảm khấu hao các năm trước';
																			|ru = 'Уменьшение амортизации прошлых лет';
																			|en = 'Depreciation decrease of previous years'; fa = 'کاهش استهلاک سال‌های قبل';
																			|it = 'Уменьшение амортизации прошлых лет';
																			|pl = 'Depreciation decrease of previous years';
																			|tr = 'Önceki yıllara göre amortismanın azaltılması'");
			Items.DecorationReductionOfDepreciation.Title = NStr("vi = 'Giảm khấu hao các năm trước';
																|ru = 'Уменьшение амортизации прошлых лет';
																|en = 'Depreciation decrease of previous years'; fa = 'کاهش استهلاک سال‌های قبل';
																|it = 'Уменьшение амортизации прошлых лет';
																|pl = 'Depreciation decrease of previous years';
																|tr = 'Önceki yıllara göre amortismanın azaltılması'");
		Else
			Items.GroupDecreaseInDepreciationOfPreviousYears.Title = NStr("vi = 'Giảm khấu hao';
																			|ru = 'Уменьшение амортизации';
																			|en = 'Depreciation decrease'; fa = 'Depreciation decrease';
																			|it = 'Уменьшение амортизации';
																			|pl = 'Depreciation decrease';
																			|tr = 'Amortismanın azaltılması'");
			Items.DecorationReductionOfDepreciation.Title = NStr("vi = 'Giảm khấu hao';
																|ru = 'Уменьшение амортизации';
																|en = 'Depreciation decrease'; fa = 'Depreciation decrease';
																|it = 'Уменьшение амортизации';
																|pl = 'Depreciation decrease';
																|tr = 'Amortismanın azaltılması'");
		EndIf;

	EndIf;

	If StructureOfChangedProps.Property("BonusDepreciationAdjustment") 
		Or StructureOfChangedProps.Property("BonusDepreciationDecreaseRecording") 
		Or StructureOfChangedProps.Property("RecordingOfBonusDepreciationDecreaseStorno") 
		Or UpdateAll Then

		If Object.RecordingOfBonusDepreciationDecreaseStorno Then
			Items.GroupBonusDepreciationIncrease.Title = NStr("vi = 'Giảm khấu hao (đảo ngược)';
																|ru = 'Уменьшение амортизационной премии (сторно)';
																|en = 'Bonus depreciation decrease (storno)'; fa = 'Bonus depreciation decrease (storno)';
																|it = 'Уменьшение амортизационной премии (сторно)';
																|pl = 'Bonus depreciation decrease (storno)';
																|tr = 'Amortisman primi azaltılması'");
			Items.DecorationBonusDepreciationIncrease.Title = NStr("vi = 'Giảm khấu hao (đảo ngược)';
																	|ru = 'Уменьшение амортизационной премии (сторно)';
																	|en = 'Bonus depreciation decrease (storno)'; fa = 'Bonus depreciation decrease (storno)';
																	|it = 'Уменьшение амортизационной премии (сторно)';
																	|pl = 'Bonus depreciation decrease (storno)';
																	|tr = 'Amortisman primi azaltılması'");
		Else
			Items.GroupBonusDepreciationIncrease.Title = NStr("vi = 'Tăng khấu hao';
																|ru = 'Увеличение амортизационной премии';
																|en = 'Bonus depreciation increase'; fa = 'افزایش استهلاک تشویقی';
																|it = 'Увеличение амортизационной премии';
																|pl = 'Bonus depreciation increase';
																|tr = 'Amortisman primi arttırılması'");
			Items.DecorationBonusDepreciationIncrease.Title = NStr("vi = 'Tăng khấu hao';
																	|ru = 'Увеличение амортизационной премии';
																	|en = 'Bonus depreciation increase'; fa = 'افزایش استهلاک تشویقی';
																	|it = 'Увеличение амортизационной премии';
																	|pl = 'Bonus depreciation increase';
																	|tr = 'Amortisman primi arttırılması'");
		EndIf;

	EndIf;

	#EndRegion
	
	SaveDetailsValuesBeforeChanging(Form);

	FixedAssetCostAndDepreciationAdjustmentClientServerLocalization.ConfigureDependentFormElements(Form, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If UpdateAll Then
		
		Items.DepreciationUntil2009.Visible = False;
		Items.TaDepreciationAtBeginningOfPeriodCurrency.Visible = False;
		Items.PDDepreciationAtBeginningOfPeriodCurrency.Visible = False;
		Items.DepreciationOfCFAtBeginningOfPeriodCurrency.Visible = False;
		Items.DepreciationOfPRTFAtBeginningOfPeriodCurrency.Visible = False;
		Items.DecorationBonusDepreciationIncrease.Visible = False;
		Items.DecorationReductionOfBonusDepreciation.Visible = False;
		Items.DecorationIncreaseInCFRevenues.Visible = False;
		Items.DecorationReductionOfCFRevenues.Visible = False;
		
		If Not FormServiceParameters.ComplianceCAAccountingIsKept Then
			Items.LineOfBusiness_BonusDepreciation.Visible = False;
			Items.LineOfBusinessBonusDepreciationDecrease.Visible = False;
			Items.LineOfBusinessTargetFinancingIncomeIncrease.Visible = False;
			Items.LineOfBusinessTargetFinancingIncomeDecrease.Visible = False;
		EndIf;
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);

	EndIf;
	
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrency",
			ComplCurrency,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(ComplCurrency),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			CurrencyOfMan = ComplCurrency,
			FormServiceParameters);
			
		ParentCompany = AccountingPoliciesTaxSettingsCached.ParentCompany(Object.Organization);
		SetFormFunctionalOptionParameters(New Structure("Organization", ParentCompany));
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		SettingDate = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));
		
		AccountingSettings = AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Object.Organization, SettingDate);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"AccountingPolicyForFixedAssets",
			AccountingSettings.AccountingPolicyForFixedAssets,
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"ProcedureForCalculatingManSDepreciation",
			AccountingSettings.ProcedureOfFixedAssetDepreciationCharge,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"DepreciationChargeProcedureLocal",
			AccountingSettings.ProcedureOfFixedAssetDepreciationChargeLocal,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ProcedureForCalculatingDepreciationManLease",
			AccountingSettings.LeasedAssetDepreciationChargeProcedureManag,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"LeasedFixedAssetDepreciationChargeProcedureLocal",
			AccountingSettings.LeasedFixedAssetDepreciationChargeProcedureLocal,
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, SettingDate),
			FormServiceParameters);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FSB6IsApplied",
			AccountingSettings.FSB6IsApplied,
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or UpdateAll Then
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"TheseAreRentedFA",
			Documents.FixedAssetCostAndDepreciationAdjustment.TheseAreRentedFA(Object),
			FormServiceParameters);
			
	EndIf;
		
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("BeginOfPeriod") 
		Or StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or UpdateAll Then
		
		Documents.FixedAssetCostAndDepreciationAdjustment.GetParametersOfAccountingPoliciesForPeriod(Object, FormServiceParameters);
		
		If FormServiceParameters.TheseAreRentedFA
				And FormServiceParameters.ProcedureForCalculatingDepreciationManLease_ForPeriod = Enums.DepreciationProcedure.StartingNextMonth
			Or Not FormServiceParameters.TheseAreRentedFA
				And FormServiceParameters.ProcedureForCalculatingDepreciationUpr_ForPeriod = Enums.DepreciationProcedure.StartingNextMonth Then
			
			Items.FinancialDetailsForThePeriod.ChangeRowSet = False;
			Items.FinancialDetailsForThePeriodDate.ReadOnly = True;
		Else
			Items.FinancialDetailsForThePeriod.ChangeRowSet = True;
			Items.FinancialDetailsForThePeriodDate.ReadOnly = False;
		EndIf;
		
		If Not FormServiceParameters.FSB6_IsAppliedForPeriod
			Or FormServiceParameters.TheseAreRentedFA
				And FormServiceParameters.DepreciationProcedureLocalLease_ForPeriod = Enums.DepreciationProcedure.StartingNextMonth
			Or Not FormServiceParameters.TheseAreRentedFA
				And FormServiceParameters.ProcedureForCalculatingDepreciationRegl_ForPeriod = Enums.DepreciationProcedure.StartingNextMonth Then
				
			Items.FinancialDetailsForThePeriodAC.ChangeRowSet = False;
			Items.FinancialDetailsForThePeriodACDate.ReadOnly = True;
		Else
			Items.FinancialDetailsForThePeriodAC.ChangeRowSet = True;
			Items.FinancialDetailsForThePeriodACDate.ReadOnly = False;
		EndIf;
		
	EndIf;
		
	If StructureOfChangedProps.Property("Organization") 
		Or UpdateAll Then
		
		Items.FACostInManagementAccounting.Visible = False;
		Items.FACostPermanentDifference.Visible = False;
		Items.FACostInTaxAccounting.Visible = False;
		Items.FACostInAccounting.Visible = False;
		
		Items.FADepreciationInAccounting.Visible = False;
		Items.FADepreciationInTaxAccounting.Visible = False;
		Items.FADepreciationPermanentDifferences.Visible = False;
		Items.FADepreciationManagementAccounting.Visible = False;
		
		Items.FAInitialCostTA.Visible = False;
		
		//
		CurrencyOfManPresentation = FormServiceParameters.CurrencyOfManPresentation;
		ComplCurrencyPresentation = FormServiceParameters.ComplCurrencyPresentation;
		
		Items.FACostInManagementAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'MA';
																|pl = 'MA';
																|tr = 'YM'"), CurrencyOfManPresentation);
			
		Items.FADepreciationManagementAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'QT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'Ewidencja zarządcza';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
			
		Items.OsstoimostUUSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị';
																|ru = 'Стоимость';
																|en = 'Cost'; fa = 'بهای تمام‌شده';
																|it = 'Costo';
																|pl = 'Wartość';
																|tr = 'Maliyet'"), CurrencyOfManPresentation);
		
		Items.OsamortizatsiyaUUSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao';
																|ru = 'Амортизация';
																|en = 'Depreciation'; fa = 'استهلاک';
																|it = 'Ammortamento';
																|pl = 'Amortyzacja';
																|tr = 'Amortisman'"), CurrencyOfManPresentation);
		
		Items.FAInitialCostMA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTQT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità gestionale';
																|pl = 'Ewidencja zarządcza';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
		
		Items.InitialCostOfYYSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Nguyên giá';
																|ru = 'Первоначальная стоимость (УУ)';
																|en = 'Initial cost (mgmt)'; fa = 'بهای اولیه (مدیریت)';
																|it = 'Costo iniziale (gest)';
																|pl = 'Wartość początkowa (zarz)';
																|tr = 'Başlangıç değeri (YM)'"), CurrencyOfManPresentation);
		
		Items.FACostInAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.FADepreciationInAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.OsstoimostUsedSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị (KTDN)';
																|ru = 'Стоимость (БУ)';
																|en = 'Cost (LA)'; fa = 'بها (محلی)';
																|it = 'Costo (contabilità)';
																|pl = 'Wartość (EK)';
																|tr = 'Maliyet (LA)'"), ComplCurrencyPresentation);
		
		Items.OsamortizatsiyaUsedSeparately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao (KTDN)';
																|ru = 'Амортизация (БУ)';
																|en = 'Depreciation (LA)'; fa = 'استهلاک (محلی)';
																|it = 'Ammortamento (regol)';
																|pl = 'Amortyzacja EK';
																|tr = 'Amortisman (LA)'"), ComplCurrencyPresentation);
			
		Items.FAInitialCostLocalAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
		
		Items.OpenvanillaTheValueOfBFromA.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Nguyên giá (KTDN)';
																|ru = 'Первоначальная стоимость (БУ)';
																|en = 'Initial cost (local)'; fa = 'بهای اولیه (محلی)';
																|it = 'Costo iniziale (regol)';
																|pl = 'Wartość początkowa (regl)';
																|tr = 'Başlangıç değeri (LA)'"), ComplCurrencyPresentation);
		
		Items.FACostUsedToCalculateDepreciationInAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị để trích khấu hao (KTDN)';
																|ru = 'Стоимость для вычисления амортизации (БУ)';
																|en = 'Cost to calculate depreciation (LA)'; fa = 'بهای تمام‌شده برای محاسبه استهلاک (محلی)';
																|it = 'Costo per il calcolo dell''ammortamento (reg.)';
																|pl = 'Cost to calculate depreciation (LA)';
																|tr = 'Amortisman hesaplaması için maliyet (LA)'"), ComplCurrencyPresentation);
			
		Items.FACostUsedToCalculateDepreciationInManagementAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị để trích khấu hao (KTQT)';
																|ru = 'Стоимость для вычисления амортизации (УУ)';
																|en = 'Cost to calculate depreciation (MA)'; fa = 'بهای تمام‌شده برای محاسبه استهلاک (مدیریت)';
																|it = 'Prezzo per il calcolo dell''ammortamento';
																|pl = 'Cost to calculate depreciation (MA)';
																|tr = 'Amortisman hesaplaması için maliyet (YM)'"), CurrencyOfManPresentation);

		If FormServiceParameters.ReglVNAAccountingIsConductedIndependently_ForPeriod Then
			Items.FinancialDetailsForThePeriodLocalCost.Title = StrTemplate(NStr("vi = 'Giá trị tài chính (%1)';
																				|ru = 'Стоимость регл. (%1)';
																				|en = 'Local cost (%1)'; fa = 'Local cost (%1)';
																				|it = 'Costo regolatorio (%1)';
																				|pl = 'Wartość reg. (%1)';
																				|tr = 'Net başlangıç maliyeti (yerel). (%1)'"), ComplCurrencyPresentation);
			Items.FinancialDetailsForThePeriodCost.Title = StrTemplate(NStr("vi = 'Giá trị quản trị (%1)';
																			|ru = 'Стоимость упр. (%1)';
																			|en = 'Mgmt cost (%1)'; fa = 'Mgmt cost (%1)';
																			|it = 'Costo gestionale (%1)';
																			|pl = 'Wartość zarz. (%1)';
																			|tr = 'Net başlangıç maliyeti (yönetim). (%1)'"), CurrencyOfManPresentation);
		Else
			Items.FinancialDetailsForThePeriodLocalCost.Title = StrTemplate(NStr("vi = 'Chi phí (%1)';
																				|ru = 'Стоимость (%1)';
																				|en = 'Cost (%1)'; fa = 'Cost (%1)';
																				|it = 'Costo (%1)';
																				|pl = 'Wartość (%1)';
																				|tr = 'Maliyet (%1)'"), ComplCurrencyPresentation);
			Items.FinancialDetailsForThePeriodCost.Title = StrTemplate(NStr("vi = 'Chi phí (%1)';
																			|ru = 'Стоимость (%1)';
																			|en = 'Cost (%1)'; fa = 'Cost (%1)';
																			|it = 'Costo (%1)';
																			|pl = 'Wartość (%1)';
																			|tr = 'Maliyet (%1)'"), CurrencyOfManPresentation);
		EndIf;
		
		Items.FinancialDetailsForThePeriodResidualValueLocal.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý';
																|ru = 'Ликвидационная стоимость';
																|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
																|it = 'Prezzo di liquidazione';
																|pl = 'Wartość likwidacyjna';
																|tr = 'Artık değer'"), ComplCurrencyPresentation);
			
		Items.FinancialDetailsForThePeriodResidualValueMan.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Giá trị thanh lý';
																|ru = 'Ликвидационная стоимость';
																|en = 'Residual value'; fa = 'ارزش باقی‌مانده';
																|it = 'Prezzo di liquidazione';
																|pl = 'Wartość likwidacyjna';
																|tr = 'Artık değer'"), CurrencyOfManPresentation);
		
		Items.FADepreciationAsOfTheYearStartBookkeeping.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTDN';
																|ru = 'БУ';
																|en = 'LA'; fa = 'محلی';
																|it = 'Contabilità civilistica';
																|pl = 'EK';
																|tr = 'Genel Muhasebe'"), ComplCurrencyPresentation);
			
		Items.FADepreciationAsOfTheYearStartTaxAccounting.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'KTTh';
																|ru = 'НУ';
																|en = 'TA'; fa = 'مالیاتی';
																|it = 'Contabilità fiscale';
																|pl = 'EP';
																|tr = 'Vergi muhasebesi'"), ComplCurrencyPresentation);
			
		Items.FAPermanentDifferencesInDepreciationAsOfTheYearStart.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'CLVV';
																|ru = 'ПР';
																|en = 'PD'; fa = 'تفاوت دائم';
																|it = 'Differenze permanenti';
																|pl = 'RT';
																|tr = 'Sabit farklar'"), ComplCurrencyPresentation);
			
		Items.FADepreciationAtBeginningOfYearMa.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'QT';
																|ru = 'УУ';
																|en = 'MA'; fa = 'مدیریت';
																|it = 'Contabilità Gestionale';
																|pl = 'EZ';
																|tr = 'Yönetim Muhasebesi'"), CurrencyOfManPresentation);
			
		Items.FATargetFundsInDepreciationAsOfTheYearStart.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao đầu năm (tài chính mục tiêu)';
																|ru = 'Амортизация на начало года (целевое финансирование)';
																|en = 'Depreciation as of year start (target financing)'; fa = 'استهلاک در ابتدای سال (تأمین مالی هدفمند)';
																|it = 'Depreciation as of year start (target financing)';
																|pl = 'Depreciation as of year start (target financing)';
																|tr = 'Yıl başlangıcındaki amortisman (hedef finansman)'"), ComplCurrencyPresentation);
		
		Items.FADepreciationAtBeginningOfYearAC_Separately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao vào đầu kỳ (KTDN)';
																|ru = 'Амортизация на начало года (БУ)';
																|en = 'Depreciation as of the beginning of the year (LA)'; fa = 'Depreciation as of the beginning of the year (LA)';
																|it = 'Depreciation as of the beginning of the year (LA)';
																|pl = 'Depreciation as of the beginning of the year (LA)';
																|tr = 'Yıl başı amortismanı (GM)'"), ComplCurrencyPresentation);
			
		Items.FADepreciationAtBeginningOfYearUU_Separately.Title = 
			NonCurrentAssetsClientServer.AddCurrencyToLine(NStr("vi = 'Khấu hao vào đầu kỳ (KTQT)';
																|ru = 'Амортизация на начало года (УУ)';
																|en = 'Depreciation as of the beginning of the year (MA)'; fa = 'Depreciation as of the beginning of the year (MA)';
																|it = 'Depreciation as of the beginning of the year (MA)';
																|pl = 'Depreciation as of the beginning of the year (MA)';
																|tr = 'Yıl başı amortismanı (YM)'"), CurrencyOfManPresentation);
		
	EndIf;
	
	If StructureOfChangedProps.Property("FixedAssetKind") 
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustment") Then
			
		ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
		IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);
	EndIf;
	
	FixedAssetCostAndDepreciationAdjustmentLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("FixedAssetKind")
		Or StructureOfChangedProps.Property("CostAdjustment")
		Or StructureOfChangedProps.Property("DepreciationAdjustment")
		Or StructureOfChangedProps.Property("FA") 
		Or StructureOfChangedProps.Property("FixedAsset") Then
				
		Return True;
	EndIf; 
	
	Return False;

EndFunction

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()

	FillInHeaderForSelectedFA();

EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()

	ConfigureDependentFormElementsOnServer("Organization");
	
EndProcedure

#EndRegion

#Region BarcodesAndTradeEquipment

&AtServer
Procedure ProcessBarcodes(Val BarcodeData_5)
	
	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);
	ObjectsArray = NonCurrentAssets.FindFixedAssetsByBarcodes(BarcodeData_5, PickingParameters);
	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ObjectsArray);
	
	If AddedRows.Count() <> 0 Then
		FillInHeaderForSelectedFA();
	EndIf;
	
EndProcedure

&AtClient
Procedure LoadDataFromTSD()
	
	ClearMessages();
	
	EquipmentManagerClient.StartDownloadingDataFromTSD(
		New CallbackDescription("DownloadFromTSDCompletion", ThisObject),
		UUID);
	
EndProcedure

&AtClient
Procedure DownloadFromTSDCompletion(Result, AdditionalParameters) Export
	
	If Result.Result Then
		ProcessBarcodes(Result.TableOfGoods);
	Else
		EquipmentManagerTMClient.ReportError(Result);
	EndIf;
	
EndProcedure

#EndRegion

#Region ManagingParametersForPeriod

&AtClient
Procedure BeginOfPeriodStartChoiceCompletion(SelectedPeriod, AdditionalParameters) Export 
	
	If SelectedPeriod = Undefined Then
		Return;
	EndIf;
	
	If SelectedPeriod = AttributesValuesBeforeChange.BeginOfPeriod Then
		Return;
	EndIf;

	Modified = True;
	Object.BeginOfPeriod = BegOfMonth(SelectedPeriod);
	
	If Not CheckBeginningOfPeriod() Then
		Return;
	EndIf;
	
	StartFillingInDepreciationCalculationParameters();

EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChangeCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Object.AdjustmentModeFromPreviousDate = AttributesValuesBeforeChange.AdjustmentModeFromPreviousDate;
		Return;
	EndIf;
	
	If Object.AdjustmentModeFromPreviousDate Then
		
		Object.BeginOfPeriod = MaximumStartOfPeriod(Object.Date);
		
	EndIf;

	ConfigureDependentFormElements("AdjustmentModeFromPreviousDate,BeginOfPeriod");

	If Object.AdjustmentModeFromPreviousDate Then
		
		StartFillingInDepreciationCalculationParameters();
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure SaveDetailsValuesBeforeChanging(Form)
	
	NewValues = New Structure("AdjustmentModeFromPreviousDate,BeginOfPeriod");
	FillPropertyValues(NewValues, Form.Object);
	
	Form.AttributesValuesBeforeChange = New FixedStructure(NewValues);
	
EndProcedure

&AtClient
Function CheckBeginningOfPeriod()

	If BegOfMonth(Object.BeginOfPeriod) >= BegOfMonth(Object.Date) Then
		
		WarningText = NStr("vi = 'Đầu kỳ điều chỉnh không được muộn hơn %1';
							|ru = 'Начало периода корректировки должно быть не позже %1';
							|en = 'The start of the adjustment period must be not later than %1'; fa = 'The start of the adjustment period must be not later than %1';
							|it = 'L''inizio del periodo di aggiustamento non deve essere successivo a %1';
							|pl = 'Początek okresu korekty powinien być nie później niż %1';
							|tr = 'Ayarlama döneminin başlangıcı en geç %1 olmalıdır'");
		WarningText = StrTemplate(WarningText, Format(BegOfMonth(Object.Date), "DLF=D;"));
		
		ShowMessageBox(,WarningText);
		
		Object.BeginOfPeriod = AttributesValuesBeforeChange.BeginOfPeriod;
		
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

&AtClient
Procedure StartFillingInDepreciationCalculationParameters()
	
	QueryText = NStr("vi = 'Điền lại tham số và tính khấu hao trong tất cả sổ kế toán?';
					|ru = 'Перезаполнить параметры и рассчитать амортизацию во всех учетах?';
					|en = 'Refill the parameters and calculate depreciation in all types of accounting?'; fa = 'Refill the parameters and calculate depreciation in all types of accounting?';
					|it = 'Refill the parameters and calculate depreciation in all types of accounting?';
					|pl = 'Refill the parameters and calculate depreciation in all types of accounting?';
					|tr = 'Parametreler yeniden doldurulsun ve tüm muhasebe türlerinde amortisman hesaplansın mı?'");
	CallbackDescription = New CallbackDescription("FillInDepreciationCalculationParametersEnd", ThisObject, Undefined);
	ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure FillInDepreciationCalculationParametersEnd(QuestionResult, AccountingSection) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	TimeConsumingOperation = FillInDepreciationCalculationParametersATServer(AccountingSection);

	CallbackOnCompletion = New CallbackDescription("ProcessResultOfFillingInDepreciationCalculationParameters", ThisObject, AccountingSection);
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.MessageText = NStr("vi = 'Đang điền tham số kế toán';
										|ru = 'Выполняется заполнение параметров учета';
										|en = 'Filling in accounting parameters'; fa = 'Filling in accounting parameters';
										|it = 'Filling in accounting parameters';
										|pl = 'Filling in accounting parameters';
										|tr = 'Muhasebe parametreleri dolduruluyor'");
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);

EndProcedure

&AtServer
Function FillInDepreciationCalculationParametersATServer(Val AccountingSection)
	
	FunctionParameters = New Structure;
	FunctionParameters.Insert("Ref", Object.Ref);
	FunctionParameters.Insert("Date", Object.Date);
	FunctionParameters.Insert("Organization", Object.Organization);
	FunctionParameters.Insert("PostInAccounting", Object.PostInAccounting);
	FunctionParameters.Insert("RecordInTA", Object.RecordInTA);
	FunctionParameters.Insert("RecordInManAccounting", Object.RecordInManAccounting);
	FunctionParameters.Insert("FA", Object.FA.Unload());
	FunctionParameters.Insert("AdjustmentModeFromPreviousDate", Object.AdjustmentModeFromPreviousDate);
	FunctionParameters.Insert("BeginOfPeriod", Object.BeginOfPeriod);
	FunctionParameters.Insert("BonusDepreciationAdjustment", Object.BonusDepreciationAdjustment);
	FunctionParameters.Insert("BonusDepreciationIncreaseRecording", Object.BonusDepreciationIncreaseRecording);
	FunctionParameters.Insert("IncludesDepreciationOfCurrentMonth", Object.IncludesDepreciationOfCurrentMonth);
	FunctionParameters.Insert("AccountingSection", AccountingSection);

	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.FixedAssetCostAndDepreciationAdjustment.DepreciationCalculationParameters", FunctionParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure ProcessResultOfFillingInDepreciationCalculationParameters(Result, AccountingSection) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ProcessResultOfFillingInDepreciationCalculationParametersAtServer(Result.ResultAddress, AccountingSection);
	
EndProcedure

&AtServer
Procedure ProcessResultOfFillingInDepreciationCalculationParametersAtServer(Val ResultAddress, Val AccountingSection)
	
	ParametersForCalculation = GetFromTempStorage(ResultAddress);

	Documents.FixedAssetCostAndDepreciationAdjustment.ProcessDepreciationCalculationParameters(Object, ParametersForCalculation, AccountingSection);
	
	ConfigureDependentFormElementsOnServer("FinancialDetailsForThePeriod");
	
EndProcedure

&AtClient
Procedure CalculateDepreciationCompletion(QuestionResult, AccountingSection) Export
	
	If QuestionResult <> DialogReturnCode.Yes
		Or Not Object.AdjustmentModeFromPreviousDate
		Or Object.BeginOfPeriod = '000101010000' Then
			
		Return;
	EndIf;

	TimeConsumingOperation = StartCalculatingDepreciationAccordingToSpecifiedParametersOnServer(AccountingSection);

	CallbackOnCompletion = New CallbackDescription("ProcessDepreciationCalculationResult", ThisObject, AccountingSection);
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion);

EndProcedure

&AtClient
Procedure ProcessDepreciationCalculationResult(Result, AccountingSection) Export
	
	If Result = Undefined Then
		Return;
	EndIf;

	If Result.Status = "Error" Then
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ProcessResultOfDepreciationCalculationAtServer(Result.ResultAddress);
	
EndProcedure

&AtServer
Procedure ProcessResultOfDepreciationCalculationAtServer(Val ResultAddress)
	
	CalculationResult2 = GetFromTempStorage(ResultAddress);

	Documents.FixedAssetCostAndDepreciationAdjustment.ProcessDepreciationCalculationResult(Object, CalculationResult2);
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodACBeforeAddRowCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	RowIndex = 0;

	For Cnt = 0 To Object.FinancialDetailsForThePeriodAC.Count()-1 Do
		
		RowData = Object.FinancialDetailsForThePeriodAC[Cnt];
		
		If RowData.Date = Result Then
			Return;
		EndIf;
		
		If RowData.Date < Result
			And Cnt < Object.FinancialDetailsForThePeriodAC.Count()-1
			And Object.FinancialDetailsForThePeriodAC[Cnt+1].Date > Result Then
			
			RowIndex = Cnt+1;
			Break;
		EndIf;
		
	EndDo;
	
	AddParameters(Object.FinancialDetailsForThePeriodAC, RowIndex, Result);
	
EndProcedure

&AtClient
Procedure FinancialDetailsForThePeriodBeforeAddRowCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	RowIndex = 0;

	For Cnt = 0 To Object.FinancialDetailsForThePeriod.Count()-1 Do
		
		RowData = Object.FinancialDetailsForThePeriod[Cnt];
		
		If RowData.Date = Result Then
			Return;
		EndIf;
		
		If RowData.Date < Result
			And Cnt < Object.FinancialDetailsForThePeriod.Count()-1
			And Object.FinancialDetailsForThePeriod[Cnt+1].Date > Result Then
			
			RowIndex = Cnt+1;
			Break;
		EndIf;
		
	EndDo;
	
	AddParameters(Object.FinancialDetailsForThePeriod, RowIndex, Result);
	
EndProcedure

&AtClient
Procedure AddParameters(Val Table, Val RowIndex, Val DateOfParameters)

	RowData = Table.Insert(RowIndex);	
	RowData.Date = DateOfParameters;
	RowData.CanDelete = True;

EndProcedure

&AtClientAtServerNoContext
Function MaximumStartOfPeriod(Val Date)

	Return BegOfMonth(AddMonth(Date, -1));
	
EndFunction

&AtClient
Procedure CopyValuesOfCompletionParameters(Result, TableName) Export
	
	If TableName = "FinancialDetailsForThePeriodAC" Then
		CurrentData = Items.FinancialDetailsForThePeriodAC.CurrentData;
		FinancialDetailsForThePeriod = Object.FinancialDetailsForThePeriodAC;
		NotFieldsToFillIn = "Date,DepreciationInAccounting,DepreciationPermanentDifferences,FixedAssetDepreciationTargetFinancing";
	Else
		CurrentData = Items.FinancialDetailsForThePeriod.CurrentData;
		FinancialDetailsForThePeriod = Object.FinancialDetailsForThePeriod;
		NotFieldsToFillIn = "Date,Depreciation,DepreciationLocal";
	EndIf;
	
	If Result = Undefined Or CurrentData = Undefined Then
		Return;
	EndIf;
	
	For Each RowData In FinancialDetailsForThePeriod Do
		If Result.Find(RowData.Date) <> Undefined Then
			FillPropertyValues(RowData, CurrentData,, NotFieldsToFillIn);
		EndIf;
	EndDo;
	
	ConfigureDependentFormElements("FinancialDetailsForThePeriod");
	
EndProcedure

&AtServer
Function StartCalculatingDepreciationAccordingToSpecifiedParametersOnServer(Val AccountingSection = Undefined)
	
	FixedAsset = NonCurrentAssetsInternal.FirstFilledValueInTable(
		Object.FA, "FixedAsset", Catalogs.Assets.EmptyRef());

	CalculationParameters = New Structure;
	CalculationParameters.Insert("Organization", Object.Organization);
	CalculationParameters.Insert("FixedAsset", FixedAsset);
	CalculationParameters.Insert("CommissioningDateMA", Object.CommissioningDateMA);
	CalculationParameters.Insert("CommissioningDateAC", Object.CommissioningDateAC);
	CalculationParameters.Insert("CommissioningDateTA", Object.CommissioningDateTA);
	CalculationParameters.Insert("CostAtBeginningOfYear", Object.CostAtBeginningOfYear);
	CalculationParameters.Insert("LocalCostAtBeginningOfYear", Object.LocalCostAtBeginningOfYear);
	CalculationParameters.Insert("DepreciationAsOfTheYearStart", Object.DepreciationAsOfTheYearStart);
	CalculationParameters.Insert("LocalDepreciationAsOfTheYearStart", Object.LocalDepreciationAsOfTheYearStart);
	CalculationParameters.Insert("DepreciationAsOfThePeriodStart", Object.DepreciationAsOfThePeriodStart);
	CalculationParameters.Insert("LocalDepreciationAtBeginningOfPeriod", Object.LocalDepreciationAtBeginningOfPeriod);
	CalculationParameters.Insert("DepreciationInTaxAccountingBeginOfPeriod", Object.DepreciationInTaxAccountingBeginOfPeriod);
	CalculationParameters.Insert("PermanentDifferencesInDepreciation", Object.PermanentDifferencesInDepreciation);
	CalculationParameters.Insert("TargetFundsInDepreciation", Object.TargetFundsInDepreciation);
	CalculationParameters.Insert("PermanentDifferencesOfTargetFundsInDepreciation", Object.PermanentDifferencesOfTargetFundsInDepreciation);
	CalculationParameters.Insert("DepreciationBefore2009", Object.DepreciationBefore2009);
	CalculationParameters.Insert("ActualUsefulLifeBefore2009", Object.ActualUsefulLifeBefore2009);
	CalculationParameters.Insert("TheseAreRentedFA", FormServiceParameters.TheseAreRentedFA);

	If AccountingSection <> Undefined Then
		
		ListOfAccountingSections = StrSplit(AccountingSection, ",");
	
	Else
		
		ListOfAccountingSections = New Array;
		ListOfAccountingSections.Add("MA");
		
		If FormServiceParameters.ReglVNAAccountingIsConductedIndependently_ForPeriod Then
			ListOfAccountingSections.Add("ACC");
		EndIf;
		
		
	EndIf;
	
	CalculationTables = New Structure;
	
	If ListOfAccountingSections.Find("MA") <> Undefined Then
		CalculationTables.Insert("ParametersForMAPeriod", Object.FinancialDetailsForThePeriod.Unload());
	EndIf;
	
	If ListOfAccountingSections.Find("ACC") <> Undefined Then
		CalculationTables.Insert("FinancialDetailsForThePeriodAC", Object.FinancialDetailsForThePeriodAC.Unload());
	EndIf;
	
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "Documents.FixedAssetsDepreciationCharge2_4.CalculateDepreciationAccordingToTable", CalculationTables, CalculationParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

#EndRegion

#Region Localization

&AtClient
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export
	
	Var ActionParameters;

	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf;
	
EndProcedure

#EndRegion

#Region AttachableCommands

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export

	Var ActionParameters;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf; 
	
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	FillInServiceDetailsOfTS();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	
	CurrentParameters = "AsOfThePeriodStart";
	
	InitializeServiceParametersOfForm();
	
EndProcedure

&AtServer
Procedure FillInServiceDetailsOfTS()

	For Each RowData In Object.FinancialDetailsForThePeriod Do
		RowData.CanDelete = (EndOfDay(RowData.Date) <> EndOfMonth(RowData.Date));
	EndDo;
	
	For Each RowData In Object.FinancialDetailsForThePeriodAC Do
		RowData.CanDelete = (EndOfDay(RowData.Date) <> EndOfMonth(RowData.Date));
	EndDo;
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	InternalParameters = New Structure;
	
	InternalParameters.Insert("CurrencyOfMan", CurrencyOfMan);
	InternalParameters.Insert("ComplCurrency", ComplCurrency);
	InternalParameters.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	InternalParameters.Insert("ComplCurrencyPresentation", String(ComplCurrency));
	InternalParameters.Insert("CurrenciesDoNotMatch", InternalParameters.CurrencyOfMan = InternalParameters.ComplCurrency);
	InternalParameters.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	InternalParameters.Insert("IncomeTaxPayer", False);
	InternalParameters.Insert("CalculationOfPermanentAndTemporaryDifferencesIsKept", False);
	InternalParameters.Insert("ThisIsInternationalVersion", Not GetFunctionalOption("LocalizationRFService"));

	InternalParameters.Insert("UseFixedAssetAccountingByActivities", 
		GetFunctionalOption("UseFixedAssetAccountingByActivities"));
	
	FormServiceParameters = New FixedStructure(InternalParameters);
	
EndProcedure

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		FillInHeaderForSelectedFA();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheAccountingFormCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccountInformationOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInDepreciationBasedOnAccountingParametersCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	DepreciationManagementAccounting = Object.FinancialDetailsForThePeriod.Total("Depreciation");
	DepreciationInAccounting = Object.FinancialDetailsForThePeriod.Total("DepreciationLocal");
	DepreciationInAccounting = Object.FinancialDetailsForThePeriodAC.Total("DepreciationInAccounting");
	DepreciationPermanentDifferences = Object.FinancialDetailsForThePeriodAC.Total("DepreciationPermanentDifferences");
	FixedAssetDepreciationTargetFinancing = Object.FinancialDetailsForThePeriodAC.Total("FixedAssetDepreciationTargetFinancing");
	DepreciationInTaxAccounting = Object.FinancialDetailsForThePeriodTA.Total("DepreciationInTaxAccounting");
	DepreciationMAChange = Object.FinancialDetailsForThePeriod.Total("DepreciationUpdate");
	DepreciationACChange = Object.FinancialDetailsForThePeriod.Total("DepreciationLocalUpdate");
	DepreciationACChange = Object.FinancialDetailsForThePeriodAC.Total("DepreciationLocalUpdate");
	DepreciationPDChange = Object.FinancialDetailsForThePeriodAC.Total("DepreciationPermanentDifferencesUpdate");
	DepreciationTFChange = Object.FinancialDetailsForThePeriodAC.Total("FixedAssetDepreciationTargetFinancingUpdate");
	DepreciationChangeTA = Object.FinancialDetailsForThePeriodTA.Total("DepreciationInTaxAccountingUpdate");
	
	For Each Item In Items.FA.SelectedRows Do
		
		RowData = Items.FA.RowData(Item);
		
		If Object.RecordInManAccounting Then
			RowData.DepreciationManagementAccounting = Object.DepreciationAsOfThePeriodStart + DepreciationManagementAccounting + DepreciationMAChange;
		EndIf;

		If Object.PostInAccounting Then
			RowData.DepreciationInAccounting = Object.LocalDepreciationAtBeginningOfPeriod + DepreciationInAccounting + DepreciationACChange;
			RowData.FixedAssetDepreciationTargetFinancing = Object.TargetFundsInDepreciation + FixedAssetDepreciationTargetFinancing + DepreciationTFChange;
			RowData.DepreciationPermanentDifferences = Object.PermanentDifferencesInDepreciation + DepreciationPermanentDifferences + DepreciationPDChange;
		EndIf;
		
		If Object.RecordInTA Then
			RowData.DepreciationInTaxAccounting = Object.DepreciationInTaxAccountingBeginOfPeriod + DepreciationInTaxAccounting + DepreciationChangeTA;
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure FillInAccountInformationOnServer()

	StringsList = New Array;
	
	For Each RowID In Items.FA.SelectedRows Do
		RowData = Object.FA.FindByID(RowID);
		StringsList.Add(RowData);
	EndDo; 
	
	FillInAccordingToAccountingDataOnServer(StringsList);

EndProcedure
 
&AtServer
Procedure FillInAccordingToAccountingDataOnServer(StringsList)

	Documents.FixedAssetCostAndDepreciationAdjustment.FillInByAccountingData(Object, StringsList);

EndProcedure

&AtClientAtServerNoContext
Function FillInDetailsDependingOnProperties(Form, ItemDetailsParameters)

	Object = Form.Object;
	Items = Form.Items;
	
	ChangedBankingDetails = New Array;
	
	For Each AttributeParameters In ItemDetailsParameters Do
		
		If Not ValueIsFilled(AttributeParameters.AttributeName)
			Or StrSplit(AttributeParameters.AttributeName, ".").UBound() <> 0 Then
			Continue;
		EndIf;
		
		Action = NonCurrentAssetsClientServer.ClearOrFill(Object, AttributeParameters);
		
		If Not ValueIsFilled(Action) Then
			Continue;
		EndIf;
		
		If AttributeParameters.AttributeName = "AssetExpenseItemCostReduction" Then
			
			If Action = "Fill" And Object.AssetExpenseItemCostReduction = Undefined Then
				Object.AssetExpenseItemCostReduction = PredefinedValue("ChartOfCharacteristicTypes.ExpenseItems.EmptyRef");
			EndIf; 
			
			IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.AssetExpenseItemCostReduction);
			
		ElsIf AttributeParameters.AttributeName = "IncomeLiabilityItemCostIncrease" Then
			
			If Action = "Fill" And Object.IncomeLiabilityItemCostIncrease = Undefined Then
				Object.IncomeLiabilityItemCostIncrease = PredefinedValue("ChartOfCharacteristicTypes.IncomeItems.EmptyRef");
			EndIf; 
			
			IncomeAndExpensesClientServer.AssetRefOnChange(Form, Items.IncomeLiabilityItemCostIncrease);
			
		EndIf;
		
		FixedAssetCostAndDepreciationAdjustmentClientServerLocalization.FillInDetailsDependingOnProperties(
			Object, AttributeParameters, Action, ChangedBankingDetails);
		
	EndDo; 
	
	Return StrConcat(ChangedBankingDetails, ",");
	
EndFunction

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";
	
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	FixedAssetCostAndDepreciationAdjustmentLocalization.SetConditionalAppearance(ThisObject);

	#Region FinancialDetailsForThePeriodDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialDetailsForThePeriodDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FinancialDetailsForThePeriod.CanDelete");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
		
	#Region FinancialDetailsForThePeriodACDate
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.FinancialDetailsForThePeriodACDate.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.FinancialDetailsForThePeriodAC.CanDelete");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	#EndRegion
		
EndProcedure

&AtClient
Procedure AdjustAdjustmentParametersCompletion(Result, AdditionalParameters) Export
	
	If Result = Undefined Or ReadOnly Then
		Return;
	EndIf;
	
	Modified = True;
	
	FillPropertyValues(Object, Result);
	
	If Object.PeriodAdjustment <> 0 And Object.Date <> EndOfYear(Object.Date) Then
		 Object.Date = EndOfYear(Object.Date);
	EndIf;

	ParametersNeedToBeUpdated = 
		Object.IncludesDepreciationOfCurrentMonth <> Result.IncludesDepreciationOfCurrentMonth
		And Object.AdjustmentModeFromPreviousDate;
	
	ConfigureAdjustmentParametersEndOnServer();

	If ParametersNeedToBeUpdated Then
		StartFillingInDepreciationCalculationParameters();
	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureAdjustmentParametersEndOnServer()

	ChangedBankingDetails = AdjustmentParameters();
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetCostAndDepreciationAdjustment.ItemsAndDimensionsSelectionParameters(Object);
	IncomeAndExpensesServer.WhenChangingArticleSelectionParameters(ThisObject, ItemsAndDimensionsSelectionParameters);

EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(SelectedElement, AdditionalParameters) Export

	If SelectedElement = Undefined Then
		Object.GeneratedDocument = False;
		Return;
	EndIf;
	
	ChoiceFormName = Undefined;
	
	If SelectedElement.Value = Type("DocumentRef.ChangeFixedAssetFinancialDetails2_4") Then
		ChoiceFormName = "Document.ChangeFixedAssetFinancialDetails2_4.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.FixedAssetsCostAdditions2_4") Then
		ChoiceFormName = "Document.FixedAssetsCostAdditions2_4.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.MergeOfFixedAssets") Then
		ChoiceFormName = "Document.MergeOfFixedAssets.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.FARevaluation2_4") Then
		ChoiceFormName = "Document.FARevaluation2_4.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.ReceiveLeasedAssets") Then
		ChoiceFormName = "Document.ReceiveLeasedAssets.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.FixedAssetsInitialRecognition2_4") Then
		ChoiceFormName = "Document.FixedAssetsInitialRecognition2_4.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.SplitFixedAssets") Then
		ChoiceFormName = "Document.SplitFixedAssets.ChoiceForm";
	ElsIf SelectedElement.Value = Type("DocumentRef.AllocateVariancesToFixedAssetCost") Then
		ChoiceFormName = "Document.AllocateVariancesToFixedAssetCost.ChoiceForm";
	EndIf;
	
	If ChoiceFormName = Undefined Then
		Return;
	EndIf;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Organization", Object.Organization);

	FormParameters = New Structure;
	FormParameters.Insert("Filter", FilterParameters);
	
	CallbackDescription = New CallbackDescription("SelectingFoundationDocumentCompletion", ThisObject);
	OpenForm(ChoiceFormName, FormParameters,,,,, CallbackDescription, FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure SelectingFoundationDocumentCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
		Object.DocumentBasis = Undefined;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền dựa trên chứng từ được chọn?';
						|ru = 'Заполнить на основании выбранного документа?';
						|en = 'Fill in based on the selected document?'; fa = 'Fill in based on the selected document?';
						|it = 'Fill in based on the selected document?';
						|pl = 'Fill in based on the selected document?';
						|tr = 'Seçilen belgeye göre doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		FillInAccordingToBaseDataOnServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInAccordingToBaseDataOnServer()
	
	Documents.FixedAssetCostAndDepreciationAdjustment.FillInBasedOnDocument(Object, Object.DocumentBasis);
	
EndProcedure

&AtClientAtServerNoContext
Function AdjustmentParameters()
	
	AdjustmentParameters = 
	"CostAdjustment,AdjustmentOfInitialCost,
	|DepreciationAdjustment,IncludesDepreciationOfCurrentMonth,AdjustmentOfDepreciationCalculationParameters,
	|BonusDepreciationAdjustment,AdjustTAExpenseAmountOfInvestmentTaxDeduction,DepreciationAdjustmentForPeriod,
	|CostIncreaseRecording,CostDecreaseRecording,RecordCostDecreaseByReversal,RecordCostChangeInTADueToPD,
	|DepreciationIncreaseRecording,DepreciationDecreaseRecording,RecordThisYearDepreciationDecreaseAsStorno,SeparateAdjustmentOfCurrentAndPreviousPeriods,
	|BonusDepreciationIncreaseRecording,BonusDepreciationDecreaseRecording,RecordingOfBonusDepreciationDecreaseStorno,
	|PeriodAdjustment,ApplicationOfTargetFinancing";
	
	Return AdjustmentParameters;
	
EndFunction

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
	If Item.Name = "sh_ShamsiInput_Date" Then
		DateOnChange(Items.Date);
	ElsIf Item.Name = "sh_ShamsiInput_BeginOfPeriod" Then
		BeginOfPeriodOnChange(Items.BeginOfPeriod);
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
