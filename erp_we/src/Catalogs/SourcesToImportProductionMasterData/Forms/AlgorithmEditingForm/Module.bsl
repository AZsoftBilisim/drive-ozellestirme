
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Parameters.Property("AlgorithmText", AlgorithmText);
	If Parameters.Property("AlgorithmParameters") Then
		For Each ParameterStructure In Parameters.AlgorithmParameters Do
			FillPropertyValues(AlgorithmParameters.Add(), ParameterStructure);
		EndDo;
		UpdateNumberOfParameters(ThisObject);
	EndIf;
	
	If Parameters.Property("Title") Then
		Parameters.Property("Title", Title);
	EndIf;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
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

#Region FormTableItemsEventHandlersAlgorithmParameters

&AtClient
Procedure AlgorithmParametersOnEditEnd(Item, NewRow, CancelEdit)
	
	UpdateNumberOfParameters(ThisObject);
	
EndProcedure

&AtClient
Procedure AlgorithmParametersValueStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.AlgorithmParameters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ConfigureParameterValueSelectionElement(Item, CurrentData);
	
EndProcedure

&AtClient
Procedure AlgorithmParametersValueClearing(Item, StandardProcessing)
	
	CurrentData = Items.AlgorithmParameters.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentData.Value = Undefined;
	CurrentData.ValueType = Undefined;
	CurrentData.ValueTypePresentation = Undefined;
	
	ConfigureParameterValueSelectionElement(Item, CurrentData);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Save(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure Validate(Command)
	
	Return; // empty handler
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure CompleteEditing()
	
	Cancel = False;
	
	TemplateParameterName = NStr("vi = 'Chưa chỉ ra tên tham số tại dòng %1.';
								|ru = 'Не указано имя параметра в строке %1.';
								|en = 'A parameter name is not specified in line %1.'; fa = 'A parameter name is not specified in line %1.';
								|it = 'Не указано имя параметра в строке %1.';
								|pl = 'A parameter name is not specified in line %1.';
								|tr = '%1 satırında parametre adı belirtilmedi.'");
	TemplateParameterValue = NStr("vi = 'Chưa đặt giá trị tham số ""%1"".';
									|ru = 'Не задано значение параметра ""%1"".';
									|en = 'A value of the %1 parameter is not set.'; fa = 'A value of the %1 parameter is not set.';
									|it = 'Не задано значение параметра ""%1"".';
									|pl = 'A value of the %1 parameter is not set.';
									|tr = '""%1"" parametre değeri belirtilmedi.'");
	DataPathTemplate = "AlgorithmParameters[%1].%2";
	
	ParametersArray = New Array;
	For IndexOf = 0 To AlgorithmParameters.Count()-1 Do
		StringParameter = AlgorithmParameters[IndexOf];
		If Not ValueIsFilled(StringParameter.ParameterName) Then
			CommonClient.MessageToUser(
				StrTemplate(TemplateParameterName, IndexOf),,
				StrTemplate(DataPathTemplate, IndexOf, "ParameterName"),,
				Cancel);
			Continue;
		EndIf;
		If StringParameter.Value = Undefined Then
			CommonClient.MessageToUser(
				StrTemplate(TemplateParameterValue, StringParameter.ParameterName),,
				StrTemplate(DataPathTemplate, IndexOf, "Value"),,
				Cancel);
			Continue;
		EndIf;
		ParametersArray.Add(New Structure("ParameterName,Value", StringParameter.ParameterName, StringParameter.Value));
	EndDo;
	
	Result = New Structure;
	Result.Insert("AlgorithmText", AlgorithmText);
	Result.Insert("AlgorithmParameters", ParametersArray);
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	Close(Result);
	
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
Procedure ConfigureParameterValueSelectionElement(Item, RowData)
	
	Item.ChooseType          = (RowData.Value = Undefined);
	Item.ChoiceButton         = True;
	Item.ClearButton        = Not Item.ChooseType;
	Item.ChoiceFoldersAndItems = FoldersAndItems.FoldersAndItems;
	
EndProcedure

&AtClientAtServerNoContext
Procedure UpdateNumberOfParameters(Form)
	
	Form.ParametersCount = Form.AlgorithmParameters.Count();
	
EndProcedure

#EndRegion
