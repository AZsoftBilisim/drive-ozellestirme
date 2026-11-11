#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.EditOptionsAllowed = False;
	Settings.EditStructureAllowed = False;
	
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	FillInLayoutParameters(Form.Parameters, SettingsComposer.Settings);
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	FillInLayoutParameters(Form.Parameters, SettingsComposer.Settings);
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	
	Settings = SettingsComposer.GetSettings();
	
	If Not GetFunctionalOption("UseAlternativeMaterials") Then
		AnalogsField = New DataCompositionField("Substitutes");
		For Each Group In Settings.Structure Do
			For Each Item In Group.Selection.Items Do
				If TypeOf(Item) = Type("DataCompositionSelectedField")
					And Item.Field = AnalogsField Then
					Group.Selection.Items.Delete(Item);
					AnalogsField = Undefined;
					Break;
				EndIf;
			EndDo;
			If AnalogsField = Undefined Then
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, Settings, DetailsData);	
	
	ExternalDataSets = GenerateExternalDatasets(Settings);
	
	DataCompositionProcessor = New DataCompositionProcessor;
	DataCompositionProcessor.Initialize(CompositionTemplate, ExternalDataSets, DetailsData);
	
	ProcessorOutputToTabularDocument = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	ProcessorOutputToTabularDocument.SetDocument(ResultDocument);	
	ProcessorOutputToTabularDocument.Output(DataCompositionProcessor);
	
EndProcedure

#EndRegion

#Region Private

Procedure FillInLayoutParameters(Parameters, Settings)
	
	For Each Name In StrSplit("BillOfMaterials,Products,Characteristic,Count,LineOfBusiness,ProductionOrder", ",") Do
		If Parameters.Property(Name) Then
			DataCompositionClientServer.SetParameter(Settings, Name, Parameters[Name]);
		EndIf;
	EndDo;
	
	Assignments = Undefined;
	If Parameters.Property("DestinationAddress") 
			And IsTempStorageURL(Parameters.DestinationAddress) Then
		Assignments = GetFromTempStorage(Parameters.DestinationAddress);
	EndIf;
	If Assignments = Undefined Then
		Assignments = New ValueTable;
		Assignments.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		Assignments.Columns.Add("Count", New TypeDescription("Number"));
	EndIf;
	DataCompositionClientServer.SetParameter(Settings, "Assignments", New ValueStorage(Assignments));
	
	Products_1 = Undefined;
	If Parameters.Property("ProductAddress") 
			And IsTempStorageURL(Parameters.ProductAddress) Then
		Products_1 = GetFromTempStorage(Parameters.ProductAddress);
	EndIf;
	If Products_1 = Undefined Then
		Products_1 = New ValueTable;
		Products_1.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		Products_1.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		Products_1.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
		Products_1.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		Products_1.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		Products_1.Columns.Add("Count", New TypeDescription("Number"));
	EndIf;
	DataCompositionClientServer.SetParameter(Settings, "Products_1", New ValueStorage(Products_1));
	
	DataCompositionClientServer.SetParameter(Settings, "DataTypeOutputProducts", DataTypeOutputProducts());
	DataCompositionClientServer.SetParameter(Settings, "DataTypeByProducts", DataTypeByProducts());
	DataCompositionClientServer.SetParameter(Settings, "DataTypeMaterials", DataTypeMaterials());
	DataCompositionClientServer.SetParameter(Settings, "DataTypeLaborCosts", DataTypeLaborCosts());
	DataCompositionClientServer.SetParameter(Settings, "DataTypeStages", DataTypeStages());
	
EndProcedure

Function GenerateExternalDatasets(Settings)
	
	Result = New Structure;
	
	// Getting parameters
	Parameter = DataCompositionClientServer.GetParameter(Settings, "BillOfMaterials");
	BillOfMaterials = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "Products");
	Products = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "Characteristic");
	Characteristic = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "Count");
	Count = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "Assignments");
	DestinationStorage = Parameter.Value; //ValueStorage
	Assignments = ?(Parameter <> Undefined, DestinationStorage.Get(), Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "Products_1");
	ProductStorage = Parameter.Value; //ValueStorage
	Products_1 = ?(Parameter <> Undefined, ProductStorage.Get(), Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "LineOfBusiness");
	LineOfBusiness = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "ProductionOrder");
	ProductionOrder = ?(Parameter <> Undefined, Parameter.Value, Undefined);
	
	Parameter = DataCompositionClientServer.GetParameter(Settings, "OnlyProblematicPositions");
	OnlyProblematicPositions = ?(Parameter <> Undefined, Parameter.Value, False);
	
	// Reading specification data
	ItemData_3 = Catalogs.BillsOfMaterials.ItemData_3();
	ItemData_3.BillOfMaterials = BillOfMaterials;
	ItemData_3.Products = Products;
	ItemData_3.Characteristic = Characteristic;
	ItemData_3.Count = Count;
	
	SelectionParameters = Catalogs.BillsOfMaterials.DataSamplingParameters();
	SelectionParameters.CombineMaterialsAndIncomingProducts = True;
	
	SpecificationData = Catalogs.BillsOfMaterials.SpecificationDataByProducts(
		ItemData_3, SelectionParameters);
	
	Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(SpecificationData);
	
	// Output items
	ManufacturedProducts = SpecificationData.ManufacturedProducts;
	ManufacturedProducts.Columns.Add("DataType", New TypeDescription("Number"));
	ManufacturedProducts.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	ManufacturedProducts.Columns.Add("ProductionOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	
	RecipientTypes = New Array;
	RecipientTypes.Add(Type("CatalogRef.BusinessStructure"));
	RecipientTypes.Add(Type("CatalogRef.Warehouses"));
	TypeDescription = New TypeDescription(RecipientTypes);
	ManufacturedProducts.Columns.Add("Recipient", TypeDescription);
	ManufacturedProducts.LoadColumn(ManufacturedProducts.UnloadColumn("Warehouse"), "Recipient");
	
	If Products_1 <> Undefined Then
		
		TheStructureOfTheSearch = New Structure("Products, Characteristic");
		For IndexOf = -(ManufacturedProducts.Count()-1) To 0 Do
			
			String = ManufacturedProducts[-IndexOf];
			String.DataType = DataTypeOutputProducts();
			
			If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
				If ValueIsFilled(Products_1) Then
					String.Purpose = Products_1[0].Purpose;
				EndIf;
			Else
				
				LineNumber = 1;
				
				FillPropertyValues(TheStructureOfTheSearch, String);
				For Each FillingValues In Products_1.FindRows(TheStructureOfTheSearch) Do
					If FillingValues.Count = 0 Then
						Continue;
					EndIf;
					
					If String.Count > FillingValues.Count Then
						NewRow = ManufacturedProducts.Insert(-IndexOf + LineNumber);
						FillPropertyValues(NewRow, String);
						FillPropertyValues(NewRow, FillingValues, "ProductionOrder, Recipient, Purpose, Count");
						
						String.Count = String.Count - NewRow.Count;
						FillingValues.Count = 0;
						LineNumber = LineNumber + 1;
					Else
						FillPropertyValues(String, FillingValues, "ProductionOrder, Recipient, Purpose");
						FillingValues.Count  = FillingValues.Count - String.Count;
						Break;
					EndIf;
					
				EndDo;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	Result.Insert("ManufacturedProducts", ManufacturedProducts);
	
	// By-products
	SideAndIntermediateRelease = SpecificationData.RecyclableWaste;
	SideAndIntermediateRelease.Columns.Add("DataType", New TypeDescription("Number"));
	SideAndIntermediateRelease.FillValues(DataTypeByProducts(), "DataType");
	Result.Insert("SideAndIntermediateRelease", SideAndIntermediateRelease);
	
	// UsedMaterials
	UsedMaterials = SpecificationData.MaterialsAndServices;
	UsedMaterials.Columns.Add("Substitutes", Common.TypeDescriptionNumber(15, 3, AllowedSign.Nonnegative));
	UsedMaterials.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	
	If SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Disassembly Then
		TheStructureOfTheSearch = New Structure("Products, Characteristic");
		For Each Material In UsedMaterials Do
			
			If StrFind(Material.RowType, "IncomingProduct") <> 0 Then
				
				FillPropertyValues(TheStructureOfTheSearch, Material);
				
				ProductLines_ = Products_1.FindRows(TheStructureOfTheSearch);
				
				If ProductLines_.Count() <> 0 Then
					Material.Warehouse = ProductLines_[0].Recipient;
				EndIf;
				
			EndIf;
			
		EndDo;
	EndIf;
	
	If Assignments <> Undefined Then
		
		Total = Assignments.Total("Count");
		UBound = Assignments.Count()-1;
		
		For IndexMaterial = -UsedMaterials.Count()+1 To 0 Do
			
			String = UsedMaterials[-IndexMaterial];
			
			Balance = String.Count;
			For IndexPurpose = 0 To UBound Do
				
				AssignmentRow = Assignments[IndexPurpose];
				
				NewRow = UsedMaterials.Add();
				FillPropertyValues(NewRow, String);
				NewRow.Purpose = AssignmentRow.Purpose;
				NewRow.Count = ?(IndexPurpose = UBound,
					Balance,
					String.Count * AssignmentRow.Count/Total);
					
				Balance = Balance - NewRow.Count;
				
			EndDo;
			
			UsedMaterials.Delete(String);
			
		EndDo;
		
		UsedMaterials.Sort("LineNumber");
		
	EndIf;
	
	If GetFunctionalOption("UseAlternativeMaterials") Then
		
		ChoiceParameters = AlternativeMaterials.AnalogSelectionParameters(
			New TypeDescription("CatalogRef.ProductionStages"));
		
		// Goods
		Goods = UsedMaterials.Copy(,
			"Stage,LineNumber,Products,Characteristic,Warehouse,Purpose,WithAssignment,Count,ConnectionKey,MaterialApplication");
		Goods.Columns.Stage.Name = "Ref";
		Goods.Columns.ConnectionKey.Name = "LinkKeyBOM";
		Goods.Columns.MaterialApplication.Name = "Comment";
		Goods.Columns.Add("TotalCount1", New TypeDescription("Number", New NumberQualifiers));
		
		For Each TableRow In Goods Do
			TableRow.TotalCount1 = TableRow.Count;
		EndDo;
		
		ChoiceParameters.GoodsParameters.Goods = PutToTempStorage(Goods);
		
		// Parameters
		ParametersTable = ChoiceParameters.SubstitutesParameters.ParametersTable;
		
		For Each String In SpecificationData.Stages Do
			
			TableRow = ParametersTable.Add();
			TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
			TableRow.Ref = String.Stage;
			TableRow.Department = String.Department;
			
			TableRow.LineOfBusiness = LineOfBusiness;			
			TableRow.ProductionOrder = ProductionOrder;
			TableRow.BillOfMaterials = BillOfMaterials;
			TableRow.Product = Products;
			TableRow.ItemVariantOfProduct = Characteristic;
			
		EndDo;
		
		ChoiceParameters.SubstitutesParameters.ParametersTable = PutToTempStorage(ParametersTable);
		
		ReplacementTable = AlternativeMaterials.GetReplacementTable(ChoiceParameters);
		If ReplacementTable <> Undefined Then
			
			ReplacementTable.Indexes.Add("ThisIsASubstitute");
			UsedMaterials.Indexes.Add("LineNumber");
			
			FilterLineNumber = New Structure("LineNumber");
			
			FoundRows = ReplacementTable.FindRows(New Structure("ThisIsASubstitute", False));
			For Each RowFromReplacementTable In FoundRows Do
				
				FillPropertyValues(FilterLineNumber, RowFromReplacementTable);
				
				NewMaterials = UsedMaterials.FindRows(FilterLineNumber)[0];
				NewMaterials.Substitutes = NewMaterials.Count - RowFromReplacementTable.Count;
				
			EndDo;
			
		EndIf;
		
	EndIf;
	
	Query = New Query(
		"SELECT
		|	UsedMaterials.Products       AS Products,
		|	UsedMaterials.Characteristic     AS Characteristic,
		|	UsedMaterials.Warehouse              AS Warehouse,
		|	UsedMaterials.Purpose         AS Purpose,
		|	UsedMaterials.WithAssignment        AS WithAssignment,
		|	UsedMaterials.Stage               AS Stage,
		|	UsedMaterials.StageSubdivision AS StageSubdivision,
		|	UsedMaterials.LineNumber        AS LineNumber,
		|	UsedMaterials.Substitutes            AS Substitutes,
		|	UsedMaterials.Count         AS Count
		|INTO UsedMaterials
		|FROM
		|	&UsedMaterials AS UsedMaterials
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UsedMaterials.Products AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Warehouse AS Warehouse,
		|	UsedMaterials.Purpose AS Purpose
		|INTO FilterInventoryAndDemands
		|FROM
		|	UsedMaterials AS UsedMaterials
		|WHERE
		|	UsedMaterials.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	UsedMaterials.Products AS Products,
		|	UsedMaterials.Characteristic AS Characteristic,
		|	UsedMaterials.Warehouse AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
		|FROM
		|	UsedMaterials AS UsedMaterials
		|INDEX BY
		|	Products, Characteristic, Warehouse, Purpose
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	Inventories.InStockBalance AS InStockBalance,
		|	Inventories.LockedInStockBalance AS LockedInStockBalance,
		|	Inventories.OrderedBalance AS OrderedBalance,
		|	Inventories.Received_1Balance AS Received_1Balance,
		|	Inventories.LockedReceiptBalance AS LockedReceiptBalance,
		|	Inventories.ReserveAtWarehouseBalance AS ReserveAtWarehouseBalance,
		|	Inventories.ReserveAsReceivedBalance AS ReserveAsReceivedBalance,
		|	Inventories.SnoozeReservationBalance AS SnoozeReservationBalance,
		|	Inventories.ToSupplyBalance AS ToSupplyBalance,
		|	Inventories.NotProvideBalance AS NotProvideBalance
		|INTO InventoryAndDemandsBalance
		|FROM
		|	AccumulationRegister.InventoryAndDemands.Balance(,
		|		(Products, Characteristic, Warehouse, Purpose) IN(
		|			SELECT
		|				Filter.Products AS Products,
		|				Filter.Characteristic AS Characteristic,
		|				Filter.Warehouse AS Warehouse,
		|				Filter.Purpose AS Purpose
		|			FROM
		|				FilterInventoryAndDemands AS Filter)) AS Inventories
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	UsedMaterials.Products                    AS Products,
		|	UsedMaterials.Characteristic                  AS Characteristic,
		|	UsedMaterials.Warehouse                           AS Warehouse,
		|	UsedMaterials.Purpose                      AS Purpose,
		|	UsedMaterials.WithAssignment                     AS WithAssignment,
		|	UsedMaterials.Stage                            AS Stage,
		|	UsedMaterials.StageSubdivision              AS StageSubdivision,
		|	UsedMaterials.LineNumber                     AS LineNumber,
		|	UsedMaterials.Substitutes                         AS Substitutes,
		|	UsedMaterials.Count                      AS Required2,
		|	ISNULL(Separate_Balance.QuantityForShipAction, 0) AS ProductsInStockToOrder,
		|	ISNULL(AvailableStock.QuantityForShipAction, 0) AS AvailableStock,
		|	CASE
		|		WHEN UsedMaterials.Count - UsedMaterials.Substitutes - ISNULL(Separate_Balance.QuantityForShipAction, 0) - ISNULL(AvailableStock.QuantityForShipAction, 0) < 0 
		|			OR UsedMaterials.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5)
		|			THEN 0
		|		ELSE UsedMaterials.Count - UsedMaterials.Substitutes - ISNULL(Separate_Balance.QuantityForShipAction, 0) - ISNULL(AvailableStock.QuantityForShipAction, 0)
		|	END AS Deficit,
		|	&DataTypeMaterials                       AS DataType
		|FROM
		|	UsedMaterials AS UsedMaterials
		|
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS Separate_Balance
		|		ON UsedMaterials.Purpose <> VALUE(Catalog.Assignments.EmptyRef)
		|			AND UsedMaterials.Products = Separate_Balance.Products
		|			AND UsedMaterials.Characteristic = Separate_Balance.Characteristic
		|			AND UsedMaterials.Warehouse = Separate_Balance.Warehouse
		|			AND UsedMaterials.Purpose = Separate_Balance.Purpose
		|
		|		LEFT JOIN CalculationOfBalancesForSettingActions AS AvailableStock
		|		ON UsedMaterials.Products = AvailableStock.Products
		|			AND UsedMaterials.Characteristic = AvailableStock.Characteristic
		|			AND UsedMaterials.Warehouse = AvailableStock.Warehouse
		|			AND AvailableStock.Purpose = VALUE(Catalog.Assignments.EmptyRef)
		|WHERE
		|	&ConditionProblemPositions");
	
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(Query.Text, TablesNames);
	
	Query.SetParameter("UsedMaterials", UsedMaterials);
	Query.SetParameter("DataTypeMaterials", DataTypeMaterials());
	
	Query.Text = StrReplace(Query.Text, "&ConditionProblemPositions", ?(OnlyProblematicPositions, 
		"UsedMaterials.Products.ItemsType <> VALUE(Enum.ItemsTypes.Work_5)
		|AND UsedMaterials.Count - UsedMaterials.Substitutes - ISNULL(Separate_Balance.QuantityForShipAction, 0) - ISNULL(AvailableStock.QuantityForShipAction, 0) > 0", "True"));
	
	Result.Insert("UsedMaterials", Query.Execute().Unload());
	
	// LaborCosts
	LaborCosts = SpecificationData.LaborCosts;
	LaborCosts.Columns.Add("DataType", New TypeDescription("Number"));
	LaborCosts.Columns.Add("LaborInput", New TypeDescription("Number"));
	
	ActivityKinds = Common.ObjectsAttributesValues(
		LaborCosts.UnloadColumn("WorkKind"),
		"LaborInput, LaborInputMultiplier");
	For Each String In LaborCosts Do
		
		String.DataType = DataTypeLaborCosts();
		
		If ActivityKinds[String.WorkKind].LaborInputMultiplier <> 0 Then
			String.LaborInput = Round(String.Count
				* ActivityKinds[String.WorkKind].LaborInput
				/ ActivityKinds[String.WorkKind].LaborInputMultiplier, 3);
		EndIf;
		
	EndDo;
	
	Result.Insert("LaborCosts", LaborCosts);
	
	// Stages
	Stages = SpecificationData.Stages;
	Stages.Columns.Add("DataType", New TypeDescription("Number"));
	Stages.FillValues(DataTypeStages(), "DataType");
	Result.Insert("Stages", Stages);
	
	Return Result;

EndFunction

Function DataTypeOutputProducts()
	
	Return 1;
	
EndFunction

Function DataTypeByProducts()
	
	Return 2;
	
EndFunction

Function DataTypeMaterials()
	
	Return 3;
	
EndFunction

Function DataTypeLaborCosts()
	
	Return 4;
	
EndFunction

Function DataTypeStages()
	
	Return 5;
	
EndFunction

#EndRegion

#EndIf
