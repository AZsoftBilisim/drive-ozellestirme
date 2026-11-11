#Region Variables

&AtClient
Var CachedValues;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Parameters.ItemData_3 <> Undefined Then
		
		UseProductionAccordingToSpecification = ?(Parameters.Property("UseProductionAccordingToSpecification"),
			Parameters.UseProductionAccordingToSpecification,
			True);
		IntermediateSemiFinishedProducts = ?(Parameters.Property("IntermediateSemiFinishedProducts"),
			Parameters.IntermediateSemiFinishedProducts,
			ProductDataManagementClientServer.IntermediateSemiFinishedProductsDoNotReceive());
		FillInMaterials(UseProductionAccordingToSpecification, IntermediateSemiFinishedProducts);
		
		Title = StrTemplate(
			NStr("vi = 'Lọc vật liệu theo bảng kê chi tiết các nguồn lực sản xuất: %1';
				|ru = 'Подбор материалов по спецификации: %1';
				|en = 'Pick materials by BOM: %1'; fa = 'Pick materials by BOM: %1';
				|it = 'Selezione dei materiali secondo la specifica: %1';
				|pl = 'Wybór materiałów wg specyfikacji: %1';
				|tr = 'Ürün reçetesine göre malzeme seçimi: %1'"),
			Common.ObjectAttributeValue(Parameters.ItemData_3.BillOfMaterials, "Presentation"));
		
	EndIf;
	
	If Parameters.ShowQuantityMatched Then
		
		ReadQuantityMatched();
		
		If Parameters.ColumnTitleQuantitySelected <> "" Then
			Items.UsedMaterialsTheNumberOfPackagesIsSelected.Title = Parameters.ColumnTitleQuantitySelected;
		EndIf;
		
	Else
		Items.UsedMaterialsTheNumberOfPackagesIsSelected.Visible = False;
	EndIf;
	
	ResultAddress = Parameters.UUID;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Modified And ThereIsDataToTransfer() Then
		
		SaveAndCloseNotification = New CallbackDescription(
			"BeforeClosingMoveAndClose", ThisObject);
	
		CommonClient.ShowFormClosingConfirmation(
			SaveAndCloseNotification,
			Cancel,
			Exit,
			NStr("vi = 'Dữ liệu đã được thay đổi. Chuyển vào chứng từ?';
				|ru = 'Данные были изменены. Перенести в документ?';
				|en = 'Data has changed. Transfer to the document?'; fa = 'Data has changed. Transfer to the document?';
				|it = 'I dati sono stati modificati. Trasferirli nel documento?';
				|pl = 'Dane zostały zmienione. Przenieść do dokumentu?';
				|tr = 'Veriler değiştirildi. Belgeye aktarılsın mı?'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersUsedMaterials

&AtClient
Procedure UsedMaterialsSelection(Item, RowSelected, Field, StandardProcessing)
	
	FieldName = Field.Name;
	CurrentData = Items.UsedMaterials.CurrentData;
	
	If FieldName = "UsedMaterialsProducts"
		And ValueIsFilled(CurrentData.Products) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.Products);
		
	ElsIf FieldName = "UsedMaterialsBillOfMaterials"
		And ValueIsFilled(CurrentData.BillOfMaterials) Then
		
		StandardProcessing = False;
		ShowValue(, CurrentData.BillOfMaterials);
		
	ElsIf FieldName = "UsedMaterialsApplyingTheMaterialEditing"
		And ValueIsFilled(CurrentData.ApplyingTheMaterialEditing) Then
		
		StandardProcessing = False;
		OpenMaterialApplicationSettingsForm(CurrentData);
		
	EndIf;

EndProcedure

&AtClient
Procedure UsedMaterialsNumberOfPackagesOnChange(Item)
	
	CurrentRow = Items.UsedMaterials.CurrentData;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfUnits", New Structure("MustBeRoundOff", False));
	
	BatchProcessingOfTablePartClient.ProcessTSString(CurrentRow, StructureOfActions, CachedValues);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure MoveToDocument(Command)
	
	If ThereIsDataToTransfer() Then
		
		TransferContentToDocument();
		
	Else
		
		ClearMessages();
		
		CommonClientServer.MessageToUser(
			NStr("vi = 'Cần chỉ định số lượng của mặt hàng';
				|ru = 'Необходимо указать количество номенклатуры';
				|en = 'Specify the amount of products'; fa = 'Specify the amount of products';
				|it = 'È necessario indicare la quantità dell''articolo';
				|pl = 'Należy wskazać ilość towarów';
				|tr = 'Öğe miktarını belirtmek gerekmektedir'"));
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()
	
	ConditionalAppearance.Items.Clear();
	
	ConditionalDesignParameters = ProductsServer.NewParametersForConditionalDesignOfUnitsOfMeasurement();
	ConditionalDesignParameters.NameOfUnitField = "UsedMaterialsProductsUnitOfMeasure";
	ConditionalDesignParameters.PathToPackagingUnitField = "UsedMaterials.Package";
	ProductsServer.SetConditionalAppearanceOfUnitsOfMeasurement(ThisObject, ConditionalDesignParameters);
	
	ProductsServer.EstablishConditionalAppearanceOfProductCharacteristics(
		ThisObject,
		"UsedMaterialsCharacteristic",
		"UsedMaterials.ItemVariantsAreUsed");
	
	// Text <specified during production>
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.UsedMaterialsCharacteristic.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.ItemVariantsAreUsed");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.Characteristic");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<được chỉ định trong sản xuất>';
													|ru = '<уточняется при производстве>';
													|en = '<specified during production>'; fa = '<specified during production>';
													|it = '<specificato durante la produzione>';
													|pl = '<uściślane podczas produkcji>';
													|tr = '<üretim esnasında netleştirilmektedir>'"));
	
	// The "dash" text for the Set in the "Selected" column
	Item = ConditionalAppearance.Items.Add();
	
	Item.Fields.Items.Add().Field = New DataCompositionField(Items.UsedMaterialsTheNumberOfPackagesIsSelected.Name);
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("UsedMaterials.ItemsType");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.ItemsTypes.Set;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", "-");
	
EndProcedure

&AtServer
Procedure FillInMaterials(UseProductionAccordingToSpecification, IntermediateSemiFinishedProducts)
	
	UsedMaterials.Clear();
	
	Basis = Undefined;
	Parameters.Property("Basis", Basis);
	
	ListOfData = "MaterialsAndServices,IncomingProducts";
	TempTablesManager = Undefined;
	If ValueIsFilled(Parameters.Stage)
		And (Parameters.FirstOperationID <> 0
			Or Parameters.LastOperationID <> 0) Then
		ListOfData = ListOfData + ",Operations"
	EndIf;
	If Not Parameters.ReferenceOrder.IsEmpty() Then
		TempTablesManager = New TempTablesManager;
		Documents.ProductionOrder2_2.CreateTTWaysToGetMaterials2_2(
			TempTablesManager, Parameters.ReferenceOrder);
	EndIf;
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters(
		ListOfData,
		TempTablesManager);
	SelectionParameters.GetPresentations = True;
	SelectionParameters.MethodOfCalculationOfMaterials = Enums.MaterialCalculationMethods.MaximumConsumption;
	SelectionParameters.OverridingReleasePartySetting.Use = True;
	SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions = True;
	SelectionParameters.CombineMaterialsAndIncomingProducts = True;
	SelectionParameters.GetDataSets = TypeOf(Basis) <> Type("DocumentRef.ProductionStage2_2");
	SelectionParameters.IntermediateSemiFinishedProducts = IntermediateSemiFinishedProducts;
	Filter = Undefined;
	If ValueIsFilled(Parameters.Stage) Then
		Filter = New Structure("Stage", Parameters.Stage);
	EndIf;
	
	SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
		Parameters.ItemData_3,
		SelectionParameters,
		Filter);
	If TypeOf(Basis) = Type("DocumentRef.EngineeringChangeOrder") Then
		ProductDataManagement.ExcludeMaterialsOfTechnologicalSets(SpecificationData);
	EndIf;
	
	If ValueIsFilled(Parameters.Stage)
		And Parameters.FirstOperationID <> 0 Then
		StructureOfSearchPredecessors = New Structure("Stage, NextOperation", Parameters.Stage);
		SearchStructureOperationData = New Structure("Stage, Operation", Parameters.Stage);
		
		SearchStructureOperation = New Structure;
		SearchStructureOperation.Insert("Stage", Parameters.Stage);
		SearchStructureOperation.Insert("OperationID", Parameters.FirstOperationID);
		FoundRows = SpecificationData.Operations.FindRows(SearchStructureOperation);
		If FoundRows.UBound() <> -1 Then
			StructureOfSearchPredecessors.NextOperation = FoundRows[0].OperationNumber;
			OperationQueue = SpecificationData.Operations.FindRows(StructureOfSearchPredecessors);
			While OperationQueue.UBound() <> -1 Do
				LineOperation = OperationQueue[0];
				SearchStructureOperationData.Operation = LineOperation.Operation;
				
				For Each String In SpecificationData.MaterialsAndServices.FindRows(SearchStructureOperationData) Do
					SpecificationData.MaterialsAndServices.Delete(String);
				EndDo;
				
				StructureOfSearchPredecessors.NextOperation = LineOperation.OperationNumber;
				For Each String In SpecificationData.Operations.FindRows(StructureOfSearchPredecessors) Do
					OperationQueue.Add(String);
				EndDo;
				
				OperationQueue.Delete(0);
			EndDo;
		EndIf;
	EndIf;
	
	If ValueIsFilled(Parameters.Stage)
		And Parameters.LastOperationID <> 0 Then
		SearchStructureFollowers = New Structure("Stage, OperationNumber", Parameters.Stage);
		SearchStructureOperationData = New Structure("Stage, Operation", Parameters.Stage);
		
		SearchStructureOperation = New Structure;
		SearchStructureOperation.Insert("Stage", Parameters.Stage);
		SearchStructureOperation.Insert("OperationID", Parameters.LastOperationID);
		FoundRows = SpecificationData.Operations.FindRows(SearchStructureOperation);
		If FoundRows.UBound() <> -1 Then
			SearchStructureFollowers.OperationNumber = FoundRows[0].NextOperation;
			OperationQueue = SpecificationData.Operations.FindRows(SearchStructureFollowers);
			While OperationQueue.UBound() <> -1 Do
				LineOperation = OperationQueue[0];
				SearchStructureOperationData.Operation = LineOperation.Operation;
				
				For Each String In SpecificationData.MaterialsAndServices.FindRows(SearchStructureOperationData) Do
					SpecificationData.MaterialsAndServices.Delete(String);
				EndDo;
				
				SearchStructureFollowers.OperationNumber = LineOperation.NextOperation;
				For Each String In SpecificationData.Operations.FindRows(SearchStructureFollowers) Do
					OperationQueue.Add(String);
				EndDo;
				
				OperationQueue.Delete(0);
			EndDo;
		EndIf;
	EndIf;
	LineNumber = 1;
	For Each String In SpecificationData.MaterialsAndServices Do
		
		NewRow = UsedMaterials.Add();
		
		FillPropertyValues(
			NewRow,
			String,
			"Stage,
			|Products,
			|Characteristic,
			|Package,
			|ProductCostElement,
			|BillOfMaterials,
			|ConnectionKey,
			|ApplyingTheMaterialEditing,
			|MaterialApplication,
			|AlternateType,
			|Probability,
			|SupplyOption,
			|Warehouse,
			|ItemsType,
			|LineKind");
		
		NewRow.NumberOfPackagesStandard = String.NumberOfPackages;
		
		If UseProductionAccordingToSpecification Then
			NewRow.Produced = String.Produced;
		Else
			NewRow.Produced = False;
		EndIf;
		
		If UseProductionAccordingToSpecification
			And String.ProducedInProcess
			And String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
			And Not String.WithAssignment Then
			NewRow.WithAssignment = True;
		Else
			NewRow.WithAssignment = String.WithAssignment;
		EndIf;
		
		NewRow.LineNumber = LineNumber;
		LineNumber = LineNumber + 1;
		
		NewRow.Department = String.StageSubdivision;
		
	EndDo;
	
	StructureOfActions = New Structure;
	
	StructureOfActions.Insert(
		"FillInFeatureAttribute",
		New Structure("Products", "ItemVariantsAreUsed"));
		
	StructureOfActions.Insert(
		"FillInArticleAttribute",
		New Structure("Products", "SKU"));
		
	ProductsServer.FillInServiceDetailsForProductInCollection(UsedMaterials, StructureOfActions);
	
EndProcedure

&AtServer
Procedure ReadQuantityMatched()
	
	If Not IsTempStorageURL(Parameters.AddressSelectedMaterials) Then
		Return;
	EndIf;
	
	TheStructureOfTheSearch = Parameters.SearchStructureSelectedMaterials;
	
	SelectedMaterials = GetFromTempStorage(Parameters.AddressSelectedMaterials);
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfSuffixUnits",
		New Structure("Suffix, MustBeRoundOff", "Selected", False));
	
	ReadyForProcessing_ = New Array;
	CachedValues = BatchProcessingOfTablePartClientServer.GetStructureOfCachedValues();
	
	For Each String In UsedMaterials Do
		
		FillPropertyValues(TheStructureOfTheSearch, String);
		FoundRows = SelectedMaterials.FindRows(TheStructureOfTheSearch);
		
		If FoundRows.Count() > 0 Then
			
			For Each StringMatched In FoundRows Do
				If String.Package = StringMatched.Package Then
					NumberOfPackagesToAdd = StringMatched.NumberOfPackages;
				Else
					DataArray = New Array;
					DataArray.Add(String);
					DataArray.Add(StringMatched);
					
					PackingFactors = Catalogs.PackagesAndUnitsOfMeasure.PackingFactors(DataArray).Get(String.Products);
					PackagingFactor1 = PackingFactors.Get(StringMatched.Package);
					PackagingFactor2 = PackingFactors.Get(String.Package);
					
					NumberOfPackagesToAdd = StringMatched.NumberOfPackages
						* ?(ValueIsFilled(PackagingFactor1),PackagingFactor1,1)
								/ ?(ValueIsFilled(PackagingFactor2),PackagingFactor2,1);
				EndIf;
				String.TheNumberOfPackagesIsSelected = String.TheNumberOfPackagesIsSelected + NumberOfPackagesToAdd;
			EndDo;
			
			ReadyForProcessing_.Add(String);
			
		EndIf;
		
	EndDo;
	
	BatchProcessingOfTablePartServer.ProcessTSStrings(
		ReadyForProcessing_,
		StructureOfActions,
		UsedMaterials,
		CachedValues);
	
EndProcedure

&AtClient
Procedure BeforeClosingMoveAndClose(QuestionResult, AdditionalParameters) Export
	
	TransferContentToDocument();
	
EndProcedure

&AtClient
Procedure TransferContentToDocument()
	
	Result = PlaceMaterialsInStorage();
	
	Modified = False;
	Close();
	
	NotifyChoice(Result);
	
EndProcedure

&AtServer
Function PlaceMaterialsInStorage()
	
	TableOfMaterials = FormAttributeToValue("UsedMaterials").CopyColumns(ResultOfComposition());
	
	For Each String In UsedMaterials Do
		
		If String.Count <> 0 Then
			FillPropertyValues(TableOfMaterials.Add(), String);
		EndIf;
		
	EndDo;
	
	Return PutToTempStorage(TableOfMaterials, ResultAddress);
	
EndFunction

&AtServer
Function ResultOfComposition()
	
	Return
		"Stage,
		|Products,
		|Characteristic,
		|Package,
		|NumberOfPackages,
		|Count,
		|ProductCostElement,
		|Produced,
		|BillOfMaterials,
		|MaterialApplication,
		|ConnectionKey,
		|SupplyOption,
		|WithAssignment,
		|Warehouse,
		|ItemVariantsAreUsed,
		|Department,
		|ItemsType,
		|LineKind";
	
EndFunction

&AtClient
Function ThereIsDataToTransfer()
	
	Result = False;
	
	For Each String In UsedMaterials Do
		
		If String.Count <> 0 Then
			
			Result = True;
			Break;
			
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

&AtClient
Procedure OpenMaterialApplicationSettingsForm(RowData)
	
	FormParameters = New Structure;
	
	FormParameters.Insert("Products", RowData.Products);
	FormParameters.Insert("Characteristic", RowData.Characteristic);
	
	FormParameters.Insert("MaterialApplication", RowData.MaterialApplication);
	FormParameters.Insert("AlternateType", RowData.AlternateType);
	FormParameters.Insert("Probability", RowData.Probability);
	
	FormParameters.Insert("ReadOnly", True);
	
	OpenForm("Catalog.BillsOfMaterials.Form.MaterialUsageSetupForm", FormParameters, ThisForm);

EndProcedure

#EndRegion
