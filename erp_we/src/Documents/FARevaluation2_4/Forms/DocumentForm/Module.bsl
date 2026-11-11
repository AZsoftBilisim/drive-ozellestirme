
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	If Not ValueIsFilled(Object.Ref) Then
		
		OnReadCreateAtServer();
		
	EndIf;
	
	ItemsAndDimensionsSelectionParameters = Documents.FARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);

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
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)

	// StandardSubsystems.AccessManagement
	AccessManagement.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.AccessManagement
	
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
	ItemsAndDimensionsSelectionParameters = Documents.FARevaluation2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_FARevaluation2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	If ValueIsFilled(Object.DocumentBasis)
		And TypeOf(Object.DocumentBasis) = Type("DocumentRef.FixedAssetsPhysicalCount") Then
		Notify("RecordDocumentBasedOnInventory",, Object.Ref);
	EndIf;

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
	
	FillInInformationAboutDocumentInAnotherAccount();
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure BeforeWrite(Cancel, WriteParameters)
	
	FormEventsClient.BeforeWrite(ThisObject, Cancel, WriteParameters);

EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(
		ThisObject,
		CurrentObject,
		WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_FARevaluation2_4" 
		And Source <> Object.Ref Then
		FillInInformationAboutDocumentInAnotherAccount();
	EndIf;
	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure RecordInLocalAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInLocalAccounting = True;
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInLocalAccounting");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RecordInManAccounting");

EndProcedure

&AtClient
Procedure MethodOfRevaluationOnChange(Item)

	Object.RevaluateAtFairValue = (MethodOfRevaluation = 1);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "RevaluateAtFairValue");
	
EndProcedure

&AtClient
Procedure ExpensesPostingMethodOnChange(Item)
	
	ChangedBankingDetails = "ExpensesPostingMethod,ExpenseItem,BusinessUnitAndLineOfBusinessMatchAccountingData,DimensionCorrespondsToFAToWriteOff";
	
	NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
		Object.ExpensesPostingMethod, 
		Object.ExpenseItem, 
		Object.DimensionOfExpenses, 
		Object.ExpensesBusinessUnit, 
		Object.ExpenseLineOfBusiness, 
		Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);

	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtClient
Procedure ExpenseItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod,ExpenseItem");
	
EndProcedure

&AtClient
Procedure ExpenseItemStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, "ExpensesPostingMethod");
	EndIf;
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure DimensionOfExpensesTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpensesBusinessUnitOnChange(Item)

	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,ExpensesBusinessUnit");
	
EndProcedure

&AtClient
Procedure ExpenseLineOfBusinessOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,ExpenseLineOfBusiness");
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	If ValueIsFilled(Object.ExpensesPostingMethod) Then
		Object.ExpensesPostingMethod = PredefinedValue("Catalog.WaysToReflectExpenses.EmptyRef");
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject,"ExpensesPostingMethod,BusinessUnitAndLineOfBusinessMatchAccountingData");

EndProcedure

&AtClient
Procedure IncomeItemOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Item);
	
EndProcedure

&AtClient
Procedure IncomeBusinessUnitAndLineOfBusinessMatchAccountingDataOnChange(Item)
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, Item.Name);

EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.FARevaluation2_4.ObjectForm", FormParameters);
	EndIf;
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChange(Item)
	
	If Object.GeneratedDocument Then
		
		ListFilter = New Structure;
		ListFilter.Insert("Posted", True);
		If ValueIsFilled(Object.Organization) Then
			ListFilter.Insert("Organization", Object.Organization);
		EndIf;
		
		FormParameters = New Structure;
		FormParameters.Insert("Filter", ListFilter);
		
		CallbackDescription = New CallbackDescription("GeneratedDocumentOnChangeCompletion", ThisObject);
		OpenForm("Document.FixedAssetsPhysicalCount.ChoiceForm", FormParameters,,,,, CallbackDescription);
		
	Else
		Object.DocumentBasis = Undefined;
	EndIf; 
	
EndProcedure

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

#Region FormTableItemsEventHandlersFA

&AtClient
Procedure FAChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	If NonCurrentAssetsClientServer.ProcessingElementSelection(Object.FA, "FixedAsset", ValueSelected).Count() <> 0 Then
		WhenChangingFAOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	
	WhenChangingFAOnServer();

EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pickup(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);

	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, 
					Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
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
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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

&AtServer
Procedure OnReadCreateAtServer()
	
	InitializingFormWhenCreatingItOnServer();
	
	FillInInformationAboutDocumentInAnotherAccount();
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Val Form, Val ChangedBankingDetails = "")

	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", FormServiceParameters.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps_RevaluationOfFA(
										Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If Not UpdateAll Then
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA");
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or UpdateAll Then
		
		Items.MethodOfRevaluation.Visible = 
			Object.RecordInManAccounting
				And FormServiceParameters.AccountingSettings.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards")
				And FormServiceParameters.AccountingSettings.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod")
			Or Object.RecordInLocalAccounting
				And FormServiceParameters.AccountingSettings.FSB6IsApplied
				And FormServiceParameters.AccountingSettings.MethodOfRevaluationOfFALocal = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod");
				
		If Object.RecordInManAccounting
			And Object.RecordInLocalAccounting
			And FormServiceParameters.ComplianceCAAccountingIsKept
			And FormServiceParameters.AccountingSettings.AccountingPolicyForFixedAssets = PredefinedValue("Enum.AccountingPolicyForFixedAssets.ByFinancialAccountingStandards")
			And FormServiceParameters.AccountingSettings.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod")
			And (Not FormServiceParameters.AccountingSettings.FSB6IsApplied
				Or FormServiceParameters.AccountingSettings.MethodOfRevaluationOfFALocal = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod")) Then
			
			Items.MethodOfRevaluation.Title = NStr("vi = 'Phương thức đánh giá lại (quản trị)';
													|ru = 'Способ переоценки (упр)';
													|en = 'Revaluation method (mgmt)'; fa = 'Revaluation method (mgmt)';
													|it = 'Способ переоценки (упр)';
													|pl = 'Revaluation method (mgmt)';
													|tr = 'Способ переоценки (упр)'");
			
		ElsIf Object.RecordInManAccounting
			And FormServiceParameters.ComplianceCAAccountingIsKept
			And FormServiceParameters.AccountingSettings.FSB6IsApplied
			And FormServiceParameters.AccountingSettings.MethodOfRevaluationOfFALocal = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.ProportionalRecalculationMethod")
			And (Not FormServiceParameters.AccountingSettings.FSB6IsApplied
				Or FormServiceParameters.AccountingSettings.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod")) Then
			
			Items.MethodOfRevaluation.Title = NStr("vi = 'Phương thức đánh giá lại (tài chính)';
													|ru = 'Способ переоценки (регл)';
													|en = 'Revaluation method (local)'; fa = 'Revaluation method (local)';
													|it = 'Способ переоценки (регл)';
													|pl = 'Revaluation method (local)';
													|tr = 'Способ переоценки (регл)'");
			
		Else
			Items.MethodOfRevaluation.Title = NStr("vi = 'Phương thức đánh giá lại';
													|ru = 'Способ переоценки';
													|en = 'Revaluation method'; fa = 'روش تجدید ارزیابی';
													|it = 'Способ переоценки';
													|pl = 'Revaluation method';
													|tr = 'Способ переоценки'");
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("ExpensesPostingMethod") 
		Or UpdateAll Then
			
		NonCurrentAssetsClientServer.CustomizeItemsAccordingToWayExpensesAreReflected(
			Object.ExpensesPostingMethod,
			Form, 
			"ExpenseItem,DimensionOfExpenses,ExpensesBusinessUnit,ExpenseLineOfBusiness,BusinessUnitAndLineOfBusinessMatchAccountingData");
	
	EndIf;
	
	If StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("RevaluateAtFairValue")
		Or UpdateAll Then
		
		If Object.RevaluateAtFairValue
			Or FormServiceParameters.AccountingSettings.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod") Then
			
			Items.FACostInManagementAccounting.Title = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Giá trị hợp lý';
					|ru = 'Справедливая стоимость';
					|en = 'Fair value'; fa = 'ارزش منصفانه';
					|it = 'Справедливая стоимость';
					|pl = 'Fair value';
					|tr = 'Adil değer'"), 
				NStr("vi = 'Giá trị hợp lý (KTQT)';
					|ru = 'Справедливая стоимость (УУ)';
					|en = 'Fair value (MA)'; fa = 'Fair value (MA)';
					|it = 'Fair value (MA)';
					|pl = 'Fair value (MA)';
					|tr = 'Gerçeğe uygun değer (Yönetim Muhasebesi)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.CurrencyOfManPresentation);
				
		Else
			
			Items.FACostInManagementAccounting.Title = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Giá trị phục hồi';
					|ru = 'Восстановительная стоимость';
					|en = 'Replacement cost'; fa = 'بهای جایگزینی';
					|it = 'Costo di sostituzione';
					|pl = 'Koszt odtworzenia';
					|tr = 'Yenileme değeri'"), 
				NStr("vi = 'Giá trị phục hồi (KTQT)';
					|ru = 'Восстановительная стоимость (УУ)';
					|en = 'Replacement cost (MA)'; fa = 'Replacement cost (MA)';
					|it = 'Replacement cost (MA)';
					|pl = 'Replacement cost (MA)';
					|tr = 'Yenileme maliyeti (Yönetim Muhasebesi)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.CurrencyOfManPresentation);
				
		EndIf;
		
		If Object.RevaluateAtFairValue
			Or FormServiceParameters.AccountingSettings.MethodOfRevaluationOfFALocal = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod") Then
			
			Items.FACostInAccounting.Title = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Giá trị hợp lý';
					|ru = 'Справедливая стоимость';
					|en = 'Fair value'; fa = 'ارزش منصفانه';
					|it = 'Справедливая стоимость';
					|pl = 'Fair value';
					|tr = 'Adil değer'"), 
				NStr("vi = 'Giá trị hợp lý (KTDN)';
					|ru = 'Справедливая стоимость (БУ)';
					|en = 'Fair value (LA)'; fa = 'Fair value (LA)';
					|it = 'Fair value (LA)';
					|pl = 'Fair value (LA)';
					|tr = 'Gerçeğe uygun değer (Genel Muhasebe)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.ComplCurrencyPresentation);
				
		Else
			
			Items.FACostInAccounting.Title = NonCurrentAssetsClientServer.PresentationOfCurrencyField(
				NStr("vi = 'Giá trị phục hồi';
					|ru = 'Восстановительная стоимость';
					|en = 'Replacement cost'; fa = 'بهای جایگزینی';
					|it = 'Costo di sostituzione';
					|pl = 'Koszt odtworzenia';
					|tr = 'Yenileme değeri'"), 
				NStr("vi = 'Giá trị phục hồi (KTDN)';
					|ru = 'Восстановительная стоимость (БУ)';
					|en = 'Replacement cost (LA)'; fa = 'Replacement cost (LA)';
					|it = 'Replacement cost (LA)';
					|pl = 'Replacement cost (LA)';
					|tr = 'Yenileme maliyeti (Genel Muhasebe)'"), 
				FormServiceParameters.FALocalAccountingIsConductedIndependently, 
				FormServiceParameters.CurrenciesDoNotMatch,
				FormServiceParameters.ComplCurrencyPresentation);
				
		EndIf;
			
		If Object.RevaluateAtFairValue
			Or FormServiceParameters.AccountingSettings.FixedAssetRevaluationMethod = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod") Then
			
			Items.FACostInManagementAccounting.ToolTip = NStr("vi = 'Giá trị hợp lý theo tiền tệ của kế toán quản trị';
																|ru = 'Справедливая стоимость в валюте упр. учета';
																|en = 'Fair value in the management accounting currency'; fa = 'Fair value in the management accounting currency';
																|it = 'Справедливая стоимость в валюте упр. учета';
																|pl = 'Fair value in the management accounting currency';
																|tr = 'Справедливая стоимость в валюте упр. учета'");
				
		Else
			
			Items.FACostInManagementAccounting.ToolTip = NStr("vi = 'Giá trị thị trường hiện tại (khôi phục) bằng tiền tệ của kế toán quản trị';
																|ru = 'Текущая рыночная (восстановительная) стоимость в валюте упр. учета';
																|en = 'Current market (replacement) value in the management accounting currency'; fa = 'Current market (replacement) value in the management accounting currency';
																|it = 'Текущая рыночная (восстановительная) стоимость в валюте упр. учета';
																|pl = 'Current market (replacement) value in the management accounting currency';
																|tr = 'Текущая рыночная (восстановительная) стоимость в валюте упр. учета'");
			
		EndIf;

		If Object.RevaluateAtFairValue
			Or FormServiceParameters.AccountingSettings.MethodOfRevaluationOfFALocal = PredefinedValue("Enum.FixedAndIntangibleAssetRevaluationMethods.CashMethod") Then
			
			Items.FACostInAccounting.ToolTip = NStr("vi = 'Giá trị hợp lý theo tiền tệ của kế toán tài chính';
													|ru = 'Справедливая стоимость в валюте регл. учета';
													|en = 'Fair value in the local accounting currency'; fa = 'Fair value in the local accounting currency';
													|it = 'Справедливая стоимость в валюте регл. учета';
													|pl = 'Fair value in the local accounting currency';
													|tr = 'Справедливая стоимость в валюте регл. учета'");
				
		Else
			
			Items.FACostInAccounting.ToolTip = NStr("vi = 'Giá trị thị trường hiện tại (khôi phục) bằng tiền tệ của kế toán tài chính';
													|ru = 'Текущая рыночная (восстановительная) стоимость в валюте регл. учета';
													|en = 'Current market (replacement) value in the local accounting currency'; fa = 'Current market (replacement) value in the local accounting currency';
													|it = 'Текущая рыночная (восстановительная) стоимость в валюте регл. учета';
													|pl = 'Current market (replacement) value in the local accounting currency';
													|tr = 'Текущая рыночная (восстановительная) стоимость в валюте регл. учета'");
			
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("RevaluateAtFairValue")
		Or UpdateAll Then
			
		Form.MethodOfRevaluation = ?(Object.RevaluateAtFairValue, 1, 0);

	EndIf;
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")
	
	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	If StructureOfChangedProps.Property("Organization") 
		Or StructureOfChangedProps.Property("Date")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);

		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplCurrencyPresentation",
			String(ComplCurrency),
			FormServiceParameters);

		NonCurrentAssetsInternal.SetStructureProperty(
			"CurrenciesDoNotMatch",
			FormServiceParameters.CurrencyOfMan = ComplCurrency,
			FormServiceParameters);
			
	EndIf;
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure FillInInformationAboutDocumentInAnotherAccount()

	NonCurrentAssetsInternal.FillInInformationAboutDocumentInAnotherAccount(Object, Items);

EndProcedure

&AtServer
Procedure WhenChangingFAOnServer()
	
	FillInHeaderForSelectedFA();
	
EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "FixedAsset";

	NonCurrentAssetsInternal.FillInHeaderForSelectedFA("Organization,Department", Object.FA, Object, ChangedBankingDetails);
	
	If Not ValueIsFilled(Object.ExpensesPostingMethod) Then
		
		Object.ExpensesPostingMethod = NonCurrentAssetsInternal.WayToReflectFAExpenses(
			Object,
			NonCurrentAssetsInternal.FirstFilledValueInTable(Object.FA, "FixedAsset"));
		
		If ValueIsFilled(Object.ExpensesPostingMethod) Then
			
			NonCurrentAssetsClientServer.FillInAccordingToMethodOfReflectingExpenses(
				Object.ExpensesPostingMethod, 
				Object.ExpenseItem, 
				Object.DimensionOfExpenses, 
				Object.ExpensesBusinessUnit, 
				Object.ExpenseLineOfBusiness, 
				Object.BusinessUnitAndLineOfBusinessMatchAccountingData);
				
			IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItem);
			
			ChangedBankingDetails = ChangedBankingDetails + "," + "ExpensesPostingMethod,BusinessUnitAndLineOfBusinessMatchAccountingData";
			
		EndIf;
		
	EndIf;
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure InitializeServiceParametersOfForm()

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	
	NewServiceParametersOfForm = New Structure;
	NewServiceParametersOfForm.Insert("CurrencyOfMan", CurrencyOfMan);
	NewServiceParametersOfForm.Insert("CurrencyOfManPresentation", String(CurrencyOfMan));
	NewServiceParametersOfForm.Insert("ComplianceCAAccountingIsKept", NonCurrentAssetsInternal.ComplianceCAAccountingIsKept());
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);

	GetAccountingSettings();
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()
	
	ChangedBankingDetails = "Date";
	
	GetAccountingSettings();
	AfterChangingAccountingSettings(ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServer
Procedure OrganizationWhenChangedOnServer()
	
	ChangedBankingDetails = "Organization";

	GetAccountingSettings();
	AfterChangingAccountingSettings(ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);

EndProcedure

&AtServer
Procedure AfterChangingAccountingSettings(ChangedBankingDetails)
	
	If Not FormServiceParameters.AccountingSettings.FSB6IsApplied
		And Object.RevaluateAtFairValue Then
		
		Object.RevaluateAtFairValue = False;
		ChangedBankingDetails = ChangedBankingDetails + "," + "RevaluateAtFairValue";
	EndIf;
	
EndProcedure

&AtServer
Procedure GetAccountingSettings()

	DateOfSettings = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));

	NonCurrentAssetsInternal.SetStructureProperty(
		"FALocalAccountingIsConductedIndependently",
		AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfSettings),
		FormServiceParameters);
	
	NonCurrentAssetsInternal.SetStructureProperty(
		"AccountingSettings",
		AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Object.Organization, DateOfSettings),
		FormServiceParameters);
	
EndProcedure

&AtClient
Procedure GeneratedDocumentOnChangeCompletion(ClosingResult, AdditionalParameters) Export

	If ValueIsFilled(ClosingResult) Then
		Object.DocumentBasis = ClosingResult;
	Else
		Object.GeneratedDocument = False;
	EndIf;
	
	If ValueIsFilled(Object.DocumentBasis) Then
		QueryText = NStr("vi = 'Điền chứng từ theo kiểm kê?';
						|ru = 'Заполнить документ по инвентаризации?';
						|en = 'Fill in the physical inventory count document?'; fa = 'Fill in the physical inventory count document?';
						|it = 'Fill in the physical inventory count document?';
						|pl = 'Fill in the physical inventory count document?';
						|tr = 'Belge stok sayımına göre doldurulsun mu?'");
		CallbackDescription = New CallbackDescription("FillInAccordingToBaseEnd", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo); 
	EndIf; 
	
EndProcedure

&AtClient
Procedure FillInAccordingToBaseEnd(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		DocumentBasedOnChangeAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure DocumentBasedOnChangeAtServer()
	
	Object.FA.Clear();
	
	Documents.FARevaluation2_4.FillInBasedOnInventory(Object, True);
	
	ConfigureDependentFormElementsOnServer("GeneratedDocument,RevaluateAtFairValue,RecordInManAccounting,RecordInLocalAccounting");
	
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
