#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	NotCheckedAttributeArray = New Array();
	
	NotCheckedAttributeArray.Add("MaterialsAndServices.Products");
	NotCheckedAttributeArray.Add("MaterialsAndServices.Characteristic");
	NotCheckedAttributeArray.Add("MaterialsAndServices.ProductCostElement");
	NotCheckedAttributeArray.Add("MaterialsAndServices.NumberOfPackages");
	NotCheckedAttributeArray.Add("LaborCosts.Count");
	
	If Status = Enums.TechnologicalProcessStatuses.Valid Then
		
		If MaterialsAndServices.Count() > 0 Then
			CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
			CheckParameters.TSName = "MaterialsAndServices";
			If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
				StringsList = MaterialsAndServices.FindRows(New Structure("MethodOfItemVariantAutoselection", 
					Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
				CheckParameters.StringsList = StringsList;
			EndIf;
			ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		EndIf;
		
		CheckCompletionOfCalculationArticle(Cancel);
		
		CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel);
		
		Catalogs.TechnologicalProcesses.SequenceOfOperationsIsCorrect(Ref, Cancel);
		ProductionProcessEditor.CheckCorrectnessOfFillingInOperations(Ref, Department, Cancel);
		
		CheckFillingInProductsAndQuantities(Cancel);
		
	Else
		NotCheckedAttributeArray.Add("Department");
	EndIf;
	
	If Not CalculateFactor Then
		NotCheckedAttributeArray.Add("NumeratorFactor");
		NotCheckedAttributeArray.Add("FactorDenominator");
	EndIf;
	
	ObjectTabularSections = Metadata().TabularSections;
	CheckSelectionOfOperations("MaterialsAndServices", ObjectTabularSections.MaterialsAndServices.Synonym, Cancel);
	CheckSelectionOfOperations("LaborCosts",ObjectTabularSections.LaborCosts.Synonym, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		
		FillInDataType = TypeOf(FillingData);
		
		If FillInDataType = Type("CatalogRef.Products") Then
			
			AttributesStructure1 = Common.ObjectAttributesValues(FillingData, "IsFolder, ProductKind");
			If AttributesStructure1.IsFolder = False Then
				ForFinishedProductsKind = AttributesStructure1.ProductKind;
			EndIf;
			
		EndIf;
		
		EmployeeResponsible = Users.CurrentUser();
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return;
	EndIf;
	
	Status         = Enums.TechnologicalProcessStatuses.UnderDevelopment;
	EmployeeResponsible  = Users.CurrentUser();
	Department  = Catalogs.BusinessStructure.EmptyRef();
	
	ClearSelectionOfOperations();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		
		If DeletionMark Then
			Status = Enums.TechnologicalProcessStatuses.Closed;
			ClearSelectionOfOperations();
		EndIf;
		
		BeforeRecordingCurrentTechnologicalProcess(Cancel);
		
		FillInServiceDetails();
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure BeforeRecordingCurrentTechnologicalProcess(Cancel)

	If Status = Enums.TechnologicalProcessStatuses.Valid And Not DeletionMark And Not Cancel Then
		
		ClearUnusedData();
		
		UpdateOperationBinding(Cancel);
		
	EndIf;
	
EndProcedure

// Updates the value of the Operation prop in the table parts
//  - if the Edit Operation prop is not empty, then substitutes the value from it
//  - if the Edit operation prop is empty, it substitutes the last operation.
//
Procedure UpdateOperationBinding(Cancel)
	
	FirstOperation = Undefined;
	
	EmptyOperation = Catalogs.ManufacturingOperations.EmptyRef();
	
	GetExtremeOperations = MaterialsAndServices.Find(EmptyOperation, "OperationEdit") <> Undefined
		Or LaborCosts.Find(EmptyOperation, "OperationEdit") <> Undefined;
	
	If GetExtremeOperations Then
		
		Query = New Query(
			"SELECT
			|	ManufacturingOperations.Ref,
			|	CASE
			|		WHEN ManufacturingOperations.OperationNumber = 1
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS FirstOperation
			|FROM
			|	Catalog.ManufacturingOperations AS ManufacturingOperations
			|WHERE
			|	ManufacturingOperations.Owner = &Owner
			|	AND NOT ManufacturingOperations.DeletionMark");
		
		Query.SetParameter("Owner", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			If Selection.FirstOperation Then
				FirstOperation = Selection.Ref;
			EndIf;
			
		EndDo;
		
	EndIf; 
	
	TabularSections = New Array;
	TabularSections.Add("MaterialsAndServices");
	TabularSections.Add("LaborCosts");
	
	For Each TabularSection In TabularSections Do
		
		For Each String In ThisObject[TabularSection] Do
			
			If String.OperationEdit.IsEmpty() Then
				
				String.Operation = FirstOperation;
				
			Else
				
				String.Operation = String.OperationEdit;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ClearSelectionOfOperations()

	TabularSections = New Array;
	TabularSections.Add("MaterialsAndServices");
	TabularSections.Add("LaborCosts");
	
	For Each TabularSection In TabularSections Do
		
		For Each String In ThisObject[TabularSection] Do
			
			String.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			String.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckSelectionOfOperations(TableName, TablePresentation, Cancel)

	If DeletionMark Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("vi = 'Không được phép chọn các thao tác được đánh dấu để xóa (danh sách ""%1"", dòng%2).';
							|ru = 'Не допускается выбор операций помеченных на удаление (список ""%1"", строка %2).';
							|en = 'It is not allowed to select operations marked for deletion (the ""%1"" list, line %2).'; fa = 'It is not allowed to select operations marked for deletion (the ""%1"" list, line %2).';
							|it = 'Non è permessa la scelta di operazioni contrassegnate per la cancellazione (elenco ""%1"", riga %2).';
							|pl = 'Wybór operacji zaznaczonych do usunięcia jest niedozwolony (lista ""%1"", wiersz %2).';
							|tr = 'Silinmek üzere işaretlenen işlemlerin seçilmesine izin verilmemektedir (""%1"" listesi, %2 satırı).'");
	
	TabularSection = ThisObject[TableName]; // CatalogTabularSection.TechnologicalProcesses.MaterialsAndServices
	For Each TableRow In TabularSection Do
		If TableRow.OperationEdit.IsEmpty() 
			Or Not Common.ObjectAttributeValue(TableRow.OperationEdit, "DeletionMark") Then
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
																					TablePresentation, 
																					Format(TableRow.LineNumber, "NG="));
																					
		Field = CommonClientServer.PathToTabularSection(TableName, TableRow.LineNumber, "OperationEdit");
		Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
	EndDo; 
	
EndProcedure

Procedure CheckFillingInProductsAndQuantities(Cancel)
	
	MessageTemplateProducts = NStr("vi = 'Cột ""Mặt hàng"" trong hàng%1 của danh sách ""%2"" không được điền';
									|ru = 'Не заполнена колонка ""Номенклатура"" в строке %1 списка ""%2""';
									|en = 'Column ""Items"" in line %1 of the ""%2"" list is not filled in'; fa = 'Column ""Items"" in line %1 of the ""%2"" list is not filled in';
									|it = 'La colonna ""articolo"" nella riga %1 dell''elenco ""%2"" non è compilata';
									|pl = 'Nie wypełniona kolumna ""Produkty"" w wierszu%1 listy ""%2""';
									|tr = '""%2"" listesinin %1 satırında ""Öğe"" sütunu doldurulmadı'");
	MessageTemplateQuantity   = NStr("vi = 'Cột ""Số lượng"" trong hàng %1 của danh sách ""%2"" không được điền';
									|ru = 'Не заполнена колонка ""Количество"" в строке %1 списка ""%2""';
									|en = 'Column ""Quantity"" in line %1 of the ""%2"" list is not filled in'; fa = 'Column ""Quantity"" in line %1 of the ""%2"" list is not filled in';
									|it = 'La colonna ""Quantità"" nella riga %1 dell''elenco ""%2"" non è compilata';
									|pl = 'Kolumna ""Ilość"" w wierszu %1 listy ""%2"" nie jest wypełniona.';
									|tr = '""%2"" listesinin %1 satırındaki ""Miktar"" sütunu doldurulmadı'");
	
	TSMetadata = Metadata.Catalogs.TechnologicalProcesses.TabularSections;
	
	VerificationDetails_1 = "TSName, Products, Count";
	
	ChecksArray = New Array;
	ChecksArray.Add(New Structure(VerificationDetails_1, "MaterialsAndServices", "Products", "NumberOfPackages"));
	ChecksArray.Add(New Structure(VerificationDetails_1, "LaborCosts", "", "Count"));
	
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.TechnologicalProcesses.MaterialsAndServices
		For Each CurrentRow In TabularSection Do
			
			If Validation.Products <> ""
				And CurrentRow[Validation.Products].IsEmpty()
				And (CurrentRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData 
					Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
				
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							MessageTemplateProducts, 
							Format(CurrentRow.LineNumber, "NG="),
							TSMetadata[Validation.TSName].Synonym);
							
					Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Products);
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			EndIf;
			
			If Status = Enums.TechnologicalProcessStatuses.Valid Then
				
				If CurrentRow[Validation.Count] = 0
					And (IsBlankString(CurrentRow.QuantityCalculationAlgorithm) 
						Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											MessageTemplateQuantity, 
											Format(CurrentRow.LineNumber, "NG="),
											TSMetadata[Validation.TSName].Synonym);
											
					Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Count);
					Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				EndIf;
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckCompletionOfCalculationArticle(Cancel)
	
	MessageTemplate = NStr("vi = 'Chưa điền cột ""Dạng tính giá thành"" tại dòng %1 của danh sách ""%2""';
							|ru = 'Не заполнена колонка ""Статья калькуляции"" в строке %1 списка ""%2""';
							|en = 'The ""Product cost element"" column in the %1 line of the ""%2"" list is not filled'; fa = 'The ""Product cost element"" column in the %1 line of the ""%2"" list is not filled';
							|it = 'Colonna ""Voci di calcolo"" non compilata nella riga %1 dell''elenco ""%2""';
							|pl = 'Nie wypełniono kolumny ""Rodzaj kosztu"" w wierszu %1 listy ""%2""';
							|tr = '""%2"" listesinin %1 satırındaki ""Ürün maliyet kalemi"" sütunu doldurulmadı'");
	
	ItemsTypes = Common.ObjectsAttributeValue(
		MaterialsAndServices.UnloadColumn("Products"),
		"ItemsType");
		
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	TSMetadata = Metadata.Catalogs.TechnologicalProcesses.TabularSections.MaterialsAndServices;
	
	For Each CurrentRow In MaterialsAndServices Do
		
		CalculationArticleIsNotRequired =
			ItemsTypes.Get(CurrentRow.Products) = Enums.ItemsTypes.Set
			And SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.Specifications;
		
		If Not CalculationArticleIsNotRequired And Not ValueIsFilled(CurrentRow.ProductCostElement) Then
			MessageText = StrTemplate(MessageTemplate,
				Format(CurrentRow.LineNumber, "NG="),
				TSMetadata.Synonym);
			Field = CommonClientServer.PathToTabularSection(
				TSMetadata.Name,
				CurrentRow.LineNumber,
				"ProductCostElement");
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel)

	If Not GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		Return;
	EndIf;
	
#Region AutoSelection

	ChecksArray = New Array;
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "MaterialsAndServices", NStr("vi = 'Nguyên vật liệu và nhân công';
																									|ru = 'Материалы и работы';
																									|en = 'Materials and works'; fa = 'Materials and works';
																									|it = 'Materiali e lavori';
																									|pl = 'Materiały i prace';
																									|tr = 'Malzemeler ve işler'"), "Products"));
	
	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesForAutoSelection(ForFinishedProductsKind); 
	
	// Let's check that the property in which the nomenclature is specified is in the product
	MessageTemplate = NStr("vi = 'Trong cài đặt tự động chọn, xác định rằng mục được chỉ định trong thuộc tính ""%1"", nhưng thuộc tính này không được bao gồm trong các thuộc tính của sản phẩm chính (danh sách ""%2"", dòng%3).';
							|ru = 'В настройке автовыбора определено, что номенклатура указывается в свойстве ""%1"", но это свойство не входит в состав свойств основного изделия (список ""%2"", строка %3).';
							|en = 'In auto selection settings, it is determined that items are specified in the ""%1"" property, but this property is not included in main product properties (the ""%2"" list, line %3).'; fa = 'In auto selection settings, it is determined that items are specified in the ""%1"" property, but this property is not included in main product properties (the ""%2"" list, line %3).';
							|it = 'Nella configurazione della selezione automatica è stabilito che l''articolo viene indicata nella proprietà ""%1"", ma questa proprietà non fa parte delle proprietà del prodotto principale (elenco ""%2"", riga %3).';
							|pl = 'W ustawieniu wyboru automatycznego określono, że produkty są wskazywane we właściwości ""%1"", ale ta właściwość nie wchodzi do składu właściwości podstawowego wyrobu (lista ""%2"", wiersz %3).';
							|tr = 'Otomatik seçim ayarlarında, ""%1"" özelliğinde öğenin belirtildiği, ancak bu özelliğin nihai ana ürün özelliklerinde yer almadığı tanımlanmıştır (""%2"" listesi, %3 satırı).'");
	TextAutoselectPropertyIsNotSet = NStr("vi = 'Trong cài đặt chọn tự động, xác định rằng mục được chỉ định trong thuộc tính của sản phẩm chính, nhưng thuộc tính không được đặt.';
											|ru = 'В настройке автовыбора определено, что номенклатура указывается в свойстве основного изделия, но свойство не задано.';
											|en = 'In auto selection settings, it is determined that items are specified in the property of the main product, but this property is not set.'; fa = 'In auto selection settings, it is determined that items are specified in the property of the main product, but this property is not set.';
											|it = 'Nella configurazione della selezione automatica è stabilito che l''articolo viene indicata nella proprietà del prodotto principale, ma questa proprietà non è impostata.';
											|pl = 'W ustawieniach automatycznego wyboru jest określono, że produkt jest wskazywany we właściwości produktu podstawowego, jednak ta właściwość nie jest wskazana.';
											|tr = 'Otomatik seçim ayarlarında, nihai ana ürünün özelliğinde öğenin belirtildiği, ancak özelliğin belirtilmediği tanımlanmıştır.'");
	TextNoAutoselectionAlgorithmSpecified = NStr("vi = 'Trong cài đặt tự động chọn, xác định rằng đặc tính được xác định bởi thuật toán, nhưng thuật toán không được xác định.';
												|ru = 'В настройке автовыбора определено, что характеристика определяется по алгоритму, но алгоритм не задан.';
												|en = 'In auto selection settings, it is determined that a variant is defined by algorithm, but the algorithm is not specified.'; fa = 'In auto selection settings, it is determined that a variant is defined by algorithm, but the algorithm is not specified.';
												|it = 'Nella configurazione della selezione automatica è stabilito che la caratteristica viene definita secondo l''algoritmo, ma l''algoritmo stesso non è impostato.';
												|pl = 'W ustawieniach automatycznego wyboru jest określono, że charakterystyka jest określana według algorytmu, jednak algorytm nie jest wskazany.';
												|tr = 'Otomatik seçim ayarlarında, varyantın algoritma tarafından belirlendiği, ancak algoritmanın belirtilmediği tanımlanmıştır.'");
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // TabularSection - Catalog.TechnologicalProcesses.MaterialsAndServices
		For Each CurrentRow In TabularSection Do
			
			MessageText = "";
			If CurrentRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty Then
				
				If ValueIsFilled(CurrentRow.PropertyThatContainsProducts) Then
					If ListOfAllAvailableProperties.Find(CurrentRow.PropertyThatContainsProducts, "Property") = Undefined Then
						PropertyHeader = Common.ObjectAttributeValue(CurrentRow.PropertyThatContainsProducts, "Title");
						MessageText = StringFunctionsClientServer.SubstituteParametersToString(
							MessageTemplate, 
							PropertyHeader,
							Validation.Presentation,
							Format(CurrentRow.LineNumber, "NG="));
					EndIf;
				Else
					MessageText = TextAutoselectPropertyIsNotSet;
				EndIf;
				
			ElsIf CurrentRow.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm 
				And Not ValueIsFilled(CurrentRow.ItemVariantAutoSelectionAlgorithm) Then
				MessageText = TextNoAutoselectionAlgorithmSpecified;
			EndIf;
			
			If Not IsBlankString(MessageText) Then
				Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, "Products");
				Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			EndIf;
			
		EndDo;
		
	EndDo;
	
#EndRegion

#Region SelectionByProperties
	
	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(ForFinishedProductsKind,,False);
	
	// Usage settings and quantity calculation
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "LaborCosts", NStr("vi = 'Chi phí nhân công';
																						|ru = 'Трудозатраты';
																						|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
																						|it = 'Costi di manodopera';
																						|pl = 'Labor costs';
																						|tr = 'İş gücü maliyetleri'"), "WorkKind"));
	
	MessageTemplate = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng (danh sách ""%1"", dòng%2).';
							|ru = 'В настройках использования указаны неверные свойства (список ""%1"", строка %2).';
							|en = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).'; fa = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).';
							|it = 'Proprietà non valide specificate nelle impostazioni di utilizzo (elenco ""%1"", riga %2).';
							|pl = 'W ustawieniach używania są wskazane nieprawidłowe właściwości (lista ""%1"", wiersz %2).';
							|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi (""%1"" listesi, %2 satırı).'");
	
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.TechnologicalProcesses.MaterialsAndServices
		For Each CurrentRow In TabularSection Do
			
			SelectionLines = SelectionByProperties.FindRows(New Structure("ConnectionKey", CurrentRow.ConnectionKey));
			
			For Each StringSelection_ In SelectionLines Do
				
				If ListOfAllAvailableProperties.Find(StringSelection_.Property, "Property") = Undefined Then
					
					MessageText = StrTemplate(MessageTemplate, Validation.Presentation, Format(CurrentRow.LineNumber, "NG="));
					
					Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Attribute);
					
					Common.MessageToUser(
						MessageText, 
						ThisObject, 
						Field,
						, 
						Cancel);
						
					Break;
					
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
#EndRegion

#Region CalculationByFormulas

	ObjectTabularSections = Metadata().TabularSections;
	
	Filter = New Structure("QuantityCalculationAlgorithm", "");
	
	For It = - ChecksArray.UBound() To 0 Do
		Validation = ChecksArray[-It];
		If ThisObject[Validation.TSName].FindRows(Filter).Count() = ThisObject[Validation.TSName].Count() Then
			ChecksArray.Delete(-It);
		Else
			AttributeName = "NumberOfPackages";
			If ObjectTabularSections[Validation.TSName].Attributes.Find(AttributeName) = Undefined Then
				AttributeName = "Count";
			EndIf;
			Validation.Attribute = AttributeName;
		EndIf;
	EndDo;
	
	If ChecksArray.Count() > 0 Then
		
		DescriptionOfSources = Catalogs.TechnologicalProcesses.UploadDataForFormulaConstructor(ThisObject, "");
		
		CheckParameters = New Structure("Content, OutputMessages, ClearNotFound", ChecksArray, True, False);
		
		ProductDataManagement.CheckClearQuantityCalculationAlgorithm(ThisObject, DescriptionOfSources, CheckParameters, Cancel);
		
	EndIf;
	
#EndRegion
	
EndProcedure

Procedure ClearUnusedData()
	
	UseBillOfMaterialsParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	For Each String In MaterialsAndServices Do
		If Not IsBlankString(String.QuantityCalculationAlgorithm) And UseBillOfMaterialsParameterization Then
			String.NumberOfPackages = 0;
		EndIf;
	EndDo;
	
	For Each String In LaborCosts Do
		If Not IsBlankString(String.QuantityCalculationAlgorithm) And UseBillOfMaterialsParameterization Then
			String.Count = 0;
		EndIf;
	EndDo;
	
EndProcedure

Procedure FillInServiceDetails()
	
	If ( Status = Enums.BOMStatuses.UnderDevelopment ) Then
		
		ContainsResourcesParametrization = False;
		
	Else
		
		ContainsResourcesParametrization = SelectionByProperties.Count();
		If Not ContainsResourcesParametrization Then
			
			ListOfTS = New Array;
			ListOfTS.Add("MaterialsAndServices");
			ListOfTS.Add("LaborCosts");
			
			For Each TSName In ListOfTS Do
				For Each String In ThisObject[TSName] Do
					If Not IsBlankString(String.QuantityCalculationAlgorithm)
						Or TSName <> "LaborCosts"
							And (String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty
								Or String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties
								Or String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.PickedByAlgorithm) Then
						ContainsResourcesParametrization = True;
						Break;
					EndIf;
				EndDo;
				If ContainsResourcesParametrization Then
					Break;
				EndIf;
			EndDo;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf