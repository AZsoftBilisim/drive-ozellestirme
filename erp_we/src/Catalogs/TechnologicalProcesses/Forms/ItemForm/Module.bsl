#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	CalculateTheCoefficientNumber = Object.CalculateFactor;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	SetSelectionInListOfOperations();
	
	// Handler of the "Properties" subsystem
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", True);
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	
	// Handler of the subsystem "Versioning of objects"
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// The end of the standard subsystem.Pluggable commands
	// Standard subsystems.Worksfiles
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	FillInThereIsAutomaticSelectionOfNomenclature();
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, New Array);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// Handler of the "Properties" subsystem
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("Write_TechnologicalProcesses",, Object.Ref);

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
	
	SetSelectionInListOfOperations();
	
	FillInServiceDetails();
	
	Items.DetailsGroup.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	CustomizeFormElements();

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	If EventName = "Write_File" Then
		
		Items.Operations.Refresh();
		
	ElsIf EventName = "CopyingLinesToClipboard" Then
		
		SetAvailabilityOfClipboardCommands(ThisObject, AttributeAvailability);
		
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And ChoiceSource.FormName = "CommonForm.ConfigureProductAutoSelection" Then
		
		ProcessingSelectionSettingUpAutomaticSelectionOfProducts(ChoiceSource.TSName, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm") 
		And ChoiceSource.FormName = "CommonForm.ConfigureFilterByPropertiesAndCalculationUsingFormulas" Then
		
		SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(ChoiceSource.TSName, ValueSelected);
		
	ElsIf ChoiceSource <> Undefined 
		And TypeOf(ChoiceSource) = Type("ClientApplicationForm")
		And ChoiceSource.FormName = "Catalog.Products.Form.ChoiceForm" Then
		
		ProcessingSelectionOfSelectionOnServer(ValueSelected);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure GroupPagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If CurrentPage.Name = "AdvancedGroup"
		And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtClient
Procedure CalculateTheCoefficientNumber0OnChange(Item)
	
	WhenChangingCalculateCoefficientNumber();
	
EndProcedure

&AtClient
Procedure CalculateTheCoefficientNumber1OnChange(Item)
	
	WhenChangingCalculateCoefficientNumber();
	
EndProcedure

&AtClient
Procedure FactorDenominatorOnChange(Item)
	
	ConfigureDecryptionCoefficientDenominator(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersOperations

&AtClient
Procedure OperationsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group)
	
	AddOperation(Cancel);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsAndServices

&AtClient
Procedure MaterialsAndServicesSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("MaterialsAndServices", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewProcessLine(ThisObject, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearProductSelectionSettings(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.PropertyMapping);
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
				Items.MaterialsAndServices,
				Items.MaterialsAndServices.SelectedRows,
				Object.SelectionByProperties);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesProductsOnChange(Item)
	
	CurrentRow = Items.MaterialsAndServices.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));

	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName",
		FormName, "MaterialsAndServices"));

	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
	ProductDataManagementClientServer.WhenChangingProductsInLineWithAutoSelection(CurrentRow, Object);
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentRow, Object);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCharacteristicOnChange(Item)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ProductDataManagementClientServer.WhenChangingCharacteristicInLineWithAutoSelection(CurrentData, Object);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersLaborCosts

&AtClient
Procedure LaborCostsSelection(Item, RowSelected, Field, StandardProcessing)
	
	ProcessFieldSelectionInTable("LaborCosts", Field.Name, StandardProcessing);
	
EndProcedure

&AtClient
Procedure LaborCostsInsertLines(Command)
	
	GetLinesFromClipboard("LaborCosts");
	
EndProcedure

&AtClient
Procedure TheEffortToCopyRows(Command)
	
	CopyTSLines("LaborCosts");
	
EndProcedure

&AtClient
Procedure LaborCostsBeforeDeleteRow(Item, Cancel)
	
	ProductDataManagementClient.ClearSelectionSettingsByProperties(
		Items.LaborCosts,
		Items.LaborCosts.SelectedRows,
		Object.SelectionByProperties);
	
EndProcedure
	
&AtClient
Procedure LaborCostsOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		WhenEnteringNewProcessLine(ThisObject, Item.Name, Items[Item.Name].CurrentData, Copy);
		
	EndIf;
	
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

&AtClient
Procedure FillInTheWorkflowTeam(Command)
	
	FilterParameters = New Structure("DeletionMark", False);
	FormParameters = New Structure("DisableSelection,Filter", Object.Ref, FilterParameters);
	CallbackDescription = New CallbackDescription("HandlerFillInTheInformationOnTheTechnologicalProcess", ThisObject);
	OpenForm("Catalog.TechnologicalProcesses.ChoiceForm",
				FormParameters,,,,,
				CallbackDescription,
				FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ReplaceInStages(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TechnologicalProcess", Object.Ref);
	
	OpenForm("DataProcessor.ProductionProcessEditor.Form.BulkReplacement", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure TheSetStatusInDevelopmentCommand(Command)
	
	If Not AttributeAvailability Then
		
		CallbackDescription = New CallbackDescription("SetStatusUnderDevelopmentCompletion", ThisObject);
		OpenForm("Catalog.TechnologicalProcesses.Form.AttributeUnlocking",
								New Structure("Object", Object.Ref),,,,,
								CallbackDescription,
								FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure TheSetStatusCommandIsActive(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.TechnologicalProcessStatuses.Valid"));
	
EndProcedure

&AtClient
Procedure SetStatusClosedCommand(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.TechnologicalProcessStatuses.Closed"));
	
EndProcedure

&AtClient
Procedure CheckFillInCommand(Command)
	
	ClearMessages();
	
	TitleText = NStr("vi = 'Kiểm tra quy trình kỹ thuật';
					|ru = 'Проверка технологического процесса';
					|en = 'Check technological process'; fa = 'Check technological process';
					|it = 'Verifica del processo tecnologico';
					|pl = 'Sprawdzenie procesu technologicznego';
					|tr = 'Teknolojik sürecin kontrolü'");
	
	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Quy trình kỹ thuật bị đánh dấu xóa không thể có hiệu lực.';
							|ru = 'Помеченный на удаление технологический процесс не может быть действующим.';
							|en = 'The technological process marked for deletion cannot be valid.'; fa = 'The technological process marked for deletion cannot be valid.';
							|it = 'Помеченный на удаление технологический процесс не может быть действующим.';
							|pl = 'The technological process marked for deletion cannot be valid.';
							|tr = 'Silinmek üzere işaretlenen teknolojik süreç geçerli olamaz.'");
		ShowMessageBox(,WarningText,, TitleText);
		Return;
	EndIf;
	
	If CheckForcedFilling() Then
		WarningText = NStr("vi = 'Có thể đưa quy trình kỹ thuật vào hoạt động.';
							|ru = 'Технологический процесс можно сделать действующим.';
							|en = 'The technological process can be set as valid.'; fa = 'The technological process can be set as valid.';
							|it = 'Il processo tecnologico può essere reso attivo.';
							|pl = 'Proces technologiczny można zaznaczyć jako obowiązujący.';
							|tr = 'Teknolojik süreç aktif hale getirilebilir.'");
	Else
		WarningText = NStr("vi = 'Không thể đưa quy trình kỹ thuật vào hoạt động.';
							|ru = 'Технологический процесс не может быть действующим.';
							|en = 'The technological process cannot be set as valid.'; fa = 'The technological process cannot be set as valid.';
							|it = 'Il processo tecnologico non può essere reso attivo.';
							|pl = 'Proces technologiczny nie może być obowiązującym.';
							|tr = 'Teknolojik süreç aktif hale getirilebilir.'");
	EndIf;
	
	ShowMessageBox(,WarningText,, TitleText);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	If Modified Then
		ShowMessageBox(, NStr("vi = 'Đối tượng không được ghi lại!';
								|ru = 'Объект не записан!';
								|en = 'Object is not saved.'; fa = 'Object is not saved.';
								|it = 'L''oggetto non è registrato!';
								|pl = 'Obiekt nie jest zapisany!';
								|tr = 'Nesne kaydedilmedi!'"));
		Return;
	EndIf;
	
	CallbackDescription = New CallbackDescription("QuestionCopyTechnologicalProcess", ThisObject);
	
	ProductDataManagementClient.ShowQuestionCopyWorkflowWithOperations(CallbackDescription)
	
EndProcedure

#Region UsedMaterials

&AtClient
Procedure SetUpAutoSelectionOfMaterialsCommand(Command)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		MessageText = NStr("vi = 'Hàng của bảng ""Nguyên vật liệu và nhân công"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		Return;
	EndIf;
	
	PropertyMapping = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.PropertyMapping,
		ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
	
	ProductDataManagementClient.ConfigureProductsAutoselection(
							ThisObject,
							"MaterialsAndServices",
							PropertyMapping, 
							Object.ForFinishedProductsKind,
							NStr("vi = 'Được chỉ ra trong quy trình kỹ thuật';
								|ru = 'Указывается в технологическом процессе';
								|en = 'Specified in technological process'; fa = 'Specified in technological process';
								|it = 'Si indica nel processo tecnologico';
								|pl = 'Jest wskazywane w procesie technologicznym';
								|tr = 'Teknolojik süreçte belirtilmektedir'"),
							Not AttributeAvailability);
	
EndProcedure

&AtClient
Procedure MaterialsAndServices_SettingUpFilterByPropertiesAndCalculationByFormulas(Command)
	
	CurrentData = Items.MaterialsAndServices.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Nguyên vật liệu và nhân công"" không được chọn.';
							|ru = 'Не выбрана строка таблицы ""Материалы и работы"".';
							|en = 'Row of the ""Materials and works"" table is not selected.'; fa = 'Row of the ""Materials and works"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Materiali e lavori"".';
							|pl = 'Nie wybrano wiersza tabeli ""Materiały i prace"".';
							|tr = '""Malzemeler ve İşler"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.MaterialsAndServices", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure OpenSelectionOfMaterialsCommand(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnChoice", False);
	ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, "MaterialsAndServices");
	AvailableProductTypes = New FixedArray(ArrayOfProductTypes);
	FormParameters.Insert("Filter", New Structure("ItemsType", AvailableProductTypes));
	
	OpenForm("Catalog.Products.Form.ChoiceForm", 
			FormParameters, 
			ThisObject, 
			UUID,,,, 
			FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesInsertLines(Command)
	
	GetLinesFromClipboard("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesCopyLines(Command)
	
	CopyTSLines("MaterialsAndServices");
	
EndProcedure

&AtClient
Procedure MaterialsAndServicesFillOutTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("MaterialsAndServices");
	
EndProcedure

#EndRegion

#Region LaborCosts

&AtClient
Procedure LaborCostsSettingUpSelectionByPropertiesAndCalculationByFormulas_3(Command)
	
	CurrentData = Items.LaborCosts.CurrentData;
	
	ClearMessages();
	
	If CurrentData = Undefined Then
		
		MessageText = NStr("vi = 'Hàng của bảng ""Chi phí nhân công""chưa được chọn.';
							|ru = 'Не выбрана строка таблицы ""Трудозатраты"".';
							|en = 'Line of the ""Labor costs"" table is not selected.'; fa = 'Line of the ""Labor costs"" table is not selected.';
							|it = 'Non è stata scelta una riga della tabella ""Costi di manodopera"".';
							|pl = 'Nie wybrano wiersza tabeli ""Nakłady pracy"".';
							|tr = '""İş Gücü Maliyetleri"" tablosunun satırı seçilmedi.'");
		CommonClient.MessageToUser(MessageText,, "Object.LaborCosts", "Object");
		
		Return;
	EndIf;
	
	OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, "LaborCosts");

EndProcedure

&AtClient
Procedure LaborCostsFillInTheCalculationArticle(Command)
	
	FillInCalculationArticleInLines("LaborCosts");
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure AddOperationCommand(Command)
	
	Items.Operations.AddRow();
	
EndProcedure

&AtClient
Procedure MoveOperationForwardCommand(Command)
	
	MoveOperation(True);
	
EndProcedure

&AtClient
Procedure MoveOperationBackCommand(Command)
	
	MoveOperation(False);
	
EndProcedure

#EndRegion

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

#EndRegion

#Region Private

// StandardSubsystems.Properties

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
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

#Region PropertySubsystemProcedures

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

#EndRegion

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(TSName)
	
	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		CopyLinesOnServer(TSName);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[TSName].SelectedRows.Count());
	EndIf;
	
EndProcedure

&AtServer
Procedure CopyLinesOnServer(TSName)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[TSName], Items[TSName].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfRowsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	CompositionOfLines     = Undefined;
	FilterParameters = Undefined;
	
	If TSName = "MaterialsAndServices" Then
		CompositionOfLines = "Products,Characteristic,Package,NumberOfPackages,ProductCostElement";
	ElsIf TSName = "LaborCosts" Then
		CompositionOfLines = "WorkKind,Count,ProductCostElement";
	EndIf;
	
	SelectGoods = TSName <> "LaborCosts";
	
	StructureOfActions = New Structure;
	
	If SelectGoods Then
		
		ArrayOfProductTypes = ProductDataManagementClientServer.ArrayOfAvailableItemTypes(ThisObject, TSName);
		FilterParameters = New Map;
		FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
		
		StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
		StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
		
	EndIf;
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, CompositionOfLines);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	ObjectTable = Object[TSName]; // FormDataCollection
	RowsToProcess = New Array();
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = ObjectTable.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		WhenEnteringNewProcessLine(ThisObject, TSName, CurrentRow);
		
		If SelectGoods Then
			RowsToProcess.Add(CurrentRow);
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable);
	
	FillInServiceDetails();
	
EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, BankingDetailsAreAvailable)
	
	Form.Items.MaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuMaterialsAndServicesInsertLines.Enabled = BankingDetailsAreAvailable;
	
	Form.Items.LaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	Form.Items.ContextMenuLaborCostsInsertLines.Enabled = BankingDetailsAreAvailable;
	
EndProcedure

#EndRegion

#Region Operations

&AtClient
Procedure MoveOperation(GoForward)
	
	ErrorText = "";
	
	If Not CurLineIsOperation() Then
		Return;
	EndIf;
	
	CurrentData = Items.Operations.CurrentData;
	If MoveOperationOnServer(CurrentData.Ref, GoForward, ErrorText) Then
		NotifyChanged(Type("CatalogRef.ManufacturingOperations"));
	Else
		ShowMessageBox(,ErrorText);
	EndIf;
	
EndProcedure

&AtServerNoContext
Function MoveOperationOnServer(Ref, GoForward, ErrorText)

	OperationObject = Ref.GetObject();
	Try
		OperationObject.Lock();
	Except
		ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
								|Có thể là giao dịch đang được chỉnh sửa bởi người sử dụng.';
								|ru = 'Не удалось переместить операцию.
								|Возможно, операция редактируется пользователем.';
								|en = 'Cannot move the operation. 
								|Maybe, the operation is being edited by another user.'; fa = 'Cannot move the operation. 
								|Maybe, the operation is being edited by another user.';
								|it = 'Non è stato possibile spostare l''operazione.
								|Probabilmente l''operazione sta venendo modificata dall''utente.';
								|pl = 'Przemieszczenie operacji nie powiodło się.
								|Być może operacja jest edytowana przez użytkownika.';
								|tr = 'İşlem taşınamadı.
								|İşlem, kullanıcı tarafından düzenleniyor olabilir.'");
	    Return False;
	EndTry;
	OperationNumber          = OperationObject.OperationNumber;
	NextOperation = OperationObject.NextOperation;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Owner = &Owner
	|	AND NOT ManufacturingOperations.DeletionMark
	|	AND (&GoForward
	|				AND ManufacturingOperations.OperationNumber = &NextOperation
	|			OR NOT &GoForward
	|				AND ManufacturingOperations.NextOperation = &OperationNumber)";
	
	Query.SetParameter("Owner",               OperationObject.Owner);
	Query.SetParameter("OperationNumber",          OperationNumber);
	Query.SetParameter("NextOperation", NextOperation);
	Query.SetParameter("GoForward",                 GoForward);
	
	Result = Query.Execute().Unload(); // See ProductionServer.ServiceStructureOfValueTable
	If Result.Count() = 0 Then
		
		Return True;
		
	ElsIf Result.Count() > 1 Then
		// There shouldn't be multiple operations
		If GoForward Then
			ErrorText = NStr("vi = 'Không thể chuyển giao dịch về sau,
									|bởi vì có nhiều giao dịch tiếp theo.';
									|ru = 'Не удалось переместить операцию вперед,
									|т.к. следующих операций несколько.';
									|en = 'Cannot put the operation forward 
									|as there are several following operations.'; fa = 'Cannot put the operation forward 
									|as there are several following operations.';
									|it = 'Non è stato possibile spostare in avanti l''operazione,
									|poiché ci sono più operazioni successive.';
									|pl = 'Przemieszczenie operacji naprzód nie powiodło się,
									|ponieważ następnych operacji jest kilka.';
									|tr = 'Birden fazla sonraki işlem olduğundan dolayı
									|işlem ileriye taşınamadı.'");
		Else
			ErrorText = NStr("vi = 'Không thể chuyển giao dịch lên trước,
									|bởi vì có nhiều giao dịch trước đó.';
									|ru = 'Не удалось переместить операцию назад,
									|т.к. предыдущих операций несколько.';
									|en = 'Cannot put the operation back
									|as there are several previous operations.'; fa = 'Cannot put the operation back
									|as there are several previous operations.';
									|it = 'Non è stato possibile spostare indietro l''operazione,
									|poiché ci sono più operazioni precedenti.';
									|pl = 'Przemieszczenie operacji wstecz nie powiodło się,
									|ponieważ poprzednich operacji jest kilka.';
									|tr = 'Birden fazla sonraki işlem olduğundan dolayı
									|işlem geriye taşınamadı.'");
		EndIf;
		Return False;
	EndIf;
	
	ReplacementOperation = Undefined;
	
	// Block the operation with which the transfer will be performed
	ReplacementOperation = Result[0].Ref.GetObject();
	Try
		ReplacementOperation.Lock();
	Except
		If GoForward Then
			ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
									|Có thể là người sử dụng đang chỉnh sửa giao dịch tiếp theo.';
									|ru = 'Не удалось переместить операцию.
									|Возможно, следующая операция редактируется пользователем.';
									|en = 'Cannot move the operation.
									|Maybe, the following operation is being edited by another user.'; fa = 'Cannot move the operation.
									|Maybe, the following operation is being edited by another user.';
									|it = 'Non è stato possibile spostare l''operazione.
									|Probabilmente l''operazione successiva sta venendo modificata dall''utente.';
									|pl = 'Przemieszczenie operacji nie powiodło się.
									|Być może, następna operacja jest edytowana przez użytkownika.';
									|tr = 'İşlem taşınamadı.
									|Sonraki işlem, kullanıcı tarafından düzenleniyor olabilir.'");
		Else
			ErrorText = NStr("vi = 'Không thể sắp xếp giao dịch.
									|Có thể là người sử dụng đang chỉnh sửa giao dịch trước đó.';
									|ru = 'Не удалось переместить операцию.
									|Возможно, предыдущая операция редактируется пользователем.';
									|en = 'Cannot move the operation.
									|Maybe, the previous operation is being edited by another user.'; fa = 'Cannot move the operation.
									|Maybe, the previous operation is being edited by another user.';
									|it = 'Non è stato possibile spostare l''operazione.
									|Probabilmente l''operazione precedente sta venendo modificata dall''utente.';
									|pl = 'Przemieszczenie operacji nie powiodło się.
									|Być może, poprzednia operacja jest edytowana przez użytkownika.';
									|tr = 'İşlem taşınamadı.
									|Önceki işlem, kullanıcı tarafından düzenleniyor olabilir.'");
		EndIf;
	    Return False;
	EndTry;
	
	OperationObject.OperationNumber          = ReplacementOperation.OperationNumber;
	OperationObject.NextOperation = ReplacementOperation.NextOperation;
	
	ReplacementOperation.OperationNumber          = OperationNumber;
	ReplacementOperation.NextOperation = NextOperation;
	
	Try
		OperationObject.Write();
		ReplacementOperation.Write();
	Except
		ErrorText = NStr("vi = 'Không thể di chuyển giao dịch.';
						|ru = 'Не удалось переместить операцию.';
						|en = 'Cannot move the operation.'; fa = 'Cannot move the operation.';
						|it = 'Non è stato possibile spostare l''operazione.';
						|pl = 'Przemieszczenie operacji nie powiodło się.';
						|tr = 'İşlem taşınamadı.'");
		Return False;
	EndTry;
	
	OperationObject.Unlock();
	ReplacementOperation.Unlock();
	
	Return True;

EndFunction

&AtClient
Function CurLineIsOperation()

	CurrentData = Items.Operations.CurrentData;
	If CurrentData = Undefined Or TypeOf(CurrentData) = Type("DynamicListGroupRow") Then
		Return False;
	EndIf;

	Return True;
	
EndFunction

&AtServer
Procedure SetSelectionInListOfOperations()
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"Owner", 
		Object.Ref, 
		DataCompositionComparisonType.Equal,
		, 
		True);
	
	CommonClientServer.SetDynamicListFilterItem(
		Operations, 
		"DeletionMark", 
		False, 
		DataCompositionComparisonType.Equal,
		, 
		True);
	
EndProcedure

&AtClient
Procedure AddOperation(Cancel = False)

	If Not AttributeAvailability Then
		
		Cancel = True;
		
	ElsIf Not ValueIsFilled(Object.Ref) Then
		
		Cancel = True;
		
		If Object.Status = PredefinedValue("Enum.TechnologicalProcessStatuses.Valid") Then
			QueryText = NStr("vi = 'Có thể nhập giao dịch với trạng thái ""Đang phát triển"".
										|Thay đổi trạng thái và ghi lại bảng kê chi tiết?';
										|ru = 'Ввод операций возможен со статусом ""В разработке"".
										|Изменить статус и записать спецификацию?';
										|en = 'You can enter operations only with status ""Under development"".
										|Change the status and save the BOM?'; fa = 'You can enter operations only with status ""Under development"".
										|Change the status and save the BOM?';
										|it = 'L''immissione di operazioni è permessa con stato ""In lavorazione"".
										|Modificare lo stato e registrare la specifica?';
										|pl = 'Wprowadzanie operacji jest możliwe ze statusem ""W przygotowaniu"".
										|Zmienić status i zapisać specyfikację?';
										|tr = 'İşlem girişi, ""Geliştirme Aşamasında"" durumu ile mümkündür.
										|Durum değiştirilsin ve ürün reçetesine kaydedilsin mi?'");
		Else
			QueryText = NStr("vi = 'Chỉ có thể nhập giao dịch sau khi ghi lại quy trình công nghệ.
										|Ghi lại quy trình công nghệ?';
										|ru = 'Ввод операций возможен только после записи технологического процесса.
										|Записать технологический процесс?';
										|en = 'Operations can only be entered after saving the technological process.
										|Save the technological process?'; fa = 'Operations can only be entered after saving the technological process.
										|Save the technological process?';
										|it = 'L''inserimento di operazioni è possibile solo dopo il salvataggio del processo tecnologico.
										|Salvare il processo tecnologico?';
										|pl = 'Wprowadzenie operacji jest możliwe tylko po zapisaniu procesu technologicznego.
										|Zapisyć proces technologiczny?';
										|tr = 'İşlem girişi sadece teknolojik süreç kaydından sonra mümkündür.
										|Teknolojik süreç kaydedilsin mi?'");
		EndIf;
		
		CallbackDescription = New CallbackDescription("QuestionAddOperation", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNo);
		
	EndIf;

EndProcedure

#EndRegion

#Region AutoSelection_SelectionByProperties_CalculationOfQuantity

&AtClient
Procedure ProcessingSelectionSettingUpAutomaticSelectionOfProducts(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	MethodOfProductsAutoselection = CurrentData.MethodOfProductsAutoselection;
	
	If ProductDataManagementClient.ConfigureProductsAutoselectionCompletion(ValueSelected, CurrentData, Object.PropertyMapping) Then
		
		If MethodOfProductsAutoselection <> CurrentData.MethodOfProductsAutoselection Then
			
			StructureOfActions = New Structure;
			StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
			StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
			BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
			
		EndIf;
		
		FillInThereIsAutomaticSelectionOfNomenclature();
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectionProcessingSettingUpSelectionByPropertiesAndCalculationByFormulas(TSName, ValueSelected)
	
	CurrentData = Items[TSName].CurrentData;
	
	If ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulasCompletion(ValueSelected, CurrentData, Object.SelectionByProperties) Then
		Modified = True;
	EndIf;
	
EndProcedure

&AtClient
Procedure OpenSettingsForSelectingByPropertiesAndCalculatingByFormulas(CurrentData, TSName)
	
	AddressInStorage = PutDataForCalculationByFormulasInRepository(TSName);
	
	SelectionByProperties = ProductDataManagementClient.DetailsOfSettingsByLineInArray(
		CurrentData,
		Object.SelectionByProperties,
		ProductDataManagementClientServer.DetailsSettingUpSelectionByProperties());
	
	ProductDataManagementClient.ConfigureSelectionByPropertiesAndCalculationByFormulas(
								ThisObject,
								TSName,
								SelectionByProperties,
								Object.ForFinishedProductsKind,
								Not AttributeAvailability,
								,
								AddressInStorage);

EndProcedure

&AtServer
Function PutDataForCalculationByFormulasInRepository(TSName)
	
	FormTable = Items[TSName]; // FormTable
	
	DataForCalculation = Catalogs.TechnologicalProcesses.UploadDataForFormulaConstructor(
		Object,
		TSName,
		Object[TSName].FindByID(FormTable.CurrentRow));
	
	Result = PutToTempStorage(DataForCalculation, UUID);
	Return Result;
	
EndFunction

&AtClientAtServerNoContext
Procedure WhenEnteringNewProcessLine(Form, TSName, LineOfATabularSection, Copy = False)
	
	SourceLinkKey = ?(Copy, LineOfATabularSection.ConnectionKey, Undefined);
	
	LineOfATabularSection.ConnectionKey = New UUID;
	
	If TSName <> "LaborCosts" Then
	
		ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(
			LineOfATabularSection, 
			SourceLinkKey,
			Form.Object.PropertyMapping);
		
	EndIf;
		
	ProductDataManagementClientServer.WhenEnteringNewLineWithSelectionByProperties(
		LineOfATabularSection,
		SourceLinkKey,
		Form.Object.SelectionByProperties);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	UseBillOfMaterialsParameterization = 
		GetFunctionalOption("UseBillOfMaterialsParameterization");
		
	FillInServiceDetails();
	
	ConfigureDecryptionCoefficientDenominator(ThisObject);
	
	ProductDataManagementClientServer.SetMaterialSelectionParameters(
		Items.MaterialsAndServicesProducts, ThisObject);
		
	Items.DetailsGroup.Picture = CommonClientServer.CommentPicture(Object.LongDesc);
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Department.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.TechnologicalProcessStatuses.Valid;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

	//
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "MaterialsAndServicesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.MaterialsAndServices.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch đầu tiên>';
													|ru = '<первая операция>';
													|en = '<first operation>'; fa = '<first operation>';
													|it = '<operazione prima>';
													|pl = '<pierwsza operacja>';
													|tr = '<ilk işlem>'"));
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.MaterialsAndServicesProductCostElement.Name);
	
	AndGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	AndGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = PredefinedValue("Enum.ItemsTypes.Set");
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.MaterialsAndServices.ProductCostElement");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = AndGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("SourceOfCompositionOfSetsInProduction");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.SourcesOfCompositionOfSetsInProduction.Specifications;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ ra trong thành phần bộ sản phẩm>';
													|ru = '<указывается в составе набора>';
													|en = '<specified in the set>'; fa = '<specified in the set>';
													|it = '<viene mostrato nella composizione del kit>';
													|pl = '<podaje się w składzie zestawu>';
													|tr = '<küme içeriğinde belirtilmektedir>'"));
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.LaborCostsOperation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.LaborCosts.OperationEdit");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<giao dịch đầu tiên>';
													|ru = '<первая операция>';
													|en = '<first operation>'; fa = '<first operation>';
													|it = '<operazione prima>';
													|pl = '<pierwsza operacja>';
													|tr = '<ilk işlem>'"));

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ForFinishedProductsKind.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ThereIsProductItemAutoSelection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"MaterialsAndServices",
		"NumberOfPackages");
	ProductDataManagement.EstablishConditionalAppearanceOfSelectionByPropertiesAndCalculationByFormulas(
		ThisObject,
		"Object",
		"LaborCosts",
		"Count");
		
	ProductDataManagement.SetConditionalAppearanceForAutoSelectingProducts(ThisObject, "Object", "MaterialsAndServices");
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInFeatureAttribute", New Structure("Products", "ItemVariantsAreUsed"));
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.MaterialsAndServices, StructureOfActions);
		
	If UseBillOfMaterialsParameterization Then
		
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.MaterialsAndServices,
			True,
			True,
			Object.SelectionByProperties);
		ProductDataManagement.FillInServiceDetailsOfAutoSelectionAndCalculationOfNumber(
			Object.LaborCosts,
			False,
			True,
			Object.SelectionByProperties);
		
	EndIf;
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.SetStatusValid.Enabled   = (Object.Status <> Enums.TechnologicalProcessStatuses.Valid);
	Items.SetTheClosedStatus_3.Enabled     = (Object.Status <> Enums.TechnologicalProcessStatuses.Closed);
	Items.SetStatusUnderDevelopment.Enabled = (Object.Status <> Enums.TechnologicalProcessStatuses.UnderDevelopment);
	Items.CheckFilling.Enabled         = (Object.Status <> Enums.TechnologicalProcessStatuses.Valid);
	
	Items.FormReplaceInStages.Enabled        = ValueIsFilled(Object.Ref);
	
	SetAvailabilityOfItemsByStatusServer();

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("CalculateFactor")
		Or Initialize Then
			
		DisplayCoefficient = True;
		
		Items.GroupApplicationRate.Visible = DisplayCoefficient;
		Items.GroupCoefficientFormula.Visible = DisplayCoefficient And Object.CalculateFactor;
			
	EndIf;
	
EndProcedure

// Performs filling according to another technological process
// 
// Parameters:
// 	Source - CatalogObject.TechnologicalProcesses
&AtServer
Procedure FillInTheInformationOnTheTechnologicalProcess(Source)
	
	BeginTransaction();
	
	Try
		
		If ValueIsFilled(Object.Ref) Then
			DeleteRecipientOperations();
		Else
			If Not ValueIsFilled(Object.Description) Then
				Object.Description = Source.Description;
			EndIf;
			Write();
		EndIf;
		ReceiverLink_ = Object.Ref;
		
		If Not Catalogs.TechnologicalProcesses.FillInTheInformationOnTheTechnologicalProcess(Object, Source, ReceiverLink_) Then
			Raise NStr("vi = 'Không thể điền theo quy trình công nghệ.';
						|ru = 'Не удалось заполнить по технологическому процессу.';
						|en = 'Cannot fill in by technological process.'; fa = 'Cannot fill in by technological process.';
						|it = 'Non è stato possibile compilare secondo il processo tecnologico.';
						|pl = 'Nie udało się wypełnić wg procesu technologicznego.';
						|tr = 'Teknolojik sürece göre doldurulamadı.'");
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
 		WriteLogEvent(
			NStr("vi = 'Điền theo quy trình công nghệ';
				|ru = 'Заполнение технологического процесса';
				|en = 'Technological process population'; fa = 'Technological process population';
				|it = 'Compilazione del processo tecnologico';
				|pl = 'Wypełnienie procesu technologicznego';
				|tr = 'Teknolojik sürecin doldurulması'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			
 		Raise;
		
	EndTry;
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLines(TSName)
	
	If Not ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[TSName]) Then
		Return;
	EndIf;
	
	Filter = New Structure;
	Filter.Insert("ExpenseType", ProductionClient.TypesOfCostsForChoosingCalculationArticle(TSName));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	CallbackDescription = New CallbackDescription("FillInCalculationArticleInLinesCompletion", ThisObject, TSName);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLinesCompletion(ClosingResult, TSName) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items[TSName].SelectedRows;
	TabularSection = Object[TSName];
	
	For Each RowID In SelectedRows Do
		
		CurrentData = TabularSection.FindByID(RowID);
		CurrentData.ProductCostElement = ClosingResult;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure DeleteRecipientOperations()

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Owner = &Owner
	|	AND NOT ManufacturingOperations.DeletionMark";
	
	Query.SetParameter("Owner", Object.Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		OperationObject = Selection.Ref.GetObject();
		OperationObject.DataExchange.Load = True;
		OperationObject.SetDeletionMark(True);
	EndDo;

EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	AttributeAvailability = (Object.Status = Enums.TechnologicalProcessStatuses.UnderDevelopment);
	TechnologicalProcessIsClosed = (Object.Status = Enums.TechnologicalProcessStatuses.Closed);
	
	// Header Controls
	Items.Code.ReadOnly = Not AttributeAvailability;
	Items.ForFinishedProductsKind.ReadOnly = Not AttributeAvailability;
	Items.Department.ReadOnly = Not AttributeAvailability;
	
	// Elements of table parts
	Items.MaterialsAndServices.ReadOnly = Not AttributeAvailability;
	Items.LaborCosts.ReadOnly = Not AttributeAvailability;
	
	// Commands
	Items.MaterialsAndServicesOpenMaterialSelection.Enabled = AttributeAvailability;
	Items.FormFillInTheInformationOnTheTechnologicalProcess.Enabled = AttributeAvailability;
	
	// If the technical process is closed, then we will make the rest of the details unavailable
	
	Items.EmployeeResponsible.ReadOnly = TechnologicalProcessIsClosed;
	
	// Availability of operation list items
	Items.Operations.ChangeRowSet       = AttributeAvailability;
	Items.OperationsGroupAdd.Enabled = AttributeAvailability;
	
	Items.OperationsMoveTheOperationBack.Enabled   = AttributeAvailability;
	Items.OperationsMoveTheOperationForward.Enabled  = AttributeAvailability;
	
	SetAvailabilityOfClipboardCommands(
		ThisObject,
		ProcessingOfTabularForms.ThereAreLinesInClipboard() And AttributeAvailability);
	
EndProcedure

&AtServer
Function CheckForcedFilling()
	
	Cancel = False;
	
	CatalogObject = FormAttributeToValue("Object");
	CatalogObject.Status = Enums.TechnologicalProcessStatuses.Valid;
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, New Array, CatalogObject);
	// End StandardSubsystems.Properties
	
	If Not CatalogObject.CheckFilling() Then
		Cancel = True;
	EndIf;
	
	Return Not Cancel;
	
EndFunction
 
&AtClient
Procedure SetNewStatusAndRecord(Status)

	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Không thể thay đổi trạng thái quy trình kỹ thuật đã đặt dấu xóa.';
							|ru = 'Нельзя изменить статус помеченного на удаление технологического процесса.';
							|en = 'Cannot change the status of a technological process marked for deletion.'; fa = 'Cannot change the status of a technological process marked for deletion.';
							|it = 'Impossibile modificare lo stato del processo tecnologico contrassegnato per l''eliminazione.';
							|pl = 'Nie można zmienić statusu zaznaczonego do usunięcia procesu technologicznego.';
							|tr = 'Silinmek üzere işaretlenen teknolojik sürecin durumu değiştirilemez.'");
  		ShowMessageBox(,WarningText);
		Return;
	EndIf; 
	
	ClearMessages();
	
	CurrentStatus = Object.Status;
	
	Object.Status = Status;
	If Not Write() Then
		Object.Status = CurrentStatus;
	EndIf;
	
EndProcedure

&AtServer
Procedure ProcessingSelectionOfSelectionOnServer(ValueSelected)

	If TypeOf(ValueSelected) = Type("Array") Then
		GoodsList = ValueSelected;
	Else
		GoodsList = New Array;
		GoodsList.Add(ValueSelected);
	EndIf;
	
	TSName = "MaterialsAndServices";
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInArticleAttribute", New Structure("Products", "SKU"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner");
	StructureOfActions.Insert("CheckFillPackageByOwner");
	RowsToProcess = New Array();
	
	ObjectTable = Object[TSName]; // FormDataCollection
	
	For Each RowOfProduct In GoodsList Do
		
		CurrentRow = ObjectTable.Add();
		CurrentRow.Products = RowOfProduct;
		
		WhenEnteringNewProcessLine(ThisObject, TSName, CurrentRow);
		RowsToProcess.Add(CurrentRow);
		
	EndDo;
		
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		ObjectTable);

EndProcedure

&AtClient
Procedure HandlerFillInTheInformationOnTheTechnologicalProcess(TechnologicalProcessSource, AdditionalParameters) Export

	If TechnologicalProcessSource = Undefined Then
		Return;
	EndIf; 
	
	QueryText = NStr("vi = 'Khi điền dữ liệu cũ sẽ bị xóa.
								|Điền?';
								|ru = 'При заполнении прежние данные будут утеряны.
								|Заполнить?';
								|en = 'The previous data will be lost during the population.
								|Populate?'; fa = 'The previous data will be lost during the population.
								|Populate?';
								|it = 'Procedendo con la compilazione i dati precedenti verranno persi.
								|Continuare?';
								|pl = 'Podczas wypełniania poprzednie dane zostaną utracone.
								|Wypełnić?';
								|tr = 'Doldururken önceki veriler kaybolacaktır.
								|Doldurulsun mu?'");
	ButtonsList = New ValueList;
	ButtonsList.Add(DialogReturnCode.Yes, NStr("vi = 'Điền';
												|ru = 'Заполнить';
												|en = 'Fill'; fa = 'پرکردن';
												|it = 'Compilare';
												|pl = 'Fill';
												|tr = 'Doldur'"));
	ButtonsList.Add(DialogReturnCode.Cancel);
	CallbackDescription = New CallbackDescription("FillInQuestionOnTechnologicalProcess", ThisObject, TechnologicalProcessSource);
	ShowQueryBox(CallbackDescription, QueryText, ButtonsList,,, NStr("vi = 'Điền theo quy trình công nghệ';
																	|ru = 'Заполнение по технологическому процессу';
																	|en = 'Population by technological process'; fa = 'Population by technological process';
																	|it = 'Compilazione secondo il processo tecnologico';
																	|pl = 'Wypełnienie wg procesu technologicznego';
																	|tr = 'Teknolojik sürece göre doldurulması'"));

EndProcedure

&AtClient
Procedure FillInQuestionOnTechnologicalProcess(QuestionResult, TechnologicalProcessSource) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	FillInTheInformationOnTheTechnologicalProcess(TechnologicalProcessSource);
	
	NotifyChanged(Type("CatalogRef.ManufacturingOperations"));
	
	Notify("Write_ManufacturingOperations");
	
EndProcedure

&AtClient
Procedure QuestionAddOperation(QuestionResult, AdditionalParameters) Export

	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	If Object.Status = PredefinedValue("Enum.TechnologicalProcessStatuses.Valid") Then
		Object.Status = PredefinedValue("Enum.TechnologicalProcessStatuses.UnderDevelopment");
	EndIf;
	
	If Write() Then
		Items.Operations.AddRow();
	EndIf;

EndProcedure

&AtClient
Procedure SetStatusUnderDevelopmentCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = True Then
		SetNewStatusAndRecord(PredefinedValue("Enum.TechnologicalProcessStatuses.UnderDevelopment"));
	EndIf;

EndProcedure

&AtClient
Procedure ProcessFieldSelectionInTable(TableName, FieldName, StandardProcessing)

	If Not ReadOnly And AttributeAvailability Then
		Return;
	EndIf;

	CurrentData = Items[TableName].CurrentData;
	
	If (FieldName = "MaterialsAndServicesProducts"
			Or FieldName = "MaterialsAndServicesProductsCode"
			Or FieldName = "MaterialsAndServicesSKU")
		And ValueIsFilled(CurrentData.Products) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf (FieldName = "MaterialsAndServicesOperation"
		Or FieldName = "LaborCostsOperation")
		And ValueIsFilled(CurrentData.OperationEdit) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.OperationEdit);
		
	ElsIf (FieldName = "MaterialsAndServicesProductCostElement"
			Or FieldName = "LaborCostsProductCostElement")
		And ValueIsFilled(CurrentData.ProductCostElement)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.ProductCostElement);
		
	ElsIf (FieldName = "LaborCostsWorkKind")
		And ValueIsFilled(CurrentData.WorkKind)  Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.WorkKind);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure WhenChangingCalculateCoefficientNumber()
	
	Object.CalculateFactor = CalculateTheCoefficientNumber;
	
	ConfigureDependentFormElements(ThisObject, "CalculateFactor");
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDecryptionCoefficientDenominator(Form)
	
	UnitPresentation = TMCommonUseClientServer.InPlural(
		NStr("vi = 'đơn vị';
			|ru = 'единицу';
			|en = 'unit'; fa = 'واحد';
			|it = 'un''unità';
			|pl = 'jednostkę';
			|tr = 'birimini'"),
		NStr("vi = 'đơn vị tính';
			|ru = 'единицы';
			|en = 'units'; fa = 'واحد';
			|it = 'unità';
			|pl = 'jednostki';
			|tr = 'birimlerini'"),
		NStr("vi = 'đơn vị tính';
			|ru = 'единицы';
			|en = 'units'; fa = 'واحد';
			|it = 'unità';
			|pl = 'jednostki';
			|tr = 'birimlerini'"),
		Form.Object.FactorDenominator);
	
	Form.Items.DecodingTheCoefficientDenominator.Title = StrTemplate(
		NStr("vi = '%1 bảng kê chi tiết các nguồn lực sản xuất sản phẩm chính';
			|ru = '%1 основного изделия спецификации';
			|en = '%1 of main BOM product'; fa = '%1 of main BOM product';
			|it = '%1 del prodotto principale della specifica';
			|pl = '%1 produktu podstawowego specyfikacji';
			|tr = 'ürün reçetesi nihai ana ürün %1'"),
		UnitPresentation);
	
EndProcedure

&AtServer
Procedure FillInThereIsAutomaticSelectionOfNomenclature()
	
	ThereIsProductItemAutoSelection = UseBillOfMaterialsParameterization 
	And ProductDataManagement.ThereIsAutomaticSelectionOfItemsInTable(Object.MaterialsAndServices);
	
EndProcedure

&AtClient
Procedure QuestionCopyTechnologicalProcess(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult <> DialogReturnCode.Yes Then
		Return;
	EndIf;
	
	Ref = CopyWorkflowOnServer(Object.Ref);
	
	If Ref <> Undefined Then
		
		ProductDataManagementClient.NotifyAboutCopyingTechnologicalProcessWithOperations();
		
		OpenForm("Catalog.TechnologicalProcesses.ObjectForm", New Structure("Key", Ref));
	
	EndIf;

EndProcedure

&AtServerNoContext
Function CopyWorkflowOnServer(Source)
	
	Return Catalogs.TechnologicalProcesses.CopyWorkflowWithOperations(Source);
	
EndFunction

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

#EndRegion

#EndRegion
