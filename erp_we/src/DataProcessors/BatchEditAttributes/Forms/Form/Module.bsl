///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Variables

&AtClient
Var CurrentSelectedAttribute;

&AtClient
Var ErrorsInfo;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	AdditionalDataProcessorRef = Parameters.AdditionalDataProcessorRef;

	ContextCall = TypeOf(Parameters.ObjectsArray) = Type("Array");
	
	Items.FormBack.Visible = False;
	EditProhibitionIntegrated = Metadata.FindByFullName("CommonModule.ObjectAttributesLockClient") <> Undefined;
	
	If ContextCall Then
		ExecuteActionsOnContextOpen();
	Else
		If Not Users.IsFullUser() Then
			Raise(NStr("vi = 'Không đủ quyền truy cập.';
						|ru = 'Недостаточно прав доступа.';
						|en = 'Insufficient access rights.'; fa = 'حقوق دسترسی ناکافی.';
						|it = 'Diritti di accesso insufficienti.';
						|pl = 'Niewystarczające uprawnienia dostępu.';
						|tr = 'Yetersiz erişim hakı.'"), ErrorCategory.AccessViolation);
		EndIf;
		Title = NStr("vi = 'Thay đổi mục tin theo nhóm';
					|ru = 'Групповое изменение реквизитов';
					|en = 'Bulk attribute edit'; fa = 'ویرایش گروهی ویژگی‌ها';
					|it = 'Modifica di gruppo dei requisiti';
					|pl = 'Zmiana grupowa atrybutów';
					|tr = 'Toplu öznitelik düzenleme'");
		FillObjectsTypesList();
	EndIf;
	
	LoadProcessingSettings();
	
	GenerateNoteOnConfiguredChanges();
	UpdateItemsVisibility();
	
	If Not ContextCall Then
		WindowOpeningMode = FormWindowOpeningMode.Independent;
	EndIf;
	
	Items.GenerateErrorReport.Visible = False;
	
EndProcedure

&AtClient
Procedure OnClose(Exit)
	
	SendErrorReport();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If ChoiceSource.FormName = "DataProcessor.BatchEditAttributes.Form.AdditionalParameters" Then
		
		RefillObjectAttributesStructure = False;
		If TypeOf(ValueSelected) = Type("Structure") Then
			Object.DeveloperMode = ValueSelected.DeveloperMode;
			DisableSelectionParameterConnections = ValueSelected.DisableSelectionParameterConnections;
			If IncludeHierarchy And ProcessRecursively <> ValueSelected.ProcessRecursively Then
				ProcessRecursively = ValueSelected.ProcessRecursively;
				RefillObjectAttributesStructure = True;
				InitializeSettingsComposer();
			EndIf;
			Object.ChangeInTransaction = ValueSelected.ChangeInTransaction;
			Object.InterruptOnError  = ValueSelected.InterruptOnError;
			
			If Object.ShowInternalAttributes <> ValueSelected.ShowInternalAttributes Then
				Object.ShowInternalAttributes = ValueSelected.ShowInternalAttributes;
				RefillObjectAttributesStructure = True;
				FillObjectsTypesList();
			EndIf;
			
			If RefillObjectAttributesStructure And Not IsBlankString(KindsOfObjectsToChange) Then
				SavedSettings = Undefined;
				LoadObjectMetadata(True, SavedSettings);
				If SavedSettings <> Undefined And Object.OperationType <> "ExecuteAlgorithm" Then
					SetChangeSetting(SavedSettings);
				EndIf;
			EndIf;
			
			UpdateItemsVisibility();
			SaveDataProcessorSettings(Object.ChangeInTransaction, Object.InterruptOnError, ProcessRecursively);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure KindOfObjectsToChangeStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	CallbackDescription = New CallbackDescription("KindOfObjectsToChangeWhenSelected", ThisObject);
	
	FormParameters = New Structure;
	FormParameters.Insert("SelectedTypes", KindsOfObjectsToChange);
	FormParameters.Insert("ShowHiddenItems", Object.ShowInternalAttributes);
	
	OpenForm("DataProcessor.BatchEditAttributes.Form.SelectObjectsKind",
		FormParameters, , , , , CallbackDescription);
EndProcedure

&AtClient
Procedure PresentationOfObjectsToChangeOnChange(Item)
	Selected_2Type = Items.PresentationOfObjectsToChange.ChoiceList.FindByValue(PresentationOfObjectsToChange);
	If Selected_2Type = Undefined Then
		For Each Type In Items.PresentationOfObjectsToChange.ChoiceList Do
			If StrFind(Lower(Type.Presentation), Lower(PresentationOfObjectsToChange)) = 1 Then
				Selected_2Type = Type;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	If Selected_2Type = Undefined Then
		PresentationOfObjectsToChange = PresentationOfObjectsToChange();
	Else
		PresentationOfObjectsToChange = Selected_2Type.Presentation;
		KindsOfObjectsToChange = Selected_2Type.Value;
		SelectedObjectsInContext.Clear();
		RebuildFormInterfaceForSelectedObjectKind();
		If Not ContextCall Then
			SaveKindsOfObjectsToChange(KindsOfObjectsToChange, SelectedItemsListAddress);
		EndIf;	
	EndIf;
	
	Algorithm = PresentationOfObjectsToChange;
	
EndProcedure

&AtClient
Procedure OperationKindOnChange(Item)
	
	If Object.OperationType = "ExecuteAlgorithm" Then
		Items.OperationKindPages.CurrentPage = Items.ArbitraryAlgorithm;
		Items.FormChange.Title = NStr("vi = 'Thực hiện';
										|ru = 'Выполнить';
										|en = 'Run'; fa = 'اجرا';
										|it = 'Eseguire';
										|pl = 'Run';
										|tr = 'Tamamla'");
		Items.PreviouslyChangedAttributes.Visible = False;
		Items.Algorithms.Visible = True;
		Items.AttributesSearchString.Visible = False;
	Else
		Items.OperationKindPages.CurrentPage = Items.AttributesToChange;
		Items.FormChange.Title = NStr("vi = 'Thay đổi mục tin';
										|ru = 'Изменить реквизиты';
										|en = 'Edit attributes'; fa = 'ویرایش ویژگی‌ها';
										|it = 'Modificare i requisiti';
										|pl = 'Zmień atrybuty';
										|tr = 'Öznitelikleri değiştir'");
		Items.PreviouslyChangedAttributes.Visible = True;
		Items.Algorithms.Visible = False;
		Items.AttributesSearchString.Visible = True;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectCompositionOnCurrentPageChange(Item, CurrentPage)
	Items.AttributesSearchString.Visible = (CurrentPage = Items.Attributes);
EndProcedure

&AtClient
Procedure GenerateErrorReportClick(Item)
	
	CurrentData = Items.ObjectsThatCouldNotBeChanged.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ErrorReport = InfoOnError(CurrentData.Object).ErrorReport;
	If ErrorReport <> Undefined Then
		StandardSubsystemsClient.ShowErrorReport(ErrorReport);
	EndIf;
	
EndProcedure

&AtClient
Procedure PresentationOfObjectsToChangeAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	InputFieldAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
EndProcedure

&AtClient
Procedure InputFieldAutoSelection(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	ChoiceData = ChoiceData(Text, Item.ChoiceList);
	StandardProcessing = Not ValueIsFilled(Text);
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSettingsComposerSettingsFilter

&AtClient
Procedure UpdateLabel()
	UpdateLabelServer();
EndProcedure

&AtServer
Procedure UpdateLabelServer()
	UpdateSelectedCountLabel();
	GenerateNoteOnConfiguredChanges();
	Algorithm = PresentationOfObjectsToChange;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectsThatCouldNotBeChanged

&AtClient
Procedure ObjectsThatCouldNotBeChangedBeforeRowChange(Item, Cancel)
	If TypeOf(Item.CurrentData.Object) <> Type("String")
		And Item.CurrentItem = Items.ObjectsThatCouldNotBeChangedObject Then
		Cancel = True;
		ShowValue(, Item.CurrentData.Object);
	EndIf;
EndProcedure

&AtClient
Procedure ObjectsThatCouldNotBeChangedOnActivateRow(Item)
	If Item.CurrentData = Undefined Then
		Cause = "";
	Else
		Cause = Item.CurrentData.Cause;
	EndIf;
	
	ConfigureVisibilityAndTitleForURLSendErrorReport();

EndProcedure

&AtClient
Procedure ConfigureVisibilityAndTitleForURLSendErrorReport()
	
	Items.GenerateErrorReport.Visible = False;
	
	If Items.Pages.CurrentPage <> Items.ObjectsChange 
		Or Not Items.ObjectsThatCouldNotBeChangedGroup.Visible Then
		Return;
	EndIf;
	
	CurrentData = Items.ObjectsThatCouldNotBeChanged.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ErrorInfo = InfoOnError(CurrentData.Object).ErrorInfo;
	If ErrorInfo <> Undefined Then
		StandardSubsystemsClient.ConfigureVisibilityAndTitleForURLSendErrorReport(
			Items.GenerateErrorReport, ErrorInfo);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectAttributes

&AtClient
Procedure ObjectAttributesDragCheck(Item, DragParameters, StandardProcessing, String, Field)
	If Field <> Undefined And Field.Name = Items.ObjectAttributesValue.Name 
		And ObjectAttributes.FindByID(String).AllowedTypes.ContainsType(Type("String"))
		And Not StrStartsWith(ObjectAttributes.FindByID(String).Value, "'") Then
		StandardProcessing = False;
	EndIf;
EndProcedure

&AtClient
Procedure ObjectAttributesDrag(Item, DragParameters, StandardProcessing, String, Field)
	AttributeDetails = ObjectAttributes.FindByID(DragParameters.Value[0]);
	PasteTemplate = "[%1]";
	
	TextForInsert = StringFunctionsClientServer.SubstituteParametersToString(PasteTemplate, AttributeDetails.Presentation);
	CurrentData = ObjectAttributes.FindByID(String);
	If Not IsBlankString(CurrentData.Value) Then
		TextForInsert = "+" + TextForInsert;
	EndIf;
	CurrentData.Value = String(CurrentData.Value) + TextForInsert;
	If Not StrStartsWith(TrimL(CurrentData.Value), "=") Then
		CurrentData.Value = "=" + CurrentData.Value;
	EndIf;
	CurrentData.Change = True;
EndProcedure

&AtClient
Procedure ObjectAttributesValueStartChoice(Item, ChoiceData, StandardProcessing)
	CurrentData = Items.ObjectAttributes.CurrentData;
	If CurrentData.AllowedTypes.Types().Count() = 1 And CurrentData.AllowedTypes.ContainsType(Type("String")) Then
		StandardProcessing = False;
		AttachIdleHandler("EditFormula", 0.1, True);
	EndIf;
EndProcedure

&AtClient
Function ExpressionsHaveErrors()
	Result = False;
	For IndexOf = 0 To ObjectAttributes.Count() - 1 Do
		AttributeDetails = ObjectAttributes[IndexOf];
		If AttributeDetails.Change And TypeOf(AttributeDetails.Value) = Type("String") 
			And StrStartsWith(AttributeDetails.Value, "=") Then
			ErrorText = "";
			If ExpressionHasErrors(AttributeDetails.Value, ErrorText) Then
				Result = True;
				Message = New UserMessage;
				Message.Field = StringFunctionsClientServer.SubstituteParametersToString("ObjectAttributes[%1].Value", Format(IndexOf, "NG=0"));
				Message.Text = ErrorText;
				Message.Message();
			EndIf;
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure ObjectAttributesValueChoiceCompletion(Formula, CurrentData) Export
	If Formula = Undefined Then
		Return;
	EndIf;
	If Not StrStartsWith(Formula, "=") Then
		Formula = "=" + Formula;
	EndIf;
	CurrentData.Value = Formula;
	CurrentData.Change = True;
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersObjectAttributesAlgorithm

&AtClient
Procedure ObjectAttributesAlgorithmDragStart(Item, DragParameters, Perform)
	DragParameters.Value = "Object." + Item.CurrentData.Name;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Change(Command)
	
	SendErrorReport();
	If Object.OperationType = "ExecuteAlgorithm" Then
		
		CodeExecutionRights = AvailableCodeExecutionRights();
		
		If Not CodeExecutionRights.CodeExecutionAvailable Then
			Return;
		EndIf;
		
		If Not CodeExecutionRights.UnsafeModeCodeExecutionAvailable And Object.ExecutionMode = 1 Then
			Object.ExecutionMode = 0; // Switching to safe mode
		EndIf;
		
	EndIf;
	
	ButtonPurpose = "Change";
	If ProcessingInProgress Then
		ButtonPurpose = "Abort";
	ElsIf ProcessingCompleted Or Items.Pages.CurrentPage = Items.ObjectsChange Then
		ButtonPurpose = "Close";
		If ObjectsThatCouldNotBeChanged.Count() > 0 Then
			ButtonPurpose = "Retry";
		EndIf;
	EndIf;
	
	If ButtonPurpose = "Close" Then
		Close();
		Return;
	EndIf;
	
	If ButtonPurpose = "Abort" Then
		If CurrentChangeStatus = Undefined Or TimeConsumingOperation = Undefined Then
			Return;
		EndIf;
		CurrentChangeStatus.AbortUpdate = True;
		Items.FormChange.Enabled = False;
		If Not TimeConsumingOperation.Status = "Completed2" Then
			CompleteObjectChange();
		EndIf;
		Return;
	EndIf;
	
	If ButtonPurpose = "Change" Then
		If Not SelectedObjectsAvailable() Then
			ShowMessageBox(, NStr("vi = 'Chưa chỉ ra phần tử để thay đổi.';
									|ru = 'Не указаны элементы для изменения.';
									|en = 'Items to edit are not provided.'; fa = 'Items to edit are not provided.';
									|it = 'Не указаны элементы для изменения.';
									|pl = 'Items to edit are not provided.';
									|tr = 'Değişecek öğeler belirtilmedi.'"));
			Return;
		EndIf;
		
		If ExpressionsHaveErrors() Then
			Return;
		EndIf;
	
		If AvailableConfiguredFilters() Then
			ExecuteChangeFilterCheckCompleted();
		Else
			QueryText = NStr("vi = 'Chưa đặt lọc. Thay đổi tất cả phần tử?';
							|ru = 'Отбор не задан. Изменить все элементы?';
							|en = 'Filter not set. Do you want to edit all items?'; fa = 'Filter not set. Do you want to edit all items?';
							|it = 'La selezione non è impostata. Modificare tutti gli elementi?';
							|pl = 'Wybór nie został określony. Zmienić wszystkie elementy?';
							|tr = 'Filtre ayarlanmadı. Tüm öğeler değişsin mi?'");
			CallbackDescription = New CallbackDescription("ExecuteChangeFilterCheckCompleted", ThisObject);
			ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel, , , NStr("vi = 'Thay đổi phần tử';
																								|ru = 'Изменение элементов';
																								|en = 'Edit items'; fa = 'Edit items';
																								|it = 'Modifica degli elementi';
																								|pl = 'Zmień elementy';
																								|tr = 'Öğelerin değiştirilmesi'"));
		EndIf;
		
		Return;
	EndIf;
	
	If ButtonPurpose = "Retry" Then
		ExecuteChangeChecksCompleted();
	EndIf;
	
EndProcedure

&AtClient
Procedure Back(Command)
	
	SendErrorReport();
	BackServer();
	
EndProcedure

&AtClient
Procedure ConfigureChangeParameters(Command)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("ChangeInTransaction",            Object.ChangeInTransaction);
	FormParameters.Insert("ProcessRecursively",         ProcessRecursively);
	FormParameters.Insert("InterruptOnError",             Object.InterruptOnError);
	FormParameters.Insert("IncludeHierarchy",              IncludeHierarchy);
	FormParameters.Insert("ShowInternalAttributes",   Object.ShowInternalAttributes);
	FormParameters.Insert("ContextCall",               ContextCall);
	FormParameters.Insert("DeveloperMode",              Object.DeveloperMode);
	FormParameters.Insert("DisableSelectionParameterConnections", DisableSelectionParameterConnections);
	
	OpenForm("DataProcessor.BatchEditAttributes.Form.AdditionalParameters", FormParameters, ThisObject);
	
EndProcedure

#Region ConnectedHandlers

&AtClient
Procedure Attachable_ValueOnChange(FormField)
	CurrentData = FormField.Parent.CurrentData;
	CurrentData.Change = ValueIsFilled(CurrentData.Value);
	UpdateCountersOfAttributesToChange(FormField.Parent);
	AttachIdleHandler("UpdateNoteAboutConfiguredChanges", 0.1, True);
EndProcedure

&AtClient
Procedure Attachable_OnCheckChange(FormField)
	UpdateCountersOfAttributesToChange(FormField.Parent);
	AttachIdleHandler("UpdateNoteAboutConfiguredChanges", 0.1, True);
EndProcedure

// Parameters:
//   Command - FormCommand
//
&AtClient
Procedure Attachable_SetSetting(Command)
	
	If StrStartsWith(Command.Name, "Algorithms") Then
		CommandLocation = Items.Algorithms;
		CommandNamePattern = CommandLocation.Name + "ChangesSetting";
		CommandIndex = Number(Mid(Command.Name, StrLen(CommandNamePattern) + 1));
		AlgorithmCode = AlgorithmsHistoryList[CommandIndex].Value;
		Algorithm = AlgorithmsHistoryList[CommandIndex].Presentation;
		GenerateNoteOnConfiguredChanges();
	Else
		CommandLocation = Items.PreviouslyChangedAttributes;
		CommandNamePattern = CommandLocation.Name + "ChangesSetting";
		CommandIndex = Number(Mid(Command.Name, StrLen(CommandNamePattern) + 1));
		SetChangeSetting(OperationsHistoryList[CommandIndex].Value);
		GenerateNoteOnConfiguredChanges();
	EndIf;
	
EndProcedure

&AtClient
Procedure Attachable_BeforeRowChange(Item, Cancel)
	
	RestrictSelectableTypesAndSetValueChoiceParameters(Item);
	If (Item.CurrentItem = Items.ObjectAttributesValue
		Or Item.CurrentItem = Items.ObjectAttributesChange)
		And Item.CurrentData.LockedAttribute Then
			Cancel = True;
			CurrentSelectedAttribute = Item.CurrentData;
			AttachIdleHandler("AllowEditAttributes", 0.1, True);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Private

&AtClient
Procedure UpdateNoteAboutConfiguredChanges()
	GenerateNoteOnConfiguredChanges();
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	// Auto-numbering info. This is always the first setting.
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectAttributesValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Change");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.IsStandardAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	FilterGroup = Item.Filter.Items.Add(Type("DataCompositionFilterItemGroup"));
	FilterGroup.GroupType = DataCompositionFilterItemsGroupType.OrGroup;
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Code";
	
	ItemFilter = FilterGroup.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "Number";
	
	Item.Appearance.SetParameterValue("Text", NoteOnAutonumbering);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	
	// Locked attribute.
	
	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ObjectAttributesPresentation.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.LockedAttribute");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	//@skip-check new-color
	Item.Appearance.SetParameterValue("TextColor", New Color(192, 192, 192)); // ACC:1346 Standalone data processor cannot use styles.
	
	// Notes for linked attributes
	
	For Each Attribute In ObjectAttributes Do
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.ObjectAttributesValue.Name);

		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Name");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = Attribute.Name;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Value");
		ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.Change");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = False;
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("ObjectAttributes.ChoiceParameterLinksPresentation");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
		
		Item.Appearance.SetParameterValue("Text", Attribute.ChoiceParameterLinksPresentation);
		Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
	EndDo;
	
	For Each TabularSection In ObjectTabularSections Do
		For Each Attribute In ThisObject[TabularSection.Value] Do
			SetConditionalTabularSectionAttributeFormatting(Attribute, TabularSection);
		EndDo;
	EndDo;
	
EndProcedure

// Parameters:
//   Attribute - Structure:
//   * Name - String
//   ChoiceParameterLinksPresentation - String
//   TabularSection - ValueListItem
//
&AtServer
Procedure SetConditionalTabularSectionAttributeFormatting(Attribute, TabularSection)
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(TabularSection.Value + "Value");

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TabularSection.Value + ".Name");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Attribute.Name;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TabularSection.Value + ".Value");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TabularSection.Value + ".Change");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(TabularSection.Value + ".ChoiceParameterLinksPresentation");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Filled;
	
	Item.Appearance.SetParameterValue("Text", Attribute.ChoiceParameterLinksPresentation);
	Item.Appearance.SetParameterValue("TextColor", WebColors.Gray);
EndProcedure

&AtClient
Procedure ExecuteChangeFilterCheckCompleted(QuestionResult = Undefined, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	If Not AvailableConfiguredChanges() And Object.OperationType = "EnterValues" Then
		QueryText = NStr("vi = 'Chưa xác định thay đổi. Thực hiện ghi lại các phần tử mà không thay đổi?';
						|ru = 'Изменения не заданы. Выполнить перезапись элементов без внесения изменений?';
						|en = 'No changes found. Overwrite the items without introducing changes?'; fa = 'No changes found. Overwrite the items without introducing changes?';
						|it = 'Изменения не заданы. Выполнить перезапись элементов без внесения изменений?';
						|pl = 'No changes found. Overwrite the items without introducing changes?';
						|tr = 'Değişiklikler ayarlanmadı. Öğeler değişiklik olmadan tekrar yazılsın mı?'");
		CallbackDescription = New CallbackDescription("ExecuteChangeChecksCompleted", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.OKCancel, , , NStr("vi = 'Thay đổi phần tử';
																							|ru = 'Изменение элементов';
																							|en = 'Edit items'; fa = 'Edit items';
																							|it = 'Modifica degli elementi';
																							|pl = 'Zmień elementy';
																							|tr = 'Öğelerin değiştirilmesi'"));
	Else
		ExecuteChangeChecksCompleted();
	EndIf;
	
EndProcedure

&AtServer
Function AvailableConfiguredFilters()
	For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
		If FilterElement.Use Then
			Return True;
		EndIf;
	EndDo;
	Return False;
EndFunction

&AtServer
Procedure ExecuteActionsOnContextOpen()
	
	TitleTemplate1 = NStr("vi = 'Thay đổi các phần tử đã chọn ""%1"" (%2)';
							|ru = 'Изменение выделенных элементов ""%1"" (%2)';
							|en = 'Edit selected %1 elements (%2)'; fa = 'Edit selected %1 elements (%2)';
							|it = 'Modifica degli elementi selezionati ""%1"" (%2)';
							|pl = 'Zmień wybrane elementy ""%1"" (%2)';
							|tr = 'Seçili öğelerin değiştirilmesi ""%1"" (%2)'");
	
	ObjectsTypes = New ValueList;
	For Each PassedObject In Parameters.ObjectsArray Do
		MetadataObject = PassedObject.Metadata();
		ObjectName = MetadataObject.FullName();
		If ObjectsTypes.FindByValue(ObjectName) = Undefined Then
			ObjectsTypes.Add(ObjectName, MetadataObject.Presentation());
		EndIf;
	EndDo;
	
	TypePresentation = Parameters.ObjectsArray[0].Metadata().Presentation();
	If ObjectsTypes.Count() > 1 Then
		TypePresentation = "";
		TitleTemplate1 = NStr("vi = 'Thay đổi các phần tử đã tách chọn (%2)';
								|ru = 'Изменение выделенных элементов (%2)';
								|en = 'Edit selected items (%2)'; fa = 'Edit selected items (%2)';
								|it = 'Modifica degli elementi selezionati (%2)';
								|pl = 'Zmień wybrane elementy (%2)';
								|tr = 'Seçili öğelerin değiştirilmesi (%2)'");
	EndIf;
	
	ObjectCount = Parameters.ObjectsArray.Count();
	Title = StringFunctionsClientServer.SubstituteParametersToString(TitleTemplate1, TypePresentation, ObjectCount);
	
	// Hiding all settings-related actions if there are no write permissions for settings.
	Items.PreviouslyChangedAttributes.Visible = AccessRight("SaveUserData", Metadata);
	
	KindsOfObjectsToChange = StrConcat(ObjectsTypes.UnloadValues(), ",");
	
	// Loading the history of operations for this object type.
	LoadOperationsHistory();
	FillPreviouslyChangedAttributesSubmenu();
	
	// This is a hierarchy object.
	IncludeHierarchy = HierarchicalMetadataObject1(Parameters.ObjectsArray[0]);
	FolderHierarchy = HierarchyFoldersAndItems(Parameters.ObjectsArray[0]);
	
	SelectedObjectsInContext.LoadValues(Parameters.ObjectsArray);
	InitializeSettingsComposer();
	
	LoadObjectMetadata();
	
	PresentationOfObjectsToChange = PresentationOfObjectsToChange();
	UpdateSelectedCountLabel();
	
	Items.PresentationOfObjectsToChange.ReadOnly = True;
	
EndProcedure

&AtClient
Procedure ExecuteChangeChecksCompleted(QuestionResult = Undefined, AdditionalParameters = Undefined) Export
	
	If QuestionResult = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	CurrentChangeStatus = Undefined;
	SettButtonsDuringChange(True);
	GoToChangeObjectsPage();
	ObjectsThatCouldNotBeChanged.Clear();
	ErrorsInfo = Undefined;
	
	AttachIdleHandler("ChangeObjects1", 0.1, True);
	
EndProcedure

&AtServer
Function AvailableConfiguredChanges()
	Return AttributesToChange().Count() > 0 Or TabularSectionsToChange().Count() > 0;
EndFunction

&AtServer
Procedure AddChangeToHistory(ChangeStructure, ChangePresentation)
	
	If Object.OperationType = "ExecuteAlgorithm" Then
		Settings = Common.CommonSettingsStorageLoad("BatchEditObjects", 
			"AlgorithmsHistory/" + KindsOfObjectsToChange);
		
		If Settings = Undefined Then
			Settings = New Array;
		Else
			For IndexOf = 0 To Settings.UBound() Do
				If Settings.Get(IndexOf).Presentation = ChangePresentation Then
					Settings.Delete(IndexOf);
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		Settings.Insert(0, New Structure("Update, Presentation", ChangeStructure, ChangePresentation));
		
		If Settings.Count() > 20 Then
			Settings.Delete(19);
		EndIf;
		
		Common.CommonSettingsStorageSave(
			"BatchEditObjects", "AlgorithmsHistory/" + KindsOfObjectsToChange, Settings);
		
		LoadOperationsHistory();
		FillPreviouslyChangedAttributesSubmenu();

		Return;
	EndIf;
	
	Settings = Common.CommonSettingsStorageLoad("BatchEditObjects", 
		"ChangeHistory/" + KindsOfObjectsToChange);
	
	If Settings = Undefined Then
		Settings = New Array;
	Else
		For IndexOf = 0 To Settings.UBound() Do
			If Settings.Get(IndexOf).Presentation = ChangePresentation Then
				Settings.Delete(IndexOf);
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Settings.Insert(0, New Structure("Update, Presentation", ChangeStructure, ChangePresentation));
	
	If Settings.Count() > 20 Then
		Settings.Delete(19);
	EndIf;
	
	Common.CommonSettingsStorageSave(
		"BatchEditObjects", "ChangeHistory/" + KindsOfObjectsToChange, Settings);
	
	LoadOperationsHistory();
	FillPreviouslyChangedAttributesSubmenu();
EndProcedure

&AtServer
Procedure LoadOperationsHistory()
	
	OperationsHistoryList.Clear();
	ChangeHistory = Common.CommonSettingsStorageLoad(
		"BatchEditObjects", "ChangeHistory/" + KindsOfObjectsToChange);
		
	If ChangeHistory <> Undefined And TypeOf(ChangeHistory) = Type("Array") Then
		For Each Setting In ChangeHistory Do
			OperationsHistoryList.Add(Setting.Update, Setting.Presentation);
		EndDo;
	EndIf;
	
	AlgorithmsHistoryList.Clear();
	ChangeHistory = Common.CommonSettingsStorageLoad(
		"BatchEditObjects", "AlgorithmsHistory/" + KindsOfObjectsToChange);
		
	If ChangeHistory = Undefined Then
		Return;
	EndIf;
	
	For Each Setting In ChangeHistory Do
		AlgorithmsHistoryList.Add(Setting.Update, Setting.Presentation);
	EndDo;
	
EndProcedure

&AtClient
Procedure AskForAttributeUnlockConfirmation(SelectedAttribute)
	
	Buttons = New ValueList;
	Buttons.Add(DialogReturnCode.Yes, NStr("vi = 'Bỏ phong tỏa';
											|ru = 'Разблокировать';
											|en = 'Unlock'; fa = 'رفع قفل';
											|it = 'Разблокировать';
											|pl = 'Unlock';
											|tr = 'Kilidi kaldır'"));
	QueryText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Để ngăn ngừa khả năng dữ liệu không nhất quán trong ứng dụng
			|không cho phép chỉnh sửa mục tin ""%1"".
			|
			|Trước khi cho phép chỉnh sửa, nên đánh giá hậu quả
			|bằng cách kiểm tra tất cả các vị trí đang sử dụng các phần tử này trong ứng dụng
			|
			|Bỏ phong tỏa mục tin ""%1""để thay đổi?';
			|ru = 'Для того чтобы не допустить рассогласования данных в приложении,
			|реквизит ""%1"" недоступен для редактирования.
			|
			|Перед тем, как разрешить его редактирование, рекомендуется оценить последствия,
			|проверив все места использования выбранных элементов в приложении.
			|
			|Разблокировать реквизит ""%1"" для изменения?';
			|en = 'To prevent data inconsistency, attribute %1 has been locked.
			|
			|Before you allow editing, view the occurrences of the selected items
			|and consider possible data implications.
			|
			|Allow editing of %1?
			|'; fa = 'To prevent data inconsistency, attribute %1 has been locked.
			|
			|Before you allow editing, view the occurrences of the selected items
			|and consider possible data implications.
			|
			|Allow editing of %1?
			|';
			|it = 'Для того чтобы не допустить рассогласования данных в приложении,
			|реквизит ""%1"" недоступен для редактирования.
			|
			|Перед тем, как разрешить его редактирование, рекомендуется оценить последствия,
			|проверив все места использования выбранных элементов в приложении.
			|
			|Разблокировать реквизит ""%1"" для изменения?';
			|pl = 'To prevent data inconsistency, attribute %1 has been locked.
			|
			|Before you allow editing, view the occurrences of the selected items
			|and consider possible data implications.
			|
			|Allow editing of %1?
			|';
			|tr = 'Uygulamadaki verilerin yanlış hizalanmasını önlemek için, 
			|""%1"" özniteliği düzenlenemez.
			|
			|Düzenlemeye izin vermeden önce, uygulamadaki öğenin
			|tüm kullanım yerlerini kontrol ederek sonuçların değerlendirilmesi önerilmektedir.
			|
			|""%1"" özniteliğinin kilidi değişik için kaldırılsın mı?'"),
		SelectedAttribute.Presentation);
	
	Buttons.Add(DialogReturnCode.Cancel, NStr("vi = 'Hủy bỏ';
												|ru = 'Отмена';
												|en = 'Cancel'; fa = 'انصراف';
												|it = 'Отмена';
												|pl = 'Cancel';
												|tr = 'İptal'"));
	
	CallbackDescription = New CallbackDescription("AskForAttributeUnlockConfirmationCompletion", ThisObject, SelectedAttribute);
	ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Yes, NStr("vi = 'Mục tin đã bị phong tỏa';
																						|ru = 'Реквизит заблокирован';
																						|en = 'Attribute is locked'; fa = 'Attribute is locked';
																						|it = 'Il requisito è bloccato';
																						|pl = 'Rekwizyt zablokowany';
																						|tr = 'Öznitelik kilitlendi'"));
	
EndProcedure

&AtClient
Procedure AskForAttributeUnlockConfirmationCompletion(Response, AttributeDetails) Export
	
	If Response = DialogReturnCode.Yes Then
		AttributeDetails.LockedAttribute = False;
	EndIf;
	
EndProcedure

&AtServerNoContext
Procedure SetSelectionParametersServer(ChoiceParameters, ChoiceParametersArray1)
	
	For IndexOf = 1 To StrLineCount(ChoiceParameters) Do
		ChoiceParametersString      = StrGetLine(ChoiceParameters, IndexOf);
		ChoiceParametersStringsArray = StrSplit(ChoiceParametersString, ";");
		FilterFieldName = TrimAll(ChoiceParametersStringsArray[0]);
		TypeName       = TrimAll(ChoiceParametersStringsArray[1]);
		XMLString     = TrimAll(ChoiceParametersStringsArray[2]);
		
		If Type(TypeName) = Type("FixedArray") Then
			Array = New Array;
			XMLStringArray = StrSplit(XMLString, "#");
			For Each Item In XMLStringArray Do
				Item_Array = StrSplit(Item, "*");
				ElementValue = XMLValue(Type(Item_Array[0]), Item_Array[1]);
				Array.Add(ElementValue);
			EndDo;
			Value = New FixedArray(Array);
		Else
			Value = XMLValue(Type(TypeName), XMLString);
		EndIf;
		
		ChoiceParametersArray1.Add(New ChoiceParameter(FilterFieldName, Value));
	EndDo;
	
EndProcedure

&AtServerNoContext
Procedure SaveDataProcessorSettings(ChangeInTransaction, InterruptOnError, ProcessRecursively)
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	SettingsStructure = SettingsStructure();
	SettingsStructure.ChangeInTransaction    = ChangeInTransaction;
	SettingsStructure.InterruptOnError     = InterruptOnError;
	SettingsStructure.ProcessRecursively = ProcessRecursively;
	Common.CommonSettingsStorageSave("DataProcessor.BatchEditObjects", "", SettingsStructure);
	
EndProcedure

&AtServerNoContext
Procedure SaveKindsOfObjectsToChange(KindsOfObjectsToChange, SelectedItemsListAddress)
	
	ClearUpTempStorageOfListOfSelected(SelectedItemsListAddress);
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	Common.CommonSettingsStorageSave(
		"BatchEditObjects", "KindsOfObjectsToChange", KindsOfObjectsToChange);
	
EndProcedure

&AtServerNoContext
Function SettingsStructure()
	
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ChangeInTransaction",    False);
	SettingsStructure.Insert("InterruptOnError",     False);
	SettingsStructure.Insert("ProcessRecursively", False);
	
	Return SettingsStructure;
	
EndFunction

&AtServer
Procedure LoadProcessingSettings()
	
	Object.OperationType                  = "EnterValues";
	Object.ObjectWriteOption         = "Write";
	
	If Not ContextCall Then
		KindsOfObjectsToChange = LoadTheConfigurationOfTheTypesOfObjectsToChange();
		If Not IsBlankString(KindsOfObjectsToChange) Then
			PresentationOfObjectsToChange = PresentationOfObjectsToChange();
			SelectedObjectsInContext.Clear();
			RebuildFormInterfaceForSelectedObjectKind();
			Algorithm = PresentationOfObjectsToChange;
		EndIf;
	EndIf;
	
	SettingsStructure = Common.CommonSettingsStorageLoad(
		"DataProcessor.BatchEditObjects", KindsOfObjectsToChange, SettingsStructure());
	
	Object.ChangeInTransaction = SettingsStructure.ChangeInTransaction;
	Object.InterruptOnError  = SettingsStructure.InterruptOnError;
	ProcessRecursively     = SettingsStructure.ProcessRecursively;
	If AccessRight("DataAdministration", Metadata) And SettingsStructure.Property("ShowInternalAttributes") Then
		Object.ShowInternalAttributes = SettingsStructure.ShowInternalAttributes;
	Else
		Object.ShowInternalAttributes = False;
	EndIf;
	
	CodeExecutionAvailable                    = CodeExecutionAvailable() And Not ContextCall;
	Items.ArbitraryAlgorithm.Visible   = CodeExecutionAvailable;
	Items.GroupOperationType.Visible      = CodeExecutionAvailable;

	UnsafeModeCodeExecutionAvailable = UnsafeModeCodeExecutionAvailable();
	Items.ExecutionMode.Visible        = UnsafeModeCodeExecutionAvailable;
	
EndProcedure

&AtServer
Function LoadTheConfigurationOfTheTypesOfObjectsToChange()
	
	KindsOfObjectsToChange = Common.CommonSettingsStorageLoad(
		"BatchEditObjects", "KindsOfObjectsToChange", "");
	
	ListOfSpecies = New Array;
	For Each MetadataObjectName In StrSplit(KindsOfObjectsToChange, ",", False) Do
		MetadataObject = Metadata.FindByFullName(MetadataObjectName);
		If MetadataObject <> Undefined Then
			FullName = MetadataObject.FullName();
			If Items.PresentationOfObjectsToChange.ChoiceList.FindByValue(FullName) <> Undefined Then
				ListOfSpecies.Add(FullName);
			EndIf;
		EndIf;
	EndDo;
	
	KindsOfObjectsToChange = StrConcat(ListOfSpecies, ",");
	
	Return KindsOfObjectsToChange;
	
EndFunction

// Custom algorithms are not allowed in SaaS mode, base configurations, or without SystemAdministrator rights.
//
&AtServerNoContext
Function UnsafeModeCodeExecutionAvailable()
	If StandardSubsystemsServer.IsBaseConfigurationVersion()
		Or Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	If Not AccessRight("Administration", Metadata) Then
		Return False;
	EndIf;
	
	Return True;
EndFunction

&AtServerNoContext
Function CodeExecutionAvailable()
	
	If Common.DataSeparationEnabled() Then
		Return False;
	EndIf;
	
	Return True;
EndFunction

&AtServerNoContext
Function AvailableCodeExecutionRights()
	
	Result = New Structure();
	Result.Insert("UnsafeModeCodeExecutionAvailable", UnsafeModeCodeExecutionAvailable());
	Result.Insert("CodeExecutionAvailable", CodeExecutionAvailable());
	
	Return Result;
EndFunction

&AtClient
Procedure AllowEditAttributes()
	
	SelectedAttribute = CurrentSelectedAttribute;
	
	If Not CommonClient.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
		AskForAttributeUnlockConfirmation(SelectedAttribute);
		Return;
	EndIf;
	
	LockedAttributes = New Array;
	LockedAttributesRows = ObjectAttributes.FindRows(
		New Structure("LockedAttribute", True));
	
	For Each OperationDescriptionString In LockedAttributesRows Do
		LockedAttributes.Add(OperationDescriptionString.Name);
	EndDo;
	
	ModuleObjectAttributesLockClient =
		CommonClient.CommonModule("ObjectAttributesLockClient");
	
	ProcedureParameters = ModuleObjectAttributesLockClient.NewParametersAllowEditingObjectAttributes();
	ProcedureParameters.ResultProcessing = New CallbackDescription("OnUnlockAttributes", ThisObject);
	ProcedureParameters.FullObjectName = StrSplit(KindsOfObjectsToChange, ",", False)[0];
	ProcedureParameters.LockedAttributes = LockedAttributes;
	ProcedureParameters.MarkedAttribute = SelectedAttribute.Name;
	ProcedureParameters.AddressOfRefsToObjects = AddressOfChangeableObjectsArray();
	
	ModuleObjectAttributesLockClient.AllowObjectsAttributesEdit(ProcedureParameters);
	
EndProcedure

&AtClient
Procedure GoToChangeObjectsPage()
	
	If Items.Pages.CurrentPage = Items.ChangesSetting Then
		Items.Pages.CurrentPage = Items.ObjectsChange;
	EndIf;
	
EndProcedure

&AtClient
Procedure SettButtonsDuringChange(StartChange)
	
	ProcessingInProgress = StartChange;

	Items.FormChange.Enabled = True;
	
	If StartChange Then
		Items.FormChange.Title = NStr("vi = 'Ngừng';
										|ru = 'Прервать';
										|en = 'Abort'; fa = 'توقف';
										|it = 'Interrompere';
										|pl = 'Abort';
										|tr = 'Durdur'");
	Else
		If ObjectsThatCouldNotBeChanged.Count() > 0 Then
			Items.FormChange.Title = NStr("vi = 'Thay đổi lại';
											|ru = 'Повторить изменение';
											|en = 'Edit same attributes'; fa = 'Edit same attributes';
											|it = 'Ripetere la modifica';
											|pl = 'Ponów zmianę';
											|tr = 'Değişikliği yeniden yap'");
		Else
			Items.FormChange.Title = NStr("vi = 'Đóng';
											|ru = 'Закрыть';
											|en = 'Close'; fa = 'بستن';
											|it = 'Chiudere';
											|pl = 'Close';
											|tr = 'Kapat'");
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure ChangeObjects1()
	
	ClearMessages();
	CurrentChangeStatus = New Structure;
	ObjectsCountForProcessing = SelectedObjectsCount(True, True);
	
	ShowUserNotification(NStr("vi = 'Thay đổi các phần tử đã chọn';
								|ru = 'Изменение выделенных элементов';
								|en = 'Edit selected items'; fa = 'ویرایش اقلام انتخاب‌شده';
								|it = 'Modifica degli elementi selezionati';
								|pl = 'Zmień wybrane elementy';
								|tr = 'Seçili öğeleri değiştirme'"),, 
		NStr("vi = 'Xin vui lòng đợi, việc xử lý có thể mất chút thời gian...';
			|ru = 'Пожалуйста подождите, обработка может занять некоторое время...';
			|en = 'Please wait. Processing may take some time…'; fa = 'Please wait. Processing may take some time…';
			|it = 'Si prega di attendere, l''elaborazione potrebbe richiedere del tempo...';
			|pl = 'Proszę czekać, przetwarzanie może zająć trochę czasu...';
			|tr = 'Lütfen, bekleyin. Veri işlemcisi biraz zaman alabilir...'"));
	ShowProcessedItemsPercentage = False;
	
	CurrentChangeStatus.Insert("ItemsAvailableForProcessing", True);
	
	// Position of the last processed item, where 1 is the first item.
	CurrentChangeStatus.Insert("CurrentPosition", 0);
	
	// Batching in multithreaded runtime is performed in the object module.
	CurrentChangeStatus.Insert("PortionSize", ObjectsCountForProcessing);
	
	CurrentChangeStatus.Insert("ErrorsCount", 0);            // Initialize the error counter.
	CurrentChangeStatus.Insert("ChangedCount", 0);        // Initialize the changed item counter.
	CurrentChangeStatus.Insert("ObjectsCountForProcessing",  ObjectsCountForProcessing);
	CurrentChangeStatus.Insert("StopChangeOnError", Object.InterruptOnError);
	CurrentChangeStatus.Insert("ShowProcessedItemsPercentage",   ShowProcessedItemsPercentage);
	CurrentChangeStatus.Insert("AbortUpdate", False);
	
	AttachIdleHandler("ChangeObjectsBatch", 0.1, True);
	
	Items.Pages.CurrentPage = Items.WaitingForProcessing;
	
EndProcedure

&AtClient
Async Procedure ChangeObjectsBatch()
	
	ChangeAtServer(CurrentChangeStatus.StopChangeOnError);
	
	If TimeConsumingOperation.Status = "Completed2" Then
		ChangeResult = GetFromTempStorage(TimeConsumingOperation.ResultAddress);
		If TypeOf(ChangeResult) = Type("Structure") Then
			ProcessChangeResult(ChangeResult);
		Else
			OnCompleteChange(TimeConsumingOperation, Undefined);
		EndIf;
	Else
		IdleParameters = TimeConsumingOperationsClient.IdleParameters(ThisObject);
		IdleParameters.OutputIdleWindow = False;
		
		CallbackDescription = New CallbackDescription("OnCompleteChange", ThisObject);
		TimeConsumingOperationsClient.WaitCompletion(TimeConsumingOperation, CallbackDescription, IdleParameters);
	EndIf;
	
EndProcedure

// Parameters:
//  Result - See TimeConsumingOperationsClient.NewResultLongOperation
//  AdditionalParameters - Undefined
//
&AtClient
Procedure OnCompleteChange(Result, AdditionalParameters) Export
	
	If Result = Undefined Then
		BackServer();
		Return;
	EndIf;
	
	If Result.Status <> "Completed2" Then
		BackServer();
		StandardSubsystemsClient.OutputErrorInfo(Result.ErrorInfo);
		Return;
	EndIf;
	
	ResultsOfChanges = GetFromTempStorage(Result.ResultAddress);
	
	If TypeOf(ResultsOfChanges) <> Type("Map") Then
		ErrorText = NStr("vi = 'Nhiệm vụ nền không trả về kết quả';
						|ru = 'Фоновое задание не вернуло результат';
						|en = 'The background job did not return a result'; fa = 'The background job did not return a result';
						|it = 'Compito in background non ha restituito il risultato';
						|pl = 'Zadanie w tle nie zwróciło wyniku';
						|tr = 'Arka plan görevi sonuç vermedi'");
		Raise ErrorText;
	EndIf;
	
	StatusError = "Error";
	
	For Each ChangeResult In ResultsOfChanges Do
		
		ResultOfBatchExecution = ChangeResult.Value;
		If ResultOfBatchExecution.Status = StatusError Then
			StandardSubsystemsClient.OutputErrorInfo(ResultOfBatchExecution.ErrorInfo);
		Else
			ResultOfBatchChange = GetFromTempStorage(ResultOfBatchExecution.ResultAddress);
			If TypeOf(ResultOfBatchChange) <> Type("Structure") Then
				ErrorText = NStr("vi = 'Nhiệm vụ nền của luồng chưa trả lại kết quả';
								|ru = 'Фоновое задание потока не вернуло результат';
								|en = 'The thread background job did not return a result'; fa = 'The thread background job did not return a result';
								|it = 'Фоновое задание потока не вернуло результат';
								|pl = 'The thread background job did not return a result';
								|tr = 'Arka plan görevi sonuç vermedi'");
				Raise ErrorText;
			EndIf;
		
			ProcessChangeResult(ResultOfBatchChange);
		EndIf;
		
	EndDo;
	
EndProcedure 

&AtClient
Procedure ProcessChangeResult(ChangeResult = Undefined, ContinueProcessing = Undefined)
	Var ErrorsCount, ChangedCount;
	
	If ContinueProcessing = Undefined Then
		ContinueProcessing = True;
	EndIf;
	
	While ContinueProcessing Do
		FillProcessedObjectsStatus(ChangeResult, ErrorsCount, ChangedCount);
		
		CurrentChangeStatus.ErrorsCount = ErrorsCount + CurrentChangeStatus.ErrorsCount;
		CurrentChangeStatus.ChangedCount = ChangedCount + CurrentChangeStatus.ChangedCount;
		
		If Not (CurrentChangeStatus.StopChangeOnError And ChangeResult.HasErrors) Then
			Break;
		EndIf;
		
		// Rolling back the entire transaction if there were errors.
		If Object.ChangeInTransaction Then
			AttachIdleHandler("CompleteObjectChange", 0.1, True);
			Return; // Exit the loop and procedure.
		EndIf;
		
		QueryText = NStr("vi = 'Đã xảy ra lỗi khi thay đổi các phần tử (nhóm phần tử).
			|Ngắt thay đổi phần tử và chuyển đến xem lỗi?';
			|ru = 'При изменении элементов (группы элементов) возникли ошибки.
			|Прервать изменение элементов и перейти к просмотру ошибок?';
			|en = 'Errors editing items.
			|Do you want to cancel editing and see the Error log?'; fa = 'Errors editing items.
			|Do you want to cancel editing and see the Error log?';
			|it = 'Durante la modifica degli elementi si sono verificati gli errori.
			|Interrompere la modifica degli elementi e passare alla visualizzazione degli errori?';
			|pl = 'Wystąpiły błędy podczas modyfikowania elementów (grupy elementów).
			|Zatrzymaj modyfikowanie elementów i przejdź do wyświetlania błędów?';
			|tr = 'Öğeler değiştirilirken hatalar oluştu (öğe grupları). 
			|Öğe değişikliklerini sonlandırmak ve görüntülenen hatalara devam etmek istiyor musunuz?'");
		Buttons = New ValueList;
		Buttons.Add(DialogReturnCode.Abort, NStr("vi = 'Ngắt';
												|ru = 'Прервать';
												|en = 'Abort'; fa = 'توقف';
												|it = 'Interrompere';
												|pl = 'Abort';
												|tr = 'Durdur'"));
		Buttons.Add(DialogReturnCode.Ignore, NStr("vi = 'Tiếp tục';
													|ru = 'Продолжить';
													|en = 'Continue'; fa = 'ادامه';
													|it = 'Continuare';
													|pl = 'Continue';
													|tr = 'Devam'"));
		Buttons.Add(DialogReturnCode.No, NStr("vi = 'Sẽ không hỏi nữa';
												|ru = 'Больше не спрашивать';
												|en = 'Do not ask again'; fa = 'دوباره پرسیده نشود';
												|it = 'Non chiedere più';
												|pl = 'Nie pytaj ponownie';
												|tr = 'Bir daha sorma'"));
		
		CallbackDescription = New CallbackDescription("ProcessChangeResultResponseReceived", 
			ThisObject, ChangeResult);
		ShowQueryBox(CallbackDescription, QueryText, Buttons, , DialogReturnCode.Abort, 
			NStr("vi = 'Lỗi khi thay đổi phần tử';
				|ru = 'Ошибки при изменении элементов';
				|en = 'Editing errors'; fa = 'Editing errors';
				|it = 'Errori durante la modifica degli elementi';
				|pl = 'Błędy podczas zmiany elementów';
				|tr = 'Öğeler değiştirildiğinde hatalar oluştu'"));
		Return;
	EndDo;
	
	CurrentChangeStatus.CurrentPosition = CurrentChangeStatus.CurrentPosition + ChangeResult.ProcessingState.Count();
	
	If CurrentChangeStatus.ShowProcessedItemsPercentage Then
		// Calculating the current percentage of processed objects.
		CurrentPercentage = Round(CurrentChangeStatus.CurrentPosition / CurrentChangeStatus.ObjectsCountForProcessing * 100);
		Status(NStr("vi = 'Đang xử lý các phần tử...';
					|ru = 'Обрабатываются элементы...';
					|en = 'Processing in progress…'; fa = 'Processing in progress…';
					|it = 'Elementi in elaborazione...';
					|pl = 'Przetworzone przedmioty...';
					|tr = 'Ögeler işleniyor...'"), CurrentPercentage, NStr("vi = 'Thay đổi các phần tử đã chọn';
																				|ru = 'Изменение выделенных элементов';
																				|en = 'Edit selected items'; fa = 'ویرایش اقلام انتخاب‌شده';
																				|it = 'Modifica degli elementi selezionati';
																				|pl = 'Zmień wybrane elementy';
																				|tr = 'Seçili öğeleri değiştirme'"));
	EndIf;
	
	ItemsAvailableForProcessing = ?(CurrentChangeStatus.CurrentPosition < CurrentChangeStatus.ObjectsCountForProcessing, True, False);
	
	If ItemsAvailableForProcessing And Not CurrentChangeStatus.AbortUpdate Then
		AttachIdleHandler("ChangeObjectsBatch", 0.1, True);
	Else
		AttachIdleHandler("CompleteObjectChange", 0.1, True);
	EndIf;

EndProcedure

&AtClient
Procedure ProcessChangeResultResponseReceived(QuestionResult, ChangeResult) Export
	
	If QuestionResult = Undefined Or QuestionResult = DialogReturnCode.Abort Then
		AttachIdleHandler("CompleteObjectChange", 0.1, True);
		Return;
	ElsIf QuestionResult = DialogReturnCode.No Then
		CurrentChangeStatus.StopChangeOnError = False;
	EndIf;
	
	ProcessChangeResult(ChangeResult, False);
	
EndProcedure

&AtClient
Procedure CompleteObjectChange()
	
	SettButtonsDuringChange(False);
	FinalActionsOnChangeServer();
	
	For Each Type In TypesOfObjectsToChange() Do
		NotifyChanged(Type);
	EndDo;
	
	Notify("BulkObjectChangeCompletion");
	
	ProcessingCompleted = CurrentChangeStatus.ChangedCount = CurrentChangeStatus.ObjectsCountForProcessing;
	If ProcessingCompleted Then
		ShowUserNotification(NStr("vi = 'Thay đổi mục tin của phần tử';
									|ru = 'Изменение реквизитов элементов';
									|en = 'Edit attributes'; fa = 'ویرایش ویژگی‌ها';
									|it = 'Modifica dei requisiti di elementi';
									|pl = 'Zmień szczegóły elementów';
									|tr = 'Öznitelik öğelerinin değiştirilmesi'"), , 
			StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Đã thay đổi các phần tử (%1).';
					|ru = 'Изменены элементы (%1).';
					|en = '%1 items have been edited.'; fa = '%1 items have been edited.';
					|it = 'Elementi modificati (%1).';
					|pl = 'Zmieniono elementy (%1).';
					|tr = 'Öğeler değişti (%1).'"), CurrentChangeStatus.ChangedCount));
		GoToCompletedPage();
		Return;
	EndIf;
	
	Items.ObjectsThatCouldNotBeChangedGroup.Visible = ObjectsThatCouldNotBeChanged.Count() > 0;
	
	If ProcessingCompleted Then
		MessageTemplate = NStr("vi = 'Các thay đổi được thực hiện trong tất cả phần tử đã chọn (%2).';
								|ru = 'Изменения выполнены во всех выбранных элементах (%2).';
								|en = 'All %2 selected items have been edited.'; fa = 'All %2 selected items have been edited.';
								|it = 'Modifiche effettuate in tutti elementi selezionati(%2).';
								|pl = 'Zmiany są wprowadzane do wszystkich wybranych elementów (%2).';
								|tr = 'Seçilen tüm öğelerde değişiklikler yapıldı (%2).'");
	Else
		If Object.ChangeInTransaction Or CurrentChangeStatus.ChangedCount = 0 Then
			MessageTemplate = NStr("vi = 'Chưa thay đổi.';
									|ru = 'Изменения не выполнены.';
									|en = 'No items have been edited.'; fa = 'No items have been edited.';
									|it = 'Le modifiche non sono eseguite.';
									|pl = 'Nie wprowadzono żadnych zmian.';
									|tr = 'Değişiklikler yapılmadı.'");
		Else
			MessageTemplate = NStr("vi = 'Đã thay đổi một phần.
										|Đã thay đổi: %1; Không thể thay đổi: %3';
										|ru = 'Изменения выполнены частично.
										|Изменено: %1; Не удалось изменить: %3';
										|en = 'Items edited partially.
										|Edited: %1. Could not edit: %3.'; fa = 'Items edited partially.
										|Edited: %1. Could not edit: %3.';
										|it = 'Le modifiche sono eseguite in parte.
										|Modificati: %1; Non è stato possibile modificare: %3';
										|pl = 'Częściowo zaimplementowane zmiany.
										|Zmieniono: %1; Nie można zmienić: %3';
										|tr = 'Kısmen değiştirilmiş. 
										|Değiştirildi:%1; Değiştirilemedi: %3'");
		EndIf;
	EndIf;
	
	If Object.ChangeInTransaction And Not ProcessingCompleted Then
		SkippedItemsCount = CurrentChangeStatus.ObjectsCountForProcessing - CurrentChangeStatus.ErrorsCount;
		If SkippedItemsCount > 0 And Not CurrentChangeStatus.AbortUpdate Then
			TableRow = ObjectsThatCouldNotBeChanged.Add();
			TableRow.Object = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = '... và các phần tử khác (%1)';
					|ru = '... и другие элементы (%1)';
					|en = '… and other items (%1)'; fa = '… and other items (%1)';
					|it = '... e altri elementi (%1)';
					|pl = '... i inne elementy (%1)';
					|tr = '... ve diğer öğeler (%1)'"), SkippedItemsCount);
			TableRow.Cause = NStr("vi = 'Đã bỏ qua vì đã thay đổi một hoặc nhiều phần tử.';
									|ru = 'Пропущены, так как не были изменены один или более элементов.';
									|en = 'Cannot modify some items. The items were skipped.'; fa = 'Cannot modify some items. The items were skipped.';
									|it = 'Omessi, perché uno o più elementi non sono stati modificati.';
									|pl = 'Pomijany, ponieważ co najmniej jeden element nie został zmieniony.';
									|tr = 'Bir veya daha fazla öğe değişmemiş olarak atlandı.'");
		EndIf;
	EndIf;
	
	Items.ProcessingResultsLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		MessageTemplate,
		CurrentChangeStatus.ChangedCount,
		CurrentChangeStatus.ObjectsCountForProcessing,
		CurrentChangeStatus.ErrorsCount);
		
	Items.FormBack.Visible = True;
	
EndProcedure

&AtServer
Procedure BackServer()
	
	Items.Pages.CurrentPage = Items.ChangesSetting;
	
	ProcessingCompleted = False;
	ObjectsThatCouldNotBeChanged.Clear();
	Items.FormBack.Visible = False;
	If Object.OperationType = "ExecuteAlgorithm" Then
		Items.FormChange.Title = NStr("vi = 'Thực hiện';
										|ru = 'Выполнить';
										|en = 'Run'; fa = 'اجرا';
										|it = 'Eseguire';
										|pl = 'Run';
										|tr = 'Tamamla'");
		Items.FormChange.ExtendedTooltip.Title = NStr("vi = 'Thực hiện thuật toán';
														|ru = 'Выполнить алгоритм';
														|en = 'Run algorithm'; fa = 'Run algorithm';
														|it = 'Eseguire algoritmo';
														|pl = 'Uruchom algorytm';
														|tr = 'Algoritmayı tamamla'");
	Else
		Items.FormChange.Title = NStr("vi = 'Thay đổi mục tin';
										|ru = 'Изменить реквизиты';
										|en = 'Edit attributes'; fa = 'ویرایش ویژگی‌ها';
										|it = 'Modificare i requisiti';
										|pl = 'Zmień atrybuty';
										|tr = 'Öznitelikleri değiştir'");
	EndIf;
	
	UpdateLabelServer();
	
EndProcedure

&AtServer
Procedure GoToCompletedPage()
	
	Items.Pages.CurrentPage = Items.AllDone;
	Items.DoneLabel.Title = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Đã thay đổi mục tin của các phần tử đã chọn.
			|Đã thay đổi toàn bộ của các phần tử: %1';
			|ru = 'Реквизиты выбранных элементов были изменены.
			|Всего изменено элементов: %1';
			|en = 'Attributes of selected items edited.
			|Total items edited: %1.'; fa = 'ویژگی‌های اقلام انتخاب‌شده ویرایش شدند.
			|کل اقلام ویرایش‌شده: %1.';
			|it = 'I requisiti degli elementi selezionati sono stati modificati.
			|Totale elementi modificati: %1';
			|pl = 'Atrybuty wybranych pozycji zostały zmienione.
			|Łącznie zmienionych pozycji: %1';
			|tr = 'Seçilen öğelerin öznitelikleri değiştirildi.
			|Değiştirilen toplam öğe sayısı: %1'"), CurrentChangeStatus.ChangedCount);
	Items.FormChange.Title = NStr("vi = 'Đồng ý';
									|ru = 'Готово';
									|en = 'Finish'; fa = 'پایان';
									|it = 'Fine';
									|pl = 'Finish';
									|tr = 'Bitti'");
	Items.FormBack.Visible = True;
	
	AddMessagePossibleToEditAttributesFaster();
	
EndProcedure

// A message stating that attribute edit can be accelerated is shown if:
// 1. The run mode is client/server (not SaaS).
// 2. The transaction runtime flag is set.
// 3. The number of batches in Administration settings is more than 1.
//
&AtServer
Procedure AddMessagePossibleToEditAttributesFaster()
	
	If Not Object.ChangeInTransaction Then
		Return;
	EndIf;
	
	LongRunningOperationsThreadCount = TimeConsumingOperations.AllowedNumberofThreads();
	If LongRunningOperationsThreadCount <= 1 Then
		Return;
	EndIf;
	
	Items.DoneLabel.Title = Items.DoneLabel.Title
		+ Chars.LF + Chars.LF
		+ NStr("vi = 'Có thể thay đổi mục tin nhanh hơn.
		|Để thực hiện điều này, cần bỏ dấu hộp kiểm ""Thay đổi trong giao tác"" trong các tham số bổ sung.';
		|ru = 'Изменение реквизитов можно выполнять быстрее.
		|Для этого нужно снять флаг ""Изменять в транзакции"" в дополнительных параметрах.';
		|en = 'You can edit attributes faster.
		|To do it, clear the ""Edit in transaction"" check box in the additional parameters.'; fa = 'You can edit attributes faster.
		|To do it, clear the ""Edit in transaction"" check box in the additional parameters.';
		|it = 'Изменение реквизитов можно выполнять быстрее.
		|Для этого нужно снять флаг ""Изменять в транзакции"" в дополнительных параметрах.';
		|pl = 'You can edit attributes faster.
		|To do it, clear the ""Edit in transaction"" check box in the additional parameters.';
		|tr = 'Öznitelikleri daha hızlı değiştirebilirsiniz.
		|Bunu yapmak için, ek parametrelerdeki ""İşlemde değiştir"" onay işaretini kaldırmanız gerekir.'");
	
EndProcedure

&AtServer
Function TypesOfObjectsToChange()
	Result = New Array;
	For Each ObjectsKind In StrSplit(KindsOfObjectsToChange, ",", False) Do
		ObjectManager = Common.ObjectManagerByFullName(ObjectsKind);
		Result.Add(TypeOf(ObjectManager.EmptyRef()));
	EndDo;
	Return Result;
EndFunction

&AtServer
Procedure FinalActionsOnChangeServer()
	If TimeConsumingOperation.Property("JobID") Then
		TimeConsumingOperations.CancelJobExecution(TimeConsumingOperation.JobID);
	EndIf;
	
	Items.Pages.CurrentPage = Items.ObjectsChange;
	SaveCurrentChangeSettings();
EndProcedure

&AtServer
Procedure SaveCurrentChangeSettings()
	
	CurrentSettings = CurrentChangeSettings();
	If CurrentSettings <> Undefined Then
		AddChangeToHistory(CurrentSettings.ChangeDescription, CurrentSettings.ChangePresentation);
	EndIf;
	
EndProcedure

&AtServer
Function CurrentChangeSettings()
	
	If Object.OperationType = "ExecuteAlgorithm" Then
		Result = New Structure;
		Result.Insert("ChangeDescription", AlgorithmCode);
		Result.Insert("ChangePresentation", Algorithm);
		Return Result;
	EndIf;
	
	ChangeDescription = New Structure;
	OperationsCollection = ObjectAttributes.FindRows(New Structure("Change", True));
	
	TemplateOfPresentation = "[Field] = <Value>";
	ChangePresentation = "";
	
	AttributesChangeSetting = New Array;
	For Each OperationDescription In OperationsCollection Do
		ChangeStructure = New Structure;
		ChangeStructure.Insert("OperationKind", OperationDescription.OperationKind);
		ChangeStructure.Insert("AttributeName", OperationDescription.Name);
		ChangeStructure.Insert("Property", OperationDescription.Property);
		ChangeStructure.Insert("Value", OperationDescription.Value);
		AttributesChangeSetting.Add(ChangeStructure);
		
		ValueAsString = TrimAll(String(OperationDescription.Value));
		If IsBlankString(ValueAsString) Then
			ValueAsString = """""";
		EndIf;
		Update = StrReplace(TemplateOfPresentation, "[Field]", TrimAll(String(OperationDescription.Presentation)));
		Update = StrReplace(Update, "<Value>", ValueAsString);
		
		If Not IsBlankString(ChangePresentation) Then
			ChangePresentation = ChangePresentation + "; ";
		EndIf;
		ChangePresentation = ChangePresentation + Update;
	EndDo;
	ChangeDescription.Insert("Attributes", AttributesChangeSetting);
	
	TabularSectionChangeSetting = New Structure;
	For Each TabularSection In TabularSectionsToChange() Do
		If Not IsBlankString(ChangePresentation) Then
			ChangePresentation = ChangePresentation + "; ";
		EndIf;
		ChangePresentation = ChangePresentation + TabularSection.Key + " (";
		AttributesChangeSetting = New Array;
		AttributesRow = "";
		For Each Attribute In TabularSection.Value Do
			ChangeStructure = New Structure("Name,Value");
			FillPropertyValues(ChangeStructure, Attribute);
			AttributesChangeSetting.Add(ChangeStructure);
			
			Update = StrReplace(TemplateOfPresentation, "[Field]", TrimAll(String(Attribute.Presentation)));
			Update = StrReplace(Update, "<Value>", TrimAll(String(Attribute.Value)));
			
			If Not IsBlankString(AttributesRow) Then
				AttributesRow = AttributesRow + "; ";
			EndIf;
			AttributesRow = AttributesRow + Update;
		EndDo;
		ChangePresentation = ChangePresentation + AttributesRow + ")";
		TabularSectionChangeSetting.Insert(TabularSection.Key, AttributesChangeSetting);
	EndDo;
	
	ChangeDescription.Insert("TabularSections", TabularSectionChangeSetting);
	
	Result = Undefined;
	If ValueIsFilled(ChangePresentation) Then
		Result = New Structure;
		Result.Insert("ChangeDescription", ChangeDescription);
		Result.Insert("ChangePresentation", ChangePresentation);
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillProcessedObjectsStatus(ChangeResult, ErrorsCount, ChangedCount)
	
	ErrorsCount = 0;
	ChangedCount = 0;
	
	For Each ProcessedObjectStatus In ChangeResult.ProcessingState Do
		If Not IsBlankString(ProcessedObjectStatus.Value.ErrorCode) Then
			ErrorsCount = ErrorsCount + 1;
			
			ErrorInfo = ProcessedObjectStatus.Value.ErrorMessage;
			
			ErrorReport = New ErrorReport(ErrorInfo);
			
			InfoOnError = InfoOnError();
			InfoOnError.ErrorReport = ErrorReport;
			InfoOnError.ErrorInfo = ErrorInfo;
			
			ErrorsInfo().Insert(ProcessedObjectStatus.Key, InfoOnError);
			
			ErrorRecord = ObjectsThatCouldNotBeChanged.Add();
			ErrorRecord.Object = ProcessedObjectStatus.Key;
			ErrorRecord.Cause = ErrorProcessing.ErrorMessageForUser(ErrorInfo);
		Else
			ChangedCount = ChangedCount + 1;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Function NextBatchOfObjectsForChange()
	
	SelectionStart = CurrentChangeStatus.CurrentPosition;
	SelectionEnd = CurrentChangeStatus.CurrentPosition + CurrentChangeStatus.PortionSize - 1;
	
	SelectedObjects = SelectedObjects();
	If SelectionEnd > SelectedObjects.Rows.Count() - 1 Then
		SelectionEnd = SelectedObjects.Rows.Count() - 1;
	EndIf;
	
	Result = New ValueTree;
	For Each Column In SelectedObjects.Columns Do
		Result.Columns.Add(Column.Name, Column.ValueType);
	EndDo;
	
	For IndexOf = SelectionStart To SelectionEnd Do
		ObjectDetails = Result.Rows.Add();
		FillPropertyValues(ObjectDetails, SelectedObjects.Rows[IndexOf]);
		For Each ObjectString In SelectedObjects.Rows[IndexOf].Rows Do
			FillPropertyValues(ObjectDetails.Rows.Add(), ObjectString);
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function AttributesToChange(TabularSectionName = "ObjectAttributes")
	AttributesTable = ThisObject[TabularSectionName];
	Return Common.ValueTableToArray(
		AttributesTable.Unload(New Structure("Change", True)));
EndFunction

&AtServer
Function TabularSectionsToChange()
	Result = New Structure;
	For Each TabularSection In ObjectTabularSections Do
		AttributesToChange = AttributesToChange(TabularSection.Value);
		If AttributesToChange.Count() > 0 Then
			TabularSectionName = Mid(TabularSection.Value, StrLen("TabularSection") + 1);
			Result.Insert(TabularSectionName, AttributesToChange);
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServer
Procedure ChangeAtServer(Val StopChangeOnError)
	
	ObjectsForProcessing = NextBatchOfObjectsForChange();
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	JobParameters = New Structure;
	JobParameters.Insert("ObjectsToProcess", New ValueStorage(ObjectsForProcessing));
	JobParameters.Insert("StopChangeOnError", StopChangeOnError);
	JobParameters.Insert("ChangeInTransaction", DataProcessorObject.ChangeInTransaction);
	JobParameters.Insert("InterruptOnError", DataProcessorObject.InterruptOnError);
	JobParameters.Insert("OperationType", DataProcessorObject.OperationType);
	JobParameters.Insert("AlgorithmCode", AlgorithmCode);
	JobParameters.Insert("ExecutionMode", DataProcessorObject.ExecutionMode);
	JobParameters.Insert("ObjectWriteOption", DataProcessorObject.ObjectWriteOption);
	JobParameters.Insert("AdditionalAttributesUsed", DataProcessorObject.AdditionalAttributesUsed);
	JobParameters.Insert("AdditionalInfoUsed", DataProcessorObject.AdditionalInfoUsed);
	JobParameters.Insert("AttributesToChange", AttributesToChange());
	JobParameters.Insert("AvailableAttributes", Common.ValueTableToArray(ObjectAttributes.Unload(, "Name,Presentation,OperationKind,Property")));
	JobParameters.Insert("TabularSectionsToChange", TabularSectionsToChange());
	JobParameters.Insert("ObjectsForChanging", New ValueStorage(SelectedObjects()));
	JobParameters.Insert("DeveloperMode", DataProcessorObject.DeveloperMode);
	JobParameters.Insert("ExternalReportDataProcessor", Undefined);
	
	StorageAddress = PutToTempStorage(Undefined, UUID);
	TimeConsumingOperation = DataProcessorObject.ChangeObjects1(JobParameters, StorageAddress);
	
	If TimeConsumingOperation = Undefined Then
		TimeConsumingOperation = New Structure("Status, ResultAddress");
		TimeConsumingOperation.Status          = "Completed2";
		TimeConsumingOperation.ResultAddress = StorageAddress;
	EndIf;
	
EndProcedure

&AtServer
Function AddressOfChangeableObjectsArray()
	
	SelectedObjects = SelectedObjects();
	References = SelectedObjects.Rows.UnloadColumn("Ref");
	Return PutToTempStorage(References, UUID);
	
EndFunction

&AtServerNoContext
Function HierarchicalMetadataObject1(FirstObjectReference)
	
	ObjectKindByRef = Common.ObjectKindByRef(FirstObjectReference);
	Return ((ObjectKindByRef = "Catalog" Or ObjectKindByRef = "ChartOfCharacteristicTypes") And FirstObjectReference.Metadata().Hierarchical)
	 	Or (ObjectKindByRef = "ChartOfAccounts");
	
EndFunction

&AtServerNoContext
Function HierarchyFoldersAndItems(FirstObjectReference)
	
	ObjectKindByRef = Common.ObjectKindByRef(FirstObjectReference);
	Return (ObjectKindByRef = "Catalog" And FirstObjectReference.Metadata().Hierarchical
		And FirstObjectReference.Metadata().HierarchyType = Metadata.ObjectProperties.HierarchyType.HierarchyFoldersAndItems)
		Or (ObjectKindByRef = "ChartOfCharacteristicTypes" And FirstObjectReference.Metadata().Hierarchical);
	
EndFunction

&AtClient
Procedure ResetChangeSettings()
	For Each Attribute In ObjectAttributes Do
		Attribute.Value = Undefined;
		Attribute.Change = False;
	EndDo;
	
	For Each TabularSection In ObjectTabularSections Do
		For Each Attribute In ThisObject[TabularSection.Value] Do
			Attribute.Value = Undefined;
			Attribute.Change = False;
		EndDo;
	EndDo;	
EndProcedure

&AtClient
Procedure FilterSettingsClick(Item)
	GoToFilterSettings();
EndProcedure

&AtClient
Procedure OnCloseSelectedObjectsForm(Settings, AdditionalParameters) Export
	If TypeOf(Settings) = Type("DataCompositionSettings") Then
		SettingsComposer.LoadSettings(Settings);
		UpdateLabel();
		ClearUpTempStorageOfListOfSelected(SelectedItemsListAddress);
	EndIf;
EndProcedure

&AtServerNoContext
Function Filter_Settings()
	Result = New Structure;
	Result.Insert("UpdateList", False);
	Result.Insert("IncludeTabularSectionsInSelection", False);
	Result.Insert("RestrictSelection", False);
	Return Result;
EndFunction

// Parameters:
//   Filter_Settings - Structure:
//     * RestrictSelection - Boolean
//     * IncludeTabularSectionsInSelection - Boolean
//     * UpdateList - Boolean
//   ErrorMessageText - String
//
// Returns:
//   ValueTree:
//     * Ref - AnyRef
//
&AtServer
Function SelectedObjects(Filter_Settings = Undefined, ErrorMessageText = "")
	
	If Filter_Settings = Undefined Then
		Filter_Settings = Filter_Settings();
	EndIf;
	
	UpdateList = Filter_Settings.UpdateList;
	IncludeTabularSectionsInSelection = Filter_Settings.IncludeTabularSectionsInSelection;
	RestrictSelection = Filter_Settings.RestrictSelection;
	
	If Not UpdateList And Not RestrictSelection And Not IsBlankString(SelectedItemsListAddress) Then
		Return GetFromTempStorage(SelectedItemsListAddress);
	EndIf;
		
	Result = New ValueTree;
	
	If Not IsBlankString(KindsOfObjectsToChange) Then
		DataProcessorObject = FormAttributeToValue("Object");
		QueryText = DataProcessorObject.QueryText(KindsOfObjectsToChange, RestrictSelection);
		DataCompositionSchema = DataCompositionSchema(QueryText);
		
		DataCompositionSettingsComposer = New DataCompositionSettingsComposer;
		SchemaURL = PutToTempStorage(DataCompositionSchema, UUID);
		DataCompositionSettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(SchemaURL));
		DataCompositionSettingsComposer.LoadSettings(SettingsComposer.Settings);
		If IncludeTabularSectionsInSelection Then
			SetResultOutputStructureSetting(DataCompositionSettingsComposer.Settings, IncludeTabularSectionsInSelection);
		EndIf;
		
		If ObjectsThatCouldNotBeChanged.Count() > 0 And Not Object.ChangeInTransaction Then // Repeat for unchanged objects.
			FilterElement = DataCompositionSettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
			FilterElement.LeftValue = New DataCompositionField("Ref");
			FilterElement.ComparisonType = DataCompositionComparisonType.InList;
			FilterElement.RightValue = New ValueList;
			FilterElement.RightValue.LoadValues(ObjectsThatCouldNotBeChanged.Unload().UnloadColumn("Object"));
		EndIf;
		
		Result = New ValueTree;
		TemplateComposer = New DataCompositionTemplateComposer;
		Try
			DataCompositionTemplate = TemplateComposer.Execute(DataCompositionSchema,
				DataCompositionSettingsComposer.Settings, , , Type("DataCompositionValueCollectionTemplateGenerator"));
		Except
			ErrorMessageText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
			Return Result;
		EndTry;
			
		DataCompositionProcessor = New DataCompositionProcessor;
		DataCompositionProcessor.Initialize(DataCompositionTemplate);

		OutputProcessor = New DataCompositionResultValueCollectionOutputProcessor;
		OutputProcessor.SetObject(Result);
		OutputProcessor.Output(DataCompositionProcessor);
		If Not RestrictSelection Then
			SelectedItemsListAddress = PutToTempStorage(Result, UUID);
		EndIf;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServerNoContext
Procedure ClearUpTempStorageOfListOfSelected(SelectedItemsListAddress)
	
	If ValueIsFilled(SelectedItemsListAddress) Then
		DeleteFromTempStorage(SelectedItemsListAddress);
		SelectedItemsListAddress = "";
	EndIf;
	
EndProcedure

&AtServer
Procedure SetResultOutputStructureSetting(Settings, ForChange = False)
	
	Settings.Structure.Clear();
	Settings.Selection.Items.Clear();
	
	DataCompositionGroup = Settings.Structure.Add(Type("DataCompositionGroup"));
	DataCompositionGroup.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
	DataCompositionGroup.Use = True;
	
	GroupingField = DataCompositionGroup.GroupFields.Items.Add(Type("DataCompositionGroupField"));
	GroupingField.Field = New DataCompositionField("Ref");
	GroupingField.Use = True;
	
	ComboBox = Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
	ComboBox.Field = New DataCompositionField("Ref");
	ComboBox.Use = True;
	
	If ForChange Then
		DataProcessorObject = FormAttributeToValue("Object");
		CommonObjectsAttributes = DataProcessorObject.CommonObjectsAttributes(KindsOfObjectsToChange);
		For Each TabularSection In CommonObjectsAttributes.TabularSections Do
			TabularSectionName = TabularSection.Key;
			
			TableGroup = DataCompositionGroup.Structure.Add(Type("DataCompositionGroup"));
			TableGroup.Selection.Items.Add(Type("DataCompositionAutoSelectedField"));
			TableGroup.Use = True;
			
			GroupingField = TableGroup.GroupFields.Items.Add(Type("DataCompositionGroupField"));
			GroupingField.Field = New DataCompositionField(TabularSectionName + ".LineNumber");
			GroupingField.Use = True;
			
			ComboBox = Settings.Selection.Items.Add(Type("DataCompositionSelectedField"));
			ComboBox.Field = New DataCompositionField(TabularSectionName + ".LineNumber");
			ComboBox.Use = True;
		EndDo;
	EndIf;
	
EndProcedure

&AtServer
Function SelectedObjectsCount(ShouldRecalculate = False, ForChange = False, ErrorMessageText = "")
	Filter_Settings = Filter_Settings();
	Filter_Settings.UpdateList = ShouldRecalculate;
	Filter_Settings.IncludeTabularSectionsInSelection = ForChange;
	
	Return SelectedObjects(Filter_Settings, ErrorMessageText).Rows.Count();
EndFunction

&AtServer
Function DataCompositionSchema(QueryText)
	
	DataCompositionSchema = New DataCompositionSchema;
	
	DataSource = DataCompositionSchema.DataSources.Add();
	DataSource.Name = "DataSource1";
	DataSource.DataSourceType = "local";
	
	DataSet = DataCompositionSchema.DataSets.Add(Type("DataCompositionSchemaDataSetQuery"));
	DataSet.DataSource = "DataSource1";
	DataSet.AutoFillAvailableFields = True;
	DataSet.Query = QueryText;
	DataSet.Name = "DataSet1";
	
	Return DataCompositionSchema;
	
EndFunction

&AtClient
Procedure KindOfObjectsToChangeWhenSelected(Val SelectedObjects, AdditionalParameters) Export
	If SelectedObjects <> Undefined And KindsOfObjectsToChange <> SelectedObjects Then
		KindsOfObjectsToChange = StrConcat(SelectedObjects, ",");
		SelectedObjectsInContext.Clear();
		RebuildFormInterfaceForSelectedObjectKind();
		Items.ObjectAttributesAlgorithm.RowFilter = New FixedStructure(New Structure("OperationKind", "1"));
		If Not ContextCall Then
			SaveKindsOfObjectsToChange(KindsOfObjectsToChange, SelectedItemsListAddress);
		EndIf;	
	EndIf;
EndProcedure

&AtServer
Procedure RebuildFormInterfaceForSelectedObjectKind()
	InitializeFormSettings();
	UpdateItemsVisibility();
	GenerateNoteOnConfiguredChanges();
EndProcedure

&AtServer
Procedure InitializeFormSettings()
	InitializeSettingsComposer();
	LoadObjectMetadata();
	LoadOperationsHistory();
	FillPreviouslyChangedAttributesSubmenu();
	PresentationOfObjectsToChange = PresentationOfObjectsToChange();
	UpdateLabelServer();
EndProcedure

&AtServer
Function PresentationOfObjectsToChange()
	TypesPresentation1 = New Array;
	For Each MetadataObjectName In StrSplit(KindsOfObjectsToChange, ",", False) Do
		MetadataObject = Metadata.FindByFullName(MetadataObjectName);
		TypesPresentation1.Add(MetadataObject.Presentation());
	EndDo;
		
	Result = StrConcat(TypesPresentation1, ", ");
	Return Result;
EndFunction

&AtServer
Procedure InitializeSettingsComposer()
	If IsBlankString(KindsOfObjectsToChange) Then
		Return;
	EndIf;
	
	DataProcessorObject1 = FormAttributeToValue("Object");
	QueryText = DataProcessorObject1.QueryText(KindsOfObjectsToChange);
	DataCompositionSchema = DataCompositionSchema(QueryText);
	SettingsComposer.Initialize(New DataCompositionAvailableSettingsSource(
		PutToTempStorage(DataCompositionSchema, UUID)));
	SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
	
	If SelectedObjectsInContext.Count() > 0 Then
		If TypeOf(Parameters.SettingsComposer) = Type("DataCompositionSettingsComposer") Then
			ComposerSettings = Parameters.SettingsComposer.GetSettings();
			SettingsComposer.LoadSettings(ComposerSettings);
			SettingsComposer.Settings.ConditionalAppearance.Items.Clear();
			
			ItemsToRemove = New Array;
			For Each Item In SettingsComposer.Settings.Order.Items Do
				AvailableField = SettingsComposer.Settings.Order.OrderAvailableFields.FindField(Item.Field);
				If AvailableField = Undefined Then
					ItemsToRemove.Add(Item);
				EndIf;
			EndDo;
			For Each Item In ItemsToRemove Do
				SettingsComposer.Settings.Order.Items.Delete(Item);
			EndDo;
			
			TemplateComposer = New DataCompositionTemplateComposer;
			Try
				TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.Settings,,, 
					Type("DataCompositionValueCollectionTemplateGenerator"));
			Except
				SettingsComposer.LoadSettings(DataCompositionSchema.DefaultSettings);
			EndTry;
		EndIf;
		
		FilterElement = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
		FilterElement.LeftValue = New DataCompositionField("Ref");
		If IncludeHierarchy And ProcessRecursively Then
			FilterElement.ComparisonType = DataCompositionComparisonType.InListByHierarchy;
		Else
			FilterElement.ComparisonType = DataCompositionComparisonType.InList;
		EndIf;
		FilterElement.RightValue = New ValueList;
		FilterElement.RightValue.LoadValues(SelectedObjectsInContext.UnloadValues());
	
	EndIf;
	
	SetResultOutputStructureSetting(SettingsComposer.Settings);
	
EndProcedure

&AtServer
Procedure ClearObjectDetails()
	FormAttributesBeingDeleted = New Array;
	For Each TabularSection In ObjectTabularSections Do
		FormAttributesBeingDeleted.Add(TabularSection.Value);
		Items.Delete(Items.Find("Page" + TabularSection.Value));
	EndDo;
	ChangeAttributes(, FormAttributesBeingDeleted);
	ObjectTabularSections.Clear();
EndProcedure

&AtServer
Procedure LoadObjectMetadata(SaveCurrentChangeSettings = False, SavedSettings = Undefined)
	
	If SaveCurrentChangeSettings Then
		CurrentSettings =  CurrentChangeSettings();
		If CurrentSettings <> Undefined Then
			SavedSettings = CurrentSettings.ChangeDescription;
		EndIf;
	EndIf;
	
	ClearObjectDetails();
	
	DetailsOfAttributes = New Structure;
	DetailsOfAttributes.Insert("AttributesToSkip", AttributesToSkip());
	DetailsOfAttributes.Insert("DisabledAttributes", DisabledAttributes());
	DetailsOfAttributes.Insert("LockedAttributes", LockedAttributes());
	DetailsOfAttributes.Insert("ExcludedAttributeTypes", ExcludedAttributeTypes());

	DataProcessorObject = FormAttributeToValue("Object");
	CommonObjectsAttributes = DataProcessorObject.CommonObjectsAttributes(KindsOfObjectsToChange);
	
	FillObjectAttributes(DetailsOfAttributes, CommonObjectsAttributes.Attributes);
	FillObjectsTabularSections(DetailsOfAttributes, CommonObjectsAttributes.TabularSections);
	
	GenerateNoteAboutAutonumbering();
	SetConditionalAppearance();
	
EndProcedure

&AtServer
Procedure GenerateNoteAboutAutonumbering()
	
	Autonumbering = Undefined;
	For Each TypeName In StrSplit(KindsOfObjectsToChange, ",", False) Do
		MetadataObject = Metadata.FindByFullName(TypeName); // MetadataObjectCatalog, MetadataObjectDocument
		
		If Metadata.ExchangePlans.Contains(MetadataObject) 
			Or Metadata.ChartsOfCalculationTypes.Contains(MetadataObject)
			Or Metadata.ChartsOfAccounts.Contains(MetadataObject) Then
				Autonumbering = Undefined;
				Break;
		EndIf;
		
		If Autonumbering = Undefined Then
			Autonumbering = MetadataObject.Autonumbering;
			Continue;
		EndIf;
		
		If Autonumbering And Not MetadataObject.Autonumbering Then
			Autonumbering = Undefined;
			Break;
		EndIf;
	EndDo;
	
	If Autonumbering = Undefined Then
		NoteOnAutonumbering = "";
	ElsIf Autonumbering Then
		NoteOnAutonumbering = NStr("vi = '<Thiết lập tự động>';
									|ru = '<Установить автоматически>';
									|en = '<Set automatically>'; fa = '<Set automatically>';
									|it = '<Installare automaticamente>';
									|pl = '<Zainstaluj automatycznie>';
									|tr = '<Otomatik olarak kur>'");
	Else
		NoteOnAutonumbering = NStr("vi = '<Xóa bỏ>';
									|ru = '<Очистить>';
									|en = '<Clear>'; fa = '<Clear>';
									|it = '<Delete>';
									|pl = '<Wyczyść>';
									|tr = '<Temizle>'");
	EndIf;
	
EndProcedure

&AtServer
Function ObjectAttributesToLock(ObjectName)
	
	If Common.SubsystemExists("StandardSubsystems.ObjectAttributesLock") Then
		ModuleObjectAttributesLock = Common.CommonModule("ObjectAttributesLock");
		Return ModuleObjectAttributesLock.ObjectAttributesToLock(ObjectName);
	EndIf;
	
	Return New Array;
	
EndFunction

&AtServer
Function LockedAttributes()
	
	Result = New Array;
	
	For Each ObjectsKind In StrSplit(KindsOfObjectsToChange, ",", False) Do
		For Each Attribute In ObjectAttributesToLock(ObjectsKind) Do
			If Result.Find(Attribute) = Undefined Then
				Result.Add(Attribute);
			EndIf;
		EndDo;
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function AttributesToSkip()
	
	If Object.ShowInternalAttributes Then
		Return New Array;
	EndIf;
	
	Result = New Array;
	DataProcessorObject = FormAttributeToValue("Object");
	
	AttributesNames = New Map;
	
	For Each KindOfObjectsToChange In StrSplit(KindsOfObjectsToChange, ",", False) Do
		MetadataObject = Metadata.FindByFullName(KindOfObjectsToChange);
		AttributesEditingSettings = DataProcessorObject.AttributesEditingSettings(MetadataObject);
		AttributesToEdit = AttributesEditingSettings.ToEdit;
		AttributesToSkip = AttributesEditingSettings.NotToEdit;
		
		If ValueIsFilled(AttributesToSkip) Then
			If AttributesToSkip.Find("*") = Undefined Then
				For Each AttributeName In AttributesToSkip Do
					AttributesNames.Insert(AttributeName);
				EndDo;
				Continue;
			Else
				AttributesToEdit = New Array;
			EndIf;
		Else
			If AttributesToEdit = Undefined 
				Or TypeOf(AttributesToEdit) = Type("Array") And AttributesToEdit.Find("*") <> Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		AttributesToSkip = New Array;
		MetadataObject = Metadata.FindByFullName(KindOfObjectsToChange);
		StandardAttributesDetails = MetadataObject.StandardAttributes; // Array of StandardAttributeDescription
		For Each AttributeDetails In StandardAttributesDetails Do
			AttributesToSkip.Add(AttributeDetails.Name);
		EndDo;
		
		AttributesDetails1 = MetadataObject.Attributes; // Array of MetadataObjectAttribute
		For Each AttributeDetails In AttributesDetails1 Do
			AttributesToSkip.Add(AttributeDetails.Name);
		EndDo;
		
		For Each TabularSection In MetadataObject.TabularSections Do
			If AttributesToEdit.Find(TabularSection.Name + ".*") <> Undefined Then
				Break;
			EndIf;
			TabularSectionAttributesDetails = TabularSection.Attributes; // Array of MetadataObjectAttribute
			For Each Attribute In TabularSectionAttributesDetails Do
				AttributesToSkip.Add(TabularSection.Name + "." + Attribute.Name);
			EndDo;
		EndDo;
		
		For Each AttributeName In AttributesToEdit Do
			IndexOf = AttributesToSkip.Find(AttributeName);
			If IndexOf = Undefined Then
				Continue;
			EndIf;
			AttributesToSkip.Delete(IndexOf);
		EndDo;
		
		For Each AttributeName In AttributesToSkip Do
			AttributesNames.Insert(AttributeName);
		EndDo;
	EndDo;
	
	For Each Item In AttributesNames Do
		AttributeName = Item.Key;
		Result.Add(AttributeName);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function DisabledAttributes()

	If Object.ShowInternalAttributes Then
		Return New Array;
	EndIf;
	
	ObjectsEnabled = ObjectsEnabled();
	
	For Each TypeName In StrSplit(KindsOfObjectsToChange, ",", False) Do
		MetadataObject = Metadata.FindByFullName(TypeName);
		DisabledAttributes = EditFilterByType(MetadataObject);
		
		AttributesDisabledByFunctionalOptions = New Map;
		
		AttributesDetails1 = MetadataObject.Attributes; // Array of MetadataObjectAttribute
		For Each Attribute In AttributesDetails1 Do
			If ObjectsEnabled[Attribute] = False Then
				AttributesDisabledByFunctionalOptions.Insert(Attribute.Name, True);
			EndIf;
		EndDo;
		
		TabularSectionsDetails = MetadataObject.TabularSections; // Array of MetadataObjectTabularSection
		For Each TabularSection In TabularSectionsDetails Do
			If ObjectsEnabled[TabularSection] = False Then
				AttributesDisabledByFunctionalOptions.Insert(TabularSection.Name + ".*", True);
				Continue;
			EndIf;
			For Each Attribute In TabularSection.Attributes Do
				If ObjectsEnabled[Attribute] = False Then
					AttributesDisabledByFunctionalOptions.Insert(TabularSection.Name + "." + Attribute.Name, True);
				EndIf;
			EndDo;
		EndDo;
		
		For Each PropsClosedWithFunctionalOptions In AttributesDisabledByFunctionalOptions Do
			DisabledAttributes.Insert(PropsClosedWithFunctionalOptions.Key, True);
		EndDo;
		
	EndDo;
		
	Result = New Array;
	For Each Attribute In DisabledAttributes Do
		Result.Add(Attribute.Key);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function ExcludedAttributeTypes()
	
	Result = Undefined;
	KindsOfObjectsToChangeList = StrSplit(KindsOfObjectsToChange, ",", False);
	
	If KindsOfObjectsToChangeList.Count() = 0 Then
		Return Result;
	EndIf;
	
	If Common.SubsystemExists("StandardSubsystems.FilesOperations") Then
		ModuleFilesOperationsInternal = Common.CommonModule("FilesOperationsInternal");
		ObjectName = KindsOfObjectsToChangeList[0];
		Result = New Map;
		For Each CatalogName In ModuleFilesOperationsInternal.FileStorageCatalogNames(
			Common.ObjectManagerByFullName(ObjectName).EmptyRef(), True) Do
			Result[Type("CatalogRef." + CatalogName.Key)] = True;
		EndDo;
	EndIf;
	
	Return Result;
	
EndFunction

&AtServer
Procedure FillObjectsTabularSections(DetailsOfAttributes, AvailableTabularSections)
	
	KindsOfObjectsToChangeList = StrSplit(KindsOfObjectsToChange, ",", False);
	If KindsOfObjectsToChangeList.Count() = 0 Then
		Return;
	EndIf;

	ObjectName = KindsOfObjectsToChangeList[0];
	MetadataObject = Metadata.FindByFullName(ObjectName);
	
	NewFormAttributes = New Array;
	TableColumns = AttributesTableColumnDescriptions();
	ObjectTables = New Structure;
	ObjectTabularSections.Clear();

	For Each TabularSectionDetails In MetadataObject.TabularSections Do
		If Not AvailableTabularSections.Property(TabularSectionDetails.Name) Then
			Continue;
		EndIf;
			
		If Not AccessRight("Edit", TabularSectionDetails) Then
			Continue;
		EndIf;

		If DetailsOfAttributes.AttributesToSkip.Find(TabularSectionDetails.Name + ".*") <> Undefined Then
			Continue;
		EndIf;
		If DetailsOfAttributes.DisabledAttributes.Find(TabularSectionDetails.Name + ".*") <> Undefined Then
			Continue;
		EndIf;
		
		EditableAttributes = EditableAttributes(TabularSectionDetails, DetailsOfAttributes, 
			AvailableTabularSections[TabularSectionDetails.Name]);
		If EditableAttributes.Count() = 0 Then
			Continue;
		EndIf;
		
		AttributeName = "TabularSection" + TabularSectionDetails.Name;
		ValueTable = New FormAttribute(AttributeName, New TypeDescription("ValueTable"), , TabularSectionDetails.Presentation());
		NewFormAttributes.Add(ValueTable);
		
		For Each ColumnDetails In TableColumns Do 
			TableAttribute = New FormAttribute(ColumnDetails.Name, ColumnDetails.Type, ValueTable.Name, ColumnDetails.Presentation);
			NewFormAttributes.Add(TableAttribute);
		EndDo;
		
		ObjectTables.Insert(AttributeName, TabularSectionDetails);
		ObjectTabularSections.Add(AttributeName, TabularSectionDetails.Presentation());
	EndDo;
	ChangeAttributes(NewFormAttributes);
	
	For Each ObjectTable In ObjectTables Do
		AttributeName = ObjectTable.Key;
		PageName = "Page" + AttributeName;
		Page = Items.Add(PageName, Type("FormGroup"), Items.ObjectComposition);
		Page.Type = FormGroupType.Page;
		TabularSectionDetails = ObjectTable.Value;
		Page.Title = TabularSectionDetails.Presentation();
		
		FormTable = Items.Add(AttributeName, Type("FormTable"), Page);
		FormTable.TitleLocation = FormItemTitleLocation.None;
		FormTable.DataPath = AttributeName;
		FormTable.CommandBarLocation = FormItemCommandBarLabelLocation.None;
		FormTable.Title = TabularSectionDetails.Presentation();
		FormTable.SetAction("BeforeRowChange", "Attachable_BeforeRowChange");
		FormTable.ChangeRowOrder = False;
		FormTable.ChangeRowSet = False;
		FormTable.RowsPicture = PictureLib.OperationKinds;
		FormTable.RowPictureDataPath = AttributeName + ".OperationKind";
		FormTable.Height = 5;
		
		For Each ColumnDetails In TableColumns Do 
			If ColumnDetails.FieldKind = Undefined Then
				Continue;
			EndIf;
			AttributeName = ColumnDetails.Name;
			TagName = FormTable.Name + AttributeName;
			TableColumn2 = Items.Add(TagName, Type("FormField"), FormTable);
			If ColumnDetails.Picture <> Undefined Then
				TableColumn2.TitleLocation = FormItemTitleLocation.None;
				TableColumn2.HeaderPicture = ColumnDetails.Picture;
			EndIf;
			TableColumn2.DataPath = ObjectTable.Key + "." + AttributeName;
			TableColumn2.Type = ColumnDetails.FieldKind;
			TableColumn2.EditMode = ColumnEditMode.EnterOnInput;
			TableColumn2.ReadOnly = ColumnDetails.ReadOnly;
			If ColumnDetails.Actions <> Undefined Then
				For Each Action In ColumnDetails.Actions Do
					TableColumn2.SetAction(Action.Key, Action.Value);
				EndDo;
			EndIf;
		EndDo;
		
		EditableAttributes = EditableAttributes(TabularSectionDetails, DetailsOfAttributes,
			AvailableTabularSections[TabularSectionDetails.Name]);	
		For Each AttributeDetails In EditableAttributes Do
			FormDataTable = ThisObject[ObjectTable.Key]; // See AttributesTableColumnDescriptions
			Attribute = FormDataTable.Add();
			Attribute.Name = AttributeDetails.Name;
			Attribute.Presentation = ?(IsBlankString(AttributeDetails.Presentation()), AttributeDetails.Name, 
				AttributeDetails.Presentation());
			Attribute.AllowedTypes = AttributeDetails.Type;
			Attribute.ChoiceParameterLinks = ChoiceParameterLinksAsString(AttributeDetails.ChoiceParameterLinks);
			Attribute.ChoiceParameters = ChoiceParametersAsString(AttributeDetails.ChoiceParameters);
			Attribute.OperationKind = 1;
			Attribute.ChoiceParameterLinksPresentation = ChoiceParameterLinksPresentation(
				AttributeDetails.ChoiceParameterLinks, MetadataObject);
		EndDo;
	EndDo;
	
EndProcedure

// Parameters:
//   TabularSectionDetails - Structure:
//     * Attributes - Array of MetadataObjectAttribute
//   DetailsOfAttributes - Structure
//   AvailableAttributes - Array
//
// Returns:
//   Array of MetadataObjectAttribute
//
&AtServer
Function EditableAttributes(TabularSectionDetails, DetailsOfAttributes, AvailableAttributes)
	
	Result = New Array;
	
	For Each AttributeDetails In TabularSectionDetails.Attributes Do
		If AvailableAttributes.Find(AttributeDetails.Name) = Undefined Then
			Continue;
		EndIf;
		
		If Not AccessRight("Edit", AttributeDetails) Then
			Continue;
		EndIf;
		
		If DetailsOfAttributes.AttributesToSkip.Find(TabularSectionDetails.Name + "." + AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		If DetailsOfAttributes.DisabledAttributes.Find(TabularSectionDetails.Name + "." + AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		If IsExcludedAttributeType(AttributeDetails, DetailsOfAttributes.ExcludedAttributeTypes) Then
			Continue;	
		EndIf;
		
		Result.Add(AttributeDetails);
	EndDo;
	
	Return Result;
	
EndFunction

// Returns:
//   ValueTable:
//   * Name - String
//   * Type - String
//   * Presentation - String 
//   * FieldKind - String
//   * Actions - Structure:
//     ** OnChange - Boolean
//     ** Attachable_OnCheckChange - Boolean
//   * ReadOnly - Boolean
//   * Picture - Picture
//
&AtServer
Function AttributesTableColumnDescriptions()
	
	TableColumns = New ValueTable;
	TableColumns.Columns.Add("Name");
	TableColumns.Columns.Add("Type");
	TableColumns.Columns.Add("Presentation");
	TableColumns.Columns.Add("FieldKind");
	TableColumns.Columns.Add("Actions");
	TableColumns.Columns.Add("ReadOnly", New TypeDescription("Boolean"));
	TableColumns.Columns.Add("Picture");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "Name";
	ColumnDetails.Type = New TypeDescription("String");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "Presentation";
	ColumnDetails.Type = New TypeDescription("String");
	ColumnDetails.Presentation = NStr("vi = 'Mục tin';
										|ru = 'Реквизит';
										|en = 'Attribute'; fa = 'ویژگی';
										|it = 'Requisito';
										|pl = 'Attribute';
										|tr = 'Öznitelik'");
	ColumnDetails.FieldKind = FormFieldType.InputField;
	ColumnDetails.ReadOnly = True;
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "Change";
	ColumnDetails.Type = New TypeDescription("Boolean");
	ColumnDetails.FieldKind = FormFieldType.CheckBoxField;
	ColumnDetails.Picture = PictureLib.Change;
	ColumnDetails.Actions = New Structure("OnChange", "Attachable_OnCheckChange");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "Value";
	ColumnDetails.Type = AllTypes();
	ColumnDetails.Presentation = NStr("vi = 'Giá trị mới';
										|ru = 'Новое значение';
										|en = 'New value'; fa = 'مقدار جدید';
										|it = 'Valore nuovo';
										|pl = 'Nowa wartość';
										|tr = 'Yeni değer'");
	ColumnDetails.FieldKind = FormFieldType.InputField;
	ColumnDetails.Actions = New Structure("OnChange", "Attachable_ValueOnChange");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "AllowedTypes";
	ColumnDetails.Type = New TypeDescription("TypeDescription");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "ChoiceParameterLinks";
	ColumnDetails.Type = New TypeDescription("String");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "ChoiceParameters";
	ColumnDetails.Type = New TypeDescription("String");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "OperationKind";
	ColumnDetails.Type = New TypeDescription("Number");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "Property";
	ColumnDetails.Type = New TypeDescription("String");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "ChoiceFoldersAndItems";
	ColumnDetails.Type = New TypeDescription("String");
	
	ColumnDetails = TableColumns.Add();
	ColumnDetails.Name = "ChoiceParameterLinksPresentation";
	ColumnDetails.Type = New TypeDescription("String");
	
	Return TableColumns;
	
EndFunction

&AtServer
Function AllTypes()
	Result = Undefined;
	Attributes = GetAttributes("ObjectAttributes");
	For Each Attribute In Attributes Do
		If Attribute.Name = "Value" Then
			Result = Attribute.ValueType;
			Break;
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtClient
Procedure RestrictSelectableTypesAndSetValueChoiceParameters(TableBox)
	If TableBox.CurrentData = Undefined Then
		Return;
	EndIf;
	
	InputField = TableBox.ChildItems[TableBox.Name + "Value"];
	InputField.TypeRestriction = TableBox.CurrentData.AllowedTypes;
	
	If InputField.TypeRestriction.Types().Count() = 1 And InputField.TypeRestriction.ContainsType(Type("String")) Then
		InputField.ChoiceButton = True;
	EndIf;
	
	ChoiceParametersArray1 = New Array;
	
	If Not IsBlankString(TableBox.CurrentData.ChoiceParameters) Then
		SetSelectionParametersServer(TableBox.CurrentData.ChoiceParameters, ChoiceParametersArray1)
	EndIf;
	
	If Not IsBlankString(TableBox.CurrentData.ChoiceParameterLinks) Then
		For IndexOf = 1 To StrLineCount(TableBox.CurrentData.ChoiceParameterLinks) Do
			ChoiceParametersLinksString = StrGetLine(TableBox.CurrentData.ChoiceParameterLinks, IndexOf);
			ParsedStrings = StrSplit(ChoiceParametersLinksString, ";");
			ParameterName = TrimAll(ParsedStrings[0]);
			
			AttributeName = TrimAll(ParsedStrings[1]);
			AttributeNameParts = StrSplit(AttributeName, ".", False);
			TabularSectionName = "";
			If AttributeNameParts.Count() > 1 Then
				TabularSectionName = AttributeNameParts[0];
			EndIf;
			AttributeName = AttributeNameParts[AttributeNameParts.Count() - 1];
			
			AttributesTable = ObjectAttributes;
			If Not IsBlankString(TabularSectionName) Then
				AttributesTable = ThisObject["TabularSection" + TabularSectionName];
			EndIf;
			
			FoundRows = AttributesTable.FindRows(New Structure("OperationKind,Name", 1, AttributeName));
			If FoundRows.Count() = 1 Then
				Value = FoundRows[0].Value;
				If ValueIsFilled(Value) Then
					ChoiceParametersArray1.Add(New ChoiceParameter(ParameterName, Value));
				EndIf;
			EndIf;
		EndDo;
	EndIf;
	
	If ValueIsFilled(TableBox.CurrentData.Property) Then
		ChoiceParametersArray1.Add(New ChoiceParameter("Filter.Owner", TableBox.CurrentData.Property));
	EndIf;
	
	If DisableSelectionParameterConnections Then
		InputField.ChoiceParameters = New FixedArray(New Array);
	Else
		InputField.ChoiceParameters = New FixedArray(ChoiceParametersArray1);
	EndIf;
	
	ChoiceFoldersAndItems = TableBox.CurrentData.ChoiceFoldersAndItems;
	
	If ChoiceFoldersAndItems <> "" Then
		If ChoiceFoldersAndItems = "Groups" Then
			InputField.ChoiceFoldersAndItems = FoldersAndItems.Folders;
		ElsIf ChoiceFoldersAndItems = "FoldersAndItems" Then
			InputField.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
		ElsIf ChoiceFoldersAndItems = "Items" Then
			InputField.ChoiceFoldersAndItems = FoldersAndItems.Items;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateCountersOfAttributesToChange(Val FormTable = Undefined)
	
	TablesList = New Array;
	If FormTable <> Undefined Then
		TablesList.Add(FormTable);
	Else
		TablesList.Add(Items.ObjectAttributes);
		For Each TabularSection In ObjectTabularSections Do
			TablesList.Add(Items[TabularSection.Value]);
		EndDo;
	EndIf;
	
	For Each FormTable In TablesList Do
		TabularSection = ThisObject[FormTable.Name];
		ItemsToChangeCount = 0;
		For Each Attribute In TabularSection Do
			If Attribute.Change Then
				ItemsToChangeCount = ItemsToChangeCount + 1;
			EndIf;
		EndDo;
	
		Page = FormTable.Parent;// FormGroup
		Page.Title = FormTable.Title + ?(ItemsToChangeCount = 0, "", " (" + ItemsToChangeCount+ ")");
	EndDo;
	
EndProcedure

&AtServer
Procedure UpdateItemsVisibility()
	If ObjectTabularSections.Count() = 0 Then
		Items.ObjectComposition.PagesRepresentation = FormPagesRepresentation.None;
	Else
		Items.ObjectComposition.PagesRepresentation = FormPagesRepresentation.TabsOnTop;
	EndIf;
	
	If Not IsBlankString(KindsOfObjectsToChange) Then
		CommonAttributesAvailable = ObjectAttributes.Count() > 0;
		Items.NoAttributesGroup.Visible = Not CommonAttributesAvailable;
		If Object.OperationType = "ExecuteAlgorithm" Then
			Items.Algorithms.Visible = True;
		Else
			Items.PreviouslyChangedAttributes.Visible = CommonAttributesAvailable Or ObjectTabularSections.Count() > 0;
		EndIf;
		Items.ObjectAttributes.Visible = CommonAttributesAvailable;
	EndIf;
EndProcedure

&AtServer
Procedure FillObjectAttributes(DetailsOfAttributes, AvailableAttributes)
	
	ObjectAttributes.Clear();
	
	KindsOfObjectsToChangeList = StrSplit(KindsOfObjectsToChange, ",", False);
	If KindsOfObjectsToChangeList.Count() = 0 Then
		Return;
	EndIf;
	
	ObjectName = KindsOfObjectsToChangeList[0];
	MetadataObject = Metadata.FindByFullName(ObjectName);

	AddAttributesToSet(DetailsOfAttributes, MetadataObject, AvailableAttributes, MetadataObject.StandardAttributes);
	AddAttributesToSet(DetailsOfAttributes, MetadataObject, AvailableAttributes, MetadataObject.Attributes);
	ObjectAttributes.Sort("Presentation Asc");
	
	If Common.SubsystemExists("StandardSubsystems.Properties") Then
		ModulePropertyManager = Common.CommonModule("PropertyManager");
		If ModulePropertyManager <> Undefined Then
			AdditionalAttributesUsed = True;
			AdditionalInfoUsed = True;
			For Each ObjectKind In KindsOfObjectsToChangeList Do
				ObjectManager = Common.ObjectManagerByFullName(ObjectKind);
				AdditionalAttributesUsed = AdditionalAttributesUsed And ModulePropertyManager.UseAddlAttributes(ObjectManager.EmptyRef());
				AdditionalInfoUsed  = AdditionalInfoUsed And ModulePropertyManager.UseAddlInfo (ObjectManager.EmptyRef());
			EndDo;
			If AdditionalAttributesUsed Or AdditionalInfoUsed Then
				AddAdditionalAttributesAndInfoToSet();
			EndIf;
		EndIf;
	EndIf;
	
	AddExternalAttributesToSet(DetailsOfAttributes, KindsOfObjectsToChangeList);
	
EndProcedure

&AtServer
Procedure AddAdditionalAttributesAndInfoToSet()
	
	DataProcessorObject = FormAttributeToValue("Object");
	
	KindsOfObjectsToChangeList = StrSplit(KindsOfObjectsToChange, ",", False);
	CommonAttributesList = PropertiesListForObjectsKind(KindsOfObjectsToChangeList[0]);
	For IndexOf = 1 To KindsOfObjectsToChangeList.Count() - 1 Do
		CommonAttributesList = DataProcessorObject.SetIntersection(CommonAttributesList, PropertiesListForObjectsKind(KindsOfObjectsToChangeList[IndexOf]));
	EndDo;
	
	PropertiesToAdd = New Array;
	
	If ContextCall Then
		Filter_Settings = Filter_Settings();
		Filter_Settings.UpdateList = True;
		SelectedObjects = SelectedObjects(Filter_Settings).Rows;
		For Each ObjectData In SelectedObjects Do
			ObjectToChange1 = ObjectData.Ref;
			
			ObjectKindByRef = Common.ObjectKindByRef(ObjectToChange1);
			If (ObjectKindByRef = "Catalog" Or ObjectKindByRef = "ChartOfCharacteristicTypes")
				And Common.ObjectIsFolder(ObjectToChange1) Then
				Continue;
			EndIf;
			
			ModulePropertyManager = Common.CommonModule("PropertyManager");
			ListOfProperties = ModulePropertyManager.ObjectProperties(ObjectToChange1);
			For Each Property In ListOfProperties Do
				If CommonAttributesList.Find(Property) = Undefined Then
					Continue;
				EndIf;
				
				If PropertiesToAdd.Find(Property) <> Undefined Then
					Continue;
				EndIf;
				
				PropertiesToAdd.Add(Property);
			EndDo;
		EndDo;
	Else
		PropertiesToAdd = CommonAttributesList;
	EndIf;
	
	AddPropertiesToAttributesList(PropertiesToAdd);
	ObjectAttributes.Sort("Presentation");
	
EndProcedure

&AtServer
Procedure AddPropertiesToAttributesList(Properties)
	
	DetailsOfProperties = Common.ObjectsAttributesValues(Properties, "Ref,Description,ValueType,IsAdditionalInfo");
	
	For Each Property In Properties Do
		PropertyDetails = DetailsOfProperties[Property];
		AttributeDetails = ObjectAttributes.Add();
		AttributeDetails.OperationKind = ?(PropertyDetails.IsAdditionalInfo, 3, 2);
		AttributeDetails.Property = PropertyDetails.Ref;
		AttributeDetails.Presentation = PropertyDetails.Description;
		AttributeDetails.AllowedTypes = PropertyDetails.ValueType;
	EndDo;
	
EndProcedure

&AtServer
Function PropertiesListForObjectsKind(ObjectsKind)
	Result = New Array;
	
	PropertiesKinds = New Array;
	PropertiesKinds.Add("AdditionalAttributes");
	PropertiesKinds.Add("AdditionalInfo");
	
	ModulePropertyManagerInternal = Common.CommonModule("PropertyManagerInternal");
	If ModulePropertyManagerInternal <> Undefined Then
		For Each PropertyKind1 In PropertiesKinds Do
			ListOfProperties = ModulePropertyManagerInternal.PropertiesListForObjectsKind(ObjectsKind, PropertyKind1);
			If ListOfProperties <> Undefined Then
				For Each Item In ListOfProperties Do
					Result.Add(Item.Property);
				EndDo;
			EndIf;
		EndDo;
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure AddAttributesToSet(DetailsOfAttributes, MetadataObject, AvailableAttributes, AttributesDetails2)
	
	For Each AttributeDetails In AttributesDetails2 Do
		If AvailableAttributes.Find(AttributeDetails.Name) = Undefined Then
			Continue;
		EndIf;
		
		If TypeOf(AttributeDetails) = Type("StandardAttributeDescription") Then
			If Not AccessRight("Edit", MetadataObject, , AttributeDetails.Name) Then
				Continue;
			EndIf;
		Else
			If Not AccessRight("Edit", AttributeDetails) Then
				Continue;
			EndIf;
		EndIf;
		
		If DetailsOfAttributes.AttributesToSkip.Find(AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		If DetailsOfAttributes.DisabledAttributes.Find(AttributeDetails.Name) <> Undefined Then
			Continue;
		EndIf;
		If IsExcludedAttributeType(AttributeDetails, DetailsOfAttributes.ExcludedAttributeTypes) Then
			Continue;	
		EndIf;
		
		ChoiceFoldersAndItems = "";
		If TypeOf(AttributeDetails) = Type("StandardAttributeDescription") Then
			If AttributeDetails.Name = "Parent" Or AttributeDetails.Name = "Parent" Then
				ChoiceFoldersAndItems = "Groups";
			ElsIf AttributeDetails.Name = "Owner" Or AttributeDetails.Name = "Owner" Then
				If MetadataObject.SubordinationUse = Metadata.ObjectProperties.SubordinationUse.ToItems Then
					ChoiceFoldersAndItems = "Items";
				ElsIf MetadataObject.SubordinationUse = Metadata.ObjectProperties.SubordinationUse.ToFoldersAndItems Then
					ChoiceFoldersAndItems = "FoldersAndItems";
				ElsIf MetadataObject.SubordinationUse = Metadata.ObjectProperties.SubordinationUse.ToFolders Then
					ChoiceFoldersAndItems = "Groups";
				EndIf;
			EndIf;
		Else
			IsReference = False;
			
			For Each Type In AttributeDetails.Type.Types() Do
				If Common.IsReference(Type) Then
					IsReference = True;
					Break;
				EndIf;
			EndDo;
			
			If IsReference Then
				If AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.Folders Then
					ChoiceFoldersAndItems = "Groups";
				ElsIf AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.FoldersAndItems Then
					ChoiceFoldersAndItems = "FoldersAndItems";
				ElsIf AttributeDetails.ChoiceFoldersAndItems = FoldersAndItemsUse.Items Then
					ChoiceFoldersAndItems = "Items";
				EndIf;
			EndIf;
		EndIf;
		
		KindsOfObjectsToChangeList = StrSplit(KindsOfObjectsToChange, ",", False);
		ChoiceParameterLinksPresentation = "";
		If KindsOfObjectsToChangeList.Count() = 1 Then
			ChoiceParametersString = ChoiceParametersAsString(AttributeDetails.ChoiceParameters);
			ChoiceParameterLinksString = ChoiceParameterLinksAsString(AttributeDetails.ChoiceParameterLinks);
			ChoiceParameterLinksPresentation = ChoiceParameterLinksPresentation(AttributeDetails.ChoiceParameterLinks, MetadataObject);
		Else
			ChoiceParametersString = ChoiceParametersAsString(New Array);
			ChoiceParameterLinksString = ChoiceParameterLinksAsString(New Array);
		EndIf;
		
		ObjectAttribute = ObjectAttributes.Add();
		ObjectAttribute.Name = AttributeDetails.Name;
		ObjectAttribute.Presentation = AttributeDetails.Presentation();
		
		ObjectAttribute.AllowedTypes = AttributeDetails.Type;
		ObjectAttribute.ChoiceParameters = ChoiceParametersString;
		ObjectAttribute.ChoiceParameterLinks = ChoiceParameterLinksString;
		ObjectAttribute.ChoiceParameterLinksPresentation = ChoiceParameterLinksPresentation;
		ObjectAttribute.ChoiceFoldersAndItems = ChoiceFoldersAndItems;
		ObjectAttribute.OperationKind = 1;
		
		If DetailsOfAttributes.LockedAttributes.Find(AttributeDetails.Name) <> Undefined Then
			ObjectAttribute.LockedAttribute = True;
		EndIf;
		
		ObjectAttribute.IsStandardAttribute = TypeOf(AttributeDetails) = Type("StandardAttributeDescription");
		
	EndDo;
	
EndProcedure

&AtServer
Procedure AddExternalAttributesToSet(AttributesSets, KindsOfObjectsToChangeList)
	
	ExternalAttributes = New Array; // Array of See UsersInternal.
	UsersInternal.OnFillExternalAttributes(KindsOfObjectsToChangeList, ExternalAttributes);
	
	For Each ExternalAttribute In ExternalAttributes Do
		If Not Object.ShowInternalAttributes
		   And ExternalAttribute.IsInternal Then
			Continue;
		EndIf;
		AttributeDetails = ObjectAttributes.Add();
		AttributeDetails.OperationKind = 4;
		AttributeDetails.Name = ExternalAttribute.Name;
		AttributeDetails.Presentation = ExternalAttribute.Presentation;
		AttributeDetails.AllowedTypes = ExternalAttribute.ValueType;
	EndDo;
	
	ObjectAttributes.Sort("Presentation");
	
EndProcedure

&AtServer
Function IsExcludedAttributeType(AttributeDetails, ExcludedAttributeTypes)

	If ExcludedAttributeTypes = Undefined Then
		Return False;
	EndIf;

	Result = False;
	For Each AttributeType In AttributeDetails.Type.Types() Do
		If ExcludedAttributeTypes[AttributeType] = True Then 
			Result = True;
			Continue;
		EndIf;
	EndDo;
	Return Result;
	
EndFunction

&AtServer
Function FilterAttributes_()

	Result = New ValueTable;
	Result.Columns.Add("ObjectType", New TypeDescription("String", New StringQualifiers(80)));
	Result.Columns.Add("Attribute", New TypeDescription("String", New StringQualifiers(80)));
	
	// All objects.
	Filter = Result.Add();
	Filter.ObjectType = "*";
	Filter.Attribute = "Description";

	Filter = Result.Add();
	Filter.ObjectType = "*";
	Filter.Attribute = "DeletionMark";

	Filter = Result.Add();
	Filter.ObjectType = "*";
	Filter.Attribute = "Ref";

	Filter = Result.Add();
	Filter.ObjectType = "*";
	Filter.Attribute = "AdditionalAttributes.*";

	Filter = Result.Add();
	Filter.ObjectType = "*";
	Filter.Attribute = "ContactInformation.*";

	// Catalogs.
	Filter = Result.Add();
	Filter.ObjectType = "Catalogs";
	Filter.Attribute = "PredefinedDataName";

	Filter = Result.Add();
	Filter.ObjectType = "Catalogs";
	Filter.Attribute = "Code";

	Filter = Result.Add();
	Filter.ObjectType = "Catalogs";
	Filter.Attribute = "Predefined";

	Filter = Result.Add();
	Filter.ObjectType = "Catalogs";
	Filter.Attribute = "IsFolder";

	Filter = Result.Add();
	Filter.ObjectType = "Catalogs";
	Filter.Attribute = "AddlOrderingAttribute";
	
	// Documents.
	Filter = Result.Add();
	Filter.ObjectType = "Documents";
	Filter.Attribute = "Number";

	Filter = Result.Add();
	Filter.ObjectType = "Documents";
	Filter.Attribute = "Posted";
	
	// Charts of characteristic types.
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCharacteristicTypes";
	Filter.Attribute = "PredefinedDataName";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCharacteristicTypes";
	Filter.Attribute = "Code";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCharacteristicTypes";
	Filter.Attribute = "Predefined";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCharacteristicTypes";
	Filter.Attribute = "IsFolder";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCharacteristicTypes";
	Filter.Attribute = "ValueType";
	
	// Charts of accounts.
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfAccounts";
	Filter.Attribute = "PredefinedDataName";

	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfAccounts";
	Filter.Attribute = "Code";

	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfAccounts";
	Filter.Attribute = "Predefined";

	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfAccounts";
	Filter.Attribute = "Order";

	// Charts of calculation types.
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCalculationTypes";
	Filter.Attribute = "PredefinedDataName";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCalculationTypes";
	Filter.Attribute = "Code";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCalculationTypes";
	Filter.Attribute = "Predefined";
	
	Filter = Result.Add();
	Filter.ObjectType = "ChartsOfCalculationTypes";
	Filter.Attribute = "ActionPeriodIsBasic";
	
	// Tasks.
	Filter = Result.Add();
	Filter.ObjectType = "Tasks";
	Filter.Attribute = "Number";
	
	// Business processes.
	Filter = Result.Add();
	Filter.ObjectType = "BusinessProcesses";
	Filter.Attribute = "Number";

	Filter = Result.Add();
	Filter.ObjectType = "BusinessProcesses";
	Filter.Attribute = "Date";
	
	// Exchange plans.
	Filter = Result.Add();
	Filter.ObjectType = "ExchangePlans";
	Filter.Attribute = "Code";
	
	Filter = Result.Add();
	Filter.ObjectType = "ExchangePlans";
	Filter.Attribute = "SentNo";
	
	Filter = Result.Add();
	Filter.ObjectType = "ExchangePlans";
	Filter.Attribute = "ReceivedNo";
	
	Result.Indexes.Add("ObjectType");
	
	Return Result;
EndFunction
	
// Parameters:
//   MetadataObject - MetadataObject
// 
// Returns:
//   Map
//
&AtServer
Function EditFilterByType(MetadataObject)
	
	FilterTable1 = FilterAttributes_();
	
	// Attributes lockable for any metadata object type.
	CommonFilter = FilterTable1.FindRows(New Structure("ObjectType", "*"));
	
	// Attributes lockable for the specified metadata object type.
	FilterByObjectType = FilterTable1.FindRows(New Structure("ObjectType", 
		Common.BaseTypeNameByMetadataObject(MetadataObject)));
	
	DisabledAttributes = New Map;
	
	For Each RowDescription1 In CommonFilter Do
		DisabledAttributes[RowDescription1.Attribute] = True;
	EndDo;
	
	For Each RowDescription1 In FilterByObjectType Do
		DisabledAttributes[RowDescription1.Attribute] = True;
	EndDo;
	
	AttributesBeingDeletedPrefix = "Delete";
	AttributesDetails1 = MetadataObject.Attributes; // Array of MetadataObjectAttribute
	For Each Attribute In AttributesDetails1 Do
		If Lower(Left(Attribute.Name, StrLen(AttributesBeingDeletedPrefix))) = Lower(AttributesBeingDeletedPrefix) Then
			DisabledAttributes[Attribute.Name] = True;
		EndIf;
	EndDo;
	For Each TabularSection In MetadataObject.TabularSections Do
		If Lower(Left(TabularSection.Name, StrLen(AttributesBeingDeletedPrefix))) = Lower(AttributesBeingDeletedPrefix) Then
			DisabledAttributes[TabularSection.Name + ".*"] = True;
		Else
			TabularSectionAttributesDetails = TabularSection.Attributes; // Array of MetadataObjectAttribute
			For Each Attribute In TabularSectionAttributesDetails Do
				If Lower(Left(Attribute.Name, StrLen(AttributesBeingDeletedPrefix))) = Lower(AttributesBeingDeletedPrefix) Then
					DisabledAttributes[TabularSection.Name + "." + Attribute.Name] = True;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Return DisabledAttributes;
	
EndFunction

&AtServer
Function FilterItemsNoHierarchy(Val FilterItems1)
	Result = New Array;
	For Each FilterElement In FilterItems1 Do
		If TypeOf(FilterElement) = Type("DataCompositionFilterItemGroup") Then
			SubordinateFilters = FilterItemsNoHierarchy(FilterElement.Items);
			For Each SubordinateFilter In SubordinateFilters Do
				Result.Add(SubordinateFilter);
			EndDo;
		Else
			Result.Add(FilterElement);
		EndIf;
	EndDo;
	Return Result;
EndFunction

&AtServer
Procedure GenerateNoteOnConfiguredChanges()
	
	FilterByRowsAvailable = False;
	For Each FilterElement In FilterItemsNoHierarchy(SettingsComposer.Settings.Filter.Items) Do
		If Not FilterElement.Use Then
			Continue;
		EndIf;
		For Each TabularSection In ObjectTabularSections Do
			TabularSectionName = Mid(TabularSection.Value, StrLen("TabularSection") + 1);
			If StrStartsWith(FilterElement.LeftValue, TabularSectionName) Then
				FilterByRowsAvailable = True;
				Break;
			EndIf;
		EndDo;
	EndDo;
	
	TabularSectionsToChange = New Map;
	For Each TabularSection In ObjectTabularSections Do
		AttributesToChange = New Array;
		For Each Attribute In ThisObject[TabularSection.Value] Do
			If Attribute.Change Then
				AttributesToChange.Add(Attribute.Presentation);
			EndIf;
		EndDo;
		If AttributesToChange.Count() > 0 Then 
			TabularSectionsToChange.Insert(TabularSection.Presentation, AttributesToChange);
		EndIf;
	EndDo;
	
	AttributesToChange = New Array;
	For Each Attribute In ObjectAttributes Do
		If Attribute.Change Then
			AttributesToChange.Add(Attribute.Presentation);
		EndIf;
	EndDo;
	
	If Not SelectedObjectsAvailable() Then
		Explanation = NStr("vi = 'Chưa chọn phần tử mà có mục tin cần thay đổi.';
							|ru = 'Не выбраны элементы, реквизиты которых необходимо изменить.';
							|en = 'No items selected.'; fa = 'No items selected.';
							|it = 'Nono sono stati selezionati elementi, requisiti dei quali devono essere modificati.';
							|pl = 'Nie wybrano żadnych elementów, których dane wymagają zmiany.';
							|tr = 'Özniteliklerin değiştirileceği öğeler seçilmedi.'");
	Else
		If AttributesToChange.Count() = 1 Then
			NoteTemplate = NStr("vi = 'Thay đổi mục tin %1 trong các mục đã chọn';
								|ru = 'Изменить реквизит %1 в выбранных элементах';
								|en = 'Change the %1 attribute for the selected items'; fa = 'Change the %1 attribute for the selected items';
								|it = 'Modificare il requisito %1 negli elementi selezionati';
								|pl = 'Zmień atrybut %1 w wybranych elementach';
								|tr = 'Seçili öğelerde %1 özniteliğini değiştir'") // for example, "Change the details ""Warehouse""..."
		ElsIf AttributesToChange.Count() > 3 Then
			NoteTemplate = NStr("vi = 'Thay đổi chi tiết (%1) trong các mục đã chọn';
								|ru = 'Изменить реквизиты (%1) в выбранных элементах';
								|en = 'Change %1 attributes for the selected items'; fa = 'Change %1 attributes for the selected items';
								|it = 'Modificare i requisiti (%1) negli elementi selezionati';
								|pl = 'Zmień atrybuty (%1) w wybranych elementach';
								|tr = 'Seçili öğelerde (%1) özniteliklerini değiştir'"); // Example: "Update attributes (5)..."
		ElsIf AttributesToChange.Count() > 1 Then
			NoteTemplate = NStr("vi = 'Thay đổi mục tin (%1) trong các phần tử đã chọn';
								|ru = 'Изменить реквизиты %1 в выбранных элементах';
								|en = 'Change the %1 attributes for the selected items'; fa = 'Change the %1 attributes for the selected items';
								|it = 'Modificare i requisiti %1 negli elementi selezionati';
								|pl = 'Zmień atrybuty %1 w wybranych elementach';
								|tr = 'Seçili öğelerde %1 özniteliklerini değiştir'"); // Example: "Update attributes ""Warehouse"", ""Office""..."
		Else	
			NoteTemplate = "";
		EndIf;
		
		If AttributesToChange.Count() > 3 Then
			Explanation = StringFunctionsClientServer.SubstituteParametersToString(NoteTemplate, AttributesToChange.Count());
		ElsIf AttributesToChange.Count() > 0 Then
			Explanation = StringFunctionsClientServer.SubstituteParametersToString(NoteTemplate, AttributesNames(AttributesToChange));
		Else
			Explanation = "";
		EndIf;
		
		For Each TabularSection In TabularSectionsToChange Do
			
			AttributesToChange = TabularSection.Value;
			If AttributesToChange.Count() = 0 Then
				Continue;
			EndIf;
			
			If AttributesToChange.Count() = 1 Then
				NoteTemplate = ?(IsBlankString(Explanation),
					NStr("vi = 'Thay đổi mục tin %1 trong phần bảng ""%2""';
						|ru = 'Изменить реквизит %1 в табличной части ""%2""';
						|en = 'Change the attribute %1 in tabular section ""%2""'; fa = 'Change the attribute %1 in tabular section ""%2""';
						|it = 'Modificare il requisito %1 nella tabella ""%2""';
						|pl = 'Zmień atrybut %1 w sekcji tabelarycznej ""%2""';
						|tr = '""%2"" tablo bölümündeki %1 özniteliğini değiştir'"),
					NStr("vi = 'mục tin %1 trong phần bảng ""%2""';
						|ru = 'реквизит %1 в табличной части ""%2""';
						|en = 'the %1 attribute in tabular section ""%2""'; fa = 'the %1 attribute in tabular section ""%2""';
						|it = 'il requisito %1 nella tabella ""%2""';
						|pl = 'atrybut %1 w sekcji tabelarycznej""%2""';
						|tr = '""%2"" tablo bölümündeki %1 özniteliği'")); 
			ElsIf AttributesToChange.Count() > 3 Then
				NoteTemplate = ?(IsBlankString(Explanation),
					NStr("vi = 'Thay đổi chi tiết (%1) trong phần bảng ""%2""';
						|ru = 'Изменить реквизиты (%1) в табличной части ""%2""';
						|en = 'Change %1 attributes in tabular section ""%2""'; fa = 'Change %1 attributes in tabular section ""%2""';
						|it = 'Modificare i requisiti (%1) nella tabella ""%2""';
						|pl = 'Zmień atrybuta (%1) w sekcji tabelarycznej ""%2""';
						|tr = '""%2"" tablo bölümündeki (%1) özniteliklerini değiştir'"),
					NStr("vi = 'mục tin (%1) trong phần bảng ""%2""';
						|ru = 'реквизиты (%1) в табличной части ""%2""';
						|en = '%1 attributes in tabular section ""%2""'; fa = '%1 attributes in tabular section ""%2""';
						|it = 'i requisiti (%1) nella tabella ""%2""';
						|pl = 'atrybuty (%1) w sekcji tabelarycznej ""%2""';
						|tr = '""%2"" tablo bölümünde öznitelikler (%1)'")); 
			Else 
				NoteTemplate = ?(IsBlankString(Explanation),
					NStr("vi = 'Thay đổi mục tin %1 trong phần bảng ""%2""';
						|ru = 'Изменить реквизиты %1 в табличной части ""%2""';
						|en = 'Change the %1 attributes in tabular section ""%2""'; fa = 'Change the %1 attributes in tabular section ""%2""';
						|it = 'Modificare i requisiti %1nella tabella ""%2""';
						|pl = 'Zmień atrybuty %1 w sekcji tabelarycznej ""%2""';
						|tr = '""%2"" tablo bölümündeki %1 özniteliklerini değiştir'"),
					NStr("vi = 'chi tiết %1 trong phần bảng ""%2""';
						|ru = 'реквизиты %1 в табличной части ""%2""';
						|en = 'the %1 attributes in tabular section ""%2""'; fa = 'the %1 attributes in tabular section ""%2""';
						|it = 'i requisiti %1 nella tabella ""%2""';
						|pl = 'atrybuty %1 w sekcji tabelarycznej ""%2""';
						|tr = '""%2"" tablo bölümünde %1 öznitelikleri'")); 
			EndIf;
			
			If Not IsBlankString(Explanation) Then
				Explanation = Explanation + ", ";
			EndIf;
			If AttributesToChange.Count() > 3 Then
				Explanation = Explanation + StringFunctionsClientServer.SubstituteParametersToString(NoteTemplate, 
					AttributesToChange.Count(), TabularSection.Key);
			Else
				Explanation = Explanation + StringFunctionsClientServer.SubstituteParametersToString(NoteTemplate, 
					AttributesNames(AttributesToChange), TabularSection.Key);
			EndIf;
		EndDo;
		
		If Not IsBlankString(Explanation) Then
			Explanation = Explanation + ".";
			If TabularSectionsToChange.Count() > 0 Then
				If FilterByRowsAvailable Then 
					Explanation = Explanation + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Sẽ thực hiện thay đổi trong các dòng của phần tử đã chọn đáp ứng <a href = ""%1"">điều kiện lọc</a>.';
						|ru = 'Изменения будут выполнены в тех строках выбранных элементов, которые удовлетворяют <a href = ""%1"">условиям отбора</a>.';
						|en = 'Apply the changes only to the lines of the selected items that match the <a href = ""%1"">filter</a>.'; fa = 'Apply the changes only to the lines of the selected items that match the <a href = ""%1"">filter</a>.';
						|it = 'Изменения будут выполнены в тех строках выбранных элементов, которые удовлетворяют <a href = ""%1"">условиям отбора</a>.';
						|pl = 'Apply the changes only to the lines of the selected items that match the <a href = ""%1"">filter</a>.';
						|tr = 'Aşağıdakileri filtre koşullarını karşılayan seçili öğelerin satırlarında değişiklikler yapılacaktır <a href = ""%1""></a>.'"),
						"GoToFilterSettings");
				Else
					Explanation = Explanation + " " + StringFunctionsClientServer.SubstituteParametersToString(NStr(
						"vi = 'Sẽ thực hiện thay đổi <a href = ""%1"">trong tất cả các dòng</a> của phần tử đã chọn.';
						|ru = 'Изменения будут выполнены <a href = ""%1"">во всех строках</a> выбранных элементов.';
						|en = 'Apply the changes <a href = ""%1"">to all lines</a> of the selected items.'; fa = 'Apply the changes <a href = ""%1"">to all lines</a> of the selected items.';
						|it = 'Изменения будут выполнены <a href = ""%1"">во всех строках</a> выбранных элементов.';
						|pl = 'Apply the changes <a href = ""%1"">to all lines</a> of the selected items.';
						|tr = 'Seçilen öğelerin tüm <a href = ""%1""> satırlarında </a>değişiklikler yapılacaktır.'"),
						"GoToFilterSettings");
				EndIf;
			EndIf;
		Else
			Explanation = NStr("vi = 'Thực hiện <b>ghi lại </b> các phần tử đã chọn.';
								|ru = 'Выполнить <b>перезапись</b> выбранных элементов.';
								|en = '<b>Overwrite</b> the selected items.'; fa = '<b>Overwrite</b> the selected items.';
								|it = 'Выполнить <b>перезапись</b> выбранных элементов.';
								|pl = '<b>Overwrite</b> the selected items.';
								|tr = '<b>Seçilmiş öğeler</b> yeniden yazılsın.'");
		EndIf;
	EndIf;
	
	Items.NoteOnConfiguredChanges.Title = StringFunctions.FormattedString(Explanation);
	If IsBlankString(AlgorithmCode) Then
		AlgorithmCode = StringFunctionsClientServer.SubstituteParametersToString(NStr("vi = '// Các biến có sẵn:
		|// %1 - đối tượng xử lý';
		|ru = '// Доступные переменные:
		|// %1 - обрабатываемый объект';
		|en = '// Available variables:
		|// %1 - an object to be processed.'; fa = '// Available variables:
		|// %1 - an object to be processed.';
		|it = '//  Variabili disponibili:
		|// %1 - oggetto in corso di elaborazione';
		|pl = '// Dostępne tymczasowe:
		|// %1 - przetwarzany obiekt';
		|tr = '// Erişilen değişkenler:
		|//%1-işlenen nesne'"), "Object") + Chars.LF;
	EndIf;
	
EndProcedure

&AtServer
Function AttributesNames(Val AttributesToChange)
	
	AttributesNames = "";
	For Each Attribute In AttributesToChange Do
		If Not IsBlankString(AttributesNames) Then
			AttributesNames = AttributesNames + ", ";
		EndIf;
		AttributesNames = AttributesNames + """" + Attribute + """";
	EndDo;
	Return AttributesNames;

EndFunction

&AtServer
Function SelectedObjectsAvailable()
	Filter_Settings = Filter_Settings();
	Filter_Settings.RestrictSelection = True;
	Return SelectedObjects(Filter_Settings).Rows.Count() > 0;
EndFunction

&AtServer
Procedure UpdateSelectedCountLabel()
	
	If AvailableConfiguredFilters() Then
		ErrorMessageText = "";
		SelectedObjectsCount = SelectedObjectsCount(True, , ErrorMessageText);
		LabelText = StringFunctionsClientServer.StringWithNumberForAnyLanguage(NStr("vi = ';%1 phần tử;;%1 phần tử;%1 phần tử;%1 phần tử';
																					|ru = ';%1 элемент;;%1 элемента;%1 элементов;%1 элемента';
																					|en = ';%1 item;;;;%1 items'; fa = ';%1 item;;;;%1 items';
																					|it = ';%1 elemento;;%1 dell''elemento;%1 degli elementi;%1 dell''elemento';
																					|pl = ';%1 element;;%1 elementu;%1 elementów;%1 elementu';
																					|tr = ';%1 öğe;;%1 öğe;%1 öğe;%1 öğe'"),
			SelectedObjectsCount);
	Else
		LabelText = NStr("vi = 'Tất cả phần tử';
						|ru = 'Все элементы';
						|en = 'All items'; fa = 'همه اقلام';
						|it = 'Tutti gli elementi';
						|pl = 'Wszystkie elementy';
						|tr = 'Tüm öğeler'");
	EndIf;
	
	Items.FilterSettings.Title = LabelText;
EndProcedure

&AtServer
Procedure FillPreviouslyChangedAttributesSubmenu()
	
	CommandLocation = Items.PreviouslyChangedAttributes;
	
	ItemsToRemove = New Array;
	For Each Setting In CommandLocation.ChildItems Do
		If Setting.Name = "Stub" Then
			Continue;
		EndIf;
		ItemsToRemove.Add(Setting);
	EndDo;
	
	For Each Setting In ItemsToRemove Do
		Commands.Delete(Commands[Setting.Name]);
		Items.Delete(Setting);
	EndDo;
	
	For Each Setting In OperationsHistoryList Do
		CommandNumber = OperationsHistoryList.IndexOf(Setting);
		CommandName = CommandLocation.Name + "ChangesSetting" + CommandNumber;
		
		FormCommand = Commands.Add(CommandName);
		FormCommand.Action = "Attachable_SetSetting";
		FormCommand.Title = Setting.Presentation;
		FormCommand.ModifiesStoredData = False;
		
		NewItem = Items.Add(CommandName, Type("FormButton"), CommandLocation);
		NewItem.Type = FormButtonType.CommandBarButton;
		NewItem.CommandName = CommandName;
	EndDo;
	
	Items.Stub.Visible = OperationsHistoryList.Count() = 0;
	
	If Not ContextCall Then
		FillAlgorithmsListSubmenu();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillAlgorithmsListSubmenu()
	CommandLocation = Items.Algorithms;
	
	ItemsToRemove = New Array;
	For Each Setting In CommandLocation.ChildItems Do
		If Setting.Name = "StubAlgorythms" Then
			Continue;
		EndIf;
		ItemsToRemove.Add(Setting);
	EndDo;
	
	For Each Setting In ItemsToRemove Do
		Commands.Delete(Commands[Setting.Name]);
		Items.Delete(Setting);
	EndDo;
	
	For Each Setting In AlgorithmsHistoryList Do
		CommandNumber = AlgorithmsHistoryList.IndexOf(Setting);
		CommandName = CommandLocation.Name + "ChangesSetting" + CommandNumber;
		
		FormCommand = Commands.Add(CommandName);
		FormCommand.Action = "Attachable_SetSetting";
		FormCommand.Title = Setting.Presentation;
		FormCommand.ModifiesStoredData = False;
		
		NewItem = Items.Add(CommandName, Type("FormButton"), CommandLocation);
		NewItem.Type = FormButtonType.CommandBarButton;
		NewItem.CommandName = CommandName;
	EndDo;
	
	Items.StubAlgorythms.Visible = AlgorithmsHistoryList.Count() = 0;
EndProcedure

&AtClient
Procedure SetChangeSetting(Val Setting)
	
	ResetChangeSettings();
	
	LockedAttributesAvailable = False;
	
	// For backward compatibility with settings saved in SSL 2.1.
	If TypeOf(Setting) <> Type("Structure") Then
		Setting = New Structure("Attributes,TabularSections", Setting, New Structure);
	EndIf;
	
	For Each AttributeToChange In Setting.Attributes Do
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("OperationKind", AttributeToChange.OperationKind);
		If AttributeToChange.OperationKind = 1 Then // Object attribute.
			TheStructureOfTheSearch.Insert("Name", AttributeToChange.AttributeName);
		Else
			TheStructureOfTheSearch.Insert("Property", AttributeToChange.Property);
		EndIf;
		
		FoundRows = ObjectAttributes.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			If FoundRows[0].LockedAttribute  Then
				LockedAttributesAvailable = True;
				Continue;
			EndIf;
			FoundRows[0].Value = AttributeToChange.Value;
			FoundRows[0].Change = True;
		EndIf;
	EndDo;
	
	For Each TabularSection In Setting.TabularSections Do
		For Each AttributeToChange In TabularSection.Value Do
			TheStructureOfTheSearch = New Structure;
			TheStructureOfTheSearch.Insert("Name", AttributeToChange.Name);
			If Items.Find("TabularSection" + TabularSection.Key) <> Undefined Then
				FoundRows = ThisObject["TabularSection" + TabularSection.Key].FindRows(TheStructureOfTheSearch);
				If FoundRows.Count() > 0 Then
					FoundRows[0].Value = AttributeToChange.Value;
					FoundRows[0].Change = True;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	If LockedAttributesAvailable Then
		ShowMessageBox(, NStr("vi = 'Nhiều mục tin đã bị phong tỏa thay đổi, không thể thay đổi.';
								|ru = 'Некоторые реквизиты заблокированы для изменения, изменения не установлены.';
								|en = 'Some attributes are locked for editing. Changes are not saved.'; fa = 'Some attributes are locked for editing. Changes are not saved.';
								|it = 'Alcuni requisiti sono bloccati per le modifiche, le modifiche non sono impostate.';
								|pl = 'Niektóre szczegóły są blokowane w przypadku zmian, zmiany nie są instalowane.';
								|tr = 'Bazı öznitelikler düzenleme için kilitlenmiştir. Değişiklikler tanımlanmamıştır.'"));
	EndIf;
	
	UpdateCountersOfAttributesToChange();
EndProcedure

&AtServer
Function ChoiceParametersAsString(ChoiceParameters)
	Result = "";
	
	For Each ChoiceParameterDescription In ChoiceParameters Do
		CurrentCPString = "[FilterField];[StringType];[StringValue1]";
		ValueType = TypeOf(ChoiceParameterDescription.Value);
		
		If ValueType = Type("FixedArray") Then
			TypePresentationString = "FixedArray";
			StringValue1 = "";
			
			For Each Item In ChoiceParameterDescription.Value Do
				ValueStringPattern = "[Type]*[Value]";
				ValueStringPattern = StrReplace(ValueStringPattern, "[Type]", Common.TypePresentationString(TypeOf(Item)));
				ValueStringPattern = StrReplace(ValueStringPattern, "[Value]", XMLString(Item));
				StringValue1 = StringValue1 + ?(IsBlankString(StringValue1), "", "#") + ValueStringPattern;
			EndDo;
		Else
			TypePresentationString = Common.TypePresentationString(ValueType);
			StringValue1 = XMLString(ChoiceParameterDescription.Value);
		EndIf;
		
		If Not IsBlankString(StringValue1) Then
			CurrentCPString = StrReplace(CurrentCPString, "[FilterField]", ChoiceParameterDescription.Name);
			CurrentCPString = StrReplace(CurrentCPString, "[StringType]", TypePresentationString);
			CurrentCPString = StrReplace(CurrentCPString, "[StringValue1]", StringValue1);
			
			Result = Result + CurrentCPString + Chars.LF;
		EndIf;
	EndDo;
	
	Result = Left(Result, StrLen(Result)-1);
	Return Result;
EndFunction

&AtServer
Function ChoiceParameterLinksAsString(ChoiceParameterLinks)
	Result = "";
	
	For Each ChoiceParameterLinkDescription In ChoiceParameterLinks Do
		CurrentCPLString = "[ParameterName];[AttributeName]";
		CurrentCPLString = StrReplace(CurrentCPLString, "[ParameterName]", ChoiceParameterLinkDescription.Name);
		CurrentCPLString = StrReplace(CurrentCPLString, "[AttributeName]", ChoiceParameterLinkDescription.DataPath);
		Result = Result + CurrentCPLString + Chars.LF;
	EndDo;
	
	Result = Left(Result, StrLen(Result)-1);
	Return Result;
EndFunction

&AtServer
Function ChoiceParameterLinksPresentation(ChoiceParameterLinks, MetadataObject)
	Result = "";
	
	LinkedAttributes = New Array;
	For Each ChoiceParameterLinkDescription In ChoiceParameterLinks Do
		AttributeName = ChoiceParameterLinkDescription.DataPath;
		TabularSectionPresentation = "";
		AttributesOwner = MetadataObject;
		NameParts = StrSplit(AttributeName, ".", True);
		If NameParts.Count() = 2 Then
			AttributeName = NameParts[1];
			TabularSectionName = NameParts[0];
			AttributesOwner = MetadataObject.TabularSections.Find(TabularSectionName);
			If AttributesOwner <> Undefined Then
				TabularSectionPresentation = AttributesOwner.Presentation();
			EndIf;
		EndIf;
		If AttributesOwner <> Undefined Then
			Attribute = AttributesOwner.Attributes.Find(AttributeName);
			If Attribute = Undefined Then
				StandardAttributesDetails = AttributesOwner.StandardAttributes;// StandardAttributeDescriptions
				For Each StandardAttribute In StandardAttributesDetails Do
					If StandardAttribute.Name = AttributeName Then
						Attribute = StandardAttribute;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Attribute <> Undefined Then
				AttributeRepresentation = Attribute.Presentation();
				If Not IsBlankString(TabularSectionPresentation) Then
					AttributeRepresentation = AttributeRepresentation + " (" + NStr("vi = 'bảng';
																					|ru = 'таблица';
																					|en = 'table'; fa = 'table';
																					|it = 'tabella';
																					|pl = 'tabela';
																					|tr = 'tablo'") + " " 
						+ TabularSectionPresentation + ")";
				EndIf;
				LinkedAttributes.Add(AttributeRepresentation);
			EndIf;
		EndIf;
	EndDo;
	
	If LinkedAttributes.Count() > 0 Then
		LinkPresentationPattern = NStr("vi = 'Phụ thuộc vào các mục tin: %1.';
										|ru = 'Зависит от реквизитов: %1.';
										|en = 'Dependency to attributes: %1.'; fa = 'Dependency to attributes: %1.';
										|it = 'Dipende dai requisiti: %1.';
										|pl = 'Zależy od szczegółów: %1.';
										|tr = 'Şu özniteliklere bağlı: %1.'");
		If LinkedAttributes.Count() = 1 Then
			LinkPresentationPattern = NStr("vi = 'Tùy thuộc vào mục tin %1.';
											|ru = 'Зависит от реквизита %1.';
											|en = 'Depends on attribute %1.'; fa = 'Depends on attribute %1.';
											|it = 'Dipende dal requisito %1.';
											|pl = 'Zależy od szczegółu %1.';
											|tr = '%1 özniteliğine bağlıdır.'");
		EndIf;
		Result = StringFunctionsClientServer.SubstituteParametersToString(
			LinkPresentationPattern, StrConcat(LinkedAttributes, ", "));
	EndIf;
	
	Return Result;
EndFunction

&AtServer
Procedure FillObjectsTypesList()
	Items.PresentationOfObjectsToChange.ChoiceList.Clear();
	DataProcessorObject = FormAttributeToValue("Object");
	DataProcessorObject.FillEditableObjectsCollection(
		Items.PresentationOfObjectsToChange.ChoiceList, Object.ShowInternalAttributes);
EndProcedure

&AtClient
Procedure NoteOnConfiguredChangesURLProcessing(Item, FormattedStringURL, StandardProcessing)
	If FormattedStringURL = "GoToFilterSettings" Then
		StandardProcessing = False;
		GoToFilterSettings();
	EndIf;
EndProcedure

&AtClient
Procedure GoToFilterSettings()
	If Not IsBlankString(KindsOfObjectsToChange) Then
		CallbackDescription = New CallbackDescription("OnCloseSelectedObjectsForm", ThisObject);
		OpenForm("DataProcessor.BatchEditAttributes.Form.SelectedItems", 
			New Structure("SelectedTypes, Settings", KindsOfObjectsToChange, SettingsComposer.Settings), , , , , CallbackDescription);
	EndIf;
EndProcedure

&AtClient
Function ConstructorParameters(Formula)
	Result = New Structure;
	Result.Insert("Formula", Formula);
	Result.Insert("OperandsTitle", NStr("vi = 'Mục tin khả dụng';
										|ru = 'Доступные реквизиты';
										|en = 'Available attributes'; fa = 'ویژگی‌های در دسترس';
										|it = 'Requisiti disponibili';
										|pl = 'Dostępne atrybuty';
										|tr = 'Erişilebilir öznitelikler'"));
	Result.Insert("Operands", Operands());
	Result.Insert("Advanced", False);
	Return Result;
EndFunction

&AtServer
Function Operands()
	OperandsTable = New ValueTable;
	OperandsTable.Columns.Add("Id");
	OperandsTable.Columns.Add("Presentation");
	
	For Each AttributeDetails In ObjectAttributes Do
		Operand = OperandsTable.Add();
		Operand.Id = AttributeDetails.Presentation;
	EndDo;
	
	Return PutToTempStorage(OperandsTable, UUID);
EndFunction

&AtClient
Function ExpressionHasErrors(Val Expression, ErrorText = "")
	
	Expression = Mid(Expression, 2);
	
	For Each AttributeDetails In ObjectAttributes Do
		Expression = StrReplace(Expression, "[" + AttributeDetails.Presentation + "]", """1""");
	EndDo;
	
	Try
		Return Eval(Expression) = Undefined;
	Except
		ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
		Return True;
	EndTry;
	
EndFunction

&AtClient
Procedure OnUnlockAttributes(UnlockedAttributes, AdditionalParameters) Export
	
	If UnlockedAttributes = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(UnlockedAttributes) = Type("Array") And UnlockedAttributes.Count() > 0 Then
		Filter = New Structure("LockedAttribute", True);
		LockedAttributesRows = ObjectAttributes.FindRows(Filter);
		For Each OperationDescriptionString In LockedAttributesRows Do
			If OperationDescriptionString.LockedAttribute
			   And UnlockedAttributes.Find(OperationDescriptionString.Name) <> Undefined Then
				OperationDescriptionString.LockedAttribute = False;
			EndIf;
		EndDo;
		
	ElsIf UnlockedAttributes = True Then
	
		For Each OperationDescriptionString In LockedAttributesRows Do
			OperationDescriptionString.LockedAttribute = False;
		EndDo;
		
	EndIf;
	
EndProcedure

&AtClient
Function ChoiceData(String, ChoiceList)
	
	Result = New ValueList;
	
	If Not ValueIsFilled(String) Then
		Return Result;
	EndIf;
	
	For Each Item In ChoiceList Do
		ItemPresentation = Item.Presentation;
		
		SearchString = ItemPresentation;
		
		FormattedStrings = New Array;
		For Each Substring In StrSplit(String, " ", False) Do
			Position = StrFind(Lower(SearchString), Lower(Substring));
			If Position = 0 Then
				FormattedStrings = Undefined;
				Break;
			EndIf;
			
			SubstringBeforeOccurence = Left(SearchString, Position - 1);
			OccurenceSubstring = Mid(SearchString, Position, StrLen(Substring));
			SearchString = Mid(SearchString, Position + StrLen(Substring));
			
			FormattedStrings.Add(SubstringBeforeOccurence);
			//@skip-check new-font
			//@skip-check new-color
			FormattedStrings.Add(New FormattedString(OccurenceSubstring,
				New Font( , , True), New Color(0,128,0))); // ACC:1345, ACC:1346 Standalone data processor cannot use styles.
		EndDo;
		
		If Not ValueIsFilled(FormattedStrings) Then
			Continue;
		EndIf;
		
		FormattedStrings.Add(SearchString);
		HighlightedString = New FormattedString(FormattedStrings); // ACC:1356 - A compound format string can be used as the string array consists of the passed text.
		
		Result.Add(Item.Value, HighlightedString);
	EndDo;
	
	Return Result;
	
EndFunction

&AtServer
Function ObjectsEnabled()
	
	ObjectsEnabled = New Map;
	For Each FunctionalOption In Metadata.FunctionalOptions Do
		If Not Metadata.Constants.Contains(FunctionalOption.Location) Then
			Continue;
		EndIf;
		Value = GetFunctionalOption(FunctionalOption.Name, New Structure);
		For Each Item In FunctionalOption.Content Do
			If Item.Object = Undefined Then
				Continue;
			EndIf;
			If Value = True Then
				ObjectsEnabled.Insert(Item.Object, True);
			Else
				If ObjectsEnabled[Item.Object] = Undefined Then
					ObjectsEnabled.Insert(Item.Object, False);
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	Return ObjectsEnabled;
	
EndFunction

&AtClient
Procedure EditFormula()
	CurrentData = Items.ObjectAttributes.CurrentData;
	CallbackDescription = New CallbackDescription("ObjectAttributesValueChoiceCompletion", ThisObject, CurrentData);
	OpenForm("DataProcessor.BatchEditAttributes.Form.FormulaEdit",
		ConstructorParameters(CurrentData.Value), , , , , CallbackDescription);
EndProcedure

&AtClient
Function ErrorsInfo()
	
	If ErrorsInfo = Undefined Then
		ErrorsInfo = New Map;
	EndIf;
	
	Return ErrorsInfo;
	
EndFunction

&AtClient
Function InfoOnError(Val Var_Key = Undefined)
	
	InfoOnError = Undefined;
	
	If Var_Key <> Undefined Then
		InfoOnError = ErrorsInfo()[Var_Key];
	EndIf;
	
	If InfoOnError = Undefined Then
		InfoOnError = New Structure;
		InfoOnError.Insert("ErrorReport");
		InfoOnError.Insert("ErrorInfo");
	EndIf;
	
	Return InfoOnError;
	
EndFunction

&AtClient
Procedure SendErrorReport()
	
	For Each Item In ErrorsInfo() Do
		InfoOnError = Item.Value;
		StandardSubsystemsClient.SendErrorReport(InfoOnError.ErrorReport, InfoOnError.ErrorInfo);
	EndDo;
	
	ErrorsInfo = Undefined;
	
EndProcedure

#EndRegion