
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	DescriptionOfUploadedDataElement = Parameters.DescriptionOfUploadedDataElement; // See ProductDataManagement.DescriptionOfLoadedDataElementConstructor
	For Each AttributeGroup In ProductDataManagementClientServer.GroupsOfAttributesForItemHeader() Do
		For Each KeyAndValue In DescriptionOfUploadedDataElement[AttributeGroup] Do
			AttributeDetails = KeyAndValue.Value;
			NewRow = AvailableAttributes.Add();
			NewRow.AttributeName  = AttributeDetails.Name;
			NewRow.Presentation = AttributeDetails.Presentation;
		EndDo;
	EndDo;
	
	If DescriptionOfUploadedDataElement.HasCode Then
		NewRow = AvailableAttributes.Add();
		NewRow.AttributeName  = "Code";
		NewRow.Presentation = NewRow.AttributeName;
	EndIf;
	
	Setting = Undefined;
	If Parameters.Property("ConfiguringSearchConflictResolution", Setting) Then
		Rule = Setting.Rule;
		If SortingIsAvailable(ThisObject) Then
			For IndexOf = 0 To Setting.SortingSettings.UBound() Do
				SettingStructure = Setting.SortingSettings[IndexOf]; // See ProductDataManagementClientServer.DescriptionOfSortingElementConstructor
				AddFieldByName(ThisObject, SettingStructure.AttributeName, SettingStructure.Direction);
			EndDo;
		EndIf;
	EndIf;
	
	CustomizeFormElements();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'The data was changed. Do you want to save the changes?'; fa = 'The data was changed. Do you want to save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure RuleOnChange(Item)
	
	If Not SortingIsAvailable(ThisObject) Then
		RemoveFields(ThisObject, SortingAttributes);
	EndIf;
	
	ConfigureDependentFormElements(ThisObject, "Rule");
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersAvailableAttributes

&AtClient
Procedure AvailableAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.AvailableAttributesPresentation Then
		
		AddFields(ThisObject, CommonClientServer.ValueInArray(RowSelected));
		
		Modified = True;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSortingAttributes

&AtClient
Procedure SortingAttributesSelection(Item, RowSelected, Field, StandardProcessing)
	
	If Field = Items.AttributesOfSortingDirection Then
		
		StandardProcessing = False;
		SwitchSortingDirection(RowSelected);
		
		Modified = True;
		
	ElsIf Field = Items.SortingAttributesPresentation Then
		
		RemoveFields(ThisObject, CommonClientServer.ValueInArray(RowSelected));
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SortingAttributesBeforeDeleteRow(Item, Cancel)
	
	RemoveFields(ThisObject, Items.SortingAttributes.SelectedRows);
	
	Cancel = True;
	Modified = True;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToRight(Command)
	
	AddFields(ThisObject, Items.AvailableAttributes.SelectedRows);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure ToLeft(Command)
	
	RemoveFields(ThisObject, Items.SortingAttributes.SelectedRows);
	
	Modified = True;
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	CompleteEditing();
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	If Parameters.Property("Title") Then
		Parameters.Property("Title", Title);
	EndIf;
	
	AvailableAttributes.Sort("Presentation");
	Items.AvailableAttributes.RowFilter = New FixedStructure("Selected", False);

	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	If AttributesStructure1.Property("Rule")
		Or Initialize Then
			
			Items.GroupSort.Enabled = SortingIsAvailable(Form);
			
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure RemoveFields(Form, RowsIDs)
	
	DeleteArray = New Array;
	TheStructureOfTheSearch = New Structure("AttributeName");
	
	For Each RowID In RowsIDs Do
		If TypeOf(RowID) = Type("Number") Then
			RowData = Form.SortingAttributes.FindByID(RowID);
		Else
			RowData = RowID;
		EndIf;
		TheStructureOfTheSearch.AttributeName = RowData.AttributeName;
		For Each FoundRow In Form.AvailableAttributes.FindRows(TheStructureOfTheSearch) Do
			FoundRow.Selected = False;
		EndDo;
		DeleteArray.Add(RowData);
	EndDo;
	
	For Each RowData In DeleteArray Do
		Form.SortingAttributes.Delete(RowData);
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddFields(Form, RowsIDs, Direction = "Asc")
	
	For Each RowID In RowsIDs Do
		If TypeOf(RowID) = Type("Number") Then
			RowData = Form.AvailableAttributes.FindByID(RowID);
		Else
			RowData = RowID;
		EndIf;
		NewRow = Form.SortingAttributes.Add();
		NewRow.AttributeName  = RowData.AttributeName;
		NewRow.Presentation = RowData.Presentation;
		NewRow.Direction   = Direction;
		NewRow.DirectionPresentation = String(SortDirection[NewRow.Direction]);
		RowData.Selected = True;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddFieldByName(Form, AttributeName, Direction = "Asc")
	
	FoundRows = Form.AvailableAttributes.FindRows(New Structure("AttributeName", AttributeName));
	If ValueIsFilled(FoundRows) Then
		AddFields(Form,
			CommonClientServer.ValueInArray(FoundRows[0].GetID()),
			Direction);
	EndIf;
	
EndProcedure

&AtClient
Procedure SwitchSortingDirection(RowID)
	
	RowData = SortingAttributes.FindByID(RowID);
	
	RowData.Direction = ?(RowData.Direction = "Asc", "Desc", "Asc");
	RowData.DirectionPresentation = String(SortDirection[RowData.Direction]);
	
EndProcedure

&AtClient
Procedure BeforeCloseCompletion(QuestionResult, AdditionalParameters) Export
	
	If QuestionResult = DialogReturnCode.Yes Then
		CompleteEditing();
	ElsIf QuestionResult = DialogReturnCode.No Then
		Modified = False;
		Close();
	EndIf;
	
EndProcedure

&AtClient
Procedure CompleteEditing()
	
	Cancel = False;
	
	Setting = ProductDataManagementClientServer.DescriptionOfConflictResolutionSettingsForSearchConstructor();
	
	Setting.Rule = Rule;
	
	If SortingIsAvailable(ThisObject) Then
		If SortingAttributes.Count() > 0 Then
			For Each String In SortingAttributes Do
				NewItem = ProductDataManagementClientServer.DescriptionOfSortingElementConstructor();
				FillPropertyValues(NewItem, String);
				Setting.SortingSettings.Add(NewItem);
			EndDo;
		Else
			CommonClient.MessageToUser(
				NStr("vi = 'Cần chọn trường mà theo đó sẽ thực hiện sắp xếp';
					|ru = 'Необходимо выбрать поля, по которым будет производиться сортировка';
					|en = 'Select fields to sort'; fa = 'Select fields to sort';
					|it = 'Необходимо выбрать поля, по которым будет производиться сортировка';
					|pl = 'Select fields to sort';
					|tr = 'Sıralamanın gerçekleştirileceği alanları seçmeniz gerekmektedir'"),,
				"SortingAttributes",,
				Cancel);
		EndIf;
	EndIf;
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	Close(New Structure("ConfiguringSearchConflictResolution", Setting));
	
EndProcedure

&AtClientAtServerNoContext
Function SortingIsAvailable(Form)
	
	Return Form.Rule = ProductDataManagementClientServer.RuleForResolvingConflictsWhenSearchingSort();
	
EndFunction

#EndRegion