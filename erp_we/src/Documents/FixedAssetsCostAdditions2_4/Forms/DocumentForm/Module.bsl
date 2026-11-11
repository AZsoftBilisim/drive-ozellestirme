
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
	
	#Region StandardSubsystems
	
	// StandardSubsystems.ObjectsVersioning
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.ObjectsVersioning
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	
	Items.DecorationEDOState.Visible = GetFunctionalOption("UseElectronicDocumentExchangeWithCounterparties");
	
	// StandardSubsystems.FilesOperations
	FilesHyperlink = FilesOperations.FilesHyperlink();
	FilesHyperlink.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, FilesHyperlink);
	// End StandardSubsystems.FilesOperations
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	#EndRegion
	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsCostAdditions2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnCreateAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FixedAssetsCostAdditionsLocalization.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
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
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();

	FormEvents.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands

	
	ItemsAndDimensionsSelectionParameters = Documents.FixedAssetsCostAdditions2_4.ItemsAndDimensionsSelectionParameters();
	IncomeAndExpensesServer.OnReadAtServer(ThisObject, ItemsAndDimensionsSelectionParameters);
	
	FixedAssetsCostAdditionsLocalization.OnReadAtServer(ThisObject, CurrentObject);
	
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
Procedure AfterWrite(WriteParameters)

	Notify("Write_FixedAssetsCostAdditions2_4", WriteParameters, Object.Ref);
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);

	TMCommonUseClient.PerformActionsAfterRecording(ThisObject, Object, WriteParameters);
	
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
	

	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
	FillInInformationInBasement();
	
	IncomeAndExpensesServer.AfterWriteAtServer(ThisObject);

	ConfigureDependentFormElementsOnServer("Ref");
	
	FixedAssetsCostAdditionsLocalization.AfterWriteAtServer(ThisObject);
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "Write_FixedAssetsCostAdditions2_4"
		Or EventName = "Write_ChangeFixedAssetFinancialDetails2_4" Then
		FillInInformationInBasement();
	EndIf;
	

	FormEventsClient.NotificationProcessing(ThisObject, EventName, Parameter, Source);
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure BusinessOperationOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure OrganizationOnChange(Item)
	
	OrganizationWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DepartmentOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	NonCurrentAssetsClient.SetCurrentTimeForLastDate(Object.Date);
	
	DateOfChangeOnServer();
	
EndProcedure

&AtClient
Procedure AdjustmentModeFromPreviousDateOnChange(Item)
	
	If Not ValueIsFilled(Object.DepreciationAdjustmentOption)
		And Object.AdjustmentModeFromPreviousDate Then
		Object.DepreciationAdjustmentOption = PredefinedValue("Enum.AdditionalDepreciationAccrualOptions.Automatically");
	EndIf;
	
	ConfigureDependentFormElements("AdjustmentModeFromPreviousDate,DepreciationAdjustmentOption");

EndProcedure

&AtClient
Procedure PostInAccountingOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.PostInAccounting = True;
	EndIf;
	
	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElements("RecordInLocalAccounting,PostInAccounting");

EndProcedure

&AtClient
Procedure RecordInTAOnChange(Item)
	
	If Not Object.PostInAccounting And Not Object.RecordInTA And Not Object.RecordInManAccounting Then
		Object.RecordInTA = True;
	EndIf;

	Object.RecordInLocalAccounting = Object.PostInAccounting Or Object.RecordInTA;

	ConfigureDependentFormElements("RecordInLocalAccounting,RecordInTA");

EndProcedure

&AtClient
Procedure RecordInManAccountingOnChange(Item)
	
	If Not Object.RecordInLocalAccounting And Not Object.RecordInManAccounting Then
		Object.RecordInManAccounting = True;
	EndIf;

	ConfigureDependentFormElements("RecordInManAccounting");

EndProcedure

&AtClient
Procedure TypeOfExpenseAnalysisFixedAssetsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization,FixedAssetCostAdditionsPartial");
	
EndProcedure

&AtClient
Procedure TypeOfCostAnalysisConstructionObjectsOnChange(Item)
	
	ConfigureDependentFormElements("DimensionKindExpenseCapitalization");
	
EndProcedure

&AtClient
Procedure FixedAssetCostAdditionsPartialOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);

EndProcedure

&AtClient
Procedure DepreciationAdjustmentURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#Create" Then
		
		StandardProcessing = False;
		
		If Not ValueIsFilled(Object.Ref)
			Or Modified Then
			
			ButtonsList = New ValueList();
			ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Kết chuyển và tạo';
														|ru = 'Провести и создать';
														|en = 'Post and create'; fa = 'Post and create';
														|it = 'Провести и создать';
														|pl = 'Post and create';
														|tr = 'Kaydet ve oluştur'"));
			ButtonsList.Add(DialogReturnCode.Cancel);
			
			QueryText = NStr("vi = 'Chỉ có thể tạo chứng từ sau khi kết chuyển.
					|Kết chuyển và tiếp tục?';
					|ru = 'Оформление документа возможно только после проведения.
					|Провести и продолжить?';
					|en = 'Document registration is only available after posting.
					|Post and continue?'; fa = 'Document registration is only available after posting.
					|Post and continue?';
					|it = 'Оформление документа возможно только после проведения.
					|Провести и продолжить?';
					|pl = 'Document registration is only available after posting.
					|Post and continue?';
					|tr = 'Belgenin oluşturulması ancak kayıttan sonra mümkündür.
					|Kaydedilsin ve devam edilsin mi?'");
			
			CallbackDescription = New CallbackDescription("CreateAdjustmentCompletion", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, ButtonsList,, DialogReturnCode.Yes);
			
		Else
			CreateAdjustmentCompletion(DialogReturnCode.Yes, Undefined);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteOffAppreciationCostsOnChange(Item)

	ConfigureDependentFormElements(Item.Name);
		
EndProcedure

&AtClient
Procedure DocumentInformationInAnotherAccountingURLProcessing(Item, FormattedStringURL, StandardProcessing)
	
	If FormattedStringURL = "#CreateDocument" Then
		StandardProcessing = False;
		FormParameters = New Structure("Basis", Object.Ref);
		OpenForm("Document.FixedAssetsCostAdditions2_4.ObjectForm", FormParameters);
	EndIf; 
	
EndProcedure

#Region TheAccountingPage

&AtClient
Procedure ExpenseItemWriteOffCostsOnChange(Item)
	
	IncomeAndExpensesClientServer.AssetRefOnChange(ThisObject, Items.ExpenseItemWriteOffCosts);

EndProcedure

&AtClient
Procedure ExpenseItemWriteOffCostsStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartArticleSelection(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsStartChoice(Item, ChoiceData, StandardProcessing)
	
	IncomeAndExpensesClient.StartSelectingExpenseAnalytics(ThisObject, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	IncomeAndExpensesClient.AutoSelectionOfExpenseAnalytics(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ExpenseDimensionWriteOffCostsTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	IncomeAndExpensesClient.EndOfCostAnalyticsTextEntry(ThisObject, Item, Text, ChoiceData, DataGetParameters, StandardProcessing);
	
EndProcedure

&AtClient
Procedure BusinessUnitAndLineOfBusinessMatchAccountingDataWriteOffCostsOnChange(Item)
	
	ConfigureDependentFormElements(Item.Name);
	
EndProcedure

#EndRegion

#Region Localization

&AtClient
Procedure Attachable_OnChangeAttribute(Item)

	FixedAssetsCostAdditionsClientLocalization.OnChangeAttribute(Item.Name, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_StartChoice(Item, ChoiceData, StandardProcessing)
	
	FixedAssetsCostAdditionsClientLocalization.StartChoice(Item, ChoiceData, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	FixedAssetsCostAdditionsClientLocalization.AutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Attachable_TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	FixedAssetsCostAdditionsClientLocalization.TextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing, ThisObject);
	
EndProcedure

&AtClient
Procedure Decorationedonage(Item, StandardProcessing)
	
	
	Return; // WE have an empty handler

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
Procedure FAOnStartEdit(Item, NewRow, Copy)
	
	FillInValuesOfFADetailsBeforeChange();
		
EndProcedure

&AtClient
Procedure FAFixedAssetOnChange(Item)
	FAIsPrimaryMeansWhenChangingOnServer();
EndProcedure

&AtClient
Procedure FACostInAccountingOnChange(Item)

	FACostOfACWhenChangedOnServer();	

EndProcedure

&AtClient
Procedure FACostInManagementAccountingOnChange(Item)
	
	FillInInformationInBasement();
	
EndProcedure

&AtClient
Procedure FAOnChange(Item)
	
	ConfigureDependentFormElements("FA");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Pick(Command)
	
	PerformanceMonitorClient.TimeMeasurement("Catalog.Assets.ChoiceForm");

	PickingParameters = TMCommonUseClientServer.PickingParameters(Items.FAFixedAsset, ThisObject);

	OpenForm("Catalog.Assets.ChoiceForm", 
					PickingParameters, Items.FA,,,,, 
					FormWindowOpeningMode.LockOwnerWindow)
	
EndProcedure

&AtClient
Procedure FillInRenovationCostAmount(Command)
	
	FillInCostAmount();
	
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

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommand(Command)

	FixedAssetsCostAdditionsClientLocalization.OnExecuteCommand(Command, ThisObject);

EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

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
Procedure AtEndOfChangingLocalizationDetails(TagName, NotificationParameters) Export

	AdditionalParametersAfterCallingServer = Undefined;
	
	If NotificationParameters.ServerCallRequired_ Then
		AdditionalParametersAfterCallingServer = WhenYouChangeDetailsOfCompletionOnServer(TagName, NotificationParameters.ProcessingParameters);
	EndIf;
	
	If Not NotificationParameters.ServerCallRequired_ Then
		
		If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements") Then
			ActionParameters = NotificationParameters.ProcessingParameters.Execute_ConfigureDependentFormElements;
			ConfigureDependentFormElements(ActionParameters);
		EndIf;

		If NotificationParameters.ProcessingParameters.Property("Execute_SaveDetailsValues") Then
			SaveDetailsValues(ThisObject);
		EndIf;
		
		If NotificationParameters.ProcessingParameters.Property("Execute_FillInformationInBasement") Then
			FillInInformationInBasement();
		EndIf;
	
	EndIf;

	If AdditionalParametersAfterCallingServer <> Undefined
		And AdditionalParametersAfterCallingServer.Property("Execute_WhenChangingBankingDetails") Then
		
		ActionParameters = New Structure;
		ActionParameters.Insert("FormItemName", "");
		ActionParameters.Insert("AdditionalActionParameters", Undefined);
		FillPropertyValues(ActionParameters, AdditionalParametersAfterCallingServer.Execute_WhenChangingBankingDetails);
		
		FixedAssetsCostAdditionsClientLocalization.OnChangeAttribute(
			ActionParameters.FormItemName, 
			ThisObject, 
			ActionParameters.AdditionalActionParameters);
			
	EndIf;
	
EndProcedure

&AtServer
Function WhenYouChangeDetailsOfCompletionOnServer(Val TagName, Val AdditionalParameters)

	Var ActionParameters;
	
	AdditionalParametersAfterCallingServer = Common.CopyRecursive(AdditionalParameters);
	
	FixedAssetsCostAdditionsLocalization.OnChangeAttribute(TagName, ThisObject, AdditionalParametersAfterCallingServer);

	If AdditionalParametersAfterCallingServer.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElementsOnServer(ActionParameters);
	EndIf;

	If AdditionalParametersAfterCallingServer.Property("Execute_SaveDetailsValues", ActionParameters) Then
		SaveDetailsValues(ThisObject);
	EndIf;
	
	If AdditionalParametersAfterCallingServer.Property("Execute_FillInformationInBasement", ActionParameters) Then
		FillInInformationInBasement();
	EndIf;
	
	Return AdditionalParametersAfterCallingServer;
	
EndFunction
 
&AtServer
Procedure OrganizationWhenChangedOnServer()

	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
	
	ConfigureDependentFormElementsOnServer("Organization,VATTaxation");
	
EndProcedure

&AtServer
Procedure DateOfChangeOnServer()

	NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);

	ConfigureDependentFormElementsOnServer("Date");
	
EndProcedure

&AtServer
Procedure FAIsPrimaryMeansWhenChangingOnServer()
	
	CurrentRow = Items.FA.CurrentRow;
	RowData = Object.FA.FindByID(CurrentRow);
	WhenChangingFixedAsset(CommonClientServer.ValueInArray(RowData));

EndProcedure

&AtServer
Procedure FACostOfACWhenChangedOnServer()

	CurrentRow = Items.FA.CurrentRow;
	CurrentData = Object.FA.FindByID(CurrentRow);
	
	If FAAttributeValuesBeforeChange.CostInAccounting = FAAttributeValuesBeforeChange.CostInManagementAccounting 
		And Object.RecordInManAccounting 
		And CurrenciesDoNotMatch
		And FormServiceParameters.ComplianceCAAccountingIsKept Then
		CurrentData.CostInManagementAccounting = CurrentData.CostInAccounting;
	EndIf; 

	FixedAssetsCostAdditionsLocalization.FACostInAccountingOnChange(ThisObject, CurrentData);
	
	FillInInformationInBasement();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SaveDetailsValues(Form)

	NewSavedBankingDetails = New Structure(Form.FormServiceParameters.ListOfDetailsForSavingValueBeforeChangingIt);
	FillPropertyValues(NewSavedBankingDetails, Form.Object);
	
	Form.SavedBankDetails_3 = New FixedStructure(NewSavedBankingDetails);

EndProcedure

&AtClient
Procedure Attachable_OnChangeAttributeCompletion(TagName, AdditionalParameters) Export

	Var ActionParameters;
	
	AdditionalParametersAfterCallingServer = Undefined;
	
	If AdditionalParameters.ServerCallRequired_ Then
		AdditionalParametersAfterCallingServer = WhenYouChangeDetailsOfCompletionOnServer(TagName, AdditionalParameters);
	EndIf;
	
	If Not AdditionalParameters.ServerCallRequired_ Then
		
		If AdditionalParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
			ConfigureDependentFormElements(ActionParameters);
		EndIf;

		If AdditionalParameters.Property("Execute_SaveDetailsValues", ActionParameters) Then
			SaveDetailsValues(ThisObject);
		EndIf;
		
		If AdditionalParameters.Property("Execute_FillInformationInBasement", ActionParameters) Then
			FillInInformationInBasement();
		EndIf;
		
		If AdditionalParameters.Property("Execute_FillInFADetailsValuesBeforeChanging") Then
			FillInValuesOfFADetailsBeforeChange();
		EndIf;
		
	EndIf;

	If AdditionalParametersAfterCallingServer <> Undefined
		And AdditionalParametersAfterCallingServer.Property("Execute_WhenChangingBankingDetails", ActionParameters) Then
		
		FixedAssetsCostAdditionsClientLocalization.OnChangeAttribute(
			ActionParameters.FormItemName, 
			ThisObject, 
			ActionParameters.AdditionalActionParameters);
			
	EndIf;
	
EndProcedure
 
#EndRegion

#Region FillType

&AtServer
Procedure SelectionOnServer(ValueSelected)

	AddedRows = NonCurrentAssetsClientServer.ProcessingElementSelection(
		Object.FA, "FixedAsset", ValueSelected);

	If AddedRows.Count() <> 0 Then
		WhenChangingFixedAsset(AddedRows, True);
	EndIf;
	
EndProcedure

&AtServer
Procedure WhenChangingFixedAsset(RowsSelected = Undefined, TheseAreNewLines = False)

	FillInHeaderForSelectedFA();

	FillInCostAmount(RowsSelected);
	
	FixedAssetsCostAdditionsLocalization.WhenChangingFixedAsset(ThisObject, RowsSelected, TheseAreNewLines);
	
	ConfigureDependentFormElementsOnServer("FA,FixedAsset");
	
EndProcedure
 
&AtServer
Procedure FillInCostAmount(RowsSelected = Undefined)

	If Not FormServiceParameters.ThereIsCostAccounting Then
		Return;
	EndIf;
	
	ReportErrors = RowsSelected = Undefined;
	
	Cancel = False;
	If Not ValueIsFilled(Object.Date)  Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường ""Ngày"" chưa điền';
								|ru = 'Поле ""Дата"" не заполнено';
								|en = '""Date"" is required'; fa = '""Date"" is required';
								|it = 'Il campo ""Data"" non è compilato';
								|pl = 'Pole ""Дата"" nie jest wypełnione';
								|tr = '""Tarih"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, , "Object", "Date", Cancel);
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	If Not ValueIsFilled(Object.Organization) Then
		If ReportErrors Then
			MessageText = NStr("vi = 'Chưa điền trường ""Doanh nghiệp""';
								|ru = 'Поле ""Организация"" не заполнено';
								|en = '""Company"" is required'; fa = '""Company"" is required';
								|it = 'Il campo ""Società"" non è compilato';
								|pl = 'Nie wypełniono pola ""Firma""';
								|tr = '""İş yeri"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, , "Object", "Organization", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	If Not ValueIsFilled(Object.ConstructionObject) 
		And Object.DimensionKindExpenseCapitalization = Enums.KindsOfExpenseCapitalizationDimension.ConstructionObject Then
		
		If ReportErrors Then
			MessageText = NStr("vi = 'Trường ""Đối tượng xây dựng"" không được điền';
								|ru = 'Поле ""Объект строительства"" не заполнено';
								|en = '""Assets under construction"" is required'; fa = '""Assets under construction"" is required';
								|it = 'Il campo ""Oggetto in costruzione"" non è compilato';
								|pl = 'Pole ""Obiekty budowy"" nie jest wypełnione';
								|tr = '""Yapı nesnesi"" alanı doldurulmadı'");
			CommonClientServer.MessageToUser(MessageText, , "Object", "ConstructionObject", Cancel); 
		Else
			Cancel = True;
		EndIf; 
	EndIf;
	
	If Not Cancel Then
		Documents.FixedAssetsCostAdditions2_4.FillInCostAmount(Object, RowsSelected);
		FillInInformationInBasement();
	EndIf;
	
EndProcedure
 
#EndRegion

#Region Other

&AtClient
Procedure Attachable_CloseForm()
	
	Close();
	
EndProcedure

&AtClient
Procedure ContinueRunningLocalizationCommand(CommandName, NotificationParameters) Export

	Var ActionParameters;

	If NotificationParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, NotificationParameters.ProcessingParameters);
		Return;
	EndIf;
	
	If NotificationParameters.ProcessingParameters.Property("Execute_ConfigureDependentFormElements", ActionParameters) Then
		ConfigureDependentFormElements(ActionParameters);
	EndIf; 
	
EndProcedure

&AtServer
Procedure WhenExecutingEndCommandOnServer(Val CommandName, Val AdditionalParameters)

	FixedAssetsCostAdditionsLocalization.OnExecuteCommand(CommandName, ThisObject);

EndProcedure

&AtServer
Procedure OnReadCreateAtServer()

	InitializingFormWhenCreatingItOnServer();
	
	SaveDetailsValues(ThisObject);
	
	Items.CommentPage.Picture = CommonClientServer.CommentPicture(Object.Comment);
	
 	UseConstructionObjects = GetFunctionalOption("UseConstructionObjects");
	
	FixedAssetsCostAdditionsLocalization.OnReadCreateAtServer(ThisObject);
	
	ConfigureDependentFormElementsOnServer();
	
EndProcedure

&AtServer
Procedure InitializingFormWhenCreatingItOnServer()

	InitializeServiceParametersOfForm();
	
	CurrencyOfMan = Constants.ManagementAccountingCurrency.Get();
	ComplCurrency = SettingsValueCached.CurrencyOfOrganizationSRegulatedAccounting(Object.Organization);
	CurrenciesDoNotMatch = (CurrencyOfMan = ComplCurrency);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	FixedAssetsCostAdditionsLocalization.SetConditionalAppearance(ThisObject);
		
EndProcedure

&AtClient
Procedure ConfigureDependentFormElements(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	If RequiresServerCallToConfigureFormElements(StructureOfChangedProps) Then
		ConfigureDependentFormElementsOnServer(ChangedBankingDetails)
	Else
		ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElementsOnClientOnServer(Form, Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	Object = Form.Object;
	Items = Form.Items;
	FormServiceParameters = Form.FormServiceParameters;
	PresentationOfDetails = FormServiceParameters.PresentationOfDetails; // Map
	
	AuxiliaryAttributes = New Structure;
	AuxiliaryAttributes.Insert("ComplianceCAAccountingIsKept", FormServiceParameters.ComplianceCAAccountingIsKept);
	AuxiliaryAttributes.Insert("FALocalAccountingIsConductedIndependently", FormServiceParameters.FALocalAccountingIsConductedIndependently);
	AuxiliaryAttributes.Insert("CurrenciesDoNotMatch", Form.CurrenciesDoNotMatch);
	AuxiliaryAttributes.Insert("UseConstructionObjects", Form.UseConstructionObjects);
	AuxiliaryAttributes.Insert("LineOfBusinessIsMandatory", False);
	AuxiliaryAttributes.Insert("ThereIsCostAccounting", FormServiceParameters.ThereIsCostAccounting);
	AuxiliaryAttributes.Insert("AccountPolicySettings", FormServiceParameters.AccountPolicySettings);
	AuxiliaryAttributes.Insert("PropertyTaxMayBeCharged", False);
	AuxiliaryAttributes.Insert("PropertyTaxAdvancesArePaid", False);
	NonCurrentAssetsClientServerLocalization.AddAuxiliaryDetails_UpgradingFA(Form, AuxiliaryAttributes);
	
	NonCurrentAssetsClientServer.WhenChangingBankingDetails_UpgradeFA(Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__FA(
									Object, AuxiliaryAttributes, ChangedBankingDetails);
	
	TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
	
	If Not UpdateAll Then
		
		TMCommonUseClientServer.ClearUnusedProps(Object, ItemDetailsParameters, "FA,TargetFinancing");
		
		ChangedBankingDetails = NonCurrentAssetsClientServer.FillInDetailsDependingOnProperties__FA(
				Object, ItemDetailsParameters);

		If ValueIsFilled(ChangedBankingDetails) Then
			ItemDetailsParameters = NonCurrentAssetsClientServer.PropertyValuesOfDependentProps__FA(
											Object, AuxiliaryAttributes, ChangedBankingDetails);
		
			TMCommonUseClientServer.ConfigureDependentFormElements(Form, ItemDetailsParameters);
		EndIf;
		
	EndIf;

	FAUpgradeOptions = NonCurrentAssetsClientServer.FAUpgradeOptions(Object, AuxiliaryAttributes);

	#Region IsMain
	
	Items.DecorationPartialUpgrade.Visible = Items.FixedAssetCostAdditionsPartial.Visible;
	
	If StructureOfChangedProps.Property("Ref")
		Or StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost") Then
			PresentationOperation = NStr("vi = 'Đưa chi phí bổ sung vào giá trị TSCĐ';
										|ru = 'Включение доп. расходов в стоимость ОС';
										|en = 'Include additional expenses in fixed asset cost'; fa = 'گنجاندن هزینه‌های تکمیلی در بهای دارایی ثابت';
										|it = 'Include additional expenses in fixed asset cost';
										|pl = 'Include additional expenses in fixed asset cost';
										|tr = 'Ek giderlerin sabit kıymet maliyetine dahil edilmesi'");
			ModePresentation = NStr("vi = 'Bao gồm chi phí từ';
									|ru = 'Включение расходов с';
									|en = 'Include expenses from'; fa = 'Include expenses from';
									|it = 'Include expenses from';
									|pl = 'Include expenses from';
									|tr = '-den giderlere dahil edilmesi'");
			PresentationOfReflectionOption = NStr("vi = 'Bao gồm chi phí trong';
													|ru = 'Включение расходов в';
													|en = 'Include expenses in'; fa = 'Include expenses in';
													|it = 'Include expenses in';
													|pl = 'Include expenses in';
													|tr = '-e giderlerin dahil edilmesi'");
		Else
			PresentationOperation = NStr("vi = 'Nâng cấp TSCĐ';
										|ru = 'Модернизация ОС';
										|en = 'Fixed assets appreciation'; fa = 'افزایش ارزش دارایی‌های ثابت';
										|it = 'Ammodernamento del patrimonio aziendale di capitale fisso';
										|pl = 'Modernizacja środków trwałych';
										|tr = 'SV modernizasyonu'");
			ModePresentation = NStr("vi = 'Nâng cấp từ';
									|ru = 'Модернизация с';
									|en = 'Appreciation from'; fa = 'افزایش ارزش از';
									|it = 'Appreciation from';
									|pl = 'Appreciation from';
									|tr = 'İle modernizasyon'");
			PresentationOfReflectionOption = NStr("vi = 'Nâng cấp trong';
													|ru = 'Модернизация в';
													|en = 'Appreciation in'; fa = 'افزایش ارزش در';
													|it = 'Ammodernamento in';
													|pl = 'Modernizacja w';
													|tr = 'Modernizasyon'");
		EndIf;
		
		Form.Title = ?(ValueIsFilled(Object.Ref),
			StrTemplate(NStr("vi = '%1 %2 ngày %3';
							|ru = '%1 %2 от %3';
							|en = '%1 %2 dated %3'; fa = '%1 %2 dated %3';
							|it = '%1 %2 del %3';
							|pl = '%1 %2 z dnia %3';
							|tr = '%3 tarihli %1 %2'"), PresentationOperation, Object.Number, Object.Date),
			StrTemplate(NStr("vi = '%1 (tạo mới)';
							|ru = '%1 (создание)';
							|en = '%1 (Create)'; fa = '%1 (Create)';
							|it = '%1 (creazione)';
							|pl = '%1 (utworzenie)';
							|tr = '%1 (oluşturma)'"), PresentationOperation));
			
		Items.AdjustmentModeFromPreviousDate.Title = ModePresentation;
		Items.DecorationIsReflectionOption.Title = PresentationOfReflectionOption;
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		Items.PostInAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.RecordInTA.Visible = FormServiceParameters.ComplianceCAAccountingIsKept;
		Items.RecordInManAccounting.Visible = FormServiceParameters.FALocalAccountingIsConductedIndependently;
		Items.DecorationIsReflectionOption.Visible = Items.PostInAccounting.Visible Or Items.RecordInManAccounting.Visible;
		
		If Not FormServiceParameters.FALocalAccountingIsConductedIndependently 
			And Not UpdateAll Then

			Object.RecordInLocalAccounting = True;
			Object.RecordInManAccounting = True;
			Object.PostInAccounting = True;
			Object.RecordInTA = True;
		EndIf;
		
	EndIf;
	
	If StructureOfChangedProps.Property("AdjustmentModeFromPreviousDate")
		Or StructureOfChangedProps.Property("DepreciationAdjustmentOption")
		Or StructureOfChangedProps.Property("WriteOffAppreciationCosts")
		Or StructureOfChangedProps.Property("Write_FixedAssetCostAndDepreciationAdjustment")
		Or UpdateAll Then
		
		If Object.AdjustmentModeFromPreviousDate
			And Object.DepreciationAdjustmentOption = PredefinedValue("Enum.AdditionalDepreciationAccrualOptions.Manually") Then
				
			Form.DepreciationAdjustment = InscriptionDepreciationAdjustment(Object.Ref);
			
			Items.DepreciationAdjustment.Visible = True;
			
		Else
			Items.DepreciationAdjustment.Visible = False;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	#Region FA
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		NewSelectionOptions = New Array;
		NewSelectionOptions.Add(New ChoiceParameter("Context", "ACC,MA"));
		NewSelectionOptions.Add(New ChoiceParameter("Filter.State", PredefinedValue("Enum.FixedAssetsStates.Recognized_")));
		NewSelectionOptions.Add(New ChoiceParameter("AttributesThatShouldMatch", "Organization,Department"));
		
		If Object.BusinessOperation <> PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost") Then
			AvailableFATypes = New Array;
			AvailableFATypes.Add(PredefinedValue("Enum.FATypes.Asset"));
			AvailableFATypes.Add(PredefinedValue("Enum.FATypes.GroupFA"));
			AvailableFATypes.Add(PredefinedValue("Enum.FATypes.CapitalExpenditureInLeasedAssets"));
			NewSelectionOptions.Add(New ChoiceParameter("Filter.OSType", New FixedArray(AvailableFATypes)));
		EndIf;
		
		Items.FAFixedAsset.ChoiceParameters = New FixedArray(NewSelectionOptions);

	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		Items.FACostInManagementAccounting.Title = PresentationOfDetails.Get("FA.CostInManagementAccounting");
		Items.FACostInAccounting.Title = PresentationOfDetails.Get("FA.CostInAccounting");
		Items.FACostInTaxAccounting.Title = PresentationOfDetails.Get("FA.CostInTaxAccounting");
		Items.FACostPermanentDifference.Title = PresentationOfDetails.Get("FA.CostPermanentDifference");
		Items.FAAmountOfBonusDepreciationTaxAccounting.Title = PresentationOfDetails.Get("FA.AmountOfBonusDepreciationTaxAccounting");
		
	EndIf;

	If StructureOfChangedProps.Property("Date")
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("RecordInLocalAccounting")
		Or StructureOfChangedProps.Property("RecordInManAccounting")
		Or StructureOfChangedProps.Property("DimensionKindExpenseCapitalization")
		Or StructureOfChangedProps.Property("FixedAssetCostAdditionsPartial")
		Or StructureOfChangedProps.Property("FA")
		Or StructureOfChangedProps.Property("FixedAsset")
		Or UpdateAll Then
		
		Items.FAFillInAmountOfCosts.Visible = 
			Not FAUpgradeOptions.ActualCost
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInTaxAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible);
		
		If (FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC
				Or FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC)
			And FAUpgradeOptions.CostIsRequiredToCalculateTax
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính khấu hao trong tháng hiện tại và để tính thuế tài sản.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau, còn số thuế sẽ được tính trong cùng tháng này.';
					 |ru = 'Сумма затрат используется для расчета амортизации в текущем месяце и для начисления налога на имущество.
					 |Она может не совпадать с фактическими затратами, в этом случае амортизация будет скорректирована в следующем месяце, а сумма налога в этом же месяце.';
					 |en = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.'; fa = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |it = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |pl = 'The cost amount is used to calculate depreciation for the current month and to calculate the property tax.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month, and the tax amount will be adjusted in the same month.';
					 |tr = 'Gider tutarı, cari ayda amortisman hesaplaması ve emlak vergisi tahakkuku için kullanılır.
					 | Gerçek giderlerle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda, vergi tutarı ise aynı ayda düzeltilir.'");
		 
		ElsIf (FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC
				Or FAUpgradeOptions.CostIsRequiredToCalculateDepreciationOfAC)
			And (Items.FACostInAccounting.Visible
				Or Items.FACostInManagementAccounting.Visible) Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính khấu hao trong tháng hiện tại.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, khấu hao sẽ được điều chỉnh vào tháng sau.';
					 |ru = 'Сумма затрат используется для расчета амортизации в текущем месяце.
					 |Она может не совпадать с фактическими затратами, в этом случае амортизация будет скорректирована в следующем месяце.';
					 |en = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.'; fa = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |it = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |pl = 'The cost amount is used to calculate depreciation for the current month.
					 |It may not match the actual cost. In this case, the depreciation will be adjusted next month.';
					 |tr = 'Gider tutarı, cari ayda amortisman hesaplaması için kullanılır.
					 |Gerçek giderlerle örtüşmeyebilir, bu durumda amortisman bir sonraki ayda düzeltilir.'");
					 
		ElsIf FAUpgradeOptions.CostIsRequiredToCalculateTax
			And Items.FACostInAccounting.Visible Then
			
			Items.FABasementInfoText.Visible = True;
			Items.FABasementInformationPicture.Visible = True;
			
			Items.FABasementInfoText.Title =
				NStr("vi = 'Số tiền chi phí được sử dụng để tính thuế tài sản.
					 |Số tiền này có thể không khớp với chi phí thực tế, trong trường hợp đó, số thuế sẽ được điều chỉnh trong cùng tháng này.';
					 |ru = 'Сумма затрат используется для начисления налога на имущество.
					 |Она может не совпадать с фактическими затратами, в этом случае сумма налога будет скорректирована в этом же месяце.';
					 |en = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.'; fa = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |it = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |pl = 'The cost amount is used to calculate the property tax.
					 |It may not match the actual cost. In this case, the tax amount will be adjusted in the same month.';
					 |tr = 'Gider tutarı, emlak vergisi tahakkuku için kullanılır.
					 | Gerçek giderlerle örtüşmeyebilir, bu durumda vergi tutarı aynı ayda düzeltilir.'");
					 
		Else
		 
			Items.FABasementInfoText.Visible = False;
			Items.FABasementInformationPicture.Visible = False;
			
		EndIf;
		
	EndIf;

	#EndRegion
	
	#Region TheAccountingPage
	
	If StructureOfChangedProps.Property("BusinessOperation")
		Or UpdateAll Then
		
		If Object.BusinessOperation = PredefinedValue("Enum.BusinessTransactions.IncludeAdditionalExpensesInFixedAssetCost") Then
			GroupPresentation = NStr("vi = 'Ghi giảm chi phí bổ sung';
									|ru = 'Списание доп. расходов';
									|en = 'Write-off additional expenses'; fa = 'Write-off additional expenses';
									|it = 'Write-off additional expenses';
									|pl = 'Write-off additional expenses';
									|tr = 'Ek giderlerin gider yazılması'");
		Else
			GroupPresentation = NStr("vi = 'Ghi giảm chi phí nâng cấp';
									|ru = 'Списание затрат на модернизацию';
									|en = 'Write-off modernization costs'; fa = 'Write-off modernization costs';
									|it = 'Write-off modernization costs';
									|pl = 'Write-off modernization costs';
									|tr = 'Modernizasyon maliyetlerinin giderleştirilmesi'");
		EndIf;
		
		Items.Group_WriteOffOfExpenses.Title = GroupPresentation;
		
	EndIf;
	
	#EndRegion
	
	NonCurrentAssetsClientServerLocalization.ConfigureDependentFormElements_UpgradeFA(
		Form, StructureOfChangedProps);
	
EndProcedure

&AtServer
Procedure ConfigureDependentFormElementsOnServer(Val ChangedBankingDetails = "")

	StructureOfChangedProps = New Structure(ChangedBankingDetails);
	UpdateAll = StructureOfChangedProps.Count() = 0;
	
	DateOfParameters = EndOfMonth(?(Object.Date <> '000101010000', Object.Date, CurrentSessionDate()));

	If UpdateAll Then
		
		Items.LineOfBusinessTaxAccounting.Visible = False;
		Items.LineOfBusinessBonusDepreciation.Visible = False;
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ComplianceCAAccountingIsKept",
			NonCurrentAssetsInternal.ComplianceCAAccountingIsKept(),
			FormServiceParameters);
			
	EndIf;

	If StructureOfChangedProps.Property("Date") 
		Or UpdateAll Then
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"ThereIsCostAccounting",
			CalculationOfCostCached.GenerateRegisteredRecordsOnCostRegisters(DateOfParameters),
			FormServiceParameters);
		
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or UpdateAll Then
		
		NonCurrentAssets.SetParametersOfFunctionalOptionsOfObjectForm(ThisObject, Object.Organization, Object.Date);
		
		NonCurrentAssetsInternal.SetStructureProperty(
			"FALocalAccountingIsConductedIndependently",
			AccountingPoliciesTaxSettingsCached.FALocalAccountingIsConductedIndependently(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"AccountPolicySettings",
			AccountingPoliciesTaxSettingsCached.AccountingSettingsForNonCurrentAssets(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PropertyTaxAdvancesArePaid",
			AccountingPoliciesTaxSettingsCached.PropertyTaxAdvancesArePaid(Object.Organization, DateOfParameters),
			FormServiceParameters);
			
		NonCurrentAssetsInternal.SetStructureProperty(
			"PresentationOfDetails",
			Documents.FixedAssetsCostAdditions2_4.PresentationOfDetails(Object.Organization, Object.Date),
			FormServiceParameters);
			
	EndIf;
	
	If StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("FixedAsset") 
		Or UpdateAll Then
			
		FillInInformationInBasement();
	EndIf;
	
	FixedAssetsCostAdditionsLocalization.ConfigureDependentFormElements(ThisObject, StructureOfChangedProps);
	
	ConfigureDependentFormElementsOnClientOnServer(ThisObject, ChangedBankingDetails);

EndProcedure

&AtClient
Function RequiresServerCallToConfigureFormElements(StructureOfChangedProps)

	If StructureOfChangedProps.Count() = 0
		Or StructureOfChangedProps.Property("Date") 
		Or StructureOfChangedProps.Property("Organization")
		Or StructureOfChangedProps.Property("Department") Then
		Return True;
	EndIf; 
	
	Return FixedAssetsCostAdditionsClientLocalization.RequiresServerCallToConfigureFormElements(Object, StructureOfChangedProps);

EndFunction

&AtServer
Procedure FillInInformationInBasement()

	LabelTitle = NonCurrentAssetsInternal.DocumentInformationInAnotherAccounting(Object);
	If PreliminaryCostDiffersFromActual() Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(NStr("vi = 'Giá trị tạm tính khác với giá trị thực tế.';
							|ru = 'Предварительная стоимость отличается от фактической.';
							|en = 'The preliminary cost differs from the actual cost.'; fa = 'The preliminary cost differs from the actual cost.';
							|it = 'The preliminary cost differs from the actual cost.';
							|pl = 'The preliminary cost differs from the actual cost.';
							|tr = 'Ön maliyet, gerçek maliyetten farklıdır.'"));
	EndIf; 
	
	TextUsageExpired = TermOfUseExpired();
	If TextUsageExpired <> "" Then
		If LabelTitle.Count() <> 0 Then
			LabelTitle.Add(Chars.LF);
		EndIf;
		LabelTitle.Add(TextUsageExpired);
	EndIf; 

	If LabelTitle.Count() <> 0 Then
		Items.Information.Title = New FormattedString(LabelTitle);
		Items.PictureInformation.Visible = True;
		Items.Information.Visible = True;
	Else
		Items.PictureInformation.Visible = False;
		Items.Information.Visible = False;
	EndIf; 
	
EndProcedure

&AtServer
Function PreliminaryCostDiffersFromActual()

	If Not ValueIsFilled(Object.Ref)
		Or Object.FixedAssetCostAdditionsPartial Then
		Return False;
	EndIf;
	
	QueryText = 
	"SELECT
	|	FATable.FixedAsset AS FixedAsset,
	|	FATable.CostInAccounting AS CostInAccounting,
	|	FATable.CostInManagementAccounting AS CostInManagementAccounting
	|INTO TTFATable
	|FROM
	|	&FATable AS FATable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	FATable.FixedAsset AS FixedAsset
	|FROM
	|	TTFATable AS FATable
	|		INNER JOIN AccumulationRegister.FACost AS FACost
	|		ON (FACost.Recorder = &Ref)
	|			AND FATable.FixedAsset = FACost.FixedAsset
	|			AND (FACost.CostCalculation)
	|			AND (FACost.RecordType = VALUE(AccumulationRecordType.Receipt))
	|
	|GROUP BY
	|	FATable.FixedAsset
	|
	|HAVING
	|	(&RecordInLocalAccounting
	|			AND MAX(FATable.CostInAccounting) <> SUM(FACost.LocalCost + FACost.CostTargetFinancing)
	|		OR &RecordInManAccounting
	|			AND MAX(FATable.CostInManagementAccounting) <> SUM(FACost.Cost))";
	
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("FATable", Object.FA.Unload());
	Query.SetParameter("RecordInLocalAccounting", Object.RecordInLocalAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	
	Result = Query.Execute();
	
	Return Not Result.IsEmpty();

EndFunction

&AtServer
Function TermOfUseExpired()
	
	ListOfRequests = New Array;
	
	QueryText = 
	"SELECT
	|	FALocation.FixedAsset AS FixedAsset,
	|	FALocation.Organization AS Organization
	|INTO TTLocationOfFA
	|FROM
	|	InformationRegister.FALocation.SliceLast(
	|			&EndOfMonth, 
	|			CorrectionDate = DATETIME(1,1,1)
	|				AND Recorder <> &Ref
	|				AND FixedAsset IN (&ListOfFA)) AS FALocation
	|
	|INDEX BY
	|	FixedAsset,
	|	Organization
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	FixedAssetDepreciationParametersManagementAccounting.FixedAsset AS FixedAsset,
	|	FixedAssetDepreciationParametersManagementAccounting.LastChangeDate AS LastChangeDate,
	|	FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod AS DepreciationMethod,
	|	FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth AS UsefulLifeForCalculatingDepreciationMonth
	|INTO TTOsuuDepreciationParameters
	|FROM
	|	InformationRegister.FixedAssetDepreciationParametersManagementAccounting.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND CorrectionDate = DATETIME(1,1,1)
	|				AND (FixedAsset, Organization) IN
	|						(SELECT
	|							TTLocationOfFA.FixedAsset,
	|							TTLocationOfFA.Organization
	|						FROM
	|							TTLocationOfFA AS TTLocationOfFA)) AS FixedAssetDepreciationParametersManagementAccounting
	|WHERE
	|	&RecordInManAccounting
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT 
	|	FixedAssetsAccountingProcedure.FixedAsset AS FixedAsset,
	|	FixedAssetsAccountingProcedure.RunningTimeValue AS RunningTimeValue,
	|	FixedAssetsAccountingProcedure.EstimatedRunningTime AS EstimatedRunningTime
	|INTO TTAccountingFA
	|FROM
	|	InformationRegister.FixedAssetsAccountingProcedure.SliceLast(
	|			&EndOfMonth, 
	|			Recorder <> &Ref
	|				AND CorrectionDate = DATETIME(1,1,1)
	|				AND FixedAsset IN (&ListOfFA)) AS FixedAssetsAccountingProcedure
	|
	|INDEX BY
	|	FixedAsset
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssetActivityRecords.Asset AS Asset,
	|	AssetActivityRecords.Value AS Value
	|INTO TTOperatingTimeOfObjectsOfOperation
	|FROM
	|	InformationRegister.AssetActivityRecords.SliceLast(
	|			&EndOfMonth,
	|			(Asset, RunningTimeValue) IN
	|				(SELECT
	|					TTAccountingFA.FixedAsset,
	|					TTAccountingFA.RunningTimeValue
	|				FROM
	|					TTAccountingFA AS TTAccountingFA)) AS AssetActivityRecords
	|
	|INDEX BY
	|	Asset";
	ListOfRequests.Add(QueryText);
	
	FixedAssetsCostAdditionsLocalization.AddRequestTextExpirationDate(ListOfRequests);
	
	QueryText =
	"SELECT
	|	ISNULL(MAX(CheckingParameters.ExpiredMa), FALSE) AS ExpiredMa,
	|	ISNULL(MAX(CheckingParameters.ExpiredAC), FALSE) AS ExpiredAC,
	|	ISNULL(MAX(CheckingParameters.ThereIsOperatingTime), FALSE) AS ThereIsOperatingTime,
	|	ISNULL(MAX(CheckingParameters.ThereIsNoRunningTime), FALSE) AS ThereIsNoRunningTime
	|FROM
	|	(SELECT
	|		TRUE AS ExpiredMa,
	|		FALSE AS ExpiredAC,
	|		FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction) AS ThereIsOperatingTime,
	|		FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod <> VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction) AS ThereIsNoRunningTime
	|	FROM
	|		TTOsuuDepreciationParameters AS FixedAssetDepreciationParametersManagementAccounting
	|			LEFT JOIN TTAccountingFA AS FixedAssetsAccountingProcedure
	|			ON FixedAssetsAccountingProcedure.FixedAsset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset
	|			LEFT JOIN TTOperatingTimeOfObjectsOfOperation AS AssetActivityRecords
	|			ON AssetActivityRecords.Asset = FixedAssetDepreciationParametersManagementAccounting.FixedAsset
	|	WHERE
	|		CASE
	|			WHEN FixedAssetDepreciationParametersManagementAccounting.DepreciationMethod = VALUE(Enum.AccrualMethodOfFixedAssetsDepreciation.ByUnitsOfProduction)
	|				THEN ISNULL(FixedAssetsAccountingProcedure.EstimatedRunningTime, 0)
	|						- ISNULL(AssetActivityRecords.Value, 0)
	|			ELSE 
	|				FixedAssetDepreciationParametersManagementAccounting.UsefulLifeForCalculatingDepreciationMonth
	|					- DATEDIFF(FixedAssetDepreciationParametersManagementAccounting.LastChangeDate, &EndOfMonth, MONTH) 
	|		END <= 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		FALSE AS ExpiredMa,
	|		TRUE AS ExpiredAC,
	|		CheckingParametersLocalization.ThereIsOperatingTime AS ThereIsOperatingTime,
	|		CheckingParametersLocalization.ThereIsNoRunningTime AS ThereIsNoRunningTime
	|	FROM
	|		TTParameterCheckingLocalization AS CheckingParametersLocalization
	|
	|	) AS CheckingParameters
	|
	|HAVING
	|	ISNULL(MAX(CheckingParameters.ExpiredMa), FALSE)
	|		OR ISNULL(MAX(CheckingParameters.ExpiredAC), FALSE)";
	ListOfRequests.Add(QueryText);

	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());

	Query = New Query(QueryText);
	Query.SetParameter("Ref", Object.Ref);
	Query.SetParameter("PostInAccounting", Object.PostInAccounting);
	Query.SetParameter("RecordInManAccounting", Object.RecordInManAccounting);
	Query.SetParameter("EndOfMonth", EndOfMonth(Object.Date));
	Query.SetParameter("ListOfFA", Object.FA.Unload(, "FixedAsset").UnloadColumn("FixedAsset"));
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	TextUsageExpired = "";
	
	Selection = Result.Select();
	If Selection.Next() Then
		
		If Selection.ExpiredAC And Selection.ExpiredMa Then
			
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ nâng cấp đã hết hạn (đã hết). Cần thiết phải lập một chứng từ ""Thay đổi trong các thông số TSCĐ"" và chỉ ra một thuật ngữ mới (thời gian hoạt động) hoặc tạm ngưng khấu hao trong hồ sơ kế toán và quản lý.';
										|ru = 'Срок использования (планируемый объем наработки) модернизируемых ОС истек (выработан). Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|en = 'Useful life (planned asset activity value) of modernized fixed assets has expired (generated). It is necessary to register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in local accounting and management accounting.'; fa = 'Useful life (planned asset activity value) of modernized fixed assets has expired (generated). It is necessary to register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in local accounting and management accounting.';
										|it = 'Il periodo di vita utile (volume di produzione stimato) dei Capitali fissi soggetti all''ammodernamento è terminato (esaurito). È necessario generare il documento ""Modifica dei parametri di Capitale fisso"" e indicare un nuovo termine di scadenza (volume di produzione) o sospendere il calcolo dell''ammortamento in contabilità ordinaria e gestionale.';
										|pl = 'Okres używania (planowana objętość czasu pracy) modernizowanych ŚT wygasł (została wyrobiona). Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres (objętość czasu pracy) lub wstrzymać naliczenie amortyzacji w ewidencji księgowej i zarządczej.';
										|tr = 'Modernize edilmiş sabit kıymetlerin kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve yeni bir süre (çalışma hacmi) belirlemek veya muhasebe ve yönetim hesaplarında amortisman tahakkukunu askıya almak gereklidir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ nâng cấp được phát triển đầy đủ. Cần phải lập một chứng từ Thay đổi thông số TSCĐ và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки модернизируемых ОС полностью выработан. Необходимо оформить документ ""Изменение параметров ОС"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.'; fa = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.';
										|it = 'Il volume di produzione stimato di Capitali fissi soggetti all''ammodernamento è esaurito. È necessario generare il documento ""Modifica di Capitale fisso"" e aumentare il volume di produzione stimato o sospendere il calcolo dell''ammortamento.';
										|pl = 'Przewidywana objętość czasu pracy modernizowanych ŚT została w całościa wypracowana. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i zwiększyć przewidywaną objętość wypracowania lub wstrzymać naliczenie amortyzacji.';
										|tr = 'Modernize edilen sabit kıymetlerin tahmini çalışma hacmi tamamen tükenmiştir. "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve tahmini çalışma hacmini artırmak veya amortismanı askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ nâng cấp đã hết hạn. Cần thiết phải lập một chứng từ Thay đổi các thông số TSCĐ và chỉ ra một thuật ngữ mới hoặc đình chỉ khấu hao trong hồ sơ kế toán và quản lý.';
										|ru = 'Срок использования модернизируемых ОС истек. Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок или приостановить начисление амортизации в бухгалтерском и управленческом учетах.';
										|en = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in local accounting and management accounting.'; fa = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in local accounting and management accounting.';
										|it = 'Il periodo di vita utile dei Capitali fissi soggetti all''ammodernamento è terminato. È necessario generare il documento ""Modifica dei paramentri di Capitale fisso"" e indicare un nuovo termine di scadenza o sospendere il calcolo dell''ammortamento in contabilità ordinaria e gestionale.';
										|pl = 'Okres używania  modernizowanych ŚT wygasł. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres lub wstrzymać naliczenie amortyzacji w ewidencji księgowej i zarządczej.';
										|tr = 'Modernize edilmiş sabit kıymetlerin kullanım süresi sona ermiştir. ""Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesinin yürütülmesi ve muhasebe ve yönetim kayıtlarında yeni bir dönem belirtilmesi veya amortisman tahakkukunun askıya alınması gereklidir.'");
			EndIf;
			
		ElsIf Selection.ExpiredAC Then
			
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ nâng cấp đã hết hạn (đã hết). Cần phải lập một chứng từ Thay đổi trong các thông số TSCĐ và chỉ ra một thuật ngữ mới (thời gian hoạt động) hoặc tạm ngưng khấu hao trong kế toán.';
										|ru = 'Срок использования (планируемый объем наработки) модернизируемых ОС истек (выработан). Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок (объем наработки) или приостановить начисление амортизации в бухгалтерском учете.';
										|en = 'Useful life (planned asset activity value) of modernized fixed assets has expired (generated). Register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in local accounting.'; fa = 'Useful life (planned asset activity value) of modernized fixed assets has expired (generated). Register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in local accounting.';
										|it = 'Il periodo di vita utile (volume di produzione stimato) dei Capitali fissi soggetti all''ammodernamento è terminato (esaurito). È necessario generare il documento ""Modifica dei parametri di Capitale fisso"" e indicare un nuovo termine di scadenza (volume di produzione) oppure sospendere il calcolo dell''ammortamento in contabilità ordinaria.';
										|pl = 'Okres używania (planowana objętość czasu pracy) modernizowanych ŚT wygasł (została wyrobiona). Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres (objętość czasu pracy) lub wstrzymać naliczenie amortyzacji w ewidencji księgowej.';
										|tr = 'Modernize edilmiş sabit kıymetlerin kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve yeni bir süre (çalışma hacmi) belirlemek veya muhasebede amortisman tahakkukunu askıya almak gereklidir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ nâng cấp được phát triển đầy đủ. Cần phải lập một chứng từ Thay đổi thông số TSCĐ và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки модернизируемых ОС полностью выработан. Необходимо оформить документ ""Изменение параметров ОС"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.'; fa = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.';
										|it = 'Il volume di produzione stimato di Capitali fissi soggetti all''ammodernamento è esaurito. È necessario generare il documento ""Modifica di Capitale fisso"" e aumentare il volume di produzione stimato o sospendere il calcolo dell''ammortamento.';
										|pl = 'Przewidywana objętość czasu pracy modernizowanych ŚT została w całościa wypracowana. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i zwiększyć przewidywaną objętość wypracowania lub wstrzymać naliczenie amortyzacji.';
										|tr = 'Modernize edilen sabit kıymetlerin tahmini çalışma hacmi tamamen tükenmiştir. "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve tahmini çalışma hacmini artırmak veya amortismanı askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ nâng cấp đã hết hạn. Cần thiết phải lập một chứng từ Thay đổi các thông số TSCĐ và chỉ ra một thuật ngữ mới hoặc đình chỉ khấu hao trong kế toán.';
										|ru = 'Срок использования модернизируемых ОС истек. Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок или приостановить начисление амортизации в бухгалтерском учете.';
										|en = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in local accounting.'; fa = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in local accounting.';
										|it = 'Il periodo di vita utile dei Capitali fissi soggetti all''ammodernamento è terminato. È necessario generare il documento ""Modifica dei parametri di Capitale fisso"" e indicare un nuovo termine di scadenza o sospendere il calcolo dell''ammodernamento in contabilità ordinaria.';
										|pl = 'Okres używania  modernizowanych ŚT wygasł. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres lub wstrzymać naliczenie amortyzacji w ewidencji księgowej.';
										|tr = 'Modernize edilmiş sabit kıymetlerin kullanım süresi sona ermiştir. ""Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve yeni bir dönem belirlemek veya muhasebede amortisman tahakkukunu askıya almak gereklidir.'");
			EndIf;

		Else			
		
			If Selection.ThereIsOperatingTime And Selection.ThereIsNoRunningTime Then
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng (thời gian hoạt động theo kế hoạch) của TSCĐ nâng cấp đã hết hạn (đã hết). Cần phải lập một chứng từ Thay đổi trong các thông số TSCĐ và chỉ ra một thuật ngữ mới (thời gian hoạt động) hoặc tạm ngưng khấu hao trong kế toán quản trị.';
										|ru = 'Срок использования (планируемый объем наработки) модернизируемых ОС истек (выработан). Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок (объем наработки) или приостановить начисление амортизации в управленческом учете.';
										|en = 'Useful life (planned asset activity value) of renovated fixed assets has expired (generated). Register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in management accounting.'; fa = 'Useful life (planned asset activity value) of renovated fixed assets has expired (generated). Register a document ""Adjust fixed asset financial details"" and indicate a new due date (asset activity value) or suspend depreciation charge in management accounting.';
										|it = 'Il periodo di vita utile (volume di produzione stimato) dei Capitali fissi soggetti all''ammodernamento è terminato (esaurito). È necessario generare il documento ""Modifica dei parametri di Capitale fisso"" e indicare un nuovo termine di scadenza (volume di produzione) oppure sospendere il calcolo dell''ammortamento in contabilità gestionale.';
										|pl = 'Okres używania (planowana objętość czasu pracy) modernizowanych ŚT wygasł (została wyrobiona). Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres (objętość czasu pracy) lub wstrzymać naliczenie amortyzacji w ewidencji zarządczej.';
										|tr = 'Modernize edilmiş sabit kıymetlerin kullanım süresi (planlanan çalışma hacmi) sona ermiştir (tükenmiştir). "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve yeni bir süre (çalışma hacmi) belirlemek veya yönetim muhasebesinde amortisman tahakkukunu askıya almak gereklidir.'");
			ElsIf Selection.ThereIsOperatingTime Then
				TextUsageExpired = NStr("vi = 'Thời gian hoạt động ước tính của TSCĐ nâng cấp được phát triển đầy đủ. Cần phải lập một chứng từ Thay đổi thông số TSCĐ và tăng thời gian hoạt động ước tính hoặc tạm ngưng khấu hao.';
										|ru = 'Предполагаемый объем наработки модернизируемых ОС полностью выработан. Необходимо оформить документ ""Изменение параметров ОС"" и увеличить предполагаемый объем наработки или приостановить начисление амортизации.';
										|en = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.'; fa = 'Estimated asset activity value of modernized fixed assets is fully generated. Register a document ""Adjust fixed asset financial details"" and increase the estimated asset activity value or suspend depreciation accrual.';
										|it = 'Il volume di produzione stimato di Capitali fissi soggetti all''ammodernamento è esaurito. È necessario generare il documento ""Modifica di Capitale fisso"" e aumentare il volume di produzione stimato o sospendere il calcolo dell''ammortamento.';
										|pl = 'Przewidywana objętość czasu pracy modernizowanych ŚT została w całościa wypracowana. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i zwiększyć przewidywaną objętość wypracowania lub wstrzymać naliczenie amortyzacji.';
										|tr = 'Modernize edilen sabit kıymetlerin tahmini çalışma hacmi tamamen tükenmiştir. "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve tahmini çalışma hacmini artırmak veya amortismanı askıya almak gereklidir.'");
			Else
				TextUsageExpired = NStr("vi = 'Thời hạn sử dụng của TSCĐ nâng cấp đã hết hạn. Cần thiết phải lập một chứng từ Thay đổi trong các thông số TSCĐ và chỉ ra một thuật ngữ mới hoặc đình chỉ khấu hao trong kế toán quản lý.';
										|ru = 'Срок использования модернизируемых ОС истек. Необходимо оформить документ ""Изменение параметров ОС"" и указать новый срок или приостановить начисление амортизации в управленческом учете.';
										|en = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in management accounting.'; fa = 'Useful life of modernized fixed assets has expired. Register a document ""Adjust fixed asset financial details"" and indicate a new due date or suspend depreciation charge in management accounting.';
										|it = 'Il periodo di vita utile dei Capitali fissi soggetti all''ammodernamento è terminato. È necessario generare il documento ""Modifica dei parametri di Capitale fisso"" e indicare un nuovo termine di scadenza o sospendere il calcolo dell''ammodernamento in contabilità gestionale.';
										|pl = 'Okres używania modernizowanych ŚT wygasł. Należy utworzyć dokument ""Zmiana parametrów ŚT"" i podać nowy okres lub wstrzymać naliczenie amortyzacji w ewidencji zarządczej.';
										|tr = 'Modernize edilen sabit kıymetin kullanım süresi sona ermiştir. "" Sabit Kıymet Parametrelerinin Değiştirilmesi"" belgesini yürütmek ve yeni bir dönem belirlemek veya yönetim muhasebesinde amortisman tahakkukunu askıya almak gereklidir.'");
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Return TextUsageExpired;
	
EndFunction

&AtServer
Procedure InitializeServiceParametersOfForm()

	NewServiceParametersOfForm = New Structure;
	
	ListOfDetailsForSavingValueBeforeChangingIt = "";
	NewServiceParametersOfForm.Insert("ListOfDetailsForSavingValueBeforeChangingIt", ListOfDetailsForSavingValueBeforeChangingIt);
	NewServiceParametersOfForm.Insert("PresentationOfDetails", Documents.FixedAssetsCostAdditions2_4.PresentationOfDetails(Object.Organization, Object.Date));
	NewServiceParametersOfForm.Insert("ThereIsCostAccounting", False);
	
	FixedAssetsCostAdditionsLocalization.FillInServiceParameters(NewServiceParametersOfForm);
	
	FormServiceParameters = New FixedStructure(NewServiceParametersOfForm);
	
EndProcedure

&AtClient
Procedure FillInValuesOfFADetailsBeforeChange()

	AttributesValuesBeforeChange = New Structure;
	AttributesValuesBeforeChange.Insert("CostInManagementAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInAccounting", 0);
	AttributesValuesBeforeChange.Insert("CostInTaxAccounting", 0);
	
	CurrentData = Items.FA.CurrentData;
	If CurrentData <> Undefined Then
		FillPropertyValues(AttributesValuesBeforeChange, CurrentData);
	EndIf;
	
	FAAttributeValuesBeforeChange = New FixedStructure(AttributesValuesBeforeChange);

EndProcedure

&AtServer
Procedure FillInHeaderForSelectedFA()

	ChangedBankingDetails = "";
	NonCurrentAssetsInternal.FillInHeaderForSelectedFA(
		"Organization,Department", 
		Object.FA, 
		Object, 
		ChangedBankingDetails);
	
	ConfigureDependentFormElementsOnServer(ChangedBankingDetails);
	
EndProcedure

&AtServerNoContext
Function InscriptionDepreciationAdjustment(Val Ref)
	
	Return Documents.FixedAssetCostAndDepreciationAdjustment.TextOfDepreciationAdjustmentLabel(Ref);
		
EndFunction

&AtClient
Procedure CreateAdjustmentCompletion(QuestionResult, AdditionalParameters) Export
	
	If Not ValueIsFilled(Object.Ref)
		Or Modified Then
		
		If QuestionResult <> DialogReturnCode.Yes Then
			Return;
		EndIf;
		
		WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
		If Not Write(WriteParameters) Then
			Return;
		EndIf;
		
	EndIf;
	
	FormParameters = New Structure("Basis", Object.Ref);
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.Form.DocumentForm", FormParameters);
	
EndProcedure

&AtClient
Procedure Attachable_OnExecuteCommandCompletion(CommandName, AdditionalParameters) Export

	If AdditionalParameters.ServerCallRequired_ Then
		WhenExecutingEndCommandOnServer(CommandName, AdditionalParameters);
		Return;
	EndIf;
	
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

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
