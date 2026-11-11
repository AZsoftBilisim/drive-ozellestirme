#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	TypeOfSelectionObject = Parameters.TypeOfSelectionObject;
	
	ObjectAttributesBefore = Catalogs.RulesForIntegrationWith1CDocumentManagement3.ObjectAttributesBefore(
		TypeOfSelectionObject,
		Undefined,
		True);
	
	For Each Attribute In ObjectAttributesBefore Do
		If Attribute.NameOfAttributeOfVDO = "" Then
			Continue;
		EndIf;
		AddSearchDetails(Attribute.Name, Attribute.Presentation, Attribute.Type);
	EndDo;
	
	SearchAttributes.Sort("Presentation");
	
	SearchImmediately = False;
	
	// There may be preset conditions in the parameters.
	If Parameters.Property("Filter") And Parameters.Filter <> Undefined Then
		For Each PresetCondition In Parameters.Filter Do
			AttributeName = PresetCondition.Key;
			ConditionDetails = PresetCondition.Value;
			FilterStructure1 = New Structure("Name", AttributeName);
			ConditionStrings = SearchAttributes.FindRows(FilterStructure1);
			If ConditionStrings.Count() > 0 Then
				ConditionString = ConditionStrings[0];
				ConditionString.ComparisonOperator = "=";
				If TypeOf(ConditionDetails) = Type("Structure") Then // A difficult condition.
					FillPropertyValues(ConditionString, ConditionDetails);
				Else // The selection value is indicated directly.
					ConditionString.Value = ConditionDetails;
				EndIf;
				AssembleConditionPresentation(ConditionString);
			EndIf;
		EndDo;
		SearchImmediately = True;
	EndIf;
	
	If Parameters.Property("SearchImmediately") Then
		SearchImmediately = Parameters.SearchImmediately;
	EndIf;
	
	If SearchImmediately Then
		DataProcessors.IntegrationWith1CDocumentManagement3.PerformSearchByBankingDetails(
			TypeOfSelectionObject,
			FilterStructure1(),
			AddressInTempStorage,
			NumberOfResults,
			LimitNumberOfResults);
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not SearchImmediately Or NumberOfResults = 0 Then
		Return;
	EndIf;
	
	AttachIdleHandler("ProcessSearchResults", 0.1, True);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure DecorationSimpleSearchClick(Item)
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("SearchImmediately", False);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearch",
		FormParameters,
		ThisObject,
		New UUID,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSearchAttributes

&AtClient
Procedure SearchAttributesOnStartEdit(Item, NewRow, Copy)
	
	CurrentData = Items.SearchAttributes.CurrentData;
	ConditionPresentationElement = Items.SearchAttributesConditionPresentation;
	
	ConditionPresentationElement.TypeRestriction = New TypeDescription("String");
	
	If CurrentData.AttributeType.Count() > 1 Then
		Return;
	EndIf;
	
	If CurrentData.ValueType = "String" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription("String");
		ConditionPresentation = CurrentData.Value;
		If Left(ConditionPresentation, 1) = "%" Then
			ConditionPresentation = Mid(ConditionPresentation, 2);
		EndIf;
		If Right(ConditionPresentation, 1) = "%" Then
			ConditionPresentation = Left(ConditionPresentation, StrLen(ConditionPresentation) - 1);
		EndIf;
		CurrentData.ConditionPresentation = ConditionPresentation;
		
	ElsIf CurrentData.ValueType = "Number" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription(CurrentData.ValueType);
		CurrentData.ConditionPresentation = CurrentData.Value;
		
	ElsIf CurrentData.ValueType = "Date" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription(
			"Date",,, New DateQualifiers(DateFractions.Date));
		CurrentData.ConditionPresentation = CurrentData.Value;
		
	ElsIf CurrentData.ValueType = "Boolean" Then
		ConditionPresentationElement.TypeRestriction = New TypeDescription("Boolean");
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchAttributesOnActivateRow(Item)
	
	Type = "";
	If Items.SearchAttributes.CurrentData.AttributeType.Count() = 1 Then
		Type = Items.SearchAttributes.CurrentData.AttributeType[0].Value
	EndIf;
	
	Items.SearchAttributesConditionPresentation.TextEdit =
		Type = "String" Or Type = "Number" Or Type = "Date";
	
EndProcedure

&AtClient
Procedure SearchAttributesOnEditEnd(Item, NewRow, CancelEdit)
	
	If CancelEdit Then
		Return;
	EndIf;
	CurrentData = Items.SearchAttributes.CurrentData;
	
	If CurrentData.AttributeType.Count() > 1 Then
		Return;
	EndIf;
	
	EnteredValue = CurrentData.ConditionPresentation;
	If Not ValueIsFilled(EnteredValue) Then // We consider manual cleaning to be a rejection of the search.
		CurrentData.ComparisonOperator = "";
		
	ElsIf Not ValueIsFilled(CurrentData.ComparisonOperator) Then // Assign a condition.
		If CurrentData.ValueType = "String" Then
			CurrentData.ComparisonOperator = "LIKE";
			CurrentData.Value = "%" + EnteredValue + "%";
		ElsIf CurrentData.ValueType = "Date" Then
			CurrentData.ComparisonOperator = ">=";
			CurrentData.Value = EnteredValue;
		ElsIf CurrentData.ValueType = "Number" Then
			CurrentData.ComparisonOperator = "=";
			CurrentData.Value = EnteredValue;
		EndIf;
		
	Else // The condition already exists, only the value changes.
		If CurrentData.ValueType = "String" And CurrentData.ComparisonOperator = "LIKE" Then
			// Let's keep the nuances of searching by similarity.
			CurrentData.Value = ?(Left(CurrentData.Value, 1) = "%", "%", "")
				+ EnteredValue + ?(Right(CurrentData.Value, 1) = "%", "%", "");
		Else
			CurrentData.Value = EnteredValue;
		EndIf;
		
	EndIf;
	
	AssembleConditionPresentation(CurrentData);
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationStartChoice(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SearchAttributes.CurrentData;
	
	If CurrentData.ValueType <> "" Then
		SelectValueOfAttributeTypeEnd(CurrentData.ValueType, StandardProcessing);
		
	ElsIf CurrentData.AttributeType.Count() = 1 Then
		Value = CurrentData.AttributeType[0].Value;
		SelectValueOfAttributeTypeEnd(Value, StandardProcessing);
		
	Else
		CallbackDescription = New CallbackDescription(
			"SelectValueOfAttributeTypeEnd",
			ThisObject,
			StandardProcessing);
		ShowChooseFromList(CallbackDescription, CurrentData.AttributeType, Item);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SelectValueOfAttributeTypeEnd(Val TypeValue, StandardProcessing) Export
	
	CurrentData = Items.SearchAttributes.CurrentData;
	
	If TypeOf(TypeValue) = Type("ValueListItem") Then
		TypeValue = TypeValue.Value;
	EndIf;
	
	If TypeValue = "Boolean" Then // The standard drop-down list is fine.
		CurrentData.ValueType = "Boolean";
		Items.SearchAttributesConditionPresentation.TypeRestriction = New TypeDescription("Boolean");
		Return;
	EndIf;
	
	CurrentData.ValueType = "";
	StandardProcessing = False;
	
	CallbackDescription = New CallbackDescription("SearchDetailsPresentationOfConditionCompletionOfSelection",
		ThisObject,
		Items.SearchAttributes);
	
	If TypeValue = "String" Or TypeValue = "Date" Or TypeValue = "Number" Then
		
		NameOfInputForm = StrTemplate(
			"DataProcessor.IntegrationWith1CDocumentManagementCore.Form.EnteringSearchDetails%1",
			TypeValue);
		FormParameters = New Structure;
		FormParameters.Insert("Title", CurrentData.Presentation);
		FormParameters.Insert("Value", CurrentData.Value);
		FormParameters.Insert("ComparisonOperator", CurrentData.ComparisonOperator);
		FormParameters.Insert("Value2", CurrentData.Value2);
		FormParameters.Insert("ComparisonOperator2", CurrentData.ComparisonOperator2);
		OpenForm(
			NameOfInputForm,
			FormParameters,
			ThisObject,,,,
			CallbackDescription,
			FormWindowOpeningMode.LockWholeInterface);
		
	ElsIf ValueIsFilled(TypeValue) Then // The reference type is UP to.
		
		FormParameters = New Structure;
		FormParameters.Insert("TypeOfSelectionObject", TypeValue);
		
		If ValueIsFilled(CurrentData.ValueID) Then
			FormParameters.Insert("SelectedElement", CurrentData.ValueID);
		EndIf;
		
		If IntegrationWith1CDocumentManagement3ClientCached.IsDocumentBefore3(TypeValue)
				Or TypeValue = "DMCorrespondent" Or TypeValue = "DMMeeting" Then
			// There are potentially a lot of objects UP to, you need a choice of search.
			Filter = New Structure;
			If ValueIsFilled(CurrentData.Value) Then
				Filter.Insert("name", TrimAll(CurrentData.Value));
				FormParameters.Insert("SearchImmediately", False);
			EndIf;
			FormParameters.Insert("Filter", Filter);
			
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearch",
				FormParameters,
				ThisObject,
				UUID,,,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		Else
			// The usual selection from the list.
			OpenForm("DataProcessor.IntegrationWith1CDocumentManagementCore.Form.SelectingFromList",
				FormParameters,
				ThisObject,
				New UUID,,,
				CallbackDescription,
				FormWindowOpeningMode.LockWholeInterface);
			
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationClearing(Item, StandardProcessing)
	
	CurrentData = Items.SearchAttributes.CurrentData;
	
	CurrentData.ComparisonOperator = "";
	CurrentData.Value = "";
	CurrentData.ValueID = "";
	CurrentData.Value2 = "";
	CurrentData.ComparisonOperator2 = "";
	CurrentData.ConditionPresentation = "";
	
	If CurrentData.AttributeType.Count() = 1 Then
		CurrentData.ValueType = CurrentData.AttributeType[0].Value;
	Else
		CurrentData.ValueType = "";
	EndIf;
	
EndProcedure

&AtClient
Procedure SearchAttributesConditionPresentationOnChange(Item)
	
	CurrentData = Items.SearchAttributes.CurrentData;
	If CurrentData.ValueType = "Boolean" Then
		CurrentData.ComparisonOperator = "=";
		CurrentData.Value = CurrentData.ConditionPresentation;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ToSearch(Command)
	
	ExecuteSearch();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Async Procedure ProcessSearchResults()
	
	If NumberOfResults = 0 Then
		ShowMessageBox(,NStr("vi = 'Điều kiện tìm kiếm đã đặt không cho kết quả nào.';
							|ru = 'Заданные условия поиска не дали ни одного результата.';
							|en = 'No files found with the specified search criteria.'; fa = 'No files found with the specified search criteria.';
							|it = 'Le condizioni di ricerca fornite non hanno portato alcun risultato.';
							|pl = 'Zadane warunki wyszukiwania nie dały żadnych wyników.';
							|tr = 'Belirtilen arama şartları herhangi bir sonuç getirmedi.'"));
		
	ElsIf LimitNumberOfResults <> 0 Then
		QuestionParametersYesNo = IntegrationWith1CDocumentManagementCoreClient.QuestionParametersYesNo();
		QuestionParametersYesNo.YesButtonText = StrTemplate(
			NStr("vi = 'Có, hiển thị %1 đầu tiên';
				|ru = 'Да, показать первые %1';
				|en = 'Yes, show first %1'; fa = 'Yes, show first %1';
				|it = 'Да, показать первые %1';
				|pl = 'Tak, pokaż pierwsze %1';
				|tr = 'Evet, önce göster %1'"),
				Format(LimitNumberOfResults, "NG=0"));
		QuestionParametersYesNo.NoButtonText = NStr("vi = 'Không, cần làm rõ điều kiện';
													|ru = 'Нет, уточнить условия';
													|en = 'No, clarify the filters'; fa = 'No, clarify the filters';
													|it = 'Нет, уточнить условия';
													|pl = 'Nie, uściślij warunki';
													|tr = 'Hayır, şartları kesinleştir'");
		Response = Await IntegrationWith1CDocumentManagementCoreClient.ShowQuestionYesNoAsync(
			NStr("vi = 'Điều kiện tìm kiếm đã đặt cho rất nhiều kết quả. Hiển thị kết quả?';
				|ru = 'Заданные условия поиска дали слишком много результатов. Показать результаты?';
				|en = 'Too many search results. Show the results?'; fa = 'Too many search results. Show the results?';
				|it = 'Заданные условия поиска дали слишком много результатов. Показать результаты?';
				|pl = 'Zadane warunki wyszukiwania zwróciły zbyt dużo wyników. Pokazać wyniki?';
				|tr = 'Belirtilen arama şartları çok fazla sonuç getirdi. Sonuçları göster?'"),
			QuestionParametersYesNo);
		If Response = DialogReturnCode.Yes Then
			GoToSearchResults();
		EndIf;
		
	Else
		GoToSearchResults();
		
	EndIf;
	
EndProcedure

&AtServer
Procedure AddSearchDetails(Name, Presentation, Type)
	
	PropsString = SearchAttributes.Add();
	PropsString.Name = Name;
	PropsString.Presentation = Presentation;
	PropsString.AttributeType = Type;
	
	If Type.Count() = 1 Then
		PropsString.ValueType = Type[0].Value;
	EndIf;
	
EndProcedure

// Collects a representation of a search condition from a value and a comparison operator
//
&AtClientAtServerNoContext
Procedure AssembleConditionPresentation(CurrentData)
	
	Type = CurrentData.ValueType;
	Operator = CurrentData.ComparisonOperator;
	Operator2 = CurrentData.ComparisonOperator2;
	Value = CurrentData.Value;
	Value2 = CurrentData.Value2;
	If ValueIsFilled(Operator) Then
		If Type = "String" Then
			If Operator = "=" Then
				Presentation = StrTemplate(NStr("vi = 'bằng ""%1""';
												|ru = 'равно ""%1""';
												|en = 'is ""%1""'; fa = 'is ""%1""';
												|it = 'uguale ""%1""';
												|pl = 'równa się ""%1""';
												|tr = 'eşittir ""%1""'"), Value);
				
			ElsIf Operator = "LIKE" Then
				If Left(Value, 1) = "%" And Right(Value, 1) = "%" Then
					Presentation = StrTemplate(
						NStr("vi = 'có chứa ""%1""';
							|ru = 'содержит ""%1""';
							|en = 'contains ""%1""'; fa = 'contains ""%1""';
							|it = 'contiene ""%1""';
							|pl = 'zawiera ""%1""';
							|tr = '""%1"" içeriyor'"), Mid(Value, 2, StrLen(Value) - 2));
					
				ElsIf Left(Value, 1) = "%" Then
					Presentation = StrTemplate(NStr("vi = 'kết thúc vào ""%1""';
													|ru = 'заканчивается на ""%1""';
													|en = 'ends with ""%1""'; fa = 'ends with ""%1""';
													|it = 'finisce il ""%1""';
													|pl = 'kończy się na ""%1""';
													|tr = '""%1"" ile bitiyor'"), Mid(Value,2));
					
				ElsIf Right(Value, 1) = "%" Then
					Presentation = StrTemplate(
						NStr("vi = 'bắt đầu từ ""%1""';
							|ru = 'начинается с ""%1""';
							|en = 'starts with ""%1""'; fa = 'starts with ""%1""';
							|it = 'inizia il ""%1""';
							|pl = 'zaczyna się od ""%1""';
							|tr = '""%1"" ile başlıyor'"), Left(Value, StrLen(Value) - 1));
					
				EndIf;
			EndIf;
			
		ElsIf Type = "Number" Then
			If Operator = "=" Then
				Presentation = Value;
				
			ElsIf ValueIsFilled(Operator2) Then
				Presentation = StrTemplate(NStr("vi = 'giữa %1 và %2';
												|ru = 'между %1 и %2';
												|en = 'between %1 and %2'; fa = 'between %1 and %2';
												|it = 'tra %1 e %2';
												|pl = 'między %1 i %2';
												|tr = '%1 ile %2 arasında'"), Value, Value2);
				
			ElsIf Operator = "<=" Then
				Presentation = StrTemplate(NStr("vi = 'đến %1';
												|ru = 'по %1';
												|en = 'to %1'; fa = 'to %1';
												|it = 'fino a %1';
												|pl = 'do %1';
												|tr = '%1 göre'"), Value);
				
			ElsIf Operator = ">=" Then
				Presentation = StrTemplate(NStr("vi = 'ngày %1';
												|ru = 'от %1';
												|en = ', %1'; fa = ', %1';
												|it = 'da %1';
												|pl = 'od %1';
												|tr = '%1 itibaren'"), Value);
				
			EndIf;
			
		ElsIf Type = "Date" Then
			If Operator = "=" Then
				If ValueIsFilled(Value) Then
					Presentation = Format(Value, "DLF=D");
				Else
					Presentation = "(" + NStr("vi = 'trống';
												|ru = 'пустая';
												|en = 'empty'; fa = 'empty';
												|it = 'vuota';
												|pl = 'pusty';
												|tr = 'boş'") + ")";
				EndIf;
				
			ElsIf ValueIsFilled(Operator2) Then
				Presentation = StrTemplate(
					NStr("vi = 'giữa %1 và %2';
						|ru = 'между %1 и %2';
						|en = 'between %1 and %2'; fa = 'between %1 and %2';
						|it = 'tra %1 e %2';
						|pl = 'między %1 i %2';
						|tr = '%1 ile %2 arasında'"), Format(Value, "DLF=D"), Format(Value2, "DLF=D"));
				
			ElsIf Operator = "<=" Then
				Presentation = StrTemplate(NStr("vi = 'đến %1';
												|ru = 'по %1';
												|en = 'to %1'; fa = 'to %1';
												|it = 'fino a %1';
												|pl = 'do %1';
												|tr = '%1 göre'"), Format(Value, "DLF=D"));
				
			ElsIf Operator = ">=" Then
				Presentation = StrTemplate(NStr("vi = 'từ %1';
												|ru = 'с %1';
												|en = 'from %1'; fa = 'from %1';
												|it = 'da %1 ';
												|pl = 'od %1';
												|tr = 'itibaren %1'"), Format(Value, "DLF=D"));
				
			EndIf;
			
		Else // It is a reference type or Boolean.
			Presentation = String(Value);
			
		EndIf;
		
	Else // The operator is not specified.
		Presentation = "";
		
	EndIf;
	
	CurrentData.ConditionPresentation = Presentation;
	
EndProcedure

&AtClient
Procedure SearchDetailsPresentationOfConditionCompletionOfSelection(Result, Item) Export
	
	If Result = Undefined Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If Result.Property("AttributeID") Then // Reference type.
		If Result.AttributeType = "DMFileFolder"
				Or Result.AttributeType = "DMDocumentFolder"
				Or Result.AttributeType = "DMMeetingFolder" Then
			CurrentData.ComparisonOperator = "IN HIERARCHY";
		Else
			CurrentData.ComparisonOperator = "=";
		EndIf;
		CurrentData.Value = Result.AttributePresentation;
		CurrentData.ValueID = Result.AttributeID;
		CurrentData.ValueType = Result.AttributeType;
		
	Else // Primitive type.
		CurrentData.Value = Result.Value;
		CurrentData.ValueType = String(TypeOf(Result.Value));
		If Result.Property("ComparisonOperator") Then
			CurrentData.ComparisonOperator = Result.ComparisonOperator;
		EndIf;
		If Result.Property("ComparisonOperator2") Then
			CurrentData.ComparisonOperator2 = Result.ComparisonOperator2;
		EndIf;
		If Result.Property("Value2") Then
			CurrentData.Value2 = Result.Value2;
		EndIf;
		
	EndIf;
	
	AssembleConditionPresentation(CurrentData);
	Item.EndEditRow(True);
	If Result.Property("FindImmediately") And Result.FindImmediately Then
		ExecuteSearch();
	EndIf;
	
EndProcedure

// Packages the selection parameters into a structure intended for transmission to the forms to be opened
//
&AtServer
Function FilterStructure1()
	
	Filter = New Structure;
	For Each SearchDetails In SearchAttributes Do
		If ValueIsFilled(SearchDetails.ComparisonOperator) Then
			Value = New Structure;
			Value.Insert("Presentation", SearchDetails.Presentation);
			Value.Insert("Value", SearchDetails.Value);
			Value.Insert("ValueType", SearchDetails.ValueType);
			Value.Insert("ValueID", SearchDetails.ValueID);
			Value.Insert("ComparisonOperator", SearchDetails.ComparisonOperator);
			If ValueIsFilled(SearchDetails.ComparisonOperator2) Then
				Value.Insert("ComparisonOperator2", SearchDetails.ComparisonOperator2);
				Value.Insert("Value2", SearchDetails.Value2);
			EndIf;
			Value.Insert("ConditionPresentation", SearchDetails.ConditionPresentation);
			Filter.Insert(SearchDetails.Name, Value);
		EndIf;
	EndDo;
	
	Return Filter;
	
EndFunction

&AtClient
Procedure ExecuteSearch()
	
	PerformServerSearch(
		TypeOfSelectionObject,
		AddressInTempStorage,
		NumberOfResults,
		LimitNumberOfResults);
	ProcessSearchResults();
	
EndProcedure

&AtClient
Procedure GoToSearchResults()
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfSelectionObject", TypeOfSelectionObject);
	FormParameters.Insert("Filter", FilterStructure1());
	FormParameters.Insert("AddressInTempStorage", AddressInTempStorage);
	Close();
	OpenForm("DataProcessor.IntegrationWith1CDocumentManagement3.Form.SelectingObjectBySearchResults",
		FormParameters,
		ThisObject,
		New UUID,,,
		CallbackDescriptionOnClose,
		FormWindowOpeningMode.LockWholeInterface);
	
EndProcedure

&AtServer
Procedure PerformServerSearch(TypeOfSelectionObject, AddressInTempStorage, NumberOfResults, LimitNumberOfResults)
	
	DataProcessors.IntegrationWith1CDocumentManagement3.PerformSearchByBankingDetails(
		TypeOfSelectionObject,
		FilterStructure1(),
		AddressInTempStorage,
		NumberOfResults,
		LimitNumberOfResults);
	
EndProcedure

#EndRegion