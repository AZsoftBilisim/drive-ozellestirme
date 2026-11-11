
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(Object, ThisObject);
	
	StatusEliminated = Enums.AssetStatuses.Disposed;
	
	If Not ValueIsFilled(Object.Ref) Then
		OnReadCreateAtServer();
	EndIf;
	
	If Parameters.Property("ReportAboutErrors") And Parameters.ReportAboutErrors Then
		PerformFillCheckOnServer();
	EndIf;
	
	ThereIsTheRightToEdit = AccessRight("Edit", Metadata.Catalogs.SubAssets);
	
	#Region StandardSubsystems
	
	// StandardSubsystems.AttachableCommands
	AttachableCommands.OnCreateAtServer(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
	// StandardSubsystems.FilesOperations
	HyperlinkParameters = FilesOperations.FilesHyperlink();
	HyperlinkParameters.Location = "CommandBar";
	FilesOperations.OnCreateAtServer(ThisObject, HyperlinkParameters);
	// End StandardSubsystems.FilesOperations

	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Object", Object);
	AdditionalParameters.Insert("ItemForPlacementName", "GroupAdditionalAttributes");
	AdditionalParameters.Insert("DeferredInitialization", False);
	PropertyManager.OnCreateAtServer(ThisForm, AdditionalParameters);
	
	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);
	
	#EndRegion
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	OnReadCreateAtServer();
	
	PropertyManager.OnReadAtServer(ThisForm, CurrentObject);

	// StandardSubsystems.AttachableCommands
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
	// End StandardSubsystems.AttachableCommands
	
	ConfigurationModificationOverridable.OnReadAtServer(ThisForm, CurrentObject);
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	PropertyManager.BeforeWriteAtServer(ThisForm, CurrentObject);
	
	CurrentObject.RunningTimeRecordingParameters.Load(
		RunningTimeRecordingParameters.Unload( , "RunningTimeValue, AssignedResource, SourceOfParameter"));

	ConfigurationModificationOverridable.BeforeWriteAtServer(ThisForm, Cancel, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	FillInParametersForAccountingForDevelopments(CurrentObject.RunningTimeRecordingParameters, CurrentObject.Class);
	
	SetAvailabilityOfItemsOnServer();

	ConfigurationModificationOverridable.AfterWriteAtServer(ThisForm, CurrentObject, WriteParameters);

EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	// StandardSubsystems.Properties
	PropertyManager.FillCheckProcessing(ThisForm, Cancel, CheckedAttributes);
	// End StandardSubsystems.Properties
	
EndProcedure  

&AtClient
Procedure OnOpen(Cancel)
	
	If Not IsBeingEdited
		And ValueIsFilled(Object.Ref) 
		And ValueIsFilled(Object.Owner)
		And ThereIsTheRightToEdit Then
		
		QueryText = NStr(
			"vi = 'Chưa soạn đối tượng vận hành ""%Object%"".
			|Để thay đổi thành phần nút, cần bỏ phong tỏa đối tượng để thay đổi.';
			|ru = 'Объект эксплуатации ""%Object%"" не редактируется.
			|Для изменения состава узлов потребуется разблокировать объект для изменения.';
			|en = 'Asset ""%Object%"" is not being edited.
			|To change the sub-asset content, unlock the asset for changes.'; fa = 'Asset ""%Object%"" is not being edited.
			|To change the sub-asset content, unlock the asset for changes.';
			|it = 'Non è possibile modificare l''oggetto di utilizzo ""%Object%"".
			| Per la modifica della composizione dei nodi è necessario sbloccare l''oggetto per le modifiche.';
			|pl = 'Obiekt eksploatacji ""%Object%"" nie jest edytowalny.
			|Aby zmienić skład węzłów, trzeba będzie odblokować obiekt dla zmian.';
			|tr = '""%Object%"" varlığı düzenlenemez.
			|Alt varlık yapısını değiştirmek için, değiştirilecek nesnenin kilidini açmanız gerekir.'");
		
		QueryText = StrReplace(QueryText, "%Object%", Object.Owner);
		
		AnswersOptions = New ValueList;
		AnswersOptions.Add(DialogReturnCode.OK, NStr("vi = 'Mở khóa đối tượng';
													|ru = 'Разблокировать объект';
													|en = 'Unlock object'; fa = 'Unlock object';
													|it = 'Sbloccare oggetto';
													|pl = 'Odblokuj obiekt';
													|tr = 'Bir nesnenin kilidini açın'"));
		AnswersOptions.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
														|ru = 'Отмена';
														|en = 'Cancel'; fa = 'انصراف';
														|it = 'Annulla';
														|pl = 'Cancel';
														|tr = 'İptal'"));
		
		ShowQueryBox(
			New CallbackDescription("QuestionIsWhenOpeningCompletion", ThisForm),
			QueryText,
			AnswersOptions);
		
	EndIf;
	
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
Procedure NotificationProcessing(EventName, Parameter, SourceOfParameter)
	
	If EventName = "UnlockingObjectOfOperation" 
		And Parameter.Asset = Object.Owner Then
		
		IsBeingEdited = True;
		SetAvailabilityOfItemsOnServer();
		
	EndIf;
	
	// StandardSubsystems.Properties 
	If PropertyManagerClient.ProcessNotifications(ThisObject, EventName, Parameter) Then
		UpdateAdditionalAttributesItems();
		PropertyManagerClient.AfterImportAdditionalAttributes(ThisObject);
	EndIf;
	// End StandardSubsystems.Properties
	
	// StandardSubsystems.FilesOperations
	FilesOperationsClient.NotificationProcessing(ThisObject, EventName);
	// End StandardSubsystems.FilesOperations

EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)

	ConfigurationModificationClientOverridable.AfterWrite(ThisForm, WriteParameters);
	
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
Procedure OwnerOnChange(Item)
	
	OwnerWhenChangedOnServer();
	
EndProcedure

&AtClient
Procedure DescriptionOnChange(Item)
	
	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	If Not ValueIsFilled(Object.DescriptionFull) Then
		Object.DescriptionFull = Object.Description;
	EndIf;
	
EndProcedure

&AtClient
Procedure ParentOnChange(Item)
	
	ParentWhenModifiedOnServer();
	
EndProcedure

&AtClient
Procedure ClassOnChange(Item)
	
	ClassWhenModifiedOnServer();
	
EndProcedure

&AtServer
Procedure ClassWhenModifiedOnServer()
	
	UpdateAdditionalAttributesItems();
	
	If ValueIsFilled(Object.Class) Then
		UseOfSubclasses = Common.ObjectAttributeValue(Object.Class, "UseOfSubclasses");
		AttributeSet.Load(CompositionOfDetailsOfClassOfObjectOfOperation());
	Else
		UseOfSubclasses = False;
		AttributeSet.Load(Catalogs.SubAssets.AttributeSet());
	EndIf;
	
	FillInParametersForAccountingForDevelopments(Object.RunningTimeRecordingParameters, Object.Class);
	
	SetAvailabilityOfItemsOnServer();
	FillInConditionalAppearanceOfForm();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersRunningTimeRecordingParameters

&AtClient
Procedure RunningTimeRecordingParametersFormObjectOnChange(Item)
	
	CurrentData = Items.RunningTimeRecordingParameters.CurrentData;
	CurrentData.SourceOfParameter = CurrentData.FormObject;
	
EndProcedure

&AtClient
Procedure RunningTimeRecordingParametersFormNodeOnChange(Item)
	
	CurrentData = Items.RunningTimeRecordingParameters.CurrentData;
	CurrentData.SourceOfParameter = ?(
		ValueIsFilled(CurrentData.FormNode),
		CurrentData.FormNode,
		CurrentData.FormObject);
		
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure NewBarcode(Command)
	
	Object.Barcode = NewBarcodeOnServer();

EndProcedure

#Region StandardSubsystems

&AtClient
Procedure PerformAFillInCheck(Command)
	
	Cancel = False;
	PerformFillCheckOnServer(Cancel);
	
	If Not Cancel Then
		
		ShowUserNotification(
			NStr("vi = 'Đã thực hiện kiểm tra';
				|ru = 'Проверка выполнена';
				|en = 'Check complete'; fa = 'بررسی تکمیل شد';
				|it = 'Verifica effettuata';
				|pl = 'Weryfikacja wykonana';
				|tr = 'Kontrol tamamlandı'"),
			,
			NStr("vi = 'Không tìm thấy chi tiết lỗi điền';
				|ru = 'Ошибок заполнения реквизитов не обнаружено';
				|en = 'No errors were detected when filling out the attributes'; fa = 'No errors were detected when filling out the attributes';
				|it = 'Errori di riempimento dei requisiti non rilevati';
				|pl = 'Nie wykryto błędów wypełnienia atrybutów';
				|tr = 'Özniteliklerin doldurulmasında herhangi bir hata tespit edilmedi'"),
			PictureLib.Information32);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region StandardSubsystems

&AtServer
Procedure ExecuteCommandAtServer(ExecutionParameters)
	AttachableCommands.ExecuteCommand(ThisObject, ExecutionParameters, Object);
EndProcedure

&AtClient
Procedure Attachable_ContinueCommandExecutionAtServer(ExecutionParameters, AdditionalParameters) Export
	ExecuteCommandAtServer(ExecutionParameters);
EndProcedure

&AtClient
Procedure Attachable_PropertiesExecuteCommand(ItemOrCommand, Var_URL = Undefined, StandardProcessing = Undefined)
	PropertyManagerClient.ExecuteCommand(ThisObject, ItemOrCommand, StandardProcessing);
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.StartCommandExecution(ThisObject, Command, Object);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Object);
EndProcedure

&AtClient
Procedure Attachable_AttachedFilesPanelCommand(Command)
	 FilesOperationsClient.AttachmentsControlCommand(ThisObject, Command);
EndProcedure

#EndRegion

#EndRegion

#Region Private

#Region StandardSubsystems

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
	
	PropertyManager.UpdateAdditionalAttributesItems(ThisForm);
	
EndProcedure

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

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeRecordingParametersAssignedResource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillOutTheAssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '< не требуется >';
													|en = '< not required >'; fa = '< not required >';
													|it = '< non si necessita >';
													|pl = '< nie jest wymagane >';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RunningTimeRecordingParametersAssignedResource.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillOutTheAssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.AssignedResource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RunningTimeRecordingParametersFormObject");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RunningTimeRecordingParametersFormNode");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillInTheSource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không bắt buộc>';
													|ru = '< не требуется >';
													|en = '< not required >'; fa = '< not required >';
													|it = '< non si necessita >';
													|pl = '< nie jest wymagane >';
													|tr = '<gerekli değil>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RunningTimeRecordingParametersFormObject");
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("RunningTimeRecordingParametersFormNode");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.FillInTheSource");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("RunningTimeRecordingParameters.SourceOfParameter");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", True);
	
EndProcedure

&AtServer
Procedure OnReadCreateAtServer()
	
	Items.DescriptionFull.ChoiceList.Clear();
	Items.DescriptionFull.ChoiceList.Add(Object.Description);
	
	FillInDisplayParameters(Object);
	
	FillInParametersForAccountingForDevelopments(Object.RunningTimeRecordingParameters, Object.Class);
	
	SetAvailabilityOfItemsOnServer();
	
	NumberOfStandardDesignItems = ConditionalAppearance.Items.Count();
	FillInConditionalAppearanceOfForm();
	
EndProcedure

&AtServer
Procedure SetAvailabilityOfItemsOnServer()
	
	EnableEdit = Not TheOwnerIsEliminated And IsBeingEdited;
	
	ItemArray = New Array();
	
	// Basic banking details
	ItemArray.Add("Owner");
	ItemArray.Add("Parent");
	ItemArray.Add("Description");
	ItemArray.Add("Code");
	ItemArray.Add("Status");
	ItemArray.Add("InfluenceOnWorkCenterAvailability");
	ItemArray.Add("DescriptionFull");
	ItemArray.Add("MainAttributesGroup");
	ItemArray.Add("LongDesc");
	
	// Table parts
	ItemArray.Add("WorkCenters");
	ItemArray.Add("RunningTimeRecordingParameters");
	
	// additional banking details
	ItemArray.Add("GroupAdditionalAttributes");
	
	TMCommonUseClientServer.SetPropertyOfFormElements(
		Items, ItemArray, "ReadOnly", Not EnableEdit);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, "Subclass", "Visible", UseOfSubclasses);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, "Status", "Enabled", Not ParentIsDisposed);
	
	TMCommonUseClientServer.SetFormItemProperty(
		Items, "PageParametersOfAccountingOfDevelopments", "Visible", RunningTimeRecordingParameters.Count()>0);	
	
	Items.StatusCommandBar.Visible = StatusCommandsAreAvailable;
	
	Items.StatusGroup.Visible = Not TheOwnerIsEliminated;
	Items.StatusEliminated.Visible = TheOwnerIsEliminated;
	
EndProcedure

&AtServer
Procedure FillInDisplayParameters(ObjectToFillIn_)
	
	If ValueIsFilled(ObjectToFillIn_.Owner) Then
		
		OwnerStatus = Common.ObjectAttributeValue(ObjectToFillIn_.Owner, "Status");
		IsBeingEdited = (OwnerStatus = Enums.AssetStatuses.IsBeingEdited);
		TheOwnerIsEliminated = (OwnerStatus = Enums.AssetStatuses.Disposed);
		
	Else
		
		IsBeingEdited = True;
		TheOwnerIsEliminated = False;
		
	EndIf;
	
	If ValueIsFilled(ObjectToFillIn_.Class) Then
		UseOfSubclasses = Common.ObjectAttributeValue(ObjectToFillIn_.Class, "UseOfSubclasses");
		AttributeSet.Load(CompositionOfDetailsOfClassOfObjectOfOperation());
	Else
		UseOfSubclasses = False;
		AttributeSet.Load(Catalogs.SubAssets.AttributeSet());
	EndIf;
	
	If ValueIsFilled(ObjectToFillIn_.Parent) Then
		ParentIsDisposed = (Common.ObjectAttributeValue(ObjectToFillIn_.Parent, "Status") = Enums.AssetStatuses.Disposed);
	Else
		ParentIsDisposed = False;
	EndIf;
	
	StatusCommandsAreAvailable = AccessRight("Update", Metadata.Catalogs.SubAssets);
	
EndProcedure

&AtServer
Function CompositionOfDetailsOfClassOfObjectOfOperation()
	
	Query = New Query(
		"SELECT
		|	CAST(AttributeSet.Name AS STRING(255)) AS Name,
		|	CAST(AttributeSet.Synonym AS STRING(255)) AS Synonym,
		|	CAST(AttributeSet.RequiredForFilling AS BOOLEAN) AS RequiredForFilling,
		|	CAST(AttributeSet.RequiredForViewOnly AS BOOLEAN) AS RequiredForViewOnly
		|INTO ObjectsAttributes
		|FROM
		|	&ItemDetails__ AS AttributeSet
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Attributes.AttributeName AS Name,
		|	Attributes.RequiredForFilling AS RequiredForFilling
		|INTO DetailsOfClassObjects
		|FROM
		|	Catalog.MaintenanceSchemes.AttributesForControl AS Attributes
		|WHERE
		|	Attributes.Ref = &Class
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Attributes.Name, DetailsForObjectControl.Name) AS Name,
		|	ISNULL(Attributes.RequiredForFilling, FALSE) AS RequiredForFilling
		|FROM
		|	DetailsOfClassObjects AS Attributes
		|		FULL JOIN ObjectsAttributes AS DetailsForObjectControl
		|		ON Attributes.Name = DetailsForObjectControl.Name");
	Query.SetParameter("ItemDetails__", Catalogs.Assets.CompositionOfDetailsOfObjectOfOperation());
	Query.SetParameter("Class", Object.Class);
	
	Return Query.Execute().Unload();
	
EndFunction

&AtServer
Procedure FillInConditionalAppearanceOfForm()
	
	AppearanceItems = ThisForm.ConditionalAppearance.Items;
	While AppearanceItems.Count() > NumberOfStandardDesignItems Do
		AppearanceItems.Delete(AppearanceItems.Get(AppearanceItems.Count()-1));
	EndDo;
	
	For Each Attribute In AttributeSet Do
		
		Name = TrimAll(Attribute.Name);
		
		Item = AppearanceItems.Add();
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Object." + Name);
		Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
		Filter.Use = True;
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("IsBeingEdited");
		Filter.ComparisonType = DataCompositionComparisonType.Equal;
		Filter.RightValue = True;
		Filter.Use = True;
		
		MarkIncomplete = Item.Appearance.Items.Find("MarkIncomplete");
		MarkIncomplete.Value = Attribute.RequiredForFilling;
		MarkIncomplete.Use = True;
		
		AppearanceField = Item.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField(Name);
		AppearanceField.Use = True;
		
		Item = AppearanceItems.Add();
		
		Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		Filter.LeftValue = New DataCompositionField("Object." + Name);
		Filter.ComparisonType = DataCompositionComparisonType.Filled;
		Filter.Use = True;
		
		MarkIncomplete = Item.Appearance.Items.Find("MarkIncomplete");
		MarkIncomplete.Value = False;
		MarkIncomplete.Use = True;
		
		AppearanceField = Item.Fields.Items.Add();
		AppearanceField.Field = New DataCompositionField(Name);
		AppearanceField.Use = True;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure PerformFillCheckOnServer(Cancel=False)
	
	CheckParameters = Catalogs.SubAssets.FillVerificationParameters();
	CheckParameters.Form = ThisForm;
	CheckParameters.Report_Errors = False;
	
	Catalogs.SubAssets.CheckFilling(Object, CheckParameters, Cancel);
	
	Assets.ReportFillVerificationErrors(CheckParameters.ErrorStream, Cancel);
	
EndProcedure

&AtServer
Procedure FillInParametersForAccountingForDevelopments(PopulationTable, FillingClass)
	
	Query = New Query(
		"SELECT
		|	PopulationTable.RunningTimeValue,
		|	PopulationTable.AssignedResource,
		|	PopulationTable.SourceOfParameter
		|INTO PopulationTable
		|FROM
		|	&PopulationTable AS PopulationTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	OperatingTimeIndicatorsByClassification.RunningTimeValue AS RunningTimeValue,
		|	PopulationTable.AssignedResource AS AssignedResource,
		|	PopulationTable.SourceOfParameter AS SourceOfParameter,
		|	ISNULL(Objects.Ref, Nodes.Owner) AS FormObject,
		|	ISNULL(Nodes.Ref, UNDEFINED) AS FormNode,
		|	OperatingTimeIndicatorsByClassification.CalculateResidualLifetime AS FillOutTheAssignedResource,
		|	OperatingTimeIndicatorsByClassification.RegisterBySource AS FillInTheSource
		|FROM
		|	Catalog.MaintenanceSchemes.RunningTimeValues AS OperatingTimeIndicatorsByClassification
		|		LEFT JOIN PopulationTable AS PopulationTable
		|		ON OperatingTimeIndicatorsByClassification.RunningTimeValue = PopulationTable.RunningTimeValue
		|		LEFT JOIN Catalog.Assets AS Objects
		|		ON (PopulationTable.SourceOfParameter = Objects.Ref)
		|		LEFT JOIN Catalog.SubAssets AS Nodes
		|		ON (PopulationTable.SourceOfParameter = Nodes.Ref)
		|WHERE
		|	OperatingTimeIndicatorsByClassification.Ref = &Class
		|	AND (OperatingTimeIndicatorsByClassification.CalculateResidualLifetime
		|			OR OperatingTimeIndicatorsByClassification.RegisterBySource)
		|
		|ORDER BY
		|	OperatingTimeIndicatorsByClassification.LineNumber");
	
	Query.SetParameter("PopulationTable", PopulationTable.Unload(, "RunningTimeValue, AssignedResource, SourceOfParameter"));
	Query.SetParameter("Class", FillingClass);
	
	RunningTimeRecordingParameters.Load(Query.Execute().Unload());
	
EndProcedure

&AtServerNoContext
Procedure UnlockObjectOfOperation(Asset, Cancel)
	
	Catalogs.Assets.UnlockObjectOfOperation(Asset, Cancel);
	
EndProcedure

&AtServer
Procedure OwnerWhenChangedOnServer()
	
	Object.Parent = Catalogs.SubAssets.EmptyRef();
	
	ParentWhenModifiedOnServer();
	FillInDisplayParameters(Object);
	
EndProcedure

&AtServer
Procedure ParentWhenModifiedOnServer()
	
	If ValueIsFilled(Object.Parent) Then
		ParentStatus = Common.ObjectAttributeValue(Object.Parent, "Status");
		ParentIsDisposed = (ParentStatus = Enums.AssetStatuses.Disposed);
		If ParentIsDisposed Then
			Object.Status = ParentStatus;
		EndIf;
	Else
		ParentIsDisposed = False;
	EndIf;
	
	SetAvailabilityOfItemsOnServer();
	
EndProcedure

&AtClient
Procedure QuestionIsWhenOpeningCompletion(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.OK Then
		HasErrors = False;
		UnlockObjectOfOperation(Object.Owner, HasErrors);
		If HasErrors Then
			Close();
		Else
			Notify("UnlockingObjectOfOperation", New Structure("Asset", Object.Owner));
		EndIf;
	ElsIf Result = DialogReturnCode.Cancel Then
		Close();
	EndIf;
	
EndProcedure

&AtServerNoContext
Function NewBarcodeOnServer()
	
	Return RMManagement.NewNodeBarcode();
	
EndFunction

#EndRegion

#EndRegion
