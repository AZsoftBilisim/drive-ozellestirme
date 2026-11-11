
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.ReadOnly Then
		Items.FormSaveSetting.Enabled = False;
	EndIf;
	
	FunctionDescription = ProductDataManagementCached.DescriptionOfAutoSelectionFunctionsForProductItemPropertyValue();
		
	// Let's add product properties that can be matched
	MaterialProperties = ProductDataManagement.GetPropertiesForAutoSelection(Parameters.MaterialKind, True);
	ProductProperties = ProductDataManagement.GetPropertiesForAutoSelection(Parameters.TypeOfProducts);
	For Each GivenMaterialProperties In MaterialProperties Do
		
		If GivenMaterialProperties.DeletionMark Then
			Continue;
		EndIf;
		
		NewRow = PropertyMapping.Add();
		NewRow.MaterialProperty = GivenMaterialProperties.Property;
		NewRow.MaterialPropertyPresentation = GivenMaterialProperties.Presentation;
		
		// Properties can be matched if
		// - the properties are the same
		// - the properties are different, but a common list of values
		// - is used - the property type is primitive (number, string, boolean, date).
		For Each TheseProductProperties In ProductProperties Do
			
			If TheseProductProperties.DeletionMark Then
				Continue;
			EndIf;
			
			If (TheseProductProperties.Property = GivenMaterialProperties.Property
				
					Or TheseProductProperties.AdditionalValuesOwner = GivenMaterialProperties.Property
					
					Or TheseProductProperties.Property = GivenMaterialProperties.AdditionalValuesOwner
					
					Or TheseProductProperties.AdditionalValuesOwner = GivenMaterialProperties.AdditionalValuesOwner
						And ValueIsFilled(TheseProductProperties.AdditionalValuesOwner)
						
					Or GivenMaterialProperties.ValueType = TheseProductProperties.ValueType
						And Not GivenMaterialProperties.Property.ValueType.ContainsType(Type("CatalogRef.ObjectsPropertiesValues"))
						
				) Then
				
				NewRow.ListOfAvailableProperties.Add(TheseProductProperties.Property, TheseProductProperties.Presentation);
				
			EndIf;
			
		EndDo;
		
		NewRow.ThereAreAvailablePropertiesToSelect = (NewRow.ListOfAvailableProperties.Count() <> 0);
		
		NewRow.AllowsCalculationUsingFormula = GivenMaterialProperties.Property.ValueType.ContainsType(Type("Number"))
			Or GivenMaterialProperties.Property.ValueType.ContainsType(Type("String"))
			Or GivenMaterialProperties.Property.ValueType.ContainsType(Type("Boolean"));
			
		// Adding value matching functions by algorithm
		If FunctionDescription.Count() Then
			For Each LongDesc In FunctionDescription Do // See ProductDataManagement.CreateDescriptionOfAutoselectFunction
				
				If Not TypeOf(LongDesc) = Type("Structure") Or Not LongDesc.Property("FunctionName") Then
					Continue;
				EndIf;
				
				PropertyName = "";
				If LongDesc.Parameters.Property("PropertyName", PropertyName) And PropertyName <> GivenMaterialProperties.Name Then
					Continue;
				EndIf;
				
				If LongDesc.ReturnValue <> Undefined Then
					For Each Type In LongDesc.ReturnValue.Types() Do
						AddFunction = GivenMaterialProperties.Property.ValueType.ContainsType(Type);
						If AddFunction Then
							Break;
						EndIf;
					EndDo;
					If Not AddFunction Then
						Continue;
					EndIf;
				EndIf;
				
				NewRow.AvailableFunctionsList.Add(LongDesc.FunctionName, LongDesc.Presentation);
				
			EndDo;
			NewRow.AvailableFunctionsList.SortByPresentation();
			NewRow.ThereAreAvailableFunctionsThatCanBeSelected = (NewRow.AvailableFunctionsList.Count() <> 0);
		EndIf;
			
	EndDo;
	
	// Fill in the matching properties
	For Each CurrentData In PropertyMapping Do
		
		TheStructureOfTheSearch = New Structure("MaterialProperty", CurrentData.MaterialProperty);
		StringsList = Parameters.PropertyMapping.FindRows(TheStructureOfTheSearch);
		
		CurrentData.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.AnyValue;
		
		If StringsList.Count() <> 0 Then
			
			ConfiguringCompliance = StringsList[0];
			
			CurrentData.ValueSelectionMethod = ConfiguringCompliance.ValueSelectionMethod;
			
			If CurrentData.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByProperty Then
				
				ElProductionProperty = CurrentData.ListOfAvailableProperties.FindByValue(ConfiguringCompliance.ProductsProperty);
				If ElProductionProperty <> Undefined Then
					
					CurrentData.ProductsProperty              = ConfiguringCompliance.ProductsProperty;
					CurrentData.ProductsPropertyPresentation = ElProductionProperty.Presentation;
					
				EndIf;
				
			ElsIf CurrentData.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByValue Then
				
				CurrentData.PropertyValue = ConfiguringCompliance.PropertyValue;
				
			ElsIf CurrentData.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByFormula Then
				
				CurrentData.ValueCalculationAlgorithm = ConfiguringCompliance.ValueCalculationAlgorithm;
				
			ElsIf CurrentData.ValueSelectionMethod = Enums.MethodsOfSelectingProductPropertyValue.ByAlgorithm Then
				
				ListOfFunctions = CurrentData.AvailableFunctionsList.FindByValue(ConfiguringCompliance.ValueCalculationAlgorithm);
				If ListOfFunctions <> Undefined Then
					
					CurrentData.ValueCalculationAlgorithm              = ConfiguringCompliance.ValueCalculationAlgorithm;
					CurrentData.ValueCalculationAlgorithmPresentation = ListOfFunctions.Presentation;
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	GenerateDataForMatchingUsingFormula(ProductProperties);
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, StandardProcessing)
	
	If Modified Then
		StandardProcessing = False;
		Cancel = True;
		QueryText = NStr("vi = 'Dữ liệu đã thay đổi. Lưu lại thay đổi?';
						|ru = 'Данные были изменены. Сохранить изменения?';
						|en = 'Data has changed. Save the changes?'; fa = 'Data has changed. Save the changes?';
						|it = 'I dati sono stati modificati. Salvare le modifiche?';
						|pl = 'Dane zostały zmienione. Chcesz zapisać zmiany?';
						|tr = 'Veriler değiştirildi. Değişiklikler kaydedilsin mi?'");
		CallbackDescription = New CallbackDescription("BeforeCloseCompletion", ThisObject);
		ShowQueryBox(CallbackDescription, QueryText, QuestionDialogMode.YesNoCancel);
	EndIf; 
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersPropertyMapping

&AtClient
Procedure PropertyMatchingMethodOfDeterminingWhenChanging(Item)
	
	CurrentData = Items.PropertyMapping.CurrentData;
	ClearMatchInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure PropertyMatchingProductPropertyStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PropertyMapping.CurrentData;
	
	If CurrentData.ThereAreAvailablePropertiesToSelect Then
		
		CallbackDescription = New CallbackDescription("ProductPropertyStartSelectionEnd", ThisObject);
		ShowChooseFromList(CallbackDescription, CurrentData.ListOfAvailableProperties, Item);
	
	EndIf;
	
EndProcedure

&AtClient
Procedure PropertyMatchingValueOrProductPropertyCleaning(Item, StandardProcessing)
	
	CurrentData = Items.PropertyMapping.CurrentData;
	ClearMatchInRow(CurrentData);
	
EndProcedure

&AtClient
Procedure PropertyMatchingMethodOfDefinitionStartOfSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.PropertyMapping.CurrentData;
	
	ChoiceList = Items.PropertyMappingValueSelectionMethod.ChoiceList;
	ChoiceList.Clear();
	
	ChoiceList.Add(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByProperty"), NStr("vi = 'theo tính chất';
																									|ru = 'по свойству';
																									|en = 'by property'; fa = 'by property';
																									|it = 'per proprietà';
																									|pl = 'według właściwości';
																									|tr = 'özelliğe göre'"));
	ChoiceList.Add(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByValue"), NStr("vi = 'theo giá trị';
																								|ru = 'по значению';
																								|en = 'by value'; fa = 'by value';
																								|it = 'per valore';
																								|pl = 'wg wartości';
																								|tr = 'değere göre'"));
	
	If CurrentData.AllowsCalculationUsingFormula Then
		ChoiceList.Add(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByFormula"), NStr("vi = 'theo công thức';
																										|ru = 'по формуле';
																										|en = 'by formula'; fa = 'by formula';
																										|it = 'secondo la formula';
																										|pl = 'wg formuły';
																										|tr = 'formüle göre'"));
	EndIf;
	
	ChoiceList.Add(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByAlgorithm"), NStr("vi = 'theo thuật toán';
																									|ru = 'по алгоритму';
																									|en = 'by algorithm'; fa = 'by algorithm';
																									|it = 'per algoritmo';
																									|pl = 'według algorytmu';
																									|tr = 'algoritmaya göre'"));
	ChoiceList.Add(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.AnyValue"), NStr("vi = 'giá trị bất kỳ';
																								|ru = 'любое значение';
																								|en = 'any value'; fa = 'any value';
																								|it = 'qualsiasi valore';
																								|pl = 'dowolna wartość';
																								|tr = 'herhangi bir değer'"));
	
EndProcedure

&AtClient
Procedure PropertyMappingValueCalculationAlgorithmStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PropertyMapping.CurrentData;
	
	FormParameters = FormulaEditingFormParameters(CurrentData.ValueCalculationAlgorithm);
	
	CallbackDescription = New CallbackDescription("AlgorithmForCalculatingValueStartSelectionEnd", ThisObject);
	
	OpenForm("CommonForm.FormulasConstructor", 
		FormParameters, 
		ThisForm,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure
	
&AtClient
Procedure PropertyMatchingValueCalculationFunctionStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	CurrentData = Items.PropertyMapping.CurrentData;
	
	If CurrentData.ThereAreAvailableFunctionsThatCanBeSelected Then
		
		CallbackDescription = New CallbackDescription("ValueCalculationFunctionStartSelectionEnd", ThisObject);
		ShowChooseFromList(CallbackDescription, CurrentData.AvailableFunctionsList, Item);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure OkCommand(Command)
	
	CompleteEditing();
	
EndProcedure

&AtClient
Procedure FillInMap(Command)
	
	For Each CurrentData In PropertyMapping Do
		
		If CurrentData.ListOfAvailableProperties.Count() = 1
			And CurrentData.ValueSelectionMethod = PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.AnyValue") Then
			
			CurrentData.ValueSelectionMethod          = PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByProperty");
			CurrentData.ProductsProperty              = CurrentData.ListOfAvailableProperties[0].Value;
			CurrentData.ProductsPropertyPresentation = CurrentData.ListOfAvailableProperties[0].Presentation;
			
			Modified = True;
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region DataForFormulaConstructor

&AtServer
Function FormulaEditingFormParameters(Formula)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Formula", Formula);
	FormParameters.Insert("OperandsTree", AddressOfOperandTreeStorage);
	FormParameters.Insert("Operators", OperatorsTreeStorageAddress);
	FormParameters.Insert("UsesOperandTree", True);
	FormParameters.Insert("FunctionsFromCommonModule", ProductDataManagementCached.DescriptionOfFormulaConstructorFunctions());
	FormParameters.Insert("ResultType", New TypeDescription("Number"));
	
	Return FormParameters;
	
EndFunction

&AtServer
Procedure GenerateDataForMatchingUsingFormula(ProductProperties)
	
	OperandsTree = ProcessingOfFormulas.GetEmptyOperandTree();
	TypesOfTreeElements = ProcessingOfFormulas.TypesOfOperandTreeElements();
	
	GroupProducts_2 = ProcessingOfFormulas.NewLineOfOperandTree(OperandsTree);
	GroupProducts_2.Id = "ProductProperties";
	GroupProducts_2.Presentation = NStr("vi = 'Đặc tính sản phẩm';
										|ru = 'Свойства продукции';
										|en = 'Product properties'; fa = 'Product properties';
										|it = 'Proprietà della produzione';
										|pl = 'Właściwość produkcji';
										|tr = 'İmal edilen ürün özellikleri'");
	GroupProducts_2.TreeItemType = TypesOfTreeElements.TopLevelRowGroup;
	GroupProducts_2.OperandSelectionAllowed = False;
	GroupProducts_2.IncludedInID = False;
	
	For Each Property In ProductProperties Do
		If Property.ValueType.ContainsType(Type("Number")) 
			Or Property.ValueType.ContainsType(Type("String")) 
			Or Property.ValueType.ContainsType(Type("Boolean")) Then
			OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(GroupProducts_2);
			OperandString_.Id = Property.Id;
			OperandString_.Presentation = Property.Presentation;
			OperandString_.ValueType = Property.ValueType;
			OperandString_.TreeItemType = TypesOfTreeElements.AdditionalAttribute;
		EndIf;
	EndDo;
	
	AddressOfOperandTreeStorage = PutToTempStorage(OperandsTree, UUID);
	
	OperatorsTree = ProductDataManagement.BuildTreeOfOperators();
	OperatorsTreeStorageAddress = PutToTempStorage(OperatorsTree, UUID);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()
	
	// Visibility of the <Product Properties> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMatchingProductProperty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotInList;
	
	ListOfMethodsForDetermining = New ValueList;
	ListOfMethodsForDetermining.Add(Enums.MethodsOfSelectingProductPropertyValue.ByProperty);
	ListOfMethodsForDetermining.Add(Enums.MethodsOfSelectingProductPropertyValue.AnyValue);
	
	ItemFilter.RightValue = ListOfMethodsForDetermining;

	Item.Appearance.SetParameterValue("Visible", False);
	
	// Visibility of the <Property Value> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMappingPropertyValue.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.ByValue;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Field visibility <Assignment Calculation algorithm (by formula)>
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMappingValueCalculationAlgorithm.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.ByFormula;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Visibility of the <Algorithm Assignment Calculation (by algorithm)> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMatchingValueCalculationFunction.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.ByAlgorithm;
	
	Item.Appearance.SetParameterValue("Visible", False);
	
	// Availability of the <Product Properties> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMatchingProductProperty.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.AnyValue;

	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	// Making an empty selection list of the <Product Properties> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMatchingProductProperty.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ThereAreAvailablePropertiesToSelect");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.ByProperty;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có thuộc tính có sẵn để lựa chọn>';
													|ru = '<нет свойств доступных для выбора>';
													|en = '<no properties to select>'; fa = '<no properties to select>';
													|it = '<non ci sono proprietà disponibili per la scelta>';
													|pl = '<brak właściwości dostępnych do wyboru>';
													|tr = '<seçim için mevcut özellik yok>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Making an empty list of the selection of the <Assignment Function> field
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyMatchingValueCalculationFunction.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ThereAreAvailableFunctionsThatCanBeSelected");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.MethodsOfSelectingProductPropertyValue.ByAlgorithm;

	Item.Appearance.SetParameterValue("Text", NStr("vi = '<không có thuật toán có sẵn để lựa chọn>';
													|ru = '<нет алгоритмов доступных для выбора>';
													|en = '<no algorithm to select>'; fa = '<no algorithm to select>';
													|it = '<non ci sono algoritmi disponibili per la scelta>';
													|pl = '<brak algorytmów dostępnych do wyboru>';
													|tr = '<seçim için mevcut algoritma yok>'"));
	Item.Appearance.SetParameterValue("ReadOnly", True);
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Design of the <Method of definition> field
	For Each ValueSelectionMethod In Enums.MethodsOfSelectingProductPropertyValue Do
		
		Item = ConditionalAppearance.Items.Add();
		
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(Items.PropertyMappingValueSelectionMethod.Name);
		
		ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
		ItemFilter.LeftValue = New DataCompositionField("PropertyMapping.ValueSelectionMethod");
		ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
		ItemFilter.RightValue = ValueSelectionMethod;
		
		Item.Appearance.SetParameterValue("Text", Lower(ValueSelectionMethod));
		Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
		
	EndDo;
	
EndProcedure

&AtClient
Procedure ClearMatchInRow(CurrentData)
	
	CurrentData.ProductsProperty = Undefined;
	CurrentData.ProductsPropertyPresentation = Undefined;
	CurrentData.PropertyValue = Undefined;
	CurrentData.ValueCalculationAlgorithm = "";

EndProcedure

&AtClient
Procedure ProductPropertyStartSelectionEnd(SelectedElement, AdditionalParameters) Export

	If SelectedElement <> Undefined Then
		
		CurrentData = Items.PropertyMapping.CurrentData;
		
		CurrentData.ProductsProperty              = SelectedElement.Value;
		CurrentData.ProductsPropertyPresentation = SelectedElement.Presentation;
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure AlgorithmForCalculatingValueStartSelectionEnd(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		CurrentData = Items.PropertyMapping.CurrentData;
		
		CurrentData.ValueCalculationAlgorithm = TrimAll(ClosingResult);
		
		Modified = True;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ValueCalculationFunctionStartSelectionEnd(ClosingResult, AdditionalParameters) Export
	
	If ClosingResult <> Undefined Then
		
		CurrentData = Items.PropertyMapping.CurrentData;
		
		CurrentData.ValueCalculationAlgorithm              = ClosingResult.Value;
		CurrentData.ValueCalculationAlgorithmPresentation = ClosingResult.Presentation;
		
		Modified = True;
		
	EndIf;
	
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
	
	FillVerificationFields = New Map;
	FillVerificationFields.Insert(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByProperty"),
		"ProductsPropertyPresentation");
	FillVerificationFields.Insert(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByFormula"),
		"ValueCalculationAlgorithm");
	FillVerificationFields.Insert(PredefinedValue("Enum.MethodsOfSelectingProductPropertyValue.ByAlgorithm"),
		"ValueCalculationAlgorithmPresentation");
	
	MessageTemplate = NStr("vi = 'Bạn phải điền giá trị cài đặt tuân thủ vào dòng %1';
							|ru = 'Необходимо заполнить значение настройки соответствия в строке %1';
							|en = 'Fill in setting value in line %1'; fa = 'Fill in setting value in line %1';
							|it = 'È necessario compilare il valore dell''impostazione di correlazione nella riga %1';
							|pl = 'Należy wypełnić wartość ustawienia zgodności w wierszu %1';
							|tr = '%1 satırdaki eşleşme ayarı değerini doldurmanız gerekmektedir'");
	
	Result = New Array;
	For Each String_Matching In PropertyMapping Do
		
		FieldToCheck = FillVerificationFields[String_Matching.ValueSelectionMethod];
		If FieldToCheck <> Undefined And Not ValueIsFilled(String_Matching[FieldToCheck]) Then
			RowIndex = PropertyMapping.IndexOf(String_Matching);
			CommonClientServer.MessageToUser(
				StrTemplate(MessageTemplate, RowIndex+1),,
				"PropertyMapping["+RowIndex+"]."+FieldToCheck,,Cancel);
		EndIf;
		
		ConfiguringCompliance = New Structure(ProductDataManagementClientServer.DetailsSettingUpPropertyMatching());
		FillPropertyValues(ConfiguringCompliance, String_Matching);
		Result.Add(ConfiguringCompliance);
		
	EndDo;
	
	If Cancel Then
		Return;
	EndIf;
	
	Modified = False;
	
	Close(Result);

EndProcedure

#EndRegion

#EndRegion
