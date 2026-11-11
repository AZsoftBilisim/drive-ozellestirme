
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	TSName = Parameters.TSName;
	If Parameters.ReadOnly Then
		Items.FormSaveSetting.Enabled = False;
	EndIf;
	
	QuantityCalculationAlgorithm = Parameters.QuantityCalculationAlgorithm;
	AdditionalDataAddress = Parameters.AdditionalDataAddress;
	
	ProductTypeOrProductRange = Parameters.ProductTypeOrProductRange;
	If TypeOf(ProductTypeOrProductRange) = Type("CatalogRef.Products") Then
		TypeOfProducts = Common.ObjectAttributeValue(ProductTypeOrProductRange, "ProductKind");
	Else
		TypeOfProducts = ProductTypeOrProductRange;
	EndIf;
	
	If Not ValueIsFilled(TypeOfProducts) Then
		InformationBar = NStr("vi = 'Chưa xác định dạng mặt hàng sản phẩm, thuộc tính sẽ được phép để chọn.';
								|ru = 'Не задан вид номенклатуры изделия, свойства будут недоступны для выбора.';
								|en = 'The item kind is not set, the properties will not be available for selection.'; fa = 'The item kind is not set, the properties will not be available for selection.';
								|it = 'Не задан вид номенклатуры изделия, свойства будут недоступны для выбора.';
								|pl = 'The item kind is not set, the properties will not be available for selection.';
								|tr = 'Nihai ürünün ürün türü belirtilmedi, özellikler seçim için mevcut olmayacaktır.'");
	ElsIf Not Parameters.Property("InformationBar", InformationBar) Then
		Items.InformationPanelGroup.Visible = False;
	EndIf;
	
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	If UseAdditionalAttributesAndInfo Then
		
		FillInListOfSelectionsByProperties();
		
	EndIf;
	
	SetVisibilityAccessibilityBySettingsComposition();
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	Notification = New CallbackDescription("WriteAndCloseOnClient", ThisObject);
	CommonClient.ShowFormClosingConfirmation(Notification, Cancel, Exit);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSelectionByProperties

&AtClient
Procedure SelectionOfPropertiesPropertyIsWhenYouChange(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionOfPropertiesPropertyIsWhenYouChange(
		ThisObject,
		CurrentData,
		TableOfAvailableProductCharacteristics,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure TheSelectionOfThePropertiesSubjectToChange(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.TheSelectionOfThePropertiesSubjectToChange(
		ThisObject,
		CurrentData,
		TableOfAvailableProductCharacteristics,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionByPropertiesValueIntervalWhenChanging(Item)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionByPropertiesValueIntervalWhenChanging(
		CurrentData,
		Item.Name);
		
EndProcedure

&AtClient
Procedure SelectionByPropertiesBeforeRowChange(Item, Cancel)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionByPropertiesBeforeRowChange(
		ThisObject,
		CurrentData,
		TableOfAvailableProductCharacteristics,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(Item, ChoiceData, StandardProcessing)
	
	CurrentData = Items.SelectionByProperties.CurrentData;
	
	ProductDataManagementClient.SelectionOfPropertiesTheConditionOfTheBeginningOfTheSelection(
		ThisObject,
		CurrentData,
		TableOfAvailableProductCharacteristics,
		ConditionsStructure);
		
EndProcedure

&AtClient
Procedure SelectionByPropertiesConditionCleaning(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure SelectionByPropertiesBeforeAddRow(Item, Cancel, Copy, Parent, Var_Group, Parameter)
	If Copy Then
		Cancel = True;
	EndIf;
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSetting(Command)
	
	WriteAndCloseOnClient(Undefined, Undefined);
	
EndProcedure

&AtClient
Procedure EnterFormula(Command)
	
	FormParameters = FormulaEditingFormParameters(QuantityCalculationAlgorithm);
	
	CallbackDescription = New CallbackDescription("HandlingFormulaInput", ThisObject);
	
	OpenForm("CommonForm.FormulasConstructor",
		FormParameters,
		,
		,
		,
		,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure ClearFormula(Command)
	
	QuantityCalculationAlgorithm = "";
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SelectionByProperties.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("UseAdditionalAttributesAndInfo");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	ProductDataManagement.SetConditionalAppearanceOfSelectionTableByProperties(ConditionalAppearance);
	
EndProcedure

&AtServer
Procedure SetVisibilityAccessibilityBySettingsComposition()
	
	Var CompositionOfSettings;
	
	If Parameters.Property("CompositionOfSettings") Then
		CompositionOfSettings = Parameters.CompositionOfSettings;
	EndIf;
	
	Items.GroupSelectionByProperties.Visible =(
			CompositionOfSettings = Undefined Or CompositionOfSettings.Property("SelectionByProperties")
		) And UseAdditionalAttributesAndInfo;
	
	Items.GroupQuantityCalculationAlgorithm.Enabled = (
			CompositionOfSettings = Undefined Or CompositionOfSettings.Property("QuantityCalculationAlgorithm"));

EndProcedure

&AtServer
Function ConstructTreeOfOperands()
	
	Tree = ProcessingOfFormulas.GetEmptyOperandTree();
	
	If IsTempStorageURL(AdditionalDataAddress) Then
		
		StructureOfData = GetFromTempStorage(AdditionalDataAddress);
		
		TypesOfOperandTreeElements = ProcessingOfFormulas.TypesOfOperandTreeElements();
		
		For Each KeyAndValue In StructureOfData Do
			
			Source = KeyAndValue.Value; // See ProductDataManagement.CreateDescriptionsOfOperandDataSource
			
			Operands = Undefined; // See ProductDataManagement.DataSourceOperandTableConstructor
			If Source.Property("Operands", Operands) And Operands.Count() > 0 Then
				
				OperandGroup = ProcessingOfFormulas.NewLineOfOperandTree(Tree);
				OperandGroup.Id = Source.Id;
				OperandGroup.Presentation = Source.Presentation;
				OperandGroup.TreeItemType = TypesOfOperandTreeElements.TopLevelRowGroup;
				OperandGroup.OperandSelectionAllowed = False;
				OperandGroup.IncludedInID = False;
				
				For Each Operand In Operands Do
					
					OperandString_ = ProcessingOfFormulas.NewLineOfOperandTree(OperandGroup);
					OperandString_.Id = Operand.Id;
					OperandString_.Presentation = Operand.Presentation;
					OperandString_.ValueType = Operand.ValueType;
					OperandString_.OperandSelectionAllowed = True;
					OperandString_.IncludedInID = True;
					OperandString_.TreeItemType = Operand.OperandType_;
					
				EndDo;
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return PutToTempStorage(Tree, UUID);
	
EndFunction

&AtServer
Function FormulaEditingFormParameters(Formula)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("UsesOperandTree", True);
	
	FormParameters.Insert("Formula",   Formula);
	FormParameters.Insert("OperandsTree", ConstructTreeOfOperands());
	
	OperatorsTree = ProductDataManagement.BuildTreeOfOperators();
	FormParameters.Insert("Operators", PutToTempStorage(OperatorsTree, UUID));
	
	FormParameters.Insert("OperandsTitle", NStr("vi = 'Mục tin khả dụng';
												|ru = 'Доступные реквизиты';
												|en = 'Available attributes'; fa = 'ویژگی‌های در دسترس';
												|it = 'Requisiti disponibili';
												|pl = 'Dostępne atrybuty';
												|tr = 'Kullanılabilir öznitelikler'"));
	FormParameters.Insert("NotUsePresentation", True);

	FormParameters.Insert("FunctionsFromCommonModule", ProductDataManagementCached.DescriptionOfFormulaConstructorFunctions());
	
	FormParameters.Insert("ResultType", New TypeDescription("Number"));
	
	Return FormParameters;
	
EndFunction

&AtClient
Procedure HandlingFormulaInput(ClosingResult, AdditionalParameters) Export

	If ClosingResult <> Undefined Then
		QuantityCalculationAlgorithm = ClosingResult;
	EndIf;
	
EndProcedure

&AtClient
Procedure WriteAndCloseOnClient(Result, AdditionalParameters) Export 
	
	ClearMessages();
	
	HasErrors = False;
	SelectionByPropertiesForCurRow = Undefined;
	FormParameters = New Structure;
	
	SelectionByPropertiesForCurRow = ProductDataManagementClient.SelectionByPropertiesPerformControlGenerateResultOfSetting(
		SelectionByProperties,
		TableOfAvailableProductCharacteristics,
		HasErrors);
	
	If HasErrors Then
		Return;
	EndIf;
	
	FormParameters.Insert("SelectionByProperties", SelectionByPropertiesForCurRow);
	FormParameters.Insert("QuantityCalculationAlgorithm", QuantityCalculationAlgorithm);
	
	Modified = False;
	
	NotifyChoice(FormParameters);
	
EndProcedure

&AtServer
Procedure FillInListOfSelectionsByProperties()
	
	ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
	
	ListOfProductProperties = ProductDataManagement.GetPropertiesToSelectByProperties(TypeOfProducts);
	
	For Each DataProperty In ListOfProductProperties Do
		FillPropertyValues(TableOfAvailableProductCharacteristics.Add(), DataProperty);
		Items.Property.ChoiceList.Add(DataProperty.Property, DataProperty.Presentation);
	EndDo;
	
	Items.Property.ChoiceList.SortByPresentation();
	
	ProductDataManagement.FillInListOfSelectionsByProperties(SelectionByProperties, Parameters.SelectionByProperties);
	
	Return; // empty handler
	
EndProcedure

#EndRegion
