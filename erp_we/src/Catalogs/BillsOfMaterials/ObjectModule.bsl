#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If Not IsFolder Then
		
		FillInDataType = TypeOf(FillingData);
		
		ProductionProcessType = Enums.ProductionProcessTypes.Assembly;
		AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList;
		If Not GetFunctionalOption("UseProductionManagement") Then
			AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.Products;
		EndIf;
		If FillInDataType = Type("CatalogRef.Products") Then
			
			AttributesStructure1 = Common.ObjectAttributesValues(FillingData, "IsFolder");
			If AttributesStructure1.IsFolder = False Then
				
				NewRow = ManufacturedProducts.Add();
				NewRow.ConnectionKey          = New UUID;
				NewRow.Products       = FillingData;
				NewRow.NumberOfPackages = 1;
				ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
				
				MainProductProducts       = FillingData;
				MainProductNumberOfPackages = 1;
			
			EndIf;
			
		ElsIf FillInDataType = Type("Structure") Then
			
			If FillingData.Property("ProductionProcessType") Then
				If TypeOf(FillingData.ProductionProcessType) = Type("Array") 
					Or TypeOf(FillingData.ProductionProcessType) = Type("FixedArray") Then
					ProductionProcessType = FillingData.ProductionProcessType[0];
				Else
					ProductionProcessType = FillingData.ProductionProcessType;
				EndIf;
			EndIf;
			
			FillingData.Property("Description", Description);
			
			If FillingData.Property("Products") Then
				
				NumberOfPackages = 1;
				If FillingData.Property("NumberOfPackages") Then
					NumberOfPackages = FillingData.NumberOfPackages;
				EndIf;
				
				Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
				If FillingData.Property("Package") Then
					Package = FillingData.Package;
				EndIf;
				
				If Not FillingData.Property("ManufacturedProducts")
					And (ProductionProcessType = Enums.ProductionProcessTypes.Assembly
						Or ProductionProcessType = Enums.ProductionProcessTypes.Repair
						Or ProductionProcessType = Enums.ProductionProcessTypes.PerformRM
						Or Not ValueIsFilled(ProductionProcessType)) Then
				
					NewRow = ManufacturedProducts.Add();
					NewRow.ConnectionKey          = New UUID;
					NewRow.Products       = FillingData.Products;
					NewRow.Characteristic     = FillingData.Characteristic;
					NewRow.Package           = Package;
					NewRow.NumberOfPackages = NumberOfPackages;
					ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
					
				EndIf;
				
				MainProductProducts       = FillingData.Products;
				MainProductCharacteristic     = FillingData.Characteristic;
				MainProductPackage           = Package;
				MainProductNumberOfPackages = NumberOfPackages;
				
			EndIf;
			
			ArrayOfTables = TabularSectionNames();
			ArrayOfTables.Add("SelectionByProperties");
			ArrayOfTables.Add("PropertyMapping");
			
			For Each TSName In ArrayOfTables Do
				
				If Not FillingData.Property(TSName) Then
					Continue;
				ElsIf IsTempStorageURL(FillingData[TSName]) Then
					Table = GetFromTempStorage(FillingData[TSName]);
					DeleteFromTempStorage(FillingData[TSName]);
				Else
					Table = FillingData[TSName];
				EndIf;
				
				TabularSection = ThisObject[TSName]; // TabularSection
				
				ThereIsAutoselection = (TSName = "ManufacturedProducts"
									Or TSName = "RecyclableWaste"
									Or TSName = "MaterialsAndServices");
				
				For Each String In Table Do
					NewRow = TabularSection.Add();
					If ThereIsAutoselection Then
						ProductDataManagementClientServer.WhenEnteringNewLineWithAutoSelection(NewRow);
					EndIf;
					FillPropertyValues(NewRow, String);
				EndDo;
				
			EndDo;
			
		EndIf;
		
		CheckAppearanceOfProductItem();
		
		EmployeeResponsible = Users.CurrentUser();
		
	EndIf; 
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If IsFolder Then
		Return;
	EndIf;
	
	DescriptionManufacturingProcess = Undefined;
	If Not AdditionalProperties.Property("DescriptionManufacturingProcess", DescriptionManufacturingProcess) Then
		DescriptionManufacturingProcess = Catalogs.BillsOfMaterials.DescriptionManufacturingProcess(Ref);
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
		Common.MessageToUser(ErrorText, ThisObject, "ValidToDate",, Cancel);
		
	EndIf;
	
	NotCheckedAttributeArray = New Array;
	
#Region ManufacturedProducts
	NotCheckedAttributeArray.Add("ManufacturedProducts");
	NotCheckedAttributeArray.Add("ManufacturedProducts.ProductKind");
	NotCheckedAttributeArray.Add("ManufacturedProducts.Products");
	NotCheckedAttributeArray.Add("ManufacturedProducts.NumberOfPackages");
	NotCheckedAttributeArray.Add("ManufacturedProducts.Characteristic");
	NotCheckedAttributeArray.Add("ManufacturedProducts.CostShare");
	NotCheckedAttributeArray.Add("ManufacturedProducts.BillOfMaterials");
#EndRegion
	
#Region RecyclableWaste
	NotCheckedAttributeArray.Add("RecyclableWaste");
	NotCheckedAttributeArray.Add("RecyclableWaste.Products");
	NotCheckedAttributeArray.Add("RecyclableWaste.NumberOfPackages");
	NotCheckedAttributeArray.Add("RecyclableWaste.ProductCostElement");
	NotCheckedAttributeArray.Add("RecyclableWaste.BillOfMaterials");
	NotCheckedAttributeArray.Add("RecyclableWaste.Characteristic");
#EndRegion
	
#Region IncomingProduct
	If ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		Or Status <> Enums.BOMStatuses.Valid Then
		NotCheckedAttributeArray.Add("MainProductProductKind");
		NotCheckedAttributeArray.Add("MainProductProducts");
		NotCheckedAttributeArray.Add("MainProductNumberOfPackages");
	ElsIf AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind Then
		NotCheckedAttributeArray.Add("MainProductProducts");
	Else
		NotCheckedAttributeArray.Add("MainProductProductKind");
	EndIf;
	CheckFillingOfIncomingItems(Cancel);
#EndRegion
	
#Region UsedMaterials
	NotCheckedAttributeArray.Add("MaterialsAndServices.Products");
	NotCheckedAttributeArray.Add("MaterialsAndServices.MethodOfReceivingMaterial");
	NotCheckedAttributeArray.Add("MaterialsAndServices.SourceOfSemiFinishedProduct");
	NotCheckedAttributeArray.Add("MaterialsAndServices.NumberOfPackages");
	NotCheckedAttributeArray.Add("MaterialsAndServices.ProductCostElement");
	NotCheckedAttributeArray.Add("MaterialsAndServices.Characteristic");
	CheckContentFilling(Cancel);
#EndRegion

#Region LaborCosts
	If ThisIsTechnologicalSet() Then
		NotCheckedAttributeArray.Add("LaborCosts");
		NotCheckedAttributeArray.Add("LaborCosts.WorkKind");
	EndIf;
	NotCheckedAttributeArray.Add("LaborCosts.ProductCostElement");
	NotCheckedAttributeArray.Add("LaborCosts.Count");
#EndRegion
#Region IntermediateRelease
	NotCheckedAttributeArray.Add("IntermediateRelease.StageSender");
	NotCheckedAttributeArray.Add("IntermediateRelease.RecipientStage");
	NotCheckedAttributeArray.Add("IntermediateRelease.Products");
	NotCheckedAttributeArray.Add("IntermediateRelease.Characteristic");
#EndRegion

#Region WorksToPerform
	NotCheckedAttributeArray.Add("WorksToPerform.Products");
	NotCheckedAttributeArray.Add("WorksToPerform.Characteristic");
	NotCheckedAttributeArray.Add("WorksToPerform.ProductCostElement");
#EndRegion
#Region Common
	// during disassembly, several last stages are possible
	If Status <> Enums.BOMStatuses.Valid
		Or ProductionProcessType <> Enums.ProductionProcessTypes.Disassembly
		Or Not DescriptionManufacturingProcess.SeveralLastSteps
		Then
		NotCheckedAttributeArray.Add("ManufacturedProducts.StageEditing");
		NotCheckedAttributeArray.Add("RecyclableWaste.StageEditing");
	EndIf;
	// during assembly, several first stages are possible
	If Status <> Enums.BOMStatuses.Valid
		Or ProductionProcessType <> Enums.ProductionProcessTypes.Assembly
		Or Not DescriptionManufacturingProcess.SeveralFirstSteps
		Then
		NotCheckedAttributeArray.Add("MaterialsAndServices.StageEditing");
		NotCheckedAttributeArray.Add("LaborCosts.StageEditing");
	EndIf;
#EndRegion

	CheckCurrentSpecification(NotCheckedAttributeArray, Cancel);
	
	CheckAdditionalDetailsOfProductionProcess(Cancel);
	
	CheckStageSelection("ManufacturedProducts",  "StageEditing", Cancel);
	CheckStageSelection("RecyclableWaste", "StageEditing", Cancel);
	CheckStageSelection("MaterialsAndServices", "StageEditing", Cancel);
	CheckStageSelection("LaborCosts",     "StageEditing", Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;

	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If Not IsFolder Then
		
		If Not IsNew() Then
			Block = New DataLock;
			Block.Add("Catalog.ProductionStages").SetValue("Owner", Ref);
			Block.Lock();
		EndIf;
		
		If DeletionMark Then
			Status = Enums.BOMStatuses.Closed_;
		EndIf;
		
		ClearUnusedData();
		
		If Not IsNew() Then
			CheckAdjustProductionSteps(Cancel);
		EndIf;
		
		FillInServiceDetails();
		
		If Cancel Then
			Return;
		EndIf;
		
		SetAttributesForStagesOfOperations();
	
		If Not IsNew() Then
			RegisterDurationCalculationAccordingToSpecification();
		EndIf;
		
		DataVersionID = New UUID();
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If Not IsFolder Then
	
		InformationRegisters.ProductsBOM.WriteProductsAccordingToSpecification(Ref, Status = Enums.BOMStatuses.Closed_);
		If Status = Enums.BOMStatuses.Valid Then
			UpdateSeriesReferenceIsRequired();
		EndIf;
		CompleteRecalculation = False;
		
		If AdditionalProperties.Property("CalculateProductionDuration", CompleteRecalculation) Then
			InformationRegisters.JobsOfStandardProductionDurationCalculation.AddJob(
				Ref, CompleteRecalculation, Not AdditionalProperties.Property("ProhibitCalculationOfProductionDuration"));
		EndIf;
	
	EndIf;
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	If IsFolder Then
		Return
	EndIf; 
	
	EmployeeResponsible = Users.CurrentUser();
	Status = Enums.BOMStatuses.UnderDevelopment;
	
	ValidOnDate = CurrentSessionDate();
	ValidToDate  = '00010101';
	
	// Clear the connection with the stages
	For Each TSName In TabularSectionNames() Do
		For Each RowData In ThisObject[TSName] Do
			RowData.Stage = Catalogs.ProductionStages.EmptyRef();
			RowData.StageEditing = Catalogs.ProductionStages.EmptyRef();
			RowData.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			RowData.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
		EndDo;
	EndDo;
	For Each RowData In IntermediateRelease Do
		RowData.StageSender = Catalogs.ProductionStages.EmptyRef();
		RowData.RecipientStage = Catalogs.ProductionStages.EmptyRef();
		RowData.SenderOperation = Catalogs.ManufacturingOperations.EmptyRef();
		RowData.OperationRecipient = Catalogs.ManufacturingOperations.EmptyRef();
	EndDo;
	
	For Each RowData In WorksToPerform Do
		RowData.Stage = Catalogs.ProductionStages.EmptyRef();
	EndDo;
	DataVersionID = Undefined;
	
EndProcedure

#EndRegion

#Region Private

#Region FillChecking

#Region ValidStatus

Procedure CheckCurrentSpecification(NotCheckedAttributeArray, Cancel)

	If Status <> Enums.BOMStatuses.Valid
			Or DeletionMark Then
		Return;
	EndIf;
	
	CheckIfOutputItemsAreFilledInWithValidStatus(
		NotCheckedAttributeArray,
		Cancel);
	
	CheckReturnableWasteFillingWithValidStatus(
		NotCheckedAttributeArray,
		Cancel);
	
	CheckContentCompletionWithValidStatus(
		NotCheckedAttributeArray,
		Cancel);
	
	CheckLaborCostsInValidStatus(Cancel);
	
	CheckProductionProcess(Cancel);
	
	CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel);
	
	CheckRouteMaps(Cancel);
	
	CheckDestinationParameters(Cancel);
	Catalogs.BillsOfMaterials.CheckNestedSpecifications(ThisObject, Cancel);
EndProcedure

Procedure CheckIfOutputItemsAreFilledInWithValidStatus(NotCheckedAttributeArray, Cancel)
	
	TSName           = "ManufacturedProducts";
	PresentationOfTS = PresentationOfTableInForm(TSName);
	
	UseBillOfMaterialsParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	// Checking the filling of the main product
	If Not ValueIsFilled(ManufacturedProducts) Then
		
		MessageText = StrTemplate(NStr("vi = 'Không có hàng nào được nhập trong danh sách ""%1""';
										|ru = 'Не введено ни одной строки в список ""%1""';
										|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
										|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
										|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
										|tr = '""%1"" listesine herhangi satır girilmedi'"), PresentationOfTS);
		Common.MessageToUser(
			MessageText,
			ThisObject,
			TSName,
			,
			Cancel);
			
		Return;
	EndIf;
	
	ThisIsBuild = (ProductionProcessType = Enums.ProductionProcessTypes.Assembly);
	
	AssignmentOptionTypeOfProduct = (AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind);
	DestinationOptionListOfProducts = (AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList);
	
	// Checking the filling of the tabular part
	For IndexOf = 0 To ManufacturedProducts.Count() - 1 Do
		
		If ThisIsBuild And Not DestinationOptionListOfProducts And IndexOf > 0 Then
			Break;
		EndIf;
		
		String = ManufacturedProducts[IndexOf];
		
		If String.Products.IsEmpty()
			And Not AssignmentOptionTypeOfProduct
			And (String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
				Or Not UseBillOfMaterialsParameterization) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Mặt hàng';
																						|ru = 'Номенклатура';
																						|en = 'Items'; fa = 'اقلام';
																						|it = 'Articolo';
																						|pl = 'Pozycja';
																						|tr = 'Öğe'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "Products");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				,
				Cancel);
			
		EndIf;
		
		If String.ProductKind.IsEmpty() And AssignmentOptionTypeOfProduct Then
				
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Dạng mặt hàng';
																						|ru = 'Вид номенклатуры';
																						|en = 'Item kind'; fa = 'نوع قلم';
																						|it = 'Tipo di articolo';
																						|pl = 'Rodzaj pozycji';
																						|tr = 'Ürün türü'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "ProductKind");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				,
				Cancel);
				
		EndIf;
		
		If Not AssignmentOptionTypeOfProduct Then
			CheckFillingOfQuantityInTabLine(TSName, PresentationOfTS, String, Cancel);
		EndIf;
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And String.ProcessByBOM
			And String.BillOfMaterials.IsEmpty() Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																						|ru = 'Спецификация';
																						|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																						|it = 'Specifica';
																						|pl = 'Specafikacja';
																						|tr = 'Ürün reçetesi'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "BillOfMaterials");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	If Not (ThisIsBuild And Not DestinationOptionListOfProducts) Then
		CheckRepeatOfOutputProducts(Cancel);
		CheckWhetherSharesOfOutputProductCostAreFilledIn(Cancel);
	EndIf;
	
	// Checking the characteristics of output products
	If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly 
		Or (ProductionProcessType = Enums.ProductionProcessTypes.Assembly 
			And ManufacturedProducts.Count() > 1) Then
			
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = TSName;
		CheckParameters.PresentationOfTS = PresentationOfTS;
		
		StringsList = Undefined;
		If ProductionProcessType = Enums.ProductionProcessTypes.Assembly Then
			
			StringsList = New Array;
			For It = 1 To ManufacturedProducts.Count()-1 Do
				String = ManufacturedProducts[It];
				If String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData
					Or Not UseBillOfMaterialsParameterization Then
					StringsList.Add(String);
				EndIf;
			EndDo;
			
		ElsIf ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And UseBillOfMaterialsParameterization Then
			
			StringsList = ManufacturedProducts.FindRows(New Structure("MethodOfItemVariantAutoselection", 
					Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
			
		EndIf;
		
		CheckParameters.StringsList = StringsList;
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
	EndIf;
	
	// In version 2.2, production at the calculated cost is possible only at the last stages
	If ProductionServer.ProductionIsUsed22()
		And Not IsNew() Then 
		
		ReleasingStages = ReleasingStages();
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And ReleasingStages.Count() > 1 Then
			
			Template = NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""%1"" ở công đoạn ""%2""';
							|ru = 'Не введено ни одной строки в список ""%1"" по этапу ""%2""';
							|en = 'No lines entered into the ""%1"" list by the ""%2"" stage'; fa = 'No lines entered into the ""%1"" list by the ""%2"" stage';
							|it = 'Non è immessa alcuna riga nell''elenco ""%1"" per la fase ""%2""';
							|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1"" dla etapu ""%2""';
							|tr = '""%2"" aşamasına göre ""%1"" listesine herhangi bir satır girilmedi'");
			For Each ReleasingStage In ReleasingStages Do
				
				TheStructureOfTheSearch = New Structure("StageEditing", ReleasingStage);
				If ManufacturedProducts.FindRows(TheStructureOfTheSearch).UBound() = -1 Then
					
					MessageText = StrTemplate(Template, PresentationOfTS, ReleasingStage);
					
					Common.MessageToUser(
						MessageText,
						ThisObject,
						TSName,
						,
						Cancel);
					
				EndIf;
				
			EndDo;
			
		EndIf;
		
		Template = NStr("vi = 'Xuất xưởng với chi phí tính toán chỉ có thể ở công đoạn cuối (xem danh sách ""%1"", dòng%2)';
						|ru = 'Выпуск по рассчитываемой стоимости возможен только на последнем этапе (см. список ""%1"", строка %2)';
						|en = 'Release at calculated cost is possible only at the last stage (see the ""%1"" list, line %2)'; fa = 'Release at calculated cost is possible only at the last stage (see the ""%1"" list, line %2)';
						|it = 'Il rilascio sul valore calcolato è possibile solo nell''ultima fase (vedasi elenco ""%1"", riga %2)';
						|pl = 'Wypuszczanie produkcji po szacowanej cenie jest możliwe tylko na ostatnim etapie (zob. listę ""%1"", wiersz %2)';
						|tr = 'Hesaplanan maliyetle ürün çıkışı sadece son aşamada mümkündür (bk. ""%1"" listesi, %2 satırı)'");
		For Each String In ManufacturedProducts Do
			
			If String.StageEditing.IsEmpty()
				Or ReleasingStages.Find(String.StageEditing) <> Undefined Then
				Continue;
			EndIf;
			
			MessageText = StrTemplate(Template, PresentationOfTS, Format(String.LineNumber, "NG="));
			
			Field = CommonClientServer.PathToTabularSection(
				TSName, String.LineNumber, "StageEditing");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				, 
				Cancel);
			
		EndDo;
		
	EndIf;
EndProcedure

Procedure CheckReturnableWasteFillingWithValidStatus(NotCheckedAttributeArray, Cancel)
	
	If ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	TSName           = "RecyclableWaste";
	PresentationOfTS = PresentationOfTableInForm(TSName);
	
	For Each String In RecyclableWaste Do
		
		If String.Products.IsEmpty()
			And (String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
				Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Mặt hàng';
																						|ru = 'Номенклатура';
																						|en = 'Items'; fa = 'اقلام';
																						|it = 'Articolo';
																						|pl = 'Pozycja';
																						|tr = 'Öğe'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "Products");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				,
				Cancel);
			
		EndIf;
		
		CheckFillingOfQuantityInTabLine(TSName, PresentationOfTS, String, Cancel);
		
		If ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And String.ProcessByBOM
			And String.BillOfMaterials.IsEmpty() Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																						|ru = 'Спецификация';
																						|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																						|it = 'Specifica';
																						|pl = 'Specafikacja';
																						|tr = 'Ürün reçetesi'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "BillOfMaterials");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,
				,
				Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(String.ProductCostElement) Then
		
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Dạng tính giá thành';
																						|ru = 'Статья калькуляции';
																						|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																						|it = 'Voce di calcolo';
																						|pl = 'Rodzaj kosztu';
																						|tr = 'Ürün maliyet kalemi'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "ProductCostElement");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,,
				Cancel);
			
		EndIf;
		
	EndDo;
	
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = TSName;
	CheckParameters.PresentationOfTS = PresentationOfTS;
	If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		StringsList = RecyclableWaste.FindRows(New Structure("MethodOfItemVariantAutoselection", Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
		CheckParameters.StringsList = StringsList;
	EndIf;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
EndProcedure

Procedure CheckContentCompletionWithValidStatus(NotCheckedAttributeArray, Cancel)
	
	TSName           = "MaterialsAndServices";
	PresentationOfTS = PresentationOfTableInForm(TSName);
	
	ProductionIsUsed22 = ProductionServer.ProductionIsUsed22();
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	ItemsTypes           = Common.ObjectsAttributeValue(MaterialsAndServices.UnloadColumn("Products"), "ItemsType");
	
	For Each String In MaterialsAndServices Do
		
		If String.Products.IsEmpty()
			And (String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData
			
			Or String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty
				And String.ProducedInProcess
				And String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			
			Or String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess
				And String.ProducedInProcess
				
			Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")
			) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Mặt hàng';
																						|ru = 'Номенклатура';
																						|en = 'Items'; fa = 'اقلام';
																						|it = 'Articolo';
																						|pl = 'Pozycja';
																						|tr = 'Öğe'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "Products");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,,
				Cancel);
			
		EndIf;
		
		If String.NumberOfPackages = 0
			And (IsBlankString(String.QuantityCalculationAlgorithm)
			Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Số lượng';
																						|ru = 'Количество';
																						|en = 'Quantity'; fa = 'مقدار';
																						|it = 'Quantità';
																						|pl = 'Ilość';
																						|tr = 'Miktar'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "NumberOfPackages");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,,
				Cancel);
		
		EndIf;
		
		If Not ValueIsFilled(String.ProductCostElement)
			And Not String.ProducedInProcess
			And Not (ItemsTypes.Get(String.Products) = Enums.ItemsTypes.Set
					And SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.Specifications) Then
			
			MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Dạng tính giá thành';
																						|ru = 'Статья калькуляции';
																						|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																						|it = 'Voce di calcolo';
																						|pl = 'Rodzaj kosztu';
																						|tr = 'Ürün maliyet kalemi'"), String.LineNumber, PresentationOfTS);
			Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "ProductCostElement");
			
			Common.MessageToUser(
				MessageText,
				ThisObject,
				Field,,
				Cancel);
			
		EndIf;
		
		If String.ProducedInProcess And Not ValueIsFilled(String.SourceOfSemiFinishedProduct) Then
			
			If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials 
				And GetFunctionalOption("UseProductionManagement") Then // only 2.1 
				
				MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Bảng kê chi tiết các nguồn lực sản xuất';
																							|ru = 'Спецификация';
																							|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																							|it = 'Specifica';
																							|pl = 'Specafikacja';
																							|tr = 'Ürün reçetesi'"), String.LineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "MethodOfGettingTheMaterialEditing");
				
				Common.MessageToUser(
					MessageText,
					ThisObject,
					Field,,
					Cancel);
				
			EndIf;
			
			If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
				
				MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Công đoạn sản xuất bán thành phẩm';
																							|ru = 'Этап выпуска полуфабриката';
																							|en = 'Stage of semi-finished product release'; fa = 'Stage of semi-finished product release';
																							|it = 'Fase di rilascio del semilavorato';
																							|pl = 'Etap produkcji półproduktu';
																							|tr = 'Yarın mamul imalatı aşaması'"), String.LineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "MethodOfGettingTheMaterialEditing");
			
				Common.MessageToUser(
					MessageText,
					ThisObject,
					Field,,
					Cancel);
				
			EndIf;
			
		EndIf;
		
		If String.MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.Provide
			And (ProductionIsUsed22 And ItemsTypes[String.Products] = Enums.ItemsTypes.ReusablePackage
				Or ItemsTypes[String.Products] = Enums.ItemsTypes.Set) Then
				
				MessageText = StrTemplate(
					NStr("vi = 'Đối với chứng từ có loại ""%1"", chỉ có một dấu hiệu của phương pháp để có được ""Cung cấp"".';
						|ru = 'Для материала с типом ""%1"" доступно только указание способа получения ""Обеспечивать""';
						|en = 'You can only specify the ""Supply"" receipt method for the material with the ""%1"" type'; fa = 'You can only specify the ""Supply"" receipt method for the material with the ""%1"" type';
						|it = 'Per il materiale con tipo ""%1"" è disponibile solo l''indicazione del metodo di ricezione ""Fornire""';
						|pl = 'Dla materiału o typie ""%1"" dostępne jest tylko podanie sposobu otrzymania ""Zapewniaj""';
						|tr = '""%1"" türündeki bir malzeme için sadece ""Sağla"" elde edilme yönteminin belirtilmesi mevcuttur.'"),
					ItemsTypes[String.Products]);
				
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "Correctness", NStr("vi = 'Phương pháp nhận nguyên liệu';
													|ru = 'Способ получения материала';
													|en = 'Method of receiving material'; fa = 'روش دریافت ماده';
													|it = 'Metodo di acquisizione del materiale';
													|pl = 'Sposób otrzymania materiału';
													|tr = 'Malzemenin elde edilme yöntemi'"), String.LineNumber, PresentationOfTS, MessageText);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "MethodOfGettingTheMaterialEditing");
			
				Common.MessageToUser(
					MessageText,
					ThisObject,
					Field,,
					Cancel);
			
		EndIf;
		
	EndDo;
	
	// Characteristics
	CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
	CheckParameters.TSName = TSName;
	CheckParameters.PresentationOfTS = PresentationOfTS;
	If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		StringsList = MaterialsAndServices.FindRows(New Structure("MethodOfItemVariantAutoselection", Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData));
		CheckParameters.StringsList = StringsList;
	EndIf;
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel, CheckParameters);
	
	// Additional checks: intermediate semi-finished products, production 2.1
	ParametersForCheckingIntermediateSemiFinishedProducts = ProductDataManagement.GetParametersForCheckingInternalSemiFinishedProducts(ThisObject);
	StructureOfChecks = New Structure("ComplianceWithSpecification, MultiplicityOfProducedQuantity, FillingInternalSemiFinishedProducts");
	CheckParameters = New Structure;
	CheckParameters.Insert("AttributeName", "MethodOfGettingTheMaterialEditing");
	CheckParameters.Insert("StructureOfChecks", StructureOfChecks);
	CheckParameters.Insert("ParametersForCheckingInternalSemiFinishedProducts", ParametersForCheckingIntermediateSemiFinishedProducts);
	
	If ProductDataManagement.AvailableDescriptionOfProbabilityOfApplicationOfMaterials() Then
		StringsList = MaterialsAndServices.FindRows(New Structure("ProducedInProcess,AlternateType",True,False));
	Else
		StringsList = MaterialsAndServices.FindRows(New Structure("ProducedInProcess",True));
	EndIf;
	
	ProductDataManagement.CheckSpecificationsOfSemiFinishedProducts(
		StringsList,
		CheckParameters,
		Cancel,
		ThisObject);
	
EndProcedure

Procedure CheckLaborCostsInValidStatus(Cancel)
	
	If ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	TemplateArticleCalculation = NStr("vi = 'Cột ""Dạng tính giá thành"" trong hàng %1 của danh sách ""Chi phí nhân công"" không được điền';
										|ru = 'Не заполнена колонка ""Статья калькуляции"" в строке %1 списка ""Трудозатраты""';
										|en = 'Column ""Product cost element"" in line %1 of the ""Labor costs"" list is not filled in'; fa = 'Column ""Product cost element"" in line %1 of the ""Labor costs"" list is not filled in';
										|it = 'La colonna ""Articolo di costo"" nella riga %1 dell''elenco ""Costi di manodopera"" non è compilata';
										|pl = 'Nie wypełniono kolumny ""Rodzaj kosztu"" w wierszu %1 listy ""Nakłady pracy""';
										|tr = '""İş Gücü Maliyetleri"" listesinin %1 satırındaki ""Ürün maliyet kalemi"" sütunu doldurulmadı'");
	TemplateQuantity        = NStr("vi = 'Cột ""Số lượng"" trong hàng %1 của danh sách ""Chi phí nhân công"" không được điền';
									|ru = 'Не заполнена колонка ""Количество"" в строке %1 списка ""Трудозатраты""';
									|en = 'Column ""Quantity"" in line %1 of the ""Labor costs"" list is not filled in'; fa = 'Column ""Quantity"" in line %1 of the ""Labor costs"" list is not filled in';
									|it = 'La colonna ""Quantità"" nella riga %1 dell''elenco ""Costi di manodopera"" non è compilata';
									|pl = 'Nie wypełniono kolumny ""Ilość"" w wierszu %1 listy ""Nakłady pracy""';
									|tr = '""İş Gücü Maliyetleri"" listesinin %1 satırındaki ""Miktar"" sütunu doldurulmadı'");
	
	For Each String In LaborCosts Do
		
		If String.ProductCostElement.IsEmpty() Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateArticleCalculation, 
				Format(String.LineNumber, "NG="));
			
			Field = CommonClientServer.PathToTabularSection("LaborCosts", String.LineNumber, "ProductCostElement");
			
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			
		EndIf;
		
		If String.Count = 0
			And (IsBlankString(String.QuantityCalculationAlgorithm) 
			Or Not GetFunctionalOption("UseBillOfMaterialsParameterization")) Then
			
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				TemplateQuantity, 
				Format(String.LineNumber, "NG="));
			
			Field = CommonClientServer.PathToTabularSection("LaborCosts", String.LineNumber, "Count");
			
			Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckAutoSelectionCalculationByFormulasSelectionByProperties(Cancel)
	
	If Not GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		Return;
	EndIf;
#Region AutoSelection

	// Let's check that the properties specified in the auto-selection and conditions of use are in the product
	MainProduct = ProductDataManagementClientServer.MainPropsOfMainProductSpecification(ThisObject);
	If MainProduct.Value.IsEmpty() Then
		Return;
	EndIf;
	
	If MainProduct.Name = "ProductKind" Then
		TypeOfProducts = MainProduct.Value;
	Else
		TypeOfProducts = Common.ObjectAttributeValue(MainProduct.Value, "ProductKind");
	EndIf;
	
	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesForAutoSelection(TypeOfProducts);
	
	ChecksArray = New Array;
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "ManufacturedProducts", PresentationOfTableInForm("ManufacturedProducts"), "Products"));
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "RecyclableWaste", PresentationOfTableInForm("RecyclableWaste"), "Products"));
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "MaterialsAndServices", PresentationOfTableInForm("MaterialsAndServices"), "Products"));
	
	// Auto-selection settings for materials
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
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.BillsOfMaterials.ManufacturedProducts
		
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
				Field = CommonClientServer.PathToTabularSection(Validation.TSName, CurrentRow.LineNumber, Validation.Attribute);
				Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
			EndIf;
			
		EndDo;
		
	EndDo;
	
#EndRegion

#Region SelectionByProperties

	ListOfAllAvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(TypeOfProducts,,False);

	// Usage settings and quantity calculation
	MessageTemplate = NStr("vi = 'Thuộc tính không chính xác được chỉ định trong cài đặt sử dụng (danh sách ""%1"", dòng%2).';
							|ru = 'В настройках использования указаны неверные свойства (список ""%1"", строка %2).';
							|en = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).'; fa = 'Incorrect properties are specified in usage settings (the ""%1"" list, line %2).';
							|it = 'Proprietà non valide specificate nelle impostazioni di utilizzo (elenco ""%1"", riga %2).';
							|pl = 'W ustawieniach używania są wskazane nieprawidłowe właściwości (lista ""%1"", wiersz %2).';
							|tr = 'Kullanım ayarlarında yanlış özellikler belirtildi (""%1"" listesi, %2 satırı).'");
	
	ChecksArray.Add(New Structure("TSName, Presentation, Attribute", "LaborCosts", PresentationOfTableInForm("LaborCosts"), "WorkKind"));
	
	For Each Validation In ChecksArray Do
		
		TabularSection = ThisObject[Validation.TSName]; // CatalogTabularSection.BillsOfMaterials.ManufacturedProducts
		
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
	
	If Not InteractiveVerificationPassed() Then
		Catalogs.ProductionStages.CheckComplianceOfSelectionByProperties(
			Ref, ListOfAllAvailableProperties, MultiStageProductionProcess, Cancel);
	EndIf;
	
#EndRegion

#Region ApplicationClarifications

	SettingsKinds = New ValueList;
	SettingsKinds.Add("Products",   NStr("vi = 'Trong tùy chỉnh lọc theo thuộc tính mặt hàng đã chỉ ra sai thuộc tính.';
										|ru = 'В настройках отбора по свойствам номенклатуры указаны неверные свойства.';
										|en = 'Incorrect properties are specified in filter settings by item properties.'; fa = 'Incorrect properties are specified in filter settings by item properties.';
										|it = 'Le impostazioni di filtro delle proprietà degli articoli non sono corrette.';
										|pl = 'W ustawieniach filtru według właściwości produktu są podane nieprawidłowe właściwości.';
										|tr = 'Öğe özelliklerine göre filtreleme ayarlarında yanlış özellikler belirtildi.'"));
	SettingsKinds.Add("Characteristic", NStr("vi = 'Trong tùy chỉnh lọc theo thuộc tính của đặc tính đã chỉ ra sai thuộc tính.';
											|ru = 'В настройках отбора по свойствам характеристики указаны неверные свойства.';
											|en = 'Incorrect properties are specified in filter settings by variant properties.'; fa = 'Incorrect properties are specified in filter settings by variant properties.';
											|it = 'Le impostazioni di filtro delle proprietà delle caratteristiche non sono corrette.';
											|pl = 'W ustawieniach filtru według właściwości charakterystyki są podane nieprawidłowe właściwości.';
											|tr = 'Varyant özelliklerine göre filtreleme ayarlarında yanlış özellikler belirtildi.'"));
	
	Field = "";
	If InteractiveVerificationPassed() Then
		Field = ?(AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind,
			"MainProductProductKind",
			"MainProductProducts");
	EndIf;
	
	For Each Item In SettingsKinds Do
		
		SettingKind                  = Item.Value;
		ViewSettingsAvailableProperties = ProductDataManagement.GetPropertiesToSelectByProperties(TypeOfProducts, SettingKind);
		TypeOfSetupCommunicationKey         = ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey(SettingKind);
		
		SelectionLines = SelectionByProperties.FindRows(New Structure("ConnectionKey", TypeOfSetupCommunicationKey));
		For Each StringSelection_ In SelectionLines Do
			
			If ViewSettingsAvailableProperties.Find(StringSelection_.Property, "Property") = Undefined Then
				
				Common.MessageToUser(
					Item.Presentation,
					Ref,
					Field,,
					Cancel);
				
			EndIf;
			
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
	
	DescriptionOfSources = Catalogs.BillsOfMaterials.UploadDataForFormulaConstructor(ThisObject, "");
	
	If ChecksArray.Count() > 0 Then
		
		CheckParameters = New Structure("Content, OutputMessages, ClearNotFound", ChecksArray, True, False);
		
		ProductDataManagement.CheckClearQuantityCalculationAlgorithm(ThisObject, DescriptionOfSources, CheckParameters, Cancel);
		
	EndIf;
	
	If Not InteractiveVerificationPassed() Then
		Catalogs.ProductionStages.CheckQuantityCalculationAlgorithm(Ref, DescriptionOfSources, MultiStageProductionProcess, Cancel);
	EndIf;
	
#EndRegion

EndProcedure

Procedure CheckProductionProcess(Cancel)
	
	If ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	If EconomicReleaseLot <> 0
		And MinimumReleaseLot > EconomicReleaseLot Then
	
		MessageText = NStr("vi = 'Xuất xưởng lô tối thiểu không thể vượt quá lô tối ưu';
							|ru = 'Минимальная партия выпуска не может превышать оптимальную партию';
							|en = 'Minimum release lot cannot exceed the size of economic lot'; fa = 'Minimum release lot cannot exceed the size of economic lot';
							|it = 'Il lotto minimo di rilascio non può superare il lotto ottimale';
							|pl = 'Minimalna partia produkcji nie może być większa od partii optymalnej';
							|tr = 'Minimum üretim lotu, optimum lotu aşamaz'");
		
		Common.MessageToUser(
			MessageText,
			ThisObject,
			"MinimumReleaseLot",
			,
			Cancel);
		
	EndIf;
	
	If InteractiveVerificationPassed() Then
		Return;
	EndIf;
	
	Messages = New Array(GetUserMessages(True));
	
	NumberOfStages = NumberOfProductionStages();
	If NumberOfStages = 0 Then
		MessageText = NStr("vi = 'Cần tạo công đoạn sản xuất.';
							|ru = 'Необходимо создать этап производства.';
							|en = 'Create a production stage.'; fa = 'Create a production stage.';
							|it = 'È necessario creare una fase di produzione.';
							|pl = 'Należy utworzyć etap produkcji.';
							|tr = 'Üretim aşaması oluşturulmalı.'");
		Common.MessageToUser(MessageText,,,,Cancel);
	ElsIf NumberOfStages > 1 Then
		If Not ProductDataManagementClientServer.MultiStageProductionProcessIsAvailable() Then
			MessageText = ProductDataManagementClientServer.MultiStageProductionProcessErrorText();
			Common.MessageToUser(MessageText,,,,Cancel);
		Else
			CheckOrderOfStages(Cancel);
		EndIf;
	EndIf;
	
	CheckBankDetails(Cancel);
	
	CheckProductionStepsOnSide(Cancel);
	CheckDetailsOrderOfOperations(Cancel);
	CheckReverseKittingInStatusValid(Cancel);
	CheckCompletionOfInterimIssueInStatusValid(Cancel);
	CheckCompletionOfWorkInProgressInStatusValid(Cancel);
	If Cancel Then
		RecordProductionProcessVerificationErrorsInLog();
		Message = New UserMessage;
		Message.Text = TextOfProductionProcessErrorMessage();
		Message.SetData(ThisObject);
		Messages.Add(Message);
	EndIf;
	
	For Each Message In Messages Do
		Message.Message();
	EndDo;
	
EndProcedure

Procedure CheckRouteMaps(Cancel) 

	If GetFunctionalOption("StoreOperationsInBillsOfMaterials")
			Or Not AdditionalProperties.Property("CheckStages")
			Or ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductionStages.Ref                            AS Stage,
	|	ProductionStages.Description                      AS Description,
	|	ProductionStages.RouteSheet                   AS Ref,
	|	ProductionStages.RouteSheet.Status            AS Status,
	|	ProductionStages.RouteSheet.ValidOnDate    AS ValidOnDate,
	|	ProductionStages.RouteSheet.ValidToDate     AS ValidToDate
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|		INNER JOIN Catalog.ProductionStages AS ProductionStages
	|		ON (ProductionStages.Owner = BillsOfMaterials.Ref)
	|			AND (NOT ProductionStages.DeletionMark)
	|			AND (ProductionStages.RouteSheet <> VALUE(Catalog.RouteSheets.EmptyRef))
	|WHERE
	|	BillsOfMaterials.Ref = &BillOfMaterials
	|
	|ORDER BY
	|	ProductionStages.StageNumber";
	
	Query.SetParameter("BillOfMaterials", Ref);
	
	Result = Query.Execute();
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		Catalogs.BillsOfMaterials.CheckCorrectnessOfRouteMap(
			ValidOnDate, ValidToDate, Selection, Selection.Stage, Selection.Description, Cancel);
		
	EndDo;
	
	Return; // the handler is empty
	
EndProcedure

Procedure CheckDestinationParameters(Cancel)
	
	If InteractiveVerificationPassed()
			Or Not GetFunctionalOption("UseBOMAssignmentParameters") Then
		Return;
	EndIf;
	
	DestinationParameterValues = Catalogs.BillsOfMaterials.ValuesOfBOMAssignmentParameters(
		CommonClientServer.ValueInArray(Ref)).Get(Ref);
	
	For Each String In DestinationParameterValues Do
		
		If Not ProductDataManagementCached.DestinationParameterIsUsed(String.ParameterKind, String.Attribute, False) Then
			Continue;
		EndIf;
		
		ProductDataManagement.CheckFillingOfDestinationParameter(
			Ref, String.ParameterKind, String.Attribute, String.ValueStructure, String.ValueType, Cancel);
		
	EndDo;
	
	Return; // the handler is empty
	
EndProcedure

Procedure CheckBankDetails(Cancel)

	Query = New Query;
	Query.Text = 
	"SELECT
	|	ProductionStages.Ref
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	ProductionStages.Owner = &BillOfMaterials
	|	AND NOT ProductionStages.DeletionMark";
	
	Query.SetParameter("BillOfMaterials", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		StageObject = Selection.Ref.GetObject();
		StageObject.AdditionalProperties.Insert("SpecificationStatus_", Status);
		If Not StageObject.CheckFilling() Then
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckOrderOfStages(Cancel)
	
	// The order of the production process
	
	StructureOfChecks = ProductionProcessEditor.StructureOfStageSequenceChecks(ProductionProcessType);
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("NameOfOperationsCatalog",     "ProductionStages");
	ParametersStructure.Insert("OperationNumberField",          "StageNumber");
	ParametersStructure.Insert("NextOperationNumberField", "NextStageNo");
	
	ProductionProcessEditor.SequenceOfOperationsIsCorrect(
			Ref,
			ParametersStructure,
			StructureOfChecks,
			Cancel);
	
	// The order of semi-finished products produced at the stages and the "Plan not earlier" setting
	
	Filter = New Structure("ProducedInProcess", True);
	RowsArray = MaterialsAndServices.FindRows(Filter);
	For IndexOf = -RowsArray.UBound() To 0 Do;
		TableRow = RowsArray[-IndexOf];
		If (TableRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
					And ValueIsFilled(TableRow.PlanNotEarlierThan)
				Or TableRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			) Then
			Continue;
		EndIf;
		RowsArray.Delete(-IndexOf);
	EndDo;
	
	If RowsArray.UBound() <> -1 Then
		
		ReferencesArrray = New Array;
		For Each TableRow In RowsArray Do
			ReferencesArrray.Add(TableRow.StageEditing);
		EndDo;
		
		MessageTemplate = NStr("vi = 'Một chuỗi các bước không chính xác đã được phát hiện (liệt kê ""Vật liệu và công việc"", dòng%1).';
								|ru = 'Обнаружена неправильная последовательность этапов (список ""Материалы и работы"", строка %1).';
								|en = 'Wrong order of stages (""Materials and works"" list, line %1).'; fa = 'Wrong order of stages (""Materials and works"" list, line %1).';
								|it = 'È stata rilevata una sequenza di passaggi errata (elenco ""Materiali e lavori"", riga %1).';
								|pl = 'Wykryto nieprawidłową kolejność etapów (lista ""Materiały i prace"", wiersz %1).';
								|tr = 'Yanlış aşama sırası tespit edildi (""Malzemeler ve İşler"" listesi, %1 satırı).'");
		
		Predecessors = Catalogs.ProductionStages.Predecessors(ReferencesArrray);
		For Each TableRow In RowsArray Do
			If (TableRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
					And Predecessors[TableRow.StageEditing].Find(TableRow.PlanNotEarlierThan) <> Undefined
				Or TableRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
					And Predecessors[TableRow.StageEditing].Find(TableRow.SourceOfSemiFinishedProduct) <> Undefined
				) Then
				Continue;
			EndIf;
			MessageText = StrTemplate(MessageTemplate, Format(TableRow.LineNumber, "NG="));
			Common.MessageToUser(
				MessageText,
				ThisObject,
				CommonClientServer.PathToTabularSection("MaterialsAndServices", TableRow.LineNumber, "MethodOfGettingTheMaterialEditing"),
				, Cancel);
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckRepeatOfOutputProducts(Cancel)
	
	PresentationOfTS = PresentationOfTableInForm("ManufacturedProducts");
	
	If ManufacturedProducts.Count() > 1 Then
		
		ProductRepeatPattern = NStr("vi = 'Sản phẩm đầu ra ""%1"" đã được mô tả trong bảng kê chi tiết các nguồn lực sản xuất (xem danh sách ""%2"", dòng %3). Không được phép sao chép các sản phẩm đầu ra trong cùng bảng kê chi tiết các nguồn lực sản xuất.';
									|ru = 'Выходное изделие ""%1"" уже описано в спецификации (см. список ""%2"", строка %3). Дублирование выходных изделий в рамках одной спецификации не допускается.';
									|en = 'The ""%1"" finished product is already described in the bill of materials (see the ""%2"" list, line %3). Duplication of finished products within one bill of materials is not allowed.'; fa = 'The ""%1"" finished product is already described in the bill of materials (see the ""%2"" list, line %3). Duplication of finished products within one bill of materials is not allowed.';
									|it = 'Il prodotto di output ""%1"" è già descritto nelle specifiche (vedasi lista ""%2"", riga %3). La duplicazione di prodotti di output in una specifica non è consentita.';
									|pl = 'Wyrób wyjściowy ""%1"" jest już opisany w specyfikacji (zob. lista ""%2"", wiersz %3). Duplikowanie wyrobów wyjściowych w ramach jednej specyfikacji jest niedopuszczalne.';
									|tr = 'Üretilen ""%1"" nihai ürünü zaten ürün reçetesinde açıklanmıştır (bk. ""%2"" listesi, %3 satırı). Üretilen nihai ürünlerin aynı ürün reçetesi dahilinde çoğaltılmasına izin verilmemektedir.'");

		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("Products");
		TheStructureOfTheSearch.Insert("PropertyThatContainsProducts");
		
		For Each TableRow In ManufacturedProducts Do
			
			TheStructureOfTheSearch.Products                   = TableRow.Products;
			TheStructureOfTheSearch.PropertyThatContainsProducts = ?(
				TableRow.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInProductsProperty,
				TableRow.PropertyThatContainsProducts,
				ChartsOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef());
			
			FoundProducts_ = ManufacturedProducts.FindRows(TheStructureOfTheSearch);
			For Each StringFound_ In FoundProducts_ Do
				
				If TableRow.LineNumber > StringFound_.LineNumber
					And (TableRow.Characteristic = StringFound_.Characteristic
						Or TableRow.Characteristic.IsEmpty()
						Or StringFound_.Characteristic.IsEmpty()) Then
						
						ProductPresentation = ProductsClientServer.ProductPresentation(
							TableRow.Products,
							?(StringFound_.Characteristic.IsEmpty(),Undefined,TableRow.Characteristic));
							
						MessageText = StrTemplate(ProductRepeatPattern, ProductPresentation, PresentationOfTS, Format(StringFound_.LineNumber, "NG="));
						
						Field = CommonClientServer.PathToTabularSection(
							"ManufacturedProducts", TableRow.LineNumber, "Products");
							
						Common.MessageToUser(
							MessageText, ThisObject, Field,, Cancel);
							
						Break;
						
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndIf;

EndProcedure

Procedure CheckWhetherSharesOfOutputProductCostAreFilledIn(Cancel)
	
	// The verification is not performed for the calculation methods "By planned cost", "By volume", "By weight", "By quantity"
	If MethodOfAllocatingFinishedProductCosts <> Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
		Return;
	EndIf;
	
	CostAllocationParameters = Catalogs.BillsOfMaterials.CostAllocationParameters(ThisObject);
	
	QueryText =
	"SELECT
	|	ManufacturedProducts.StageEditing AS Ref,
	|	ManufacturedProducts.LineNumber        AS LineNumber,
	|
	|	ManufacturedProducts.Products       AS Products,
	|	ManufacturedProducts.Characteristic     AS Characteristic,
	|	ManufacturedProducts.StageEditing AS StageEditing,
	|
	|	ManufacturedProducts.Package           AS Package,
	|	ManufacturedProducts.NumberOfPackages AS NumberOfPackages,
	|
	|	ManufacturedProducts.CostShare      AS CostShare
	|
	|INTO TabularSection
	|FROM
	|	&ManufacturedProducts AS ManufacturedProducts
	|;
	|" + ProductionServer.QueryTextCheckSharesOfCostOfOutputProducts(CostAllocationParameters.LinkFields);
	
	Query = New Query(QueryText);
	Query.SetParameter("ManufacturedProducts", ManufacturedProducts.Unload());
	
	QueryResult = Query.Execute();
	If Not QueryResult.IsEmpty() Then
		
		PresentationOfTS = PresentationOfTableInForm("ManufacturedProducts");
		Selection = QueryResult.Select();
		While Selection.Next() Do;
			
			MessageText = CommonClientServer.FillingErrorText(
				"Column", "FillType", NStr("vi = 'Tỷ lệ giá trị';
											|ru = 'Доля стоимости';
											|en = 'Cost share'; fa = 'سهم بها';
											|it = 'Quota del costo';
											|pl = 'Udział kosztów';
											|tr = 'Maliyet payı'"), Selection.LineNumber, PresentationOfTS);
			
			Field = CommonClientServer.PathToTabularSection(
				"ManufacturedProducts", Selection.LineNumber, "CostShare");
			
			Common.MessageToUser(
				MessageText, ThisObject, Field,, Cancel);
		
			EndDo;
			
	EndIf;
	
EndProcedure

Procedure CheckDetailsOrderOfOperations(Cancel)
	
	If Not GetFunctionalOption("StoreOperationsInBillsOfMaterials") Then
		Return;
	EndIf;
	
	StructureOfChecks = ProductionProcessEditor.StructureOfOperationSequenceChecks();
	TransactionTable   = ProductionProcessEditor.TableOfVerificationOfOrderOfElementsOfProductionProcessDesigner();
	
	QueryText = "
	|SELECT
	|	ProductionStages.Ref                      AS Stage,
	|	ProductionStages.Department               AS StageDivision,
	|	ProductionStages.Department.Presentation AS StageDivisionPresentation,
	|
	|	CatOperations.Ref                 AS Operation,
	|	CatOperations.Presentation          AS Presentation,
	|	CatOperations.OperationNumber          AS OperationNumber,
	|	CatOperations.NextOperation AS NextOperation,
	|
	|	CatOperations.TechnologicalProcess                             AS TechnologicalProcess,
	|	CatOperations.TechnologicalProcess.Presentation               AS TechnicalProcessPresentation,
	|	CatOperations.TechnologicalProcess.Status                      AS ProcessStatus,
	|	CatOperations.TechnologicalProcess.Department               AS TechnicalProcessDivision,
	|	CatOperations.TechnologicalProcess.Department.Presentation AS TechnicalProcessDivisionPresentation,
	|
	|	&CorrectnessOfSequenceOfControlOperations,
	|
	|	""NextOperation""         AS NextOperationNumberField,
	|	MAX(CASE WHEN CatFollowingOperations.Ref IS NULL
	|						AND CatOperations.NextOperation <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|			END) AS ThereIsNoNextOperation
	|
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|
	|		LEFT JOIN Catalog.ManufacturingOperations AS CatOperations
	|		ON CatOperations.Owner = ProductionStages.Ref
	|		AND NOT CatOperations.DeletionMark
	|
	|		LEFT JOIN Catalog.ManufacturingOperations AS CatFollowingOperations
	|		ON CatOperations.NextOperation = CatFollowingOperations.OperationNumber
	|			AND CatOperations.Owner = CatFollowingOperations.Owner
	|			AND NOT CatFollowingOperations.DeletionMark
	|
	|WHERE
	|	ProductionStages.Owner = &BillOfMaterials
	|	AND NOT ProductionStages.DeletionMark
	|	AND NOT CatOperations.Ref IS NULL
	|
	|GROUP BY
	|	ProductionStages.Ref,
	|	CatOperations.Ref,
	|	CatOperations.OperationNumber,
	|	CatOperations.NextOperation,
	|	CatOperations.TechnologicalProcess
	|
	|ORDER BY
	|	ProductionStages.StageNumber,
	|	CatOperations.OperationNumber
	|
	|TOTALS BY
	|	Stage
	|";
	
	TextControlOperations = "";
	If StructureOfChecks.Property("ControlOperations") Then
		TextControlOperations = ProductionProcessEditor.TextCorrectnessOfSequenceOfControlOperations();
	EndIf;
	QueryText = StrReplace(QueryText, "&CorrectnessOfSequenceOfControlOperations," , TextControlOperations);
	
	Query = New Query;
	Query.SetParameter("BillOfMaterials", Ref);
	Query.Text = QueryText;
	
	SamplingStages = Query.Execute().Select(QueryResultIteration.ByGroups, "Stage");
	While SamplingStages.Next() Do
		
		TransactionTable.Clear();
		
		OperationSelection_ = SamplingStages.Select();
		While OperationSelection_.Next() Do
			
			OperationObject = OperationSelection_.Operation.GetObject();
			OperationObject.AdditionalProperties.Insert("SpecificationStatus_", Status);
			
			If Not OperationObject.CheckFilling() Then
				Cancel = True;
			EndIf;
			
			If OperationObject.ContainsTechnologicalProcess Then
				
				If SamplingStages.StageDivision <> OperationSelection_.TechnicalProcessDivision Then
				
					MessageText = StrTemplate(
						NStr("vi = 'Bộ phận của quy trình kỹ thuật (%1) không tương ứng với bộ phận của công đoạn (""%2"").';
							|ru = 'Подразделение технологического процесса (""%1"") не соответствует подразделению этапа (""%2"").';
							|en = 'The technological process business unit (""%1"") does not match the stage business unit (""%2"").'; fa = 'The technological process business unit (""%1"") does not match the stage business unit (""%2"").';
							|it = 'Il reparto del processo tecnologico (""%1"") non corrisponde al reparto della fase (""%2"").';
							|pl = 'Dział procesu technologicznego (""%1"") nie odpowiada działowi etapu (""%2"").';
							|tr = '(""%1"") teknolojik süreç departmanı, (""%2"") aşamasının departmanına karşılık gelmemektedir.'"),
						OperationSelection_.TechnicalProcessDivisionPresentation,
						SamplingStages.StageDivisionPresentation);
						
					Common.MessageToUser(MessageText, OperationSelection_.TechnologicalProcess,,, Cancel);
				
				EndIf;
				
				If OperationSelection_.ProcessStatus <> Enums.TechnologicalProcessStatuses.Valid Then
					
					MessageText = StrTemplate(
						NStr("vi = 'Quy trình kỹ thuật ""%1"" cần có trạng thái ""Có hiệu lực"".';
							|ru = 'Технологический процесс ""%1"" должен иметь статус ""Действует"".';
							|en = 'Technological process ""%1"" must be in ""Valid"" status.'; fa = 'Technological process ""%1"" must be in ""Valid"" status.';
							|it = 'Il processo tecnologico ""%1"" deve avere lo stato ""Attivo"".';
							|pl = 'Proces technologiczny ""%1"" powinien mieć status ""Obowiązuje"".';
							|tr = '""%1"" teknolojik süreci ""Aktif"" durumunda olmalıdır.'"),
						OperationSelection_.TechnicalProcessPresentation);
					
					Common.MessageToUser(MessageText, OperationSelection_.TechnologicalProcess,,, Cancel);
					
				EndIf;
				
			EndIf;
			
			ProductionProcessEditor.CheckFillingOfOperationWorkCenters(
				OperationObject, SamplingStages.StageDivision, OperationSelection_.Operation, Cancel);
			
			FillPropertyValues(TransactionTable.Add(), OperationSelection_);
			
		EndDo;
		
		If TransactionTable.Count() > 0
			And Not ProductionProcessEditor.SequenceOfListOfOperationsIsCorrect(TransactionTable, StructureOfChecks, SamplingStages.Stage) Then
			Cancel = True;
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckTransactionDetails(Cancel)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.BillOfMaterials = &BillOfMaterials
	|	AND NOT ManufacturingOperations.DeletionMark
	|";
	
	Query.SetParameter("BillOfMaterials", Ref);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	While Selection.Next() Do
		OperationObject = Selection.Ref.GetObject();
		OperationObject.AdditionalProperties.Insert("SpecificationStatus_", Status);
		If Not OperationObject.CheckFilling() Then
			Cancel = True;
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckCompletionOfInterimIssueInStatusValid(Cancel) Export
	
	If RecordMethodOfMaterialTransferBetweenStagesLots =
			Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts Then
		
		Query = New Query(
			"SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.ProductionStages AS ProductionStages
			|WHERE
			|	ProductionStages.Owner = &BillOfMaterials
			|	AND NOT ProductionStages.DeletionMark
			|
			|GROUP BY
			|	ProductionStages.StageNumber
			|
			|HAVING
			|	COUNT(ProductionStages.Ref) > 1
			|
			|UNION ALL
			|
			|SELECT TOP 1
			|	TRUE
			|FROM
			|	Catalog.ProductionStages AS ProductionStages
			|WHERE
			|	ProductionStages.Owner = &BillOfMaterials
			|	AND NOT ProductionStages.DeletionMark
			|	AND ProductionStages.NextStageNo <> 0
			|
			|GROUP BY
			|	ProductionStages.NextStageNo
			|
			|HAVING
			|	COUNT(ProductionStages.Ref) > 1");
		Query.SetParameter("BillOfMaterials", Ref);
		
		If Not Query.Execute().IsEmpty() Then
			MessageText = NStr("vi = 'Với phương án xuất xưởng trung gian ""Sản phẩm với chất lượng Dùng được hạn chế"", quy trình sản xuất cần phải hợp nhất (hội tụ) lại.';
								|ru = 'При варианте промежуточного выпуска ""Продукция с качеством Ограниченно годен"" производственный процесс не должен быть расходимым (сходимым).';
								|en = 'If you use the ""Manufactured products with limited quality"" intermediate release option, the production process cannot be divergent (convergent).'; fa = 'If you use the ""Manufactured products with limited quality"" intermediate release option, the production process cannot be divergent (convergent).';
								|it = 'При варианте промежуточного выпуска ""Продукция с качеством Ограниченно годен"" производственный процесс не должен быть расходимым (сходимым).';
								|pl = 'If you use the ""Manufactured products with limited quality"" intermediate release option, the production process cannot be divergent (convergent).';
								|tr = '""Sınırlı geçerli kaliteye sahip imal edilen ürünlerin"" ara ürün çıkışı seçeneğinde, üretim süreci ıraksak (yakınsak) olmamalıdır.'");
			Common.MessageToUser(MessageText, ThisObject, "RecordMethodOfMaterialTransferBetweenStagesLots",, Cancel);
		EndIf;
		
	ElsIf RecordMethodOfMaterialTransferBetweenStagesLots =
			Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually
		And IntermediateRelease.Count() <> 0 Then
		
		TSName = "IntermediateRelease";
		PresentationOfTS = PresentationOfTableInForm(TSName);
		
		LineNumbers = New Map;
		UseGoodsQuality = GetFunctionalOption("UseGoodsQuality");
		
		Query = New Query(
			"SELECT
			|	Products.Ref AS Ref,
			|	Products.UseVariants AS UseVariants
			|FROM
			|	Catalog.Products AS Products
			|WHERE
			|	Products.Ref IN (&Products)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT
			|	ProductionStages.Ref AS Ref
			|FROM
			|	Catalog.ProductionStages AS ProductionStages
			|WHERE
			|	ProductionStages.Ref IN (&Stages)
			|	AND ProductionStages.NextStageNo = 0");
		Query.SetParameter("Products", IntermediateRelease.UnloadColumn("Products"));
		Query.SetParameter("Stages", IntermediateRelease.UnloadColumn("StageSender"));
		
		QueryResults = Query.ExecuteBatch();
		
		UseVariants = New Map;
		Selection = QueryResults[0].Select();
		While Selection.Next() Do
			UseVariants.Insert(Selection.Ref, Selection.UseVariants);
		EndDo;
		
		LastStagesWithRelease = QueryResults[1].Unload().UnloadColumn("Ref");
		
		For IndexOf = 0 To IntermediateRelease.Count() - 1 Do
			String = IntermediateRelease[IndexOf];
			If String.StageSender.IsEmpty() Then
				SenderSLineNumber = String.LineNumber;
			ElsIf LineNumbers[String.StageSender] = Undefined Then
				SenderSLineNumber = 1;
				LineNumbers.Insert(String.StageSender, 1);
			Else
				SenderSLineNumber = LineNumbers[String.StageSender] + 1 ;
				LineNumbers[String.StageSender] = SenderSLineNumber;
			EndIf;
			
			If String.StageSender.IsEmpty() Then
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Người gửi';
												|ru = 'Отправитель';
												|en = 'Sender'; fa = 'فرستنده';
												|it = 'Отправитель';
												|pl = 'Sender';
												|tr = 'Gönderici'"), SenderSLineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "StageSender");
				Common.MessageToUser(
					MessageText, ThisObject, Field,, Cancel);
			ElsIf LastStagesWithRelease.Find(String.StageSender) <> Undefined Then
				MessageText = StrTemplate(
					NStr("vi = 'Xuất xưởng trung gian không thể có công đoạn cuối (dòng %1 của danh sách %2).';
						|ru = 'Промежуточный выпуск не может быть на последнем этапе (строка %1 списка %2).';
						|en = 'The intermediate release cannot be in the last step (line %1 of the %2 list).'; fa = 'The intermediate release cannot be in the last step (line %1 of the %2 list).';
						|it = 'Промежуточный выпуск не может быть на последнем этапе (строка %1 списка %2).';
						|pl = 'The intermediate release cannot be in the last step (line %1 of the %2 list).';
						|tr = 'Ara ürün çıkışı (%2 listesinin %1 satırı) dahilinde son aşamada olamaz.'"),
					SenderSLineNumber,
					PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "RecipientStage");
				Common.MessageToUser(
					MessageText, String.StageSender, Field,, Cancel);
			EndIf;
			
			If String.RecipientStage.IsEmpty() Then
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Người nhận';
												|ru = 'Получатель';
												|en = 'Recipient'; fa = 'گیرنده';
												|it = 'Получатель';
												|pl = 'Recipient';
												|tr = 'Alıcı'"), SenderSLineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "RecipientStage");
				Common.MessageToUser(
					MessageText, ?(String.StageSender.IsEmpty(), ThisObject, String.StageSender),Field,, Cancel);
			EndIf;
			
			If String.Products.IsEmpty()
				And Not UseGoodsQuality Then
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Mặt hàng';
												|ru = 'Номенклатура';
												|en = 'Item'; fa = 'قلم';
												|it = 'Номенклатура';
												|pl = 'Pozycja';
												|tr = 'Öğe'"), SenderSLineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "Products");
				Common.MessageToUser(
					MessageText, ?(String.StageSender.IsEmpty(), ThisObject, String.StageSender),Field,, Cancel);
			EndIf;
			
			If Not String.Products.IsEmpty()
				And String.Characteristic.IsEmpty()
				And (UseVariants[String.Products] = Enums.ItemVariantsUsageOptions.SpecialForItems
					Or UseVariants[String.Products] = Enums.ItemVariantsUsageOptions.CommonForItemKind
					Or UseVariants[String.Products] = Enums.ItemVariantsUsageOptions.CommonWithOtherItemKind) Then
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Đặc tính';
												|ru = 'Характеристика';
												|en = 'Variant'; fa = 'گونه';
												|it = 'Характеристика';
												|pl = 'Charakterystyka';
												|tr = 'Varyant'"), SenderSLineNumber, PresentationOfTS);
				Field = CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "Characteristic");
				Common.MessageToUser(
					MessageText, ?(String.StageSender.IsEmpty(), ThisObject, String.StageSender),Field,, Cancel);
			EndIf;
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CheckCompletionOfWorkInProgressInStatusValid(Cancel, DataSource = Undefined) Export
	
	If Not ProductionProcessType = Enums.ProductionProcessTypes.PerformRM Then
		Return;
	EndIf;
	
	TemplateMessageAttributes     = NStr("vi = 'Chưa điền giá trị mục tin ""%1"" trong dòng %2 của công đoạn lập kế hoạch công việc';
										|ru = 'Не заполнено значение реквизита ""%1"" в строке %2 этапа планирования работ';
										|en = 'The ""%1"" attribute value in line %2 of the work planning stage is not filled in'; fa = 'The ""%1"" attribute value in line %2 of the work planning stage is not filled in';
										|it = 'The ""%1"" attribute value in line %2 of the work planning stage is not filled in';
										|pl = 'The ""%1"" attribute value in line %2 of the work planning stage is not filled in';
										|tr = 'İş planlama aşamasının   %2 . satırında yer alan ""%1""  niteliğinin değeri doldurulmamıştır.'");
	MessageTemplateMatching  = NStr("vi = 'Bảng kê chi tiết được chỉ định trong dòng %1 của công đoạn lập kế hoạch công việc, cần tương ứng với công việc đã chọn';
									|ru = 'Спецификация, указанная в строке %1 этапа планирования работ, должна соответствовать выбранной работе';
									|en = 'The bill of materials specified in line %1 of the work planning stage must correspond to the selected work.'; fa = 'The bill of materials specified in line %1 of the work planning stage must correspond to the selected work.';
									|it = 'The bill of materials specified in line %1 of the work planning stage must correspond to the selected work.';
									|pl = 'The bill of materials specified in line %1 of the work planning stage must correspond to the selected work.';
									|tr = 'İş planlama aşamasının %1. satırında belirtilen ürün reçetesi, seçilen işe uygun olmalıdır.'");
	MessageTemplateLooping = NStr("vi = 'Công việc lồng nhau được chỉ định trong dòng %1 của công đoạn lập kế hoạch công việc, không cần trùng với công việc đã được thực hiện chính theo bảng kê chi tiết';
									|ru = 'Вложенная работа, указанная в строке %1 этапа планирования работ, не должна совпадать с основной выполняемой работой по спецификации';
									|en = 'The nested work specified in line %1 of the work planning stage must not coincide with the main work performed in the bill of materials'; fa = 'The nested work specified in line %1 of the work planning stage must not coincide with the main work performed in the bill of materials';
									|it = 'The nested work specified in line %1 of the work planning stage must not coincide with the main work performed in the bill of materials';
									|pl = 'The nested work specified in line %1 of the work planning stage must not coincide with the main work performed in the bill of materials';
									|tr = 'İş planlama aşamasının %1. satırında belirtilen alt iş, ürün reçetesine göre yapılan ana işle çakışmamalıdır.'");
	StatusMessageTemplate        = NStr("vi = 'Chú ý! Bảng kê chi tiết ""%1"" được chỉ định trong dòng %2 của công đoạn lập kế hoạch công việc, không phải là bảng kê chi tiết đang có hiệu lực';
										|ru = 'Внимание! Спецификация ""%1"", указанная в строке %2 этапа планирования работ, не является действующей';
										|en = 'Important. The ""%1"" BOM specified in line %2 of the work planning stage is not valid'; fa = 'Important. The ""%1"" BOM specified in line %2 of the work planning stage is not valid';
										|it = 'Important. The ""%1"" BOM specified in line %2 of the work planning stage is not valid';
										|pl = 'Important. The ""%1"" BOM specified in line %2 of the work planning stage is not valid';
										|tr = 'Dikkat! İş planlama aşamasının %2 . satırında belirtilen ""%1"" numaralı ürün reçetesi geçerli değildir.'");
	
	QueryText = "
	|SELECT
	|	T.LineNumber                        AS LineNumber,
	|	T.Products                       AS Products,
	|	T.Characteristic                     AS Characteristic,
	|	T.UnderRepairProduct   AS UnderRepairProduct,
	|	T.UnderRepairVariant AS UnderRepairVariant,
	|	T.ProductCostElement                  AS ProductCostElement,
	|	T.BillOfMaterials                       AS BillOfMaterials,
	|	T.Stage                               AS Stage
	|INTO WorksToPerform
	|FROM
	|	&WorksToPerform AS T
	|
	|;
	|
	|SELECT
	|	T.LineNumber                        AS LineNumber,
	|	T.Products                       AS Products,
	|	T.Characteristic                     AS Characteristic
	|INTO ManufacturedProducts
	|FROM
	|	&ManufacturedProducts AS T
	|
	|;
	|
	|SELECT
	|	WorksToPerform.*,
	|	PRESENTATION(WorksToPerform.BillOfMaterials)                      AS BillOfMaterialsPresentation,
	|	WorksToPerform.BillOfMaterials.Status                              AS SpecificationStatus,
	|	CASE
	|		WHEN WorksToPerform.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                              AS ItemVariantsAreUsed,
	|	CASE
	|		WHEN WorksToPerform.UnderRepairProduct.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                              AS FinishedProductBeingRepairedCharacteristicsAreUsed,
	|	TRUE IN (SELECT TOP 1
	|				TRUE
	|			FROM
	|				Catalog.BillsOfMaterials.ManufacturedProducts AS T
	|			WHERE
	|				T.Ref = WorksToPerform.BillOfMaterials
	|				AND WorksToPerform.Products = T.Products)     AS BillOfMaterialsCorrespondsTo,
	|	TRUE IN (SELECT TOP 1
	|				TRUE
	|			FROM
	|				ManufacturedProducts AS T
	|			WHERE
	|				T.Products = WorksToPerform.Products
	|				AND T.Characteristic = WorksToPerform.Characteristic) AS WorkInvestedIsEqualToWorkPerformed
	|	
	|FROM 
	|	WorksToPerform AS WorksToPerform
	|
	|ORDER BY
	|	WorksToPerform.Stage,
	|	WorksToPerform.LineNumber
	|";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ManufacturedProducts", ManufacturedProducts);
	Query.SetParameter("WorksToPerform", ?(DataSource = Undefined, WorksToPerform, DataSource));
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do 
		
		If Not ValueIsFilled(Selection.Products) Then
		
			MessageText = StrTemplate(TemplateMessageAttributes, NStr("vi = 'Công việc';
																		|ru = 'Работа';
																		|en = 'Work'; fa = 'کار';
																		|it = 'Work';
																		|pl = 'Work';
																		|tr = 'İş'"), Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(Selection.Products)
			And Not ValueIsFilled(Selection.Characteristic)
			And Selection.ItemVariantsAreUsed Then
			
			MessageText = StrReplace(TemplateMessageAttributes, """%1""", NStr("vi = '""%1"" (đối với công việc)';
																				|ru = '""%1"" (для работы)';
																				|en = '""%1"" (for work)'; fa = '""%1"" (for work)';
																				|it = '""%1"" (for work)';
																				|pl = '""%1"" (for work)';
																				|tr = '""%1"" (iş için)'"));
			MessageText = StrTemplate(MessageText, NStr("vi = 'Đặc tính';
														|ru = 'Характеристика';
														|en = 'Variant'; fa = 'گونه';
														|it = 'Variant';
														|pl = 'Variant';
														|tr = 'Varyant'"), Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(Selection.UnderRepairProduct)
			And Not ValueIsFilled(Selection.UnderRepairVariant)
			And Selection.FinishedProductBeingRepairedCharacteristicsAreUsed Then
			
			MessageText = StrReplace(TemplateMessageAttributes, """%1""", NStr("vi = '""%1"" (đối với bộ phận)';
																				|ru = '""%1"" (для узла)';
																				|en = '""%1"" (for node)'; fa = '""%1"" (for node)';
																				|it = '""%1"" (for node)';
																				|pl = '""%1"" (for node)';
																				|tr = '""%1"" (alt varlık için)'"));
			MessageText = StrTemplate(MessageText, NStr("vi = 'Đặc tính';
														|ru = 'Характеристика';
														|en = 'Variant'; fa = 'گونه';
														|it = 'Variant';
														|pl = 'Variant';
														|tr = 'Varyant'"), Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If Selection.WorkInvestedIsEqualToWorkPerformed Then
			
			MessageText = StrTemplate(MessageTemplateLooping, Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If Not ValueIsFilled(Selection.ProductCostElement) Then
		
			MessageText = StrTemplate(TemplateMessageAttributes, NStr("vi = 'Dạng tính giá thành';
																		|ru = 'Статья калькуляции';
																		|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																		|it = 'Voce di calcolo';
																		|pl = 'Rodzaj kosztu';
																		|tr = 'Ürün maliyet kalemi'"), Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(Selection.BillOfMaterials)
			And Not Selection.BillOfMaterialsCorrespondsTo Then
			
			MessageText = StrTemplate(MessageTemplateMatching, Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage,,, Cancel);
			
		EndIf;
		
		If ValueIsFilled(Selection.BillOfMaterials)
			And Not Selection.SpecificationStatus = Enums.BOMStatuses.Valid Then
			
			MessageText = StrTemplate(StatusMessageTemplate, Selection.BillOfMaterialsPresentation, Selection.LineNumber);
			Common.MessageToUser(MessageText, Selection.Stage);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckReverseKittingInStatusValid(Cancel, ArrayOfStages = Undefined) Export
	
	If Not (ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
			And GetFunctionalOption("DynamicStructureOfProductionOrders")) Then
		Return;
	EndIf;
	
	If ArrayOfStages = Undefined Then
		
		QueryText = "
		|SELECT
		|	TRUE
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|WHERE
		|	ProductionStages.Owner = &Owner
		|	AND NOT ProductionStages.DeletionMark
		|HAVING
		|	COUNT(*) > 1";
		
		Query = New Query;
		Query.Text = QueryText;
		Query.SetParameter("Owner", Ref);
		
		HasErrors = Not Query.Execute().IsEmpty();
		
	Else
		
		HasErrors = ArrayOfStages.Count() > 1;
		
	EndIf;
	
	If HasErrors Then
		
		MessageText = NStr("vi = 'Không hỗ trợ bảng kê chi tiết phân rã theo nhiều công đoạn.';
							|ru = 'Не поддерживаются многоэтапные разборочные спецификации.';
							|en = 'Multi-stage disassembly BOMs are not supported.'; fa = 'Multi-stage disassembly BOMs are not supported.';
							|it = 'Multi-stage disassembly BOMs are not supported.';
							|pl = 'Multi-stage disassembly BOMs are not supported.';
							|tr = 'Çok aşamalı demontaj özellikleri desteklenmiyor.'");
		Common.MessageToUser(MessageText,,,,Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region AllStatuses

Procedure CheckFillingOfIncomingItems(Cancel)
	
	If ProductionProcessType = Enums.ProductionProcessTypes.Repair
		Or ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		
		VerificationAttribute = ?(AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind,
			"MainProductProductKind",
			"MainProductProducts");
		
		ItemsType = Common.ObjectAttributeValue(ThisObject[VerificationAttribute], "ItemsType");
		
		If ItemsType = Enums.ItemsTypes.Work_5 Then
			
			MessageText = StrTemplate(NStr("vi = 'Không được phép chỉ định công việc trong trường ""%1""';
											|ru = 'Не допускается указание работы в поле ""%1""';
											|en = 'It is not allowed to specify work in the ""%1"" field'; fa = 'It is not allowed to specify work in the ""%1"" field';
											|it = 'Non è permesso specificare il lavoro nel campo ""%1""';
											|pl = 'Wskazywanie pracy w polu ""%1"" jest niedozwolone';
											|tr = '""%1"" alanında işin belirtilmesine izin verilmemektedir'"), VerificationAttribute);
			
			Common.MessageToUser(
				MessageText,, VerificationAttribute,, Cancel);
			
		EndIf;
		
	EndIf;

EndProcedure

Procedure CheckContentFilling(Cancel)
	
	PresentationOfTS = PresentationOfTableInForm("MaterialsAndServices");

	For Each String In MaterialsAndServices Do
		
		If ValueIsFilled(String.MethodOfReceivingMaterial) Then
			
			If ProductDataManagementClientServer.SemiFinishedProductProducedInProcess(String) And Not String.ProducedInProcess Then
				
				MessageText = CommonClientServer.FillingErrorText(
					"Column", "FillType", NStr("vi = 'Được sản xuất trong quá trình';
												|ru = 'Производится в процессе';
												|en = 'Produced in process'; fa = 'تولیدشده در فرایند';
												|it = 'Viene eseguito nel processo';
												|pl = 'Jest wytwarzane w procesie';
												|tr = 'Süreçte üretilen'"), String.LineNumber, PresentationOfTS);
					
				Field = CommonClientServer.PathToTabularSection(
					"MaterialsAndServices", String.LineNumber, "ProducedInProcess");
				
				Common.MessageToUser(
					MessageText, ThisObject, Field,, Cancel);
				
			EndIf;
			
		Else
			
			MessageText = CommonClientServer.FillingErrorText(
				"Column", "FillType", NStr("vi = 'Phương pháp nhận nguyên liệu';
											|ru = 'Способ получения материала';
											|en = 'Method of receiving material'; fa = 'روش دریافت ماده';
											|it = 'Metodo di acquisizione del materiale';
											|pl = 'Sposób otrzymania materiału';
											|tr = 'Malzemenin elde edilme yöntemi'"), String.LineNumber, PresentationOfTS);
				
			Field = CommonClientServer.PathToTabularSection(
				"MaterialsAndServices", String.LineNumber, "MethodOfReceivingMaterial");
			
			Common.MessageToUser(
				MessageText, ThisObject, Field,, Cancel);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckStageSelection(TableName, StageProps, Cancel)
	
	Query = New Query("
	|SELECT
	|	TRUE
	|FROM
	|	Catalog.ProductionStages AS T
	|WHERE
	|	T.Ref = &Ref
	|	AND T.DeletionMark");
	
	PresentationOfTS = PresentationOfTableInForm(TableName);
	MessageTemplate = NStr("vi = 'Không được phép chọn các công đoạn được đánh dấu để xóa (danh sách ""%1"", dòng %2).';
							|ru = 'Не допускается выбор этапов помеченных на удаление (список ""%1"", строка %2).';
							|en = 'Cannot select stages marked for deletion (list ""%1"", line %2).'; fa = 'Cannot select stages marked for deletion (list ""%1"", line %2).';
							|it = 'La selezione delle fasi contrassegnate per la cancellazione non è consentita (lista ""%1"", riga %2).';
							|pl = 'Wybór etapów zaznaczonych do usunięcia jest niedozwolony (lista ""%1"", wiersz %2).';
							|tr = 'Silinmek üzere işaretlenen aşamaların seçilmesine izin verilmemektedir (""%1"" listesi, %2 satırı).'");
	For Each TableRow In ThisObject[TableName] Do
		
		If TableRow[StageProps].IsEmpty() Then
			Continue;
		EndIf;
		
		Query.SetParameter("Ref", TableRow[StageProps]);
		If Query.Execute().IsEmpty() Then
			Continue;
		EndIf;
		
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, PresentationOfTS, Format(TableRow.LineNumber, "NG="));
		Field = CommonClientServer.PathToTabularSection(TableName, TableRow.LineNumber, StageProps);
		Common.MessageToUser(MessageText, ThisObject, Field,, Cancel);
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function UploadMaterialsAndServices()
	
	Result = MaterialsAndServices.Unload(, 
		"LineNumber, 
		|Products, 
		|Characteristic,
		|StageEditing, 
		|ProducedInProcess,
		|SourceOfSemiFinishedProduct");
	
	Result.Indexes.Add("StageEditing");
	Result.Indexes.Add("StageEditing, Products");
	Result.Indexes.Add("StageEditing, Products, Characteristic");
	
	Return Result;
	
EndFunction

Function UnloadOutputProducts()
	
	Result = ManufacturedProducts.Unload(, 
		"LineNumber, 
		|Products, 
		|Characteristic,
		|StageEditing");
	
	Result.Indexes.Add("StageEditing");
	
	Return Result;
	
EndFunction

Function UnloadReturnableWaste()
	
	Result = RecyclableWaste.Unload(, 
		"LineNumber, 
		|Products, 
		|Characteristic,
		|StageEditing");
	
	Result.Indexes.Add("StageEditing");
	
	Return Result;
	
EndFunction

Function UploadInterimRelease()
	
	Result = IntermediateRelease.Unload(, 
		"StageSender, 
		|RecipientStage");
	
	Result.Indexes.Add("StageSender");
	Result.Indexes.Add("RecipientStage");
	
	Return Result;
	
EndFunction

Procedure CheckProductionStepsOnSide(Cancel) Export
	
	If Not GetFunctionalOption("UseProductionByThirdParty2_5")
		And True Then
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Catalog.ProductionStages AS Table
	|WHERE
	|	Table.Owner = &Owner
	|	AND Table.ProductionByThirdParty
	|	AND NOT Table.DeletionMark");
	Query.SetParameter("Owner", Ref);
	
	If Query.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	// Production on the side is only available for the "Manufacture, Assembly" type of production process
	If ProductionProcessType <> Enums.ProductionProcessTypes.Assembly Then
		MessageText = StrTemplate(NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất ""%1"" không cho phép sử dụng các bước được thực hiện bởi bên nhận gia công';
										|ru = 'В спецификации типа ""%1"" не допускается использовать этапы, выполняемые переработчиком';
										|en = 'Cannot use the stages performed by the subcontractor in BOM of the %1 type'; fa = 'Cannot use the stages performed by the subcontractor in BOM of the %1 type';
										|it = 'Le specifiche del tipo ""%1"" non sono autorizzate a utilizzare le fasi eseguite dal subfornitore';
										|pl = 'W specyfikacji typu ""%1"" nie można używać etapów, wykonywanych przez przetwórcę';
										|tr = '""%1"" türündeki ürün reçetesinde, fason üretici tarafından gerçekleştirilen aşamaların kullanılmasına izin verilmemektedir'"), ProductionProcessType);
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		Return;
	EndIf;
	
	// In the SPACECRAFT, it is not allowed to use the stages performed by the processor in a multi-stage specification
	If MultiStageProductionProcess And GetFunctionalOption("ComplexAutomation") Then
		MessageText = NStr("vi = 'Trong bảng kê chi tiết các nguồn lực sản xuất nhiều công đoạn, không được phép sử dụng các công đoạn được thực hiện bởi bên nhận gia công';
							|ru = 'В многоэтапной спецификации не допускается использовать этапы, выполняемые переработчиком';
							|en = 'Cannot use stages executed by the subcontractor in multi-stage BOM'; fa = 'Cannot use stages executed by the subcontractor in multi-stage BOM';
							|it = 'In una specifica multifase, non è consentito utilizzare le fasi eseguite dal subfornitore';
							|pl = 'W specyfikacji wieloetapowej nie można używać etapów, wykonywanych przez przetwórcę';
							|tr = 'Çok aşamalı ürün reçetesinde, fason üretici tarafından gerçekleştirilen aşamaların kullanılmasına izin verilmemektedir'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	MaterialsAndServices.LineNumber                                                   AS LineNumber,
	|	CAST(MaterialsAndServices.Products AS Catalog.Products)            AS Products,
	|	CAST(MaterialsAndServices.StageEditing AS Catalog.ProductionStages) AS StageEditing,
	|	MaterialsAndServices.ProducedInProcess                                         AS ProducedInProcess,
	|	CASE
	|		WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                                          AS ProducedOnStage,
	|	CASE
	|		WHEN MaterialsAndServices.SourceOfSemiFinishedProduct REFS Catalog.ProductionStages
	|			THEN FALSE
	|		ELSE TRUE
	|	END                                                                          AS ManufacturedByBOM
	|INTO TTTable
	|FROM
	|	&MaterialsAndServices AS MaterialsAndServices
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	StageList.Ref                AS Ref,
	|	StageList.ProductionByThirdParty AS ProductionByThirdParty
	|INTO TTListOfStages
	|FROM
	|	Catalog.ProductionStages AS StageList
	|WHERE
	|	StageList.Owner = &BillOfMaterials
	|	AND NOT StageList.DeletionMark
	|	
	|UNION ALL
	|
	|SELECT
	|	VALUE(Catalog.ProductionStages.EmptyRef),
	|	MAX(StageList.ProductionByThirdParty)
	|FROM
	|	Catalog.ProductionStages AS StageList
	|WHERE
	|	StageList.Owner = &BillOfMaterials
	|	AND StageList.StageNumber = 1
	|	AND NOT StageList.DeletionMark
	|
	|INDEX BY
	|	StageList.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialsAndServices.LineNumber                       AS LineNumber,
	|	MaterialsAndServices.Products                      AS Products,
	|	ISNULL(StageList.ProductionByThirdParty, FALSE) AS ProductionByThirdParty,
	|	MaterialsAndServices.ProducedInProcess             AS ProducedInProcess,
	|	MaterialsAndServices.ProducedOnStage               AS ProducedOnStage,
	|	MaterialsAndServices.ManufacturedByBOM        AS ManufacturedByBOM
	|INTO TTMaterialsAndServices
	|FROM
	|	TTTable AS MaterialsAndServices
	|		LEFT JOIN TTListOfStages AS StageList
	|		ON MaterialsAndServices.StageEditing = StageList.Ref
	|;
	|
	|SELECT
	|	Table.Ref               AS Stage,
	|	Table.Description         AS StageName,
	|	Table.StageNumber           AS StageNumber,
	|	Table.NextStageNo AS NextStageNo
	|FROM
	|	Catalog.ProductionStages AS Table
	|WHERE 
	|	Table.Owner = &BillOfMaterials
	|		AND Table.ProductionByThirdParty
	|		AND NOT Table.DeletionMark
	|
	|ORDER BY
	|	StageNumber
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS LineNumber
	|WHERE
	|	FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	0 AS LineNumber
	|WHERE
	|	FALSE
	|");
	Query.SetParameter("BillOfMaterials", Ref);
	
	SubsystemSettingsProduction = ProductionServerCached.SubsystemSettingsProduction();
	Query.SetParameter("ProductionIsUsed22", SubsystemSettingsProduction.ProductionIsUsed22);
	
	
	OutputProductTable  = UnloadOutputProducts();
	TableReturnableWaste = UnloadReturnableWaste();
	TableMaterialsAndServices = UploadMaterialsAndServices();
	TableIntermediateRelease = UploadInterimRelease();
	Query.SetParameter("MaterialsAndServices", TableMaterialsAndServices);
	
	Result = Query.ExecuteBatch();
	NumberOfPackages_ = Result.Count();
	
	// For the stages performed on the side, the materials and output products must be described
	If Not Result[NumberOfPackages_ - 3].IsEmpty() Then
		
		ProductRepeatTextTemplate = NStr("vi = 'Mặt hàng ""%1"" không thể xuất hiện đồng thời trong các sản phẩm và trong vật liệu (dịch vụ).';
										|ru = 'Номенклатура ""%1"" не может присутствовать одновременно в продукции и в материалах (услугах).';
										|en = 'The ""%1"" products cannot be both in products and materials (services).'; fa = 'The ""%1"" products cannot be both in products and materials (services).';
										|it = 'L''articolo ""%1"" non può essere contemporaneamente sia in produzione che nei materiali (servizi).';
										|pl = 'Towar ""%1"" nie może znajdować się jednocześnie w produkcji i materiałach (usługach).';
										|tr = '""%1"" öğesi, imal edilen ürünlerde ve malzemelerde (hizmetlerde) aynı anda bulunamaz.'");
		TemplateTextRepeatSideIssue = NStr("vi = 'Mặt hàng ""%1"" không thể xuất hiện đồng thời trong một vấn đề phụ và trong chứng từ (dịch vụ).';
											|ru = 'Номенклатура ""%1"" не может присутствовать одновременно в побочном выпуске и в материалах (услугах).';
											|en = 'The ""%1"" products cannot be both in side release and materials (services).'; fa = 'The ""%1"" products cannot be both in side release and materials (services).';
											|it = 'L''articolo ""%1"" non può essere presente contemporaneamente sia nel rilascio secondario che nei materiali (servizi).';
											|pl = 'Towar ""%1"" nie może znajdować się jednocześnie w produkcji ubocznej i w materiałach (usługach).';
											|tr = '""%1"" öğesi, yan ürün çıkışında ve malzemelerde (hizmetlerde) aynı anda bulunamaz.'");
		
		If MultiStageProductionProcess Then
			FilterParameters = New Structure;
			FilterParameters.Insert("StageEditing");
			
			SenderSelectionParameters = New Structure;
			SenderSelectionParameters.Insert("StageSender");
			
			SelectionParametersRecipient = New Structure;
			SelectionParametersRecipient.Insert("RecipientStage");
			
			SelectionParametersForEmptyStage = New Structure;
			SelectionParametersForEmptyStage.Insert("StageEditing", Catalogs.ProductionStages.EmptyRef());
			
			TextTemplateNoLinesInTablePart = NStr("vi = 'Đối với công đoạn %1 được thực hiện bởi bên nhận gia công, không có một dòng nào được nhập vào danh sách ""%2""';
													|ru = 'Для этапа %1, выполняемого переработчиком, не введено ни одной строки в список ""%2""';
													|en = 'No lines are entered into the ""%2"" list for stage %1 performed by data subcontractor'; fa = 'No lines are entered into the ""%2"" list for stage %1 performed by data subcontractor';
													|it = 'Per la fase %1, svolta dal processore, non è stata immessa nemmeno una riga nell''elenco ""%2""';
													|pl = 'Dla etapu %1 wykonywanego przez przetwórcę nie wprowadzono żadnego wiersza na liście ""%2""';
													|tr = 'Fason üretici tarafından gerçekleştirilen %1 aşaması için ""%2"" listesine herhangi bir satır girilmedi'");
			
			Selection = Result[NumberOfPackages_ - 3].Select();
			
			While Selection.Next() Do
				
				FilterParameters.StageEditing = Selection.Stage;
				
				ArrayOfRowsOutputProducts = OutputProductTable.FindRows(FilterParameters);
				
				If Selection.NextStageNo = 0 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsOutputProducts,
						OutputProductTable.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				ArrayOfRowsReturnableWaste = TableReturnableWaste.FindRows(FilterParameters);
				
				If Selection.NextStageNo = 0 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsReturnableWaste,
						TableReturnableWaste.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				// In the stage, there must be at least one output product on the side
				// * in the old concept - at the calculated cost
				// * in the new concept: 
				// ** in the last stage - at the calculated cost
				// ** in other stages - at a fixed cost
				If SubsystemSettingsProduction.ProductionIsUsed22 Then
					
					ThereIsIntermediateRelease = False;
					If RecordMethodOfMaterialTransferBetweenStagesLots =
							Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts Then
						ThereIsIntermediateRelease = True;
					ElsIf RecordMethodOfMaterialTransferBetweenStagesLots =
							Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
						SenderSelectionParameters.StageSender = Selection.Stage;
						ArrayOfLinesIntermediateRelease = TableIntermediateRelease.FindRows(SenderSelectionParameters);
						ThereIsIntermediateRelease = ArrayOfLinesIntermediateRelease.UBound() <> -1;
					EndIf;
					
					// we check all stages except the last one, the last one will be checked by the platform
					If Selection.NextStageNo <> 0
						And ArrayOfRowsReturnableWaste.UBound() = -1 
						And Not ThereIsIntermediateRelease Then
						
						MessageText = StrTemplate(TextTemplateNoLinesInTablePart, Selection.StageName, PresentationOfTableInForm("RecyclableWaste"));
						
						Common.MessageToUser(
							MessageText, 
							ThisObject, 
							"RecyclableWaste",, 
							Cancel); 
						
					EndIf;
					
				Else
					
					If ArrayOfRowsOutputProducts.UBound() = -1 Then
						
						MessageText = StrTemplate(TextTemplateNoLinesInTablePart, Selection.StageName, PresentationOfTableInForm("ManufacturedProducts"));
						
						Common.MessageToUser(
							MessageText,
							ThisObject,
							"ManufacturedProducts",,
							Cancel);
						
					EndIf;
					
				EndIf;
				
				ArrayOfRowsMaterialsAndServices = TableMaterialsAndServices.FindRows(FilterParameters);
				
				If Selection.StageNumber = 1 Then
					
					CommonClientServer.SupplementArray(ArrayOfRowsMaterialsAndServices,
						TableMaterialsAndServices.FindRows(SelectionParametersForEmptyStage));
						
				EndIf;
				
				ThereIsIntermediateReleaseConsumption = False;
				If RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts Then
					ThereIsIntermediateReleaseConsumption = True;
				ElsIf RecordMethodOfMaterialTransferBetweenStagesLots =
						Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
					SelectionParametersRecipient.RecipientStage = Selection.Stage;
					ArrayOfLinesIntermediateRelease = TableIntermediateRelease.FindRows(SelectionParametersRecipient);
					ThereIsIntermediateReleaseConsumption = ArrayOfLinesIntermediateRelease.UBound() <> -1;
				EndIf;
					
				// At least one material must be described for the stage performed by the processor
				If ArrayOfRowsMaterialsAndServices.UBound() = -1
					And Not ThereIsIntermediateReleaseConsumption Then
					
					MessageText = StrTemplate(TextTemplateNoLinesInTablePart, Selection.StageName, PresentationOfTableInForm("MaterialsAndServices"));
					
					Common.MessageToUser(
						MessageText, 
						ThisObject, 
						"MaterialsAndServices",, 
						Cancel);
						
				EndIf;
				
				
			EndDo;
		Else
			
			
			// At least one material must be described for the stage performed by the processor
			If TableMaterialsAndServices.Count() = 0 Then
				
				TextTemplate1 = NStr("vi = 'Không có một dòng nào được nhập vào danh sách ""Vật liệu và Dịch vụ""';
									|ru = 'Не введено ни одной строки в список ""Материалы и услуги""';
									|en = 'No line is entered into the ""Materials and services"" list'; fa = 'No line is entered into the ""Materials and services"" list';
									|it = 'Non è stata immessa nemmeno una riga nell''elenco ""Materiali e servizi""';
									|pl = 'Nie wprowadzono żadnego wiersza do listy ""Materiały i usługi""';
									|tr = '""Malzemeler ve Hizmetler"" listesine herhangi bir satır girilmedi'");
				
				Common.MessageToUser(
					TextTemplate1, 
					ThisObject, 
					"MaterialsAndServices",, 
					Cancel); 
					
			EndIf;
			
		EndIf;
		
	EndIf;
	
	// In the "Materials and Works" list, it is not allowed to specify works for the stages performed by the processor
	If Not Result[NumberOfPackages_ - 2].IsEmpty() Then
		
		TextTemplate1 = NStr("vi = 'Chỉ ra các công việc đối với công đoạn do người nhận gia công khi vô hiệu hóa kế toán theo phiên bản 2.4 (xem dòng %1 của danh sách ""Nguyên vật liệu và công việc"").';
							|ru = 'Указание работ для этапов, выполняемых переработчиком, допускается при отключенном учете по версии 2.4 (см. строку %1 списка ""Материалы и работы"").';
							|en = 'Work specification for the subcontractor stages is available if accounting of version 2.4 is disabled (see the %1 line of the ""Materials and works"" list).'; fa = 'Work specification for the subcontractor stages is available if accounting of version 2.4 is disabled (see the %1 line of the ""Materials and works"" list).';
							|it = 'L''indicazione dei lavori per le fasi eseguibili da parte dell''elaboratore è permessa con la contabilità disattivata nella versione 2.4 (vedi riga %1 dell''elenco ""Materiali e lavori"").';
							|pl = 'Określenie prac dla etapów, wykonywanych przez przetwórcę, jest dopuszczalne przy wyłączonej ewidencji według wersji 2.4 (patrz wiersz %1 listy ""Materiały i prace"").';
							|tr = 'Fason üretici tarafından gerçekleştirilen aşamalara yönelik işlerin belirtilmesine, sürüm 2.4 üzerinden hesap devre dışı bırakıldığında izin verilmektedir (bk. ""Malzemeler ve İşler"" listesinin %1 satırı).'");
		
		Selection = Result[NumberOfPackages_ - 2].Select();
			
		While Selection.Next() Do
			
			Field           = CommonClientServer.PathToTabularSection("MaterialsAndServices", Selection.LineNumber, "Products");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(TextTemplate1, Selection.LineNumber);
			
			Common.MessageToUser(
				MessageText, 
				ThisObject, 
				Field,, 
				Cancel);
			
		EndDo;
		
	EndIf;
	
	
EndProcedure

// Checks only additional details for non-interactive work with the specification.
// For the status of the specification "Valid", the check is performed in the general procedure for checking the production process.
// 
// Parameters:
//  Cancel - Boolean - Cancel
Procedure CheckAdditionalDetailsOfProductionProcess(Cancel)
	
	If InteractiveVerificationPassed()
			Or Status = Enums.BOMStatuses.Valid Then
		Return;
	EndIf;
	
	Messages = New Array(GetUserMessages(True));
	
	CheckBankDetails(Cancel);
	CheckTransactionDetails(Cancel);
	If Cancel Then
		RecordProductionProcessVerificationErrorsInLog();
		Message = New UserMessage;
		Message.Text = TextOfProductionProcessErrorMessage();
		Message.SetData(ThisObject);
		Messages.Add(Message);
	EndIf;
	
	For Each Message In Messages Do
		Message.Message();
	EndDo;
	
EndProcedure

Function TextOfProductionProcessErrorMessage()
	
	Return NStr("vi = 'Quy trình sản xuất có lỗi. Hãy sử dụng kiểm tra và nhập chỉnh sửa cần thiết trong biểu mẫu bảng kê chi tiết.';
				|ru = 'Производственный процесс содержит ошибки. Воспользуйтесь проверкой и внесите необходимые исправления в форме спецификации.';
				|en = 'The production process contains errors. Use the check and make any necessary corrections in the bill of materials form.'; fa = 'The production process contains errors. Use the check and make any necessary corrections in the bill of materials form.';
				|it = 'Il processo di produzione contiene errori. Utilizzare la verifica per apportare le correzioni necessarie nel modulo della specifica.';
				|pl = 'Proces produkcyjny zawiera błędy. Skorzystaj z weryfikacji i wprowadź konieczne korekty w formularz specyfikacji.';
				|tr = 'Üretim süreci hatalar içermektedir. Doğrulamayı kullanın ve ürün reçetesi formunda gerekli düzeltmeleri yapın.'")
	
EndFunction

Procedure RecordProductionProcessVerificationErrorsInLog()
	
	EventName = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất.';
					|ru = 'Ресурсная спецификация.';
					|en = 'Bill of materials.'; fa = 'Bill of materials.';
					|it = 'Specifica di risorse.';
					|pl = 'Specyfikacja.';
					|tr = 'Ürün reçetesi.'", Common.DefaultLanguageCode());
	MessageTemplate = NStr("vi = '%1 %2';
							|ru = '%1 %2';
							|en = '%1 %2'; fa = '%1 %2';
							|it = '%1 %2';
							|pl = '%1 %2';
							|tr = '%1 %2'");
	
	Messages = GetUserMessages(True);
	For Each Message In Messages Do
		MessageText = StrTemplate(
			MessageTemplate,
			Message.Text,
			?(ValueIsFilled(Message.DataKey), "("+Message.DataKey+")" ,""));
		WriteLogEvent(EventName, EventLogLevel.Warning,, Ref, MessageText);
	EndDo;
	
EndProcedure

Procedure InstallInteractiveVerificationPassed() Export
	
	AdditionalProperties.Insert("InteractiveVerificationPassed");
	
EndProcedure

Function InteractiveVerificationPassed() Export
	
	Return AdditionalProperties.Property("InteractiveVerificationPassed"); // Boolean
	
EndFunction

#EndRegion

#EndRegion

#Region Other

Procedure CheckAdjustProductionSteps(Cancel)
	
	If InteractiveVerificationPassed()
			And Not ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	Stages.Ref,
	|	Stages.StageNumber,
	|	Stages.NextStageNo,
	|	Stages.QuantityOfProductUnitsLotsProducedSimultaneously AS SimultaneouslyManufacturedQuantity
	|FROM
	|	Catalog.ProductionStages AS Stages
	|WHERE
	|	Stages.Owner = &BillOfMaterials
	|	AND NOT Stages.DeletionMark
	|
	|ORDER BY
	|	Stages.StageNumber");
	Query.SetParameter("BillOfMaterials", Ref);
	
	Selection = Query.Execute().Select();
	
	ValidStatus = (Status = Enums.BOMStatuses.Valid);
	MultiStageProductionProcess = Selection.Count() > 1 And Not ThisIsTechnologicalSet();
	
	While Selection.Next() Do
		
		Try
			
			If ThisIsTechnologicalSet() Then
				
				StageObject = Selection.Ref.GetObject();
				StageObject.AdditionalProperties.Insert("AllowRecording");
				StageObject.SetDeletionMark(True);
				
			Else
			
				RequiredRenumbering = Not MultiStageProductionProcess And (Selection.StageNumber <> 1 Or Selection.NextStageNo <> 0);
				
				If ValidStatus And Not ProductionIssueByCustomPortions
					And Selection.SimultaneouslyManufacturedQuantity <> Int(Selection.SimultaneouslyManufacturedQuantity) Then
					ItIsRequiredToRoundQuantity = True;
				Else
					ItIsRequiredToRoundQuantity = False;
				EndIf;
				
				If RequiredRenumbering Or ItIsRequiredToRoundQuantity Then
					
					StageObject = Selection.Ref.GetObject(); // CatalogObject.ProductionStages
					
					If RequiredRenumbering Then
						StageObject.StageNumber = 1;
						StageObject.NextStageNo = 0;
					EndIf;
					
					If ItIsRequiredToRoundQuantity Then
						StageObject.QuantityOfProductUnitsLotsProducedSimultaneously = Round(StageObject.QuantityOfProductUnitsLotsProducedSimultaneously);
					EndIf;
					
					StageObject.Write();
					
				EndIf;
			
			EndIf;
			
		Except
			
			EventName = NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất';
							|ru = 'Ресурсная спецификация';
							|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
							|it = 'Specifica di risorse';
							|pl = 'Specyfikacja zasobów';
							|tr = 'Ürün reçetesi'", Common.DefaultLanguageCode());
			TextPattern = NStr("vi = 'Không thể điều chỉnh các bước bảng kê chi tiết các nguồn lực sản xuất tài nguyên %1';
								|ru = 'Не удалось скорректировать этапы ресурсной спецификации %1';
								|en = 'Cannot correct the bill of materials stages %1'; fa = 'Cannot correct the bill of materials stages %1';
								|it = 'Non è stato possibile correggere le fasi delle specifiche delle risorse %1';
								|pl = 'Nie udało się skorygować etapów specyfikacji zasobów %1';
								|tr = 'Ürün reçetesinin aşamalarının düzeltilememesi %1'");
			
			MessageText = StrTemplate(TextPattern, NStr("vi = '(để biết thêm chi tiết, xem nhật ký)';
														|ru = '(подробнее см. в журнале регистрации)';
														|en = '(for more details, see the event log)'; fa = '(for more details, see the event log)';
														|it = '(maggiori dettagli nel registro di registrazione)';
														|pl = '(więcej zob. w dzienniku rejestracji)';
														|tr = '(daha fazla bilgi için olay günlüğüne bakın)'"));
			Common.MessageToUser(MessageText,,,, Cancel);
			
			MessageText = StrTemplate(TextPattern, NStr("vi = 'theo nguyên nhân:';
														|ru = 'по причине:';
														|en = 'Reason:'; fa = 'دلیل:';
														|it = 'a causa di:';
														|pl = 'z powodu:';
														|tr = 'nedeni:'") + " " + ErrorProcessing.DetailErrorDescription(ErrorInfo()));
			WriteLogEvent(
				EventName,
				EventLogLevel.Warning,
				,
				Ref,
				MessageText);
			
		EndTry;
		
	EndDo;
	
EndProcedure

Procedure RegisterDurationCalculationAccordingToSpecification() Export
	
	// When the specification status changes, we run a full recalculation of secondary data:
	// - we calculate the entire queue of tasks, 
	// - we calculate the number of days until the end.
	
	If Status = Enums.BOMStatuses.UnderDevelopment
			Or ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	CASE
	|		WHEN BillsOfMaterials.Status = VALUE(Enum.BOMStatuses.UnderDevelopment)
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS CompleteRecalculation
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	( BillsOfMaterials.Status = VALUE(Enum.BOMStatuses.UnderDevelopment)
	|		OR NOT (&EconomicReleaseLot <> 0
	|				OR &MinimumReleaseLot <> 0
	|				OR &ContainsResourcesParametrization
	|				OR &ContainsNestedBOMs
	|				OR &ContainsProbabilityCalculation
	|				OR &ProductionIssueByCustomPortions = FALSE
	|				OR &AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ItemList)
	|				OR &ContainsAliquotStandardsOfWorkCenterTypes) <> (NOT (BillsOfMaterials.EconomicReleaseLot <> 0
	|														OR BillsOfMaterials.MinimumReleaseLot <> 0
	|														OR BillsOfMaterials.ContainsResourcesParametrization
	|														OR BillsOfMaterials.ContainsNestedBOMs
	|														OR BillsOfMaterials.ContainsProbabilityCalculation
	|														OR BillsOfMaterials.ProductionIssueByCustomPortions = FALSE
	|														OR BillsOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ItemList)
	|														OR BillsOfMaterials.ContainsAliquotStandardsOfWorkCenterTypes))
	|	)
	|	AND BillsOfMaterials.Ref = &Ref
	|");
	Query.SetParameter("Ref", Ref);
	
	Query.SetParameter("EconomicReleaseLot",    EconomicReleaseLot);
	Query.SetParameter("MinimumReleaseLot",    MinimumReleaseLot);
	Query.SetParameter("ContainsResourcesParametrization",  ContainsResourcesParametrization);
	Query.SetParameter("ContainsNestedBOMs",   ContainsNestedBOMs);
	Query.SetParameter("ContainsProbabilityCalculation",       ContainsProbabilityCalculation);
	Query.SetParameter("ContainsAliquotStandardsOfWorkCenterTypes",   ContainsAliquotStandardsOfWorkCenterTypes);
	Query.SetParameter("ProductionIssueByCustomPortions", ProductionIssueByCustomPortions);
	Query.SetParameter("AssignmentOption",           AssignmentOption);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		Selection.Next();
		
		AdditionalProperties.Insert("CalculateProductionDuration", Selection.CompleteRecalculation);
		
	EndIf;
	
EndProcedure

Procedure CheckClearSelectionOfStagesInLine(TableRow)
	
	TableRow.Stage = Catalogs.ProductionStages.EmptyRef();
	TableRow.StageEditing = Catalogs.ProductionStages.EmptyRef();
	TableRow.Operation = Catalogs.ManufacturingOperations.EmptyRef();
	TableRow.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
EndProcedure

Procedure FillInServiceDetails()
	
	ProductDataManagement.CheckFillInDefaultAttributes(ThisObject);
	
	For Each TSName In StrSplit("ManufacturedProducts,RecyclableWaste,MaterialsAndServices", ",") Do
		For Each String In ThisObject[TSName] Do
			If String.MethodOfProductsAutoselection.IsEmpty() Then
				String.MethodOfProductsAutoselection = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
			EndIf;
			If String.MethodOfItemVariantAutoselection.IsEmpty() Then
				String.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
			EndIf;
		EndDo;
	EndDo;
	
	CheckFillInDetailsOfMainProduct();
	
	FillInServiceDetailsCached();
	
	If ContainsResourcesParametrization Then
		AllowSelectionForSideOutletProducts = False;
	EndIf;
	
EndProcedure

Procedure FillInServiceDetailsCached()
	
	If True
		And (AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.Products
			Or AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind)
		And ( Status = Enums.BOMStatuses.UnderDevelopment ) Then
		
		ThereIsSpecifiedMainProduct      = False;
		ContainsResourcesParametrization         = False;
		ContainsNestedBOMs          = False;
		ContainsProbabilityCalculation              = False;
		ContainsAliquotStandardsOfWorkCenterTypes          = False;
	Else
		
		ResultsByStages = New Structure("ContainsResourcesParametrization, ContainsAliquotStandardsOfWorkCenterTypes", False, False);
		Query = New Query(
		"SELECT
		|	CASE
		|		WHEN TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages.WorkCenterTypes AS Table
		|				WHERE
		|					Table.Ref.Owner = &BillOfMaterials
		|					AND NOT (CAST(Table.QuantityCalculationAlgorithm AS STRING(100))) = """"
		|					AND NOT Table.Ref.DeletionMark)
		|	
		|			OR TRUE IN
		|	
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages.AlternateWorkCenterTypes AS Table
		|				WHERE
		|					Table.Ref.Owner = &BillOfMaterials
		|					AND NOT (CAST(Table.QuantityCalculationAlgorithm AS STRING(100))) = """"
		|					AND NOT Table.Ref.DeletionMark)
		|
		|			OR TRUE IN
		|
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages.SelectionByProperties AS Table
		|				WHERE
		|					Table.Ref.Owner = &BillOfMaterials
		|					AND NOT Table.Ref.DeletionMark)
		|
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ContainsResourcesParametrization,
		|	CASE
		|		WHEN TRUE IN
		|				(SELECT TOP 1
		|					TRUE
		|				FROM
		|					Catalog.ProductionStages AS Table
		|				WHERE
		|					Table.Owner = &BillOfMaterials
		|					AND NOT Table.QuantityOfProductUnitsLotsProducedSimultaneously IN (0, 1)
		|					AND NOT Table.DeletionMark)
		|			THEN TRUE
		|		ELSE FALSE
		|	END AS ContainsAliquotStandardsOfWorkCenterTypes");
		Query.SetParameter("BillOfMaterials", Ref);
		
		SetPrivilegedMode(True);
		FillPropertyValues(ResultsByStages, Query.Execute().Unload()[0]);
		SetPrivilegedMode(False);
		// parameterization of the main product specification is used
		#Region ThereIsSpecifiedMainProduct
		
		ThereIsSpecifiedMainProduct = (AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind)
											Or (MainProductCharacteristic.IsEmpty()
													And Catalogs.Products.ItemVariantsAreUsed(MainProductProducts));
		
		#EndRegion
		
		// parameterization of specification resources is used
		#Region ContainsResourcesParametrization
		
		ContainsResourcesParametrization = False;
		If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
			
			ContainsResourcesParametrization = ResultsByStages.ContainsResourcesParametrization
				Or SelectionByProperties.Count();
			
			If Not ContainsResourcesParametrization Then
				
				For Each TSName In TabularSectionNames() Do
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
		
		#EndRegion
		
		// the production of semi-finished products in the process or sets is used
		#Region ContainsNestedBOMs
		
		ContainsNestedBOMs =
			MaterialsAndServices.Find(Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials, "MethodOfReceivingMaterial") <> Undefined;
		If Not ContainsNestedBOMs Then
			AttributesValues = Common.ObjectsAttributeValue(MaterialsAndServices.UnloadColumn("Products"), "ItemsType");
			For Each KeyAndValue In AttributesValues Do
				If KeyAndValue.Value = Enums.ItemsTypes.Set Then
					ContainsNestedBOMs = True;
					Break;
				EndIf;
			EndDo;
		EndIf;
		
		#EndRegion
		
		// the calculation of the probability of application is used
		#Region ContainsProbabilityCalculation
		
		ContainsProbabilityCalculation = False;
		For Each String In ManufacturedProducts Do
			If String.ShareOfNonconformity = 0 Then
				Continue;
			EndIf;
			ContainsProbabilityCalculation = True;
			Break;
		EndDo;
		If Not ContainsProbabilityCalculation Then
			For Each String In MaterialsAndServices Do
				If String.Probability = 0 Then
					Continue;
				EndIf;
				ContainsProbabilityCalculation = True;
				Break;
			EndDo;
		EndIf;
		
		#EndRegion
		
		// non-recurring release of products
		#Region ThereIsOneTimeIssue
		
		ThereIsOneTimeIssue = False;
		If Not AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ProductKind Then
			If (ProductionProcessType = Enums.ProductionProcessTypes.Repair
				Or ProductionProcessType = Enums.ProductionProcessTypes.Disassembly) Then
				Count = MainProductNumberOfPackages * Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(MainProductPackage, MainProductProducts);
				ThereIsOneTimeIssue = Not ( ProductionIssueByCustomPortions Or Count = 1 And ProductDataManagement.PieceProduct(MainProductProducts));
			Else
				ThereIsOneTimeIssue = ( ManufacturedProducts.Count() > 1 );
				If Not ThereIsOneTimeIssue Then
					For Each String In ManufacturedProducts Do
						Count = String.NumberOfPackages * Catalogs.PackagesAndUnitsOfMeasure.PackagingFactor(String.Package, String.Products);
						ThereIsOneTimeIssue = Not ( ProductionIssueByCustomPortions Or Count = 1 And ProductDataManagement.PieceProduct(MainProductProducts));
						Break;
					EndDo;
				EndIf;
			EndIf;
		EndIf;
		
		#EndRegion
		
		// non-multiple equipment loading standards
		#Region ContainsAliquotStandardsOfWorkCenterTypes
			ContainsAliquotStandardsOfWorkCenterTypes = ResultsByStages.ContainsAliquotStandardsOfWorkCenterTypes;
		#EndRegion
	EndIf;
	
EndProcedure

Procedure ClearUnusedData()
	
	UseBillOfMaterialsParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	
	ThisIsBuild = (ProductionProcessType = Enums.ProductionProcessTypes.Assembly);
	DestinationOptionListOfProducts = (AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList);
	
	If ThisIsBuild And Not DestinationOptionListOfProducts Then
		For IndexOf = -ManufacturedProducts.Count() + 1 To 0 Do
			If IndexOf = 0 Then
				ManufacturedProducts[IndexOf].ProductDescription = "";
			Else
				ProductDataManagementClientServer.ClearAutoSelectionSettingsByLine(
					ManufacturedProducts[-IndexOf], PropertyMapping);
				ProductDataManagementClientServer.ClearSelectionSettingsByPropertiesByRow(
					ManufacturedProducts[-IndexOf], SelectionByProperties);
				ManufacturedProducts.Delete(-IndexOf);
			EndIf;
		EndDo;
	EndIf;
	
	For Each TSName In StrSplit("ManufacturedProducts,RecyclableWaste,MaterialsAndServices,LaborCosts",",") Do
		For Each String In ThisObject[TSName] Do
			If Not IsBlankString(String.QuantityCalculationAlgorithm) And UseBillOfMaterialsParameterization Then
				If TSName = "LaborCosts" Then
					String.Count = 0;
				Else
					String.NumberOfPackages = 0;
				EndIf;
			EndIf;
			If TSName = "MaterialsAndServices" Then
				If String.MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
					String.PlanNotEarlierThan = Undefined;
				EndIf;
				If String.MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
					String.BillOfMaterialsRM = Undefined;
				EndIf;
			EndIf;
			If TSName = "ManufacturedProducts" Then
				If ThisIsBuild And Not DestinationOptionListOfProducts
					Or MethodOfAllocatingFinishedProductCosts <> Enums.MethodsOfCostAllocatingOnProductCosts.ByCostShares Then
					String.CostShare = 0;
				EndIf;
			EndIf;
			If DeletionMark Or ThisIsTechnologicalSet() Then
				CheckClearSelectionOfStagesInLine(String);
			EndIf;
		EndDo;
	EndDo;
	If ThisIsBuild And DestinationOptionListOfProducts Then
		ProductDataManagementClientServer.ClearSpecificationRefinementSettings(ThisObject);
	EndIf;
	If Not ProductDataManagement.AvailableProductionProcessParameters(ThisObject) Then
		MinimumReleaseLot = 0;
		EconomicReleaseLot = 0;
		PermissibleExcessOfOptimalReleaseLot = 0;
	EndIf;
	If ThisIsTechnologicalSet() Then
		WorksToPerform.Clear();
		RecordMethodOfMaterialTransferBetweenStagesLots = Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.NotUsed;
		For Each TSName In StrSplit("RecyclableWaste,LaborCosts",",") Do
			For IndexOf = 0 To ThisObject[TSName].Count() - 1 Do
				If TSName <> "LaborCosts" Then
					ProductDataManagementClientServer.ClearAutoSelectionSettingsByLine(
						ThisObject[TSName][IndexOf], PropertyMapping);
				EndIf;
				ProductDataManagementClientServer.ClearSelectionSettingsByPropertiesByRow(
					ThisObject[TSName][IndexOf], SelectionByProperties);
			EndDo;
			ThisObject[TSName].Clear();
		EndDo;
	EndIf;
	If RecordMethodOfMaterialTransferBetweenStagesLots
			<> Enums.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually Then
		IntermediateRelease.Clear();
	EndIf;
EndProcedure

Procedure SetAttributesForStagesOfOperations()
	
	If IsNew()
			Or ThisIsTechnologicalSet() Then
		Return;
	EndIf;
	
	StageEmptyLink = Catalogs.ProductionStages.EmptyRef();
	
	DisassemblyRepair = ProductionProcessType = Enums.ProductionProcessTypes.Disassembly
		Or ProductionProcessType = Enums.ProductionProcessTypes.Repair;
	
	FirstStage    = New Structure("Ref, Department");
	LastStage = New Structure("Ref, Department");
	If (DisassemblyRepair
			Or ManufacturedProducts.Find(StageEmptyLink, "StageEditing") <> Undefined
			Or RecyclableWaste.Find(StageEmptyLink, "StageEditing") <> Undefined
			Or MaterialsAndServices.Find(StageEmptyLink, "StageEditing") <> Undefined
			Or LaborCosts.Find(StageEmptyLink, "StageEditing") <> Undefined
		) Then
		Catalogs.BillsOfMaterials.GetFirstAndLastStage(Ref, FirstStage, LastStage, "Department", True);
	EndIf;
	EmptyLinkOperation = Catalogs.ManufacturingOperations.EmptyRef();
	
	FirstOperations    = New Map;
	RecentOperations = New Map;
	If (ManufacturedProducts.Find(EmptyLinkOperation, "OperationEdit") <> Undefined
			Or RecyclableWaste.Find(EmptyLinkOperation, "OperationEdit") <> Undefined
			Or MaterialsAndServices.Find(EmptyLinkOperation, "OperationEdit") <> Undefined
			Or LaborCosts.Find(EmptyLinkOperation, "OperationEdit") <> Undefined
			Or IntermediateRelease.Count() <> 0
		) Then
		Catalogs.BillsOfMaterials.GetFirstAndLastOperations(Ref, FirstOperations, RecentOperations);
	EndIf;
	// Updates the value of the stage props in table parts
	//  - . if the stage editing props is not empty, it substitutes the value from it
	//  - if the stage editing prop is empty, then
	//		1. for products substitutes the last stage
	//		2. for materials substitutes the first stage
	//
	For Each TSName In TabularSectionNames() Do
		
		For Each TSRow In ThisObject[TSName] Do
			
			If TSRow.StageEditing.IsEmpty() Then
				If TSName = "ManufacturedProducts" Or TSName = "RecyclableWaste" Then
					TSRow.Stage = LastStage.Ref;
				Else
					TSRow.Stage = FirstStage.Ref;
				EndIf;
			Else
				TSRow.Stage = TSRow.StageEditing;
			EndIf;
			If TSRow.OperationEdit.IsEmpty() Then
				If TSName = "ManufacturedProducts" Or TSName = "RecyclableWaste" Then
					TSRow.Operation = RecentOperations.Get(TSRow.Stage);
				Else
					TSRow.Operation = FirstOperations.Get(TSRow.Stage);
				EndIf;
			Else
				TSRow.Operation = TSRow.OperationEdit;
			EndIf;
		EndDo;
		
	EndDo;
	For Each String In IntermediateRelease Do
		String.SenderOperation = RecentOperations.Get(String.StageSender);
		String.OperationRecipient = FirstOperations.Get(String.RecipientStage);
	EndDo;
	If DisassemblyRepair Then
		MainProductStage = FirstStage.Ref;
	ElsIf ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			And ManufacturedProducts.Count() > 0 Then
		MainProductStage = ManufacturedProducts[0].Stage;
	EndIf;
	
EndProcedure

Procedure CheckAppearanceOfProductItem()
	
	StringsList = New Array;
	ItemList = New Array;
	
	For Each String In ManufacturedProducts Do
		If Not ValueIsFilled(String.ProductKind) And ValueIsFilled(String.Products) Then
			StringsList.Add(String);
			ItemList.Add(String.Products);
		EndIf; 
	EndDo;
	
	If (Not ValueIsFilled(MainProductProductKind) And ValueIsFilled(MainProductProducts))
		Or (Not ValueIsFilled(ItemKindOfProductUnderRM) And ValueIsFilled(UnderRepairProduct)) Then
		StringsList.Add(ThisObject);
		ItemList.Add(MainProductProducts);
		ItemList.Add(UnderRepairProduct);
	EndIf;
	
	If StringsList.Count() > 0 Then 
		AttributeValues = Common.ObjectsAttributeValue(ItemList, "ProductKind");
		For Each StringObject In StringsList Do
			If StringObject = ThisObject Then
				If ValueIsFilled(MainProductProducts) Then
					MainProductProductKind = AttributeValues[MainProductProducts];
				EndIf;
				If ValueIsFilled(UnderRepairProduct) Then
					ItemKindOfProductUnderRM = AttributeValues[UnderRepairProduct];
				EndIf;
			Else
				StringObject.ProductKind = AttributeValues[StringObject.Products];
			EndIf;
		EndDo;
	EndIf;
	
	StringsList = Undefined;
	
EndProcedure

Function CheckFillInDetailsOfMainProduct() Export
	
	ObjectModified = False;
	
	If ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Assembly")
		Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.Repair")
		Or ProductionProcessType = PredefinedValue("Enum.ProductionProcessTypes.PerformRM") Then
		
		AttributesList = "ProductKind,Products,Characteristic,Package,NumberOfPackages";
		StructureOfData = New Structure(AttributesList);
		
		If ManufacturedProducts.Count() > 0 Then
			FillPropertyValues(StructureOfData, ManufacturedProducts[0]);
		EndIf;
		
		For Each KeyAndValue In StructureOfData Do
			ObjectAttribute = "MainProduct"+KeyAndValue.Key;
			If ThisObject[ObjectAttribute] <> KeyAndValue.Value Then
				ThisObject[ObjectAttribute] = KeyAndValue.Value;
				ObjectModified = True;
			EndIf;
		EndDo;
		
	EndIf;
	
	Return ObjectModified;
	
EndFunction

Procedure UpdateSeriesReferenceIsRequired()

	RecordSet = InformationRegisters.ReferenceBatchSpecificationIsRequired.CreateRecordSet();
	RecordSet.Filter.BillOfMaterials.Set(Ref);
	
	TheStructureOfTheSearch = New Structure("BatchIndicationRequired", True);
	
	// ManufacturedProducts
	TableOfProducts = ManufacturedProducts.Unload(TheStructureOfTheSearch, "Products");
 	ItemList = TMCommonUse.DeleteDuplicateElementsFromArray(TableOfProducts.UnloadColumn("Products"));
	
	For Each StringProducts In ItemList Do
		If Not ValueIsFilled(StringProducts) Then
			Continue;
		EndIf;
		StrawNewEntry = RecordSet.Add();
		StrawNewEntry.BillOfMaterials = Ref;
		StrawNewEntry.Products = StringProducts;
		StrawNewEntry.BOMRowKind = Enums.TypesOfSpecificationLines.FinishedProduct;
	EndDo; 
	
	// MaterialsAndServices
	TableOfProducts = MaterialsAndServices.Unload(TheStructureOfTheSearch, "Products");
 	ItemList = TMCommonUse.DeleteDuplicateElementsFromArray(TableOfProducts.UnloadColumn("Products"));
	For Each StringProducts In ItemList Do
		If Not ValueIsFilled(StringProducts) Then
			Continue;
		EndIf;
		StrawNewEntry = RecordSet.Add();
		StrawNewEntry.BillOfMaterials = Ref;
		StrawNewEntry.Products = StringProducts;
		StrawNewEntry.BOMRowKind = Enums.TypesOfSpecificationLines.Material;
	EndDo; 
	
	RecordSet.Write();
	
EndProcedure

Function ReleasingStages()
	
	Query = New Query(
	"SELECT
	|	ProductionStages.Ref
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	Owner = &Ref AND NOT DeletionMark AND NextStageNo = 0");
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction

Function PresentationOfTableInForm(TSName) Export
	
	ListName = "";
	
	If TSName = "ManufacturedProducts"
		And ProductionProcessType = Enums.ProductionProcessTypes.Assembly Then
		
		ListName = NStr("vi = 'Sản phẩm';
						|ru = 'Продукция';
						|en = 'Manufactured products'; fa = 'محصولات تولیدی';
						|it = 'Prodotti';
						|pl = 'Wiersze pozycji';
						|tr = 'İmal edilen ürünler'");
		
	Else
		
		ListName = Metadata.Catalogs.BillsOfMaterials.TabularSections[TSName].Synonym;
		
	EndIf;
	
	Return ListName;
	
EndFunction

Procedure CheckFillingOfQuantityInTabLine(TSName, PresentationOfTS, String, Cancel)
	
	If Not IsBlankString(String.QuantityCalculationAlgorithm) And GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		Return;
	EndIf;
	
	If String.NumberOfPackages = 0 Then
		
		MessageText = CommonClientServer.FillingErrorText("Column", "FillType", NStr("vi = 'Số lượng';
																					|ru = 'Количество';
																					|en = 'Quantity'; fa = 'مقدار';
																					|it = 'Quantità';
																					|pl = 'Ilość';
																					|tr = 'Miktar'"),
			String.LineNumber, PresentationOfTS);
		
	Else
		Return;
	EndIf;
	
	Common.MessageToUser(MessageText,
		ThisObject,
		CommonClientServer.PathToTabularSection(TSName, String.LineNumber, "NumberOfPackages"),,
		Cancel);
	
EndProcedure

Function NumberOfProductionStages()
	
	Query = New Query("
	|SELECT
	|	COUNT(*) AS NumberOfStages
	|FROM
	|	Catalog.ProductionStages AS Stages
	|WHERE
	|	Stages.Owner = &BillOfMaterials
	|	AND NOT Stages.DeletionMark");
	Query.SetParameter("BillOfMaterials", Ref);
	
	QueryResult = Query.Execute();
	If QueryResult.IsEmpty() Then
		Return 0;
	Else
		Selection = QueryResult.Select();
		Selection.Next();
		Return Selection.NumberOfStages;
	EndIf;
	
EndFunction

Function TabularSectionNames()
	
	Return Catalogs.BillsOfMaterials.TabularSectionNames();
	
EndFunction

Function ThisIsTechnologicalSet()
	
	Return ProductDataManagement.ThisIsTechnologicalSet(ThisObject);
	
EndFunction

#EndRegion

#EndRegion

#EndIf
