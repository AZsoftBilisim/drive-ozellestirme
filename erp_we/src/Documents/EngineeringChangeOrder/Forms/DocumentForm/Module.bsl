
#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

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
	
	VisibilityManagement(ThisObject);
	
	SetAvailabilityOfClipboardCommands(ThisObject, ProcessingOfTabularForms.ThereAreLinesInClipboard());
	
	AdjustVisibilityOfScope(ThisObject);
	AdjustVisibilityOfReplacementPage(ThisObject);
	ConfigureReplacementPriorityField(ThisObject);
	ConfigureSchedulingField(ThisObject);
	
	
		ThereIsOutdatedObject = False;
		
		For Each ScopeString In Object.AreasOfAction Do
			
			If ValueIsFilled(ScopeString.SalesOrder) 
			 Or ValueIsFilled(ScopeString.ProductionOrder) 
			   And TypeOf(ScopeString.ProductionOrder) <> Type("DocumentRef.ProductionOrder2_2") Then
			
				ThereIsOutdatedObject = True;
				Break;
			
			EndIf;	
		
		EndDo;
		
		If ThereIsOutdatedObject Then
			Items.AreasOfAction.ReadOnly = True;
			Items.ScopesSubmenuToFillIn.Enabled = False;
		Else
			Items.AreasOfActionProductionOrder.TypeRestriction = New TypeDescription("DocumentRef.ProductionOrder2_2");
		EndIf;
		
		
	If Not RightToConductStagesIsAvailable Then
		Items.FormReplace_With_Analogues.Visible = False;
	EndIf;
	
	ReplacementOptionBeforeChange = Object.ReplacementOption;
	MultipleIndication = NStr("vi = 'Tùy chỉnh chỉ ra vùng thao tác';
								|ru = 'Настроить множественное указание области действия';
								|en = 'Set up multiple scopes'; fa = 'Set up multiple scopes';
								|it = 'Настроить множественное указание области действия';
								|pl = 'Set up multiple scopes';
								|tr = 'Çoklu kapsam göstergesini yapılandırma'");
		
	// StandardSubsystems.Properties
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	PropertyManager.OnCreateAtServer(ThisObject, AdditionalParameters);
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands

	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.OnCreateAtServer(ThisObject);
	// End IntegrationWith1CDocumentManagementSubsystem

	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);

	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
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
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	// Handler of the "Date-change" mechanism
	PeriodClosingDates.ObjectOnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.Properties
	PropertyManager.OnReadAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisObject, CurrentObject);
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM" Then
		
		If Not IsTempStorageURL(ValueSelected) Then
			Return;
		EndIf;
		
		Modified = True;
		
		SelectionOfMaterialsAccordingToSpecification(ValueSelected);
		
	ElsIf ChoiceSource.FormName = "Document.EngineeringChangeOrder.Form.ScopeInputForm" Then
		
		Modified = True;
		
		SelectionValue = ValueSelected.SelectionValue;
		
		If Not SelectionValue.MultipleIndication Then
	
			ListOfProperties = "LineOfBusiness,"
						+ "ProductionOrder,"
						+ "SalesOrder,"
						+ "Department,"
						+ "BillOfMaterials,"
						+ "Stage,"
						+ "Product,"
						+ "ItemVariantOfProduct";
						
			If Object.AreasOfAction.Count() > 0 Then
				
				BillOfMaterialsBeforeSelection = Object.AreasOfAction[0].BillOfMaterials;
				StageBeforeSelection = Object.AreasOfAction[0].Stage;
				
				If BillOfMaterialsBeforeSelection <> SelectionValue.BillOfMaterials Or StageBeforeSelection <> SelectionValue.Stage Then
					Object.UsedMaterials.Clear();
				EndIf;
				
				Object.AreasOfAction.Clear();
				
			EndIf;
			
			ScopeString = Object.AreasOfAction.Add();
			FillPropertyValues(ScopeString, SelectionValue, ListOfProperties);
			
		Else
			
			ThereIsDifferenceInSetting = False;
			For Each TSRow In Object.AreasOfAction Do
				
				If TSRow.Stage <> SelectionValue.Stage
				   And Not ThereIsDifferenceInSetting Then
				
					ThereIsDifferenceInSetting = True;
					Break;
				
				EndIf;
				
				If TSRow.BillOfMaterials <> SelectionValue.BillOfMaterials
				   And Not ThereIsDifferenceInSetting Then
				
					ThereIsDifferenceInSetting = True;
					Break;
				
				EndIf;

			EndDo;

			If ThereIsDifferenceInSetting Then
				Object.UsedMaterials.Clear();
			EndIf;
			
			ListOfProperties = "BillOfMaterials, Stage, Product, ItemVariantOfProduct";
			CurrentData = Items.AreasOfAction.CurrentData;
			FillPropertyValues(CurrentData, SelectionValue, ListOfProperties);
			FillInFinishedProductPresentation(CurrentData);
		
		EndIf;
		
		UpdateScopePresentation();
		
		VisibilityManagement(ThisObject);
		DetermineAvailabilityOfReplacementOption(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "CopyingLinesToClipboard" Then
		SetAvailabilityOfClipboardCommands(ThisObject, True);
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInServiceDetails();
	CustomizeFormElements();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisObject, CurrentObject, WriteParameters);

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

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	// StandardSubsystems.Properties
	PropertyManager.BeforeWriteAtServer(ThisObject, CurrentObject);
	// End StandardSubsystems.Properties
	
	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisObject, Cancel, CurrentObject, WriteParameters);
	
	// IntegrationWith1CDocumentManagementSubsystem
	IntegrationWith1CDocumentManagementCore.BeforeWriteAtServer(ThisObject, CurrentObject, WriteParameters);
	// End IntegrationWith1CDocumentManagementSubsystem
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ScopeViewClick(Item, StandardProcessing)
	
	ClearMessages();
	StandardProcessing = False;
	
	If Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList") Then
	
		MessageText = NStr("vi = 'Không cho phép chỉ ra vùng thao tác đối với phương án thay thế ""Danh sách vật tư tương tự""';
							|ru = 'Указание области действия недоступно для варианта замены ""Список аналогов""';
							|en = 'Cannot specify the scope for the ""Substitute list"" replacement option'; fa = 'Cannot specify the scope for the ""Substitute list"" replacement option';
							|it = 'Указание области действия недоступно для варианта замены ""Список аналогов""';
							|pl = 'Cannot specify the scope for the ""Substitute list"" replacement option';
							|tr = '""İkamelerin listesi"" değiştirme seçeneği için kapsam belirlemek mümkün değildir.'");
		CommonClient.MessageToUser(MessageText);
		Return;
	
	EndIf;
	
	If Object.AreasOfAction.Count() = 0 Then
		ScopeString = Object.AreasOfAction.Add();
	Else
		ScopeString = Object.AreasOfAction[0];
	EndIf;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("LineOfBusiness", ScopeString.LineOfBusiness);
	FormParameters.Insert("ProductionOrder", ScopeString.ProductionOrder);
	FormParameters.Insert("SalesOrder", ScopeString.SalesOrder);
	FormParameters.Insert("Department", ScopeString.Department);
	FormParameters.Insert("BillOfMaterials", ScopeString.BillOfMaterials);
	FormParameters.Insert("Stage", ScopeString.Stage);
	FormParameters.Insert("Product", ScopeString.Product);
	FormParameters.Insert("ItemVariantOfProduct", ScopeString.ItemVariantOfProduct);
	FormParameters.Insert("QuantityOfMaterials", Object.UsedMaterials.Count());
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("MultipleScopeIndication", False);
	
	OpenForm("Document.EngineeringChangeOrder.Form.ScopeInputForm", FormParameters, ThisObject);
	
EndProcedure

&AtClient
Procedure BasisStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	CommonClient.ShowCommentEditingForm(
		Item.EditText,
		ThisObject,
		"Object.UsageNote",
		NStr("vi = 'Hướng dẫn sử dụng';
			|ru = 'Указание по применению';
			|en = 'Usage note'; fa = 'یادداشت استفاده';
			|it = 'Indicazione d''uso';
			|pl = 'Wskazówki dotyczące zastosowania';
			|tr = 'Kullanım notu'"));
	
EndProcedure

&AtClient
Procedure StatusOnChange(Item)
	
	If Object.Status 
			= PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Confirmed")
		And Not ValueIsFilled(Object.ValidityStartDate) Then
		
		Object.ValidityStartDate = CommonClient.SessionDate();
		
	ElsIf Object.Status 
			= PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Terminated") Then
			
		Object.ValidityEndDate = CommonClient.SessionDate();
		
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Status");
	
EndProcedure

&AtClient
Async Procedure ReplacementOptionOnChange(Item)
	
	ClearMessages();
	AskQuestion_ = False;
	ChangeIsAvailable = True;
	OptionList = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList");
	
	If ReplacementOptionBeforeChange <> OptionList
	   And Object.ReplacementOption = OptionList Then
	
		ThereAreLinesOfAnalogs = Object.Substitutes.Count() > 0;
		
		If ThereAreLinesOfAnalogs Then
			
			QueryText = NStr("vi = 'Việc thay đổi phương án thay thế dẫn đến không thể nhập vùng thao tác và mất dữ liệu của tập hợp vật tư tương tự. Tiếp tục?';
							|ru = 'Изменение варианта замены приведет к невозможности ввода области действия и потере данных набора аналогов. Продолжить?';
							|en = 'If you change the replacement option, you will not be able to enter the scope and will lose the substitute set data. Continue?'; fa = 'If you change the replacement option, you will not be able to enter the scope and will lose the substitute set data. Continue?';
							|it = 'Изменение варианта замены приведет к невозможности ввода области действия и потере данных набора аналогов. Продолжить?';
							|pl = 'If you change the replacement option, you will not be able to enter the scope and will lose the substitute set data. Continue?';
							|tr = 'Değiştirme seçeneğinin değiştirilmesi kapsama girilememesine ve ikame set verilerinin kaybına yol açacaktır. Devam edilsin mi?'");
			AskQuestion_ = True;
			
		EndIf;
		
	EndIf;
	
	If AskQuestion_ Then
	
		Promise = DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo, , DialogReturnCode.Yes);
		Result = Await Promise;
		
		If Result = DialogReturnCode.Yes Then
			PerformActionsWhenChangingReplacementOption();
		Else
			Object.ReplacementOption = ReplacementOptionBeforeChange;
		EndIf;
		
	ElsIf ChangeIsAvailable Then
		
		PerformActionsWhenChangingReplacementOption();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ReplacementPriorityOnChange(Item)
	
	ConfigureSchedulingField(ThisObject);
	DetermineAvailabilityOfReplacementOption(ThisObject);
		
	If Object.ReplacementPriority = PredefinedValue("Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute") Then
		
		Object.InterchangeableSubstitutes = False;
		
	EndIf;
	
	If Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList") Then
	
		Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SetToSet");
		PerformActionsWhenChangingReplacementOption();
	
	EndIf;
	
EndProcedure

&AtClient
Procedure MultipleIndicationClick(Item, StandardProcessing)
	
	StandardProcessing = False;
	Items.GroupMultipleScope.Visible = True;
	Items.MultipleIndication.Visible = False;
	Items.ScopeView.Visible = False;
	
	If Object.AreasOfAction.Count() > 0 Then
		
		ScopeString = Object.AreasOfAction[0];
		FillInFinishedProductPresentation(ScopeString);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure ScopesFinishedProductStartChoice(Item, ChoiceData, ChoiceByAdding, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.AreasOfAction.CurrentData;
	
	FormParameters = New Structure;
	
	FormParameters.Insert("LineOfBusiness", CurrentData.LineOfBusiness);
	FormParameters.Insert("ProductionOrder", CurrentData.ProductionOrder);
	FormParameters.Insert("SalesOrder", CurrentData.SalesOrder);
	FormParameters.Insert("Department", CurrentData.Department);
	FormParameters.Insert("BillOfMaterials", CurrentData.BillOfMaterials);
	FormParameters.Insert("Stage", CurrentData.Stage);
	FormParameters.Insert("Product", CurrentData.Product);
	FormParameters.Insert("ItemVariantOfProduct", CurrentData.ItemVariantOfProduct);
	FormParameters.Insert("QuantityOfMaterials", Object.UsedMaterials.Count());
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("MultipleScopeIndication", True);
	
	OpenForm("Document.EngineeringChangeOrder.Form.ScopeInputForm", FormParameters, ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsOnChange(Item)
	
	CheckDocumentDataByLinesTS(ThisObject);
	
EndProcedure

&AtClient
Procedure UsedMaterialsBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		FillRowID(Items.UsedMaterials.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure UsedMaterialsBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	If NewRow Then
		FillRowID(Items.UsedMaterials.CurrentData);
	EndIf;	
	
EndProcedure

&AtClient
Procedure UsedMaterialsProductsOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(StructureOfActions, CurrentRow, "UsedMaterials");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure SelectMaterialsAccordingToTheSpecification(Command)
	
	OpenForm(
		"Catalog.BillsOfMaterials.Form.SelectMaterialsByBOM",
		ParametersForMatchingSpecifications(),
		ThisObject, 
		UUID,,,, 
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure MaterialsToInsertRows(Command)
	
	GetLinesFromClipboard("UsedMaterials");
	
EndProcedure

&AtClient
Procedure MaterialsCopyOfTheString(Command)
	
	CopyTSLines("UsedMaterials", "UsedMaterials");
	
EndProcedure

&AtClient
Procedure UsedMaterials_ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportQuantity = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FillInMaterials", True);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	ProcessFieldSelectionInTable("UsedMaterials", Field, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSubstitutes

&AtClient
Procedure SubstitutesOnChange(Item)
	
	CheckDocumentDataByLinesTS(ThisObject);
	
EndProcedure

&AtClient
Procedure SubstitutesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		FillRowID(Items.Substitutes.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstitutesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	If NewRow Then
		FillRowID(Items.Substitutes.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure SubstitutesProductsOnChange(Item)
	
	CurrentRow = Items.Substitutes.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(StructureOfActions, CurrentRow, "Substitutes");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure AnalogsInsertLines(Command)
	
	GetLinesFromClipboard("Substitutes");
	
EndProcedure

&AtClient
Procedure AnalogsCopyStrings(Command)
	
	CopyTSLines("Substitutes", "Substitutes");
	
EndProcedure

&AtClient
Procedure Substitutes_ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportQuantity = True;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FillInMaterials", False);
	
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure SubstitutesSelection(Item, RowSelected, Field, StandardProcessing)
	ProcessFieldSelectionInTable("Substitutes", Field, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersMaterialsListOfAnalogues

&AtClient
Procedure MaterialsListOfAnaloguesItemOnChange(Item)
	
	CurrentRow = Items.MaterialsListOfAnalogues.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddActionsToStructureWhenChangingProducts(StructureOfActions, CurrentRow, "UsedMaterials");
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnaloguesBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If CancelEdit Then
		Return;
	EndIf;
	
	If NewRow Then
		
		CurrentData = Items.MaterialsListOfAnalogues.CurrentData;
		CurrentData.NumberOfPackages = 1;
		FillRowID(CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnaloguesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	
	If Copy Then
		FillRowID(Items.MaterialsListOfAnalogues.CurrentData);
	EndIf;
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnalogues_CopyRows(Command)
	
	CopyTSLines("UsedMaterials", "MaterialsListOfAnalogues");
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnalogues_InsertRows(Command)
	
	GetLinesFromClipboard("UsedMaterials");
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnalogues_ImportFromExternalFile(Command)
	
	ImportParameters = ProcessingOfTabularFormsClient.ProductLoadingParameters();
	ImportParameters.ImportQuantity = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("FillInMaterials", True);
		
	Notification = New CallbackDescription("ImportFromExternalFileCompletion", ThisObject, AdditionalParameters);
	ProcessingOfTabularFormsClient.ShowProductUploadForm(ImportParameters, Notification);
	
EndProcedure

&AtClient
Procedure MaterialsListOfAnaloguesSelection(Item, RowSelected, Field, StandardProcessing)
	ProcessFieldSelectionInTable("MaterialsListOfAnalogues", Field, StandardProcessing);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAreasOfAction

&AtClient
Procedure AreasOfActionOnChange(Item)
	
	DetermineAvailabilityOfReplacementOption(ThisObject);
	
EndProcedure

&AtClient
Procedure AreasOfActionAfterDeleteRow(Item)
	
	If Object.AreasOfAction.Count() = 0 Then
		Object.AreasOfAction.Add();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
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

&AtClient
Procedure WriteDocument(Command)
	
	TMCommonUseClient.Write(ThisObject);
	
EndProcedure

&AtClient
Procedure PostDocument(Command)
	
	TMCommonUseClient.Post(ThisObject);
	
EndProcedure

&AtClient
Procedure PostAndClose(Command)
	
	TMCommonUseClient.PostAndClose(ThisObject);
	
EndProcedure

&AtClient
Procedure SetDateIntervalExecute(Command)
	
	TMCommonUseClient.EditPeriod(Object, 
		New Structure("StartDate, EndDate", "ValidityStartDate", "ValidityEndDate"));
	
EndProcedure

&AtClient
Async Procedure Replace_With_Analogues(Command)
	
	ClearMessages();
	ContinueExecution = True;
	
	If Modified Then
		
		QueryText = NStr("vi = 'Cần kết chuyển chứng từ để thực hiện giao dịch. Ghi lại chứng từ?';
						|ru = 'Необходимо провести документ для выполнения операции. Записать документ?';
						|en = 'To proceed, post the document. Save the document?'; fa = 'To proceed, post the document. Save the document?';
						|it = 'To proceed, post the document. Save the document?';
						|pl = 'To proceed, post the document. Save the document?';
						|tr = 'İşlemi gerçekleştirmek için belgenin kaydedilmesi gerekir. Belge kaydedilsin mi?'");
		Result = Await DoQueryBoxAsync(QueryText, QuestionDialogMode.YesNo);
		ContinueExecution = Result = DialogReturnCode.Yes;
		
		If ContinueExecution Then
		
			WriteParameters = New Structure("WriteMode", DocumentWriteMode.Posting);
			ContinueExecution = Write(WriteParameters);
		
		EndIf;
	
	EndIf;
	
	If ContinueExecution Then
	
		FormParameters = StructureOfFormParameters();
	
		OneToOneReplacement = Object.UsedMaterials.Count() = 1;
		
		FormParameters.OneToOneReplacement = OneToOneReplacement;
		
		If OneToOneReplacement Then
			
			ContentLine = Object.UsedMaterials[0];
			FormParameters.Material = ContentLine.Products;
			FormParameters.ItemVariantOfMaterial = ContentLine.Characteristic;
			
		EndIf;
			
		FormParameters.Resolution = Object.Ref;
		FormParameters.ReplacementPriority = Object.ReplacementPriority;
		FormParameters.RoleOfAnalogues = RoleOfDocumentAnalogues();
		
		OpenForm("Document.EngineeringChangeOrder.Form.ReplacementWizard", FormParameters, ThisObject);
	
	EndIf;

EndProcedure

&AtClient
Procedure AreasOfAction_PickUpProductionOrders(Command)
	
	ObjectTypes_ = New Array;
	ObjectTypes_.Add(Type("DocumentRef.ProductionOrder2_2"));
	
	SelectionSettings = New Structure;
	SelectionSettings.Insert("ObjectTypes_", ObjectTypes_);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("SelectionOfProductionOrders", True);
	
	OpenForm(
		"Document.EngineeringChangeOrder.Form.PickOrders",
		SelectionSettings,
		ThisObject,
		,
		,
		,
		New CallbackDescription("PickUpOrdersCompletion",
		ThisObject,
		AdditionalParameters),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Scopes_FillInLineOfBusiness(Command)
	
	SelectedRows = Items.AreasOfAction.SelectedRows;
	
	OpenForm(
		"Catalog.LinesOfBusiness.ChoiceForm",
		,
		ThisObject,
		,
		,
		,
		New CallbackDescription("FillInDirectionOfActivityCompletion",
		ThisObject,
		New Structure("SelectedRows", SelectedRows)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Scopes_FillInDivision(Command)
	
	SelectedRows = Items.AreasOfAction.SelectedRows;
	
	OpenForm(
		"Catalog.BusinessStructure.ChoiceForm",
		,
		ThisObject,
		,
		,
		,
		New CallbackDescription("FillInTheDepartmentCompletion",
		ThisObject,
		New Structure("SelectedRows", SelectedRows)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure Scopes_FillInFinishedProduct(Command)
	
	SelectedRows = Items.AreasOfAction.SelectedRows;
	FormParameters = New Structure;
	
	FormParameters.Insert("LineOfBusiness", Undefined);
	FormParameters.Insert("ProductionOrder", Undefined);
	FormParameters.Insert("SalesOrder", Undefined);
	FormParameters.Insert("Department", Undefined);
	FormParameters.Insert("BillOfMaterials", Undefined);
	FormParameters.Insert("Stage", Undefined);
	FormParameters.Insert("Product", Undefined);
	FormParameters.Insert("ItemVariantOfProduct", Undefined);
	FormParameters.Insert("QuantityOfMaterials", Object.UsedMaterials.Count());
	FormParameters.Insert("ReadOnly", ReadOnly);
	FormParameters.Insert("MultipleScopeIndication", True);
	
	OpenForm(
		"Document.EngineeringChangeOrder.Form.ScopeInputForm",
		FormParameters,
		ThisObject,
		,
		,
		,
		New CallbackDescription("FillInFINISHEDProductCompletion",
		ThisObject,
		New Structure("SelectedRows", SelectedRows)),
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure 

&AtClient
Procedure Scopes_CloseMultipleSettings(Command)
	
	ClearMessages();
	
	If Object.AreasOfAction.Count() = 1 Then
		AdjustVisibilityOfScope(ThisObject);
		UpdateScopePresentation();
		DetermineAvailabilityOfReplacementOption(ThisObject);
	Else	
		Text = NStr("vi = 'Để đóng tùy chỉnh nhiều vùng thao tác cần chỉ còn một dòng trong phần bảng.';
					|ru = 'Для закрытия множественной настройки области действия необходимо, чтобы в табличной части осталась только одна строка.';
					|en = 'To close the multiple scope setting, leave only one row in the table.'; fa = 'To close the multiple scope setting, leave only one row in the table.';
					|it = 'Для закрытия множественной настройки области действия необходимо, чтобы в табличной части осталась только одна строка.';
					|pl = 'To close the multiple scope setting, leave only one row in the table.';
					|tr = 'Çoklu kapsam ayarını kapatmak için tablo bölümünde yalnızca bir satırın kalması gerekir.'");
		CommonClient.MessageToUser(Text);
	EndIf;
	
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

// StandardSubsystems.Properties
&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure
// End StandardSubsystems.Properties

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	#Region StandardAppearance
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			 "UsedMaterialsCharacteristic",
																		     "Object.UsedMaterials.ItemVariantsAreUsed");

	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																			 "SubstitutesCharacteristic",
																		     "Object.Substitutes.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(ThisObject, 
																		 "MaterialsListOfAnaloguesCharacteristic",
																	     "Object.UsedMaterials.ItemVariantsAreUsed");

	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UsedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.UsedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
																   
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SubstitutesProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.Substitutes.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	#EndRegion
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ValidityEndDate.Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.Use = True;
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	                                                                                
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.StatusesOfEngineeringChangeOrders.Terminated;
	
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.ValidityEndDate");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AreasOfActionDepartment.Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.Use = True;
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	                                                                                
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AreasOfAction.Department");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.BusinessStructure.EmptyRef();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tất cả bộ phận>';
													|ru = '<все подразделения>';
													|en = '<all business units>'; fa = '<all business units>';
													|it = '<все подразделения>';
													|pl = '<all business units>';
													|tr = '<tüm departmanlar>'"));
    Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AreasOfActionProductPresentation.Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.Use = True;
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	                                                                                
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AreasOfAction.ProductPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "";
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tất cả sản phẩm>';
													|ru = '<все изделия>';
													|en = '<all finished products>'; fa = '<all finished products>';
													|it = '<все изделия>';
													|pl = '<all finished products>';
													|tr = '<tüm nihai ürünler>'"));
    Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AreasOfActionProductionOrder.Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.Use = True;
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	                                                                                
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AreasOfAction.ProductionOrder");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tất cả đơn hàng>';
													|ru = '<все заказы>';
													|en = '<all orders>'; fa = '<all orders>';
													|it = '<все заказы>';
													|pl = '<wszystkie zamówienia>';
													|tr = '<tüm siparişler>'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AreasOfActionLineOfBusiness.Name);
	
	FilterOrGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterOrGroup.Use = True;
	FilterOrGroup.GroupType = DataCompositionFilterItemsGroupType.AndGroup;
	                                                                                
	ItemFilter = FilterOrGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.AreasOfAction.LineOfBusiness");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Catalogs.LinesOfBusiness.EmptyRef();
	
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<tất cả hướng hoạt động>';
													|ru = '<все направления деятельности>';
													|en = '<all lines of business>'; fa = '<all lines of business>';
													|it = '<все направления деятельности>';
													|pl = '<all lines of business>';
													|tr = '<tüm iş kolları>'"));
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	FillInServiceDetails();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	CheckDocumentDataByLinesTS(ThisObject);
	UpdateScopePresentation();
	
	ConfigureDependentFormElements(ThisObject);
	
	AdjustVisibilityOfScope(ThisObject);
	AdjustVisibilityOfReplacementPage(ThisObject);
	ConfigureReplacementPriorityField(ThisObject);
	ConfigureSchedulingField(ThisObject);
	DetermineAvailabilityOfReplacementOption(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Object = Form.Object;
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
		
	If AttributesStructure1.Property("Status")
		Or Initialize Then
		
		Items.ValidityEndDate.AutoMarkIncomplete = 
			(Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Terminated"));
			
		AvailableUpdate = ChangeByStatusIsAvailable(Form);
		
		Replacement_IsAvailable = Form.RightToConductStagesIsAvailable And Object.Posted
			And Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Confirmed");
		Items.FormReplace_With_Analogues.Visible = Replacement_IsAvailable;
		
		ItemsNames = New Array; // Array of String
		ItemsNames.Add("AreasOfAction");
		ItemsNames.Add("ReplacementGroupSet");
		ItemsNames.Add("GroupReplacementList");
			
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items, ItemsNames, "ReadOnly", Not AvailableUpdate);
			
		ItemsNames = New Array; // Array of String
		ItemsNames.Add("ContextMenuAnalogsInsertLines");
		ItemsNames.Add("MaterialsCopyOfTheString");
		ItemsNames.Add("MaterialsToInsertRows");
		ItemsNames.Add("UsedMaterials_ImportFromExternalFile");
		ItemsNames.Add("SelectMaterialsAccordingToTheSpecification");
		ItemsNames.Add("ContextMenuMaterialsCopyLines");
		ItemsNames.Add("ContextMenuMaterialsInsertLines");
		ItemsNames.Add("AnalogsCopyStrings");
		ItemsNames.Add("AnalogsInsertLines");
		ItemsNames.Add("Substitutes_ImportFromExternalFile");
		ItemsNames.Add("ContextMenuAnalogsCopyStrings");
		ItemsNames.Add("MaterialsListOfAnalogues_CopyRows");
		ItemsNames.Add("MaterialsListOfAnalogues_InsertRows");
		ItemsNames.Add("MaterialsListOfAnalogues_ImportFromExternalFile");
		ItemsNames.Add("ContextMenuMaterials_CopyLinesList");
		ItemsNames.Add("ContextMenuMaterials_InsertLinesList");
		ItemsNames.Add("AreasOfAction_PickUpProductionOrders");
		ItemsNames.Add("Scopes_FillInLineOfBusiness");
		ItemsNames.Add("Scopes_FillInDivision");
		ItemsNames.Add("Scopes_FillInFinishedProduct");
		ItemsNames.Add("Scopes_CloseMultipleSettings");
		ItemsNames.Add("ReplacementOption");
		ItemsNames.Add("ScopeView");
		ItemsNames.Add("MultipleIndication");
		ItemsNames.Add("ReplacementPriority");
		ItemsNames.Add("UseItForAutocorrectInOrders");
		
		TMCommonUseClientServer.SetPropertyOfFormElements(
			Items, ItemsNames, "Enabled", AvailableUpdate);
			
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInServiceDetails()
	
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	YouCanSpecifyReplacementPriority = DynamicStructure;
	ProductionIsUsed2_2 = True;
	
	
	RightToConductStagesIsAvailable = ProductionIsUsed2_2 And AccessRight("Posting", Metadata.Documents.ProductionStage2_2);
	
	FillInFeatureAttribute = New Structure("Products", "ItemVariantsAreUsed");
	FillInProductTypeAttribute_ = New Structure("Products", "ItemsType");
	
	StructureOfActions = New Structure("FillInFeatureAttribute, FillInProductTypeAttribute_",
		FillInFeatureAttribute,
		FillInProductTypeAttribute_);
		
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.UsedMaterials, StructureOfActions);
		
	ProductsServer.FillInServiceDetailsForProductInCollection(
		Object.Substitutes, StructureOfActions);
		
	For Each TSRow In Object.AreasOfAction Do
		FillInFinishedProductPresentation(TSRow);
	EndDo;
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	RowsToProcess = New Array;
	For Each TSRow In Object.UsedMaterials Do
		RowsToProcess.Add(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.UsedMaterials);
		
	RowsToProcess = New Array;
	For Each TSRow In Object.Substitutes Do
		RowsToProcess.Add(TSRow);
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		RowsToProcess,
		StructureOfActions,
		Object.Substitutes);
		
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionsToStructureWhenChangingProducts(StructureOfActions, CurrentRow, TSName)

	StructureOfActions.Insert("FillInProductTypeAttribute", New Structure("Products", "ProductKind"));
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentRow.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner", CurrentRow.Package);
	StructureOfActions.Insert("ProductsOnChangeOverridable", New Structure("FormName, TabularSectionName", "DocumentForm", TSName));
	
EndProcedure

&AtServer
Procedure UpdateScopePresentation()
	
	If Object.AreasOfAction.Count() = 0 Then
		
		ScopeView = NStr("vi = 'Đối với toàn bộ Tập đoàn';
						|ru = 'По предприятию в целом';
						|en = 'By the entire enterprise'; fa = 'By the entire enterprise';
						|it = 'Per la società in toto';
						|pl = 'Dla przedsiębiorstwa jako całości';
						|tr = 'İşletme hedefine göre'");
		Return;
		
	EndIf;
	
	ScopeString = Object.AreasOfAction[0];
	ScopeView = "";
	SubstringsArray = New Array;
	
	If ValueIsFilled(ScopeString.ProductionOrder) Then
		
		ObjectAttributes = Common.ObjectAttributesValues(ScopeString.ProductionOrder, "Number, Date");
		
		Template = NStr("vi = 'Đơn hàng sản xuất: Số %1 ngày %2';
						|ru = 'Заказ на производство: №%1 от %2';
						|en = 'Production order: No.%1 dated %2'; fa = 'Production order: No.%1 dated %2';
						|it = 'Заказ на производство: №%1 от %2';
						|pl = 'Production order: No.%1 dated %2';
						|tr = 'Üretim emri: %2 tarihli %1 numaralı;'");
		SubstringsArray.Add(StrTemplate(Template,
			ObjectsPrefixesClientServer.NumberForPrinting(ObjectAttributes.Number),
			Format(ObjectAttributes.Date, "DLF=D")));
		
	EndIf;
	
	If ValueIsFilled(ScopeString.SalesOrder) Then
		
		ObjectAttributes = Common.ObjectAttributesValues(ScopeString.SalesOrder, "Number, Date");
		
		Template = NStr("vi = 'Đơn hàng của khách: Số %1 ngày %2';
						|ru = 'Заказ клиента: №%1 от %2';
						|en = 'Sales order: No.%1 dated %2'; fa = 'Sales order: No.%1 dated %2';
						|it = 'Заказ клиента: №%1 от %2';
						|pl = 'Sales order: No.%1 dated %2';
						|tr = 'Satış siparişi: %2 tarihli %1 numaralı;'");
		SubstringsArray.Add(StrTemplate(Template,
			ObjectsPrefixesClientServer.NumberForPrinting(ObjectAttributes.Number),
			Format(ObjectAttributes.Date, "DLF=D")));
		
	EndIf;
	
	If ValueIsFilled(ScopeString.BillOfMaterials) Then
		
		Template = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất: %1';
						|ru = 'Спецификация: %1';
						|en = 'Bill of materials: %1'; fa = 'Bill of materials: %1';
						|it = 'Спецификация: %1';
						|pl = 'Bill of materials: %1';
						|tr = 'Ürün reçetesi: %1;'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.BillOfMaterials));
		
	EndIf;
		
	If ValueIsFilled(ScopeString.Stage) Then
		
		Template = NStr("vi = 'Công đoạn: %1';
						|ru = 'Этап: %1';
						|en = 'Stage: %1'; fa = 'Stage: %1';
						|it = 'Этап: %1';
						|pl = 'Stage: %1';
						|tr = 'Aşama: %1;'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.Stage));
		
	EndIf;
	
	If ValueIsFilled(ScopeString.Product) Then
		
		Template = NStr("vi = 'Sản phẩm: %1';
						|ru = 'Изделие: %1';
						|en = 'Finished product: %1'; fa = 'Finished product: %1';
						|it = 'Изделие: %1';
						|pl = 'Finished product: %1';
						|tr = 'Nihai ürün: %1;'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.Product));
		
	EndIf;
	
	If ValueIsFilled(ScopeString.ItemVariantOfProduct) Then
		
		Template = NStr("vi = 'Đặc tính: %1';
						|ru = 'Характеристика: %1';
						|en = 'Variant: %1'; fa = 'Variant: %1';
						|it = 'Характеристика: %1';
						|pl = 'Charakterystyka: %1';
						|tr = 'Varyant: %1'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.ItemVariantOfProduct));
		
	EndIf;
	
	If ValueIsFilled(ScopeString.Department) Then
		
		Template = NStr("vi = 'Bộ phận :%1';
						|ru = 'Подразделение: %1';
						|en = 'Business unit: %1'; fa = 'Business unit: %1';
						|it = 'Подразделение: %1';
						|pl = 'Dział: %1';
						|tr = 'Departman: %1;'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.Department));
		
	EndIf;
		
	If ValueIsFilled(ScopeString.LineOfBusiness) Then
		
		Template = NStr("vi = 'Lĩnh vực hoạt động: %1';
						|ru = 'Направление деятельности: %1';
						|en = 'Line of business: %1'; fa = 'Line of business: %1';
						|it = 'Направление деятельности: %1';
						|pl = 'Rodzaj działalności: %1';
						|tr = 'İş kolu: %1'");
		SubstringsArray.Add(StrTemplate(Template, ScopeString.LineOfBusiness));
		
	EndIf;
	
	ScopeView = StrConcat(SubstringsArray, "; ");
	StringLength = StrLen(ScopeView);
	
	If StringLength = 0 Then
		ScopeView = NStr("vi = 'Đối với toàn bộ Tập đoàn';
						|ru = 'По предприятию в целом';
						|en = 'By the entire enterprise'; fa = 'By the entire enterprise';
						|it = 'Per la società in toto';
						|pl = 'Dla przedsiębiorstwa jako całości';
						|tr = 'İşletme hedefine göre'");
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure VisibilityManagement(Form)
	
	VisibilityOfBufferCommands = True;
	
	For Each TSRow In Form.Object.AreasOfAction Do
	
		If ValueIsFilled(TSRow.BillOfMaterials) Then
			VisibilityOfBufferCommands = False;
			Break;
		EndIf;
	
	EndDo;
	
	Form.Items.MaterialsToInsertRows.Visible = VisibilityOfBufferCommands;
	Form.Items.ContextMenuMaterialsInsertLines.Visible = VisibilityOfBufferCommands;
	Form.Items.SelectMaterialsAccordingToTheSpecification.Visible = Not VisibilityOfBufferCommands;
	
EndProcedure

&AtClient
Procedure FillRowID(TableRow)
	
	TableRow.RowID = New UUID;
	
EndProcedure	

#Region WorkingWithClipboard

&AtClient
Procedure CopyTSLines(ObjectNameTS, ItemsNameTS)

	If ProcessingOfTabularFormsClient.SelectedLineToExecuteCommand(Items[ItemsNameTS]) Then
		CopyLinesOnServer(ObjectNameTS, ItemsNameTS);
		ProcessingOfTabularFormsClient.NotifyUserAboutCopyingStrings(Items[ItemsNameTS].SelectedRows.Count());
	EndIf;

EndProcedure

&AtServer
Procedure CopyLinesOnServer(ObjectNameTS, ItemsNameTS)
	
	ProcessingOfTabularForms.CopyRowsToClipboard(Object[ObjectNameTS], Items[ItemsNameTS].SelectedRows);
	
EndProcedure

&AtClient
Procedure GetLinesFromClipboard(TSName)
	
	NumberOfRowsBeforeInsertion = Object[TSName].Count();
	
	GetLinesFromClipboardOnServer(TSName);
	
	NumberOfInserted = Object[TSName].Count() - NumberOfRowsBeforeInsertion;
	ProcessingOfTabularFormsClient.NotifyUserAboutInsertingRows(NumberOfInserted);
	
	CheckDocumentDataByLinesTS(ThisObject);
	
EndProcedure

&AtServer
Procedure GetLinesFromClipboardOnServer(TSName)
	
	ArrayOfProductTypes = New Array;
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	ArrayOfProductTypes.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	FilterParameters = New Map;
	FilterParameters.Insert("Products.ItemsType", ArrayOfProductTypes);
	
	Columns = "Products,Characteristic,Package,NumberOfPackages";
	
	LinesFromBuffer = ProcessingOfTabularForms.RowsFromClipboard(FilterParameters, Columns);
	
	If Not ValueIsFilled(LinesFromBuffer) Then
		Return;
	EndIf;
	
	Table = Object[TSName];//FormDataCollection - 
	
	ListReplacementOption = Object.ReplacementOption = Enums.SubstituteReplacementOption.SubstituteList;
	EmptyPackaging = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	
	For Each LineFromBuffer In LinesFromBuffer Do
		
		CurrentRow = Table.Add();
		FillPropertyValues(CurrentRow, LineFromBuffer);
		
		If ListReplacementOption Then
			
			CurrentRow.NumberOfPackages = 1;
			CurrentRow.Package = EmptyPackaging;
			
		EndIf;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingProducts(StructureOfActions, CurrentRow, TSName);
		BatchProcessingOfTablePartServer.ProcessTSString(
			CurrentRow,
			StructureOfActions,
			Undefined,
			Table);
		
	EndDo;

EndProcedure

&AtClientAtServerNoContext
Procedure SetAvailabilityOfClipboardCommands(Form, AttributeAvailability)
	
	Items = Form.Items;
	Object = Form.Object;
	
	If Object.Posted
	   And (Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Confirmed")
			Or Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Terminated")) Then
	
		AttributeAvailability = False;
	
	EndIf;
	
	Items.MaterialsToInsertRows.Enabled = AttributeAvailability;
	Items.ContextMenuMaterialsInsertLines.Enabled = AttributeAvailability;
	
	Items.AnalogsInsertLines.Enabled = AttributeAvailability;
	Items.ContextMenuAnalogsInsertLines.Enabled = AttributeAvailability;
	
	Items.MaterialsListOfAnalogues_InsertRows.Enabled = AttributeAvailability;
	Items.ContextMenuMaterials_InsertLinesList.Enabled = AttributeAvailability;
	
EndProcedure

#EndRegion

#Region MatchingSpecifications

&AtServer
Function ParametersForMatchingSpecifications()
	
	ItemData_3 = Catalogs.BillsOfMaterials.ProductData_5();
	
	BillOfMaterials = Catalogs.BillsOfMaterials.EmptyRef();
	Stage = Catalogs.ProductionStages.EmptyRef();
	
	For Each TSRow In Object.AreasOfAction Do
		
		If ValueIsFilled(TSRow.BillOfMaterials) Then
			BillOfMaterials = TSRow.BillOfMaterials;
			Stage = TSRow.Stage;
			Break;
		EndIf;
		
	EndDo;
	
	ItemData_3.BillOfMaterials = BillOfMaterials;
	
	AttributesValues = Common.ObjectAttributesValues(
		BillOfMaterials, "MainProductProducts, MainProductPackage, MainProductNumberOfPackages");
		
	SpecificationData = New Structure;
	SpecificationData.Insert("Products",       AttributesValues.MainProductProducts);
	SpecificationData.Insert("Package",           AttributesValues.MainProductPackage);
	SpecificationData.Insert("NumberOfPackages", AttributesValues.MainProductNumberOfPackages);
	SpecificationData.Insert("Count",         0);
		
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits");
	
	BatchProcessingOfTablePartServer.ProcessTSString(SpecificationData, StructureOfActions, Undefined);
	
	ItemData_3.Count = SpecificationData.Count;
	
	TableFieldStructure = ProductionServer.TableFieldStructure();
	TableFieldStructure.MainField = "Products, Characteristic, NumberOfPackages, Package";
	TableFieldStructure.AdditionalFields.Insert("Stage", New TypeDescription("CatalogRef.ProductionStages"));
	TableFieldStructure.DefaultValues.Insert("Stage", Stage);
	
	AddressSelectedMaterials = ProductionServer.PlaceStringDataInTemporaryStorage(
									ThisObject, "Object", "UsedMaterials", False, TableFieldStructure);
	
	PickingParameters = New Structure;
	PickingParameters.Insert("ItemData_3", ItemData_3);
	PickingParameters.Insert("Stage", Stage);
	PickingParameters.Insert("ShowQuantityMatched", True);
	PickingParameters.Insert("ColumnTitleQuantitySelected", NStr("vi = 'Trong chứng từ';
																|ru = 'В документе';
																|en = 'In document'; fa = 'در سند';
																|it = 'Nel documento';
																|pl = 'W dokumencie';
																|tr = 'Belgede'"));
	PickingParameters.Insert("SearchStructureSelectedMaterials", New Structure("Products, Characteristic, Stage"));
	PickingParameters.Insert("AddressSelectedMaterials", AddressSelectedMaterials);
	PickingParameters.Insert("Basis", Object.Ref);
	
	Return PickingParameters;
	
EndFunction

&AtServer
Procedure SelectionOfMaterialsAccordingToSpecification(AddressInStorage)
	
	DataTable = GetFromTempStorage(AddressInStorage);
	For Each TableRow In DataTable Do
		
		NewMaterials = Object.UsedMaterials.Add();
		FillPropertyValues(NewMaterials, TableRow);
		NewMaterials.RowID = New UUID;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingProducts(StructureOfActions, NewMaterials, "UsedMaterials");
		BatchProcessingOfTablePartServer.ProcessTSString(
			NewMaterials,
			StructureOfActions,
			Undefined,
			Object.UsedMaterials);
		
	EndDo;
	
	CheckDocumentDataByLinesTS(ThisObject);
	
EndProcedure	

#EndRegion

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
Procedure UpdateAdditionalAttributesItems()

	PropertyManager.UpdateAdditionalAttributesItems(ThisObject);

EndProcedure

// End StandardSubsystems.Properties


&AtClient
Procedure PerformActionsWhenChangingReplacementOption(ClearScopes = False)

	ProcessDataOfTablePartsWhenChangingReplacementOption();
	AdjustVisibilityOfReplacementPage(ThisObject);
	AdjustVisibilityOfScope(ThisObject);
	
	ReplacementOptionBeforeChange = Object.ReplacementOption;
	If ClearScopes Then
	
		Object.AreasOfAction.Clear();
		Object.AreasOfAction.Add();
	
	EndIf;
	
	UpdateScopePresentation();
	
	If Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList")
	   And Object.InterchangeableSubstitutes Then
	
		Object.InterchangeableSubstitutes = False;
	
	EndIf;

EndProcedure 

&AtClientAtServerNoContext
Procedure AdjustVisibilityOfReplacementPage(Form)
	
	Items = Form.Items;
	ReplacementOption = Form.Object.ReplacementOption;
	
	If ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SetToSet") Then
		
		Items.ReplacementGroupSet.Visible = True;
		Items.GroupReplacementList.Visible = False;
		
	Else
		
		Items.ReplacementGroupSet.Visible = False;
		Items.GroupReplacementList.Visible = True;
		
	EndIf;

EndProcedure

&AtClient
Procedure ProcessDataOfTablePartsWhenChangingReplacementOption()
	
	If Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList") Then
		
		Object.Substitutes.Clear();
		
		For Each TSRow In Object.UsedMaterials Do
			TSRow.NumberOfPackages = 1;
			TSRow.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
		EndDo;
			
	EndIf;

EndProcedure

&AtClient
Procedure ImportFromExternalFileCompletion(ImportedDataAddress, AdditionalParameters) Export
	
	If ValueIsFilled(ImportedDataAddress) Then
		ClearMessages();
		FillInMaterials = CommonClientServer.StructureProperty(
								AdditionalParameters, "FillInMaterials", False);
		GetUploadedProductsFromStorage(ImportedDataAddress, FillInMaterials);
	EndIf;
	
	CheckDocumentDataByLinesTS(ThisObject);
	
EndProcedure

&AtServer
Procedure GetUploadedProductsFromStorage(ImportedDataAddress, FillInMaterials)

	ItemsFromStorage = GetFromTempStorage(ImportedDataAddress);
	
	If FillInMaterials Then
		TabularSection = Object.UsedMaterials;
		TSName = "UsedMaterials";
	Else
		TabularSection = Object.Substitutes;
		TSName = "Substitutes";
	EndIf;
	
	For Each LineProducts_ In ItemsFromStorage Do
	
		NewRow = TabularSection.Add();
		FillPropertyValues(NewRow, LineProducts_);
		NewRow.RowID = New UUID;
		
		If NewRow.NumberOfPackages = 0 Then
			NewRow.NumberOfPackages = 1;
		EndIf;
		
		StructureOfActions = New Structure;
		AddActionsToStructureWhenChangingProducts(StructureOfActions, NewRow, TSName);
		BatchProcessingOfTablePartServer.ProcessTSString(
			NewRow,
			StructureOfActions,
			Undefined,
			TabularSection);
	
	EndDo;
		
EndProcedure 

&AtClientAtServerNoContext
Procedure AdjustVisibilityOfScope(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	ReplacingWithList = Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList");
	
	TSVisibility = Object.AreasOfAction.Count() > 1 And Not ReplacingWithList;
	Items.GroupMultipleScope.Visible = TSVisibility;
	Items.MultipleIndication.Visible = Form.ProductionIsUsed2_2 And Not TSVisibility And Not ReplacingWithList;
	Items.ScopeView.Visible = Not TSVisibility;
	
	If TSVisibility Then
	
		For Each TSRow In Object.AreasOfAction Do
			FillInFinishedProductPresentation(TSRow);
		EndDo;
	
	EndIf;

EndProcedure

&AtClient
Procedure FillInDirectionOfActivityCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(Result) Then
		
		For Each CurRow In SelectedRows Do
			
			TableRow = Object.AreasOfAction.FindByID(CurRow);
			TableRow.LineOfBusiness = Result;
			
		EndDo;
		
		DetermineAvailabilityOfReplacementOption(ThisObject);
		
		NotificationText1 = NStr("vi = 'Đã điền dòng được chọn';
								|ru = 'Выделенные строки заполнены';
								|en = 'Selected lines are filled in'; fa = 'Selected lines are filled in';
								|it = 'Выделенные строки заполнены';
								|pl = 'Wybrane wiersze są wypełnione';
								|tr = 'Seçilen satırlar dolduruldu'");
		ShowUserNotification(NotificationText1,,, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInTheDepartmentCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(Result) Then
		
		For Each CurRow In SelectedRows Do
			
			TableRow = Object.AreasOfAction.FindByID(CurRow);
			TableRow.Department = Result;
			
		EndDo;
		
		DetermineAvailabilityOfReplacementOption(ThisObject);
		
		NotificationText1 = NStr("vi = 'Đã điền dòng được chọn';
								|ru = 'Выделенные строки заполнены';
								|en = 'Selected lines are filled in'; fa = 'Selected lines are filled in';
								|it = 'Выделенные строки заполнены';
								|pl = 'Wybrane wiersze są wypełnione';
								|tr = 'Seçilen satırlar dolduruldu'");
		ShowUserNotification(NotificationText1,,, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure FillInFINISHEDProductCompletion(Result, AdditionalParameters) Export

	SelectedRows = AdditionalParameters.SelectedRows;
	
	If ValueIsFilled(Result) Then
		
		For Each CurRow In SelectedRows Do
			
			TableRow = Object.AreasOfAction.FindByID(CurRow);
			ListOfProperties = "BillOfMaterials, Stage, Product, ItemVariantOfProduct";
			FillPropertyValues(TableRow, Result.SelectionValue, ListOfProperties);
			
		EndDo;
		
		DetermineAvailabilityOfReplacementOption(ThisObject);
		
		NotificationText1 = NStr("vi = 'Đã điền dòng được chọn';
								|ru = 'Выделенные строки заполнены';
								|en = 'Selected lines are filled in'; fa = 'Selected lines are filled in';
								|it = 'Выделенные строки заполнены';
								|pl = 'Wybrane wiersze są wypełnione';
								|tr = 'Seçilen satırlar dolduruldu'");
		ShowUserNotification(NotificationText1,,, PictureLib.Information32);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PickUpOrdersCompletion(Result, AdditionalParameters) Export

	If ValueIsFilled(Result) Then
		
		SelectionOfProductionOrders = CommonClientServer.StructureProperty(
									AdditionalParameters, "SelectionOfProductionOrders", False);
		
		ArrayOfUniqueLinks = New Array;
		
		If SelectionOfProductionOrders Then
			
			For Each ListLine In Result Do
				
				If ArrayOfUniqueLinks.Find(ListLine.Value) <> Undefined Then
					Continue;
				EndIf;
				
				NewRow = Object.AreasOfAction.Add();
				NewRow.ProductionOrder = ListLine.Value;
				
				ArrayOfUniqueLinks.Add(ListLine.Value);
			
			EndDo;
			
		EndIf;
		
		DetermineAvailabilityOfReplacementOption(ThisObject);
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInFinishedProductPresentation(TSRow)
	
	ProductPresentation = "";
	SubstringsArray = New Array;
	
	If ValueIsFilled(TSRow.BillOfMaterials) Then
		
		Template = NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất: %1';
						|ru = 'Спецификация: %1';
						|en = 'Bill of materials: %1'; fa = 'Bill of materials: %1';
						|it = 'Спецификация: %1';
						|pl = 'Bill of materials: %1';
						|tr = 'Ürün reçetesi: %1;'");
		SubstringsArray.Add(StrTemplate(Template, TSRow.BillOfMaterials));
		
	EndIf;
		
	If ValueIsFilled(TSRow.Stage) Then
		
		Template = NStr("vi = 'Công đoạn: %1';
						|ru = 'Этап: %1';
						|en = 'Stage: %1'; fa = 'Stage: %1';
						|it = 'Этап: %1';
						|pl = 'Stage: %1';
						|tr = 'Aşama: %1;'");
		SubstringsArray.Add(StrTemplate(Template, TSRow.Stage));
		
	EndIf;
	
	If ValueIsFilled(TSRow.Product) Then
		
		Template = NStr("vi = 'Sản phẩm: %1';
						|ru = 'Изделие: %1';
						|en = 'Finished product: %1'; fa = 'Finished product: %1';
						|it = 'Изделие: %1';
						|pl = 'Finished product: %1';
						|tr = 'Nihai ürün: %1;'");
		SubstringsArray.Add(StrTemplate(Template, TSRow.Product));
		
	EndIf;
	
	If ValueIsFilled(TSRow.ItemVariantOfProduct) Then
		
		Template = NStr("vi = 'Đặc tính: %1';
						|ru = 'Характеристика: %1';
						|en = 'Variant: %1'; fa = 'Variant: %1';
						|it = 'Характеристика: %1';
						|pl = 'Charakterystyka: %1';
						|tr = 'Varyant: %1'");
		SubstringsArray.Add(StrTemplate(Template, TSRow.ItemVariantOfProduct));
		
	EndIf;
	
	ProductPresentation = StrConcat(SubstringsArray, ";");
		
	TSRow.ProductPresentation = ProductPresentation;

EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureReplacementPriorityField(Form)

	Items = Form.Items;
	
	Items.ReplacementPriority.Visible = Form.YouCanSpecifyReplacementPriority;
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureSchedulingField(Form)

	Items = Form.Items;
	Object = Form.Object;
	
	Items.UseItForAutocorrectInOrders.Visible = Form.DynamicStructure;
	
	ComprehensiveReplacement = Object.UsedMaterials.Count() > 1 Or Object.Substitutes.Count() > 1;
	ModeSet = Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SetToSet");
	
	If ComprehensiveReplacement And ModeSet Then
		
		Items.UseItForAutocorrectInOrders.ReadOnly = True;
		
	Else
		
		Items.UseItForAutocorrectInOrders.ReadOnly = False;
		
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure CheckDocumentDataByLinesTS(Form)
	
	Items = Form.Items;
	Object = Form.Object;
	ComprehensiveReplacement = Object.UsedMaterials.Count() > 1 Or Object.Substitutes.Count() > 1;
	ModeSet = Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SetToSet");
	
	Items.InterchangeableSubstitutes.ReadOnly = ComprehensiveReplacement;
	Items.UseItForAutocorrectInOrders.ReadOnly = ComprehensiveReplacement And ModeSet;
	
	If ComprehensiveReplacement Then
	
		Object.InterchangeableSubstitutes = False;
		
		If ModeSet Then
			Object.UseItForAutocorrectInOrders = False;
		EndIf;
	
	EndIf;

EndProcedure

&AtClientAtServerNoContext
Procedure DetermineAvailabilityOfReplacementOption(Form)

	Object = Form.Object;
	Items = Form.Items;
	
	ScopeIsFull = False;
	ListIsAvailableForSelection = False;
	
	For Each TSRow In Object.AreasOfAction Do
	
		If ValueIsFilled(TSRow.LineOfBusiness)
		 Or ValueIsFilled(TSRow.Department)
		 Or ValueIsFilled(TSRow.Product)
		 Or ValueIsFilled(TSRow.ItemVariantOfProduct)
		 Or ValueIsFilled(TSRow.ProductionOrder)
		 Or ValueIsFilled(TSRow.BillOfMaterials)
		 Or ValueIsFilled(TSRow.Stage)
		 Or ValueIsFilled(TSRow.SalesOrder) Then
		
			ScopeIsFull = True;
			Break;
		
		EndIf;
	
	EndDo;
	
	If Not ScopeIsFull
	   And Object.ReplacementPriority = PredefinedValue("Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials") Then
	
		ListIsAvailableForSelection = True;
	
	EndIf;
	
	Items.ReplacementOption.Visible = True;
	Items.ReplacementOption.ReadOnly = Not ListIsAvailableForSelection;
	Items.DecorationListReplacement.Visible = ?(Form.YouCanSpecifyReplacementPriority, Not ListIsAvailableForSelection, False);
	
	Items.InterchangeableSubstitutes.Visible = Object.ReplacementPriority = PredefinedValue("Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials");
	
EndProcedure

&AtServerNoContext
Function StructureOfFormParameters()

	Return Documents.EngineeringChangeOrder.ParametersOfReplacementAssistantForm();

EndFunction

&AtClient
Function RoleOfDocumentAnalogues()

	If Object.ReplacementOption = PredefinedValue("Enum.SubstituteReplacementOption.SubstituteList")
	 Or Object.InterchangeableSubstitutes Then
	
		RoleOfAnalogues = PredefinedValue("Enum.SubstituteRoles.InterchangeableSubstitute");
		
	Else
		
		RoleOfAnalogues = PredefinedValue("Enum.SubstituteRoles.Material");
	
	EndIf;
	
	Return RoleOfAnalogues;

EndFunction

&AtClientAtServerNoContext
Function ChangeByStatusIsAvailable(Form)
	
	Object = Form.Object;
	AvailableUpdate = True;
			
	If Object.Posted
	   And (Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Confirmed")
			Or Object.Status = PredefinedValue("Enum.StatusesOfEngineeringChangeOrders.Terminated")) Then
	
		AvailableUpdate = False;
	
	EndIf;
	
	Return AvailableUpdate;

EndFunction


&AtClient
Procedure ProcessFieldSelectionInTable(TableName, Field, StandardProcessing)

	If Not ChangeByStatusIsAvailable(ThisObject) Then
		
		FieldName = Field.Name;
		CurrentData = Items[TableName].CurrentData;
		
		If StrFind(FieldName, "Products") > 0
			And ValueIsFilled(CurrentData.Products) Then
			
			StandardProcessing = False;
			ShowValue(, CurrentData.Products);
			
		ElsIf StrFind(FieldName, "Characteristic") > 0
			And ValueIsFilled(CurrentData.Characteristic) Then
			
			StandardProcessing = False;
			ShowValue(, CurrentData.Characteristic);
			
		EndIf;
		
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
