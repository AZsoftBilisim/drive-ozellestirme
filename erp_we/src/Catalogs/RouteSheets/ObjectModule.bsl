#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	// The expiration date must be at least the start date.
	If ValueIsFilled(ValidOnDate) 
		And ValueIsFilled(ValidToDate) 
		And ValidOnDate > ValidToDate Then
		
		ErrorText = NStr("vi = 'Ngày hết hạn phải không ít hơn ngày bắt đầu của hành động.';
						|ru = 'Дата окончания действия должна быть не меньше даты начала действия.';
						|en = 'Action expiration date must be greater than the effective date.'; fa = 'Action expiration date must be greater than the effective date.';
						|it = 'La data di fine dell''azione non deve essere inferiore la data di inizio dell''azione.';
						|pl = 'Data zakończenia okresu ważności nie może być wcześniejsza od daty rozpoczęcia.';
						|tr = 'Geçerlilik bitiş tarihi, geçerlilik başlangıç tarihinden daha az olmamalıdır.'");
		
		CommonClientServer.MessageToUser(
			ErrorText,
			ThisObject,
			"ValidToDate",
			,
			Cancel);
		
	EndIf;
		
	NotCheckedAttributeArray = New Array();
	
	NotCheckedAttributeArray.Add("ManufacturedProducts.Products");
	NotCheckedAttributeArray.Add("ManufacturedProducts.NumberOfPackages");
	NotCheckedAttributeArray.Add("ManufacturedProducts.CostShare");
	
	NotCheckedAttributeArray.Add("RecyclableWaste.Products");
	NotCheckedAttributeArray.Add("RecyclableWaste.NumberOfPackages");
	
	If Not UseFinishedProducts Then
		NotCheckedAttributeArray.Add("ManufacturedProducts.Characteristic");
		NotCheckedAttributeArray.Add("RecyclableWaste.Characteristic");
	EndIf;
	
	NotCheckedAttributeArray.Add("MaterialsAndServices.Products");
	NotCheckedAttributeArray.Add("MaterialsAndServices.NumberOfPackages");
	
	If Not UseMaterials Then
		NotCheckedAttributeArray.Add("MaterialsAndServices.Characteristic");
	EndIf;
	
	If Not UseLaborCosts Then
		NotCheckedAttributeArray.Add("LaborCosts.WorkKind");
	EndIf;
	NotCheckedAttributeArray.Add("LaborCosts.Count");
	
	If Status <> Enums.StatusesOfRouteSheets.Valid Then
		NotCheckedAttributeArray.Add("Department");
		NotCheckedAttributeArray.Add("ValidOnDate");
		NotCheckedAttributeArray.Add("ValidToDate");
		NotCheckedAttributeArray.Add("UnitOfMeasureOfPreliminaryBuffer");
		NotCheckedAttributeArray.Add("UnitOfMeasureOfFollowUpBuffer");
	EndIf;
	
	If UseFinishedProducts Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "ManufacturedProducts";
		If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
			StringsList = ManufacturedProducts.FindRows(New Structure("MethodOfItemVariantAutoselection", 
				Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
			CheckParameters.StringsList = StringsList;
		EndIf;
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "RecyclableWaste";
		If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
			StringsList = RecyclableWaste.FindRows(New Structure("MethodOfItemVariantAutoselection", 
				Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
			CheckParameters.StringsList = StringsList;
		EndIf;
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	If UseMaterials Then
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = "MaterialsAndServices";
		If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
			StringsList = MaterialsAndServices.FindRows(New Structure("MethodOfItemVariantAutoselection", 
				Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
			CheckParameters.StringsList = StringsList;
		EndIf;
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	EndIf;
	
	CheckFillingInProductsAndQuantities(Cancel);
	
	If Status = Enums.StatusesOfRouteSheets.Valid Then
		
		CheckWhetherCostShareIsFilledIn(Cancel);
		CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel);
		
		If UseOperations Then
			Catalogs.RouteSheets.SequenceOfOperationsIsCorrect(Ref, Cancel);
			ProductionProcessEditor.CheckCorrectnessOfFillingInOperations(Ref, Department, Cancel);
		EndIf;
		If PreliminaryBuffer = 0 Then
			NotCheckedAttributeArray.Add("UnitOfMeasureOfPreliminaryBuffer");
		EndIf; 
		If FollowUpBuffer = 0 Then
			NotCheckedAttributeArray.Add("UnitOfMeasureOfFollowUpBuffer");
		EndIf;
		
	EndIf;
	
	If Not CalculateFactor Then
		NotCheckedAttributeArray.Add("NumeratorFactor");
		NotCheckedAttributeArray.Add("FactorDenominator");
	EndIf;
	
	ObjectTabularSections = Metadata().TabularSections;
	If UseFinishedProducts Then
		CheckSelectionOfOperations("ManufacturedProducts",  ObjectTabularSections.ManufacturedProducts.Synonym, Cancel);
		CheckSelectionOfOperations("RecyclableWaste", ObjectTabularSections.RecyclableWaste.Synonym, Cancel);
	EndIf; 
	If UseMaterials Then
		CheckSelectionOfOperations("MaterialsAndServices", ObjectTabularSections.MaterialsAndServices.Synonym, Cancel);
	EndIf; 
	If UseLaborCosts Then
		CheckSelectionOfOperations("LaborCosts",ObjectTabularSections.LaborCosts.Synonym, Cancel);
	EndIf; 
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		
		FillInDataType = TypeOf(FillingData);
		
		If FillInDataType = Type("CatalogRef.Products") Then
			
			AttributesStructure1 = Common.ObjectAttributesValues(FillingData, "IsFolder, ProductKind");
			If AttributesStructure1.IsFolder = False Then
				ForFinishedProductsKind = AttributesStructure1.ProductKind;
				
				NewRow = ManufacturedProducts.Add();
				NewRow.ConnectionKey          = New UUID;
				NewRow.Products       = FillingData;
				NewRow.NumberOfPackages = 1;
				ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
			EndIf;
			
		EndIf;
		
		EmployeeResponsible = Users.CurrentUser();
		
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return;
	EndIf;
	
	Status         = Enums.StatusesOfRouteSheets.UnderDevelopment;
	EmployeeResponsible  = Users.CurrentUser();
	Department  = Catalogs.BusinessStructure.EmptyRef();
	ValidOnDate = '00010101';
	
	ClearSelectionOfOperations();
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		
		If DeletionMark Then
			Status = Enums.StatusesOfRouteSheets.Closed_;
			ClearSelectionOfOperations();
			RemoveMainRouteMapAttribute();
		EndIf;
		
		BeforeRecordingValidRouteMap(Cancel);
		
		If Cancel Then
			Return;
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region Other

Procedure BeforeRecordingValidRouteMap(Cancel)

	If Status = Enums.StatusesOfRouteSheets.Valid And Not DeletionMark And Not Cancel Then
		
		ClearUnusedData();
		
		UpdateOperationBinding(Cancel);
		CheckNestedRoutes(Cancel);
		
	EndIf;
	
EndProcedure

// Updates the value of the operation attribute in the Output items table part
//  - if the edit operation detail is not empty, it substitutes the value from it
//  - if the edit operation prop is empty, it substitutes the last operation.
//
Procedure UpdateOperationBinding(Cancel)
	
	FirstOperation = Undefined;
	LastOperation_ = Undefined;
	
	EmptyOperation = Catalogs.ManufacturingOperations.EmptyRef();
	
	GetExtremeOperations = ManufacturedProducts.Find(EmptyOperation, "OperationEdit") <> Undefined
		Or RecyclableWaste.Find(EmptyOperation, "OperationEdit") <> Undefined
		Or MaterialsAndServices.Find(EmptyOperation, "OperationEdit") <> Undefined
		Or LaborCosts.Find(EmptyOperation, "OperationEdit") <> Undefined;
	
	If GetExtremeOperations Then
		
		Query = New Query(
			"SELECT
			|	ManufacturingOperations.Ref AS Ref,
			|	TRUE AS FirstOperation,
			|	CASE
			|		WHEN ManufacturingOperations.NextOperation = 0
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS LastOperation_
			|FROM
			|	Catalog.ManufacturingOperations AS ManufacturingOperations
			|WHERE
			|	ManufacturingOperations.Owner = &Owner
			|	AND ManufacturingOperations.OperationNumber = 1
			|	AND NOT ManufacturingOperations.DeletionMark
			|	AND ManufacturingOperations.ContainsNestedRoute = FALSE
			|
			|UNION
			|
			|SELECT
			|	ManufacturingOperations.Ref,
			|	CASE
			|		WHEN ManufacturingOperations.OperationNumber = 1
			|			THEN TRUE
			|		ELSE FALSE
			|	END,
			|	TRUE
			|FROM
			|	Catalog.ManufacturingOperations AS ManufacturingOperations
			|WHERE
			|	ManufacturingOperations.Owner = &Owner
			|	AND ManufacturingOperations.NextOperation = 0
			|	AND NOT ManufacturingOperations.DeletionMark
			|	AND ManufacturingOperations.ContainsNestedRoute = FALSE");
		
		Query.SetParameter("Owner", Ref);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			If Selection.FirstOperation Then
				FirstOperation = Selection.Ref;
			EndIf;
			
			If Selection.LastOperation_ Then
				LastOperation_ = Selection.Ref;
			EndIf;
			
		EndDo;
		
	EndIf; 
	
	TabularSections = New Array;
	TabularSections.Add("ManufacturedProducts");
	TabularSections.Add("RecyclableWaste");
	TabularSections.Add("MaterialsAndServices");
	TabularSections.Add("LaborCosts");
	
	For Each TabularSection In TabularSections Do
		
		For Each String In ThisObject[TabularSection] Do
			
			If String.OperationEdit.IsEmpty() Then
				
				If TabularSection = "ManufacturedProducts" Or TabularSection = "RecyclableWaste" Then
					String.Operation = LastOperation_;
				Else
					String.Operation = FirstOperation;
				EndIf;
				
			Else
				
				String.Operation = String.OperationEdit;
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure CheckNestedRoutes(Cancel) Export
	
	Depth = 0;
	MaxDepth = Catalogs.RouteSheets.MaximumNestingDepth();
	
	PathsInGraph = New Map;
	PathsInGraph.Insert(Ref, New Array);
	
	Query = New Query(
	"SELECT DISTINCT
	|	NestedRoutes.Owner                AS Owner,
	|	NestedRoutes.Owner.Presentation  AS OwnerPresentation,
	|	NestedRoutes.NestedRoute        AS Ref,
	|	NestedRoutes.Description            AS Presentation,
	|// checking the details of the nested route
	|	NestedRoutes.NestedRoute.Status        AS Status,
	|	NestedRoutes.NestedRoute.Department AS Department
	|FROM
	|	Catalog.ManufacturingOperations AS NestedRoutes
	|WHERE
	|	NestedRoutes.Owner IN(&ReferencesArrray)
	|	AND NestedRoutes.ContainsNestedRoute
	|	AND NOT NestedRoutes.DeletionMark");
	
	ReferencesArrray = New Array;
	ReferencesArrray.Add(Ref);
	While Depth <> MaxDepth And ReferencesArrray.UBound() <> -1 Do
		
		Query.SetParameter("ReferencesArrray", ReferencesArrray);
		
		Result = Query.Execute();
		If Result.IsEmpty() Then
			Break;
		EndIf;
		
		ReferencesArrray.Clear();
		PathsInGraphAreNew = New Map;
		
		Selection = Result.Select();
		While Selection.Next() Do
			
			If PathsInGraph[Selection.Owner].Find(Selection.Owner) = Undefined Then
				PathsInGraph[Selection.Owner].Insert(0,Selection.Owner);
			EndIf;
			PathsInGraphAreNew.Insert(Selection.Ref, PathsInGraph[Selection.Owner]); 
			
			ReferencesArrray.Add(Selection.Ref);
			
			CheckDetailsOfNestedRoute(Selection, Cancel);
			
		EndDo;
		
		PathsInGraph = PathsInGraphAreNew;
		PathsInGraphAreNew = Undefined;
		Depth = Depth + 1;
		
	EndDo;
	
	If Depth <> MaxDepth Then
		Return;
	EndIf;
	
	PathInGraph = New ValueTable;
	PathInGraph.Columns.Add("Vertex", New TypeDescription("CatalogRef.RouteSheets"));
	PathInGraph.Columns.Add("Order", New TypeDescription("Number", New NumberQualifiers));
	
	For Each KeyAndValue In PathsInGraph Do
		Path = KeyAndValue.Value;
		For IndexOf = 0 To Path.UBound() Do
			NewRow = PathInGraph.Add();
			NewRow.Vertex = Path[IndexOf];
			NewRow.Order = IndexOf;
		EndDo;
		Break;
	EndDo;
	
	TextPathInGraph = "";
	If PathInGraph.Count() > 0 Then
		
		Query = New Query(
		"SELECT
		|	PathInGraph.Vertex,
		|	PathInGraph.Order
		|INTO TTIsPathInGraph
		|FROM
		|	&PathInGraph AS PathInGraph
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(RouteSheets.Ref.Code, """") AS Code
		|FROM
		|	TTIsPathInGraph AS PathInGraph
		|		LEFT JOIN Catalog.RouteSheets AS RouteSheets
		|		ON PathInGraph.Vertex = RouteSheets.Ref
		|
		|ORDER BY
		|	-PathInGraph.Order");
		Query.SetParameter("PathInGraph", PathInGraph);
		
		Route = Query.Execute().Unload().UnloadColumn(0);
		TextPathInGraph = "/" + StrConcat(Route, "/") + "/";
		
	EndIf;
	
	ErrorText = NStr("vi = 'Vượt quá độ sâu lồng tối đa của sơ đồ tuyến đường %1';
					|ru = 'Превышена максимальная глубина вложенности маршрутных карт %1';
					|en = 'Maximum nesting depth of the %1 route sheet is exceeded'; fa = 'Maximum nesting depth of the %1 route sheet is exceeded';
					|it = 'È superata la profondità massima di inserimento delle schede di lavorazione %1';
					|pl = 'Przekroczono maksymalną głębokość zagnieżdżenia kart technologicznych %1';
					|tr = '%1Rotalarının maksimum iç içe geçme derinliği aşıldı'");
	ErrorText = StrTemplate(ErrorText, TextPathInGraph);
	
	CommonClientServer.MessageToUser(ErrorText, 
		ThisObject,
		,
		,
		Cancel);
	
EndProcedure

Procedure CheckDetailsOfNestedRoute(Selection, Cancel)
	
	If Selection.Status <> Enums.StatusesOfRouteSheets.Valid Then
		
		ErrorText = NStr("vi = 'Trạng thái của tuyến đường lồng nhau ""%1"" của bản đồ tuyến đường ""%2"" phải là ""Hiệu quả"".';
						|ru = 'Статус вложенного маршрута ""%1"" маршрутной карты ""%2"" должен быть ""Действует"".';
						|en = 'Status of ""%1"" nested route of the ""%2"" route sheet must be set to ""Valid"".'; fa = 'Status of ""%1"" nested route of the ""%2"" route sheet must be set to ""Valid"".';
						|it = 'Lo stato del percorso inserito ""%1"" nella scheda di lavorazione ""%2"" deve essere ""Attivo"".';
						|pl = 'Status trasy zagnieżdżonej ""%1"" karty technologicznej ""%2"" musi być ""Aktualna"".';
						|tr = '""%2"" Rotanın ""%1"" iç içe rota durumu ""Aktif"" olmalıdır.'");
		ErrorText = StrTemplate(ErrorText, Selection.Presentation, Selection.OwnerPresentation);
		
		CommonClientServer.MessageToUser(ErrorText, 
			Selection.Owner,
			,
			,
			Cancel);
		
	EndIf;
	
	If Selection.Department <> ThisObject.Department Then
		
		ErrorText = NStr("vi = 'Đơn vị của tuyến đường lồng nhau ""%1"" phải khớp với đơn vị của bản đồ tuyến đường ""%2"".';
						|ru = 'Подразделение вложенного маршрута ""%1"" должно совпадать с подразделением маршрутной картой ""%2"".';
						|en = 'Business unit specified in the ""%1"" nested route must match the business unit specified in the ""%2"" route sheet.'; fa = 'Business unit specified in the ""%1"" nested route must match the business unit specified in the ""%2"" route sheet.';
						|it = 'Il reparto del percorso inserito ""%1"" deve corrispondere al reparto della scheda di lavorazione""%2"".';
						|pl = 'Dział trasy zagnieżdżonej ""%1"" musi być taki sam, jak dział karty technologicznej ""%2.';
						|tr = '""%1"" iç içe rota departmanı, ""%2"" rota departmanı ile aynı olmalıdır.'");
		ErrorText = StrTemplate(ErrorText, Selection.Presentation, Selection.OwnerPresentation);
		
		CommonClientServer.MessageToUser(ErrorText, 
			Selection.Owner,
			,
			,
			Cancel);
		
	EndIf;
	
EndProcedure

Procedure ClearSelectionOfOperations()

	TabularSections = New Array;
	TabularSections.Add("ManufacturedProducts");
	TabularSections.Add("RecyclableWaste");
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
	
	TabularSection = ThisObject[TableName]; // CatalogTabularSection.RouteSheets.ManufacturedProducts
	For Each TableRow In TabularSection Do
		If TableRow.OperationEdit.IsEmpty() 
			Or Not Common.ObjectAttributeValue(TableRow.OperationEdit, "DeletionMark") Then
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
																					TablePresentation, 
																					Format(TableRow.LineNumber, "NG="));
																					
		Field = CommonClientServer.PathToTabularSection(TableName, TableRow.LineNumber, "OperationEdit");
		CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel); 						
	EndDo; 
	
EndProcedure

Procedure CheckWhetherCostShareIsFilledIn(Cancel)
	
	If Not UseFinishedProducts
		Or Not GetFunctionalOption("UseProductionManagement")
		Or ManufacturedProducts.Count() < 2 Then
		Return;
	EndIf;
	
	MessageTemplate = NStr("vi = 'Cột ""Thành phần giá trị"" trong hàng %1 của danh sách ""Sản phẩm đầu ra"" không được điền';
							|ru = 'Не заполнена колонка ""Доля стоимости"" в строке %1 списка ""Выходные изделия""';
							|en = 'Column ""Cost share"" in line %1 of the ""Finished products"" list is not filled in'; fa = 'Column ""Cost share"" in line %1 of the ""Finished products"" list is not filled in';
							|it = 'La colonna ""Parte del costo"" nella riga %1 dell''elenco ""Prodotti di output"" non è compilata';
							|pl = 'Nie wypełniono kolumny ""Udział kosztów"" w wierszu %1 listy ""Produkty wyjściowe""';
							|tr = '""Üretilen Nihai Ürünler"" listesinin %1 satırındaki ""Maliyet Payı"" sütunu doldurulmadı'");
	For Each TableRow In ManufacturedProducts Do
		If TableRow.CostShare = 0 Then
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, 
																						Format(TableRow.LineNumber, "NG="));
																						
			Field = CommonClientServer.PathToTabularSection("ManufacturedProducts", TableRow.LineNumber, "CostShare");
			CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
		EndIf; 
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
	
	TSMetadata = Metadata.Catalogs.RouteSheets.TabularSections;
	
	VerificationDetails_1 = "TSName, Products, Count";
	
	ChecksArray = New Array;
	If UseFinishedProducts Then
		ChecksArray.Add(New Structure(VerificationDetails_1, "ManufacturedProducts", "Products", "NumberOfPackages"));
		ChecksArray.Add(New Structure(VerificationDetails_1, "RecyclableWaste", "Products", "NumberOfPackages"));
	EndIf;
	If UseMaterials Then
		ChecksArray.Add(New Structure(VerificationDetails_1, "MaterialsAndServices", "Products", "NumberOfPackages"));
	EndIf;
	If UseLaborCosts Then
		ChecksArray.Add(New Structure(VerificationDetails_1, "LaborCosts", "", "Count"));
	EndIf;
	
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.RouteSheets.ManufacturedProducts
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
					CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			EndIf;
			
			If Status = Enums.StatusesOfRouteSheets.Valid Then
				
				If CurrentRow[Validation.Count] = 0
					And (IsBlankString(CurrentRow.QuantityCalculationAlgorithm) 
						Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
					
					MessageText = StringFunctionsClientServer.SubstituteParametersToString(
											MessageTemplateQuantity, 
											Format(CurrentRow.LineNumber, "NG="),
											TSMetadata[Validation.TSName].Synonym);
											
					Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Count);
					CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
				EndIf;
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel)

	If Not (UseFinishedProducts
				Or UseMaterials 
				Or UseLaborCosts) 
		Or Not GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		Return;
	EndIf;
	
#Region AutoSelection

	ChecksArray = New Array;
	If UseFinishedProducts Then
		ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "ManufacturedProducts", NStr("vi = 'Sản phẩm đầu ra';
																										|ru = 'Выходные изделия';
																										|en = 'Finished products'; fa = 'Finished products';
																										|it = 'Prodotti finiti';
																										|pl = 'Wyroby gotowe';
																										|tr = 'Üretilen nihai ürünler'"), "Products"));
		ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "RecyclableWaste", NStr("vi = 'Xuất xưởng trung gian và sản phẩm phụ';
																								|ru = 'Промежуточный и побочный выпуск';
																								|en = 'Intermediate and side release'; fa = 'Intermediate and side release';
																								|it = 'Produzione transitoria e supplementare';
																								|pl = 'Poboczne i pośrednie wypuszczenie';
																								|tr = 'Ara ve yan ürün çıkışı'"), "Products"));
	EndIf;
	If UseMaterials Then
		ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "MaterialsAndServices", NStr("vi = 'Nguyên vật liệu và nhân công';
																										|ru = 'Материалы и работы';
																										|en = 'Materials and works'; fa = 'Materials and works';
																										|it = 'Materiali e lavori';
																										|pl = 'Materiały i prace';
																										|tr = 'Malzemeler ve işler'"), "Products"));
	EndIf;
	
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
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.RouteSheets.ManufacturedProducts
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
				CommonClientServer.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			EndIf;
			
		EndDo;
		
	EndDo;
	
#EndRegion

#Region SelectionByProperties
	
	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(ForFinishedProductsKind,,False);
	
	// Usage settings and quantity calculation
	If UseLaborCosts Then
		ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "LaborCosts", NStr("vi = 'Chi phí nhân công';
																							|ru = 'Трудозатраты';
																							|en = 'Labor costs'; fa = 'هزینه‌های دستمزد';
																							|it = 'Costi di manodopera';
																							|pl = 'Labor costs';
																							|tr = 'İş gücü maliyetleri'"), "WorkKind"));
	EndIf;
	
	MessageTemplate = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng (danh sách ""%1"", dòng%2).';
							|ru = 'В настройках использования указаны неверные свойства (список ""%1"", строка %2).';
							|en = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).'; fa = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).';
							|it = 'Proprietà non valide specificate nelle impostazioni di utilizzo (elenco ""%1"", riga %2).';
							|pl = 'W ustawieniach używania są wskazane nieprawidłowe właściwości (lista ""%1"", wiersz %2).';
							|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi (""%1"" listesi, %2 satırı).'");
	
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.RouteSheets.ManufacturedProducts
		For Each CurrentRow In TabularSection Do
			
			SelectionLines = SelectionByProperties.FindRows(New Structure("ConnectionKey", CurrentRow.ConnectionKey));
			
			For Each StringSelection_ In SelectionLines Do
				
				If ListOfAllAvailableProperties.Find(StringSelection_.Property, "Property") = Undefined Then
					
					MessageText = StrTemplate(MessageTemplate, Validation.Presentation, Format(CurrentRow.LineNumber, "NG="));
					
					Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Attribute);
					
					CommonClientServer.MessageToUser(
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
		
		DescriptionOfSources = Catalogs.RouteSheets.UploadDataForFormulaConstructor(ThisObject, "");
		
		CheckParameters = New Structure("Content, OutputMessages, ClearNotFound", ChecksArray, True, False);
		
		ProductDataManagement.CheckClearQuantityCalculationAlgorithm(ThisObject, DescriptionOfSources, CheckParameters, Cancel);
		
	EndIf;
	
#EndRegion
	
EndProcedure

Procedure RemoveMainRouteMapAttribute()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	MainRouteSheets.Products,
	|	MainRouteSheets.Characteristic,
	|	MainRouteSheets.Department
	|FROM
	|	InformationRegister.MainRouteSheets AS MainRouteSheets
	|WHERE
	|	MainRouteSheets.RouteSheet = &RouteSheet";
	
	Query.SetParameter("RouteSheet", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		MainEntry = InformationRegisters.MainRouteSheets.CreateRecordManager();
		MainEntry.Products   = Selection.Products;
		MainEntry.Characteristic = Selection.Characteristic;
		MainEntry.Department  = Selection.Department;
		MainEntry.Delete();
	EndDo;
	
EndProcedure

Procedure ClearUnusedData()
	
	UseBillOfMaterialsParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	For Each TSName In StrSplit("ManufacturedProducts,RecyclableWaste,MaterialsAndServices",",") Do
		For Each String In ThisObject[TSName] Do
			If Not IsBlankString(String.QuantityCalculationAlgorithm) And UseBillOfMaterialsParameterization Then
				String.NumberOfPackages = 0;
			EndIf;
		EndDo;
	EndDo;
	
	For Each String In LaborCosts Do
		If Not IsBlankString(String.QuantityCalculationAlgorithm) And UseBillOfMaterialsParameterization Then
			String.Count = 0;
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion

#EndRegion

#EndIf