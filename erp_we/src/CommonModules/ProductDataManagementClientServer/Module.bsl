////////////////////////////////////////////////////////////////////////////////
// NSI of production: Procedures of the subsystem of product data management
//
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Specifications

// Returns parameters for selecting specifications for the item.
// 
// Returns:
// 	Structure - From:
//  * AvailableTypes - Array - available specification types
//  * AvailableStatuses - Array - available specification statuses
//  * SpecificationsWithProductionOnSideAreAvailable - Boolean - indication of availability of specifications with production on the side
//  * SideOutputSpecificationsAreAvailable - Boolean - flag for displaying specifications at a fixed cost
//  * GetProductBOM - Boolean - selection flag for the specified item
//  * ChoiceParameterLinks - Map - Relationships of selection parameters
//  * SpecificationDetails - String - list of specification details
//
Function BOMSelectionParameters() Export
	
	ChoiceParameters = New Structure;
	
	ChoiceParameters.Insert("AvailableTypes", New Array);
	ChoiceParameters.Insert("AvailableStatuses", New Array);
	
	ChoiceParameters.Insert("SpecificationsWithProductionOnSideAreAvailable", True);
	ChoiceParameters.Insert("SideOutputSpecificationsAreAvailable", False);
	
	ChoiceParameters.Insert("ChoiceParameterLinks", New Map);
	ChoiceParameters.Insert("GetProductBOM", True);
	
	ChoiceParameters.Insert("SpecificationDetails", ""); // To get the details of the selected specification
	
	Return ChoiceParameters;
	
EndFunction

// Returns the parameters necessary to carry out the action "Providesopportunities".
//
// Parameters:
//  Object							- FormDataStructure 			- Current object
//  CurrentData					- FormDataCollectionItem 	- The collection string where the specification is selected
//  BOMSelectionParameters		- Structure 					- Specification selection parameters
//  Form							- ClientApplicationForm				- Form
//  AdditionalParameters			- Structure 					- Additional call parameters
// 
// Returns:
//  Structure - list of parameters.
//
Function ActionParametersCheckFillSpecification(Object,
	CurrentData,
	BOMSelectionParameters,
	Form = Undefined,
	AdditionalParameters = Undefined) Export
	
	ActionParameters = New Structure("ProductData,BOMSelectionParameters,FieldNameSpecification");
	
	ActionParameters.BOMSelectionParameters = BOMSelectionParameters;
	ActionParameters.FieldNameSpecification         = "BillOfMaterials";
	
	If TypeOf(AdditionalParameters) = Type("Structure")
			And AdditionalParameters.Property("PropsNameSpecification") Then
		ActionParameters.FieldNameSpecification = AdditionalParameters.PropsNameSpecification;
	EndIf;
	
	ActionParameters.ProductData = CollectProductDataForSpecificationSelection(
		Object,
		CurrentData,
		BOMSelectionParameters,
		Form,
		AdditionalParameters);
	ActionParameters.ProductData.CurrentSpecification = CurrentData[ActionParameters.FieldNameSpecification];
	
	Return ActionParameters;
	
EndFunction

// Returns available item types by type of production process
//
// Parameters:
//  ProductionProcessType - EnumRef.ProductionProcessTypes	 - type of production process
// 
// Returns:
//  Array of EnumRef.ProductionProcessTypes- Available Product Types
//
Function TypesOfItemsByTypeOfProductionProcess(ProductionProcessType) Export

	TypesArray = New Array;
	
	If ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		
		TypesArray.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		
	ElsIf ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly")
		Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair") Then
		
		TypesArray.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	
	Else // Production (Kitting, no specializations)
	
		TypesArray.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
		TypesArray.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
		TypesArray.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
		
	EndIf;
	
	Return TypesArray;
	
EndFunction

// The procedure sets the selection parameters for the item.
//
// Parameters:
//  Item			 - Array, FormField - field for entering the item
//  AvailableTypes	 - Array			 - Available Product Types
//
Procedure SetSelectionByItemType(Item, AvailableTypes) Export
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(AvailableTypes)));
	
	If TypeOf(Item) = Type("FormField") Then
		Item.ChoiceParameters = New FixedArray(ChoiceParametersArray);
	Else
		For IndexOf = 0 To Item.UBound() Do
			Item[IndexOf].ChoiceParameters = New FixedArray(ChoiceParametersArray);
		EndDo;
	EndIf;
	
EndProcedure

// List of fields that define the selection of the item specification
// 
// Returns:
//  String - list of fields
//
Function ProductDataStructureFieldsForSelectingSpecifications() Export
	
	Result = New Array;
	
	Result.Add("Products");
	Result.Add("Characteristic");
	Result.Add("ProductionStart");
	Result.Add("ProductionDispatcherBusinessUnit");
	Result.Add("LineOfBusiness");
	
	Result.Add("UnderRepairProduct");
	Result.Add("UnderRepairVariant");
	
	Return StrConcat(Result, ",");
	
EndFunction

// The constructor of the data structure to select the BOM item
// 
// Returns:
//  Structure - data structure
//
Function ProductDataStructureForSpecificationSelection() Export
	
	Result = New Structure(ProductDataStructureFieldsForSelectingSpecifications());
	
	Result.Products            = PredefinedValue("Catalog.Products.EmptyRef");
	Result.Characteristic          = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
	Result.ProductionStart      = Date(1,1,1);
	Result.ProductionDispatcherBusinessUnit  = PredefinedValue("Catalog.BusinessStructure.EmptyRef");
	Result.LineOfBusiness = PredefinedValue("Catalog.LinesOfBusiness.EmptyRef");
	
	Result.UnderRepairProduct   = PredefinedValue("Catalog.Products.EmptyRef");
	Result.UnderRepairVariant = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
	
	Result.Insert("CurrentSpecification", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	
	Return Result;
	
EndFunction

// The option of obtaining intermediate semi-finished products in the Bill of Materials data is not to receive.
// 
// Returns:
//  String
//
Function IntermediateSemiFinishedProductsDoNotReceive() Export
	
	Return "NotToGet";
	
EndFunction

// The option of obtaining intermediate semi-finished products in the Bill of Materials data is to obtain.
// 
// Returns:
//  String
//
Function IntermediateSemiFinishedProductsGet() Export
	
	Return "Get";
	
EndFunction

#EndRegion

#Region AutoSelection

// The text of the design of the auto-selection methods.
// 
// Returns:
//  Map of EnumRef.MethodsOfProductAutoSelection,EnumRef.MethodsOfItemVariantAutoselection
Function DesignTextsForAutoSelectionMethods() Export
	
	Result = New Map;
	
	Result.Insert(PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData"),
		"");
	Result.Insert(PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty"),
		NStr("vi = '<được chỉ định trong thuộc tính ""%1"">';
			|ru = '<указывается в свойстве ""%1"">';
			|en = '<specified in the ""%1"" property>'; fa = '<specified in the ""%1"" property>';
			|it = '<indicato nella proprietà ""%1"">';
			|pl = '<dobierane wg właściwości ""%1"">';
			|tr = '<""%1"" özelliğinde belirtilmektedir>'"));
	Result.Insert(PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInProductionProcess"),
		NStr("vi = '<được chỉ định trong sản xuất>';
			|ru = '<уточняется при производстве>';
			|en = '<specified during production>'; fa = '<specified during production>';
			|it = '<specificato durante la produzione>';
			|pl = '<uściślane podczas produkcji>';
			|tr = '<üretim esnasında netleştirilmektedir>'"));
	
	Result.Insert(PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData"),
		"");
	Result.Insert(PredefinedValue("Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties"),
		NStr("vi = '<được xác định bởi các thuộc tính của sản phẩm chính>';
			|ru = '<определяется по свойствам основного изделия>';
			|en = '<determined by main product properties>'; fa = '<determined by main product properties>';
			|it = '<determinato dalle proprietà del prodotto principale>';
			|pl = '<jest określane według właściwości głównego wyrobu>';
			|tr = '<nihai ana ürünün özelliklerine göre tanımlanmaktadır>'"));
	Result.Insert(PredefinedValue("Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm"),
		NStr("vi = '<được xác định bởi thuật toán>';
			|ru = '<определяется по алгоритму>';
			|en = '<defined by algorithm>'; fa = '<defined by algorithm>';
			|it = '<determinato secondo un algoritmo>';
			|pl = '<jest określane według algorytmu>';
			|tr = '<algoritmaya göre tanımlanmaktadır>'"));
	Result.Insert(PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInProductionProcess"),
		NStr("vi = '<được chỉ định trong sản xuất>';
			|ru = '<уточняется при производстве>';
			|en = '<specified during production>'; fa = '<specified during production>';
			|it = '<specificato durante la produzione>';
			|pl = '<uściślane podczas produkcji>';
			|tr = '<üretim esnasında netleştirilmektedir>'"));
	
	Return Result;
	
EndFunction

#EndRegion

#Region CalculationByFormulas

// Returns a description of the functions used in the formula constructor
// 
// Parameters:
//  GroupName - String - the name of the group in the formula tree of the constructor
// 
// Returns:
//  Array of See ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction - description of the functions of external modules.
//
Function DescriptionOfFormulaConstructorFunctions(GroupName = "") Export
	
	Result = ProcessingOfFormulasClientServer.CommonModuleFunctions();
	
	If GroupName = "NumericFunction" Or IsBlankString(GroupName) Then
		
		LongDesc = DescriptionOfFunctionOfOcdFormulaConstructorUp();
		Result.Add(LongDesc);
		
		LongDesc = DescriptionOfFunctionOfOcdFormulaConstructorDown();
		Result.Add(LongDesc);
		
	EndIf;
	
	If GroupName = "OtherFunctions" Or IsBlankString(GroupName) Then
	
		LongDesc = ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction();
		LongDesc.Id = "SelectByThreshold";
		LongDesc.FullPath = "ProductDataManagementClientServer.SelectByThreshold";
		LongDesc.Presentation = NStr("vi = 'Lựa chọn ngưỡng';
									|ru = 'Выбор по порогу';
									|en = 'Select by threshold'; fa = 'Select by threshold';
									|it = 'Scelta in base al margine';
									|pl = 'Wybór wg wartości progowej';
									|tr = 'Eşiğe göre seçim'");
		ParameterPresentation1 = NStr("vi = '<Tham số>';
										|ru = '<Параметр>';
										|en = '<Parameter>'; fa = '<Parameter>';
										|it = '<Parametro>';
										|pl = '<Parametr>';
										|tr = '<Parametre>'");
		ParameterPresentation2 = NStr("vi = '<Giá trị1>';
										|ru = '<Значение1>';
										|en = '<Value1>'; fa = '<Value1>';
										|it = '<Valore 1>';
										|pl = '<Wartość1>';
										|tr = '<Değer1>'");
		ParameterPresentation3 = NStr("vi = '<Ngưỡng1>';
										|ru = '<Порог1>';
										|en = '<Threshold1>'; fa = '<Threshold1>';
										|it = '<Soglia1>';
										|pl = '<Próg1>';
										|tr = '<Eşik1>'");
		ParameterPresentation4 = NStr("vi = '<Giá trị2>';
										|ru = '<Значение2>';
										|en = '<Value2>'; fa = '<Value2>';
										|it = '<Valore2>';
										|pl = '<Wartość2>';
										|tr = '<Değer2>'");
		ParameterPresentation5 = NStr("vi = '<Ngưỡng4 (không bắt buộc)>';
										|ru = '<Порог4 (необязательный)>';
										|en = '<Threshold4 (optional)>'; fa = '<Threshold4 (optional)>';
										|it = '<Sogli4 (facoltativa)>';
										|pl = '<Próg4 (niekonieczny)>';
										|tr = '<Eşik4 (isteğe bağlı)>'");
		ParameterPresentation6 = NStr("vi = '<Giá trị5 (không bắt buộc)>';
										|ru = '<Значение5 (необязательный)>';
										|en = '<Value5 (optional)>'; fa = '<Value5 (optional)>';
										|it = '<Valore5 (facoltativo)>';
										|pl = '<Wartość5 (niekonieczny)>';
										|tr = '<Değer5 (isteğe bağlı)>'");
		LongDesc.StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
			"SelectByThreshold(%1, %2, %3, %4,..., %5, %6)",
			ParameterPresentation1,
			ParameterPresentation2,
			ParameterPresentation3,
			ParameterPresentation4,
			ParameterPresentation5,
			ParameterPresentation6);
		LongDesc.Explanation = NStr("vi = 'Chọn giá trị theo ngưỡng đã đặt';
									|ru = 'Выбирает значение согласно заданному порогу';
									|en = 'Selects a value according to a specified threshold.'; fa = 'Selects a value according to a specified threshold.';
									|it = 'Selezione il valore secondo la soglia indicata';
									|pl = 'Wybiera wartość zgodnie z zadanym progiem';
									|tr = 'Verilen eşiğe göre değer seçmektedir'");
		Result.Add(LongDesc);
	
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the description of the OK function above for the formula constructor
// 
// Returns:
//  See ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction
//
Function DescriptionOfFunctionOfOcdFormulaConstructorUp() Export
	
	LongDesc = ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction();
	LongDesc.Id = "RoundCeiling";
	LongDesc.FullPath = "TMCommonUseClientServer.RoundCeiling";
	LongDesc.Presentation = NStr("vi = 'Làm tròn lên';
								|ru = 'Округление вверх';
								|en = 'Rounding up'; fa = 'Rounding up';
								|it = 'Arrotondamento per eccesso';
								|pl = 'Zaokrąglenie w górę';
								|tr = 'Yukarı yuvarlama'");
	ParameterPresentation1 = NStr("vi = '<Giá trị làm tròn>';
									|ru = '<Округляемое значение>';
									|en = '<Round value>'; fa = '<Round value>';
									|it = '<Valore da arrotondare>';
									|pl = '<Wartość zaokrąglana>';
									|tr = '<Yuvarlanmış değer>'");
	ParameterPresentation2 = NStr("vi = '<Độ sâu bit>';
									|ru = '<Разрядность>';
									|en = '<Bitness>'; fa = '<Bitness>';
									|it = '<bitness>';
									|pl = '<Ilość pozycji>';
									|tr = '<Bit genişliği>'");
	LongDesc.StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"RoundCeiling(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	LongDesc.Explanation = NStr("vi = 'Làm tròn lên đến giá trị lớn hơn gần nhất';
								|ru = 'Округление до ближайшего большего значения';
								|en = 'Rounding to the nearest greater value'; fa = 'Rounding to the nearest greater value';
								|it = 'Arrotondamento al numero più alto più vicino';
								|pl = 'Zaokrąglenie do najbliższej większej wartości';
								|tr = 'En yakın büyük değere yuvarlama'");
	
	Return LongDesc;
	
EndFunction

// Returns a description of the OkrVniz function for the formula constructor
// 
// Returns:
//  See ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction
//
Function DescriptionOfFunctionOfOcdFormulaConstructorDown() Export
	
	LongDesc = ProcessingOfFormulasClientServer.DescriptionOfCommonModuleFunction();
	LongDesc.Id = "RoundFloor";
	LongDesc.FullPath = "TMCommonUseClientServer.RoundFloor";
	LongDesc.Presentation = NStr("vi = 'Làm tròn xuống';
								|ru = 'Округление вниз';
								|en = 'Rounding down'; fa = 'Rounding down';
								|it = 'Arrotondamento per difetto';
								|pl = 'Zaokrąglenie w dół';
								|tr = 'Aşağı yuvarlama'");
	ParameterPresentation1 = NStr("vi = '<Giá trị làm tròn>';
									|ru = '<Округляемое значение>';
									|en = '<Round value>'; fa = '<Round value>';
									|it = '<Valore da arrotondare>';
									|pl = '<Wartość zaokrąglana>';
									|tr = '<Yuvarlanmış değer>'");
	ParameterPresentation2 = NStr("vi = '<Độ sâu bit>';
									|ru = '<Разрядность>';
									|en = '<Bitness>'; fa = '<Bitness>';
									|it = '<bitness>';
									|pl = '<Ilość pozycji>';
									|tr = '<Bit genişliği>'");
	LongDesc.StructureToInsert = StringFunctionsClientServer.SubstituteParametersToString(
		"RoundFloor(%1, %2)",
		ParameterPresentation1,
		ParameterPresentation2);
	LongDesc.Explanation = NStr("vi = 'Làm tròn xuống giá trị thấp hơn tiếp theo';
								|ru = 'Округление до ближайшего меньшего значения';
								|en = 'Rounding to the nearest lower value'; fa = 'Rounding to the nearest lower value';
								|it = 'Arrotondamento al numero più basso più vicino';
								|pl = 'Zaokrąglenie do najbliższej mniejszej wartości';
								|tr = 'En yakın küçük değere yuvarlama'");
	
	Return LongDesc;
	
EndFunction

// Selects a value according to the specified threshold
//
// Parameters:
//  Parameter	 - Number	 - Parameter
//  Value	 - Number	 - Value
//  Threshold		 - Number	 - Threshold
//  Value2	 - Number	 - Value
//  Threshold2		 - Number	 - Threshold
//  Value3	 - Number	 - Value
//  Threshold3		 - Number	 - Threshold
//  Value4	 - Number	 - Value
//  Threshold4		 - Number	 - Threshold
//  Value5	 - Number	 - Value
//  Threshold5		 - Number	 - Threshold
// 
// Returns:
//  Number - selection result
//
Function SelectByThreshold(
	Parameter,
	Value,
	Threshold,
	Value2 = 0,
	Threshold2 = Undefined,
	Value3 = 0,
	Threshold3 = Undefined,
	Value4 = 0,
	Threshold4 = Undefined,
	Value5 = 0,
	Threshold5 = Undefined) Export
	
	Result = 0;
	
	If Threshold >= Parameter Then 
		
		Result = Value;
		
	ElsIf Value2 <> 0 And Threshold2 = Undefined Then
		
		Result = Value2;
		
	ElsIf ValueIsFilled(Threshold2) And Value2 <> Undefined And Threshold2 >= Parameter Then
		
		Result = Value2;
		
	ElsIf Value3 <> 0 And Threshold3 = Undefined Then
		
		Result = Value3;
		
	ElsIf ValueIsFilled(Threshold3) And Value3 <> Undefined And Threshold3 >= Parameter Then
		
		Result = Value3;
		
	ElsIf Value4 <> 0 And Threshold4 = Undefined Then
		
		Result = Value4;
	
	ElsIf ValueIsFilled(Threshold4) And Value4 <> Undefined And Threshold4 >= Parameter Then
		
		Result = Value4;
		
	ElsIf Value5 <> 0 And Threshold5 = Undefined Then
		
		Result = Value5;
		
	ElsIf ValueIsFilled(Threshold5) And Value5 <> Undefined And Threshold5 >= Parameter Then
		
		Result = Value5;
		
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region EditingMaterials

// Performs standard actions when entering a new line in the tab. part that provides automatic selection of the item
//  - sets the method for automatic selection of the item
//  - sets the method for automatic selection of characteristics
//  - copies the auto-selection settings.
//
// Parameters:
//  RowData			 - FormDataStructure	 - contains string data
//  SourceLinkKey		 - Number, Undefined	 - source link key (when copying a string)
//  PropertyMapping		 - FormDataCollection	 - the tabular part of the "Sootvetstvovat".
//
Procedure WhenEnteringNewLineWithAutoSelection(RowData, SourceLinkKey = Undefined, PropertyMapping = Undefined) Export

	NewRow = (SourceLinkKey = Undefined);
	
	If NewRow Or Not ValueIsFilled(RowData.MethodOfProductsAutoselection) Then
		RowData.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData");
	EndIf;
	
	If NewRow Or Not ValueIsFilled(RowData.MethodOfItemVariantAutoselection) Then
		RowData.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData");
	EndIf;
	
	If (SourceLinkKey <> Undefined) Then
		StringsList = PropertyMapping.FindRows(New Structure("ConnectionKey", SourceLinkKey));
		For Each FoundRow In StringsList Do
			NewRow = PropertyMapping.Add();
			FillPropertyValues(NewRow, FoundRow);
			NewRow.ConnectionKey = RowData.ConnectionKey;
		EndDo;
	EndIf;
	
EndProcedure

// Performs standard actions when entering a new row in a table that has the ability to select by properties
//   - copies selection settings
//
// Parameters:
//  RowData          - FormDataStructure   - contains string data
//  SourceLinkKey    - Number, Undefined    - source link key (when copying a string)
//  SelectionByProperties      - FormDataCollection   - the tabular part of the "AMBROSIASTER"
Procedure WhenEnteringNewLineWithSelectionByProperties(RowData, SourceLinkKey = Undefined, SelectionByProperties = Undefined) Export

	If SourceLinkKey <> Undefined Then // Copy
		
		StringsList = SelectionByProperties.FindRows(New Structure("ConnectionKey", SourceLinkKey));
		For Each FoundRow In StringsList Do
			NewRow = SelectionByProperties.Add();
			FillPropertyValues(NewRow, FoundRow);
			NewRow.ConnectionKey = RowData.ConnectionKey;
		EndDo;
		
	EndIf;

EndProcedure

// Performs the standard steps when you change the material
//
Procedure WhenChangingProductsInLineWithAutoSelection(RowData, Object) Export

	If RowData.MethodOfProductsAutoselection <> PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData") Then
		RowData.MethodOfProductsAutoselection = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData");
		RowData.ProductsAsAString = "";
	EndIf; 
		
EndProcedure

// Performs standard actions when changing a characteristic
//
Procedure WhenChangingCharacteristicInLineWithAutoSelection(RowData, Object) Export

	If RowData.MethodOfItemVariantAutoselection <> PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData") Then
		RowData.MethodOfItemVariantAutoselection = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData");
		RowData.CharacteristicAsAString = "";
	EndIf;
	
	SpecifiedProperties = Object.PropertyMapping.FindRows(New Structure("ConnectionKey", RowData.ConnectionKey));
	For Each CollectionItem In SpecifiedProperties Do
		Object.PropertyMapping.Delete(CollectionItem);
	EndDo; 
	
EndProcedure

// The function determines whether the material is a semi finished product produced in the process
//
// Parameters:
//  RowData - FormDataStructure - contains string data.
// 
// Returns:
//   - Boolean - True if the material is a semi-finished product and is produced in the process.
//
Function SemiFinishedProductProducedInProcess(RowData) Export
	
	Result = False;
	If CommonClientServer.HasAttributeOrObjectProperty(RowData, "MethodOfReceivingMaterial") Then
		Result = (RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage")
					Or RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials"));
	ElsIf CommonClientServer.HasAttributeOrObjectProperty(RowData, "ProducedInProcess") Then
		Result = RowData.ProducedInProcess;
	EndIf;
	Return Result;
	
EndFunction

// The function determines whether the material is a semi-finished product produced in the process at the stage.
//
// Parameters:
//  RowData - FormDataStructure - contains string data.
// 
// Returns:
//   - Boolean - True if the material is a semi-finished product and is produced in the process at the stage.
//
Function SemiFinishedProductIsProducedAtStage(RowData) Export
	Return RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage");
	Return False; // empty handler
	
EndFunction

// The function determines whether the material is a semi-finished product produced in the process according to the specification.
//
// Parameters:
//  RowData - FormDataStructure - contains string data.
// 
// Returns:
//   - Boolean - True if the material is a semi-finished product and is produced in the process according to the specification.
//
Function SemiFinishedProductIsProducedAccordingToSpecification(RowData) Export
	Return RowData.MethodOfReceivingMaterial = PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials");
	Return False; // empty handler
	
EndFunction

Procedure FillInDefaultMethodForGettingMaterial(RowData) Export
	
	StructureOfValues = New Structure;
	
	StructureOfValues.Insert("ProducedInProcess", False);
	StructureOfValues.Insert("SourceOfSemiFinishedProduct", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	StructureOfValues.Insert("SourceOfSemiFinishedProductPresentation", "");
	StructureOfValues.Insert("PlanNotEarlierThan", PredefinedValue("Catalog.ProductionStages.EmptyRef"));
	StructureOfValues.Insert("PlanNotEarlierThanPresentation", "");
	StructureOfValues.Insert("BillOfMaterialsRM", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	StructureOfValues.Insert("BillOfMaterialsRMPresentation", "");
	StructureOfValues.Insert("MethodOfReceivingMaterial", PredefinedValue("Enum.MethodsOfReceivingBOMMaterials.Provide"));
	StructureOfValues.Insert("MethodOfGettingTheMaterialEditing", NStr("vi = 'Đảm bảo';
																		|ru = 'Обеспечивать';
																		|en = 'Supply'; fa = 'Supply';
																		|it = 'Fornire';
																		|pl = 'Supply';
																		|tr = 'Sağla'"));
	
	FillPropertyValues(RowData, StructureOfValues);
	
EndProcedure

// Returns an array of available item types for tab.parts of NSI production
// 
// Parameters:
//  Form - ClientApplicationForm
//  TSName - String - PM name
// 
// Returns:
//  Array - Array of available item types
Function ArrayOfAvailableItemTypes(Form, TSName = "") Export
	
	Result = New Array;
	
	Result.Add(PredefinedValue("Enum.ItemsTypes.ReusablePackage"));
	Result.Add(PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	Result.Add(PredefinedValue("Enum.ItemsTypes.Work_5"));
	
	If TSName = "MaterialsAndServices" Then
		
		KitsAreAvailable = Form.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.KitConfigurations")
			Or (Form.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.Specifications")
					And TypeOf(Form.Object.Ref) <> Type("CatalogRef.RouteSheets"))
			Or Form.SourceOfCompositionOfSetsInProduction = PredefinedValue("Enum.SourcesOfCompositionOfSetsInProduction.SpecificationsOrConfigurationOptions");
		
		If KitsAreAvailable Then
			Result.Add(PredefinedValue("Enum.ItemsTypes.Set"));
		EndIf;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Sets the parameters for the selection of materials in the production NSI
// 
// Parameters:
//  Item - FormField
//  Form - ClientApplicationForm
Procedure SetMaterialSelectionParameters(Item, Form) Export
	
	ArrayOfProductTypes = ArrayOfAvailableItemTypes(Form, "MaterialsAndServices");
	
	ChoiceParametersArray = New Array;
	ChoiceParametersArray.Add(New ChoiceParameter("Filter.ItemsType", New FixedArray(ArrayOfProductTypes)));
	
	If TypeOf(Item) = Type("Array") Then
		Items = Item;
	Else
		Items = CommonClientServer.ValueInArray(Item);
	EndIf;
	
	For IndexOf = 0 To Items.UBound() Do
		Items[IndexOf].ChoiceParameters = New FixedArray(ChoiceParametersArray);
	EndDo;
	
EndProcedure

#EndRegion

#Region DescriptionManufacturingProcess

// Retrieves data from the main product specification
//
// Parameters:
//  Object	 - CatalogObject.BillsOfMaterials, Structure - specification.
// 
// Returns:
//  Structure - data of the main product.
//
Function MainProductSpecificationData(Object) Export
	
	ThisIsBuild   = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	ThisIsRepair   = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM")
					Or Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair"));
	ThisIsDisassembly = (Object.ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	
	If (ThisIsBuild Or ThisIsRepair)
		And Object.ManufacturedProducts.Count() <> 0 Then
		
		Result = New Structure(
			"ProductKind,
			|Products,
			|Characteristic,
			|Package,
			|NumberOfPackages");
		FillPropertyValues(Result, Object.ManufacturedProducts[0]);
		
	ElsIf ThisIsDisassembly Then
		
		Result = New Structure;
		Result.Insert("ProductKind",    Object.MainProductProductKind);
		Result.Insert("Products",       Object.MainProductProducts);
		Result.Insert("Characteristic",     Object.MainProductCharacteristic);
		Result.Insert("Package",           Object.MainProductPackage);
		Result.Insert("NumberOfPackages", Object.MainProductNumberOfPackages);
		
	Else
		
		Result = New Structure;
		Result.Insert("ProductKind",    PredefinedValue("Catalog.ItemKinds.EmptyRef"));
		Result.Insert("Products",       PredefinedValue("Catalog.Products.EmptyRef"));
		Result.Insert("Characteristic",     PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
		Result.Insert("Package",           PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
		Result.Insert("NumberOfPackages", 0);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Gets the value of the main detail according to the data of the main product specification
//
// Parameters:
//  Object  - CatalogObject.BillsOfMaterials, Structure - specification.
//  MainProduct - See MainProductSpecificationData
// 
// Returns:
//  Structure - data of the main props
//
Function MainPropsOfMainProductSpecification(Object, MainProduct = Undefined) Export
	
	Result = New Structure;
	
	If MainProduct = Undefined Then
		MainProduct = MainProductSpecificationData(Object);
	EndIf;
	
	If Object.AssignmentOption = PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.ProductKind") Then
		Result.Insert("Name", "ProductKind");
	Else
		Result.Insert("Name", "Products");
	EndIf;
	
	Result.Insert("Value", MainProduct[Result.Name]);
	
	Return Result;
	
EndFunction

// Returns a representation of the unit of measurement for the release batch
//
// Parameters:
//  ReleaseBatchDescription	 - Structure, String, CatalogRef.PackagesAndUnitsOfMeasure	 - description or unit of measurement of the release batch
//  Count				 - Number														 - number of units / batches.
// 
// Returns:
//  String - representation of the unit of measurement of the release batch.
//
Function PresentationOfUnitOfMeasurementOfBatchOfRelease(ReleaseBatchDescription = Undefined, Count = 0) Export
	
	If ReleaseBatchDescription <> Undefined Then
		
		If TypeOf(ReleaseBatchDescription) = Type("FixedStructure") Then
			ReleaseBatchDescriptionIsUsed = True;
			UnitOfMeasurementOfReleaseBatch = ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch;
		Else
			ReleaseBatchDescriptionIsUsed = False;
			UnitOfMeasurementOfReleaseBatch = ReleaseBatchDescription;
		EndIf;
		If Not ValueIsFilled(UnitOfMeasurementOfReleaseBatch) Then
			If ReleaseBatchDescriptionIsUsed And ReleaseBatchDescription.ProductionIssueByCustomPortions Then
				Result = NStr("vi = 'đơn vị lưu trữ';
								|ru = 'ед. хранения';
								|en = 'stock UOM'; fa = 'stock UOM';
								|it = 'unità di stoccaggio';
								|pl = 'J. przechowywania';
								|tr = 'stok ölçü birimi'");
			Else
				Result = TMCommonUseClientServer.DeclensionOfWord(
								Count,
								NStr("vi = 'lô, lô, lô, d';
									|ru = 'партия, партии, партий, ж';
									|en = 'lot, lots'; fa = 'lot, lots';
									|it = 'партия, партии, партий, ж';
									|pl = 'lot, lots';
									|tr = 'parti, partiler, partiler, j'"));
			EndIf;
		Else
			Result = String(UnitOfMeasurementOfReleaseBatch);
		EndIf;
		
		// Let's add a unit of measurement with a description of the release batch
		If ReleaseBatchDescriptionIsUsed 
			And Not ReleaseBatchDescription.MultipleIssue
			And Not ReleaseBatchDescription.ProductionIssueByCustomPortions
			And ReleaseBatchDescription.UnitOfProductMeasurement <> ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch
			And ReleaseBatchDescription.NumberOfPackages > 0 Then
				Result = StrTemplate(
								NStr("vi = '%1 (%2 %3)';
									|ru = '%1 (%2 %3)';
									|en = '%1 (%2 %3)'; fa = '%1 (%2 %3)';
									|it = '%1 (%2 %3)';
									|pl = '%1 (%2 %3)';
									|tr = '%1 (%2 %3)'"),
								Result,
								Format(ReleaseBatchDescription.NumberOfPackages,"NZ=; NG="), 
								ReleaseBatchDescription.UnitOfProductMeasurement
				);
		EndIf;
		
		Return Result;
	Else
		
		Return NStr("vi = 'đơn vị / lô';
					|ru = 'единиц/партий изделий';
					|en = 'units/lots of products'; fa = 'واحدها/بچ‌های محصول';
					|it = 'unità/lotti dei prodotti';
					|pl = 'jednostek/partii wyrobów';
					|tr = 'nihai ürün birimi/lotu'");
	EndIf;

EndFunction

// Sets the design for the field for entering the number of units/batches
//
// Parameters:
//  ProductionIssueByCustomPortions	 - Boolean	 - True if an arbitrary batch release is available
//  Item						 - FormField - Control element.
//
Procedure SetParametersForEnteringNumberOfBatchUnits(ProductionIssueByCustomPortions, Item) Export
	
	Item.TypeRestriction = New TypeDescription("Number", New NumberQualifiers(15, ?(ProductionIssueByCustomPortions,3,0)));
	
	Item.ChoiceButton        = ProductionIssueByCustomPortions;
	Item.SpinButton = Not ProductionIssueByCustomPortions;
	
EndProcedure

#EndRegion

#Region Other

// Generates a stage view that can be used for output to the user.
//
// Parameters:
//  BillOfMaterialsPresentation			- String - Specification view
//  StagePresentation					- String - stage presentation
//  MultiStageProductionProcess	- Boolean - Indicates that the production process consists of several stages
//  StageOfRestorationOfDefectiveGoods				- Boolean - Indicates that the stage was created to restore the marriage.
//
// Returns:
//   String   - stage representation.
//
Function PresentationStage(BillOfMaterialsPresentation, StagePresentation, MultiStageProductionProcess, StageOfRestorationOfDefectiveGoods = False) Export

	If MultiStageProductionProcess Then
		SpecificationString = StagePresentation + ", " + BillOfMaterialsPresentation;
	Else
		SpecificationString = BillOfMaterialsPresentation;
	EndIf;
	If StageOfRestorationOfDefectiveGoods Then
		SpecificationString = SpecificationString + " (" + NStr("vi = 'phục hồi hỏng hóc';
																|ru = 'восстановление брака';
																|en = 'restoring nonconforming goods '; fa = 'restoring nonconforming goods ';
																|it = 'recupero degli scarti';
																|pl = 'przywrócenie wady';
																|tr = 'uygunsuzluğun giderilmesi'") + ")";
	EndIf; 

	Return SpecificationString;
		
EndFunction

// Returns a string representation of the specification status
//
// Parameters:
//  Status			 - EnumRef.BOMStatuses	 - specification status
//  ValidOnDate	 - Date										 - start of the validity period
//  ValidToDate	 - Date										 - end of validity period
//  RowStatus	 - String									 - Performance.
// 
// Returns:
//  String - presentation of the specification.
//
Function SpecificationStatusPresentation(Status, ValidOnDate = '00010101', ValidToDate = '00010101', RowStatus = "") Export
	
	If IsBlankString(RowStatus) Then
		RowStatus = String(Status);
	EndIf;
	
	StringValidityPeriod = "";
	If Status = PredefinedValue("Enum.BOMStatuses.Valid") Then
		If ValidOnDate <> '00010101' And ValidToDate <> '00010101' Then
			StringValidityPeriod = " " + StrTemplate(NStr("vi = 'từ %1 đến %2';
															|ru = 'с %1 по %2';
															|en = 'from %1 to %2'; fa = 'from %1 to %2';
															|it = 'da %1 fino a %2';
															|pl = 'od %1 do %2';
															|tr = '%1 ile %2 arası'"), Format(ValidOnDate, "DLF=D"), Format(ValidToDate, "DLF=D"));
		ElsIf ValidOnDate <> '00010101' Then
			StringValidityPeriod = " " + StrTemplate(NStr("vi = 'từ %1';
															|ru = 'с %1';
															|en = 'from %1'; fa = 'from %1';
															|it = 'da %1';
															|pl = 'od %1';
															|tr = '%1 itibarıyla'"), Format(ValidOnDate, "DLF=D"));
		ElsIf ValidToDate <> '00010101'  Then
			StringValidityPeriod = " " + StrTemplate(NStr("vi = 'đến %1';
															|ru = 'по %1';
															|en = 'to %1'; fa = 'to %1';
															|it = 'fino a %1';
															|pl = 'do %1';
															|tr = '%1 arası'"), Format(ValidToDate, "DLF=D"));
		EndIf;
	EndIf;
	
	RowStatus = StrTemplate("%1%2", RowStatus, StringValidityPeriod);
	
	Return RowStatus;
	
EndFunction

#EndRegion

#Region BOMsTree

// Parameters for building a specification tree
// 
// Returns:
//   - Structure - parameters for building the specification tree, contains:
//   	* Products - CatalogRef.Products - Products
//   	* ProductCharacteristic - CatalogRef.ItemsCharacteristics - characteristics of the nomenclature
//   	* BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
//   	* Date - Date - date of selection of sub-spec
//   	* ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - destination parameter
//   	* LineOfBusiness - CatalogRef.LinesOfBusiness - setting up the assignment
//   	* BOMSelectionParameters - See ProductDataManagement.BOMSelectionParameters
//   	* DisplayStages - Boolean - the sign of the output stages
//   	* OutputOfOperations - Boolean - flag for output of operations
//   	* OutputOutputProducts - Boolean - indicates whether output items are displayed
//   	* DisplayMaterials - Boolean - whether to output content
//   	* DeduceLaborCosts - Boolean - indication of output of labor costs
//   	* DisplayGroupingTitles - Boolean - indicates whether grouping headers are displayed when printing
//   	* DisplayBalanceOfGoods - Boolean - indicates whether Balances are displayed in the warehouse
//   	* UnravelSemiFinishedProducts - Boolean - indicates whether semi-finished products need to be unzipped
//   	* DynamicReading - Boolean - dynamic reading mode for tree nodes
//   	* SaveData_ - Boolean - whether to save data
//   	* ConnectionKey - UUID - 
//   	* OutputProductPackaging - CatalogRef.PackagesAndUnitsOfMeasure - 
//   	* NumberOfPackagesOfOutputProduct - Number - 
//   	* OutputProductQuantity - Number - 
//   	* AddressInStorage - String - address of the order structure
//
Function SpecificationTreeParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("Products");
	Parameters.Insert("ProductCharacteristic");
	
	Parameters.Insert("BillOfMaterials");
	Parameters.Insert("Date");
	
	Parameters.Insert("ProductionDispatcherBusinessUnit");
	Parameters.Insert("LineOfBusiness");
	
	Parameters.Insert("BOMSelectionParameters");
	
	Parameters.Insert("DisplayStages", False);
	Parameters.Insert("OutputOfOperations", False);
	Parameters.Insert("OutputOutputProducts", False);
	Parameters.Insert("DisplayMaterials", False);
	Parameters.Insert("DeduceLaborCosts", False);
	Parameters.Insert("DisplayGroupingTitles", False);
	Parameters.Insert("DisplayBalanceOfGoods", False);
	
	Parameters.Insert("UnravelSemiFinishedProducts", False);
	Parameters.Insert("DynamicReading", False);
	Parameters.Insert("SaveData_", False);

	//Begin.OrderSpecificationTreeMode
	
	Parameters.Insert("ConnectionKey");
	
	Parameters.Insert("OutputProductPackaging");
	Parameters.Insert("NumberOfPackagesOfOutputProduct");
	Parameters.Insert("OutputProductQuantity");

	Parameters.Insert("AddressInStorage");
	
	//End.OrderSpecificationTreeMode
	
	Return Parameters;
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region OperationsSheetList

// Sets selection in the dynamic list of route maps
// 
// Parameters:
// 	List - DynamicList - the list for which you want to set the selection
// 	Products - CatalogRef.Products - Products
// 	Purpose - EnumRef.UseOfItemsInProductionMasterData - additional selection criteria
Procedure SetSelectionByProductInRouteMapList(List, Products, Purpose = Undefined) Export
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg towaru';
			|tr = 'Öğeye göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.ManufacturedProducts.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products) And (Not ValueIsFilled(Purpose) Or Purpose = PredefinedValue("Enum.UseOfItemsInProductionMasterData.Product")));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.MaterialsAndServices.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products) And (Not ValueIsFilled(Purpose) Or Purpose = PredefinedValue("Enum.UseOfItemsInProductionMasterData.Material")));
	
	List.SettingsComposer.Settings.AdditionalProperties.Insert("Products", Products);
	
EndProcedure

#EndRegion

#Region AutoSelection_SelectionByProperties

Function DetailsSettingUpSelectionByProperties() Export
	
	Return "Property,Condition,Value";
	
EndFunction

Function SelectionByPropertiesOfCommunicationKey(SettingKind) Export
	
	If SettingKind = "Products" Then
		
		Return New UUID("2f97ad16-b5bd-47c5-af87-b6dcc608e039");
		
	ElsIf SettingKind = "Characteristic" Then
		
		Return New UUID("e826d6c8-259e-4721-8664-eac66f1434b5");
		
	Else
		
		Raise NStr("vi = 'Để có được khóa chọn cho các thuộc tính, chế độ xem không chính xác của cài đặt đã được chuyển.';
					|ru = 'Для получения ключа отбора по свойствам передан неверный вид настройки.';
					|en = 'An invalid setting kind was passed to receive a filter key by properties'; fa = 'An invalid setting kind was passed to receive a filter key by properties';
					|it = 'Per ricevere la chiave di selezione per le proprietà è stato trasferito un tipo di impostazione non corretto.';
					|pl = 'W celu otrzymania klucza filtru wg właściwości został przekazany błędny rodzaj ustawienia.';
					|tr = 'Özelliklere göre seçim anahtarının alınması için yanlış ayar türü aktarıldı.'");
		
	EndIf;
	
EndFunction

Procedure ClearAutoSelectionSettingsByLine(RowData, PropertyMapping) Export
	
	ProductsAreSpecifiedInMasterData   = PredefinedValue("Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData");
	CharacteristicIsSpecifiedInMasterData = PredefinedValue("Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData");
	
	If RowData.MethodOfProductsAutoselection = ProductsAreSpecifiedInMasterData
		And RowData.MethodOfItemVariantAutoselection = CharacteristicIsSpecifiedInMasterData Then
		Return;
	EndIf;
	
	StringsList = PropertyMapping.FindRows(New Structure("ConnectionKey", RowData.ConnectionKey));
	For Each FoundRow In StringsList Do
		PropertyMapping.Delete(FoundRow);
	EndDo; 
	
EndProcedure

Procedure ClearSelectionSettingsByPropertiesByRow(RowData, SelectionByProperties) Export
	
	StringsList = SelectionByProperties.FindRows(New Structure("ConnectionKey", RowData.ConnectionKey));
	For Each FoundRow In StringsList Do
		SelectionByProperties.Delete(FoundRow);
	EndDo;
	
EndProcedure

Procedure ClearSpecificationRefinementSettings(Object, SettingsKinds = "Products,Characteristic") Export
	
	For Each SettingKind In StrSplit(SettingsKinds,",") Do
	
		ConnectionKey = SelectionByPropertiesOfCommunicationKey(SettingKind);
		
		StringsList = Object.SelectionByProperties.FindRows(New Structure("ConnectionKey", ConnectionKey));
		For Each FoundRow In StringsList Do
			Object.SelectionByProperties.Delete(FoundRow);
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region BOMsTree

Procedure TreeSpecificationsOutputElements(CurrentRow, ItemsCollection, OutputOfChildLines = False) Export
	
	SubordinateItems = CurrentRow.GetItems();
	SubordinateItems.Clear();
	
	If OutputOfChildLines And CurrentRow.ThereIsBOM And ItemsCollection.UBound() = -1 Then
		
		SubordinateItems.Add();
		Return;
		
	EndIf;
	
	For Each CollectionItem In ItemsCollection Do
		
		NewRow = SubordinateItems.Add();
		FillPropertyValues(NewRow, CollectionItem);
		
		TreeSpecificationsOutputElements(NewRow, CollectionItem.Rows, True);
		
	EndDo;
	
EndProcedure

Function SpecificationTreeMode() Export
	
	Return "BOMsTree";
	
EndFunction

Function OrderSpecificationTreeMode()Export
	
	Return "OrderSpecificationTree"; 
	
EndFunction

// Puts data from the specification tree row in the structure
// 
// Parameters:
// 	CurrentRow - FormDataCollectionItem - this line
// Returns:
// 	Structure - the data structure of a string from:
// * LineKind - EnumRef.TypesOfSpecificationLines - the string
// * Id - UUID - ID of the tree row
// * Products - CatalogRef.Products,String - Products
// * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
// * BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
// * Count - Number - quantity in the base unit of measurement
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure, String - basic unit of measurement
// * NumberOfPackages - Number - Number of packages
// * Package - CatalogRef.PackagesAndUnitsOfMeasure - Package
// * Warehouse - CatalogRef.Warehouses - default material provision warehouse
// * InStock - Number - in stock by default
// * Available - Number - available in stock by default
// * PictureIndex - Number, Picture - index of an image in the image collection
// * ProducedInProcess - Boolean - sign of production in progress
// * ApplyingTheMaterialEditing - String - 
// * ItemVariantsAreUsed - Boolean - whether to use characteristics
// * MethodOfProductsAutoselection - EnumRef.MethodsOfProductAutoSelection - automatic item selection method
// * MethodOfItemVariantAutoselection - EnumRef.MethodsOfItemVariantAutoselection - automatic feature selection method
// * UnderRepairProduct - CatalogRef.Products,String - The item of the repaired finishedproduct
// * UnderRepairVariant - CatalogRef.ItemsCharacteristics - characteristics of the finishedproduct being repaired
// * ThereIsBOM - Boolean - indicates whether the specification exists
// * BOMIsRead - Boolean,
// * ItemsType - EnumRef.ItemsTypes,
// * ProductionProcessType - EnumRef.ProductionProcessTypes
//
Function TreeStringWithStructure(CurrentRow) Export
	
	FieldsStructure = New Structure("
		|LineKind,
		|Id,
		|Level,
		|DesignLevel,
		|Products,
		|Characteristic,
		|BillOfMaterials,
		|Count,
		|UnitOfMeasure,
		|NumberOfPackages,
		|Package,
		|Warehouse,
		|InStock,
		|Available,
		|PictureIndex,
		|ProducedInProcess,
		|ApplyingTheMaterialEditing,
		|ItemVariantsAreUsed,
		|MethodOfProductsAutoselection,
		|MethodOfItemVariantAutoselection,
		|UnderRepairProduct,
		|UnderRepairVariant,
		|ThereIsBOM,
		|BOMIsRead,
		|ItemsType,
		|ProductionProcessType");
	
	FillPropertyValues(FieldsStructure, CurrentRow);
	
	FieldsStructure.Insert("Rows", New Array);
	
	Return FieldsStructure;
	
EndFunction

Function SelectionStructureOfListOfAvailableSpecifications() Export
	
	Result = New Structure;
	
	Result.Insert("Products",   PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	
	Return Result;
	
EndFunction

Function ExpandedLevelsOfCacheConstructorTree() Export
	
	Result = New Structure;
	
	Result.Insert("ExpandedLevels");
	Result.Insert("ExpandAllMode",    0);
	Result.Insert("Control_Level",    50);
	Result.Insert("ControlLevelStep", 25);
	
	Return Result;
	
EndFunction

Procedure RecalculateReferenceLevelOfTree(Form, RowData = Undefined) Export
	
	ExpandedLevelsOfCacheTree = Form.ExpandedLevelsOfCacheTree;
	
	If RowData = Undefined Then
		ExpandedLevelsOfCacheTree.Control_Level = ExpandedLevelsOfCacheTree.Control_Level
			+ ExpandedLevelsOfCacheTree.ControlLevelStep;
	ElsIf RowData.Level > ExpandedLevelsOfCacheTree.Control_Level Then
		ExpandedLevelsOfCacheTree.Control_Level = ExpandedLevelsOfCacheTree.ControlLevelStep
			* (Int(RowData.Level/ExpandedLevelsOfCacheTree.ControlLevelStep)+1);
	EndIf;
	
EndProcedure

// Returns the key of specification selection parameters based on the passed tree line.
// 
// Parameters:
//  TreeRow - FormDataTreeItem
// 
// Returns:
//  String, Undefined -
Function KeyParametersForSelectingTreeSpecifications(TreeRow) Export
	
	Result = "MaterialsAndServices";
	
	If TreeRow <> Undefined Then 
	
		If TreeRow.LineKind = PredefinedValue("Enum.TypesOfSpecificationLines.FinishedProduct") Then
			Result = "ManufacturedProducts";
		ElsIf TreeRow.LineKind = PredefinedValue("Enum.TypesOfSpecificationLines.Products") Then
			Result = "MaterialsAndServices";
		ElsIf TreeRow.LineKind = PredefinedValue("Enum.TypesOfSpecificationLines.Material")
			And TypeOfProductionProcessOfStringTree(TreeRow) = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
			Result = "MaterialsAndServices_RepairWork";
		ElsIf TreeRow.LineKind = PredefinedValue("Enum.TypesOfSpecificationLines.Material") Then
			Result = "MaterialsAndServices_KitRAndM";
		EndIf;
	
	EndIf;
	
	Return Result;
	
EndFunction

// Returns the process type of the upper-level bill of materials based on the passed tree line.
// 
// Parameters:
//  TreeRow - FormDataTreeItem
// 
// Returns:
//  EnumRef.ProductionProcessTypes, Undefined - The Type Of Production Process Of The String Tree
Function TypeOfProductionProcessOfStringTree(TreeRow) Export
	
	ParentRow = TreeRow.GetParent();
	
	If ParentRow = Undefined Then
		Return Undefined;
	ElsIf ValueIsFilled(ParentRow.BillOfMaterials) Then
		Return ParentRow.ProductionProcessType;
	Else
		Return TypeOfProductionProcessOfStringTree(ParentRow);
	EndIf;
	
EndFunction

#EndRegion

#Region Specifications

Function CollectProductDataForSpecificationSelection(Object,
	CurrentData,
	BOMSelectionParameters,
	Form = Undefined,
	AdditionalParameters = Undefined) Export
	
	KeyOfDataPaths         = "";
	PropsNameSpecification = "BillOfMaterials";
	PropsNameObject       = "Object";
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		
		If AdditionalParameters.Property("KeyOfDataPaths") Then
			KeyOfDataPaths = AdditionalParameters.KeyOfDataPaths;
		EndIf;
		
		If AdditionalParameters.Property("PropsNameSpecification") Then
			PropsNameSpecification = AdditionalParameters.PropsNameSpecification;
		EndIf;
		
		If AdditionalParameters.Property("PropsNameObject") Then
			PropsNameObject = AdditionalParameters.PropsNameObject;
		EndIf;
		
	EndIf;
	
	Result = ProductDataStructureForSpecificationSelection();
	
	If Not BOMSelectionParameters.Property("ChoiceParameterLinks") Then
		Return Result;
	EndIf;
	
	DataPaths = Undefined;
	If Not IsBlankString(KeyOfDataPaths) Then
		DataPaths = BOMSelectionParameters.ChoiceParameterLinks.Get(StrTemplate("%1.%2", KeyOfDataPaths, PropsNameSpecification));
	Else
		For Each KeyAndValue In BOMSelectionParameters.ChoiceParameterLinks Do
			DataPaths = KeyAndValue.Value;
			Break;
		EndDo;
	EndIf;
	
	If ValueIsFilled(DataPaths) Then
		
		For Each KeyAndValue In DataPaths Do
			
			If Not ValueIsFilled(KeyAndValue.Value) Then
				Continue;
			EndIf;
			
			If TypeOf(KeyAndValue.Value) = Type("Structure") Then
				DataPath = KeyAndValue.Value.DataPath;
			Else
				DataPath = KeyAndValue.Value;
			EndIf;
			
			PathParts = StrSplit(DataPath, ".");
			FieldName = PathParts[PathParts.UBound()];
			
			If PathParts.Count() = 1 And Form <> Undefined Then
				Result[KeyAndValue.Key] = Form[FieldName];
			ElsIf PathParts.Count() = 2 And PathParts[0] = PropsNameObject Then
				Result[KeyAndValue.Key] = Object[FieldName];
			Else
				Result[KeyAndValue.Key] = CurrentData[FieldName];
			EndIf;
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Bill of Materials selection parameters.
// 
// Parameters:
//  BOMSelectionParameters - See BOMSelectionParameters
// 
// Returns:
//  Array of ChoiceParameter
Function BillOfMaterialsItemSelectionParameters(BOMSelectionParameters) Export
	
	ChoiceParameters = New Array();
	
	For Each ParameterValue In BOMSelectionParameters Do
		If ParameterValue.Key = "ChoiceParameterLinks" Then
			Continue;
		EndIf;
		NewParameter1 = New ChoiceParameter(ParameterValue.Key, ParameterValue.Value);
		ChoiceParameters.Add(NewParameter1);
	EndDo;
	
	If BOMSelectionParameters.Property("AvailableTypes") And BOMSelectionParameters.AvailableTypes.Count() <> 0 Then
		NewParameter1 = New ChoiceParameter("Filter.ProductionProcessType", New FixedArray(BOMSelectionParameters.AvailableTypes));
		ChoiceParameters.Add(NewParameter1);
	EndIf;
	
	If BOMSelectionParameters.Property("AvailableStatuses") And BOMSelectionParameters.AvailableStatuses.Count() <> 0 Then
		NewParameter1 = New ChoiceParameter("Filter.Status", New FixedArray(BOMSelectionParameters.AvailableStatuses));
		ChoiceParameters.Add(NewParameter1);
	EndIf;
	
	Return ChoiceParameters;
	
EndFunction

#EndRegion

#Region DescriptionManufacturingProcess

// Determines the availability of multi-stage specifications
// 
// Returns:
//  Boolean
Function MultiStageProductionProcessIsAvailable() Export
	
	Result = False;
	Result = True;
	Return Result;
	
EndFunction

// Error text unavailability of a multi-stage production process
// 
// Returns:
//  String
Function MultiStageProductionProcessErrorText() Export
	
	Result = NStr("vi = 'Bảng kê chi tiết nhiều công đoạn không hỗ trợ trong KA. Việc hỗ trợ các bảng kê chi tiết như vậy có trong 1C:ERP.';
					|ru = 'Многоэтапные спецификации не поддерживаются в КА. Поддержка таких спецификаций имеется в 1C:ERP.';
					|en = 'Multi-stage BOMs are not supported in PA. They are supported in 1C:ERP.'; fa = 'Multi-stage BOMs are not supported in PA. They are supported in 1C:ERP.';
					|it = 'Многоэтапные спецификации не поддерживаются в КА. Поддержка таких спецификаций имеется в 1C:ERP.';
					|pl = 'Multi-stage BOMs are not supported in PA. They are supported in 1C:ERP.';
					|tr = 'Çok aşamalı ürün reçeteleri Karmaşık Otomasyonda desteklenmemektedir. Bu tür ürün reçeteleri için 1C:ERP üzerinde destek mevcuttur.'");
	Result = NStr("vi = 'Hỗ trợ chỉ bảng kê chi tiết một công đoạn.';
					|ru = 'Поддерживаются только одноэтапные спецификации.';
					|en = 'Only one-step BOMs are supported.'; fa = 'Only one-step BOMs are supported.';
					|it = 'Поддерживаются только одноэтапные спецификации.';
					|pl = 'Only one-step BOMs are supported.';
					|tr = 'Sadece tek aşamalı ürün reçeteleri desteklenmektedir.'");
	Return Result;
	
EndFunction

#EndRegion

#Region ApplicationOfMaterials

// Fills in information about automatic material selection in the table part row
//
Procedure FillInInformationOnUseOfMaterial(String) Export
	
	StringProbability = "";
	If String.Probability > 0 Then
		
		If String.AlternateType Then
			Template = NStr("vi = 'theo yêu cầu (xác suất %1)';
							|ru = 'по требованию (вероятность %1)';
							|en = 'on demand (probability %1)'; fa = 'on demand (probability %1)';
							|it = 'su richiesta (probabilità %1)';
							|pl = 'na żądanie (prawdopodobieństwo %1)';
							|tr = 'talep üzerine (olasılık %1)'");
		Else
			Template = NStr("vi = 'theo mặc định (xác suất  %1)';
							|ru = 'по умолчанию (вероятность %1)';
							|en = 'by default (probability %1)'; fa = 'by default (probability %1)';
							|it = 'di default (probabilità %1)';
							|pl = 'domyślnie (prawdopodobieństwo %1)';
							|tr = 'varsayılan olarak (olasılık %1)'");
		EndIf;
		StringProbability = StrTemplate(Template, "" + String.Probability + "%");
		
	ElsIf String.AlternateType Then
		
		StringProbability = NStr("vi = 'theo yêu cầu';
								|ru = 'по требованию';
								|en = 'on demand'; fa = 'on demand';
								|it = 'su richiesta';
								|pl = 'na żądanie';
								|tr = 'talep üzerine'");
		
	EndIf;
	String.ApplyingTheMaterialEditing = String.MaterialApplication + ?(Not IsBlankString(StringProbability) And Not IsBlankString(String.MaterialApplication),", ","") + StringProbability;
	
EndProcedure

#EndRegion

#Region AssignmentParameters

// Constructor for describing the value of a specification assignment parameter
// 
// Returns:
// 	Structure - From:
// * Condition - See StructureOfSelectionConditionByProductProperties
// * Value - ValueList,Characteristic.AdditionalAttributesAndInfo - parameter value
// * Value1 - Number - value of the interval condition From
// * Value2 - Number - value of the interval condition up To
Function SpecificationAssignmentParameterValueStructure() Export
	
	Result = New Structure;
	
	Result.Insert("Condition");
	Result.Insert("Value");
	Result.Insert("Value1");
	Result.Insert("Value2");
	
	Return Result;
	
EndFunction

// Determines whether the assignment parameter must be filled in
// 
// Parameters:
//  Condition - See StructureOfSelectionConditionByProductProperties
//  ValueType - Type
// 
// Returns:
//  Boolean - Mandatory
Function FillingInValueOfDestinationParameterIsMandatory(Condition, ValueType) Export
	
	Return Not Condition.Fullness
		And Not (ValueType.ContainsType(Type("Number")) And ValueType.Types().Count() = 1);
	
EndFunction

// Defines the type of the destination parameter value by the type of parameter and the type of the props value
// 
// Parameters:
//  ParameterKind - EnumRef.TypesOfBOMAssignmentParameters - type of parameter
//  AttributeValueType - Type
// 
// Returns:
//  Type - type of parameter value
Function TypeOfValueOfDestinationParameter(ParameterKind, AttributeValueType) Export
	
	ValueType = AttributeValueType;
	
	If ParameterKind = PredefinedValue("Enum.TypesOfBOMAssignmentParameters.ProductionDispatcherBusinessUnit") Then
		ValueType = New TypeDescription("CatalogRef.BusinessStructure");
	ElsIf ParameterKind = PredefinedValue("Enum.TypesOfBOMAssignmentParameters.LineOfBusiness") Then
		ValueType = New TypeDescription("CatalogRef.LinesOfBusiness");
	EndIf;
	
	Return ValueType;
	
EndFunction

// Determines the availability of the interval for the destination parameter
// 
// Parameters:
//  ValueType - Type
// 
// Returns:
//  Boolean - Interval availability
Function IntervalOfDestinationParameterIsAvailable(ValueType) Export
	
	Return ValueType.ContainsType(Type("Number")) Or ValueType.ContainsType(Type("Date"));
	
EndFunction

#EndRegion

#Region ImportProductionMasterData

// The key for describing the upload object by Catalog name and tab name. parts.
// 
// Parameters:
//  MetadataObjectName - String
//  TSName - String
// 
// Returns:
//  String - Key for the description of the upload object
Function KeyForDescriptionOfUploadedDataElement(MetadataObjectName, TSName = "") Export
	
	Return ?(IsBlankString(TSName), MetadataObjectName, StrTemplate("%1_%2", MetadataObjectName, TSName));
	
EndFunction

// The key of the object processing algorithm when loading.
// 
// Parameters:
//  EventName - String
//  MetadataObjectName - String
//  TSName - String
// 
// Returns:
//  String
Function KeyOfObjectProcessingAlgorithmWhenLoading(EventName, MetadataObjectName, TSName = "") Export
	
	Return StrTemplate("%1_%2", KeyForDescriptionOfUploadedDataElement(MetadataObjectName, TSName), EventName);
	
EndFunction

// The key of the products and materials section.
// 
// Returns:
//  String
Function KeyOfProductsAndMaterialsSection() Export
	
	Return "products";
	
EndFunction

// The key of the production equipment section.
// 
// Returns:
//  String
Function KeyOfProductionEquipmentSection() Export
	
	Return "equipment";
	
EndFunction

// The key of the product compositions section.
// 
// Returns:
//  String
Function KeyOfProductCompositionsSection() Export
	
	Return "bom";
	
EndFunction

// The key of the production technology section.
// 
// Returns:
//  String
Function KeyOfProductionTechnologySection() Export
	
	Return "technology";
	
EndFunction

// The key of the permission section for the replacement of materials.
// 
// Returns:
//  String
Function KeyOfMaterialsReplacementSection() Export
	
	Return "replacements";
	
EndFunction

// The composition of the uploaded data by default
// 
// Returns:
//  Structure of String
Function SectionsToBeProcessedByConstructor() Export
	
	Result = New Structure;
	
	Result.Insert(KeyOfProductsAndMaterialsSection());
	Result.Insert(KeyOfProductionEquipmentSection());
	Result.Insert(KeyOfProductCompositionsSection());
	Result.Insert(KeyOfProductionTechnologySection());
	
	Return Result;
	
EndFunction

// The order in which partitions are processed when loading.
// 
// Returns:
//  Array of String
Function OrderOfProcessingSections() Export
	
	Result = New Array;
	
	Result.Add(KeyOfProductsAndMaterialsSection());
	Result.Add(KeyOfProductionEquipmentSection());
	Result.Add(KeyOfProductCompositionsSection());
	Result.Add(KeyOfProductionTechnologySection());
	Result.Add(KeyOfMaterialsReplacementSection());
	
	Return Result;
	
EndFunction

// The order in which partitions are processed when loading.
// 
// Parameters:
//  DataSourceSettings - See Catalogs.SourcesToImportProductionMasterData.DataSourceSettingsConstructor
// 
// Returns:
//  Array of String
Function OrderOfProcessingSectionsOfSource(DataSourceSettings = Undefined) Export
	
	Result = New Array;
	
	For Each SectionKey In OrderOfProcessingSections() Do
		
		If DataSourceSettings = Undefined
			Or DataSourceSettings.SectionsToBeProcessed.Property(SectionKey) Then
			
			Result.Add(SectionKey);
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Presentation of the data file by partition key.
// 
// Parameters:
//  SectionKey - String
// 
// Returns:
//  String
Function PresentationOfDataFileByPartitionKey(SectionKey) Export
	
	Result = SectionKey;
	
	If SectionKey = KeyOfProductsAndMaterialsSection() Then
		Result = NStr("vi = 'Sản phẩm và nguyên vật liệu';
						|ru = 'Изделия и материалы';
						|en = 'Finished products and materials'; fa = 'محصولات نهایی و مواد';
						|it = 'Изделия и материалы';
						|pl = 'Finished products and materials';
						|tr = 'Nihai ürünler ve malzemeler'");
	ElsIf SectionKey = KeyOfProductionEquipmentSection() Then
		Result = NStr("vi = 'Thiết bị';
						|ru = 'Оборудование';
						|en = 'Equipment'; fa = 'تجهیزات';
						|it = 'Оборудование';
						|pl = 'Equipment';
						|tr = 'Ekipman'");
	ElsIf SectionKey = KeyOfProductCompositionsSection() Then
		Result = NStr("vi = 'Thành phần';
						|ru = 'Составы';
						|en = 'Compositions'; fa = 'ترکیب‌ها';
						|it = 'Составы';
						|pl = 'Compositions';
						|tr = 'İçerikler'");
	ElsIf SectionKey = KeyOfProductionTechnologySection() Then
		Result = NStr("vi = 'Công nghệ';
						|ru = 'Технология';
						|en = 'Technology'; fa = 'فناوری';
						|it = 'Технология';
						|pl = 'Technology';
						|tr = 'Teknoloji'");
	ElsIf SectionKey = KeyOfMaterialsReplacementSection() Then
		Result = NStr("vi = 'Thay thế';
						|ru = 'Замены';
						|en = 'Replacements'; fa = 'جایگزینی‌ها';
						|it = 'Замены';
						|pl = 'Replacements';
						|tr = 'İkameler'");
	EndIf;
	
	Return Result;
	
EndFunction

// Name of the event before loading the object.
// 
// Returns:
//  String - Event name
Function NameOfEventBeforeLoadingObject() Export
	
	Return "BeforeImport";
	
EndFunction

// Name of the event before recording the object.
// 
// Returns:
//  String - Event name
Function NameOfEventBeforeRecordingObject() Export
	
	Return "BeforeWrite";
	
EndFunction

// Name of the End event For loading data by source
// 
// Returns:
//  String - Event name
Function EventNameLoadingEnd() Export
	
	Return "ImportProductionMasterData_Completion";
	
EndFunction

// The communication key of the type of object processing algorithm.
// 
// Parameters:
//  EventName - String
// 
// Returns:
//  UUID
Function CommunicationKeyOfTypeOfObjectProcessingAlgorithm(EventName) Export
	
	Result = CommonClientServer.BlankUUID();
	
	If EventName = NameOfEventBeforeLoadingObject() Then
		Result = New UUID("bba2d7a1-b1a9-4761-a878-180d0a45c0fd");
	ElsIf EventName = NameOfEventBeforeRecordingObject() Then
		Result = New UUID("5a278bf8-8055-4a58-8a1b-2122c98fb495");
	EndIf;
	
	Return Result;
	
EndFunction

// Presentation Of the Type Of Object Processing Algorithm
//
// Parameters:
//  EventName - String
// 
// Returns:
//  String
Function PresentationOfTypeOfObjectProcessingAlgorithm(EventName) Export
	
	Result = "";
	
	If EventName = ProductDataManagementClientServer.NameOfEventBeforeLoadingObject() Then
		Result = NStr("vi = 'Trước khi kết nhập';
						|ru = 'Перед загрузкой';
						|en = 'Before importing'; fa = 'Before importing';
						|it = 'Перед загрузкой';
						|pl = 'Before importing';
						|tr = 'Yükleme öncesi'");
	ElsIf EventName = ProductDataManagementClientServer.NameOfEventBeforeRecordingObject() Then
		Result = NStr("vi = 'Trước khi ghi lại';
						|ru = 'Перед записью';
						|en = 'Before saving'; fa = 'Before saving';
						|it = 'Перед записью';
						|pl = 'Before saving';
						|tr = 'Kayıttan önce'");
	EndIf;
	
	Return Result;
	
EndFunction

// List OF groups OF Attributes of the uploaded data ELEMENT
// Parameters:
//  ToExclude - Boolean - include Attributes that are not available for interactive configuration
// 
// Returns:
//  Array of String
Function AttributesGroups(ToExclude = False) Export
	
	Result = New Array;
	
	Result.Add("AttributesIds");
	Result.Add("AttributesStandard");
	Result.Add("AttributesApplication");
	Result.Add("ServiceDetails");
	Result.Add("AdditionalDetails_");
	
	If ToExclude Then
		Result.Add("AttributesExcluded");
	EndIf;
	
	Return Result;
	
EndFunction

// List of groups of Attributes of the item header
// Parameters:
//  ToExclude - Boolean - include Attributes that are not available for interactive configuration
// 
// Returns:
//  Array of String
Function GroupsOfAttributesForItemHeader(ToExclude = False) Export
	
	Result = New Array;
	
	Result.Add("AttributesStandard");
	Result.Add("AttributesApplication");
	
	If ToExclude Then
		Result.Add("AttributesExcluded");
	EndIf;
	
	Return Result;
	
EndFunction

// Register of correspondence by data type.
// Parameters:
//  DataType - String
// 
// Returns:
//  Structure - Register Of Correspondence By Data Type:
// * RegisterName - String
// * TableName - String
// * ObjectFieldsAvailable - Array
// * ObjectFieldsRedefinition - Structure
Function ParametersOfCorrespondenceRegister(DataType) Export
	
	Result = New Structure;
	Result.Insert("RegisterName",                "");
	Result.Insert("TableName",                 "");
	Result.Insert("ObjectFieldsAvailable",       New Array);
	Result.Insert("ObjectFieldsRedefinition", New Structure);
	
	If TypeOf(DataType) = Type("CatalogRef.Products")
			Or TypeOf(DataType) = Type("CatalogRef.ItemsCharacteristics")
			Or (TypeOf(DataType) = Type("String") And DataType = "Products") Then
				
		Result.RegisterName = "ItemMappingToImportMasterData";
		
		Result.ObjectFieldsAvailable.Add("Products");
		Result.ObjectFieldsAvailable.Add("Characteristic");
		
		Result.ObjectFieldsRedefinition.Insert("Products");
		Result.ObjectFieldsRedefinition.Insert("Characteristic");
		Result.ObjectFieldsRedefinition.Insert("MetadataObject", "VALUE(Catalog.Products.EmptyRef)");
		Result.ObjectFieldsRedefinition.Insert("ObjectReference", "UNDEFINED");
	
	Else
		
		Result.RegisterName = "ObjectMappingToImportMasterData";
		
		Result.ObjectFieldsAvailable.Add("ObjectReference");
		
		Result.ObjectFieldsRedefinition.Insert("Products", "VALUE(Catalog.Products.EmptyRef)");
		Result.ObjectFieldsRedefinition.Insert("Characteristic", "VALUE(Catalog.ItemsCharacteristics.EmptyRef)");
		Result.ObjectFieldsRedefinition.Insert("MetadataObject");
		Result.ObjectFieldsRedefinition.Insert("ObjectReference", "CAST(&TableName.ObjectReference AS &TypeName)");
		
	EndIf;
	
	Result.TableName = StrTemplate("InformationRegister.%1", Result.RegisterName);
	
	Return Result;
	
EndFunction

// Description of the file handling settings after the upload is completed.
// Parameters:
//  State_Description - String
// 
// Returns:
//  Structure - Description Of The Action With The Constructor Files:
// * State - EnumRef.ImportMasterDataStates
// * Action - EnumRef.ImportMasterDataActionsWithFiles
// * Directory - String
Function DescriptionOfActionWithConstructorFiles(State_Description = "DoNotPerformed") Export
	
	Result = New Structure;
	
	Result.Insert("State_Description", State_Description);
	Result.Insert("State", PredefinedValue(StrTemplate("Enum.ImportMasterDataStates.%1", State_Description)));
	Result.Insert("Action",  PredefinedValue("Enum.ImportMasterDataActionsWithFiles.NotDefined"));
	Result.Insert("Directory",   "");
	
	Return Result;
	
EndFunction

// The rule for resolving a conflict when searching is to register an error.
// 
// Returns:
//  Number
Function RuleForResolvingConflictWhenSearchingLogError() Export
	
	Return 0;
	
EndFunction

// The rule for resolving conflicts when searching is to sort.
// 
// Returns:
//  Number
Function RuleForResolvingConflictsWhenSearchingSort() Export
	
	Return 1;
	
EndFunction

// Constructor of the structure of the search conflict resolution rule
// 
// Returns:
//  Structure - Rule for resolving conflicts when searching for a constructor:
// * Rule - Number - Rule Number
// * SortingSettings - Array - setting up sorting
Function DescriptionOfConflictResolutionSettingsForSearchConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("Rule", RuleForResolvingConflictWhenSearchingLogError());
	Result.Insert("SortingSettings", New Array);
	
	Return Result;
	
EndFunction

// Constructor of the Object Update configuration structure
// 
// Returns:
//  Structure - Rule for resolving conflicts when searching for a constructor:
// * UpdateOption - EnumRef.ImportMasterDataObjectUpdateOptions
Function DescriptionOfObjectUpdateSettingsConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("UpdateOption", PredefinedValue("Enum.ImportMasterDataObjectUpdateOptions.UpdateIfThereAreChanges"));
	Result.Insert("Parameters");
	
	Return Result;
	
EndFunction

// Description of the sorting element.
// 
// Returns:
//  Structure - Description of the constructor sorting element:
// * AttributeName - String
// * Direction - String
Function DescriptionOfSortingElementConstructor() Export
	
	Result = New Structure;
	
	Result.Insert("AttributeName", "");
	Result.Insert("Direction",  "");
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Function StructureDescriptionOfReleaseBatch() Export
	
	ReleaseBatchDescription = New Structure("
		|MultipleIssue,
		|ProductionIssueByCustomPortions,
		|
		|ProductKind,
		|Products,
		|Characteristic,
		|Package,
		|NumberOfPackages,
		|
		|UnitOfProductMeasurement,
		|UnitOfMeasurementOfReleaseBatch");
	
	ReleaseBatchDescription.MultipleIssue = False;
	ReleaseBatchDescription.ProductionIssueByCustomPortions = False;
	
	ReleaseBatchDescription.ProductKind = PredefinedValue("Catalog.ItemKinds.EmptyRef");
	ReleaseBatchDescription.Products = PredefinedValue("Catalog.Products.EmptyRef");
	ReleaseBatchDescription.Characteristic = PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef");
	
	ReleaseBatchDescription.Package = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	ReleaseBatchDescription.NumberOfPackages = 0;
	
	ReleaseBatchDescription.UnitOfProductMeasurement = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch = PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef");
	
	Return ReleaseBatchDescription;
	
EndFunction

Function BasicUnitOfTime() Export

	Return PredefinedValue("Enum.TimeMeasureUnits.Minute");

EndFunction

Function DetailsSettingUpPropertyMatching() Export
	
	Return "MaterialProperty,ProductsProperty,PropertyValue,ValueCalculationAlgorithm,ValueSelectionMethod";
	
EndFunction

// Constructor of parameters for selecting bill of materials for the process type - Kitting
// 
// Returns:
// 	Structure
//
Function ParametersForSelectingSpecificationsForManufacturingAssembly() Export
	
	ChoiceParameters = BOMSelectionParameters();
	
	ChoiceParameters.AvailableTypes.Add(PredefinedValue("Enum.ProductionProcessTypes.Assembly"));
	ChoiceParameters.AvailableStatuses.Add(PredefinedValue("Enum.BOMStatuses.Valid"));
	
	Return ChoiceParameters;
	
EndFunction

// Constructor of parameters for selecting bill of materials for the type of process - Performing repair work
// 
// Returns:
// 	Structure
//
Function ParametersForSelectingBillOfMaterialsForRepairWork() Export
	
	ChoiceParameters = BOMSelectionParameters();
	
	ChoiceParameters.AvailableTypes.Add(PredefinedValue("Enum.ProductionProcessTypes.PerformRM"));
	ChoiceParameters.AvailableStatuses.Add(PredefinedValue("Enum.BOMStatuses.Valid"));
	
	Return ChoiceParameters;
	
EndFunction

// Constructor of Bill of Materials selection parameters for the type of process - Reverse Kit
// 
// Returns:
// 	Structure
//
Function ParametersForSelectingBillOfMaterialsForReverseKitting() Export
	
	ChoiceParameters = BOMSelectionParameters();
	
	ChoiceParameters.AvailableTypes.Add(PredefinedValue("Enum.ProductionProcessTypes.Disassembly"));
	ChoiceParameters.AvailableStatuses.Add(PredefinedValue("Enum.BOMStatuses.Valid"));
	
	Return ChoiceParameters;
	
EndFunction

// Generates an array of selection conditions by properties
// 
// Returns:
// 	Array of Structure - From:
// 		* Id - String - condition ID
// 		* Presentation - String - condition representation
// 		* Comparison - Boolean - flag of the comparison condition
// 		* Template - String - the pattern condition
Function ListOfSelectionCriteriaByProductProperties()
	
	Result = New Array;
	
	Attributes = "Id, Presentation, Comparison, Template";
	
	Condition = New Structure(Attributes, "Equal",             NStr("vi = 'Bằng';
																	|ru = 'Равно';
																	|en = 'Equal to'; fa = 'برابر با';
																	|it = 'Uguale';
																	|pl = 'Równa się';
																	|tr = 'Eşit'"),               False,   "%1 = %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "NotEqual",           NStr("vi = 'Không bằng';
																	|ru = 'Не равно';
																	|en = 'Not equal'; fa = 'Not equal';
																	|it = 'Non equo';
																	|pl = 'Nie równa się';
																	|tr = 'Eşit değil'"),            False,   "%1 <> %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "Greater",            NStr("vi = 'Lớn hơn';
																	|ru = 'Больше';
																	|en = 'Greater than'; fa = 'Greater than';
																	|it = 'Maggiore';
																	|pl = 'Więcej';
																	|tr = 'Büyük'"),              True, "%1 > %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "GreaterOrEqual",    NStr("vi = 'Hơn hoặc bằng';
																	|ru = 'Больше или равно';
																	|en = 'Greater than or equal'; fa = 'Greater than or equal';
																	|it = 'Maggiore o uguale';
																	|pl = 'Więcej lub równo';
																	|tr = 'Büyüktür veya eşittir'"),    True, "%1 >= %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "Less",            NStr("vi = 'Nhỏ hơn';
																	|ru = 'Меньше';
																	|en = 'Less'; fa = 'Less';
																	|it = 'Minore';
																	|pl = 'Mniej';
																	|tr = 'Küçük'"),              True, "%1 < %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "LessOrEqual",    NStr("vi = 'Ít hơn hoặc bằng';
																|ru = 'Меньше или равно';
																|en = 'Less than or equal'; fa = 'Less than or equal';
																|it = 'Minore o uguale';
																|pl = 'Mniej lub równo';
																|tr = 'Küçüktür veya eşittir'"),    True, "%1 <= %2");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "InList",           NStr("vi = 'Trong danh sách';
																	|ru = 'В списке';
																	|en = 'In the list'; fa = 'In the list';
																	|it = 'Nella lista';
																	|pl = 'W liście';
																	|tr = 'Listede'"),            False,   "%1 IN (%2)");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "NotInList",         NStr("vi = 'Không trong danh sách';
																	|ru = 'Не в списке';
																	|en = 'Not in the list'; fa = 'Not in the list';
																	|it = 'Non nella lista';
																	|pl = 'Nie w liście';
																	|tr = 'Listede değil'"),         False,   "NOT %1 IN (%2)");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "InInterval",        NStr("vi = 'Trong khoảng (>, <)';
																	|ru = 'В интервале (>,<)';
																	|en = 'Within interval (>,<)'; fa = 'Within interval (>,<)';
																	|it = 'Nell''intervallo (>,<)';
																	|pl = 'W przedziale (>,<)';
																	|tr = 'Aralığı (>,<)'"),   True, "%1 > %2 AND %1 < %3");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "InIntervalIncluding", NStr("vi = 'Trong khoảng (> =, <=)';
																		|ru = 'В интервале (>=,<=)';
																		|en = 'Within interval (>=,<=)'; fa = 'Within interval (>=,<=)';
																		|it = 'Nell''intervallo (>=,<=)';
																		|pl = 'W przedziale (>=,<=)';
																		|tr = 'Aralığı (>=,<=)'"), True, "%1 >= %2 AND %1 <= %3");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "Filled",         NStr("vi = 'Đã điền';
																|ru = 'Заполнено';
																|en = 'Filled'; fa = 'پرشده';
																|it = 'Compilato';
																|pl = 'Wypełniono';
																|tr = 'Dolduruldu'"),           False,   "NOT %1 IN (UNDEFINED, FALSE, 0)");
	Result.Add(Condition);
	Condition = New Structure(Attributes, "NotFilled",       NStr("vi = 'Chưa điền';
																	|ru = 'Не заполнено';
																	|en = 'Blank'; fa = 'خالی';
																	|it = 'Non compilato';
																	|pl = 'Nie wypełnione';
																	|tr = 'Boş'"),        False,   "%1 IN (UNDEFINED, FALSE, 0)");
	Result.Add(Condition);
	
	Return Result;
	
EndFunction

Function StructureOfSelectionConditionsByProductProperties() Export
	
	ConditionsStructure = New Structure;
	
	Conditions = ListOfSelectionCriteriaByProductProperties();
	For Each Condition In Conditions Do
		
		ConditionProperties = StructureOfSelectionConditionByProductProperties(Condition);
		
		ConditionsStructure.Insert(Condition.Id, ConditionProperties);
		
	EndDo;
	
	Return ConditionsStructure;
	
EndFunction

// Constructor of the selection criteria structure by properties
// 
// Parameters:
// 	Condition - Structure - From:
// 		* Id - String - condition ID
// 		* Presentation - String - condition representation
// 		* Comparison - Boolean - flag of the comparison condition
// 		* Template - String - the pattern condition
// Returns:
// 	Structure - From:
//		* Id - String - condition ID
//		* Presentation - String - condition representation
//		* Comparison - Boolean - flag of the comparison condition
//		* Template - String - the pattern condition
//		* List - Boolean - sign of working conditions with the list
//		* Interval - Boolean - indicates an interval condition
//		* Fullness - Boolean - indicates the condition for verifying fullness
//		* Including - Boolean - flag for a condition that includes a border
//		* Reverse_1 - Boolean - inversion flag in the condition
Function StructureOfSelectionConditionByProductProperties(Condition) Export
	
	ConditionsIncluding  = StrSplit("Equal,InList,GreaterOrEqual,LessOrEqual,InIntervalIncluding", ",");
	ConditionsAreReversed = StrSplit("NotEqual,NotInList", ",");
	
	Result = New Structure;
	
	Result.Insert("Id", Condition.Id);
	Result.Insert("Presentation", Condition.Presentation);
	Result.Insert("Comparison",     Condition.Comparison);
	Result.Insert("Template",        Condition.Template);
	Result.Insert("List",        StrFind(Condition.Id, "InList") > 0);
	Result.Insert("Interval",      StrFind(Condition.Id, "InInterval") > 0);
	Result.Insert("Fullness", StrFind(Condition.Id, "Filled") > 0);
	Result.Insert("Including",       ConditionsIncluding.Find(Condition.Id) <> Undefined);
	Result.Insert("Reverse_1",      ConditionsAreReversed.Find(Condition.Id) <> Undefined);
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion