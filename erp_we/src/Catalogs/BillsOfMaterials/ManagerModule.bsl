#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region StandardSubsystems

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
	
	NotAttributesToEdit.Add("ManufacturedProducts.Stage");
	NotAttributesToEdit.Add("RecyclableWaste.Stage");
	NotAttributesToEdit.Add("MaterialsAndServices.Stage");
	NotAttributesToEdit.Add("LaborCosts.Stage");
	NotAttributesToEdit.Add("ManufacturedProducts.Operation");
	NotAttributesToEdit.Add("RecyclableWaste.Operation");
	NotAttributesToEdit.Add("MaterialsAndServices.Operation");
	NotAttributesToEdit.Add("LaborCosts.Operation");
	Return NotAttributesToEdit;
	
EndFunction

// Checks the use of the object
//
// Parameters:
//  Parameters		- Structure - contains an object that you want to check for usage
//  StorageAddress	- String - address of the storage where the verification result will be placed
//
Procedure CheckObjectUsage(Parameters, StorageAddress) Export

	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS SearchTable
	|WHERE
	|	SearchTable.SourceOfSemiFinishedProduct REFS Catalog.BillsOfMaterials
	|	AND SearchTable.SourceOfSemiFinishedProduct = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	AccumulationRegister.ProductionPlans AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE AS ThereAreRefs
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterialsRM = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionOrder2_2.ManufacturedProduct AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2.ManufacturedProducts AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2 AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2.SideAndIntermediateRelease AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.ProductionStage2_2.MaterialsAndWorksSets AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	InformationRegister.ScopesOfSubstitutes AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|
	|UNION ALL
	|
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	Document.BackflushProduction.ManufacturedProducts AS SearchTable
	|WHERE
	|	SearchTable.BillOfMaterials = &Object
	|";
	
	Query.SetParameter("Object", Parameters.Object);
	
	SetPrivilegedMode(True);
	Result = Query.Execute();
	SetPrivilegedMode(False);
	
	ThereAreRefs = Not Result.IsEmpty();
	
	PutToTempStorage(ThereAreRefs, StorageAddress);

EndProcedure

// Populates the list of creation commands based on.
// 
// Parameters:
//  CreateCommandsBasedOn - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(CreateCommandsBasedOn, Parameters) Export
	
	VisibilityInForms = "ItemForm,ListForm,ChoiceForm";
	Command = Documents.StandardCosting2_2.AddGenerateCommand(CreateCommandsBasedOn);
	If Command <> Undefined Then
		Command.WriteMode = "";
		Command.VisibilityInForms = VisibilityInForms;
	EndIf;
	
	
	Command = Documents.EngineeringChangeOrder.AddGenerateCommand(CreateCommandsBasedOn);
	If Command <> Undefined Then
		Command.WriteMode = "";
		Command.VisibilityInForms = VisibilityInForms;
	EndIf;
	
	Command = AddCommandToCreateReverseKittingBasedOnKitting(CreateCommandsBasedOn);
	If Command <> Undefined Then
		Command.VisibilityInForms = VisibilityInForms;
	EndIf;
	Command = BusinessProcesses.Job.AddGenerateCommand(CreateCommandsBasedOn);
	If Command <> Undefined Then
		Command.VisibilityInForms = VisibilityInForms;
	EndIf;
	
EndProcedure

#Region Print

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export

EndProcedure

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

#Region Reports

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
EndProcedure

#EndRegion

#Region FillType

// Defines a list of fill commands.
//
// Parameters:
//   FillingCommands - See ObjectsFillingOverridable.BeforeAddFillCommands.FillingCommands
//   Parameters - See ObjectsFillingOverridable.BeforeAddFillCommands.Parameters
//
Procedure AddFillCommands(FillingCommands, Parameters) Export
	
EndProcedure

// Adds the "permission to replace materials" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined -
//
Function AddCommandToCreateReverseKittingBasedOnKitting(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Catalogs.BillsOfMaterials) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Catalogs.BillsOfMaterials.FullName();
		CreateBasedOnCommand.Presentation = Enums.ProductionProcessTypes.Disassembly;
		CreateBasedOnCommand.FunctionalOptions = "EnterpriseManagement";
		CreateBasedOnCommand.Handler = "ProductDataManagementClient.CreateReverseKittingBasedOnKitting";
		
		AttachableCommands.AddCommandVisibilityCondition(CreateBasedOnCommand,
			"ProductionProcessType",
			Enums.ProductionProcessTypes.Assembly,
			DataCompositionComparisonType.Equal);
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

#EndRegion

#Region DownloadingFromVHFFile

// Sets the download parameters.
//
// Parameters:
//   Parameters - Structure - download parameters from a file.
//
Procedure SetDownloadParametersFromVHFFile(Parameters) Export
	
	ColumnDataType = Parameters.ColumnDataType;
	TSName            = Parameters.AdditionalParameters.TSName;
	
	ColumnDataType.Insert("StageNumber",    New TypeDescription("Number",, New NumberQualifiers(5, 0)));
	ColumnDataType.Insert("OperationNumber", New TypeDescription("Number",, New NumberQualifiers(5, 0)));
	
	ColumnDataType.Insert("ProductCostElement", New TypeDescription("String",, New StringQualifiers(100)));
	ColumnDataType.Insert("Stage",              New TypeDescription("String",, New StringQualifiers(150)));
	ColumnDataType.Insert("Operation",          New TypeDescription("String",, New StringQualifiers(150)));
	
	If TSName = "LaborCosts" Then
		
		ColumnDataType.Insert("WorkKindCode",    New TypeDescription("String",, New StringQualifiers(9)));
		ColumnDataType.Insert("WorkKind",        New TypeDescription("String",, New StringQualifiers(150)));
		ColumnDataType.Insert("WorkAssignment", New TypeDescription("String",, New StringQualifiers(150)));
		
		ColumnDataType.Insert("Count", New TypeDescription("Number",,  New NumberQualifiers(15, 3)));
		
	Else
		
		ColumnDataType.Insert("Barcode",        New TypeDescription("String",, New StringQualifiers(200)));
		ColumnDataType.Insert("SKU",         New TypeDescription("String",, New StringQualifiers(50)));
		ColumnDataType.Insert("ProductsAndServicesCode", New TypeDescription("String",, New StringQualifiers(11)));
		ColumnDataType.Insert("Products",    New TypeDescription("String",, New StringQualifiers(100)));
		ColumnDataType.Insert("Characteristic",  New TypeDescription("String",, New StringQualifiers(150)));
		ColumnDataType.Insert("PackageCode",     New TypeDescription("String",, New StringQualifiers(4)));
		ColumnDataType.Insert("Package",        New TypeDescription("String",, New StringQualifiers(50)));
		
		ColumnDataType.Insert(?(TSName = "MaterialsAndServices", "MaterialApplication", "ProductDescription"),
			New TypeDescription("String",, New StringQualifiers(0)));
		
		ColumnDataType.Insert("NumberOfPackages", New TypeDescription("Number",, New NumberQualifiers(15, 3)));
		
	EndIf;
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
// 
// Parameters:
// 	AddressOfUploadedData- String - address of the temporary storage with a table of values that
//                                   contains the downloaded data from the file.
// 	AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                       which is a copy of the table part of the document 
//                                       that needs to be filled in from the addressable Data table.
// 	ConflictsList - ValueTable - consists of:
//  * Id - Number - Id
//  * Column - String - column name
// 	FullTabularSectionName - String - full name of the table part
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure MapDataToImport(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, FullTabularSectionName, AdditionalParameters) Export
	
	If AdditionalParameters.TSName = "LaborCosts" Then
		CompareUploadedDataLaborCosts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, AdditionalParameters);
	Else
		MatchDownloadableDataProducts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, AdditionalParameters);
	EndIf;
	
EndProcedure

// Returns a list of suitable IB objects for an ambiguous cell value.
// 
// Parameters:
// 	FullTabularSectionName- String - full name of the table part where data is loaded.
// 	ConflictsList - Array - list of ambiguities.
// 	ColumnName - String - name of the column where the ambiguity occurs.
// 	LoadedValuesString - String - Loaded data based on which the ambiguity occurred.
// 	AdditionalParameters - Structure - additional parameters passed from the source form.
Procedure FillInListOfAmbiguities(FullTabularSectionName, ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters) Export 
	
	If AdditionalParameters.TSName = "LaborCosts" Then
		FillInListOfAmbiguitiesLaborCosts(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters);
	Else
		FillInListOfProductAmbiguities(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters);
	EndIf;
	
EndProcedure

#EndRegion

#EndRegion

#Region Constructors

// Function-constructor of the structure for selecting data from the resource specification.
// 
// Returns:
//  Structure - structure with parameters for fetching specification data:
//  	* Products - CatalogRef.Products - Products
//  	* Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//  	* BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
//  	* Count - Number - number of products
//
Function ItemData_3() Export
	
	ItemData_3 = New Structure;
	
	ItemData_3.Insert("Products");
	ItemData_3.Insert("Characteristic");
	
	ItemData_3.Insert("BillOfMaterials");
	ItemData_3.Insert("Count");
	
	Return ItemData_3;
	
EndFunction

// Function-constructor of the structure for selecting data from the resource specification.
//
// Returns:
//  Structure - structure with parameters for fetching specification data:
//  	* Products - CatalogRef.Products - Products
//  	* Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//  	* BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
//  	* Count - Number - number of products
//  	* ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - Department
//  	* LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//  	* ProductionStart - Date - production start date
//  	* DaysFromDemand - Number - number of days from demand according to the standard schedule
//		* ReferenceOrder - DocumentRef - ReferenceOrder
//
Function ProductData_5() Export
	
	ItemData_3 = New Structure;
	
	ItemData_3.Insert("Products");
	ItemData_3.Insert("Characteristic");
	
	ItemData_3.Insert("BillOfMaterials");
	ItemData_3.Insert("Count");
	
	ItemData_3.Insert("ReferenceOrder");
	
	ItemData_3.Insert("ProductionDispatcherBusinessUnit");
	ItemData_3.Insert("LineOfBusiness");
	ItemData_3.Insert("ProductionStart");
	
	ItemData_3.Insert("DaysFromDemand");
	
	Return ItemData_3;
	
EndFunction

// The constructor function tables for the sample data, the resource specification for the list of values.
//
// Returns:
//  ValueTable - table with parameters for selecting specification data:
//  	* Products - CatalogRef.Products - The item for which you need to get the specification data
//  	* Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
//  	* BillOfMaterials - CatalogRef.BillsOfMaterials - specification to get the data for
//  	* Count - Number - number of products
//  	* ProductionDispatcherBusinessUnit - CatalogRef.BusinessStructure - Department
//  	* AssigneeBusinessUnit - CatalogRef.BusinessStructure - redefining the executing division
//  	* LineOfBusiness - CatalogRef.LinesOfBusiness - Direction of activity
//  	* ProductionStart - Date - production start date
//  	* DaysFromDemand - Number - number of days from demand according to the standard schedule
//  	* ReferenceOrder - DocumentRef - ReferenceOrder
//  	* Id - Number - the row identifier for the table (added later)
//  	* Product - CatalogRef.Products - A top-level finished product, for cases when the Specification data of the specified Nomenclature
//  			should be obtained taking into account its belonging to a multi-level structure. If not specified, it is considered equal to the Nomenclature.
//  	* ItemVariantOfProduct - CatalogRef.ItemsCharacteristics - Product features
//  	* ProductSpecification - CatalogRef.BillsOfMaterials - Product Specification
//  	* ProductSpecificationStage - CatalogRef.ProductionStages - Product Specification Stage
//
Function ItemList() Export
	
	ItemList = New ValueTable;
	
	ItemList.Columns.Add("Products",             New TypeDescription("CatalogRef.Products"));
	ItemList.Columns.Add("Characteristic",           New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ItemList.Columns.Add("BillOfMaterials",             New TypeDescription("CatalogRef.BillsOfMaterials"));
	ItemList.Columns.Add("Count",               New TypeDescription("Number", New NumberQualifiers(15,3)));
	ItemList.Columns.Add("ProductionDispatcherBusinessUnit",   New TypeDescription("CatalogRef.BusinessStructure"));
	ItemList.Columns.Add("AssigneeBusinessUnit", New TypeDescription("CatalogRef.BusinessStructure"));
	ItemList.Columns.Add("LineOfBusiness",  New TypeDescription("CatalogRef.LinesOfBusiness"));
	ItemList.Columns.Add("ProductionStart",       New TypeDescription("Date",,, New DateQualifiers));
	ItemList.Columns.Add("DaysFromDemand",        New TypeDescription("Number", New NumberQualifiers(10)));
	ItemList.Columns.Add("Product",                  New TypeDescription("CatalogRef.Products"));
	ItemList.Columns.Add("ItemVariantOfProduct",    New TypeDescription("CatalogRef.ItemsCharacteristics"));
	ItemList.Columns.Add("ProductSpecification",      New TypeDescription("CatalogRef.BillsOfMaterials"));
	ItemList.Columns.Add("ProductSpecificationStage",  New TypeDescription("CatalogRef.ProductionStages"));
	DataTypes = New Array;
	DataTypes.Add(Type("DocumentRef.ProductionOrder2_2"));
	ItemList.Columns.Add("ReferenceOrder", New TypeDescription(DataTypes));
	Return ItemList;
	
EndFunction

// Function-constructor of the structure for selecting data from the resource specification.
//
// Parameters:
//  ListOfData - String,Array,Undefined  - contains a list of specification data to get.
//  TempTablesManager - TempTablesManager,Undefined - contains temporary tables used to get the security method.
//  SoftwareFillingOption - EnumRef.ProductionSupplyFillingVariants,Undefined - defines the option for filling in the security.
// 
// Returns:
//  Structure - structure with parameters for fetching specification data:
//  	* ListOfData - Array - Contains a list of specification data to get.
//  	    Undefined - if you need to get the entire data set.
//  	* TempTablesManager - TempTablesManager - contains temporary tables used to get the security method.
//  	* SoftwareFillingOption - EnumRef.ProductionSupplyFillingVariants -  Option for filling in software in production
//  	* GetPresentations - Boolean - True if you need to get views of reference fields.
//  	* GetAutoSelectionInformation - Boolean - True if you need to get auto-selection information.
//  	* OverridingReleasePartySetting - Structure - used to override the release batch setting.
//  	* RoundUpNumberOfUnitItems_ - Boolean - if True, then piece goods in measured units. when shipped
//  		from/to warehouses that are not shop storerooms, they will be rounded up to a whole number of pieces.
//  		Also, the unit nomenclature is rounded up to a whole number if: 
//  		the issue is in arbitrary portions, the product is the same and the standard is set to a whole number of base units.
//  	* GetDataSets - Boolean - if True, then the compositions of the sets will be unpacked
//  	* IntermediateSemiFinishedProducts - String - the option of obtaining intermediate semi-finished products specified by the setting "Transfer of intermediate output between stages"
//  	* PerformDirectiveSubstitutions - Boolean - if True, then directive substitutions will be performed
//
Function DataSamplingParameters(ListOfData = Undefined, TempTablesManager = Undefined, SoftwareFillingOption = Undefined) Export
	
	SelectionParameters = New Structure;
	SelectionParameters.Insert("TempTablesManager", TempTablesManager);
	
	If TypeOf(ListOfData) = Type("Array") Then
		SelectionParameters.Insert("ListOfData", ListOfData);
	ElsIf TypeOf(ListOfData) = Type("String") Then
		SelectionParameters.Insert("ListOfData", StrSplit(StrReplace(ListOfData, " ", ""), ",", False));
	Else
		SelectionParameters.Insert("ListOfData", ListOfSpecificationData());
	EndIf;
	
	SelectionParameters.Insert("GetPresentations", False);
	SelectionParameters.Insert("GetAutoSelectionInformation", True);
	
	SelectionParameters.Insert("GetDataSets", True);
	SelectionParameters.Insert("IntermediateSemiFinishedProducts", ProductDataManagementClientServer.IntermediateSemiFinishedProductsDoNotReceive());
	
	SelectionParameters.Insert("CombineMaterialsAndIncomingProducts", False);
	SelectionParameters.Insert("CombineMaterialsAndWorksPerformed", False);
	SelectionParameters.Insert("PerformDirectiveSubstitutions", AlternativeMaterials.UseDirectiveSubstitutions());
	SelectionParameters.Insert("AvailableWorks", True);
	SelectionParameters.Insert("MethodOfCalculationOfMaterials", Enums.MaterialCalculationMethods.MinimumConsumption);
	If SoftwareFillingOption = Undefined Then
		SelectionParameters.Insert("SoftwareFillingOption", Enums.ProductionSupplyFillingVariants.BySupplySchemes);
	Else
		SelectionParameters.Insert("SoftwareFillingOption", SoftwareFillingOption);
	EndIf;
	
	SelectionParameters.Insert("ConsiderProbabilityOfDefectiveGoods", True);
	SelectionParameters.Insert("RoundUpNumberOfUnitItems_", True);
	
	SelectionParameters.Insert("CalculateShareOfCostOfOutputProducts", False);
	SelectionParameters.Insert("CalculateScheduleProductionAttribute", True);
	
	SelectionParameters.Insert("OverridingReleasePartySetting", New Structure("Use,ProductionIssueByCustomPortions",False,False));
	
	Return SelectionParameters;
	
EndFunction

#EndRegion

#Region SpecificationData

// The constructor of the data structure specifications
// 
// Returns:
// 	Structure - From:
//		* BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
//		* BillOfMaterialsPresentation - String - Specification view
//		* MethodOfAllocatingFinishedProductCosts - EnumRef.MethodsOfCostAllocatingOnProductCosts - cost allocation method
//		* ProductionProcessType - EnumRef.ProductionProcessTypes - type of production process
//		* AssignmentOption - EnumRef.BillOfMaterialsAssignmentOptions - option of destination
//		* MultiStageProductionProcess - Boolean - indicates a multi-step process
//		* ProductionIssueByCustomPortions - Boolean - indicates whether the product is released in random portions
//		* EconomicReleaseLot - Number - the optimal size of the party
//		* PermissibleExcessOfOptimalReleaseLot - Number - the size of the tolerance range
//		* MinimumReleaseLot - Number - minimum batch size
//		* MainProduct - See MainProductSpecificationDataStructure
//		* QueuePeriodIsLimited - Boolean - a sign that limits the duration of bed rest
//		* MaximumPeriodOfLyingInDays - Number - maximum period of stay
//		* OptimalTransfersQuantityBetweenStages - Number - optimal amount of transmission between stages
//		* Stages - ValueTable - stage table
//		* ManufacturedProducts - ValueTable - Table Of Output Products:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* RecyclableWaste - ValueTable - Table Of Returnable Waste:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* MaterialsAndServices - ValueTable - table of materials:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* IncomingProducts - ValueTable - Table Of Incoming Products:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* LaborCosts - ValueTable - Table Of Labor Costs:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* WorkCenterTypes - ValueTable - table of types of work centers:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//		* AlternateWorkCenterTypes - ValueTable - table of alternative types of work centers:
//			** LineNumber - Number - the line number table
//			** ConnectionKey - UUID - the link key table
//
Function DataSpecificationConstructor() Export
	
	StructureOfData = New Structure;
	
	StructureOfData.Insert("BillOfMaterials");
	StructureOfData.Insert("BillOfMaterialsPresentation", "");
	
	StructureOfData.Insert("Code", "");
	StructureOfData.Insert("DataVersionID", "");
	
	StructureOfData.Insert("MethodOfAllocatingFinishedProductCosts");
	
	StructureOfData.Insert("ProductionProcessType");
	StructureOfData.Insert("AssignmentOption");
	
	StructureOfData.Insert("MultiStageProductionProcess",  False);
	
	StructureOfData.Insert("ProductionIssueByCustomPortions",          False);
	StructureOfData.Insert("EconomicReleaseLot", 0);
	StructureOfData.Insert("PermissibleExcessOfOptimalReleaseLot", 0);
	StructureOfData.Insert("MinimumReleaseLot", 0);
	
	StructureOfData.Insert("MainProduct", MainProductSpecificationDataStructure());
	
	StructureOfData.Insert("QueuePeriodIsLimited", False);
	StructureOfData.Insert("MaximumPeriodOfLyingInDays", 0);
	
	StructureOfData.Insert("OptimalTransfersQuantityBetweenStages", 0);
	
	StructureOfData.Insert("ThereIsSpecifiedMainProduct", False);
	StructureOfData.Insert("ContainsResourcesParametrization",    False);
	StructureOfData.Insert("ContainsNestedBOMs",     False);
	StructureOfData.Insert("ContainsProbabilityCalculation",         False);
	StructureOfData.Insert("ContainsAliquotStandardsOfWorkCenterTypes",     False);
	
	StructureOfData.Insert("ResponsibleBusinessUnit");
	
	StructureOfData.Insert("StateOfDataSets", "Missing1"); // Collapsed, Unpacked
	
	Return StructureOfData;
	
EndFunction

// Returns the data specification based on the data about the item
// 
// Parameters:
// 	ItemData_3 - See ProductData_5
// 	SelectionParameters - See DataSamplingParameters
// 	Filter - Structure,Undefined - Selection structure
// Returns:
// 	See DataSpecificationConstructor
//
Function SpecificationDataByProducts(ItemData_3, SelectionParameters, Filter = Undefined) Export
	
	SpecificationData = SpecificationData(ItemData_3, SelectionParameters)[0];
	
	ReleaseParty = CalculateBatchOfOutputByProduct(ItemData_3, SpecificationData, SelectionParameters);
	
	CalculateQuantityPerBatchRelease(ReleaseParty, SpecificationData, ItemData_3);
	
	ApplySelectionBasedOnSpecificationData(SpecificationData, Filter, SelectionParameters);
	
	Return SpecificationData;
	
EndFunction

// Returns bill of material information for the given list item.
//
// Parameters:
//  ItemList - See ItemList
//  SelectionParameters   - See DataSamplingParameters
//	GroupData_ - Boolean - True if you want to group
//		data by the specified set of fields when retrieving data (see the Grouping field parameter).
//	GroupFields    - String - the field names listed separated by commas, which you want to group the data.
//		The string must not contain spaces or other insignificant characters.
//		Columns with similar names must be present in the list of items to receive data.
//		If the fields are not specified, but the group Data parameter is set, then grouping is performed only by specification.
//
// Returns:
//  Array of See DataSpecificationConstructor - specification data array
//
Function SpecificationDataByProductsList(ItemList, SelectionParameters, GroupData_ = False, GroupFields = "") Export
	
	TMCommonUse.NumberValueTable(ItemList, "Id");
	
	SpecificationsData = SpecificationData(ItemList, SelectionParameters);
	
	#Region DataGroup2
	
	// Variables for grouping data
	TheStructureOfTheSearch = Undefined;
	AdditionalIndex = Undefined;
	ArrayDimensionFields = New Array;
	
	If GroupData_ Then
		
		SearchFields = GroupFields;
		If StrFind(SearchFields, "BillOfMaterials") = 0 Then
			SearchFields = SearchFields + ?(IsBlankString(SearchFields), "", ",") + "BillOfMaterials";
		EndIf;
		TheStructureOfTheSearch = New Structure(SearchFields);
		AdditionalIndex = ItemList.Indexes.Add(SearchFields);
		
		If Not IsBlankString(GroupFields) Then
			For Each Item In StrSplit(GroupFields, ",", False) Do
				ArrayDimensionFields.Add(TrimAll(Item));
			EndDo;
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	Result = New Array;
	
	For IndexOf = 0 To ItemList.Count()-1 Do
		
		String = ItemList[IndexOf];
		
		If String.BillOfMaterials.IsEmpty() Then
			Result.Add(Undefined);
			Continue;
		ElsIf String.Id = -1 Then
			Continue; // the rows processed during the data grouping process receive the identifier -1
		EndIf;
		
		SpecificationData   = SpecificationsData[String.Id];
		ItemData_3 = ProductData_5();
		FillPropertyValues(ItemData_3, String);
		
		// Calculation of the release batch
		If GroupData_ Then
			
			ReleaseParty = ReleaseParty(0,1);
			
			#Region DataGroup2
			
			If SpecificationData.MainProduct.ThisIsMainProduct Then
				Products = String.Products;
				Characteristic = String.Characteristic;
			Else
				Products = Undefined;
				Characteristic = Undefined;
			EndIf;
			
			// Searching for rows to group
			FillPropertyValues(TheStructureOfTheSearch, String);
			FoundRows = ItemList.FindRows(TheStructureOfTheSearch);
			
			For Cnt1 = 0 To FoundRows.UBound() Do
				
				If FoundRows[Cnt1].Id = -1 Then
					Continue;
				EndIf;
				
				SpecificationDataNew = SpecificationsData[FoundRows[Cnt1].Id];
				
				// Limitation on the nomenclature and characteristics
				If SpecificationData.ThereIsSpecifiedMainProduct
					And SpecificationDataNew.MainProduct.ThisIsMainProduct Then
					
					If Products = Undefined Then
						Products = FoundRows[Cnt1].Products;
						Characteristic = FoundRows[Cnt1].Characteristic;
						SpecificationData = SpecificationDataNew;
					ElsIf Products <> FoundRows[Cnt1].Products
						Or Characteristic <> FoundRows[Cnt1].Characteristic Then
						Continue;
					EndIf;
					
				EndIf;
				
				NewProductData = ProductData_5();
				FillPropertyValues(NewProductData, FoundRows[Cnt1]);
				
				// Summation of the quantity if N and X are identical
				For Cnt2 = Cnt1+1 To FoundRows.UBound() Do
					
					If FoundRows[Cnt2].Id <> -1
						And FoundRows[Cnt1].Products = FoundRows[Cnt2].Products
						And FoundRows[Cnt1].Characteristic = FoundRows[Cnt2].Characteristic Then
						
						NewProductData.Count = NewProductData.Count + FoundRows[Cnt2].Count;
						FoundRows[Cnt2].Id = -1;
						
					EndIf;
					
				EndDo;
				
				FoundRows[Cnt1].Id = -1;
				
				// Calculation of the max. batch
				BatchIssueNov = CalculateBatchOfOutputByProduct(
					NewProductData, SpecificationDataNew, SelectionParameters);
				If CompareReleaseBatches(BatchIssueNov, ReleaseParty) > 0 Then
					ReleaseParty = BatchIssueNov;
					ItemData_3 = NewProductData;
				EndIf;
				
			EndDo;
			
			// Copying grouping fields to the result
			For Each Field In ArrayDimensionFields Do
				SpecificationData.Insert(Field, String[Field]);
			EndDo;
			
			#EndRegion
			
		Else
			
			ReleaseParty = CalculateBatchOfOutputByProduct(
				ItemData_3, SpecificationData, SelectionParameters);
			
		EndIf;
		
		// calculation of quantity
		CalculateQuantityPerBatchRelease(ReleaseParty, SpecificationData, ItemData_3);
		
		Result.Add(SpecificationData);
		
	EndDo;
	
	ItemList.Columns.Delete("Id");
	
	If GroupData_ Then
		ItemList.Indexes.Delete(AdditionalIndex);
	EndIf;
	
	Return Result;
	
EndFunction

// Returns specification data, including data about the item and specifications of semi-finished products produced in the process.
// 
// Parameters:
// 	ItemData_3 - See ProductData_5
// 	ToExcludeSemiFinishedProducts - Boolean - True, if you do not need to add semi-finished products to materials and output products
// 	SelectionParameters - See DataSamplingParameters
// Returns:
// 	See DataSpecificationConstructor
//
Function SpecificationDataBySemiFinishedProducts(ItemData_3, ToExcludeSemiFinishedProducts, SelectionParameters) Export
	
	SelectionParametersCopy = Common.CopyRecursive(SelectionParameters);
	SelectionParametersCopy.CombineMaterialsAndWorksPerformed = True;
	If ToExcludeSemiFinishedProducts Then
		If SelectionParametersCopy.ListOfData.Find("RecyclableWaste") = Undefined Then
			SelectionParametersCopy.ListOfData.Add("RecyclableWaste");
		EndIf;
		If SelectionParametersCopy.ListOfData.Find("Stages") = Undefined Then
			SelectionParametersCopy.ListOfData.Add("Stages");
		EndIf;
	EndIf;
	
	SpecificationData = SpecificationDataByProducts(ItemData_3, SelectionParametersCopy);
	
	If SpecificationData = Undefined Then
		
		If ItemData_3.Property("BillOfMaterials") And ValueIsFilled(ItemData_3.BillOfMaterials) Then
			ExceptionText = NStr("vi = 'Lỗi đọc dữ liệu danh sách bảng kê chi tiết các nguồn lực sản xuất: %BillOfMaterials%.';
								|ru = 'Ошибка при чтении данных ресурсной спецификации: %BillOfMaterials%.';
								|en = 'An error occurred when reading data of the %BillOfMaterials% bill of materials.'; fa = 'An error occurred when reading data of the %BillOfMaterials% bill of materials.';
								|it = 'Errore durante la lettura dei dati delle specifiche delle risorse: %BillOfMaterials%.';
								|pl = 'Błąd podczas odczytu danych specyfikacji zasobów: %BillOfMaterials%.';
								|tr = 'Ürün reçetesi verileri okunurken hata oluştu: %BillOfMaterials%.'");
			ExceptionText = StrReplace(ExceptionText, "%BillOfMaterials%", ItemData_3.BillOfMaterials);
		Else
			ExceptionText = NStr("vi = 'Lỗi đọc dữ liệu danh sách bảng kê chi tiết các nguồn lực sản xuất: bảng kê chi tiết các nguồn lực sản xuất không được truyền.';
								|ru = 'Ошибка при чтении данных ресурсной спецификации: не передана спецификация.';
								|en = 'An error occurred when reading bill of materials data: bill of materials not transferred.'; fa = 'An error occurred when reading bill of materials data: bill of materials not transferred.';
								|it = 'Errore durante la lettura dei dati delle specifiche delle risorse: nessuna specifica è stata indicata.';
								|pl = 'Błąd podczas odczytu danych specyfikacji zasobów: nie przekazano certyfikacji.';
								|tr = 'Ürün reçetesi verileri okunurken hata oluştu: Ürün reçetesi aktarılmadı.'");
		EndIf;
		
		Raise ExceptionText;
		
	EndIf;
	
	If ToExcludeSemiFinishedProducts Then
		Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(SpecificationData);
	EndIf;
	
	UnearthedSpecifications = New Map;
	UnearthedSpecifications.Insert(SpecificationData.BillOfMaterials);
	
	ItemList = ItemList();
	
	For Each String In SpecificationData.MaterialsAndServices Do
		
		If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
			And UnearthedSpecifications.Get(String.SourceOfSemiFinishedProduct) = Undefined Then
			
			NewRow = ItemList.Add();
			FillPropertyValues(NewRow, String, "Products, Characteristic, Count, DaysFromDemand");
			FillPropertyValues(NewRow, ItemData_3, "ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness");
			NewRow.BillOfMaterials = String.SourceOfSemiFinishedProduct;
			
		EndIf;
		
		If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
			And ValueIsFilled(String.BillOfMaterialsRM)
			And UnearthedSpecifications.Get(String.BillOfMaterialsRM) = Undefined Then
			
			NewRow = ItemList.Add();
			FillPropertyValues(NewRow, String, "Products, Characteristic, Count, DaysFromDemand");
			FillPropertyValues(NewRow, ItemData_3, "ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness");
			NewRow.BillOfMaterials = String.BillOfMaterialsRM;
			
		EndIf;
		
	EndDo;
	
	SelectionParametersCopy = Common.CopyRecursive(SelectionParametersCopy);
	SelectionParametersCopy.CombineMaterialsAndIncomingProducts = False;
	While ItemList.Count() > 0 Do
		
		ItemList = AddSemiFinishedProductData(
			SpecificationData, ItemList, SelectionParametersCopy, UnearthedSpecifications, ToExcludeSemiFinishedProducts);
		
	EndDo;
	
	If ToExcludeSemiFinishedProducts Then
		
		FilterStructure1 = New Structure("ProducedInProcess", True);
		FoundRows = SpecificationData.MaterialsAndServices.FindRows(FilterStructure1);
		
		For Each String In FoundRows Do
			
			SpecificationData.MaterialsAndServices.Delete(String);
			
		EndDo;
		
	EndIf;
	
	Return SpecificationData;
	
EndFunction

// Returns the responsible department of the specification.
// 
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials -BillOfMaterials 
// 
// Returns:
//   - CatalogRef.BusinessStructure -
Function ResponsibleBusinessUnit(BillOfMaterials) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	BillsOfMaterials.ResponsibleBusinessUnit
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|WHERE
	|	BillsOfMaterials.Ref = &Ref";

	Query.SetParameter("Ref", BillOfMaterials);
	
	Selection = Query.Execute().Select();
	
	If Selection.Next() Then
		Result = Selection.ResponsibleBusinessUnit;
	Else
		Result = Catalogs.BusinessStructure.EmptyRef();
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region DescriptionManufacturingProcess

// Gets a description of the release batch according to the specification
//
// Parameters:
//  BillOfMaterials - CatalogObject.BillsOfMaterials, CatalogRef.BillsOfMaterials - this specification
// 
// Returns:
//  Structure - description of the release batch
//
Function ReleaseBatchDescription(BillOfMaterials) Export
	
	ReleaseBatchDescription = ProductDataManagementClientServer.StructureDescriptionOfReleaseBatch();
	
	ListOfSpecificationDetails = "ProductionProcessType,AssignmentOption,ProductionIssueByCustomPortions";
	
	If TypeOf(BillOfMaterials) = Type("CatalogRef.BillsOfMaterials") Then
		
		SpecificationDetails = Common.ObjectAttributesValues(BillOfMaterials, ListOfSpecificationDetails);
		
		MainProductData = MainProductSpecificationData(BillOfMaterials);
		FillPropertyValues(ReleaseBatchDescription, MainProductData);
		
	Else
		
		SpecificationDetails = New Structure(ListOfSpecificationDetails);
		FillPropertyValues(SpecificationDetails, BillOfMaterials);
		
		MainProductData = ProductDataManagementClientServer.MainProductSpecificationData(BillOfMaterials);
		FillPropertyValues(ReleaseBatchDescription, MainProductData);
		
	EndIf;
	
	If (SpecificationDetails.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
			And SpecificationDetails.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList
		) Then
		ReleaseBatchDescription.MultipleIssue = True;
	Else
		ReleaseBatchDescription.MultipleIssue = False;
	EndIf;
	
	If SpecificationDetails.ProductionIssueByCustomPortions = True Then
		ReleaseBatchDescription.ProductionIssueByCustomPortions = True;
	Else
		ReleaseBatchDescription.ProductionIssueByCustomPortions = False;
	EndIf;
	
	If ValueIsFilled(ReleaseBatchDescription.Products) Then
		BasicUnitOfMeasurement = Common.ObjectAttributeValue(ReleaseBatchDescription.Products, "UnitOfMeasure");
	Else
		BasicUnitOfMeasurement = Common.ObjectAttributeValue(MainProductData.Package, "Owner.UnitOfMeasure");
	EndIf;
	
	If ValueIsFilled(BasicUnitOfMeasurement) And ReleaseBatchDescription.Package.IsEmpty() Then
		ReleaseBatchDescription.UnitOfProductMeasurement = BasicUnitOfMeasurement;
	Else
		ReleaseBatchDescription.UnitOfProductMeasurement = ReleaseBatchDescription.Package;
	EndIf;
	
	If ValueIsFilled(BasicUnitOfMeasurement) And SpecificationDetails.ProductionIssueByCustomPortions Then
		ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch = BasicUnitOfMeasurement;
	ElsIf ReleaseBatchDescription.MultipleIssue Or ReleaseBatchDescription.NumberOfPackages <> 1 Then // Unit of measurement of the Release Party() 
		ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
	Else
		ReleaseBatchDescription.UnitOfMeasurementOfReleaseBatch = ReleaseBatchDescription.UnitOfProductMeasurement;
	EndIf;
	
	Return New FixedStructure(ReleaseBatchDescription);
	
EndFunction

// Gets a description of the production process
//
// Parameters:
//  Ref - CatalogRef.BillsOfMaterials - resource specification
// 
// Returns:
//  Structure - description of the production process
//
Function DescriptionManufacturingProcess(Ref) Export
	
	Result = New Structure("SeveralFirstSteps,SeveralLastSteps");
	
	Query = New Query(
	"SELECT
	|	ISNULL(SUM(CASE
	|			WHEN NextStageNo = 0
	|				THEN 1
	|			ELSE 0
	|		END),0) > 1 AS SeveralLastSteps,
	|	ISNULL(SUM(CASE
	|			WHEN StageNumber = 1
	|				THEN 1
	|			ELSE 0
	|		END),0) > 1 AS SeveralFirstSteps
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|WHERE
	|	Owner = &Ref AND NOT DeletionMark");
	Query.SetParameter("Ref", Ref);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	FillPropertyValues(Result, Selection);
	
	Return New FixedStructure(Result);
	
EndFunction

// Returns the data structure of the main product by specification
//
// Parameters:
//  BillOfMaterials	 - CatalogRef.BillsOfMaterials	 - specification to get data from
//  Products	 - CatalogRef.Products			 - Output item nomenclature, if not specified, the main one
//  Characteristic	 - CatalogRef.ItemsCharacteristics - Output product characteristics, if not specified, 
//																	the main or any of the characteristics of the item
//
// Returns:
//   Structure   - contains product data
//
Function MainProductSpecificationData(BillOfMaterials, Products = Undefined, Characteristic = Undefined) Export
	
	QueryText = 
	"SELECT
	|	0               AS Id,
	|	&BillOfMaterials   AS BillOfMaterials,
	|	&Products   AS Products,
	|	&Characteristic AS Characteristic
	|INTO TTProductData_
	|;
	|/////////////////////////////////////////////////////////////////////////////
	|"
	+ QueryTextMainProductSpecificationData();
	
	Query = New Query(QueryText);
	
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	If Products = Undefined Then
		Query.SetParameter("Products", Catalogs.Products.EmptyRef());
	Else
		Query.SetParameter("Products", Products);
	EndIf;
	
	If Characteristic = Undefined Then
		Query.SetParameter("Characteristic", Catalogs.ItemsCharacteristics.EmptyRef());
	Else
		Query.SetParameter("Characteristic", Characteristic);
	EndIf;
	
	Query.SetParameter("ConsiderProbabilityOfDefectiveGoods", True);
	
	QueryResults = Query.ExecuteBatch();
	
	Result = QueryResults[QueryResults.Count()-1];
	
	ItemData_3 = MainProductSpecificationDataStructure();
		
	If Not Result.IsEmpty() Then
		
		Selection = Result.Select();
		Selection.Next();
		
		FillPropertyValues(ItemData_3, Selection);
		
		ProductDataManagement.FillInPackingDataInDataSetRow(
			ItemData_3,
			QueryResults[QueryResults.Count()-2].Unload());
		
		ItemData_3.Count = DescriptionOfTypeOfQuantitativeProps().AdjustValue(
			ItemData_3.NumberOfPackages
				* ItemData_3.PackageData.Numerator / ItemData_3.PackageData.Denominator);
		
	EndIf;
	
	Return ItemData_3;
	
EndFunction

#EndRegion

#Region Other

//Returns parameters for selecting specifications for the items specified in the document.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of the choice specs.
//
// Returns:
//   Structure - A structure that overrides the defaults set in the management function of the Client Server's data items.Parameterselectionspecifications().
//
Function BOMSelectionParameters(Object) Export
	
	BOMSelectionParameters = New Structure;
	
#Region Assembly

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Assembly);
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.UnderDevelopment);
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	BOMSelectionParameters.Insert("Assembly", TSSpecificationSelectionParameters);
	
#EndRegion
	
#Region Repair

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Repair);
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.UnderDevelopment);
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	BOMSelectionParameters.Insert("Repair", TSSpecificationSelectionParameters);
	
#EndRegion

#Region PerformRM

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.UnderDevelopment);
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ChoiceParameterLinks = New Structure(ProductDataManagementClientServer.ProductDataStructureFieldsForSelectingSpecifications());
	ChoiceParameterLinks.Products   = "Object.WorksToPerform.Products";
	ChoiceParameterLinks.Characteristic = "Object.WorksToPerform.Characteristic";
	ChoiceParameterLinks.UnderRepairProduct   = "Object.WorksToPerform.UnderRepairProduct";
	ChoiceParameterLinks.UnderRepairVariant = "Object.WorksToPerform.UnderRepairVariant";
	
	TSSpecificationSelectionParameters.ChoiceParameterLinks.Insert("Object.WorksToPerform.BillOfMaterials", ChoiceParameterLinks);
	
	BOMSelectionParameters.Insert("PerformRM", TSSpecificationSelectionParameters);
	
#EndRegion
	
#Region Disassembly

	TSSpecificationSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	
	TSSpecificationSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.Disassembly);
	
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.UnderDevelopment);
	TSSpecificationSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	BOMSelectionParameters.Insert("Disassembly", TSSpecificationSelectionParameters);
	
#EndRegion

	Return BOMSelectionParameters;

EndFunction

//The names of the details, the values of which depend on the selection parameters spec
//
//	Returns:
//		String - the names of the details, separated by commas
//
Function NamesOfDetailsForFillingInParametersForSelectingSpecifications() Export
	
	AttributesNames = "";
	Return AttributesNames;
	
EndFunction

// Returns the parameters of the distribution of the costs of the output product.
//
// Parameters:
//   Object - Structure - the structure of the values of the details object required to populate the parameters of cost allocation.
// 
// Returns:
//  Structure - parameters specifying the specifics of the distribution of costs for output products.
//
Function CostAllocationParameters(Object) Export
	
	CostAllocationParameters = ProductionClientServer.CostAllocationParametersForOutputProducts("ManufacturedProducts", Object.MethodOfAllocatingFinishedProductCosts);
	
	If Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly Then
		CostAllocationParameters.AutoCalculationOfAnyCharacteristic = True;
	EndIf;
	
	CostAllocationParameters.ThereIsParameterizationOfResourceSpecification = True;
	
	CostAllocationParameters.CalculateShareCostPercentageField = True;
	CostAllocationParameters.ThisFlagIndicatesThatThereAreFillInErrors = True;
	CostAllocationParameters.CalculateShareOfCostAttributeRequired = True;
	CostAllocationParameters.ParametersForFillingInCostShares.Date = 
								?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Date"), 
								Object.Date, 
								Date("00010101"));
	CostAllocationParameters.ParametersForFillingInCostShares.Currency = 
								?(CommonClientServer.HasAttributeOrObjectProperty(Object, "Currency"), 
								Object.Currency, 
								Catalogs.Currencies.EmptyRef());
	
	CostAllocationParameters.LinkFields = "Products,Characteristic,StageEditing";
	CostAllocationParameters.ReadOnly = True;
	
	Return CostAllocationParameters;
	
EndFunction

// Returns the specifications that include the semi-finished product produced / processed according to the specified specification
//
// Parameters:
//  BillOfMaterials - CatalogRef.BillsOfMaterials - semi-finished product specification
// 
// Returns:
//  Array - dependent specifications
//
Function DependentSpecifications(BillOfMaterials) Export
	
	Query = New Query(
	"SELECT DISTINCT
	|	Table.Ref AS Ref
	|FROM
	|	(
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials = &BillOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS Table
	|WHERE
	|	Table.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials = &BillOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND Table.ProducedInProcess
	|	AND Table.SourceOfSemiFinishedProduct = &BillOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|	AND Table.ProducedInProcess
	|	AND Table.BillOfMaterialsRM = &BillOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref
	|FROM
	|	InformationRegister.ProductsBOM AS ProductsBOM
	|	
	|		INNER JOIN Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|		ON ProductsBOM.ProductKind = Table.Products.ProductKind
	|			AND ProductsBOM.Products IN (Table.Products, VALUE(Catalog.Products.EmptyRef))
	|			AND ProductsBOM.Characteristic IN (VALUE(Catalog.ItemsCharacteristics.EmptyRef), Table.Characteristic)
	|			AND Table.ProducedInProcess
	|			AND Table.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|			AND Table.SourceOfSemiFinishedProduct = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|			AND Table.Ref.Status = VALUE(Enum.BOMStatuses.Valid)
	|			
	|WHERE
	|	ProductsBOM.BillOfMaterials = &BillOfMaterials
	|	AND ProductsBOM.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Assembly)
	|	AND ProductsBOM.SideExit = FALSE
	|
	|) AS Table");
	Query.SetParameter("BillOfMaterials", BillOfMaterials);
	
	SetPrivilegedMode(True);
	Return Query.Execute().Unload().UnloadColumn(0);
	
EndFunction

// Returns a reference to a specification stage that has a single stage production process
//
// Parameters:
//  BillOfMaterials	- CatalogRef.BillsOfMaterials - specification to check the stages of
//
// Returns:
//   CatalogRef.ProductionStages - single-stage specification stage
//
Function GetStageOfSingleStepProcess(BillOfMaterials) Export

	Query = New Query("
	|SELECT TOP 1
	|	Stages.Ref
	|FROM
	|	Catalog.ProductionStages AS Stages
	|WHERE
	|	NOT Stages.DeletionMark
	|	AND Stages.Owner = &Owner
	|
	|ORDER BY
	|	StageNumber,
	|	Ref");
	Query.SetParameter("Owner", BillOfMaterials);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();
	
	Return Selection.Ref;

EndFunction

// Checks whether the quantity of the ordered product meets the restrictions on the batch size:
// minimum and optimal batch size, batch multiplicity.
// 
// Parameters:
// 	SpecificationData - See Catalogs.BillsOfMaterials.SpecificationData
// 	Count - Number - batch size in basic units of the ordered product (specification Data.Main products).
// 	Cancel - Boolean - check result: if the check fails, the variable is set to True.
// 	FailureMessages - Array - the array contains the verification error texts.
//
Procedure CheckBatchSize(SpecificationData, Count, Cancel, FailureMessages) Export
	
	// Checking for the optimal/minimum batch
	If SpecificationData.ProductionIssueByCustomPortions Then
		ZoomRatio = SpecificationData.MainProduct.ConversionFactorToMainProduct;
	Else
		PackageData = SpecificationData.MainProduct.PackageData;
		ZoomRatio = SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
			* PackageData.Numerator / PackageData.Denominator;
	EndIf;
	
	MinimumOutput    = Round(SpecificationData.MinimumReleaseLot * ZoomRatio, 3);
	OptimalRelease    = Round(SpecificationData.EconomicReleaseLot * ZoomRatio, 3);
	AllowableExcessOf = Round(SpecificationData.PermissibleExcessOfOptimalReleaseLot * ZoomRatio, 3);
	
	If MinimumOutput <> 0
		And Count < MinimumOutput Then
		
		Cancel = True;
		FailureMessages.Add(
			StrTemplate(
				NStr("vi = 'Kích thước lô nhỏ hơn giá trị đặc điểm tối thiểu theo bảng kê chi tiết các nguồn lực sản xuất (%1%2).';
					|ru = 'Размер партии меньше минимально допустимого значения по спецификации (%1 %2).';
					|en = 'Lot size is less than minimum allowable value according to BOM (%1 %2).'; fa = 'Lot size is less than minimum allowable value according to BOM (%1 %2).';
					|it = 'La dimensione del lotto è inferiore al valore minimo consentito per specifica (%1 %2).';
					|pl = 'Rozmiar partii jest mniejszy niż dopuszczalna wartość wg specyfikacji (%1 %2).';
					|tr = 'Lot büyüklüğü, ürün reçetesine göre kabul edilebilir minimum değerden daha azdır (%1 %2).'"),
				Format(MinimumOutput, "NG="),
				SpecificationData.MainProduct.UnitOfMeasure));
		
	ElsIf OptimalRelease <> 0
		And Count > (OptimalRelease + AllowableExcessOf) Then
		
		Cancel = True;
		FailureMessages.Add(
			StrTemplate(
				NStr("vi = 'Kích thước lô lớn hơn giá trị thông số tối ưu theo bảng kê chi tiết các nguồn lực sản xuất (%1%2).';
					|ru = 'Размер партии больше оптимального значения по спецификации (%1 %2).';
					|en = 'Lot size is greater than optimum value according to BOM (%1 %2).'; fa = 'Lot size is greater than optimum value according to BOM (%1 %2).';
					|it = 'La dimensione del lotto è superiore al valore ottimale per specifica (%1 %2).';
					|pl = 'Rozmiar partii jest większy niż optymalna wartość wg specyfikacji (%1 %2).';
					|tr = 'Lot büyüklüğü, ürün reçetesine göre optimum değerden daha büyüktür (%1 %2).'"),
				Format(OptimalRelease + AllowableExcessOf, "NG="),
				SpecificationData.MainProduct.UnitOfMeasure));
		
	EndIf;
	
	// Checking for the multiplicity of the issue
	If Not SpecificationData.ProductionIssueByCustomPortions
		And Not Cancel Then
		
		QuantityPerReleaseLotUnit = SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
			* PackageData.Numerator / PackageData.Denominator;
		
		If Count % QuantityPerReleaseLotUnit <> 0 Then
			
			Cancel = True;
			FailureMessages.Add(
				StrTemplate(
					NStr("vi = 'Kích thước lô không phải là bội số của giá trị quy chuẩn theo bảng kê chi tiết các nguồn lực sản xuất (%1%2).';
						|ru = 'Размер партии не кратен нормативному значению по спецификации (%1 %2).';
						|en = 'Lot size is not a multiple of the normative value according to BOM (%1 %2).'; fa = 'Lot size is not a multiple of the normative value according to BOM (%1 %2).';
						|it = 'La dimensione del lotto non è un multiplo del valore normativo per specifica (%1 %2).';
						|pl = 'Rozmiar partii nie jest podzielny z normatywną wartością wg specyfikacji (%1 %2).';
						|tr = 'Lot büyüklüğü, ürün reçetesine göre normatif değerin katı değildir (%1 %2).'"),
					Format(QuantityPerReleaseLotUnit, "NG="),
					SpecificationData.MainProduct.UnitOfMeasure));
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Checks the type of the data string specic and
//
// Parameters:
//  LineKind - String - View of the specification data line
// 
// Returns:
//  Boolean - True if the string TS is Materials and works
//
Function ThisIsLineTSMaterialsAndWorks(LineKind) Export

	If LineKind = Enums.TypesOfSpecificationLines.Material
		Or LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

// Assigns the appropriate string type to the intermediate release and intermediate semi-finished products of the specification data.
// 
// Parameters:
// 	SpecificationData - See DataSpecificationConstructor
// 	SplitLineIfThereIsIncompleteMatch - Boolean
//
// Returns:
// 	Array of ValueTableRow - specification data lines that have been marked as an interim release
//
Function MarkInterimRelease(SpecificationData, SplitLineIfThereIsIncompleteMatch = False) Export
	
	RecyclableWaste = Undefined; // ValueTable
	MaterialsAndServices = Undefined; // ValueTable
	Stages            = Undefined; // ValueTable
	
	LinesIntermediateRelease = New Array;
	
	If Not SpecificationData.Property("RecyclableWaste", RecyclableWaste)
		Or RecyclableWaste.Count() = 0
		Or Not SpecificationData.Property("MaterialsAndServices", MaterialsAndServices)
		Or MaterialsAndServices.Count() = 0 Then
		Return LinesIntermediateRelease;
	EndIf;
	
	CompareValues = New CompareValues;
	GroupFields = New Structure("Products,Characteristic");
	
	Calculations = New ValueTable;
	Calculations.Columns.Add("Products");
	Calculations.Columns.Add("Characteristic");
	Calculations.Indexes.Add("Products,Characteristic");
	
	TableOfCalculation = New ValueTable;
	TableOfCalculation.Columns.Add("Products");
	TableOfCalculation.Columns.Add("Characteristic");
	TableOfCalculation.Columns.Add("StageNumber"); 
	TableOfCalculation.Columns.Add("LinesGroup"); // 0 - receipts, 1 - expenses
	TableOfCalculation.Columns.Add("String");
	TableOfCalculation.Columns.Add("QuantitativeDetails");
	TableOfCalculation.Columns.Add("IsModified");
	
	MaterialsAndServices.Indexes.Add("Products,Characteristic");
	If SpecificationData.Property("Stages", Stages) Then
		Stages.Indexes.Add("Stage");
	EndIf;
	
	For Each ProductLine In RecyclableWaste Do
		
		FinishedProductStageNumber = 0;
		If Stages <> Undefined Then
			ProductStageData = Stages.Find(ProductLine.Stage, "Stage");
			If ProductStageData = Undefined
				Or ProductStageData.NextStageNo = 0 Then
				Continue;
			EndIf;
			FinishedProductStageNumber = ProductStageData.StageNumber;
		EndIf;
		
		FillPropertyValues(GroupFields, ProductLine);
		
		If Calculations.FindRows(GroupFields).UBound() <> -1 Then
			SemiFinishedProduct = TableOfCalculation.Add();
			FillPropertyValues(SemiFinishedProduct, ProductLine);
			SemiFinishedProduct.String = ProductLine;
			SemiFinishedProduct.StageNumber = FinishedProductStageNumber;
			SemiFinishedProduct.LinesGroup = 0;
			SemiFinishedProduct.QuantitativeDetails = QuantitativeAttributesOfDataLineOfSpecification(SemiFinishedProduct.String);
		Else
			ThisIsASemiFinishedProduct = False;
			FoundSemiFinishedProducts = MaterialsAndServices.FindRows(GroupFields);
			
			For Each FoundSemiFinishedProduct In FoundSemiFinishedProducts Do
				If FoundSemiFinishedProduct.ProducedInProcess
						And FoundSemiFinishedProduct.MethodOfReceivingMaterial <> Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage Then
					Continue;
				EndIf;
			
				SemiFinishedProductStageNumber = 0;
				If Stages <> Undefined Then
					SemiFinishedProductStageData = Stages.Find(FoundSemiFinishedProduct.Stage, "Stage");
					If SemiFinishedProductStageData = Undefined Then
						Continue;
					EndIf;
					SemiFinishedProductStageNumber = SemiFinishedProductStageData.StageNumber;
				EndIf;
			
				ThisIsASemiFinishedProduct = True;
				SemiFinishedProduct = TableOfCalculation.Add();
				FillPropertyValues(SemiFinishedProduct, ProductLine);
				SemiFinishedProduct.String = FoundSemiFinishedProduct;
				SemiFinishedProduct.StageNumber = SemiFinishedProductStageNumber;
				SemiFinishedProduct.LinesGroup = 1;
				SemiFinishedProduct.QuantitativeDetails = QuantitativeAttributesOfDataLineOfSpecification(SemiFinishedProduct.String);
			EndDo;
			
			If ThisIsASemiFinishedProduct Then 
				SemiFinishedProduct = TableOfCalculation.Add();
				FillPropertyValues(SemiFinishedProduct, ProductLine);
				SemiFinishedProduct.String = ProductLine;
				SemiFinishedProduct.StageNumber = FinishedProductStageNumber;
				SemiFinishedProduct.LinesGroup = 0;
				SemiFinishedProduct.QuantitativeDetails = QuantitativeAttributesOfDataLineOfSpecification(SemiFinishedProduct.String);
				FillPropertyValues(Calculations.Add(), ProductLine);
			EndIf;
			
		EndIf; 
		
	EndDo;
	
	TableOfCalculation.Sort("Products, Characteristic, LinesGroup, StageNumber", CompareValues);
	
	GroupFields.Products = Undefined;
	GroupFields.Characteristic = Undefined;
	
	IndexOfProduct = -1;
	ProductBoundary = -1;
	
	For CurIndex__ = 0 To TableOfCalculation.Count() - 1 Do
		
		CurRow = TableOfCalculation[CurIndex__];
		
		If GroupFields.Products <> CurRow.Products Or GroupFields.Characteristic <> CurRow.Characteristic Then
			FillPropertyValues(GroupFields, CurRow);
			IndexOfProduct = CurIndex__;
			ProductBoundary = -1;
		EndIf;
		If CurRow.LinesGroup = 0 Then
			ProductBoundary = CurIndex__;
			Continue;
		EndIf;
		
		StringMaterial = CurRow;
		
		While ProductBoundary >= IndexOfProduct And StringMaterial.QuantitativeDetails.Count > 0 Do
			
			ProductLine = TableOfCalculation[IndexOfProduct];
			
			If Stages <> Undefined
				And StringMaterial.StageNumber < ProductLine.StageNumber Then
				Break;
			EndIf; 
			
			Allocated = Min(StringMaterial.QuantitativeDetails.Count, ProductLine.QuantitativeDetails.Count);
			
			ProductLine.QuantitativeDetails.Count = ProductLine.QuantitativeDetails.Count - Allocated;
			ProductLine.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch = ?(ProductLine.QuantitativeDetails.NumberOfPackages > 0,
				ProductLine.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch
					- (Allocated * ProductLine.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch) / ProductLine.QuantitativeDetails.NumberOfPackages,
				0);
			ProductLine.QuantitativeDetails.NumberOfPackages = ProductLine.QuantitativeDetails.Count
					* ProductLine.String.PackageData.Denominator / ProductLine.String.PackageData.Numerator;
			ProductLine.IsModified = True;
			
			StringMaterial.QuantitativeDetails.Count = StringMaterial.QuantitativeDetails.Count - Allocated;
			StringMaterial.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch = ?(StringMaterial.QuantitativeDetails.NumberOfPackages > 0,
				StringMaterial.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch
					- (Allocated * StringMaterial.QuantitativeDetails.NumberOfPackagesPerUnitOfProductionBatch) / StringMaterial.QuantitativeDetails.NumberOfPackages,
				0);
			StringMaterial.QuantitativeDetails.NumberOfPackages = StringMaterial.QuantitativeDetails.Count
					* StringMaterial.String.PackageData.Denominator / StringMaterial.String.PackageData.Numerator;
			StringMaterial.IsModified = True;
			
			If ProductLine.QuantitativeDetails.Count > 0 Then
				Continue;
			EndIf;
			
			IndexOfProduct = IndexOfProduct + 1;
			
		EndDo;
		
	EndDo;
	
	For Each CurRow In TableOfCalculation.FindRows(New Structure("IsModified", True)) Do
		
		If CurRow.QuantitativeDetails.Count = 0
			And Not CurRow.String.Count = 0 Then
				
			CurRow.String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct;
			LinesIntermediateRelease.Add(CurRow.String);
			
		ElsIf CurRow.QuantitativeDetails.Count > 0
			And CurRow.QuantitativeDetails.Count <> CurRow.String.Count Then
			
			If SplitLineIfThereIsIncompleteMatch Then
			
				Table = CurRow.String.Owner(); // ValueTable
				
				NewRow = Table.Insert(Table.IndexOf(CurRow.String));
				FillPropertyValues(NewRow, CurRow.String);
				FillPropertyValues(NewRow, CurRow.QuantitativeDetails);
				
				For Each KeyAndValue In CurRow.QuantitativeDetails Do
					CurRow.String[KeyAndValue.Key] =
						CurRow.String[KeyAndValue.Key] - CurRow.QuantitativeDetails[KeyAndValue.Key];
				EndDo;
				
			EndIf;
			
			CurRow.String.LineKind = Enums.TypesOfSpecificationLines.IntermediateSemiFinishedProduct;
			LinesIntermediateRelease.Add(CurRow.String);
			
		EndIf;
		
	EndDo;
	
	Return LinesIntermediateRelease;
	
EndFunction

// Excludes intermediate release and intermediate semi-finished products from these specifications.
// 
// Parameters:
// 	SpecificationData - See DataSpecificationConstructor
//
Procedure ExcludeIntermediateRelease(SpecificationData) Export
	
	LinesIntermediateRelease = MarkInterimRelease(SpecificationData, True);
	
	For Each String In LinesIntermediateRelease Do
		String.Owner().Delete(String);
	EndDo;

EndProcedure

// Names of the main tabular parts of resource storage
// 
// Returns:
//  Array of String
Function TabularSectionNames() Export
	
	Result = New Array;
	
	Result.Add("ManufacturedProducts");
	Result.Add("RecyclableWaste");
	Result.Add("MaterialsAndServices");
	Result.Add("LaborCosts");
	
	Return Result;
	
EndFunction

#EndRegion

#EndRegion

#EndIf

#Region EventHandlers

Procedure ChoiceDataGetProcessing(ChoiceData, Parameters, StandardProcessing)
	
	ProductDataManagementServerCall.ResourceSpecificationsProcessingOfSelectionDataAcquisition(
				ChoiceData,
				Parameters, 
				StandardProcessing);
	
EndProcedure

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)
	
	ProductDataManagementServerCall.ResourceSpecificationsFormReceiptProcessing(
				FormType,
				Parameters,
				SelectedForm,
				StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region FillChecking

// Tests of nested specifications
// 
// Parameters:
// 	Object - CatalogObject.BillsOfMaterials - current specification
// 	Cancel - Boolean - The flag of failure
//
Procedure CheckNestedSpecifications(Object, Cancel) Export
	
	List = New Array();
	RowsMap = New Map;
	
	For Each String In Object.ManufacturedProducts Do
		If String.ProcessByBOM Then
			AddNestedSpecificationToList(List, RowsMap, "ManufacturedProducts", String, "BillOfMaterials");
		EndIf;
	EndDo;
	
	For Each String In Object.RecyclableWaste Do
		If String.ProcessByBOM Then
			AddNestedSpecificationToList(List, RowsMap, "RecyclableWaste", String, "BillOfMaterials");
		EndIf;
	EndDo;
	
	For Each String In Object.MaterialsAndServices Do
		If String.ProducedInProcess Then
			If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials Then
				AddNestedSpecificationToList(
					List,
					RowsMap,
					"MaterialsAndServices",
					String,
					"SourceOfSemiFinishedProduct");
			ElsIf String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
				And ValueIsFilled(String.BillOfMaterialsRM)
				And Object.ProductionProcessType = Enums.ProductionProcessTypes.Repair Then
				AddNestedSpecificationToList(
					List,
					RowsMap,
					"MaterialsAndServices",
					String,
					"BillOfMaterialsRM");
			EndIf;
		EndIf;
	EndDo;
	
	If List.UBound() = -1 Then
		Return;
	EndIf;
	
	Query = New Query(
	"SELECT
	|	NestedQuery.Ref AS Ref,
	|	NestedQuery.StatusIsNotValid AS StatusIsNotValid
	|FROM
	|	(SELECT
	|		Table.Ref AS Ref,
	|		CASE
	|			WHEN Table.Status <> VALUE(Enum.BOMStatuses.Valid)
	|				THEN TRUE
	|			ELSE FALSE
	|		END AS StatusIsNotValid
	|	FROM
	|		Catalog.BillsOfMaterials AS Table
	|	WHERE
	|		Table.Ref IN(&Specifications)) AS NestedQuery
	|WHERE
	|	NestedQuery.StatusIsNotValid
	|	AND NestedQuery.Ref <> &BillOfMaterials");
	Query.SetParameter("BillOfMaterials", Object.Ref);
	Query.SetParameter("Specifications", List);
	
	QueryResult = Query.Execute();
	
	If Not QueryResult.IsEmpty() Then
		
		Selection = QueryResult.Select();
		While Selection.Next() Do

			TSRow = RowsMap[Selection.Ref][0]; // LineOfATabularSection
			ListName = Metadata.Catalogs.BillsOfMaterials.TabularSections[TSRow.TSName].Synonym;
			
			ErrorText = NStr("vi = 'Chú ý! Bảng kê chi tiết ""%1"" không phải là bảng hợp lệ (xem danh sách ""%2"", dòng %3)';
							|ru = 'Внимание! Спецификация ""%1"" не является действующей (см. список ""%2"", строка %3)';
							|en = 'Warning. The %1 BOM is invalid. See the %2 list, line %3'; fa = 'Warning. The %1 BOM is invalid. See the %2 list, line %3';
							|it = 'Внимание! Спецификация ""%1"" не является действующей (см. список ""%2"", строка %3)';
							|pl = 'Warning. The %1 BOM is invalid. See the %2 list, line %3';
							|tr = 'Uyarı! ""%1"" ürün reçetesi geçerli değildir (bk. ""%2"" listesi, %3 satırı)'");
			ErrorText = StrTemplate(ErrorText, Selection.Ref, ListName, TSRow.LineNumber);
			
			Field = CommonClientServer.PathToTabularSection(
				TSRow.TSName,
				TSRow.LineNumber,
				TSRow.FieldName);
		
			Common.MessageToUser(
				ErrorText,
				Object,
				Field);
			
		EndDo;
		
	EndIf;
	
	CheckLoopingSpecifications(Object.Ref, List, Cancel);
	
EndProcedure

Procedure CheckLoopingSpecifications(BillOfMaterials, NestedSpecifications = Undefined, Cancel)
	
	ErrorList    = New Array(2);
	Queue         = New Array();
	Count_            = ProductionManagement.Count_();
	ThereAreCyclesInGraph = False;
	
	Query = New Query(
	"SELECT DISTINCT
	|	Table.Ref       AS Vertex,
	|	Table.BillOfMaterials AS AdjacentVertex
	|FROM
	|	&Table AS Table");
	Query.Text = StrReplace(Query.Text, "&Table", "("+QueryTextNestedSpecifications()+")");
	
	If NestedSpecifications <> Undefined Then // maintenance of an unsigned object
		ObjectRequest = New Query(
		"SELECT
		|	&BillOfMaterials  AS Vertex,
		|	Table.Ref AS AdjacentVertex
		|FROM
		|	Catalog.BillsOfMaterials AS Table
		|WHERE
		|	Table.Ref IN (&Specifications)");
		ObjectRequest.SetParameter("BillOfMaterials", BillOfMaterials);
		ObjectRequest.SetParameter("Specifications", NestedSpecifications);
		Selection = ObjectRequest.Execute().Select();
	Else
		Query.SetParameter("Specifications", BillOfMaterials);
		Selection = Query.Execute().Select();
	EndIf;
	
	While Selection.Count() > 0 Do
		
		While Selection.Next() Do
			
			If Selection.Vertex = Selection.AdjacentVertex Then
				ErrorList[0] = Selection.Vertex;
				ErrorList[1] = Selection.Vertex;
				ThereAreCyclesInGraph = True;
				Break;
			Else
				CurrentVertex = ProductionManagement.GetVertexOfGraphFromLink(Count_, Selection.Vertex);
				ProductionManagement.AddAdjacentVertexToAdjacencyList(CurrentVertex, Selection.AdjacentVertex);
				ProductionManagement.GetVertexOfGraphFromLink(Count_, Selection.AdjacentVertex);
			EndIf;
			
			Queue.Add(Selection.AdjacentVertex);
		
		EndDo;
		
		If ThereAreCyclesInGraph Or ProductionManagement.ThereAreCyclesInGraph(Count_, ErrorList[0], ErrorList[1]) Then
			ThereAreCyclesInGraph = True;
			Break;
		EndIf;
		
		Query.SetParameter("Specifications", Queue);
		Selection = Query.Execute().Select();
		Queue.Clear();
		
	EndDo;
	
	If ThereAreCyclesInGraph Then
		ErrorText = NStr("vi = 'Sử dụng bảng kê chi tiết các nguồn lực sản xuất ""%2"" trong bảng kê chi tiết các nguồn lực sản xuất ""%1"" dẫn đến một vòng lặp.';
						|ru = 'Использование в спецификации ""%1"" спецификации ""%2"" приводит к зацикливанию.';
						|en = 'Using the ""%2"" BOM in the ""%1"" BOM causes looping.'; fa = 'Using the ""%2"" BOM in the ""%1"" BOM causes looping.';
						|it = 'L''uso della specifica ""%2"" all''interno della specifica ""%1"" causa un ciclo.';
						|pl = 'Używanie w specyfikacji ""%1"" specyfikacji ""%2"" prowadzi do zapętlenia.';
						|tr = '""%1"" ürün reçetesinde ""%2"" ürün reçetesinin kullanılması döngüyle sonuçlanır.'");
		ErrorText = StrTemplate(ErrorText, ErrorList[0], ErrorList[1]);
		Common.MessageToUser(ErrorText,,,, Cancel);
	EndIf;
	
EndProcedure

Procedure AddNestedSpecificationToList(List, RowsMap, TSName, String, FieldName = "BillOfMaterials")
	
	List.Add(String[FieldName]);
	RowPath = New Structure("TSName, LineNumber, FieldName", TSName, String.LineNumber, FieldName);
	
	If RowsMap[String[FieldName]] = Undefined Then
		DataPaths = New Array;
		DataPaths.Add(RowPath);
		RowsMap.Insert(String[FieldName], DataPaths);
	Else
		DataPaths = RowsMap[String[FieldName]]; // Array
		DataPaths.Add(RowPath);
	EndIf;
	
EndProcedure

// Checks whether the route map is specified correctly in the specification stage
// 
// Parameters:
// 	ValidOnDate - Date - start of the specification
// 	ValidToDate - Date - end of the specification
// 	RouteSheet - CatalogObject.RouteSheets
// 	Stage - CatalogRef.ProductionStages
// 	StagePresentation - String
// 	Cancel - Boolean
Procedure CheckCorrectnessOfRouteMap(
	ValidOnDate, ValidToDate, RouteSheet, Stage, StagePresentation, Cancel) Export
	
	MessageTemplate = NStr("vi = 'Trong công đoạn ""%1"" cần chỉ ra sơ đồ quy trình hợp lệ.';
							|ru = 'В этапе ""%1"" необходимо указать действующую маршрутную карту.';
							|en = 'Specify a valid route sheet for stage ""%1"".'; fa = 'Specify a valid route sheet for stage ""%1"".';
							|it = 'Nella fase ""%1"" è necessario indicare una scheda di lavorazione funzionante.';
							|pl = 'Dla etapu ""%1"" należy wskazać aktualną kartę technologiczną.';
							|tr = '""%1"" aşamasında geçerli bir rota belirtmeniz gerekmektedir.'");
	DataKey = Stage;
	
	If RouteSheet.Status <> Enums.StatusesOfRouteSheets.Valid
		
		// The start of the route map must be 
		// no later than the end of the specification
		Or RouteSheet.ValidOnDate <> '000101010000'
			And ValidToDate <> '000101010000'
			And RouteSheet.ValidOnDate > ValidToDate
			
		// The end of the validity of the route map should 
		// not be earlier than the beginning of the validity of the specification
		Or RouteSheet.ValidToDate <> '000101010000'
			And ValidOnDate <> '000101010000'
			And RouteSheet.ValidToDate <= ValidOnDate Then 
			
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, TrimAll(StagePresentation));
		CommonClientServer.MessageToUser(MessageText, DataKey, "RouteSheet",, Cancel);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region SpecificationsData

#Region IsMain

// Retrieves specification data from the specified list of item data
// 
// Parameters:
// 	ListDataStructure - See ItemList
// 	SelectionParameters - See DataSamplingParameters
// 
// Returns:
// Map of KeyAndValue:
// * Key - Number
// * Value - See DataSpecificationConstructor
//
Function SpecificationData(ListDataStructure, SelectionParameters) Export
	
	ListOfData = Undefined;
	If Not SelectionParameters.Property("ListOfData", ListOfData) Or Not ValueIsFilled(ListOfData) Then
		ListOfData = ListOfSpecificationData();
	EndIf;
	
	SourcesOfResourceParameterization = CommonClientServer.ArraysDifference(
		StrSplit("ManufacturedProducts,MaterialsAndServices",","), ListOfData);
	If SourcesOfResourceParameterization.UBound() <> -1 Then
		ListOfData = Common.CopyRecursive(ListOfData, False);
		CommonClientServer.SupplementArray(ListOfData, SourcesOfResourceParameterization);
	EndIf;
	
	TempTablesManager = Undefined;
	If Not SelectionParameters.Property("TempTablesManager", TempTablesManager)
		Or TempTablesManager = Undefined
		Then
		TempTablesManager = New TempTablesManager;
	EndIf;
	
	DynamicStructure = False;
	DynamicStructure = GetFunctionalOption("DynamicStructureOfProductionOrders");
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("EmptyLinkKey", CommonClientServer.BlankUUID());
	Query.SetParameter("DynamicStructureOfProductionOrders", DynamicStructure);
	
	ListOfTablesToDelete = New Array;
	
	RequestSeparatorInPacket_ = Common.QueryBatchSeparator();
	
	QueryTexts = New ValueList;
	
	#Region TTProductData_
	
	QueryText = "
	|SELECT
	|	T.Id             AS Id,
	|	T.BillOfMaterials              AS BillOfMaterials,
	|	T.Products              AS Products,
	|	T.Characteristic            AS Characteristic,
	|	T.Count                AS Count,
	|	T.ProductionDispatcherBusinessUnit    AS ProductionDispatcherBusinessUnit,
	|	T.AssigneeBusinessUnit  AS AssigneeBusinessUnit,
	|	T.LineOfBusiness   AS LineOfBusiness,
	|	T.ReferenceOrder              AS ReferenceOrder,
	|	T.Purpose                AS Purpose,
	|	T.ProductionStart        AS ProductionStart,
	|
	|	CASE
	|		WHEN T.Product = VALUE(Catalog.Products.EmptyRef)
	|			THEN T.Products
	|		ELSE T.Product
	|	END                                 AS Product,
	|	CASE
	|		WHEN T.Product = VALUE(Catalog.Products.EmptyRef)
	|			THEN T.Characteristic
	|		ELSE T.ItemVariantOfProduct
	|	END                                 AS ItemVariantOfProduct,
	|	CASE
	|		WHEN T.Product = VALUE(Catalog.Products.EmptyRef)
	|			THEN T.BillOfMaterials
	|		ELSE T.ProductSpecification
	|	END                                 AS ProductSpecification,
	|	CASE
	|		WHEN T.Product = VALUE(Catalog.Products.EmptyRef)
	|			THEN VALUE(Catalog.ProductionStages.EmptyRef)
	|		ELSE T.ProductSpecificationStage
	|	END                                 AS ProductSpecificationStage
	|
	|INTO TTProductData_
	|FROM
	|	&ProductDataSet AS T
	|
	|INDEX BY
	|	BillOfMaterials, Id
	|
	|";
	
	If TypeOf(ListDataStructure) = Type("ValueTable") Then
		ProductDataSet = ListDataStructure;
	Else
		ProductDataSet = ItemList();
		FillPropertyValues(ProductDataSet.Add(), ListDataStructure);
	EndIf;
	
	If ProductDataSet.Count() = 1 Then
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Catalog.BillsOfMaterials.ManagerModule.SpecificationData_1");
		MeasurementWeight = 1;
	Else
		MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement("Catalog.BillsOfMaterials.ManagerModule.SpecificationData");
		MeasurementWeight = ProductDataSet.Count() / 10;
	EndIf;
	
	Query.SetParameter("ProductDataSet", ProductDataSet);
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("Id",            0);
	
	AdditionalParameters.Insert("ProductionDispatcherBusinessUnit",   Catalogs.BusinessStructure.EmptyRef());
	AdditionalParameters.Insert("AssigneeBusinessUnit", Catalogs.BusinessStructure.EmptyRef());
	AdditionalParameters.Insert("LineOfBusiness",  Catalogs.LinesOfBusiness.EmptyRef());
	AdditionalParameters.Insert("ReferenceOrder",             Catalogs.BillsOfMaterials.EmptyRef());
	AdditionalParameters.Insert("Purpose",               Catalogs.Assignments.EmptyRef());
	AdditionalParameters.Insert("ProductionStart",       Date(1,1,1));
	
	AdditionalParameters.Insert("Product",                  Catalogs.Products.EmptyRef());
	AdditionalParameters.Insert("ItemVariantOfProduct",    Catalogs.ItemsCharacteristics.EmptyRef());
	AdditionalParameters.Insert("ProductSpecification",      Catalogs.BillsOfMaterials.EmptyRef());
	AdditionalParameters.Insert("ProductSpecificationStage",  Catalogs.ProductionStages.EmptyRef());
	
	For Each KeyAndValue In AdditionalParameters Do
		ParameterName = KeyAndValue.Key;
		If ProductDataSet.Columns.Find(ParameterName) = Undefined Then
			QueryText = StrReplace(QueryText, StrTemplate("T.%1%2", ParameterName, " "),        "&"+ParameterName);
			QueryText = StrReplace(QueryText, StrTemplate("T.%1%2", ParameterName, Chars.LF), "&"+ParameterName);
			Query.SetParameter(ParameterName, KeyAndValue.Value);
		EndIf;
	EndDo;
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_);
	
	ListOfTablesToDelete.Add("TTProductData_");
	
	#EndRegion
	
	#Region TTWares
	
	QueryText = "
	|SELECT
	// 0 - Output, 1 - Input, 2 - Side
	|	0                                                   AS Product_Type,
	|	TTProductData_.Id                AS Id,
	|	TTProductData_.BillOfMaterials                 AS BillOfMaterials,
	|	TTProductData_.ProductionDispatcherBusinessUnit       AS ProductionDispatcherBusinessUnit,
	|	TTProductData_.AssigneeBusinessUnit     AS AssigneeBusinessUnit,
	|	TTProductData_.LineOfBusiness      AS LineOfBusiness,
	|	TTProductData_.ReferenceOrder                 AS ReferenceOrder,
	|	TTProductData_.Purpose                   AS Purpose,
	|	TTProductData_.ProductionStart           AS ProductionStart,
	|
	|	ManufacturedProducts.LineNumber                         AS LineNumber,
	|
	|	ManufacturedProducts.ProductKind                     AS ProductKind,
	|	&OutputProductsSourceOfProducts                AS Products,
	|	&OutputProductsSourceSpecifications              AS Characteristic,
	|	
	|	&OutputProductsSourceTSOCharacteristics            AS PricingVariant,
	|	&OutputProductsSourceTSOSeries                     AS PricingBatch,
	|	&OutputProductsSourceOfTSOPackaging                  AS PricingPackage,
	|	
	|	ManufacturedProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)                   AS MethodOfReceivingMaterial,
	|	FALSE                                                                                          AS WithAssignment,
	|
	|	ManufacturedProducts.Stage                                AS Stage,
	|	ManufacturedProducts.Operation                            AS Operation,
	|
	|	CAST(ManufacturedProducts.NumberOfPackages * ISNULL(&OutputProductsPackingRatio, 1) AS NUMBER(15,3)) AS Count,
	|	ManufacturedProducts.NumberOfPackages                                                                              AS NumberOfPackages,
	|
	|	ManufacturedProducts.Package                            AS Package,
	|	ISNULL(&OutputProductsPackingRatio, 1)    AS PackagingFactor,
	|
	|	ManufacturedProducts.ShareOfNonconformity                        AS ShareOfNonconformity,
	|
	|	ManufacturedProducts.CostShare                       AS CostShare,
	|	UNDEFINED                                        AS ProductCostElement,
	|	ManufacturedProducts.Ref.ProductionProcessType AS ProductionProcessType,
	|	CASE
	|		WHEN ManufacturedProducts.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|				AND NOT &DynamicStructureOfProductionOrders
	|			THEN ManufacturedProducts.ProcessByBOM
	|		ELSE FALSE
	|	END                                               AS ProcessByBOM,
	|	CASE
	|		WHEN ManufacturedProducts.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|				AND NOT &DynamicStructureOfProductionOrders
	|			THEN ManufacturedProducts.BillOfMaterials
	|		ELSE UNDEFINED
	|	END                                               AS ProcessBySpecificationSpecification,
	|	FALSE                                                AS ItIsSubjectToRAndM,
	|	ManufacturedProducts.MethodOfProductsAutoselection        AS MethodOfProductsAutoselection,
	|	ManufacturedProducts.MethodOfItemVariantAutoselection      AS MethodOfItemVariantAutoselection,
	|	ManufacturedProducts.PropertyThatContainsProducts      AS PropertyThatContainsProducts,
	|	ManufacturedProducts.ItemVariantAutoSelectionAlgorithm    AS ItemVariantAutoSelectionAlgorithm,
	|	ManufacturedProducts.QuantityCalculationAlgorithm           AS QuantityCalculationAlgorithm,
	|	ManufacturedProducts.ProductDescription                     AS ProductDescription,
	|	ManufacturedProducts.ConnectionKey                           AS ConnectionKey,
	|
	|	CASE WHEN ManufacturedProducts.Ref.ProductionProcessType IN (
	|					VALUE(Enum.ProductionProcessTypes.Assembly),
	|					VALUE(Enum.ProductionProcessTypes.PerformRM),
	|					VALUE(Enum.ProductionProcessTypes.Repair))
	|		AND (ManufacturedProducts.LineNumber = 1)
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS ThisIsMainProduct,
	|
	|	CASE WHEN ManufacturedProducts.Ref.ProductionProcessType IN (
	|					VALUE(Enum.ProductionProcessTypes.Assembly),
	|					VALUE(Enum.ProductionProcessTypes.PerformRM),
	|					VALUE(Enum.ProductionProcessTypes.Repair))
	|		AND (ManufacturedProducts.Products = TTProductData_.Products
	|			OR TTProductData_.Products = VALUE(Catalog.Products.EmptyRef)
	|				AND ManufacturedProducts.LineNumber = 1
	|			OR ManufacturedProducts.Products = VALUE(Catalog.Products.EmptyRef)
	|				AND ManufacturedProducts.ProductKind = TTProductData_.Products.ProductKind
	|				AND ManufacturedProducts.LineNumber = 1)
	|		AND (TTProductData_.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				AND ManufacturedProducts.LineNumber = 1
	|			OR ManufacturedProducts.Characteristic = TTProductData_.Characteristic
	|			OR ManufacturedProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                               AS CorrespondsToProductData,
	|
	|	ManufacturedProducts.Ref.RecordMethodOfMaterialTransferBetweenStagesLots AS RecordMethodOfMaterialTransferBetweenStagesLots
	|
	|INTO TTWares
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS ManufacturedProducts
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON ManufacturedProducts.Ref = TTProductData_.BillOfMaterials
	|
	|UNION ALL
	|
	|SELECT
	|	1                                               AS Product_Type,
	|	TTProductData_.Id            AS Id,
	|	TTProductData_.BillOfMaterials             AS BillOfMaterials,
	|	TTProductData_.ProductionDispatcherBusinessUnit   AS ProductionDispatcherBusinessUnit,
	|	TTProductData_.AssigneeBusinessUnit AS AssigneeBusinessUnit,
	|	TTProductData_.LineOfBusiness  AS LineOfBusiness,
	|	TTProductData_.ReferenceOrder             AS ReferenceOrder,
	|	TTProductData_.Purpose               AS Purpose,
	|	TTProductData_.ProductionStart       AS ProductionStart,
	|
	|	0                                               AS LineNumber,
	|
	|	InputProducts.MainProductProductKind   AS ProductKind,
	|	&InputProductsSourceOfProducts             AS Products,
	|	&InputProductsSourceCharacteristics           AS Characteristic,
	|
	|	UNDEFINED                                    AS PricingVariant,
	|	UNDEFINED                                    AS PricingBatch,
	|	UNDEFINED                                    AS PricingPackage,
	|	
	|	InputProducts.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)                                 AS MethodOfReceivingMaterial,
	|	FALSE                                                                                                        AS WithAssignment,
	|
	|	InputProducts.MainProductStage AS Stage,
	|	UNDEFINED                       AS Operation,
	|
	|	CAST(InputProducts.MainProductNumberOfPackages * ISNULL(&InputProductsPackingRatio, 1) AS NUMBER(15,3)) AS Count,
	|	InputProducts.MainProductNumberOfPackages                                                                             AS NumberOfPackages,
	|
	|	InputProducts.MainProductPackage          AS Package,
	|	ISNULL(&InputProductsPackingRatio, 1) AS PackagingFactor,
	|
	|	0                                               AS ShareOfNonconformity,
	|
	|	1                                               AS CostShare,
	|	UNDEFINED                                    AS ProductCostElement,
	|	InputProducts.ProductionProcessType     AS ProductionProcessType,
	|	FALSE                                            AS ProcessByBOM,
	|	UNDEFINED                                    AS ProcessBySpecificationSpecification,
	|	FALSE                                            AS ItIsSubjectToRAndM,
	|	UNDEFINED                                    AS MethodOfProductsAutoselection,
	|	UNDEFINED                                    AS MethodOfItemVariantAutoselection,
	|	UNDEFINED                                    AS PropertyThatContainsProducts,
	|	""""                                            AS ItemVariantAutoSelectionAlgorithm,
	|	""""                                            AS QuantityCalculationAlgorithm,
	|	""""                                            AS ProductDescription,
	|	UUID(InputProducts.Ref)  AS ConnectionKey,
	|
	|	InputProducts.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly) AS ThisIsMainProduct,
	|
	|	CASE WHEN InputProducts.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND (InputProducts.MainProductProducts = TTProductData_.Products
	|				OR TTProductData_.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR InputProducts.MainProductProducts = VALUE(Catalog.Products.EmptyRef)
	|					AND InputProducts.MainProductProductKind = TTProductData_.Products.ProductKind)
	|			AND (TTProductData_.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR InputProducts.MainProductCharacteristic = TTProductData_.Characteristic
	|				OR InputProducts.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                           AS CorrespondsToProductData,
	|
	|	InputProducts.RecordMethodOfMaterialTransferBetweenStagesLots AS RecordMethodOfMaterialTransferBetweenStagesLots
	|
	|FROM
	|	Catalog.BillsOfMaterials AS InputProducts
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON InputProducts.Ref = TTProductData_.BillOfMaterials
	|			AND InputProducts.ProductionProcessType IN (
	|					VALUE(Enum.ProductionProcessTypes.Repair),
	|					VALUE(Enum.ProductionProcessTypes.Disassembly))
	|
	|UNION ALL
	|
	|SELECT
	|	2                                                   AS Product_Type,
	|	TTProductData_.Id                AS Id,
	|	TTProductData_.BillOfMaterials                 AS BillOfMaterials,
	|	TTProductData_.ProductionDispatcherBusinessUnit       AS ProductionDispatcherBusinessUnit,
	|	TTProductData_.AssigneeBusinessUnit     AS AssigneeBusinessUnit,
	|	TTProductData_.LineOfBusiness      AS LineOfBusiness,
	|	TTProductData_.ReferenceOrder                 AS ReferenceOrder,
	|	TTProductData_.Purpose                   AS Purpose,
	|	TTProductData_.ProductionStart           AS ProductionStart,
	|
	|	RecyclableWaste.LineNumber                        AS LineNumber,
	|
	|	ISNULL(RecyclableWaste.Products.ProductKind, VALUE(Catalog.ItemKinds.EmptyRef)) AS ProductKind,
	|	RecyclableWaste.Products                             AS Products,
	|	RecyclableWaste.Characteristic                           AS Characteristic,
	|	
	|	UNDEFINED                                        AS PricingVariant,
	|	UNDEFINED                                        AS PricingBatch,
	|	UNDEFINED                                        AS PricingPackage,
	|	
	|	RecyclableWaste.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)                    AS MethodOfReceivingMaterial,
	|	FALSE                                                                                           AS WithAssignment,
	|
	|	RecyclableWaste.Stage                               AS Stage,
	|	RecyclableWaste.Operation                           AS Operation,
	|
	|	CAST(RecyclableWaste.NumberOfPackages * ISNULL(&ReturnableWastePackingRatio, 1) AS NUMBER(15,3)) AS Count,
	|	RecyclableWaste.NumberOfPackages                                                                               AS NumberOfPackages,
	|
	|	RecyclableWaste.Package                            AS Package,
	|	ISNULL(&ReturnableWastePackingRatio, 1)    AS PackagingFactor,
	|
	|	0                                                    AS ShareOfNonconformity,
	|
	|	1                                                    AS CostShare,
	|	RecyclableWaste.ProductCostElement                   AS ProductCostElement,
	|	RecyclableWaste.Ref.ProductionProcessType AS ProductionProcessType,
	|	CASE
	|		WHEN RecyclableWaste.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|				AND NOT &DynamicStructureOfProductionOrders
	|			THEN RecyclableWaste.ProcessByBOM
	|		ELSE FALSE
	|	END                                                AS ProcessByBOM,
	|	CASE
	|		WHEN RecyclableWaste.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|				AND NOT &DynamicStructureOfProductionOrders
	|			THEN RecyclableWaste.BillOfMaterials
	|		ELSE UNDEFINED
	|	END                                                AS ProcessBySpecificationSpecification,
	|	CASE
	|		WHEN RecyclableWaste.Ref.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.PerformRM)
	|			THEN RecyclableWaste.ProcessByBOM
	|		ELSE FALSE
	|	END                                                AS ItIsSubjectToRAndM,
	|	RecyclableWaste.MethodOfProductsAutoselection        AS MethodOfProductsAutoselection,
	|	RecyclableWaste.MethodOfItemVariantAutoselection      AS MethodOfItemVariantAutoselection,
	|	RecyclableWaste.PropertyThatContainsProducts      AS PropertyThatContainsProducts,
	|	RecyclableWaste.ItemVariantAutoSelectionAlgorithm    AS ItemVariantAutoSelectionAlgorithm,
	|	RecyclableWaste.QuantityCalculationAlgorithm           AS QuantityCalculationAlgorithm,
	|	RecyclableWaste.ProductDescription                     AS ProductDescription,
	|	RecyclableWaste.ConnectionKey                           AS ConnectionKey,
	|
	|	FALSE                                                 AS ThisIsMainProduct,
	|
	|	CASE WHEN RecyclableWaste.Products = TTProductData_.Products
	|				AND RecyclableWaste.Characteristic = TTProductData_.Characteristic
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                                AS CorrespondsToProductData,
	|
	|	RecyclableWaste.Ref.RecordMethodOfMaterialTransferBetweenStagesLots AS RecordMethodOfMaterialTransferBetweenStagesLots
	|
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS RecyclableWaste
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON RecyclableWaste.Ref = TTProductData_.BillOfMaterials
	|
	|INDEX BY
	|	BillOfMaterials, ThisIsMainProduct
	|
	|";
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"ManufacturedProducts.Package",
		"CAST(&OutputProductsSourceOfProducts AS Catalog.Products)");
		
	QueryText = StrReplace(
		QueryText,
		"&OutputProductsPackingRatio",
		QueryTextPackagingFactor);
	
	SubstitutionParametersOutputProducts = SubstitutionParametersProductDescriptionOfMainProduct(
		"ManufacturedProducts",
		"ProductKind",
		"Products",
		"Characteristic");

	UsePriceManagementSystem25 = PriceManagementSystemServerCall.UsePriceManagementSystem25();
	
	If UsePriceManagementSystem25 Then
		QueryText = StrReplace(QueryText, "&OutputProductsSourceTSOCharacteristics", 
											TextOfFieldExpressionCharacteristicsOfMainProductCenter("ManufacturedProducts"));
		QueryText = StrReplace(QueryText, "&OutputProductsSourceTSOSeries",
											"VALUE(Catalog.ItemsBatchesForPricing.EmptyRef)");
		QueryText = StrReplace(QueryText, "&OutputProductsSourceOfTSOPackaging",
											TextOfFieldExpressionPackagingTCOOfMainProduct("ManufacturedProducts"));
	Else
		QueryText = StrReplace(QueryText, "&OutputProductsSourceTSOCharacteristics", "UNDEFINED");
		QueryText = StrReplace(QueryText, "&OutputProductsSourceTSOSeries",          "UNDEFINED");
		QueryText = StrReplace(QueryText, "&OutputProductsSourceOfTSOPackaging",       "UNDEFINED");
	EndIf;
	
	QueryText = StrReplace(QueryText, "&OutputProductsSourceOfProducts",   SubstitutionParametersOutputProducts.SourceProduct);
	QueryText = StrReplace(QueryText, "&OutputProductsSourceSpecifications", SubstitutionParametersOutputProducts.SourceCharacteristics);
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"InputProducts.MainProductPackage",
		"CAST(&InputProductsSourceOfProducts AS Catalog.Products)");
		
	QueryText = StrReplace(
		QueryText,
		"&InputProductsPackingRatio",
		QueryTextPackagingFactor);
	
	SubstitutionParametersInputProducts  = SubstitutionParametersProductDescriptionOfMainProduct(
		"InputProducts",
		"MainProductProductKind",
		"MainProductProducts",
		"MainProductCharacteristic");
		
	QueryText = StrReplace(QueryText, "&InputProductsSourceOfProducts",   SubstitutionParametersInputProducts.SourceProduct);
	QueryText = StrReplace(QueryText, "&InputProductsSourceCharacteristics", SubstitutionParametersInputProducts.SourceCharacteristics);
	
	QueryTextPackagingFactor = Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"RecyclableWaste.Package",
		"CAST(RecyclableWaste.Products AS Catalog.Products)");
		
	QueryText = StrReplace(
		QueryText,
		"&ReturnableWastePackingRatio",
		QueryTextPackagingFactor);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_);
	
	ListOfTablesToDelete.Add("TTWares");
	
	#EndRegion

	#Region IntermediateRelease
	
	If SelectionParameters.IntermediateSemiFinishedProducts = ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet() Then
		
		QueryText =
		"SELECT TOP 1
		|	TRUE AS ThereIsIntermediateRelease
		|FROM
		|	TTWares AS Products_1
		|WHERE
		|	Products_1.RecordMethodOfMaterialTransferBetweenStagesLots IN (
		|		VALUE(Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts),
		|		VALUE(Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.SetUpManually))";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "IntermediateRelease");
		
	EndIf;
	
	#EndRegion
	
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , False, True);
	SetPrivilegedMode(False);
	
	QueryTexts = New ValueList;
	
	#Region TTIntermediateRelease
	
	ThereIsIntermediateRelease = False;
	
	If SelectionParameters.IntermediateSemiFinishedProducts = ProductDataManagementClientServer.IntermediateSemiFinishedProductsGet() Then
		ThereIsIntermediateRelease = Tables.IntermediateRelease.Count() > 0;
	EndIf;
	
	If ThereIsIntermediateRelease Then
		
		QueryText =
		"SELECT DISTINCT
		|	Products_1.Products                            AS Products,
		|	Products_1.Products.UseVariants AS UseVariants,
		|	Products_1.Products.UnitOfMeasure           AS UnitOfMeasure,
		|	Products_1.Products.UsePackages       AS UsePackages,
		|	Products_1.ProductKind                         AS ProductKind,
		|	Products_1.Characteristic                          AS Characteristic,
		|	Products_1.Characteristic.Description             AS CharacteristicName
		|INTO TTProductsForSelectionOfIntermediateRelease
		|FROM
		|	TTWares AS Products_1
		|WHERE
		|	Products_1.ThisIsMainProduct
		|	AND (Products_1.RecordMethodOfMaterialTransferBetweenStagesLots =
		|			VALUE(Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts)
		|		OR TRUE IN (
		|			SELECT TOP 1
		|				TRUE
		|			FROM
		|				Catalog.BillsOfMaterials.IntermediateRelease AS T
		|			WHERE
		|				T.Ref = Products_1.BillOfMaterials
		|				AND T.Products = VALUE(Catalog.Products.EmptyRef)))
		|INDEX BY
		|	Products,
		|	ProductKind,
		|	UseVariants,
		|	UnitOfMeasure,
		|	UsePackages";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTProductsForSelectionOfIntermediateRelease");
		
		//
		
		QueryText =
		"SELECT
		|	AnotherQualityGoods.Products                                AS Products,
		|	AnotherQualityGoods.OtherQualityGoods                            AS OtherQualityGoods,
		|	AnotherQualityGoods.OtherQualityGoods.ProductKind            AS ItemTypeOfNonconformityTypeOfItem,
		|	AnotherQualityGoods.OtherQualityGoods.UseVariants AS ItemsOfNonconformityUseOfCharacteristics,
		|	AnotherQualityGoods.OtherQualityGoods.UnitOfMeasure           AS ItemsOfNonconformityUnitOfMeasurement,
		|	AnotherQualityGoods.OtherQualityGoods.UsePackages       AS ItemsNonconformityOfPackagingUse
		|INTO TTGoodsOfOtherQuality
		|FROM
		|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
		|WHERE
		|	AnotherQualityGoods.Products IN (
		|		SELECT
		|			T.Products
		|		FROM
		|			TTProductsForSelectionOfIntermediateRelease AS T)
		|	AND AnotherQualityGoods.QualityGradation = VALUE(Enum.QualityLevels.SuitableToALimitedExtent)
		|INDEX BY
		|	Products,
		|	ItemTypeOfNonconformityTypeOfItem,
		|	ItemsOfNonconformityUseOfCharacteristics,
		|	ItemsOfNonconformityUnitOfMeasurement,
		|	ItemsNonconformityOfPackagingUse";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTGoodsOfOtherQuality");
		
		//
		
		QueryText =
		"SELECT
		|	Products_1.Products                   AS Products,
		|	Products_1.Characteristic                 AS Characteristic,
		|	AnotherQualityGoods.OtherQualityGoods AS ItemOfIntermediateRelease,
		|	CASE
		|		WHEN Products_1.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			THEN Products_1.Characteristic
		|		WHEN Products_1.UseVariants IN (
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN Products_1.Characteristic
		|		WHEN CharacteristicsOfGoodsOfOtherQuality.Ref IS NOT NULL
		|			THEN CharacteristicsOfGoodsOfOtherQuality.Ref
		|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|	END                                  AS CharacteristicsOfIntermediateRelease,
		|	RECORDAUTONUMBER()                      AS Order
		|INTO TTSelectionOfIntermediateRelease
		|FROM
		|	TTProductsForSelectionOfIntermediateRelease AS Products_1
		|
		|	INNER JOIN TTGoodsOfOtherQuality AS AnotherQualityGoods
		|	ON Products_1.Products = AnotherQualityGoods.Products
		|		AND Products_1.ProductKind = AnotherQualityGoods.ItemTypeOfNonconformityTypeOfItem
		|		AND Products_1.UseVariants = AnotherQualityGoods.ItemsOfNonconformityUseOfCharacteristics
		|		AND Products_1.UnitOfMeasure = AnotherQualityGoods.ItemsOfNonconformityUnitOfMeasurement
		|		AND Products_1.UsePackages = AnotherQualityGoods.ItemsNonconformityOfPackagingUse
		|
		|	LEFT JOIN Catalog.ItemsCharacteristics AS CharacteristicsOfGoodsOfOtherQuality
		|	ON Products_1.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		AND Products_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|		AND AnotherQualityGoods.OtherQualityGoods = CharacteristicsOfGoodsOfOtherQuality.Owner
		|		AND Products_1.CharacteristicName = CharacteristicsOfGoodsOfOtherQuality.Description
		|		AND NOT CharacteristicsOfGoodsOfOtherQuality.DeletionMark
		|INDEX BY
		|	Products, Characteristic";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTSelectionOfIntermediateRelease");
		
		//
		
		QueryText = 
		"SELECT
		|	IntermediateRelease.Products                        AS Products,
		|	IntermediateRelease.Characteristic                      AS Characteristic,
		|	IntermediateRelease.ItemOfIntermediateRelease   AS ItemOfIntermediateRelease,
		|	IntermediateRelease.CharacteristicsOfIntermediateRelease AS CharacteristicsOfIntermediateRelease
		|INTO TTItemsOfIntermediateReleaseSelected
		|FROM
		|	TTSelectionOfIntermediateRelease AS IntermediateRelease
		|WHERE
		|	IntermediateRelease.Order IN (
		|		SELECT
		|			MIN(T.Order) AS Order
		|		FROM
		|			TTSelectionOfIntermediateRelease AS T
		|		WHERE
		|			T.Products = IntermediateRelease.Products
		|			AND T.Characteristic = IntermediateRelease.Characteristic)
		|INDEX BY
		|	Products, Characteristic";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_);
		ListOfTablesToDelete.Add("TTItemsOfIntermediateReleaseSelected");
		
		//
		
		QueryText = 
		"SELECT
		|	Products_1.Products                                AS Products,
		|	Products_1.Characteristic                              AS Characteristic,
		|	ISNULL(SelectedProducts.ItemOfIntermediateRelease,
		|		VALUE(Catalog.Products.EmptyRef)) AS ItemOfIntermediateRelease,
		|	ISNULL(SelectedProducts.CharacteristicsOfIntermediateRelease,
		|		Products_1.Characteristic)                         AS CharacteristicsOfIntermediateRelease,
		|	Products_1.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		AND Products_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|		AND ISNULL(SelectedProducts.CharacteristicsOfIntermediateRelease, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS CreateCharacteristic
		|FROM
		|	TTProductsForSelectionOfIntermediateRelease AS Products_1
		|	
		|	LEFT JOIN TTItemsOfIntermediateReleaseSelected AS SelectedProducts
		|	ON Products_1.Products = SelectedProducts.Products
		|		AND Products_1.Characteristic = SelectedProducts.Characteristic
		|WHERE
		|	SelectedProducts.ItemOfIntermediateRelease IS NULL
		|	OR Products_1.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|		AND Products_1.UseVariants = VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems)
		|		AND ISNULL(SelectedProducts.CharacteristicsOfIntermediateRelease, VALUE(Catalog.ItemsCharacteristics.EmptyRef)) = VALUE(Catalog.ItemsCharacteristics.EmptyRef)";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_);
		
		SetPrivilegedMode(True);
		QueryResults = TMCommonUse.ExecuteBatchOfRequests(Query, QueryTexts, False, True);
		SetPrivilegedMode(False);
		
		IntermediateReleaseLinkCache = New Map;
		ItemOfIntermediateReleaseIsNew = QueryResults[QueryTexts.Count() - 1].Unload();
		For Each String In ItemOfIntermediateReleaseIsNew Do
			CreateIntermediateItemCharacteristic(String, IntermediateReleaseLinkCache);
		EndDo;
		
		QueryTexts = New ValueList;
		
		QueryText = 
		"SELECT
		|	IntermediateRelease.Products                        AS Products,
		|	IntermediateRelease.Characteristic                      AS Characteristic,
		|	IntermediateRelease.ItemOfIntermediateRelease   AS ItemOfIntermediateRelease,
		|	IntermediateRelease.CharacteristicsOfIntermediateRelease AS CharacteristicsOfIntermediateRelease
		|INTO TTItemOfIntermediateReleaseIsNew
		|FROM
		|	&ItemOfIntermediateReleaseIsNew AS IntermediateRelease
		|INDEX BY
		|	Products, Characteristic";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTItemOfIntermediateReleaseIsNew");
		Query.SetParameter("ItemOfIntermediateReleaseIsNew", ItemOfIntermediateReleaseIsNew);
		
		//
		
		QueryText = 
		"SELECT
		|	IntermediateRelease.Ref              AS Ref,
		|	IntermediateRelease.LineNumber         AS LineNumber,
		|	IntermediateRelease.StageSender     AS StageSender,
		|	IntermediateRelease.SenderOperation AS SenderOperation,
		|	IntermediateRelease.RecipientStage      AS RecipientStage,
		|	IntermediateRelease.OperationRecipient  AS OperationRecipient,
		|	IntermediateRelease.Products        AS Products,
		|	IntermediateRelease.Characteristic      AS Characteristic,
		|	IntermediateRelease.ConnectionKey           AS ConnectionKey
		|INTO TTIntermediateRelease
		|FROM
		|	Catalog.BillsOfMaterials.IntermediateRelease AS IntermediateRelease
		|WHERE
		|	IntermediateRelease.Ref IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|
		|UNION ALL
		|
		|SELECT
		|	BillsOfMaterials.Ref                                 AS Ref,
		|	0                                                            AS LineNumber,
		|	StageSender.Ref                                       AS StageSender,
		|	ISNULL(SenderOperation.Ref, VALUE(Catalog.ManufacturingOperations.EmptyRef)) AS SenderOperation,
		|	RecipientStage.Ref                                        AS RecipientStage,
		|	ISNULL(OperationRecipient.Ref, VALUE(Catalog.ManufacturingOperations.EmptyRef))  AS OperationRecipient,
		|	VALUE(Catalog.Products.EmptyRef)               AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	UUID(StageSender.Ref)              AS ConnectionKey
		|FROM
		|	Catalog.BillsOfMaterials AS BillsOfMaterials
		|	
		|	INNER JOIN Catalog.ProductionStages AS StageSender
		|	ON BillsOfMaterials.Ref = StageSender.Owner
		|
		|	INNER JOIN Catalog.ProductionStages AS RecipientStage
		|	ON BillsOfMaterials.Ref = RecipientStage.Owner
		|		AND StageSender.NextStageNo = RecipientStage.StageNumber
		|
		|	LEFT JOIN Catalog.ManufacturingOperations AS SenderOperation
		|	ON StageSender.Ref = SenderOperation.Owner
		|		AND SenderOperation.NextOperation = 0
		|		AND NOT SenderOperation.DeletionMark
		|
		|	LEFT JOIN Catalog.ManufacturingOperations AS OperationRecipient
		|	ON RecipientStage.Ref = OperationRecipient.Owner
		|		AND OperationRecipient.OperationNumber = 1
		|		AND NOT OperationRecipient.DeletionMark
		|WHERE
		|	BillsOfMaterials.Ref IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|	AND BillsOfMaterials.RecordMethodOfMaterialTransferBetweenStagesLots =
		|			VALUE(Enum.RecordMethodsOfMaterialTransferBetweenStagesLots.NonconformingProducts)
		|	AND NOT StageSender.DeletionMark
		|	AND NOT RecipientStage.DeletionMark
		|
		|INDEX BY
		|	Ref";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTIntermediateRelease");
		
	EndIf;
	
	#EndRegion
	
	#Region TTMethodsOfObtainingMaterials
	
	If TempTablesManager.Tables.Find("TTMethodsOfObtainingMaterials") = Undefined Then
	
		QueryTexts.Add(ProductionSupply.RequestTextTTMethodsOfGettingMaterialsEmpty());
		ListOfTablesToDelete.Add("TTMethodsOfObtainingMaterials");
		
	EndIf;
	
	#EndRegion
	
	#Region TTWarehouseFormats
	
	If TempTablesManager.Tables.Find("TTWarehouseFormats") = Undefined Then
	
		QueryTexts.Add(Catalogs.StoreFormats.QueryTextTTWarehouseFormats(False));
		ListOfTablesToDelete.Add("TTWarehouseFormats");
	
	EndIf;
	
	#EndRegion
	
	#Region TTWorkingHoursOfTypesOfWorkCenters
	
	If ListOfData.Find("WorkCenterTypes") <> Undefined
		Or ListOfData.Find("AlternateWorkCenterTypes") <> Undefined Then
		
		QueryText =
		"SELECT
		|	TabularSection.Ref AS Stage,
		|	TabularSection.WorkCenterType AS WorkCenterType,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN SetupOptions.OperationTime
		|		ELSE TypesOfRC.OperationTime
		|	END AS OperationTime,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN SetupOptions.UnitOfMeasure
		|		ELSE TypesOfRC.UnitOfMeasure
		|	END AS UnitOfMeasure,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN CASE SetupOptions.UnitOfMeasure
		|					WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|						THEN SetupOptions.OperationTime * 60
		|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|						THEN SetupOptions.OperationTime * 3600
		|					WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|						THEN SetupOptions.OperationTime * 86400
		|					ELSE SetupOptions.OperationTime
		|				END
		|		ELSE CASE TypesOfRC.UnitOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN TypesOfRC.OperationTime * 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN TypesOfRC.OperationTime * 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN TypesOfRC.OperationTime * 86400
		|				ELSE TypesOfRC.OperationTime
		|			END
		|	END AS RunningTimeInSeconds,
		|	ProductionStages.OperatingProcedureOfWorkCenterTypes = VALUE(Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously) AS SimultaneousOperation
		|
		|INTO TTSynchronousOperation
		|FROM
		|	Catalog.ProductionStages.WorkCenterTypes AS TabularSection
		|
		|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|		ON TabularSection.Ref = ProductionStages.Ref
		|
		|		LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|		ON TabularSection.WorkCenterType = TypesOfRC.Ref
		|
		|		LEFT JOIN Catalog.SetupOptions AS SetupOptions
		|		ON TabularSection.SetupSettings = SetupOptions.Ref
		|WHERE
		|	ProductionStages.Owner IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|	AND NOT ProductionStages.DeletionMark
		|	AND TypesOfRC.ParallelLoad
		|	AND TypesOfRC.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|
		|UNION ALL
		|
		|SELECT
		|	TabularSection.Ref AS Stage,
		|	TabularSection.WorkCenterType AS WorkCenterType,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN SetupOptions.OperationTime
		|		ELSE TypesOfRC.OperationTime
		|	END AS OperationTime,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN SetupOptions.UnitOfMeasure
		|		ELSE TypesOfRC.UnitOfMeasure
		|	END AS UnitOfMeasure,
		|	CASE
		|		WHEN TypesOfRC.SetupSettingsAreUsed
		|			THEN CASE SetupOptions.UnitOfMeasure
		|					WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|						THEN SetupOptions.OperationTime * 60
		|					WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|						THEN SetupOptions.OperationTime * 3600
		|					WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|						THEN SetupOptions.OperationTime * 86400
		|					ELSE SetupOptions.OperationTime
		|				END
		|		ELSE CASE TypesOfRC.UnitOfMeasure
		|				WHEN VALUE(Enum.TimeMeasureUnits.MINUTE)
		|					THEN TypesOfRC.OperationTime * 60
		|				WHEN VALUE(Enum.TimeMeasureUnits.HOUR)
		|					THEN TypesOfRC.OperationTime * 3600
		|				WHEN VALUE(Enum.TimeMeasureUnits.Days1)
		|					THEN TypesOfRC.OperationTime * 86400
		|				ELSE TypesOfRC.OperationTime
		|			END
		|	END AS RunningTimeInSeconds,
		|	ProductionStages.OperatingProcedureOfWorkCenterTypes = VALUE(Enum.OperatingProcedureOfWorkCenterTypes.Simultaneously) AS SimultaneousOperation
		|
		|FROM
		|	Catalog.ProductionStages.AlternateWorkCenterTypes AS TabularSection
		|
		|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|		ON TabularSection.Ref = ProductionStages.Ref
		|
		|		LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|		ON TabularSection.WorkCenterType = TypesOfRC.Ref
		|
		|		LEFT JOIN Catalog.SetupOptions AS SetupOptions
		|		ON TabularSection.SetupSettings = SetupOptions.Ref
		|WHERE
		|	ProductionStages.Owner IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|	AND NOT ProductionStages.DeletionMark
		|	AND TypesOfRC.ParallelLoad
		|	AND TypesOfRC.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|
		|INDEX BY
		|	Stage,
		|	WorkCenterType";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTSynchronousOperation");
		
		QueryText =
		"SELECT
		|	TTSynchronousOperation.Stage AS Stage,
		|	MAX(TTSynchronousOperation.RunningTimeInSeconds) AS RunningTimeInSeconds
		|INTO TTMaxWorkingTime
		|FROM
		|	TTSynchronousOperation AS TTSynchronousOperation
		|WHERE
		|	TTSynchronousOperation.SimultaneousOperation
		|
		|GROUP BY
		|	TTSynchronousOperation.Stage
		|
		|INDEX BY
		|	Stage,
		|	RunningTimeInSeconds";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTMaxWorkingTime");
		
		QueryText = 
		"SELECT
		|	TTSynchronousOperation.Stage AS Stage,
		|	MAX(TTSynchronousOperation.WorkCenterType) AS WorkCenterType
		|INTO TTTypesOfRC
		|FROM
		|	TTSynchronousOperation AS TTSynchronousOperation
		|WHERE
		|	TTSynchronousOperation.SimultaneousOperation
		|	AND (TTSynchronousOperation.Stage, TTSynchronousOperation.RunningTimeInSeconds) IN
		|			(SELECT
		|				TTMaxWorkingTime.Stage AS Stage,
		|				TTMaxWorkingTime.RunningTimeInSeconds AS RunningTimeInSeconds
		|			FROM
		|				TTMaxWorkingTime AS TTMaxWorkingTime)
		|
		|GROUP BY
		|	TTSynchronousOperation.Stage";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTTypesOfRC");
		
		QueryText =
		"SELECT
		|	TTSynchronousOperation.Stage AS Stage,
		|	TTSynchronousOperation.OperationTime AS OperationTime,
		|	TTSynchronousOperation.UnitOfMeasure AS UnitOfMeasure
		|INTO TTSynchronousSimultaneousOperation
		|FROM
		|	TTSynchronousOperation AS TTSynchronousOperation
		|		INNER JOIN TTTypesOfRC AS TTTypesOfRC
		|		ON TTSynchronousOperation.Stage = TTTypesOfRC.Stage
		|			AND TTSynchronousOperation.WorkCenterType = TTTypesOfRC.WorkCenterType
		|
		|INDEX BY
		|	Stage";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTSynchronousSimultaneousOperation");
		
		QueryText =
		"SELECT
		|	TabularSection.Ref AS Stage,
		|	TabularSection.WorkCenterType AS WorkCenterType,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN TTSynchronousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousOperation.OperationTime
		|		WHEN TTSynchronousSimultaneousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousSimultaneousOperation.OperationTime
		|		ELSE TabularSection.OperationTime
		|	END AS OperationTime,
		|	CASE
		|		WHEN TTSynchronousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousOperation.UnitOfMeasure
		|		WHEN TTSynchronousSimultaneousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousSimultaneousOperation.UnitOfMeasure
		|		ELSE TabularSection.UnitOfMeasure
		|	END AS UnitOfMeasure,
		|	CASE
		|		WHEN TypesOfRC.ParallelLoad
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS CalculateEmployment
		|INTO TTWorkingHoursOfTypesOfWorkCenters
		|FROM
		|	Catalog.ProductionStages.WorkCenterTypes AS TabularSection
		|
		|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|		ON TabularSection.Ref = ProductionStages.Ref
		|
		|		LEFT JOIN Catalog.WorkCenterTypes AS TypesOfRC
		|		ON TabularSection.WorkCenterType = TypesOfRC.Ref
		|
		|		LEFT JOIN TTSynchronousSimultaneousOperation AS TTSynchronousSimultaneousOperation
		|		ON TabularSection.Ref = TTSynchronousSimultaneousOperation.Stage
		|
		|		LEFT JOIN TTSynchronousOperation AS TTSynchronousOperation
		|		ON TabularSection.Ref = TTSynchronousOperation.Stage
		|			AND TabularSection.WorkCenterType = TTSynchronousOperation.WorkCenterType
		|			AND TabularSection.ConnectionKey = TTSynchronousOperation.ConnectionKey
		|WHERE
		|	ProductionStages.Owner IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|	AND NOT ProductionStages.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	TabularSection.Ref AS Stage,
		|	TabularSection.WorkCenterType AS WorkCenterType,
		|	TabularSection.ConnectionKey AS ConnectionKey,
		|	CASE
		|		WHEN TTSynchronousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousOperation.OperationTime
		|		WHEN TTSynchronousSimultaneousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousSimultaneousOperation.OperationTime
		|		ELSE TabularSection.OperationTime
		|	END AS OperationTime,
		|	CASE
		|		WHEN TTSynchronousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousOperation.UnitOfMeasure
		|		WHEN TTSynchronousSimultaneousOperation.Stage IS NOT NULL 
		|			THEN TTSynchronousSimultaneousOperation.UnitOfMeasure
		|		ELSE TabularSection.UnitOfMeasure
		|	END AS UnitOfMeasure,
		|	FALSE AS CalculateEmployment
		|FROM
		|	Catalog.ProductionStages.AlternateWorkCenterTypes AS TabularSection
		|
		|		LEFT JOIN Catalog.ProductionStages AS ProductionStages
		|		ON TabularSection.Ref = ProductionStages.Ref
		|
		|		LEFT JOIN TTSynchronousSimultaneousOperation AS TTSynchronousSimultaneousOperation
		|		ON TabularSection.Ref = TTSynchronousSimultaneousOperation.Stage
		|
		|		LEFT JOIN TTSynchronousOperation AS TTSynchronousOperation
		|		ON TabularSection.Ref = TTSynchronousOperation.Stage
		|			AND TabularSection.WorkCenterType = TTSynchronousOperation.WorkCenterType
		|			AND TabularSection.ConnectionKey = TTSynchronousOperation.ConnectionKey
		|
		|WHERE
		|	ProductionStages.Owner IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
		|	AND NOT ProductionStages.DeletionMark";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTWorkingHoursOfTypesOfWorkCenters");
		
	EndIf;
	
	#EndRegion
	
	#Region TTTechnologicalProcesses
	
	QueryText = "
	|SELECT
	|	TTProductData_.Id                                    AS Id,
	|
	|	Operations.BillOfMaterials                                                   AS BillOfMaterials,
	|	CAST(Operations.Owner AS Catalog.ProductionStages)            AS Stage,
	|	Operations.Ref                                                         AS Operation,
	|	Operations.TechnologicalProcess                                         AS TechnologicalProcess,
	|	Operations.TechnologicalProcess.ContainsResourcesParametrization              AS ContainsResourcesParametrization,
	|	Operations.TechnologicalProcessFactor                            AS ZoomRatio,
	|
	|	CAST(Operations.Owner AS Catalog.ProductionStages).StageNumber           AS StageNumber,
	|	CAST(Operations.Owner AS Catalog.ProductionStages).NextStageNo AS NextStageNo,
	|	Operations.OperationNumber                                                            AS OperationNumber
	|
	|INTO TTTechnologicalProcesses
	|FROM
	|	Catalog.ManufacturingOperations AS Operations
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON Operations.BillOfMaterials = TTProductData_.BillOfMaterials
	|
	|WHERE
	|	&UseTechnologicalProcesses
	|	AND Operations.ContainsTechnologicalProcess
	|	AND NOT Operations.DeletionMark 
	|
	|INDEX BY
	|	Id
	|
	|";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTTechnologicalProcesses");
	
	QueryText = "
	|SELECT DISTINCT
	|	TTTechnologicalProcesses.BillOfMaterials           AS BillOfMaterials,
	|	TTTechnologicalProcesses.TechnologicalProcess AS TechnologicalProcess
	|
	|INTO TTTechnologicalProcessesSpecifications
	|FROM
	|	TTTechnologicalProcesses AS TTTechnologicalProcesses
	|
	|INDEX BY
	|	TechnologicalProcess
	|";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTTechnologicalProcessesSpecifications");
	
	#EndRegion
	
	#Region TT_SelectionByProperties
	
	QueryText = "
	|SELECT
	|	TTProductData_.Id            AS Id,
	|
	|	BillsOfMaterialsSelectionByProperties.ConnectionKey AS ConnectionKey,
	|	BillsOfMaterialsSelectionByProperties.Property  AS Property,
	|	BillsOfMaterialsSelectionByProperties.Condition   AS Condition,
	|	BillsOfMaterialsSelectionByProperties.Value  AS ValueSelection,
	|
	|	CASE
	|		WHEN NOT PropertiesCharacteristics.Value IS NULL
	|			THEN PropertiesCharacteristics.Value
	|		WHEN NOT ProductProperties_.Value IS NULL
	|			THEN ProductProperties_.Value
	|		WHEN NOT PropertiesOfDirectionOfActivity.Value IS NULL
	|			THEN PropertiesOfDirectionOfActivity.Value
	|		ELSE
	|			CASE
	|				WHEN VALUETYPE(BillsOfMaterialsSelectionByProperties.Value) = TYPE(BOOLEAN)
	|					THEN FALSE
	|				WHEN VALUETYPE(BillsOfMaterialsSelectionByProperties.Value) = TYPE(NUMBER)
	|					THEN 0
	|				ELSE UNDEFINED
	|			END
	|	END                                           AS PropertyValue
	|
	|INTO TTSelectionBySettingProperties
	|FROM
	|	Catalog.BillsOfMaterials.SelectionByProperties AS BillsOfMaterialsSelectionByProperties
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON BillsOfMaterialsSelectionByProperties.Ref = TTProductData_.BillOfMaterials
	|
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ProductProperties_
	|		ON BillsOfMaterialsSelectionByProperties.Property = ProductProperties_.Property
	|			AND (ProductProperties_.Ref = TTProductData_.Products)
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesCharacteristics
	|		ON BillsOfMaterialsSelectionByProperties.Property = PropertiesCharacteristics.Property
	|			AND (PropertiesCharacteristics.Ref = TTProductData_.Characteristic)
	|
	|		LEFT JOIN Catalog.LinesOfBusiness.AdditionalAttributes AS PropertiesOfDirectionOfActivity
	|		ON BillsOfMaterialsSelectionByProperties.Property = PropertiesOfDirectionOfActivity.Property
	|			AND (PropertiesOfDirectionOfActivity.Ref = TTProductData_.LineOfBusiness)
	|
	|WHERE
	|	&UseParameterization
	|	AND NOT BillsOfMaterialsSelectionByProperties.ConnectionKey IN (&CommunicationKeyProducts, &CommunicationKeyCharacteristic)
	|
	|UNION ALL
	|
	|SELECT
	|	TTProductData_.Id        AS Id,
	|
	|	ProductionStagesSelectionByProperties.ConnectionKey AS ConnectionKey,
	|	ProductionStagesSelectionByProperties.Property  AS Property,
	|	ProductionStagesSelectionByProperties.Condition   AS Condition,
	|	ProductionStagesSelectionByProperties.Value  AS ValueSelection,
	|
	|	CASE
	|		WHEN NOT PropertiesCharacteristics.Value IS NULL
	|			THEN PropertiesCharacteristics.Value
	|		WHEN NOT ProductProperties_.Value IS NULL
	|			THEN ProductProperties_.Value
	|		ELSE
	|			CASE
	|				WHEN VALUETYPE(ProductionStagesSelectionByProperties.Value) = TYPE(BOOLEAN)
	|					THEN FALSE
	|				WHEN VALUETYPE(ProductionStagesSelectionByProperties.Value) = TYPE(NUMBER)
	|					THEN 0
	|				ELSE UNDEFINED
	|			END
	|	END                                       AS PropertyValue
	|
	|FROM
	|	Catalog.ProductionStages.SelectionByProperties AS ProductionStagesSelectionByProperties
	|
	|		INNER JOIN Catalog.ProductionStages AS ProductionStages
	|		ON ProductionStagesSelectionByProperties.Ref = ProductionStages.Ref
	|			AND (NOT ProductionStages.DeletionMark)
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON (ProductionStages.Owner = TTProductData_.BillOfMaterials)
	|
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ProductProperties_
	|		ON ProductionStagesSelectionByProperties.Property = ProductProperties_.Property
	|			AND (ProductProperties_.Ref = TTProductData_.Products)
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesCharacteristics
	|		ON ProductionStagesSelectionByProperties.Property = PropertiesCharacteristics.Property
	|			AND (PropertiesCharacteristics.Ref = TTProductData_.Characteristic)
	|
	|WHERE
	|	&UseParameterization
	|
	|UNION ALL
	|
	|SELECT DISTINCT
	|	TTProductData_.Id                 AS Id,
	|
	|	TechnologicalProcessesSelectionByProperties.ConnectionKey    AS ConnectionKey,
	|	TechnologicalProcessesSelectionByProperties.Property     AS Property,
	|	TechnologicalProcessesSelectionByProperties.Condition      AS Condition,
	|	TechnologicalProcessesSelectionByProperties.Value     AS ValueSelection,
	|
	|	CASE
	|		WHEN NOT PropertiesCharacteristics.Value IS NULL
	|			THEN PropertiesCharacteristics.Value
	|		WHEN NOT ProductProperties_.Value IS NULL
	|			THEN ProductProperties_.Value
	|		ELSE
	|			CASE
	|				WHEN VALUETYPE(TechnologicalProcessesSelectionByProperties.Value) = TYPE(BOOLEAN)
	|					THEN FALSE
	|				WHEN VALUETYPE(TechnologicalProcessesSelectionByProperties.Value) = TYPE(NUMBER)
	|					THEN 0
	|				ELSE UNDEFINED
	|			END
	|	END                                                AS PropertyValue
	|
	|FROM
	|	TTTechnologicalProcesses AS TTTechnologicalProcesses
	|
	|		INNER JOIN Catalog.TechnologicalProcesses.SelectionByProperties AS TechnologicalProcessesSelectionByProperties
	|		ON TechnologicalProcessesSelectionByProperties.Ref = TTTechnologicalProcesses.TechnologicalProcess
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON TTTechnologicalProcesses.Id = TTProductData_.Id
	|
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ProductProperties_
	|		ON TechnologicalProcessesSelectionByProperties.Property = ProductProperties_.Property
	|			AND (ProductProperties_.Ref = TTProductData_.Products)
	|
	|		LEFT JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS PropertiesCharacteristics
	|		ON TechnologicalProcessesSelectionByProperties.Property = PropertiesCharacteristics.Property
	|			AND (PropertiesCharacteristics.Ref = TTProductData_.Characteristic)
	|
	|WHERE
	|	&UseParameterization
	|
	|INDEX BY
	|	ConnectionKey,
	|	Property
	|";
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTSelectionBySettingProperties");
	
	QueryText = ProductDataManagement.QueryTextTTSelectionByProperties("TTSelectionBySettingProperties");
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TT_SelectionByProperties");
	
	#EndRegion
	
	#Region ItemData_3
	
	QueryText = 
	"SELECT
	|	ItemData_3.Id             AS Id,
	|	ItemData_3.BillOfMaterials              AS BillOfMaterials,
	|	ItemData_3.Products              AS Products,
	|	ItemData_3.Characteristic            AS Characteristic,
	|	ItemData_3.Count                AS Count,
	|	ItemData_3.ProductionDispatcherBusinessUnit    AS ProductionDispatcherBusinessUnit,
	|	ItemData_3.LineOfBusiness   AS LineOfBusiness,
	|	ItemData_3.ReferenceOrder              AS ReferenceOrder,
	|	ItemData_3.Purpose                AS Purpose,
	|	ItemData_3.ProductionStart        AS ProductionStart
	|FROM
	|	TTProductData_ AS ItemData_3
	|ORDER BY
	|	Id";
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "ItemData_3");
	
	#EndRegion
	
	#Region AutoSelection

	QueryText = 
	"SELECT
	|	TTProductData_.Products                         AS Products,
	|	TTProductData_.Characteristic                       AS Characteristic,
	|	ProductsAdditionalDetails.Property                AS Property,
	|	&ExpressionOfPropertyIdentifierProductList     AS IDProperty,
	|	PRESENTATION(ProductsAdditionalDetails.Property) AS PropertyPresentation,
	|	ProductsAdditionalDetails.Value                AS Value
	|FROM
	|	TTProductData_ AS TTProductData_
	|		INNER JOIN Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
	|		ON TTProductData_.Products = ProductsAdditionalDetails.Ref
	|WHERE
	|	&UseParameterization
	|
	|UNION
	|
	|SELECT
	|	TTProductData_.Products,
	|	TTProductData_.Characteristic,
	|	CharacteristicsAdditionalDetails.Property,
	|	&ExpressionOfIdentifierOfPropertiesOfToleranceCharacteristic,
	|	PRESENTATION(CharacteristicsAdditionalDetails.Property),
	|	CharacteristicsAdditionalDetails.Value
	|FROM
	|	TTProductData_ AS TTProductData_
	|		INNER JOIN Catalog.ItemsCharacteristics.AdditionalAttributes AS CharacteristicsAdditionalDetails
	|		ON TTProductData_.Characteristic = CharacteristicsAdditionalDetails.Ref
	|		LEFT JOIN Catalog.Products.AdditionalAttributes AS ProductsAdditionalDetails
	|		ON TTProductData_.Products = ProductsAdditionalDetails.Ref
	|			AND CharacteristicsAdditionalDetails.Property = ProductsAdditionalDetails.Property
	|WHERE
	|	&UseParameterization
	|	AND ProductsAdditionalDetails.Property IS NULL";
	
	IDFieldForFormulas = ProcessingOfFormulas.IdFieldForAdditionalBankingDetails();
	ExpressionOfPropertyIdentifierProductList = StringFunctionsClientServer.SubstituteParametersToString(
		"ProductsAdditionalDetails.Property.%1",
		IDFieldForFormulas);
	ExpressionOfIdentifierOfPropertiesOfToleranceCharacteristic = StringFunctionsClientServer.SubstituteParametersToString(
		"CharacteristicsAdditionalDetails.Property.%1",
		IDFieldForFormulas);
	QueryText = StrReplace(QueryText, "&ExpressionOfPropertyIdentifierProductList", ExpressionOfPropertyIdentifierProductList);
	QueryText = StrReplace(QueryText, "&ExpressionOfIdentifierOfPropertiesOfToleranceCharacteristic", ExpressionOfIdentifierOfPropertiesOfToleranceCharacteristic);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "ValuesOfProductProperties");
	
	QueryText = "
	|SELECT
	|	PropertyMapping.Ref                           AS BillOfMaterials,
	|	PropertyMapping.ConnectionKey                        AS ConnectionKey,
	|	PropertyMapping.ValueSelectionMethod            AS ValueSelectionMethod,
	|	PropertyMapping.MaterialProperty                AS MaterialProperty,
	|	&ExpressionOfMaterialPropertyID            AS IDProperty,
	|	PRESENTATION(PropertyMapping.MaterialProperty) AS PropertyPresentation,
	|	PropertyMapping.ProductsProperty                AS ProductsProperty,
	|	PropertyMapping.PropertyValue                 AS Value,
	|	PropertyMapping.ValueCalculationAlgorithm          AS ValueCalculationAlgorithm
	|FROM
	|	Catalog.BillsOfMaterials.PropertyMapping AS PropertyMapping
	|	
	|WHERE
	|	&UseParameterization
	|	AND PropertyMapping.Ref IN (SELECT DISTINCT T.BillOfMaterials FROM TTProductData_ AS T)
	|	AND PropertyMapping.ValueSelectionMethod <> VALUE(Enum.MethodsOfSelectingProductPropertyValue.AnyValue)
	|
	|UNION ALL
	|
	|SELECT
	|	TTTechnologicalProcessesSpecifications.BillOfMaterials   AS BillOfMaterials,
	|	PropertyMapping.ConnectionKey                        AS ConnectionKey,
	|	PropertyMapping.ValueSelectionMethod            AS ValueSelectionMethod,
	|	PropertyMapping.MaterialProperty                AS MaterialProperty,
	|	&ExpressionOfMaterialPropertyID            AS IDProperty,
	|	PRESENTATION(PropertyMapping.MaterialProperty) AS PropertyPresentation,
	|	PropertyMapping.ProductsProperty                AS ProductsProperty,
	|	PropertyMapping.PropertyValue                 AS Value,
	|	PropertyMapping.ValueCalculationAlgorithm          AS ValueCalculationAlgorithm
	|FROM
	|	Catalog.TechnologicalProcesses.PropertyMapping AS PropertyMapping
	|	
	|		INNER JOIN TTTechnologicalProcessesSpecifications
	|		ON PropertyMapping.Ref = TTTechnologicalProcessesSpecifications.TechnologicalProcess
	|	
	|WHERE
	|	&UseParameterization
	|	AND PropertyMapping.ValueSelectionMethod <> VALUE(Enum.MethodsOfSelectingProductPropertyValue.AnyValue)
	|
	|";
	
	IdFieldName = ProcessingOfFormulas.IdFieldForAdditionalBankingDetails();
	ExpressionOfMaterialPropertyID = StringFunctionsClientServer.SubstituteParametersToString(
		"PropertyMapping.MaterialProperty.%1",
		IdFieldName);
	QueryText = StrReplace(QueryText, "&ExpressionOfMaterialPropertyID", ExpressionOfMaterialPropertyID);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "PropertyMapping");
	
	#EndRegion

	#Region SpecificationDetails
	
	QueryText = 
	"SELECT
	|	TTProductData_.Id AS Id,
	|
	|	BillsOfMaterials.Ref        AS BillOfMaterials,
	|	BillsOfMaterials.Presentation AS BillOfMaterialsPresentation,
	|
	|	BillsOfMaterials.Code AS Code,
	|	BillsOfMaterials.DataVersionID AS DataVersionID,
	|
	|	BillsOfMaterials.MethodOfAllocatingFinishedProductCosts AS MethodOfAllocatingFinishedProductCosts,
	|
	|	BillsOfMaterials.ProductionProcessType         AS ProductionProcessType,
	|	BillsOfMaterials.AssignmentOption                    AS AssignmentOption,
	|	BillsOfMaterials.MultiStageProductionProcess  AS MultiStageProductionProcess,
	|
	|	CASE
	|		WHEN &OverrideReleasePartySetting
	|			THEN &ProductionIssueByCustomPortions
	|		ELSE CASE
	|				WHEN &ReleaseBatchDescriptionIsAvailable
	|					THEN BillsOfMaterials.ProductionIssueByCustomPortions
	|				ELSE FALSE
	|			END
	|	END                                                         AS ProductionIssueByCustomPortions,
	|	CASE
	|		WHEN &OverrideReleasePartySetting
	|			THEN 0
	|		ELSE BillsOfMaterials.EconomicReleaseLot
	|	END                                                         AS EconomicReleaseLot,
	|	CASE
	|		WHEN &OverrideReleasePartySetting
	|			THEN 0
	|		ELSE BillsOfMaterials.PermissibleExcessOfOptimalReleaseLot
	|	END                                                         AS PermissibleExcessOfOptimalReleaseLot,
	|	CASE
	|		WHEN &OverrideReleasePartySetting
	|			THEN 0
	|		ELSE CASE
	|				WHEN &ReleaseBatchDescriptionIsAvailable
	|					THEN BillsOfMaterials.MinimumReleaseLot
	|				ELSE 0
	|			END
	|	END                                                         AS MinimumReleaseLot,
	|	
	|	BillsOfMaterials.ProductQueuePeriodIsLimited    AS QueuePeriodIsLimited,
	|	BillsOfMaterials.MaximumPeriodOfProductQueue AS MaximumPeriodOfLyingInDays,
	|	BillsOfMaterials.OptimalTransfersQuantityBetweenStages   AS OptimalTransfersQuantityBetweenStages,
	|	
	|	BillsOfMaterials.ThereIsSpecifiedMainProduct                                  AS ThereIsSpecifiedMainProduct,
	|	BillsOfMaterials.ContainsNestedBOMs                                      AS ContainsNestedBOMs,
	|	BillsOfMaterials.ContainsProbabilityCalculation                                          AS ContainsProbabilityCalculation,
	|	BillsOfMaterials.ContainsAliquotStandardsOfWorkCenterTypes                                      AS ContainsAliquotStandardsOfWorkCenterTypes,
	|	BillsOfMaterials.ContainsResourcesParametrization OR &ThereIsParameterizationOfTechnicalProcesses AS ContainsResourcesParametrization,
	|	
	|	BillsOfMaterials.ResponsibleBusinessUnit AS ResponsibleBusinessUnit
	|	
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON BillsOfMaterials.Ref = TTProductData_.BillOfMaterials
	|
	|ORDER BY
	|	Id";
	
	TextOfFieldIsParameterizationOfTechnicalProcesses = "FALSE";
	TextOfFieldIsParameterizationOfTechnicalProcesses = "TRUE IN (
	|SELECT TOP 1
	|	TRUE
	|FROM
	|	TTTechnologicalProcesses AS T
	|WHERE
	|	T.BillOfMaterials = BillsOfMaterials.Ref
	|	AND T.ContainsResourcesParametrization
	|)";
	QueryText = StrReplace(QueryText, "&ThereIsParameterizationOfTechnicalProcesses", TextOfFieldIsParameterizationOfTechnicalProcesses);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "SpecificationDetails");
	
	#EndRegion
	
	#Region MainProduct
	
	QueryText = "
	|SELECT
	|	TTWares.Id                            AS Id,
	|
	|	TTWares.ProductKind                          AS ProductKind,
	|	TTWares.Products                             AS Products,
	|	TTWares.Characteristic                           AS Characteristic,
	|	
	|	0                                                  AS Count,
	|	TTWares.NumberOfPackages                       AS NumberOfPackages,
	|	TTWares.NumberOfPackages                       AS NumberOfPackagesPerUnitOfProductionBatch,
	|	TTWares.Package                                 AS Package,
	|	UNDEFINED                                       AS PackageData,
	|
	|	ISNULL(TTWares.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))  AS UnitOfMeasure,
	|	ISNULL(TTWares.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
	|
	|	CASE
	|		WHEN TTWares.Products.UseVariants IN (
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                              AS ItemVariantsAreUsed,
	|
	|	TTWares.AnyCharacteristic                      AS AnyCharacteristic,
	|	TTWares.BillOfMaterials                             AS BillOfMaterials,
	|	TTWares.BillOfMaterials.AssignmentOption           AS AssignmentOption,
	|	CASE
	|		WHEN &ConsiderProbabilityOfDefectiveGoods
	|			THEN TTWares.ShareOfNonconformity / 100
	|		ELSE 0
	|	END                                              AS DefectiveGoodsRate,
	|	TTWares.Stage                                     AS Stage,
	|	TTWares.Stage.Department                       AS StageSubdivision,
	|	TTWares.ThisIsMainProduct                       AS ThisIsMainProduct,
	|
	|	TTWares.ConnectionKey                                AS ConnectionKey,
	|	
	|	ISNULL(TTProductsMainProduct.Products, VALUE(Catalog.Products.EmptyRef))         AS MainProductProducts,
	|	ISNULL(TTProductsMainProduct.Package, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS MainProductPackage,
	|	ISNULL(TTProductsMainProduct.NumberOfPackages, 0)                                                AS MainProductNumberOfPackagesPerUnitOfProductionBatch,
	|
	|	ISNULL(TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
	|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PackagingPiece,
	|	ISNULL(TTWares.Products.AnalyticalGroup, VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef)) AS AnalyticalGroup
	|
	|FROM TTWares AS TTWares
	|
	|		LEFT JOIN TTWares AS TTProductsMainProduct
	|		ON TTWares.Id = TTProductsMainProduct.Id
	|			AND NOT TTWares.ThisIsMainProduct
	|			AND TTProductsMainProduct.ThisIsMainProduct
	|
	|WHERE
	|	TTWares.CorrespondsToProductData
	|
	|ORDER BY
	|	TTWares.Id,
	|	TTWares.Product_Type
	|";
	
	TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"MeasuredValueType",
		"TTWares.Package",
		"TTWares.Products");
		
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextMeasuredValueType",
		TextOfMeasuredValueTypeField);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "MainProduct");
	
	#EndRegion
	
	#Region Stages
	
	If ListOfData.Find("Stages") <> Undefined Then
		QueryText =
			"SELECT
			|	ProductionStages.Ref                                             AS Stage,
			|	TTProductData_.Id                                 AS Id,
			|	VALUE(Enum.OperatingProcedureOfWorkCenterTypes.EmptyRef) AS OperatingProcedureOfWorkCenterTypes
			|INTO TTRedefiningOrderOfWorkOfTypesOfWorkCenters
			|FROM
			|	Catalog.ProductionStages AS ProductionStages
			|
			|		INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS TabularSection
			|		ON TabularSection.Ref = ProductionStages.Ref
			|
			|		INNER JOIN TTProductData_ AS TTProductData_
			|		ON ProductionStages.Owner = TTProductData_.BillOfMaterials
			|
			|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
			|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
			|			AND TTProductData_.Id = TT_SelectionByProperties.Id
			|
			|WHERE
			|	NOT ProductionStages.DeletionMark
			|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
			|	AND TRUE IN (
			|		SELECT TOP 1
			|			TRUE
			|		FROM
			|			TT_SelectionByProperties AS Filter
			|		WHERE
			|			Filter.Id = TTProductData_.Id)
			|
			|GROUP BY
			|	ProductionStages.Ref,
			|	TTProductData_.Id
			|
			|HAVING
			|	COUNT(TabularSection.WorkCenterType) <= 1
			|
			|INDEX BY
			|	Stage, Id";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTRedefiningOrderOfWorkOfTypesOfWorkCenters");
		QueryText = 
		"SELECT
		|	&ProductionStages_Presentations,
		|	MainOutputProduct.Id                                    AS Id,
		|	ProductionStages.Ref                                                 AS Stage,
		|	ProductionStages.Owner                                               AS BillOfMaterials,
		|	ProductionStages.Presentation                                          AS StagePresentation,
		|	ProductionStages.StageNumber                                             AS StageNumber,
		|	ProductionStages.NextStageNo                                   AS NextStageNo,
		|	ProductionStages.Department                                          AS Department,
		|	1                                                                        AS Count,
		|	1                                                                        AS QuantityPerReleaseLotUnit,
		|	MainOutputProduct.Count                                       AS ProductQuantity,
		|
		|	ProductionStages.PlanOperationsOfWorkCenterTypes                   AS PlanOperationsOfWorkCenterTypes,
		|	ProductionStages.Continuous_                                            AS Continuous_,
		|	ProductionStages.QuantityOfProductUnitsLotsProducedSimultaneously  AS QuantityOfProductUnitsLotsProducedSimultaneously,
		|	ProductionStages.StageDuration                                      AS StageDuration,
		|	ProductionStages.UnitOfMeasureOfStageDuration                      AS UnitOfMeasureOfStageDuration,
		|	ProductionStages.PreliminaryBuffer                                   AS PreliminaryBuffer,
		|	ProductionStages.FollowUpBuffer                                       AS FollowUpBuffer,
		|	ProductionStages.UnitOfMeasureOfPreliminaryBuffer                 AS UnitOfMeasureOfPreliminaryBuffer,
		|	ProductionStages.UnitOfMeasureOfFollowUpBuffer                     AS UnitOfMeasureOfFollowUpBuffer,
		|	ProductionStages.LongDesc                                               AS LongDesc,
		|	ProductionStages.ProductionByThirdParty                                  AS ProductionByThirdParty,
		|	ProductionStages.WorkPlanning                                      AS WorkPlanning,
		|	ProductionStages.Partner                                                AS Partner,
		|	ProductionStages.WorkScheduleOfPartner                                   AS WorkScheduleOfPartner,
		|	ProductionStages.SubcontractorServices.(
		|		LineNumber       AS LineNumber,
		|		Products      AS Products,
		|		Characteristic    AS Characteristic,
		|		Count        AS Count,
		|		Count        AS QuantityPerReleaseLotUnit,
		|		ProductCostElement AS ProductCostElement)                             AS SubcontractorServices,
		|
		|	&TextOfRouteMapField,
		|
		|	ISNULL(RedefiningOrderOfWork.OperatingProcedureOfWorkCenterTypes,
		|				ProductionStages.OperatingProcedureOfWorkCenterTypes)          AS OperatingProcedureOfWorkCenterTypes,
		|	ProductionStages.ContainsResourcesParametrization                             AS ContainsResourcesParametrization,
		|
		|	ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)             AS StageDurationInDays,
		|	ISNULL(NormativeDurationOfStages.DurationInSeconds, 0)         AS StageDurationInSeconds,
		|
		|	CASE BillsOfMaterials.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END                                                                    AS DaysFromDemand,
		|
		|	ISNULL(NormativeDurationOfStages.DurationBeforeProductionIssue, 0)         AS DurationBeforeProductionIssue,
		|	
		|	VALUE(Enum.TypesOfSpecificationLines.Stage)                        AS LineKind
		|
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON ProductionStages.Owner = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN Catalog.BillsOfMaterials AS BillsOfMaterials
		|		ON ProductionStages.Owner = BillsOfMaterials.Ref
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = ProductionStages.Ref
		|
		|		LEFT JOIN TTRedefiningOrderOfWorkOfTypesOfWorkCenters AS RedefiningOrderOfWork
		|		ON RedefiningOrderOfWork.Stage = ProductionStages.Ref
		|			AND RedefiningOrderOfWork.Id = MainOutputProduct.Id
		|
		|WHERE
		|	NOT ProductionStages.DeletionMark
		|
		|ORDER BY
		|	Id, StageNumber";
		
		If GetFunctionalOption("StoreOperationsInBillsOfMaterials") Then
			TextOfRouteMapField = "
			|	""""                                                AS RouteSheet,";
			TextOfRouteMapField = "
			|	VALUE(Catalog.RouteSheets.EmptyRef)   AS RouteSheet,";
			TextOfRouteMapField = TextOfRouteMapField + "
			|	0                                                   AS RouteSheetFactor,
			|	0                                                   AS RouteMapCoefficientPerUnitOfIssueBatch";
		Else
			TextOfRouteMapField = "
			|	ProductionStages.RouteSheet                   AS RouteSheet,
			|	ProductionStages.RouteSheetFactor        AS RouteSheetFactor,
			|	ProductionStages.RouteSheetFactor        AS RouteMapCoefficientPerUnitOfIssueBatch";
		EndIf;
		QueryText = StrReplace(QueryText, "&TextOfRouteMapField", TextOfRouteMapField);
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "Stages");
	
	EndIf;
	
	#EndRegion
	
	#Region ManufacturedProducts
	
	If ListOfData.Find("ManufacturedProducts") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	&OutputProducts_Presentations,
		|	TTWares.Id                         AS Id,
		|	TTWares.LineNumber                           AS LineNumber,
		|	TTWares.ProductKind                       AS ProductKind,
		|	TTWares.Products                          AS Products,
		|	TTWares.Characteristic                        AS Characteristic,
		|	TTWares.AnyCharacteristic                   AS AnyCharacteristic,
		|
		|	ISNULL(TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)  AS PackagingPiece,
		|
		|	0                                               AS Count,
		|	TTWares.NumberOfPackages                    AS NumberOfPackages,
		|	TTWares.NumberOfPackages                    AS NumberOfPackagesPerUnitOfProductionBatch,
		|	TTWares.Package                              AS Package,
		|	UNDEFINED                                    AS PackageData,
		|
		|	ISNULL(TTWares.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))  AS UnitOfMeasure,
		|	ISNULL(TTWares.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|
		|	MainOutputProduct.Count              AS ProductQuantity,
		|
		|	&CostShare                                  AS CostShare,
		|	&CostSharePerUnit                         AS CostSharePerUnit,
		|
		|	TTWares.Stage                                  AS Stage,
		|	TTWares.Stage.Department                    AS StageSubdivision,
		|	TTWares.Operation                              AS Operation,
		|
		|	&WarehouseTextField                                 AS Warehouse,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)       AS ThisIsWorkshopPantry,
		|	CASE
		|		WHEN TTWares.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                           AS ItemVariantsAreUsed,
		|	TTWares.ProcessByBOM              AS ProcessByBOM,
		|	TTWares.ProcessBySpecificationSpecification  AS BillOfMaterials,
		|
		|	CASE
		|		WHEN &ConsiderProbabilityOfDefectiveGoods
		|			THEN TTWares.ShareOfNonconformity / 100
		|		ELSE 0
		|	END                                           AS DefectiveGoodsRate,
		|
		|	CASE 
		|		WHEN (TTWares.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		|				OR TTWares.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
		|				AND &UseParameterization
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                           AS UseAutoselection,
		|	PRESENTATION("""")                             AS AutoselectionDetails,
		|	TTWares.MethodOfProductsAutoselection          AS MethodOfProductsAutoselection,
		|	TTWares.MethodOfItemVariantAutoselection        AS MethodOfItemVariantAutoselection,
		|	TTWares.PropertyThatContainsProducts        AS PropertyThatContainsProducts,
		|	TTWares.ItemVariantAutoSelectionAlgorithm      AS ItemVariantAutoSelectionAlgorithm,
		|	TTWares.ProductDescription                       AS ProductDescription,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN TTWares.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                           AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                             AS Formula,
		|	PRESENTATION("""")                             AS FormulaCalculationError,
		|
		// rounding:
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND TTWares.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|			VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			VALUE(Enum.TypesOfMeasuredValues.Length),
		|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)    AS RoundOff,
		|
		|	CASE TTWares.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
		|	END                                             AS DaysFromNeedStandard,
		|	0                                                 AS DaysFromDemand,
		|
		|	ISNULL(NormativeDurationOfStages.DurationBeforeProductionIssue, 0) AS DurationBeforeProductionIssue,
		|
		|	VALUE(Enum.TypesOfSpecificationLines.FinishedProduct)     AS LineKind,
		|
		|	TTWares.ConnectionKey                             AS ConnectionKey
		|
		|FROM
		|	TTWares AS TTWares
		|
		|		LEFT JOIN TTWares AS MainOutputProduct
		|		ON TTWares.Id = MainOutputProduct.Id
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON TTWares.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND TTWares.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = TTWares.Stage
		|
		|		,ConnectionTextContentTransferSettings
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON &WarehouseTextField = CatWarehouses.Ref
		|
		|		,CompoundShareCost
		|
		|WHERE
		|	TTWares.Product_Type = 0
		|		AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|ORDER BY
		|	Id, LineNumber";
		
		// For compatibility with 2.1, getting a warehouse for the main output product
		NameOfProductsTable =
			?(SelectionParameters.SoftwareFillingOption = Enums.ProductionSupplyFillingVariants.BySupplySchemes,
			"TTWares",
			"MainOutputProduct");
		
		RequestTextForGettingWarehouse = ProductionSupply.RequestTextForContentTransferSettings(
			NameOfProductsTable,
			"Stage.Department",
			SelectionParameters.SoftwareFillingOption);
			
		QueryText = StrReplace(
							QueryText, 
							",ConnectionTextContentTransferSettings",
							RequestTextForGettingWarehouse.JoinText);
							
		QueryText = StrReplace(
							QueryText, 
							"&WarehouseTextField",
							RequestTextForGettingWarehouse.WarehouseTextField);
		
		TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
							"MeasuredValueType",
							"TTWares.Package",
							"TTWares.Products");
		QueryText = StrReplace(
							QueryText, 
							"&QueryTextMeasuredValueType",
							TextOfMeasuredValueTypeField);

		If SelectionParameters.CalculateShareOfCostOfOutputProducts Then
		
			If UsePriceManagementSystem25 Then
				SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm(
					"TTWares",
					"TTWares.BillOfMaterials.MethodOfAllocatingFinishedProductCosts",
					"(Products, PricingVariant, PricingBatch, PricingPackage) IN (
					|	SELECT
					|		T.Products,
					|		T.PricingVariant,
					|		T.PricingBatch,
					|		T.PricingPackage
					|	FROM
					|		TTWares AS T
					|	WHERE
					|		T.Product_Type = 0
					|		AND T.BillOfMaterials.MethodOfAllocatingFinishedProductCosts =
					|			VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost))",
					UsePriceManagementSystem25);
			Else
				SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm(
					"TTWares",
					"TTWares.BillOfMaterials.MethodOfAllocatingFinishedProductCosts",
					"(Products, Characteristic) IN (
					|	SELECT
					|		T.Products,
					|		T.Characteristic
					|	FROM
					|		TTWares AS T
					|	WHERE
					|		T.Product_Type = 0
					|		AND T.BillOfMaterials.MethodOfAllocatingFinishedProductCosts =
					|			VALUE(Enum.MethodsOfCostAllocatingOnProductCosts.ByTargetCost))");
			EndIf;
			
			ProductionServer.PerformSubstitutionOfCostFractionCalculationAlgorithm(QueryText, SubstitutionParameters, UsePriceManagementSystem25);
			
		Else
			
			SubstitutionParameters = ProductionServer.SubstitutionParametersOfCostFractionCalculationAlgorithm("TTWares");
			
			QueryText = StrReplace(QueryText, SubstitutionParameters.CompoundShareCost, "");
			QueryText = StrReplace(QueryText, SubstitutionParameters.CostSharePerUnit, "0");
			QueryText = StrReplace(QueryText, SubstitutionParameters.CostShare, SubstitutionParameters.SourceCostShare);
		
		EndIf;
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "ManufacturedProducts");
		
	EndIf;
	
	#EndRegion
	
	#Region RecyclableWaste
	
	If ListOfData.Find("RecyclableWaste") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	&ReturnableWaste_Presentations,
		|	TTWares.Id                            AS Id,
		|	TTWares.LineNumber                              AS LineNumber,
		|	TTWares.ProductKind                          AS ProductKind,
		|	TTWares.Products                             AS Products,
		|	TTWares.Characteristic                           AS Characteristic,
		|	TTWares.AnyCharacteristic                      AS AnyCharacteristic,
		|
		|	ISNULL(TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PackagingPiece,
		|
		|	0                                                  AS Count,
		|	TTWares.NumberOfPackages                       AS NumberOfPackages,
		|	TTWares.NumberOfPackages                       AS NumberOfPackagesPerUnitOfProductionBatch,
		|	ISNULL(TTWares.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	TTWares.Package                                 AS Package,
		|	UNDEFINED                                       AS PackageData,
		|
		|	ISNULL(MainOutputProduct.Count, 0)    AS ProductQuantity,
		|
		|	TTWares.Stage                                     AS Stage,
		|	TTWares.Stage.Department                       AS StageSubdivision,
		|	TTWares.Stage.StageNumber                          AS StageNumber,
		|	TTWares.Stage.NextStageNo                AS NextStageNo,
		|	TTWares.Operation                                 AS Operation,
		|
		|	&WarehouseTextField                                    AS Warehouse,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)          AS ThisIsWorkshopPantry,
		|	ISNULL(TTWares.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	CASE
		|		WHEN TTWares.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                              AS ItemVariantsAreUsed,
		|	TTWares.ProcessByBOM                 AS ProcessByBOM,
		|	TTWares.ProcessBySpecificationSpecification     AS BillOfMaterials,
		|	TTWares.ItIsSubjectToRAndM                          AS ItIsSubjectToRAndM,
		|
		|	TTWares.ProductCostElement                        AS ProductCostElement,
		|
		|	CASE 
		|		WHEN (TTWares.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		|				OR TTWares.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
		|				AND &UseParameterization
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                              AS UseAutoselection,
		|	PRESENTATION("""")                                AS AutoselectionDetails,
		|	TTWares.MethodOfProductsAutoselection             AS MethodOfProductsAutoselection,
		|	TTWares.MethodOfItemVariantAutoselection           AS MethodOfItemVariantAutoselection,
		|	TTWares.PropertyThatContainsProducts           AS PropertyThatContainsProducts,
		|	TTWares.ItemVariantAutoSelectionAlgorithm         AS ItemVariantAutoSelectionAlgorithm,
		|	TTWares.ProductDescription                          AS ProductDescription,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN TTWares.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                              AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                AS Formula,
		|	PRESENTATION("""")                                AS FormulaCalculationError,
		|
		// rounding:
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND TTWares.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|			VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			VALUE(Enum.TypesOfMeasuredValues.Length),
		|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)      AS RoundOff,
		|
		|	CASE TTWares.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
		|	END                                             AS DaysFromNeedStandard,
		|	0                                                 AS DaysFromDemand,
		|
		|	ISNULL(NormativeDurationOfStages.DurationBeforeProductionIssue, 0) AS DurationBeforeProductionIssue,
		|
		|	VALUE(Enum.TypesOfSpecificationLines.SideExit) AS LineKind,
		|
		|	TTWares.ConnectionKey                         AS ConnectionKey
		|
		|FROM
		|	TTWares AS TTWares
		|
		|		LEFT JOIN TTWares AS MainOutputProduct
		|		ON TTWares.Id = MainOutputProduct.Id
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON TTWares.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND TTWares.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = TTWares.Stage
		|
		|		,ConnectionTextContentTransferSettings
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON &WarehouseTextField = CatWarehouses.Ref
		|
		|WHERE
		|	TTWares.Product_Type = 2
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|";
		
		QueryText = StrReplace(QueryText, 
			"&QueryTextMeasuredValueType",
			Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
				"MeasuredValueType",
				"TTWares.Package",
				"TTWares.Products"));
		
		// For compatibility with 2.1, getting a warehouse for the main output product
		NameOfProductsTable =
			?(SelectionParameters.SoftwareFillingOption = Enums.ProductionSupplyFillingVariants.BySupplySchemes,
			"TTWares",
			"MainOutputProduct");
		
		RequestTextForGettingWarehouse = ProductionSupply.RequestTextForContentTransferSettings(
			NameOfProductsTable,
			"Stage.Department",
			SelectionParameters.SoftwareFillingOption);
			
		QueryText = StrReplace(
							QueryText, 
							",ConnectionTextContentTransferSettings",
							RequestTextForGettingWarehouse.JoinText);
							
		QueryText = StrReplace(
							QueryText, 
							"&WarehouseTextField",
							RequestTextForGettingWarehouse.WarehouseTextField);
		If ThereIsIntermediateRelease Then
			
			QueryTextPVData = "
			|SELECT
			|	&IntermediateRelease_Views,
			|	MainOutputProduct.Id                             AS Id,
			|	CAST(IntermediateRelease.LineNumber AS NUMBER(10,0)) + 10000 AS LineNumber,
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products.ProductKind
			|		ELSE MainOutputProduct.ProductKind
			|	END AS ProductKind,
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products
			|		WHEN ItemIsNew.ItemOfIntermediateRelease IS NOT NULL
			|			THEN ItemIsNew.ItemOfIntermediateRelease
			|		ELSE ISNULL(Products_Selected.ItemOfIntermediateRelease, VALUE(Catalog.Products.EmptyRef))
			|	END AS Products,
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Characteristic
			|		WHEN ItemIsNew.ItemOfIntermediateRelease IS NOT NULL
			|			THEN ItemIsNew.CharacteristicsOfIntermediateRelease
			|		ELSE ISNULL(Products_Selected.CharacteristicsOfIntermediateRelease, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|	END AS Characteristic,
			|	CASE
			|		WHEN IntermediateRelease.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS AnyCharacteristic,
			|	
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
			|		ELSE MainOutputProduct.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
			|	END AS PieceUnitOfMeasure,
			|	FALSE AS PackagingPiece,
			|
			|	MainOutputProduct.Count                AS Count,
			|	MainOutputProduct.Count                AS NumberOfPackages,
			|	MainOutputProduct.Count                AS NumberOfPackagesPerUnitOfProductionBatch,
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products.UnitOfMeasure
			|		ELSE MainOutputProduct.Products.UnitOfMeasure
			|	END AS UnitOfMeasure,
			|
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|	UNDEFINED AS PackageData,
			|
			|	MainOutputProduct.Count AS ProductQuantity,
			|
			|	IntermediateRelease.StageSender                      AS Stage,
			|	IntermediateRelease.StageSender.Department        AS StageSubdivision,
			|	IntermediateRelease.StageSender.StageNumber           AS StageNumber,
			|	IntermediateRelease.StageSender.NextStageNo AS NextStageNo,
			|	IntermediateRelease.SenderOperation                  AS Operation,
			|
			|	&WarehouseTextField                           AS Warehouse,
			|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE) AS ThisIsWorkshopPantry,
			|
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products.ItemsType
			|		ELSE MainOutputProduct.Products.ItemsType
			|	END AS ItemsType,
			|	CASE
			|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN IntermediateRelease.Products.UseVariants IN (
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
			|		ELSE MainOutputProduct.Products.UseVariants IN (
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
			|	END AS ItemVariantsAreUsed,
			|
			|	FALSE AS ProcessByBOM,
			|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
			|	FALSE AS ItIsSubjectToRAndM,
			|
			|	VALUE(Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess) AS ProductCostElement,
			|
			|	FALSE                AS UseAutoselection,
			|	PRESENTATION("""") AS AutoselectionDetails,
			|	UNDEFINED        AS MethodOfProductsAutoselection,
			|	UNDEFINED        AS MethodOfItemVariantAutoselection,
			|	UNDEFINED        AS PropertyThatContainsProducts,
			|	""""                AS ItemVariantAutoSelectionAlgorithm,
			|	""""                AS ProductDescription,
			|
			// calculation by the formula:
			|	""""                AS QuantityCalculationAlgorithm,
			|	PRESENTATION("""") AS Formula,
			|	PRESENTATION("""") AS FormulaCalculationError,
			|
			// rounding:
			|	FALSE AS RoundOff,
			|
			|	CASE MainOutputProduct.ProductionProcessType
			|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
			|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
			|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0) + ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0)
			|	END AS DaysFromNeedStandard,
			|	0     AS DaysFromDemand,
			|
			|	ISNULL(NormativeDurationOfStages.DurationBeforeProductionIssue, 0) AS DurationBeforeProductionIssue,
			|
			|	VALUE(Enum.TypesOfSpecificationLines.IntermediateSemiFinishedProduct) AS LineKind,
			|
			|	IntermediateRelease.ConnectionKey AS ConnectionKey
			|FROM
			|	TTIntermediateRelease AS IntermediateRelease
			|
			|		INNER JOIN TTWares AS MainOutputProduct
			|		ON IntermediateRelease.Ref = MainOutputProduct.BillOfMaterials
			|			AND MainOutputProduct.ThisIsMainProduct
			|
			|		LEFT JOIN TTItemOfIntermediateReleaseIsNew AS ItemIsNew
			|		ON MainOutputProduct.Products = ItemIsNew.Products
			|			AND MainOutputProduct.Characteristic = ItemIsNew.Characteristic
			|
			|		LEFT JOIN TTItemsOfIntermediateReleaseSelected AS Products_Selected
			|		ON MainOutputProduct.Products = Products_Selected.Products
			|			AND MainOutputProduct.Characteristic = Products_Selected.Characteristic
			|
					// A request to get a warehouse is inserted here
			|		,ConnectionTextContentTransferSettings
			|
			|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
			|		ON NormativeDurationOfStages.Stage = IntermediateRelease.StageSender
			|
			|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
			|		ON &WarehouseTextField = CatWarehouses.Ref
			|";
			
			RequestTextForGettingWarehouse = ProductionSupply.RequestTextForContentTransferSettings(
				"MainOutputProduct",
				"&Department",
				SelectionParameters.SoftwareFillingOption);
			QueryTextPVData = StrReplace(
								QueryTextPVData, 
								",ConnectionTextContentTransferSettings",
								RequestTextForGettingWarehouse.JoinText);
			QueryTextPVData = StrReplace(
								QueryTextPVData, 
								"&WarehouseTextField",
								RequestTextForGettingWarehouse.WarehouseTextField);
			QueryTextPVData = StrReplace(
								QueryTextPVData, 
								"&Department",
								"IntermediateRelease.StageSender.Department");
			
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + QueryTextPVData;
			
		EndIf;
		QueryText = QueryText + "
		|ORDER BY
		|	Id, LineNumber";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "RecyclableWaste");
		
	EndIf;
	
	#EndRegion
	
	#Region IncomingProducts
	
	If ListOfData.Find("IncomingProducts") <> Undefined Or SelectionParameters.CombineMaterialsAndIncomingProducts Then
		
		QueryText = "
		|SELECT
		|	&IncomingFinishedProducts_Presentations,
		|	TTWares.Id                         AS Id,
		|	TTWares.BillOfMaterials                          AS Ref,
		|	1                                               AS LineNumber,
		|
		|	TTWares.Products                          AS Products,
		|	TTWares.Characteristic                        AS Characteristic,
		|
		|	TTWares.Products.ItemsType          AS ItemsType,
		|	CASE
		|		WHEN TTWares.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                           AS ItemVariantsAreUsed,
		|
		|	TTWares.AnyCharacteristic                   AS AnyCharacteristic,
		|
		|	0                                               AS Count,
		|	TTWares.NumberOfPackages                    AS NumberOfPackages,
		|	TTWares.NumberOfPackages                    AS NumberOfPackagesPerUnitOfProductionBatch,
		|	TTWares.Products.UnitOfMeasure         AS UnitOfMeasure,
		|	TTWares.Package                              AS Package,
		|	UNDEFINED                                    AS PackageData,
		|
		|	TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)            AS PackagingPiece,
		|
		|	MainOutputProduct.Count              AS ProductQuantity,
		|
		|	FALSE                                            AS Produced,
		|
		|	&WarehouseTextField                                 AS Warehouse,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)       AS ThisIsWorkshopPantry,
		|	&TextFieldSoftwareOption                    AS SupplyOption,
		|	&TextFieldIsSeparate                           AS WithAssignment,
		|	TTWares.MethodOfReceivingMaterial              AS MethodOfReceivingMaterial,
		|	CASE
		|		WHEN TTWares.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Repair)
		|			THEN VALUE(Catalog.ProductCostElements.ProductsUnderRepair)
		|		WHEN TTWares.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN VALUE(Catalog.ProductCostElements.ProductsBeingDisassembled)
		|	END                                           AS ProductCostElement,
		|
		|	TTWares.Stage                                  AS Stage,
		|	TTWares.Stage                                  AS StageEditing,
		|
		|	TTWares.Stage.StageNumber                       AS StageNumber,
		|	TTWares.Stage.NextStageNo             AS NextStageNo,
		|	TTWares.Stage.Department                    AS StageSubdivision,
		|
		|	TTWares.Operation                              AS Operation,
		|
		|	CASE TTWares.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END AS DaysFromNeedStandard,
		|	0     AS DaysFromDemand,
		|
		|	ISNULL(CASE
		|			WHEN NormativeDurationOfStages.DurationInSeconds = 0 THEN
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + 0.0001
		|			ELSE 
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + NormativeDurationOfStages.DurationInSeconds
		|		END, 0) AS DurationBeforeProductionIssue,
		|
		|	1                                               AS ProbabilityCoefficient,
		|	TTWares.ProductionStart                    AS ProductionStart,
		|
		// rounding:
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND TTWares.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND TTWares.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|			VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			VALUE(Enum.TypesOfMeasuredValues.Length),
		|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)      AS RoundOff,
		|
		|	VALUE(Enum.TypesOfSpecificationLines.IncomingProduct) AS LineKind,
		|
		|	TTWares.ConnectionKey                              AS ConnectionKey
		|
		|FROM
		|	TTWares AS TTWares
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON TTWares.Id = MainOutputProduct.Id
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON TTWares.Stage = NormativeDurationOfStages.Stage
		|
				// A request is inserted here to receive a warehouse, a security option
		|		,ConnectionTextSoftwareParameters
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON &WarehouseTextField = CatWarehouses.Ref
		|
		|WHERE
		|	TTWares.Product_Type = 1
		|
		|ORDER BY
		|	Id";
		
		TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"MeasuredValueType",
			"TTWares.Package",
			"TTWares.Products");
		QueryText = StrReplace(
			QueryText, 
			"&QueryTextMeasuredValueType",
			TextOfMeasuredValueTypeField);
			
		ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryText,
			"TTWares",
			"MethodOfReceivingMaterial",
			"Stage.Department",
			Enums.ProductionSupplyFillingVariants.BySupplySchemes);
			
		QueryText = StrReplace(QueryText, "&ReferenceOrder", "TTWares.ReferenceOrder");
		QueryText = StrReplace(QueryText, "&Purpose"  , "TTWares.Purpose");
			
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "IncomingProducts");
		
	EndIf;
	
	#EndRegion
	
	#Region MaterialsAndServices
	
	If ListOfData.Find("MaterialsAndServices") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	&MaterialsAndServices_Presentations,
		|	MainOutputProduct.Id                  AS Id,
		|	CAST(MaterialsAndServices.LineNumber AS NUMBER(10,0)) AS LineNumber,
		|	MaterialsAndServices.Products                          AS Products,
		|	MaterialsAndServices.Characteristic                        AS Characteristic,
		|	ISNULL(MaterialsAndServices.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|
		|	CASE 
		|		WHEN MaterialsAndServices.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                             AS ItemVariantsAreUsed,
		|	CASE
		|		WHEN MaterialsAndServices.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                             AS AnyCharacteristic,
		|
		|	0                                                 AS Count,
		|	MaterialsAndServices.NumberOfPackages               AS NumberOfPackages,
		|	MaterialsAndServices.NumberOfPackages               AS NumberOfPackagesPerUnitOfProductionBatch,
		|	ISNULL(MaterialsAndServices.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	MaterialsAndServices.Package                         AS Package,
		|	UNDEFINED                                      AS PackageData,
		|
		|	ISNULL(MaterialsAndServices.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)                   AS PackagingPiece,
		|
		|	MainOutputProduct.Count                AS ProductQuantity,
		|
		|	MaterialsAndServices.Stage                             AS Stage,
		|	MaterialsAndServices.Operation                         AS Operation,
		|
		|	&WarehouseTextField                                   AS Warehouse,
		|	&TextFieldSoftwareOption                      AS SupplyOption,
		|	&TextFieldIsSeparate                             AS WithAssignment,
		|	MaterialsAndServices.Stage.Department               AS StageSubdivision,
		|	MaterialsAndServices.Stage.ProductionByThirdParty       AS ProductionByThirdParty,
		|	MaterialsAndServices.Stage.StageNumber                  AS StageNumber,
		|	MaterialsAndServices.Stage.NextStageNo        AS NextStageNo,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)         AS ThisIsWorkshopPantry,
		|
		|	&TextFieldOrderToWarehouse                         AS OrderToWarehouse,
		|
		|	&ScheduleTextField                           AS ToPlan,
		|
		|	MaterialsAndServices.ProductCostElement                AS ProductCostElement,
		|
		|	CASE 
		|		WHEN (MaterialsAndServices.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		|				OR MaterialsAndServices.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
		|				AND &UseParameterization
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                              AS UseAutoselection,
		|	PRESENTATION("""")                                AS AutoselectionDetails,
		|	MaterialsAndServices.MethodOfProductsAutoselection      AS MethodOfProductsAutoselection,
		|	MaterialsAndServices.MethodOfItemVariantAutoselection    AS MethodOfItemVariantAutoselection,
		|	MaterialsAndServices.PropertyThatContainsProducts    AS PropertyThatContainsProducts,
		|	MaterialsAndServices.ItemVariantAutoSelectionAlgorithm  AS ItemVariantAutoSelectionAlgorithm,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN MaterialsAndServices.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                              AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                AS Formula,
		|	PRESENTATION("""")                                AS FormulaCalculationError,
		|
		// rounding:
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND MaterialsAndServices.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND MaterialsAndServices.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|				VALUE(Enum.TypesOfMeasuredValues.Weight),
		|				VALUE(Enum.TypesOfMeasuredValues.Length),
		|				VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|				VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)) , FALSE) AS RoundOff,
		|	
		|	MaterialsAndServices.ProducedInProcess AS Produced,
		|	MaterialsAndServices.ProducedInProcess AS ProducedInProcess,
		|	MaterialsAndServices.MethodOfReceivingMaterial AS MethodOfReceivingMaterial,
		|	MaterialsAndServices.SourceOfSemiFinishedProduct AS SourceOfSemiFinishedProduct,
		|
		|
		|	CASE
		|		WHEN MaterialsAndServices.BillOfMaterialsRM <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
		|			THEN MaterialsAndServices.BillOfMaterialsRM
		|		ELSE ISNULL(CAST(MaterialsAndServices.SourceOfSemiFinishedProduct AS Catalog.BillsOfMaterials), VALUE(Catalog.BillsOfMaterials.EmptyRef))
		|	END AS BillOfMaterials,
		|
		|	MaterialsAndServices.PlanNotEarlierThan  AS PlanNotEarlierThan,
		|	MaterialsAndServices.BillOfMaterialsRM AS BillOfMaterialsRM,
		|
		|	CASE MaterialsAndServices.Ref.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END AS DaysFromNeedStandard,
		|	0     AS DaysFromDemand,
		|
		|	ISNULL(CASE
		|			WHEN NormativeDurationOfStages.DurationInSeconds = 0 THEN
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + 0.0001
		|			ELSE 
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + NormativeDurationOfStages.DurationInSeconds
		|		END, 0) AS DurationBeforeProductionIssue,
		|
		|	MaterialsAndServices.MaterialApplication AS MaterialApplication,
		|	MaterialsAndServices.AlternateType      AS AlternateType,
		|
		|	MaterialsAndServices.Probability         AS Probability,
		|	CASE
		|		WHEN (MaterialsAndServices.AlternateType OR &MethodOfCalculationOfMaterials = VALUE(Enum.MaterialCalculationMethods.PossibleConsumption))
		|				AND MaterialsAndServices.Probability > 0
		|			THEN MaterialsAndServices.Probability / 100
		|		ELSE 1
		|	END                                                     AS ProbabilityCoefficient,
		|
		|	MainOutputProduct.ProductionStart                AS ProductionStart,
		|	MainOutputProduct.ProductionDispatcherBusinessUnit            AS ProductionDispatcherBusinessUnit,
		|
		|	FALSE                                                      AS Auxiliary,
		|	0                                                         AS Order,
		|	VALUE(Catalog.ManufacturingOperations.EmptyRef) AS OperationParent,
		|	VALUE(Enum.TypesOfSpecificationLines.Material)     AS LineKind,
		|
		|	&EmptyLinkKey                                          AS CommunicationKeySet,
		|
		|	&TextOfDirectiveReplacementField,
		|
		|	MaterialsAndServices.ConnectionKey                                AS ConnectionKey
		|FROM
		|	Catalog.BillsOfMaterials.MaterialsAndServices AS MaterialsAndServices
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON MaterialsAndServices.Ref = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		,TextCanBeOrderedToWarehouse
		|
				// A request is inserted here to receive a warehouse, a security option
		|		,ConnectionTextSoftwareParameters
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON MaterialsAndServices.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND MainOutputProduct.ID = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = MaterialsAndServices.Stage
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON &WarehouseTextField = CatWarehouses.Ref
		|
		|		,TextConnectionsWaysToEnsure
		|
		|WHERE
		|	(NOT MaterialsAndServices.AlternateType OR &MethodOfCalculationOfMaterials IN (
		|													VALUE(Enum.MaterialCalculationMethods.PossibleConsumption),
		|													VALUE(Enum.MaterialCalculationMethods.MaximumConsumption)))
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|";
		
		OrderToWarehouseField = ParametersForSubstitutingOrderToWarehouseField("MaterialsAndServices",, SelectionParameters.SoftwareFillingOption);
		
		QueryText = StrReplace(QueryText, "&TextFieldOrderToWarehouse"      , OrderToWarehouseField.FieldText);
		QueryText = StrReplace(QueryText, ",TextCanBeOrderedToWarehouse", OrderToWarehouseField.JoinText);
		
		ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryText,
			"MaterialsAndServices",
			"MethodOfReceivingMaterial",
			"&Department",
			SelectionParameters.SoftwareFillingOption);
			
		TextOfDivisionField = "
		|	(CASE
		|		WHEN MainOutputProduct.AssigneeBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN MaterialsAndServices.Stage.Department
		|		ELSE MainOutputProduct.AssigneeBusinessUnit
		|	END)
		|";
		
		QueryText = StrReplace(QueryText, "&Department", TextOfDivisionField);
		
		ScheduleTextField = "FALSE";
		TextConnectionsWaysToEnsure = "";
		If SelectionParameters.CalculateScheduleProductionAttribute Then
			ScheduleTextField = TextOfScheduleFieldSubstitution("MainOutputProduct.ProductionDispatcherBusinessUnit");
			TextConnectionsWaysToEnsure = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
				"LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
				|	ON &MainSupplyMethodSubstitution",
				"MainSupplyMethodSubstitution",
				"MaterialsAndServices.Products, MaterialsAndServices.Characteristic, CatWarehouses.Ref");
		EndIf;
		QueryText = StrReplace(QueryText, "&ScheduleTextField"           , ScheduleTextField);
		QueryText = StrReplace(QueryText, ",TextConnectionsWaysToEnsure", TextConnectionsWaysToEnsure);
		
		TextOfDirectiveReplacementField = ProductDataManagement.QueryTextOfDirectiveReplacementField(
			SelectionParameters,,
			"NOT MaterialsAndServices.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage)");
		QueryText = StrReplace(QueryText, "&TextOfDirectiveReplacementField" , TextOfDirectiveReplacementField);
		
		QueryTextTAData = "
		|SELECT
		|	&MaterialsAndServicesTP_Presentation,
		|	TTTechnologicalProcesses.Id                AS Id,
		|	CAST(MaterialsAndServices.LineNumber AS NUMBER(10,0)) AS LineNumber,
		|	MaterialsAndServices.Products                          AS Products,
		|	MaterialsAndServices.Characteristic                        AS Characteristic,
		|	ISNULL(MaterialsAndServices.Products.ItemsType, VALUE(Enum.ItemsTypes.EmptyRef)) AS ItemsType,
		|	CASE 
		|		WHEN MaterialsAndServices.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                             AS ItemVariantsAreUsed,
		|	CASE
		|		WHEN MaterialsAndServices.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                             AS AnyCharacteristic,
		|
		|	0                                                                           AS Count,
		|	MaterialsAndServices.NumberOfPackages * TTTechnologicalProcesses.ZoomRatio AS NumberOfPackages,
		|	MaterialsAndServices.NumberOfPackages * TTTechnologicalProcesses.ZoomRatio AS NumberOfPackagesPerUnitOfProductionBatch,
		|	ISNULL(MaterialsAndServices.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)) AS UnitOfMeasure,
		|	MaterialsAndServices.Package                                                   AS Package,
		|	UNDEFINED                                                                AS PackageData,
		|
		|	ISNULL(MaterialsAndServices.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)                   AS PackagingPiece,
		|
		|	MainOutputProduct.Count                AS ProductQuantity,
		|
		|	TTTechnologicalProcesses.Stage                    AS Stage,
		|	MaterialsAndServices.Operation                         AS Operation,
		|
		|	&WarehouseTextField                                   AS Warehouse,
		|	&TextFieldSoftwareOption                      AS SupplyOption,
		|	&TextFieldIsSeparate                             AS WithAssignment,
		|	TTTechnologicalProcesses.Stage.Department      AS StageSubdivision,
		|	FALSE                                              AS ProductionByThirdParty,
		|	TTTechnologicalProcesses.StageNumber              AS StageNumber,
		|	TTTechnologicalProcesses.NextStageNo    AS NextStageNo,
		|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)         AS ThisIsWorkshopPantry,
		|
		|	FALSE                                              AS OrderToWarehouse,
		|
		|	&ScheduleTextField                           AS ToPlan,
		|
		|	MaterialsAndServices.ProductCostElement                AS ProductCostElement,
		|
		|	CASE 
		|		WHEN (MaterialsAndServices.MethodOfProductsAutoselection <> VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
		|				OR MaterialsAndServices.MethodOfItemVariantAutoselection <> VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData))
		|				AND &UseParameterization
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                              AS UseAutoselection,
		|	PRESENTATION("""")                                AS AutoselectionDetails,
		|	MaterialsAndServices.MethodOfProductsAutoselection      AS MethodOfProductsAutoselection,
		|	MaterialsAndServices.MethodOfItemVariantAutoselection    AS MethodOfItemVariantAutoselection,
		|	MaterialsAndServices.PropertyThatContainsProducts    AS PropertyThatContainsProducts,
		|	MaterialsAndServices.ItemVariantAutoSelectionAlgorithm  AS ItemVariantAutoSelectionAlgorithm,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN MaterialsAndServices.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                              AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                AS Formula,
		|	PRESENTATION("""")                                AS FormulaCalculationError,
		|
		// rounding:
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND MaterialsAndServices.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND MaterialsAndServices.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|				VALUE(Enum.TypesOfMeasuredValues.Weight),
		|				VALUE(Enum.TypesOfMeasuredValues.Length),
		|				VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|				VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)     AS RoundOff,
		|
		|	FALSE                                                                         AS Produced,
		|	FALSE                                                                         AS ProducedInProcess,
		|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)  AS MethodOfReceivingMaterial,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef)                      AS SourceOfSemiFinishedProduct,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef)                      AS BillOfMaterials,
		|	
		|	VALUE(Catalog.ProductionStages.EmptyRef)                          AS PlanNotEarlierThan,
		|	VALUE(Catalog.BillsOfMaterials.EmptyRef)                      AS BillOfMaterialsRM,
		|
		|	CASE TTTechnologicalProcesses.BillOfMaterials.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END AS DaysFromNeedStandard,
		|	0     AS DaysFromDemand,
		|
		|	ISNULL(CASE
		|			WHEN NormativeDurationOfStages.DurationInSeconds = 0 THEN
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + 0.0001
		|			ELSE 
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + NormativeDurationOfStages.DurationInSeconds
		|		END, 0) AS DurationBeforeProductionIssue,
		|
		|	MaterialsAndServices.MaterialApplication           AS MaterialApplication,
		|	FALSE                                           AS AlternateType,
		|
		|	0                                              AS Probability,
		|	1                                              AS ProbabilityCoefficient,
		|
		|	MainOutputProduct.ProductionStart     AS ProductionStart,
		|	MainOutputProduct.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
		|
		|	TRUE                                                                                   AS Auxiliary,
		|	100000 * TTTechnologicalProcesses.StageNumber + TTTechnologicalProcesses.OperationNumber  AS Order,
		|	TTTechnologicalProcesses.Operation                                                       AS OperationParent,
		|	VALUE(Enum.TypesOfSpecificationLines.Material)                                    AS LineKind,
		|
		|	&EmptyLinkKey                                                                         AS CommunicationKeySet,
		|
		|	&TextOfDirectiveReplacementField,
		|
		|	MaterialsAndServices.ConnectionKey                     AS ConnectionKey
		|
		|FROM
		|	TTTechnologicalProcesses AS TTTechnologicalProcesses
		|
		|		INNER JOIN Catalog.TechnologicalProcesses.MaterialsAndServices AS MaterialsAndServices
		|		ON MaterialsAndServices.Ref = TTTechnologicalProcesses.TechnologicalProcess
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON TTTechnologicalProcesses.Id = MainOutputProduct.Id
		|			AND TTTechnologicalProcesses.BillOfMaterials = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON MaterialsAndServices.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND TTTechnologicalProcesses.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = TTTechnologicalProcesses.Stage
		|
				// A request is inserted here to receive a warehouse, a security option
		|		,ConnectionTextSoftwareParameters
		|
		|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
		|		ON &WarehouseTextField = CatWarehouses.Ref
		|
		|		,TextConnectionsWaysToEnsure
		|
		|WHERE
		|	ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|";
		
		ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryTextTAData,
			"MaterialsAndServices",
			,
			"&Department",
			SelectionParameters.SoftwareFillingOption);
			
		TextOfDivisionField = "
		|	(CASE
		|		WHEN MainOutputProduct.AssigneeBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
		|			THEN TTTechnologicalProcesses.Stage.Department
		|		ELSE MainOutputProduct.AssigneeBusinessUnit
		|	END)
		|";
			
		QueryTextTAData = StrReplace(QueryTextTAData, "&Department", TextOfDivisionField);
		QueryTextTAData = StrReplace(QueryTextTAData, "MaterialsAndServices.MethodOfReceivingMaterial", "VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide)");
		QueryTextTAData = StrReplace(QueryTextTAData, "MaterialsAndServices.WithAssignment", "FALSE");
		
		ScheduleTextField = "FALSE";
		TextConnectionsWaysToEnsure = "";
		If SelectionParameters.CalculateScheduleProductionAttribute Then
			ScheduleTextField = TextOfScheduleFieldSubstitution(
				"MainOutputProduct.ProductionDispatcherBusinessUnit",,
				"VALUE(Catalog.BillsOfMaterials.EmptyRef)");
			TextConnectionsWaysToEnsure = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
				"LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
				|	ON &MainSupplyMethodSubstitution",
				"MainSupplyMethodSubstitution",
				"MaterialsAndServices.Products, MaterialsAndServices.Characteristic, CatWarehouses.Ref");
		EndIf;
		QueryTextTAData = StrReplace(QueryTextTAData, "&ScheduleTextField"           , ScheduleTextField);
		QueryTextTAData = StrReplace(QueryTextTAData, ",TextConnectionsWaysToEnsure", TextConnectionsWaysToEnsure);
		
		TextOfDirectiveReplacementField = ProductDataManagement.QueryTextOfDirectiveReplacementField(SelectionParameters);
		QueryTextTAData = StrReplace(QueryTextTAData, "&TextOfDirectiveReplacementField" , TextOfDirectiveReplacementField);
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|" + QueryTextTAData;
		
		If ThereIsIntermediateRelease Then
			
			QueryTextPVData = "
			|SELECT
			|	&PV_SubmissionMaterials,
			|	MainOutputProduct.Id AS Id,
			|	CAST(UsedMaterials.LineNumber AS NUMBER(10,0)) + 10000 AS LineNumber,
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Products
			|		WHEN ItemIsNew.ItemOfIntermediateRelease IS NOT NULL
			|			THEN ItemIsNew.ItemOfIntermediateRelease
			|		ELSE ISNULL(Products_Selected.ItemOfIntermediateRelease, VALUE(Catalog.Products.EmptyRef))
			|	END AS Products,
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Characteristic
			|		WHEN ItemIsNew.ItemOfIntermediateRelease IS NOT NULL
			|			THEN ItemIsNew.CharacteristicsOfIntermediateRelease
			|		ELSE ISNULL(Products_Selected.CharacteristicsOfIntermediateRelease, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
			|	END AS Characteristic,
			|
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Products.ItemsType
			|		ELSE MainOutputProduct.Products.ItemsType
			|	END AS ItemsType,
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Products.UseVariants IN (
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
			|		ELSE MainOutputProduct.Products.UseVariants IN (
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
			|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
			|	END AS ItemVariantsAreUsed,
			|	CASE
			|		WHEN UsedMaterials.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
			|			THEN TRUE
			|		ELSE FALSE
			|	END AS AnyCharacteristic,
			|
			|	MainOutputProduct.Count      AS Count,
			|	MainOutputProduct.Count      AS NumberOfPackages,
			|	MainOutputProduct.Count      AS NumberOfPackagesPerUnitOfProductionBatch,
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Products.UnitOfMeasure
			|		ELSE MainOutputProduct.Products.UnitOfMeasure
			|	END AS UnitOfMeasure,
			|
			|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
			|	UNDEFINED AS PackageData,
			|
			|	CASE
			|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
			|			THEN UsedMaterials.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
			|		ELSE MainOutputProduct.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
			|	END AS PieceUnitOfMeasure,
			|	FALSE AS PackagingPiece,
			|
			|	MainOutputProduct.Count AS ProductQuantity,
			|
			|	UsedMaterials.RecipientStage     AS Stage,
			|	UsedMaterials.OperationRecipient AS Operation,
			|
			|	&WarehouseTextField                                         AS Warehouse,
			|	VALUE(Enum.SupplyOptions.ToSupply) AS SupplyOption,
			|	TRUE                                                  AS WithAssignment,
			|
			|	UsedMaterials.RecipientStage.Department         AS StageSubdivision,
			|	UsedMaterials.RecipientStage.ProductionByThirdParty AS ProductionByThirdParty,
			|	UsedMaterials.RecipientStage.StageNumber            AS StageNumber,
			|	UsedMaterials.RecipientStage.NextStageNo  AS NextStageNo,
			|	ISNULL(CatWarehouses.ShopFloorStockroom, FALSE)  AS ThisIsWorkshopPantry,
			|
			|	FALSE AS OrderToWarehouse,
			|
			|	FALSE AS ToPlan,
			|
			|	VALUE(Catalog.ProductCostElements.SemiFinishedProductsProducedInProcess) AS ProductCostElement,
			|
			|	FALSE                AS UseAutoselection,
			|	PRESENTATION("""") AS AutoselectionDetails,
			|	UNDEFINED        AS MethodOfProductsAutoselection,
			|	UNDEFINED        AS MethodOfItemVariantAutoselection,
			|	UNDEFINED        AS PropertyThatContainsProducts,
			|	""""                AS ItemVariantAutoSelectionAlgorithm,
			|
			// calculation by the formula:
			|	""""                AS QuantityCalculationAlgorithm,
			|	PRESENTATION("""") AS Formula,
			|	PRESENTATION("""") AS FormulaCalculationError,
			|
			// rounding:
			|	FALSE AS RoundOff,
			|
			|	TRUE AS Produced,
			|	TRUE AS ProducedInProcess,
			|	VALUE(Enum.MethodsOfReceivingBOMMaterials.ProducedOnStage) AS MethodOfReceivingMaterial,
			|	UsedMaterials.StageSender AS SourceOfSemiFinishedProduct,
			|
			|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterials,
			|	
			|	VALUE(Catalog.ProductionStages.EmptyRef)     AS PlanNotEarlierThan,
			|	VALUE(Catalog.BillsOfMaterials.EmptyRef) AS BillOfMaterialsRM,
			|
			|	CASE MainOutputProduct.ProductionProcessType
			|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
			|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
			|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
			|	END AS DaysFromNeedStandard,
			|	0     AS DaysFromDemand,
			|
			|	ISNULL(CASE
			|			WHEN NormativeDurationOfStages.DurationInSeconds = 0 THEN
			|				NormativeDurationOfStages.DurationBeforeProductionIssue + 0.0001
			|			ELSE 
			|				NormativeDurationOfStages.DurationBeforeProductionIssue + NormativeDurationOfStages.DurationInSeconds
			|		END, 0) AS DurationBeforeProductionIssue,
			|	
			|	""""                                           AS MaterialApplication,
			|	FALSE                                           AS AlternateType,
			|
			|	0                                              AS Probability,
			|	1                                              AS ProbabilityCoefficient,
			|
			|	MainOutputProduct.ProductionStart     AS ProductionStart,
			|	MainOutputProduct.ProductionDispatcherBusinessUnit AS ProductionDispatcherBusinessUnit,
			|
			|	FALSE                                                      AS Auxiliary,
			|	0                                                         AS Order,
			|	VALUE(Catalog.ManufacturingOperations.EmptyRef) AS OperationParent,
			|	VALUE(Enum.TypesOfSpecificationLines.IntermediateSemiFinishedProduct) AS LineKind,
			|
			|	&EmptyLinkKey                                          AS CommunicationKeySet,
			|
			|	&TextOfDirectiveReplacementField,
			|
			|	UsedMaterials.ConnectionKey                                       AS ConnectionKey
			|FROM
			|	TTIntermediateRelease AS UsedMaterials
			|
			|		INNER JOIN TTWares AS MainOutputProduct
			|		ON UsedMaterials.Ref = MainOutputProduct.BillOfMaterials
			|			AND MainOutputProduct.ThisIsMainProduct
			|
			|		LEFT JOIN TTItemOfIntermediateReleaseIsNew AS ItemIsNew
			|		ON MainOutputProduct.Products = ItemIsNew.Products
			|			AND MainOutputProduct.Characteristic = ItemIsNew.Characteristic
			|
			|		LEFT JOIN TTItemsOfIntermediateReleaseSelected AS Products_Selected
			|		ON MainOutputProduct.Products = Products_Selected.Products
			|			AND MainOutputProduct.Characteristic = Products_Selected.Characteristic
			|
					// A request to get a warehouse is inserted here
			|		,ConnectionTextSoftwareParameters
			|
			|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
			|		ON NormativeDurationOfStages.Stage = UsedMaterials.RecipientStage
			|
			|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
			|		ON &WarehouseTextField = CatWarehouses.Ref
			|";
			
			ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryTextPVData,
				"MainOutputProduct",
				,
				"&Department",
				SelectionParameters.SoftwareFillingOption);
			TextOfDivisionField = "
			|	(CASE
			|		WHEN MainOutputProduct.AssigneeBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
			|			THEN UsedMaterials.RecipientStage.Department
			|		ELSE MainOutputProduct.AssigneeBusinessUnit
			|	END)
			|";
			QueryTextPVData = StrReplace(QueryTextPVData, "&Department", TextOfDivisionField);
			
			TextOfDirectiveReplacementField = ProductDataManagement.QueryTextOfDirectiveReplacementField();
			QueryTextPVData = StrReplace(QueryTextPVData, "&TextOfDirectiveReplacementField" , TextOfDirectiveReplacementField);
			
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|" + QueryTextPVData;
			
		EndIf;
		QueryText = QueryText + "
		|ORDER BY
		|	Id,
		|	Order,
		|	LineNumber";
		
		TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"MeasuredValueType",
			"MaterialsAndServices.Package",
			"MaterialsAndServices.Products");
		QueryText = StrReplace(
			QueryText, 
			"&QueryTextMeasuredValueType",
			TextOfMeasuredValueTypeField);
		
		QueryText = StrReplace(QueryText, "&ReferenceOrder", "MainOutputProduct.ReferenceOrder");
		QueryText = StrReplace(QueryText, "&Purpose",   "MainOutputProduct.Purpose"); 
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "MaterialsAndServices");
		
	EndIf;
	
	#EndRegion
	
	#Region LaborCosts
	
	If ListOfData.Find("LaborCosts") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	MainOutputProduct.Id           AS Id,
		|	LaborCosts.LineNumber                        AS LineNumber,
		|	LaborCosts.WorkKind                           AS WorkKind,
		|	LaborCosts.WorkKind.UnitOfMeasure          AS UnitOfMeasure,
		|	MainOutputProduct.Count              AS ProductQuantity,
		|	LaborCosts.ProductCostElement                  AS ProductCostElement,
		|	LaborCosts.WorkAssignment                    AS WorkAssignment,
		|
		|	LaborCosts.Count AS Count,
		|	LaborCosts.Count AS QuantityPerReleaseLotUnit,
		|
		|	CASE LaborCosts.Ref.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END AS DaysFromNeedStandard,
		|	0     AS DaysFromDemand,
		|
		|	LaborCosts.Stage                                            AS Stage,
		|	LaborCosts.Operation                                        AS Operation,
		|
		|	ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0) AS StageDurationInDays,
		|
		|	LaborCosts.Stage.StageDuration                          AS StageDuration,
		|	LaborCosts.Stage.Department                              AS StageSubdivision,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN LaborCosts.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                                        AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                          AS Formula,
		|	PRESENTATION("""")                                          AS FormulaCalculationError,
		|
		|	LaborCosts.ConnectionKey AS ConnectionKey,
		|	0                                                            AS Order,
		|	VALUE(Catalog.ManufacturingOperations.EmptyRef)    AS OperationParent,
		|	FALSE                                                         AS Auxiliary
		|
		|FROM
		|	Catalog.BillsOfMaterials.LaborCosts AS LaborCosts
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON LaborCosts.Ref = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON LaborCosts.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND MainOutputProduct.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = LaborCosts.Stage
		|
		|WHERE
		|	ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|UNION ALL
		|
		|SELECT
		|	TTTechnologicalProcesses.Id         AS Id,
		|	LaborCosts.LineNumber                        AS LineNumber,
		|	LaborCosts.WorkKind                           AS WorkKind,
		|	LaborCosts.WorkKind.UnitOfMeasure          AS UnitOfMeasure,
		|	MainOutputProduct.Count              AS ProductQuantity,
		|	LaborCosts.ProductCostElement                  AS ProductCostElement,
		|	LaborCosts.WorkAssignment                    AS WorkAssignment,
		|
		|	LaborCosts.Count * TTTechnologicalProcesses.ZoomRatio AS Count,
		|	LaborCosts.Count * TTTechnologicalProcesses.ZoomRatio AS QuantityPerReleaseLotUnit,
		|
		|	CASE TTTechnologicalProcesses.BillOfMaterials.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END AS DaysFromNeedStandard,
		|	0     AS DaysFromDemand,
		|
		|	TTTechnologicalProcesses.Stage                               AS Stage,
		|	LaborCosts.Operation                                        AS Operation,
		|
		|	ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0) AS StageDurationInDays,
		|
		|	TTTechnologicalProcesses.Stage.StageDuration             AS StageDuration,
		|	TTTechnologicalProcesses.Stage.Department                 AS StageSubdivision,
		|
		|	// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN LaborCosts.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                                        AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                          AS Formula,
		|	PRESENTATION("""")                                          AS FormulaCalculationError,
		|
		|	LaborCosts.ConnectionKey AS ConnectionKey,
		|
		|	100000 * TTTechnologicalProcesses.StageNumber + TTTechnologicalProcesses.OperationNumber  AS Order,
		|	TTTechnologicalProcesses.Operation                                                       AS OperationParent,
		|
		|	TRUE                                                       AS Auxiliary
		|
		|FROM
		|	TTTechnologicalProcesses AS TTTechnologicalProcesses
		|
		|		INNER JOIN Catalog.TechnologicalProcesses.LaborCosts AS LaborCosts
		|		ON LaborCosts.Ref = TTTechnologicalProcesses.TechnologicalProcess
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON TTTechnologicalProcesses.Id = MainOutputProduct.Id
		|			AND TTTechnologicalProcesses.BillOfMaterials = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON LaborCosts.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND TTTechnologicalProcesses.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = TTTechnologicalProcesses.Stage
		|
		|WHERE
		|	ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|ORDER BY
		|	Id,
		|	Order,
		|	LineNumber
		|";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "LaborCosts");
		
	EndIf;
	
	#EndRegion
	
	#Region WorkCenterTypes
	
	If ListOfData.Find("WorkCenterTypes") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	&TypesOfWorkCenters_Presentations,
		|	MainOutputProduct.Id           AS Id,
		|	TabularSection.WorkCenterType                AS WorkCenterType,
		|	TabularSection.ConnectionKey                        AS ConnectionKey,
		|	MainOutputProduct.Count              AS ProductQuantity,
		|
		|	TTWorkingTime.OperationTime                       AS OperationTime,
		|	TTWorkingTime.OperationTime                       AS OperatingTimePerBatchUnit,
		|	TTWorkingTime.UnitOfMeasure                  AS UnitOfMeasure,
		|	TTWorkingTime.CalculateEmployment               AS CalculateEmployment,
		|	0                                               AS Occupation,
		|	0                                               AS EmploymentPerUnitOfIssueBatch,
		|
		|	TabularSection.SetupSettings                   AS SetupSettings,
		|	TabularSection.Load                         AS Load,
		|	TabularSection.Load                         AS LoadingPerUnitOfLotReference,
		|	ProductionStages.StageDuration             AS StageDuration,
		|
		|	TabularSection.WorkCenterType.ParallelLoad AS ParallelLoad,
		|	TabularSection.WorkCenterType.MaximumLoad AS MaximumLoad,
		|
		|	ISNULL(NormativeDurationOfStages.ProductionDurationDays, 0) AS StageDurationInDays,
		|
		|	CASE BillsOfMaterials.ProductionProcessType
		|		WHEN VALUE(Enum.ProductionProcessTypes.Disassembly)
		|			THEN ISNULL(NormativeDurationOfStages.DaysFromBeginning, 0)
		|		ELSE - ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0)
		|	END                                                        AS DaysFromNeedStandard,
		|	0                                                            AS DaysFromDemand,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN TabularSection.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                                                   AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                                     AS Formula,
		|	PRESENTATION("""")                                                     AS FormulaCalculationError,
		|
		|	ProductionStages.Ref                                                AS Stage,
		|	ProductionStages.Department                                         AS StageSubdivision,
		|	ProductionStages.QuantityOfProductUnitsLotsProducedSimultaneously AS QuantityOfProductUnitsLotsProducedSimultaneously
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|
		|		INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS TabularSection
		|		ON TabularSection.Ref = ProductionStages.Ref
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON ProductionStages.Owner = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN TTWorkingHoursOfTypesOfWorkCenters AS TTWorkingTime
		|		ON TabularSection.Ref = TTWorkingTime.Stage
		|			AND TabularSection.WorkCenterType = TTWorkingTime.WorkCenterType
		|			AND TabularSection.ConnectionKey = TTWorkingTime.ConnectionKey
		|
		|		LEFT JOIN Catalog.BillsOfMaterials AS BillsOfMaterials
		|		ON BillsOfMaterials.Ref = ProductionStages.Owner
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND MainOutputProduct.Id = TT_SelectionByProperties.Id
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON NormativeDurationOfStages.Stage = ProductionStages.Ref
		|
		|WHERE
		|	NOT ProductionStages.DeletionMark
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|
		|ORDER BY
		|	Id, TabularSection.LineNumber";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "WorkCenterTypes");
		
	EndIf;
	
	#EndRegion
	
	#Region AlternateWorkCenterTypes
	
	If ListOfData.Find("AlternateWorkCenterTypes") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	TTProductData_.Id                     AS Id,
		|	TablePartAlternative.WorkCenterType           AS WorkCenterType,
		|	TablePartAlternative.LinkKeyWorkCenterTypes AS LinkKeyWorkCenterTypes,
		|
		|	TTWorkingTime.OperationTime                                AS OperationTime,
		|	TTWorkingTime.OperationTime                                AS OperatingTimePerBatchUnit,
		|	TTWorkingTime.UnitOfMeasure                           AS UnitOfMeasure,
		|
		|	TablePartAlternative.SetupSettings              AS SetupSettings,
		|	TablePartAlternative.Load                    AS Load,
		|	TablePartAlternative.Load                    AS LoadingPerUnitOfLotReference,
		|	TabularSection.WorkCenterType                         AS BasicViewOfWorkCenter,
		|
		|	TablePartAlternative.WorkCenterType.ParallelLoad AS ParallelLoad,
		|	TablePartAlternative.WorkCenterType.MaximumLoad AS MaximumLoad,
		|
		// calculation by the formula:
		|	CASE
		|		WHEN &UseParameterization
		|			THEN TablePartAlternative.QuantityCalculationAlgorithm
		|		ELSE """" 
		|	END                                                                   AS QuantityCalculationAlgorithm,
		|	PRESENTATION("""")                                                     AS Formula,
		|	PRESENTATION("""")                                                     AS FormulaCalculationError,
		|
		|	ProductionStages.Ref                                                AS Stage,
		|	ProductionStages.Department                                         AS StageSubdivision,
		|	ProductionStages.QuantityOfProductUnitsLotsProducedSimultaneously AS QuantityOfProductUnitsLotsProducedSimultaneously
		|FROM
		|	Catalog.ProductionStages AS ProductionStages
		|
		|		INNER JOIN Catalog.ProductionStages.WorkCenterTypes AS TabularSection
		|		ON ProductionStages.Ref = TabularSection.Ref
		|
		|		INNER JOIN Catalog.ProductionStages.AlternateWorkCenterTypes AS TablePartAlternative
		|		ON TabularSection.Ref = TablePartAlternative.Ref
		|			AND TabularSection.ConnectionKey = TablePartAlternative.LinkKeyWorkCenterTypes
		|
		|		INNER JOIN TTProductData_ AS TTProductData_
		|		ON ProductionStages.Owner = TTProductData_.BillOfMaterials
		|
		|		LEFT JOIN TTWorkingHoursOfTypesOfWorkCenters AS TTWorkingTime
		|		ON TablePartAlternative.Ref = TTWorkingTime.Stage
		|			AND TablePartAlternative.WorkCenterType = TTWorkingTime.WorkCenterType
		|			AND TablePartAlternative.ConnectionKey = TTWorkingTime.ConnectionKey
		|
		|		LEFT JOIN TT_SelectionByProperties AS TT_SelectionByProperties
		|		ON TabularSection.ConnectionKey = TT_SelectionByProperties.ConnectionKey
		|			AND TTProductData_.Id = TT_SelectionByProperties.Id
		|		LEFT JOIN TT_SelectionByProperties AS TTSelectionByPropertiesAlternative
		|		ON TablePartAlternative.ConnectionKey = TTSelectionByPropertiesAlternative.ConnectionKey
		|			AND TTProductData_.Id = TTSelectionByPropertiesAlternative.Id
		|
		|WHERE
		|	NOT ProductionStages.DeletionMark
		|	AND ISNULL(TT_SelectionByProperties.Used, TRUE)
		|	AND ISNULL(TTSelectionByPropertiesAlternative.Used, TRUE)
		|
		|ORDER BY
		|	Id, TabularSection.LineNumber";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "AlternateWorkCenterTypes");
		
	EndIf;
	
	#EndRegion
	
	#Region ManufacturingOperations
	
	If ListOfData.Find("Operations") <> Undefined Then
		
		QueryText = "
		|SELECT
		|	TTProductData_.Id          AS Id,
		|
		|	Operations.Ref                 AS Operation,
		|	Operations.Presentation          AS OperationPresentation,
		|	Operations.Id          AS OperationID_,
		|	Operations.OperationKind            AS OperationKind,
		|	Operations.UnitOfMeasure       AS UnitOfMeasure,
		|	Operations.Load               AS Load,
		|	Operations.Continuous            AS Continuous,
		|	Operations.Repeatable         AS Repeatable,
		|	Operations.Skippable        AS Skippable,
		|	Operations.Control               AS Control,
		|	Operations.TransferLot     AS TransferLot,
		|
		|	Operations.WorkCenter      AS WorkCenter,
		|	Operations.SetupSettings    AS SetupSettings,
		|	Operations.TimePerPiece      AS TimePerPiece,
		|	Operations.TimePerPieceUnitOfMeasure AS TimePerPieceUnitOfMeasure,
		|	Operations.SetupTime           AS SetupTime,
		|	Operations.SetupTimeUnitOfMeasure      AS SetupTimeUnitOfMeasure,
		|
		|	Operations.OperationNumber                  AS OriginalOperationNumber,
		|	Operations.NextOperation         AS SourceNumberOfNextOperation,
		|
		|	Operations.Count                     AS Count,
		|
		|	Operations.TechnologicalProcess         AS TechnologicalProcess,
		|	1                                       AS TechnologicalProcessFactor,
		|	Operations.ContainsTechnologicalProcess AS ContainsTechnologicalProcess,
		|	Operations.ContainsTechnologicalProcess AS ContainsNestedRoute,
		|
		|	VALUE(Catalog.ManufacturingOperations.EmptyRef)               AS OperationParent,
		|	0                                                                       AS OperationParentID,
		|	CAST(Operations.Owner AS Catalog.ProductionStages)            AS Stage,
		|	CAST(Operations.Owner AS Catalog.ProductionStages).StageNumber AS StageNumber
		|
		|INTO TTOperations
		|
		|FROM
		|	Catalog.ManufacturingOperations AS Operations
		|
		|		INNER JOIN TTProductData_ AS TTProductData_
		|		ON Operations.BillOfMaterials = TTProductData_.BillOfMaterials
		|			AND NOT Operations.DeletionMark
		|
		|UNION ALL
		|
		|SELECT
		|	TTProductData_.Id          AS Id,
		|
		|	TAOperations.Ref                 AS Operation,
		|	TAOperations.Presentation          AS OperationPresentation,
		|	TAOperations.Id          AS OperationID_,
		|	TAOperations.OperationKind            AS OperationKind,
		|	TAOperations.UnitOfMeasure       AS UnitOfMeasure,
		|	TAOperations.Load               AS Load,
		|	TAOperations.Continuous            AS Continuous,
		|	TAOperations.Repeatable         AS Repeatable,
		|	TAOperations.Skippable        AS Skippable,
		|	TAOperations.Control               AS Control,
		|	TAOperations.TransferLot     AS TransferLot,
		|
		|	TAOperations.WorkCenter      AS WorkCenter,
		|	TAOperations.SetupSettings    AS SetupSettings,
		|	TAOperations.TimePerPiece      AS TimePerPiece,
		|	TAOperations.TimePerPieceUnitOfMeasure AS TimePerPieceUnitOfMeasure,
		|	TAOperations.SetupTime           AS SetupTime,
		|	TAOperations.SetupTimeUnitOfMeasure      AS SetupTimeUnitOfMeasure,
		|
		|	TAOperations.OperationNumber          AS OriginalOperationNumber,
		|	TAOperations.NextOperation AS SourceNumberOfNextOperation,
		|
		|	TAOperations.Count             AS Count,
		|
		|	Operations.TechnologicalProcess              AS TechnologicalProcess,
		|	Operations.TechnologicalProcessFactor AS TechnologicalProcessFactor,
		|	FALSE                                         AS ContainsTechnologicalProcess,
		|	FALSE                                         AS ContainsNestedRoute,
		|
		|	Operations.Ref                                                         AS OperationParent,
		|	Operations.Id                                                  AS OperationParentID,
		|	CAST(Operations.Owner AS Catalog.ProductionStages)            AS Stage,
		|	CAST(Operations.Owner AS Catalog.ProductionStages).StageNumber AS StageNumber
		|
		|FROM
		|	Catalog.ManufacturingOperations AS Operations
		|
		|		INNER JOIN TTProductData_ AS TTProductData_
		|		ON Operations.BillOfMaterials = TTProductData_.BillOfMaterials
		|			AND NOT Operations.DeletionMark
		|
		|		INNER JOIN Catalog.ManufacturingOperations AS TAOperations
		|		ON Operations.ContainsTechnologicalProcess
		|			AND Operations.TechnologicalProcess = TAOperations.Owner
		|			AND NOT TAOperations.DeletionMark
		|
		|";
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "TTOperations");

		QueryText = "
		|SELECT
		|	Operations.Id           AS Id,
		|
		|	Operations.Operation                AS Operation,
		|	PRESENTATION(Operations.Operation) AS OperationPresentation,
		|	Operations.OperationID_   AS OperationID_,
		|	Operations.OperationKind             AS OperationKind,
		|	Operations.UnitOfMeasure        AS UnitOfMeasure,
		|	Operations.Load                AS Load,
		|	Operations.Continuous             AS Continuous,
		|	Operations.Repeatable          AS Repeatable,
		|	Operations.Skippable         AS Skippable,
		|	Operations.Control                AS Control,
		|	Operations.TransferLot      AS TransferLot,
		|
		|	Operations.OriginalOperationNumber          AS OriginalOperationNumber,
		|	Operations.SourceNumberOfNextOperation AS SourceNumberOfNextOperation,
		|
		|	Operations.Count                     AS Count,
		|
		|	Operations.TechnologicalProcess              AS TechnologicalProcess,
		|	Operations.TechnologicalProcessFactor AS TechnologicalProcessFactor,
		|	Operations.TechnologicalProcessFactor AS CoefficientOfTechnologicalProcessPerUnitOfBatchOutput,
		|	Operations.ContainsTechnologicalProcess      AS ContainsTechnologicalProcess,
		|	Operations.ContainsNestedRoute            AS ContainsNestedRoute,
		|
		|	Operations.OperationParent              AS OperationParent,
		|	Operations.OperationParentID AS OperationParentID,
		|	Operations.Stage                          AS Stage,
		|	Operations.StageNumber                    AS StageNumber,
		|
		|	0                                   AS OperationID,
		|	0                                   AS OperationNumber,
		|	0                                   AS NextOperation,
		|	Operations.SetupSettings             AS SetupSettings,
		|	&EmptyLinkKey                    AS ConnectionKey,
		|	&EmptyLinkKey                    AS ParentCommunicationKey,
		|
		|	&TextDetailsOfTransactionExecutor,
		|	&TextDetailsForCalculatingOperationExecutionTime
		|
		|FROM
		|	TTOperations AS Operations
		|
		|ORDER BY
		|	Id,
		|	StageNumber,
		|	OperationParent <> VALUE(Catalog.ManufacturingOperations.EmptyRef),
		|	OriginalOperationNumber
		|";
		
		QueryText = StrReplace(
			QueryText,
			"&TextDetailsOfTransactionExecutor",
			Catalogs.ManufacturingOperations.QueryTextAttributesOfContractorOfOperation("Operations"));
		
		QueryText = StrReplace(
			QueryText,
			"&TextDetailsForCalculatingOperationExecutionTime",
			Catalogs.ManufacturingOperations.QueryTextAttributesForCalculatingTimeOfOperation("Operations"));
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "Operations");
		
	EndIf;
	
	#EndRegion
	
	#Region WorksToPerform
	
	If ListOfData.Find("WorksToPerform") <> Undefined
			Or SelectionParameters.CombineMaterialsAndWorksPerformed Then
		
		QueryText = "
		|SELECT
		|	&WorksPerformed_Presentations,
		|	MainOutputProduct.Id                      AS Id,
		|	CAST(WorksToPerform.LineNumber AS NUMBER(10,0))    AS LineNumber,
		|	
		|	WorksToPerform.Products                             AS Products,
		|	WorksToPerform.Characteristic                           AS Characteristic,
		|	WorksToPerform.Products.ItemsType             AS ItemsType,
		|	CASE
		|		WHEN WorksToPerform.Products.UseVariants IN (
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|					VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
		|					VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                      AS ItemVariantsAreUsed,
		|
		|	WorksToPerform.Count                               AS Count,
		|	WorksToPerform.Count                               AS NumberOfPackages,
		|	WorksToPerform.Count                               AS NumberOfPackagesPerUnitOfProductionBatch,
		|	WorksToPerform.Products.UnitOfMeasure            AS UnitOfMeasure,
		|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
		|	UNDEFINED                                               AS PackageData,
		|
		|	WorksToPerform.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS PieceUnitOfMeasure,
		|	FALSE                                                                                                                                AS PackagingPiece,
		|
		|	MainOutputProduct.Count                         AS ProductQuantity,
		|
		|	WorksToPerform.ProducedInProcess                    AS ProducedInProcess,
		|	WorksToPerform.BillOfMaterials                             AS BillOfMaterials,
		|	WorksToPerform.ProductCostElement                        AS ProductCostElement,
		|
		|	CASE
		|		WHEN WorksToPerform.ProducedInProcess OR WorksToPerform.Products.AssignedPurchaseSale THEN
		|			TRUE
		|		ELSE
		|			FALSE
		|	END AS WithAssignment,
		|	CASE 
		|		WHEN WorksToPerform.ProducedInProcess OR WorksToPerform.Products.AssignedPurchaseSale THEN
		|			VALUE(Enum.SupplyOptions.ToSupply)
		|		ELSE
		|			VALUE(Enum.SupplyOptions.NotRequired)
		|	END AS SupplyOption,
		|
		|	WorksToPerform.Stage                                     AS Stage,
		|
		|	WorksToPerform.Stage.StageNumber                          AS StageNumber,
		|	WorksToPerform.Stage.NextStageNo                AS NextStageNo,
		|	WorksToPerform.Stage.Department                       AS StageSubdivision,
		|
		|	- ISNULL(NormativeDurationOfStages.DaysBeforeEnd, 0) AS DaysFromNeedStandard,
		|	0                                                            AS DaysFromDemand,
		|
		|	ISNULL(CASE
		|			WHEN NormativeDurationOfStages.DurationInSeconds = 0 THEN
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + 0.0001
		|			ELSE 
		|				NormativeDurationOfStages.DurationBeforeProductionIssue + NormativeDurationOfStages.DurationInSeconds
		|		END, 0) AS DurationBeforeProductionIssue,
		|	
		|	0                                                          AS Probability,
		|	1                                                          AS ProbabilityCoefficient,
		|	
		|	WorksToPerform.UnderRepairProduct         AS UnderRepairProduct,
		|	WorksToPerform.UnderRepairVariant       AS UnderRepairVariant,
		|	
		|	VALUE(Enum.TypesOfSpecificationLines.Work_In_Progress) AS LineKind,
		|
		|	WorksToPerform.ConnectionKey                                AS ConnectionKey
		|	
		|FROM
		|	Catalog.BillsOfMaterials.WorksToPerform AS WorksToPerform
		|
		|		INNER JOIN TTWares AS MainOutputProduct
		|		ON WorksToPerform.Ref = MainOutputProduct.BillOfMaterials
		|			AND MainOutputProduct.ThisIsMainProduct
		|
		|		LEFT JOIN InformationRegister.StandardDurationOfProductionStages AS NormativeDurationOfStages
		|		ON WorksToPerform.Stage = NormativeDurationOfStages.Stage
		|";
		
		QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "WorksToPerform");
		
	EndIf;
	
	#EndRegion
	
	#Region PackageData_
	
	DescriptionOfTables = New Array;
	DescriptionOfTables.Add("TTWares");
	If ListOfData.Find("MaterialsAndServices") <> Undefined Then
		TableDetails = ProductDataManagement.DescriptionOfQueryTextTablePackageData();
		TableDetails.TableName = "Catalog.BillsOfMaterials.MaterialsAndServices";
		TableDetails.JoinText = "
			|		INNER JOIN TTProductData_ AS TTProductData_
			|		ON T.Ref = TTProductData_.BillOfMaterials";
		DescriptionOfTables.Add(TableDetails);
		TableDetails = ProductDataManagement.DescriptionOfQueryTextTablePackageData();
		TableDetails.TableName = "Catalog.TechnologicalProcesses.MaterialsAndServices";
		TableDetails.JoinText = "
			|		INNER JOIN TTTechnologicalProcesses AS TTTechnologicalProcesses
			|		ON T.Ref = TTTechnologicalProcesses.TechnologicalProcess";
		DescriptionOfTables.Add(TableDetails);
	EndIf;
		
	QueryText = ProductDataManagement.QueryTextPackageData_(DescriptionOfTables);
	
	QueryTexts.Add(QueryText + RequestSeparatorInPacket_, "PackageData_");
	
	#EndRegion

	For Each Item In QueryTexts Do
		AddPresentationsToRequest(Item.Value, SelectionParameters.GetPresentations);
		If SelectionParameters.MethodOfCalculationOfMaterials <> Enums.MaterialCalculationMethods.MinimumConsumption Then
			Item.Value = StrReplace(Item.Value,
				"NormativeDurationOfStages.DaysFromBeginning",
				"NormativeDurationOfStages.DaysFromBeginningMax");
			Item.Value = StrReplace(Item.Value,
				"NormativeDurationOfStages.DaysBeforeEnd",
				"NormativeDurationOfStages.DaysBeforeEndMax");
		EndIf;
	EndDo;
	
	Query.SetParameter("ConsiderProbabilityOfDefectiveGoods",  SelectionParameters.ConsiderProbabilityOfDefectiveGoods);
	Query.SetParameter("MethodOfCalculationOfMaterials", SelectionParameters.MethodOfCalculationOfMaterials);
	Query.SetParameter("RoundUpNumberOfUnitItems_", SelectionParameters.RoundUpNumberOfUnitItems_);
	
	Query.SetParameter("DefaultWarehouse", Catalogs.Warehouses.DefaultWarehouse());
	
	UseParameterization = GetFunctionalOption("UseBillOfMaterialsParameterization");
	DisableCalculationOfParametricFormulas = False;
	If SelectionParameters.Property("DisableCalculationOfParametricFormulas", DisableCalculationOfParametricFormulas)
			And DisableCalculationOfParametricFormulas Then
		UseParameterization = False;
	EndIf;
	Query.SetParameter("UseParameterization", UseParameterization);
	Query.SetParameter("UseTechnologicalProcesses", GetFunctionalOption("UseTechnologicalProcesses"));
	If SelectionParameters.Property("OverridingReleasePartySetting")
		And SelectionParameters.OverridingReleasePartySetting.Use Then
		Query.SetParameter("OverrideReleasePartySetting", True);
		Query.SetParameter("ProductionIssueByCustomPortions", SelectionParameters.OverridingReleasePartySetting.ProductionIssueByCustomPortions);
	Else
		Query.SetParameter("OverrideReleasePartySetting", False);
		Query.SetParameter("ProductionIssueByCustomPortions", False);
	EndIf;
	
	Query.SetParameter("ReleaseBatchDescriptionIsAvailable", ProductDataManagement.ReleaseBatchDescriptionIsAvailable());
	Query.SetParameter("PriceKind", ProductionServerCached.TypeOfPricePlannedCost_());
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Currency", ProductionServerCached.PlannedPriceCurrencyOfProductsMaterialsAndLabor());
	Query.SetParameter("BaseCurrency", SettingsValueCached.DefaultBaseCurrency());
	Query.SetParameter("CommunicationKeyProducts", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Products"));
	Query.SetParameter("CommunicationKeyCharacteristic", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Characteristic"));
	SetPrivilegedMode(True);
	Tables = TMCommonUse.UploadResultsOfQuery(Query, QueryTexts, , False, True);
	SetPrivilegedMode(False);
	
	Result = New Map;
	
	For Each DataSetName In StrSplit("MainProduct,SpecificationDetails", ",") Do
		Table = Tables[DataSetName]; // ValueTable
		Table.Indexes.Add("Id");
	EndDo;
	For Each DataSetName In ListOfData Do
		Table = Tables[DataSetName]; // ValueTable
		Table.Indexes.Add("Id");
	EndDo;
	ProcessAutoSelectionSettings(Tables, TempTablesManager, SelectionParameters);
	FillInMaterialSupportParameters(Query, Tables, SelectionParameters);
	
	FillInParametersForProvidingOutputProducts(Query, Tables, SelectionParameters);
	FillInParametersOfWorkBeingPerformed(Query, Tables, SelectionParameters);
	
	#Region DataForCalculationByFormulas
	
	DescriptionOfOperandDataSources = Undefined;
	SourcesOfParameterValues       = Undefined;
	
	#EndRegion
	ProductDataManagement.FillInPackingDataInDataset(
		Tables.MainProduct,
		Tables.PackageData_);
	
	MainProductSpecifications  = New Structure("Products,Package,NumberOfPackagesPerUnitOfProductionBatch,PackageData");
	SelectionStructureIdentifier = New Structure("Id");
	DefaultPackagingStructure = ProductDataManagementCached.PackingDataStructure();
	
	TableDataOnProducts = Tables.ItemData_3; // See ItemList
	For Each String In TableDataOnProducts Do
		
		Id = String.Id;
		SelectionStructureIdentifier.Id = Id;
		
		StructureOfData = DataSpecificationConstructor();
		
		HeaderData_ = Tables.SpecificationDetails.Find(Id, "Id");
		If HeaderData_ <> Undefined Then
			FillPropertyValues(StructureOfData, HeaderData_);
		EndIf;
		
		DataSetRow = Tables.MainProduct.Find(Id, "Id");
		If DataSetRow <> Undefined Then
			FillPropertyValues(StructureOfData.MainProduct, DataSetRow);
			If Not StructureOfData.MainProduct.ThisIsMainProduct Then
				MainProductSpecifications.Products   = DataSetRow.MainProductProducts;
				MainProductSpecifications.Package       = DataSetRow.MainProductPackage;
				MainProductSpecifications.PackageData = DefaultPackagingStructure;
				MainProductSpecifications.NumberOfPackagesPerUnitOfProductionBatch =
											DataSetRow.MainProductNumberOfPackagesPerUnitOfProductionBatch;
				If ValueIsFilled(MainProductSpecifications.Package) Then
					ProductDataManagement.FillInPackingDataInDataSetRow(
						MainProductSpecifications, Tables.PackageData_);
				EndIf;
				ProductDataManagement.FillInConversionFactorToMainProduct(
					StructureOfData.MainProduct, MainProductSpecifications);
			EndIf;
		EndIf;
		
		For Each DataSetName In ListOfData Do
			
			DataSet = Tables[DataSetName].Copy(SelectionStructureIdentifier);
			
			If DataSetName = "MaterialsAndServices" Then
				ApplySelectionBasedOnDataSelectionParameters(
					DataSet,
					SelectionParameters);
				FillInInformationOnUseOfMaterial(
					DataSet,
					SelectionParameters);
				IncludeDataSetsInSpecificationDataStructure(
					StructureOfData,
					Tables,
					SelectionParameters,
					SelectionStructureIdentifier);
			ElsIf DataSetName = "IncomingProducts" Then
				ProductDataManagement.FillInPackingDataInDataset(
					DataSet,
					Tables.PackageData_);
			ElsIf DataSetName = "ManufacturedProducts" Then
				ProductDataManagement.FillInPackingDataInDataset(
					DataSet,
					Tables.PackageData_);
			ElsIf DataSetName = "RecyclableWaste" Then
				ProductDataManagement.FillInPackingDataInDataset(
					DataSet,
					Tables.PackageData_);
			ElsIf DataSetName = "Operations" Then
				PrepareTableOfOperations(DataSet);
			EndIf;
			
			StructureOfData.Insert(DataSetName, DataSet);
			
		EndDo;
		ProcessProcessData(StructureOfData);
		
		PrepareParametersForCalculationUsingFormulas(
			String,
			StructureOfData,
			Tables,
			DescriptionOfOperandDataSources,
			ListOfData,
			SourcesOfParameterValues);
		Result.Insert(Id, StructureOfData);
		
	EndDo;
	ProductDataManagement.FillInParameterValuesForCalculationByFormulas(SourcesOfParameterValues);
	If ListOfTablesToDelete.Count() > 0 Then
		TMCommonUse.DestroyTemporaryTables(TempTablesManager, StrConcat(ListOfTablesToDelete,","));
	EndIf;
	If SelectionParameters.CombineMaterialsAndIncomingProducts Then
		CombineMaterialsAndIncomingProducts(Result, Tables);
	EndIf;
	If SelectionParameters.CombineMaterialsAndWorksPerformed Then
		CombineMaterialsAndWorksPerformed(Result, Tables);
	EndIf;
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, MeasurementWeight);
	
	Return Result;
	
EndFunction

#EndRegion

#Region ListOfData

Function ListOfSpecificationData() Export
	
	ListOfData = New Array;
	ListOfData.Add("Stages");
	ListOfData.Add("ManufacturedProducts");
	ListOfData.Add("RecyclableWaste");
	ListOfData.Add("IncomingProducts"); //(repair,disassembly)
	ListOfData.Add("WorksToPerform");
	ListOfData.Add("MaterialsAndServices");
	ListOfData.Add("LaborCosts");
	ListOfData.Add("WorkCenterTypes");
	ListOfData.Add("AlternateWorkCenterTypes");
	Return ListOfData;
	
EndFunction

#EndRegion

#Region CalculationOfQuantity

Function CalculateBatchOfOutputByProduct(ItemData_3, SpecificationData, SelectionParameters) Export
	
	Count = ItemData_3.Count;
	
	If SelectionParameters.RoundUpNumberOfUnitItems_
		And Int(Count) <> Count
		And SpecificationData.MainProduct.PieceUnitOfMeasure
		And Not ValueIsFilled(SpecificationData.MainProduct.Package)
		And SpecificationData.ProductionIssueByCustomPortions
		And Int(SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch)
			= SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
		And SpecificationData.ProductionProcessType = Enums.ProductionProcessTypes.Assembly
		And SpecificationData.Property("ManufacturedProducts")
		And SpecificationData.ManufacturedProducts.Count() = 1 Then
		Count = Int(Count) + 1;
	EndIf;
	
	ArrayOfBatches = BreakIntoOptimalReleaseBatches(Count, SpecificationData);
	
	// Summation of fractions
	Numerator = 0;
	Denominator = ProductionServer.SmallestCommonMultipleInCollection(ArrayOfBatches, "Denominator");
	DefectiveGoods = Undefined;
	For Each Lot In ArrayOfBatches Do
		
		Numerator = Numerator + Lot.Numerator * Denominator / Lot.Denominator;
		
		If Lot.DefectiveGoods <> Undefined Then
			If DefectiveGoods = Undefined Then
				DefectiveGoods = New Map;
			EndIf;
			For Each KeyAndValue In Lot.DefectiveGoods Do
				If DefectiveGoods[KeyAndValue.Key] = Undefined Then
					DefectiveGoods.Insert(KeyAndValue.Key, KeyAndValue.Value);
				Else
					DefectiveGoods[KeyAndValue.Key] = DefectiveGoods[KeyAndValue.Key] + KeyAndValue.Value;
				EndIf;
			EndDo;
		EndIf;
		
	EndDo;
	
	// Fraction reduction
	GreatestCommonDivisor = ProductionServer.GreatestCommonDivisor(Numerator, Denominator);
	Numerator   = Numerator / GreatestCommonDivisor;
	Denominator = Denominator / GreatestCommonDivisor;
		
	Result = ReleaseParty(Numerator, Denominator, DefectiveGoods, ArrayOfBatches);
	
	Return Result;
	
EndFunction

Function BreakIntoOptimalReleaseBatches(Val Count, SpecificationData) Export
	
	Result  = New Array;
	
	ThereIsReleaseInArbitraryPortions = SpecificationData.ProductionIssueByCustomPortions;
	ThereAreSettingsForSplittingIntoBatches   = SpecificationData.EconomicReleaseLot <> 0;
	ThereIsDefectiveGoods = SpecificationData.MainProduct.DefectiveGoodsRate <> 0;
	
	PackageData = SpecificationData.MainProduct.PackageData;
	
	If (ThereIsReleaseInArbitraryPortions And ThereAreSettingsForSplittingIntoBatches)
			Or ThereIsDefectiveGoods Then
		QuantityBatch = SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
			* PackageData.Numerator / PackageData.Denominator;
		PackageData   = ProductDataManagementCached.PackingDataStructure();
	Else
		QuantityBatch = SpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch;
	EndIf;
	
	If QuantityBatch = 0 Then
		Return CommonClientServer.ValueInArray(ReleaseParty(0, 1));
	EndIf;
	
	Balance = CheckRoundUpToWholeBatches(
					Count * PackageData.Denominator / PackageData.Numerator,
					QuantityBatch,
					SpecificationData);
					
	If ThereIsReleaseInArbitraryPortions Then
		ConversionFactorOfLaunchBatch = SpecificationData.MainProduct.ConversionFactorToMainProduct;
	Else
		ConversionFactorOfLaunchBatch = QuantityBatch;
	EndIf;
	
	MinimumOutput = Round(SpecificationData.MinimumReleaseLot * ConversionFactorOfLaunchBatch, 3);
	
	If Not ThereIsDefectiveGoods
		And Not ThereAreSettingsForSplittingIntoBatches Then
			
		Result.Add(ReleaseParty(
					Max(Balance, MinimumOutput),
					QuantityBatch));
	Else
		
		OptimalRelease    = Round(SpecificationData.EconomicReleaseLot * ConversionFactorOfLaunchBatch, 3);
		AllowableExcessOf = Round(SpecificationData.PermissibleExcessOfOptimalReleaseLot * ConversionFactorOfLaunchBatch, 3);
		
		If OptimalRelease <> 0 And MinimumOutput > OptimalRelease Then
			MinimumOutput = OptimalRelease;
		EndIf;
		DeltaMinimumOptimum = OptimalRelease - MinimumOutput;
		Product              = SpecificationData.MainProduct;
		
		If OptimalRelease > 0 Then
			
			DefectiveGoodsSum = 0;
			If Product.DefectiveGoodsRate = 0 Then
				RemainderDefectiveGoods = 0;
			Else
				RemainderDefectiveGoods = CheckRoundUpToWholeBatches(
					Round(Balance / (1-Product.DefectiveGoodsRate), ?(Product.PieceUnitOfMeasure, 0, 3)),
					QuantityBatch,
					SpecificationData);
			EndIf;
			
			While Balance >= OptimalRelease Or RemainderDefectiveGoods >= OptimalRelease Do
				
				Result.Add(OptimalRelease);
				
				If Product.DefectiveGoodsRate = 0 Then
					Balance = Balance - OptimalRelease;
				Else
					DefectiveGoodsSum = DefectiveGoodsSum + (OptimalRelease * Product.DefectiveGoodsRate);
					DefectiveGoodsCredit = Round(DefectiveGoodsSum, ?(Product.PieceUnitOfMeasure, 0, 3));
					If DefectiveGoodsCredit > 0 Then
						Balance   = Balance - (OptimalRelease - DefectiveGoodsCredit);
						DefectiveGoodsSum = DefectiveGoodsSum - DefectiveGoodsCredit;
					Else
						Balance = Balance - OptimalRelease;
					EndIf;
					RemainderDefectiveGoods = CheckRoundUpToWholeBatches(
						Round((Balance / (1-Product.DefectiveGoodsRate)) + DefectiveGoodsSum, ?(Product.PieceUnitOfMeasure, 0, 3)),
						QuantityBatch,
						SpecificationData);
				EndIf;
				
			EndDo;
			
			If RemainderDefectiveGoods > 0 And RemainderDefectiveGoods > Balance Then
				Balance = RemainderDefectiveGoods; // balance adjusted for marriage
			EndIf;
			
			If Balance > 0 Then
				
				// if we can cover the balance due to the allowable excess
				If Balance <= Result.Count() * AllowableExcessOf Then
					
					If SpecificationData.ProductionIssueByCustomPortions Then
						
						For X = -Result.UBound() To 0 Do
							If Balance <= 0 Then
								Break;
							EndIf;
							Result[-X] = Result[-X] + Min(AllowableExcessOf, Balance);
							Balance = Balance - Min(AllowableExcessOf, Balance);
						EndDo;
						
					Else
						
						BalancePerBatch = Int(Balance / Result.Count());
						If BalancePerBatch > 0 Then
							For X = 0 To Result.UBound() Do
								Result[X] = Result[X] + BalancePerBatch;
							EndDo;
						EndIf;
						
						Balance = Balance % Result.Count();
						
						For X = -Result.UBound() To 0 Do
							If Balance <= 0 Then
								Break;
							EndIf;
							Result[-X] = Result[-X] + Min(1, Balance);
							Balance = Balance - 1;
						EndDo;
						
					EndIf;
					
				// if we can cover the remainder by reducing the optimal batches to the minimum
				Else
					
					For X = -Result.UBound() To 0 Do
						If Balance >= MinimumOutput Then
							Break;
						EndIf;
						Result[-X] = Result[-X] - Min(DeltaMinimumOptimum, MinimumOutput - Balance);
						Balance = Balance + Min(DeltaMinimumOptimum, MinimumOutput - Balance);
					EndDo;
					Result.Add(Max(Balance, MinimumOutput));
					
				EndIf;
				
			EndIf;
			
		Else
			If Product.DefectiveGoodsRate <> 0 Then
				Balance = CheckRoundUpToWholeBatches(
							Round(Count / (1-Product.DefectiveGoodsRate), ?(Product.PieceUnitOfMeasure, 0, 3)),
							QuantityBatch,
							SpecificationData);
			EndIf;
			Result.Add(Max(Balance, MinimumOutput));
		EndIf;
		
		DefectiveGoodsLines = Undefined;
		If SpecificationData.Property("ManufacturedProducts") Then
			For IndexOf = 0 To SpecificationData.ManufacturedProducts.Count()-1 Do
				If SpecificationData.ManufacturedProducts[IndexOf].DefectiveGoodsRate <> 0 Then
					If DefectiveGoodsLines = Undefined Then
						DefectiveGoodsLines = New Map;
					EndIf;
					DefectiveGoodsLines.Insert(IndexOf, 0);
				EndIf;
			EndDo;
		EndIf;
		
		For X = 0 To Result.UBound() Do
			
			If DefectiveGoodsLines = Undefined Then
				DefectiveGoods = Undefined;
			Else
				
				DefectiveGoods = New Map;
				For Each KeyAndValue In DefectiveGoodsLines Do
					
					Product = SpecificationData.ManufacturedProducts[KeyAndValue.Key];
					
					DefectiveGoodsLines[KeyAndValue.Key] = DefectiveGoodsLines[KeyAndValue.Key]
						+ (Product.NumberOfPackagesPerUnitOfProductionBatch * Product.PackageData.Numerator
							* Result[X] / (QuantityBatch * Product.PackageData.Denominator) // Lot
							* Product.DefectiveGoodsRate);
					
					DefectiveGoodsCount = Round(DefectiveGoodsLines[KeyAndValue.Key], ?(Product.PieceUnitOfMeasure, 0, 3));
					
					If DefectiveGoodsCount > 0 Then
						DefectiveGoods.Insert(KeyAndValue.Key, DefectiveGoodsCount);
						DefectiveGoodsLines[KeyAndValue.Key] = DefectiveGoodsLines[KeyAndValue.Key] - DefectiveGoodsCount;
					EndIf;
					
				EndDo;
			EndIf;
			
			Result[X] = ReleaseParty(Result[X], QuantityBatch, DefectiveGoods);
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Procedure CalculateQuantityPerBatchRelease(ReleaseParty, SpecificationData, ItemData_3) Export
	
	ListOfData = ListOfSpecificationData();
	
	ProcessDataSets(ReleaseParty, SpecificationData, "BeforeCalculationProcess");
	
	DataForCalculation = Undefined;
	DataForCalculation = DataForCalculationByFormulas(ReleaseParty, SpecificationData, ItemData_3);
	If SpecificationData.Property("MainProduct") Then
		CalculateNumberInRow(ReleaseParty, SpecificationData.MainProduct, True, False, False);
		If ReleaseParty.DefectiveGoods <> Undefined Then
			For Each KeyAndValue In ReleaseParty.DefectiveGoods Do
				String = SpecificationData.ManufacturedProducts[KeyAndValue.Key];
				If SpecificationData.MainProduct.Products <> String.Products
					Or SpecificationData.MainProduct.Characteristic <> String.Characteristic Then
					Continue;
				EndIf;
				
				SpecificationData.MainProduct.Count = SpecificationData.MainProduct.Count - KeyAndValue.Value;
				If SpecificationData.MainProduct.PackageData.Numerator <> 0 Then
					SpecificationData.MainProduct.NumberOfPackages = SpecificationData.MainProduct.Count
						* SpecificationData.MainProduct.PackageData.Denominator
						/ SpecificationData.MainProduct.PackageData.Numerator;
				Else
					SpecificationData.MainProduct.Count = 0;
					SpecificationData.MainProduct.NumberOfPackages = 0;
				EndIf;
				Break;
			EndDo;
		EndIf;
	EndIf;
	If SpecificationData.Property("ManufacturedProducts")
		And ListOfData.Find("ManufacturedProducts") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.ManufacturedProducts,
			True, False, True, True, True, DataForCalculation);
		If ReleaseParty.DefectiveGoods <> Undefined Then
			For Each KeyAndValue In ReleaseParty.DefectiveGoods Do
				String = SpecificationData.ManufacturedProducts[KeyAndValue.Key];
				String.Count = String.Count - KeyAndValue.Value;
				If String.PackageData.Numerator <> 0 Then
					String.NumberOfPackages = String.Count * String.PackageData.Denominator / String.PackageData.Numerator;
				Else
					String.Count = 0;
					String.NumberOfPackages = 0;
				EndIf;
			EndDo;
		EndIf;
		CalculateDaysFromNeed(ItemData_3, SpecificationData.ManufacturedProducts);
		ProductionClientServer.CalculateFractionOfValueInCollection(SpecificationData.ManufacturedProducts, SpecificationData.MethodOfAllocatingFinishedProductCosts);
	EndIf;
	If SpecificationData.Property("MaterialsAndServices")
		And ListOfData.Find("MaterialsAndServices") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.MaterialsAndServices,
			True, True, True, False, True, DataForCalculation);
		CalculateDaysFromNeed(ItemData_3, SpecificationData.MaterialsAndServices);
	EndIf;
	If SpecificationData.Property("RecyclableWaste")
		And ListOfData.Find("RecyclableWaste") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.RecyclableWaste,
			True, False, True, True, True, DataForCalculation);
		CalculateDaysFromNeed(ItemData_3, SpecificationData.RecyclableWaste);
	EndIf;
	If SpecificationData.Property("IncomingProducts")
		And ListOfData.Find("IncomingProducts") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.IncomingProducts,
			True, False, True, False, False);
		CalculateDaysFromNeed(ItemData_3, SpecificationData.IncomingProducts);
	EndIf;
	If SpecificationData.Property("LaborCosts")
		And ListOfData.Find("LaborCosts") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.LaborCosts,
			False, False, False, False, True, DataForCalculation);
		CalculateDaysFromNeed(ItemData_3, SpecificationData.LaborCosts);
	EndIf;
	If SpecificationData.Property("WorkCenterTypes")
		And ListOfData.Find("WorkCenterTypes") <> Undefined Then
		CalculateRunningTime(ReleaseParty, SpecificationData, SpecificationData.WorkCenterTypes, DataForCalculation);
		CalculateDownload(ReleaseParty, SpecificationData, SpecificationData.WorkCenterTypes);
		CalculateEmployment(ReleaseParty, SpecificationData.WorkCenterTypes, DataForCalculation);
		CalculateDaysFromNeed(ItemData_3, SpecificationData.WorkCenterTypes);
	EndIf;
	If SpecificationData.Property("AlternateWorkCenterTypes")
		And ListOfData.Find("AlternateWorkCenterTypes") <> Undefined Then
		CalculateRunningTime(ReleaseParty, SpecificationData, SpecificationData.AlternateWorkCenterTypes, DataForCalculation);
		CalculateDownload(ReleaseParty, SpecificationData, SpecificationData.AlternateWorkCenterTypes);
	EndIf;
	If SpecificationData.Property("Operations") Then
		CalculateNumberOfTimeOperations(ReleaseParty, SpecificationData.Operations);
		CalculateProcessCoefficient(ReleaseParty, SpecificationData.Operations);
	EndIf;
	If SpecificationData.Property("Stages")
		And ListOfData.Find("Stages") <> Undefined Then
		CalculateCount(ReleaseParty, SpecificationData.Stages,
			False, False, False, False, False);
		RecalculateDuration(SpecificationData, ListOfData);
		CalculateOperationsSheetFactor(ReleaseParty, SpecificationData.Stages);
		For Each Data_Stage In SpecificationData.Stages Do
			If Data_Stage.ProductionByThirdParty Then
				CalculateCount(ReleaseParty, Data_Stage.SubcontractorServices,
					False, False, False, False, False);
			EndIf;
		EndDo;
	EndIf;
	
	ProcessDataSets(ReleaseParty, SpecificationData, "AfterCalculation");
	
EndProcedure

Procedure CalculateCount(ReleaseParty, Collection, ThereArePackages, ThereIsPossibility, RoundOff, ControlRoundingUp, CalculateFormulas, DataForCalculation = Undefined)
	
	For Each String In Collection Do
		
		CalculateNumberInRow(ReleaseParty, String, ThereArePackages, ThereIsPossibility, CalculateFormulas, DataForCalculation);
		
		If RoundOff Then
			RoundUpNumberInRow(ReleaseParty, String, ThereArePackages, ControlRoundingUp);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CalculateNumberInRow(ReleaseParty, String, ThereArePackages, ThereIsPossibility, CalculateFormulas, DataForCalculation = Undefined)
	
	// Calculation of quantity per batch
	If CalculateFormulas And Not IsBlankString(String.QuantityCalculationAlgorithm) Then
		ProductDataManagement.CalculateQuantityUsingFormula(String, DataForCalculation, "Count");
	Else
		If ThereArePackages Then
			If String.PackageData.Denominator <> 0 Then
				String.Count = String.NumberOfPackagesPerUnitOfProductionBatch 
					* String.PackageData.Numerator * ReleaseParty.Numerator 
					/ (String.PackageData.Denominator * ReleaseParty.Denominator);
			Else
				String.Count = 0;
			EndIf;
		Else
			String.Count = String.QuantityPerReleaseLotUnit * ReleaseParty.Numerator / ReleaseParty.Denominator;
		EndIf;
	EndIf;
	// Correction for probability
	If ThereIsPossibility And String.ProbabilityCoefficient <> 1 Then
		String.Count = String.Count * String.ProbabilityCoefficient;
	EndIf;
	
	// Recalculating the number of packages
	If ThereArePackages Then
		If String.PackageData.Numerator <> 0 Then
			String.NumberOfPackages = String.Count * String.PackageData.Denominator / String.PackageData.Numerator;
			String.Count         = DescriptionOfTypeOfQuantitativeProps().AdjustValue(String.Count);
		Else
			String.NumberOfPackages = 0;
			String.Count         = 0;
		EndIf;
	EndIf;
	
EndProcedure

Procedure RoundUpNumberInRow(ReleaseParty, String, ThereArePackages, ControlRoundingUp)
	
	If Not String.RoundOff 
		Or String.Count = Int(String.Count) Then
		Return;
	EndIf;
	
	Count = Round(String.Count);
	
	AllowableVariance = TMCommonUseCached.AllowableDeviationOfAutomaticRounding();
	
	Deviation = ?(Count > String.Count,
		(Count - String.Count)/String.Count * 100,
		(String.Count - Count)/String.Count * 100);
			
	If String.ThisIsWorkshopPantry Then
		
		If Deviation <= AllowableVariance Then
			
			String.Count = Count;
			
			If ThereArePackages Then
				If String.PackageData.Numerator <> 0 Then
					String.NumberOfPackages = String.Count * String.PackageData.Denominator / String.PackageData.Numerator;
				Else
					String.Count         = 0;
					String.NumberOfPackages = 0;
				EndIf;
			EndIf;
			
		EndIf;
		
	Else
		
		If Deviation > AllowableVariance Then
			
			If ControlRoundingUp
				And Count > String.Count Then
				
				Count = Count - 1;
				
			ElsIf Not ControlRoundingUp
				And Count < String.Count Then
				
				Count = Count + 1;
				
			EndIf;
			
		EndIf;
		
		String.Count = Count;
		
		If ThereArePackages Then
			If String.PackageData.Numerator <> 0 Then
				String.NumberOfPackages = String.Count * String.PackageData.Denominator / String.PackageData.Numerator;
			Else
				String.Count         = 0;
				String.NumberOfPackages = 0;
			EndIf;
		EndIf;
		
	EndIf;
	
EndProcedure

Function CheckRoundUpToWholeBatches(Count, QuantityBatch, SpecificationData)
	
	If SpecificationData.ProductionIssueByCustomPortions Then
		
		Return Count;
		
	Else
		
		ZoomRatio = Count / QuantityBatch;
		
		If Int(ZoomRatio) = ZoomRatio Then
			Return Count;
		Else
			Return QuantityBatch * (Int(ZoomRatio) + 1);
		EndIf;
		
	EndIf;
	
EndFunction

Function DescriptionOfTypeOfQuantitativeProps()
	
	Return New TypeDescription("Number", New NumberQualifiers(15,3,AllowedSign.Nonnegative));
	
EndFunction

Procedure CalculateRunningTime(ReleaseParty, SpecificationData, Collection, DataForCalculation = Undefined)
	
	For Each String In Collection Do
		
		If IsBlankString(String.QuantityCalculationAlgorithm) Then
			If String.ParallelLoad
				And String.MaximumLoad <> 0 Then
				
				Load = String.LoadingPerUnitOfLotReference * ReleaseParty.Numerator / ReleaseParty.Denominator;
				ZoomRatio = Int(Load / String.MaximumLoad)
					+ ?(Load % String.MaximumLoad > 0, 1, 0);
				String.OperationTime = String.OperatingTimePerBatchUnit * ZoomRatio;
				
			ElsIf String.QuantityOfProductUnitsLotsProducedSimultaneously > 0 Then
				
				SimultaneouslyProduced = String.QuantityOfProductUnitsLotsProducedSimultaneously;
				MainProduct = SpecificationData.MainProduct;
				
				If SpecificationData.ProductionIssueByCustomPortions Then
					
					ZoomRatio = Int(MainProduct.Count / SimultaneouslyProduced)
						+ ?(MainProduct.Count % SimultaneouslyProduced > 0, 1, 0);
						
				Else
					
					ZoomRatio = Int(ReleaseParty.Numerator / (ReleaseParty.Denominator * SimultaneouslyProduced))
						+ ?((ReleaseParty.Numerator / ReleaseParty.Denominator) % SimultaneouslyProduced > 0, 1, 0);
						
				EndIf;
				
				String.OperationTime = String.OperatingTimePerBatchUnit * ZoomRatio;
				
			Else
				
				String.OperationTime = String.OperatingTimePerBatchUnit
					* ReleaseParty.Numerator / ReleaseParty.Denominator;
				
			EndIf;
		Else
			ProductDataManagement.CalculateQuantityUsingFormula(String, DataForCalculation, "OperationTime");
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CalculateDownload(ReleaseParty, SpecificationData, Collection)
	
	For Each String In Collection Do
		String.Load = String.LoadingPerUnitOfLotReference
			* ReleaseParty.Numerator / ReleaseParty.Denominator;
	EndDo;
	
EndProcedure

Procedure CalculateEmployment(ReleaseParty, SourceTable, DataForCalculation = Undefined)

	For Each String In SourceTable Do
		
		If Not String.CalculateEmployment Then
			Continue;
		EndIf;
			
		If IsBlankString(String.QuantityCalculationAlgorithm) Then
			
			String.Occupation = ProductionPlanningClientServer.GetTimeInSeconds(
				String.OperationTime,
				String.UnitOfMeasure);
			String.EmploymentPerUnitOfIssueBatch = ProductionPlanningClientServer.GetTimeInSeconds(
				String.OperatingTimePerBatchUnit,
				String.UnitOfMeasure);
			
		Else
			
			ProductDataManagement.CalculateQuantityUsingFormula(String, DataForCalculation, "Occupation");
			String.Occupation = ProductionPlanningClientServer.GetTimeInSeconds(
				String.Occupation, 
				String.UnitOfMeasure);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure RecalculateDuration(SpecificationData, ListOfData)
	
	Settings = ProductionServerCached.SubsystemSettingsProduction();
	If
		(
			SpecificationData.Property("WorkCenterTypes")
			And ListOfData.Find("WorkCenterTypes") <> Undefined
		)
		And (
			Settings.PlanningByProductionResourcesIsUsed
				Or (Settings.ProductionIsUsed21
					And Not Settings.PlanningByMaterialResourcesIsUsed)
		) Then
		
		TheStructureOfTheSearch = New Structure;
		TheStructureOfTheSearch.Insert("PlanOperationsOfWorkCenterTypes", True);
		TheStructureOfTheSearch.Insert("ContainsResourcesParametrization", True);
		For Each String In SpecificationData.Stages.FindRows(TheStructureOfTheSearch) Do
			
			ProductDataManagement.FillInUnitOfMeasurementAndDurationOfBBVStage(
				String,
				SpecificationData.WorkCenterTypes.FindRows(New Structure("Stage", String.Stage)),
				True);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure CalculateOperationsSheetFactor(ReleaseParty, Stages)
	
	For Each String In Stages Do
		String.RouteSheetFactor = String.RouteMapCoefficientPerUnitOfIssueBatch
			* ReleaseParty.Numerator / ReleaseParty.Denominator; 
	EndDo;
	
EndProcedure

Procedure CalculateNumberOfTimeOperations(ReleaseParty, Operations)
	
	For Each LineOperation In Operations Do
		
		LineOperation.QuantityPerBatch = LineOperation.Count
			* LineOperation.TechnologicalProcessFactor
			* ReleaseParty.Numerator / ReleaseParty.Denominator;
		
		ProductionAccountingClientServer.CalculateTotalOperationTime(
			LineOperation,
			LineOperation.TechnologicalProcessFactor
				* ReleaseParty.Numerator / ReleaseParty.Denominator);
		
	EndDo;
	
EndProcedure

Procedure CalculateProcessCoefficient(ReleaseParty, Operations)
	
	For Each LineOperation In Operations Do
		LineOperation.TechnologicalProcessFactor = LineOperation.CoefficientOfTechnologicalProcessPerUnitOfBatchOutput
			* ReleaseParty.Numerator / ReleaseParty.Denominator;
	EndDo;
	
EndProcedure

Procedure CalculateDaysFromNeed(ItemData_3, SourceTable)
	
	If ItemData_3 <> Undefined
		And ItemData_3.Property("DaysFromDemand")
		And ItemData_3.DaysFromDemand <> Undefined Then
		
		For Each TableRow In SourceTable Do
			TableRow.DaysFromDemand = TableRow.DaysFromNeedStandard + ItemData_3.DaysFromDemand;
		EndDo;
		
	Else
		
		For Each TableRow In SourceTable Do
			TableRow.DaysFromDemand = TableRow.DaysFromNeedStandard;
		EndDo;
		
	EndIf;
	
EndProcedure

Function ReleaseParty(Numerator, Denominator, DefectiveGoods = Undefined, Details = Undefined) Export
	
	Result = New Structure;
	
	Result.Insert("Numerator",      Numerator);
	Result.Insert("Denominator",    Denominator);
	
	Result.Insert("Value",       Numerator / Denominator);
	
	// Either the correspondence is uncertain, where the Key is the PM index of the output product, the value is the number of defective products
	Result.Insert("DefectiveGoods",           DefectiveGoods);
	
	// Undefined or An array detailing a given batch to optimal batches (array elements are also release batches)
	Result.Insert("Details",    Details);
	
	Return Result;
	
EndFunction

Function CompareReleaseBatches(Lot1, Lot2) Export
	
	If Lot1.Value > Lot2.Value Then
		Return 1;
	ElsIf Lot1.Value < Lot2.Value Then
		Return -1;
	Else
		Return 0;
	EndIf;
	
EndFunction

#EndRegion

#Region CalculationByFormulas

#Region DataForCalculation

Function DataForCalculationByFormulas(ReleaseParty, SpecificationData, ItemData_3)
	
	DataForCalculation = Undefined;
	
#Region ParametersForCalculation

	ParametersForCalculation = Undefined;
	If SpecificationData.Property("ParametersForCalculationByFormulas") Then
		ParametersForCalculation = SpecificationData.ParametersForCalculationByFormulas.Copy();
	EndIf;
	
	If Not ValueIsFilled(ParametersForCalculation) Then
		Return DataForCalculation;
	EndIf;
	
#EndRegion

	StructureOfData = New Structure("MainProduct,ManufacturedProducts,RecyclableWaste,MaterialsAndServices");
	FillPropertyValues(StructureOfData, SpecificationData);
	
	NomenclatureDataCopy = ProductData_5();
	FillPropertyValues(NomenclatureDataCopy, ItemData_3);

#Region DataSources
	DataSources = StructureOfSourcesForCalculationByFormulas();
	
	// these orders for the nomenclature
	DataSources.ItemData_3 = NomenclatureDataCopy;
	
	// Main product specifications
	MainProduct = Common.CopyRecursive(StructureOfData.MainProduct);
	CalculateNumberInRow(ReleaseParty, MainProduct, True, False, False);
	DataSources.MainProduct = MainProduct;
	
	// tabular part of output products
	If StructureOfData.ManufacturedProducts <> Undefined Then
		
		For Each String In StructureOfData.ManufacturedProducts Do
			
			CalculateNumberInRow(ReleaseParty, String, True, False, False);
			FillPropertyValues(DataSources.ManufacturedProducts.Add(), String);
			
		EndDo;
		
	EndIf;

	// tabular part of the materials and services
	If StructureOfData.MaterialsAndServices <> Undefined Then
		
		For Each String In StructureOfData.MaterialsAndServices Do
			
			CalculateNumberInRow(ReleaseParty, String, True, False, False);
			FillPropertyValues(DataSources.MaterialsAndServices.Add(), String);
			
		EndDo;
		
	EndIf;
	
	// tabular part of the ReturnrefeRences
	If StructureOfData.RecyclableWaste <> Undefined Then
		
		For Each String In StructureOfData.RecyclableWaste Do
			
			CalculateNumberInRow(ReleaseParty, String, True, False, False);
			FillPropertyValues(DataSources.RecyclableWaste.Add(), String);
			
		EndDo;
		
	EndIf;
	
#EndRegion

	DescriptionOfSources = DescriptionOfOperandDataSources();

	DataForCalculation = ProductDataManagement.DataForCalculationByFormulas(
		Catalogs.BillsOfMaterials, ParametersForCalculation, DescriptionOfSources, DataSources);
	Return DataForCalculation;
	
EndFunction

Function UploadDataForFormulaConstructor(ObjectOrRef, TSName, RowData = Undefined) Export
	
	DescriptionOfSources = DescriptionOfOperandDataSources();
	
	MainProduct = ProductDataManagementClientServer.MainPropsOfMainProductSpecification(ObjectOrRef);
	
	DescriptionOfSources["MainProduct"].SourceOfProductProperties = MainProduct.Value;
	
	If Not IsBlankString(TSName) 
		And TSName <> "RecyclableWaste" Then
		DescriptionOfSources.Delete("RecyclableWaste");
		DescriptionOfSources.Delete("ReturnWaste");
	EndIf;
	
	If TSName = "ManufacturedProducts" Then
		DescriptionOfSources.Delete("MaterialsAndServices");
		DescriptionOfSources.Delete("Material");
	EndIf;
	
	ProductDataManagement.SupplementDescriptionOfSourcesWithCompositionOfOperands(
		DescriptionOfSources, ObjectOrRef, TSName, RowData);
	
	Return DescriptionOfSources;
	
EndFunction

Procedure PrepareParametersForCalculationUsingFormulas(ItemData_3, StructureOfData, Tables, DescriptionOfSources, ListOfData, SourcesOfParameterValues)
	
	If Not StructureOfData.ContainsResourcesParametrization Then
		Return;
	EndIf;
	
	If DescriptionOfSources = Undefined Then
		DescriptionOfSources = DescriptionOfOperandDataSources();
	EndIf;
	
	If SourcesOfParameterValues = Undefined Then
		SourcesOfParameterValues = ProductDataManagement.CreateTableOfSourcesOfParameterValuesForCalculationByFormulas();
	EndIf;

	FilterStructure1 = New Structure("QuantityCalculationAlgorithm", "");	
	DataSets = New Array;
	For Each TableName In ListOfData Do
		Table = StructureOfData[TableName];
		If Table.Columns.Find("Formula") <> Undefined
			And Table.FindRows(FilterStructure1).Count() <> Table.Count() Then	
			DataSets.Add(Table);
		EndIf;
	EndDo;
	
	If DataSets.Count() = 0 Then
		Return;
	EndIf;
	
	ParametersForCalculation = ProductDataManagement.ParametersForCalculationByFormulas(DescriptionOfSources, DataSets);
	If ParametersForCalculation.Count() = 0 Then
		Return;
	EndIf;
	
	FilterStructure1 = New Structure("Id", ItemData_3.Id);
	DataSources = StructureOfSourcesForCalculationByFormulas();
	For Each KeyAndValue In DataSources Do
		If StructureOfData.Property(KeyAndValue.Key) Then
			DataSources[KeyAndValue.Key] = StructureOfData[KeyAndValue.Key];
		ElsIf Tables.Property(KeyAndValue.Key) Then
			DataSources[KeyAndValue.Key] = Tables[KeyAndValue.Key].Copy(FilterStructure1);
		EndIf;
	EndDo;
	DataSources.ItemData_3 = ItemData_3;
	
	ProductDataManagement.SupplementTableOfSourcesOfParameterValuesForCalculationByFormulas(
		Catalogs.BillsOfMaterials,
		SourcesOfParameterValues,
		DataSources,
		DescriptionOfSources,
		ParametersForCalculation);
	
	StructureOfData.Insert("ParametersForCalculationByFormulas", ParametersForCalculation);
	
EndProcedure

#EndRegion

#Region DataSources

// Constructor of the source structure for calculation using formulas
// 
// Returns:
// 	Structure - From:
// * ItemData_3 - See ProductData_5
// * MaterialsAndServices - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
// * RecyclableWaste - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
// * ManufacturedProducts - See ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas
// * MainProduct - Structure - Main product
//
Function StructureOfSourcesForCalculationByFormulas() Export
	
	DataSources = New Structure;
	
	DataSources.Insert("MainProduct");
	
	DataSources.Insert("ManufacturedProducts",  ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	DataSources.Insert("RecyclableWaste", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	DataSources.Insert("MaterialsAndServices", ProductDataManagement.CreateTableOfDataSourcesForCalculationByFormulas());
	
	DataSources.Insert("ItemData_3"); // data on the order nomenclature
	
	Return DataSources;
	
EndFunction

// Description of operand sources for formulas
// 
// Parameters:
// 	Object - FormDataStructure,Undefined - object data
// Returns:
// 	Structure - From:
// 		* MainProduct - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* ManufacturedProducts - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* FinishedProduct - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* MaterialsAndServices - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* Material - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* RecyclableWaste - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* ReturnWaste - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* Department - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* ReferenceOrder - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
// 		* LineOfBusiness - See ProductDataManagement.CreateDescriptionsOfOperandDataSource
//
Function DescriptionOfOperandDataSources(Object = Undefined) Export
	
	TypeDescriptionNumber = New TypeDescription("Number");
	
	Result = New Structure;
	
	// [Main Product]
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
		Or Object.ProductionProcessType = Enums.ProductionProcessTypes.Assembly Then
		
		SourcePresentation = NStr("vi = 'Sản phẩm đầu ra';
									|ru = 'Выходные изделия';
									|en = 'Finished products'; fa = 'Finished products';
									|it = 'Prodotti finiti';
									|pl = 'Wyroby gotowe';
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
	
	EndIf;
		
	// [MaterialsAndServices]
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
	
	// [Material]
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
	
	// [RecyclableWaste]
	SourcePresentation = NStr("vi = 'Xuất xưởng sản phẩm phụ';
								|ru = 'Побочный выход';
								|en = 'By-product'; fa = 'محصول فرعی';
								|it = 'Produzione collaterale';
								|pl = 'Produkcja poboczna';
								|tr = 'Yan ürün çıkışı'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"RecyclableWaste", SourcePresentation);
	
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
	
	Result.Insert("RecyclableWaste", LongDesc);
	
	// [ReturnWaste]
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
	If GetFunctionalOption("UseProductionManagement2_2")
		And Not GetFunctionalOption("UseProductionManagement") Then
		
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
	
	// [BillOfMaterials]
	SourcePresentation = NStr("vi = 'Bảng kê chi tiết';
								|ru = 'Спецификация';
								|en = 'bill of materials'; fa = 'bill of materials';
								|it = 'Specifica';
								|pl = 'Specyfikacja';
								|tr = 'Ürün reçetesi'");
	LongDesc = ProductDataManagement.CreateDescriptionsOfOperandDataSource(
		"BillOfMaterials", SourcePresentation);
		
	LongDesc.ContainsProperties = True;
	LongDesc.PropertiesSet     = PropertyManager.PropertiesSetByName("Catalog_BillsOfMaterials");
	
	Result.Insert("BillOfMaterials", LongDesc);
	
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
	
	If DataPath.Key = "MainProduct" Then
		
		Source = ProductDataManagement.CreateSourceDataStructureForCalculationUsingFormulas();
		FillPropertyValues(Source, DataSources.MainProduct);
		
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
			Or DataPath.Key = "BillOfMaterials"
			Or DataPath.Key = "LineOfBusiness" Then
			
			FillPropertyValues(Structure, DataSources.ItemData_3);
			
		EndIf;
		Source = Structure[DataPath.Key];
		
	EndIf;
	
	Return Source;
	
EndFunction

#EndRegion

#EndRegion

#Region SettingsForAutomaticSelectionAndConsumptionOfProducts

Procedure ProcessAutoSelectionSettings(Tables, TempTablesManager, SelectionParameters)
	
	If Not GetFunctionalOption("UseBillOfMaterialsParameterization") Then
		Return;
	EndIf;
	
	AutoSelectionParameters = Undefined;
	
	For Each DataSetName In StrSplit("MaterialsAndServices,RecyclableWaste,ManufacturedProducts",",") Do
		
		DataSet = Undefined;
		If Not Tables.Property(DataSetName, DataSet) Then
			Continue;
		EndIf;
		
		If AutoSelectionParameters = Undefined Then
			AutoSelectionParameters = GetAutoSelectionParameters(Tables, TempTablesManager, SelectionParameters);
		EndIf;
		AutoSelectionParameters.TSName = DataSetName;
		
		ProductDataManagement.ProcessSettingsForAutomaticSelectionOfProducts(DataSet, AutoSelectionParameters);
		
	EndDo;
	
EndProcedure

Function GetAutoSelectionParameters(Tables, TempTablesManager, SelectionParameters)
	
	AutoSelectionParameters = ProductDataManagement.AutoSelectionParametersConstructor();
	
	AutoSelectionParameters.TempTablesManager = TempTablesManager;
	
	TableOfProductData = Tables.ItemData_3; // ValueTable
	TableOfProductData.Indexes.Add("Id");
	AutoSelectionParameters.TableOfProductData = TableOfProductData;
	
	ValuesOfProductProperties = Tables.ValuesOfProductProperties; // ValueTable
	ValuesOfProductProperties.Indexes.Add("Products,Characteristic");
	ValuesOfProductProperties.Indexes.Add("Property");
	ValuesOfProductProperties.Indexes.Add("IDProperty");
	AutoSelectionParameters.ValuesOfProductProperties = ValuesOfProductProperties;
	
	PropertyMapping = Tables.PropertyMapping; // ValueTable
	PropertyMapping.Indexes.Add("BillOfMaterials");
	PropertyMapping.Indexes.Add("BillOfMaterials,ConnectionKey");
	AutoSelectionParameters.PropertyMapping = PropertyMapping;
	
	AutoSelectionParameters.GetPresentations      = SelectionParameters.GetPresentations;
	AutoSelectionParameters.GetAutoSelectionInformation = SelectionParameters.GetAutoSelectionInformation;
	
	Return AutoSelectionParameters;
	
EndFunction

#EndRegion

#Region AssignmentParameters

Function ValuesOfBOMAssignmentParameters(Specifications) Export
	
	Result = New Map;
	
	TableTemplate = New ValueTable;
	TableTemplate.Columns.Add("ParameterKind", New TypeDescription("EnumRef.TypesOfBOMAssignmentParameters"));
	TableTemplate.Columns.Add("Attribute",     New TypeDescription("ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo"));
	TableTemplate.Columns.Add("ValueType",  New TypeDescription("TypeDescription"));
	TableTemplate.Columns.Add("ValueStructure");
	
	QueryText = "
	|SELECT
	|	Values.BillOfMaterials             AS BillOfMaterials,
	|	Values.ParameterKind             AS ParameterKind,
	|	Values.Attribute                 AS Attribute,
	|	Values.Attribute.ValueType     AS PropsValueType,
	|	Values.NumberInList             AS NumberInList,
	|	Values.Condition                  AS Condition,
	|	Values.Value                 AS Value,
	|	ISNULL(Settings.Priority, -1) AS Priority
	|FROM
	|	InformationRegister.ValuesOfBOMAssignmentParameters AS Values
	|
	|	LEFT JOIN InformationRegister.BOMAssignmentParameters AS Settings
	|	ON Values.ParameterKind = Settings.ParameterKind
	|		AND Values.Attribute = Settings.Attribute
	|
	|WHERE
	|	Values.BillOfMaterials IN (&Specifications)
	|
	|ORDER BY
	|	ISNULL(Settings.Priority, -1) DESC,
	|	Values.Condition,
	|	Values.NumberInList
	|TOTALS BY
	|	Values.BillOfMaterials,
	|	Values.ParameterKind,
	|	Values.Attribute";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Specifications", Specifications);
	
	ConditionsStructure = ProductDataManagementClientServer.StructureOfSelectionConditionsByProductProperties();
	
	SampleSpecification = Query.Execute().Select(QueryResultIteration.ByGroups, "BillOfMaterials");
	For Each BillOfMaterials In Specifications Do
		
		SpecificationAssignmentParameters = TableTemplate.CopyColumns();
		
		SampleSpecification.Reset();
		SampleSpecification.FindNext(BillOfMaterials);
		
		SelectionTypeOfParameter = SampleSpecification.Select(QueryResultIteration.ByGroups, "ParameterKind");
		While SelectionTypeOfParameter.Next() Do
			
			SelectingProps = SelectionTypeOfParameter.Select(QueryResultIteration.ByGroups, "Attribute");
			While SelectingProps.Next() Do
				
				Condition           = Undefined; // See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
				ValueStructure = ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure();
				
				Selection = SelectingProps.Select(QueryResultIteration.Linear);
				While Selection.Next() Do
					
					If Not ConditionsStructure.Property(Selection.Condition, Condition) Then
						Continue;
					EndIf;
					
					If Condition.List Then
						
						If Not ValueIsFilled(ValueStructure.Value) Then
							ValueStructure.Value = New ValueList;
						EndIf;
						ValueStructure.Value.Add(Selection.Value);
						
					ElsIf Selection.NumberInList > 0 Then
						
						If StrFind(Condition.Id, "Greater") Then
							ValueStructure.Value1 = Selection.Value;
						ElsIf StrFind(Condition.Id, "Less") Then
							ValueStructure.Value2 = Selection.Value;
						EndIf;
						Condition = ConditionsStructure[?(StrFind(Condition.Id, "Equal"),"InIntervalIncluding","InInterval")];
						
					Else
						
						ValueStructure.Value = Selection.Value;
						
					EndIf;
					
				EndDo;
				
				If Condition <> Undefined Then
					ValueStructure.Condition = Condition;
					NewRow = SpecificationAssignmentParameters.Add();
					NewRow.ParameterKind      = SelectionTypeOfParameter.ParameterKind;
					NewRow.Attribute          = SelectingProps.Attribute;
					NewRow.ValueStructure = ValueStructure;
					NewRow.ValueType       = ProductDataManagementClientServer.TypeOfValueOfDestinationParameter(
														SelectionTypeOfParameter.ParameterKind,
														SelectingProps.PropsValueType);
				EndIf;
				
			EndDo;
			
		EndDo;
		
		SpecificationAssignmentParameters.Indexes.Add("ParameterKind");
		SpecificationAssignmentParameters.Indexes.Add("ParameterKind,Attribute");
		
		Result.Insert(BillOfMaterials, SpecificationAssignmentParameters);
		
	EndDo;
	
	Return Result;
	
EndFunction

// Constructor of parameters for calling a background job to define a list of preemptive specifications
// 
// Parameters:
// 	Object - CatalogObject.BillsOfMaterials - specification object
// Returns:
// 	Structure - Parameters:
// * BillOfMaterials - CatalogRef.BillsOfMaterials - BillOfMaterials
// * ProductKind - CatalogRef.ItemKinds - Product kind
// * Products - CatalogRef.Products - Products
// * Characteristic - CatalogRef.ItemsCharacteristics - Characteristic
// * BOMSelectionParameters - See ProductDataManagementClientServer.BOMSelectionParameters
//
Function ListOfPreemptiveSpecificationsCallParameters(Object) Export
	
	ProcedureParameters = New Structure;
	
	MainProduct = ProductDataManagementClientServer.MainProductSpecificationData(Object);
	
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	BOMSelectionParameters.AvailableTypes.Add(Object.ProductionProcessType);
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	
	ProcedureParameters.Insert("BillOfMaterials",                Object.Ref);
	ProcedureParameters.Insert("ProductKind",             MainProduct.ProductKind);
	ProcedureParameters.Insert("Products",                MainProduct.Products);
	ProcedureParameters.Insert("Characteristic",              MainProduct.Characteristic);
	ProcedureParameters.Insert("BOMSelectionParameters", BOMSelectionParameters);
	
	Return ProcedureParameters;
	
EndFunction

Procedure ListOfPreemptiveSpecificationsInBackground(Parameters, StorageAddress) Export
	
	BillOfMaterials = Parameters.BillOfMaterials;
	
	Specifications = ListOfPreemptiveSpecifications(BillOfMaterials, Parameters);
	
	PutToTempStorage(Specifications, StorageAddress);
	
EndProcedure

Function ListOfPreemptiveSpecifications(BillOfMaterials, AdditionalParameters = Undefined) Export
	
	ProductKind = Catalogs.ItemKinds.EmptyRef();
	Products    = Catalogs.Products.EmptyRef();
	Characteristic  = Catalogs.ItemsCharacteristics.EmptyRef();
	BOMSelectionParameters = Undefined;
	
	If TypeOf(AdditionalParameters) = Type("Structure") Then
		If AdditionalParameters.Property("ProductKind") Then
			ProductKind = AdditionalParameters.ProductKind;
		EndIf;
		If AdditionalParameters.Property("Products") Then
			Products = AdditionalParameters.Products;
		EndIf;
		If AdditionalParameters.Property("Characteristic") Then
			Characteristic = AdditionalParameters.Characteristic;
		EndIf;
		If AdditionalParameters.Property("BOMSelectionParameters") Then
			BOMSelectionParameters = AdditionalParameters.BOMSelectionParameters;
		EndIf;
	EndIf;
	
	RequestTextParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	RequestTextParameters.PriorityOnly = True;
	RequestTextParameters.OutputTableName = "TTSpecifications";
	
	If BOMSelectionParameters = Undefined Then
		BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
		BOMSelectionParameters.AvailableTypes.Add(Common.ObjectAttributeValue(BillOfMaterials,"ProductionProcessType"));
		BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	EndIf;
	
	QueryText = "
	|SELECT
	|	Table.Ref.ProductionProcessType AS ProductionProcessType,
	|	Table.ProductKind                     AS ProductKind,
	|	Table.Products                        AS Products,
	|	Table.Characteristic                      AS Characteristic,
	|	Table.Ref.ValidOnDate               AS ValidOnDate,
	|	CASE
	|		WHEN Table.Ref.ValidToDate = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 1, 1)
	|		ELSE Table.Ref.ValidToDate
	|	END                                       AS ValidToDate
	|INTO TTCurSpecificationData
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.Ref.ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Assembly), VALUE(Enum.ProductionProcessTypes.Repair))
	|	AND (Table.ProductKind = &ProductKind
	|			OR &ProductKind = VALUE(Catalog.ItemKinds.EmptyRef))
	|	AND (Table.Products = &Products
	|			OR &Products = VALUE(Catalog.Products.EmptyRef))
	|	AND (Table.Characteristic = &Characteristic
	|			OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|
	|UNION
	|
	|SELECT
	|	Table.ProductionProcessType,
	|	Table.MainProductProductKind,
	|	Table.MainProductProducts,
	|	Table.MainProductCharacteristic,
	|	Table.ValidOnDate,
	|	CASE
	|		WHEN Table.ValidToDate = DATETIME(1, 1, 1)
	|			THEN DATETIME(3999, 1, 1)
	|		ELSE Table.ValidToDate
	|	END
	|FROM
	|	Catalog.BillsOfMaterials AS Table
	|WHERE
	|	Table.Ref = &BillOfMaterials
	|	AND Table.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|	AND (Table.MainProductProductKind = &ProductKind
	|			OR &ProductKind = VALUE(Catalog.ItemKinds.EmptyRef)) 
	|	AND (Table.MainProductProducts = &Products
	|			OR &Products = VALUE(Catalog.Products.EmptyRef))
	|	AND (Table.MainProductCharacteristic = &Characteristic
	|			OR &Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.Ref                 AS BillOfMaterials,
	|	Table.Ref.Code             AS Code,
	|	Table.Ref.ValidOnDate  AS ValidOnDate,
	|	Table.Ref = &BillOfMaterials AS IsCurrent
	|INTO TTDataOfCompetingSpecifications
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|		INNER JOIN TTCurSpecificationData AS CurrentSpecification
	|		ON Table.Ref.ProductionProcessType = CurrentSpecification.ProductionProcessType
	|			AND NOT Table.Ref.ExcludeAutomaticSelection
	|			AND Table.Ref.Status IN (&AvailableStatuses)
	|			AND Table.ProductKind = CurrentSpecification.ProductKind
	|			AND (Table.Products = CurrentSpecification.Products
	|				OR CurrentSpecification.Products = VALUE(Catalog.ItemKinds.EmptyRef))
	|			AND (Table.Characteristic = CurrentSpecification.Characteristic
	|				OR CurrentSpecification.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|WHERE
	|	Table.Ref.ValidOnDate <= CurrentSpecification.ValidToDate
	|	AND CASE
	|			WHEN Table.Ref.ValidToDate = DATETIME(1, 1, 1)
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE Table.Ref.ValidToDate
	|		END >= CurrentSpecification.ValidOnDate
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref,
	|	Table.Code,
	|	Table.ValidOnDate,
	|	Table.Ref = &BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials AS Table
	|		INNER JOIN TTCurSpecificationData AS CurrentSpecification
	|		ON Table.ProductionProcessType = CurrentSpecification.ProductionProcessType
	|			AND NOT Table.ExcludeAutomaticSelection
	|			AND Table.Status IN (&AvailableStatuses)
	|			AND Table.MainProductProductKind = CurrentSpecification.ProductKind
	|			AND (Table.MainProductProducts = CurrentSpecification.Products
	|				OR CurrentSpecification.Products = VALUE(Catalog.ItemKinds.EmptyRef))
	|			AND (Table.MainProductCharacteristic = CurrentSpecification.Characteristic
	|				OR CurrentSpecification.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|WHERE
	|	Table.ValidOnDate <= CurrentSpecification.ValidToDate
	|	AND CASE
	|			WHEN Table.ValidToDate = DATETIME(1, 1, 1)
	|				THEN DATETIME(3999, 1, 1)
	|			ELSE Table.ValidToDate
	|		END >= CurrentSpecification.ValidOnDate
	|
	|INDEX BY
	|	BillOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	T.*
	|FROM
	|	TTDataOfCompetingSpecifications AS T
	|
	|ORDER BY
	|	T.IsCurrent DESC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Property AS Property
	|FROM
	|	Catalog.BillsOfMaterials.SelectionByProperties AS Table
	|		INNER JOIN TTDataOfCompetingSpecifications AS Table_Selection
	|		ON Table.Ref = Table_Selection.BillOfMaterials
	|			AND Table.ConnectionKey IN (&CommunicationKeyProducts, &CommunicationKeyCharacteristic)
	|WHERE
	|	&UseAdditionalBankingDetails_3
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Table.ParameterKind AS ParameterKind,
	|	Table.Attribute     AS Attribute,
	|	Table.Priority    AS Priority
	|FROM
	|	InformationRegister.BOMAssignmentParameters AS Table
	|WHERE
	|	&UseDestinationParameters
	|
	|ORDER BY
	|	Priority DESC
	|";
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager;
	Query.SetParameter("BillOfMaterials",     BillOfMaterials);
	Query.SetParameter("ProductKind",  ProductKind);
	Query.SetParameter("Products",     Products);
	Query.SetParameter("Characteristic",   Characteristic);
	Query.SetParameter("AvailableStatuses", BOMSelectionParameters.AvailableStatuses);
	Query.SetParameter("CommunicationKeyProducts", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Products"));
	Query.SetParameter("CommunicationKeyCharacteristic", ProductDataManagementClientServer.SelectionByPropertiesOfCommunicationKey("Characteristic"));
	Query.SetParameter("UseDestinationParameters", GetFunctionalOption("UseBOMAssignmentParameters"));
	Query.SetParameter("UseAdditionalBankingDetails_3", GetFunctionalOption("UseAdditionalAttributesAndInfo"));
	Query.Text = QueryText;
	
	QueryResults = Query.ExecuteBatch();
	
	Specifications                    = QueryResults[QueryResults.Count()-3].Unload();
	ApplicationClarifications             = QueryResults[QueryResults.Count()-2].Unload();
	ApplicationRefinementsAreUsed = ApplicationClarifications.Count() > 0;
	AssignmentParameters             = QueryResults[QueryResults.Count()-1].Unload();
	DestinationParametersAreUsed = AssignmentParameters.Count() > 0;
	
	Result = New Array;
	If Specifications.Count() = 0 Then
		Return Result;
	EndIf;
	
	CurrentSpecification = Specifications[0];
	
	// Checking the conditions for clarifying the application.
	If ApplicationRefinementsAreUsed Then
		
		ValuesOfApplicationConstraints = ProductDataManagement.ValuesOfSpecificationsApplicationConstraints(Specifications.UnloadColumn("BillOfMaterials"));
		ValuesForCurSpecificationApplicationConstraints = ValuesOfApplicationConstraints.Get(CurrentSpecification.BillOfMaterials);
		
		DeleteLineSpecifications = New Array;
		For IndexOf = 1 To Specifications.Count() - 1 Do
			
			ValuesOfLineConstraints = ValuesOfApplicationConstraints.Get(Specifications[IndexOf].BillOfMaterials);
			For Each ClarificationOfApplication In ApplicationClarifications Do
				
				CurValue_1 = ValuesForCurSpecificationApplicationConstraints.Find(ClarificationOfApplication.Property, "Property");
				StringValue_  = ValuesOfLineConstraints.Find(ClarificationOfApplication.Property, "Property");
				
				If CurValue_1 <> Undefined
					And StringValue_ <> Undefined
					And Not ThereIsIntersectionOfDestinationParameters(CurValue_1, StringValue_) Then
						DeleteLineSpecifications.Add(Specifications[IndexOf]);
						Break;
				EndIf;
				
			EndDo;
			
		EndDo;
		
		For Each String In DeleteLineSpecifications Do
			Specifications.Delete(String);
		EndDo;
		
	EndIf;
	
	// Checking the parameters of the assignment, validity period, code.
	TheStructureOfTheSearch                        = New Structure("ParameterKind,Attribute");
	DestinationParameterValues           = Undefined;
	CurSpecificationAssignmentParameters = Undefined;
	For IndexOf = 1 To Specifications.Count() - 1 Do
		
		PreemptiveSpecification      = False;
		CheckDisplacementByPeriod = True;
		
		If DestinationParametersAreUsed Then
			
			If DestinationParameterValues = Undefined Then
				
				DestinationParameterValues           = ValuesOfBOMAssignmentParameters(Specifications.UnloadColumn("BillOfMaterials"));
				CurSpecificationAssignmentParameters = DestinationParameterValues.Get(CurrentSpecification.BillOfMaterials);
				
			EndIf;
			
			StringAssignmentParameters = DestinationParameterValues.Get(Specifications[IndexOf].BillOfMaterials);
			For Each DestinationParameter In AssignmentParameters Do
				
				FillPropertyValues(TheStructureOfTheSearch, DestinationParameter);
				
				FoundByCur = CurSpecificationAssignmentParameters.FindRows(TheStructureOfTheSearch);
				FoundByLine  = StringAssignmentParameters.FindRows(TheStructureOfTheSearch);
				
				If Not ValueIsFilled(FoundByCur) And Not ValueIsFilled(FoundByLine) Then
					Continue;
				ElsIf Not ValueIsFilled(FoundByCur) And ValueIsFilled(FoundByLine) Then
					PreemptiveSpecification = True;
					Break;
				ElsIf ValueIsFilled(FoundByCur) And Not ValueIsFilled(FoundByLine) Then
					CheckDisplacementByPeriod = False;
					Break;
				Else
					If ThereIsIntersectionOfDestinationParameters(FoundByCur[0].ValueStructure, FoundByLine[0].ValueStructure) Then
						Continue;
					Else
						CheckDisplacementByPeriod = False;
						Break;
					EndIf;
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If Not PreemptiveSpecification And CheckDisplacementByPeriod Then
			
			If Specifications[IndexOf].ValidOnDate > CurrentSpecification.ValidOnDate
				Or (Specifications[IndexOf].ValidOnDate = CurrentSpecification.ValidOnDate
						And Specifications[IndexOf].Code > CurrentSpecification.Code) Then
				PreemptiveSpecification = True;
			EndIf;
			
		EndIf;
		
		If PreemptiveSpecification Then
			Result.Add(Specifications[IndexOf].BillOfMaterials);
		EndIf;
		
	EndDo;
	
	Return Result;
	
EndFunction

// Determines the existence of the intersection of parameters of assignment
// 
// Parameters:
// 	ValueStructure1 - See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
// 	ValueStructure2 - See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure
// Returns:
// 	Boolean - Indication of the intersection of parameters
Function ThereIsIntersectionOfDestinationParameters(ValueStructure1, ValueStructure2)
	
	ArrayOfValues1 = ValueOfSpecificationAssignmentParameterInArray(ValueStructure1);
	ArrayOfValues2 = ValueOfSpecificationAssignmentParameterInArray(ValueStructure2);
	
	If ValueStructure1.Condition.Fullness Then
		Return ThereIsIntersectionOfDestinationParametersBasedOnOccupancyConditions(
			ValueStructure1.Condition, ValueStructure2.Condition, ArrayOfValues2);
	EndIf;
	
	If ValueStructure2.Condition.Fullness Then
		Return ThereIsIntersectionOfDestinationParametersBasedOnOccupancyConditions(
			ValueStructure2.Condition, ValueStructure1.Condition, ArrayOfValues1);
	EndIf;
	
	If ArrayOfValues1.UBound() = -1 Or ArrayOfValues2.UBound() = -1 Then
		Return False;
	EndIf;
	
	ValueType1 = TypeOf(ArrayOfValues1[0]);
	ValueType2 = TypeOf(ArrayOfValues2[0]);
	
	If ValueType1 <> ValueType2 Then
		Return True;
	EndIf;
	
	If ValueType1 = Type("Number") Or ValueType1 = Type("Date") Then
		
		Return ThereIsIntersectionOfAssignmentParametersOverIntervals(
			ValueStructure1.Condition, ArrayOfValues1, ValueStructure2.Condition, ArrayOfValues2);
		
	Else
		
		Return ThereIsIntersectionOfAssignmentParametersByNonIntervalConditions(
			ValueStructure1.Condition, ArrayOfValues1, ValueStructure2.Condition, ArrayOfValues2);
		
	EndIf;
	
EndFunction

Function ValueOfSpecificationAssignmentParameterInArray(ValueStructure)
	
	Result = New Array;
	
	If ValueStructure.Condition.Interval Then
		Result.Add(ValueStructure.Value1);
		Result.Add(ValueStructure.Value2);
	ElsIf ValueStructure.Condition.List Then
		ValueStructure.Value.SortByValue();
		For Each ListItem In ValueStructure.Value Do
			Result.Add(ListItem.Value);
		EndDo;
	ElsIf Not ValueStructure.Condition.Fullness Then
		Result.Add(ValueStructure.Value);
	EndIf;
	
	Return Result;
	
EndFunction

// Converts the parameter value to an array of interval values
// 
// Parameters:
// 	Condition - See ProductDataManagementClientServer.StructureOfSelectionConditionByProductProperties
// 	ArrayOfValues - Array of See ProductDataManagementClientServer.SpecificationAssignmentParameterValueStructure - Array of values
// Returns:
// 	Array of See IntervalStructureOfDestinationParameterValue - array of intervals
Function ValueOfSpecificationAssignmentParameterInIntervalArray(Condition, Val ArrayOfValues)
	
	Result = New Array;
	
	If Condition.Reverse_1 Then // Unequal, unevenly
		
		ArrayOfValues.Add(ValueOfIntervalBoundaryIsInfinity(1));
		
		CurStartOfInterval = ValueOfIntervalBoundaryIsInfinity(-1);
		For IndexOf = 0 To ArrayOfValues.UBound() Do
			
			CurrentValue = ArrayOfValues[IndexOf];
			
			If CurStartOfInterval = CurrentValue Then
				Continue;
			EndIf;
			
			Interval = IntervalStructureOfDestinationParameterValue();
			
			Interval.Begin  = ValueOfIntervalBoundaryByValueOfDestinationParameter(CurStartOfInterval);
			Interval.End   = ValueOfIntervalBoundaryByValueOfDestinationParameter(CurrentValue);
			
			CurStartOfInterval = CurrentValue;
			
			Result.Add(Interval);
			
		EndDo;
		
	ElsIf Condition.Interval Then // WIntervale, Wintervale including
		
		Interval = IntervalStructureOfDestinationParameterValue();
		
		Interval.Begin  = ValueOfIntervalBoundaryByValueOfDestinationParameter(ArrayOfValues[0]);
		Interval.End   = ValueOfIntervalBoundaryByValueOfDestinationParameter(ArrayOfValues[1]);
		
		Result.Add(Interval);
		
	ElsIf Condition.Comparison Then // More equal, Less Equal, More, Less
		
		Interval = IntervalStructureOfDestinationParameterValue();
		
		If StrFind(Condition.Id, "Greater") > 0 Then
			Interval.Begin = ValueOfIntervalBoundaryByValueOfDestinationParameter(ArrayOfValues[0]);
		Else
			Interval.End  = ValueOfIntervalBoundaryByValueOfDestinationParameter(ArrayOfValues[0]);
		EndIf;
			
		Result.Add(Interval);
		
	Else // Equal to, VSPISK
		
		For Each Value In ArrayOfValues Do
			
			Interval = IntervalStructureOfDestinationParameterValue();
			
			Interval.Begin = ValueOfIntervalBoundaryByValueOfDestinationParameter(Value);
			Interval.End  = ValueOfIntervalBoundaryByValueOfDestinationParameter(Value);
			
			Result.Add(Interval);
			
		EndDo;
		
	EndIf;
	
	Return Result;
	
EndFunction

Function ThereIsIntersectionOfDestinationParametersBasedOnOccupancyConditions(Condition1, Condition2, ArrayOfValues2)
	
	If Condition1.Id = "Filled" Then
		
		If Condition2.Id = "NotFilled" Then
			Return False;
		EndIf;
		
		If ArrayOfValues2.Count() = 1
			And (Not ValueIsFilled(ArrayOfValues2[0]) Or ArrayOfValues2[0] = False)
			And (Condition2.Id = "Equal" Or Condition2.Id = "InList") Then
			Return False;
		EndIf;
		
		Return True;
		
	EndIf;
	
	If Condition1.Id = "NotFilled" Then
		
		ThereAreBlankOnes = False;
		For Each Value In ArrayOfValues2 Do
			If Not ValueIsFilled(Value) Or Value = False Then
				ThereAreBlankOnes = True;
				Break;
			EndIf;
		EndDo;
		
		If ThereAreBlankOnes
			And (Condition2.Equality_ = True Or Condition2.Id = "InList") Then
			Return True;
		EndIf;
		
		Return False;
		
	EndIf;
	
	Return False;
	
EndFunction

Function ThereIsIntersectionOfAssignmentParametersOverIntervals(Condition1, ArrayOfValues1, Condition2, ArrayOfValues2)
	
	ArrayOfIntervals1 = ValueOfSpecificationAssignmentParameterInIntervalArray(Condition1, ArrayOfValues1);
	ArrayOfIntervals2 = ValueOfSpecificationAssignmentParameterInIntervalArray(Condition2, ArrayOfValues2);
	
	Delta = 0.0000000000000000000000000000001;
	
	For Each Interval1 In ArrayOfIntervals1 Do
		For Each Interval2 In ArrayOfIntervals2 Do
			
			Begin1 = Interval1.Begin + ?(Condition1.Including, 0, Delta);
			End1  = Interval1.End  - ?(Condition1.Including, 0, Delta);
			
			Begin2 = Interval2.Begin + ?(Condition2.Including, 0, Delta);
			End2  = Interval2.End  - ?(Condition2.Including, 0, Delta);
			
			If Begin1 <= End2 And End1 >= Begin2 Then
				Return True;
			EndIf;
			
		EndDo;
	EndDo;
	
	Return False;
	
EndFunction

Function ThereIsIntersectionOfAssignmentParametersByNonIntervalConditions(Condition1, ArrayOfValues1, Condition2, ArrayOfValues2)
	
	If Condition1.Reverse_1 = Condition2.Reverse_1 Then
		If Condition1.Reverse_1 Then
			Return True;
		Else
			Return (ArrayOfValues1.Count() <> CommonClientServer.ArraysDifference(ArrayOfValues1, ArrayOfValues2).Count())
		EndIf;
	Else
		If Condition1.Reverse_1 Then
			Return CommonClientServer.ArraysDifference(ArrayOfValues2, ArrayOfValues1).Count() > 0;
		Else
			Return CommonClientServer.ArraysDifference(ArrayOfValues1, ArrayOfValues2).Count() > 0;
		EndIf;
	EndIf;
	
EndFunction

Function ValueOfIntervalBoundaryIsInfinity(Character)
	
	Return Character * 9999999999999999999999999999999;
	
EndFunction

Function ValueOfIntervalBoundaryByValueOfDestinationParameter(Value)
	
	If TypeOf(Value) = Type("Date") Then
		Return (Value - Date(1,1,1));
	Else
		Return Value;
	EndIf;
	
EndFunction

// Constructor for the interval structure of the destination parameter value
// 
// Returns:
// 	Structure - From:
// * Begin - Date - Start date
// * End - Date - Expiry date
Function IntervalStructureOfDestinationParameterValue()
	
	Interval = New Structure("Begin,End");
	Interval.Begin  = ValueOfIntervalBoundaryIsInfinity(-1);
	Interval.End   = ValueOfIntervalBoundaryIsInfinity(1);
	
	Return Interval;
	
EndFunction

#EndRegion

#Region Sets

// Details of the set composition line.
// 
// Parameters:
//  SetType - String - Shopping,Technological
//  SelectionParameters - SeeDataSamplingParameters
// 
// Returns:
//  String - Details of the set composition line
Function DetailsOfSetCompositionLine(SetType, SelectionParameters = Undefined)
	
	Attributes = New Array;
	
	Attributes.Add("Id");
	Attributes.Add("ConnectionKey");
	Attributes.Add("LineNumber");
	
	Attributes.Add("ItemsType");
	Attributes.Add("Products");
	Attributes.Add("Characteristic");
	Attributes.Add("ItemVariantsAreUsed");
	Attributes.Add("BillOfMaterials");
	Attributes.Add("MethodOfProductsAutoselection");
	Attributes.Add("MethodOfItemVariantAutoselection");
	Attributes.Add("UseAutoselection");
	Attributes.Add("AutoselectionDetails");
	Attributes.Add("ItemVariantAutoSelectionAlgorithm");
	Attributes.Add("Produced");
	Attributes.Add("ProducedInProcess");
	Attributes.Add("Count");
	Attributes.Add("UnitOfMeasure");
	Attributes.Add("PieceUnitOfMeasure");
	Attributes.Add("NumberOfPackages");
	Attributes.Add("Package");
	Attributes.Add("PackageData");
	Attributes.Add("PackagingPiece");
	Attributes.Add("RoundOff");
	Attributes.Add("QuantityCalculationAlgorithm");
	Attributes.Add("Warehouse");
	Attributes.Add("SupplyOption");
	Attributes.Add("WithAssignment");
	Attributes.Add("ToPlan");
	Attributes.Add("OrderToWarehouse");
	Attributes.Add("OperationParent");
	Attributes.Add("MethodOfReceivingMaterial");
	Attributes.Add("SourceOfSemiFinishedProduct");
	Attributes.Add("PermissionToReplace");
	If SetType = "Technological" Then
		Attributes.Add("ProductCostElement");
		Attributes.Add("MaterialApplication");
		Attributes.Add("AlternateType");
		Attributes.Add("Probability");
		Attributes.Add("ProbabilityCoefficient");
		Attributes.Add("CommunicationKeySet");
	EndIf;
	If SelectionParameters = Undefined
			Or SelectionParameters.GetPresentations Then
		Attributes.Add("Ed");
		Attributes.Add("ProductsPresentation");
		Attributes.Add("CharacteristicPresentation");
		If SetType = "Technological" Then
			Attributes.Add("ApplyingTheMaterialEditing");
		EndIf;
	EndIf;
	
	Return StrConcat(Attributes,",");
	
EndFunction

Procedure IncludeDataSetsInSpecificationDataStructure(SpecificationData, Tables, SelectionParameters, FilterStructure1)
	
	If Not SelectionParameters.GetDataSets Then
		Return;
	EndIf;
	
	DataOfSets = New Structure;
	
	TypesOfDataSets = New Array;
	TypesOfDataSets.Add("DataOfTradingSets");
	TypesOfDataSets.Add("DataOfTechnologicalSets");
	For Each TypeOfDataSets In TypesOfDataSets Do
		
		StructureOfData = New Structure("State, Content, SavedLines", "Missing1");
		
		If Tables.Property(TypeOfDataSets) Then
		
			Content = Tables[TypeOfDataSets].Copy(FilterStructure1); // ValueTable
			If Content.Count() > 0 Then
				
				StructureOfData.Content    = Content;
				StructureOfData.State = "Collapsed_1";
				
			EndIf;
		
		EndIf;
		
		DataOfSets.Insert(TypeOfDataSets, StructureOfData);
		
	EndDo;
	
	SpecificationData.Insert("DataOfSets", DataOfSets);
	
EndProcedure

// Decompresses / convolves data sets inside the specification data structure
// 
// Parameters:
// 	ReleaseParty - Structure - release batch
// 	SpecificationData - See DataSpecificationConstructor
// 	Phase - String - the action that should be performed: Unpack, Collapse
//
Procedure ProcessDataSets(ReleaseParty, SpecificationData, Phase)
	
	If Not SpecificationData.Property("MaterialsAndServices")
			Or Not SpecificationData.Property("DataOfSets") Then
		Return;
	EndIf;
	
	FilterAttributes = "ConnectionKey";
	FilterAttributes = "ConnectionKey,OperationParent";
	FilterItemsType = New Structure("ItemsType", Enums.ItemsTypes.Set);
	RowFilter           = New Structure(FilterAttributes);
	
	SourceOfCompositionOfSetsInProduction = ProductDataManagementCached.SourceOfCompositionOfSetsInProduction();
	
	MaterialsAndServices  = SpecificationData.MaterialsAndServices;
	
	TypesOfDataSets = New Array;
	TypesOfDataSets.Add("DataOfTechnologicalSets");
	TypesOfDataSets.Add("DataOfTradingSets");
	
	#Region Collapse
	
	If Phase = "BeforeCalculationProcess" Then
		
		For Each TypeOfDataSets In TypesOfDataSets Do
			DataOfSets = SpecificationData.DataOfSets[TypeOfDataSets];
			
			If DataOfSets.State = "Unpacked" Then
				
				If Not SpecificationData.DataOfSets.Property("MaterialsAndServices") Then
					SpecificationData.DataOfSets.Insert("MaterialsAndServices", MaterialsAndServices);
					MaterialsAndServices = MaterialsAndServices.Copy();
				EndIf;
				
				For Each NewMaterials In DataOfSets.SavedLines Do
					
					InsertIndex = MaterialsAndServices.Count()-1;
					
					IndexOf = 0;
					While IndexOf < MaterialsAndServices.Count() Do
						String = MaterialsAndServices[IndexOf];
						If ValueIsFilled(String.CommunicationKeySet)
								And NewMaterials.KeysLinksSet.Find(String.CommunicationKeySet) <> Undefined Then
							InsertIndex = Min(InsertIndex, IndexOf);
							MaterialsAndServices.Delete(IndexOf);
							Continue;
						EndIf;
						IndexOf = IndexOf + 1;
					EndDo;
					
					NewRow = MaterialsAndServices.Insert(InsertIndex);
					FillPropertyValues(NewRow, NewMaterials);
					
				EndDo;
				
				DataOfSets.State = "Collapsed_1";
				DataOfSets.SavedLines.Clear();
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
	#EndRegion
	
	#Region UnpackingProcess
	
	If Phase = "AfterCalculation" Then
		
		MaterialsAndServicesKits = MaterialsAndServices.FindRows(FilterItemsType);
		If MaterialsAndServicesKits.Count() = 0 Then
			Return;
		EndIf;
		
		MaterialsAndWorksSets = ProductDataManagement.SetsOfMaterialsAndWorksDesigner();
		
		For Each TypeOfDataSets In TypesOfDataSets Do
			
			DataOfSets = SpecificationData.DataOfSets[TypeOfDataSets];
			
			If DataOfSets.State = "Collapsed_1" Then
				
				If DataOfSets.Content.Indexes.Count() = 0 Then
					DataOfSets.Content.Indexes.Add(FilterAttributes);
				EndIf;
				
				SavedLines = MaterialsAndServices.CopyColumns();
				SavedLines.Columns.Add("KeysLinksSet");
				If TypeOfDataSets = "DataOfTechnologicalSets" Then
					
					StringWithStructure = New Structure(DetailsOfSetCompositionLine("Technological"));
					
					For Each NewMaterials In MaterialsAndServicesKits Do
						
						If NewMaterials.Products.IsEmpty() Then
							Continue;
						EndIf;
						
						KeysLinksSet = New Array;
						
						FillPropertyValues(RowFilter, NewMaterials);
						FoundRows = DataOfSets.Content.FindRows(RowFilter);
						If FoundRows.Count() = 0 Then
							Continue;
						EndIf;
						
						CommunicationKeySet             = New UUID();
						SetSpecificationData   = FoundRows[0].SpecificationData;
						DataOnSetNomenclature = ProductData_5();
						FillPropertyValues(DataOnSetNomenclature, NewMaterials);
						
						SetBatch = ReleaseParty(NewMaterials.Count,
							SetSpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch
								* SetSpecificationData.MainProduct.PackageData.Numerator
									/ SetSpecificationData.MainProduct.PackageData.Denominator);
						
						CalculateQuantityPerBatchRelease(
							SetBatch,
							SetSpecificationData,
							DataOnSetNomenclature);
							
						InsertIndex = MaterialsAndServices.IndexOf(NewMaterials)+1;
						For IndexOf = 0 To SetSpecificationData.MaterialsAndServices.Count()-1 Do
							
							SetRow = SetSpecificationData.MaterialsAndServices[IndexOf];
							FillPropertyValues(StringWithStructure, SetRow);
							
							NewRow = MaterialsAndServices.Insert(InsertIndex);
							FillPropertyValues(NewRow, NewMaterials);
							FillPropertyValues(NewRow, StringWithStructure,,"Id,LineNumber,OperationParent");
							NewRow.NumberOfPackagesPerUnitOfProductionBatch = SetRow.NumberOfPackagesPerUnitOfProductionBatch
								* NewMaterials.NumberOfPackagesPerUnitOfProductionBatch * NewMaterials.PackageData.Numerator
									/ SetSpecificationData.MainProduct.NumberOfPackagesPerUnitOfProductionBatch * NewMaterials.PackageData.Denominator;
							If SourceOfCompositionOfSetsInProduction = Enums.SourcesOfCompositionOfSetsInProduction.Specifications
									And ValueIsFilled(NewMaterials.ProductCostElement) Then
								NewRow.ProductCostElement = NewMaterials.ProductCostElement;
							EndIf;
							NewRow.WithAssignment = (NewRow.WithAssignment
															Or NewMaterials.WithAssignment);
							If Not ValueIsFilled(NewRow.CommunicationKeySet) Then
								NewRow.CommunicationKeySet = CommunicationKeySet;
							EndIf;
							
							InsertIndex = InsertIndex + 1;
							KeysLinksSet.Add(NewRow.CommunicationKeySet);
							
						EndDo;
						
						NewRow = MaterialsAndWorksSets.Add();
						NewRow.ConnectionKey             = CommunicationKeySet;
						NewRow.BillOfMaterials          = NewMaterials.BillOfMaterials;
						NewRow.ParentSpecification  = SpecificationData.BillOfMaterials;
						NewRow.LinkKeyBOM = NewMaterials.ConnectionKey;
						NewRow.Stage                  = NewMaterials.Stage;
						NewRow.RowsCount       = SetSpecificationData.MaterialsAndServices.Count();
						If SetSpecificationData.Property("MaterialsAndWorksSets") Then
							For Each String In SetSpecificationData.MaterialsAndWorksSets Do
								NewRow = MaterialsAndWorksSets.Add();
								FillPropertyValues(NewRow, String);
								If Not ValueIsFilled(NewRow.ParentCommunicationKey) Then
									NewRow.ParentCommunicationKey = CommunicationKeySet;
								EndIf;
								If Not ValueIsFilled(NewRow.Stage) Then
									NewRow.Stage = NewMaterials.Stage;
								EndIf;
							EndDo;
						EndIf;
						
						NewRow = SavedLines.Add();
						FillPropertyValues(NewRow, NewMaterials);
						NewRow.KeysLinksSet = TMCommonUse.DeleteDuplicateElementsFromArray(KeysLinksSet);
						MaterialsAndServices.Delete(NewMaterials);
						
					EndDo;
					
				EndIf;
				If TypeOfDataSets = "DataOfTradingSets" Then
					
					StringWithStructure = New Structure(DetailsOfSetCompositionLine("Shopping"));
					
					For Each NewMaterials In MaterialsAndServicesKits Do
						
						If NewMaterials.Products.IsEmpty() Then
							Continue;
						EndIf;
						
						KeysLinksSet = New Array;
						
						FillPropertyValues(RowFilter, NewMaterials);
						SetComposition = DataOfSets.Content.Copy(RowFilter);
						If SetComposition.Count() = 0 Then
							Continue;
						EndIf;
						
						CommunicationKeySet = New UUID();
						InsertIndex  = MaterialsAndServices.IndexOf(NewMaterials)+1;
						
						SetComposition.Sort("LineNumber");
						For IndexOf = 0 To SetComposition.Count() - 1 Do
							
							SetRow = SetComposition[IndexOf];
							FillPropertyValues(StringWithStructure, SetRow);
							
							NewRow = MaterialsAndServices.Insert(InsertIndex);
							FillPropertyValues(NewRow, NewMaterials);
							FillPropertyValues(NewRow, StringWithStructure,,"Id,LineNumber");
							NewRow.NumberOfPackages = SetRow.NumberOfPackages * NewMaterials.Count;
							NewRow.Count = SetRow.NumberOfPackages
								* NewMaterials.Count
								* SetRow.PackageData.Numerator / SetRow.PackageData.Denominator;
							NewRow.NumberOfPackagesPerUnitOfProductionBatch = SetRow.NumberOfPackages
								* NewMaterials.NumberOfPackagesPerUnitOfProductionBatch
								* NewMaterials.PackageData.Numerator / NewMaterials.PackageData.Denominator;
							If Not ValueIsFilled(NewRow.CommunicationKeySet) Then
								NewRow.CommunicationKeySet = CommunicationKeySet;
							EndIf;
							
							InsertIndex = InsertIndex + 1;
							KeysLinksSet.Add(NewRow.CommunicationKeySet);
							
						EndDo;
						
						NewRow = MaterialsAndWorksSets.Add();
						NewRow.ConnectionKey             = CommunicationKeySet;
						NewRow.BillOfMaterials          = SetComposition[0].ProductKit;
						NewRow.ParentSpecification  = SpecificationData.BillOfMaterials;
						NewRow.LinkKeyBOM = NewMaterials.ConnectionKey;
						NewRow.Stage                  = NewMaterials.Stage;
						NewRow.RowsCount       = SetComposition.Count();
						
						NewRow = SavedLines.Add();
						FillPropertyValues(NewRow, NewMaterials);
						NewRow.KeysLinksSet = TMCommonUse.DeleteDuplicateElementsFromArray(KeysLinksSet);
						MaterialsAndServices.Delete(NewMaterials);
						
					EndDo;
					
				EndIf;
				
				DataOfSets.SavedLines = SavedLines;
				DataOfSets.State = "Unpacked";
				
				MaterialsAndServicesKits = MaterialsAndServices.FindRows(FilterItemsType);
				
			EndIf;
			
		EndDo;
		
		MaterialsAndWorksSets.Indexes.Add("ConnectionKey");
		SpecificationData.Insert("MaterialsAndWorksSets", MaterialsAndWorksSets);
		
		For Each NewMaterials In MaterialsAndServicesKits Do
			
			If NewMaterials.Products.IsEmpty() Then
				Continue;
			EndIf;
			
			ProductPresentation = ProductsClientServer.ProductPresentation(
					NewMaterials.Products,
					NewMaterials.Characteristic);
					
			AutoselectionDetails = StrTemplate(NStr("vi = 'Không thể xác định thành phần tập hợp ""%1"".%2';
													|ru = 'Не удалось определить состав набора ""%1"".%2';
													|en = 'Cannot determine the content of the ""%1"" set.%2'; fa = 'Cannot determine the content of the ""%1"" set.%2';
													|it = 'Non è stato possibile definire la composizione del kit ""%1"".%2';
													|pl = 'Nie udało się określić skład zestawu ""%1"".%2';
													|tr = '""%1"" set kapsamı tanımlanamadı.%2'"),
				ProductPresentation,
				" "+NewMaterials.AutoselectionDetails);
			
			NewMaterials.Products                   = Catalogs.Products.EmptyRef();
			NewMaterials.Characteristic                 = Catalogs.ItemsCharacteristics.EmptyRef();
			NewMaterials.MethodOfProductsAutoselection   = Enums.MethodsOfProductAutoSelection.SpecifiedInProductionProcess;
			NewMaterials.MethodOfItemVariantAutoselection = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
			NewMaterials.AutoselectionDetails             = TrimAll(AutoselectionDetails);
			NewMaterials.UseAutoselection          = True;
			
		EndDo;
		
		If SpecificationData.DataOfSets.Property("MaterialsAndServices") Then
			For IndexOf = 0 To MaterialsAndServices.Count() - 1 Do
				FillPropertyValues(SpecificationData.DataOfSets.MaterialsAndServices[IndexOf], MaterialsAndServices[IndexOf]);
			EndDo;
			MaterialsAndServices = SpecificationData.DataOfSets.MaterialsAndServices;
			SpecificationData.DataOfSets.Delete("MaterialsAndServices");
		EndIf;
		
	EndIf;
	
	#EndRegion
	
	SpecificationData.MaterialsAndServices = MaterialsAndServices;
	
EndProcedure

Procedure GetDataOfTechnologicalSets(ItemList, Tables, SelectionParameters)
	
	If ItemList.Count() = 0 Then
		Return;
	EndIf;
	
	ProcessingParameters = Undefined;
	If Not SelectionParameters.Property("ProcessingParametersOfTechnologicalSets", ProcessingParameters) Then
		ProcessingParameters = New Structure;
		ProcessingParameters.Insert("Level",                      0);
		ProcessingParameters.Insert("LoopControlGraphs",   New Map());
		ProcessingParameters.Insert("ListOfDataCopy",          SelectionParameters.ListOfData);
		ProcessingParameters.Insert("TemporaryTableManagerCopy", SelectionParameters.TempTablesManager);
		SelectionParameters.ListOfData = StrSplit("ManufacturedProducts,MaterialsAndServices", ",");
		SelectionParameters.Insert("ProcessingParametersOfTechnologicalSets", ProcessingParameters);
	EndIf;
	ProcessingParameters.Level = ProcessingParameters.Level + 1;
	
	ChainSeparator  = 100000;
	GraphsOfCurrentLevel = New Array;
	ItemList.Columns.Add("Id",        New TypeDescription("Number"));
	ItemList.Columns.Add("ChainID", New TypeDescription("Number"));
	
	For IndexOf = 0 To ItemList.Count() - 1 Do
		CurrentRow = ItemList[IndexOf];
		
		Id = CurrentRow.RowOwner["Id"];
		CurrentRow.ChainID = ?(
			Id >= ChainSeparator, Int(Id/ChainSeparator), Id);
		CurrentRow.Id = CurrentRow.ChainID * ChainSeparator + IndexOf;
		
		Count_ = ProcessingParameters.LoopControlGraphs.Get(CurrentRow.ChainID);
		If Count_ = Undefined Then
			Count_ = ProductionManagement.Count_();
			ProcessingParameters.LoopControlGraphs.Insert(CurrentRow.ChainID, Count_);
		EndIf;
		
		CurrentVertex = ProductionManagement.GetVertexOfGraphFromLink(Count_, CurrentRow.SpecificationOwner);
		ProductionManagement.AddAdjacentVertexToAdjacencyList(CurrentVertex, CurrentRow.BillOfMaterials);
		ProductionManagement.GetVertexOfGraphFromLink(Count_, CurrentRow.BillOfMaterials);
		
		If GraphsOfCurrentLevel.Find(Count_) = Undefined Then
			GraphsOfCurrentLevel.Add(Count_);
		EndIf;
		
	EndDo;
	
	ErrorList = New Array(2);
	For Each Count_ In GraphsOfCurrentLevel Do
		If ProductionManagement.ThereAreCyclesInGraph(Count_, ErrorList[0], ErrorList[1]) Then
			ErrorText = NStr("vi = 'Đã tìm thấy vòng lặp khi nhận dữ liệu bộ sản phẩm (bảng kê chi tiết ""%1"" và ""%2"").';
							|ru = 'Обнаружено зацикливание при получении данных производственных наборов (спецификации ""%1"" и ""%2"").';
							|en = 'Looping is detected when receiving the production set data (""%1"" and ""%2"" bills of materials).'; fa = 'Looping is detected when receiving the production set data (""%1"" and ""%2"" bills of materials).';
							|it = 'Rilevato loop alla ricezione dei dati dei kit di produzione (specifiche ""%1"" e ""%2"")';
							|pl = 'Wykryto zapętlenie podczas otrzymania danych zestawów produkcyjnych (specyfikacje ""%1"" i ""%2"").';
							|tr = 'Üretim kümelerinin verileri alınırken döngü tespit edildi (""%1"" ve ""%2"" ürün reçetesi).'");
			Raise StrTemplate(ErrorText, ErrorList[0], ErrorList[1]);
		EndIf;
	EndDo;
	
	SelectionParameters.TempTablesManager = Undefined;
	SpecificationsData = SpecificationData(ItemList, SelectionParameters);
	
	DataOfSets = Tables.MaterialsAndServices.CopyColumns("Id,ConnectionKey,OperationParent"); // ValueTable
	DataOfSets.Columns.Add("SpecificationData");
	
	For IndexOf = 0 To ItemList.Count() - 1 Do
		CurrentRow = ItemList[IndexOf];
		NewRow = DataOfSets.Add();
		FillPropertyValues(NewRow, CurrentRow.RowOwner);
		NewRow.SpecificationData = SpecificationsData[CurrentRow.Id];
	EndDo;
	
	DataOfSets.Indexes.Add("Id");
	Tables.Insert("DataOfTechnologicalSets", DataOfSets);
	
	ProcessingParameters.Level = ProcessingParameters.Level - 1;
	If ProcessingParameters.Level = 0 Then
		SelectionParameters.ListOfData          = ProcessingParameters.ListOfDataCopy;
		SelectionParameters.TempTablesManager = ProcessingParameters.TemporaryTableManagerCopy;
		SelectionParameters.Delete("ProcessingParametersOfTechnologicalSets");
	EndIf;
	
EndProcedure

#EndRegion

#Region IntermediateRelease

Function QuantitativeAttributesOfDataLineOfSpecification(String = Undefined)
	
	Result = New Structure;
	
	Result.Insert("Count",                               0);
	Result.Insert("NumberOfPackages",                       0);
	Result.Insert("NumberOfPackagesPerUnitOfProductionBatch", 0);
	
	If String <> Undefined Then
		FillPropertyValues(Result, String);
	EndIf;
	
	Return Result;
	
EndFunction

#EndRegion

#Region Other

Procedure AddPresentationsToRequest(QueryText, GetPresentations)
	
	If GetPresentations Then
	
		QueryText = StrReplace(QueryText, "&ProductionStages_Presentations,",
										"ISNULL(ProductionStages.Department.Presentation, """") AS DepartmentPresentation,
										|	ISNULL(ProductionStages.RouteSheet.Presentation, """") AS RouteSheetPresentation,"); //@Query-part
										
		QueryText = StrReplace(QueryText, "&TypesOfWorkCenters_Presentations,",
										"ISNULL(TabularSection.WorkCenterType.Presentation, """") AS WorkCenterTypePresentation,"); //@Query-part
										
		QueryText = StrReplace(QueryText, "&OutputProducts_Presentations,",
										"ISNULL(TTWares.Stage.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN TTWares.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
										|			THEN ISNULL(TTWares.Package.Presentation, """")
										|		ELSE ISNULL(TTWares.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	ISNULL(TTWares.ProductKind.Presentation, """") AS ProductKindPresentation,
										|	ISNULL(TTWares.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(TTWares.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&ReturnableWaste_Presentations,",
										"ISNULL(TTWares.Stage.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN TTWares.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
										|			THEN ISNULL(TTWares.Package.Presentation, """")
										|		ELSE ISNULL(TTWares.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	ISNULL(TTWares.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(TTWares.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&MaterialsAndServices_Presentations,",
										"ISNULL(MaterialsAndServices.Stage.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN MaterialsAndServices.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
										|			THEN ISNULL(MaterialsAndServices.Package.Presentation, """")
										|		ELSE ISNULL(MaterialsAndServices.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	ISNULL(MaterialsAndServices.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(MaterialsAndServices.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		QueryText = StrReplace(QueryText, "&IntermediateRelease_Views,",
										"ISNULL(IntermediateRelease.StageSender.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN IntermediateRelease.Products.UnitOfMeasure.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Products.UnitOfMeasure.Presentation
										|		ELSE ISNULL(Products_Selected.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	CASE
										|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN IntermediateRelease.Products.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Products.Presentation
										|		ELSE ISNULL(Products_Selected.Products.Presentation, """")
										|	END AS ProductsPresentation,
										|	CASE
										|		WHEN IntermediateRelease.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN IntermediateRelease.Characteristic.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Characteristic.Presentation
										|		ELSE ISNULL(Products_Selected.Characteristic.Presentation, """")
										|	END AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&MaterialsAndServicesTP_Presentation,",
										"ISNULL(TTTechnologicalProcesses.Stage.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN MaterialsAndServices.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
										|			THEN ISNULL(MaterialsAndServices.Package.Presentation, """")
										|		ELSE ISNULL(MaterialsAndServices.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	ISNULL(MaterialsAndServices.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(MaterialsAndServices.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&PV_SubmissionMaterials,",
										"ISNULL(UsedMaterials.RecipientStage.Presentation, """") AS StagePresentation,
										|	CASE
										|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN UsedMaterials.Products.UnitOfMeasure.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Products.UnitOfMeasure.Presentation
										|		ELSE ISNULL(Products_Selected.Products.UnitOfMeasure.Presentation, """")
										|	END AS Ed,
										|	CASE
										|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN UsedMaterials.Products.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Products.Presentation
										|		ELSE ISNULL(Products_Selected.Products.Presentation, """")
										|	END AS ProductsPresentation,
										|	CASE
										|		WHEN UsedMaterials.Products <> VALUE(Catalog.Products.EmptyRef)
										|			THEN UsedMaterials.Characteristic.Presentation
										|		WHEN ItemIsNew.Products IS NOT NULL
										|			THEN ItemIsNew.Characteristic.Presentation
										|		ELSE ISNULL(Products_Selected.Characteristic.Presentation, """")
										|	END AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&WorksPerformed_Presentations,",
										"ISNULL(WorksToPerform.Stage.Presentation, """") AS StagePresentation,
										|	ISNULL(WorksToPerform.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(WorksToPerform.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		
		QueryText = StrReplace(QueryText, "&IncomingFinishedProducts_Presentations,",
										"ISNULL(TTWares.Stage.Presentation, """") AS StagePresentation,
										|	ISNULL(TTWares.Products.Presentation, """") AS ProductsPresentation,
										|	ISNULL(TTWares.Characteristic.Presentation, """") AS CharacteristicPresentation,"); //@Query-part
		
	Else
		
		QueryText = StrReplace(QueryText, "&ProductionStages_Presentations,", "");
										
		QueryText = StrReplace(QueryText, "&TypesOfWorkCenters_Presentations,", "");
										
		QueryText = StrReplace(QueryText, "&OutputProducts_Presentations,", "");
		
		QueryText = StrReplace(QueryText, "&ReturnableWaste_Presentations,", "");
		
		QueryText = StrReplace(QueryText, "&MaterialsAndServices_Presentations,", "");
		QueryText = StrReplace(QueryText, "&IntermediateRelease_Views,", "");
		
		QueryText = StrReplace(QueryText, "&MaterialsAndServicesTP_Presentation,", "");
		
		QueryText = StrReplace(QueryText, "&PV_SubmissionMaterials,", "");
		
		QueryText = StrReplace(QueryText, "&WorksPerformed_Presentations,", "");
		
		QueryText = StrReplace(QueryText, "&IncomingFinishedProducts_Presentations,", "");
	EndIf;
	
EndProcedure

Procedure ApplySelectionBasedOnDataSelectionParameters(MaterialsAndServices, SelectionParameters)
	
	If Not SelectionParameters.AvailableWorks Then
		
		For X = -MaterialsAndServices.Count() + 1 To 0 Do
			
			String = MaterialsAndServices[-X];
			
			If String.ItemsType = Enums.ItemsTypes.OwnGoods
				Or String.ItemsType = Enums.ItemsTypes.ReusablePackage
				Or String.ItemsType = Enums.ItemsTypes.Set
				Or String.Products.IsEmpty() Then
				Continue;
			EndIf;
			
			MaterialsAndServices.Delete(-X);
			
		EndDo;
	
	EndIf;
	
EndProcedure
Procedure CreateIntermediateItemCharacteristic(String, IntermediateReleaseLinkCache)
	
	If ValueIsFilled(String.ItemOfIntermediateRelease) Then
		CreateProducts = False;
	ElsIf IntermediateReleaseLinkCache[String.Products] <> Undefined Then
		String.ItemOfIntermediateRelease = IntermediateReleaseLinkCache[String.Products];
		CreateProducts = False;
	Else
		CreateProducts = True;
	EndIf;
	
	If Not String.CreateCharacteristic Then
		CreateCharacteristic = False;
	ElsIf IntermediateReleaseLinkCache[String.Characteristic] <> Undefined Then
		String.CharacteristicsOfIntermediateRelease = IntermediateReleaseLinkCache[String.Characteristic];
		CreateCharacteristic = False;
	Else
		CreateCharacteristic = True;
	EndIf;
	
	If Not CreateProducts And Not CreateCharacteristic Then
		Return;
	EndIf;
	
	BeginTransaction();
	
	Try
		
		DataLock = New DataLock;
		
		LockItem = DataLock.Add("InformationRegister.AnotherQualityGoods");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.SetValue("Products", String.Products);
		
		DataLock.Lock();
		
		If CreateProducts Then
			Query = New Query(
				"SELECT
				|	AnotherQualityGoods.OtherQualityGoods                            AS OtherQualityGoods,
				|	AnotherQualityGoods.OtherQualityGoods.ProductKind            AS ItemTypeOfNonconformityTypeOfItem,
				|	AnotherQualityGoods.OtherQualityGoods.UseVariants AS ItemsOfNonconformityUseOfCharacteristics,
				|	AnotherQualityGoods.OtherQualityGoods.UnitOfMeasure           AS ItemsOfNonconformityUnitOfMeasurement,
				|	AnotherQualityGoods.OtherQualityGoods.UsePackages       AS ItemsNonconformityOfPackagingUse
				|INTO TTGoodsOfOtherQuality
				|FROM
				|	InformationRegister.AnotherQualityGoods AS AnotherQualityGoods
				|WHERE
				|	AnotherQualityGoods.Products = &Products
				|	AND AnotherQualityGoods.QualityGradation = VALUE(Enum.QualityLevels.SuitableToALimitedExtent)
				|INDEX BY
				|	ItemTypeOfNonconformityTypeOfItem,
				|	ItemsOfNonconformityUseOfCharacteristics,
				|	ItemsOfNonconformityUnitOfMeasurement,
				|	ItemsNonconformityOfPackagingUse
				|;
				|
				|////////////////////////////////////////////////////////////////////////////////
				|SELECT TOP 1
				|	AnotherQualityGoods.OtherQualityGoods AS Products
				|FROM
				|	Catalog.Products AS MainProduct
				|
				|	INNER JOIN TTGoodsOfOtherQuality AS AnotherQualityGoods
				|	ON MainProduct.ProductKind = AnotherQualityGoods.ItemTypeOfNonconformityTypeOfItem
				|		AND MainProduct.UseVariants = AnotherQualityGoods.ItemsOfNonconformityUseOfCharacteristics
				|		AND MainProduct.UnitOfMeasure = AnotherQualityGoods.ItemsOfNonconformityUnitOfMeasurement
				|		AND MainProduct.UsePackages = AnotherQualityGoods.ItemsNonconformityOfPackagingUse
				|WHERE
				|	MainProduct.Ref = &Products");
			Query.SetParameter("Products", String.Products);
			Selection = Query.Execute().Select();
			If Selection.Next() Then
				String.ItemOfIntermediateRelease = Selection.Products;
				IntermediateReleaseLinkCache.Insert(String.Products, Selection.Products);
			Else
				SetPrivilegedMode(True);
				Products = String.Products.Copy();
				Products.Description = Products.Description
					+ ", " + String(Enums.QualityLevels.SuitableToALimitedExtent);
				Products.DescriptionFull = Products.DescriptionFull
					+ ", " + String(Enums.QualityLevels.SuitableToALimitedExtent);
				Products.Quality = Enums.QualityLevels.SuitableToALimitedExtent;
				Products.PicturesFile = Catalogs.ProductsAttachedFiles.EmptyRef();
				Products.DescriptionFileForWebsite = Catalogs.ProductsAttachedFiles.EmptyRef();
				Products.Code = "";
				Products.SearchCode = "";
				Products.DeletionMark = False;
				Products.Write();
				
				InformationRegisters.AnotherQualityGoods.RecordLinkToProductOfDifferentQuality(
					String.Products, Products.Ref);
				SetPrivilegedMode(False);
				
				String.ItemOfIntermediateRelease = Products.Ref;
				IntermediateReleaseLinkCache.Insert(String.Products, Products.Ref);
			EndIf;
		EndIf;
		
		If CreateCharacteristic Then
			String.CharacteristicsOfIntermediateRelease = Catalogs.ItemsCharacteristics.IdenticalCharacteristic(
				String.ItemOfIntermediateRelease, String.Characteristic);
			IntermediateReleaseLinkCache.Insert(String.Characteristic, String.CharacteristicsOfIntermediateRelease);
		EndIf;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		WriteLogEvent(
			NStr("vi = 'Bảng kê chi tiết nguồn lực';
				|ru = 'Ресурсная спецификация';
				|en = 'Bill of materials'; fa = 'فهرست مواد (BOM)';
				|it = 'Specifica di risorse';
				|pl = 'Specyfikacja';
				|tr = 'Ürün reçetesi'", Common.DefaultLanguageCode()),
			EventLogLevel.Error,,,
			ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		Raise NStr("vi = 'Không thể tạo mặt hàng xuất xưởng trung gian';
					|ru = 'Не удалось создать номенклатуру промежуточного выпуска';
					|en = 'Cannot create intermediate products'; fa = 'Cannot create intermediate products';
					|it = 'Не удалось создать номенклатуру промежуточного выпуска';
					|pl = 'Cannot create intermediate products';
					|tr = 'Ara ürün çıkışı için öğe oluşturulamadı'");
		
	EndTry;
	
EndProcedure

// Combines tables of materials and incoming items
// 
// Parameters:
// 	SpecificationsData - Map - this specification
// 	DataTables - Structure - From:
//		* MaterialsAndServices - ValueTable - table of materials:
//			** Id - Number - row ID
//		* IncomingProducts - ValueTable - Product Table:
//			** Id - Number - row ID
Procedure CombineMaterialsAndIncomingProducts(SpecificationsData, DataTables)
	
	TableOfIncomingProducts  = Undefined; // ValueTable
	TableMaterialsAndServices = Undefined; // ValueTable
	
	If Not DataTables.Property("IncomingProducts", TableOfIncomingProducts)
		Or Not DataTables.Property("MaterialsAndServices", TableMaterialsAndServices) Then
		Return;
	EndIf;
	
	DefaultValuesInColumns = DefaultValuesInColumnsWhenMerging(
		TableOfIncomingProducts, TableMaterialsAndServices);
	
	FilterStructure1 = New Structure("Id");
	
	IDsTable = TableOfIncomingProducts.Copy(,"Id");
	IDsTable.GroupBy("Id");
	
	For Each IDRow In IDsTable Do
		
		SpecificationData = SpecificationsData.Get(IDRow.Id); // See DataSpecificationConstructor
		MaterialsAndServices   = SpecificationData.MaterialsAndServices;
		
		IncomingProducts = Undefined;
		If Not SpecificationData.Property("IncomingProducts", IncomingProducts) Then
			If TableOfIncomingProducts.Indexes.Count() = 0 Then
				TableOfIncomingProducts.Indexes.Add("Id");
			EndIf;
			FilterStructure1.Id = IDRow.Id;
			IncomingProducts = TableOfIncomingProducts.Copy(FilterStructure1);
		EndIf;
		
		RowsCount = MaterialsAndServices.Count();
		
		If RowsCount > 0 Then
			LineNumber = MaterialsAndServices[RowsCount-1].LineNumber + 1;
		Else
			LineNumber = 1;
		EndIf;
		
		For Each String In IncomingProducts Do
			
			NewRow = MaterialsAndServices.Add();
			FillPropertyValues(NewRow, String,, "LineNumber");
			FillPropertyValues(NewRow, DefaultValuesInColumns);
			
			NewRow.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
			
			ProductDataManagement.FillInPackingDataInDataSetRow(NewRow, DataTables.PackageData_);
			
		EndDo;
		
	EndDo;
	
EndProcedure

// Combines tables of materials and works performed
// 
// Parameters:
// 	SpecificationsData - Map - this specification
// 	DataTables - Structure - From:
//		* MaterialsAndServices - ValueTable - table of materials:
//			** Id - Number - row ID
//		* WorksToPerform - ValueTable - Product Table:
//			** Id - Number - row ID
Procedure CombineMaterialsAndWorksPerformed(SpecificationsData, DataTables)
	
	TableOfWorksPerformed = Undefined; // ValueTable
	TableMaterialsAndServices  = Undefined; // ValueTable
	
	If Not DataTables.Property("WorksToPerform", TableOfWorksPerformed)
		Or Not DataTables.Property("MaterialsAndServices", TableMaterialsAndServices) Then
		Return;
	EndIf;
	
	DefaultValuesInColumns = DefaultValuesInColumnsWhenMerging(
		TableOfWorksPerformed, TableMaterialsAndServices);
	
	FilterStructure1 = New Structure("Id");
	
	IDsTable = TableOfWorksPerformed.Copy(,"Id");
	IDsTable.GroupBy("Id");
	
	For Each IDRow In IDsTable Do
		
		SpecificationData = SpecificationsData.Get(IDRow.Id); // See DataSpecificationConstructor
		MaterialsAndServices   = SpecificationData.MaterialsAndServices;
		MaterialsAndServices.Columns.Add("UnderRepairProduct", New TypeDescription("CatalogRef.Products"));
		MaterialsAndServices.Columns.Add("UnderRepairVariant", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		
		WorksToPerform = Undefined;
		If Not SpecificationData.Property("WorksToPerform", WorksToPerform) Then
			If TableOfWorksPerformed.Indexes.Count() = 0 Then
				TableOfWorksPerformed.Indexes.Add("Id");
			EndIf;
			FilterStructure1.Id = IDRow.Id;
			WorksToPerform = TableOfWorksPerformed.Copy(FilterStructure1);
		EndIf;
		
		RowsCount = MaterialsAndServices.Count();
		
		If RowsCount > 0 Then
			LineNumber = MaterialsAndServices[RowsCount-1].LineNumber + 1;
		Else
			LineNumber = 1;
		EndIf;
		
		For Each String In WorksToPerform Do
			
			NewRow = MaterialsAndServices.Add();
			FillPropertyValues(NewRow, String,, "LineNumber");
			FillPropertyValues(NewRow, DefaultValuesInColumns);
			
			NewRow.LineNumber = LineNumber;
			LineNumber = LineNumber + 1;
			
			If NewRow.ProducedInProcess Then
				NewRow.Produced = True;
				NewRow.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials;
				NewRow.SourceOfSemiFinishedProduct = NewRow.BillOfMaterials;
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Function DefaultValuesInColumnsWhenMerging(SourceTable1, DestinationTable)
	
	DefaultValuesInColumns = New Structure();
	
	For Each Column In DestinationTable.Columns Do
		ColumnName = Column.Name;
		If SourceTable1.Columns.Find(ColumnName) <> Undefined Then
			Continue;
		EndIf;
		DefaultValue = Undefined;
		For Each Type In Column.ValueType.Types() Do
			If Type = Type("Null") Then
				Continue;
			ElsIf Type = Type("EnumRef.MethodsOfReceivingBOMMaterials") Then
				DefaultValue = Enums.MethodsOfReceivingBOMMaterials.Provide;
				Break;
			ElsIf Type = Type("EnumRef.MethodsOfProductAutoSelection") Then
				DefaultValue = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
				Break;
			ElsIf Type = Type("EnumRef.MethodsOfItemVariantAutoselection") Then
				DefaultValue = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
				Break;
			EndIf;
			TypesArray = New Array;
			TypesArray.Add(Type);
			TypeDescription = New TypeDescription(TypesArray);
			DefaultValue = TypeDescription.AdjustValue(Undefined);
			Break;
		EndDo;
		DefaultValuesInColumns.Insert(ColumnName, DefaultValue);
	EndDo;
	
	Return DefaultValuesInColumns;
	
EndFunction

Procedure FillInMaterialSupportParameters(Query, Tables, SelectionParameters)
	
	Table = Undefined; // ValueTable
	If Not Tables.Property("MaterialsAndServices", Table) Then
		Return;
	EndIf;
	
	ProductDataManagement.FillInPackingDataInDataset(
		Table,
		Tables.PackageData_);
	
	Table.Columns.Add("RowIndex", New TypeDescription("Number"));
	
	RowIndex      = 0;
	RowsCountToProcess = 0;
	SelectReplacements   = False;
	
	DeleteTables        = New Array;
	TablesDataOfPackages = New Array;
	
	For Each String In Table Do
		String.RowIndex = RowIndex;
		String.SelectReplacement = SelectionParameters.PerformDirectiveSubstitutions
				And (String.SelectReplacement
				Or String.ItemsType = Enums.ItemsTypes.Set
					And SelectionParameters.GetDataSets
				Or String.UseAutoselection);
		If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
					And String.BillOfMaterials.IsEmpty()
				Or String.ItemsType = Enums.ItemsTypes.Set
					And SelectionParameters.GetDataSets
				Or String.UseAutoselection
				Or String.SelectReplacement Then
			RowsCountToProcess = RowsCountToProcess + 1;
			SelectReplacements = SelectReplacements Or String.SelectReplacement;
		EndIf;
		RowIndex = RowIndex + 1;
	EndDo;
	
	If RowsCountToProcess = 0 Then
		Table.Columns.Delete("RowIndex");
		Return;
	EndIf;
		
	QueriesTexts = New Array;
	
	//
	QueryText = "
	|SELECT
	|	FALSE                AS DataOfSets,
	|
	|	T.Id     AS Id,
	|	T.RowIndex      AS RowIndex,
	|	0                   AS LineNumber,
	|	T.ConnectionKey         AS ConnectionKey,
	|
	|	T.Products      AS Products,
	|	T.Characteristic    AS Characteristic,
	|	T.ItemsType   AS ItemsType,
	|	FALSE                AS ItemVariantsAreUsed,
	|
	|	0                                                          AS Count,
	|	0                                                          AS NumberOfPackages,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS UnitOfMeasure,
	|	VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef) AS Package,
	|	0                                                          AS PackageData,
	|
	|	FALSE                                                       AS PieceUnitOfMeasure,
	|	FALSE                                                       AS PackagingPiece,
	|
	|	FALSE                                                       AS RoundOff,
	|
	|	T.Stage                           AS Stage,
	|	T.OperationParent               AS OperationParent,
	|
	|	T.MethodOfReceivingMaterial       AS MethodOfReceivingMaterial,
	|	T.WithAssignment                    AS WithAssignment,
	|	T.SourceOfSemiFinishedProduct AS SourceOfSemiFinishedProduct,
	|	T.ProducedInProcess          AS ProducedInProcess,
	|
	|	VALUE(Catalog.ProductKitConfigurations.EmptyRef) AS ProductKit,
	|
	|	T.UseAutoselection
	|		AND NOT T.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|                                    AS SelectSoftware,
	|	T.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|		AND (T.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|			OR T.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|				AND &ItIsAvailableToStoreCompositionOfSetInSpecifications)
	|                                    AS SelectSpecifications,
	|	T.SelectReplacement                AS SelectReplacement
	|
	|INTO TTMaterialsAndServices
	|FROM
	|	&MaterialsAndServices AS T
	|
	|WHERE
	|	&RowFilter
	|";
	
	If RowsCountToProcess / Table.Count() <= 0.7 Then
		RowFilter = "
		|	(T.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
		|			AND T.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef))
		|	OR T.UseAutoselection
		|	OR T.ItemsType = VALUE(Enum.ItemsTypes.Set)
		|	OR T.SelectReplacement
		|";
	Else
		RowFilter = "TRUE";
	EndIf;
	QueryText = StrReplace(QueryText, "&RowFilter", RowFilter);
	
	QueriesTexts.Add(QueryText);
	DeleteTables.Add("TTMaterialsAndServices");
	
	//
	QueryText = "
	|SELECT
	|	TRUE                                          AS DataOfSets,
	|
	|	TTMaterialsAndServices.Id                AS Id,
	|	TTMaterialsAndServices.RowIndex                 AS RowIndex,
	|	Components.LineNumber                       AS LineNumber,
	|	TTMaterialsAndServices.ConnectionKey                    AS ConnectionKey,
	|
	|	Components.Products                      AS Products,
	|	Components.Characteristic                    AS Characteristic,
	|	Components.Products.ItemsType      AS ItemsType,
 	|	CASE 
	|		WHEN Components.Products.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
	|			THEN TRUE
	|		ELSE FALSE
	|	END                                           AS ItemVariantsAreUsed,
	|
	|	0                                               AS Count,
	|	Components.NumberOfPackages                AS NumberOfPackages,
	|	Components.Products.UnitOfMeasure     AS UnitOfMeasure,
	|	Components.Package                          AS Package,
	|	UNDEFINED                                    AS PackageData,
	|
	|	Components.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS PieceUnitOfMeasure,
	|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)                AS PackagingPiece,
	|
	// rounding:
	|	ISNULL(&RoundUpNumberOfUnitItems_
	|		AND Components.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
	|		AND Components.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|		AND &QueryTextMeasuredValueType IN (
	|			VALUE(Enum.TypesOfMeasuredValues.Weight),
	|			VALUE(Enum.TypesOfMeasuredValues.Length),
	|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
	|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)        AS RoundOff,
	|
	|	TTMaterialsAndServices.Stage                         AS Stage,
	|	TTMaterialsAndServices.OperationParent             AS OperationParent,
	|
	|	VALUE(Enum.MethodsOfReceivingBOMMaterials.Provide) AS MethodOfReceivingMaterial,
	|	TTMaterialsAndServices.WithAssignment                                              AS WithAssignment,
	|	VALUE(Catalog.BillsOfMaterials.EmptyRef)                     AS SourceOfSemiFinishedProduct,
	|	FALSE                                                                        AS ProducedInProcess,
	|
	|	Components.Ref                                                        AS ProductKit,
	|
	|	TRUE                               AS SelectSoftware,
	|	FALSE                                 AS SelectSpecifications,
	|	&PerformDirectiveSubstitutions          AS SelectReplacement
	|
	|INTO TTDataSets
	|FROM
	|	TTMaterialsAndServices AS TTMaterialsAndServices
	|
	|		LEFT JOIN Catalog.ProductKitConfigurations.Goods AS Components
	|		ON TTMaterialsAndServices.Products = Components.Ref.Owner
	|			AND TTMaterialsAndServices.Characteristic = Components.Ref.Characteristic
	|			AND (Components.Ref.Main)
	|
	|WHERE
	|	TTMaterialsAndServices.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|	AND &StorageOfCompositionOfSetIsAvailableInConfigurationOptions
	|	AND Components.Products.ItemsType IN 
	|		(VALUE(Enum.ItemsTypes.OwnGoods),
	|			VALUE(Enum.ItemsTypes.ReusablePackage),
	|			VALUE(Enum.ItemsTypes.Work_5))
	|";
	
	TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
		"MeasuredValueType",
		"Components.Package",
		"Components.Products");
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextMeasuredValueType",
		TextOfMeasuredValueTypeField);
		
	QueriesTexts.Add(QueryText);
	DeleteTables.Add("TTDataSets");
	TablesDataOfPackages.Add("TTDataSets");
	
	//
	QueryText = "
	|SELECT
	|	T.*,
	|	T.RowIndex AS TheIndexOfTheData
	|FROM
	|	TTMaterialsAndServices AS T
	|
	|UNION ALL
	|
	|SELECT
	|	T.*,
	|	NULL
	|FROM
	|	TTDataSets AS T
	|
	|";
	
	QueryText = StrReplace("
	|SELECT
	|	T.*,
	|
	|	TTProductData_.ReferenceOrder            AS ReferenceOrder,
	|	TTProductData_.Purpose              AS Purpose,
	|	TTProductData_.ProductionStart      AS ProductionStart,
	|	TTProductData_.ProductionDispatcherBusinessUnit  AS ProductionDispatcherBusinessUnit,
	|	TTProductData_.LineOfBusiness AS LineOfBusiness,
	|	TTProductData_.BillOfMaterials            AS BillOfMaterials,
	|	TTProductData_.Product                 AS Product,
	|	TTProductData_.ItemVariantOfProduct   AS ItemVariantOfProduct,
	|	TTProductData_.ProductSpecification     AS ProductSpecification,
	|	CASE
	|		WHEN TTProductData_.ProductSpecificationStage = VALUE(Catalog.ProductionStages.EmptyRef)
	|					AND TTProductData_.ProductSpecification = TTProductData_.BillOfMaterials
	|			THEN T.Stage
	|		ELSE TTProductData_.ProductSpecificationStage
	|	END                                          AS ProductSpecificationStage,
	|
	|	RECORDAUTONUMBER()                              AS RowKey,
	|
	|	&Presentations,
	|	CASE
	|		WHEN TTProductData_.AssigneeBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef)
	|			THEN T.Stage.Department
	|		ELSE TTProductData_.AssigneeBusinessUnit
	|	END                                          AS AssigneeBusinessUnit,
	|	T.Products.ProductKind                 AS ProductKind
	|
	|INTO TTListOfProducts
	|FROM
	|	&Table AS T
	|
	|	LEFT JOIN TTProductData_ AS TTProductData_
	|	ON T.Id = TTProductData_.Id
	|
	|", "&Table", "("+QueryText+")");
	
	PresentationText = "";
	If SelectionParameters.GetPresentations Then
		PresentationText = "
		|	CASE
		|		WHEN T.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|			THEN ISNULL(T.Package.Presentation, """")
		|		ELSE ISNULL(T.Products.UnitOfMeasure.Presentation, """")
		|	END                                          AS Ed,
		|	ISNULL(T.Products.Presentation, """")   AS ProductsPresentation,
		|	ISNULL(T.Characteristic.Presentation, """") AS CharacteristicPresentation,
		|";
	EndIf;
	QueryText = StrReplace(QueryText, "&Presentations,", PresentationText);
	
	QueriesTexts.Add(QueryText);
	DeleteTables.Add("TTListOfProducts");
	
	// Selection of specifications
	BOMSelectionParameters = ProductDataManagementClientServer.ParametersForSelectingSpecificationsForManufacturingAssembly();
	
	SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	SpecificationRequestParameters.OutputTableName         = "TTSpecifications";
	SpecificationRequestParameters.PriorityOnly         = True;
	SpecificationRequestParameters.FinalPackageSeparator = False;
	SpecificationRequestParameters.ConditionsForSelectingIncomingData.Add("TTListOfProducts.SelectSpecifications = TRUE");
	
	QueriesTexts.Add(ProductDataManagement.RequestTextForProductItemsSpecifications(
															SpecificationRequestParameters,
															BOMSelectionParameters));
	DeleteTables.Add("TTSpecifications");
	
	// Selection of directive replacements
	QueryText = "
	|SELECT
	|	0            AS RowKey
	|WHERE
	|	FALSE
	|";
	If SelectReplacements Then
		
		QueryText = "
		|SELECT
		|	T.RowKey                               AS Ref,
		|
		|	T.Products                             AS Products,
		|	T.Characteristic                           AS Characteristic,
		|
		|	CASE
		|		WHEN T.ProductionStart = DATETIME(1, 1, 1)
		|				AND &DynamicStructureOfProductionOrders
		|				AND VALUETYPE(T.ReferenceOrder) = TYPE(Document.ProductionOrder2_2)
		|			THEN ISNULL(ProductionOrders.EarliestStartDate, DATETIME(1, 1, 1))
		|		ELSE T.ProductionStart
		|	END                                      AS PermissionValidityDate,
		|	T.ReferenceOrder                             AS ProductionOrder,
		|	UNDEFINED                               AS SalesOrder,
		|	T.ProductSpecificationStage.Department    AS Department,
		|	T.LineOfBusiness                  AS LineOfBusiness,
		|	T.Product                                  AS Product,
		|	T.ItemVariantOfProduct                    AS ItemVariantOfProduct,
		|	T.ProductSpecification                      AS BillOfMaterials,
		|	T.ProductSpecificationStage                  AS Stage
		|
		|INTO TTDirectiveSubstitutionsSource
		|FROM
		|	TTListOfProducts AS T
		|		LEFT JOIN Document.ProductionOrder2_2 AS ProductionOrders
		|		ON T.ReferenceOrder = ProductionOrders.Ref
		|
		|";
		
		QueriesTexts.Add(QueryText);
		DeleteTables.Add("TTDirectiveSubstitutionsSource");
		
		MatchingMatchingFields = New Map;
		MatchingMatchingFields.Insert("ReplacementPriority", "InstructionsForReplacement");
		
		ParametersForSelectingAnalogs = New Structure;
		ParametersForSelectingAnalogs.Insert("GoodsTogetherWithParameters",         True);
		ParametersForSelectingAnalogs.Insert("ConsiderManyToMany",             False);
		ParametersForSelectingAnalogs.Insert("ToSelectInterchangeableAnalogues", False);
		ParametersForSelectingAnalogs.Insert("SelectionOfPermissions",                  MatchingMatchingFields);
		ParametersForSelectingAnalogs.Insert("NameOfTemporaryGoodsTable",        "TTDirectiveSubstitutionsSource");
		ParametersForSelectingAnalogs.Insert("TempTableName",              "TTDirectiveSubstitutions");
		ParametersForSelectingAnalogs.Insert("DeleteTemporaryTables",          True);
		
		QueriesTexts.Add(AlternativeMaterials.QueryTextDirectiveSubstitutions(ParametersForSelectingAnalogs));
		
		QueryText = "
		|SELECT
		|	Substitutions_3.*,
		|	Substitutions_3.Ref                                AS RowKey,
		|	Substitutions_3.Products.ItemsType          AS ItemsType,
		|	Substitutions_3.Products.UnitOfMeasure         AS UnitOfMeasure,
		|	UNDEFINED                                 AS PackageData,
		|	Substitutions_3.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)   AS PieceUnitOfMeasure,
		|	ISNULL(&QueryTextMeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE)           AS PackagingPiece,
	 	|	CASE 
		|		WHEN Substitutions_3.Products.UseVariants IN (
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
		|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind),
		|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems))
		|			THEN TRUE
		|		ELSE FALSE
		|	END                                                                       AS ItemVariantsAreUsed,
		|	ISNULL(&RoundUpNumberOfUnitItems_
		|		AND Substitutions_3.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces)
		|		AND Substitutions_3.Package <> VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
		|		AND &QueryTextMeasuredValueType IN (
		|			VALUE(Enum.TypesOfMeasuredValues.Weight),
		|			VALUE(Enum.TypesOfMeasuredValues.Length),
		|			VALUE(Enum.TypesOfMeasuredValues.VolumeM3),
		|			VALUE(Enum.TypesOfMeasuredValues.AreaTypeOfMeasurement)), FALSE)        AS RoundOff
		|FROM
		|	TTDirectiveSubstitutions AS Substitutions_3
		|
		|ORDER BY
		|	Substitutions_3.ScopeMaxPriority DESC,
		|	Substitutions_3.Period DESC,
		|	Substitutions_3.Resolution DESC";
		
		TextOfMeasuredValueTypeField = Catalogs.PackagesAndUnitsOfMeasure.RequestTextValueOfUnitDetails(
			"MeasuredValueType",
			"Substitutions_3.Package",
			"Substitutions_3.Products");
		
		QueryText = StrReplace(
			QueryText, 
			"&QueryTextMeasuredValueType",
			TextOfMeasuredValueTypeField);
		
		DeleteTables.Add("TTDirectiveSubstitutions");
		TablesDataOfPackages.Add("TTDirectiveSubstitutions");
		
	EndIf;
	QueriesTexts.Add(QueryText);
	
	// Package data
	QueriesTexts.Add(ProductDataManagement.QueryTextPackageData_(TablesDataOfPackages));
	
	// Priority specifications
	QueryText = "
	|SELECT
	|	T.RowIndex              AS RowIndex,
	|	T.SelectSpecifications     AS SelectSpecifications,
	|
	|	T.ProductionStart        AS ProductionStart,
	|	T.ReferenceOrder              AS ReferenceOrder,
	|	T.LineOfBusiness   AS LineOfBusiness,
	|	T.ProductionDispatcherBusinessUnit    AS ProductionDispatcherBusinessUnit,
	|	T.AssigneeBusinessUnit  AS AssigneeBusinessUnit,
	|	T.BillOfMaterials              AS SpecificationOwner,
	|	TTSpecifications.BillOfMaterials AS BillOfMaterials,
	|
	|	T.Product                   AS Product,
	|	T.ItemVariantOfProduct     AS ItemVariantOfProduct,
	|	T.ProductSpecification       AS ProductSpecification,
	|	T.ProductSpecificationStage   AS ProductSpecificationStage
	|
	|FROM
	|	TTListOfProducts AS T
	|
	|		LEFT JOIN TTSpecifications AS TTSpecifications
	|		ON T.TheIndexOfTheData = TTSpecifications.TheIndexOfTheData
	|
	|WHERE
	|	T.SelectSpecifications
	|		AND NOT TTSpecifications.BillOfMaterials IS NULL
	|	OR T.ItemsType = VALUE(Enum.ItemsTypes.Set)
	|		AND &ItIsAvailableToStoreCompositionOfSetInSpecifications
	|
	|ORDER BY
	|	T.RowIndex,
	|	T.LineNumber
	|";
	QueriesTexts.Add(QueryText);
	
	// Materials for processing: software, data sets, replacements
	QueryText = "
	|SELECT
	|	T.*,
	|	UNDEFINED                 AS PackageData,
	|	&TextFieldOrderToWarehouse    AS OrderToWarehouse,
	|	&WarehouseTextField              AS Warehouse,
	|	&TextFieldSoftwareOption AS SupplyOption,
	|	&TextFieldIsSeparate        AS WithAssignment,
	|	&ScheduleTextField      AS ToPlan
	|FROM
	|	TTListOfProducts AS T
	|
			// A request is inserted here to receive a warehouse, a security option
	|		,ConnectionTextSoftwareParameters
	|
	|		LEFT JOIN Catalog.Warehouses AS CatWarehouses
	|		ON &WarehouseTextField = CatWarehouses.Ref
	|
	|		,TextConnectionsWaysToEnsure
	|
	|		,TextCanBeOrderedToWarehouse
	|
	|WHERE
	|	T.SelectSoftware
	|	OR T.SelectReplacement
	|
	|ORDER BY
	|	T.DataOfSets,
	|	T.RowIndex,
	|	T.LineNumber
	|";
	
	ScheduleTextField = "FALSE";
	TextConnectionsWaysToEnsure = "";
	If SelectionParameters.CalculateScheduleProductionAttribute Then
		ScheduleTextField = TextOfScheduleFieldSubstitution(
			"T.ProductionDispatcherBusinessUnit",
			"T.Products",
			"VALUE(Catalog.BillsOfMaterials.EmptyRef)");
		TextConnectionsWaysToEnsure = InformationRegisters.SupplySchemes.SubstituteConnectionToGetSecurityMethod(
			"LEFT JOIN Catalog.ProcurementStrategies AS CatSupplyMethod
			|	ON &MainSupplyMethodSubstitution",
			"MainSupplyMethodSubstitution",
			"T.Products, T.Characteristic, CatWarehouses.Ref");
	EndIf;
	QueryText = StrReplace(QueryText, "&ScheduleTextField"            , ScheduleTextField);
	QueryText = StrReplace(QueryText, ",TextConnectionsWaysToEnsure",  TextConnectionsWaysToEnsure);
	
	OrderToWarehouseField = ParametersForSubstitutingOrderToWarehouseField("T",, SelectionParameters.SoftwareFillingOption);
	
	QueryText = StrReplace(QueryText, "&TextFieldOrderToWarehouse"      , OrderToWarehouseField.FieldText);
	QueryText = StrReplace(QueryText, ",TextCanBeOrderedToWarehouse", OrderToWarehouseField.JoinText);
	
	ProductionSupply.PerformSubstitutionOfMaterialSupportParameters(QueryText,
		"T",,
		"AssigneeBusinessUnit",
		SelectionParameters.SoftwareFillingOption);
	
	QueryText = StrReplace(QueryText, "&ReferenceOrder", "T.ReferenceOrder");
	QueryText = StrReplace(QueryText, "&Purpose",   "T.Purpose");
	
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	ItIsAvailableToStoreCompositionOfSetInSpecifications = ProductDataManagementCached.ItIsAvailableToStoreCompositionOfSetInSpecifications();
	Query.SetParameter("ItIsAvailableToStoreCompositionOfSetInSpecifications", ItIsAvailableToStoreCompositionOfSetInSpecifications);
	StorageOfCompositionOfSetIsAvailableInConfigurationOptions = ProductDataManagementCached.StorageOfCompositionOfSetIsAvailableInConfigurationOptions();
	Query.SetParameter("StorageOfCompositionOfSetIsAvailableInConfigurationOptions", StorageOfCompositionOfSetIsAvailableInConfigurationOptions);
	
	Query.SetParameter("MaterialsAndServices", Table);
	
	PerformDirectiveSubstitutions = False;
	PerformDirectiveSubstitutions = SelectionParameters.PerformDirectiveSubstitutions;
	Query.SetParameter("PerformDirectiveSubstitutions", PerformDirectiveSubstitutions);
	
	Query.Text = QueryText;
	
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(
		Query,
		BOMSelectionParameters);
	
	SetPrivilegedMode(True);
	QueryResults = Query.ExecuteBatch();
	SetPrivilegedMode(False);
	
	DataForReplacement              = QueryResults[QueryResults.Count()-4].Unload();
	PackageData_           = QueryResults[QueryResults.Count()-3].Unload();
	Specifications             = QueryResults[QueryResults.Count()-2].Unload();
	MaterialsForProcessing      = QueryResults[QueryResults.Count()-1].Unload();
	
	ProductDataManagement.FillInPackingDataInDataset(DataForReplacement, PackageData_);
	ProductDataManagement.FillInPackingDataInDataset(MaterialsForProcessing, PackageData_);
	
	DataOfSets = Table.CopyColumns(DetailsOfSetCompositionLine("Shopping", SelectionParameters));
	DataOfSets.Columns.Add("ProductKit");
	
	For Each String In MaterialsForProcessing Do
		RowData = Table[String.RowIndex];
		If String.DataOfSets Then
			RowData = DataOfSets.Add();
			FillPropertyValues(RowData, String);
			RowData.BillOfMaterials                     = Catalogs.BillsOfMaterials.EmptyRef();
			RowData.MethodOfProductsAutoselection     = Enums.MethodsOfProductAutoSelection.SpecifiedInMasterData;
			RowData.MethodOfItemVariantAutoselection   = Enums.MethodsOfItemVariantAutoselection.SpecifiedInMasterData;
			RowData.QuantityCalculationAlgorithm        = "";
			RowData.UseAutoselection            = False;
			RowData.AutoselectionDetails               = "";
			RowData.ItemVariantAutoSelectionAlgorithm = "";
			RowData.Produced                     = False;
			RowData.ProducedInProcess            = False;
		ElsIf String.SelectSoftware Then
			FillPropertyValues(RowData, String, "Warehouse,SupplyOption,WithAssignment,ToPlan,OrderToWarehouse");
		EndIf;
		If String.SelectReplacement Then
			ReplacementData = ProductDataManagement.ReplacementDataForDatasetRow(String, DataForReplacement, "RowKey");
			If ReplacementData <> Undefined Then
				FillPropertyValues(RowData, ReplacementData);
			EndIf;
		EndIf;
	EndDo;
	
	If DataOfSets.Count() > 0 Then
		ApplySelectionBasedOnDataSelectionParameters(DataOfSets, SelectionParameters);
		DataOfSets.Indexes.Add("Id");
		Tables.Insert("DataOfTradingSets", DataOfSets);
	EndIf;
	TechnologicalKits = ItemList();
	TechnologicalKits.Columns.Add("RowOwner");
	TechnologicalKits.Columns.Add("SpecificationOwner", New TypeDescription("CatalogRef.BillsOfMaterials"));
	For Each String In Specifications Do
		
		StringMaterial = Table[String.RowIndex];
		
		If String.SelectSpecifications
				And Not ValueIsFilled(StringMaterial.PermissionToReplace) Then
			StringMaterial.BillOfMaterials                   = String.BillOfMaterials;
			StringMaterial.SourceOfSemiFinishedProduct = String.BillOfMaterials;
		EndIf;
		
		If StringMaterial.ItemsType = Enums.ItemsTypes.Set
				And ItIsAvailableToStoreCompositionOfSetInSpecifications
				And SelectionParameters.GetDataSets
				And ValueIsFilled(StringMaterial.BillOfMaterials) Then
			NewRow = TechnologicalKits.Add();
			NewRow.RowOwner = StringMaterial;
			FillPropertyValues(NewRow, String);
			FillPropertyValues(NewRow, StringMaterial, "Products,Characteristic,BillOfMaterials");
			If Not ValueIsFilled(NewRow.ProductSpecificationStage)
				And String.SpecificationOwner = String.ProductSpecification Then
				NewRow.ProductSpecificationStage = StringMaterial.Stage;
			EndIf;
		EndIf;
		
	EndDo;
	
	GetDataOfTechnologicalSets(TechnologicalKits, Tables, SelectionParameters);
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager, StrConcat(DeleteTables, ","));
		
	Table.Columns.Delete("RowIndex");
		
EndProcedure
		
Procedure FillInParametersForProvidingOutputProducts(Query, Tables, SelectionParameters)
	
	RequestSeparatorInPacket = Common.QueryBatchSeparator();
	
	NamesOfDataSets = New Array;
	TextsOfAssociation  = New Array;
	
	QueryText = "";

	For Each DataSetName In StrSplit("ManufacturedProducts,RecyclableWaste",",") Do
		
		Table = Undefined;
		If Tables.Property(DataSetName, Table) And Table.Find(True,"UseAutoselection") <> Undefined Then
			
			QueryText = QueryText + "
			|SELECT
			|	""TableName""   AS DataSetName,
			|	T.Id  AS Id,
			|	T.LineNumber    AS LineNumber,
			|
			|	T.Products   AS Products,
			|	T.Characteristic AS Characteristic,
			|
			|	T.Stage           AS Stage
			|
			|INTO TableName
			|FROM
			|	&TableName AS T
			|
			|WHERE
			|	T.UseAutoselection
			|" + RequestSeparatorInPacket;
			
			QueryText = StrReplace(QueryText, "TableName", DataSetName);
			
			Query.SetParameter(DataSetName, Table);
			
			TextsOfAssociation.Add(StrReplace("SELECT T.* FROM DataSetName AS T", "DataSetName", DataSetName));
			
			NamesOfDataSets.Add(DataSetName);
			
		EndIf;
		
	EndDo;
	
	If NamesOfDataSets.Count() = 0 Then
		Return;
	EndIf;
	
	QueryText = QueryText + "
	|SELECT
	|	T.*,
	|	&WarehouseTextField AS Warehouse
	|
	|FROM &TableName AS T
	|
	|	,ConnectionTextContentTransferSettings
	|
	|ORDER BY
	|	T.DataSetName,
	|	T.Id,
	|	T.LineNumber
	|";
	QueryText = StrReplace(QueryText, "&TableName", "("+StrConcat(TextsOfAssociation," UNION ALL ")+")");
	
	RequestTextForGettingWarehouse = ProductionSupply.RequestTextForContentTransferSettings(
		"T",
		"Stage.Department",
		SelectionParameters.SoftwareFillingOption);
		
	QueryText = StrReplace(
						QueryText, 
						",ConnectionTextContentTransferSettings",
						RequestTextForGettingWarehouse.JoinText);
		
	QueryText = StrReplace(
						QueryText, 
						"&WarehouseTextField",
						RequestTextForGettingWarehouse.WarehouseTextField);
	
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	ResultProvision = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	ResultProvision.Indexes.Add("DataSetName,Id,LineNumber");
	
	Filter = New Structure("DataSetName,Id,LineNumber");
	For Each DataSetName In NamesOfDataSets Do
		For Each String In Tables[DataSetName] Do
			If String.UseAutoselection Then
				Filter.DataSetName = DataSetName;
				FillPropertyValues(Filter, String, "Id,LineNumber");
				
				ResultLines      = ResultProvision.FindRows(Filter);
				If ResultLines <> Undefined Then
					String.Warehouse = ResultLines[0].Warehouse;
				EndIf;
			EndIf;
		EndDo;
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
		StrConcat(NamesOfDataSets,","));
	
EndProcedure

Procedure FillInParametersOfWorkBeingPerformed(Query, Tables, SelectionParameters)
	
	Table = Undefined; // ValueTable
	If Not Tables.Property("WorksToPerform", Table) Then
		Return;
	EndIf;
	
	ProductDataManagement.FillInPackingDataInDataset(
		Table,
		Tables.PackageData_);
	
	Table.Columns.Add("TheIndexOfTheData", New TypeDescription("Number"));
	
	RowsCountToProcess = 0;
	For TheIndexOfTheData = 0 To Table.Count() - 1 Do
		String = Table[TheIndexOfTheData];
		String.TheIndexOfTheData = TheIndexOfTheData;
		If String.ProducedInProcess
			And String.BillOfMaterials.IsEmpty() Then
			RowsCountToProcess = RowsCountToProcess + 1;
		EndIf;
	EndDo;
	
	If RowsCountToProcess = 0 Then
		Return;
	EndIf;
	
	QueriesTexts = New Array;
	
	//
	QueryText = "
	|SELECT
	|	T.Id     AS Id,
	|	T.TheIndexOfTheData      AS TheIndexOfTheData,
	|	0                   AS LineNumber,
	|	T.ConnectionKey         AS ConnectionKey,
	|
	|	T.Products                        AS Products,
	|	T.Characteristic                      AS Characteristic,
	|	T.UnderRepairProduct    AS UnderRepairProduct,
	|	T.UnderRepairVariant  AS UnderRepairVariant
	|
	|INTO WorkTTIsBeingCarriedOut
	|FROM
	|	&WorksToPerform AS T
	|
	|WHERE
	|	T.ProducedInProcess
	|		AND T.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|";
	
	QueriesTexts.Add(QueryText);
	
	//
	QueryText = "
	|SELECT
	|	T.*,
	|	T.Products.ProductKind                   AS ProductKind,
	|	TTProductData_.ReferenceOrder              AS ReferenceOrder,
	|	TTProductData_.ProductionStart        AS ProductionStart,
	|	TTProductData_.ProductionDispatcherBusinessUnit    AS ProductionDispatcherBusinessUnit,
	|	TTProductData_.LineOfBusiness   AS LineOfBusiness
	|
	|INTO TTListOfProducts
	|FROM WorkTTIsBeingCarriedOut AS T
	|
	|	INNER JOIN TTProductData_ AS TTProductData_
	|	ON T.Id = TTProductData_.Id
	|";
	
	QueriesTexts.Add(QueryText);
	
	//
	BOMSelectionParameters = ProductDataManagementClientServer.BOMSelectionParameters();
	BOMSelectionParameters.AvailableStatuses.Add(Enums.BOMStatuses.Valid);
	BOMSelectionParameters.AvailableTypes.Add(Enums.ProductionProcessTypes.PerformRM);
	
	SpecificationRequestParameters = ProductDataManagement.ParametersOfRequestTextForManufacturedProductSpecifications();
	SpecificationRequestParameters.OutputTableName         = "TTSpecifications";
	SpecificationRequestParameters.PriorityOnly         = True;
	SpecificationRequestParameters.FinalPackageSeparator = False;
	
	QueriesTexts.Add(ProductDataManagement.RequestTextForProductItemsSpecifications(
		SpecificationRequestParameters,
		BOMSelectionParameters));
	
	//
	QueryText = "
	|SELECT
	|	T.TheIndexOfTheData                  AS TheIndexOfTheData,
	|	TTSpecifications.BillOfMaterials     AS BillOfMaterials
	|
	|FROM
	|	TTListOfProducts AS T
	|
	|		INNER JOIN TTSpecifications AS TTSpecifications
	|		ON T.TheIndexOfTheData = TTSpecifications.TheIndexOfTheData
	|
	|ORDER BY
	|	T.TheIndexOfTheData
	|";
	QueriesTexts.Add(QueryText);
	
	Query.SetParameter("WorksToPerform", Table);
	Query.Text = StrConcat(QueriesTexts, Common.QueryBatchSeparator());;
	
	ProductDataManagement.SetParametersForRequestManufacturedProductSpecifications(
		Query,
		BOMSelectionParameters);
	
	SetPrivilegedMode(True);
	Selection = Query.Execute().Select();
	SetPrivilegedMode(False);
	
	While Selection.Next() Do
		
		Table[Selection.TheIndexOfTheData].BillOfMaterials = Selection.BillOfMaterials;
		
	EndDo;
	
	TMCommonUse.DestroyTemporaryTables(Query.TempTablesManager,
		"WorkTTIsBeingCarriedOut,TTListOfProducts");
	
EndProcedure

// Prepares the table of operations of the specification
// 
// Parameters:
// 	Operations - ValueTable
//
Procedure PrepareTableOfOperations(Operations)
	
	OperationTable       = Catalogs.ManufacturingOperations.OperationTableConstructor();
	
	IDLength   = Catalogs.ManufacturingOperations.LengthOfOperationID();
	FilterOperationParent = New Structure("OperationParent");
	FilterStageOperations    = New Structure("Stage");
	ArrayOfStages          = New Array;
	
	Operations.Indexes.Add("OperationParent");
	Operations.Indexes.Add("Stage");
	
	For IndexOf = 0 To Operations.Count() - 1 Do
		
		LineOperation = Operations[IndexOf];
		
		LineOperation.ConnectionKey = New UUID;
		
		If LineOperation.ContainsTechnologicalProcess Then
			FilterOperationParent.OperationParent = LineOperation.Operation;
			FoundRows = Operations.FindRows(FilterOperationParent);
			For Each TPOperation In FoundRows Do
				TPOperation.ParentCommunicationKey = LineOperation.ConnectionKey;
			EndDo;
		EndIf;
		
		If ValueIsFilled(LineOperation.OperationParent) Then
			LineOperation.OperationID = LineOperation.OperationParentID * Pow(10, IDLength);
		EndIf;
		LineOperation.OperationID = LineOperation.OperationID + LineOperation.OperationID_;
		
		ArrayOfStages.Add(LineOperation.Stage);
		
	EndDo;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfStages);
	
	For Each Stage In ArrayOfStages Do
		
		FilterStageOperations.Stage = Stage;
		StageOperations = Operations.Copy(FilterStageOperations);
		
		Catalogs.ManufacturingOperations.FillInOrderOfOperations(StageOperations);
		
		For Each LineOperation In StageOperations Do
			FillPropertyValues(OperationTable.Add(), LineOperation);
		EndDo;
		
	EndDo;
	
	Operations = OperationTable;
	
EndProcedure

// Determines whether a row belongs of operation
// 
// Parameters:
//  OperationData - ValueTableRow
//  LineOfStandard - ValueTableRow
//  ThisProduct - Boolean - This Product
// 
// Returns:
//  Boolean - The Data Line Of the Bill of Materials Belongs To The Operation
Function DataLineOfBillOfMaterialsBelongsToOperation(OperationData, LineOfStandard, ThisProduct = False) Export
	
	Return (OperationData.Operation = LineOfStandard.Operation
				And (ThisProduct
					Or OperationData.OperationParent = LineOfStandard.OperationParent))
			Or (ThisProduct
				And OperationData.SourceNumberOfNextOperation = 0
				And OperationData.OperationParent = LineOfStandard.Operation)
			Or (Not ThisProduct
				And OperationData.OriginalOperationNumber = 1
				And OperationData.OperationParent = LineOfStandard.Operation);
	
EndFunction

// Fills in information about the use of the material
// 
// Parameters:
// 	MaterialsAndServices - ValueTable - table of materials
// 	SelectionParameters - See DataSamplingParameters
Procedure FillInInformationOnUseOfMaterial(MaterialsAndServices, SelectionParameters)
	
	If SelectionParameters.GetPresentations Then
		
		MaterialsAndServices.Columns.Add("ApplyingTheMaterialEditing");
		
		For Each String In MaterialsAndServices Do
			
			ProductDataManagementClientServer.FillInInformationOnUseOfMaterial(String);
			
		EndDo;
		
	EndIf;
	
EndProcedure

Procedure ProcessProcessData(SpecificationData)
	
	NameOfOperandSource = "MaterialsAndServices";
	
	OperandReplacementTable_ = New ValueTable();
	OperandReplacementTable_.Columns.Add("OperationParent");
	OperandReplacementTable_.Columns.Add("OperandOld");
	OperandReplacementTable_.Columns.Add("NewLineNumber_");
	
	FilterStructure1 = New Structure("OperationParent,OperandOld");
	
	For Each TableName In StrSplit("MaterialsAndServices,LaborCosts", ",") Do
		
		Table = Undefined; // ValueTable
		If Not SpecificationData.Property(TableName, Table) Then
			Return;
		EndIf;
		
		NewLineNumber_ = 0;
		
		For IndexOf = 0 To Table.Count() - 1 Do
			
			String = Table[IndexOf];
			
			If Not String.Auxiliary Then
				NewLineNumber_ = String.LineNumber;
				Continue;
			EndIf;
			
			LineNumberCur = String.LineNumber;
			NewLineNumber_   = NewLineNumber_ + 1;
			
			If TableName = NameOfOperandSource Then
				NewRow = OperandReplacementTable_.Add();
				NewRow.OperationParent = String.OperationParent;
				NewRow.OperandOld    = StrTemplate("%1[%2].", NameOfOperandSource, Format(LineNumberCur,"NZ=; NG="));
				NewRow.NewLineNumber_ = Format(NewLineNumber_,"NZ=; NG=");
			EndIf;
			
			ReplaceOperandsInRowOfDatasetByTable(String, NameOfOperandSource, OperandReplacementTable_, FilterStructure1);
			
			String.LineNumber = NewLineNumber_;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure ReplaceOperandsInRowOfDatasetByTable(String, NameOfOperandSource, OperandReplacementTable_, FilterStructure1)
	
	If IsBlankString(String.QuantityCalculationAlgorithm) Then
		Return;
	EndIf;
	
	Operands = New Array;
	
	OpeningMarker = StrFind(String.QuantityCalculationAlgorithm, NameOfOperandSource,,1);
	While OpeningMarker > 0 Do
		ClosingMarker = StrFind(String.QuantityCalculationAlgorithm, "].",,OpeningMarker);
		If ClosingMarker > 0 Then
			Operand = Mid(String.QuantityCalculationAlgorithm, OpeningMarker, ClosingMarker-OpeningMarker+2);
			If Operands.Find(Operand) = Undefined Then
				Operands.Add(Operand);
			EndIf;
		EndIf;
		OpeningMarker = StrFind(String.QuantityCalculationAlgorithm, NameOfOperandSource,,ClosingMarker);
	EndDo;
	
	FillPropertyValues(FilterStructure1, String);
	For Each Operand In Operands Do
		FilterStructure1.OperandOld = Operand;
		FoundRows = OperandReplacementTable_.FindRows(FilterStructure1);
		If FoundRows.UBound() <> -1 Then
			ReplacementNumber = FoundRows[0].NewLineNumber_;
		Else
			ReplacementNumber = "0";
		EndIf;
		String.QuantityCalculationAlgorithm = StrReplace(
			String.QuantityCalculationAlgorithm, Operand, StrTemplate("%1_[%2].", NameOfOperandSource, ReplacementNumber));
	EndDo;
	
	String.QuantityCalculationAlgorithm = StrReplace(
		String.QuantityCalculationAlgorithm, NameOfOperandSource+"_", NameOfOperandSource);
	
EndProcedure

Procedure ApplySelectionBasedOnSpecificationData(SpecificationData, Filter, SelectionParameters = Undefined) Export
	
	If TypeOf(Filter) <> Type("Structure") Then
		Return;
	EndIf;
	
	If SelectionParameters = Undefined Then
		TablesNames = ListOfSpecificationData();
	Else
		TablesNames = Common.CopyRecursive(SelectionParameters.ListOfData);
	EndIf;
	
	TablesNames.Add("MaterialsAndWorksSets");
	
	For Each TableName In TablesNames Do
		Table = Undefined; // ValueTable
		If SpecificationData.Property(TableName, Table) Then
			SpecificationData.Insert(TableName, Table.Copy(Filter));
		EndIf;
	EndDo;
	
EndProcedure

Function AddSemiFinishedProductData(
	SpecificationDataSummary, ItemList, SelectionParameters, UnearthedSpecifications, ToExcludeSemiFinishedProducts = False)
	
	ListOfData = SelectionParameters.ListOfData;
	
	ListOfProductsNew = ItemList();
	
	SpecificationsData = SpecificationDataByProductsList(ItemList, SelectionParameters);
	
	For IndexOf = 0 To SpecificationsData.UBound() Do
		
		SpecificationData = SpecificationsData[IndexOf];
		
		If SpecificationData = Undefined Then
			Continue;
		EndIf;
		
		If ToExcludeSemiFinishedProducts Then
			Catalogs.BillsOfMaterials.ExcludeIntermediateRelease(SpecificationData);
		EndIf;
		
		UnearthedSpecifications.Insert(SpecificationData.BillOfMaterials);
		
		If ListOfData.Find("AlternateWorkCenterTypes") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.AlternateWorkCenterTypes, SpecificationDataSummary.AlternateWorkCenterTypes);
		EndIf;
		
		If ListOfData.Find("WorkCenterTypes") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.WorkCenterTypes, SpecificationDataSummary.WorkCenterTypes);
		EndIf;
		
		If ListOfData.Find("ManufacturedProducts") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.ManufacturedProducts, SpecificationDataSummary.ManufacturedProducts);
		EndIf;
		
		If ListOfData.Find("RecyclableWaste") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.RecyclableWaste, SpecificationDataSummary.RecyclableWaste);
		EndIf;
		
		If ListOfData.Find("MaterialsAndServices") <> Undefined Then
			
			CommonClientServer.SupplementTable(SpecificationData.MaterialsAndServices, SpecificationDataSummary.MaterialsAndServices);
			
			For Each String In SpecificationData.MaterialsAndServices Do
				
				If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials
					And UnearthedSpecifications.Get(String.SourceOfSemiFinishedProduct) = Undefined Then
					
					NewRow = ListOfProductsNew.Add();
					FillPropertyValues(NewRow, String, "Products, Characteristic, Count, DaysFromDemand");
					FillPropertyValues(NewRow, ItemList[IndexOf], "ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness");
					NewRow.BillOfMaterials = String.SourceOfSemiFinishedProduct;
					
				EndIf;
				
				If String.MethodOfReceivingMaterial = Enums.MethodsOfReceivingBOMMaterials.ProducedOnStage
					And ValueIsFilled(String.BillOfMaterialsRM)
					And UnearthedSpecifications.Get(String.BillOfMaterialsRM) = Undefined Then
				
					NewRow = ListOfProductsNew.Add();
					FillPropertyValues(NewRow, String, "Products, Characteristic, Count, DaysFromDemand");
					FillPropertyValues(NewRow, ItemList[IndexOf], "ProductionStart, ProductionDispatcherBusinessUnit, LineOfBusiness");
					NewRow.BillOfMaterials = String.BillOfMaterialsRM;
				
				EndIf;
				
			EndDo;
			
		EndIf;
		
		If ListOfData.Find("LaborCosts") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.LaborCosts, SpecificationDataSummary.LaborCosts);
		EndIf;
		
		If ListOfData.Find("Stages") <> Undefined Then
			CommonClientServer.SupplementTable(SpecificationData.Stages, SpecificationDataSummary.Stages);
		EndIf;
		
	EndDo;
	
	Return ListOfProductsNew;
	
EndFunction

#EndRegion

#EndRegion

#Region ListOfResourceSpecifications

Function RequestTextForDynamicListOfResourceSpecifications() Export
	
	QueryText =
	"SELECT ALLOWED
	|	CatalogBillsOfMaterials.Ref AS Ref,
	|
	|	CatalogBillsOfMaterials.Code AS Code,
	|	CatalogBillsOfMaterials.Description AS Description,
	|
	|	CatalogBillsOfMaterials.Status AS Status,
	|	CatalogBillsOfMaterials.ProductionProcessType AS ProductionProcessType,
	|
	|	CatalogBillsOfMaterials.ValidOnDate AS ValidOnDate,
	|	CatalogBillsOfMaterials.ValidToDate AS ValidToDate,
	|
	|	CatalogBillsOfMaterials.EmployeeResponsible AS EmployeeResponsible,
	|	CatalogBillsOfMaterials.LongDesc AS LongDesc,
	|
	|	CASE
	|		WHEN CatalogBillsOfMaterials.AssignmentOption = VALUE(Enum.BillOfMaterialsAssignmentOptions.ProductKind)
	|			THEN CatalogBillsOfMaterials.MainProductProductKind
	|		ELSE CatalogBillsOfMaterials.MainProductProducts
	|	END AS MainProduct
	|
	|FROM
	|	Catalog.BillsOfMaterials AS CatalogBillsOfMaterials
	|	
	|";
	
	Return QueryText;
	
EndFunction

// Conditional design of the list of resource specifications
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional design
// 	NameOfOwnerOfSelectionFields - String - element name
Procedure SetConditionalAppearanceOfListOfResourceSpecifications(ConditionalAppearance, NameOfOwnerOfSelectionFields = "") Export

	OwnerOfSelectionFields = ?(NameOfOwnerOfSelectionFields = "", "", NameOfOwnerOfSelectionFields + ".");
	
	// Design of the specification in development
	Item = ConditionalAppearance.Items.Add();

	If NameOfOwnerOfSelectionFields <> "" Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfOwnerOfSelectionFields);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(OwnerOfSelectionFields + "Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BOMStatuses.UnderDevelopment;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Design of a closed specification
	Item = ConditionalAppearance.Items.Add();

	If NameOfOwnerOfSelectionFields <> "" Then
		ItemField = Item.Fields.Items.Add();
		ItemField.Field = New DataCompositionField(NameOfOwnerOfSelectionFields);
	EndIf;
	
	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField(OwnerOfSelectionFields + "Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BOMStatuses.Closed_;
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure

Function RequestTextForDynamicListOfAvailableSpecifications() Export
	
	QueryText = "
	|SELECT
	|	BillsOfMaterials.Ref         AS BillOfMaterials,
	|
	|	BillsOfMaterials.ValidOnDate AS ValidOnDate,
	|	BillsOfMaterials.ValidToDate  AS ValidToDate,
	|
	|	BillsOfMaterials.Status         AS Status,
	|
	|	FALSE                                 AS Priority_2
	|
	|FROM
	|	Catalog.BillsOfMaterials AS BillsOfMaterials
	|	
	|WHERE
	|	NOT BillsOfMaterials.DeletionMark
	|	AND BillsOfMaterials.Ref IN (&BOMList)
	|";
	
	Return QueryText;
	
EndFunction

// Conditional design of the list of available specifications
// 
// Parameters:
// 	ConditionalAppearance - DataCompositionConditionalAppearance - conditional design
Procedure SetConditionalAppearanceOfListOfAvailableSpecifications(ConditionalAppearance) Export

	// Design of the specification in development
	Item = ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	ItemFilter.LeftValue  = New DataCompositionField("Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BOMStatuses.UnderDevelopment;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.NoteText);
	
	// Design of a closed specification
	Item = ConditionalAppearance.Items.Add();

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	
	ItemFilter.LeftValue  = New DataCompositionField("Status");
	ItemFilter.ComparisonType   = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.BOMStatuses.Closed_;
	
	Item.Appearance.SetParameterValue("TextColor", StyleColors.ClosedDocument);
	
EndProcedure

#EndRegion
#Region FillingInUsingRouteMaps

// Fills in the resource specification with route map data for its stages
// 
// Parameters:
// 	Object - CatalogObject.BillsOfMaterials - BillOfMaterials
//
Procedure FillInUsingOperationsSheetsForStages(Object) Export
	
	Query = New Query;
	Query.TempTablesManager = New TempTablesManager; //temporary tables are reused
	
	Query.Text = 
	"SELECT
	|	ProductionStages.Ref AS Stage,
	|	ProductionStages.RouteSheet           AS RouteSheet,
	|	RouteSheets.UseFinishedProducts AS UseFinishedProducts,
	|	RouteSheets.UseMaterials       AS UseMaterials,
	|	RouteSheets.UseLaborCosts    AS UseLaborCosts,
	|	CASE
	|		WHEN ProductionStages.RouteSheetFactor = 0
	|			THEN 1
	|		ELSE ProductionStages.RouteSheetFactor
	|	END AS RouteSheetFactor,
	|	ProductionStages.StageNumber AS StageNumber,
	|	CASE
	|		WHEN ProductionStages.StageNumber = 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsTheFirstStep,
	|	CASE
	|		WHEN ProductionStages.NextStageNo = 0
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ThisIsLastStage
	|INTO StageList
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON ProductionStages.RouteSheet = RouteSheets.Ref
	|WHERE
	|	ProductionStages.Owner = &BillOfMaterials
	|	AND NOT ProductionStages.DeletionMark";
	
	Query.SetParameter("BillOfMaterials", Object.Ref);
	
	Query.SetParameter("ProductionProcessType",  Object.ProductionProcessType);
	Query.SetParameter("MainProductProducts",   Object.MainProductProducts);
	Query.SetParameter("MainProductCharacteristic", Object.MainProductCharacteristic);
	
	Query.Execute();
	
	StructureOfData = Undefined;
	GetRouteMapData(Query, StructureOfData);
	
	Query.TempTablesManager.Close();
	
	DeleteLinesWhereMKAreSpecifiedForStages(Object, "ManufacturedProducts",  StructureOfData.TableStages, "ThisIsLastStage", "UseFinishedProducts");
	DeleteLinesWhereMKAreSpecifiedForStages(Object, "RecyclableWaste", StructureOfData.TableStages, "ThisIsLastStage", "UseFinishedProducts");
	DeleteLinesWhereMKAreSpecifiedForStages(Object, "MaterialsAndServices", StructureOfData.TableStages, "ThisIsTheFirstStep",    "UseMaterials");
	DeleteLinesWhereMKAreSpecifiedForStages(Object, "LaborCosts",     StructureOfData.TableStages, "ThisIsTheFirstStep",    "UseLaborCosts");
	
	ChecksArray = New Array;
	AdjustOperandsOfCountCalculationAlgorithm(Object, StructureOfData, ChecksArray);
	
	ExcludedAttributes = "";
	If Not Object.MultiStageProductionProcess Then
		ExcludedAttributes = "Stage, StageEditing";
	EndIf;
	
	If StructureOfData.ManufacturedProducts <> Undefined Then
		For Each CollectionItem In StructureOfData.ManufacturedProducts Do
			FillPropertyValues(Object.ManufacturedProducts.Add(), CollectionItem,, ExcludedAttributes);
		EndDo; 
	EndIf;
	
	If StructureOfData.RecyclableWaste <> Undefined Then
		For Each CollectionItem In StructureOfData.RecyclableWaste Do
			FillPropertyValues(Object.RecyclableWaste.Add(), CollectionItem,, ExcludedAttributes);
		EndDo; 
	EndIf;
	
	If StructureOfData.MaterialsAndServices <> Undefined Then
		For Each CollectionItem In StructureOfData.MaterialsAndServices Do
			NewRow = Object.MaterialsAndServices.Add();
			FillPropertyValues(NewRow, CollectionItem,, ExcludedAttributes);
			ProductDataManagementClientServer.FillInDefaultMethodForGettingMaterial(NewRow);
		EndDo;
	EndIf;
	
	If StructureOfData.LaborCosts <> Undefined Then
		For Each CollectionItem In StructureOfData.LaborCosts Do
			FillPropertyValues(Object.LaborCosts.Add(), CollectionItem,, ExcludedAttributes);
		EndDo;
	EndIf;
	
	If StructureOfData.PropertyMapping <> Undefined Then
		For Each CollectionItem In StructureOfData.PropertyMapping Do
			FillPropertyValues(Object.PropertyMapping.Add(), CollectionItem);
		EndDo;
	EndIf;
	
	If StructureOfData.SelectionByProperties <> Undefined Then
		For Each CollectionItem In StructureOfData.SelectionByProperties Do
			FillPropertyValues(Object.SelectionByProperties.Add(), CollectionItem);
		EndDo;
	EndIf;
	
	NumberOfProducts = Object.ManufacturedProducts.Count();
	If NumberOfProducts = 1 Then
		If ValueIsFilled(Object.ManufacturedProducts[0].Products) Then
			Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.Products;
		EndIf;
	ElsIf NumberOfProducts > 1 Then
		Object.AssignmentOption = Enums.BillOfMaterialsAssignmentOptions.ItemList;
	EndIf;
	
EndProcedure

Procedure DeleteLinesWhereMKAreSpecifiedForStages(Object, TableName, TableStages, StageAutoSelectionField, NameOfTrainDetails)

	LinesToDelete = New Array;
	For Each RowData In Object[TableName] Do
		
		If Not RowData.StageEditing.IsEmpty() Then
			StageString = TableStages.Find(RowData.StageEditing, "Stage");
		Else
			StageString = TableStages.Find(True, StageAutoSelectionField);
		EndIf;
		
		If StageString <> Undefined 
			And Not StageString.RouteSheet.IsEmpty() 
			And StageString[NameOfTrainDetails] Then
			
			LinesToDelete.Add(RowData);
		EndIf; 
		
	EndDo; 

	For Each RowData In LinesToDelete Do
		
		Found4 = Object.PropertyMapping.FindRows(New Structure("ConnectionKey", RowData.ConnectionKey));
		For Each String In Found4 Do
			Object.PropertyMapping.Delete(String);
		EndDo;
		
		Found4 = Object.SelectionByProperties.FindRows(New Structure("ConnectionKey", RowData.ConnectionKey));
		For Each String In Found4 Do
			Object.SelectionByProperties.Delete(String);
		EndDo;
		
		Object[TableName].Delete(RowData);
		
	EndDo; 
	
EndProcedure

Function InitializeDataStructureToPopulate()
	
	StructureOfData = New Structure;
	StructureOfData.Insert("ManufacturedProducts",     Undefined);
	StructureOfData.Insert("RecyclableWaste",    Undefined);
	StructureOfData.Insert("MaterialsAndServices",    Undefined);
	StructureOfData.Insert("LaborCosts",        Undefined);
	StructureOfData.Insert("PropertyMapping", Undefined);
	StructureOfData.Insert("SelectionByProperties",    Undefined);
	
	StructureOfData.Insert("TableStages",        Undefined);
	
	TableOfCommunicationKeys = New ValueTable;
	TableOfCommunicationKeys.Columns.Add("Stage");
	TableOfCommunicationKeys.Columns.Add("RouteSheet");
	TableOfCommunicationKeys.Columns.Add("ConnectionKey");
	TableOfCommunicationKeys.Columns.Add("NewCommunicationKey");
	
	TableOfCommunicationKeys.Indexes.Add("Stage,RouteSheet,ConnectionKey");
	
	StructureOfData.Insert("TableOfCommunicationKeys",  TableOfCommunicationKeys);
	
	OperandAdjustmentTable = New ValueTable;
	OperandAdjustmentTable.Columns.Add("Stage");
	OperandAdjustmentTable.Columns.Add("RouteSheet");
	OperandAdjustmentTable.Columns.Add("TableName");
	OperandAdjustmentTable.Columns.Add("RowIndex");
	
	OperandAdjustmentTable.Indexes.Add("Stage,RouteSheet");
	
	StructureOfData.Insert("OperandAdjustmentTable", OperandAdjustmentTable);
	
	Return StructureOfData;
	
EndFunction

// Constructor of the data structure table to fill in
// 
// Parameters:
// 	SourceTable1 - ValueTable - source of columns for the data structure table
// Returns:
// 	ValueTable - From:
// 		* LineNumber - Number - the line number table
// 		* ConnectionKey - UUID - ID of the table row
//
Function DataStructureTableToPopulate(SourceTable1)
	
	Return SourceTable1.CopyColumns();
	
EndFunction

Procedure GetRouteMapData(Query, StructureOfData, EnableNestedMCS = True)

	If StructureOfData = Undefined Then
		StructureOfData = InitializeDataStructureToPopulate();
	EndIf;
	
	Fields = StrSplit("UseFinishedProducts,UseMaterials,UseLaborCosts",",");
	
	StageList = Query.TempTablesManager.Tables.Find("StageList").GetData().Unload();
	If StructureOfData.TableStages = Undefined Then
		StageList.Indexes.Add("Stage");
		StructureOfData.TableStages = StageList;
	Else
		For Each StageString In StageList Do
			Found4 = StructureOfData.TableStages.Find(StageString.Stage, "Stage");
			For Each Field In Fields Do
				Found4[Field] = Max(Found4[Field], StageString[Field]);
			EndDo;
		EndDo;
	EndIf;
	
	QueryText = 
	"SELECT
	|	StageList.Stage,
	|	StageList.ThisIsTheFirstStep AS ThisIsTheFirstStep,
	|	StageList.ThisIsLastStage AS ThisIsLastStage,
	|	StageList.RouteSheet AS RouteSheet,
	|	StageList.RouteSheetFactor AS RouteSheetFactor
	|INTO OperationsSheetList
	|FROM
	|	StageList AS StageList
	|
	|INDEX BY
	|	RouteSheet
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 1. Output products
	|SELECT
	|	OperationsSheetList.Stage,
	|	OperationsSheetList.Stage AS StageEditing,
	|	OperationsSheetList.ThisIsLastStage AS ThisIsLastStage,
	|	OperationsSheetList.RouteSheet AS RouteSheet,
	|	RouteSheetsManufacturedProducts.Products.ProductKind AS ProductKind,
	|	RouteSheetsManufacturedProducts.Products,
	|	RouteSheetsManufacturedProducts.Characteristic,
	|	RouteSheetsManufacturedProducts.NumberOfPackages * OperationsSheetList.RouteSheetFactor AS NumberOfPackages,
	|	RouteSheetsManufacturedProducts.Package,
	|	RouteSheetsManufacturedProducts.CostShare,
	|	CASE 
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN RouteSheetsManufacturedProducts.MethodOfProductsAutoselection
	|		ELSE VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInMasterData)
	|	END AS MethodOfProductsAutoselection,
	|	CASE 
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN RouteSheetsManufacturedProducts.MethodOfItemVariantAutoselection
	|		ELSE VALUE(Enum.MethodsOfItemVariantAutoselection.SpecifiedInMasterData)
	|	END AS MethodOfItemVariantAutoselection,
	|	CASE 
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN RouteSheetsManufacturedProducts.PropertyThatContainsProducts
	|		ELSE VALUE(ChartOfCharacteristicTypes.AdditionalAttributesAndInfo.EmptyRef)
	|	END AS PropertyThatContainsProducts,
	|	CASE 
	|		WHEN &ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			THEN RouteSheetsManufacturedProducts.QuantityCalculationAlgorithm
	|		ELSE """"
	|	END AS QuantityCalculationAlgorithm,
	|	RouteSheetsManufacturedProducts.ProductDescription,
	|	RouteSheetsManufacturedProducts.LineNumber,
	|	RouteSheetsManufacturedProducts.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.ManufacturedProducts AS RouteSheetsManufacturedProducts
	|		ON (RouteSheetsManufacturedProducts.Ref = OperationsSheetList.RouteSheet)
	|WHERE
	|	RouteSheets.UseFinishedProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 2. Returnable waste
	|SELECT
	|	OperationsSheetList.Stage,
	|	OperationsSheetList.Stage AS StageEditing,
	|	OperationsSheetList.ThisIsLastStage AS ThisIsLastStage,
	|	OperationsSheetList.RouteSheet AS RouteSheet,
	|	RouteSheetsRecyclableWaste.Products,
	|	RouteSheetsRecyclableWaste.Characteristic,
	|	RouteSheetsRecyclableWaste.NumberOfPackages * OperationsSheetList.RouteSheetFactor AS NumberOfPackages,
	|	RouteSheetsRecyclableWaste.Package,
	|	RouteSheetsRecyclableWaste.ProductCostElement,
	|	RouteSheetsRecyclableWaste.MethodOfProductsAutoselection,
	|	RouteSheetsRecyclableWaste.MethodOfItemVariantAutoselection,
	|	RouteSheetsRecyclableWaste.PropertyThatContainsProducts,
	|	RouteSheetsRecyclableWaste.QuantityCalculationAlgorithm,
	|	RouteSheetsRecyclableWaste.ProductDescription,
	|	RouteSheetsRecyclableWaste.LineNumber,
	|	RouteSheetsRecyclableWaste.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.RecyclableWaste AS RouteSheetsRecyclableWaste
	|		ON (RouteSheetsRecyclableWaste.Ref = OperationsSheetList.RouteSheet)
	|WHERE
	|	RouteSheets.UseFinishedProducts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 3. Materials and services
	|SELECT
	|	OperationsSheetList.Stage,
	|	OperationsSheetList.Stage AS StageEditing,
	|	OperationsSheetList.RouteSheet AS RouteSheet,
	|	RouteSheetsMaterialsAndServices.Products,
	|	RouteSheetsMaterialsAndServices.Characteristic,
	|	RouteSheetsMaterialsAndServices.NumberOfPackages * OperationsSheetList.RouteSheetFactor AS NumberOfPackages,
	|	RouteSheetsMaterialsAndServices.Package,
	|	RouteSheetsMaterialsAndServices.ProductCostElement,
	|	RouteSheetsMaterialsAndServices.MethodOfProductsAutoselection,
	|	RouteSheetsMaterialsAndServices.MethodOfItemVariantAutoselection,
	|	RouteSheetsMaterialsAndServices.PropertyThatContainsProducts,
	|	RouteSheetsMaterialsAndServices.QuantityCalculationAlgorithm,
	|	CASE
	|		WHEN RouteSheetsMaterialsAndServices.MaterialApplication = """"
	|			THEN RouteSheetsMaterialsAndServices.Operation
	|		ELSE RouteSheetsMaterialsAndServices.MaterialApplication
	|	END AS MaterialApplication,
	|	RouteSheetsMaterialsAndServices.LineNumber,
	|	RouteSheetsMaterialsAndServices.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.MaterialsAndServices AS RouteSheetsMaterialsAndServices
	|		ON (RouteSheetsMaterialsAndServices.Ref = OperationsSheetList.RouteSheet)
	|WHERE
	|	RouteSheets.UseMaterials
	|	AND CASE
	|			WHEN &ProductionProcessType IN (VALUE(Enum.ProductionProcessTypes.Repair), VALUE(Enum.ProductionProcessTypes.Disassembly))
	|				THEN NOT(RouteSheetsMaterialsAndServices.Products = &MainProductProducts
	|						AND RouteSheetsMaterialsAndServices.Characteristic = &MainProductCharacteristic)
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 4. Labor costs
	|SELECT
	|		OperationsSheetList.Stage,
	|		OperationsSheetList.Stage AS StageEditing,
	|		OperationsSheetList.RouteSheet AS RouteSheet,
	|		RouteSheetsLaborCosts.WorkKind,
	|		RouteSheetsLaborCosts.Count * OperationsSheetList.RouteSheetFactor AS Count,
	|		RouteSheetsLaborCosts.ProductCostElement,
	|		RouteSheetsLaborCosts.QuantityCalculationAlgorithm,
	|		RouteSheetsLaborCosts.LineNumber,
	|		RouteSheetsLaborCosts.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.LaborCosts AS RouteSheetsLaborCosts
	|		ON (RouteSheetsLaborCosts.Ref = OperationsSheetList.RouteSheet)
	|WHERE
	|	RouteSheets.UseLaborCosts
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 5. Conformity of properties
	|SELECT
	|		OperationsSheetList.Stage AS Stage,
	|		OperationsSheetList.RouteSheet AS RouteSheet,
	|		RouteSheetsPropertyMapping.MaterialProperty,
	|		RouteSheetsPropertyMapping.ProductsProperty,
	|		RouteSheetsPropertyMapping.PropertyValue,
	|		RouteSheetsPropertyMapping.ValueCalculationAlgorithm,
	|		RouteSheetsPropertyMapping.ValueSelectionMethod,
	|		RouteSheetsPropertyMapping.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.PropertyMapping AS RouteSheetsPropertyMapping
	|		ON (RouteSheetsPropertyMapping.Ref = OperationsSheetList.RouteSheet)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 6. Selection of properties
	|SELECT
	|		OperationsSheetList.Stage AS Stage,
	|		OperationsSheetList.RouteSheet AS RouteSheet,
	|		RouteSheetsSelectionByProperties.Property,
	|		RouteSheetsSelectionByProperties.Condition,
	|		RouteSheetsSelectionByProperties.Value,
	|		RouteSheetsSelectionByProperties.ConnectionKey
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.RouteSheets.SelectionByProperties AS RouteSheetsSelectionByProperties
	|		ON (RouteSheetsSelectionByProperties.Ref = OperationsSheetList.RouteSheet)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 7.
	|DROP StageList
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	// 8. Tech. operations
	|SELECT
	|	OperationsSheetList.Stage,
	|	OperationsSheetList.ThisIsTheFirstStep AS ThisIsTheFirstStep,
	|	OperationsSheetList.ThisIsLastStage AS ThisIsLastStage,
	|	CatOperations.NestedRoute AS RouteSheet,
	|	RouteMapsNested.UseFinishedProducts AS UseFinishedProducts,
	|	RouteMapsNested.UseMaterials AS UseMaterials,
	|	RouteMapsNested.UseLaborCosts AS UseLaborCosts,
	|	OperationsSheetList.RouteSheetFactor AS RouteSheetFactor,
	|	CatOperations.Description AS NameOfTheOperation
	|INTO StageList
	|FROM
	|	OperationsSheetList AS OperationsSheetList
	|		INNER JOIN Catalog.RouteSheets AS RouteSheets
	|		ON (RouteSheets.Ref = OperationsSheetList.RouteSheet)
	|		INNER JOIN Catalog.ManufacturingOperations AS CatOperations
	|		ON (CatOperations.Owner = OperationsSheetList.RouteSheet)
	|			AND CatOperations.ContainsNestedRoute
	|		INNER JOIN Catalog.RouteSheets AS RouteMapsNested
	|		ON (RouteMapsNested.Ref = CatOperations.NestedRoute)
	|WHERE 
	|	NOT CatOperations.Ref.DeletionMark
	|	AND RouteSheets.UseOperations
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP OperationsSheetList";
	
	Query.Text = QueryText;
	
	Result = Query.ExecuteBatch();
	// Result[0] - List of route charts
	// Result[1] - Output products
	// Result[2] - Returnable
	// waste Result[3] - Materials and services
	// Result[4] - Labor costs
	// Result[5] - Correspondences of properties
	// Result[6] - Selection of properties
	// The result[8] is a list of steps according to the nested MC data, which will be used in the next iteration of the procedure
	
	AddDataToDataStructureTable(StructureOfData, Result[1].Unload(), "ManufacturedProducts" , True);
	AddDataToDataStructureTable(StructureOfData, Result[2].Unload(), "RecyclableWaste", True);
	AddDataToDataStructureTable(StructureOfData, Result[3].Unload(), "MaterialsAndServices", True);
	AddDataToDataStructureTable(StructureOfData, Result[4].Unload(), "LaborCosts");
	AddDataToDataStructureTable(StructureOfData, Result[5].Unload(), "PropertyMapping");
	AddDataToDataStructureTable(StructureOfData, Result[6].Unload(), "SelectionByProperties");
	
	If EnableNestedMCS And Result[8].Unload()[0].Count > 0 Then
		GetRouteMapData(Query, StructureOfData);
	EndIf;
	
EndProcedure

Procedure AddDataToDataStructureTable(StructureOfData, SourceTable1, NameOfDataStructureTable, SourceOfOperands = False)
	
	If StructureOfData[NameOfDataStructureTable] = Undefined Then
		StructureOfData[NameOfDataStructureTable] = DataStructureTableToPopulate(SourceTable1);
	EndIf;
	DataStructureTable = StructureOfData[NameOfDataStructureTable]; // See DataStructureTableToPopulate
	
	TheStructureOfTheSearch = New Structure("Stage,RouteSheet,ConnectionKey");
	
	For Each SourceRow In SourceTable1 Do
		
		NewRow = DataStructureTable.Add();
		FillPropertyValues(NewRow, SourceRow);
		
		FillPropertyValues(TheStructureOfTheSearch, SourceRow);
		
		FoundRows = StructureOfData.TableOfCommunicationKeys.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() > 0 Then
			NewCommunicationKey = FoundRows[0].NewCommunicationKey;
		Else
			NewCommunicationKey = New UUID;
			NewLineKey_ = StructureOfData.TableOfCommunicationKeys.Add();
			FillPropertyValues(NewLineKey_, TheStructureOfTheSearch);
			NewLineKey_.NewCommunicationKey = NewCommunicationKey;
		EndIf;
		
		NewRow.ConnectionKey = NewCommunicationKey;
		
		If SourceOfOperands Then
			LineAdjustment_ = StructureOfData.OperandAdjustmentTable.Add();
			LineAdjustment_.Stage            = NewRow.Stage;
			LineAdjustment_.RouteSheet = NewRow.RouteSheet;
			LineAdjustment_.TableName      = NameOfDataStructureTable;
			LineAdjustment_.RowIndex    = DataStructureTable.IndexOf(NewRow);
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure AdjustOperandsOfCountCalculationAlgorithm(Object, StructureOfData, ChecksArray)
	
	For Each TSName In StrSplit("ManufacturedProducts,MaterialsAndServices,RecyclableWaste,LaborCosts",",") Do
		If StructureOfData[TSName] <> Undefined Then
			ChecksArray.Add(New Structure("TSName,Presentation", TSName));
		EndIf;
	EndDo;
	
	Filter = New Structure("Stage,RouteSheet");
	OperandAdjustmentTable = Undefined;
	
	For Each Validation In ChecksArray Do
		
		For Each String In StructureOfData[Validation.TSName] Do
			
			If IsBlankString(String.QuantityCalculationAlgorithm) Then
				Continue;
			EndIf;
			
			If Filter.Stage <> String.Stage Or Filter.RouteSheet <> String.RouteSheet Then
				FillPropertyValues(Filter, String);
				OperandAdjustmentTable = StructureOfData.OperandAdjustmentTable.Copy(Filter);
				OperandAdjustmentTable.Sort("TableName, RowIndex Desc");
			EndIf;
			
			For Each LineAdjustment_ In OperandAdjustmentTable Do
				
				TableName    = LineAdjustment_.TableName;
				Table       = StructureOfData[TableName]; // See DataStructureTableToPopulate
				TableRow = Table.Get(LineAdjustment_.RowIndex);
				
				OperandOld = StrTemplate("%1[%2].", TableName, Format(TableRow.LineNumber,"NZ=; NG="));
				OperandNew  = StrTemplate("%1[%2].", TableName, Format(Object[TableName].Count()+LineAdjustment_.RowIndex+1,"NZ=; NG="));
				
				If OperandOld <> OperandNew Then
					String.QuantityCalculationAlgorithm = StrReplace(String.QuantityCalculationAlgorithm, OperandOld, OperandNew);
				EndIf;
				
			EndDo;
			
		EndDo;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region DownloadingFromVHFFile

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//      * Id - Number - sequence number of the line;
//        the remaining columns correspond to the columns of the File upload layout.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//     * Column       - String - name of the column where the ambiguity was detected
//     * Id - Number  - id of the string where the ambiguity was detected.
//   The full name of the table part is a string - the full name of the table part into which the data is loaded.
//   AdditionalParameters   - Structure - Contains:
//      * ItemsCollection  - CatalogRef.ItemsCollections - collection of items.
//
Procedure MatchDownloadableDataProducts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, AdditionalParameters)
	
	MaterialsAndServices  = GetFromTempStorage(AddressOfMappingTable);// ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTDownloadableDataMaterialsAndServices());
	QueryTexts.Add(QueryTextTTBarcodeData());
	QueryTexts.Add(QueryTextTTProductData());
	QueryTexts.Add(QueryTextTTCharacteristicsData());
	QueryTexts.Add(QueryTextTTPackingData());
	QueryTexts.Add(QueryTextTTDataProductCostElements());
	If AdditionalParameters.StagesAreUsed Then
		QueryTexts.Add(QueryTextTTStageData());
	EndIf;
	If AdditionalParameters.OperationsAreUsed Then
		QueryTexts.Add(QueryTextTTTransactionData());
	EndIf;
	QueryTexts.Add(RequestTextDownloadableDataForMaterialsAndServices());
	
	Query = CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters);// Query
	
	If AdditionalParameters.TSName = "RecyclableWaste" Then
		Query.Text = StrReplace(Query.Text, "MaterialApplication", "ProductDescription");
	EndIf;
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		NewRow = MaterialsAndServices.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.ConnectionKey = New UUID();
		
		If Selection.QuantityOfProducts > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Products";
		EndIf;
		
		If Selection.NumberOfCharacteristics > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Characteristic";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "ProductCostElement";
		EndIf;
		
		If Selection.PackingQuantity > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Package";
		EndIf;
		If AdditionalParameters.StagesAreUsed And Selection.NumberOfStages > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Stage";
		EndIf;
		If AdditionalParameters.OperationsAreUsed And Selection.OperationsCount> 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Operation";
		EndIf;
	EndDo;
	
	PutToTempStorage(MaterialsAndServices, AddressOfMappingTable);
	
EndProcedure

// Compares the data loaded in the table part of the full table part
// With the data in the IB, and fills in the parameters of the addressable Comparison and the list of one-Values.
//
// Parameters:
//   AddressOfUploadedData    - String - the address of the temporary storage with the table of values in which
//                                        the downloaded data from the file is located. Composition of columns:
//      * Id - Number - sequence number of the line;
//        the remaining columns correspond to the columns of the File upload layout.
//   AddressOfMappingTable - String - the address of the temporary storage with an empty table of values,
//                                        which is a copy of the table part of the document
//                                        that needs to be filled in from the addressable Data table.
//   ConflictsList - ValueTable - a list of ambiguous values for which there are several suitable options in the information security:
//     * Column       - String - name of the column where the ambiguity was detected
//     * Id - Number  - id of the string where the ambiguity was detected.
//   The full name of the table part is a string - the full name of the table part into which the data is loaded.
//   AdditionalParameters   - Structure - Contains:
//      * ItemsCollection  - CatalogRef.ItemsCollections - collection of items.
//
Procedure CompareUploadedDataLaborCosts(AddressOfUploadedData, AddressOfMappingTable, ConflictsList, AdditionalParameters)
	
	LaborCosts      = GetFromTempStorage(AddressOfMappingTable);// ValueTable
	DataToImport = GetFromTempStorage(AddressOfUploadedData);
	
	QueryTexts = New Array;
	QueryTexts.Add(RequestTextTTUploadedDataLaborCosts());
	QueryTexts.Add(QueryTextTTDataTypesOfWork());
	QueryTexts.Add(QueryTextTTDataProductCostElements());
	
	If AdditionalParameters.StagesAreUsed Then
		QueryTexts.Add(QueryTextTTStageData());
	EndIf;
	If AdditionalParameters.OperationsAreUsed Then
		QueryTexts.Add(QueryTextTTTransactionData());
	EndIf;
	QueryTexts.Add(RequestTextUploadedDataLaborCosts());
	
	Query = CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters);// Query
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		NewRow = LaborCosts.Add();
		FillPropertyValues(NewRow, Selection);
		
		If Selection.NumberOfWorkKinds > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "WorkKind";
		EndIf;
		
		If Selection.NumberOfCalculationArticles > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "ProductCostElement";
		EndIf;
		
		If AdditionalParameters.StagesAreUsed And Selection.NumberOfStages > 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Stage";
		EndIf;
		If AdditionalParameters.OperationsAreUsed And Selection.OperationsCount> 1 Then
			WritingAboutAmbiguity               = ConflictsList.Add();
			WritingAboutAmbiguity.Id = Selection.Id;
			WritingAboutAmbiguity.Column       = "Operation";
		EndIf;
	EndDo;
	
	PutToTempStorage(LaborCosts, AddressOfMappingTable);
	
EndProcedure

Procedure FillInListOfProductAmbiguities(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters)
	
	Query = New Query;
	
	If ColumnName = "Products" Then
		
		Query.Text =
		"SELECT DISTINCT
		|	Barcodes.Products   AS Products,
		|	Barcodes.Characteristic AS Characteristic,
		|	Barcodes.Package       AS Package
		|INTO TTBarcodeData
		|FROM
		|	InformationRegister.ItemsBarcodes AS Barcodes
		|
		|WHERE
		|	NOT &Barcode = """"
		|	AND Barcodes.Barcode = &Barcode
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	CatProducts.Ref AS Ref
		|FROM
		|	(SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &SKU = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.SKU = &SKU
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &ProductsAndServicesCode = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Code = &ProductsAndServicesCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		CatProducts.Ref AS Ref
		|	FROM
		|		Catalog.Products AS CatProducts
		|		
		|		LEFT JOIN TTBarcodeData AS BarcodeData_5
		|		ON TRUE
		|
		|	WHERE
		|		NOT &Products = """"
		|		AND BarcodeData_5.Products IS NULL
		|		AND CatProducts.Description = &Products
		|
		|	UNION ALL
		|
		|	SELECT
		|		BarcodeData_5.Products AS Ref
		|	FROM
		|		TTBarcodeData AS BarcodeData_5
		|	) AS CatProducts
		|
		|GROUP BY
		|	CatProducts.Ref
		|";
		
		Query.SetParameter("Barcode",        LoadedValuesString.Barcode);
		Query.SetParameter("SKU",         LoadedValuesString.SKU);
		Query.SetParameter("ProductsAndServicesCode", LoadedValuesString.ProductsAndServicesCode);
		Query.SetParameter("Products",    LoadedValuesString.Products);
		
	EndIf;
	
	If ColumnName = "Characteristic" Then
		
		Query.Text =
		"SELECT
		|	Characteristics.Ref AS Ref
		|FROM
		|	Catalog.ItemsCharacteristics AS Characteristics
		|
		|WHERE
		|	NOT &Characteristic = """"
		|	AND Characteristics.Description = &Characteristic
		|";
		
		Query.SetParameter("Characteristic", LoadedValuesString.Characteristic);
		
	EndIf;
	
	If ColumnName = "ProductCostElement" Then
		
		Query.Text =
		"SELECT
		|	CatProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS CatProductCostElements
		|
		|WHERE
		|	NOT &ProductCostElement = """"
		|	AND CatProductCostElements.Description = &ProductCostElement
		|";
		
		Query.SetParameter("ProductCostElement", LoadedValuesString.ProductCostElement);
		
	EndIf;
	
	If ColumnName = "Package" Then
		
		Query.Text =
		"SELECT
		|	Packages.Ref AS Ref
		|FROM
		|	(SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &PackageCode = """"
		|		AND Packages.Code = &PackageCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		Packages.Ref AS Ref
		|	FROM
		|		Catalog.PackagesAndUnitsOfMeasure AS Packages
		|
		|	WHERE
		|		NOT &Package = """"
		|		AND Packages.Description = &Package
		|	) AS Packages
		|
		|GROUP BY
		|	Packages.Ref
		|";
		
		Query.SetParameter("PackageCode", LoadedValuesString.PackageCode);
		Query.SetParameter("Package",    LoadedValuesString.Package);
		
	EndIf;
	
	If ColumnName = "Stage" Then
		
		Query.Text =
		"SELECT
		|	Stages.Ref AS Ref
		|FROM
		|	Catalog.ProductionStages AS Stages
		|
		|WHERE
		|	NOT &Stage = """"
		|	AND Stages.Owner = &BillOfMaterial
		|	AND Stages.Description = &Stage
		|";
		
		Query.SetParameter("Stage",                  LoadedValuesString.Stage);
		Query.SetParameter("BillOfMaterial", AdditionalParameters.BillOfMaterial);
		
	EndIf;
	If ColumnName = "Operation" Then
		
		Query.Text =
		"SELECT
		|	Operations.Ref AS Ref
		|FROM
		|	Catalog.ManufacturingOperations AS Operations
		|
		|WHERE
		|	NOT &Operation = """"
		|	AND Operations.BillOfMaterials = &BillOfMaterial
		|	AND Operations.Description = &Operation
		|";
		
		Query.SetParameter("Operation",              LoadedValuesString.Operation);
		Query.SetParameter("BillOfMaterial", AdditionalParameters.BillOfMaterial);
		
	EndIf;
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

Procedure FillInListOfAmbiguitiesLaborCosts(ConflictsList, ColumnName, LoadedValuesString, AdditionalParameters)
	
	Query = New Query;
	
	If ColumnName = "ProductCostElement" Then
		
		Query.Text =
		"SELECT
		|	CatProductCostElements.Ref AS Ref
		|FROM
		|	Catalog.ProductCostElements AS CatProductCostElements
		|
		|WHERE
		|	NOT &ProductCostElement = """"
		|	AND CatProductCostElements.Description = &ProductCostElement
		|";
		
		Query.SetParameter("ProductCostElement", LoadedValuesString.ProductCostElement);
		
	EndIf;
	
	If ColumnName = "WorkKind" Then
		
		Query.Text =
		"SELECT
		|	ActivityKinds.Ref AS Ref
		|FROM
		|	(SELECT
		|		ActivityKinds.Ref AS Ref
		|	FROM
		|		Catalog.EmployeeWorkKinds AS ActivityKinds
		|
		|	WHERE
		|		NOT &WorkKindCode = """"
		|		AND ActivityKinds.Code = &WorkKindCode
		|
		|	UNION ALL
		|
		|	SELECT
		|		ActivityKinds.Ref AS Ref
		|	FROM
		|		Catalog.EmployeeWorkKinds AS ActivityKinds
		|
		|	WHERE
		|		NOT &WorkKind = """"
		|		AND ActivityKinds.Description = &WorkKind
		|	) AS ActivityKinds
		|
		|GROUP BY
		|	ActivityKinds.Ref
		|";
		
		Query.SetParameter("WorkKindCode", LoadedValuesString.WorkKindCode);
		Query.SetParameter("WorkKind",     LoadedValuesString.WorkKind);
		
	EndIf;
	
	If ColumnName = "Stage" Then
		
		Query.Text =
		"SELECT
		|	Stages.Ref AS Ref
		|FROM
		|	Catalog.ProductionStages AS Stages
		|
		|WHERE
		|	NOT &Stage = """"
		|	AND Stages.Owner = &BillOfMaterial
		|	AND Stages.Description = &Stage
		|";
		
		Query.SetParameter("Stage",                  LoadedValuesString.Stage);
		Query.SetParameter("BillOfMaterial", AdditionalParameters.BillOfMaterial);
		
	EndIf;
	If ColumnName = "Operation" Then
		
		Query.Text =
		"SELECT
		|	Operations.Ref AS Ref
		|FROM
		|	Catalog.ManufacturingOperations AS Operations
		|
		|WHERE
		|	NOT &Stage = """"
		|	AND Operations.BillOfMaterials = &BillOfMaterial
		|	AND Operations.Description = &Operation
		|";
		
		Query.SetParameter("Operation",              LoadedValuesString.Operation);
		Query.SetParameter("BillOfMaterial", AdditionalParameters.BillOfMaterial);
		
	EndIf;
	If ValueIsFilled(Query.Text) Then
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			ConflictsList.Add(Selection.Ref);
		EndDo;
	EndIf;
	
EndProcedure

#Region DownloadRequestTextsFromVHFFile

Function CreateConfigureRequest(QueryTexts, DataToImport, AdditionalParameters)
	
	QueryText = StrConcat(QueryTexts, Common.QueryBatchSeparator());
	
	// Stages are used
	QueryText = StrReplace(QueryText, "&LoadingDataStage,",
		?(AdditionalParameters.StagesAreUsed, "DataToImport.StageNumber AS StageNumber,
													|DataToImport.Stage AS Stage,", ""));
	
	QueryText = StrReplace(QueryText, "&Stage,", ?(AdditionalParameters.StagesAreUsed, "
		|	CASE
		|		WHEN ISNULL(StageData_1.NumberOfStages, 0) = 1
		|			THEN StageData_1.Stage
		|		ELSE VALUE(Catalog.ProductionStages.EmptyRef)
		|	END AS Stage,", ""));
	
	QueryText = StrReplace(QueryText, "&NumberOfStages,", 
		?(AdditionalParameters.StagesAreUsed, "ISNULL(StageData_1.NumberOfStages, 0) AS NumberOfStages,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.StagesAreUsed, "
		|	LEFT JOIN TTStageData AS StageData_1
		|	ON StageData_1.Id = DataToImport.Id", "");
	
	// Operations Are Used
	
	QueryText = StrReplace(QueryText, ", &TTStageData",
		?(AdditionalParameters.OperationsAreUsed And AdditionalParameters.StagesAreUsed,
			"INNER JOIN TTStageData AS Stages
			|ON DataToImport.Id = Stages.Id", ""));
	
	QueryText = StrReplace(QueryText, "AND &FilterByStep",
		?(AdditionalParameters.OperationsAreUsed And AdditionalParameters.StagesAreUsed,
			"AND Operations.Owner = Stages.Stage", ""));
	
	QueryText = StrReplace(QueryText, "&UploadedDataOperation,",
		?(AdditionalParameters.OperationsAreUsed, "DataToImport.OperationNumber AS OperationNumber,
														|DataToImport.Operation AS Operation,", ""));
	
	QueryText = StrReplace(QueryText, "&Operation,", ?(AdditionalParameters.OperationsAreUsed, "
		|	CASE
		|		WHEN ISNULL(OperationData_.OperationsCount, 0) = 1
		|			THEN OperationData_.Operation
		|		ELSE VALUE(Catalog.ManufacturingOperations.EmptyRef)
		|	END AS Operation,", ""));
	
	QueryText = StrReplace(QueryText, "&OperationsCount,", 
		?(AdditionalParameters.OperationsAreUsed, "ISNULL(OperationData_.OperationsCount, 0) AS OperationsCount,", ""));
	
	QueryText = QueryText + ?(AdditionalParameters.OperationsAreUsed, "
		|	LEFT JOIN TTTransactionData AS OperationData_
		|	ON OperationData_.Id = DataToImport.Id", "");
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DataToImport",     DataToImport);
	Query.SetParameter("AvailableProductTypes", AdditionalParameters.AvailableProductTypes);

	If AdditionalParameters.StagesAreUsed
		Or AdditionalParameters.OperationsAreUsed
		Then
		
		ProductionProcessData = Undefined;
		
		If IsTempStorageURL(AdditionalParameters.AddressOfProductionProcessElements) Then
			
			ProductionProcessData = GetFromTempStorage(AdditionalParameters.AddressOfProductionProcessElements);
			
		EndIf;
		
		Query.SetParameter("BillOfMaterial", AdditionalParameters.BillOfMaterial);
		Query.SetParameter("ProductionProcessData", ProductionProcessData);
		
	EndIf;

	Return Query;
	
EndFunction

Function QueryTextTTStageData()
	
	QueryText ="
	|SELECT
	|	CacheStageData.Ref AS Ref,
	|	CacheStageData.Number AS StageNumber,
	|	CacheStageData.Description AS Description
	|INTO TTDataAndCache
	|FROM &ProductionProcessData AS CacheStageData
	|
	|WHERE
	|	VALUETYPE(CacheStageData.Ref) = TYPE(Catalog.ProductionStages)
	|
	|;
	|///////////////////////////////////////////////////////
	|SELECT
	|	Stages.Id                AS Id,
	|	MAX(Stages.Ref)             AS Stage,
	|	COUNT(DISTINCT Stages.Ref) AS NumberOfStages
	|INTO TTStageData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ProductionStages AS Stages
	|		ON Stages.StageNumber = DataToImport.StageNumber
	|		AND Stages.Description = DataToImport.Stage
	|
	|	WHERE
	|		Stages.Owner = &BillOfMaterial
	|		AND NOT Stages.DeletionMark
	|		AND NOT DataToImport.StageNumber = 0
	|		AND NOT DataToImport.Stage = """"
	|
	|	UNION ALL
	|
	|SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ProductionStages AS Stages
	|		ON Stages.StageNumber = DataToImport.StageNumber
	|
	|	WHERE
	|		Stages.Owner = &BillOfMaterial
	|		AND NOT Stages.DeletionMark
	|		AND NOT DataToImport.StageNumber = 0
	|		AND DataToImport.Stage = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.ProductionStages AS Stages
	|		ON Stages.Description = DataToImport.Stage
	|
	|	WHERE
	|		Stages.Owner = &BillOfMaterial
	|		AND NOT Stages.DeletionMark
	|		AND NOT DataToImport.Stage = """"
	|		AND DataToImport.StageNumber = 0
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN TTDataAndCache AS Stages
	|		ON Stages.StageNumber = DataToImport.StageNumber
	|		AND Stages.Description = DataToImport.Stage
	|
	|	WHERE
	|		NOT DataToImport.StageNumber = 0
	|		AND NOT DataToImport.Stage = """"
	|
	|	UNION ALL
	|
	|SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN TTDataAndCache AS Stages
	|		ON Stages.StageNumber = DataToImport.StageNumber
	|
	|	WHERE
	|		NOT DataToImport.StageNumber = 0
	|		AND DataToImport.Stage = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Stages.Ref                    AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTDataAndCache AS Stages
	|		ON Stages.Description = DataToImport.Stage
	|
	|	WHERE
	|		NOT DataToImport.Stage = """"
	|		AND DataToImport.StageNumber = 0
	|	) AS Stages
	|
	|GROUP BY
	|	Stages.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction
Function QueryTextTTTransactionData()
	
	QueryText ="
	|SELECT
	|	OperationDataCache.Ref AS Ref,
	|	OperationDataCache.Number AS OperationNumber,
	|	OperationDataCache.Description AS Description,
	|	OperationDataCache.Owner AS Owner
	|INTO TTOperationDataCache
	|FROM &ProductionProcessData AS OperationDataCache
	|
	|WHERE
	|	VALUETYPE(OperationDataCache.Ref) = TYPE(Catalog.ManufacturingOperations)
	|;
	|///////////////////////////////////////////////////////
	|SELECT
	|	Operations.Id                AS Id,
	|	MAX(Operations.Ref)             AS Operation,
	|	COUNT(DISTINCT Operations.Ref) AS OperationsCount
	|INTO TTTransactionData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ManufacturingOperations AS Operations
	|		ON Operations.OperationNumber = DataToImport.OperationNumber
	|		AND Operations.Description = DataToImport.Operation
	|
	|		, &TTStageData
	|
	|	WHERE
	|		Operations.BillOfMaterials = &BillOfMaterial
	|		AND NOT Operations.DeletionMark
	|		AND NOT DataToImport.OperationNumber = 0
	|		AND NOT DataToImport.Operation = """"
	|		AND &FilterByStep
	|
	|	UNION ALL
	|
	|SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN Catalog.ManufacturingOperations AS Operations
	|		ON Operations.OperationNumber = DataToImport.OperationNumber
	|		
	|		, &TTStageData
	|
	|	WHERE
	|		Operations.BillOfMaterials = &BillOfMaterial
	|		AND NOT Operations.DeletionMark
	|		AND NOT DataToImport.OperationNumber = 0
	|		AND DataToImport.Operation = """"
	|		AND &FilterByStep
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.ManufacturingOperations AS Operations
	|		ON Operations.Description = DataToImport.Operation
	|
	|		, &TTStageData
	|
	|	WHERE
	|		Operations.BillOfMaterials = &BillOfMaterial
	|		AND NOT Operations.DeletionMark
	|		AND NOT DataToImport.Operation = """"
	|		AND DataToImport.OperationNumber = 0
	|		AND &FilterByStep
	|	
	|	UNION ALL
	|
	|SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN TTOperationDataCache AS Operations
	|		ON Operations.OperationNumber = DataToImport.OperationNumber
	|		AND Operations.Description = DataToImport.Operation
	|
	|		, &TTStageData
	|
	|	WHERE
	|		NOT DataToImport.OperationNumber = 0
	|		AND NOT DataToImport.Operation = """"
	|		AND &FilterByStep
	|
	|	UNION ALL
	|
	|SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|	
	|		INNER JOIN TTOperationDataCache AS Operations
	|		ON Operations.OperationNumber = DataToImport.OperationNumber
	|
	|		, &TTStageData
	|
	|	WHERE
	|		NOT DataToImport.OperationNumber = 0
	|		AND DataToImport.Operation = """"
	|		AND &FilterByStep
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Operations.Ref                 AS Ref
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTOperationDataCache AS Operations
	|		ON Operations.Description = DataToImport.Operation
	|
	|		, &TTStageData
	|
	|	WHERE
	|		NOT DataToImport.Operation = """"
	|		AND DataToImport.OperationNumber = 0
	|		AND &FilterByStep) AS Operations
	|
	|GROUP BY
	|	Operations.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction
Function QueryTextTTDataProductCostElements()
	
	QueryText =
	"SELECT
	|	DataToImport.Id                   AS Id,
	|	MAX(CatProductCostElements.Ref)             AS ProductCostElement,
	|	COUNT(DISTINCT CatProductCostElements.Ref) AS NumberOfCalculationArticles
	|INTO TTDataProductCostElements
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN Catalog.ProductCostElements AS CatProductCostElements
	|	ON CatProductCostElements.Description = DataToImport.ProductCostElement
	|
	|WHERE
	|	NOT DataToImport.ProductCostElement = """"
	|
	|GROUP BY
	|	DataToImport.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

#Region TextsOfDownloadRequestsFromVHFFileMaterialsAndServices

Function RequestTextTTDownloadableDataMaterialsAndServices()
	
	QueryText =
	"SELECT
	|	DataToImport.Id       AS Id,
	|	DataToImport.Barcode            AS Barcode,
	|	DataToImport.SKU             AS SKU,
	|	DataToImport.ProductsAndServicesCode     AS ProductsAndServicesCode,
	|	DataToImport.Products        AS Products,
	|	DataToImport.Characteristic      AS Characteristic,
	|	DataToImport.PackageCode         AS PackageCode,
	|	DataToImport.Package            AS Package,
	|	DataToImport.NumberOfPackages  AS NumberOfPackages,
	|	&LoadingDataStage,
	|	&UploadedDataOperation,
	|	DataToImport.ProductCostElement   AS ProductCostElement,
	|	DataToImport.MaterialApplication AS MaterialApplication
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTBarcodeData()
	
	QueryText =
	"SELECT DISTINCT
	|	DataToImport.Id AS Id,
	|	Barcodes.Products          AS Products,
	|	Barcodes.Characteristic        AS Characteristic,
	|	Barcodes.Package              AS Package
	|INTO TTBarcodeData
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	INNER JOIN InformationRegister.ItemsBarcodes AS Barcodes
	|	ON Barcodes.Barcode = DataToImport.Barcode
	|
	|WHERE
	|	NOT DataToImport.Barcode = """"
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTProductData()
	
	QueryText =
	"SELECT
	|	CatProducts.Id                      AS Id,
	|	MAX(CatProducts.Products)             AS Products,
	|	COUNT(DISTINCT CatProducts.Products) AS QuantityOfProducts
	|INTO TTProductData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.SKU = DataToImport.SKU
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.SKU = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Code = DataToImport.ProductsAndServicesCode
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.ProductsAndServicesCode = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		CatProducts.Ref          AS Products
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.Products AS CatProducts
	|		ON CatProducts.Description = DataToImport.Products
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Products = """"
	|		AND CatProducts.ItemsType IN (&AvailableProductTypes)
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Products  AS Products
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS CatProducts
	|
	|GROUP BY
	|	CatProducts.Id
	|
	|INDEX BY
	|	Id,
	|	Products
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTCharacteristicsData()
	
	QueryText =
	"SELECT
	|	Characteristics.Id                        AS Id,
	|	MAX(Characteristics.Characteristic)             AS Characteristic,
	|	COUNT(DISTINCT Characteristics.Characteristic) AS NumberOfCharacteristics
	|INTO TTCharacteristicsData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = ProductData_1.Products
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Characteristics.Ref           AS Characteristic
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.ItemsCharacteristics AS Characteristics
	|		ON Characteristics.Owner = ProductData_1.Products.ProductKind
	|		AND Characteristics.Description = DataToImport.Characteristic
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Characteristic = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Characteristic AS Characteristic
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Characteristics
	|
	|GROUP BY
	|	Characteristics.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTPackingData()
	
	QueryText =
	"SELECT
	|	Packages.Id                  AS Id,
	|	MAX(Packages.Package)             AS Package,
	|	COUNT(DISTINCT Packages.Package) AS PackingQuantity
	|INTO TTPackingData
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Description = DataToImport.Package
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.Package = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		Packages.Ref                 AS Package
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN TTProductData AS ProductData_1
	|		ON ProductData_1.Id = DataToImport.Id
	|		
	|		INNER JOIN Catalog.PackagesAndUnitsOfMeasure AS Packages
	|		ON Packages.Owner = ProductData_1.Products.PackagingGroup
	|		AND Packages.Code = DataToImport.PackageCode
	|		
	|		LEFT JOIN TTBarcodeData AS BarcodeData_5
	|		ON BarcodeData_5.Id = DataToImport.Id
	|
	|	WHERE
	|		BarcodeData_5.Id IS NULL
	|		AND NOT DataToImport.PackageCode = """"
	|
	|	UNION ALL
	|
	|	SELECT DISTINCT
	|		BarcodeData_5.Id AS Id,
	|		BarcodeData_5.Package      AS Package
	|	FROM
	|		TTBarcodeData AS BarcodeData_5
	|	) AS Packages
	|
	|GROUP BY
	|	Packages.Id
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextDownloadableDataForMaterialsAndServices()
	
	QueryText =
	"SELECT
	|	DataToImport.Id                          AS Id,
	|	CASE
	|		WHEN ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) = 1
	|			THEN DataForCalculation_.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END                                                    AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(ProductData_1.QuantityOfProducts, 0) = 1
	|			THEN ProductData_1.Products
	|		ELSE VALUE(Catalog.Products.EmptyRef)
	|	END                                                    AS Products,
	|	CASE
	|		WHEN ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) = 1
	|			THEN CharacteristicsData.Characteristic
	|		ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|	END                                                    AS Characteristic,
	|	&Stage,
	|	&Operation,
	|	CASE
	|		WHEN ISNULL(PackageData_.PackingQuantity, 0) = 1
	|			THEN PackageData_.Package
	|		ELSE VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	END                                                    AS Package,
	|	ISNULL(ProductData_1.QuantityOfProducts, 0)   AS QuantityOfProducts,
	|	ISNULL(CharacteristicsData.NumberOfCharacteristics, 0) AS NumberOfCharacteristics,
	|	&NumberOfStages,
	|	&OperationsCount,
	|	ISNULL(PackageData_.PackingQuantity, 0)           AS PackingQuantity,
	|	ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) AS NumberOfCalculationArticles,
	|	DataToImport.NumberOfPackages                     AS NumberOfPackages,
	|	DataToImport.MaterialApplication                    AS MaterialApplication
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTDataProductCostElements AS DataForCalculation_
	|	ON DataForCalculation_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTProductData AS ProductData_1
	|	ON ProductData_1.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTCharacteristicsData AS CharacteristicsData
	|	ON CharacteristicsData.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTPackingData AS PackageData_
	|	ON PackageData_.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region DownloadRequestTextsFromVHFFileLaborCosts

Function RequestTextTTUploadedDataLaborCosts()
	
	QueryText =
	"SELECT
	|	DataToImport.Id     AS Id,
	|	DataToImport.WorkKindCode      AS WorkKindCode,
	|	DataToImport.WorkKind          AS WorkKind,
	|	DataToImport.Count        AS Count,
	|	DataToImport.ProductCostElement AS ProductCostElement,
	|	&LoadingDataStage,
	|	&UploadedDataOperation,
	|	DataToImport.WorkAssignment   AS WorkAssignment
	|INTO TTDownloadableData
	|FROM
	|	&DataToImport AS DataToImport
	|
	|INDEX BY
	|	Id
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextTTDataTypesOfWork()
	
	QueryText =
	"SELECT
	|	ActivityKinds.Id                  AS Id,
	|	MAX(ActivityKinds.WorkKind)             AS WorkKind,
	|	COUNT(DISTINCT ActivityKinds.WorkKind) AS NumberOfWorkKinds
	|INTO TTDataTypesOfWork
	|FROM
	|	(SELECT
	|		DataToImport.Id AS Id,
	|		ActivityKinds.Ref                AS WorkKind
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON ActivityKinds.Code = DataToImport.WorkKindCode
	|
	|	WHERE
	|		NOT DataToImport.WorkKindCode = """"
	|
	|	UNION ALL
	|
	|	SELECT
	|		DataToImport.Id AS Id,
	|		ActivityKinds.Ref                AS WorkKind
	|	FROM
	|		TTDownloadableData AS DataToImport
	|		
	|		INNER JOIN Catalog.EmployeeWorkKinds AS ActivityKinds
	|		ON ActivityKinds.Description = DataToImport.WorkKind
	|
	|	WHERE
	|		NOT DataToImport.WorkKind = """"
	|	) AS ActivityKinds
	|
	|GROUP BY
	|	ActivityKinds.Id
	|
	|INDEX BY
	|	Id,
	|	WorkKind
	|";
	
	Return QueryText;
	
EndFunction

Function RequestTextUploadedDataLaborCosts()
	
	QueryText =
	"SELECT
	|	DataToImport.Id                             AS Id,
	|	CASE
	|		WHEN ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) = 1
	|			THEN DataForCalculation_.ProductCostElement
	|		ELSE VALUE(Catalog.ProductCostElements.EmptyRef)
	|	END                                                       AS ProductCostElement,
	|	CASE
	|		WHEN ISNULL(DataTypesOfWork.NumberOfWorkKinds, 0) = 1
	|			THEN DataTypesOfWork.WorkKind
	|		ELSE VALUE(Catalog.EmployeeWorkKinds.EmptyRef)
	|	END                                                       AS WorkKind,
	|	&Stage,
	|	&Operation,
	|	ISNULL(DataTypesOfWork.NumberOfWorkKinds, 0)          AS NumberOfWorkKinds,
	|	ISNULL(DataForCalculation_.NumberOfCalculationArticles, 0) AS NumberOfCalculationArticles,
	|	DataToImport.Count                                AS Count,
	|	&NumberOfStages,
	|	&OperationsCount,
	|	DataToImport.WorkAssignment                           AS WorkAssignment
	|FROM
	|	TTDownloadableData AS DataToImport
	|	
	|	LEFT JOIN TTDataProductCostElements AS DataForCalculation_
	|	ON DataForCalculation_.Id = DataToImport.Id
	|	
	|	LEFT JOIN TTDataTypesOfWork AS DataTypesOfWork
	|	ON DataTypesOfWork.Id = DataToImport.Id
	|";
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndRegion

#EndRegion

#Region QueriesTexts

Function QueryTextMainProductSpecificationData()
	
	QueriesTexts = New Array;
	
	QueryText = "
	|SELECT TOP 1
	|	ManufacturedProducts.Ref                   AS BillOfMaterials,
	|	ManufacturedProducts.Ref.AssignmentOption AS AssignmentOption,
	|
	|	ManufacturedProducts.ProductKind          AS ProductKind,
	|	&OutputProductsSourceOfProducts     AS Products,
	|	&OutputProductsSourceSpecifications   AS Characteristic,
	|
	|	ManufacturedProducts.NumberOfPackages       AS NumberOfPackages,
	|
	|	CASE
	|		WHEN &ConsiderProbabilityOfDefectiveGoods
	|			THEN ManufacturedProducts.ShareOfNonconformity / 100
	|		ELSE 0
	|	END                                    AS DefectiveGoodsRate,
	|
	|	ManufacturedProducts.Package                 AS Package,
	|	ManufacturedProducts.Stage AS Stage,
	|	ManufacturedProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS AnyCharacteristic,
	|	ManufacturedProducts.LineNumber = 1 AS ThisIsMainProduct
	|
	|INTO TTMainProduct
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS ManufacturedProducts
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON ManufacturedProducts.Ref = TTProductData_.BillOfMaterials
	|			AND ManufacturedProducts.Ref.ProductionProcessType IN (
	|						VALUE(Enum.ProductionProcessTypes.Assembly),
	|						VALUE(Enum.ProductionProcessTypes.PerformRM),
	|						VALUE(Enum.ProductionProcessTypes.Repair))
	|			AND (ManufacturedProducts.Products = TTProductData_.Products
	|				OR TTProductData_.Products = VALUE(Catalog.Products.EmptyRef)
	|					AND ManufacturedProducts.LineNumber = 1
	|				OR ManufacturedProducts.Products = VALUE(Catalog.Products.EmptyRef)
	|					AND ManufacturedProducts.ProductKind = TTProductData_.Products.ProductKind
	|					AND ManufacturedProducts.LineNumber = 1)
	|			AND (TTProductData_.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|					AND ManufacturedProducts.LineNumber = 1
	|				OR ManufacturedProducts.Characteristic = TTProductData_.Characteristic
	|				OR ManufacturedProducts.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|
	|UNION ALL
	|
	|SELECT
	|	InputProducts.Ref,
	|	InputProducts.AssignmentOption,
	|	
	|	InputProducts.MainProductProductKind,
	|	&InputProductsSourceOfProducts,
	|	&InputProductsSourceCharacteristics,
	|
	|	InputProducts.MainProductNumberOfPackages,
	|
	|	0,
	|
	|	InputProducts.MainProductPackage,
	|	InputProducts.MainProductStage,
	|	InputProducts.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef),
	|	TRUE
	|FROM
	|	Catalog.BillsOfMaterials AS InputProducts
	|
	|		INNER JOIN TTProductData_ AS TTProductData_
	|		ON InputProducts.Ref = TTProductData_.BillOfMaterials
	|			AND InputProducts.ProductionProcessType = VALUE(Enum.ProductionProcessTypes.Disassembly)
	|			AND (InputProducts.MainProductProducts = TTProductData_.Products
	|				OR TTProductData_.Products = VALUE(Catalog.Products.EmptyRef)
	|				OR InputProducts.MainProductProducts = VALUE(Catalog.Products.EmptyRef)
	|					AND InputProducts.MainProductProductKind = TTProductData_.Products.ProductKind)
	|			AND (TTProductData_.Characteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				OR InputProducts.MainProductCharacteristic = TTProductData_.Characteristic
	|				OR InputProducts.MainProductCharacteristic = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|";
	
	QueriesTexts.Add(QueryText);
	QueriesTexts.Add(ProductDataManagement.QueryTextPackageData_(CommonClientServer.ValueInArray("TTMainProduct")));
	
	QueryText = "
	|SELECT
	|	T.*,
	|	T.NumberOfPackages               AS NumberOfPackagesPerUnitOfProductionBatch,
	|	T.ProductKind.ItemsType  AS ItemsType,
	|	CASE
	|		WHEN T.ProductKind.UseVariants IN (
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonForItemKind),
	|				VALUE(Enum.ItemVariantsUsageOptions.SpecialForItems),
	|				VALUE(Enum.ItemVariantsUsageOptions.CommonWithOtherItemKind))
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS ItemVariantsAreUsed,
	|	ISNULL(T.Products.AnalyticalGroup, VALUE(Catalog.AnalyticalInventoryGroups.EmptyRef))         AS AnalyticalGroup,
	|	ISNULL(T.Products.UnitOfMeasure, VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef))                               AS UnitOfMeasure,
	|	ISNULL(T.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces), FALSE) AS PieceUnitOfMeasure
	|
	|FROM
	|	TTMainProduct AS T
	|";
	QueriesTexts.Add(QueryText);
	
	QueryText = StrConcat(QueriesTexts, Common.QueryBatchSeparator());
	
	SubstitutionParametersOutputProducts = SubstitutionParametersProductDescriptionOfMainProduct(
		"ManufacturedProducts",
		"ProductKind",
		"Products",
		"Characteristic");
	QueryText = StrReplace(QueryText, "&OutputProductsSourceOfProducts",   SubstitutionParametersOutputProducts.SourceProduct);
	QueryText = StrReplace(QueryText, "&OutputProductsSourceSpecifications", SubstitutionParametersOutputProducts.SourceCharacteristics);
	
	SubstitutionParametersInputProducts  = SubstitutionParametersProductDescriptionOfMainProduct(
		"InputProducts",
		"MainProductProductKind",
		"MainProductProducts",
		"MainProductCharacteristic");
	QueryText = StrReplace(QueryText, "&InputProductsSourceOfProducts",   SubstitutionParametersInputProducts.SourceProduct);
	QueryText = StrReplace(QueryText, "&InputProductsSourceCharacteristics", SubstitutionParametersInputProducts.SourceCharacteristics);
	
	Return QueryText;
	
EndFunction

Function SubstitutionParametersProductDescriptionOfMainProduct(
	TableName,
	SourceTypeOfProduct = "ProductKind",
	SourceProduct = "Products",
	SourceCharacteristics = "Characteristic")
	
	Result = New Structure;
	
	TextOfProductsField = TextOfExpressionProductField(
		TableName,
		SourceTypeOfProduct,
		SourceProduct);
		
	TextOfCharacteristicField = TextOfFieldExpressionCharacteristicsOfMainProduct(
		TableName,
		SourceTypeOfProduct,
		SourceProduct,
		SourceCharacteristics);
		
	Result.Insert("SourceProduct",   TextOfProductsField);
	Result.Insert("SourceCharacteristics", TextOfCharacteristicField);
	
	Return Result;
	
EndFunction

Function TextOfExpressionProductField(
	TableName,
	SourceTypeOfProduct = "ProductKind",
	SourceProduct = "Products")

	FieldText = "
	|CASE
	|	WHEN TabularSection.Products = VALUE(Catalog.Products.EmptyRef)
	|		AND TabularSection.ProductKind = TTProductData_.Products.ProductKind
	|		THEN TTProductData_.Products
	|	ELSE TabularSection.Products
	|END
	|";
	
	FieldText = StrReplace(FieldText, "TabularSection.ProductKind", TableName + "." + SourceTypeOfProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Products",    TableName + "." + SourceProduct);
	
	Return FieldText;
	
EndFunction

Function TextOfFieldExpressionCharacteristicsOfMainProduct(
	TableName,
	SourceTypeOfProduct = "ProductKind",
	SourceProduct = "Products",
	SourceCharacteristics = "Characteristic")
	
	FieldText = "
	|CASE
	|	WHEN TabularSection.Products = VALUE(Catalog.Products.EmptyRef)
	|		AND TabularSection.ProductKind = TTProductData_.Products.ProductKind
	|		THEN TTProductData_.Characteristic
	|	WHEN TabularSection.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		THEN TabularSection.Characteristic
	|	WHEN TabularSection.Products = TTProductData_.Products
	|		THEN TTProductData_.Characteristic
	|	ELSE VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|END"; 
	
	FieldText = StrReplace(FieldText, "TabularSection.ProductKind", TableName + "." + SourceTypeOfProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Products",    TableName + "." + SourceProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Characteristic",  TableName + "." + SourceCharacteristics);
	
	Return FieldText;
	
EndFunction

Function TextOfFieldExpressionCharacteristicsOfMainProductCenter(
	TableName,
	SourceTypeOfProduct = "ProductKind",
	SourceProduct = "Products",
	SourceCharacteristics = "Characteristic")
	
	FieldText = "
	|ISNULL(CASE
	|	WHEN
	|		TabularSection.ProductKind.SettingsOfPriceKeyByItemVariant = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|		THEN VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|	ELSE CASE
	|	WHEN TabularSection.Products = VALUE(Catalog.Products.EmptyRef)
	|		AND TabularSection.ProductKind = TTProductData_.Products.ProductKind
	|		THEN TTProductData_.Characteristic.ItemsCharacteristicForPricing
	|	WHEN TabularSection.Characteristic <> VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|		THEN TabularSection.Characteristic.ItemsCharacteristicForPricing
	|	WHEN TabularSection.Products = TTProductData_.Products
	|		THEN TTProductData_.Characteristic.ItemsCharacteristicForPricing
	|	ELSE VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef)
	|END
	|END, VALUE(Catalog.ItemsCharacteristicsForPricing.EmptyRef))"; 
	
	FieldText = StrReplace(FieldText, "TabularSection.ProductKind", TableName + "." + SourceTypeOfProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Products",    TableName + "." + SourceProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Characteristic",  TableName + "." + SourceCharacteristics);
	
	Return FieldText;
	
EndFunction

Function TextOfFieldExpressionPackagingTCOOfMainProduct(
	TableName,
	SourceTypeOfProduct = "ProductKind",
	SourceProduct = "Products",
	SourcePackaging = "Package")
	
	FieldText = "
	|CASE
	|	WHEN TabularSection.ProductKind.SettingsOfPriceKeyByPackage = VALUE(Enum.FilterOptionForPriceKey.DontUse)
	|		THEN VALUE(Catalog.PackagesAndUnitsOfMeasure.EmptyRef)
	|	ELSE TabularSection.Package
	|END"; 
	
	FieldText = StrReplace(FieldText, "TabularSection.ProductKind", TableName + "." + SourceTypeOfProduct);
	FieldText = StrReplace(FieldText, "TabularSection.Package",  TableName + "." + SourcePackaging);
	
	Return FieldText;
	
EndFunction

Function QueryTextNestedSpecifications()
	
	QueryText =
	"SELECT
	|	Table.Ref AS Ref,
	|	Table.BillOfMaterials AS BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials.ManufacturedProducts AS Table
	|WHERE
	|	Table.Ref IN (&Specifications)
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.BillOfMaterials AS BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials.RecyclableWaste AS Table
	|WHERE
	|	Table.Ref IN (&Specifications)
	|	AND Table.ProcessByBOM
	|	AND Table.BillOfMaterials <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.SourceOfSemiFinishedProduct AS BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref IN (&Specifications)
	|	AND Table.ProducedInProcess
	|	AND Table.MethodOfReceivingMaterial = VALUE(Enum.MethodsOfReceivingBOMMaterials.ProduceByBillsOfMaterials)
	|	AND Table.SourceOfSemiFinishedProduct <> VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Ref AS Ref,
	|	Table.BillOfMaterialsRM AS BillOfMaterials
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS Table
	|WHERE
	|	Table.Ref IN (&Specifications)
	|	AND Table.ProducedInProcess
	|	AND Table.BillOfMaterialsRM <> VALUE(Catalog.BillsOfMaterials.EmptyRef)";
	
	Return QueryText;
	
EndFunction
Function RequestTextSpecificationMaterialsIncludingKitComposition(TableName) Export

	QueryText = "
	|SELECT
	|	ResourceSpecificationsMaterialsAndServices.Products AS Products,
	|	ResourceSpecificationsMaterialsAndServices.Characteristic AS Characteristic,
	|	MAX(ProductKitConfigurations.Ref) AS ItemKitConfiguration
	|INTO TTBasicConfigurationOfProductRange
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS ResourceSpecificationsMaterialsAndServices
	|		INNER JOIN &SpecificationTable_ AS SpecificationTable_
	|		ON (SpecificationTable_.BillOfMaterials = ResourceSpecificationsMaterialsAndServices.Ref)
	|			AND (ResourceSpecificationsMaterialsAndServices.Products.ItemsType = VALUE(Enum.ItemsTypes.Set))
	|		LEFT JOIN Catalog.ProductKitConfigurations AS ProductKitConfigurations
	|		ON ResourceSpecificationsMaterialsAndServices.Products = ProductKitConfigurations.Owner
	|			AND ResourceSpecificationsMaterialsAndServices.Characteristic = ProductKitConfigurations.Characteristic
	|			AND (NOT ProductKitConfigurations.DeletionMark)
	|
	|GROUP BY
	|	ResourceSpecificationsMaterialsAndServices.Products,
	|	ResourceSpecificationsMaterialsAndServices.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TTBasicConfigurationOfProductRange.Products AS Products,
	|	TTBasicConfigurationOfProductRange.Characteristic AS Characteristic,
	|	ConfigurationOptionsForProductRange.Products AS Accessories,
	|	ConfigurationOptionsForProductRange.Characteristic AS CharacteristicsOfComponent,
	|	ConfigurationOptionsForProductRange.Package AS Package,
	|	ConfigurationOptionsForProductRange.NumberOfPackages AS NumberOfPackages,
	|	ConfigurationOptionsForProductRange.Count AS Count
	|INTO TTCompositionOfSets
	|FROM
	|	TTBasicConfigurationOfProductRange AS TTBasicConfigurationOfProductRange
	|		INNER JOIN Catalog.ProductKitConfigurations.Goods AS ConfigurationOptionsForProductRange
	|		ON TTBasicConfigurationOfProductRange.ItemKitConfiguration = ConfigurationOptionsForProductRange.Ref
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ResourceSpecificationsMaterialsAndServices.Ref AS Ref,
	|	ResourceSpecificationsMaterialsAndServices.Stage AS Stage,
	|	ISNULL(TTCompositionOfSets.Accessories, ResourceSpecificationsMaterialsAndServices.Products) AS Products,
	|	ISNULL(TTCompositionOfSets.Characteristic, ResourceSpecificationsMaterialsAndServices.Characteristic) AS Characteristic,
	|	ISNULL(TTCompositionOfSets.Package, ResourceSpecificationsMaterialsAndServices.Package) AS Package,
	|	ResourceSpecificationsMaterialsAndServices.NumberOfPackages
	|		* ISNULL(&QueryTextPackagingFactor, 1)
	|		* ISNULL(TTCompositionOfSets.NumberOfPackages, 1)                              AS NumberOfPackages,
	|	ResourceSpecificationsMaterialsAndServices.NumberOfPackages
	|		* ISNULL(&QueryTextPackagingFactor, 1)
	|		* ISNULL(TTCompositionOfSets.Count, 1)                                      AS Count
	|INTO MaterialsAndServicesSpecifications
	|FROM
	|	Catalog.BillsOfMaterials.MaterialsAndServices AS ResourceSpecificationsMaterialsAndServices
	|		INNER JOIN &SpecificationTable_ AS SpecificationTable_
	|		ON (SpecificationTable_.BillOfMaterials = ResourceSpecificationsMaterialsAndServices.Ref)
	|		LEFT JOIN TTCompositionOfSets AS TTCompositionOfSets
	|		ON ResourceSpecificationsMaterialsAndServices.Products = TTCompositionOfSets.Products
	|			AND ResourceSpecificationsMaterialsAndServices.Characteristic = TTCompositionOfSets.Characteristic
	|			AND (ResourceSpecificationsMaterialsAndServices.Products.ItemsType = VALUE(Enum.ItemsTypes.Set))
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTBasicConfigurationOfProductRange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP TTCompositionOfSets";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ResourceSpecificationsMaterialsAndServices.Package",
			"ResourceSpecificationsMaterialsAndServices.Products"));
			
	Return StrReplace(QueryText, "&SpecificationTable_", TableName);
	
EndFunction

Function ParametersForSubstitutingOrderToWarehouseField(TableName = "TabularSection", SourceOfProducts = "",  SoftwareFillingOption = Undefined)
	
	FieldText       = "FALSE";
	JoinText = "";
	
	
	Return New Structure("FieldText, JoinText", FieldText, JoinText);
	
EndFunction

// The text of the schedule field substitution.
// 
// Parameters:
//  SourceOfDispatcherDivision - String - Source Of Dispatcher Division
//  SourceOfProducts - String - Source Of Products
//  SourceOfSemiFinishedProduct - String - Source of semi-finished product
// 
// Returns:
//  String - Text Of The Schedule Field Substitution
Function TextOfScheduleFieldSubstitution(SourceOfDispatcherDivision = "", SourceOfProducts = "", SourceOfSemiFinishedProduct = "") Export
	
	FieldText = "
	|	CASE 
	|		WHEN (&ProductionDispatcherBusinessUnit = VALUE(Catalog.BusinessStructure.EmptyRef) 
	|				OR ISNULL(CatSupplyMethod.SourceOfDemandSupply, VALUE(Catalog.BusinessStructure.EmptyRef))
	|					IN (&ProductionDispatcherBusinessUnit,
	|						UNDEFINED,
	|						VALUE(Catalog.BusinessStructure.EmptyRef)))
	|				AND ISNULL(CatSupplyMethod.SupplyType, VALUE(Enum.SupplyTypes.EmptyRef)) = VALUE(Enum.SupplyTypes.Production)
	|			THEN TRUE
	|		ELSE FALSE
	|	END";
	
	If Not IsBlankString(SourceOfProducts) Then
		
		FieldText = StrReplace(FieldText, "MaterialsAndServices.Products", SourceOfProducts);
		
	EndIf;
	
	If Not IsBlankString(SourceOfSemiFinishedProduct) Then
		
		FieldText = StrReplace(FieldText, "MaterialsAndServices.SourceOfSemiFinishedProduct", SourceOfSemiFinishedProduct);
		
	EndIf;
	
	If Not IsBlankString(SourceOfDispatcherDivision) Then
		
		FieldText = StrReplace(FieldText, "&ProductionDispatcherBusinessUnit", SourceOfDispatcherDivision);
		
	EndIf;
	
	Return FieldText;
	
EndFunction

Function RequestTextAvailablePackagingSpecificationsForProductType(AutoComplete = False) Export
	
	QueryTexts = New Array;
	
	QueryText = "
	|SELECT
	|	PackagesAndUnitsOfMeasure.Owner      AS PackagingGroup,
	|	PackagesAndUnitsOfMeasure.Ref        AS Ref,
	|	PackagesAndUnitsOfMeasure.Presentation AS Presentation
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	PackagesAndUnitsOfMeasure.Owner = VALUE(Catalog.PackagingGroups.BasicUnitsOfMeasure)
	|	AND &FilterSearchString
	|
	|";
	
	If Not AutoComplete Then
		QueryText = QueryText + "
		|ORDER BY
		|	Presentation
		|";
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	QueryText = "
	|SELECT
	|	PackagesAndUnitsOfMeasure.Owner      AS PackagingGroup,
	|	PackagesAndUnitsOfMeasure.Ref        AS Ref,
	|	PackagesAndUnitsOfMeasure.Presentation AS Presentation
	|FROM
	|	Catalog.PackagesAndUnitsOfMeasure AS PackagesAndUnitsOfMeasure
	|WHERE
	|	CAST(PackagesAndUnitsOfMeasure.Owner AS Catalog.PackagingGroups).Predefined = FALSE
	|	AND &UseItemPackages
	|	AND &FilterSearchString
	|
	|";
	
	If Not AutoComplete Then
		QueryText = QueryText + "
		|ORDER BY
		|	PackagingGroup,
		|	Ref HIERARCHY,
		|	Presentation
		|AUTOORDER
		|";
	EndIf;
	
	QueryTexts.Add(QueryText);
	
	If AutoComplete Then
		QueryText = StrConcat(QueryTexts, Chars.LF + "UNION ALL" + Chars.LF);
		QueryText = StrReplace(QueryText, "&FilterSearchString", "PackagesAndUnitsOfMeasure.Description LIKE &SearchString");
		QueryText = QueryText + "
			|ORDER BY
			|	Presentation
			|";
		QueryText = StrReplace(QueryText,
			"SELECT",
			"SELECT TOP 10"); //@query-part-1 @query-part-2
	Else
		QueryText = StrConcat(QueryTexts, Chars.LF + ";" + Chars.LF);
		QueryText = StrReplace(QueryText, "&FilterSearchString", "TRUE");
	EndIf;
	
	Return QueryText;
	
EndFunction

Function SubstitutionTextAttributeCalculationIsResourceParameterization(SourceOfSpecification = "") Export
	
	QueryText = " FALSE ";
	QueryText = "
	|	(
	|			TRUE IN (
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BillsOfMaterials.MaterialsAndServices AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref
	|					AND (
	|						CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|						OR CASE
	|							WHEN TabularSection.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm)
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|			)
	|			
	|			OR TRUE IN (
	|			
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BillsOfMaterials.ManufacturedProducts AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref
	|					AND (
	|						CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|						OR CASE
	|							WHEN TabularSection.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm)
	|									THEN TRUE
	|							ELSE FALSE
	|						END)
	|			)
	|			
	|			OR TRUE IN (
	|			
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BillsOfMaterials.RecyclableWaste AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref
	|					AND (
	|						CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|						OR CASE
	|							WHEN TabularSection.MethodOfProductsAutoselection = VALUE(Enum.MethodsOfProductAutoSelection.SpecifiedInProductsProperty)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.AutomaticallySelectedByProductsProperties)
	|								OR TabularSection.MethodOfItemVariantAutoselection = VALUE(Enum.MethodsOfItemVariantAutoselection.PickedByAlgorithm)
	|								THEN TRUE
	|							ELSE FALSE
	|						END)
	|			)
	|			
	|			OR TRUE IN (
	|			
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BillsOfMaterials.LaborCosts AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref
	|					AND CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100)) <> """"
	|				
	|			)
	|			
	|			OR TRUE IN (
	|
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.BillsOfMaterials.SelectionByProperties AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref
	|			)
	|			
	|			OR TRUE IN (
	|			
	|				SELECT TOP 1
	|						TRUE
	|					FROM
	|						Catalog.ProductionStages.WorkCenterTypes AS TabularSection
	|					WHERE
	|						Table.Ref = TabularSection.Ref.Owner
	|						AND NOT (CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100))) = """"
	|						AND NOT TabularSection.Ref.DeletionMark
	|			)
	|			
	|			OR TRUE IN (
	|	
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductionStages.AlternateWorkCenterTypes AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref.Owner
	|					AND NOT (CAST(TabularSection.QuantityCalculationAlgorithm AS STRING(100))) = """"
	|					AND NOT TabularSection.Ref.DeletionMark
	|			)
	|			
	|			OR TRUE IN (
	|
	|				SELECT TOP 1
	|					TRUE
	|				FROM
	|					Catalog.ProductionStages.SelectionByProperties AS TabularSection
	|				WHERE
	|					Table.Ref = TabularSection.Ref.Owner
	|			)
	|	)
	|";
	
	If Not IsBlankString(SourceOfSpecification) Then
		QueryText = StrReplace(QueryText, "Table.Ref", SourceOfSpecification);
	EndIf;
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

Function EventLogEvent() Export
	
	Return NStr("vi = 'Nhận dữ liệu bảng kê chi tiết các nguồn lực sản xuất';
				|ru = 'Получение данных спецификации';
				|en = 'Receiving BOM data'; fa = 'Receiving BOM data';
				|it = 'Ottenimento dei dati della specifica';
				|pl = 'Odbiór danych specyfikacji';
				|tr = 'Ürün reçetesi verilerinin alınması'", Common.DefaultLanguageCode());
	
EndFunction

Function MainProductSpecificationDataStructure() Export
	
	Result = New Structure;
	
	Result.Insert("ProductKind", PredefinedValue("Catalog.ItemKinds.EmptyRef"));
	Result.Insert("Products", PredefinedValue("Catalog.Products.EmptyRef"));
	Result.Insert("Characteristic", PredefinedValue("Catalog.ItemsCharacteristics.EmptyRef"));
	
	Result.Insert("Count", 0);
	Result.Insert("NumberOfPackages", 0);
	
	Result.Insert("Package", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	Result.Insert("PackageData", ProductDataManagementCached.PackingDataStructure());
	
	Result.Insert("UnitOfMeasure", PredefinedValue("Catalog.PackagesAndUnitsOfMeasure.EmptyRef"));
	Result.Insert("PieceUnitOfMeasure", False);
	Result.Insert("PackagingPiece", False);
	
	Result.Insert("ItemsType", PredefinedValue("Enum.ItemsTypes.OwnGoods"));
	Result.Insert("AnalyticalGroup", PredefinedValue("Catalog.AnalyticalInventoryGroups.EmptyRef"));
	
	Result.Insert("ItemVariantsAreUsed", False);
	Result.Insert("AnyCharacteristic", False);
	
	Result.Insert("BillOfMaterials", PredefinedValue("Catalog.BillsOfMaterials.EmptyRef"));
	Result.Insert("AssignmentOption", PredefinedValue("Enum.BillOfMaterialsAssignmentOptions.EmptyRef"));
	
	Result.Insert("DefectiveGoodsRate", 0);

	Result.Insert("Stage", PredefinedValue("Catalog.ProductionStages.EmptyRef"));
	Result.Insert("StageSubdivision", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	
	Result.Insert("ThisIsMainProduct", False);
	
	// service details
	Result.Insert("NumberOfPackagesPerUnitOfProductionBatch", 0);
	Result.Insert("ConversionFactorToMainProduct", 1);
	
	// details for compatibility
	Result.Insert("Department", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Result.Insert("ProductionDispatcherBusinessUnit", PredefinedValue("Catalog.BusinessStructure.EmptyRef"));
	Result.Insert("LineOfBusiness", PredefinedValue("Catalog.LinesOfBusiness.EmptyRef"));
	Result.Insert("ProductionStart", '00010101');
	Result.Insert("DemandDate", '00010101');
	Result.Insert("DaysFromDemand", 0);
	
	Return Result;
	
EndFunction

Procedure GetFirstAndLastStage(Owner, FirstStage, LastStage, AttributesList = "", OnlyStagesOfProduction = False) Export
	
	QueryText = "
	|SELECT
	|	MIN(NestedQuery.StageNumber) AS StageNumber
	|INTO NumberOfFirstStage
	|FROM (
	|	SELECT
	|		1 AS StageNumber
	|	WHERE
	|		NOT &OnlyStagesOfProduction
	|	
	|	UNION ALL
	|
	|	SELECT
	|		ProductionStages.StageNumber AS StageNumber
	|	FROM
	|		Catalog.ProductionStages AS ProductionStages
	|	WHERE
	|		ProductionStages.Owner = &Owner
	|		AND NOT ProductionStages.DeletionMark
	|		AND NOT ProductionStages.WorkPlanning
	|		AND &OnlyStagesOfProduction) AS NestedQuery
	|
	|;
	|
	|SELECT
	|	ProductionStages.Ref                                      AS Ref,
	|	&AttributesList,
	|	ProductionStages.StageNumber = NumberOfFirstStage.StageNumber   AS FirstStage,
	|	ProductionStages.NextStageNo = 0                    AS LastStage
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|	
	|	FULL JOIN NumberOfFirstStage
	|	ON TRUE
	|
	|WHERE
	|	ProductionStages.Owner = &Owner
	|	AND NOT ProductionStages.DeletionMark
	|	AND (ProductionStages.StageNumber = NumberOfFirstStage.StageNumber
	|		OR ProductionStages.NextStageNo = 0)
	|	AND (NOT &OnlyStagesOfProduction
	|		OR NOT ProductionStages.WorkPlanning)
	|
	|";
	
	TextAttributes     = "";
	If ValueIsFilled(AttributesList) Then
		For Each AttributeName In StrSplit(AttributesList, ",") Do
			TextAttributes = TextAttributes + StrTemplate("ProductionStages.%1,", AttributeName);
			FirstStage.Insert(AttributeName);
			LastStage.Insert(AttributeName);
		EndDo;
	EndIf;
	QueryText = StrReplace(QueryText, "&AttributesList,", TextAttributes);
	
	Query = New Query(QueryText);
	Query.SetParameter("Owner", Owner);
	Query.SetParameter("OnlyStagesOfProduction", OnlyStagesOfProduction);
	
	QueryResult = Query.Execute();
	Selection = QueryResult.Select();
	
	While Selection.Next() Do
		
		If Selection.FirstStage Then
			FillPropertyValues(FirstStage, Selection);
		EndIf; 
		
		If Selection.LastStage Then
			FillPropertyValues(LastStage, Selection);
		EndIf; 
		
	EndDo;
	
EndProcedure
Procedure GetFirstAndLastOperations(Ref, FirstOperations, RecentOperations) Export
	
	Query = New Query("
	|SELECT
	|	ProductionStages.Ref AS Stage,
	|	
	|	MAX(CASE WHEN ManufacturingOperations.OperationNumber = 1 THEN
	|		ManufacturingOperations.Ref
	|	ELSE
	|		VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|	END)                   AS FirstOperation,
	|	MAX(CASE WHEN ManufacturingOperations.NextOperation = 0 THEN
	|		ManufacturingOperations.Ref
	|	ELSE
	|		VALUE(Catalog.ManufacturingOperations.EmptyRef)
	|	END)                   AS LastOperation_
	|	
	|FROM
	|	Catalog.ProductionStages AS ProductionStages
	|
	|		LEFT JOIN Catalog.ManufacturingOperations AS ManufacturingOperations
	|		ON ProductionStages.Ref = ManufacturingOperations.Owner
	|			AND NOT ManufacturingOperations.DeletionMark
	|			AND (ManufacturingOperations.OperationNumber = 1
	|				OR ManufacturingOperations.NextOperation = 0)
	|WHERE
	|	ProductionStages.Owner = &Owner
	|	AND NOT ProductionStages.DeletionMark
	|
	|GROUP BY
	|	ProductionStages.Ref");
	
	Query.SetParameter("Owner", Ref);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		FirstOperations.Insert(Selection.Stage, Selection.FirstOperation);
		RecentOperations.Insert(Selection.Stage, Selection.LastOperation_);
		
	EndDo;
	
EndProcedure
#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.BillsOfMaterials.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.14";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("91171b90-bc3f-4e33-82fb-4aa23c051930");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Catalogs.BillsOfMaterials.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Điền mục tin kỹ thuật:
	|	- ""Không bao gồm lựa chọn tự động trong chứng từ"".';
	|ru = 'Заполняет технические реквизиты:
	|	- ""Исключить автоматический выбор в документах"".';
	|en = 'Fills in technical attributes:
	|	- ""Exclude automatic selection in documents"".'; fa = 'Fills in technical attributes:
	|	- ""Exclude automatic selection in documents"".';
	|it = 'Fills in technical attributes:
	|	- ""Exclude automatic selection in documents"".';
	|pl = 'Fills in technical attributes:
	|	- ""Exclude automatic selection in documents"".';
	|tr = 'Teknik bilgileri doldurur:
	|	- ""Belgelerde otomatik seçimi hariç tut"".'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.BillsOfMaterials.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.BillsOfMaterials.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
EndProcedure

// Registers links to update processing.
// 
// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Catalog.BillsOfMaterials";
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	Query = New Query(
		"SELECT
		|	BillsOfMaterials.Ref AS Ref
		|FROM
		|	Catalog.BillsOfMaterials AS BillsOfMaterials
		|WHERE
		|	NOT BillsOfMaterials.DeleteOptionOfPickingToDocuments = VALUE(Enum.DeleteOptionsOfPickingBOMsToDocuments.Automatically)
		|	AND NOT BillsOfMaterials.ExcludeAutomaticSelection");
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Catalog.BillsOfMaterials";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	For Each String In UpdatedData Do
		
		BeginTransaction();
		
		Try
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", String.Ref);
			Block.Lock();
			
			CatalogObject = String.Ref.GetObject();
			
			If CatalogObject = Undefined Then
				InfobaseUpdate.MarkProcessingCompletion(String.Ref);
				CommitTransaction();
				Continue;
			EndIf;
			
			If Not CatalogObject.DeleteOptionOfPickingToDocuments = Enums.DeleteOptionsOfPickingBOMsToDocuments.Automatically Then
				CatalogObject.ExcludeAutomaticSelection = True;
			EndIf;
			
			If CatalogObject.Modified() Then
				InfobaseUpdate.WriteData(CatalogObject);
			Else
				InfobaseUpdate.MarkProcessingCompletion(CatalogObject);
			EndIf;
			
			CommitTransaction();
		Except
			RollbackTransaction();
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), String.Ref);
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
