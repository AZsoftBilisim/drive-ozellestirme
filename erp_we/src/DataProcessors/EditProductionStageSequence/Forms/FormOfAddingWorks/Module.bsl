#Region Variables

&AtClient
Var CachedValues; //used by the mechanism for processing changes in PM details

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();

	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Object.ProductionLot = Parameters.ProductionLot;
	Stage = Parameters.Stage;
	
	StageString = Object.Stages.Add();
	
	Query = New Query(
		"SELECT
		|	*
		|FROM
		|	Document.ProductionStage2_2 AS Stages
		|WHERE
		|	Stages.Ref = &Stage");
	Query.SetParameter("Stage", Stage);
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		FillPropertyValues(StageString, Selection);
	EndIf;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("ReferenceOrder",                 "Document");
	AttributesStructure1.Insert("LineOfBusiness",      "Document.LineOfBusiness");
	AttributesStructure1.Insert("Department",                "Document.Department");
	AttributesStructure1.Insert("EarliestStartDate",                "Document.EarliestStartDate");
	AttributesStructure1.Insert("ProductionProcessType", "Document.ProductionProcessType");
	AttributesValues = Common.ObjectAttributesValues(Object.ProductionLot, AttributesStructure1);
	
	FillPropertyValues(Object, AttributesValues);
	
	BOMSelectionParameters = ProductDataManagement.BOMSelectionParameters(
		Object, DataProcessors.EditProductionStageSequence);
	
	ItemArray = New Array;
	ItemArray.Add(Items.SupplyWithMaterialsAndWorksBillOfMaterials);
	ItemArray.Add(Items.BillOfMaterials);
	ProductDataManagement.SetSpecificationSelectionParameters(
		ItemArray, BOMSelectionParameters.SupplyOfMaterialsAndWorks_WorkPlanning);
	
	SeriesSpecificationParameters = New FixedStructure(
		ProductsServer.SeriesSpecificationParameters(Object, DataProcessors.EditProductionStageSequence));
	
	ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
		Object.Stages[0], Undefined);
	
	StageEditingParameters = New FixedStructure(
		DataProcessors.EditProductionStageSequence.StageEditingParameters());
	
	EmbeddingParameters = DataProcessors.EditProductionStageSequence.AvailableRemainingEmbeddingOptions();
	ProvisionInDocumentsServer.AvailableBalancesWhenReadingOnServer(ThisObject, EmbeddingParameters);
	
	DefaultWarehouse = TMCommonUse.GetCheckWarehouseByDefault();
	
	CustomizeFormElements();
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	TSName = "SupplyWithMaterialsAndWorks";
	TSPath = "Object.SupplyWithMaterialsAndWorks";
	ListName = NStr("vi = 'Công việc được thực hiện';
					|ru = 'Выполняемые работы';
					|en = 'Works to perform'; fa = 'کارهای قابل انجام';
					|it = 'Works to perform';
					|pl = 'Works to perform';
					|tr = 'Yapılan işler'");
	DataProcessorObject = FormAttributeToValue("Object");
	
	If Mode = MultipleWorksMode()
		And Object.SupplyWithMaterialsAndWorks.Count() = 0 Then
		
		Template = NStr("vi = 'Không có hàng nào được nhập trong danh sách ""%1""';
						|ru = 'Не введено ни одной строки в список ""%1""';
						|en = 'No line is entered into the ""%1"" list'; fa = 'No line is entered into the ""%1"" list';
						|it = 'Non è immessa alcuna riga nell''elenco ""%1""';
						|pl = 'Nie wprowadzono żadnego wiersza do listy ""%1""';
						|tr = '""%1"" listesine herhangi satır girilmedi'");
		MessageText = StrTemplate(Template, ListName);
		
		Common.MessageToUser(
			MessageText,,
			"Object.SupplyWithMaterialsAndWorks",,
			Cancel);
			
	Else
		
		CheckParameters = ProductsServer.ParametersForCheckingWhetherCharacteristicsAreFilledIn();
		CheckParameters.TSName = TSName;
		CheckParameters.PresentationOfTS = ListName;
		CheckParameters.FieldNamesWithSuffix.Insert("Products", "UnderRepairProduct");
		CheckParameters.FieldNamesWithSuffix.Insert("Characteristic", "UnderRepairVariant");
		ProductsServer.CheckWhetherCharacteristicsAreFilledIn(DataProcessorObject, NotCheckedAttributeArray, Cancel, CheckParameters);
		
		ProductsServer.CheckSeriesCompletion(Object, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, Cancel, NotCheckedAttributeArray);
		
		RoundingParameters = Documents.ProductionStage2_2.TSParametersForRounding();
		ProductsServer.CheckQuantityRounding(Object, Cancel, RoundingParameters.SupplyWithMaterialsAndWorks);
		
		If Object.SupplyWithMaterialsAndWorks.Count() > 1 Then
			CheckDifferentSpecificationsOfSameItem = True;
			SearchFields = "Produced,Products,Characteristic,Warehouse,Purpose";
			TheStructureOfTheSearch = New Structure(SearchFields);
		Else
			CheckDifferentSpecificationsOfSameItem = False;
		EndIf;
		
		For Each String In Object.SupplyWithMaterialsAndWorks Do
			
			If Not ValueIsFilled(String.Products) Then
				
				ReportFillingError(TSPath, String, "Products", Cancel, ListName, NStr("vi = 'Mặt hàng';
																						|ru = 'Номенклатура';
																						|en = 'Products'; fa = 'کالاها';
																						|it = 'Articolo';
																						|pl = 'Pozycja';
																						|tr = 'Öğe'"));
				
			EndIf;
			
			If String.NumberOfPackages = 0 Then
				
				ReportFillingError(TSPath, String, "NumberOfPackages", Cancel, ListName, NStr("vi = 'Số lượng';
																								|ru = 'Количество';
																								|en = 'Quantity'; fa = 'مقدار';
																								|it = 'Количество';
																								|pl = 'Ilość';
																								|tr = 'Miktar'"));
			
			EndIf;
			
			If String.Produced
				And Not ValueIsFilled(String.BillOfMaterials) Then
				
				ReportFillingError(TSPath, String, "BillOfMaterials", Cancel, ListName, NStr("vi = 'Bảng kê chi tiết';
																							|ru = 'Спецификация';
																							|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
																							|it = 'Bill of materials';
																							|pl = 'Bill of materials';
																							|tr = 'Ürün reçetesi'"));
				
			EndIf;
			
			If String.Produced
				And ValueIsFilled(String.BillOfMaterials)
				And CheckDifferentSpecificationsOfSameItem Then
				FillPropertyValues(TheStructureOfTheSearch, String);
				For Each FoundRow In Object.SupplyWithMaterialsAndWorks.FindRows(TheStructureOfTheSearch) Do
					If Not FoundRow.LineNumber = String.LineNumber
						And ValueIsFilled(FoundRow.BillOfMaterials)
						And Not FoundRow.BillOfMaterials = String.BillOfMaterials Then
					TextOfMessage = StrTemplate(
						NStr("vi = 'Không được phép chỉ định các bảng kê chi tiết khác nhau đối với một đối tượng phân tích kế toán mặt hàng (dòng %1 của danh sách ""%2"").';
							|ru = 'Не допускается указание различных спецификаций для одной аналитики учета номенклатуры (строка %1 списка ""%2"").';
							|en = 'You cannot specify different bills of materials for the same inventory location attributes (line %1 of the ""%2"" list).'; fa = 'You cannot specify different bills of materials for the same inventory location attributes (line %1 of the ""%2"" list).';
							|it = 'You cannot specify different bills of materials for the same inventory location attributes (line %1 of the ""%2"" list).';
							|pl = 'You cannot specify different bills of materials for the same inventory location attributes (line %1 of the ""%2"" list).';
							|tr = 'Öğe muhasebe analitiği (liste ""%2""nin %1. satırı) için farklı özellikler belirtilmesine izin verilmez.'"),
						String.LineNumber,
						ListName);
					ReportFillingError(TSPath, String, "BillOfMaterials",Cancel,,, TextOfMessage);
					Break;
					EndIf;
				EndDo;
			EndIf;
			
			If Not ValueIsFilled(String.ProductCostElement) Then
				
				ReportFillingError(TSPath, String, "ProductCostElement", Cancel, ListName, NStr("vi = 'Dạng tính giá thành';
																								|ru = 'Статья калькуляции';
																								|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																								|it = 'Voce di calcolo';
																								|pl = 'Rodzaj kosztu';
																								|tr = 'Ürün maliyet kalemi'"));
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And Not ValueIsFilled(String.RepairedFinishedProductWarehouse) Then
				
				ReportFillingError(TSPath, String, "RepairedFinishedProductWarehouse", Cancel, ListName, NStr("vi = 'Kho bãi';
																												|ru = 'Склад';
																												|en = 'Warehouse'; fa = 'Warehouse';
																												|it = 'Warehouse';
																												|pl = 'Warehouse';
																												|tr = 'Ambar'"));
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And String.FinishedProductToBeRepairedNumberOfPackagingUnits = 0 Then
				
				ReportFillingError(TSPath, String, "FinishedProductToBeRepairedNumberOfPackagingUnits", Cancel, ListName, NStr("vi = 'Số lượng';
																																|ru = 'Количество';
																																|en = 'Quantity'; fa = 'مقدار';
																																|it = 'Количество';
																																|pl = 'Ilość';
																																|tr = 'Miktar'"));
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And Not ValueIsFilled(String.RepairedFinishedProductDisassemblyStage) Then
				
				ReportFillingError(TSPath, String, "RepairedFinishedProductDisassemblyStage", Cancel, ListName, NStr("vi = 'Xuất xưởng';
																													|ru = 'Выпуск';
																													|en = 'Release'; fa = 'آزادسازی';
																													|it = 'Release';
																													|pl = 'Release';
																													|tr = 'İmal edilen ürünler'"));
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And Not ValueIsFilled(String.FinishedProductBeingRepairedIsKitsStage) Then
				
				ReportFillingError(TSPath, String, "RepairedFinishedProductDisassemblyStage", Cancel, ListName,NStr("vi = 'Tiêu dùng';
																													|ru = 'Потребление';
																													|en = 'Consumption'; fa = 'مصرف';
																													|it = 'Consumption';
																													|pl = 'Consumption';
																													|tr = 'Tüketim'"));
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And ValueIsFilled(String.RepairedFinishedProductDisassemblyStage)
				And String.RepairedFinishedProductDisassemblyStage = String.FinishedProductBeingRepairedIsKitsStage Then
				
				TextOfMessage = NStr("vi = 'Giá trị của trường ""Xuất xưởng"" và ""Tiêu dùng"" không cần trùng nhau.';
									|ru = 'Значения полей ""Выпуск"" и ""Потребление"" не должны совпадать.';
									|en = 'The values of the ""Release"" and ""Consumption"" fields must not match.'; fa = 'The values of the ""Release"" and ""Consumption"" fields must not match.';
									|it = 'The values of the ""Release"" and ""Consumption"" fields must not match.';
									|pl = 'The values of the ""Release"" and ""Consumption"" fields must not match.';
									|tr = '""Üretim"" ve ""Tüketim"" alanlarının değerlerinin uyuşmaması gerekmektedir.'");
				ReportFillingError(TSPath, String, "RepairedFinishedProductDisassemblyStage",Cancel,,, TextOfMessage);
				
			EndIf;
			
			If String.AddFINISHEDProductBeingRepairedToSteps
				And Not ValueIsFilled(String.FinishedProductBeingRepairedIsProductCostingElement) Then
				
				ReportFillingError(TSPath, String, "FinishedProductBeingRepairedIsProductCostingElement", Cancel, ListName, NStr("vi = 'Dạng tính giá thành';
																																|ru = 'Статья калькуляции';
																																|en = 'Product cost element'; fa = 'عنصر بهای تمام‌شده محصول';
																																|it = 'Voce di calcolo';
																																|pl = 'Rodzaj kosztu';
																																|tr = 'Ürün maliyet kalemi'"));
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	If Mode = SingleWorkMode() Then
		Messages = GetUserMessages(True);
		For Each Message In Messages Do
			If Not IsBlankString(Message.Field) Then
				FieldParts = StrSplit(Message.Field, ".");
				Message.Field = StrTemplate("Items.SupplyWithMaterialsAndWorks.CurrentData.%1", FieldParts[FieldParts.UBound()]);
				Message.DataPath = "";
				Marker = NStr("vi = 'cột ""';
								|ru = 'колонка ""';
								|en = 'column ""'; fa = 'column ""';
								|it = 'column ""';
								|pl = 'column ""';
								|tr = 'sütun ""'");
				Position1 = StrFind(Message.Text, Marker);
				If Position1 > 0 Then
					Position2 = StrFind(Message.Text, """",, Position1+StrLen(Marker));
					If Position2 > 0 Then
						Message.Text = CommonClientServer.FillingErrorText(
							"Field",
							"FillType",
							Mid(Message.Text, Position1+StrLen(Marker), Position2-Position1-StrLen(Marker)));
					EndIf;
				EndIf;
			EndIf;
			Message.Message();
		EndDo;
	EndIf;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ModeOnChange(Item)
	
	CustomizeFormByWorkingMode(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSupplyWithMaterialsAndWorks

&AtClient
Procedure SupplyWithMaterialsAndWorksOnStartEdit(Item, NewRow, Copy)
	
	If NewRow Then
		
		CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
		
		FillInDetailsOfSupplyLineWithMaterialsAndWorksByDefault(ThisObject, CurrentData);
		
	EndIf;
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksProductsOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", ParametersForFillingAssignments);
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	ProductionManagementClientServer.AddActionsToStructureWhenChangingProducts(
		"SupplyWithMaterialsAndWorks",
		ThisObject,
		Object.Stages[0],
		StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "Work_In_Progress");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksCharacteristicOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "Work_In_Progress");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksNumberOfPackagesOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	PerformActionsToRecalculateNumberOfUnits(CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "Work_In_Progress");
	
EndProcedure

&AtClient
Procedure SupplyOfMaterialsAndWorksToProduceOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure();
	
	If Not CurrentData.Produced Then
		CurrentData.BillOfMaterials = Undefined;
	EndIf;
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	AddActionCheckFillSupply(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "Work_In_Progress");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksBillOfMaterialsOnChange(Item)
	
	ConfigureDependentFormElements(ThisObject, "Work_In_Progress");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairProductOnChange(Item)
	
	FinishedProductToBeRepairedItemOnChangeATServer(CachedValues);
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairVariantOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	StructureOfActions = New Structure;
	
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	AddActionCheckFillSupply(ThisObject, StructureOfActions);
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksUnderRepairBatchOnChange(Item)
	
	ValueSelected = ProductsClientServer.SelectedSeries();
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	ValueSelected.Value                   = CurrentData.UnderRepairBatch;
	ValueSelected.CurrentRowID = CurrentData.GetID();
	
	CurrentRow = New Structure;
	CurrentRow.Insert("SupplyOption", PredefinedValue("Enum.SupplyOptions.NotRequired"));
	CurrentRow.Insert("Canceled", False);
	CurrentRow.Insert("Series", CurrentData.UnderRepairBatch);
	CurrentRow.Insert("BatchesIndicationStatus", CurrentData.UnderRepairBatchSpecificationStatus);
	
	ProductsClient.ProcessSeriesIndication(
		ThisObject, SeriesSpecificationParameters.SupplyWithMaterialsAndWorks, ValueSelected, CurrentRow);
	
	CurrentData.UnderRepairBatch               = CurrentRow.Series;
	CurrentData.UnderRepairBatchSpecificationStatus = CurrentRow.BatchesIndicationStatus;
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksFinishedProductToBeRepairedNumberOfPackagingUnitsOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentDataStructure = StringDataByStructure(ThisObject, CurrentData, True);
	
	PerformActionsToRecalculateNumberOfUnits(CurrentDataStructure);
	
	CurrentData.RepairedFinishedProductQuantity = CurrentDataStructure.Count;
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksFinishedProductToBeRepairedPackagingunitOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	CurrentDataStructure = StringDataByStructure(ThisObject, CurrentData, True);
	
	PerformActionsToRecalculateNumberOfUnits(CurrentDataStructure);
	
	CurrentData.RepairedFinishedProductQuantity = CurrentDataStructure.Count;
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

&AtClient
Procedure SupplyWithMaterialsAndWorksAddFINISHEDProductBeingRepairedToStepsOnChange(Item)
	
	CurrentData = Items.SupplyWithMaterialsAndWorks.CurrentData;
	
	CheckClearRegistrationDetails(CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	ClearMessages();
	
	If Not CheckFilling() Then
		Return;
	EndIf;
	
	Result = StructureOfResultAtServer(
		?(FormOwner <> Undefined, FormOwner.UUID, Undefined));
	Close(Result);
	
EndProcedure

&AtClient
Procedure FillInTheWarehouse(Command)
	
	Filter = New Structure;
	Filter.Insert("IsFolder", False);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("ChoiceFoldersAndItems", FoldersAndItemsUse.Items);
	
	CallbackDescription = New CallbackDescription("FillInTheWarehouseCompletion", ThisObject);
	
	OpenForm(
		"Catalog.Warehouses.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInTheCostingItem(Command)
	
	SelectCalculationArticle("ProductCostElement");
	
EndProcedure

&AtClient
Procedure FillInProductCostingElementOfFinishedProductToBeRepaired(Command)
	
	SelectCalculationArticle("FinishedProductBeingRepairedIsProductCostingElement");
	
EndProcedure

&AtClient
Procedure FillInDisassemblyStage(Command)
	
	SelectAStage("RepairedFinishedProductDisassemblyStage");
	
EndProcedure

&AtClient
Procedure FillInKitStageOfAssembly(Command)
	
	SelectAStage("FinishedProductBeingRepairedIsKitsStage");
	
EndProcedure
#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	//
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "SupplyWithMaterialsAndWorksUnderRepairProductUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "Object.SupplyWithMaterialsAndWorks.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"SupplyWithMaterialsAndWorksCharacteristic",
		"Object.SupplyWithMaterialsAndWorks.ItemVariantsAreUsed");
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"SupplyWithMaterialsAndWorksUnderRepairVariant",
		"Object.SupplyWithMaterialsAndWorks.FinishedProductBeingRepairedCharacteristicsAreUsed");
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyOfMaterialsAndWorksToProduce.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Products");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksUnderRepairProduct.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.UnderRepairProduct");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.InaccessibleCellTextColor);
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định để tham khảo>';
													|ru = '<указывается справочно>';
													|en = '<specified for reference>'; fa = '<مشخص‌شده برای مرجع>';
													|it = '<specified for reference>';
													|pl = '<specified for reference>';
													|tr = '<referans olarak belirtilir>'"));
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksAddFINISHEDProductBeingRepairedToSteps.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.UnderRepairProduct");
	Filter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksFinishedProductToBeRepairedNumberOfPackagingUnits.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksFinishedProductToBeRepairedPackagingunit.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksRepairedFinishedProductDisassemblyStage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksFinishedProductBeingRepairedIsKitsStage.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksFinishedProductBeingRepairedIsProductCostingElement.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksRepairedFinishedProductWarehouse.Name);
	
	Filter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	Filter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.AddFINISHEDProductBeingRepairedToSteps");
	Filter.ComparisonType = DataCompositionComparisonType.Equal;
	Filter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	Item.Appearance.SetParameterValue("ReadOnly", True);
	
	//
	Item = ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.SupplyWithMaterialsAndWorksBillOfMaterials.Name);
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.BillOfMaterials.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Object.SupplyWithMaterialsAndWorks.Produced");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;
	
	Item.Appearance.SetParameterValue("MarkIncomplete", False);
	
	//
	ProductsServer.EstablishConditionalAppearanceOfProductSeries(
		ThisObject,
		"SeriesAlwaysWHGoods",
		Items.SupplyWithMaterialsAndWorksUnderRepairBatch.Name,
		"Object.SupplyWithMaterialsAndWorks.UnderRepairBatchSpecificationStatus",
		"Object.SupplyWithMaterialsAndWorks.RepairedFinishedProductTypeOfItem");
	
EndProcedure

&AtServer
Procedure CustomizeFormElements()
	
	Items.SupplyOfMaterialsAndWorksGroupRepairedFINISHEDProduct.Visible =
		Object.ProductionProcessType = Enums.ProductionProcessTypes.PerformRM;
	Items.SupplyOfMaterialsAndWorksGroupRepairedFinishedProductBatch.Visible =
		SeriesSpecificationParameters.SupplyWithMaterialsAndWorks.UseItemsBatch;
	
	If ValueIsFilled(Parameters.Stage) Then
		Title = StrTemplate(NStr("vi = '%1 sang công đoạn %2';
								|ru = '%1 в этап %2';
								|en = '%1 in the %2 stage'; fa = '%1 in the %2 stage';
								|it = '%1 in the %2 stage';
								|pl = '%1 in the %2 stage';
								|tr = '%1 aşamada %2'"),
			Title,
			Documents.ProductionStage2_2.PresentationStage(Parameters.Stage));
	EndIf;
	
	CustomizeFormByWorkingMode(ThisObject);
	
	ConfigureDependentFormElements(ThisObject);
	
EndProcedure

&AtClientAtServerNoContext
Procedure ConfigureDependentFormElements(Form, AttributesList = "")
	
	Items = Form.Items;
	Object = Form.Object;
	
	Initialize = IsBlankString(AttributesList);
	AttributesStructure1 = New Structure(AttributesList);
	
	CurrentRow = Items.SupplyWithMaterialsAndWorks.CurrentRow;
	CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(CurrentRow);
	
	If AttributesStructure1.Property("Work_In_Progress")
		Or Initialize Then
		
		If Form.Mode = SingleWorkMode()
			And CurrentData <> Undefined Then
			
			ProductionClientServer.ConfigureItemVariantsElement(
				Items.Characteristic, CurrentData.ItemVariantsAreUsed); 
				
			Items.Produce.ReadOnly = Not ValueIsFilled(CurrentData.Products);
			Items.BillOfMaterials.ReadOnly = Not ValueIsFilled(CurrentData.Products);
			Items.BillOfMaterials.Enabled = CurrentData.Produced;
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("FinishedProductBeingRepaired")
		Or Initialize Then
		
		If Form.Mode = SingleWorkMode()
			And CurrentData <> Undefined Then
			
			ProductionClientServer.ConfigureItemVariantsElement(
				Items.UnderRepairVariant, CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed);
				
			Items.AddFINISHEDProductBeingRepairedToSteps.ReadOnly = Not ValueIsFilled(CurrentData.UnderRepairProduct);
			Items.AddRepairedFinishedProductGroupToSteps.Enabled = CurrentData.AddFINISHEDProductBeingRepairedToSteps;
			
			ProductionClientServer.EstablishAvailabilityOfBatchesOfRepairedFinishedProduct(
				Form, Object.ProductionProcessType, CurrentData.UnderRepairBatchSpecificationStatus);
			
		EndIf;
		
	EndIf;
	
	If AttributesStructure1.Property("Mode")
		Or Initialize Then
		
		If Form.Mode = SingleWorkMode() Then
			Items.GroupPages.CurrentPage = Items.GroupPageOneWork;
		Else
			Items.GroupPages.CurrentPage = Items.GroupPageMultipleWorks;
		EndIf;
		
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Function SingleWorkMode()
	
	Return 0;
	
EndFunction

&AtClientAtServerNoContext
Function MultipleWorksMode()
	
	Return 1;
	
EndFunction

&AtClientAtServerNoContext
Procedure CustomizeFormByWorkingMode(Form)
	
	If Form.Mode = SingleWorkMode()
		And Form.Object.SupplyWithMaterialsAndWorks.Count() = 0 Then
		NewRow = Form.Object.SupplyWithMaterialsAndWorks.Add();
		FillInDetailsOfSupplyLineWithMaterialsAndWorksByDefault(Form, NewRow);
		Form.Items.SupplyWithMaterialsAndWorks.CurrentRow = NewRow.GetID();
	EndIf;
	
	If Form.Mode = SingleWorkMode() Then
		Form.Items.Products.Visible = True;
		Form.Items.SupplyWithMaterialsAndWorksProducts.Visible = False;
	Else
		Form.Items.SupplyWithMaterialsAndWorksProducts.Visible = True;
		Form.Items.Products.Visible = False;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure FillInDetailsOfSupplyLineWithMaterialsAndWorksByDefault(Form, RowData)
	
	ObjectStage = Form.Object.Stages[0];
	
	RowData.Ref = ObjectStage.Ref;
	RowData.Status = ObjectStage.Status;
	RowData.WorkPlanning = True;
	RowData.ProductCostElement = PredefinedValue("Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess");
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckToFillDefaultWarehouse(Form, CurrentData)
	
	If ValueIsFilled(CurrentData.UnderRepairProduct)
		And Not ValueIsFilled(CurrentData.RepairedFinishedProductWarehouse) Then
		CurrentData.RepairedFinishedProductWarehouse = Form.DefaultWarehouse;
	ElsIf Not ValueIsFilled(CurrentData.UnderRepairProduct) Then
		CurrentData.RepairedFinishedProductWarehouse = Undefined;
	EndIf;
	
EndProcedure

&AtClientAtServerNoContext
Procedure CheckClearRegistrationDetails(RowData)
	
	If Not RowData.AddFINISHEDProductBeingRepairedToSteps Then
		
		RowData.FinishedProductToBeRepairedNumberOfPackagingUnits = Undefined;
		RowData.RepairedFinishedProductQuantity = Undefined;
		RowData.RepairedFinishedProductWarehouse = Undefined;
		RowData.RepairedFinishedProductDisassemblyStage = Undefined;
		RowData.FinishedProductBeingRepairedIsKitsStage = Undefined;
		RowData.FinishedProductBeingRepairedIsProductCostingElement = Undefined;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure PerformActionsToRecalculateNumberOfUnits(RowData)
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	
	BatchProcessingOfTablePartClient.ProcessTSString(RowData, StructureOfActions, CachedValues);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddCheckActionFillInSpecification(Form, StructureOfActions, CurrentData)
	
	If Not CurrentData.Produced Then
		Return;
	EndIf;
	
	FillParameters = ProductDataManagementClientServer.ActionParametersCheckFillSpecification(
		Form.Object,
		CurrentData,
		Form.BOMSelectionParameters.SupplyOfMaterialsAndWorks_WorkPlanning);
	StructureOfActions.Insert("CheckFillSpecification", FillParameters);
	
EndProcedure

&AtClientAtServerNoContext
Procedure AddActionCheckFillSupply(Form, StructureOfActions)
	
	ObjectStage = Form.Object.Stages[0];
	
	StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", Form.ParametersForFillingAssignments);
	
	MethodParameters = New Structure();
	MethodParameters.Insert("ProductionOrder",    ObjectStage.ReferenceOrder);
	MethodParameters.Insert("Department",          ObjectStage.Department);
	MethodParameters.Insert("Ref",                 ObjectStage.Ref);
	MethodParameters.Insert("Status",                 ObjectStage.Status);
	MethodParameters.Insert("SubcontractOrder",     ObjectStage.SubcontractOrder);
	MethodParameters.Insert("WorkPlanning",      ObjectStage.WorkPlanning);
	MethodParameters.Insert("SeriesSpecificationParameters", Form.SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	MethodParameters.Insert("Form",                  Form);
	
	ProductionManagementClientServer.AddToStructureActionsCheckSoftwareInProductionPhase(
		StructureOfActions,
		MethodParameters);
	
EndProcedure

&AtClientAtServerNoContext
Function StringDataByStructure(Form, RowData, OverrideToCalculateFINISHEDProductBeingRepaired = False)
	
	Result = ProductionManagementClientServer.TheseLinesSupplyOfMaterialsAndWorksStructure(RowData);
	
	If OverrideToCalculateFINISHEDProductBeingRepaired Then
		
		Result.Insert("ItemsType", RowData.RepairedFinishedProductTypeOfItem);
		Result.Insert("Products", RowData.UnderRepairProduct);
		Result.Insert("Characteristic", RowData.UnderRepairVariant);
		Result.Insert("ItemVariantsAreUsed", RowData.FinishedProductBeingRepairedCharacteristicsAreUsed);
		Result.Insert("NumberOfPackages", RowData.FinishedProductToBeRepairedNumberOfPackagingUnits);
		Result.Insert("Package", RowData.FinishedProductToBeRepairedPackagingunit);
		Result.Insert("Status", RowData.Status);
		
	EndIf;
	
	Return Result;
	
EndFunction

&AtClient
Procedure FillInTheWarehouseCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
		
		If Not CurrentData.AddFINISHEDProductBeingRepairedToSteps Then
			Continue;
		EndIf;
		
		CurrentData.RepairedFinishedProductWarehouse = Result;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectCalculationArticle(Var_AttributeName)
	
	Filter = New Structure;
	Filter.Insert("ExpenseType", ProductionClient.TypesOfCostsForChoosingCalculationArticle("SupplyWithMaterialsAndWorks"));
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("AttributeName", Var_AttributeName);
	CallbackDescription = New CallbackDescription("FillInCalculationArticleInLinesCompletion", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Catalog.ProductCostElements.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInCalculationArticleInLinesCompletion(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
		
		AttributeName = AdditionalParameters.AttributeName;
		If AttributeName = "FinishedProductBeingRepairedIsProductCostingElement"
			And Not CurrentData.AddFINISHEDProductBeingRepairedToSteps Then
			Continue;
		EndIf;
		
		CurrentData[AttributeName] = Result;
		
	EndDo;
	
EndProcedure

&AtClient
Procedure SelectAStage(Var_AttributeName)
	
	Filter = New Structure;
	Filter.Insert("ProductionLot", Object.ProductionLot);
	Filter.Insert("WorkPlanning", False);
	
	FormParameters = New Structure;
	FormParameters.Insert("Filter", Filter);
	FormParameters.Insert("MultipleChoice", False);
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("AttributeName", Var_AttributeName);
	CallbackDescription = New CallbackDescription("FillInStageInLinesLinesEnd", ThisObject, AdditionalParameters);
	
	OpenForm(
		"Document.ProductionStage2_2.Form.ChoiceForm",
		FormParameters,
		ThisObject,,,,
		CallbackDescription,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

&AtClient
Procedure FillInStageInLinesLinesEnd(Result, AdditionalParameters) Export

	If Result = Undefined Then
		Return;
	EndIf;
	
	SelectedRows = Items.SupplyWithMaterialsAndWorks.SelectedRows;
	
	For Each RowID In SelectedRows Do
		
		CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(RowID);
		
		If Not CurrentData.AddFINISHEDProductBeingRepairedToSteps Then
			Continue;
		EndIf;
		
		AttributeName = AdditionalParameters.AttributeName;
		CurrentData[AttributeName] = Result;
		
	EndDo;
	
EndProcedure

&AtServer
Procedure ReportFillingError(TSPath, RowData, FieldName, Cancel, ListName = "", FieldPresentation = "", MessageText = Undefined)
	
	If MessageText = Undefined Then
		MessageText = CommonClientServer.FillingErrorText(
			"Column", "FillType", FieldPresentation, RowData.LineNumber, ListName);
	EndIf;
	Field = CommonClientServer.PathToTabularSection(TSPath, RowData.LineNumber, FieldName);
	
	Common.MessageToUser(MessageText,, Field,, Cancel);
	
EndProcedure

&AtServer
Function StructureOfResultAtServer(UID = Undefined)
	
	Result = New Structure;
	
	ColumnsNames = "Products,Characteristic,NumberOfPackages,Package,Count,BillOfMaterials,
		|ProductCostElement,SupplyOption,Produced,WithAssignment,Purpose,SupplyAssignment,
		|UnderRepairProduct,UnderRepairVariant,UnderRepairBatch,UnderRepairBatchSpecificationStatus,
		|AddFINISHEDProductBeingRepairedToSteps,RepairedFinishedProductDisassemblyStage,FinishedProductBeingRepairedIsKitsStage,RepairedFinishedProductWarehouse,
		|FinishedProductToBeRepairedNumberOfPackagingUnits,FinishedProductToBeRepairedPackagingunit,RepairedFinishedProductQuantity,FinishedProductBeingRepairedIsProductCostingElement";
	
	Filter = New Structure;
	If Mode = SingleWorkMode() Then
		Filter.Insert("LineNumber", 1);
	EndIf;
	
	Works = Object.SupplyWithMaterialsAndWorks.Unload(Filter, ColumnsNames);
	
	StagesOfReverseKittingKitting = New Array;
	For Each String In Works Do
		If Not String.AddFINISHEDProductBeingRepairedToSteps Then
			Continue;
		EndIf;
		If ValueIsFilled(String.RepairedFinishedProductDisassemblyStage) Then
			StagesOfReverseKittingKitting.Add(String.RepairedFinishedProductDisassemblyStage);
		EndIf;
		If ValueIsFilled(String.FinishedProductBeingRepairedIsKitsStage) Then
			StagesOfReverseKittingKitting.Add(String.FinishedProductBeingRepairedIsKitsStage);
		EndIf;
	EndDo;
	TMCommonUse.DeleteDuplicateElementsFromArray(StagesOfReverseKittingKitting);
	
	Result.Insert("AddressOfWorkTable", PutToTempStorage(Works, UID));
	Result.Insert("StagesOfReverseKittingKitting", StagesOfReverseKittingKitting);
	
	Return Result;
	
EndFunction

&AtServer
Procedure FinishedProductToBeRepairedItemOnChangeATServer(CachedValues)
	
	CurrentRow = Items.SupplyWithMaterialsAndWorks.CurrentRow;
	CurrentData = Object.SupplyWithMaterialsAndWorks.FindByID(CurrentRow);
	CurrentDataStructure = StringDataByStructure(ThisObject, CurrentData, True);
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert("CheckCharacteristicsByOwner", CurrentDataStructure.Characteristic);
	StructureOfActions.Insert("CheckFillPackageByOwner");
	StructureOfActions.Insert("RecalculateNumberOfUnits", ProductionClientServer.ParametersForRecalculatingNumberOfUnits());
	StructureOfActions.Insert("FillInProductTypeAttribute_", New Structure("Products", "ItemsType"));
	
	SeriesVerificationParameters = New Structure;
	SeriesVerificationParameters.Insert("Warehouse", Undefined);
	SeriesVerificationParameters.Insert("SeriesSpecificationParameters", SeriesSpecificationParameters.SupplyWithMaterialsAndWorks);
	StructureOfActions.Insert("CheckSeriesCalculateStatus", SeriesVerificationParameters);
	
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentDataStructure, StructureOfActions, CachedValues);
	
	CurrentData.RepairedFinishedProductTypeOfItem            = CurrentDataStructure.ItemsType;
	CurrentData.UnderRepairVariant             = CurrentDataStructure.Characteristic;
	CurrentData.FinishedProductBeingRepairedCharacteristicsAreUsed = CurrentDataStructure.ItemVariantsAreUsed;
	CurrentData.UnderRepairBatch                      = CurrentDataStructure.UnderRepairBatch;
	CurrentData.UnderRepairBatchSpecificationStatus        = CurrentDataStructure.UnderRepairBatchSpecificationStatus;
	
	StructureOfActions = New Structure;
	AddCheckActionFillInSpecification(ThisObject, StructureOfActions, CurrentData);
	BatchProcessingOfTablePartServer.ProcessTSString(CurrentData, StructureOfActions, CachedValues);
	
	If Not ValueIsFilled(CurrentData.UnderRepairProduct) Then
		CurrentData.AddFINISHEDProductBeingRepairedToSteps = False;
		CheckClearRegistrationDetails(CurrentData);
	EndIf;
	
	Catalogs.PackagesAndUnitsOfMeasure.DisplayInformationAboutStorageUnit(
		CurrentData.UnderRepairProduct, Items.FinishedProductToBeRepairedPackagingunit);
	
	CheckToFillDefaultWarehouse(ThisObject, CurrentData);
	
	ConfigureDependentFormElements(ThisObject, "FinishedProductBeingRepaired");
	
EndProcedure

#EndRegion
