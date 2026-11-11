
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetTextOfDynamicListQueries();
	
	RestoreSettings();
	
	SetUpFormOnServer();
	
	#Region StandardMechanisms
	
	AdditionalParameters = New Structure("LocationOfLocalValidationData", Items.ListOfDocumentsGroupLocalVerification);
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing, AdditionalParameters);
	
	// StandardSubsystems.AttachableCommands
	DocumentTypesUsed = New Array;
	For Each OperationDescription In BusinessTransactionsAndDocuments Do
		DocumentTypesUsed.Add(Type("DocumentRef." + StrSplit(OperationDescription.FullDocumentName, ".")[1]));
	EndDo;

	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.Sources = New TypeDescription(DocumentTypesUsed);
	PlacementParameters.CommandBar = Items.ListDocumentsCommandBar;
	PlacementParameters.GroupsPrefix = "ListDocuments";
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	#EndRegion
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "WritingDocumentToFALog" Then
		UpdateDataWhenFormBecomesActive();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterPeriodOnChange(Item)

	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterFixedAssetOnChange(Item)
	
	StartUpdatingList();
	
EndProcedure

&AtClient
Procedure FilterOrganizationOnChange(Item)
	
	StartUpdatingList();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)

	CurrentData = Items.List.CurrentData;

	If CurrentData <> Undefined Then
		TextInformation = StringFunctionsClient.FormattedString(CurrentData.Information);
	Else
		TextInformation = New FormattedString(DefaultInformation());
	EndIf;
	
EndProcedure

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListFixedAsset
		Or Field = Items.ListFixedAssetCode
		Or Field = Items.ListFixedAssetAssetID Then
		
		ShowValue(, CurrentData.FixedAsset);

	ElsIf Field = Items.ListRecognitionPresentation Then
		
		ShowOrCreateDocument(CurrentData, "FixedAssetsInitialRecognition2_4");
		
	ElsIf Field = Items.ListChangingParametersPresentation Then
		
		ShowOrCreateDocument(CurrentData, "ChangeFixedAssetFinancialDetails2_4");
		
	ElsIf Field = Items.ListWriteOffPresentation Then
		
		ShowOrCreateDocument(CurrentData, "DisposeFixedAssets2_4");
		
	ElsIf Field = Items.ListAdjustingPresentation Then
		
		ShowOrCreateDocument(CurrentData, "FixedAssetCostAndDepreciationAdjustment");
		
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListDocuments

&AtClient
Procedure ListDocumentsOnActivateRow(Item)
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

&AtClient
Procedure ListDocumentsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	Cancel = True;
	If Items.ListDocumentsGroupCreateGenerated.ChildItems.Count() <> 0 Then 
		If Copy Then
			TMCommonUseClient.CopyItem(Item);
		ElsIf FilterDocumentTypes.Count() = 1 And FilterBusinessTransactions.Count() = 1 Then 
			TeamStructure_ = New Structure("Name", Items.ListDocumentsGroupCreateGenerated.ChildItems[0].Name);
			Attachable_CreateDocument(TeamStructure_);
		Else
			Attachable_CreateDocumentViaSelectionForm(Undefined);
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	TMCommonUseClient.ChangeElement(Item);
	
EndProcedure

&AtClient
Procedure ListDocumentsBeforeDeleteRow(Item, Cancel)
	
	Cancel = True;
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Item, Title, CompletionHandler);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure CreateAcceptanceForAccounting(Command)

	CurrentData = Items.List.CurrentData;
	
	FormParameters = DocumentFormParameters(CurrentData);
	OpenForm("Document.FixedAssetsInitialRecognition2_4.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure CreateParameterChange(Command)

	CurrentData = Items.List.CurrentData;
	
	FormParameters = DocumentFormParameters(CurrentData);
	OpenForm("Document.ChangeFixedAssetFinancialDetails2_4.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure CreateCostAndDepreciationAdjustments(Command)

	CurrentData = Items.List.CurrentData;
	
	FormParameters = DocumentFormParameters(CurrentData);
	OpenForm("Document.FixedAssetCostAndDepreciationAdjustment.ObjectForm", FormParameters);

EndProcedure

&AtClient
Procedure CreateCharge(Command)
	
	CurrentData = Items.List.CurrentData;
	
	FormParameters = DocumentFormParameters(CurrentData);
	OpenForm("Document.DisposeFixedAssets2_4.ObjectForm", FormParameters);
	
EndProcedure

//@skip-check module-empty-method
&AtClient
Procedure CreateLandTaxCalculationParameters(Command)

	
EndProcedure

//@skip-check module-empty-method
&AtClient
Procedure CreatePropertyTaxCalculationParameters(Command)

	
EndProcedure

//@skip-check module-empty-method
&AtClient
Procedure CreateParametersForCalculatingTransportTax(Command)


EndProcedure

//@skip-check module-empty-method
&AtClient
Procedure CreateDeRegistrationOfLandPlots(Command)

	
EndProcedure

//@skip-check module-empty-method
&AtClient
Procedure CreateDeRegistrationOfVehicles(Command)
	
	
EndProcedure

&AtClient
Procedure ListDocumentsCancellationOfEvent(Command)
	
	TMCommonUseClient.UndoPosting(Items.ListDocuments, Title);
	
	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure ListOfDocumentsPost(Command)
	
	TMCommonUseClient.PostDocuments(Items.ListDocuments, Title);

	TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
	NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	
EndProcedure

&AtClient
Procedure CopyDocumentsList(Command)
	
	TMCommonUseClient.CopyItem(Items.ListDocuments);
	
EndProcedure

&AtClient
Procedure DocumentsListInstallUncheckDelete(Command)
	
	CompletionHandler = New CallbackDescription("SetClearDeletionMarkCompletion", ThisObject);

	TMCommonUseClient.SetDeletionMark(Items.ListDocuments, Title, CompletionHandler);
	
EndProcedure

&AtClient
Procedure ListOfInternationalAccountingEntriesDocuments(Command)
	If Items.ListDocuments.CurrentData <> Undefined Then
		NonCurrentAssetsClient.OpenInternationalAccountingTransactions(Items.ListDocuments.CurrentData.Ref);
	EndIf; 
	Return;
	
EndProcedure

&AtClient
Procedure ShowInformation(Command)

	Items.ListShowInformation.Check = Not Items.ListShowInformation.Check;
	
	Items.InformationDecoration.Visible = Items.ListShowInformation.Check;
	Items.TextInformation.Visible = Items.ListShowInformation.Check;
	Items.DecorationBasementPicture.Visible = Items.ListShowInformation.Check;
	Items.DecorationBasementInformation.Visible = Items.ListShowInformation.Check;

EndProcedure

&AtClient
Procedure UpdateList(Command)
	
	StartUpdatingList();
	
EndProcedure

#Region AttachableCommands

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Items.ListDocuments);
EndProcedure

// End StandardSubsystems.AttachableCommands

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure UpdateDataWhenFormBecomesActive()

	AttachIdleHandler("Attachable_UpdateDataWhenFormBecomesActive", 0.8, True);

EndProcedure

&AtClient
Procedure Attachable_UpdateDataWhenFormBecomesActive()
	
	If IsInputAvailable() And Items.GroupPages.CurrentPage = Items.ListPage Then
		StartUpdatingList();
	Else
		UpdateDataWhenFormBecomesActive();
	EndIf;

EndProcedure

&AtClient
Procedure StartUpdatingList()
	AttachIdleHandler("Attachable_StartUpdatingList", 0.1, True);
EndProcedure

&AtClient
Procedure Attachable_StartUpdatingList()
	
	TimeConsumingOperation = UpdateTheListOnServer();
	
	CallbackOnCompletion = New CallbackDescription("StartUpdatingListCompletion", ThisObject);
	
	IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
	IdleParameters.Title = NStr("vi = 'Cập nhật';
								|ru = 'Обновление';
								|en = 'Update'; fa = 'به‌روزرسانی';
								|it = 'Обновление';
								|pl = 'Update';
								|tr = 'Güncelleme'");
	IdleParameters.MessageText = NStr("vi = 'Đang nhận dữ liệu';
										|ru = 'Выполняется получение данных';
										|en = 'Import data'; fa = 'ورود داده';
										|it = 'Выполняется получение данных';
										|pl = 'Trwa pobieranie danych';
										|tr = 'Veri alınıyor'");
	
	TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackOnCompletion, IdleParameters);
	
EndProcedure

&AtServer
Function UpdateTheListOnServer()
	
	ShouldSaveSettings();
	
	SetDynamicListSelections_();
		
	WorkplaceParameters = New Structure;
	WorkplaceParameters.Insert("FilterPeriod", FilterPeriod);
	WorkplaceParameters.Insert("FilterFixedAsset", FilterFixedAsset);
	WorkplaceParameters.Insert("FilterOrganization", FilterOrganization);
	
	ExecutionParameters = TimeConsumingOperations.FunctionExecutionParameters(UUID);
	
	TimeConsumingOperation = TimeConsumingOperations.ExecuteFunction(
		ExecutionParameters, "DataProcessors.CorrectAccountingErrors.WorkplaceData", WorkplaceParameters);
	
	Return TimeConsumingOperation;
	
EndFunction

&AtClient
Procedure StartUpdatingListCompletion(Result, AdditionalParameters) Export

	UpdatingEndListOnServer(Result);
	
EndProcedure

&AtServer
Procedure UpdatingEndListOnServer(Val Result)

	CurrentRow = Items.List.CurrentRow;
	If CurrentRow <> Undefined Then
		RowData = List.FindByID(CurrentRow);
		CurrentRowData = New Structure("FixedAsset");
		FillPropertyValues(CurrentRowData, RowData);
	Else
		CurrentRowData = Undefined;
	EndIf;
	
	If Result = Undefined Then
		List.Clear();
		NumberOfRowsList = 0;
		Return;
	EndIf;
	
	If Result.Status = "Error" Then
		Raise Result.BriefErrorDescription;
	EndIf;
	
	WorkplaceData = GetFromTempStorage(Result.ResultAddress);
	If WorkplaceData = Undefined Then
		Return;
	EndIf;
	
	List.Load(WorkplaceData.ListData);
	
	NumberOfRowsList = List.Count();
	
	If CurrentRowData <> Undefined Then
		SearchResult = List.FindRows(CurrentRowData);
		If SearchResult.Count() <> 0 Then
			Items.List.CurrentRow = SearchResult[0].GetID();
		EndIf;
	EndIf;
	
	DeleteFromTempStorage(Result.ResultAddress);
	StorageAddress = PutToTempStorage(WorkplaceData.DocumentsData, UUID);
	
EndProcedure

&AtServer
Procedure RestoreSettings()
	
	FilterPeriod.Variant = StandardPeriodVariant.ThisMonth;
	
	Settings = Common.CommonSettingsStorageLoad(
		Metadata.DataProcessors.CorrectAccountingErrors.FullName(), 
		PurposeUseKey);
	
	If TypeOf(Settings) <> Type("Structure") Then
		Return
	EndIf;
	
	FilterPeriod = Settings.FilterPeriod;
	FilterFixedAsset = Settings.FilterFixedAsset;
	FilterOrganization = Settings.FilterOrganization;
	
EndProcedure

&AtServer
Procedure ShouldSaveSettings()
	
	AttributesToSaveNames = "FilterPeriod,FilterFixedAsset,FilterOrganization";
	
	Settings = New Structure(AttributesToSaveNames);
	FillPropertyValues(Settings, ThisObject);
	
	Common.CommonSettingsStorageSave(
		Metadata.DataProcessors.CorrectAccountingErrors.FullName(), 
		PurposeUseKey, 
		Settings);
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
		
	StandardSubsystemsServer.SetDateFieldConditionalAppearance(ThisObject, "ListDocuments.Date", "ListDocumentsDate");
		
	#Region ListOfAcceptancePresentation_TextColor
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListRecognitionPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListChangingParametersPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListWriteOffPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListAdjustingPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListTaxCalculationParametersPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListDeRegistrationPresentation.Name);
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListRecalculatePropertyTaxesPresentation.Name);
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	
	#EndRegion

	#Region ListOfAcceptanceForAccountingPresentation_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListRecognitionPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.RecognitionPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Создать';
													|pl = 'Create';
													|tr = 'Oluştur'"));
	
	#EndRegion

	#Region ListOfParameterChangesPresentation_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListChangingParametersPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ChangingParametersPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Создать';
													|pl = 'Create';
													|tr = 'Oluştur'"));
	
	#EndRegion
	
	#Region ListOfWriteOffPresentation_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListWriteOffPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.WriteOffPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Создать';
													|pl = 'Create';
													|tr = 'Oluştur'"));
	
	#EndRegion
	
	#Region ListAdjustmentPresentation_Text
	
	Item = ConditionalAppearance.Items.Add();
	
	DataCompositionClientServer.AddFieldToCreate(Item.Fields, Items.ListAdjustingPresentation.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.AdjustingPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.HyperlinkColor);
	Item.Appearance.SetParameterValue("Text", NStr("vi = 'Tạo mới';
													|ru = 'Создать';
													|en = 'Create'; fa = 'ایجاد';
													|it = 'Создать';
													|pl = 'Create';
													|tr = 'Oluştur'"));
	
	#EndRegion
	
	
EndProcedure

&AtServer
Procedure ConfigureRightsForm()

	UseLocal = GetFunctionalOption("UseLocal");
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetsInitialRecognition2_4) Then
		Items.CreateAcceptanceForAccounting.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.ChangeFixedAssetFinancialDetails2_4) Then
		Items.CreateParameterChange.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.FixedAssetCostAndDepreciationAdjustment) Then
		Items.CreateCostAndDepreciationAdjustments.Visible = False;
	EndIf;
	
	If Not AccessRight("InteractiveInsert", Metadata.Documents.DisposeFixedAssets2_4) Then
		Items.CreateCharge.Visible = False;
	EndIf;
	
	
	If Not AccessRight("View", Metadata.DataProcessors.DocumentPostingInFinancialAccounting.Commands.AccountingEntries) Then
		Items.ListOfInternationalAccountingEntriesDocuments.Visible = False;
	EndIf;
EndProcedure

&AtClient
Procedure ShowOrCreateDocument(CurrentData, DocumentName)
	
	If CurrentData = Undefined Then
		Return;
	EndIf;

	FADocumentData = FADocumentData(CurrentData.FixedAsset, StorageAddress); // Structure
	
	If FADocumentData <> Undefined
		And FADocumentData.Property(DocumentName) Then
	
		DocumentsList = FADocumentData[DocumentName];
		
		If DocumentsList.Count() = 1 Then
			
			ShowValue(, DocumentsList[0].DocumentRef);
		
		Else
			
			ChoiceList = New ValueList();
			For Each LineDocument In DocumentsList Do
				ChoiceList.Add(LineDocument.DocumentRef);
			EndDo;
			
			ChoiceNotification1 = New CallbackDescription("DocumentSelectionCompletion", ThisObject);
			ChoiceList.ShowChooseItem(ChoiceNotification1);
			
		EndIf;
		
	Else
		
		FormParameters = New Structure;
		BasisParameters = New Structure;
		BasisParameters.Insert("FixedAsset", CurrentData.FixedAsset);
		BasisParameters.Insert("AdjustmentModeFromPreviousDate", True);
		FormParameters.Insert("Basis", BasisParameters);
		
		If DocumentName = "TaxAccrualParameters" Then
			
			
		ElsIf DocumentName = "DeRegistration" Then
			
			
		Else
			OpenForm("Document" + "." + DocumentName + "." + "ObjectForm", FormParameters);
		EndIf;
		
	EndIf;
	
EndProcedure

&AtServerNoContext
Function FADocumentData(Val FixedAsset, Val StorageAddress)
	
	DocumentsData = GetFromTempStorage(StorageAddress); // Map
	If DocumentsData = Undefined Then
		Return Undefined;
	EndIf;
	
	FADocumentData = DocumentsData.Get(FixedAsset);
	
	Return FADocumentData;
	
EndFunction

&AtClient
Procedure DocumentSelectionCompletion(SelectedElement, AdditionalParameters) Export
	
	If SelectedElement <> Undefined Then
		ShowValue(, SelectedElement.Value);
	EndIf;
	
EndProcedure

&AtClient
Function DocumentFormParameters(CurrentData)
	
	FormParameters = New Structure;
	
	BasisParameters = New Structure;
	BasisParameters.Insert("AdjustmentModeFromPreviousDate", True);
	
	If CurrentData <> Undefined Then
		
		BasisParameters.Insert("FixedAsset", CurrentData.FixedAsset);
	
	Else
		
		If ValueIsFilled(FilterOrganization) Then
			BasisParameters.Insert("Organization", FilterOrganization);
		EndIf;
		
		If ValueIsFilled(FilterFixedAsset) Then
			BasisParameters.Insert("FixedAsset", FilterFixedAsset);
		EndIf;
		
	EndIf;
	
	FormParameters.Insert("Basis", BasisParameters);
	
	Return FormParameters;
	
EndFunction

&AtServerNoContext
Function InitializeBusinessTransactionsAndDocuments(BusinessTransactionsAndDocuments, FilterBusinessTransactions, FilterDocumentTypes, PurposeUseKey, UnregisteredDocuments = False)
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetsInitialRecognition;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.RecognitionOfLeaseItems;
	String.FullDocumentName			= Metadata.Documents.FixedAssetsInitialRecognition2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.ChangeFixedAssetFinancialDetails;
	String.FullDocumentName			= Metadata.Documents.ChangeFixedAssetFinancialDetails2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.FixedAssetCostAndDepreciationAdjustment;
	String.FullDocumentName			= Metadata.Documents.FixedAssetCostAndDepreciationAdjustment.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;

	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.DisposeFixedAssets;
	String.FullDocumentName			= Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	String = BusinessTransactionsAndDocuments.Add();
	String.BusinessOperation 		= Enums.BusinessTransactions.WriteOffSubAssetsComponentsOfDepreciation;
	String.FullDocumentName			= Metadata.Documents.DisposeFixedAssets2_4.FullName();
	String.PurposeUseKey 	= PurposeUseKey;
	String.AddButtonCreate        = True;
	
	
	TableOfValuesAvailable = TMCommonUse.AvailableBusinessTransactionsAndDocuments(
								BusinessTransactionsAndDocuments, 
								FilterBusinessTransactions, 
								FilterDocumentTypes, 
								PurposeUseKey);
	
	Return TableOfValuesAvailable;
		
EndFunction

&AtServer
Procedure SetTextOfDynamicListQueries()

	QueryText = 
	"SELECT
	|	FixedAssetsDocumentsOverridable.FixedAsset,
	|	FixedAssetsDocumentsOverridable.Ref,
	|	FixedAssetsDocumentsOverridable.Organization,
	|	FixedAssetsDocumentsOverridable.Date AS Date,
	|	FixedAssetsDocumentsOverridable.CorrectionPeriodStart AS CorrectionPeriodStart,
	|	FixedAssetsDocumentsOverridable.CorrectionPeriodEnd AS CorrectionPeriodEnd,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	FixedAssetsDocumentsOverridable.BusinessOperation,
	|	FixedAssetsDocumentsOverridable.Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible,
	|	DocumentsRegistryOverridable.More,
	|	DocumentsRegistryOverridable.Comment,
	|	FixedAssetsDocumentsOverridable.Posted,
	|	DocumentsRegistryOverridable.DeletionMark,
	|
	|	CASE
	|		WHEN FixedAssetsDocumentsOverridable.Posted
	|			THEN 0
	|		WHEN DocumentsRegistryOverridable.DeletionMark
	|			THEN 1
	|		ELSE 2
	|	END AS CustomPicture,
	|
	|	FixedAssetsDocumentsOverridable.AdditionalRecord,
	|	DocumentsRegistryOverridable.AdditionalRecord AS AdditionalEntryRegistry,
	|	FixedAssetsDocumentsOverridable.RefType,
	|	VALUETYPE(FixedAssetsDocumentsOverridable.Ref) AS TheTypeOfReferenceDocument,
	|	&CheckStatus AS CheckStatus,
	|	CAST(&CheckingIndicator AS BOOLEAN) AS CheckingIndicator,
	|
	|	CASE
	|		WHEN FilesExistOverridable.HasFiles IS NULL
	|			THEN 0
	|		WHEN FilesExistOverridable.HasFiles
	|			THEN 1
	|		ELSE 0
	|	END AS HasFiles
	|FROM
	|	InformationRegister.FixedAssetsDocuments AS FixedAssetsDocumentsOverridable
	|
	|		LEFT JOIN InformationRegister.DocumentsRegistry AS DocumentsRegistryOverridable
	|		ON (DocumentsRegistryOverridable.Ref = FixedAssetsDocumentsOverridable.Ref)
	|			AND (NOT DocumentsRegistryOverridable.AdditionalRecord)
	|
	|		LEFT JOIN InformationRegister.FilesExist AS FilesExistOverridable
	|		ON FixedAssetsDocumentsOverridable.Ref = FilesExistOverridable.ObjectWithFiles
	|		
	|WHERE
	|
	|	FixedAssetsDocumentsOverridable.IsPatch
	|	
	|{WHERE
	|	FixedAssetsDocumentsOverridable.FixedAsset.* AS FixedAsset,
	|	FixedAssetsDocumentsOverridable.Ref.* AS Ref,
	|	FixedAssetsDocumentsOverridable.Organization.* AS Organization,
	|	FixedAssetsDocumentsOverridable.Date AS Date,
	|	DocumentsRegistryOverridable.IBDocumentNumber AS Number,
	|	FixedAssetsDocumentsOverridable.BusinessOperation AS BusinessOperation,
	|	FixedAssetsDocumentsOverridable.Department.* AS Department,
	|	DocumentsRegistryOverridable.EmployeeResponsible.* AS EmployeeResponsible,
	|	DocumentsRegistryOverridable.More AS More,
	|	DocumentsRegistryOverridable.Comment AS Comment,
	|	FixedAssetsDocumentsOverridable.Posted AS Posted,
	|	DocumentsRegistryOverridable.DeletionMark AS DeletionMark,
	|
	|	(FixedAssetsDocumentsOverridable.Date BETWEEN &BeginOfPeriod AND &EndOfPeriod
	|		OR &EndOfPeriod = DATETIME(1, 1, 1)
	|			AND FixedAssetsDocumentsOverridable.Date >= &BeginOfPeriod)}";
	
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText = QueryText;
	Common.SetDynamicListProperties(Items.ListDocuments, ListProperties);
	
EndProcedure

&AtServer
Procedure SetUpListOfDocuments()

	TableOfValuesAvailable = InitializeBusinessTransactionsAndDocuments(
		BusinessTransactionsAndDocuments.Unload(),
		FilterBusinessTransactions,
		FilterDocumentTypes,
		SettingsKey);
	
	BusinessTransactionsAndDocuments.Load(TableOfValuesAvailable);
	
	TMCommonUse.WorkplaceData(
		BusinessTransactionsAndDocuments.Unload(), 
		DefaultFormAssignmentKey(), 
		NStr("vi = 'tất cả';
			|ru = 'все';
			|en = 'all'; fa = 'همه';
			|it = 'все';
			|pl = 'all';
			|tr = 'tümü'"));
	
	TMCommonUse.ReplaceLinkFieldWithExpressByDocumentTypeConstruct(Items.ListDocuments, BusinessTransactionsAndDocuments);

	ParametersStructure = TMCommonUse.StructureOfSettingsForDocumentManagementButtons();
	ParametersStructure.Form = ThisObject;
	ParametersStructure.NameOfCreateGroup = "ListDocumentsGroupCreateGenerated";
	ParametersStructure.GroupNameCreateContext = "ListDocumentsGroupCreateGeneratedContext";
	ParametersStructure.NameOfCopyButton = "CopyDocumentsList";
	ParametersStructure.NameOfCopyContextMenuButton = "ListDocumentsCopyContext";
	ParametersStructure.ChangeButtonName = "ListDocumentsChange";
	ParametersStructure.NameOfChangeContextMenuButton = "DocumentsListChangeContext";
	ParametersStructure.ButtonNamePost = "ListOfDocumentsPost";
	ParametersStructure.NameOfHoldContextMenuButton = "ListDocumentsHoldContext";
	ParametersStructure.NameOfCancelEventButton = "ListDocumentsCancellationOfEvent";
	ParametersStructure.NameOfCancelButtonIsContextMenu = "ListDocumentsCancellationContext";
	ParametersStructure.NameOfMarkDeleteButton = "ListDocumentsSetDeleteMark";
	ParametersStructure.ButtonNameMarkDeleteContextMenu = "ListDocumentsSetDeleteContextTag";
	
	TMCommonUse.ConfigureDocumentManagementButtons(ParametersStructure);
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocument(Command)
	
	TMCommonUseClient.CreateDocumentUsingCommand(Command.Name, SelectionsForCreatingDocument());
	
EndProcedure

&AtClient
Procedure Attachable_CreateDocumentViaSelectionForm(Command)
	
	FormKey = DefaultFormAssignmentKey();
	AddressBusinessTransactionsAndDocuments = PlaceBusinessTransactionsAndDocumentsInTemporaryStorage();
	TMCommonUseClient.CreateDocumentViaSelectionForm(AddressBusinessTransactionsAndDocuments,
		FormKey, PurposeUseKey, SelectionsForCreatingDocument());
		
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.ListDocuments);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Items.List);
EndProcedure

&AtClient
Function SelectionsForCreatingDocument()
	
	StructureSelections = New Structure;
	StructureSelections.Insert("AdjustmentModeFromPreviousDate", True);
	
	If ValueIsFilled(FilterOrganization) Then
		StructureSelections.Insert("Organization", FilterOrganization);
	EndIf;
	
	If ValueIsFilled(FilterFixedAsset) Then
		StructureSelections.Insert("FixedAsset", FilterFixedAsset);
	EndIf;
	
	Return StructureSelections;
	
EndFunction

&AtServer
Function PlaceBusinessTransactionsAndDocumentsInTemporaryStorage()
	Return PutToTempStorage(BusinessTransactionsAndDocuments.Unload(), UUID);
EndFunction

&AtServer
Procedure SetDynamicListSelections_()
	
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"BusinessOperation",
		FilterBusinessTransactions,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"RefType",
		FilterDocumentTypes,
		DataCompositionComparisonType.InList,
		,
		True);

	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"Organization",
		FilterOrganization,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"AdditionalRecord",
		False,
		DataCompositionComparisonType.Equal,
		,
		Not ValueIsFilled(FilterOrganization));
		
	CommonClientServer.SetDynamicListFilterItem(
		ListDocuments,
		"FixedAsset",
		FilterFixedAsset,
		DataCompositionComparisonType.Equal,
		,
		ValueIsFilled(FilterFixedAsset));
		
	ListDocuments.Parameters.SetParameterValue("BeginOfPeriod", FilterPeriod.StartDate);
	
	ListDocuments.Parameters.SetParameterValue("EndOfPeriod", 
		?(ValueIsFilled(FilterPeriod.EndDate),
			EndOfDay(FilterPeriod.EndDate),
			EndOfDay(Date(3999, 12, 31))));
			
EndProcedure

&AtServer
Procedure SetUpFormOnServer()
	
	StyleNameSlantedFont = Metadata.StyleItems.ItalicFontEM.Name;

	ConfigureRightsForm();
	SetUpListOfDocuments();
	
	If Parameters.Property("Filter") Then
		
		Parameters.Filter.Property("Period", FilterPeriod);
		Parameters.Filter.Property("FixedAsset", FilterFixedAsset);
		Parameters.Filter.Property("Organization", FilterOrganization);
		
	EndIf;

	
	If Not GetFunctionalOption("UseLocal") Then
		Items.ListTaxCalculationParametersPresentation.Visible = False;
		Items.ListDeRegistrationPresentation.Visible = False;
		Items.ListRecalculatePropertyTaxesPresentation.Visible = False;
	EndIf;
	
	If GetFunctionalOption("LocalFAAccounting") Then

		//@skip-check module-nstr-camelcase
		Text = StrTemplate(NStr("vi = 'Sửa lỗi khi hạch toán được thực hiện theo nhiều bước:<b>
							   |1. Sửa lỗi dữ liệu kế toán</b>
							   |Để thực hiện việc này, tạo chứng từ tương ứng, trong đó chỉ định dữ liệu đúng, chọn chế độ <span style=""font:%1"">Tham số có hiệu lực từ ngày trước</span>.
							   |Ví dụ: nếu khi tiếp nhận vào kế toán có chỉ định sai thời hạn sử dụng, thì cần thay đổi tham số, chỉ định thời hạn đúng, chọn chế độ <span style=""font:%1"">Tham số có hiệu lực từ ngày trước đó</span> và chỉ định ngày bắt đầu thay đổi thời hạn.<b>
							   |2. Điều chỉnh giá trị hoặc khấu hao</b>
							   |Nếu thời hạn sử dụng sai dẫn đến tính khấu hao sai, thì cần tạo điều chỉnh giá trị và khấu hao, chỉ định rằng, chỉ điều chỉnh khấu hao, chọn chế độ <span style=""font:%1"">Điều chỉnh từ ngày trước</span>, thông qua thẻ <span style=""font:%1"">Tham số kế toán</span> tính khấu hao và chỉ định số tiền cần thiết trên thẻ <span style=""font:%1"">Основные средства</span>.<b>
							   |3. Tính lại thuế tài sản</b>
							   |Sau khi sửa dữ liệu hạch toán và điều chỉnh giá trị hoặc khấu hao, có thể yêu cầu tính thêm tiền thuế hoặc đối trừ khoản nộp thừa, do đó tạo chứng từ <span style=""font:%1"">Tính lại thuế tài sản</span>.
							   |Thông qua chứng từ này, có thể tính số tiền thuế bao gồm những phần sửa lỗi đã thực hiện và xác định số tiền tính thêm hoặc hoàn trả.';
							   |ru = 'Исправление ошибок в учете выполняется в несколько этапов:<b>
							   |1. Исправить учетные данные</b>
							   |Для этого создается соответствующий документ, в котором указываются правильные данные, выбирается режим <span style=""font:%1"">Параметры действуют с прошлой даты</span>.
							   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров, указать правильный срок, выбрать режим <span style=""font:%1"">Параметры действуют с прошлой даты</span> и указать с какой даты должен был измениться срок.<b>
							   |2. Скорректировать стоимость или амортизацию</b>
							   |Если неправильный срок использования привел к неправильному расчету амортизации, то требуется создать корректировку стоимости и амортизации, указать, что корректируется только амортизация, выбирать режим <span style=""font:%1"">Корректировка с прошлой даты</span>, с помощью закладки <span style=""font:%1"">Параметры учета</span> рассчитать амортизацию и указать нужные суммы на закладке <span style=""font:%1"">Основные средства</span>.<b>
							   |3. Пересчитать имущественные налоги</b>
							   |После исправления учетных данных и корректировки стоимости или амортизации может потребоваться доначислить налог или зачесть переплату, для этого создается документ <span style=""font:%1"">Перерасчет имущественных налогов</span>.
							   |С помощью документа можно рассчитать сумму налога с учетом сделанных исправлений и определить сумму для доначисления или возмещения.';
							   |en = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |For that, create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.<b>
							   |3. Recalculate property taxes</b>
							   |After correcting the accounting data and adjusting the cost or depreciation, you might need to charge the tax additionally or offset the overpayment. To do this, create the <span style=""font:%1"">Recalculate property taxes</span> document.
							   |It calculates the tax amount considering the corrections and defines the amount for additional charge or compensation.'; fa = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |For that, create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.<b>
							   |3. Recalculate property taxes</b>
							   |After correcting the accounting data and adjusting the cost or depreciation, you might need to charge the tax additionally or offset the overpayment. To do this, create the <span style=""font:%1"">Recalculate property taxes</span> document.
							   |It calculates the tax amount considering the corrections and defines the amount for additional charge or compensation.';
							   |it = 'Исправление ошибок в учете выполняется в несколько этапов:<b>
							   |1. Исправить учетные данные</b>
							   |Для этого создается соответствующий документ, в котором указываются правильные данные, выбирается режим <span style=""font:%1"">Параметры действуют с прошлой даты</span>.
							   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров, указать правильный срок, выбрать режим <span style=""font:%1"">Параметры действуют с прошлой даты</span> и указать с какой даты должен был измениться срок.<b>
							   |2. Скорректировать стоимость или амортизацию</b>
							   |Если неправильный срок использования привел к неправильному расчету амортизации, то требуется создать корректировку стоимости и амортизации, указать, что корректируется только амортизация, выбирать режим <span style=""font:%1"">Корректировка с прошлой даты</span>, с помощью закладки <span style=""font:%1"">Параметры учета</span> рассчитать амортизацию и указать нужные суммы на закладке <span style=""font:%1"">Основные средства</span>.<b>
							   |3. Пересчитать имущественные налоги</b>
							   |После исправления учетных данных и корректировки стоимости или амортизации может потребоваться доначислить налог или зачесть переплату, для этого создается документ <span style=""font:%1"">Перерасчет имущественных налогов</span>.
							   |С помощью документа можно рассчитать сумму налога с учетом сделанных исправлений и определить сумму для доначисления или возмещения.';
							   |pl = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |For that, create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.<b>
							   |3. Recalculate property taxes</b>
							   |After correcting the accounting data and adjusting the cost or depreciation, you might need to charge the tax additionally or offset the overpayment. To do this, create the <span style=""font:%1"">Recalculate property taxes</span> document.
							   |It calculates the tax amount considering the corrections and defines the amount for additional charge or compensation.';
							   |tr = 'Muhasebedeki hataların düzeltilmesi birkaç aşamada gerçekleştirilir:
							   |1. Doğru kimlik bilgileri
							   |Bunu yapmak için, doğru verilerin belirtildiği ilgili bir belge oluşturun ve Parametreler son tarihten itibaren geçerlidir modunu seçin. nÖrneğin, kabul ederken Hesap için yanlış bir kullanım süresi belirtilmişse, parametrelerde bir değişiklik oluşturmanız gerekir, doğru süreyi belirtin, Parametreler şu tarihten itibaren geçerlidir: son tarih modunu seçin ve dönemin hangi tarihten itibaren değişmesi gerektiğini belirtin.< b>
							   |2. Maliyeti veya amortismanı ayarlayın</b>
							   |Yanlış bir kullanım dönemi, amortismanın yanlış hesaplanmasına yol açtıysa, o zaman maliyet ve amortisman için bir düzenleme oluşturmanız, yalnızca amortismanın düzeltildiğini belirtmeniz gerekir, Önceki mod tarihine göre ayarlama, Muhasebe parametreleri sekmesini kullanarak, amortismanı hesaplayın ve gerekli tutarları Sabit kıymetler sekmesi >.
							   |3. Emlak vergilerini yeniden hesaplayın
							   |Muhasebe verilerini düzelttikten ve değer veya amortismanı ayarladıktan sonra, ek olarak vergi tahsil etmek veya fazla ödemeyi mahsup etmek gerekebilir; bir belge Yeniden hesaplama; emlak vergisi oluşturulur.
							   |С Belgeyi kullanarak, yapılan düzeltmeleri dikkate alarak vergi tutarını hesaplayabilir ve ek değerlendirme veya geri ödeme tutarını belirleyebilirsiniz.'"), 
						 StyleNameSlantedFont);
		
		Items.DecorationBasementInformation.ExtendedTooltip.Title = StringFunctions.FormattedString(Text);
		
	Else
		
		//@skip-check module-nstr-camelcase
		Text = StrTemplate(NStr("vi = 'Sửa lỗi khi hạch toán được thực hiện theo nhiều bước:<b>
							   |1. Sửa lỗi dữ liệu hạch toán</b>
							   |Để thực hiện việc này, tạo chứng từ tương ứng, trong đó chỉ định dữ liệu đúng, chọn chế độ <span style=""font:%1"">Tham số có hiệu lực từ ngày trước</span>.
							   |Ví dụ: khi tiếp nhận vào kế toán đã chỉ định thời hạn sử dụng sai, thì cần thay đổi tham số, chỉ định thời hạn đúng, chọn chế độ <span style=""font:%1"">Tham số có hiệu lực từ ngày trước</span> và chỉ định ngày nào cần bắt đầu thay đổi thời hạn.<b>
							   |2. Điều chỉnh giá trị hoặc khấu hao</b>
							   |Nếu thời hạn sử dụng sai dẫn đến tính khấu hao không chính xác, thì cần tạo điều chỉnh giá trị và khấu hao, chỉ định rằng chỉ điều chỉnh khấu hao, chọn chế độ <span style=""font:%1"">Điều chỉnh từ ngày trước</span>, thông qua thẻ <span style=""font:%1"">Tham số kế toán</span> tính khấu hao và chỉ định số tiền cần thiết trên thẻ <span style=""font:%1"">Tài sản cố định hữu hình</span>.';
							   |ru = 'Исправление ошибок в учете выполняется в несколько этапов:<b>
							   |1. Исправить учетные данные</b>
							   |Для этого создается соответствующий документ, в котором указываются правильные данные, выбирается режим <span style=""font:%1"">Параметры действуют с прошлой даты</span>.
							   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров, указать правильный срок, выбрать режим <span style=""font:%1"">Параметры действуют с прошлой даты</span> и указать с какой даты должен был измениться срок.<b>
							   |2. Скорректировать стоимость или амортизацию</b>
							   |Если неправильный срок использования привел к неправильному расчету амортизации, то требуется создать корректировку стоимости и амортизации, указать, что корректируется только амортизация, выбирать режим <span style=""font:%1"">Корректировка с прошлой даты</span>, с помощью закладки <span style=""font:%1"">Параметры учета</span> рассчитать амортизацию и указать нужные суммы на закладке <span style=""font:%1"">Основные средства</span>.';
							   |en = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |Create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.'; fa = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |Create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.';
							   |it = 'Исправление ошибок в учете выполняется в несколько этапов:<b>
							   |1. Исправить учетные данные</b>
							   |Для этого создается соответствующий документ, в котором указываются правильные данные, выбирается режим <span style=""font:%1"">Параметры действуют с прошлой даты</span>.
							   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров, указать правильный срок, выбрать режим <span style=""font:%1"">Параметры действуют с прошлой даты</span> и указать с какой даты должен был измениться срок.<b>
							   |2. Скорректировать стоимость или амортизацию</b>
							   |Если неправильный срок использования привел к неправильному расчету амортизации, то требуется создать корректировку стоимости и амортизации, указать, что корректируется только амортизация, выбирать режим <span style=""font:%1"">Корректировка с прошлой даты</span>, с помощью закладки <span style=""font:%1"">Параметры учета</span> рассчитать амортизацию и указать нужные суммы на закладке <span style=""font:%1"">Основные средства</span>.';
							   |pl = 'To correct accounting errors:<b>
							   |1. Correct the accounting data</b>
							   |Create a corresponding document, specify the correct data, and select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode.
							   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment, specify the correct value, select the <span style=""font:%1"">Financial details are valid from the previous date</span> mode, and specify the date from which the useful life was supposed to change.<b>
							   |2. Adjust the cost or depreciation</b>
							   |If the incorrect useful life value lead to the incorrect depreciation calculation, create the cost and depreciation adjustment, specify that only the depreciation is being adjusted, select the <span style=""font:%1"">Adjustment from previous date</span> mode, calculate the depreciation on the <span style=""font:%1"">Accounting parameters</span> tab, and specify the required amount on the <span style=""font:%1"">Fixed assets</span> tab.';
							   |tr = 'Muhasebedeki hataların düzeltilmesi birkaç aşamada gerçekleştirilir:
							   |1. Doğru kimlik bilgileri
							   |Bunu yapmak için, doğru verilerin belirtildiği ilgili bir belge oluşturun ve Parametreler son tarihten itibaren geçerlidir modunu seçin. nÖrneğin, kabul ederken Hesap için yanlış bir kullanım süresi belirtilmişse, parametrelerde bir değişiklik oluşturmanız gerekir, doğru süreyi belirtin, Parametreler şu tarihten itibaren geçerlidir: son tarih modunu seçin ve dönemin hangi tarihten itibaren değişmesi gerektiğini belirtin.< b>
							   |2. Maliyeti veya amortismanı ayarlayın</b>
							   |Yanlış bir kullanım dönemi, amortismanın yanlış hesaplanmasına yol açtıysa, o zaman maliyet ve amortisman için bir düzenleme oluşturmanız, yalnızca amortismanın düzeltildiğini belirtmeniz gerekir, Önceki mod tarihine göre ayarlama, Muhasebe parametreleri sekmesini kullanarak, amortismanı hesaplayın ve gerekli tutarları <span style=""font:%1"">üzerinde belirtin font:Sabit kıymetler sekmesi .'"),
						 StyleNameSlantedFont);
						 
		Items.DecorationBasementInformation.ExtendedTooltip.Title = StringFunctions.FormattedString(Text);
				  
	EndIf;
	
	TextInformation = New FormattedString(DefaultInformation());
	
EndProcedure

&AtClientAtServerNoContext
Function DefaultFormAssignmentKey()
	
	Return "CorrectAccountingErrors";
	
EndFunction

&AtClientAtServerNoContext
Function DefaultInformation()

	TextInformation = NStr("vi = 'Để nhận thông tin, cần chọn dòng trong danh sách.
						   |Trong danh sách hiển thị các chứng từ kết chuyển ở chế độ ""từ ngày trước"".
						   |Nếu danh sách trống thì cần tạo chứng từ tương ứng.
						   |Ví dụ: khi tiếp nhận vào kế toán, nếu đã chỉ định thời hạn sử dụng sai, thì cần thay đổi và chỉ định thời hạn đúng.';
						   |ru = 'Для получения информации необходимо выбрать строку списка.
						   |В списке отображаются документы проведенные в режиме ""с прошлой даты"".
						   |Если список пустой, то необходимо создать соответствующий документ.
						   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров и указать правильный срок.';
						   |en = 'To obtain the information, select the list line.
						   |The list contains documents posted in the ""from previous date"" mode.
						   |If the list is empty, create a corresponding document.
						   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment and specify the correct useful life.'; fa = 'To obtain the information, select the list line.
						   |The list contains documents posted in the ""from previous date"" mode.
						   |If the list is empty, create a corresponding document.
						   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment and specify the correct useful life.';
						   |it = 'Для получения информации необходимо выбрать строку списка.
						   |В списке отображаются документы проведенные в режиме ""с прошлой даты"".
						   |Если список пустой, то необходимо создать соответствующий документ.
						   |Например, если при принятии к учету был указан неправильный срок использования, то требуется создать изменение параметров и указать правильный срок.';
						   |pl = 'To obtain the information, select the list line.
						   |The list contains documents posted in the ""from previous date"" mode.
						   |If the list is empty, create a corresponding document.
						   |For example, if an incorrect useful life was specified upon recognition, create the financial details adjustment and specify the correct useful life.';
						   |tr = 'Bilgi almak için listeden bir satır seçmelisiniz.
						   |Liste, “son tarihten itibaren” modunda gönderilen belgeleri görüntüler.
						   |Liste boşsa ilgili belgeyi oluşturmanız gerekir.
						   |Örneğin, Muhasebe için kabul edilirken yanlış kullanım süresi belirtildiyse, değişiklik parametrelerini oluşturmanız ve doğru dönemi belirtmeniz gerekir.'");
						   
	Return TextInformation;
		
EndFunction

&AtClient
Procedure SetClearDeletionMarkCompletion(QuestionResult, AdditionalParameters) Export

	If QuestionResult = DialogReturnCode.Yes Then
		TMCommonUseClient.NotifyAboutEntryOfDocumentInJournal();
		NonCurrentAssetsClient.NotifyAboutDocumentEntryInFALog();
	EndIf;
	
EndProcedure

#EndRegion
