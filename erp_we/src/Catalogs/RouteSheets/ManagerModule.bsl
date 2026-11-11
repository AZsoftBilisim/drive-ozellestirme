#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// StandardSubsystems.ObjectsVersioning

// Defines object settings for the object Versioning subsystem.
//
// Parameters:
//  Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export

EndProcedure

// End StandardSubsystems.ObjectsVersioning

// Returns the names of attributes, which should not appear in the list of details of the processing Gruposeincentivos.
//
//	Returns:
//		Array - an array of the names of the details.
//
Function AttributesToSkipInBatchProcessing() Export
	
	NotAttributesToEdit = New Array;
	NotAttributesToEdit.Add("ManufacturedProducts.Operation");
	NotAttributesToEdit.Add("RecyclableWaste.Operation");
	NotAttributesToEdit.Add("MaterialsAndServices.Operation");
	NotAttributesToEdit.Add("LaborCosts.Operation");
	
	Return NotAttributesToEdit;
	
EndFunction

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Command = BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	If Command <> Undefined Then
		Command.VisibilityInForms = "ItemForm,ListForm,ChoiceForm";
	EndIf;
	
EndProcedure

// The constructor function of a structure to fetch data of the route map.
//
// Returns:
//  Structure - structure with route map data selection parameters.
//
Function ItemData_3() Export
	
	ItemData_3 = New Structure;
	
	ItemData_3.Insert("ReferenceOrder"); // production order
	
	ItemData_3.Insert("LineOfBusiness");
	
	ItemData_3.Insert("Products");
	ItemData_3.Insert("Characteristic");
	
	ItemData_3.Insert("Count", 0); // quantity of the main product
	
	Return ItemData_3;
	
EndFunction

// Returns the data of route map for the nested routes
//
// Parameters:
//  RouteSheet			- CatalogRef.RouteSheets	- Route map to get data from
//  NumberOfResult	- Number								- Number of results on the route map
//  Products			- CatalogRef.Products		- Product
//  Characteristic			- CatalogRef.ItemsCharacteristics	- Product features
//  DataList			- String	- comma-separated lists the data to be received: output Items, Materials, labor Costs, Operations.
//  Nested routes-Boolean-specifies whether nested routes should be included in the result
//
// Returns:
//   Structure - contains route map data: operations, output items, materials, labor costs.
//
Function RouteMapData(RouteSheet, NumberOfResult, Products, Characteristic, Val DataList = "") Export
	
	If DataList <> "" Then
		StructureOfData = New Structure(DataList);
	Else
		StructureOfData = New Structure("ManufacturedProducts,RecyclableWaste,UsedMaterials,LaborCosts,Operations,AuxiliaryWorkCenters");
	EndIf;
	
	If StructureOfData.Property("Operations") Then
		StructureOfData.Insert("Operations", Catalogs.ManufacturingOperations.OperationTableConstructor());
	EndIf;
	
	RelationshipStructure = InitializeLinkStructure();
	AddRouteMapDataRecursively(
				RouteSheet,
				NumberOfResult,
				Products,
				Characteristic,
				RelationshipStructure,
				StructureOfData);
	
	If StructureOfData.Property("Operations") Then
		Catalogs.ManufacturingOperations.FillInOrderOfOperations(StructureOfData.Operations);
	EndIf; 
	
	Return StructureOfData;
	
EndFunction

// Returns the data of the route map with the selection of a given technological operation.
//
// Parameters:
//  Operation			         - CatalogRef.ManufacturingOperations	 - The operation of the route map, the data for which you want to.
//  OperationsCount           - Number									 - the number of operations.
//  RouteSheetFactor   - Number									 - Coefficient of the route map.
//  ItemData_3         - See ItemData_3
// 
// Returns:
//  Structure - contains route map data: operations, output items, materials, labor costs.
//
Function RouteMapOperationData(Operation, OperationsCount, RouteSheetFactor, ItemData_3) Export
	
	TransactionDetails = Common.ObjectAttributesValues(Operation, "Owner, Count");
	
	RouteSheet = TransactionDetails["Owner"];
	
	Query = New Query;
	TableIndexes = New Map;
	
	PrepareRequestTextForFetchingOperationData(Query, TableIndexes);
	
	Query.SetParameter("RouteSheet",            RouteSheet);
	Query.SetParameter("Products",               ItemData_3.Products);
	Query.SetParameter("Characteristic",             ItemData_3.Characteristic);
	Query.SetParameter("LineOfBusiness",    ItemData_3.LineOfBusiness);
	Query.SetParameter("NumberOfResult",       RouteSheetFactor);
	Query.SetParameter("OperationParent",           Undefined);
	Query.SetParameter("ParentCommunicationKey",          Undefined);
	Query.SetParameter("LinkKeyNestedRoute",  Undefined);
	Query.SetParameter("UseParameterization", GetFunctionalOption("UseBillOfMaterialsParameterization"));
	Query.SetParameter("Operation",                   Operation);
	Query.SetParameter("CurOperationCoefficient", OperationsCount / (TransactionDetails["Count"] * RouteSheetFactor));
	
	QueryResult = Query.ExecuteBatch();
	
	StructureOfData = New Structure;
	Filter = New Structure("Operation", Operation);
	
	For Each KeyAndValue In TableIndexes Do
		
		Table = QueryResult[KeyAndValue.Value].Unload();
		
		StructureOfData.Insert(KeyAndValue.Key, Table);
		
	EndDo;
	
	If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		
		AutoSelectionParameters = ProductDataManagement.GetAutoSelectionParameters(
			RouteSheet,
			ItemData_3);
		
		For Each TableName In StrSplit("ManufacturedProducts,RecyclableWaste,UsedMaterials", ",") Do
			
			If StructureOfData.Property(TableName, Table) Then
				ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(
						Table,
						AutoSelectionParameters);
			EndIf;
			
		EndDo;
		
		CalculationParametersBasedOnFormulas = GetCalculationParametersUsingFormulas(
			RouteSheet,
			OperationsCount,
			ItemData_3);
		
		ProcessCalculationOfQuantityByFormulas(CalculationParametersBasedOnFormulas, StructureOfData);
	
	EndIf;
	
	For Each KeyAndValue In StructureOfData Do
		
		StructureOfData.Insert(KeyAndValue.Key, KeyAndValue.Value.Copy(Filter));
		
	EndDo;
	
	UnpackCompositionOfSets(StructureOfData);
	
	If StructureOfData.Operations.Count() > 0 Then
		For Each Column In StructureOfData.Operations.Columns Do
			StructureOfData.Insert(Column.Name, StructureOfData.Operations[0][Column.Name]);
		EndDo;
	Else
		For Each Column In StructureOfData.Operations.Columns Do
			StructureOfData.Insert(Column.Name, Column.ValueType.AdjustValue(0));
		EndDo;
	EndIf;
	
	Return StructureOfData;
	
EndFunction


// Checks the sequence of operations
//
// Parameters:
//  RouteSheet		- CatalogRef.RouteSheets - route map whose operations need to be checked
//  Cancel				- Boolean - indicates whether the current action is canceled.
//
// Returns:
//   Boolean   - true if the sequence of operations is correct.
//
Function SequenceOfOperationsIsCorrect(RouteSheet, Cancel = False) Export
	
	TheStructureOfTheMessages = ProductionProcessEditor.StructureOfOperationSequenceChecks();
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("NameOfOperationsCatalog",     "ManufacturingOperations");
	ParametersStructure.Insert("OperationNumberField",          "OperationNumber");
	ParametersStructure.Insert("NextOperationNumberField", "NextOperation");
	
	SequenceIsCorrect = ProductionProcessEditor.SequenceOfOperationsIsCorrect(
		RouteSheet, ParametersStructure, TheStructureOfTheMessages, Cancel);
	
	Return SequenceIsCorrect;
	
EndFunction

// Fills in a route map using another route map
//
// Parameters:
//  Receiver - CatalogObject.RouteSheets, FormDataStructure - route map
//		to copy operations to.
//  Source - CatalogRef.RouteSheets - the route map whose operations you want to copy.
//	ReceiverLink_ - CatalogRef.RouteSheets - link to the route map to fill in.
//
// Returns:
//   Boolean   - true if the copy is successful.
//
Function FillInFromOperationsSheet(Receiver, Source, ReceiverLink_) Export

	SourceObject_ = Source.GetObject();
	If Receiver.UseFinishedProducts Then
		Receiver.ManufacturedProducts.Load(SourceObject_.ManufacturedProducts.Unload());
		Receiver.RecyclableWaste.Load(SourceObject_.RecyclableWaste.Unload());
	EndIf;
	If Receiver.UseMaterials Then
		Receiver.MaterialsAndServices.Load(SourceObject_.MaterialsAndServices.Unload());
	EndIf; 
	If Receiver.UseLaborCosts Then
		Receiver.LaborCosts.Load(SourceObject_.LaborCosts.Unload());
	EndIf; 
	
	If Receiver.UseOperations Then
		
		Query = New Query(
		"SELECT
		|	CatalogManufacturingOperations.Ref AS Ref
		|FROM
		|	Catalog.ManufacturingOperations AS CatalogManufacturingOperations
		|WHERE
		|	CatalogManufacturingOperations.Owner = &Source
		|	AND NOT CatalogManufacturingOperations.DeletionMark");
		Query.SetParameter("Source", Source);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		While Selection.Next() Do
			
			LinkToOperation = Catalogs.ManufacturingOperations.CopyProcessOperation(Selection.Ref, ReceiverLink_);
			If Not ValueIsFilled(LinkToOperation) Then
				Return False;
			EndIf;
			
			// Fill in the link with the operation
			If Receiver.UseFinishedProducts Then
				FoundRows = Receiver.ManufacturedProducts.FindRows(New Structure("OperationEdit", Selection.Ref));
				For Each RowData In FoundRows Do
					RowData.OperationEdit = LinkToOperation;
				EndDo;
				FoundRows = Receiver.RecyclableWaste.FindRows(New Structure("OperationEdit", Selection.Ref));
				For Each RowData In FoundRows Do
					RowData.OperationEdit = LinkToOperation;
				EndDo;
			EndIf; 
			If Receiver.UseMaterials Then
				FoundRows = Receiver.MaterialsAndServices.FindRows(New Structure("OperationEdit", Selection.Ref));
				For Each RowData In FoundRows Do
					RowData.OperationEdit = LinkToOperation;
				EndDo;
			EndIf; 
			If Receiver.UseLaborCosts Then
				FoundRows = Receiver.LaborCosts.FindRows(New Structure("OperationEdit", Selection.Ref));
				For Each RowData In FoundRows Do
					RowData.OperationEdit = LinkToOperation;
				EndDo;
			EndIf; 
			
		EndDo;
	Else
		For Each RowData In Receiver.ManufacturedProducts Do
			RowData.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			RowData.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
		EndDo;
		For Each RowData In Receiver.RecyclableWaste Do
			RowData.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			RowData.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
		EndDo;
		For Each RowData In Receiver.MaterialsAndServices Do
			RowData.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			RowData.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
		EndDo;
		For Each RowData In Receiver.LaborCosts Do
			RowData.Operation = Catalogs.ManufacturingOperations.EmptyRef();
			RowData.OperationEdit = Catalogs.ManufacturingOperations.EmptyRef();
		EndDo;
	EndIf;
	
	Return True;
	
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed.
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export

	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.ProductionStages AS SearchTable
	|WHERE
	|	SearchTable.RouteSheet = &Object
	|
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2 AS SearchTable
	|WHERE
	|	SearchTable.RouteSheet = &Object
	|";
	
	Query.SetParameter("Object", Parameters.Object);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	ThereAreRefs = Not Result.IsEmpty();
	
	PutToTempStorage(ThereAreRefs, StorageAddress);

EndProcedure

// Calculates the coefficient of application of the route map in the resource specification.
//
// Parameters:
//  MainProductSpecificationData - Structure - data for the main output item in the resource specification.
//  RouteSheet - CatalogRef.RouteSheets - route map for calculating the coefficient.
// 
// Returns:
//  Number - the calculated coefficient.
//
Function RouteMapCoefficientForSpecification(MainProductSpecificationData, RouteSheet) Export
	
	MKData = Common.ObjectAttributesValues(
		RouteSheet, "NumeratorFactor, FactorDenominator");
	
	If ValueIsFilled(MKData.FactorDenominator) Then
		
		Result = MKData.NumeratorFactor/MKData.FactorDenominator
			* MainProductSpecificationData.Count;
		
	Else
		
		Result = 0;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Creates a copy of the route map with all technological operations.
//
// Parameters:
//  Source - CatalogRef.RouteSheets - the route map you want to copy.
// 
// Returns:
//  CatalogRef.RouteSheets - link to the created route map.
//
Function CopyRouteMapWithOperations(Source) Export
	
	Ref = Undefined;
	
	BeginTransaction();
	
	Try
		
		Ref = Catalogs.RouteSheets.GetRef();
		
		Object = Source.Copy();
		Object.Description = Object.Description + " " + NStr("vi = '(bản sao)';
															|ru = '(копия)';
															|en = '(copy)'; fa = '(copy)';
															|it = '(copia)';
															|pl = '(copy)';
															|tr = '(kopya)'");
		
		If Not FillInFromOperationsSheet(Object, Source, Ref) Then
			Raise NStr("vi = 'Không thể sao chép bản đồ lộ trình.';
						|ru = 'Не удалось скопировать маршрутную карту.';
						|en = 'Cannot copy the route sheet.'; fa = 'Cannot copy the route sheet.';
						|it = 'Non è stato possibile copiare la scheda di lavorazione.';
						|pl = 'Kopiowanie karty technologicznej nie powiodło się.';
						|tr = 'Rota kopyalanamadı.'");
		EndIf;
		
		ProductDataManagement.UpdateObjectLinkKeys(Object);
		
		Object.SetNewObjectRef(Ref);
		Object.Write();
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
 		WriteLogEvent(
			NStr("vi = 'Sao chép bản đồ lộ trình';
				|ru = 'Копирование маршрутной карты';
				|en = 'Copy route sheet'; fa = 'Copy route sheet';
				|it = 'Riproduzione scheda di lavorazione';
				|pl = 'Kopiowanie karty technologicznej';
				|tr = 'Rotanın kopyalanması'", CommonClientServer.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			DetailErrorDescription(ErrorInfo()));
			
		Raise;
		
	EndTry;
	
	Return Ref;
	
EndFunction

// Returns the values of the route map details
// 
// Parameters:
// 	RouteSheet - CatalogRef.RouteSheets
// Returns:
// 	Structure - See StructureOfRouteCardDetails()
Function RouteCardDetailsValues(RouteSheet) Export
	
	RouteSheets = New Array;
	RouteSheets.Add(RouteSheet);
	Result = ValuesOfRouteMapDetails(RouteSheets);
	Return Result[RouteSheet];
	
EndFunction

Function ValuesOfRouteMapDetails(RouteSheets) Export
	
	QueryText = "
	|SELECT
	|	RouteSheets.Ref                                    AS Ref,
	|	RouteSheets.Description                              AS Description,
	|	RouteSheets.Status                                    AS Status,
	|	RouteSheets.ValidOnDate                            AS ValidOnDate,
	|	RouteSheets.ValidToDate                             AS ValidToDate,
	|	RouteSheets.MaximumNumberOfProductUnitsLots AS MaximumNumberOfProductUnitsLots,
	|	RouteSheets.CalculateFactor                   AS CalculateFactor
	|FROM
	|	Catalog.RouteSheets AS RouteSheets
	|WHERE
	|	RouteSheets.Ref IN (&RouteSheets)";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("RouteSheets", RouteSheets);
	
	Result = New Map();
	
	For Each Ref In RouteSheets Do
		Result.Insert(Ref, StructureOfRouteCardDetails());
	EndDo;
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		FillPropertyValues(Result[Selection.Ref], Selection);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Returns the structure of the route map details.
//
// Returns:
//  Structure - Contains:
//   * MaximumNumberOfProductUnitsLots - Number
//   * CalculateFactor - Boolean
Function StructureOfRouteCardDetails()
	
	Result = New Structure;
	
	Result.Insert("Ref", Catalogs.RouteSheets.EmptyRef());
	Result.Insert("Description", "");
	Result.Insert("Status", Enums.StatusesOfRouteSheets.EmptyRef());
	Result.Insert("ValidOnDate", Date(1,1,1));
	Result.Insert("ValidToDate", Date(1,1,1));
	Result.Insert("MaximumNumberOfProductUnitsLots", 0);
	Result.Insert("CalculateFactor", False);
	
	Return Result;
	
EndFunction

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductDataManagementServerCall.RouteMapsProcessingSelectionDataAcquisition(
				ChoiceData, 
				Parameters, 
				StandardProcessing);
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	If FormType = "ChoiceForm" And Parameters.Property("SelectValidRouteSheets") Then
		SelectedForm = "SelectValidRouteSheets";
		StandardProcessing = False;
	EndIf; 
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

#EndRegion

#Region CalculationByFormulas

#Region DataForCalculation

Function DataForCalculationByFormulas(DataSet, CalculationParametersBasedOnFormulas, Cached_Values = Undefined)
	
	Var DataForCalculation;
	
	DescriptionOfSources = DescriptionOfOperandDataSources();
	
#Region ParametersForCalculation
	ParametersForCalculation = ProductDataManagement.ParametersForCalculationByFormulas(DescriptionOfSources, DataSet);
	If Not ValueIsFilled(ParametersForCalculation) Then
		Return DataForCalculation;
	EndIf;
#EndRegion

#Region RouteMapData
	ListOfData = New Array;
	StructureOfData = New Structure("ManufacturedProducts,RecyclableWaste,MaterialsAndServices");
	
	If ParametersForCalculation.Find("MainProduct", "Key") <> Undefined
		Or ParametersForCalculation.Find("ManufacturedProducts", "Key") <> Undefined Then
		ThereAreOutputProducts = Cached_Values <> Undefined 
			And Cached_Values.Property("ManufacturedProducts", StructureOfData.ManufacturedProducts);
		If Not ThereAreOutputProducts Then
			ListOfData.Add("ManufacturedProducts");
		EndIf;
	EndIf;
	
	If ParametersForCalculation.Find("MaterialsAndServices", "Key") <> Undefined Then
		ThereAreMaterialsAndServices = Cached_Values <> Undefined
			And Cached_Values.Property("UsedMaterials", StructureOfData.MaterialsAndServices);
		If Not ThereAreMaterialsAndServices Then
			ListOfData.Add("UsedMaterials");
		EndIf;
	EndIf;
	
	If ParametersForCalculation.Find("RecyclableWaste", "Key") <> Undefined Then
		ThereIsReturnableWaste = Cached_Values <> Undefined
			And Cached_Values.Property("RecyclableWaste", StructureOfData.RecyclableWaste);
		If Not ThereIsReturnableWaste Then
			ListOfData.Add("RecyclableWaste");
		EndIf;
	EndIf;
	
	If ListOfData.UBound() <> -1 Then
		
		DataList = StrConcat(ListOfData, ",");
		RouteMapData = RouteMapData(
									CalculationParametersBasedOnFormulas.BillOfMaterials,
									CalculationParametersBasedOnFormulas.Count,
									CalculationParametersBasedOnFormulas.Products,
									CalculationParametersBasedOnFormulas.Characteristic,
									DataList);
			
		If RouteMapData.Property("ManufacturedProducts") Then
			StructureOfData.ManufacturedProducts = RouteMapData.ManufacturedProducts;
		EndIf;
		If RouteMapData.Property("UsedMaterials") Then
			StructureOfData.MaterialsAndServices = RouteMapData.UsedMaterials;
		EndIf;
		If RouteMapData.Property("RecyclableWaste") Then
			StructureOfData.RecyclableWaste = RouteMapData.RecyclableWaste;
		EndIf;
		
	EndIf;
#EndRegion

#Region DataSources
	DataSources = StructureOfSourcesForCalculationByFormulas();
	
	DataSources.CalculationParametersBasedOnFormulas = CalculationParametersBasedOnFormulas;
	
	For Each KeyAndValue In StructureOfData Do
		If ValueIsFilled(KeyAndValue.Value) Then
			SourceTable2 = DataSources[KeyAndValue.Key]; // See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
			For Each String In StructureOfData[KeyAndValue.Key] Do
				FillPropertyValues(SourceTable2.Add(), String);
			EndDo;
		EndIf;
	EndDo;
#EndRegion

	PrepareParametersForCalculationUsingFormulas(ParametersForCalculation, DescriptionOfSources, DataSources);
	
	DataForCalculation = ProductDataManagement.DataForCalculationByFormulas(Catalogs.RouteSheets, ParametersForCalculation, DescriptionOfSources, DataSources);
	Return DataForCalculation;
	
EndFunction

Function UploadDataForFormulaConstructor(Object, TSName, RowData = Undefined) Export
	
	DescriptionOfSources = Catalogs.RouteSheets.DescriptionOfOperandDataSources(Object);
	
	If TSName = "ManufacturedProducts" Then
		DescriptionOfSources.Delete("MaterialsAndServices");
		DescriptionOfSources.Delete("Material");
	ElsIf TSName = "MaterialsAndServices" Then
		DescriptionOfSources.Delete("RecyclableWaste");
		DescriptionOfSources.Delete("ReturnWaste");
	EndIf;
	DescriptionOfSources["MainProduct"].SourceOfProductProperties = Object.ForFinishedProductsKind;
	
	ProductDataManagement.SupplementDescriptionOfSourcesWithCompositionOfOperands(
		DescriptionOfSources, Object, TSName, RowData);
	
	Return DescriptionOfSources;
	
EndFunction

#EndRegion

#Region DataSources

// Constructor of the source structure for calculation using formulas
// 
// Returns:
// 	Structure - From:
// * CalculationParametersBasedOnFormulas - See GetCalculationParametersUsingFormulas
// * MaterialsAndServices - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
// * RecyclableWaste - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
// * ManufacturedProducts - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
//
Function StructureOfSourcesForCalculationByFormulas() Export
	
	DataSources = New Structure;
	
	DataSources.Insert("CalculationParametersBasedOnFormulas");
	
	DataSources.Insert("ManufacturedProducts", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	DataSources.Insert("RecyclableWaste", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	DataSources.Insert("MaterialsAndServices", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	
	Return DataSources;
	
EndFunction

Function DescriptionOfOperandDataSources(Object = Undefined) Export
	
	Settings = ProductionServerCached.SubsystemSettingsProduction();
	TypeDescriptionNumber = New TypeDescription("Number");
	
	Result = New Structure;
	
	// [Operation]
	If Settings.ProductionIsUsed22 And Not Settings.ProductionIsUsed21 Then
		
		SourcePresentation = NStr("vi = 'Giao dịch';
									|ru = 'Операция';
									|en = 'Operation'; fa = 'عملیات';
									|it = 'Operazione';
									|pl = 'Typ operacji';
									|tr = 'İşlem'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"Operation", SourcePresentation);
		
		SourcePresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
			"OperationsCount", TypeDescriptionNumber, SourcePresentation);
		LongDesc.Attributes.Add(NewAttribute);
		
		Result.Insert("Operation", LongDesc);
		
	EndIf;
	
	// [MainProduct]
	SourcePresentation = NStr("vi = 'Sản phẩm chính';
								|ru = 'Основное изделие';
								|en = 'Main product'; fa = 'محصول اصلی';
								|it = 'Prodotto principale';
								|pl = 'Wyrób podstawowy';
								|tr = 'Nihai ana ürün'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"MainProduct", SourcePresentation);
	
	SourcePresentation = NStr("vi = 'Số lượng';
								|ru = 'Количество';
								|en = 'Quantity'; fa = 'مقدار';
								|it = 'Quantità';
								|pl = 'Ilość';
								|tr = 'Miktar'");
	NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
		"Count", TypeDescriptionNumber, SourcePresentation);
	LongDesc.Attributes.Add(NewAttribute);
	
	LongDesc.ContainsProductProperties = True;
	
	Result.Insert("MainProduct", LongDesc);
	
	// [ManufacturedProducts]
	If Object = Undefined
		Or Object.UseFinishedProducts Then
		
		SourcePresentation = NStr("vi = 'Sản phẩm đầu ra';
									|ru = 'Выходные изделия';
									|en = 'Finished products'; fa = 'Finished products';
									|it = 'Prodotti finiti';
									|pl = 'Wyroby wychodzące';
									|tr = 'Üretilen nihai ürünler'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"ManufacturedProducts", SourcePresentation);
		
		SourcePresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
			"Count", TypeDescriptionNumber, SourcePresentation);
		LongDesc.Attributes.Add(NewAttribute);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.Collection                    = True;
		
		Result.Insert("ManufacturedProducts", LongDesc);
		
		SourcePresentation = NStr("vi = 'Sản phẩm đầu ra (dòng hiện tại)';
									|ru = 'Выходное изделие (текущая строка)';
									|en = 'Finished product (current line)'; fa = 'Finished product (current line)';
									|it = 'Prodotto di output (riga corrente)';
									|pl = 'Wyrób wychodzący (bieżący wiersz)';
									|tr = 'Üretilen nihai ürün (mevcut satır)'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"FinishedProduct", SourcePresentation);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.TSName = "ManufacturedProducts";
		
		Result.Insert("FinishedProduct", LongDesc);
		
		SourcePresentation = NStr("vi = 'Xuất xưởng sản phẩm phụ';
									|ru = 'Побочный выход';
									|en = 'By-product'; fa = 'محصول فرعی';
									|it = 'Produzione collaterale';
									|pl = 'Produkcja poboczna';
									|tr = 'Yan ürün çıkışı'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"RecyclableWaste", SourcePresentation);
		
		SourcePresentation = SourcePresentation;
		NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
			"Count", TypeDescriptionNumber, SourcePresentation);
		LongDesc.Attributes.Add(NewAttribute);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.Collection                    = True;
		
		Result.Insert("RecyclableWaste", LongDesc);
		
		SourcePresentation = NStr("vi = 'Xuất xưởng sản phẩm phụ (dòng hiện tại)';
									|ru = 'Побочный выход (текущая строка)';
									|en = 'By-product (current line)'; fa = 'By-product (current line)';
									|it = 'Scarto di recupero (riga corrente)';
									|pl = 'Produkcja poboczna (bieżący wiersz)';
									|tr = 'Yan ürün çıkışı (mevcut satır)'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"ReturnWaste", SourcePresentation);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.TSName = "RecyclableWaste";
		
		Result.Insert("ReturnWaste", LongDesc);
		
	EndIf;
	
	// [Materials and services],[Material]
	If Object = Undefined
		Or Object.UseMaterials Then
		
		SourcePresentation = NStr("vi = 'Nguyên vật liệu và nhân công';
									|ru = 'Материалы и работы';
									|en = 'Materials and works'; fa = 'Materials and works';
									|it = 'Materiali e lavori';
									|pl = 'Materiały i prace';
									|tr = 'Malzemeler ve işler'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"MaterialsAndServices", SourcePresentation);
		
		SourcePresentation = NStr("vi = 'Số lượng';
									|ru = 'Количество';
									|en = 'Quantity'; fa = 'مقدار';
									|it = 'Quantità';
									|pl = 'Ilość';
									|tr = 'Miktar'");
		NewAttribute = ProductDataManagement.CreateDescriptionsOfOperandDataSourceProps(
			"Count", TypeDescriptionNumber, SourcePresentation);
		LongDesc.Attributes.Add(NewAttribute);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.Collection                    = True;
		
		Result.Insert("MaterialsAndServices", LongDesc);
		
		SourcePresentation = NStr("vi = 'Nguyên vật liệu (dòng hiện tại)';
									|ru = 'Материал (текущая строка)';
									|en = 'Material (current line)'; fa = 'Material (current line)';
									|it = 'Materiale (riga corrente)';
									|pl = 'Materiał (wiersz bieżący)';
									|tr = 'Malzeme (mevcut satır)'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"Material", SourcePresentation);
		
		LongDesc.ContainsProductProperties = True;
		LongDesc.TSName = "MaterialsAndServices";
		
		Result.Insert("Material", LongDesc);
		
	EndIf;
	
	// [Department]
	SourcePresentation = NStr("vi = 'Bộ phận';
								|ru = 'Подразделение';
								|en = 'Business unit'; fa = 'Business unit';
								|it = 'Reparto';
								|pl = 'Dział';
								|tr = 'Departman'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"Department", SourcePresentation);
	
	LongDesc.ContainsProperties = True;
	LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_BusinessStructure");
	
	Result.Insert("Department", LongDesc);
	
	// [ReferenceOrder]
	If Settings.ProductionIsUsed22 And Not Settings.ProductionIsUsed21 Then
		
		SourcePresentation = NStr("vi = 'Đơn hàng sản xuất';
									|ru = 'Заказ на производство';
									|en = 'Production order'; fa = 'سفارش تولید';
									|it = 'Ordine di produzione';
									|pl = 'Zlecenie produkcyjne';
									|tr = 'Üretim emri'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"ReferenceOrder", SourcePresentation);
		
		LongDesc.ContainsProperties = True;
		LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Document_ProductionOrder2_2");
		
		Result.Insert("ReferenceOrder", LongDesc);
		
	EndIf;
	
	// [LineOfBusiness]
	If GetFunctionalOption("GenerateFinancialResult") Then
		SourcePresentation = NStr("vi = 'Lĩnh vực hoạt động';
									|ru = 'Направление деятельности';
									|en = 'Line of business'; fa = 'خط کسب‌وکار';
									|it = 'Settore di attività';
									|pl = 'Rodzaj działalności';
									|tr = 'İş kolu'");
		LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
			"LineOfBusiness", SourcePresentation);
		
		LongDesc.ContainsProperties = True;
		LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_LinesOfBusiness");
		
		Result.Insert("LineOfBusiness", LongDesc);
		
	EndIf;
	
	Return Result;
	
EndFunction

// Constructor of the data source for calculation using formulas
// 
// Parameters:
// 	DataPath - See ProductDataManagement.ParametersForCalculationByFormulas
// 	DataSources - See StructureOfSourcesForCalculationByFormulas
// Returns:
// 	See ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas
//
Function DataSourceForFormulaCalculations(DataPath, DataSources) Export
	
	Source = Undefined;
	
	If DataPath.Key = "Operation" Then
		
		Source = New Structure("OperationsCount", DataPath.RowData.OperationsCount);
		
	ElsIf DataPath.Key = "MainProduct" Then
		
		Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
		FillPropertyValues(Source, DataSources.CalculationParametersBasedOnFormulas);
		
	ElsIf DataPath.Key = "ManufacturedProducts"
		Or DataPath.Key = "RecyclableWaste"
		Or DataPath.Key = "MaterialsAndServices" Then
		
		RowData = DataSources[DataPath.Key].Find(DataPath.LineNumber, "LineNumber");
		
		If RowData <> Undefined Then
			Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
			FillPropertyValues(Source, RowData);
		EndIf;
		
	ElsIf DataPath.Key = "FinishedProduct"
		Or DataPath.Key = "ReturnWaste"
		Or DataPath.Key = "Material" Then
		
		Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
		FillPropertyValues(Source, DataPath.RowData);
		
	Else
		
		Structure = New Structure(DataPath.Key);
		
		If DataPath.Key = "Department" Then
			
			FillPropertyValues(Structure, DataPath.RowData);
			
		ElsIf DataPath.Key = "ReferenceOrder"
			Or DataPath.Key = "LineOfBusiness" Then
			
			FillPropertyValues(Structure, DataSources.CalculationParametersBasedOnFormulas);
			
		EndIf;
		Source = Structure[DataPath.Key];
		
	EndIf;
	
	Return Source;
	
EndFunction

#EndRegion

#Region Other

Procedure PrepareParametersForCalculationUsingFormulas(ParametersForCalculation, DescriptionOfSources, DataSources)
	
	SourcesOfParameterValues = ProductDataManagement.CreateTableOfSourcesOfParameterValuesForCalculationByFormulas();
	
	ProductDataManagement.SupplementTableOfSourcesOfParameterValuesForCalculationByFormulas(
		Catalogs.RouteSheets,
		SourcesOfParameterValues,
		DataSources,
		DescriptionOfSources,
		ParametersForCalculation);
		
	ProductDataManagement.FillInParameterValuesForCalculationByFormulas(SourcesOfParameterValues);
	
EndProcedure

Procedure ProcessCalculationOfQuantityByFormulas(CalculationParametersBasedOnFormulas, RouteMapData, UseRouteMapData = True)
	
	DataSet = New Array;
	
	ProductDataManagement.AddTableForCalculationByFormulas(DataSet, RouteMapData, "ManufacturedProducts");
	ProductDataManagement.AddTableForCalculationByFormulas(DataSet, RouteMapData, "UsedMaterials");
	ProductDataManagement.AddTableForCalculationByFormulas(DataSet, RouteMapData, "RecyclableWaste");
	ProductDataManagement.AddTableForCalculationByFormulas(DataSet, RouteMapData, "LaborCosts");
	
	If UseRouteMapData Then
		DataForCalculation = DataForCalculationByFormulas(DataSet, CalculationParametersBasedOnFormulas, RouteMapData);
	Else
		DataForCalculation = DataForCalculationByFormulas(DataSet, CalculationParametersBasedOnFormulas);
	EndIf;
	
	ProductDataManagement.CalculateNumberInRows(RouteMapData, "ManufacturedProducts",  True, DataForCalculation);
	ProductDataManagement.CalculateNumberInRows(RouteMapData, "UsedMaterials",        True, DataForCalculation);
	ProductDataManagement.CalculateNumberInRows(RouteMapData, "RecyclableWaste", True, DataForCalculation);
	ProductDataManagement.CalculateNumberInRows(RouteMapData, "LaborCosts",     False,   DataForCalculation);
	
EndProcedure

#EndRegion

#EndRegion

#Region OperationsSheetList

Function RequestTextForDynamicListOfRouteMaps() Export
	
	QueryText =
	"SELECT
	|	CatalogRouteSheets.Ref         AS Ref,
	|	CatalogRouteSheets.Status         AS Status,
	|
	|	CatalogRouteSheets.Code            AS Code,
	|	CatalogRouteSheets.Description   AS Description,
	|
	|	CatalogRouteSheets.ValidOnDate AS ValidOnDate,
	|	CatalogRouteSheets.ValidToDate  AS ValidToDate,
	|
	|	CatalogRouteSheets.Department  AS Department,
	|	CatalogRouteSheets.EmployeeResponsible  AS EmployeeResponsible,
	|
	|	CatalogRouteSheets.LongDesc       AS LongDesc
	|FROM
	|	Catalog.RouteSheets AS CatalogRouteSheets
	|";

	Return QueryText;
	
EndFunction

// Sets the conditional layout of the list of route maps
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional list design
Procedure SetConditionalAppearanceOfRouteMapList(ConditionalAppearance) Export
	
	// Route map design in development
	Item = ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfRouteSheets.UnderDevelopment;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Registration of a closed route map
	Item = ConditionalAppearance.Items.Add();
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.StatusesOfRouteSheets.Closed_;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure

#EndRegion

#Region Other

Function InitializeLinkStructure()
	
	RelationshipStructure = New Structure;
	RelationshipStructure.Insert("OperationParent", Undefined);
	RelationshipStructure.Insert("ParentCommunicationKey", Undefined);
	RelationshipStructure.Insert("LinkKeyNestedRoute", Undefined);
	RelationshipStructure.Insert("Level", 0);
	
	Return RelationshipStructure;
	
EndFunction

Function GetDataOnProducts(Products, Characteristic, RouteMapData)
	
	ItemData_3 = ItemData_3();
	
	ItemData_3.Products = Products;
	ItemData_3.Characteristic = Characteristic;
	
	If RouteMapData.Property("ManufacturedProducts")
		And ValueIsFilled(RouteMapData.ManufacturedProducts) Then
		
		Filter = New Structure("Products,Characteristic", Products, Characteristic);
		StringsList = RouteMapData.ManufacturedProducts.FindRows(Filter);
		
		If StringsList.Count() > 0 Then
			ItemData_3.Count = StringsList[0].Count;
		EndIf;
		
	EndIf;
	
	Return ItemData_3;
	
EndFunction

// Function-constructor of calculation parameters based on formulas
//
// Returns:
//  Structure - structure with calculation parameters according to formulas
//
Function GetCalculationParametersUsingFormulas(RouteSheet, NumberOfResult, ItemData_3)
	
	Result = ItemData_3();
	
	FillPropertyValues(Result, ItemData_3);
	
	Result.Insert("BillOfMaterials", RouteSheet);
	Result.Insert("OperationsCount", NumberOfResult);
	
	Return Result;
	
EndFunction

Procedure AddRouteMapDataRecursively(RouteSheet, NumberOfResult, Products, Characteristic, RelationshipStructure, StructureOfData)
	
	IndexOf = 0;
	QueryTexts = New Array;
	TableIndexes = New Map;
	
	If StructureOfData.Property("ManufacturedProducts")
		Or StructureOfData.Property("RecyclableWaste")
		Or StructureOfData.Property("UsedMaterials")
		Or StructureOfData.Property("LaborCosts")
	Then
		QueryTexts.Add(QueryTextSelectionByProperties());
		IndexOf = IndexOf + 2;
	EndIf;
	
	If StructureOfData.Property("ManufacturedProducts") Then
		
		QueryText = RequestTextRouteMapOutputItems();
		AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "ManufacturedProducts");
		
	EndIf; 

	If StructureOfData.Property("RecyclableWaste") Then
		
		QueryText = RequestTextReturnRouteMapData();
		AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "RecyclableWaste");
		
	EndIf;
	
	// We always get operations to bypass nested route maps
	QueryText = TextOfRouteMapOperationRequest(False);
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "Operations");
	
	If StructureOfData.Property("UsedMaterials") Then
		
		QueryText = RequestTextRouteMapMaterials();
		AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "UsedMaterials");
		
	EndIf;
	
	If StructureOfData.Property("LaborCosts") Then
		
		QueryText = RequestTextRouteMapLaborCosts();
		AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "LaborCosts");
		
	EndIf;
	
	If StructureOfData.Property("AuxiliaryWorkCenters") Then
		
		QueryText = RequestTextForRouteMapRC();
		AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "AuxiliaryWorkCenters");
		
	EndIf;
	
	Query = New Query;
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("RouteSheet",         RouteSheet);
	Query.SetParameter("Products",            Products);
	Query.SetParameter("Characteristic",          Characteristic);
	Query.SetParameter("LineOfBusiness", Undefined); 
	Query.SetParameter("NumberOfResult",    NumberOfResult);
	Query.SetParameter("OperationParent",        RelationshipStructure.OperationParent);
	Query.SetParameter("ParentCommunicationKey",       RelationshipStructure.ParentCommunicationKey);
	Query.SetParameter("LinkKeyNestedRoute", RelationshipStructure.LinkKeyNestedRoute);
	Query.SetParameter("UseParameterization", 
		GetFunctionalOption("UseBillOfMaterialsParameterization"));
	
	QueryResult = Query.ExecuteBatch();
	
	RouteMapData = New Structure;
	If StructureOfData.Property("ManufacturedProducts") Then
		OutputProductTable  = QueryResult[TableIndexes.Get("ManufacturedProducts")].Unload(); // ValueTable
		OutputProductTable.Columns.Add("OperationLinkKey", New TypeDescription("UUID"));
		RouteMapData.Insert("ManufacturedProducts", OutputProductTable);
	EndIf;
	If StructureOfData.Property("RecyclableWaste") Then
		TableReturnableWaste = QueryResult[TableIndexes.Get("RecyclableWaste")].Unload(); // ValueTable
		TableReturnableWaste.Columns.Add("OperationLinkKey", New TypeDescription("UUID"));
		RouteMapData.Insert("RecyclableWaste", TableReturnableWaste);
	EndIf;
	If StructureOfData.Property("UsedMaterials") Then
		TableMaterialsAndServices = QueryResult[TableIndexes.Get("UsedMaterials")].Unload(); // ValueTable
		TableMaterialsAndServices.Columns.Add("OperationLinkKey", New TypeDescription("UUID"));
		RouteMapData.Insert("UsedMaterials", TableMaterialsAndServices);
	EndIf;
	If StructureOfData.Property("LaborCosts") Then
		TableLaborCosts = QueryResult[TableIndexes.Get("LaborCosts")].Unload(); // ValueTable
		TableLaborCosts.Columns.Add("OperationLinkKey", New TypeDescription("UUID"));
		RouteMapData.Insert("LaborCosts", TableLaborCosts);
	EndIf;
	If StructureOfData.Property("AuxiliaryWorkCenters") Then
		TableAuxiliaryWorkCentres = QueryResult[TableIndexes.Get("AuxiliaryWorkCenters")].Unload(); // ValueTable
		TableAuxiliaryWorkCentres.Columns.Add("OperationLinkKey", New TypeDescription("UUID"));
		RouteMapData.Insert("AuxiliaryWorkCenters", TableAuxiliaryWorkCentres);
	EndIf;
	
	TableOfNestedRoutes = New ValueTable;
	TableOfNestedRoutes.Columns.Add("NestedRoute");
	TableOfNestedRoutes.Columns.Add("Operation");
	TableOfNestedRoutes.Columns.Add("ConnectionKey");
	
	SelectionOfOperations = QueryResult[TableIndexes.Get("Operations")].Select(); // CatalogSelection.ManufacturingOperations
	IDLength = Catalogs.ManufacturingOperations.LengthOfOperationID();
	While SelectionOfOperations.Next() Do
		
		// Add the received operations
		If StructureOfData.Property("Operations") Then
			
			LineOperation = StructureOfData.Operations.Add();
			FillPropertyValues(LineOperation, SelectionOfOperations);
			
			LineOperation.ConnectionKey = New UUID;
			
			FilterParent = New Structure("ConnectionKey", SelectionOfOperations.ParentCommunicationKey);
			FoundRows = StructureOfData.Operations.FindRows(FilterParent);
			If FoundRows.UBound() <> -1 Then
				LineOperation.OperationID = FoundRows[0].OperationID * Pow(10, IDLength);
			EndIf;
			LineOperation.OperationID = LineOperation.OperationID + SelectionOfOperations.Id;
			
			ProductionAccountingClientServer.CalculateTotalOperationTime(
				LineOperation, NumberOfResult);
			
			If SelectionOfOperations.ContainsNestedRoute Then
				NewNestedRoute = TableOfNestedRoutes.Add();
				FillPropertyValues(NewNestedRoute, LineOperation);
				Continue;
			EndIf;
			
			If StructureOfData.Property("ManufacturedProducts") Then
				FillInLinkKey(LineOperation.Operation, LineOperation.ConnectionKey, OutputProductTable);
			EndIf;
			If StructureOfData.Property("RecyclableWaste") Then
				FillInLinkKey(LineOperation.Operation, LineOperation.ConnectionKey, TableReturnableWaste);
			EndIf;
			If StructureOfData.Property("UsedMaterials") Then
				FillInLinkKey(LineOperation.Operation, LineOperation.ConnectionKey, TableMaterialsAndServices);
			EndIf;
			If StructureOfData.Property("LaborCosts") Then
				FillInLinkKey(LineOperation.Operation, LineOperation.ConnectionKey, TableLaborCosts);
			EndIf;
			If StructureOfData.Property("AuxiliaryWorkCenters") Then
				FillInLinkKey(LineOperation.Operation, LineOperation.ConnectionKey, TableAuxiliaryWorkCentres);
			EndIf;
		EndIf;
		
	EndDo;
	
	If GetFunctionalOption("UseBillOfMaterialsParameterization") Then
	
		ItemData_3 = GetDataOnProducts(
			Products,
			Characteristic,
			RouteMapData);
		
		AutoSelectionParameters = ProductDataManagement.GetAutoSelectionParameters(RouteSheet, ItemData_3);
		
		If StructureOfData.Property("ManufacturedProducts") Then
			
			ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(
					OutputProductTable,
					AutoSelectionParameters);
				
		EndIf;
		
		If StructureOfData.Property("RecyclableWaste") Then
			
			ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(
					TableReturnableWaste,
					AutoSelectionParameters);
				
		EndIf;
		
		If StructureOfData.Property("UsedMaterials") Then
			
			ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(
					TableMaterialsAndServices,
					AutoSelectionParameters);
				
		EndIf;
		
		CalculationParametersBasedOnFormulas = GetCalculationParametersUsingFormulas(RouteSheet, NumberOfResult, ItemData_3);
		ProcessCalculationOfQuantityByFormulas(CalculationParametersBasedOnFormulas, RouteMapData);
	
	EndIf;
	
	UnpackCompositionOfSets(RouteMapData);
	
	// Let's add the prepared tables to the data structure
	If StructureOfData.Property("ManufacturedProducts") Then
		AddRouteMapTable("ManufacturedProducts",  OutputProductTable.Copy(),  StructureOfData);
	EndIf;
	If StructureOfData.Property("RecyclableWaste") Then
		AddRouteMapTable("RecyclableWaste",  TableReturnableWaste.Copy(), StructureOfData);
	EndIf;
	If StructureOfData.Property("UsedMaterials") Then
		AddRouteMapTable("UsedMaterials", TableMaterialsAndServices.Copy(), StructureOfData);
	EndIf;
	If StructureOfData.Property("LaborCosts") Then
		AddRouteMapTable("LaborCosts", TableLaborCosts.Copy(), StructureOfData);
	EndIf;
	If StructureOfData.Property("AuxiliaryWorkCenters") Then
		AddRouteMapTable("AuxiliaryWorkCenters", TableAuxiliaryWorkCentres.Copy(), StructureOfData);
	EndIf;
	
	// Before we go into recursion, let's free up the memory
	Query                  = Undefined;
	QueryResult        = Undefined;
	OutputProductTable  = Undefined;
	TableReturnableWaste = Undefined;
	TableMaterialsAndServices = Undefined;
	TableLaborCosts     = Undefined;
	TableAuxiliaryWorkCentres = Undefined;
	
	// Adding nested route data recursively
	If RelationshipStructure.Level < Catalogs.RouteSheets.MaximumNestingDepth()-1 Then
		
		For Each SelectionOfOperations In TableOfNestedRoutes Do
			
			StructureOfLinksNested = New Structure;
			StructureOfLinksNested.Insert("OperationParent", SelectionOfOperations.Operation);
			StructureOfLinksNested.Insert("ParentCommunicationKey", SelectionOfOperations.ConnectionKey);
			StructureOfLinksNested.Insert("Level", RelationshipStructure.Level + 1);
			
			If RelationshipStructure.LinkKeyNestedRoute = Undefined Then
				StructureOfLinksNested.Insert("LinkKeyNestedRoute", SelectionOfOperations.ConnectionKey);
			Else
				StructureOfLinksNested.Insert("LinkKeyNestedRoute", RelationshipStructure.LinkKeyNestedRoute);
			EndIf;
			
			AddRouteMapDataRecursively(SelectionOfOperations.NestedRoute, 
													NumberOfResult, 
													Products, 
													Characteristic,
													StructureOfLinksNested,
													StructureOfData);
		EndDo;
		
	EndIf;
	
EndProcedure


Procedure FillInLinkKey(Operation, OperationLinkKey, Table)
	
	TheStructureOfTheSearch = New Structure("Operation", Operation);
	StringsList = Table.FindRows(TheStructureOfTheSearch);
	
	For Each CollectionItem In StringsList Do
		CollectionItem.OperationLinkKey = OperationLinkKey;
	EndDo; 
	
EndProcedure

Procedure AddRouteMapTable(TableName, Table, StructureOfData)

	SourceTable = Undefined; // ValueTable
	StructureOfData.Property(TableName, SourceTable);
	If SourceTable <> Undefined Then
		For Each CollectionItem In Table Do
			NewRow = SourceTable.Add();
			FillPropertyValues(NewRow, CollectionItem);
		EndDo; 
	Else
		StructureOfData.Insert(TableName, Table);
	EndIf; 
	
EndProcedure

Procedure PrepareRequestTextForFetchingOperationData(Query, TableIndexes)
	
	QueryTexts = New Array;
	IndexOf = 0;
	
	QueryTexts.Add(QueryTextSelectionByProperties());
	IndexOf = IndexOf + 2;
	
	QueryText = RequestTextRouteMapOutputItems();
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "ManufacturedProducts");
	
	QueryText = RequestTextReturnRouteMapData();
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "RecyclableWaste");
	
	QueryText = RequestTextRouteMapMaterials();
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "UsedMaterials");
	
	QueryText = RequestTextRouteMapLaborCosts();
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "LaborCosts");
	
	For It = 0 To QueryTexts.UBound() Do
		QueryTexts[It] = StrReplace(
			QueryTexts[It],
			"&NumberOfResult",
			"&NumberOfResult * CASE WHEN TabularSection.Operation = &Operation THEN &CurOperationCoefficient ELSE 1 END");
	EndDo;
	
	QueryText = TextOfRouteMapOperationRequest(False);
	AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, "Operations");
	
	Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
EndProcedure

Procedure AddTextToBatchRequest(QueryTexts, QueryText, IndexOf, TableIndexes, TableName)
	
	TableIndexes.Insert(TableName, IndexOf);
	
	QueryTexts.Add(QueryText);
	
	IndexOf = IndexOf + 1;
	
EndProcedure

Function QueryTextSelectionByProperties()
	
	Result = ProductDataManagement.QueryTextTTSelectionBasedOnPropertiesOfSetting(Catalogs.RouteSheets.EmptyRef())
		+ Common.QueryBatchSeparator()
		+ ProductDataManagement.QueryTextTTSelectionByProperties("TTSelectionBySettingProperties");
	Return StrReplace(Result, "&Ref", "&RouteSheet");
	
EndFunction

Function RequestTextRouteMapOutputItems()
	
	Result = 
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.Products AS Products,
	|	CASE 
	|		WHEN TabularSection.Products.UseVariants IN (
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.NumberOfPackages * &NumberOfResult AS NumberOfPackages,
	|	CAST(TabularSection.NumberOfPackages * ISNULL(&QueryTextPackagingFactor,1) * &NumberOfResult AS NUMBER(15,3)) AS Count,
	|	TabularSection.Package AS Package,
	|	TabularSection.Operation AS Operation,
	|	TabularSection.Operation.Count * &NumberOfResult AS OperationsCount,
	|	CASE
	|		WHEN (TabularSection.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|				OR TabularSection.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
	|				AND &UseParameterization
	|			THEN TRUE
	|		ELSE FALSE
	|	END               AS UseAutoselection,
	|	PRESENTATION("""") AS AutoselectionDetails,
	|	TabularSection.MethodOfProductsAutoselection,
	|	TabularSection.MethodOfItemVariantAutoselection,
	|	TabularSection.PropertyThatContainsProducts,
	|	TabularSection.ItemVariantAutoSelectionAlgorithm,
	|
	|	// calculation by the formula:
	|	CASE
	|		WHEN &UseParameterization
	|			THEN TabularSection.QuantityCalculationAlgorithm
	|		ELSE """" 
	|	END AS QuantityCalculationAlgorithm,
	|
	|	TabularSection.Ref.Department AS Department,
	|	TabularSection.CostShare        AS CostShare,
	|	0                                   AS Id,
	|	TabularSection.ConnectionKey            AS ConnectionKey
	|FROM
	|	Catalog.RouteSheets.ManufacturedProducts AS TabularSection
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = &RouteSheet)
	|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
	|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
	|WHERE
	|	TabularSection.Ref = &RouteSheet
	|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
	|	AND RouteSheets.UseFinishedProducts
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Result = StrReplace(
		Result,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TabularSection.Package",
			"TabularSection.Products"));
	
	Return Result;
	
EndFunction

Function RequestTextReturnRouteMapData()
	
	Result =
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.Products AS Products,
	|	CASE 
	|		WHEN TabularSection.Products.UseVariants IN (
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.NumberOfPackages * &NumberOfResult AS NumberOfPackages,
	|	CAST(TabularSection.NumberOfPackages * ISNULL(&QueryTextPackagingFactor,1) * &NumberOfResult AS NUMBER(15,3)) AS Count,
	|	TabularSection.Package AS Package,
	|	TabularSection.ProductCostElement AS ProductCostElement,
	|	TabularSection.Operation AS Operation,
	|	TabularSection.Operation.Count * &NumberOfResult AS OperationsCount,
	|	CASE
	|		WHEN (TabularSection.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|				OR TabularSection.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
	|				AND &UseParameterization
	|			THEN TRUE
	|		ELSE FALSE
	|	END               AS UseAutoselection,
	|	PRESENTATION("""") AS AutoselectionDetails,
	|	TabularSection.MethodOfProductsAutoselection,
	|	TabularSection.MethodOfItemVariantAutoselection,
	|	TabularSection.PropertyThatContainsProducts,
	|	TabularSection.ItemVariantAutoSelectionAlgorithm,
	|
	|	// calculation by the formula:
	|	CASE
	|		WHEN &UseParameterization
	|			THEN TabularSection.QuantityCalculationAlgorithm
	|		ELSE """" 
	|	END AS QuantityCalculationAlgorithm,
	|	
	|	TabularSection.Ref.Department AS Department,
	|	0                                   AS Id,
	|	TabularSection.ConnectionKey            AS ConnectionKey
	|FROM
	|	Catalog.RouteSheets.RecyclableWaste AS TabularSection
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = &RouteSheet)
	|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
	|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
	|WHERE
	|	TabularSection.Ref = &RouteSheet
	|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
	|	AND RouteSheets.UseFinishedProducts
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Result = StrReplace(
		Result,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TabularSection.Package",
			"TabularSection.Products"));
	
	Return Result;
	
EndFunction

Function RequestTextRouteMapMaterials()
	
	Result =
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.Operation AS Operation,
	|	TabularSection.Operation.Count * &NumberOfResult AS OperationsCount,
	|	TabularSection.Ref.Department AS Department,
	|	TabularSection.Products AS Products,
	|	TabularSection.Products.ItemsType AS ItemsType,
	|	CASE 
	|		WHEN TabularSection.Products.UseVariants IN (
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	TabularSection.Characteristic AS Characteristic,
	|	TabularSection.NumberOfPackages * &NumberOfResult AS NumberOfPackages,
	|	CAST(TabularSection.NumberOfPackages * ISNULL(&QueryTextPackagingFactor,1) * &NumberOfResult AS NUMBER(15,3)) AS Count,
	|	TabularSection.Package AS Package,
	|	TabularSection.ProductCostElement AS ProductCostElement,
	|	CASE
	|		WHEN (TabularSection.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|				OR TabularSection.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
	|				AND &UseParameterization
	|			THEN TRUE
	|		ELSE FALSE
	|	END                AS UseAutoselection,
	|	PRESENTATION("""")  AS AutoselectionDetails,
	|	TabularSection.MethodOfProductsAutoselection,
	|	TabularSection.MethodOfItemVariantAutoselection,
	|	TabularSection.PropertyThatContainsProducts,
	|	TabularSection.ItemVariantAutoSelectionAlgorithm,
	|
	|	// calculation by the formula:
	|	CASE
	|		WHEN &UseParameterization
	|			THEN TabularSection.QuantityCalculationAlgorithm
	|		ELSE """" 
	|	END AS QuantityCalculationAlgorithm,
	|
	|	TabularSection.MaterialApplication AS MaterialApplication,
	|	0                                  AS Id,
	|	TabularSection.ConnectionKey           AS ConnectionKey
	|FROM
	|	Catalog.RouteSheets.MaterialsAndServices AS TabularSection
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = &RouteSheet)
	|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
	|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
	|WHERE
	|	TabularSection.Ref = &RouteSheet
	|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
	|	AND RouteSheets.UseMaterials
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Result = StrReplace(
		Result,
		"&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TabularSection.Package",
			"TabularSection.Products"));
	
	Return Result;
	
EndFunction

Function RequestTextRouteMapLaborCosts()
	
	Result = 
	"SELECT
	|	TabularSection.LineNumber AS LineNumber,
	|	TabularSection.WorkKind,
	|	TabularSection.Operation.Presentation AS ContentOfWorks,
	|	TabularSection.Count * &NumberOfResult AS Count,
	|	TabularSection.ProductCostElement,
	|	TabularSection.Operation,
	|	TabularSection.Operation.Count * &NumberOfResult AS OperationsCount,
	|	TabularSection.Ref.Department AS Department,
	|
	|	// calculation by the formula:
	|	CASE
	|		WHEN &UseParameterization
	|			THEN TabularSection.QuantityCalculationAlgorithm
	|		ELSE """" 
	|	END AS QuantityCalculationAlgorithm
	|
	|FROM
	|	Catalog.RouteSheets.LaborCosts AS TabularSection
	|
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = &RouteSheet)
	|
	|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
	|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
	|
	|WHERE
	|	TabularSection.Ref = &RouteSheet
	|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
	|	AND RouteSheets.UseLaborCosts
	|
	|ORDER BY
	|	TabularSection.LineNumber";
	
	Return Result;
	
EndFunction

Function RequestTextForRouteMapRC()
	
	Result =
	"SELECT
	|	TabularSection.WorkCenter,
	|	TabularSection.Ref AS Operation
	|FROM
	|	Catalog.ManufacturingOperations.AuxiliaryWorkCenters AS TabularSection
	|WHERE
	|	TabularSection.Ref.Owner = &RouteSheet";
		
	Return Result;

EndFunction

Function TextOfRouteMapOperationRequest(SetSelectionByOperation)
	
	Result = 
	"SELECT
	|	&OperationParent                        AS OperationParent,
	|	&ParentCommunicationKey                       AS ParentCommunicationKey,
	|	&LinkKeyNestedRoute               AS LinkKeyNestedRoute,
	|	ManufacturingOperations.Owner         AS RouteSheet,
	|	ManufacturingOperations.Ref           AS Operation,
	|	ManufacturingOperations.Presentation    AS OperationPresentation,
	|	ManufacturingOperations.Id    AS Id,
	|	ManufacturingOperations.NestedRoute AS NestedRoute,
	|	ManufacturingOperations.OperationNumber    AS OriginalOperationNumber,
	|	ManufacturingOperations.NextOperation AS SourceNumberOfNextOperation,
	|	ManufacturingOperations.OperationKind      AS OperationKind,
	|	ManufacturingOperations.Count       AS Count,
	|	ManufacturingOperations.UnitOfMeasure AS UnitOfMeasure,
	|	ManufacturingOperations.Count * &NumberOfResult AS QuantityPerBatch,
	|	ManufacturingOperations.SetupSettings   AS SetupSettings,
	|	ManufacturingOperations.Load         AS Load,
	|	ManufacturingOperations.Continuous      AS Continuous,
	|	ManufacturingOperations.Repeatable   AS Repeatable,
	|	ManufacturingOperations.Skippable  AS Skippable,
	|	ManufacturingOperations.Control         AS Control,
	|	ManufacturingOperations.TransferLot AS TransferLot,
	|	ManufacturingOperations.ContainsNestedRoute AS ContainsNestedRoute,
	|	&TextDetailsOfTransactionExecutor,
	|	&TextDetailsForCalculatingOperationExecutionTime
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = &RouteSheet)
	|WHERE
	|	ManufacturingOperations.Owner = &RouteSheet
	|	AND NOT ManufacturingOperations.DeletionMark
	|	AND RouteSheets.UseOperations
	|
	|ORDER BY
	|	ManufacturingOperations.OperationNumber";
	
	Result = StrReplace(
		Result,
		"&TextDetailsOfTransactionExecutor",
		Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation("ManufacturingOperations"));
	
	Result = StrReplace(
		Result,
		"&TextDetailsForCalculatingOperationExecutionTime",
		Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("ManufacturingOperations"));
	
	If SetSelectionByOperation Then
		
		Result = StrReplace(
			Result,
			"ManufacturingOperations.Owner = &RouteSheet",
			"ManufacturingOperations.Ref = &Operation");
		
	EndIf;
	
	Return Result;
	
EndFunction

Function MaximumNestingDepth() Export
	
	Return 5;
	
EndFunction

Procedure UnpackCompositionOfSets(RouteMapData)

	DataSet = Undefined;
	If Not RouteMapData.Property("UsedMaterials", DataSet) Then
		Return;
	EndIf;
	
	ParametersForObtainingComposition = ProductDataManagement.ParametersForObtainingCompositionOfSetInProduction();
	FillPropertyValues(ParametersForObtainingComposition, RouteMapData);
	
	ParametersForObtainingComposition.SourcesOfComposition.Add(Enums.SourcesOfCompositionOfSetsInProduction.KitConfigurations);
	
	ProductDataManagement.UnpackCompositionOfProcessKits(DataSet, ParametersForObtainingComposition);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
