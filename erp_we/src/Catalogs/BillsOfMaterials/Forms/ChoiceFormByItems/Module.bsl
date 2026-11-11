
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	BOMSelectionParameters.Insert("GetProductBOM", False);
	BOMSelectionParameters.Insert("GetSpecificationsFromListOfProducts", False);
	BOMSelectionParameters.Insert("IgnoredDestinationParameters", New Array);
	BOMSelectionParameters.Insert("IgnoredApplicationRefinements", New Array);
	FillPropertyValues(BOMSelectionParameters, Parameters);
	
	Parameters.Property("ExcludeSpecification", ExcludeSpecification);
	
	For Each CurrentFilter In ListOfSelectionsByDestinationParameters() Do
		ParameterName    = CurrentFilter.Key;
		ParameterKind    = Enums.TypesOfBOMAssignmentParameters[ParameterName];
		If Not Parameters.Property(ParameterName)
			And BOMSelectionParameters.IgnoredDestinationParameters.Find(ParameterKind) = Undefined Then
			BOMSelectionParameters.IgnoredDestinationParameters.Add(ParameterKind);
		EndIf;
	EndDo;
	
	ProductData = ProductDataManagementClientServer.ProductDataStructureForSpecificationSelection();
	
	// Filling in the details for incoming data
	If BOMSelectionParameters.GetProductBOM Then
		
		FillPropertyValues(ProductData, Parameters);
		
	ElsIf BOMSelectionParameters.GetSpecificationsFromListOfProducts Then
	
		If Parameters.ProductData_2.Count() = 1 Then
			FillPropertyValues(ProductData, Parameters.ProductData_2[0]);
			BOMSelectionParameters.GetProductBOM = True;
			BOMSelectionParameters.GetSpecificationsFromListOfProducts = False;
		Else
			For Each ProductData_ In Parameters.ProductData_2 Do
				FillPropertyValues(ProductTable.Add(), ProductData_);
			EndDo;
		EndIf;
		
	Else
		
		Raise NStr("vi = 'Để mở biểu mẫu, cần truyền các tham số.';
					|ru = 'Для открытия формы необходимо передать параметры.';
					|en = 'To open the form, pass the parameters.'; fa = 'To open the form, pass the parameters.';
					|it = 'Per l''apertura del modulo è necessario trasferire i parametri.';
					|pl = 'Aby otworzyć formularz, musisz przekazać parametry.';
					|tr = 'Formun açılması için parametreleri transfer etmeniz gerekmektedir.'");
		
	EndIf;
	
	If BOMSelectionParameters.GetSpecificationsFromListOfProducts Then
		Table = ProductTable.Unload();
		For Each Column In Table.Columns Do
			If ProductData.Property(Column.Name) Then
				ProductData[Column.Name] = New Array;
				CommonClientServer.SupplementArray(
					ProductData[Column.Name], Table.UnloadColumn(Column.Name), True);
			EndIf;
		EndDo;
	EndIf;
	
	SetSpecificationListParameters();
	
	CustomizeFormElements();
	
	UpdateListOfSpecifications();
	
	// StandardSubsystems.AttachableCommands
	PlacementParameters = AttachableCommands.PlacementParameters();
	PlacementParameters.CommandBar = Items.AttachableCommands;
	AttachableCommands.OnCreateAtServer(ThisObject, PlacementParameters);
	// End StandardSubsystems.AttachableCommands
	
	FormEvents.OnCreateAtServer(ThisObject, Cancel, StandardProcessing);
	
	ObjectsVersioning.OnCreateAtServer(ThisObject);
	
	sh_ShamsiInit(); // sh_ShamsiInit
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterProductsOnChange(Item)
	
	SetSelectionByProductRange();
	
EndProcedure

&AtClient
Procedure FilterWorkCenterTypeOnChange(Item)
	SetSelectionParametersByTypeOfWorkCenter();
	Return; // empty handler
	
EndProcedure

&AtClient
Procedure FilterLineOfBusinessOnChange(Item)
	
	UpdateListOfSpecifications();
	
EndProcedure

&AtClient
Procedure FilterProductionDispatcherBusinessUnitOnChange(Item)
	
	UpdateListOfSpecifications();
	
EndProcedure

&AtClient
Procedure FilterFinishedProductBeingRepairedOnChange(Item)
	
	UpdateListOfSpecifications();
	
EndProcedure

&AtClient
Procedure DateOnChange(Item)
	Try CommonClient.CommonModule("sh_ShamsiCalendar").RefreshShamsiLabels(ThisObject); Except EndTry; // sh_Shamsi
	
	UpdateListOfSpecifications();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListOnActivateRow(Item)
	
	FillInInformationLine();
	
	// StandardSubsystems.AttachableCommands
	AttachableCommandsClient.StartCommandUpdate(ThisObject);
	// End StandardSubsystems.AttachableCommands
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisObject, Command);
	
EndProcedure

&AtClient
Procedure UpdateList(Command)

	UpdateListOfSpecifications();

EndProcedure

// StandardSubsystems.AttachableCommands
&AtClient
Procedure Attachable_ExecuteCommand(Command)
	AttachableCommandsClient.ExecuteCommand(ThisObject, Command, Items.List);
EndProcedure

&AtServer
Procedure Attachable_ExecuteCommandAtServer(Context, Result) Export
	AttachableCommands.ExecuteCommand(ThisObject, Context, Items.List, Result);
EndProcedure

&AtClient
Procedure Attachable_UpdateCommands()
	AttachableCommandsClientServer.UpdateCommands(ThisObject, Items.List);
EndProcedure
// End StandardSubsystems.AttachableCommands

#EndRegion

#Region Private

&AtServer
Procedure CustomizeFormElements()
	
	Items.Status.Visible = Not Parameters.Property("AvailableStatuses") Or Parameters.AvailableStatuses.Count() <> 1;
	
	BasicTypeOfProductionProcess = Enums.ProductionProcessTypes.EmptyRef();
	If Parameters.Property("AvailableTypes") Then
		Items.ProductionProcessType.Visible = Parameters.AvailableTypes.Count() <> 1;
		If Parameters.AvailableTypes.Count() = 1 Then
			BasicTypeOfProductionProcess = Parameters.AvailableTypes[0];
		EndIf;
	EndIf;
	
	// Title
	If Not Parameters.Property("Title", Title) Then
		SubstitutionText = "";
		If BOMSelectionParameters.GetProductBOM And ValueIsFilled(ProductData.Products) Then
			SubstitutionText = StrTemplate(" ""%1""", String(ProductData.Products)
				+ ?(ProductData.Characteristic.IsEmpty(),"",", "+String(ProductData.Characteristic)));
		EndIf;
		If ValueIsFilled(BasicTypeOfProductionProcess) Then
			SubstitutionText = StrTemplate("%1 (%2)", SubstitutionText, Lower(BasicTypeOfProductionProcess));
		EndIf;
		Title = StrTemplate(NStr("vi = 'Danh sách bảng kê chi tiết các nguồn lực sản xuất %1';
								|ru = 'Ресурсные спецификации%1';
								|en = 'Bills of materials%1'; fa = 'Bills of materials%1';
								|it = 'Specifiche delle risorse (%1)';
								|pl = 'Specyfikacje zasobów%1';
								|tr = 'Ürün reçeteleri%1'"), SubstitutionText);
	EndIf;
	
	// Filters
	For Each CurrentFilter In ListOfSelectionsByDestinationParameters() Do
		
		ParameterName        = CurrentFilter.Key;
		FilterName           = CurrentFilter.Value.FilterName;
		FilterPresentation = CurrentFilter.Value.Presentation;
		FilterElement       = Items[FilterName]; // FormField
		ParameterKind        = Enums.TypesOfBOMAssignmentParameters[ParameterName];
		
		If ProductDataManagementCached.TypeOfDestinationParameterIsUsed(ParameterKind) 
			And BOMSelectionParameters.IgnoredDestinationParameters.Find(ParameterKind) = Undefined Then
			If BOMSelectionParameters.GetProductBOM
					And ValueIsFilled(ProductData[ParameterName]) Then
				FilterValue = ProductData[ParameterName];
			ElsIf BOMSelectionParameters.GetSpecificationsFromListOfProducts
					And ProductData[ParameterName].Count() = 1
					And ValueIsFilled(ProductData[ParameterName][0]) Then
				FilterValue = ProductData[ParameterName][0];
			Else
				FilterValue = NStr("vi = '<chưa chỉ ra>';
									|ru = '<не указано>';
									|en = '<none>'; fa = '<هیچ>';
									|it = '<non indicato>';
									|pl = '<nie określono>';
									|tr = '<belirtilmedi>'");
			EndIf;
			FilterElement.Title = StrTemplate(NStr("vi = '%1: %2';
													|ru = '%1: %2';
													|en = '%1: %2'; fa = '%1: %2';
													|it = '%1: %2';
													|pl = '%1: %2';
													|tr = '%1: %2'"), FilterPresentation, FilterValue);
			FilterElement.Visible = True;
			ThisObject[FilterName]   = True;
		Else
			FilterElement.Visible = False;
		EndIf;
		
	EndDo;
	
	// Validity period
	If BOMSelectionParameters.GetProductBOM Then
		Date = ProductData.ProductionStart;
	ElsIf BOMSelectionParameters.GetSpecificationsFromListOfProducts 
		And ProductData.ProductionStart.Count() = 1 Then
		Date = ProductData.ProductionStart[0];
	EndIf;
	CommonClientServer.SetDynamicListParameter(List, "ProductionStart", Date);
	
	// The Finished Product being Repaired
	If BasicTypeOfProductionProcess = Enums.ProductionProcessTypes.PerformRM Then
		Items.GroupRepairedFinishedProduct.Visible = True;
		If BOMSelectionParameters.GetProductBOM
			And ValueIsFilled(ProductData.UnderRepairProduct) Then
			FilterFinishedProductBeingRepaired = True;
			UnderRepairProduct = ProductData.UnderRepairProduct;
			UnderRepairVariant = ProductData.UnderRepairVariant;
			Items.FilterFinishedProductBeingRepaired.Title = StrTemplate(
				NStr("vi = 'Sản phẩm được sửa chữa: %1';
					|ru = 'Ремонтируемое изделие: %1';
					|en = 'Product under R&M: %1'; fa = 'Product under R&M: %1';
					|it = 'Product under R&M: %1';
					|pl = 'Product under R&M: %1';
					|tr = 'Onarılan nihai ürün: %1'"),
				ProductsClientServer.ProductPresentation(UnderRepairProduct, UnderRepairVariant));
		EndIf;
	Else
		Items.GroupRepairedFinishedProduct.Visible = False;
	EndIf;
	Items.FilterFinishedProductBeingRepaired.Visible = FilterFinishedProductBeingRepaired;
	
	// Information on selection parameters
	FillInInformationOnSpecificationSelectionParameters();
	
EndProcedure

#Region BOMList

&AtServer
Procedure UpdateListOfSpecifications()
	
	If BOMSelectionParameters.GetProductBOM Then
		FillInListOfSpecificationsByProduct();
	ElsIf BOMSelectionParameters.GetSpecificationsFromListOfProducts Then
		FillInListOfSpecificationsOnProductTable();
	EndIf;
	
EndProcedure

&AtServer
Procedure FillInListOfSpecificationsByProduct()
	
	ProductData.ProductionStart = Date;
	
	ConfigureSelectionByDestinationParameters();
	
	If FilterFinishedProductBeingRepaired Then
		ProductData.UnderRepairProduct = UnderRepairProduct;
		ProductData.UnderRepairVariant = UnderRepairVariant;
	Else
		ProductData.UnderRepairProduct = Catalogs.Products.EmptyRef();
		ProductData.UnderRepairVariant = Catalogs.ItemsCharacteristics.EmptyRef();
	EndIf;
	
	Result = ProductDataManagement.BillsOfMaterial(ProductData, BOMSelectionParameters);
	
	Specifications             = New Array;
	PrioritySpecification = Catalogs.BillsOfMaterials.EmptyRef();
	
	For IndexOf = 0 To Result.UBound() Do
		CurrentSpecification = Result[IndexOf].BillOfMaterials;
		If PrioritySpecification.IsEmpty()
				And Result[IndexOf].SelectedAutomatically = True Then
			PrioritySpecification = CurrentSpecification;
		EndIf;
		If CurrentSpecification <> ExcludeSpecification Then
			Specifications.Add(CurrentSpecification);
		EndIf;
	EndDo;
	
	CommonClientServer.SetDynamicListParameter(List, "BOMList",       Specifications);
	CommonClientServer.SetDynamicListParameter(List, "PrioritySpecification", PrioritySpecification);
	
EndProcedure

&AtServer
Procedure FillInListOfSpecificationsOnProductTable()
	
	AttributesList = New Array;
	AttributesList.Add("Products");
	AttributesList.Add("Characteristic");
	
	ConfigureSelectionByDestinationParameters(AttributesList);
	
	Table = ProductDataManagement.ProductDataTableForSpecificationSelection();
	For IndexOf = 0 To ProductTable.Count() - 1 Do
		NewRow = Table.Add();
		FillPropertyValues(NewRow, ProductTable[IndexOf], StrConcat(AttributesList,","));
		NewRow.ProductionStart = Date;
		NewRow.TheIndexOfTheData = IndexOf;
	EndDo;
	
	Specifications = ProductDataManagement.ListOfSpecificationsByProductList(Table, BOMSelectionParameters);
	
	If Not ExcludeSpecification.IsEmpty() Then
		IndexOf = Specifications.Find(ExcludeSpecification);
		If IndexOf <> Undefined Then
			Specifications.Delete(IndexOf);
		EndIf;
	EndIf;
	
	PrioritySpecification = Catalogs.BillsOfMaterials.EmptyRef();
	
	CommonClientServer.SetDynamicListParameter(List, "BOMList",       Specifications);
	CommonClientServer.SetDynamicListParameter(List, "PrioritySpecification", PrioritySpecification);
	
EndProcedure

#EndRegion

#Region Filters

&AtClientAtServerNoContext
Function ListOfSelectionsByDestinationParameters()
	
	Result = New Structure;
	
	Attributes = "FilterName,Presentation";
	
	Result.Insert("LineOfBusiness",
		New Structure(Attributes, "FilterLineOfBusiness", NStr("vi = 'Lĩnh vực hoạt động';
																|ru = 'Направление деятельности';
																|en = 'Line of business'; fa = 'خط کسب‌وکار';
																|it = 'Settore di attività';
																|pl = 'Rodzaj działalności';
																|tr = 'İş kolu'")));
	Result.Insert("ProductionDispatcherBusinessUnit",
		New Structure(Attributes, "FilterProductionDispatcherBusinessUnit",  NStr("vi = 'Bộ phận-điều phối';
																					|ru = 'Подразделение-диспетчер';
																					|en = 'Dispatching unit'; fa = 'واحد دیسپچینگ';
																					|it = 'Reparto-distributore';
																					|pl = 'Dział dyspozytorski';
																					|tr = 'Üretim planlama departmanı'")));
	
	Return Result;
	
EndFunction

&AtServer
Procedure ConfigureSelectionByDestinationParameters(AttributesList = Undefined)
	
	For Each CurrentFilter In ListOfSelectionsByDestinationParameters() Do
		ParameterName    = CurrentFilter.Key;
		FilterName       = CurrentFilter.Value.FilterName;
		ParameterKind    = Enums.TypesOfBOMAssignmentParameters[ParameterName];
		ParameterIndex = BOMSelectionParameters.IgnoredDestinationParameters.Find(ParameterKind);
		If ThisObject[FilterName] Then
			If ParameterIndex <> Undefined Then
				BOMSelectionParameters.IgnoredDestinationParameters.Delete(ParameterIndex);
			EndIf;
			If AttributesList <> Undefined
				And ProductData[ParameterName].Count() = 1 Then
				AttributesList.Add(ParameterName);
			EndIf;
		Else
			If ParameterIndex = Undefined Then
				BOMSelectionParameters.IgnoredDestinationParameters.Add(ParameterKind);
			EndIf;
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure SetSelectionByProductRange()
	
	ProductDataManagement.SetSelectionByProductInListOfSpecifications(
		List, FilterProducts, Enums.UseOfItemsInProductionMasterData.Material);
	
EndProcedure

&AtServer
Procedure SetSelectionParametersByTypeOfWorkCenter()
	
	CommonClientServer.SetDynamicListParameter(
		List, "WorkCenterType", FilterWorkCenterType, True);
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();
	
	Catalogs.BillsOfMaterials.SetConditionalAppearanceOfListOfResourceSpecifications(List.ConditionalAppearance);
	
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue  = New DataCompositionField("PrioritySpecification");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	
	Item.Appearance.SetParameterValue("Font", New Font(,,True));
	
	//
	Item = List.ConditionalAppearance.Items.Add();
	
	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField("FinishedProductBeingRepaired");
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("FinishedProductBeingRepaired");
	ItemFilter.ComparisonType = DataCompositionComparisonType.NotFilled;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	Item.Appearance.SetParameterValue("Text", NStr("vi = '<sản phẩm bất kỳ>';
													|ru = '<любое изделие>';
													|en = '<any product>'; fa = '<هر محصول>';
													|it = '<any product>';
													|pl = '<any product>';
													|tr = '<herhangi bir ürün>'"));

EndProcedure

&AtServer
Procedure SetSpecificationListParameters()
	
	If BOMSelectionParameters.GetProductBOM Then
		ProductKind = Common.ObjectAttributeValue(ProductData.Products, "ProductKind");
		QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsBOM.Package",
			"CatProducts.Ref");
	Else
		ProductKind = Catalogs.ItemKinds.EmptyRef();
		QueryTextPackagingFactor = "NULL";
	EndIf;
	
	List.QueryText = StrReplace(List.QueryText, "&QueryTextPackagingFactor", QueryTextPackagingFactor);
	
	CommonClientServer.SetDynamicListParameter(List, "ProductKind", ProductKind);
	CommonClientServer.SetDynamicListParameter(List, "Products",    ProductData.Products);
	CommonClientServer.SetDynamicListParameter(List, "Characteristic",  ProductData.Characteristic);
	CommonClientServer.SetDynamicListParameter(List, 
		"GetProductBOM", BOMSelectionParameters.GetProductBOM);
		
	SelectionTextWorkCenterType = "TRUE";
	SelectionTextWorkCenterType = "(&WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|			OR TRUE IN (SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductionStages.WorkCenterTypes AS WorkCenterTypes
	|				WHERE
	|					WorkCenterTypes.Ref.Owner = CatalogBillsOfMaterials.Ref
	|					AND &WorkCenterType <> VALUE(Catalog.WorkCenterTypes.EmptyRef)
	|					AND (WorkCenterTypes.WorkCenterType = &WorkCenterType
	|						OR &WorkCenterType = VALUE(Catalog.WorkCenterTypes.EmptyRef))))";
	List.QueryText = StrReplace(List.QueryText, "&SelectionTextWorkCenterType", SelectionTextWorkCenterType);
	SetSelectionParametersByTypeOfWorkCenter();
EndProcedure

&AtServer
Procedure FillInInformationOnSpecificationSelectionParameters()
	
	TextSelectionParameters = "";
	
	If BOMSelectionParameters.GetSpecificationsFromListOfProducts
		And ProductData.Products.Count() > 0 Then
			TextSelectionParameters = NStr("vi = 'Mặt hàng:';
											|ru = 'Номенклатура:';
											|en = 'Item:'; fa = 'قلم:';
											|it = 'Articolo:';
											|pl = 'Pozycja:';
											|tr = 'Öğe:'") + " " + StrConcat(ProductData.Products, ", ")+".";
	EndIf;
	
	Items.TextSelectionParameters.Visible = Not IsBlankString(TextSelectionParameters);
	
EndProcedure

&AtClient
Procedure FillInInformationLine()
	
	CurrentData = Items.List.CurrentData;
	If CurrentData = Undefined
			Or Not BOMSelectionParameters.GetProductBOM Then
		InformationBar = Undefined;
		Return;
	EndIf;
	
	Rows = New Array;
	FontBold = New Font(,,True);
	
	// Minimum party
	MinimumBatch = Round(CurrentData.MinimumReleaseLot * CurrentData.QuantityPerBatch, 3);
	If MinimumBatch <> 0 Then
		
		Rows.Add(NStr("vi = 'Lô hàng tối thiểu:';
						|ru = 'Мин. партия:';
						|en = 'Min. lot:'; fa = 'Min. lot:';
						|it = 'Min. lotto:';
						|pl = 'Min. partia:';
						|tr = 'Min. lot:'") + " ");
		Rows.Add(New FormattedString(Format(MinimumBatch, "NG="), FontBold));
		Rows.Add(" ");
		Rows.Add(New FormattedString(CurrentData.UnitOfMeasurePresentation, FontBold));
		
		Rows.Add(" ");
		
	EndIf;
	
	// Optimal batch
	OptimalBatch = Round(CurrentData.EconomicReleaseLot * CurrentData.QuantityPerBatch, 3);
	If OptimalBatch <> 0 Then
		
		Rows.Add(NStr("vi = 'Lô hàng bán buôn:';
						|ru = 'Опт. партия:';
						|en = 'Wholesale lot:'; fa = 'Wholesale lot:';
						|it = 'Ott. lotto:';
						|pl = 'Opt. partia:';
						|tr = 'Opt. lot:'") + " ");
		Rows.Add(New FormattedString(Format(OptimalBatch, "NG="), FontBold));
		Rows.Add(" ");
		Rows.Add(New FormattedString(CurrentData.UnitOfMeasurePresentation, FontBold));
		
		Rows.Add(" ");
		
	EndIf;
	
	InformationBar = ?(Rows.UBound() <> -1, New FormattedString(Rows), Undefined);
	
EndProcedure

#EndRegion

#EndRegion

#Region sh_Shamsi

// Şemsi kutularını ekler / yeniler (Add-ShamsiHandlers.ps1 v2.1)
&AtServer
Procedure sh_ShamsiInit()
	Try
		Common.CommonModule("sh_ShamsiServer").AddShamsiLabels(ThisObject);
	Except
	EndTry;
EndProcedure

// Şemsi kutusu değişince (sh_ShamsiServer.AddShamsiLabels tarafından bağlanır)
&AtClient
Procedure sh_ShamsiOnChange(Item)
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
	Except
		Return;
	EndTry;
	If Not sh_Module.ShamsiFieldOnChange(ThisObject, Item) Then
		Return;
	EndIf;
	If Item.Name = "sh_ShamsiInput_F_Date" Then
		DateOnChange(Items.Date);
	EndIf;
EndProcedure

// Şemsi kutusundaki takvim butonu: Şemsi takvim penceresini açar
&AtClient
Procedure sh_ShamsiStartChoice(Item, ChoiceData, StandardProcessing)
	StandardProcessing = False;
	sh_Current = Undefined;
	Try
		sh_Module = CommonClient.CommonModule("sh_ShamsiCalendar");
		sh_Path = sh_Module.ShamsiFieldMap(ThisObject).Get(Mid(Item.Name, StrLen("sh_ShamsiInput_") + 1));
		If sh_Path <> Undefined Then
			sh_Current = sh_Module.GetDateByPath(ThisObject, sh_Path);
		EndIf;
	Except
	EndTry;
	OpenForm("CommonForm.sh_ShamsiDatePicker", New Structure("Date", sh_Current), Item);
EndProcedure

#EndRegion
