#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	For Each QuickSearchString In Parameters.QuickSearch Do
		NewSearchString = QuickSearch.Add();
		FillPropertyValues(
			NewSearchString,
			QuickSearchString,
			IntegrationWith1CDocumentManagement3ClientServer.QuickSearchColumns());
	EndDo;
	
	QuickSearchChoiceLists = Parameters.QuickSearchChoiceLists;
	
	UpdateQuickSearchPresentation();
	
	IntegrationWith1CDocumentManagement3.SetConditionalAppearanceOfQuickSearchTable(
		ConditionalAppearance,
		Items.QuickSearch,
		Items.QuickSearchValue);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersQuickSearch

&AtClient
Procedure QuickSearchOnChange(Item)
	
	QuickSearchForChangesOnServer();
	
EndProcedure

&AtClient
Procedure QuickSearchOnActivateRow(Item)
	
	If Items.QuickSearch.CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	Items.QuickSearchValue.ChoiceList.Clear();
	If QuickSearchChoiceLists.Property(CurrentData.Parameter) Then
		
		ParameterSelectionList = QuickSearchChoiceLists[CurrentData.Parameter];
		For Each ChoiceItem In ParameterSelectionList Do
			Items.QuickSearchValue.ChoiceList.Add(
				ChoiceItem.Value,
				ChoiceItem.Presentation,,
				ChoiceItem.Picture);
		EndDo;
		
		Items.QuickSearchValue.DropListButton = True;
		Items.QuickSearchValue.ChoiceButton = False;
		Items.QuickSearchValue.ListChoiceMode = True;
		
	Else
		
		Items.QuickSearchValue.DropListButton = Undefined;
		If CurrentData.Parameter = "ApplicationKind" Then
			Items.QuickSearchValue.ChoiceButton = False;
		Else
			Items.QuickSearchValue.ChoiceButton = True;
		EndIf;
		Items.QuickSearchValue.ListChoiceMode = False;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure QuickSearchValueAutoComplete(Item, Text, ChoiceData, DataGetParameters, Waiting, StandardProcessing)
	
	If Item.ChoiceList.Count() > 0 And Not ValueIsFilled(Item.ChoiceList[0].Value) Then
		Item.ChoiceList.Clear();
		Return;
	EndIf;
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If CurrentData = Undefined
			Or Not ValueIsFilled(Text)
			Or Item.ListChoiceMode
			Or TypeOf(CurrentData.Value) = Type("Number")
			Or TypeOf(CurrentData.Value) = Type("Date")
			Or TypeOf(CurrentData.Value) = Type("Boolean") Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		CurrentData.Type,
		ChoiceData,
		Text,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure QuickSearchValueTextEditEnd(Item, Text, ChoiceData, DataGetParameters, StandardProcessing)
	
	If Not ValueIsFilled(Text) Then
		Return;
	EndIf;
	
	If Item.ChoiceList.Count() > 0 And Not ValueIsFilled(Item.ChoiceList[0].Value) Then
		Item.ChoiceList.Clear();
		Return;
	EndIf;
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If CurrentData = Undefined
			Or Item.ListChoiceMode
			Or TypeOf(CurrentData.Value) = Type("Number")
			Or TypeOf(CurrentData.Value) = Type("Date")
			Or TypeOf(CurrentData.Value) = Type("Boolean") Then
		Return;
	EndIf;
	
	IntegrationWith1CDocumentManagementCoreServerCall.DataForAutoMatching(
		CurrentData.Type,
		ChoiceData,
		Text,
		StandardProcessing);
	
EndProcedure

&AtClient
Procedure QuickSearchValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	If Item.ChoiceList.Count() > 0 And Not ValueIsFilled(Item.ChoiceList[0].Value) Then
		Item.ChoiceList.Clear();
		Return;
	EndIf;
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If CurrentData = Undefined
			Or Item.ListChoiceMode
			Or TypeOf(CurrentData.Value) = Type("Number")
			Or TypeOf(CurrentData.Value) = Type("Date")
			Or TypeOf(CurrentData.Value) = Type("Boolean") Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	TypesArray = StrSplit(CurrentData.Type, ";", False);
	
	ValueSelectionParametersBefore = IntegrationWith1CDocumentManagementCoreClient.ValueSelectionParametersBefore();
	ValueSelectionParametersBefore.Notification =
		New CallbackDescription("ChooseValueOfAttributeDMCompletionInputValue", ThisObject);
	ValueSelectionParametersBefore.EditText = Items.QuickSearchValue.EditText;
	ValueSelectionParametersBefore.Presentation = CurrentData.ValuePresentation;
	ValueSelectionParametersBefore.AttributeValue = CurrentData.Value;
	ValueSelectionParametersBefore.AttributeValueID = CurrentData.ValueID;
	ValueSelectionParametersBefore.AttributeValueType = CurrentData.ValueType;
	
	IntegrationWith1CDocumentManagementCoreClient.ChooseValueOfAttributeBefore(
		ThisObject,
		Items.QuickSearchValue,
		TypesArray,
		ValueSelectionParametersBefore);
	
EndProcedure

&AtClient
Procedure ChooseValueOfAttributeDMCompletionInputValue(Result, NotificationParameters) Export
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If Result <> Undefined Then
		If TypeOf(Result) = Type("Structure") Then
			CurrentData.Value = Result.AttributePresentation;
			CurrentData.ValueID = Result.AttributeID;
			CurrentData.ValueType = Result.AttributeType;
		Else
			CurrentData.Value = Result;
		EndIf;
		QuickSearchForChangesOnServer();
	EndIf;
	
EndProcedure

&AtClient
Procedure QuickSearchValueChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	If CurrentData.Parameter = "State" And ValueSelected = NStr("vi = 'Chọn nhiều...';
																|ru = 'Выбрать несколько...';
																|en = 'Select several items...'; fa = 'Select several items...';
																|it = 'Выбрать несколько...';
																|pl = 'Select several items...';
																|tr = 'Birden fazla seç...'") Then
		
		AddlParameters = New Structure("CurrentData", CurrentData);
		CallbackDescription = New CallbackDescription(
			"QuickSearchSelectStateCompletion",
			ThisObject,
			AddlParameters);
		
		OpeningParameters = New Structure;
		OpeningParameters.Insert("CurrentDataValue", CurrentData.Value);
		OpeningParameters.Insert("CurrentDataValueID", CurrentData.ValueID);
		OpeningParameters.Insert("CurrentDataValueType", CurrentData.ValueType);
		OpeningParameters.Insert("States1", QuickSearchChoiceLists["State"]);
		
		OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.QuickSearchSelectState",
			OpeningParameters,,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
		Return;
		
	EndIf;
	
	SelectedValueInCurData(CurrentData, ValueSelected);
	
	QuickSearchForChangesOnServer();
	
EndProcedure

&AtClient
Procedure QuickSearchSelectStateCompletion(ValueSelected, AdditionalParameters) Export
	
	If ValueSelected = Undefined Or ValueSelected = DialogReturnCode.Cancel Then
		Return;
	EndIf;
	
	CurrentData = AdditionalParameters.CurrentData;
	
	SelectedValueInCurData(CurrentData, ValueSelected);
	
	QuickSearchForChangesOnServer();
	
EndProcedure

&AtClient
Procedure QuickSearchValueClearing(Item, StandardProcessing)
	
	CurrentData = Items.QuickSearch.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	StandardProcessing = False;
	
	CurrentData.Value = CurrentData.DefaultValue;
	CurrentData.ValueID = CurrentData.DefaultValueID;
	CurrentData.ValueType = CurrentData.DefaultValueID;
	
	QuickSearchForChangesOnServer();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Done(Command)
	
	Close(QuickSearch);
	
EndProcedure

&AtClient
Procedure ResetSelection(Command)
	
	ResetSelectionOnServer();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SelectedValueInCurData(CurrentData, ValueSelected)
	
	If TypeOf(ValueSelected) = Type("Structure") Then
		If ValueSelected.Property("name")
				And ValueSelected.Property("ID")
				And ValueSelected.Property("type") Then
			CurrentData.Value = ValueSelected.name;
			CurrentData.ValueID = ValueSelected.ID;
			CurrentData.ValueType = ValueSelected.type;
		ElsIf ValueSelected.Property("Description")
				And ValueSelected.Property("ID")
				And ValueSelected.Property("Type") Then
			CurrentData.Value = ValueSelected.Description;
			CurrentData.ValueID = ValueSelected.ID;
			CurrentData.ValueType = ValueSelected.Type;
		EndIf;
	Else
		CurrentData.Value = ValueSelected;
	EndIf;
	
EndProcedure

&AtServer
Procedure QuickSearchForChangesOnServer()
	
	UpdateQuickSearchPresentation();
	
EndProcedure

&AtServer
Procedure UpdateQuickSearchPresentation()
	
	IntegrationWith1CDocumentManagement3.UpdateQuickSearchPresentation(
		QuickSearch,
		Items.ResetSelection);
	
EndProcedure

&AtServer
Procedure ResetSelectionOnServer()
	
	IntegrationWith1CDocumentManagement3.ResetQuickSearch(QuickSearch, Items.ResetSelection);
	
EndProcedure

#EndRegion