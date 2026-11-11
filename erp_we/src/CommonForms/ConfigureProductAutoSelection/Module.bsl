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
	
	Products = Parameters.Products;
	If Not Products.IsEmpty() Then
		Items.PagesProducts.CurrentPage = Items.PageProductsAreSelected;
		MaterialDetails = Common.ObjectAttributesValues(Products, "ItemsType,ProductKind,UseVariants");
		MaterialKind = MaterialDetails.ProductKind;
		ProductsHaveCharacteristics = (MaterialDetails.UseVariants 
											<> Enums.ItemVariantsUsageOptions.DontUse);
		ItemsType = MaterialDetails.ItemsType;
	Else
		Items.PagesProducts.CurrentPage = Items.PageProductsAreNotSelected;
		ProductsHaveCharacteristics = False;
	EndIf;
	
	Characteristic = Parameters.Characteristic;
	If Not Characteristic.IsEmpty() Then
		Items.PagesCharacteristic.CurrentPage = Items.PageCharacteristicIsSelected;
	Else
		Items.PagesCharacteristic.CurrentPage = Items.PageCharacteristicIsNotSelected;
	EndIf;
	
	// Current setting
	MethodOfProductsAutoselection   = Parameters.MethodOfProductsAutoselection;
	MethodOfItemVariantAutoselection = Parameters.MethodOfItemVariantAutoselection;
	PropertyThatContainsProducts = Parameters.PropertyThatContainsProducts;
	
	ItemVariantAutoSelectionAlgorithm = Parameters.ItemVariantAutoSelectionAlgorithm;
	FunctionDescriptions = ProductDataManagementCached.DescriptionOfAutoSelectFeatureFunctions();
	For Each FunctionDescription_ In FunctionDescriptions Do
		If Not TypeOf(FunctionDescription_) = Type("Structure") Or Not FunctionDescription_.Property("FunctionName") Then
			Continue;
		EndIf;
		Items.ItemVariantAutoSelectionAlgorithm.ChoiceList.Add(FunctionDescription_.FunctionName, FunctionDescription_.Presentation);
	EndDo;
	If Items.ItemVariantAutoSelectionAlgorithm.ChoiceList.Count() Then
		Items.ItemVariantAutoSelectionAlgorithm.ChoiceList.SortByPresentation();
	Else
		Items.ItemVariantAutoSelectionAlgorithm.InputHint = NStr("vi = '<không có thuật toán có sẵn để lựa chọn>';
																|ru = '<нет алгоритмов доступных для выбора>';
																|en = '<no algorithm to select>'; fa = '<no algorithm to select>';
																|it = '<non ci sono algoritmi disponibili per la scelta>';
																|pl = '<brak algorytmów dostępnych do wyboru>';
																|tr = '<seçim için mevcut algoritma yok>'");
	EndIf;
	
	If Parameters.LongDesc = Undefined Then
		Items.LongDesc.ReadOnly = True;
	Else
		LongDesc = Parameters.LongDesc;
	EndIf;
	
	For Each ConfiguringCompliance In Parameters.PropertyMapping Do
		FillPropertyValues(PropertyMapping.Add(), ConfiguringCompliance);
	EndDo; 
	
	// Let's define the type of products that contains the available properties
	ProductTypeOrProductRange = Parameters.ProductTypeOrProductRange;
	If TypeOf(ProductTypeOrProductRange) = Type("CatalogRef.Products") Then
		TypeOfProducts = Common.ObjectAttributeValue(ProductTypeOrProductRange, "ProductKind");
	Else
		TypeOfProducts = ProductTypeOrProductRange;
	EndIf;
	
	If Not ValueIsFilled(TypeOfProducts) Then
		InformationBar = NStr("vi = 'Loại mặt hàng không được đặt, các thuộc tính sẽ không có sẵn để lựa chọn.';
								|ru = 'Не задан вид номенклатуры, свойства будут недоступны для выбора.';
								|en = 'The item kind is not set, the properties will not be available for selection.'; fa = 'The item kind is not set, the properties will not be available for selection.';
								|it = 'Il tipo di articolo non è stato impostato, le proprietà non saranno disponibili per la selezione.';
								|pl = 'Nie zadano rodzaju pozycji, właściwości będą niedostępne do wyboru.';
								|tr = 'Ürün türü belirtilmedi, özellikler seçim için mevcut olmayacaktır.'");
	ElsIf Not Parameters.Property("InformationBar", InformationBar) Then
		Items.InformationPanelGroup.Visible = False;
	EndIf;
	
	ListOfAllAvailableProperties.Load(ProductDataManagement.GetPropertiesForAutoSelection(TypeOfProducts));
	
	FillInSelectionOfPropertyContainingProductItem();
	
	// Let's set the representation of the selection method, depending on the context of the setting (specification or operation).
	SelectionValue = Items.TheMaterialIsSpecifiedByVNSI.ChoiceList.FindByValue(Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData);
	SelectionValue.Presentation = Parameters.PropertyNameIsSpecifiedByVNSI;
	
	SelectionValue = Items.CharacteristicIsSpecifiedInMasterData.ChoiceList.FindByValue(Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData);
	SelectionValue.Presentation = Parameters.PropertyNameIsSpecifiedByVNSI;
	
	// Disable the visibility of the elements associated with the characteristics if the characteristics are not used
	UseItemVariants = GetFunctionalOption("UseItemVariants");
	UseAdditionalAttributesAndInfo = GetFunctionalOption("UseAdditionalAttributesAndInfo");
	
	// Elements related to the "Material is specified in the product characteristics property" setting
	If Not UseAdditionalAttributesAndInfo Then
		Items.TheGroupIsSetInTheProductProperty.Visible = False;
	EndIf; 
	
	If Not UseItemVariants Then
		Items.GroupHowTheCharacteristicIsDefined.Visible = False;
	EndIf;
	
	// Elements related to the "Determined by product properties" setting
	If Not UseItemVariants Or Not UseAdditionalAttributesAndInfo Then
		Items.TheBandCharacteristicSelectedAccordingToThePropertiesOfTheProducts.Visible = False;
	EndIf; 
	
	If Not UseItemVariants Then
		Items.ExplanationCharacteristics.Visible = False;
		Items.ExplanationCharacteristicIsSelectedByProductProperties.Visible = False;
		Items.ExplanationThereIsNoCharacteristics.Visible = False;
		Items.ExplanationCharacteristicIsSpecifiedDuringProduction.Visible = False;
		Items.DecorationPropertyMatchingSettingIsEmpty.Visible = False;
	EndIf;
	
	TSName = Parameters.TSName;
	
	PropertyThatContainsProductsHeader = PropertyThatContainsProductsHeader(PropertyThatContainsProducts);
	
	AvailabilityControl(ThisForm);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region HowMaterialIsDetermined

&AtClient
Procedure TheMaterialIsSpecifiedByVNSIOnChange(Item)
	
	WhenYouChangeAutoSelectionOfProducts(ThisForm);
	
EndProcedure

&AtClient
Procedure IsDefinedByThePropertyOfProductsAvailableOnChange(Item)
	
	WhenYouChangeAutoSelectionOfProducts(ThisForm);
	
EndProcedure

&AtClient
Procedure SpecifiedInProductionProcessOnChange(Item)
	
	WhenYouChangeAutoSelectionOfProducts(ThisForm);
	
EndProcedure

&AtClient
Procedure PropertyThatContainsProductsOnChange(Item)
	
	PropertyThatContainsProductsHeader = PropertyThatContainsProductsHeader(PropertyThatContainsProducts);
	
EndProcedure

#EndRegion

#Region HowIsMaterialCharacteristicDetermined

&AtClient
Procedure CharacteristicIsSpecifiedInMasterDataOnChange(Item)
	
	WhenAutoSelectingCharacteristicChanges(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectedAccordingToThePropertiesOfProductsAvailableOnChange(Item)
	
	WhenAutoSelectingCharacteristicChanges(ThisForm);
	
EndProcedure

&AtClient
Procedure SelectedByTheAlgorithmAvailableOnChange(Item)
	
	WhenAutoSelectingCharacteristicChanges(ThisForm);
	
EndProcedure

#EndRegion

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SaveSetupCommand(Command)
	
	If Not CheckAttributesFilling() Then
		Return;
	EndIf;
	
	Result = New Structure;
	Result.Insert("Products");
	Result.Insert("ProductsAsAString");
	Result.Insert("Characteristic");
	Result.Insert("CharacteristicAsAString");
	Result.Insert("MethodOfProductsAutoselection", MethodOfProductsAutoselection);
	Result.Insert("MethodOfItemVariantAutoselection", MethodOfItemVariantAutoselection);
	Result.Insert("PropertyThatContainsProducts");
	Result.Insert("ItemVariantAutoSelectionAlgorithm");
	Result.Insert("PropertyMapping");
	Result.Insert("LongDesc", LongDesc);
	
	If MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
		Result.Products = Products;
	ElsIf MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty") Then
		Result.PropertyThatContainsProducts = PropertyThatContainsProducts;
	EndIf;
	
	If MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData") Then
		Result.Characteristic = Characteristic;
	ElsIf MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties")
			And MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
		Result.PropertyMapping = PropertyMapping;
	ElsIf MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm") Then
		Result.ItemVariantAutoSelectionAlgorithm = ItemVariantAutoSelectionAlgorithm;
	EndIf;
	
	Appearance = ProductDataManagementClientServer.DesignTextsForAutoSelectionMethods();
	
	Result.ProductsAsAString   = StringFunctionsClientServer.SubstituteParametersToString(
											Appearance.Get(MethodOfProductsAutoselection),
											PropertyThatContainsProductsHeader);
	Result.CharacteristicAsAString = Appearance.Get(MethodOfItemVariantAutoselection);
	
	NotifyChoice(Result);
	
EndProcedure

&AtClient
Procedure TheConfigurePropertyMatchingCommand(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("TypeOfProducts",          TypeOfProducts);
	FormParameters.Insert("MaterialKind",        MaterialKind);
	FormParameters.Insert("PropertyMapping", PropertyMapping);
	FormParameters.Insert("ReadOnly",      ReadOnly);
	
	CallbackDescription = New CallbackDescription("MappingOfPropertiesCompletion", ThisObject);
	OpenForm("CommonForm.MappingOfProperties", FormParameters,,,,,CallbackDescription);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.PropertyThatContainsProducts.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("MethodOfProductsAutoselection");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotEqual;
	ItemFilter.RightValue = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty;

	Item.Appearance.SetParameterValue("MarkIncomplete", False);

EndProcedure

&AtClient
Procedure MappingOfPropertiesCompletion(ClosingResult, AdditionalParameters) Export

	If ClosingResult = Undefined Then
		Return;
	EndIf;
	
	PropertyMapping.Clear();
	For Each ConfiguringCompliance In ClosingResult Do
		FillPropertyValues(PropertyMapping.Add(), ConfiguringCompliance);
	EndDo; 
	
	Modified = True;
	
EndProcedure

&AtServer
Procedure FillInSelectionOfPropertyContainingProductItem()

	For Each DataProperty In ListOfAllAvailableProperties Do
		If Not DataProperty.DeletionMark 
			And DataProperty.ValueType.ContainsType(Type("CatalogRef.Products")) 
			Or DataProperty.Property = PropertyThatContainsProducts Then
			Items.PropertyThatContainsProducts.ChoiceList.Add(DataProperty.Property, DataProperty.Presentation);
		EndIf;
	EndDo;

	If Items.PropertyThatContainsProducts.ChoiceList.Count() = 0 Then
		Items.PagesSetInTheProductProperty.CurrentPage = Items.PageSpecifiedInTheProductPropertyUnavailable;
	Else
		Items.PagesSetInTheProductProperty.CurrentPage = Items.PageSpecifiedInTheProductPropertyAvailable;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure WhenYouChangeAutoSelectionOfProducts(Form)

	CheckMethodsForAutoSelectingCharacteristics(Form);
	AvailabilityControl(Form);

EndProcedure

&AtClientAtServerNoContext
Procedure WhenAutoSelectingCharacteristicChanges(Form)
	
	If ValueIsFilled(Form.ItemVariantAutoSelectionAlgorithm)
		And Form.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm") Then
		Form.ItemVariantAutoSelectionAlgorithm = Undefined;
	EndIf;
	AvailabilityControl(Form);
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckMethodsForAutoSelectingCharacteristics(Form)
	
 	If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty") Then
		
		If Form.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess") Then
			Form.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess");
		EndIf; 
		
	ElsIf Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess") Then
		
		If Form.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess") Then
			Form.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess");
		EndIf; 
		
	EndIf;

	If ValueIsFilled(Form.PropertyThatContainsProducts)
		And Form.MethodOfProductsAutoselection <> PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty") Then
		Form.PropertyThatContainsProducts = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure AvailabilityControl(Form)

	// PropertyThatContainsProducts
	If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty") Then
		Form.Items.PropertyThatContainsProducts.Enabled = True;
	Else
		Form.Items.PropertyThatContainsProducts.Enabled = False;
	EndIf; 
	
	// CharacteristicIsSpecifiedInMasterData
	If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
		Form.Items.CharacteristicIsSpecifiedInMasterData.Enabled = True;
	Else
		Form.Items.CharacteristicIsSpecifiedInMasterData.Enabled = False;
	EndIf; 
	
	// AutomaticallySelectedByProductsProperties
	SelectionOfCharacteristicsByPropertiesIsAvailable = True;
	If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData")
		And Form.Products.IsEmpty() Then
		
		SelectionValue = Form.Items.SelectedAccordingToThePropertiesOfTheProductIsNotAvailable.ChoiceList[0];
		SelectionValue.Presentation = NStr("vi = 'Nó được xác định bởi các thuộc tính của sản phẩm chính (bạn phải chỉ định nguyên liệu)';
											|ru = 'Определяется по свойствам основного изделия (необходимо указать материал)';
											|en = 'Determined by main product properties (specify a material)'; fa = 'Determined by main product properties (specify a material)';
											|it = 'Determinato dalle proprietà del prodotto principale (necessario indicare il materiale)';
											|pl = 'Jest określane wg właściwości głównego wyrobu (jest wymagane wskazanie materiału)';
											|tr = 'Nihai ana ürün özelliklerine göre tanımlanmaktadır (malzemenin belirtilmesi gerekir)'");
		
		SelectionValue = Form.Items.SelectedByTheAlgorithmIsNotAvailable.ChoiceList[0];
		SelectionValue.Presentation = NStr("vi = 'Xác định bằng thuật toán (vật liệu phải được chỉ định)';
											|ru = 'Определяется по алгоритму (необходимо указать материал)';
											|en = 'Determined by the algorithm (material must be specified)'; fa = 'توسط الگوریتم تعیین می‌شود (ماده باید مشخص شده باشد)';
											|it = 'Determinato secondo un algoritmo (necessario indicare il materiale)';
											|pl = 'Jest określane według algorytmu (jest wymagane wskazanie materiału)';
											|tr = 'Algoritmaya göre tanımlanmaktadır (malzemenin belirtilmesi gerekir)'");
		
		SelectionOfCharacteristicsByPropertiesIsAvailable = False;
		
	ElsIf Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess") Then
		
		SelectionValue = Form.Items.SelectedAccordingToThePropertiesOfTheProductIsNotAvailable.ChoiceList[0];
		SelectionValue.Presentation = NStr("vi = 'Nó được xác định bởi các thuộc tính của sản phẩm chính (không có sẵn, vì nguyên liệu được chỉ định trong sản xuất)';
											|ru = 'Определяется по свойствам основного изделия (недоступно, т.к. материал уточняется в производстве)';
											|en = 'Determined by main product properties (unavailable as the material is specified in production)'; fa = 'Determined by main product properties (unavailable as the material is specified in production)';
											|it = 'Determinato dalle proprietà del prodotto principale (non disponibile poiché il materiale viene specificato nella produzione)';
											|pl = 'Jest określane według głównego wyrobu (niedostępne, ponieważ materiał jest wskazywany w produkcji)';
											|tr = 'Nihai ana ürün özelliklerine göre tanımlanmaktadır (malzeme, üretimde netleştirildiğinden dolayı mevcut değildir)'");
		
		SelectionValue = Form.Items.SelectedByTheAlgorithmIsNotAvailable.ChoiceList[0];
		SelectionValue.Presentation = NStr("vi = 'Nó được xác định bởi thuật toán (không có sẵn, vì nguyên liệu đang được chỉ định trong sản xuất)';
											|ru = 'Определяется по алгоритму (недоступно, т.к. материал уточняется в производстве)';
											|en = 'Determined by algorithm (unavailable as the material is specified in production)'; fa = 'Determined by algorithm (unavailable as the material is specified in production)';
											|it = 'Determinato secondo un algoritmo (non disponibile poiché il materiale viene specificato nella produzione)';
											|pl = 'Jest określane według algorytmu (niedostępne, ponieważ materiał jest wskazywany w produkcji)';
											|tr = 'Algoritmaya göre tanımlanmaktadır (malzeme, üretimde netleştirildiğinden dolayı mevcut değildir)'");
		
		SelectionOfCharacteristicsByPropertiesIsAvailable = False;
		
	EndIf;
	
	If SelectionOfCharacteristicsByPropertiesIsAvailable Then
		Form.Items.PagesCharacteristicIsSelectedByProductProperties.CurrentPage = Form.Items.PageCharacteristicIsSelectedByProductPropertiesAvailable;
		Form.Items.PagesCharacteristicIsSelectedByTheAlgorithm.CurrentPage = Form.Items.PagesCharacteristicIsSelectedByTheAlgorithmAvailable;
		If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
			Form.Items.PagesConfigurePropertyMapping.CurrentPage = Form.Items.PagePropertyMappingSetting;
		Else
			Form.Items.PagesConfigurePropertyMapping.CurrentPage = Form.Items.PagePropertyMappingSettingIsNotRequired;
		EndIf; 
	Else
		Form.Items.PagesCharacteristicIsSelectedByProductProperties.CurrentPage = Form.Items.PageCharacteristicIsSelectedByProductPropertiesNotAvailable;
		Form.Items.PagesCharacteristicIsSelectedByTheAlgorithm.CurrentPage = Form.Items.PagesCharacteristicIsSelectedByTheAlgorithmNotAvailable;
	EndIf; 
	
	If Form.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties") Then
		Form.Items.MappingOfProperties.Enabled = True;
	Else
		Form.Items.MappingOfProperties.Enabled = False;
	EndIf; 
	
	If Form.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm") Then
		Form.Items.ItemVariantAutoSelectionAlgorithm.Enabled = True;
	Else
		Form.Items.ItemVariantAutoSelectionAlgorithm.Enabled = False;
	EndIf; 
	
	If Form.UseItemVariants Then
		If Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty")
			Or Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess") Then
			Form.Items.PagesHowMaterialCharacteristicIsDefined.CurrentPage = Form.Items.PaheHowMaterialCharacteristicIsDefinedMaterialInProperty;
			Form.Items.DecorationDefiningTheMaterialCharacteristicInTheProperty.Visible =
				Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess");
			Form.Items.GroupDefinitionOfTheMaterialCharacteristicInThePropertyWithASelection.Visible = 
				Form.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty");
		ElsIf Form.ProductsHaveCharacteristics Then
			Form.Items.PagesHowMaterialCharacteristicIsDefined.CurrentPage = Form.Items.PaheHowMaterialCharacteristicIsDefinedCharacteristicExists;
			Form.Items.CharacteristicIsSpecifiedDuringProduction.Enabled =
				Form.ItemsType <> PredefinedValue("Enum.ItemsTypes.Set");
		Else
			Form.Items.PagesHowMaterialCharacteristicIsDefined.CurrentPage = Form.Items.PaheHowMaterialCharacteristicIsDefinedNoCharacteristic;
		EndIf;
	EndIf;
	
EndProcedure

&AtClient
Function CheckAttributesFilling()
	
	Cancel = False;
	
	If MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty") 
		And Not ValueIsFilled(PropertyThatContainsProducts) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Không chọn các tính chất của mặt hàng';
										|ru = 'Не выбрано свойство, содержащее номенклатуру.';
										|en = 'Property that contains products is not selected.'; fa = 'Property that contains products is not selected.';
										|it = 'Non è stata selezionata una proprietà contenente un articolo.';
										|pl = 'Nie wybrano właściwości, zawierającej produkty.';
										|tr = 'Öğeyi içeren özellik seçilmedi.'"),,
			"PropertyThatContainsProducts",,Cancel);
		
	EndIf;
	
	If MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm")
		And Not ValueIsFilled(ItemVariantAutoSelectionAlgorithm) Then
		
		CommonClient.MessageToUser(NStr("vi = 'Không có thuật toán nào được chọn theo đó đặc tính được xác định.';
										|ru = 'Не выбран алгоритм, по которому определяется характеристика.';
										|en = 'Algorithm that determines variant is not selected.'; fa = 'Algorithm that determines variant is not selected.';
										|it = 'Non è stato scelto un algoritmo secondo il quale viene determinata la caratteristica.';
										|pl = 'Nie wybrano algorytmu, według którego jest określana charakterystyka.';
										|tr = 'Varyantın tanımlandığı algoritma seçilmedi.'"),,
			"ItemVariantAutoSelectionAlgorithm",,Cancel);
		
	EndIf;
		
	Return Not Cancel;
		
EndFunction

&AtServerNoContext
Function PropertyThatContainsProductsHeader(PropertyThatContainsProducts)
	
	 Return Common.ObjectAttributeValue(PropertyThatContainsProducts, "Title");
	
EndFunction

#EndRegion
