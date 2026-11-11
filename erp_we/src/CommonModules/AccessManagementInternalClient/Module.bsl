///////////////////////////////////////////////////////////////////////////////////////////////////////
// Copyright (c) 2025, OOO 1C-Soft
// All rights reserved. This software and the related materials 
// are licensed under a Creative Commons Attribution 4.0 International license (CC BY 4.0).
// To view the license terms, follow the link:
// https://creativecommons.org/licenses/by/4.0/legalcode
///////////////////////////////////////////////////////////////////////////////////////////////////////
//

#Region Internal

////////////////////////////////////////////////////////////////////////////////
// Management of AccessKinds and AccessValues tables in edit forms.

#Region FormTableItemsEventHandlersAccessValues

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//
Procedure AccessValuesPick(Form) Export
	
	AccessValueStartChoice(Form, Undefined, Undefined, Null);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//
Procedure AccessValuesOnChange(Form, Item) Export
	
	Items = Form.Items;
	Parameters = AllowedValuesEditFormParameters(Form);
	
	If Item.CurrentData <> Undefined
	   And Item.CurrentData.AccessKind = Undefined Then
		
		Filter = AccessManagementInternalClientServer.FilterInAllowedValuesEditFormTables(
			Form, Form.CurrentAccessKind);
		
		FillPropertyValues(Item.CurrentData, Filter);
		
		Item.CurrentData.RowNumberByKind = Parameters.AccessValues.FindRows(Filter).Count();
	EndIf;
	
	AccessManagementInternalClientServer.FillNumbersOfAccessValuesRowsByKind(
		Form, Items.AccessKinds.CurrentData);
	
	AccessManagementInternalClientServer.FillAllAllowedPresentation(
		Form, Items.AccessKinds.CurrentData);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  NewRow - Boolean
//  Copy - Boolean
//
Procedure AccessValuesOnStartEdit(Form, Item, NewRow, Copy) Export
	
	Items = Form.Items;
	
	If Item.CurrentData.AccessValue = Undefined Then
		If Form.CurrentTypesOfValuesToSelect.Count() > 1
		   And Form.CurrentAccessKind <> Form.AccessKindExternalUsers
		   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
			
			Items.AccessValuesAccessValue.ChoiceButton = True;
		Else
			Items.AccessValuesAccessValue.ChoiceButton = Undefined;
			Items.AccessValues.CurrentData.AccessValue = Form.CurrentTypesOfValuesToSelect[0].Value;
			Form.CurrentTypeOfValuesToSelect = Form.CurrentTypesOfValuesToSelect[0].Value
		EndIf;
	EndIf;
	
	Items.AccessValuesAccessValue.ClearButton
		= Form.CurrentTypeOfValuesToSelect <> Undefined
		And Form.CurrentTypesOfValuesToSelect.Count() > 1;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
//
Procedure AccessValuesChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	Values = ?(TypeOf(ValueSelected) = Type("Array"),
		ValueSelected, CommonClientServer.ValueInArray(ValueSelected));
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	CurrentTypes = New Array;
	For Each ListItem In Form.CurrentTypesOfValuesToSelect Do
		CurrentTypes.Add(TypeOf(ListItem.Value));
	EndDo;
	
	Filter = AccessManagementInternalClientServer.FilterInAllowedValuesEditFormTables(
		Form, Form.CurrentAccessKind);
	
	For Each Value In Values Do
		If CurrentTypes.Find(TypeOf(Value)) = Undefined Then
			Continue;
		EndIf;
		Filter.Insert("AccessValue", Value);
		If Not ValueIsFilled(Parameters.AccessValues.FindRows(Filter)) Then
			NewRow = Parameters.AccessValues.Add();
			FillPropertyValues(NewRow, Filter);
		EndIf;
	EndDo;
	
	AccessManagementInternalClientServer.FillNumbersOfAccessValuesRowsByKind(Form,
		Form.Items.AccessKinds.CurrentData);
	
EndProcedure

// For internal use only.
Procedure AccessValueStartChoice(Form, Item, ChoiceData, StandardProcessing) Export
	
	Context = New Structure("Form, IsPick", Form, StandardProcessing = Null);
	StandardProcessing = False;
	
	If Form.CurrentTypesOfValuesToSelect.Count() = 1 Then
		
		Form.CurrentTypeOfValuesToSelect = Form.CurrentTypesOfValuesToSelect[0].Value;
		
		AccessValueStartChoiceCompletion(Context);
		Return;
		
	ElsIf Form.CurrentTypesOfValuesToSelect.Count() > 0 Then
		
		If Form.CurrentTypesOfValuesToSelect.Count() = 2 Then
		
			If Form.CurrentAccessKind = Form.AccessKindUsers Then
				Form.CurrentTypeOfValuesToSelect = PredefinedValue(
					"Catalog.Users.EmptyRef");
				
				AccessValueStartChoiceCompletion(Context);
				Return;
			EndIf;
			
			If Form.CurrentAccessKind = Form.AccessKindExternalUsers Then
				Form.CurrentTypeOfValuesToSelect = PredefinedValue(
					"Catalog.ExternalUsers.EmptyRef");
				
				AccessValueStartChoiceCompletion(Context);
				Return;
			EndIf;
		EndIf;
		
		Form.CurrentTypesOfValuesToSelect.ShowChooseItem(
			New CallbackDescription("AccessValueStartChoiceContinued", ThisObject, Context),
			NStr("vi = 'Chọn kiểu dữ liệu';
				|ru = 'Выбор типа данных';
				|en = 'Select data type'; fa = 'Select data type';
				|it = 'Scelta del tipo dati';
				|pl = 'Wybierz typ danych';
				|tr = 'Veri türünü seçin'"),
			Form.CurrentTypesOfValuesToSelect[0]);
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessValuesOnEditEnd(Form, Item, NewRow, CancelEdit) Export
	
	If Form.CurrentAccessKind = Undefined Then
		Parameters = AllowedValuesEditFormParameters(Form);
		
		Filter = New Structure("AccessKind", Undefined);
		
		FoundRows = Parameters.AccessValues.FindRows(Filter);
		
		For Each String In FoundRows Do
			Parameters.AccessValues.Delete(String);
		EndDo;
		
		CancelEdit = True;
	EndIf;
	
	If CancelEdit Then
		AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  StandardProcessing - Boolean
//
Procedure AccessValueClearing(Form, Item, StandardProcessing) Export
	
	Items = Form.Items;
	
	StandardProcessing = False;
	Form.CurrentTypeOfValuesToSelect = Undefined;
	Items.AccessValuesAccessValue.ClearButton = False;
	
	If Form.CurrentTypesOfValuesToSelect.Count() > 1
	   And Form.CurrentAccessKind <> Form.AccessKindExternalUsers
	   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
		
		Items.AccessValuesAccessValue.ChoiceButton = True;
		Items.AccessValues.CurrentData.AccessValue = Undefined;
	Else
		Items.AccessValuesAccessValue.ChoiceButton = Undefined;
		Items.AccessValues.CurrentData.AccessValue = Form.CurrentTypesOfValuesToSelect[0].Value;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessValueAutoComplete(Form, Item, Text, ChoiceData, Waiting, StandardProcessing) Export
	
	GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing);
	
EndProcedure

// For internal use only.
Procedure AccessValueTextInputCompletion(Form, Item, Text, ChoiceData, StandardProcessing) Export
	
	GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAccessKinds

// For internal use only.
Procedure AccessKindsOnActivateRow(Form, Item) Export
	
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//
Procedure AccessKindsOnActivateCell(Form, Item) Export
	
	If Form.IsAccessGroupProfile Then
		Return;
	EndIf;
	
	Items = Form.Items;
	
	If Items.AccessKinds.CurrentItem <> Items.AccessKindsAllAllowedPresentation Then
		Items.AccessKinds.CurrentItem = Items.AccessKindsAllAllowedPresentation;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessKindsBeforeAddRow(Form, Item, Cancel, Copy, Parent, Group) Export
	
	If Copy Then
		Cancel = True;
	EndIf;
	
EndProcedure

// For internal use only.
Procedure AccessKindsBeforeDeleteRow(Form, Item, Cancel) Export
	
	Form.CurrentAccessKind = Undefined;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormTable
//  NewRow - Boolean
//  Copy - Boolean
//
Procedure AccessKindsOnStartEdit(Form, Item, NewRow, Copy) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If NewRow Then
		CurrentData.Used = True;
	EndIf;
	
	AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData, False);
	
EndProcedure

// For internal use only.
Procedure AccessKindsOnEditEnd(Form, Item, NewRow, CancelEdit) Export
	
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//
Procedure AccessKindsAccessKindPresentationOnChange(Form, Item) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AccessKindPresentation = "" Then
		CurrentData.AccessKind   = Undefined;
		CurrentData.Used = True;
	EndIf;
	
	AccessManagementInternalClientServer.FillAccessKindsPropertiesInForm(Form);
	AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
// 
Procedure AccessKindsAccessKindPresentationChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	Parameters = AllowedValuesEditFormParameters(Form);
	
	Filter = New Structure("AccessKindPresentation", ValueSelected);
	Rows = Parameters.AccessKinds.FindRows(Filter);
	
	If Rows.Count() > 0
	   And Rows[0].GetID() <> Form.Items.AccessKinds.CurrentRow Then
		
		ShowMessageBox(, StringFunctionsClientServer.SubstituteParametersToString(
			NStr("vi = 'Đã chọn dạng truy cập ""%1"".
			           |Hãy chọn dạng khác.';
			           |ru = 'Вид доступа ""%1"" уже выбран.
			           |Выберите другой.';
			           |en = 'The ""%1"" access kind is already selected.
			           |Please select another one.'; fa = 'The ""%1"" access kind is already selected.
			           |Please select another one.';
			           |it = 'La modalità di accesso ""%1"" è stata selezionata.
			           |Scegliere un altro.';
			           |pl = 'Typ dostępu ""%1"" jest już wybrany.
			           |Wybierz inny.';
			           |tr = 'Erişim türü ""%1"" zaten seçilidir. 
			           |Başka birini seçin.'"),
			ValueSelected));
		
		StandardProcessing = False;
		Return;
	EndIf;
	
	Filter = New Structure("Presentation", ValueSelected);
	CurrentData.AccessKind = Form.AllAccessKinds.FindRows(Filter)[0].Ref;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//
Procedure AccessKindsAllAllowedPresentationOnChange(Form, Item) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If CurrentData.AllAllowedPresentation = "" Then
		CurrentData.AllAllowed = False;
		If Form.IsAccessGroupProfile Then
			CurrentData.Predefined = False;
		EndIf;
	EndIf;
	
	If Form.IsAccessGroupProfile Then
		AccessManagementInternalClientServer.OnChangeCurrentAccessKind(Form);
		AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData, False);
	Else
		Form.Items.AccessKinds.EndEditRow(False);
		AccessManagementInternalClientServer.FillAllAllowedPresentation(Form, CurrentData);
	EndIf;
	
EndProcedure

// For internal use only.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//  Item - FormField
//  ValueSelected - Arbitrary
//  StandardProcessing - Boolean
//
Procedure AccessKindsAllAllowedPresentationChoiceProcessing(Form, Item, ValueSelected, StandardProcessing) Export
	
	CurrentData = Form.Items.AccessKinds.CurrentData;
	If CurrentData = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	Filter = New Structure("Presentation", ValueSelected);
	Name = Form.PresentationsAllAllowed.FindRows(Filter)[0].Name;
	
	If Form.IsAccessGroupProfile Then
		CurrentData.Predefined = (Name = "AllAllowed" Or Name = "AllDenied");
	EndIf;
	
	CurrentData.AllAllowed = (Name = "AllAllowedByDefault" Or Name = "AllAllowed");
	
EndProcedure

#Region ReportFormCommonFormEventHandlers

// Handles mouse double-click, "Enter" key, and hyperlink activation in report spreadsheets.
// See "Form field extension for a spreadsheet document field.Choice" in Syntax Assistant.
//
// Parameters:
//   ReportForm          - ClientApplicationForm - a report form.
//   Item              - FormField        - Spreadsheet document.
//   Area              - SpreadsheetDocumentRange - a selected value.
//   StandardProcessing - Boolean - indicates whether standard event processing is executed.
//
Procedure SpreadsheetDocumentSelectionHandler(ReportForm, Item, Area, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRights"
	   And TypeOf(Area) = Type("SpreadsheetDocumentRange")
	   And Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
	   And TypeOf(Area.Details) = Type("String")
	   And StrStartsWith(Area.Details, "OpenListForm: ") Then
			
		StandardProcessing = False;
		OpenForm(Mid(Area.Details, StrLen("OpenListForm: ") + 1) + ".ListForm");
		Return;
	EndIf;
	
	If ReportForm.ReportSettings.FullName <> "Report.AccessRightsAnalysis" Then
		Return;
	EndIf;
	
	If TypeOf(Area) = Type("SpreadsheetDocumentRange")
		And Area.AreaType = SpreadsheetDocumentCellAreaType.Rectangle
		And Area.Details <> Undefined Then
		
		ReportForm.DetailProcessing = True;
	EndIf;
	
EndProcedure

// See ReportsClientOverridable.DetailProcessing
Procedure OnProcessDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	OnProcessReportDrilldown(ReportForm, Item, Details, StandardProcessing, False);
	
EndProcedure

// See ReportsClientOverridable.AdditionalDetailProcessing.
Procedure OnProcessAdditionalDetails(ReportForm, Item, Details, StandardProcessing) Export
	
	OnProcessReportDrilldown(ReportForm, Item, Details, StandardProcessing, True);
	
EndProcedure

// See ReportsClientOverridable.AtStartValueSelection
Procedure AtStartValueSelection(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing) Export
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRightsAnalysis" Then
		AttheStartofSelectingReportValuesAnalysisAccessPermissions(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	
	ElsIf ReportForm.ReportSettings.FullName = "Report.RolesRights" Then
		AttheStartofSelectingReportValuesRoleRights(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	EndIf;
	
EndProcedure

Procedure ShowUserRightsOnTables(User) Export
	
	Filter = New Structure("User", User);
	VariantKey = "UserRightsToTables";
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "User");
	ShortenUseDestinationKey(PurposeUseKey);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	OpenForm("Report.AccessRightsAnalysis.Form", ReportParameters, ThisObject);
	
EndProcedure

Procedure ShowUserRolesRights(Roles, User) Export
	
	Filter = New Structure("InitialSelection", New Structure("Role", Roles));
	VariantKey = "RolesRights";
	
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey,
		New Structure("User", User), "User");
	ShortenUseDestinationKey(PurposeUseKey);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	OpenForm("Report.RolesRights.Form", ReportParameters, ThisObject);
	
EndProcedure

Procedure ShowReportUsersRights(Report, TablesToUse) Export
	
	VariantKey = "UsersRightsToReportTables";
	
	Filter = New Structure;
	Filter.Insert("Report", Report);
	Filter.Insert("CanSignIn", True);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", VariantKey);
	ReportParameters.Insert("TablesToUse", TablesToUse);
	
	OpenForm("Report.AccessRightsAnalysis.Form", ReportParameters, ThisObject);
	
EndProcedure

// Opens the "AccessUpdateOnRecordsLevel" form.
//
// Parameters:
//  DisableProgressAutoUpdate - Boolean
//  ShowProgressPerLists - Boolean
//
Procedure OpenAccessUpdateOnRecordsLevelForm(DisableProgressAutoUpdate = False,
			ShowProgressPerLists = False) Export
	
	FormParameters = New Structure;
	FormParameters.Insert("DisableProgressAutoUpdate",   DisableProgressAutoUpdate);
	FormParameters.Insert("ShowProgressPerLists", ShowProgressPerLists);
	
	OpenForm("InformationRegister.DataAccessKeysUpdate.Form.AccessUpdateOnRecordsLevel",
		FormParameters);
	
EndProcedure

#EndRegion

#EndRegion

#EndRegion

#Region Private

// Continue running the AccessValueStartChoice event handler.
Procedure AccessValueStartChoiceContinued(SelectedElement, Context) Export
	
	If SelectedElement <> Undefined Then
		Context.Form.CurrentTypeOfValuesToSelect = SelectedElement.Value;
		AccessValueStartChoiceCompletion(Context);
	EndIf;
	
EndProcedure

// Completes the AccessValueStartChoice event handler.
// 
// Parameters:
//  Form - See AccessManagementInternalClientServer.AllowedValuesEditFormParameters
//
Procedure AccessValueStartChoiceCompletion(Context)
	
	Form    = Context.Form;
	Items = Form.Items;
	CurrentData = Items.AccessValues.CurrentData;
	
	If Context.IsPick Then
		Item = Items.AccessValues;
		CurrentRow = ?(CurrentData = Undefined, Undefined, CurrentData.AccessValue);
	Else
		Item = Items.AccessValuesAccessValue;
		
		If Not ValueIsFilled(CurrentData.AccessValue)
		   And CurrentData.AccessValue <> Form.CurrentTypeOfValuesToSelect Then
			
			CurrentData.AccessValue = Form.CurrentTypeOfValuesToSelect;
		EndIf;
		CurrentRow = CurrentData.AccessValue;
		
		Items.AccessValuesAccessValue.ChoiceButton = Undefined;
		Items.AccessValuesAccessValue.ClearButton
			= Form.CurrentTypeOfValuesToSelect <> Undefined
			And Form.CurrentTypesOfValuesToSelect.Count() > 1;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ChoiceMode", True);
	FormParameters.Insert("CurrentRow", CurrentRow);
	FormParameters.Insert("IsAccessValueSelection");
	If Context.IsPick Then
		FormParameters.Insert("CloseOnChoice", False);
		FormParameters.Insert("MultipleChoice", True);
	EndIf;
	
	If Form.CurrentAccessKind = Form.AccessKindUsers Then
		FormParameters.Insert("UsersGroupsSelection", True);
		OpenForm("Catalog.Users.ChoiceForm", FormParameters, Item);
		Return;
		
	ElsIf Form.CurrentAccessKind = Form.AccessKindExternalUsers Then
		FormParameters.Insert("SelectExternalUsersGroups", True);
		OpenForm("Catalog.ExternalUsers.ChoiceForm", FormParameters, Item);
		Return;
	EndIf;
	
	Filter = New Structure("ValuesType", Form.CurrentTypeOfValuesToSelect);
	FoundRows = Form.AllTypesOfValuesToSelect.FindRows(Filter);
	
	If FoundRows.Count() = 0 Then
		Return;
	EndIf;
	
	If FoundRows[0].HierarchyOfItems Then
		FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.FoldersAndItems);
	EndIf;
	
	OpenForm(FoundRows[0].TableName + ".ChoiceForm", FormParameters, Item);
	
EndProcedure

// Management of AccessKinds and AccessValues tables in edit forms.

Function AllowedValuesEditFormParameters(Form, CurrentObject = Undefined)
	
	Return AccessManagementInternalClientServer.AllowedValuesEditFormParameters(
		Form, CurrentObject);
	
EndFunction

Procedure GenerateAccessValuesChoiceData(Form, Text, ChoiceData, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
		
	If Form.CurrentAccessKind <> Form.AccessKindExternalUsers
	   And Form.CurrentAccessKind <> Form.AccessKindUsers Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	ChoiceData = AccessManagementInternalServerCall.GenerateUserSelectionData(Text,
		False,
		Form.CurrentAccessKind = Form.AccessKindExternalUsers,
		Form.CurrentAccessKind <> Form.AccessKindUsers);
	
EndProcedure

// Process report details.

// Intended for procedures "OnProcessDetails", "OnProcessAdditionalDetails".
Procedure OnProcessReportDrilldown(ReportForm, Item, Details,
			StandardProcessing, IsAdditionalDrilldown)
	
	If ReportForm.ReportSettings.FullName = "Report.AccessRightsAnalysis" Then
		Actions = AccessRightsAnalysisReportDrilldownActions(ReportForm, Item, Details);
		
	ElsIf ReportForm.ReportSettings.FullName = "Report.RolesRights" Then
		Actions = RolesRightsReportDrilldownActions(ReportForm, Item, Details);
	Else
		Return;
	EndIf;
	
	StandardProcessing = False;
	If Not ValueIsFilled(Actions) Then
		Return;
	EndIf;
	
	If IsAdditionalDrilldown
	 Or StrFind(Actions[0].Value.URL, "/command/") > 0 Then
		
		Notification = New CallbackDescription("ProcessDrilldownAction", ThisObject);
		ReportForm.ShowChooseFromMenu(Notification, Actions, Item);
	Else
		ProcessDrilldownAction(Actions[0], Undefined);
	EndIf;
	
EndProcedure

// Intended for procedure "OnProcessReportDrilldown".
Procedure ProcessDrilldownAction(Action, Context) Export
	
	If Action = Undefined Then
		Return;
	EndIf;
	
	Parameters = Action.Value;
	
	If ValueIsFilled(Parameters.URL) Then
		FileSystemClient.OpenURL(Parameters.URL);
		
	ElsIf Parameters.Value <> Undefined Then
		ShowValue(, Parameters.Value);
		
	ElsIf Parameters.User <> Undefined Then
		OpenUserRights(Parameters.User);
	Else
		OpenForm(Parameters.FullFormName, Parameters.FormParameters, Parameters.FormOwner);
	EndIf;
	
EndProcedure

// Intended for procedure "OnProcessReportDrilldown".
Function AccessRightsAnalysisReportDrilldownActions(ReportForm, Item, Details)
	
	Actions = New ValueList;
	CurVersion = ReportForm.Report.SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	If CurVersion = "UsersRightsToObject" Then
		Return Actions;
	EndIf;
	
	DetailsParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
		ReportForm.ReportDetailsData, Details);
	
	If DetailsParameters.DetailsFieldName1 = "RightsValue" Then
		Return Actions;
	ElsIf DetailsParameters.DetailsFieldName1 = "OwnerOrUserSettings"
	        And DetailsParameters.FieldList.Get("ThisSettingsOwner") = True Then
		SettingsOwner = DetailsParameters.FieldList.Get("OwnerOrUserSettings");
		If Not ValueIsFilled(SettingsOwner) Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.FullFormName = "CommonForm.ObjectsRightsSettings";
		Parameters.FormParameters = New Structure("ObjectReference", SettingsOwner);
		Actions.Insert(0, Parameters, NStr("vi = 'Mở tùy chỉnh quyền';
											|ru = 'Открыть настройки прав';
											|en = 'Access right settings'; fa = 'Access right settings';
											|it = 'Access right settings';
											|pl = 'Access right settings';
											|tr = 'Erişim ayarlarını aç'"));
		Return Actions;
	ElsIf DetailsParameters.DetailsFieldName1 = "AccessValue" Then
		AccessGroup = DetailsParameters.FieldList.Get("AccessGroup");
		If Not ValueIsFilled(AccessGroup)
		 Or TypeOf(AccessGroup) <> Type("CatalogRef.AccessGroups") Then
			Return Actions;
		EndIf;
		AccessKind = DetailsParameters.FieldList.Get("AccessKind");
		AccessValue = DetailsParameters.FieldList.Get("AccessValue");
		If AccessKind = Undefined Or AccessValue = Undefined Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.FullFormName = "Catalog.AccessGroups.ObjectForm";
		Parameters.FormParameters.Insert("Key", AccessGroup);
		Parameters.FormParameters.Insert("GotoViewAccess", AccessKind);
		Parameters.FormParameters.Insert("JumpToAccessValue", AccessValue);
		Actions.Insert(0, Parameters, NStr("vi = 'Chuyển đến giá trị trong nhóm truy cập';
											|ru = 'Перейти к значению в группе доступа';
											|en = 'View value in access group'; fa = 'View value in access group';
											|it = 'View value in access group';
											|pl = 'View value in access group';
											|tr = 'Erişim grubundaki değere git'"));
		Return Actions;
	EndIf;
	
	Table = DetailsParameters.FieldList.Get("MetadataObjectFullName");
	If ValueIsFilled(Table)
	   And Actions <> Undefined
	   And DetailsParameters.CanUseRolesRightsReport Then
		
		Filter = New Structure("MetadataObject", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"RightsOfRolesAndProfilesToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("vi = 'Quyền của vai trò và hồ sơ đối với báo cáo';
					|ru = 'Права ролей и профилей на отчет';
					|en = 'Role and profile rights that apply to report'; fa = 'Role and profile rights that apply to report';
					|it = 'Role and profile rights that apply to report';
					|pl = 'Role and profile rights that apply to report';
					|tr = 'Rapordaki rol ve profil izinleri'"),
				NStr("vi = 'Quyền của vai trò và hồ sơ đối với bảng';
					|ru = 'Права ролей и профилей на таблицу';
					|en = 'Role and profile rights that apply to table'; fa = 'Role and profile rights that apply to table';
					|it = 'Role and profile rights that apply to table';
					|pl = 'Role and profile rights that apply to table';
					|tr = 'Tablodaki rol ve profil izinleri'")));
		Filter = New Structure("MetadataObject, Profile", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("vi = 'Quyền chi tiết của hồ sơ đến báo cáo';
					|ru = 'Подробные права профилей на отчет';
					|en = 'Detailed profile rights that apply to report'; fa = 'Detailed profile rights that apply to report';
					|it = 'Detailed profile rights that apply to report';
					|pl = 'Detailed profile rights that apply to report';
					|tr = 'Profillerin rapora ilişkin detaylı izinleri'"),
				NStr("vi = 'Quyền chi tiết của hồ sơ đến bảng';
					|ru = 'Подробные права профилей на таблицу';
					|en = 'Detailed profile rights that apply to table'; fa = 'Detailed profile rights that apply to table';
					|it = 'Detailed profile rights that apply to table';
					|pl = 'Detailed profile rights that apply to table';
					|tr = 'Tablodaki profile ilişkin detaylı izinler'")));
		Filter = New Structure("MetadataObject", Table);
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions,
			?(DetailsParameters.DetailsFieldName1 = "Report",
				NStr("vi = 'Quyền chi tiết của hồ sơ đến báo cáo';
					|ru = 'Подробные права ролей на отчет';
					|en = 'Detailed role rights that apply to report'; fa = 'Detailed role rights that apply to report';
					|it = 'Detailed role rights that apply to report';
					|pl = 'Detailed role rights that apply to report';
					|tr = 'Ayrıntılı rapor rol erişim yetkisi'"),
				NStr("vi = 'Quyền chi tiết của hồ sơ đến bảng';
					|ru = 'Подробные права ролей на таблицу';
					|en = 'Detailed role rights that apply to table'; fa = 'Detailed role rights that apply to table';
					|it = 'Detailed role rights that apply to table';
					|pl = 'Detailed role rights that apply to table';
					|tr = 'Tablodaki detaylı rol izinleri'")));
	EndIf;
	
	URL = DetailsParameters.FieldList.Get("MetadataObjectURL");
	If DetailsParameters.DetailsFieldName1 = "ReportTitleMetadataObject"
	 Or DetailsParameters.DetailsFieldName1 = "FilterTitle" Then
		If Not ValueIsFilled(URL) Then
			Return Actions;
		EndIf;
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		Actions.Insert(0, Parameters, ?(DetailsParameters.DetailsFieldName1 = "FilterTitle",
			NStr("vi = 'Mở';
				|ru = 'Открыть';
				|en = 'Open'; fa = 'باز';
				|it = 'Open';
				|pl = 'Open';
				|tr = 'Aç'"), NStr("vi = 'Hiển thị danh sách';
										|ru = 'Показать список';
										|en = 'Show list'; fa = 'Show list';
										|it = 'Show list';
										|pl = 'Show list';
										|tr = 'Listeleri göster'")));
		Return Actions;
	EndIf;
	
	If ValueIsFilled(URL) And Actions <> Undefined Then
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		Actions.Add(Parameters, ?(DetailsParameters.DetailsFieldName1 = "Report",
			NStr("vi = 'Mở';
				|ru = 'Открыть';
				|en = 'Open'; fa = 'باز';
				|it = 'Aprire';
				|pl = 'Otwórz';
				|tr = 'Aç'"), NStr("vi = 'Hiển thị danh sách';
										|ru = 'Показать список';
										|en = 'Show list'; fa = 'Show list';
										|it = 'Show list';
										|pl = 'Show list';
										|tr = 'Listeleri göster'")));
	EndIf;
	
	If DetailsParameters.DetailsFieldName1 = "User" Then
		User = DetailsParameters.FieldList.Get("User");
		If ValueIsFilled(User) Then
			Parameters = NewActionExecutionParameters();
			Parameters.User = User;
			Actions.Add(Parameters, NStr("vi = 'Chuyển đến tùy chỉnh quyền của người sử dụng';
										|ru = 'Перейти к настройке прав пользователя';
										|en = 'View user right settings'; fa = 'View user right settings';
										|it = 'View user right settings';
										|pl = 'View user right settings';
										|tr = 'Kullanıcı izinleri ayarlarına git'"));
			Parameters = NewActionExecutionParameters();
			Parameters.Value = User;
			Actions.Add(Parameters, NStr("vi = 'Mở';
										|ru = 'Открыть';
										|en = 'Open'; fa = 'باز';
										|it = 'Aprire';
										|pl = 'Otwórz';
										|tr = 'Aç'"));
		EndIf;
	EndIf;
	
	Filter = New Structure;
	For Each FilterElement In ReportForm.Report.SettingsComposer.Settings.Filter.Items Do
		Setting = ReportForm.Report.SettingsComposer.UserSettings.Items.Find(
			FilterElement.UserSettingID);
		If Setting = Undefined Then
			Setting = FilterElement;
		EndIf;
		If Setting.Use Then
			If FilterElement.ComparisonType = DataCompositionComparisonType.Equal
			 Or FilterElement.ComparisonType = DataCompositionComparisonType.InList Then
				
				Filter.Insert(FilterElement.LeftValue, Setting.RightValue);
			EndIf;
		EndIf;
	EndDo;
	
	ParameterName = "User";
	ParameterValue = ParameterValue(ReportForm.Report.SettingsComposer, ParameterName);
	If ParameterValue <> Null Then
		Filter.Insert(ParameterName, ParameterValue);
	EndIf;
	
	If CurVersion = "UsersRightsToReportTables"
	   And DetailsParameters.DetailsFieldName1 <> "User"
	 Or CurVersion = "UserRightsToReportTables" Then
		
		Filter.Delete("Report");
	EndIf;
	
	If DetailsParameters.DetailsFieldName1 = "Right"
	 Or DetailsParameters.DetailsFieldName1 = "ViewRight"
	 Or DetailsParameters.DetailsFieldName1 = "EditRight"
	 Or DetailsParameters.DetailsFieldName1 = "InteractiveAddRight" Then
		
		VariantKey = "UserRightsToTable";
		
		If VariantKey = CurVersion Then
			Return Actions;
		EndIf;
		
		If DetailsParameters.FieldList["User"] <> Undefined Then
			Filter.Insert("User", DetailsParameters.FieldList["User"]);
		Else
			VariantKey = "UsersRightsToTable";
		EndIf;
		
		If DetailsParameters.FieldList["MetadataObject"] <> Undefined Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["MetadataObject"]);
		ElsIf DetailsParameters.FieldList["Report"] <> Undefined Then
			Filter.Insert("Report", DetailsParameters.FieldList["Report"]);
			VariantKey = "UserRightsToReportTables";
		EndIf;
		
		If VariantKey = CurVersion Then
			Return Actions;
		EndIf;
		
		If VariantKey <> "UserRightsToReportTables" Then
			RightsValue = DetailsParameters.FieldList[DetailsParameters.DetailsFieldName1];
			If TypeOf(RightsValue) = Type("Number")  And RightsValue = 0
			 Or TypeOf(RightsValue) = Type("Boolean") And Not RightsValue Then
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "MetadataObject" Then
		
		VariantKey = "UsersRightsToTable";
		Filter.Insert("MetadataObject", DetailsParameters.FieldList["MetadataObject"]);

		If CurVersion = "UserRightsToTables"
			Or CurVersion = "UserRightsToReportTables" Then
			VariantKey = "UserRightsToTable";
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "User" 
		And CurVersion <> "UserRightsToTables"
		And CurVersion <> "UserRightsToTable"
		And CurVersion <> "UserRightsToReportsTables" Then
		
		VariantKey = "UserRightsToTables";
		Filter.Insert("User", DetailsParameters.FieldList["User"]);
		Filter.Delete("CanSignIn");
		
		If CurVersion = "UsersRightsToTable" Then
			VariantKey = "UserRightsToTable";
		EndIf;
		
		If CurVersion = "UsersRightsToReportTables" Then
			VariantKey = "UserRightsToReportTables";
		EndIf;
		
		If CurVersion = "AccessRightsAnalysis"
		   And DetailsParameters.FieldList["OutputGroup"] = 1 Then
			
			VariantKey = "UserRightsToReportsTables";
		EndIf;
		
	ElsIf DetailsParameters.DetailsFieldName1 = "Report" Then
		
		If CurVersion = "UserRightsToReportTables"
		 Or CurVersion = "UsersRightsToReportTables" Then
			Return Actions;
		EndIf;
		
		VariantKey = "UsersRightsToReportTables";
		Filter.Insert("Report", DetailsParameters.FieldList["Report"]);
		
	Else
		DetailsValue = DetailsParameters.FieldList[DetailsParameters.DetailsFieldName1];
		If ValueIsFilled(DetailsValue)
		   And TypeOf(DetailsValue) <> Type("EnumRef.AdditionalAccessValues") Then
			
			If DetailsParameters.DetailsFieldName1 <> "User" Then
				Parameters = NewActionExecutionParameters();
				Parameters.Value = DetailsValue;
				Actions.Insert(0, Parameters, NStr("vi = 'Mở';
													|ru = 'Открыть';
													|en = 'Open'; fa = 'باز';
													|it = 'Open';
													|pl = 'Open';
													|tr = 'Aç'"));
			EndIf;
		EndIf;
		
		Return Actions;
		
	EndIf;
	
	AddOpenAccessRightsAnalysisReportOption(ReportForm, VariantKey, Details, Filter, Actions);
	
	Return Actions;
	
EndFunction

Procedure AddOpenAccessRightsAnalysisReportOption(ReportForm, VariantKey, Details, Filter,
			Actions, PresentationAction = Undefined)
	
	If Filter.Property("MetadataObject")
	   And Not ValueIsFilled(Filter.MetadataObject)
	   And (    VariantKey = "UsersRightsToTable"
	      Or VariantKey = "UserRightsToTable" ) Then
		
		Return;
	EndIf;
	
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "Report");
	RefineUseDestinationKey(PurposeUseKey, Filter, "User");
	RefineUseDestinationKey(PurposeUseKey, Filter, "MetadataObject");
	ShortenUseDestinationKey(PurposeUseKey);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Details", Details);
	ReportParameters.Insert("Filter", Filter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	Parameters = NewActionExecutionParameters();
	Parameters.FullFormName = "Report.AccessRightsAnalysis.Form";
	Parameters.FormParameters = ReportParameters;
	Parameters.FormOwner  = ReportForm;
	
	If PresentationAction = Undefined Then
		Actions.Insert(0, Parameters,
			AccessRightsAnalysisReportOptionPresentation(VariantKey));
	Else
		Actions.Add(Parameters, ?(ValueIsFilled(PresentationAction), PresentationAction,
			AccessRightsAnalysisReportOptionPresentation(VariantKey)));
	EndIf;
	
EndProcedure

// Intended for procedure "OnProcessReportDrilldown".
Function RolesRightsReportDrilldownActions(ReportForm, Item, Details)
	
	Actions = New ValueList;
	DetailsParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
		ReportForm.ReportDetailsData, Details);
	
	If DetailsParameters.DetailsFieldName1 = "Profile" Then
		Profile = DetailsParameters.FieldList["Profile"];
		If TypeOf(Profile) = Type("CatalogRef.AccessGroupProfiles")
		   And ValueIsFilled(Profile) Then
			
			Parameters = NewActionExecutionParameters();
			Parameters.Value = Profile;
			Actions.Insert(0, Parameters, NStr("vi = 'Mở';
												|ru = 'Открыть';
												|en = 'Open'; fa = 'باز';
												|it = 'Aprire';
												|pl = 'Otwórz';
												|tr = 'Aç'"));
		EndIf;
	EndIf;
	
	CurVersion = ReportForm.Report.SettingsComposer.Settings.AdditionalProperties.PredefinedOptionKey;
	
	URL = DetailsParameters.FieldList.Get("MetadataObjectURL");
	If ValueIsFilled(URL) Then
		Parameters = NewActionExecutionParameters();
		Parameters.URL = URL;
		If StrFind(URL, "/command/") > 0 Then
			Actions.Add(Parameters, NStr("vi = 'Thực hiện lệnh';
										|ru = 'Выполнить команду';
										|en = 'Run command'; fa = 'Run command';
										|it = 'Run command';
										|pl = 'Run command';
										|tr = 'Komut uygula'"));
		ElsIf StrStartsWith(URL, "e1cib/list/") Then
			Actions.Add(Parameters, NStr("vi = 'Hiển thị danh sách';
										|ru = 'Показать список';
										|en = 'Show list'; fa = 'Show list';
										|it = 'Show list';
										|pl = 'Show list';
										|tr = 'Listeleri göster'"));
		ElsIf StrStartsWith(URL, "e1cib/app/") Then
			Actions.Add(Parameters, NStr("vi = 'Mở';
										|ru = 'Открыть';
										|en = 'Open'; fa = 'باز';
										|it = 'Open';
										|pl = 'Open';
										|tr = 'Aç'"));
		EndIf;
	EndIf;
	
	If CurVersion = "DetailedRolesRightsToMetadataObject" Then
		Return Actions;
	EndIf;
	
	Filter = New Structure;
	SetParameterValue(Filter, "NameFormat", ReportForm);
	
	If DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
		If ValueIsFilled(DetailsParameters.FieldList["FullObjectName"]) Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["FullObjectName"]);
		Else
			Properties = New Structure("ReportSpreadsheetDocument");
			FillPropertyValues(Properties, ReportForm);
			If TypeOf(Properties.ReportSpreadsheetDocument) <> Type("SpreadsheetDocument") Then
				Return Actions;
			EndIf;
			ObjectScope = Properties.ReportSpreadsheetDocument.Area(Item.CurrentArea.Top, 2);
			If TypeOf(ObjectScope.Details) <> Type("DataCompositionDetailsID") Then
				Return Actions;
			EndIf;
			ObjectDecryptionParameters = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
				ReportForm.ReportDetailsData, ObjectScope.Details);
			If ValueIsFilled(ObjectDecryptionParameters.FieldList["FullObjectName"]) Then
				Filter.Insert("MetadataObject", ObjectDecryptionParameters.FieldList["FullObjectName"]);
			Else
				Return Actions;
			EndIf;
		EndIf;
	EndIf;
	
	If CurVersion = "RolesRights"
	   And DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		If ValueIsFilled(DetailsParameters.FieldList["NameOfRole"]) Then
			Filter.Insert("Role", DetailsParameters.FieldList["NameOfRole"]);
		ElsIf TypeOf(ObjectDecryptionParameters) = Type("Structure") Then
			NumberLineItem = ObjectDecryptionParameters.FieldList["NumberLineItem"];
			If Not ValueIsFilled(NumberLineItem) Then
				Return Actions;
			EndIf;
			ScopeRoles = Properties.ReportSpreadsheetDocument.Area(Item.CurrentArea.Top - NumberLineItem,
				Item.CurrentArea.Left);
			If TypeOf(ScopeRoles.Details) <> Type("DataCompositionDetailsID") Then
				Return Actions;
			EndIf;
			ParametersDecryptionRoles = AccessManagementInternalServerCall.AccessRightsAnalysisReportDetailsParameters(
				ReportForm.ReportDetailsData, ScopeRoles.Details);
			If ValueIsFilled(ParametersDecryptionRoles.FieldList["NameOfRole"]) Then
				Filter.Insert("Role", ParametersDecryptionRoles.FieldList["NameOfRole"]);
			Else
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf CurVersion = "RolesRights"
	        And DetailsParameters.DetailsFieldName1 = "NameOfRole" Then
		
		VariantKey = "RightsOfRoleAndProfilesToMetadataObjects";
		
		SetParameterValue(Filter, "MetadataObject", ReportForm);
		SetParameterValue(Filter, "RightsOnDetails", ReportForm, True);
		SetParameterValue(Filter, "ShowPermissionsofNonInterfaceSubsystems", ReportForm, True);
		SetParameterValue(Filter, "DontWarnAboutLargeReportSize", ReportForm, True);
		
		AddOpenRolesRightsReportOption(ReportForm,
			VariantKey, Details, Filter, Actions);
		
		NameOfRole = DetailsParameters.FieldList["NameOfRole"];
		If Not ValueIsFilled(NameOfRole) Then
			Return Actions;
		EndIf;
		Filter.Insert("Role", NameOfRole);
		
	ElsIf CurVersion = "RolesRights"
	        And DetailsParameters.DetailsFieldName1 = "Level" Then
		
		VariantKey = "RightsOfRolesAndProfilesToMetadataObject";
		
		FullObjectName = DetailsParameters.FieldList["FullObjectName"];
		If Not ValueIsFilled(FullObjectName) Then
			Return Actions;
		EndIf;
		Filter.Insert("MetadataObject", FullObjectName);
		FilterWithoutRole = New Structure(New FixedStructure(Filter));
		SetParameterValue(Filter, "Role", ReportForm);
		
		FilterWithoutRole.Insert("Profile");
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, FilterWithoutRole, Actions);
		
		AddOpenRolesRightsReportOption(ReportForm,
			"DetailedRolesRightsToMetadataObject", Details, Filter, Actions);
		
	ElsIf CurVersion = "RightsOfRolesAndProfilesToMetadataObject"
	        And (    DetailsParameters.DetailsFieldName1 = "Profile"
	           Or DetailsParameters.DetailsFieldName1 = "NameOfRole3") Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		Filter.Insert("MetadataObject", InitialFilterValue(ReportForm, "MetadataObject"));
		If Not ValueIsFilled(Filter.MetadataObject) Then
			Return Actions;
		EndIf;
		If DetailsParameters.DetailsFieldName1 = "NameOfRole3" Then
			Filter.Insert("Role", DetailsParameters.FieldList["NameOfRole3"]);
		Else
			Filter.Insert("Profile", DetailsParameters.FieldList["Profile3"]);
			If Not ValueIsFilled(Filter.Profile) Then
				Return Actions;
			EndIf;
		EndIf;
		
	ElsIf CurVersion = "RightsOfRoleAndProfilesToMetadataObjects" Then
		
		VariantKey = "DetailedRolesRightsToMetadataObject";
		
		If DetailsParameters.DetailsFieldName1 = "Level" Then
			Filter.Insert("MetadataObject", DetailsParameters.FieldList["FullObjectName"]);
		EndIf;
		If Not Filter.Property("MetadataObject")
		 Or Not ValueIsFilled(Filter.MetadataObject) Then
			Return Actions;
		EndIf;
		If DetailsParameters.DetailsFieldName1 = "AccessLevel" Then
			Filter.Insert("Profile", DetailsParameters.FieldList["Profile4"]);
			If Not ValueIsFilled(Filter.Profile) Then
				Return Actions;
			EndIf;
		Else
			InitialRole = InitialFilterValue(ReportForm, "Role");
			If ValueIsFilled(InitialRole) Then
				Filter.Insert("Role", InitialRole);
			Else
				SetParameterValue(Filter, "Role", ReportForm);
			EndIf;
		EndIf;
	Else
		Return Actions;
	EndIf;
	
	AddOpenRolesRightsReportOption(ReportForm, VariantKey, Details, Filter, Actions);
	
	Return Actions;
	
EndFunction

Procedure AddOpenRolesRightsReportOption(ReportForm, VariantKey, Details, Filter,
			Actions, PresentationAction = Undefined)
	
	FilterComposition = New Structure("Role, Profile", False, False);
	PurposeUseKey = VariantKey;
	RefineUseDestinationKey(PurposeUseKey, Filter, "Role",    FilterComposition.Role);
	RefineUseDestinationKey(PurposeUseKey, Filter, "Profile", FilterComposition.Profile);
	RefineUseDestinationKey(PurposeUseKey, Filter, "MetadataObject");
	ShortenUseDestinationKey(PurposeUseKey);
	If FilterComposition.Profile And Filter.Profile = Undefined Then
		FilterComposition.Profile = Undefined;
	EndIf;
	
	InitialSelection = New Structure(New FixedStructure(Filter));
	FixedFilter = New Structure;
	If InitialSelection.Property("MetadataObject")
	   And (    VariantKey = "DetailedRolesRightsToMetadataObject"
	      Or VariantKey = "RightsOfRolesAndProfilesToMetadataObject") Then
		
		FixedFilter.Insert("MetadataObject", InitialSelection.MetadataObject);
		InitialSelection.Delete("MetadataObject");
	EndIf;
	FixedFilter.Insert("InitialSelection", InitialSelection);
	
	ReportParameters = New Structure;
	ReportParameters.Insert("GenerateOnOpen", True);
	ReportParameters.Insert("Details", Details);
	ReportParameters.Insert("Filter", FixedFilter);
	ReportParameters.Insert("VariantKey", VariantKey);
	ReportParameters.Insert("PurposeUseKey", PurposeUseKey);
	
	Parameters = NewActionExecutionParameters();
	Parameters.FullFormName = "Report.RolesRights.Form";
	Parameters.FormParameters = ReportParameters;
	Parameters.FormOwner  = ReportForm;
	
	If PresentationAction = Undefined Then
		Actions.Insert(0, Parameters,
			RolesRightsReportOptionPresentation(VariantKey, FilterComposition));
	Else
		Actions.Add(Parameters, ?(ValueIsFilled(PresentationAction), PresentationAction,
			RolesRightsReportOptionPresentation(VariantKey, FilterComposition)));
	EndIf;
	
EndProcedure

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Function ParameterValue(SettingsComposer, ParameterName, UsedAlways = False)
	
	Parameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	Setting = SettingsComposer.UserSettings.Items.Find(Parameter.UserSettingID);
	
	If Setting <> Undefined
	   And (UsedAlways Or Setting.Use) Then
		
		Return Setting.Value;
	EndIf;
	
	If Parameter <> Undefined
	   And (UsedAlways Or Parameter.Use) Then
		
		Return Parameter.Value;
	EndIf;
	
	Return Null;
	
EndFunction

Function InitialFilterValue(ReportForm, ParameterName)
	
	If ReportForm.ParametersForm.Filter.Property(ParameterName) Then
		Filter = ReportForm.ParametersForm.Filter;
		
	ElsIf Not ReportForm.ParametersForm.Filter.Property("InitialSelection") Then
		Return Undefined;
	Else
		Filter = ReportForm.ParametersForm.Filter.InitialSelection;
		
		If TypeOf(Filter) <> Type("Structure")
		 Or Not Filter.Property(ParameterName) Then
			Return Undefined;
		EndIf;
	EndIf;
	
	Return Filter[ParameterName];
	
EndFunction

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Procedure RefineUseDestinationKey(Var_Key, Filter, PropertyName, ThereIsProperty = False)
	
	If Not Filter.Property(PropertyName) Then
		Return;
	EndIf;
	
	ThereIsProperty = True;
	Value = Filter[PropertyName];
	If Not ValueIsFilled(Value) Then
		Return;
	EndIf;
	
	RefType = New TypeDescription(
		"CatalogRef.MetadataObjectIDs,
		|CatalogRef.ExtensionObjectIDs,
		|CatalogRef.Users,
		|CatalogRef.UserGroups,
		|CatalogRef.ExternalUsers,
		|CatalogRef.ExternalUsersGroups");
	
	If RefType.ContainsType(TypeOf(Value)) Then
		Var_Key = Var_Key + "/" + String(Value.UUID());
	ElsIf TypeOf(Value) = Type("String") Then
		Var_Key = Var_Key + "/" + Value;
	EndIf;
	
EndProcedure

// Intended for procedures "OnProcessAccessRightsAnalysisReportDrillDown"
// and "OnProcessRolesRightsReportDrillDown".
//
Procedure ShortenUseDestinationKey(PurposeUseKey)
	
	If StrLen(PurposeUseKey) <= 128 Then
		Return;
	EndIf;
	
	PurposeUseKey =
		AccessManagementInternalServerCall.ShortcutUseDestinationKey(
			PurposeUseKey);
	
EndProcedure

// Intended for procedure "OnProcessRolesRightsReportDrillDown".
Procedure SetParameterValue(Filter, ParameterName, ReportForm, UsedAlways = False)
	
	ParameterValue = ParameterValue(ReportForm.Report.SettingsComposer, ParameterName, UsedAlways);
	If ParameterValue <> Null Then
		Filter.Insert(ParameterName, ParameterValue);
	EndIf;
	
EndProcedure

Function NewActionExecutionParameters()
	
	Result = New Structure;
	Result.Insert("URL", "");
	Result.Insert("Value");
	Result.Insert("User");
	Result.Insert("FullFormName", "");
	Result.Insert("FormParameters", New Structure);
	Result.Insert("FormOwner");
	
	Return Result;
	
EndFunction

Procedure OpenUserRights(User)
	
	ClientRunParameters = StandardSubsystemsClient.ClientRunParameters();
	If ClientRunParameters.SimplifiedAccessRightsSetupInterface Then
		FormName = "CommonForm.AccessRightsSimplified";
	Else
		FormName = "CommonForm.AccessRights";
	EndIf;
	
	Form = OpenForm("Catalog.Users.ObjectForm", New Structure("Key", User));
	OpenForm(FormName, New Structure("User", User), Form, , Form.Window);
	
EndProcedure

Function AccessRightsAnalysisReportOptionPresentation(VariantKey)
	
	If VariantKey = "AccessRightsAnalysis" Then
		Return NStr("vi = 'Phân tích quyền truy cập';
					|ru = 'Анализ прав доступа';
					|en = 'Access rights analysis'; fa = 'تحلیل حقوق دسترسی';
					|it = 'Analisi dei diritti di accesso';
					|pl = 'Analiza praw dostępu';
					|tr = 'Erişim hakları analizi'");
		
	ElsIf VariantKey = "UsersRightsToTables" Then
		Return NStr("vi = 'Quyền của người dùng đối với bảng';
					|ru = 'Права пользователей на таблицы';
					|en = 'Users rights to tables'; fa = 'حقوق کاربران بر جدول‌ها';
					|it = 'Diritti degli utenti per la tabella';
					|pl = 'Prawa użytkowników do tabel';
					|tr = 'Tablolar için kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UserRightsToTables" Then
		Return NStr("vi = 'Quyền của người dùng đối với bảng';
					|ru = 'Права пользователя на таблицы';
					|en = 'User rights to tables'; fa = 'حقوق کاربر بر جدول‌ها';
					|it = 'Diritti degli utenti per le tabelle';
					|pl = 'Prawa użytkownika do tabel';
					|tr = 'Tablolarda kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UsersRightsToTable" Then
		Return NStr("vi = 'Quyền của người dùng đối với bảng';
					|ru = 'Права пользователей на таблицу';
					|en = 'Users rights to a table'; fa = 'حقوق کاربران بر یک جدول';
					|it = 'Diritti degli utenti per la tabella';
					|pl = 'Prawa użytkowników do tabeli';
					|tr = 'Tablo için kullanıcıların yetkileri'");
		
	ElsIf VariantKey = "UserRightsToTable" Then
		Return NStr("vi = 'Quyền của người dùng đối với bảng';
					|ru = 'Права пользователя на таблицу';
					|en = 'User rights to table'; fa = 'حقوق کاربر بر جدول';
					|it = 'Diritti degli utenti per la tabella';
					|pl = 'Prawa użytkownika do tabeli';
					|tr = 'Tablo için kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UsersRightsToReportTables" Then
		Return NStr("vi = 'Quyền của người dùng đối với các bảng của báo cáo';
					|ru = 'Права пользователей на таблицы отчета';
					|en = 'Users rights to report tables'; fa = 'حقوق کاربران بر جدول‌های گزارش';
					|it = 'Diritti degli utenti per le tabelle di report';
					|pl = 'Prawa użytkowników do tabel raportów';
					|tr = 'Rapor tabloları için kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UserRightsToReportTables" Then
		Return NStr("vi = 'Quyền của người dùng đối với các bảng của báo cáo';
					|ru = 'Права пользователя на таблицы отчета';
					|en = 'User rights to report tables'; fa = 'حقوق کاربر بر جدول‌های گزارش';
					|it = 'Diritti dell''utente per le tabelle di report';
					|pl = 'Prawa użytkownika do tabel raportu';
					|tr = 'Rapor tabloları için kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UserRightsToReportsTables" Then
		Return NStr("vi = 'Quyền của người dùng đối với các bảng của báo cáo';
					|ru = 'Права пользователя на таблицы отчетов';
					|en = 'User rights to reports tables'; fa = 'حقوق کاربر بر جدول‌های گزارش‌ها';
					|it = 'Diritti dell''utente per le tabelle dei report';
					|pl = 'Prawa użytkownika do tabel raportów';
					|tr = 'Rapor tabloları için kullanıcı yetkileri'");
		
	ElsIf VariantKey = "UsersRightsToObject" Then
		Return NStr("vi = 'Quyền của người dùng đối với đối tượng';
					|ru = 'Права пользователей на объект';
					|en = 'User rights to object'; fa = 'حقوق کاربر بر شیء';
					|it = 'User rights to object';
					|pl = 'User rights to object';
					|tr = 'Nesnedeki kullanıcı izinleri'");
		
	ElsIf VariantKey = "UsersRightsByAllowedValue" Then
		Return NStr("vi = 'Quyền của người dùng theo từng giá trị được phép';
					|ru = 'Права пользователей в разрезе разрешенного значения';
					|en = 'User rights by allowed value'; fa = 'حقوق کاربر بر اساس مقدار مجاز';
					|it = 'User rights by allowed value';
					|pl = 'User rights by allowed value';
					|tr = 'İzin verilen değerlere göre kullanıcı yetkileri'");
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tên không xác định của phương án báo cáo ""%1"".';
			|ru = 'Неизвестное имя варианта отчета ""%1"".';
			|en = 'Unknown report option name: %1.'; fa = 'Unknown report option name: %1.';
			|it = 'Unknown report option name: %1.';
			|pl = 'Unknown report option name: %1.';
			|tr = '""%1"" raporu için varyant adı bilinmiyor.'"), VariantKey);
	
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction

Function RolesRightsReportOptionPresentation(VariantKey, FilterComposition)
	
	If VariantKey = "RolesRights" Then
		Return NStr("vi = 'Quyền của vai trò';
					|ru = 'Права ролей';
					|en = 'Role rights'; fa = 'حقوق نقش';
					|it = 'Diritti dei ruoli';
					|pl = 'Prawa ról';
					|tr = 'Rol yetkileri'");
		
	ElsIf VariantKey = "DetailedRolesRightsToMetadataObject" Then
		If FilterComposition.Profile = True Then
			Return NStr("vi = 'Quyền chi tiết của hồ sơ đối với đối tượng metadata';
						|ru = 'Подробные права профиля на объект метаданных';
						|en = 'Detailed profile rights that apply to metadata object'; fa = 'Detailed profile rights that apply to metadata object';
						|it = 'Detailed profile rights that apply to metadata object';
						|pl = 'Detailed profile rights that apply to metadata object';
						|tr = 'Meta veri nesnesine detaylı profil yetkisi'");
		ElsIf FilterComposition.Profile = Undefined Then
			Return NStr("vi = 'Quyền chi tiết của hồ sơ đối với đối tượng metadata';
						|ru = 'Подробные права профиля на объект метаданных';
						|en = 'Detailed profile rights that apply to metadata object'; fa = 'Detailed profile rights that apply to metadata object';
						|it = 'Detailed profile rights that apply to metadata object';
						|pl = 'Detailed profile rights that apply to metadata object';
						|tr = 'Meta veri nesnesine detaylı profil yetkisi'");
		ElsIf FilterComposition.Role Then
			Return NStr("vi = 'Quyền chi tiết của vai trò đến đối tượng metadata';
						|ru = 'Подробные права роли на объект метаданных';
						|en = 'Detailed role rights that apply to metadata object'; fa = 'حقوق تفصیلی نقش که بر شیء فراداده اعمال می‌شود';
						|it = 'Diritti dettagliati del ruolo sull''oggetto di metadati';
						|pl = 'Szczegółowe prawa roli do obiektu metadanych';
						|tr = 'Meta veri nesnesi üzerinde ayrıntılı rol yetkileri'");
		Else
			Return NStr("vi = 'Quyền chi tiết của vai trò đến đối tượng metadata';
						|ru = 'Подробные права роли на объект метаданных';
						|en = 'Detailed role rights that apply to metadata object'; fa = 'حقوق تفصیلی نقش که بر شیء فراداده اعمال می‌شود';
						|it = 'Diritti dettagliati del ruolo sull''oggetto di metadati';
						|pl = 'Szczegółowe prawa roli do obiektu metadanych';
						|tr = 'Meta veri nesnesi üzerinde ayrıntılı rol yetkileri'");
		EndIf;
		
	ElsIf VariantKey = "RightsOfRolesAndProfilesToMetadataObject" Then
		Return NStr("vi = 'Quyền của vai trò và hồ sơ đến đối tượng metadata';
					|ru = 'Права роли и профилей на объекты метаданных';
					|en = 'Role and profile rights that apply to metadata object'; fa = 'حقوق نقش و پروفایل که بر شیء فراداده اعمال می‌شود';
					|it = 'Role and profile rights that apply to metadata object';
					|pl = 'Role and profile rights that apply to metadata object';
					|tr = 'Meta veri nesnelerindeki rol ve profil izinleri'");
		
	ElsIf VariantKey = "RightsOfRoleAndProfilesToMetadataObjects" Then
		If FilterComposition.Role Then
			Return NStr("vi = 'Quyền của vai trò và hồ sơ đến đối tượng metadata';
						|ru = 'Права роли и профилей на объекты метаданных';
						|en = 'Role and profile rights that apply to metadata object'; fa = 'حقوق نقش و پروفایل که بر شیء فراداده اعمال می‌شود';
						|it = 'Role and profile rights that apply to metadata object';
						|pl = 'Role and profile rights that apply to metadata object';
						|tr = 'Meta veri nesnelerindeki rol ve profil izinleri'");
		Else
			Return NStr("vi = 'Quyền của hồ sơ đến đối tượng metadata';
						|ru = 'Права профилей на объекты метаданных';
						|en = 'Profile rights that apply to metadata objects'; fa = 'Profile rights that apply to metadata objects';
						|it = 'Regole dei profili agli oggetti di metadati';
						|pl = 'Prawa profili do obiektów metadanych';
						|tr = 'Meta veri nesnelerine profil yetkisi'");
		EndIf;
	EndIf;
	
	ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
		NStr("vi = 'Tên không xác định của phương án báo cáo ""%1"".';
			|ru = 'Неизвестное имя варианта отчета ""%1"".';
			|en = 'Unknown report option name: %1.'; fa = 'Unknown report option name: %1.';
			|it = 'Unknown report option name: %1.';
			|pl = 'Unknown report option name: %1.';
			|tr = '""%1"" raporu için varyant adı bilinmiyor.'"), VariantKey);
	
	Raise(ErrorText, ErrorCategory.ConfigurationError);
	
EndFunction


// Intended for procedure "OnValueChoiceStart".
Procedure AttheStartofSelectingReportValuesAnalysisAccessPermissions(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	If SelectionConditions.FieldName = "MetadataObject" Then
		OnStartSelectMetadataObjectOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
		
	ElsIf SelectionConditions.FieldName = "DataElement" Then
		OnStartSelectDataElementOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing);
	EndIf;
	
EndProcedure

// Intended for procedure "AttheStartofSelectingReportValuesAnalysisAccessPermissions".
Procedure OnStartSelectMetadataObjectOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	StandardProcessing = False;
	
	Collections = New ValueList;
	Collections.Add("Catalogs");
	Collections.Add("Documents");
	Collections.Add("DocumentJournals");
	Collections.Add("ChartsOfCharacteristicTypes");
	Collections.Add("ChartsOfAccounts");
	Collections.Add("ChartsOfCalculationTypes");
	Collections.Add("InformationRegisters");
	Collections.Add("AccumulationRegisters");
	Collections.Add("AccountingRegisters");
	Collections.Add("CalculationRegisters");
	Collections.Add("BusinessProcesses");
	Collections.Add("Tasks");
	
	Selected_ = CommonClient.CopyRecursive(SelectionConditions.Marked);
	DeleteDisabledValues(Selected_);
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.ChooseRefs = True;
	PickingParameters.SelectedMetadataObjects = Selected_;
	PickingParameters.MetadataObjectsToSelectCollection = Collections;
	PickingParameters.ObjectsGroupMethod = "BySections,ByKinds";
	PickingParameters.Title = NStr("vi = 'Chọn bảng';
									|ru = 'Подбор таблиц';
									|en = 'Pick tables'; fa = 'Pick tables';
									|it = 'Подбор таблиц';
									|pl = 'Wybór tabel';
									|tr = 'Tablo seçimi'");
	
	Context = New Structure;
	Context.Insert("SelectionConditions", SelectionConditions);
	Context.Insert("ClosingNotification1", ClosingNotification1);
	
	Handler = New CallbackDescription("AfterSelectingMetadataObjects", ThisObject, Context);
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, Handler);
	
EndProcedure


// Intended for procedure "AttheStartofSelectingReportValuesAnalysisAccessPermissions".
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReport(ReportForm,
			SelectionConditions, ClosingNotification1, StandardProcessing)
	
	StandardProcessing = False;
	
	Context = New Structure;
	Context.Insert("ClosingNotification1", ClosingNotification1);
	Context.Insert("InitialValue", ?(ValueIsFilled(SelectionConditions.Marked),
		SelectionConditions.Marked[0].Value, Undefined));
	
	List = AccessManagementInternalServerCall.ListOfTypesForSelection(
		SelectionConditions.AvailableTypes);
	
	Notification = New CallbackDescription(
		"OnStartSelectDataElementOfAccessRightsAnalysisReportAfterTypeSelected", ThisObject, Context);
	
	InitialItem = ?(ValueIsFilled(Context.InitialValue),
		List.FindByValue(TypeOf(Context.InitialValue)), Undefined);
	
	Title = NStr("vi = 'Chọn kiểu dữ liệu';
				|ru = 'Выбор типа данных';
				|en = 'Select data type'; fa = 'Select data type';
				|it = 'Scelta del tipo dati';
				|pl = 'Wybierz typ danych';
				|tr = 'Veri türünü seçin'");
	
	List.ShowChooseItem(Notification, Title, InitialItem);
	
EndProcedure

// Intended for procedure "AttheStartofSelectingReportValuesAnalysisAccessPermissions".
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReportAfterTypeSelected(Result, Context) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	FullName = AccessManagementInternalServerCall.FullNameOfReferenceTypeTable(
		Result.Value);
	
	FormParameters = New Structure;
	FormParameters.Insert("CurrentRow", Context.InitialValue);
	FormParameters.Insert("CloseOnChoice", True);
	
	Notification = New CallbackDescription(
		"OnStartSelectDataElementOfAccessRightsAnalysisReportAfterValueSelected", ThisObject, Context);
	
	If ValueIsFilled(FullName) Then
		OpenForm(FullName + ".ChoiceForm", FormParameters,,,,,Notification);
	Else
		FormParameters.Insert("DataItemType", Result.Value);
		OpenForm("Report.AccessRightsAnalysis.Form.SelectRegisterRow", FormParameters,,,,,Notification);
	EndIf;
	
	
EndProcedure

// Intended for procedure "AttheStartofSelectingReportValuesAnalysisAccessPermissions".
Procedure OnStartSelectDataElementOfAccessRightsAnalysisReportAfterValueSelected(Result, Context) Export
	
	If Not ValueIsFilled(Result) Then
		Return;
	EndIf;
	
	SelectedValues = CommonClientServer.ValueInArray(Result);
	RunCallback(Context.ClosingNotification1, SelectedValues);
	
EndProcedure


// Intended for procedure "OnValueChoiceStart".
Procedure AttheStartofSelectingReportValuesRoleRights(ReportForm, SelectionConditions, ClosingNotification1, StandardProcessing)
	
	If SelectionConditions.FieldName <> "Role"
	   And SelectionConditions.FieldName <> "MetadataObject" Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	Selected_ = CommonClient.CopyRecursive(SelectionConditions.Marked);
	DeleteDisabledValues(Selected_);
	Collections = New ValueList;
	
	PickingParameters = StandardSubsystemsClientServer.MetadataObjectsSelectionParameters();
	PickingParameters.SelectedMetadataObjects = Selected_;
	PickingParameters.MetadataObjectsToSelectCollection = Collections;
	
	If SelectionConditions.FieldName = "Role" Then
		For Each ListItem In Selected_ Do
			ListItem.Value = "Role." + ListItem.Value;
		EndDo;
		PickingParameters.ObjectsGroupMethod = "ByKinds";
		PickingParameters.Title = NStr("vi = 'Chọn vai trò';
										|ru = 'Подбор ролей';
										|en = 'Pick roles'; fa = 'Pick roles';
										|it = 'Подбор ролей';
										|pl = 'Wybór ról';
										|tr = 'Rol toplama'");
		Collections.Add("Roles");
	Else
		PickingParameters.ObjectsGroupMethod = "ByKinds,BySections";
		PickingParameters.Title = NStr("vi = 'Chọn đối tượng metadata';
										|ru = 'Подбор объектов метаданных';
										|en = 'Pick metadata objects'; fa = 'Pick metadata objects';
										|it = 'Подбор объектов метаданных';
										|pl = 'Wybór obiektów metadanych';
										|tr = 'Metaveri nesnelerin toplanması'");
		PickingParameters.SelectCollectionsWhenAllObjectsSelected = True;
		AccessManagementInternalClientServer.AddMetadataObjectCollectionWithRights(Collections);
	EndIf;
	
	Context = New Structure;
	Context.Insert("SelectionConditions", SelectionConditions);
	Context.Insert("ClosingNotification1", ClosingNotification1);
	
	Handler = New CallbackDescription("AfterSelectingMetadataObjects", ThisObject, Context);
	StandardSubsystemsClient.ChooseMetadataObjects(PickingParameters, Handler);
	
EndProcedure

// Intended for procedure "OnValueChoiceStart".
Procedure AfterSelectingMetadataObjects(SelectedValues, Context) Export
	
	If Context.SelectionConditions.FieldName = "Role"
	   And ValueIsFilled(SelectedValues) Then
		
		For Each ListItem In SelectedValues Do
			ListItem.Value = StrSplit(ListItem.Value, ".")[1];
		EndDo;
	EndIf;
	
	RunCallback(Context.ClosingNotification1, SelectedValues);
	
EndProcedure

// Intended for procedure "OnValueChoiceStart".
Procedure DeleteDisabledValues(MarkedValues)
	
	IndexOf = MarkedValues.Count() - 1;
	
	While IndexOf >= 0 Do 
		Item = MarkedValues[IndexOf];
		IndexOf = IndexOf - 1;
		
		If Not ValueIsFilled(Item.Value) Then 
			MarkedValues.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// For the AccessRights and AccessRightsSimplified forms.
//
// Parameters:
//  RolesDifferences - See AccessManagementInternal.DifferencesBetweenConfiguredRolesCompositionAndIBUserRoles
//
Procedure ShowDifferencesBetweenConfiguredRolesCompositionAndIBUserRoles(RolesDifferences) Export
	
	If Not ValueIsFilled(RolesDifferences) Then
		Return;
	EndIf;
	
	StandardSubsystemsClient.ShowDetailedInfo(Undefined, RolesDifferences);
	
EndProcedure

#EndRegion