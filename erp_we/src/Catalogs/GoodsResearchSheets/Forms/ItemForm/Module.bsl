
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

	UpdateScopePresentation();
	
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
	
	// Rights to change the goods research card
	SetVisibility1();
	
	ConfigureDependentFormElements(ThisObject);

	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	// StandardSubsystems.Properties
	PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.OnOpen(ThisObject, Cancel);
	// End StandardSubsystems.FilesOperations
	
	TypeOfQualityControlFillInSelectionList(ThisObject);
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
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

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FormEvents.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	// Subsystem "Properties"
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisObject, WriteParameters);
	
	// StandardSubsystems.AttachableCommands
	If CommonClient.SubsystemExists("StandardSubsystems.AttachableCommands") Then
		ModuleAttachableCommandsClient = CommonClient.CommonModule("AttachableCommandsClient");
		ModuleAttachableCommandsClient.AfterWrite(ThisObject, Object, WriteParameters);
	EndIf;
	// End StandardSubsystems.AttachableCommands

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScopeViewClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	
	FormParameters = New Structure;
	
	SelectionByProperties = GoodsResearchClient.DetailsOfTableInArrayOfStructures(
		Object.SelectionByProperties,
		GoodsResearchClient.DetailsOfSelectionByProperties());
	
	FormParameters.Insert("SelectionByProperties", SelectionByProperties);
	FormParameters.Insert("SettingsMode", Object.AssignmentOption);
	FormParameters.Insert("ReadOnly", Not AttributeAvailability);
	
	ItemList = GoodsResearchClient.DetailsOfTableInArrayOfStructures(
		Object.Goods,
		GoodsResearchClient.AttributesSetupItemList());
	FormParameters.Insert("ItemList", ItemList);
	
	CallbackDescription = New CallbackDescription(
		"OpenScopeEntryFormEnd",
		ThisObject,
		SettingsMode);
	
	OpenForm("Catalog.GoodsResearchSheets.Form.ScopeInputForm", FormParameters, ThisObject,,,, CallbackDescription);
	
EndProcedure

&AtClient
Procedure TypeOfControlOnChange(Item)
	
	CheckClearAttributesOnChangingTypeOfControl();
	
EndProcedure

&AtClient
Procedure LongDescStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	CommonClient.ShowCommentEditingForm(Item.EditText, ThisObject,
		"Object.DescriptionOfUsageSpecification", NStr("vi = 'Mô tả chi tiết về việc áp dụng sơ đồ nghiên cứu hàng hóa';
														|ru = 'Описание уточнения применения карты исследования товаров';
														|en = 'Details of refinement for applying the goods research sheet'; fa = 'Details of refinement for applying the goods research sheet';
														|it = 'Details of refinement for applying the goods research sheet';
														|pl = 'Details of refinement for applying the goods research sheet';
														|tr = 'Ürün inceleme kartı uygulama netleştirme açıklaması'"));
	
EndProcedure

&AtClient
Procedure TemplatesFilterOptionOnChange(Item)
	
	CheckClearAttributesONChangingSamplingOption();
	
EndProcedure

&AtClient
Procedure PagesOnCurrentPageChange(Item, CurrentPage)
	
	// StandardSubsystems.Properties
	If ThisObject.PropertiesParameters.Property(CurrentPage.Name)
			And Not ThisObject.PropertiesParameters.DeferredInitializationExecuted Then
		
		PropertiesExecuteDeferredInitialization();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersChecks

&AtClient
Procedure ChecksOnActivateRow(Item)
	
	CurrentData = Items.Checks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	QualityIndicatorFillInSelectionList(ThisObject, CurrentData.CheckKind);
	
EndProcedure

&AtClient
Procedure ChecksCheckKindOnChange(Item)
	
	CurrentData = Items.Checks.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	QualityIndicatorFillInSelectionList(ThisObject, CurrentData.CheckKind);
	
EndProcedure

&AtClient
Procedure ChecksCheckKindAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If ValueIsFilled(Text) Then
		StandardProcessing = False;
		ChoiceData = ChecksTypeOfCheckAutoSelectionATServer(Text);
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
Procedure Attachable_AllowObjectAttributeEdit(Command)
	
	ProcedureParameters = TMCommonUseClient.PermissionParametersForEditingItemDetails();
	ProcedureParameters.OnlyVisible = False;
	
	TMCommonUseClient.AllowObjectAttributeEdit(ThisObject, ProcedureParameters);
	
EndProcedure

// IntegrationWith1CDocumentManagementSubsystem
&AtClient
Procedure Attachable_ExecuteIntegrationCommand(Command)
	
	IntegrationWith1CDocumentManagementCoreClient.ExecutePlugInIntegrationCommand(Command, ThisObject, Object);
	
EndProcedure
// End IntegrationWith1CDocumentManagementSubsystem

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure SetStatusClosed(Command)
	SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfGoodsResearchSheet.Closed_"));
EndProcedure

&AtClient
Procedure SetDraftStatus(Command)
	
	If Not AttributeAvailability Then
		
		CallbackDescription = New CallbackDescription("HandlerSetDraftStatus", ThisObject);
		OpenForm("Catalog.GoodsResearchSheets.Form.AttributeUnlocking", 
								New Structure("Object", Object.Ref),,,,,
								CallbackDescription,
								FormWindowOpeningMode.LockOwnerWindow);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SetStatusValid(Command)
	
	SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfGoodsResearchSheet.Valid"));

EndProcedure

#EndRegion

#Region Private

#Region StandardSubsystems

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

// StandardSubsystems.Properties

&AtClient
Procedure UpdateAdditionalAttributesDependencies()
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtClient
Procedure Attachable_OnChangeAdditionalAttribute(Item)
	PropertyManagerClient.UpdateAdditionalAttributesDependencies(ThisObject);
EndProcedure

&AtServer
Procedure PropertiesExecuteDeferredInitialization()
	PropertyManager.FillAdditionalAttributesInForm(ThisObject);
EndProcedure

// End StandardSubsystems.Properties

#EndRegion

#Region CheckKind

&AtClientAtServerNoContext
Procedure QualityIndicatorFillInSelectionList(Form, CheckKind)
	
	Form.Items.ChecksQualityIndicator.ChoiceList.Clear();
	
	ChoiceList = QualityIndicatorGetSelectionList(CheckKind);
	
	For Each ListItem In ChoiceList Do
		Form.Items.ChecksQualityIndicator.ChoiceList.Add(
			ListItem.Value, ListItem.Presentation);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure TypeOfQualityControlFillInSelectionList(Form)
	
	Form.Items.ChecksCheckKind.ChoiceList.Clear();
	
	ChoiceList = TypeOfQualityControlGetSelectionList();
	
	For Each ListItem In ChoiceList Do
		Form.Items.ChecksCheckKind.ChoiceList.Add(
			ListItem.Value, ListItem.Value);
	EndDo;
	
EndProcedure

&AtServerNoContext
Function TypeOfQualityControlGetSelectionList()
	
	Return GoodsResearch.TypeOfCheckGetSelectionList();
	
EndFunction

&AtServerNoContext
Function QualityIndicatorGetSelectionList(CheckKind)
	
	Return GoodsResearch.IndicatorGetSelectionList(CheckKind);
	
EndFunction

&AtServerNoContext
Function ChecksTypeOfCheckAutoSelectionATServer(CheckKind)
	
	Return GoodsResearch.TypeOfCheckGetSelectionListAutoSelection(CheckKind);
	
EndFunction

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure HandlerSetDraftStatus(ClosingResult, AdditionalParameters) Export

	If ClosingResult = True Then
		
		SetNewStatusAndRecord(PredefinedValue("Enum.StatusesOfGoodsResearchSheet.Draft"));
		
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateAdditionalAttributesItems()
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Control")
		Or Initialize Then
		
		TypeOfControlIsSelective = Object.Control = PredefinedValue("Enum.QualityControl.Selective");
		Items.TemplatesFilterOption.Visible = TypeOfControlIsSelective;
		
		If ValueIsFilled(Object.TemplatesFilterOption) And TypeOfControlIsSelective Then
			SamplingOptionPercentage = Object.TemplatesFilterOption = PredefinedValue("Enum.FilterOptionsOfGoodsResearchTemplates.Percent");
			Items.TamplatesNumber.Visible    = Not SamplingOptionPercentage;
			Items.TemplatesPercentage.Visible       = SamplingOptionPercentage;
		Else
			Items.TamplatesNumber.Visible    = False;
			Items.TemplatesPercentage.Visible       = False;
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("TemplatesFilterOption")
		Or Initialize Then
		
		TypeOfControlIsSelective = Object.Control = PredefinedValue("Enum.QualityControl.Selective");
		SamplingOptionPercentage = Object.TemplatesFilterOption = PredefinedValue("Enum.FilterOptionsOfGoodsResearchTemplates.Percent");
		
		If ValueIsFilled(Object.TemplatesFilterOption) And TypeOfControlIsSelective Then
			Items.TamplatesNumber.Visible = Not SamplingOptionPercentage;
			Items.TemplatesPercentage.Visible    = SamplingOptionPercentage;
		Else
			Items.TamplatesNumber.Visible = False;
			Items.TemplatesPercentage.Visible    = False;
		EndIf;
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateScopePresentation()
	
	ScopeView = NStr("vi = 'Phạm vi áp dụng chưa được xác định';
					|ru = 'Область применения не задана';
					|en = 'Scope is not set'; fa = 'Scope is not set';
					|it = 'Scope is not set';
					|pl = 'Scope is not set';
					|tr = 'Uygulama alanı belirtilmemiş'");
	
	If Object.Goods.Count() = 0 Then
		Return;
	EndIf;
	
	VisibleNomenclatureTemplate = NStr("vi = '%1 %2 %3';
										|ru = '%1 %2 %3';
										|en = '%1 %2 %3'; fa = '%1 %2 %3';
										|it = '%1 %2 %3';
										|pl = '%1 %2 %3';
										|tr = '%1 %2 %3'");
	TemplateListOfItems = NStr("vi = '%1 %2';
								|ru = '%1 %2';
								|en = '%1 %2'; fa = '%1 %2';
								|it = '%1 %2';
								|pl = '%1 %2';
								|tr = '%1 %2'");
	TemplateMultiplePositions = NStr("vi = '%1 và hơn nữa %2';
									|ru = '%1 и еще %2';
									|en = '%1 and %2 more'; fa = '%1 and %2 more';
									|it = '%1 and %2 more';
									|pl = '%1 and %2 more';
									|tr = '%1 ve %2 tane daha  '");
	
	FirstPosition = True;
	NumberOfRows = 1;

	For Each LineProducts_ In Object.Goods Do

		If FirstPosition Then
			FirstPosition = False;
			If Object.AssignmentOption = Enums.AssignmentOptionsOfGoodsResearchSheet.ProductKind Then
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(VisibleNomenclatureTemplate, 
					?(ValueIsFilled(LineProducts_.ProductKind), String(LineProducts_.ProductKind) + ";", ""),
					?(ValueIsFilled(LineProducts_.Products), String(LineProducts_.Products) + ";", ""),
					?(ValueIsFilled(LineProducts_.Characteristic), String(LineProducts_.Characteristic) + ";", ""));
			Else
				Presentation = StringFunctionsClientServer.SubstituteParametersToString(TemplateListOfItems,
				?(ValueIsFilled(LineProducts_.Products), String(LineProducts_.Products) + ";", ""),
				?(ValueIsFilled(LineProducts_.Characteristic), String(LineProducts_.Characteristic) + ";", ""));
			EndIf;
		Else
			NumberOfRows = NumberOfRows + 1;
		EndIf;

	EndDo;
	
	If NumberOfRows > 1 Then 
		If CurrentLanguage().LanguageCode = "ru" Then
			PresentationNumberOfPositions = GetStringDeclensionsByNumber("position", NumberOfRows - 1, "",
				"NM=Cardinal", "CS=Nominative; NP=Number");
			ScopeView = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateMultiplePositions, Presentation, PresentationNumberOfPositions[0]);
		Else
			ScopeView = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateMultiplePositions, Presentation, String(NumberOfRows - 1));
		EndIf;
	Else
		Presentation = TrimAll(Presentation);
		StringFunctionsClientServer.DeleteLastCharInString(Presentation);
		ScopeView = Presentation;
	EndIf;
	
EndProcedure

&AtClient
Procedure SetNewStatusAndRecord(Status)

	ClearMessages();
	Cancel = False;

	If Object.DeletionMark Then
		WarningText = NStr("vi = 'Không thể thay đổi trạng thái của sơ đồ nghiên cứu hàng hóa đã được đánh dấu xóa.';
							|ru = 'Нельзя изменить статус помеченной на удаление карты исследования товаров.';
							|en = 'Cannot change the status of a goods research sheet marked for deletion.'; fa = 'Cannot change the status of a goods research sheet marked for deletion.';
							|it = 'Cannot change the status of a goods research sheet marked for deletion.';
							|pl = 'Cannot change the status of a goods research sheet marked for deletion.';
							|tr = 'Silinmek üzere işaretlenmiş ürün inceleme kartının durumu değiştirilemez.'");
		ShowMessageBox( , WarningText);
		Return;
	EndIf;

	If Status = PredefinedValue("Enum.StatusesOfGoodsResearchSheet.Valid") Then

		If Object.Goods.Count() = 0 Then

			MessageText = CommonClientServer.FillingErrorText("Field", "FillType", NStr(
			"vi = 'Áp dụng cho';
			|ru = 'Применяется к';
			|en = 'Applies to'; fa = 'اعمال بر';
			|it = 'Applies to';
			|pl = 'Applies to';
			|tr = 'Uygulanır'"), , , NStr(
			"vi = 'Chưa chỉ định phạm vi áp dụng của sơ đồ nghiên cứu hàng hóa';
			|ru = 'Не указана область применения карты исследования товаров';
			|en = 'The scope of the goods research sheet is not specified'; fa = 'The scope of the goods research sheet is not specified';
			|it = 'The scope of the goods research sheet is not specified';
			|pl = 'The scope of the goods research sheet is not specified';
			|tr = 'Ürün inceleme kartının uygulama alanı belirtilmemiş'"));
			CommonClient.MessageToUser(MessageText, , "ScopeView", , Cancel);

		EndIf;

	EndIf;

	If Not Cancel Then

		RecordStudyMapATServer(Status);

	EndIf;

EndProcedure

&AtServer
Function RecordStudyMapATServer(Val Status = Undefined)
	
	Result      = False;
	ChangeStatus_ = Status <> Undefined And Object.Status <> Status;
	
	If ChangeStatus_ Then
		CurrentStatus = Object.Status;
		Object.Status = Status;
	EndIf;
	
	Try
		
		Result = Write();
		
	Except
		
		If ChangeStatus_ Then
			EventLogEvent = NStr("vi = 'Không thể thay đổi trạng thái của sơ đồ nghiên cứu hàng hóa';
								|ru = 'Не удалось изменить статус карты исследования товаров';
								|en = 'Cannot change the goods research sheet status'; fa = 'Cannot change the goods research sheet status';
								|it = 'Cannot change the goods research sheet status';
								|pl = 'Cannot change the goods research sheet status';
								|tr = 'Ürün inceleme kartının durumu değiştirilemedi'",
				Common.DefaultLanguageCode());
		Else
			EventLogEvent = NStr("vi = 'Không thể ghi lại sơ đồ nghiên cứu hàng hóa';
								|ru = 'Не удалось записать карту исследования товаров';
								|en = 'Cannot save the goods research sheet'; fa = 'Cannot save the goods research sheet';
								|it = 'Cannot save the goods research sheet';
								|pl = 'Cannot save the goods research sheet';
								|tr = 'Ürün inceleme kartı kaydedilemedi'",
				Common.DefaultLanguageCode());
		EndIf;
		
		WriteLogEvent(
			EventLogEvent,
			EventLogLevel.Error,
			,
			,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	If ChangeStatus_ And Not Result Then
		Object.Status = CurrentStatus;
	EndIf;
	
	Return Result;

EndFunction

// Notification of the End of setting the scope of the goods research map
// 
// Parameters:
// 	SettingsResult - Structure - From:
// 		* SelectionByProperties - ValueTable - selection table by properties
// 		* LongDesc - String - configuration description
// 	AdditionalParameters - Structure - advanced setting
&AtClient
Procedure OpenScopeEntryFormEnd(SettingsResult, AdditionalParameters) Export
	
	If SettingsResult = Undefined Then
		Return;
	EndIf;
	
	Modified = True;
	
	GoodsResearchClient.UpdateTablePart(
		Object.SelectionByProperties,
		SettingsResult.SelectionByProperties);
		
	GoodsResearchClient.UpdateTablePart(
		Object.Goods,
		SettingsResult.ItemList);
	
	Object.AssignmentOption = SettingsResult.SettingsMode;
	
	UpdateScopePresentation();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()

	SetAvailabilityOfItemsByStatusServer();
	SetAvailabilityOfStatusChangeCommands();
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsByStatusServer()
	
	If ReadOnly Then
		Return;
	EndIf;
	
	AttributeAvailability = (Object.Status = Enums.StatusesOfGoodsResearchSheet.Draft);
	
	ItemArray = Catalogs.GoodsResearchSheets.GetObjectAttributesToLock();

	TMCommonUseClientServer.SetPropertyOfFormElements(Items, ItemArray, "ReadOnly", Not AttributeAvailability);
	
	AreaNameActions = Items.ScopeView.Name;
	ScopeElement = ItemArray.Find(AreaNameActions);
	If ScopeElement <> Undefined Then
		TMCommonUseClientServer.SetFormItemProperty(Items, AreaNameActions, "ReadOnly", Not AttributeAvailability);
	EndIf;
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfStatusChangeCommands()
	
	Items.SetStatusValid.Enabled	= (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Valid);
	Items.SetStatusClosed.Enabled	= (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Closed_);
	Items.SetDraftStatus.Enabled	= (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Draft);

EndProcedure

&AtServer
Procedure CheckClearAttributesOnChangingTypeOfControl()
	
	TypeOfControlIsSolid = Object.Control = PredefinedValue("Enum.QualityControl.Solid");

	If TypeOfControlIsSolid Then
		Object.TamplatesNumber = 0;
		Object.TemplatesPercentage = 0;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Control");
	
EndProcedure

&AtServer
Procedure CheckClearAttributesONChangingSamplingOption()
	
	SamplingOptionPercentage = Object.TemplatesFilterOption = PredefinedValue("Enum.FilterOptionsOfGoodsResearchTemplates.Percent");

	If SamplingOptionPercentage Then
		Object.TamplatesNumber = 0;
	Else
		Object.TemplatesPercentage = 0;
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "TemplatesFilterOption");
	
EndProcedure

&AtServer
Procedure SetVisibility1()
	
	ThereIsChangeAccess = AccessRight("Update", Metadata.Catalogs.GoodsResearchSheets);
	AttributeAvailability = (Object.Status = Enums.StatusesOfGoodsResearchSheet.Draft);
	
	Items.SetStatusValid.Enabled = ThereIsChangeAccess And (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Valid);
	Items.SetStatusClosed.Enabled = ThereIsChangeAccess And (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Closed_);
	Items.SetDraftStatus.Enabled = ThereIsChangeAccess And (Object.Status <> Enums.StatusesOfGoodsResearchSheet.Draft);
	Items.ScopeView.ReadOnly = Not (ThereIsChangeAccess And AttributeAvailability);
	
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
