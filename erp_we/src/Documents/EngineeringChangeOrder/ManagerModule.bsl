#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Generates a description of the object's details, which are filled in based on their usage statistics.
// 
// Parameters:
//  AttributesDetails1 - Structure - description of the details to get values for using statistics
//
//
Procedure EnterDescriptionOfDetailsToFillInBasedOnStatistics(AttributesDetails1) Export
	
	Parameters = ObjectsFillingByStatistics.ParametersOfBankingDetailsToFillIn();
	Parameters.StatisticsCollectionSections.UseAlways = "EmployeeResponsible";
	ObjectsFillingByStatistics.AddDescriptionOfDetailsToFillIn(AttributesDetails1,
		"ReplacementPriority", Parameters);
			
EndProcedure

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("Nsiproduction");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentRef, DocumentObject - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  See DocumentsPosting.InitializeDocumentDataForPosting
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.EngineeringChangeOrder") Then
		DocumentRef = Document.Ref;
	Else
		DocumentRef = Document;
	EndIf;
	
	Query			= New Query;
	QueryTexts	= New ValueList;
	
	If Not AddlParameters.GetQueryTexts Then
		////////////////////////////////////////////////////////////////////////////
		// Create a motion initialization request
		
		FillInInitializationParameters(Query, DocumentRef);
		
		////////////////////////////////////////////////////////////////////////////
		// Let's form the request text
		
		QueryTextTableAlternativeMaterials(Query, QueryTexts, Registers);
		QueryTextScopesOfSubstitutes(Query, QueryTexts, Registers);
	EndIf;
	
	////////////////////////////////////////////////////////////////////////////
	// We will get tables for movements
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	BusinessProcesses.ApprovalOfEngineeringChangeOrders.AddGenerateCommand(GenerationCommands);
	
EndProcedure

// Adds the "permission to replace materials" document creation command.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined -
//
Function AddGenerateCommand(GenerationCommands) Export
	
	If AccessRight("Insert", Metadata.Documents.EngineeringChangeOrder) Then
		
		CreateBasedOnCommand = GenerationCommands.Add();
		CreateBasedOnCommand.Manager = Metadata.Documents.EngineeringChangeOrder.FullName();
		CreateBasedOnCommand.Presentation = TMCommonUse.ObjectPresentation(Metadata.Documents.EngineeringChangeOrder);
		CreateBasedOnCommand.WriteMode = "Post";
		CreateBasedOnCommand.FunctionalOptions = "UseAlternativeMaterials";
		
		Return CreateBasedOnCommand;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	
	
EndProcedure

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
EndProcedure

// Standard subsystems.Versioning objects
// Defines object settings for the object Versioning subsystem.
//
// Parameters:
// Settings - Structure - subsystem settings.
Procedure OnDefineObjectVersioningSettings(Settings) Export
EndProcedure
// End StandardSubsystems.ObjectsVersioning

#Region InterfaceImplementation

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

#EndRegion

#Region Private

#Region Posting

Function AdditionalDataSourcesForRegisteredRecords(RegisterName) Export

	DataSources = New Map;

	Return DataSources; 

EndFunction

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	Query.SetParameter("Ref", DocumentRef);
	Query.Text =
	"SELECT
	|	MAX(CASE
	|			WHEN AreasOfAction.ProductionOrder IN (VALUE(Document.ProductionOrder2_2.EmptyRef), 
	|														 UNDEFINED)
	|				THEN 0
	|			ELSE 10000000
	|		END + CASE
	|			WHEN AreasOfAction.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|				THEN 0
	|			ELSE 1000000
	|		END + CASE
	|			WHEN AreasOfAction.BillOfMaterials = VALUE(Catalog.BillsOfMaterials.EmptyRef)
	|				THEN 0
	|			ELSE 100000
	|		END + CASE
	|			WHEN AreasOfAction.Stage = VALUE(Catalog.ProductionStages.EmptyRef)
	|				THEN 0
	|			ELSE 10000
	|		END + CASE
	|			WHEN AreasOfAction.ItemVariantOfProduct = VALUE(Catalog.ItemsCharacteristics.EmptyRef)
	|				THEN CASE
	|						WHEN AreasOfAction.Product = VALUE(Catalog.Products.EmptyRef)
	|							THEN 0
	|						ELSE 100
	|					END
	|			ELSE 1000
	|		END + CASE
	|			WHEN AreasOfAction.Department = VALUE(Catalog.BusinessStructure.EmptyRef)
	|				THEN 0
	|			ELSE 10
	|		END + CASE
	|			WHEN AreasOfAction.LineOfBusiness = VALUE(Catalog.LinesOfBusiness.EmptyRef)
	|				THEN 0
	|			ELSE 1
	|		END) AS Priority
	|FROM
	|	Document.EngineeringChangeOrder.AreasOfAction AS AreasOfAction
	|WHERE
	|	AreasOfAction.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	EngineeringChangeOrder.ValidityStartDate AS ValidityStartDate,
	|	EngineeringChangeOrder.ValidityEndDate AS ValidityEndDate,
	|	EngineeringChangeOrder.Status AS Status,
	|	EngineeringChangeOrder.ReplacementOption AS ReplacementOption,
	|	EngineeringChangeOrder.InterchangeableSubstitutes AS InterchangeableSubstitutes,
	|	EngineeringChangeOrder.ReplacementPriority AS ReplacementPriority,
	|	EngineeringChangeOrder.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	EngineeringChangeOrder.Posted AS Posted
	|FROM
	|	Document.EngineeringChangeOrder AS EngineeringChangeOrder
	|WHERE
	|	EngineeringChangeOrder.Ref = &Ref";
	
	ResultsArray = Query.ExecuteBatch();
	IndexOf = ResultsArray.UBound();
	
	HeaderAttributes = ResultsArray[IndexOf].Select();
	TSAttributes = ResultsArray[IndexOf - 1].Select();
	
	HeaderAttributes.Next();
	TSAttributes.Next();
	
	Query.SetParameter("Priority",                 TSAttributes.Priority);
	Query.SetParameter("Status",                    HeaderAttributes.Status);
	Query.SetParameter("ValidityStartDate",        HeaderAttributes.ValidityStartDate);
	Query.SetParameter("ValidityEndDate",     HeaderAttributes.ValidityEndDate);
	Query.SetParameter("ReplacementOption",             HeaderAttributes.ReplacementOption);
	Query.SetParameter("InterchangeableSubstitutes",   HeaderAttributes.InterchangeableSubstitutes);
	Query.SetParameter("ReplacementPriority",           HeaderAttributes.ReplacementPriority);
	Query.SetParameter("Posted",                  HeaderAttributes.Posted);
	
	Query.SetParameter("UseItForAutocorrectInOrders",
		HeaderAttributes.UseItForAutocorrectInOrders);
		
EndProcedure

Function QueryTextTableAlternativeMaterials(Query, QueryTexts, Registers)

	RegisterName = "AlternativeMaterials";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT
	|	&Ref AS Resolution,
	|	&ValidityStartDate AS Period,
	|	&ValidityEndDate AS EndPeriod,
	|	&ReplacementPriority AS ReplacementPriority,
	|	&UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	UsedMaterials.Products AS Products,
	|	UsedMaterials.Characteristic AS Characteristic,
	|	UsedMaterials.RowID AS RowID,
	|	UsedMaterials.NumberOfPackages AS NumberOfPackages,
	|	ISNULL(&QueryTextPackingFactorMaterial, 1) * UsedMaterials.NumberOfPackages AS Count,
	|	UsedMaterials.Package AS Package,
	|	CASE
	|		WHEN &ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SubstituteList)
	|				OR &InterchangeableSubstitutes
	|			THEN VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
	|		ELSE VALUE(Enum.SubstituteRoles.Material)
	|	END AS ProductsRole,
	|	&Priority AS ScopeMaxPriority
	|FROM
	|	Document.EngineeringChangeOrder.UsedMaterials AS UsedMaterials
	|WHERE
	|	UsedMaterials.Ref = &Ref
	|	AND &Posted
	|	AND &Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)
	|
	|UNION ALL
	|
	|SELECT
	|	&Ref,
	|	&ValidityStartDate,
	|	&ValidityEndDate,
	|	&ReplacementPriority,
	|	&UseItForAutocorrectInOrders,
	|	Substitutes.Products,
	|	Substitutes.Characteristic,
	|	Substitutes.RowID,
	|	Substitutes.NumberOfPackages,
	|	ISNULL(&QueryTextPackingFactorAnalog, 1) * Substitutes.NumberOfPackages,
	|	Substitutes.Package,
	|	CASE
	|		WHEN &InterchangeableSubstitutes
	|			THEN VALUE(Enum.SubstituteRoles.InterchangeableSubstitute)
	|		ELSE VALUE(Enum.SubstituteRoles.Substitute)
	|	END,
	|	&Priority
	|FROM
	|	Document.EngineeringChangeOrder.Substitutes AS Substitutes
	|WHERE
	|	Substitutes.Ref = &Ref
	|	AND &Posted
	|	AND &Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)
	|	AND &ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SetToSet)";
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackingFactorMaterial",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"UsedMaterials.Package",
		"UsedMaterials.Products"));
	
	QueryText = StrReplace(QueryText,
		"&QueryTextPackingFactorAnalog",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
		"Substitutes.Package",
		"Substitutes.Products"));
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

Function QueryTextScopesOfSubstitutes(Query, QueryTexts, Registers)

	RegisterName = "ScopesOfSubstitutes";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf; 
	
	QueryText = 
	"SELECT DISTINCT
	|	AreasOfAction.Ref AS Resolution,
	|	AreasOfAction.LineOfBusiness AS LineOfBusiness,
	|	AreasOfAction.Department AS Department,
	|	AreasOfAction.Product AS Product,
	|	AreasOfAction.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	AreasOfAction.ProductionOrder AS ProductionOrder,
	|	AreasOfAction.BillOfMaterials AS BillOfMaterials,
	|	AreasOfAction.Stage AS Stage,
	|	AreasOfAction.SalesOrder AS SalesOrder
	|FROM
	|	Document.EngineeringChangeOrder.AreasOfAction AS AreasOfAction
	|WHERE
	|	AreasOfAction.Ref = &Ref
	|	AND &Posted
	|	AND &Status = VALUE(Enum.StatusesOfEngineeringChangeOrders.Confirmed)";
	
	QueryTexts.Add(QueryText, RegisterName);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region Other

#Region SubstitutionOfMaterialsWithAlternativeMaterials

Procedure SelectionOfAnaloguesFillInData(Parameters, StorageAddress) Export

	OperationName = "Document.EngineeringChangeOrder.ManagerModule.SelectionOfAnaloguesFillInData";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(OperationName);
	
	Data = SelectionOfAnalogsFillInDataInsideTimeMeasurement(Parameters);
	
	PutToTempStorage(Data, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, 1);
	
EndProcedure

Function SelectionOfAnalogsFillInDataInsideTimeMeasurement(Parameters)
	
	GeneralParameters = Parameters.GeneralParameters;
	GoodsParameters = Parameters.GoodsParameters;
	SubstitutesParameters = Parameters.SubstitutesParameters;
	ReFilling_ = Parameters.ReFilling_;
	PermissionValidityDate = Parameters.PermissionValidityDate;
	UsedMaterials = Parameters.UsedMaterials;
	Substitutes = Parameters.Substitutes;
	RemnantsOfAnalogues = Parameters.RemnantsOfAnalogues;
	TableOfGoods = Parameters.TableOfGoods;
	ConsiderInventory = Parameters.ConsiderInventory;
	InventoryTable = Parameters.InventoryTable;
	ParametersTable = Parameters.ParametersTable;
	
	If TableOfGoods.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	GoodsTogetherWithParameters = GoodsParameters.GoodsTogetherWithParameters;
	
	ReturnStructure = New Structure();
	ReturnStructure.Insert("ReFilling_", ReFilling_);
	ReturnStructure.Insert("ArrayOfLineNumbers", Parameters.ArrayOfLineNumbers);
	ReturnStructure.Insert("FormAttributes", New Structure());
	
	If ReFilling_ Then
		ParametersTable.FillValues(PermissionValidityDate, "PermissionValidityDate");
	Else
		
		UsedMaterials.Clear();

		PermissionValidityDate = ParametersTable[0].PermissionValidityDate;
		PermissionsValidityDateBeforeChange = PermissionValidityDate;
		ReturnStructure.FormAttributes.Insert("PermissionValidityDate", PermissionValidityDate);
		ReturnStructure.FormAttributes.Insert("PermissionsValidityDateBeforeChange", PermissionsValidityDateBeforeChange);
		
	EndIf;
	
	Substitutes.Clear();
	Inventories = New ValueTable;
	
	GetWarehouseFromChina = Not SubstitutesParameters.Property("Warehouse") Or SubstitutesParameters.Warehouse = Undefined;
	SelectionFromWarehouseFromFormParameters = Not GetWarehouseFromChina;
	ReturnStructure.FormAttributes.Insert("SelectionFromWarehouseFromFormParameters", SelectionFromWarehouseFromFormParameters);
	
	SelectionParameters_2 = New Structure("ApplyInventoryTable, GetBalancesAtOtherWarehouses", ConsiderInventory, True);
	
	ArrayOfTexts = New Array;
	ArrayOfTexts.Add(AlternativeMaterials.QueryTextGoods());
	ArrayOfTexts.Add(AlternativeMaterials.QueryTextTableOfMaterials());
	ArrayOfTexts.Add(AlternativeMaterials.QueryTextTableOfAnalogues(GetWarehouseFromChina));
	ArrayOfTexts.Add(AlternativeMaterials.QueryTextTableLeftovers(SelectionParameters_2));
	ArrayOfTexts.Add(ProductDataManagement.QueryTextPackageData_(StrSplit("TableOfMaterials,TableOfAnalogues",",")));
	ArrayOfTexts.Add(RequestTextForFillingInTables());
	
	Query = New Query;
	Query.Text = StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());
	
	Query.SetParameter("Goods", TableOfGoods);
	
	If ConsiderInventory Then
		
		TableRowFilter = New Structure("ThisIsRemainder,ThisIsDocumentWarehouse", True, True);
		InventoryWithSelection = InventoryTable.Copy(TableRowFilter);
		Inventories = InventoryWithSelection;
		Query.SetParameter("Inventories", InventoryWithSelection);
		
	EndIf;
	
	If Not GoodsTogetherWithParameters Then
		
		Query.SetParameter("ParametersTable", ParametersTable);
	
	EndIf;
	
	Query.SetParameter(
		?(GetWarehouseFromChina And SubstitutesParameters.Property("Warehouse"), "DefaultWarehouse", "Warehouse"),
		?(GetWarehouseFromChina And SubstitutesParameters.Property("Warehouse"), Catalogs.Warehouses.DefaultWarehouse(), SubstitutesParameters.Warehouse)); 
	
	Try
	
		ResultsArray = Query.ExecuteBatch();
	
	Except
		
		ExceptionText = NStr("vi = 'Không thể lấy dữ liệu về các vật liệu tương tự có sẵn: %1. Vui lòng liên hệ với quản trị viên.';
							|ru = 'Не удалось получить данные о доступных аналогах материалов: %1 Обратитесь к администратору.';
							|en = 'Cannot get data on available substitutes: %1 Contact the administrator.'; fa = 'Cannot get data on available substitutes: %1 Contact the administrator.';
							|it = 'Cannot get data on available substitutes: %1 Contact the administrator.';
							|pl = 'Cannot get data on available substitutes: %1 Contact the administrator.';
							|tr = 'Mevcut ikame malzeme verileri alınamadı: %1 Yöneticiye başvurun.'");
		
		ExceptionText = StringFunctionsClientServer.SubstituteParametersToString(ExceptionText, ErrorProcessing.BriefErrorDescription(ErrorInfo()));
		Raise ExceptionText;
		
	EndTry;
	
	PermissionMaterialsTable = ResultsArray[ResultsArray.UBound() - 2].Unload();
	PermissionMaterialsTable.Indexes.Add("Resolution, KeyPermission");
	PermissionMaterialsTable.Indexes.Add("Resolution, ControlMultiplier");
	
	TableOfAnalogPermissions = ResultsArray[ResultsArray.UBound() - 1].Unload();
	TableOfAnalogPermissions.Indexes.Add("Resolution, KeyPermission");
	
	RemnantsOfAnalogues.Clear();
	
	SelectionOfBalancesByDestination = ResultsArray[ResultsArray.UBound() - 3].Select();
	While SelectionOfBalancesByDestination.Next() Do
	
		NewRow = RemnantsOfAnalogues.Add();
		FillPropertyValues(NewRow, SelectionOfBalancesByDestination);
		NewRow.AvailableForInventoryAllocation = SelectionOfBalancesByDestination.WarehouseStockBalance;
	
	EndDo;
	
	BalancesOfAnaloguesInOtherWarehouses = ResultsArray[ResultsArray.UBound() - 4].Unload();
	
	Packing_DataTable = ResultsArray[ResultsArray.UBound() - 5].Unload();
	ProductDataManagement.FillInPackingDataInDataset(PermissionMaterialsTable, Packing_DataTable);
	ProductDataManagement.FillInPackingDataInDataset(TableOfAnalogPermissions, Packing_DataTable);
	
	DataResolution = New Structure("PermissionMaterialsTable, TableOfAnalogPermissions, Resolution, InterchangeableSubstitute, Key",
		 								PermissionMaterialsTable, TableOfAnalogPermissions);
			
	If ConsiderInventory Then
		
		InventorySelectionFields = "Products, Characteristic, Purpose, WithAssignment, Warehouse";
		
		InventoryTable.Indexes.Add(InventorySelectionFields);
		StockSelection = New Structure(InventorySelectionFields);
		
	EndIf;
	
	IndicatorsInventoryAllocation = IndicatorsInventoryAllocation();
	HintFieldsIndicators = HintFieldsIndicators();
		
	LineNumberMaterials = 0;
	LineNumberAnalogues = 0;
	SampleProducts_ = ResultsArray[ResultsArray.UBound()].Select(QueryResultIteration.ByGroups);
	
	While SampleProducts_.Next() Do
		
		If ReFilling_ Then
			
			NewMaterials = UsedMaterials.FindRows(New Structure("OriginalLineNumber", SampleProducts_.OriginalLineNumber))[0];
			FillPropertyValues(NewMaterials, SampleProducts_, "ThereAreSubstituteMaterials");
			
			LineNumberMaterials = NewMaterials.LineNumber;
			
		Else	
			
			LineNumberMaterials = LineNumberMaterials + 1;
			
			NewMaterials = UsedMaterials.Add();
			FillPropertyValues(NewMaterials, SampleProducts_);
			NewMaterials.LineNumber = LineNumberMaterials;
			NewMaterials.ConnectionKey = ConnectionKey(SampleProducts_.OriginalLineNumber);
			
			If ConsiderInventory Then
			
				InventoryStateInStock = Enums.InventoryStates.InStock;
				InventoryStateInStockUnblocking = Enums.InventoryStates.AvailablePendingUnlocking;
				StateOfInventoryIsExpectedToBeReceived = Enums.InventoryStates.ExpectedForReceiptWithoutLock;
				StateOfInventoryIsExpectedToBeReceivedWithLock = Enums.InventoryStates.ExpectedForReceiptWithLock;
				StateUnderApproval = Enums.InventoryStates.PendingSupplyApproval;
				StateOfInventoryIsNotSecured = Enums.InventoryStates.NotProvided;
				
				CharacteristicsOfNeedToReserve = Enums.DemandCharacteristics.ReserveAtWarehouse;
				CharacteristicsOfNeedToReserveAsNeeded = Enums.DemandCharacteristics.ReserveAsReceived;
				CharacteristicsOfNeedToPostpone = Enums.DemandCharacteristics.SnoozeReservation;
				CharacteristicsOfNeedForProvision = Enums.DemandCharacteristics.ToSupply;
				CharacteristicsOfNeedNotToProvide = Enums.DemandCharacteristics.NotProvide;
				
				FillPropertyValues(StockSelection, SampleProducts_);
				
				ArrayOfInventoryRows = InventoryTable.FindRows(StockSelection); 
				For Each InventoryLine In ArrayOfInventoryRows Do
					
					ColumnName = Undefined;
					If InventoryLine.ThisIsRemainder And Not InventoryLine.ThisIsDocumentWarehouse Then
						ColumnName = "RemainingBalanceInOtherWarehouses";
					ElsIf (InventoryLine.InventoryState = InventoryStateInStock
									Or InventoryLine.InventoryState = InventoryStateInStockUnblocking)
								And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserve
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded) Then
						ColumnName = "InReserve";
					ElsIf (InventoryLine.InventoryState = InventoryStateInStock
									Or InventoryLine.InventoryState = InventoryStateInStockUnblocking)
								And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
						ColumnName = "SuppliedOnWarehouse";
					ElsIf (InventoryLine.InventoryState = StateOfInventoryIsExpectedToBeReceived
									Or InventoryLine.InventoryState = StateOfInventoryIsExpectedToBeReceivedWithLock
									Or InventoryLine.InventoryState = StateUnderApproval)
								And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
						ColumnName = "SuppliedByDate";
					ElsIf InventoryLine.InventoryState = StateOfInventoryIsNotSecured
								And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
									Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
						ColumnName = "ToSupply_";
					ElsIf InventoryLine.DemandCharacteristic = CharacteristicsOfNeedNotToProvide Then
						ColumnName = "NotProvide";
					EndIf;
					
					If ColumnName <> Undefined And IndicatorsInventoryAllocation.Property(ColumnName) Then
						NewMaterials[ColumnName] = InventoryLine.Count;
					EndIf;
				
				EndDo;
				
				If Not SampleProducts_.WithAssignment
				   And ValueIsFilled(SampleProducts_.Purpose) Then
				
					StockSelection.Purpose = Catalogs.Assignments.EmptyRef();
					ArrayOfInventoryRows = InventoryTable.FindRows(StockSelection); 
					For Each InventoryLine In ArrayOfInventoryRows Do
						
						ColumnName = Undefined;
						If InventoryLine.ThisIsRemainder And Not InventoryLine.ThisIsDocumentWarehouse Then
							ColumnName = "RemainingBalanceInOtherWarehouses";
						ElsIf (InventoryLine.InventoryState = InventoryStateInStock
										Or InventoryLine.InventoryState = InventoryStateInStockUnblocking)
									And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserve
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded) Then
							ColumnName = "InReserve";
						ElsIf (InventoryLine.InventoryState = InventoryStateInStock
										Or InventoryLine.InventoryState = InventoryStateInStockUnblocking)
									And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
							ColumnName = "SuppliedOnWarehouse";
						ElsIf (InventoryLine.InventoryState = StateOfInventoryIsExpectedToBeReceived
										Or InventoryLine.InventoryState = StateOfInventoryIsExpectedToBeReceivedWithLock
										Or InventoryLine.InventoryState = StateUnderApproval)
									And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
							ColumnName = "SuppliedByDate";
						ElsIf InventoryLine.InventoryState = StateOfInventoryIsNotSecured
									And (InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToReserveAsNeeded
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedToPostpone
										Or InventoryLine.DemandCharacteristic = CharacteristicsOfNeedForProvision) Then
							ColumnName = "ToSupply_";
						ElsIf InventoryLine.DemandCharacteristic = CharacteristicsOfNeedNotToProvide Then
							ColumnName = "NotProvide";
						EndIf;
						
						If ColumnName <> Undefined And IndicatorsInventoryAllocation.Property(ColumnName) Then
							NewMaterials[ColumnName] = NewMaterials[ColumnName] + InventoryLine.Count;
						EndIf;
					
					EndDo;
				
				EndIf;
			
			EndIf;
			
			NewMaterials.HintIndicators = HintIndicators(NewMaterials, HintFieldsIndicators);
		
		EndIf;
		
		If NewMaterials.ThereAreSubstituteMaterials Then
			
			ProductData_1 = New Structure("OriginalLineNumber, Products, Characteristic");
			FillPropertyValues(ProductData_1, NewMaterials);
			
			Selection = SampleProducts_.Select();
			
			HintData = HintDataStructure(Selection.Count());
			
			While Selection.Next() Do
				
				DataResolution.Resolution = Selection.Resolution;
				DataResolution.InterchangeableSubstitute = Selection.InterchangeableSubstitute;
				DataResolution.Key = Selection.KeyProducts_;
				
				ProcessPermission(DataResolution, ProductData_1, HintData, LineNumberAnalogues, GeneralParameters, Substitutes);
				
			EndDo;	
			
			NewMaterials.TipReplacementOption = HintData.Text;
			
		EndIf;
		
	EndDo;
	
	ReturnStructure.Insert("UsedMaterials", UsedMaterials);
	ReturnStructure.Insert("Substitutes", Substitutes);
	ReturnStructure.Insert("Inventories", Inventories);
	ReturnStructure.Insert("RemnantsOfAnalogues", RemnantsOfAnalogues);
	ReturnStructure.Insert("BalancesOfAnaloguesInOtherWarehouses", BalancesOfAnaloguesInOtherWarehouses);
		
	Return ReturnStructure;
	
EndFunction

Procedure ProcessPermission(ParametersResolution, ProductParameters_, HintParameters, LineNumber, GeneralParameters, Substitutes)
	
	IDCommunicationKey = ProductParameters_.OriginalLineNumber;
	
	FilterStructure1 = New Structure("Resolution", ParametersResolution.Resolution);
	NomenclatureSelectionStructure = New Structure("Resolution, KeyPermission", ParametersResolution.Resolution, ParametersResolution.Key);
	
	DataResolution = 
		New Structure("Substitutes, UsedMaterials, ControlMultiplier",
			ParametersResolution.TableOfAnalogPermissions.FindRows(NomenclatureSelectionStructure),
			ParametersResolution.PermissionMaterialsTable.FindRows(NomenclatureSelectionStructure),
			ParametersResolution.PermissionMaterialsTable.FindRows(
				New Structure("Resolution, ControlMultiplier", ParametersResolution.Resolution, True)).Count() > 0);
	
	RowsArray = Substitutes.FindRows(FilterStructure1);
	If RowsArray.Count() > 0 Then
		
		For Each StringAnalogues In RowsArray Do
			
			StringAnalogues.LinkKeyPermission = StringAnalogues.LinkKeyPermission + ConnectionKey(IDCommunicationKey, False);
			
			If Not StringAnalogues.ThisIsASubstitute 
			   And StringAnalogues.Products = ProductParameters_.Products 
			   And StringAnalogues.Characteristic = ProductParameters_.Characteristic Then
			   
				StringAnalogues.ConnectionKey = 
					StringAnalogues.ConnectionKey + ConnectionKey(IDCommunicationKey, Not ValueIsFilled(StringAnalogues.ConnectionKey)); 
					
			EndIf;
				
		EndDo;
		
	Else	
		AddPermission(DataResolution, ProductParameters_, HintParameters, ConnectionKey(IDCommunicationKey), LineNumber, Substitutes);
	EndIf;
	
	If ParametersResolution.InterchangeableSubstitute Then
	
		FilterStructure1.Insert("IsBalance", True);
		RowsArray = Substitutes.FindRows(FilterStructure1);
		IsBalance = RowsArray.Count() > 0;
		
	Else	
		
		RowsArray = Substitutes.FindRows(FilterStructure1);
		IsBalance = RowsArray[0].IsBalance;
		
	EndIf;
	
	If Not HintParameters.IsBalance Then
		
		HintParameters.IsBalance = IsBalance;
		
		NewMaterials = DataResolution.UsedMaterials[0];
		StringAnalogues = DataResolution.Substitutes[0];
		
		MaterialsOfNormativeStorage = NewMaterials.NormativeStandard
			* NewMaterials.PackageData.Numerator / NewMaterials.PackageData.Denominator;
		AnaloguesOfStorageStandards = StringAnalogues.NormativeStandard
			* StringAnalogues.PackageData.Numerator / StringAnalogues.PackageData.Denominator;
		
		If HintParameters.PermissionsCount = 1
		   And DataResolution.UsedMaterials.Count() = 1 
		   And DataResolution.Substitutes.Count() = 1 
		   And MaterialsOfNormativeStorage = 1
		   And AnaloguesOfStorageStandards = 1 Then
		   	HintOption = String(StringAnalogues.Products);
		Else
			HintOption = Format(HintParameters.PermissionsCount, "NG=") + " " + HintParameters.RowOption;
		EndIf;
		
		If GeneralParameters.ShowBalance Then
			
			ToolTipBalance =
				?(HintParameters.IsBalance, NStr("vi = 'có số dư';
												|ru = 'есть остатки';
												|en = 'there is balance'; fa = 'there is balance';
												|it = 'ci sono residui';
												|pl = 'są pozostałości';
												|tr = 'bakiye mevcut'"), NStr("vi = 'không có số dư';
																					|ru = 'нет остатков';
																					|en = 'no balance'; fa = 'no balance';
																					|it = 'non ci sono residui';
																					|pl = 'brak pozostałości';
																					|tr = 'bakiye mevcut değil'"));
			
			HintParameters.Text = StrTemplate("%1; %2", HintOption, ToolTipBalance);
			
		Else
			HintParameters.Text = StrTemplate("%1", HintOption);
		EndIf;
			
	EndIf;
	
EndProcedure	

Procedure AddPermission(ParametersResolution, NomenclatureParameters, HintParameters, ConnectionKey, LineNumber, Substitutes)
	
	ResolutionPresentation = "";
	IsBalance = False;
	
	For Each StringAnalogues In ParametersResolution.Substitutes Do
		
		LineNumber = LineNumber + 1;
		
		TableRow = Substitutes.Add();
		
		If Not ValueIsFilled(ResolutionPresentation) Then
			
			ResolutionPresentation = StrTemplate(
				"%1 %2 %3 %4", "№", StringAnalogues.Number, NStr("vi = 'ngày';
																|ru = 'от';
																|en = 'from'; fa = 'از';
																|it = 'del';
																|pl = 'z dn.';
																|tr = 'tarih'"), Format(StringAnalogues.Date, "DLF=D"));
			
			TableRow.DisplayPermission = True;
			
		EndIf;
		
		If StringAnalogues.InterchangeableSubstitute Then
			TableRow.ResolutionPresentation = ResolutionPresentation;
		EndIf;
		
		TableRow.IsBalance = StringAnalogues.StockAvailabilityRatio >= 1;
		If Not IsBalance And TableRow.IsBalance Then
			IsBalance = True;
		EndIf;
		
		FillPropertyValues(TableRow, StringAnalogues);
		FillPropertyValues(TableRow, ParametersResolution, "ControlMultiplier");
		
		TableRow.IsBalance = IsBalance;
		TableRow.LineNumber = LineNumber;
		TableRow.LinkKeyPermission = ConnectionKey;
		
		TableRow.NormativeStandardPresentation = StandardPresentation(TableRow.NormativeStandard
			* TableRow.PackageData.Numerator / TableRow.PackageData.Denominator);
			
		TableRow.WarehouseAccordingToSecurityScheme = TableRow.Warehouse;
		
	EndDo;
	
	For Each NewMaterials In ParametersResolution.UsedMaterials Do
		
		LineNumber = LineNumber + 1;
		
		TableRow = Substitutes.Add();
		
		FillPropertyValues(TableRow, NewMaterials);
		FillPropertyValues(TableRow, ParametersResolution, "ControlMultiplier");
		
		StorageStandards = TableRow.NormativeStandard * TableRow.PackageData.Numerator / TableRow.PackageData.Denominator;
		
		TableRow.NormativeStandardPresentation   = StandardPresentation(StorageStandards);
		
		TableRow.ResolutionPresentation = ResolutionPresentation 
			+ ?(StorageStandards = 1, 
				"", 
				StrTemplate(NStr("vi = '%1 (để thay thế %2 %3)';
								|ru = '%1(на замену %2 %3)';
								|en = '%1(for replacement%2%3)'; fa = '%1(for replacement%2%3)';
								|it = '%1(per la sostituzione %2 %3)';
								|pl = '%1 (na zastąpienie %2 %3)';
								|tr = '%1(%3 %2 değişime)'"), 
						  " ", TableRow.NormativeStandardPresentation, TableRow.UnitOfMeasurePresentation));
			  
		TableRow.IsBalance = IsBalance;
		TableRow.LineNumber = LineNumber;
		TableRow.LinkKeyPermission = ConnectionKey;
		
		If TableRow.Products = NomenclatureParameters.Products 
		   And TableRow.Characteristic = NomenclatureParameters.Characteristic Then
			TableRow.ConnectionKey = ConnectionKey;
		EndIf;
		
		TableRow.WarehouseAccordingToSecurityScheme = TableRow.Warehouse;
		
	EndDo;
	
EndProcedure	

Function RequestTextForFillingInTables()
	
	QueryText =
	"SELECT
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Purpose AS Purpose,
	|	BalanceTable.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	BalanceTable.CountBalance AS AvailableForInventoryAllocation
	|FROM
	|	TableOfBalancesAtOtherWarehouses AS BalanceTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	BalanceTable.Products AS Products,
	|	BalanceTable.Characteristic AS Characteristic,
	|	BalanceTable.Warehouse AS Warehouse,
	|	BalanceTable.Purpose AS Purpose,
	|	BalanceTable.Purpose <> VALUE(Catalog.Assignments.EmptyRef) AS WithAssignment,
	|	BalanceTable.CountBalance AS WarehouseStockBalance
	|FROM
	|	BalanceTable AS BalanceTable
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfMaterials.Resolution AS Resolution,
	|	TableOfMaterials.Ref AS KeyPermission,
	|	TableOfMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute) AS InterchangeableSubstitute,
	|	TableOfMaterials.Products AS Products,
	|	TableOfMaterials.Characteristic AS Characteristic,
	|	TableOfMaterials.NumberOfPackages AS NormativeStandard,
	|	TableOfMaterials.Package AS Package,
	|	UNDEFINED AS PackageData,
	|	TableOfMaterials.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ControlMultiplier,
	|	TableOfMaterials.Products.Presentation AS ProductsPresentation,
	|	TableOfMaterials.Characteristic.Presentation AS CharacteristicPresentation,
	|	TableOfMaterials.Products.UnitOfMeasure.Presentation AS UnitOfMeasurePresentation,
	|	TRUE AS PermissionIsAvailable
	|FROM
	|	TableOfMaterials AS TableOfMaterials
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TableOfAnalogues.Resolution AS Resolution,
	|	TableOfAnalogues.Ref AS KeyPermission,
	|	TableOfAnalogues.LineNumberAnalog AS LineNumberAnalog,
	|	TableOfAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute) AS InterchangeableSubstitute,
	|	CASE
	|		WHEN VALUETYPE(TableOfAnalogues.Resolution) = TYPE(Document.EngineeringChangeOrder)
	|			THEN CAST(TableOfAnalogues.Resolution AS Document.EngineeringChangeOrder).Number
	|		WHEN VALUETYPE(TableOfAnalogues.Resolution) = TYPE(Document.RegisterAdjustment)
	|			THEN CAST(TableOfAnalogues.Resolution AS Document.RegisterAdjustment).Number
	|	END AS Number,
	|	CASE
	|		WHEN VALUETYPE(TableOfAnalogues.Resolution) = TYPE(Document.EngineeringChangeOrder)
	|			THEN CAST(TableOfAnalogues.Resolution AS Document.EngineeringChangeOrder).Date
	|		WHEN VALUETYPE(TableOfAnalogues.Resolution) = TYPE(Document.RegisterAdjustment)
	|			THEN CAST(TableOfAnalogues.Resolution AS Document.RegisterAdjustment).Date
	|	END AS Date,
	|	TableOfAnalogues.Products AS Products,
	|	TableOfAnalogues.Products.ItemsType = VALUE(Enum.ItemsTypes.Work_5) AS ThisIsWork,
	|	TableOfAnalogues.Characteristic AS Characteristic,
	|	TableOfAnalogues.NumberOfPackages AS NormativeStandard,
	|	TableOfAnalogues.Package AS Package,
	|	UNDEFINED AS PackageData,
	|	TableOfAnalogues.Warehouse AS Warehouse,
	|	SUM(ISNULL(BalanceTable.CountBalance, 0)) AS WarehouseStockBalance,
	|	SUM(ISNULL(BalanceTable.CountBalance, 0)) AS StockBalanceConfirmed,
	|	SUM(ISNULL(BalanceTable.CountBalance, 0) / (TableOfAnalogues.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1))) AS StockAvailabilityRatio,
	|	TRUE AS ThisIsASubstitute,
	|	TRUE AS PermissionIsAvailable
	|FROM
	|	TableOfAnalogues AS TableOfAnalogues
	|		LEFT JOIN BalanceTable AS BalanceTable
	|		ON TableOfAnalogues.Products = BalanceTable.Products
	|			AND TableOfAnalogues.Characteristic = BalanceTable.Characteristic
	|			AND TableOfAnalogues.Warehouse = BalanceTable.Warehouse
	|
	|GROUP BY
	|	TableOfAnalogues.Resolution,
	|	TableOfAnalogues.Ref,
	|	TableOfAnalogues.LineNumberAnalog,
	|	TableOfAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute),
	|	TableOfAnalogues.NumberOfPackages,
	|	TableOfAnalogues.Package,
	|	TableOfAnalogues.Characteristic,
	|	TableOfAnalogues.Products,
	|	TableOfAnalogues.Warehouse
	|
	|ORDER BY
	|	LineNumberAnalog
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Goods.LineNumber AS OriginalLineNumber,
	|	Goods.Ref AS KeyProducts_,
	|	Goods.Products AS Products,
	|	Goods.Products.Presentation AS ProductsPresentation,
	|	Goods.Products.UnitOfMeasure.Presentation AS UnitOfMeasurePresentation,
	|	Goods.Characteristic AS Characteristic,
	|	Goods.Characteristic.Presentation AS CharacteristicPresentation,
	|	Goods.Purpose AS Purpose,
	|	Goods.WithAssignment AS WithAssignment,
	|	Goods.Count AS ToReplace,
	|	Goods.Count AS CountByDocument,
	|	Goods.TotalCount1 AS ByDocumentTotal,
	|	Goods.Warehouse AS Warehouse,
	|	TableOfMaterials.Resolution IS NOT NULL AS ThereAreSubstituteMaterials,
	|	TableOfMaterials.Resolution AS Resolution,
	|	TableOfMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute) AS InterchangeableSubstitute,
	|	TableOfMaterials.Priority AS Priority,
	|	CASE
	|		WHEN TableOfMaterials.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
	|			THEN 1
	|		WHEN TableOfMaterials.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)
	|			THEN 2
	|		ELSE 10
	|	END AS PriorityAccordingToInstructionsForReplacement,
	|	TableOfMaterials.Period AS Period
	|FROM
	|	Goods AS Goods
	|		LEFT JOIN TableOfMaterialsByPurpose AS TableOfMaterials
	|		ON Goods.LineNumber = TableOfMaterials.LineNumberOfGoods
	|
	|ORDER BY
	|	OriginalLineNumber,
	|	PriorityAccordingToInstructionsForReplacement,
	|	Priority DESC,
	|	Period DESC,
	|	Resolution DESC
	|TOTALS
	|	MAX(Products),
	|	MAX(ProductsPresentation),
	|	MAX(UnitOfMeasurePresentation),
	|	MAX(Characteristic),
	|	MAX(CharacteristicPresentation),
	|	MAX(Purpose),
	|	MAX(WithAssignment),
	|	MAX(ToReplace),
	|	MAX(CountByDocument),
	|	MAX(ByDocumentTotal),
	|	MAX(Warehouse),
	|	MAX(ThereAreSubstituteMaterials)
	|BY
	|	OriginalLineNumber";
	
	QueryText = StrReplace(QueryText, "&QueryTextPackagingFactor",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"TableOfAnalogues.Package",
			"TableOfAnalogues.Products"));
	
	Return QueryText;
	
EndFunction

Function HintFieldsIndicators()
	
	IndicatorFields_ = IndicatorsInventoryAllocation();
	
	IndicatorData_ = New Array;
	
	IndicatorName = "ByDocumentTotal";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "ToSupply_";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "RemainingBalanceInOtherWarehouses";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "SuppliedOnWarehouse";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "SuppliedByDate";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "InReserve";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	IndicatorName = "NotProvide";
	IndicatorData_.Add(New Structure("Name, Presentation", IndicatorName, IndicatorFields_[IndicatorName]));
	
	Return IndicatorData_;
	
EndFunction

Function IndicatorsInventoryAllocation()
	
	IndicatorFields_ = New Structure;
	IndicatorFields_.Insert("ByDocumentTotal",       NStr("vi = 'Tổng số';
															|ru = 'Всего';
															|en = 'Total'; fa = 'جمع کل';
															|it = 'In totale';
															|pl = 'Total';
															|tr = 'Toplam'"));
	IndicatorFields_.Insert("ToSupply_",             NStr("vi = 'Cung cấp';
															|ru = 'Обеспечить';
															|en = 'Supply'; fa = 'Supply';
															|it = 'Approvvigionare';
															|pl = 'Supply';
															|tr = 'Sağla'"));
	IndicatorFields_.Insert("RemainingBalanceInOtherWarehouses", NStr("vi = 'Trong các kho khác';
																		|ru = 'На других складах';
																		|en = 'At other warehouses'; fa = 'در سایر انبارها';
																		|it = 'In altri magazzini';
																		|pl = 'W innych magazynach';
																		|tr = 'Başka ambarlarda'"));
	IndicatorFields_.Insert("SuppliedOnWarehouse",      NStr("vi = 'Đảm bảo';
															|ru = 'Обеспечено';
															|en = 'Supplied'; fa = 'عرضه‌شده';
															|it = 'Approvvigionato';
															|pl = 'Supplied';
															|tr = 'Temin edildi'"));
	IndicatorFields_.Insert("SuppliedByDate",         NStr("vi = 'Trong lịch biểu';
															|ru = 'В графике';
															|en = 'In schedule'; fa = 'In schedule';
															|it = 'Nel grafico';
															|pl = 'W harmonogramie';
															|tr = 'Programda'"));
	IndicatorFields_.Insert("InReserve",               NStr("vi = 'Dự phòng';
															|ru = 'Резерв';
															|en = 'Reserve'; fa = 'رزرو';
															|it = 'Riservato';
															|pl = 'Reserve';
															|tr = 'Rezerv'"));
	IndicatorFields_.Insert("NotProvide",         NStr("vi = 'Không đảm bảo';
														|ru = 'Не обеспечивать';
														|en = 'Do not supply'; fa = 'تأمین نشود';
														|it = 'Non approvvigionare';
														|pl = 'Nie zapewniać';
														|tr = 'Tedarik etme'"));
	
	Return IndicatorFields_;
	
EndFunction	

Function ConnectionKey(Id, Full = True) Export
	
	LinkKeyValue = 
		?(TypeOf(Id) = Type("Number"),
			?(Full,
				Format(Id, NStr("vi = 'ЧГ=; ЧФ='';Ч;''';
								|ru = 'ЧГ=; ЧФ='';Ч;''';
								|en = 'NG=; NF='';N;'''; fa = 'NG=; NF='';N;''';
								|it = 'ЧГ=; ЧФ='';Ч;''';
								|pl = 'NG=; NF='';N;''';
								|tr = 'NG=; NF='';N;'''")),
				Format(Id, NStr("vi = 'ЧГ=; ЧФ='';Ч;''';
								|ru = 'ЧГ=; ЧФ=''Ч;''';
								|en = 'NG=; NF=''N;'''; fa = 'NG=; NF=''N;''';
								|it = 'ЧГ=; ЧФ=''Ч;''';
								|pl = 'NG=; NF=''N;''';
								|tr = 'NG=; NF=''N;'''"))),
			StrTemplate(?(Full, ";%1;", "%1;"), Id));
	
	Return LinkKeyValue;
	
EndFunction

Function HintIndicators(TableRow, HintFieldsIndicators)
			
	TextTemplate1 = "%1%2";
	ToolTipText = TextTemplate1;
	
	FirstIteration = True;
	
	For Each HintField In HintFieldsIndicators Do
		
		IndicatorValue = TableRow[HintField.Name];
		
		If ValueIsFilled(IndicatorValue) Then
			
			IndicatorPresentation = HintField.Presentation;
			
			If FirstIteration Then
				
				IndicatorPresentation = StrTemplate("%1 (%2)",
													IndicatorPresentation,
													TableRow.UnitOfMeasurePresentation);
				
				FirstIteration = False;
				
			EndIf;
			
			ToolTipText = StrTemplate(ToolTipText,
										StrTemplate("%1: %2; ", IndicatorPresentation, IndicatorValue),
										TextTemplate1);
			
		EndIf;	
		
	EndDo;
	
	Return Left(ToolTipText, StrLen(ToolTipText) - StrLen(TextTemplate1) - 2);
	
EndFunction

Function HintDataStructure(PermissionsCount)
	
	RowOption = TMCommonUseClientServer.DeclensionOfWord(
		PermissionsCount, NStr("vi = 'phương án, phương án, phương án, m';
								|ru = 'вариант, варианта, вариантов, м';
								|en = 'option, options'; fa = 'option, options';
								|it = 'вариант, варианта, вариантов, м';
								|pl = 'option, options';
								|tr = 'seçenek, seçenek, seçenekler, m'"));
	
	HintData = New Structure;
	HintData.Insert("Text", "");
	HintData.Insert("PermissionsCount", PermissionsCount);
	HintData.Insert("IsBalance", False);
	HintData.Insert("RowOption", RowOption);
	
	Return HintData;
	
EndFunction

Function StandardPresentation(NormativeStandard)
	
	CurStandard = NormativeStandard;
	For Digits = 0 To 15 Do
		If Int(CurStandard) = CurStandard Then
			Break;
		EndIf;
		CurStandard = CurStandard * 10;
	EndDo;
	
	Return Format(NormativeStandard, StrTemplate("NFD=%1;", Max(3, Digits)));
	
EndFunction

#EndRegion

#Region ReplacementWizard

Function AssistantForPerformingSubstitutionsIsAvailable() Export
	
	UseProductionManagement2_2 = True;
	
	
	Return UseProductionManagement2_2;
	
EndFunction

Procedure DataOfStagesToReplace(Parameters, StorageAddress) Export

	OperationName = "Document.EngineeringChangeOrder.ManagerModule.DataOfStagesToReplace";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(OperationName);
	
	DocumentsData = DataOfProductionStagesForSelectionOfAnalogues(Parameters);
	
	PutToTempStorage(DocumentsData, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DocumentsData.Stages.Count());
	
EndProcedure

Function DataOfProductionStagesForSelectionOfAnalogues(Parameters)
	
	If ValueIsFilled(Parameters.Stage) Then
	
		Return DataOfAssistantWhenCallingFromDocument(Parameters);
	
	EndIf;
	
	RoleOfAnalogues = Parameters.RoleOfAnalogues;
	Resolution = Parameters.Resolution;
	Stages = Parameters.Stages;
	ReplacementPriority = Parameters.ReplacementPriority;
	SelectionOfInterchangeableAnalogues = (RoleOfAnalogues = Enums.SubstituteRoles.InterchangeableSubstitute);
	
	QueryText = Documents.EngineeringChangeOrder.QueryTextForFillingInReplacementWizard(RoleOfAnalogues);
	Query = New Query(QueryText);
	Query.SetParameter("Resolution", Resolution);
	Query.SetParameter("Period", BegOfDay(CurrentSessionDate()));
	
	ResultsArray = Query.ExecuteBatch();
	ResultDocuments = ResultsArray[ResultsArray.UBound()];
	ResultStandards = ResultsArray[ResultsArray.UBound() - 1];
	PackingResult = ResultsArray[ResultsArray.UBound() - 2];
	
	TableOfStandards = ResultStandards.Unload();
	Packing_DataTable = PackingResult.Unload();
	
	ProductDataManagement.FillInPackingDataInDataset(TableOfStandards, Packing_DataTable);
	
	MaterialsTableTemplate = TableOfStandards.Copy(New Structure("ThisIsMaterial", True), "Products, Characteristic");
	CurrentMaterials = MaterialsTableTemplate;
	CurrentKey = 0;
	Delete_Position = False;
	ArrayOfAddedRows = New Array;
	
	Selection = ResultDocuments.Select();
	
	CurrentValueIsSeparate = Undefined;
	CurrentWarehouse = Undefined;
	CurrentStep = Undefined;
	CurAssignment = Undefined;
	DetachedSet = False;
	MaterialSearchStructure = New Structure("Products, Characteristic");
	
	While Selection.Next() Do
		
		KeyFieldsChanged = ?(SelectionOfInterchangeableAnalogues, True, 
			Selection.Stage <> CurrentStep
			Or Selection.Warehouse <> CurrentWarehouse 
			Or Selection.Purpose <> CurAssignment 
			Or Selection.WithAssignment <> CurrentValueIsSeparate);
		
		If KeyFieldsChanged Then
			
			If CurrentMaterials.Count() > 0 Then
				Delete_Position = True;
			EndIf;
			
			If Delete_Position Then
				TMCommonUse.DeleteTableRows(Stages, ArrayOfAddedRows);
			Else
				CheckInstallKey(CurrentMaterials, ArrayOfAddedRows, CurrentKey, DetachedSet);
			EndIf;
			
			Delete_Position = False;
			ArrayOfAddedRows.Clear();
			CurrentKey = CurrentKey + 1;
			CurrentMaterials = MaterialsTableTemplate.Copy();
			CurrentStep = Selection.Stage;
			CurAssignment = Selection.Purpose;
			CurrentValueIsSeparate = Selection.WithAssignment;
		
		EndIf;
		
		TSRow = Stages.Add();
		FillPropertyValues(TSRow, Selection);
		ProductDataManagement.FillInPackingDataInDataSetRow(TSRow, Packing_DataTable);
		
		TSRow.ItemVariantsAreUsed = ValueIsFilled(TSRow.Characteristic);
		
		TSRow.OrderPresentation = StrTemplate(NStr("vi = 'Số %1 ngày %2 (%3)';
													|ru = '№%1 от %2 (%3)';
													|en = 'No.%1 dated %2 (%3)'; fa = 'No.%1 dated %2 (%3)';
													|it = '№%1 от %2 (%3)';
													|pl = 'nr%1 z dn. %2 (%3)';
													|tr = '%2 tarihli %1 numaralı (%3)'"),
			TSRow.OrderNumber,
			Format(TSRow.OrderDate, "DLF=D"),
			TSRow.PresentationStage);
			
		If TSRow.WithAssignment Then
			DetachedSet = True;
		EndIf;
		
		If TSRow.Total = TSRow.Shipped Then
			Delete_Position = True;
		EndIf;
		
		ArrayOfAddedRows.Add(TSRow);
		FillPropertyValues(MaterialSearchStructure, Selection);
		Rows = CurrentMaterials.FindRows(MaterialSearchStructure);
		TMCommonUse.DeleteTableRows(CurrentMaterials, Rows);
	
	EndDo;
	
	If CurrentMaterials.Count() > 0 Then
		Delete_Position = True;
	EndIf;
	
	If Delete_Position Then
		TMCommonUse.DeleteTableRows(Stages, ArrayOfAddedRows);
	Else
		CheckInstallKey(CurrentMaterials, ArrayOfAddedRows, CurrentKey, DetachedSet);	
	EndIf;
	
	Return New Structure("Stages, Standards", Stages, TableOfStandards);
	
EndFunction

Function DataOfAssistantWhenCallingFromDocument(Parameters)
	
	Stage = Parameters.Stage;
	Substitutes = Parameters.Substitutes;
	
	TableFromDocument = Parameters.GoodsFromDocument;
	InventoryTable = Parameters.InventoryTable;
	ApplyInventoryTable = InventoryTable <> Undefined;
	
	If TypeOf(Stage) = Type("DocumentRef.ProductionStage2_2") Then
		TypeDetails = New TypeDescription("DocumentRef.ProductionStage2_2");
	ElsIf TypeOf(Stage) = Type("DocumentRef.OrderOfMaterialsForProduction") Then
		TypeDetails = New TypeDescription("DocumentRef.OrderOfMaterialsForProduction");
	Else
		TypeDetails = Common.TypeDescriptionNumber(10);
	EndIf;

	ChoiceParameters = AlternativeMaterials.AnalogSelectionParameters(TypeDetails);
		
	ParametersTable = ChoiceParameters.SubstitutesParameters.ParametersTable;
	
	For Each String In TableFromDocument Do
		
		TableRow = ParametersTable.Add();
		TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
		TableRow.Ref = String.Stage;
		TableRow.Department = String.Department;
		TableRow.LineOfBusiness = String.LineOfBusiness;
		TableRow.ProductionOrder = String.ProductionOrder;
		TableRow.BillOfMaterials = String.BillOfMaterials;
		TableRow.Stage = String.StageOfResourceBillOfMaterials;
		TableRow.Product = String.Product;
		TableRow.ItemVariantOfProduct = String.ItemVariantOfProduct;
		
	EndDo;
		
	QueryText = QueryTextForDocumentPermission(ApplyInventoryTable);
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Goods", TableFromDocument);
	Query.SetParameter("ParametersTable", ParametersTable);
	Query.SetParameter("SearchTable", TableFromDocument);
	
	If ApplyInventoryTable Then
		Query.SetParameter("Inventories", InventoryTable);
	EndIf;
	
	ResultsArray = Query.ExecuteBatch();
	TableBalancesOfAnalogues = ResultsArray[ResultsArray.UBound() - 2].Unload();
	SelectionOfAnalogues = ResultsArray[ResultsArray.UBound() - 1].Select();
	Packing_DataTable = ResultsArray[ResultsArray.UBound()].Unload();
	
	CurrentResolution = Undefined;	
	TemplatePresentation = NStr("vi = '%1 %2 %3 %4';
								|ru = '%1 %2 %3 %4';
								|en = '%1 %2 %3 %4'; fa = '%1 %2 %3 %4';
								|it = '%1 %2 %3 %4';
								|pl = '%1 %2 %3 %4';
								|tr = '%1 %2 %3 %4'");
	
	While SelectionOfAnalogues.Next() Do
	
		NewRow = Substitutes.Add();
		FillPropertyValues(NewRow, SelectionOfAnalogues);
		
		NewRow.ItemVariantsAreUsed = ValueIsFilled(NewRow.Characteristic);
		
		ProductDataManagement.FillInPackingDataInDataSetRow(NewRow, Packing_DataTable);
		
		If (CurrentResolution <> SelectionOfAnalogues.Resolution
		   And SelectionOfAnalogues.ThisIsASubstitute)
		 Or SelectionOfAnalogues.InterchangeableSubstitute Then
		
			CurrentResolution = SelectionOfAnalogues.Resolution;
			NewRow.ResolutionPresentation = StringFunctionsClientServer.SubstituteParametersToString(
				TemplatePresentation, "№", SelectionOfAnalogues.Number, NStr("vi = 'từ';
																			|ru = 'от';
																			|en = 'dated'; fa = 'مورخ';
																			|it = 'dated';
																			|pl = 'dated';
																			|tr = 'tarih'"), Format(SelectionOfAnalogues.Date, "DLF=D"));
		
		EndIf;
			
	EndDo;
	
	Return New Structure("Stages, RemnantsOfAnalogues, Substitutes", TableFromDocument, TableBalancesOfAnalogues, Substitutes);

EndFunction

Procedure CheckInstallKey(CurrentMaterials, ArrayOfAddedRows, CurrentKey, DetachedSet)

	If CurrentMaterials.Count() = 0 Then
				
		For Each AddedRow In ArrayOfAddedRows Do
			AddedRow.ConnectionKey = CurrentKey;
			AddedRow.DetachedSet = DetachedSet;
		EndDo;
		
	EndIf;
	
	DetachedSet = False;

EndProcedure

Function QueryTextForDocumentPermission(ApplyInventoryTable = False)
	
	FieldsMap = New Map;
	
	SelectionSettings = New Structure;
	SelectionSettings.Insert("GoodsTogetherWithParameters", False);
	SelectionSettings.Insert("ConsiderManyToMany", True);
	SelectionSettings.Insert("ToSelectInterchangeableAnalogues", True);
	SelectionSettings.Insert("SelectionOfPermissions", FieldsMap);
	SelectionSettings.Insert("TempTableName", "ConnectionsOfMaterialsAndAnalogues");
	
	QueryTextAlternativeMaterials = AlternativeMaterials.QueryTextDataOfMaterialsAndAnalogues(SelectionSettings);
	
	If ApplyInventoryTable Then
		
		QueryTextInventoryTable = 
		"SELECT
		|	InventoryTable.Products AS Products,
		|	InventoryTable.Characteristic AS Characteristic,
		|	InventoryTable.Warehouse AS Warehouse,
		|	InventoryTable.Purpose AS Purpose,
		|	InventoryTable.AvailableForInventoryAllocation AS Count
		|INTO InventoryTransferred
		|FROM
		|	&Inventories AS InventoryTable
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Inventories.Products AS Products,
		|	Inventories.Characteristic AS Characteristic,
		|	Inventories.Warehouse AS Warehouse,
		|	Inventories.Purpose AS Purpose,
		|	SUM(Inventories.Count) AS Count
		|INTO InventoryTable
		|FROM
		|	InventoryTransferred AS Inventories
		|
		|GROUP BY
		|	Inventories.Products,
		|	Inventories.Characteristic,
		|	Inventories.Warehouse,
		|	Inventories.Purpose
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Warehouse,
		|	Purpose";
		
	Else
		
		QueryTextInventoryTable =
		"SELECT TOP 0
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	0 AS Count
		|INTO InventoryTransferred
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 0
		|	VALUE(Catalog.Products.EmptyRef) AS Products,
		|	VALUE(Catalog.ItemsCharacteristics.EmptyRef) AS Characteristic,
		|	VALUE(Catalog.Warehouses.EmptyRef) AS Warehouse,
		|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose,
		|	0 AS Count
		|INTO InventoryTable";
		
	EndIf;
	
	FillingQueryText = "SELECT
	|	SearchTable.Purpose AS Purpose,
	|	SearchTable.Warehouse AS Warehouse
	|INTO SearchTable
	|FROM
	|	&SearchTable AS SearchTable
	|
	|INDEX BY
	|	Purpose,
	|	Warehouse
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
	|	AccumulationRegister.InventoryAndDemands.Balance(
	|			,
	|			(Products, Characteristic) IN
	|					(SELECT
	|						ConnectionsOfMaterialsAndAnalogues.Products AS Products,
	|						ConnectionsOfMaterialsAndAnalogues.Characteristic AS Characteristic
	|					FROM
	|						ConnectionsOfMaterialsAndAnalogues AS ConnectionsOfMaterialsAndAnalogues
	|					WHERE
	|						ConnectionsOfMaterialsAndAnalogues.ThisIsASubstitute)
	|				AND (Warehouse, Purpose) IN
	|					(SELECT
	|						SearchTable.Warehouse AS Warehouse,
	|						SearchTable.Purpose AS Purpose
	|					FROM
	|						SearchTable AS SearchTable
	|			
	|					UNION ALL
	|			
	|					SELECT
	|						SearchTable.Warehouse AS Warehouse,
	|						VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|					FROM
	|						SearchTable AS SearchTable)) AS Inventories
	|INDEX BY
	|	Products, Characteristic, Purpose, Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculation.Products AS Products,
	|	Calculation.Characteristic AS Characteristic,
	|	Calculation.Warehouse AS Warehouse,
	|	Calculation.Purpose AS Purpose,
	|	ISNULL(InventoryTable.Count, Calculation.QuantityForShipAction) AS AvailableForInventoryAllocation
	|FROM
	|	CalculationOfBalancesForSettingActions AS Calculation
	|		LEFT JOIN InventoryTable AS InventoryTable
	|		ON Calculation.Products = InventoryTable.Products
	|		 AND Calculation.Characteristic = InventoryTable.Characteristic
	|		 AND Calculation.Warehouse = InventoryTable.Warehouse
	|		 AND Calculation.Purpose = InventoryTable.Purpose
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ConnectionsOfMaterialsAndAnalogues.Resolution AS Resolution,
	|	ConnectionsOfMaterialsAndAnalogues.Period AS Period,
	|	CASE
	|		WHEN VALUETYPE(ConnectionsOfMaterialsAndAnalogues.Resolution) = TYPE(Document.EngineeringChangeOrder)
	|			THEN CAST(ConnectionsOfMaterialsAndAnalogues.Resolution AS Document.EngineeringChangeOrder).Number
	|		WHEN VALUETYPE(ConnectionsOfMaterialsAndAnalogues.Resolution) = TYPE(Document.RegisterAdjustment)
	|			THEN CAST(ConnectionsOfMaterialsAndAnalogues.Resolution AS Document.RegisterAdjustment).Number
	|	END AS Number,
	|	CASE
	|		WHEN VALUETYPE(ConnectionsOfMaterialsAndAnalogues.Resolution) = TYPE(Document.EngineeringChangeOrder)
	|			THEN CAST(ConnectionsOfMaterialsAndAnalogues.Resolution AS Document.EngineeringChangeOrder).Date
	|		WHEN VALUETYPE(ConnectionsOfMaterialsAndAnalogues.Resolution) = TYPE(Document.RegisterAdjustment)
	|			THEN CAST(ConnectionsOfMaterialsAndAnalogues.Resolution AS Document.RegisterAdjustment).Date
	|	END AS Date,
	|	ConnectionsOfMaterialsAndAnalogues.LineNumber AS LineNumber,
	|	ConnectionsOfMaterialsAndAnalogues.Products AS Products,
	|	ConnectionsOfMaterialsAndAnalogues.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ControlMultiplier,
	|	ConnectionsOfMaterialsAndAnalogues.Products.Presentation AS ProductsPresentation,
	|	ConnectionsOfMaterialsAndAnalogues.Characteristic.Presentation AS CharacteristicPresentation,
	|	ConnectionsOfMaterialsAndAnalogues.Products.UnitOfMeasure.Presentation AS UnitOfMeasurePresentation,
	|	ConnectionsOfMaterialsAndAnalogues.Characteristic AS Characteristic,
	|	ConnectionsOfMaterialsAndAnalogues.ProductsRole AS ProductsRole,
	|	ConnectionsOfMaterialsAndAnalogues.ProductsRole = VALUE(Enum.SubstituteRoles.InterchangeableSubstitute) AS InterchangeableSubstitute,
	|	ConnectionsOfMaterialsAndAnalogues.ReplacementPriority AS ReplacementPriority,
	|	ConnectionsOfMaterialsAndAnalogues.Package AS Package,
	|	ConnectionsOfMaterialsAndAnalogues.NumberOfPackages AS NormativeStandard,
	|	UNDEFINED AS PackageData,
	|	ConnectionsOfMaterialsAndAnalogues.ScopeMaxPriority AS ScopeMaxPriority,
	|	ConnectionsOfMaterialsAndAnalogues.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	ConnectionsOfMaterialsAndAnalogues.Ref AS Ref,
	|	ConnectionsOfMaterialsAndAnalogues.ManyToMany AS ManyToMany,
	|	ConnectionsOfMaterialsAndAnalogues.ConnectionKey AS ConnectionKey,
	|	ConnectionsOfMaterialsAndAnalogues.ThisIsASubstitute AS ThisIsASubstitute,
	|	CASE
	|		WHEN ConnectionsOfMaterialsAndAnalogues.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereIsSubstitute)
	|			THEN 1
	|		WHEN ConnectionsOfMaterialsAndAnalogues.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials)
	|			THEN 2
	|		ELSE 10
	|	END AS PriorityOfReplacingNumber
	|FROM
	|	ConnectionsOfMaterialsAndAnalogues AS ConnectionsOfMaterialsAndAnalogues
	|
	|ORDER BY
	|	PriorityOfReplacingNumber,
	|	ScopeMaxPriority DESC,
	|	Period DESC,
	|	Resolution DESC,
	|	LineNumber";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(FillingQueryText, TablesNames, False, False);
	
	FillingQueryText = StrReplace(FillingQueryText, "&PackingText",
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ConnectionsOfMaterialsAndAnalogues.Package",
			"ConnectionsOfMaterialsAndAnalogues.Products"));
	
	TablesNames = New Array;
	TablesNames.Add("ConnectionsOfMaterialsAndAnalogues");
		
	QueryTextPackageData = ProductDataManagement.QueryTextPackageData_(TablesNames);
	
	ArrayOfTexts = New Array; // Array of String
	ArrayOfTexts.Add(QueryTextAlternativeMaterials);
	ArrayOfTexts.Add(QueryTextInventoryTable);
	ArrayOfTexts.Add(FillingQueryText);
	ArrayOfTexts.Add(QueryTextPackageData);
	
	Return StrConcat(ArrayOfTexts, Common.QueryBatchSeparator());

EndFunction

// Returns the Query Text for the assistant for performing substitutions with analogues.
//
// Parameters:
//  RoleOfAnalogues - EnumRef.SubstituteRoles -
//
// Returns:
//	String - query text.
//
Function QueryTextForFillingInReplacementWizard(RoleOfAnalogues) Export
	
	Separator = Common.QueryBatchSeparator();
	QueryTextArray = New Array;
	
	TextDataOfStages = 
	"SELECT
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.Products.UnitOfMeasure.MeasuredValueType = VALUE(Enum.TypesOfMeasuredValues.NumberOfPieces) AS ControlMultiplier,
	|	AlternativeMaterials.ProductsRole AS ProductsRole,
	|	AlternativeMaterials.NumberOfPackages AS NormativeStandard
	|INTO GoodsPermits
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|WHERE
	|	AlternativeMaterials.Recorder = &Resolution
	|	AND AlternativeMaterials.Period <= &Period
	|	AND (AlternativeMaterials.EndPeriod = DATETIME(1, 1, 1)
	|			OR AlternativeMaterials.EndPeriod >= &Period)
	|
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsPermits.Products AS Products,
	|	GoodsPermits.Characteristic AS Characteristic,
	|	GoodsPermits.Package AS Package,
	|	GoodsPermits.ControlMultiplier AS ControlMultiplier,
	|	GoodsPermits.NormativeStandard AS NormativeStandard
	|INTO PermissionMaterials
	|FROM
	|	GoodsPermits AS GoodsPermits
	|WHERE
	|	GoodsPermits.ProductsRole IN (VALUE(Enum.SubstituteRoles.Material), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	Table.ProductionOrder AS ProductionOrder,
	|	Table.Stage AS Stage
	|INTO ActiveStagesAndOrdersPreparation
	|FROM 
	|	(SELECT
	|		OrderStructure.ProductionOrder AS ProductionOrder,
	|		OrderStructure.Stage AS Stage
	|	FROM
	|		InformationRegister.OrderStructure AS OrderStructure
	|		INNER JOIN PermissionMaterials AS PermissionMaterials
	|			ON OrderStructure.Products = PermissionMaterials.Products
	|				AND OrderStructure.Characteristic = PermissionMaterials.Characteristic
	|
	|UNION ALL
	|
	|	SELECT
	|		CAST(InventoryAllocation.ShipmentOrder AS Document.ProductionStage2_2).ReferenceOrder AS ProductionOrder,
	|		InventoryAllocation.ShipmentOrder AS Stage
	|FROM
	|		InformationRegister.InventoryAllocation AS InventoryAllocation
	|		INNER JOIN PermissionMaterials AS PermissionMaterials
	|			ON InventoryAllocation.Products = PermissionMaterials.Products
	|				AND InventoryAllocation.Characteristic = PermissionMaterials.Characteristic
	|				AND VALUETYPE(InventoryAllocation.ShipmentOrder) = TYPE(Document.ProductionStage2_2)) AS Table
	|
	|INDEX BY 	
	|	ProductionOrder, Stage
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT ALLOWED
	|	Stages.Ref AS Stage,
	|	Stages.Date AS DateOfStage_,
	|	Stages.Department AS Department,
	|	Stages.LineOfBusiness AS LineOfBusiness,
	|	Stages.ProductionLot.BillOfMaterials AS BillOfMaterials,
	|	Stages.Stage AS StageOfResourceBillOfMaterials,
	|	Stages.ProductionLot.MainProductProducts AS Product,
	|	Stages.ProductionLot.MainProductCharacteristic AS ItemVariantOfProduct,
	|	Orders.Ref AS ProductionOrder,
	|	Orders.Date AS OrderDate,
	|	Orders.Number AS OrderNumber
	|INTO ActiveStagesAndOrders
	|FROM
	|	Document.ProductionStage2_2 AS Stages
	|		INNER JOIN ActiveStagesAndOrdersPreparation AS ActiveStagesAndOrdersPreparation
	|		ON Stages.ReferenceOrder = ActiveStagesAndOrdersPreparation.ProductionOrder
	|		AND Stages.Ref = ActiveStagesAndOrdersPreparation.Stage
	|		INNER JOIN Document.ProductionOrder2_2 AS Orders
	|		ON Stages.ReferenceOrder = Orders.Ref
	|WHERE
	|	Stages.Posted
	|	AND NOT Stages.WorkPlanning
	|	AND TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.ScopesOfSubstitutes AS AreasOfAction
	|			WHERE
	|				AreasOfAction.Resolution = &Resolution
	|				AND AreasOfAction.ProductionOrder IN (Orders.Ref, VALUE(Document.ProductionOrder2_2.EmptyRef),
	|																		UNDEFINED)
	|				AND AreasOfAction.SalesOrder = VALUE(Document.SalesOrder.EmptyRef)
	|				AND AreasOfAction.BillOfMaterials IN (Stages.ProductionLot.BillOfMaterials, VALUE(Catalog.BillsOfMaterials.EmptyRef))
	|				AND AreasOfAction.Stage IN (Stages.Ref.Stage, VALUE(Catalog.ProductionStages.EmptyRef))
	|				AND (AreasOfAction.Product = Stages.ProductionLot.MainProductProducts
	|						AND AreasOfAction.ItemVariantOfProduct IN (Stages.ProductionLot.MainProductCharacteristic, VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|					OR AreasOfAction.Product = VALUE(Catalog.Products.EmptyRef)
	|						AND AreasOfAction.ItemVariantOfProduct = VALUE(Catalog.ItemsCharacteristics.EmptyRef))
	|				AND AreasOfAction.Department IN (Stages.Department, VALUE(Catalog.BusinessStructure.EmptyRef))
	|				AND AreasOfAction.LineOfBusiness IN (Stages.LineOfBusiness, VALUE(Catalog.LinesOfBusiness.EmptyRef)))
	|INDEX BY
	|
	|	Stage,
	|	ProductionOrder;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	ProductionStage2_2ProvisionOfMaterialsAndWorks.Products AS Products,
	|	ProductionStage2_2ProvisionOfMaterialsAndWorks.Characteristic AS Characteristic,
	|	CASE
	|		WHEN ProductionStage2_2ProvisionOfMaterialsAndWorks.SupplyOption <> VALUE(Enum.SupplyOptions.NotRequired)
	|			THEN ProductionStage2_2ProvisionOfMaterialsAndWorks.Count
	|		ELSE 0
	|	END AS Total,
	|	CASE
	|		WHEN ProductionStage2_2ProvisionOfMaterialsAndWorks.SupplyOption = VALUE(Enum.SupplyOptions.Ship)
	|			THEN ProductionStage2_2ProvisionOfMaterialsAndWorks.Count
	|		ELSE 0
	|	END AS Shipped,
	|	CASE
	|		WHEN ProductionStage2_2ProvisionOfMaterialsAndWorks.SupplyOption IN (VALUE(Enum.SupplyOptions.FromWarehouse), VALUE(Enum.SupplyOptions.ReserveAsReceived))
	|			THEN ProductionStage2_2ProvisionOfMaterialsAndWorks.Count
	|		ELSE 0
	|	END AS Reserved,
	|	ActiveStagesAndOrders.Stage AS Stage,
	|	ActiveStagesAndOrders.ProductionOrder AS ProductionOrder,
	|	ProductionStage2_2ProvisionOfMaterialsAndWorks.Warehouse AS Warehouse,
	|	ProductionStage2_2ProvisionOfMaterialsAndWorks.SupplyAssignment AS Purpose,
	|	ProductionStage2_2ProvisionOfMaterialsAndWorks.WithAssignment AS WithAssignment
	|INTO MaterialSupply
	|FROM
	|	Document.ProductionStage2_2.SupplyWithMaterialsAndWorks AS ProductionStage2_2ProvisionOfMaterialsAndWorks
	|	INNER JOIN ActiveStagesAndOrders AS ActiveStagesAndOrders
	|		ON ProductionStage2_2ProvisionOfMaterialsAndWorks.Ref = ActiveStagesAndOrders.Stage
	|	INNER JOIN PermissionMaterials AS PermissionMaterials
	|		ON ProductionStage2_2ProvisionOfMaterialsAndWorks.Products = PermissionMaterials.Products
	|			AND ProductionStage2_2ProvisionOfMaterialsAndWorks.Characteristic = PermissionMaterials.Characteristic
	|WHERE
	|	NOT ProductionStage2_2ProvisionOfMaterialsAndWorks.Canceled
	|
	|INDEX BY 
	|	
	|	Products,
	|	Characteristic,
	|	Stage
	|";
		
	QueryTextArray.Add(TextDataOfStages);
	QueryTextArray.Add(Separator);
	
	If RoleOfAnalogues = Enums.SubstituteRoles.InterchangeableSubstitute Then
		
		TextManyToMany = "SELECT TOP 0
		|	NULL AS Products,
		|	NULL AS Characteristic,
		|	NULL AS Stage
		|INTO AllMaterialsWithStages
		|
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT TOP 0
		|	NULL AS Stage
		|INTO ExcludedStages";
		
	Else	
		
		TextManyToMany = "SELECT DISTINCT
		|	PermissionMaterials.Products AS Products,
		|	PermissionMaterials.Characteristic AS Characteristic,
		|	MaterialSupply.Stage AS Stage
		|INTO AllMaterialsWithStages
		|FROM
		|	PermissionMaterials AS PermissionMaterials
		|		INNER JOIN MaterialSupply AS MaterialSupply
		|		ON (TRUE)
		|
		|INDEX BY
		|	Products,
		|	Characteristic,
		|	Stage
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AllMaterialsWithStages.Stage AS Stage
		|INTO ExcludedStages
		|FROM
		|	AllMaterialsWithStages AS AllMaterialsWithStages
		|		LEFT JOIN MaterialSupply AS MaterialSupply
		|		ON AllMaterialsWithStages.Products = MaterialSupply.Products
		|			AND AllMaterialsWithStages.Characteristic = MaterialSupply.Characteristic
		|			AND AllMaterialsWithStages.Stage = MaterialSupply.Stage
		|WHERE
		|	MaterialSupply.Products IS NULL
		|
		|INDEX BY
		|	Stage";
		
	EndIf;
	
	QueryTextArray.Add(TextManyToMany);
	QueryTextArray.Add(Separator);
	
	TablesNames = New Array;
	TablesNames.Add("GoodsPermits");
		
	QueryTextPackageData = ProductDataManagement.QueryTextPackageData_(TablesNames);
	
	QueryTextArray.Add(QueryTextPackageData);
	QueryTextArray.Add(Separator);
	
	TextFillingData = 
	"SELECT
	|	GoodsPermits.Products AS Products,
	|	GoodsPermits.Characteristic AS Characteristic,
	|	UNDEFINED AS PackageData,
	|	GoodsPermits.Package AS Package,
	|	GoodsPermits.ControlMultiplier AS ControlMultiplier,
	|	GoodsPermits.ProductsRole = VALUE(Enum.SubstituteRoles.Material) AS ThisIsMaterial,
	|	GoodsPermits.NormativeStandard AS NormativeStandard
	|FROM
	|	GoodsPermits AS GoodsPermits
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	MaterialSupply.Products AS Products,
	|	MaterialSupply.Characteristic AS Characteristic,
	|	UNDEFINED AS PackageData,
	|	PermissionMaterials.ControlMultiplier AS ControlMultiplier,
	|	PermissionMaterials.NormativeStandard AS NormativeStandard,
	|	PermissionMaterials.Package AS Package,
	|	SUM(MaterialSupply.Total) AS Total,
	|	SUM(MaterialSupply.Shipped) AS Shipped,
	|	SUM(MaterialSupply.Reserved) AS Reserved,
	|	SUM(MaterialSupply.Shipped + MaterialSupply.Reserved) AS Supplied,
	|	MaterialSupply.Stage AS Stage,
	|	&PresentationStage AS PresentationStage,
	|	MaterialSupply.ProductionOrder AS ProductionOrder,
	|	MaterialSupply.Warehouse AS Warehouse,
	|	MaterialSupply.Purpose AS Purpose,
	|	MaterialSupply.WithAssignment AS WithAssignment,
	|	ActiveStagesAndOrders.DateOfStage_ AS DateOfStage_,
	|	ActiveStagesAndOrders.Department AS Department,
	|	ActiveStagesAndOrders.LineOfBusiness AS LineOfBusiness,
	|	ActiveStagesAndOrders.BillOfMaterials AS BillOfMaterials,
	|	ActiveStagesAndOrders.StageOfResourceBillOfMaterials AS StageOfResourceBillOfMaterials,
	|	ActiveStagesAndOrders.Product AS Product,
	|	ActiveStagesAndOrders.ItemVariantOfProduct AS ItemVariantOfProduct,
	|	ActiveStagesAndOrders.OrderDate AS OrderDate,
	|	ActiveStagesAndOrders.OrderNumber AS OrderNumber
	|FROM
	|	MaterialSupply AS MaterialSupply
	|		INNER JOIN PermissionMaterials AS PermissionMaterials
	|		ON MaterialSupply.Products = PermissionMaterials.Products
	|			AND MaterialSupply.Characteristic = PermissionMaterials.Characteristic
	|		INNER JOIN ActiveStagesAndOrders AS ActiveStagesAndOrders
	|		ON MaterialSupply.Stage = ActiveStagesAndOrders.Stage
	|			AND MaterialSupply.ProductionOrder = ActiveStagesAndOrders.ProductionOrder
	|WHERE
	|	NOT MaterialSupply.Stage IN
	|				(SELECT
	|					ExcludedStages.Stage AS Stage
	|				FROM
	|					ExcludedStages AS ExcludedStages)
	|
	|GROUP BY
	|	MaterialSupply.Products,
	|	MaterialSupply.Characteristic,
	|	PermissionMaterials.Package,
	|	PermissionMaterials.ControlMultiplier,
	|	PermissionMaterials.NormativeStandard,
	|	MaterialSupply.Stage,
	|	MaterialSupply.ProductionOrder,
	|	MaterialSupply.Warehouse,
	|	MaterialSupply.Purpose,
	|	MaterialSupply.WithAssignment,
	|	ActiveStagesAndOrders.DateOfStage_,
	|	ActiveStagesAndOrders.Department,
	|	ActiveStagesAndOrders.LineOfBusiness,
	|	ActiveStagesAndOrders.BillOfMaterials,
	|	ActiveStagesAndOrders.StageOfResourceBillOfMaterials,
	|	ActiveStagesAndOrders.Product,
	|	ActiveStagesAndOrders.ItemVariantOfProduct,
	|	ActiveStagesAndOrders.OrderDate,
	|	ActiveStagesAndOrders.OrderNumber
	|
	|ORDER BY
	|	DateOfStage_,
	|	Stage,
	|	Purpose,
	|	WithAssignment DESC,
	|	Products,
	|	Characteristic";
		
	TextFillingData = StrReplace(TextFillingData, "&PresentationStage",
		Documents.ProductionStage2_2.QueryTextPresentationStage("MaterialSupply.Stage"));
		
	QueryTextArray.Add(TextFillingData);
	
	Return StrConcat(QueryTextArray);

EndFunction

// Initializes the structure of the form parameter helpersfill the name
//
//
// Returns:
//  Structure - Parameters For Clearing Participants' Attributes:
//	* OneToOneReplacement - Boolean -
//	* Material - CatalogRef.Products -
//	* ItemVariantOfMaterial - CatalogRef.ItemsCharacteristics -
//	* Resolution - DocumentRef.EngineeringChangeOrder -
//	* ReplacementPriority - EnumRef.RulesOfReplacingWithSubstitutes -
//	* RoleOfAnalogues - EnumRef.SubstituteRoles -
//	* Stage - DocumentRef.ProductionStage2_2 -
//
Function ParametersOfReplacementAssistantForm() Export

	ParametersStructure = New Structure;
	ParametersStructure.Insert("OneToOneReplacement", False);
	ParametersStructure.Insert("Material", Catalogs.Products.EmptyRef());
	ParametersStructure.Insert("ItemVariantOfMaterial", Catalogs.ItemsCharacteristics.EmptyRef());
	ParametersStructure.Insert("Resolution", Documents.EngineeringChangeOrder.EmptyRef());
	ParametersStructure.Insert("ReplacementPriority", Enums.RulesOfReplacingWithSubstitutes.EmptyRef());
	ParametersStructure.Insert("RoleOfAnalogues", Enums.SubstituteRoles.EmptyRef());
	ParametersStructure.Insert("Stage", Documents.ProductionStage2_2.EmptyRef());
	
	Return ParametersStructure;

EndFunction

Procedure ReplaceWithAnalogsInProductionStagesDelayed(Parameters, StorageAddress) Export
	
	OperationName = "Document.EngineeringChangeOrder.ManagerModule.ReplaceWithAnalogsInProductionStagesDelayed";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(OperationName);
	
	DataVolume = ReplaceWithAnalogsDeferredInsideTimeMeasurement(Parameters, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);
	
EndProcedure

Function ResultOfFormation() Export
	
	ModifiedObjects = New ValueTable;
	ModifiedObjects.Columns.Add("Document", New TypeDescription("DocumentRef.ProductionStage2_2"));
	ModifiedObjects.Columns.Add("ReferenceOrder", New TypeDescription("DocumentRef.ProductionOrder2_2"));
	ModifiedObjects.Columns.Add("Presentation", New TypeDescription("String"));
	
	Errors = New ValueTable;
	Errors.Columns.Add("Document", New TypeDescription("DocumentRef.ProductionStage2_2"));
	Errors.Columns.Add("Presentation", New TypeDescription("String"));
	Errors.Columns.Add("MessageText", New TypeDescription("String"));
	
	Result = New Structure;
	Result.Insert("ModifiedObjects", ModifiedObjects);
	Result.Insert("Errors", Errors);
	
	Return Result;
	
EndFunction

Function ReplaceWithAnalogsDeferredInsideTimeMeasurement(Parameters, StorageAddress)
	
	ReplaceWithAnaloguesInProductionStages(Parameters, StorageAddress);
	
	DataVolume = 0;
	Result = GetFromTempStorage(StorageAddress);
	If TypeOf(Result) = Type("Structure")
		And CommonClientServer.HasAttributeOrObjectProperty(Result, "ModifiedObjects") Then
		DataVolume = Result.ModifiedObjects.Count();
	EndIf;
	
	Return DataVolume;
	
EndFunction

Procedure ReplaceWithAnaloguesInProductionStages(Parameters, StorageAddress)

	Result = ResultOfFormation();
	
	PortionSize = 100;
	
	TableOfStagesForProcessing = Parameters.TableOfStagesForProcessing;
	TableOfAnalogues = Parameters.TableOfAnalogues;
	ReferencesArrray = Parameters.ReferencesArrray;
	
	If ReferencesArrray.Count() <= PortionSize Then
		ReplaceWithAnalogsInPortionOfDocuments(TableOfStagesForProcessing, TableOfAnalogues, ReferencesArrray, Result, StorageAddress);
	Else
		Counter = 1;
		MaxIndex = ReferencesArrray.Count()-1;
		
		StageTableCopy = TableOfStagesForProcessing.CopyColumns();
		TableOfAnalogsCopy = TableOfAnalogues.CopyColumns();
		ArrayOfLinksCopy = New Array;
		
		TableOfStagesForProcessing.Indexes.Add("Ref");
		TableOfAnalogues.Indexes.Add("Ref");
	
		TheStructureOfTheSearch = New Structure("Ref");
		IndexOf = 0;
		
		For Each StageLink In ReferencesArrray Do
		
			TheStructureOfTheSearch.Ref = StageLink;
			For Each StageString In TableOfStagesForProcessing.FindRows(TheStructureOfTheSearch) Do
				FillPropertyValues(StageTableCopy.Add(), StageString);
			EndDo;
			For Each StringAnalog In TableOfAnalogues.FindRows(TheStructureOfTheSearch) Do
				FillPropertyValues(TableOfAnalogsCopy.Add(), StringAnalog);
			EndDo;
			
			ArrayOfLinksCopy.Add(StageLink);
			
			If Counter = PortionSize Or IndexOf = MaxIndex Then
				ReplaceWithAnalogsInPortionOfDocuments(StageTableCopy, TableOfAnalogsCopy, ArrayOfLinksCopy, Result, StorageAddress);
				
				StageTableCopy.Clear();
				TableOfAnalogsCopy.Clear();
				ArrayOfLinksCopy.Clear();
				Counter = 1;
			Else
				Counter = Counter+1;
			EndIf;
			
			IndexOf = IndexOf + 1;
		
		EndDo;
	
	EndIf;	

EndProcedure

Procedure ReplaceWithAnalogsInPortionOfDocuments(TableOfStagesForProcessing, TableOfAnalogues, ReferencesArrray, Result, StorageAddress)
	
	ModifiedObjects = Result.ModifiedObjects;
	Errors = Result.Errors;
	
	TableOfStagesForProcessing.Indexes.Add("Ref");
	TableOfAnalogues.Indexes.Add("Ref");
	
	TheStructureOfTheSearch = New Structure("Ref");
	StructureOfStringSearch = New Structure("Products, Characteristic, SupplyAssignment");
	StructureOfStringSearch.Insert("Canceled", False);
	ShipOption = Enums.SupplyOptions.Ship;
	OptionToProvide = Enums.SupplyOptions.ToSupply;
	
	MaterialRowData = New Structure("ProductCostElement");
	
	MaterialSearchIterations = New Array;
	MaterialSearchIterations.Add(New Structure("SelectToProvide", True));
	MaterialSearchIterations.Add(New Structure("SelectToProvide", False));
	
	ErrorPatternBlocking = NStr("vi = 'Không thể phong tỏa %1. %2';
								|ru = 'Не удалось заблокировать %1. %2';
								|en = 'Cannot block %1. %2'; fa = 'Cannot block %1. %2';
								|it = 'Impossibile bloccare %1. %2';
								|pl = 'Nie udało się zablokować %1. %2';
								|tr = '%1 engellenemedi. %2'");
	FillingErrorTemplate = NStr("vi = 'Trong chứng từ %1 không thể tìm thấy nguyên vật liệu để thay thế';
								|ru = 'В документе %1 не удалось найти материалы для замены';
								|en = 'Cannot find materials for replacement in the ""%1"" document'; fa = 'Cannot find materials for replacement in the ""%1"" document';
								|it = 'Cannot find materials for replacement in the ""%1"" document';
								|pl = 'Cannot find materials for replacement in the ""%1"" document';
								|tr = '%1 belgede değişiklik için malzeme bulunamadı'");
	ErrorTemplateReplacementWithAnalogs = NStr("vi = 'Trong chứng từ %1 không thể thay thế sang vật tư tương tự do: %2';
												|ru = 'В документе %1 не удалось выполнить замену на аналоги по причине: %2';
												|en = 'Cannot replace with substitutes in the ""%1"" document due to: %2'; fa = 'Cannot replace with substitutes in the ""%1"" document due to: %2';
												|it = 'Cannot replace with substitutes in the ""%1"" document due to: %2';
												|pl = 'Cannot replace with substitutes in the ""%1"" document due to: %2';
												|tr = 'Belge %1''de ikame ile değiştirme şu nedenden gerçekleştirelemedi: %2'");
	
	If TableOfStagesForProcessing.Count() > 0 Then
	
		For Each StageLink In ReferencesArrray Do
			
			LockSet = False;
			
			BeginTransaction();
			Try
			
				LockDataForEdit(StageLink);
				
				LockSet = True;
				
				TheStructureOfTheSearch.Ref = StageLink;
				LinesToReplace = TableOfStagesForProcessing.FindRows(TheStructureOfTheSearch);
				
				IndexList1 = New ValueList;
				FillError = False;
				
				StageObject = StageLink.GetObject();
				
				ParametersForFillingAssignments = ProductionSupply.ActionParametersFillInPurposeOfProvisionInProductionPhase(
					StageObject, StageObject.ManufacturedProducts);
				
				For Each SpecificationRow In LinesToReplace Do
					
					FillPropertyValues(StructureOfStringSearch, SpecificationRow, "Products, Characteristic");
					StructureOfStringSearch.SupplyAssignment = SpecificationRow.Purpose;
					DocumentRows = StageObject.SupplyWithMaterialsAndWorks.FindRows(StructureOfStringSearch);
					QuantityToReplace = SpecificationRow.Count;
					PresentationStage = SpecificationRow.Presentation;
					
					For Each SearchIteration In MaterialSearchIterations Do
					
						For Each DocumentLine In DocumentRows Do
					
							If DocumentLine.SupplyOption = ShipOption Then
								Continue;
							EndIf;
							
							If SearchIteration.SelectToProvide
							   And DocumentLine.SupplyOption <> OptionToProvide Then
							
								Continue;	
							
							EndIf;
							
							If QuantityToReplace = 0 Then
								Break;
							EndIf;
							
							If QuantityToReplace >= DocumentLine.Count Then
							
								QuantityToReplace = QuantityToReplace - DocumentLine.Count;
								DocumentLine.Count = 0;
								IndexList1.Add(DocumentLine.LineNumber - 1);
								
							Else
								
								DocumentLine.Count = DocumentLine.Count - QuantityToReplace;
								DocumentLine.NumberOfPackages = DocumentLine.Count;
								DocumentLine.Package = Catalogs.PackagesAndUnitsOfMeasure.EmptyRef();
								
								QuantityToReplace = 0;
							
							EndIf;
							
							FillPropertyValues(MaterialRowData, DocumentLine);
						
						EndDo;	
					
					EndDo;
					
					If QuantityToReplace <> 0 Then
						
						FillError = True;
						Break;
						
					EndIf;
				
				EndDo;
				
				If FillError Then
					
					MessageFilling = StringFunctionsClientServer.SubstituteParametersToString(FillingErrorTemplate, StageObject);
					
					Error = Errors.Add();
					Error.Document = StageLink;
					Error.Presentation = PresentationStage;
					Error.MessageText = MessageFilling;
					
				Else
					
					StringsToProcess = New Array;
					AnalogStrings = TableOfAnalogues.FindRows(TheStructureOfTheSearch);
					For Each StringAnalog In AnalogStrings Do
					
						NewRow = StageObject.SupplyWithMaterialsAndWorks.Add();
						
						NewRow.Department = StageObject.Department;
						
						FillPropertyValues(NewRow, StringAnalog, "Products, Characteristic, Warehouse, Count");
						FillPropertyValues(NewRow, MaterialRowData);
						
						NewRow.SupplyAssignment = StringAnalog.Purpose;
						NewRow.WithAssignment = ValueIsFilled(StringAnalog.Purpose);
						NewRow.NumberOfPackages = NewRow.Count;
						NewRow.SupplyOption = Enums.SupplyOptions.ToSupply;
						NewRow.DateOfShipment = StageObject.DateOfShipment;
						If ValueIsFilled(NewRow.SupplyAssignment) Then
							NewRow.Purpose = NewRow.SupplyAssignment;
						Else
							
							StructureOfActions = New Structure;
							StructureOfActions.Insert("CheckFillCommunicationKeySpecifications");
							StructureOfActions.Insert("FillInPurposeOfProvisionInProductionPhase", ParametersForFillingAssignments);
							BatchProcessingOfTablePartServer.ProcessTSString(NewRow, StructureOfActions, Undefined);
							
						EndIf;
						
						StringsToProcess.Add(NewRow);
					
					EndDo;
					
					IndexList1.SortByValue(SortDirection.Desc);
					
					For Each ListLine In IndexList1 Do
						
						RowIndex = ListLine.Value;
						TSRow = StageObject.SupplyWithMaterialsAndWorks[RowIndex];
						If TSRow.Count = 0 Then
							If ValueIsFilled(TSRow.CommunicationKeySet) Then
								ProductDataManagement.AdjustTableSetsOfMaterialsAndWorks(
									StageObject.MaterialsAndWorksSets, TSRow.CommunicationKeySet, -1);
							EndIf;
							StageObject.SupplyWithMaterialsAndWorks.Delete(TSRow);
						EndIf;
					
					EndDo;
					
					ActionSettingParameters = New Structure;
					ActionSettingParameters.Insert("UncheckShipByOneDateFlag", False);
					ActionSettingParameters.Insert("FillShippingDateWithSingleDate", True);
					
					EmbeddingParameters = Documents.ProductionStage2_2.AvailableRemainingEmbeddingOptions(StageObject);
					
					ProvisionInDocumentsServer.FillInBalanceProvisionOptionForSelectedObjectRows(
						StageObject,
						"ACTION_RESERVE",
						ActionSettingParameters, StringsToProcess, EmbeddingParameters);
					
					ProductsServer.FillInStatusesForSpecifyingSeries(
						StageObject,
						Documents.ProductionStage2_2.SeriesSpecificationParameters(StageObject).SupplyWithMaterialsAndWorks);
					
					OrderStructureDocumentPosting.ProductionStageBeforeWrite(
						StageObject, StageObject.AdditionalProperties, False);
			
					OrdersServer.SetKeyInRowsOfTablePart(
						StageObject, "SupplyWithMaterialsAndWorks", "MaximumRowCodeMaterialsAndServicesSupply");
					
					StageObject.Write(DocumentWriteMode.Posting);
					
					TableRow = ModifiedObjects.Add();
					TableRow.Document = StageLink;
					TableRow.Presentation = PresentationStage;
					TableRow.ReferenceOrder = StageObject.ReferenceOrder;
					
				EndIf;
				
				CommitTransaction();
			
			Except
				
				RollbackTransaction();
				
				If IsBlankString(PresentationStage) Then
					PresentationStage = String(StageLink);
				EndIf;
				
				If LockSet Then
					ErrorText = ErrorProcessing.DetailErrorDescription(ErrorInfo());
					ReplacementExecutionError = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplateReplacementWithAnalogs, StageLink, ErrorText);
				Else
					ErrorText = ErrorProcessing.BriefErrorDescription(ErrorInfo());
					ReplacementExecutionError = StringFunctionsClientServer.SubstituteParametersToString(ErrorPatternBlocking, StageLink, ErrorText);
				EndIf;
				
				Error = Errors.Add();
				Error.Document = StageLink;
				Error.Presentation = PresentationStage;
				Error.MessageText = ReplacementExecutionError;
				
				Continue;
				
			EndTry;
		
		EndDo;
	
	EndIf;
	
	// Fixing the result
	PutToTempStorage(Result, StorageAddress);

EndProcedure

Function ResultOfAutomaticFillingOfAssistant() Export

	ReturnStructure = New Structure;
	ReturnStructure.Insert("StepsTable", New ValueTable);
	ReturnStructure.Insert("Tree", New ValueTree);
	ReturnStructure.Insert("BalanceTable", New ValueTable);
	
	Return ReturnStructure;

EndFunction

Procedure FillOutAccessibilityAssistantOnHold(Parameters, StorageAddress) Export

	OperationName = "Document.EngineeringChangeOrder.ManagerModule.FillOutAccessibilityAssistantOnHold";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(OperationName);
	
	DataVolume = FillOutAccessibilityAssistant(Parameters.StructureOfFormData, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

EndProcedure

Function FillOutAccessibilityAssistant(StructureOfFormData, StorageAddress)
	
	Tree = StructureOfFormData.Tree;
	BalanceTable = StructureOfFormData.RemnantsOfAnalogues;
	StepsTable = StructureOfFormData.Stages;
	Resolution = StructureOfFormData.Resolution;
	ReplacementPriority = StructureOfFormData.ReplacementPriority;
	FilterStructure1 = StructureOfFormData.StageSelectionStructure;
	
	ColumnsNames = "
	|ConnectionKey,
	|Products,
	|Characteristic,
	|Purpose,
	|WithAssignment,
	|Warehouse,
	|Department,
	|LineOfBusiness,
	|Stage,
	|ProductionOrder,
	|BillOfMaterials,
	|StageOfResourceBillOfMaterials,
	|Product,
	|ItemVariantOfProduct,
	|Total,
	|Shipped,
	|Supplied";
	
	If FilterStructure1.Count() > 0 Then
		TableOfGoods = StructureOfFormData.Stages.Copy(FilterStructure1, ColumnsNames);
	Else
		TableOfGoods = StructureOfFormData.Stages.Copy(, ColumnsNames);
	EndIf;
	
	ChoiceParameters = AlternativeMaterials.AnalogSelectionParameters(
		Common.TypeDescriptionNumber(15));
		
	Filter = New Map();
	TMCommonUse.AddSelectionItemToCollection(Filter, "AlternativeMaterials.Recorder", "&Resolution");
		
	ChoiceParameters.GeneralParameters.SelectionOfPermissions = Filter;
	ChoiceParameters.GeneralParameters.PermissionSelectionParameters.Insert("Resolution", Resolution);
		
	TMCommonUse.NumberValueTable(TableOfGoods, "LineNumber");
	
	TableOfGoods.Columns.Add("Ref", Common.TypeDescriptionNumber(15));
	TableOfGoods.Columns.Add("TotalCount1", New TypeDescription("Number", New NumberQualifiers));
	TableOfGoods.Columns.Add("Count", New TypeDescription("Number", New NumberQualifiers));
	
	ReplacementInAbsenceOfMaterial = (ReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials);
	DataVolume = TableOfGoods.Count();
	
	ParametersTable = ChoiceParameters.SubstitutesParameters.ParametersTable;
	
	For Each String In TableOfGoods Do
		
		TableRow = ParametersTable.Add();
		TableRow.PermissionValidityDate = BegOfDay(CurrentSessionDate());
		TableRow.Ref = String.ConnectionKey;
		TableRow.Department = String.Department;
		TableRow.LineOfBusiness = String.LineOfBusiness;
		TableRow.ProductionOrder = String.ProductionOrder;
		TableRow.BillOfMaterials = String.BillOfMaterials;
		TableRow.Stage = String.StageOfResourceBillOfMaterials;
		TableRow.Product = String.Product;
		TableRow.ItemVariantOfProduct = String.ItemVariantOfProduct;
		
		String.Ref = String.ConnectionKey;
		If ReplacementInAbsenceOfMaterial Then
			String.Count = String.Total - String.Supplied;
		Else
			String.Count = String.Total - String.Shipped;
		EndIf;
		String.TotalCount1 = String.Count;
		
	EndDo;
		
	ChoiceParameters.GoodsParameters.Goods = PutToTempStorage(TableOfGoods);
	ChoiceParameters.SubstitutesParameters.ParametersTable = PutToTempStorage(ParametersTable);
	
	TableOfSubstitutionsForAnalogues = AlternativeMaterials.GetReplacementTable(ChoiceParameters);
	
	FlagMaterial = 1;
	FlagSubstitute = 0;
	
	SearchByLineNumber = New Structure("LineNumber");
	SearchForCommunicationKey = New Structure("ConnectionKey");
	ListOfProperties = "Products, Characteristic, ThisIsASubstitute";
	StructureOfKeyFields = New Structure("Products, Characteristic, Purpose, Ref");
	ProductSearchStructure_ = New Structure(ListOfProperties);
	
	SearchForSourceString = New Structure("Products, Characteristic, ConnectionKey");
	BalanceTable.Indexes.Add("Products, Characteristic, Purpose, Warehouse");
	StepsTable.Indexes.Add("Products, Characteristic, ConnectionKey");
	StepsTable.Indexes.Add("ConnectionKey");
		
	If TableOfSubstitutionsForAnalogues <> Undefined Then
		
		Goods = TableOfSubstitutionsForAnalogues.Copy(, ListOfProperties);
		Goods.GroupBy(ListOfProperties);
		
		For Each SpecificationRow In Goods Do
		
			NewTreeRow = Tree.Rows.Add();
			NewTreeRow.Products = SpecificationRow.Products;
			NewTreeRow.Characteristic = SpecificationRow.Characteristic;
			NewTreeRow.ItemVariantsAreUsed = ValueIsFilled(NewTreeRow.Characteristic);
			
			FillPropertyValues(ProductSearchStructure_, SpecificationRow);
			ArrayOfReplacementsForAnalogues = TableOfSubstitutionsForAnalogues.FindRows(ProductSearchStructure_);
			
			For Each RowFromReplacementTable In ArrayOfReplacementsForAnalogues Do
				
				If StructureOfKeyFields.Products <> RowFromReplacementTable.Products
				 Or StructureOfKeyFields.Characteristic <> RowFromReplacementTable.Characteristic
				 Or StructureOfKeyFields.Purpose <> RowFromReplacementTable.Purpose
				 Or StructureOfKeyFields.Ref <> RowFromReplacementTable.Ref Then
				
					NewRow = NewTreeRow.Rows.Add();
					FillPropertyValues(StructureOfKeyFields, RowFromReplacementTable);
				
				EndIf;
				
				FillPropertyValues(NewRow, RowFromReplacementTable, "Products, Characteristic, Purpose");
				NewRow.ItemVariantsAreUsed = ValueIsFilled(NewRow.Characteristic);
				
				If RowFromReplacementTable.ThisIsASubstitute Then
					
					SearchForCommunicationKey.ConnectionKey = RowFromReplacementTable.Ref;
					StageString_ = StepsTable.FindRows(SearchForCommunicationKey)[0];
					
					NewRow.Warehouse = RowFromReplacementTable.Warehouse;
					NewRow.Flag = FlagSubstitute;
					NewRow.Count = NewRow.Count + RowFromReplacementTable.Count;
					NewTreeRow.Flag = FlagSubstitute;
					NewTreeRow.Count = NewTreeRow.Count + RowFromReplacementTable.Count;
					
				Else
					
					FillPropertyValues(SearchForSourceString, RowFromReplacementTable, "Products, Characteristic");
					SearchForSourceString.ConnectionKey = RowFromReplacementTable.Ref;
					
					StageString_ = StepsTable.FindRows(SearchForSourceString)[0];
					
					SearchByLineNumber.LineNumber = RowFromReplacementTable.LineNumber;
					ProductLines_2 = TableOfGoods.FindRows(SearchByLineNumber);
					QuantityToBeSubtracted = ProductLines_2[0].Count - RowFromReplacementTable.Count;
					
					NewRow.Warehouse = StageString_.Warehouse;
					NewRow.Count = NewRow.Count + QuantityToBeSubtracted;
					NewRow.Flag = FlagMaterial;
					
					NewTreeRow.Count = NewTreeRow.Count + QuantityToBeSubtracted;
					NewTreeRow.Flag = FlagMaterial;
					
					StageString_.ToReplace = QuantityToBeSubtracted;
					StageString_.Selected = StageString_.ToReplace > 0;
					StageString_.ToBeReplacedBeforeChange = QuantityToBeSubtracted;
				
				EndIf;
				
				NewRow.Stage = StageString_.Stage;
				NewRow.OrderPresentation = StageString_.OrderPresentation;
			
			EndDo;
			
			If NewTreeRow.Flag <> FlagMaterial Then
			
				For Each DecryptionString In NewTreeRow.Rows Do
					ReflectChangeInBalanceTable(BalanceTable, DecryptionString);
				EndDo;
				
			EndIf;
		
		EndDo;
	
	EndIf;

	UpdateColumnAvailable(StructureOfFormData, StepsTable, BalanceTable);
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("StepsTable", StepsTable);
	ReturnStructure.Insert("Tree", Tree);
	ReturnStructure.Insert("BalanceTable", BalanceTable);
	
	PutToTempStorage(ReturnStructure, StorageAddress);
	
	Return DataVolume;

EndFunction

Procedure FillOutStrategyAssistantOnHold(Parameters, StorageAddress) Export

	OperationName = "Document.EngineeringChangeOrder.ManagerModule.FillOutStrategyAssistantOnHold";
	MeasurementDetails = PerformanceMonitor.StartTimeConsumingOperationMeasurement(OperationName);
	
	DataVolume = FillInStrategyAssistant(Parameters.StructureOfFormData, StorageAddress);
	
	PerformanceMonitor.EndTimeConsumingOperationMeasurement(MeasurementDetails, DataVolume);

EndProcedure

Function FillInStrategyAssistant(StructureOfFormData, StorageAddress)
	
	FillingInUnloaded = StructureOfFormData.FillingInUnloaded;
	RowFilter = StructureOfFormData.StageSelectionStructure;
	Stages = StructureOfFormData.Stages;
	Tree = StructureOfFormData.Tree;
	TableOfBalancesOfAnalogues = StructureOfFormData.RemnantsOfAnalogues;
	
	If RowFilter.Count() > 0 Then
		DataTable = Stages.Copy(RowFilter, "Stage, ConnectionKey");
	Else
		DataTable = Stages.Copy(, "Stage, ConnectionKey");
	EndIf;
	
	DataTable.GroupBy("Stage, ConnectionKey");
	DataTable.Indexes.Add("Stage, ConnectionKey");
	FilterParameters = New Structure("Stage, ConnectionKey");
	
	DataVolume = DataTable.Count();
	LinesByProductName = Tree.Rows;
	TableOfBalancesOfAnalogues.Indexes.Add("Products, Characteristic, Warehouse, Purpose");
	
	For Each TableRow In DataTable Do
		
		FillPropertyValues(FilterParameters, TableRow);
		StageLines_ = Stages.FindRows(FilterParameters);
		
		NumberOfSetsToReplace = -1;
		
		For Each SpecificationRow In StageLines_ Do
	
			If FillingInUnloaded Then
				ToReplace = SpecificationRow.Total - SpecificationRow.Shipped - SpecificationRow.ToBeReplacedBeforeChange;
			Else
				ToReplace = SpecificationRow.Total - SpecificationRow.Supplied - SpecificationRow.ToBeReplacedBeforeChange;
			EndIf;
			
			NumberOfSets = ProductionClientServer.CoefficientByStandard(
				SpecificationRow.ControlMultiplier,
				ToReplace,
				SpecificationRow.NormativeStandard, 
				SpecificationRow.PackageData);
			
			If NumberOfSetsToReplace = -1 Then
				NumberOfSetsToReplace = NumberOfSets;
			Else
				NumberOfSetsToReplace = Min(NumberOfSetsToReplace, NumberOfSets);
			EndIf;
			
		EndDo;
		
		If NumberOfSetsToReplace <> 0 Then
			ToProcessUpdate(StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, FilterParameters.Stage, FilterParameters.ConnectionKey, NumberOfSetsToReplace, SpecificationRow);
		EndIf;
		
	EndDo;
	
	UpdateColumnAvailable(StructureOfFormData, Stages, TableOfBalancesOfAnalogues);
	
	ReturnStructure = New Structure;
	ReturnStructure.Insert("StepsTable", Stages);
	ReturnStructure.Insert("Tree", Tree);
	ReturnStructure.Insert("BalanceTable", TableOfBalancesOfAnalogues);
	
	PutToTempStorage(ReturnStructure, StorageAddress);
	
	Return DataVolume;

EndFunction

Function ToProcessUpdate(
	StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, Stage, ConnectionKey, NumberOfSets, StageString_, FillInToReplaceCurrentLine = True) Export
	
	Stages = StructureOfFormData.Stages;
	
	FilterParameters = New Structure;
	FilterParameters.Insert("Stage", Stage);
	FilterParameters.Insert("ConnectionKey", ConnectionKey);
	CancelUpdate = False;
	
	DetachedSet = False;
	PurposeOfSeparation = Catalogs.Assignments.EmptyRef();
	Warehouse = Catalogs.Warehouses.EmptyRef();
	OrderPresentation = "";
	
	StageLines = Stages.FindRows(FilterParameters);
	
	For Each TableRow In StageLines Do
	
		If TableRow.ControlMultiplier
		   And Int(NumberOfSets) <> NumberOfSets Then
		
			CancelUpdate = True;
			MessageText = NStr("vi = 'Nhập bội số của tiêu chuẩn.';
								|ru = 'Введите количество кратное нормативу.';
								|en = 'Enter the amount multiple of the standard'; fa = 'Enter the amount multiple of the standard';
								|it = 'Inserite un numero multiplo della quantità standard.';
								|pl = 'Wprowadź ilość wielokrotną normie.';
								|tr = 'Miktarı standardın katları olarak girin.'");
			Common.MessageToUser(MessageText);
			Break;
		
		EndIf;
		
		EstimatedQuantity = EstimatedNumberOfItems(TableRow.NormativeStandard, NumberOfSets, TableRow.PackageData);
		
		If TableRow.ToBeReplacedBeforeChange + EstimatedQuantity > TableRow.Total - TableRow.Shipped Then
		
			CancelUpdate = True;
			MessageText = NStr("vi = 'Hãy nhập số lượng không lớn hơn số lượng chưa giao.';
								|ru = 'Введите количество не превышающее неотгруженное количество.';
								|en = 'Enter a number no greater than the number of unshipped goods.'; fa = 'Enter a number no greater than the number of unshipped goods.';
								|it = 'Enter a number no greater than the number of unshipped goods.';
								|pl = 'Enter a number no greater than the number of unshipped goods.';
								|tr = 'Sevk edilmemiş miktarı aşmayan bir miktar girin.'");
			Common.MessageToUser(MessageText);
			Break;
		
		EndIf;
		
		If ConnectionKey <> 0 Then
			PurposeOfSeparation = TableRow.Purpose;
		EndIf;
		
		Warehouse = TableRow.Warehouse;
		OrderPresentation = TableRow.OrderPresentation;
		DetachedSet = TableRow.DetachedSet;
		
	EndDo;
	
	If CancelUpdate Then
	
		For Each TableRow In StageLines Do
		
			TableRow.ToReplace = TableRow.ToBeReplacedBeforeChange;
			TableRow.Selected = TableRow.ToReplace > 0;
		
		EndDo;
		
	Else
		
		FillingData = New Structure;
		FillingData.Insert("Purpose", PurposeOfSeparation);
		FillingData.Insert("DetachedSet", DetachedSet);
		FillingData.Insert("Warehouse", Warehouse);
		FillingData.Insert("StageLines", StageLines);
		FillingData.Insert("Stage", Stage);
		FillingData.Insert("OrderPresentation", OrderPresentation);
		FillingData.Insert("FillingInSelectedLine", False);
		FillingData.Insert("FillInToReplaceCurrentLine", FillInToReplaceCurrentLine);
		FillingData.Insert("SelectedRow", StageString_);
		
		ReflectManualQuantityChangeToReplacement(StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, FillingData, NumberOfSets);
		
	EndIf;
	
	Return Not CancelUpdate;

EndFunction

Procedure ReflectManualQuantityChangeToReplacement(StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, FillingData, NumberOfSets) Export
	
	SelectionOfInterchangeableAnalogues = StructureOfFormData.SelectionOfInterchangeableAnalogues;
	Standards = StructureOfFormData.Standards;
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Flag");
	SelectedRow = FillingData.SelectedRow;
	
	If SelectionOfInterchangeableAnalogues Then
				
		FillInTranscriptOfInterchangeableAnalogues(
			StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, FillingData, NumberOfSets);
			
	Else
			
		For Each LineOfStandard In Standards Do
		
			FillingData.FillingInSelectedLine = LineOfStandard.Products = SelectedRow.Products
			   And LineOfStandard.Characteristic = SelectedRow.Characteristic;
				
			FillPropertyValues(TheStructureOfTheSearch, LineOfStandard);
			TheStructureOfTheSearch.Flag = ?(LineOfStandard.ThisIsMaterial, 1, 0);
			
			TreeRows = FindAddTreeRow(LinesByProductName, TheStructureOfTheSearch);
				
			For Each LineByItem In TreeRows Do
				
				If LineOfStandard.ThisIsMaterial Then
				
					FillInTranscriptOfMaterialsByLineParent(
						LineByItem, FillingData, NumberOfSets, LineOfStandard);
						
				Else	
					
					EstimatedQuantity = EstimatedNumberOfItems(LineOfStandard.NormativeStandard, NumberOfSets, LineOfStandard.PackageData); 
					
					FillInTranscriptOfAnalogsOnParentLine(
						StructureOfFormData, LineByItem, TableOfBalancesOfAnalogues, FillingData, EstimatedQuantity);
					
				EndIf;
			
			EndDo;
			
			If LineByItem.Count = 0 Then
				LinesByProductName.Delete(LineByItem);
			EndIf;
		
		EndDo;	
	
	EndIf;

EndProcedure

Procedure FillInTranscriptOfMaterialsByLineParent(LineByItem, FillingData, Val NumberOfSets, Line1_) Export
	
	NormativeStandard = Line1_.NormativeStandard;
	PackageData = Line1_.PackageData;
	Count = EstimatedNumberOfItems(NormativeStandard, NumberOfSets, PackageData);
	LineByItem.Count = LineByItem.Count + Count;
	
	If FillingData.FillingInSelectedLine Then
		
		SelectedRow = FillingData.SelectedRow;
		
		If FillingData.FillInToReplaceCurrentLine Then
			SelectedRow.ToReplace = Count;
		EndIf;
		
		SelectedRow.ToBeReplacedBeforeChange = SelectedRow.ToReplace;
		SelectedRow.Selected = SelectedRow.ToReplace > 0;
		FillInDecryptionLineInTree(LineByItem, FillingData, SelectedRow.Purpose, Count);
		
	Else
		
		For Each StageString In FillingData.StageLines Do
			
			If NumberOfSets = 0 Then
				Break;
			EndIf;
			
			If StageString.Products = LineByItem.Products
			   And StageString.Characteristic = LineByItem.Characteristic Then
			
				AvailableToInstall = ProductionClientServer.CoefficientByStandard(
					Line1_.ControlMultiplier, 
					StageString.Total - StageString.Shipped - StageString.ToBeReplacedBeforeChange, 
					NormativeStandard, 
					PackageData);
				
				If AvailableToInstall >= NumberOfSets Then
					ForSetting = NumberOfSets;
				Else
					ForSetting = AvailableToInstall;
				EndIf;
				
				If ForSetting <> 0 Then
					
					EstimatedQuantity = EstimatedNumberOfItems(NormativeStandard, ForSetting, PackageData);
					StageString.ToReplace = StageString.ToReplace + EstimatedQuantity;
					StageString.Selected = StageString.ToReplace > 0;
					StageString.ToBeReplacedBeforeChange = StageString.ToReplace;
					
					FillInDecryptionLineInTree(LineByItem, FillingData, StageString.Purpose, Count);
					
					NumberOfSets = NumberOfSets - ForSetting;
					
				EndIf;
				
			EndIf;
		
		EndDo;
	
	EndIf;
	
EndProcedure

Procedure FillInTranscriptOfAnalogsOnParentLine(StructureOfFormData, LineByItem, TableOfBalancesOfAnalogues, FillingData, Count) Export
	
	ParametersOfAnalogSelection = New Structure("Products, Characteristic, Purpose, Warehouse");
	FillPropertyValues(ParametersOfAnalogSelection, LineByItem, "Products, Characteristic");
	ParametersOfAnalogSelection.Warehouse = FillingData.Warehouse;
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	
	AdditionalParameters = New Structure();
	AdditionalParameters.Insert("LinesByProductName", Undefined);
	AdditionalParameters.Insert("TheStructureOfTheSearch", Undefined);
	AdditionalParameters.Insert("SelectedRow", Undefined);
	
	ReducingNumber = Count < 0;
	ThereIsUndistributedAmount = Count <> 0;
	
	If ReducingNumber Then
		
		SearchForCreditedLines = New Structure();
		SearchForCreditedLines.Insert("Products", LineByItem.Products);
		SearchForCreditedLines.Insert("Characteristic", LineByItem.Characteristic);
		SearchForCreditedLines.Insert("Warehouse", FillingData.Warehouse);
		SearchForCreditedLines.Insert("Stage", FillingData.Stage);
		
		SelectedAppointments = New Map;
		ArrayOfCountedLines = LineByItem.Rows.FindRows(SearchForCreditedLines);
		
		For Each TreeRow In ArrayOfCountedLines Do
			
			If SelectedAppointments.Get(TreeRow.Purpose) = Undefined Then
				SelectedAppointments.Insert(TreeRow.Purpose, TreeRow.Count);
			EndIf;
			
		EndDo;
		
		QuantityWithoutAssignment = SelectedAppointments.Get(EmptyAssignment);
		
		If ThereIsUndistributedAmount
		   And QuantityWithoutAssignment <> Undefined Then
		
			ParametersOfAnalogSelection.Purpose = EmptyAssignment;
			QuantityToChange = Max(Count, -QuantityWithoutAssignment);
			Count = Count - QuantityToChange;
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, QuantityToChange, ParametersOfAnalogSelection, FillingData, LineByItem, AdditionalParameters);
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
		QuantityByAppointment = SelectedAppointments.Get(FillingData.Purpose);
		
		If ThereIsUndistributedAmount And ValueIsFilled(FillingData.Purpose)
		   And QuantityByAppointment <> Undefined Then
	
			ParametersOfAnalogSelection.Purpose = FillingData.Purpose;
			QuantityToChange = Max(Count, -QuantityByAppointment);
			Count = Count - QuantityToChange;
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, QuantityToChange, ParametersOfAnalogSelection, FillingData, LineByItem, AdditionalParameters);
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
	Else	
		
		If ThereIsUndistributedAmount And ValueIsFilled(FillingData.Purpose) Then
	
			ParametersOfAnalogSelection.Purpose = FillingData.Purpose;
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, Count, ParametersOfAnalogSelection, FillingData, LineByItem, AdditionalParameters);
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
		If ThereIsUndistributedAmount Then
		
			ParametersOfAnalogSelection.Purpose = EmptyAssignment;
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, Count, ParametersOfAnalogSelection, FillingData, LineByItem, AdditionalParameters);
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
	EndIf;
	
	If ThereIsUndistributedAmount Then
		
		PurposeOfSearch = ?(FillingData.DetachedSet, FillingData.Purpose, EmptyAssignment);
		ParametersOfAnalogSelection.Purpose = PurposeOfSearch;
		
		BalanceAccountingLine = Undefined;
		RemainderLines_ = TableOfBalancesOfAnalogues.FindRows(ParametersOfAnalogSelection);
		If RemainderLines_.Count() > 0 Then
			BalanceAccountingLine = RemainderLines_[0];
		EndIf;
		
		If BalanceAccountingLine <> Undefined Then
			
			If ReducingNumber Then
				
				ToWriteOff = -Count;
				ToWriteOffOverBalance = Min(BalanceAccountingLine.UsedInExcessOfBalance, ToWriteOff);
				
				If ToWriteOffOverBalance <> 0 Then
					BalanceAccountingLine.UsedInExcessOfBalance = BalanceAccountingLine.UsedInExcessOfBalance - ToWriteOffOverBalance;
				EndIf;
				
				ToWriteOff = ToWriteOff - ToWriteOffOverBalance;
				UsedForWriteOff = Min(BalanceAccountingLine.Used_, ToWriteOff);
				
				If UsedForWriteOff <> 0 Then
					BalanceAccountingLine.Used_ = BalanceAccountingLine.Used_ - UsedForWriteOff;
				EndIf;
				
			Else
				
				BalanceAccountingLine.UsedInExcessOfBalance = BalanceAccountingLine.UsedInExcessOfBalance + Count;
			
			EndIf;
			
		EndIf;
		
		LineByItem.Count = LineByItem.Count + Count;
		FillInDecryptionLineInTree(LineByItem, FillingData, PurposeOfSearch, Count);
	
	EndIf;
	
EndProcedure

Procedure FillInTranscriptOfInterchangeableAnalogues(StructureOfFormData, LinesByProductName, TableOfBalancesOfAnalogues, FillingData, NumberOfSets) Export
	
	Standards = StructureOfFormData.Standards;
	FillingData.FillingInSelectedLine = True;
	SelectedRow = FillingData.SelectedRow;
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	
	StructureOfStandardSearch = New Structure("Products, Characteristic");
	FillPropertyValues(StructureOfStandardSearch, SelectedRow);
	
	For Each TableRow In Standards Do
	
		If TableRow.Products = SelectedRow.Products
		   And TableRow.Characteristic = SelectedRow.Characteristic Then
		
			Continue;
		
		EndIf;
		
		LineOfStandard = TableRow;
		Break;
	
	EndDo;
	
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Flag");
	FillPropertyValues(TheStructureOfTheSearch, SelectedRow);
	TheStructureOfTheSearch.Flag = 1;
	
	TreeRows = FindAddTreeRow(LinesByProductName, TheStructureOfTheSearch);
	
	For Each LineByItem In TreeRows Do
				
		FillInTranscriptOfMaterialsByLineParent(
			LineByItem, FillingData, NumberOfSets, LineOfStandard);
			
		If LineByItem.Count = 0 Then
			LinesByProductName.Delete(LineByItem);
		EndIf;
	
	EndDo;
		
	FillingData.FillingInSelectedLine = False;
	TheStructureOfTheSearch.Flag = 0;
	FlagSubstitute = 0;
		
	Count = EstimatedNumberOfItems(LineOfStandard.NormativeStandard, NumberOfSets, LineOfStandard.PackageData);
	ThereIsUndistributedAmount = Count <> 0;
	ReducingNumber = Count < 0;
	
	SelectionByDestinationWarehouse = New Structure("Purpose, Warehouse");
	FillPropertyValues(SelectionByDestinationWarehouse, FillingData);
	
	If ThereIsUndistributedAmount And ReducingNumber Then
		
		SearchForCreditedLines = New Structure();
		SearchForCreditedLines.Insert("Warehouse", FillingData.Warehouse);
		SearchForCreditedLines.Insert("Stage", FillingData.Stage);
		
		CrawlTable = New ValueTable;
		CrawlTable.Columns.Add("Products", New TypeDescription("CatalogRef.Products"));
		CrawlTable.Columns.Add("Characteristic", New TypeDescription("CatalogRef.ItemsCharacteristics"));
		CrawlTable.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
		CrawlTable.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
		CrawlTable.Columns.Add("Count", Common.TypeDescriptionNumber(15,3));
		
		For Each TreeRow In LinesByProductName Do
		
			If TreeRow.Flag = FlagSubstitute
			   And Not (TreeRow.Products = SelectedRow.Products
			   And TreeRow.Characteristic = SelectedRow.Characteristic) Then
			
				SearchRows = TreeRow.Rows;
				
				ArrayOfCountedLines = SearchRows.FindRows(SearchForCreditedLines);
				
				For Each TreeRow In ArrayOfCountedLines Do
					
					NewCrawlLine = CrawlTable.Add();
					FillPropertyValues(NewCrawlLine, TreeRow);
					
				EndDo;
			
			EndIf;	
		
		EndDo;
		
		AdditionalParameters = New Structure();
		AdditionalParameters.Insert("LinesByProductName", LinesByProductName);
		AdditionalParameters.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
		AdditionalParameters.Insert("SelectedRow", SelectedRow);
		
		ParametersOfSelectionOfBalanceAnalogues = New Structure("Products, Characteristic, Purpose, Warehouse");
		CrawlTable.Sort("Purpose", New CompareValues);
		For Each CrawlString In CrawlTable Do
		
			If Not ThereIsUndistributedAmount Then
				Break;
			EndIf;
			
			FillPropertyValues(ParametersOfSelectionOfBalanceAnalogues, CrawlString);
			QuantityToChange = Max(Count, -CrawlString.Count);
			Count = Count - QuantityToChange;
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, QuantityToChange, ParametersOfSelectionOfBalanceAnalogues, FillingData, Undefined, AdditionalParameters);
			ThereIsUndistributedAmount = Count <> 0;
		
		EndDo;
		
	Else
		
		If ThereIsUndistributedAmount And ValueIsFilled(FillingData.Purpose) Then
		
			SelectionByDestinationWarehouse.Purpose = FillingData.Purpose;
			AdditionalParameters = New Structure();
			AdditionalParameters.Insert("LinesByProductName", LinesByProductName);
			AdditionalParameters.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
			AdditionalParameters.Insert("SelectedRow", SelectedRow);
			
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, Count, SelectionByDestinationWarehouse, FillingData, Undefined, AdditionalParameters);
			
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
		If ThereIsUndistributedAmount Then
		
			SelectionByDestinationWarehouse.Purpose = EmptyAssignment;
			AdditionalParameters = New Structure();
			AdditionalParameters.Insert("LinesByProductName", LinesByProductName);
			AdditionalParameters.Insert("TheStructureOfTheSearch", TheStructureOfTheSearch);
			AdditionalParameters.Insert("SelectedRow", SelectedRow);
			
			ProcessIterationOfSelectingAnalogBalances(StructureOfFormData, TableOfBalancesOfAnalogues, Count, SelectionByDestinationWarehouse, FillingData, Undefined, AdditionalParameters);
			
			ThereIsUndistributedAmount = Count <> 0;
		
		EndIf;
		
	EndIf;
		
	If ThereIsUndistributedAmount Then
		
		PurposeOfSearch = ?(FillingData.DetachedSet, FillingData.Purpose, EmptyAssignment);
		ParametersOfAnalogSelection = New Structure("Products, Characteristic, Purpose, Warehouse");
		ParametersOfAnalogSelection.Purpose = PurposeOfSearch;
		ParametersOfAnalogSelection.Warehouse = SelectionByDestinationWarehouse.Warehouse;
		ParametersOfAnalogSelection.Products = LineOfStandard.Products;
		ParametersOfAnalogSelection.Characteristic = LineOfStandard.Characteristic;
		
		BalanceAccountingLine = Undefined;
		RemainderLines_ = TableOfBalancesOfAnalogues.FindRows(ParametersOfAnalogSelection);
		If RemainderLines_.Count() > 0 Then
			BalanceAccountingLine = RemainderLines_[0];
		EndIf;
		
		If BalanceAccountingLine <> Undefined Then
			
			If ReducingNumber Then
				
				ToWriteOff = -Count;
				ToWriteOffOverBalance = Min(BalanceAccountingLine.UsedInExcessOfBalance, ToWriteOff);
				
				If ToWriteOffOverBalance <> 0 Then
					BalanceAccountingLine.UsedInExcessOfBalance = BalanceAccountingLine.UsedInExcessOfBalance - ToWriteOffOverBalance;
				EndIf;
				
				ToWriteOff = ToWriteOff - ToWriteOffOverBalance;
				UsedForWriteOff = Min(BalanceAccountingLine.Used_, ToWriteOff);
				
				If UsedForWriteOff <> 0 Then
					BalanceAccountingLine.Used_ = BalanceAccountingLine.Used_ - UsedForWriteOff;
				EndIf;
				
			Else
				
				BalanceAccountingLine.UsedInExcessOfBalance = BalanceAccountingLine.UsedInExcessOfBalance + Count;
			
			EndIf;
			
		EndIf;
		
		FillPropertyValues(TheStructureOfTheSearch, LineOfStandard);
		TreeRows = FindAddTreeRow(LinesByProductName, TheStructureOfTheSearch);
		LineByItem = TreeRows[0];
		LineByItem.Count = LineByItem.Count + Count;
		FillInDecryptionLineInTree(LineByItem, FillingData, PurposeOfSearch, Count);
			
		If LineByItem.Count = 0 Then
			LinesByProductName.Delete(LineByItem);
		EndIf;
	
	EndIf;
	
EndProcedure

Function FindAddTreeRow(LinesByProductName, TheStructureOfTheSearch) Export

	TreeRows = LinesByProductName.FindRows(TheStructureOfTheSearch);
			
	If TreeRows.Count() = 0 Then
	
		LineByItem = LinesByProductName.Add();
		FillPropertyValues(LineByItem, TheStructureOfTheSearch);
		LineByItem.ItemVariantsAreUsed = ValueIsFilled(LineByItem.Characteristic);
		TreeRows.Add(LineByItem);
		
	EndIf;
	
	Return TreeRows;

EndFunction

Procedure ProcessIterationOfSelectingAnalogBalances(
	StructureOfFormData, TableOfBalancesOfAnalogues, Count, ParametersOfAnalogSelection, FillingData, LineByItem, AdditionalParameters) Export
	
	SelectionOfInterchangeableAnalogues = StructureOfFormData.SelectionOfInterchangeableAnalogues;
	ArrayOfBalances = TableOfBalancesOfAnalogues.FindRows(ParametersOfAnalogSelection);

	LinesByProductName = AdditionalParameters.LinesByProductName;
	TheStructureOfTheSearch = AdditionalParameters.TheStructureOfTheSearch;
	SelectedRow = AdditionalParameters.SelectedRow;
	
	For Each RemainderLine_ In ArrayOfBalances Do
	
		If Count = 0 Then
			Break;
		EndIf;
		
		If SelectionOfInterchangeableAnalogues Then
		
			If RemainderLine_.Products = SelectedRow.Products
			   And RemainderLine_.Characteristic = SelectedRow.Characteristic Then
			
				Continue;
			
			EndIf;
			
			FillPropertyValues(TheStructureOfTheSearch, RemainderLine_, "Products, Characteristic");
			
			TreeRows = FindAddTreeRow(LinesByProductName, TheStructureOfTheSearch);
			LineByItem = TreeRows[0];
		
		EndIf;
		
		ProcessBalanceLine(Count, FillingData, ParametersOfAnalogSelection.Purpose, RemainderLine_, LineByItem);
		
		If LinesByProductName <> Undefined And LineByItem.Count = 0 Then
			LinesByProductName.Delete(LineByItem);
		EndIf;
	
	EndDo;
	
EndProcedure

Procedure FillInDecryptionLineInTree(LineByItem, FillingData, Purpose, Count) Export

	FilterStructure1 = New Structure;
	FilterStructure1.Insert("Products", LineByItem.Products);
	FilterStructure1.Insert("Characteristic", LineByItem.Characteristic);
	FilterStructure1.Insert("Purpose", Purpose);
	FilterStructure1.Insert("Stage", FillingData.Stage);
	FilterStructure1.Insert("Warehouse", FillingData.Warehouse);
	
	DecryptionLines = LineByItem.Rows.FindRows(FilterStructure1);
	
	If DecryptionLines.Count() = 0 Then
		
		DecryptionString = LineByItem.Rows.Add();
		FillPropertyValues(DecryptionString, LineByItem,, "Count");
		FillPropertyValues(DecryptionString, FillingData, "Stage, OrderPresentation");
		DecryptionString.Purpose = Purpose;
		DecryptionString.Warehouse = FillingData.Warehouse;
		DecryptionString.Count = Count;
		
	Else
		
		LinesToDelete = New Array;
		
		For Each DecryptionString In DecryptionLines Do
		
			DecryptionString.Count = DecryptionString.Count + Count;
			
			If DecryptionString.Count = 0 Then
				LinesToDelete.Add(DecryptionString);
			EndIf;
		
		EndDo;
		
		For Each RowToDelete In LinesToDelete Do
			LineByItem.Rows.Delete(RowToDelete);
		EndDo;
	
	EndIf;

EndProcedure

Procedure ProcessBalanceLine(Count, FillingData, Purpose, RemainderLine_, LineByItem) Export
	
	ReducingNumber = Count < 0;
	AvailableQuantity = ?(ReducingNumber, 
		- RemainderLine_.Used_ - RemainderLine_.UsedInExcessOfBalance,
		RemainderLine_.AvailableForInventoryAllocation - RemainderLine_.Used_);
			
	If ReducingNumber Then
		ForSetting = ?(AvailableQuantity >= Count, AvailableQuantity, Count);
	Else
		ForSetting = ?(AvailableQuantity >= Count, Count, AvailableQuantity);
	EndIf;
	
	If ForSetting <> 0 Then
		
		ChangingBalance = ForSetting;
		
		If ReducingNumber Then
			
			QuantityToWriteOff = -ForSetting;
			If QuantityToWriteOff >= RemainderLine_.UsedInExcessOfBalance Then
				ChangingBalance = QuantityToWriteOff - RemainderLine_.UsedInExcessOfBalance;
				RemainderLine_.UsedInExcessOfBalance = 0;
			Else
				ChangingBalance = 0;
				RemainderLine_.UsedInExcessOfBalance = RemainderLine_.UsedInExcessOfBalance - QuantityToWriteOff;
			EndIf;
			
			ChangingBalance = -ChangingBalance;
			
		EndIf;
		
		RemainderLine_.Used_ = RemainderLine_.Used_ + ChangingBalance;
		
		LineByItem.Count = LineByItem.Count + ForSetting;
		FillInDecryptionLineInTree(LineByItem, FillingData, Purpose, ForSetting);
		
	EndIf;
	
	Count = Count - ForSetting;

EndProcedure

Procedure ReflectChangeInBalanceTable(BalanceTable, DecryptionString) Export

	TheStructureOfTheSearch = New Structure;
	TheStructureOfTheSearch.Insert("Products", DecryptionString.Products);
	TheStructureOfTheSearch.Insert("Characteristic", DecryptionString.Characteristic);
	TheStructureOfTheSearch.Insert("Purpose", DecryptionString.Purpose);
	TheStructureOfTheSearch.Insert("Warehouse", DecryptionString.Warehouse);
	
	RemainderLines_ = BalanceTable.FindRows(TheStructureOfTheSearch);
	For Each SpecificationRow In RemainderLines_ Do
	
		SpecificationRow.Used_ = SpecificationRow.Used_ + DecryptionString.Count;
	
	EndDo;

EndProcedure

Procedure UpdateColumnAvailable(StructureOfFormData, Stages, BalanceTable = Undefined) Export
	
	Resolution = StructureOfFormData.Resolution;
	Standards = StructureOfFormData.Standards;
	SelectionOfInterchangeableAnalogues = StructureOfFormData.SelectionOfInterchangeableAnalogues;
	RemnantsOfAnalogues = StructureOfFormData.RemnantsOfAnalogues;
	
	AvailableAnalogues = New ValueTable;
	AvailableAnalogues.Columns.Add("Purpose", New TypeDescription("CatalogRef.Assignments"));
	AvailableAnalogues.Columns.Add("Warehouse", New TypeDescription("CatalogRef.Warehouses"));
	AvailableAnalogues.Columns.Add("NumberIsSeparate", Common.TypeDescriptionNumber(15,3));
	AvailableAnalogues.Columns.Add("Quantity_Total_1", Common.TypeDescriptionNumber(15,3));
	
	ColumnsNames = "Purpose, Warehouse";
	SearchTable = Stages.Copy(, ColumnsNames);
	SearchTable.GroupBy(ColumnsNames);
	WarehouseArray = Common.UnloadColumn(SearchTable, "Warehouse", True);
	
	If BalanceTable = Undefined Then
	
		Query = New Query;
		Query.Text = QueryTextForAvailabilityOfAnalogues();
		
		Query.SetParameter("Resolution", Resolution);
		Query.SetParameter("SearchTable", SearchTable);
			
		QueryResult = Query.Execute();
		
		BalanceTable = QueryResult.Unload();
		BalanceTable.Indexes.Add("Products, Characteristic, Purpose, Warehouse");
	
	EndIf;
	
	AvailableAnalogues.Indexes.Add(ColumnsNames);
	
	TableOfAnalogues = Standards.Copy(New Structure("ThisIsMaterial", False));
	
	StructureOfSearchForAvailableAnalogues = New Structure(ColumnsNames);
	StructureOfSearchForAvailableAnalogues.Purpose = Catalogs.Assignments.EmptyRef();
	
	For Each Warehouse In WarehouseArray Do
	
		StructureOfSearchForAvailableAnalogues.Warehouse = Warehouse;
		
		RowsArray = AvailableAnalogues.FindRows(StructureOfSearchForAvailableAnalogues);
		
		If RowsArray.Count() = 0 Then
		
			AvailabilityFactors = CoefficientOfAvailabilityOfAnalogues(
				StructureOfFormData, TableOfAnalogues, BalanceTable, StructureOfSearchForAvailableAnalogues);
			RowOfAvailabilityTable = AvailableAnalogues.Add();
			RowOfAvailabilityTable.NumberIsSeparate = AvailabilityFactors.CalculationCoefficientIsSeparate;
			RowOfAvailabilityTable.Quantity_Total_1 = AvailabilityFactors.AvailabilityCoefficientIsGeneral;
			RowOfAvailabilityTable.Warehouse = StructureOfSearchForAvailableAnalogues.Warehouse;
			RowOfAvailabilityTable.Purpose = StructureOfSearchForAvailableAnalogues.Purpose;
		
		EndIf;
	
	EndDo;
	
	For Each RowOfSearchTable In SearchTable Do
		
		FillPropertyValues(StructureOfSearchForAvailableAnalogues, RowOfSearchTable);
		
		AvailabilityFactors = CoefficientOfAvailabilityOfAnalogues(
			StructureOfFormData, TableOfAnalogues, BalanceTable, StructureOfSearchForAvailableAnalogues);
		
		RowOfAvailabilityTable = AvailableAnalogues.Add();
		RowOfAvailabilityTable.NumberIsSeparate = AvailabilityFactors.CalculationCoefficientIsSeparate;
		RowOfAvailabilityTable.Quantity_Total_1 = AvailabilityFactors.AvailabilityCoefficientIsGeneral;
		RowOfAvailabilityTable.Warehouse = RowOfSearchTable.Warehouse;
		RowOfAvailabilityTable.Purpose = RowOfSearchTable.Purpose;
	
	EndDo;
		
	EmptyAssignment = Catalogs.Assignments.EmptyRef();
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose, Warehouse");
		
	For Each TSRow In Stages Do
		
		TSRow.Available = 0;
		
		FillPropertyValues(StructureOfSearchForAvailableAnalogues, TSRow, ColumnsNames);
		If Not ValueIsFilled(TSRow.ConnectionKey) Then
			StructureOfSearchForAvailableAnalogues.Purpose = EmptyAssignment;
		EndIf;
	
		RowsArray = AvailableAnalogues.FindRows(StructureOfSearchForAvailableAnalogues);
		For Each StringOfAvailableAnalogues In RowsArray Do
			
			AvailableSets_ = ?(TSRow.DetachedSet, 
				StringOfAvailableAnalogues.NumberIsSeparate, StringOfAvailableAnalogues.Quantity_Total_1);
			AvailableSets_ = StringOfAvailableAnalogues.Quantity_Total_1;
			TSRow.Available = TSRow.Available + AvailableSets_;
		
		EndDo;
		
		If SelectionOfInterchangeableAnalogues Then
		
			FillPropertyValues(TheStructureOfTheSearch, TSRow);
			ArrayOfGoodsBalance = BalanceTable.FindRows(TheStructureOfTheSearch);
			
			For Each ItemBalanceLine In ArrayOfGoodsBalance Do
				
				SubtractedQuantity = ProductionClientServer.CoefficientByStandard(
					TSRow.ControlMultiplier,
					ItemBalanceLine.AvailableForInventoryAllocation - ItemBalanceLine.Used_,
					TSRow.NormativeStandard,
					TSRow.PackageData);
				
				TSRow.Available = TSRow.Available - SubtractedQuantity;
			
			EndDo;
			
			TheStructureOfTheSearch.Purpose = EmptyAssignment;
			ArrayOfGoodsBalance = BalanceTable.FindRows(TheStructureOfTheSearch);
			
			For Each ItemBalanceLine In ArrayOfGoodsBalance Do
					
				SubtractedQuantity = ProductionClientServer.CoefficientByStandard(
					TSRow.ControlMultiplier,
					ItemBalanceLine.AvailableForInventoryAllocation - ItemBalanceLine.Used_,
					TSRow.NormativeStandard,
					TSRow.PackageData);
				
				TSRow.Available = TSRow.Available - SubtractedQuantity;
			
			EndDo;
			
		EndIf;
		
		EstimatedQuantity = EstimatedNumberOfItems(TSRow.NormativeStandard, TSRow.Available, TSRow.PackageData);
		
		TSRow.Available = EstimatedQuantity;
	
	EndDo;
	
EndProcedure

Function QueryTextForAvailabilityOfAnalogues()

	Text =
	"SELECT
	|	SearchTable.Purpose AS Purpose,
	|	SearchTable.Warehouse AS Warehouse
	|INTO BalanceLookupTable
	|FROM
	|	&SearchTable AS SearchTable
	|
	|INDEX BY
	|	Purpose,
	|	Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AlternativeMaterials.Products AS Products,
	|	AlternativeMaterials.Characteristic AS Characteristic,
	|	AlternativeMaterials.Package AS Package,
	|	AlternativeMaterials.NumberOfPackages AS NumberOfPackages
	|INTO AnalogsByPermission
	|FROM
	|	InformationRegister.AlternativeMaterials AS AlternativeMaterials
	|WHERE
	|	AlternativeMaterials.Recorder = &Resolution
	|	AND AlternativeMaterials.ProductsRole IN (VALUE(Enum.SubstituteRoles.Substitute), VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|
	|INDEX BY
	|	Products,
	|	Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Purpose AS Purpose,
	|	Table.Warehouse AS Warehouse
	|INTO AnalystTable
	|FROM
	|	(SELECT
	|		AnalogsByPermission.Products AS Products,
	|		AnalogsByPermission.Characteristic AS Characteristic,
	|		BalanceLookupTable.Purpose AS Purpose,
	|		BalanceLookupTable.Warehouse AS Warehouse
	|	FROM
	|		BalanceLookupTable AS BalanceLookupTable
	|			INNER JOIN AnalogsByPermission AS AnalogsByPermission
	|			ON (TRUE)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		AnalogsByPermission.Products,
	|		AnalogsByPermission.Characteristic,
	|		VALUE(Catalog.Assignments.EmptyRef),
	|		BalanceLookupTable.Warehouse
	|	FROM
	|		BalanceLookupTable AS BalanceLookupTable
	|			INNER JOIN AnalogsByPermission AS AnalogsByPermission
	|			ON (TRUE)) AS Table
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Purpose,
	|	Characteristic
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
	|	AccumulationRegister.InventoryAndDemands.Balance(
	|			,
	|			(Products, Characteristic, Purpose, Warehouse) IN
	|				(SELECT
	|					AnalystTable.Products AS Products,
	|					AnalystTable.Characteristic AS Characteristic,
	|					AnalystTable.Purpose AS Purpose,
	|					AnalystTable.Warehouse AS Warehouse
	|				FROM
	|					AnalystTable AS AnalystTable)) AS Inventories
	|INDEX BY
	|	Products, Characteristic, Purpose, Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Calculation.Products AS Products,
	|	Calculation.Characteristic AS Characteristic,
	|	Calculation.Warehouse AS Warehouse,
	|	Calculation.Purpose AS Purpose,
	|	Calculation.QuantityForShipAction AS AvailableForInventoryAllocation
	|INTO RemnantsOfAnalogues
	|FROM
	|	CalculationOfBalancesForSettingActions AS Calculation
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AnalystTable.Products AS Products,
	|	AnalystTable.Characteristic AS Characteristic,
	|	AnalystTable.Purpose AS Purpose,
	|	AnalystTable.Warehouse AS Warehouse,
	|	ISNULL(RemnantsOfAnalogues.AvailableForInventoryAllocation, 0) AS AvailableForInventoryAllocation,
	|	0 AS Used_
	|FROM
	|	AnalystTable AS AnalystTable
	|		LEFT JOIN RemnantsOfAnalogues AS RemnantsOfAnalogues
	|		ON AnalystTable.Products = RemnantsOfAnalogues.Products
	|			AND AnalystTable.Characteristic = RemnantsOfAnalogues.Characteristic
	|			AND AnalystTable.Purpose = RemnantsOfAnalogues.Purpose
	|			AND AnalystTable.Warehouse = RemnantsOfAnalogues.Warehouse";
	TablesNames = ProvisionInDocumentsServer.NewTableNamesForCalculatingBalancesForSettingActions();
	TablesNames.Balance = "InventoryAndDemandsBalance"; // @query-part-1
	TablesNames.Result = "CalculationOfBalancesForSettingActions"; // @query-part-1
	ProvisionInDocumentsServer.CalculationOfBalancesForSettingActions(Text, TablesNames);
	
	Return Text;
	
EndFunction

Function CoefficientOfAvailabilityOfAnalogues(StructureOfFormData, TableOfAnalogues, BalanceTable, RowOfSearchTable) Export
	
	SelectionOfInterchangeableAnalogues = StructureOfFormData.SelectionOfInterchangeableAnalogues;
	AvailabilityCoefficientIsGeneral = -1;
	AvailabilityCoefficientIsSeparate = -1;
	AdditionallyTakeIntoAccountFreeBalance = ValueIsFilled(RowOfSearchTable.Purpose);
	TheStructureOfTheSearch = New Structure("Products, Characteristic, Purpose, Warehouse");
	
	For Each RowOfAnalogTable In TableOfAnalogues Do
		
		FillPropertyValues(TheStructureOfTheSearch, RowOfAnalogTable, "Products, Characteristic");
		FillPropertyValues(TheStructureOfTheSearch, RowOfSearchTable, "Warehouse, Purpose");
		
		ArrayOfGoodsBalance = BalanceTable.FindRows(TheStructureOfTheSearch);
		AddOnArray = New Array;
		
		If AdditionallyTakeIntoAccountFreeBalance Then
		
			TheStructureOfTheSearch.Purpose = Catalogs.Assignments.EmptyRef();
			AddOnArray = BalanceTable.FindRows(TheStructureOfTheSearch);
		
		EndIf;
		
		BalanceWithoutAssignment = 0;
		AvailableForInventoryAllocation = 0;
		Used_ = 0;
		
		For Each RowOfRemainderTable In ArrayOfGoodsBalance Do
			
			AvailableForInventoryAllocation = RowOfRemainderTable.AvailableForInventoryAllocation;
			Used_ = RowOfRemainderTable.Used_;
			
		EndDo;
		
		If AdditionallyTakeIntoAccountFreeBalance Then
		
			For Each ExtensionString In AddOnArray Do
				BalanceWithoutAssignment = BalanceWithoutAssignment + ExtensionString.AvailableForInventoryAllocation - ExtensionString.Used_;
			EndDo;
		
		EndIf;
		
		CalculationCoefficientIsGeneral = ProductionClientServer.CoefficientByStandard(
			RowOfAnalogTable.ControlMultiplier, 
			AvailableForInventoryAllocation - Used_ + BalanceWithoutAssignment,
			RowOfAnalogTable.NormativeStandard,
			RowOfAnalogTable.PackageData);
			
		CalculationCoefficientIsSeparate = ProductionClientServer.CoefficientByStandard(
			RowOfAnalogTable.ControlMultiplier, 
			AvailableForInventoryAllocation - Used_,
			RowOfAnalogTable.NormativeStandard,
			RowOfAnalogTable.PackageData);
								
		If AvailabilityCoefficientIsGeneral < 0 Then
			AvailabilityCoefficientIsGeneral = CalculationCoefficientIsGeneral;
		ElsIf SelectionOfInterchangeableAnalogues Then
			AvailabilityCoefficientIsGeneral = AvailabilityCoefficientIsGeneral + CalculationCoefficientIsGeneral;
		Else
			AvailabilityCoefficientIsGeneral = Min(AvailabilityCoefficientIsGeneral, CalculationCoefficientIsGeneral);
		EndIf;
		
		If AvailabilityCoefficientIsSeparate < 0 Then
			AvailabilityCoefficientIsSeparate = CalculationCoefficientIsSeparate;
		ElsIf SelectionOfInterchangeableAnalogues Then
			AvailabilityCoefficientIsSeparate = AvailabilityCoefficientIsSeparate + CalculationCoefficientIsSeparate;
		Else
			AvailabilityCoefficientIsSeparate = Min(AvailabilityCoefficientIsSeparate, CalculationCoefficientIsSeparate);
		EndIf;
	
	EndDo;
	
	AvailabilityCoefficientIsGeneral = ?(AvailabilityCoefficientIsGeneral < 0, 0, AvailabilityCoefficientIsGeneral);
	AvailabilityCoefficientIsSeparate = ?(AvailabilityCoefficientIsSeparate < 0, 0, AvailabilityCoefficientIsSeparate);
	
	Return New Structure("AvailabilityCoefficientIsGeneral, CalculationCoefficientIsSeparate", AvailabilityCoefficientIsGeneral, AvailabilityCoefficientIsSeparate);

EndFunction

Function EstimatedNumberOfItems(NormativeStandard, ConversionFactor_, PackageData) Export

	EstimatedQuantity = NormativeStandard * ConversionFactor_
		* PackageData.Numerator / PackageData.Denominator;
			
	CurrentCount = Int(EstimatedQuantity);
	If EstimatedQuantity > CurrentCount Then
		CurrentCount = CurrentCount + Int((EstimatedQuantity - CurrentCount) * 1000) / 1000;
	EndIf;
	
	Return EstimatedQuantity;

EndFunction

#EndRegion

Function RequestTextForDynamicListOfPermissionsToReplaceMaterials() Export
	
	QueryText =
	"SELECT
	|	MainTable.Ref AS Ref,
	|	MainTable.DataVersion AS DataVersion,
	|	MainTable.DeletionMark AS DeletionMark,
	|	MainTable.Number AS Number,
	|	MainTable.Date AS Date,
	|	MainTable.Posted AS Posted,
	|	MainTable.ValidityStartDate AS ValidityStartDate,
	|	MainTable.ValidityEndDate AS ValidityEndDate,
	|	MainTable.Status AS Status,
	|	MainTable.UsageNote AS UsageNote,
	|	MainTable.EmployeeResponsible AS EmployeeResponsible
	|FROM
	|	Document.EngineeringChangeOrder AS MainTable";
	
	Return QueryText;
	
EndFunction

// Sets the selection by item in the dynamic list.
//
// Parameters:
//  List       - DynamicList - a dynamic list that is being created.
//  Products - CatalogRef.Products - the range of selection.
//  Purpose   - EnumRef.UseOfItemsInProductionMasterData - purpose of selection.
//
Procedure SetSelectionByProductInDynamicListOfMaterialReplacementPermits(List, Products, Purpose = Undefined) Export
	
	FilterRemainingGoodsByShelfLives = CommonClientServer.CreateFilterItemGroup(
		List.SettingsComposer.FixedSettings.Filter.Items,
		NStr("vi = 'Lọc theo mặt hàng';
			|ru = 'Отбор по номенклатуре';
			|en = 'Filter by items'; fa = 'فیلتر بر اساس اقلام';
			|it = 'La selezione in base all''elenco articoli';
			|pl = 'Filtr wg towaru';
			|tr = 'Ürüne göre filtre'"),
		DataCompositionFilterItemsGroupType.OrGroup);
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.AreasOfAction.Product",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products) And (Not ValueIsFilled(Purpose) Or Purpose = Enums.UseOfItemsInProductionMasterData.Product));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.UsedMaterials.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products) And (Not ValueIsFilled(Purpose) Or Purpose = Enums.UseOfItemsInProductionMasterData.Material));
	
	CommonClientServer.AddCompositionItem(
		FilterRemainingGoodsByShelfLives,
		"Ref.Substitutes.Products",
		DataCompositionComparisonType.Equal,
		Products,
		,
		ValueIsFilled(Products) And (Not ValueIsFilled(Purpose) Or Purpose = Enums.UseOfItemsInProductionMasterData.Substitute));
	
EndProcedure

#EndRegion

#Region InfobaseUpdate

Function AdaptedCaseSensitiveQueryText(RegisterName) Export

	Query = New Query;
	QueryTexts = New ValueList;
	
	FullDocumentName = "Document.EngineeringChangeOrder";
	SynonymForDocumentTable = "PermissionToReplaceMaterialsMaterials";
	
	If RegisterName = "AlternativeMaterials" Then
		
		QueryText = QueryTextTableAlternativeMaterials(Query, QueryTexts, RegisterName);
		
	Else
		
		ExceptionText = NStr("vi = 'Trong chứng từ %FullDocumentName% không thực hiện yêu cầu tạo bản ghi kết chuyển theo biểu ghi %RegisterName%.';
							|ru = 'В документе %FullDocumentName% не реализована адаптация текста запроса формирования движений по регистру %RegisterName%.';
							|en = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.'; fa = 'In document %FullDocumentName%, adaptation of request for generating records of register %RegisterName% is not implemented.';
							|it = 'Nel documento %FullDocumentName% non è stato effettuato l''adattamento di testo della richiesta di generazione di movimenti sul registro%RegisterName%.';
							|pl = 'W dokumencie %FullDocumentName% nie jest realizowana adaptacja tekstu zapytania tworzenia przepływów w rejestrze %RegisterName%.';
							|tr = '%FullDocumentName% belgesinde, %RegisterName% kaydına göre hareketlerin düzenlenmesi talebinin metin uyarlaması uygulanmadı.'");
		ExceptionText = StrReplace(ExceptionText, "%FullDocumentName%", FullDocumentName);
		ExceptionText = StrReplace(ExceptionText, "%RegisterName%", RegisterName);
		
		Raise ExceptionText;
		
	EndIf;
	
	Result = InfobaseUpdateTM.ResultOfRequestAdaptation();
	Result.QueryText = InfobaseUpdateTM.AdaptRequestOfHoldingMechanism(
									QueryText, FullDocumentName, SynonymForDocumentTable);
	
	Return Result;
	
EndFunction

// Adds to the list of procedures-handlers for updating information security
// data for all supported versions of the library or configuration.
// Called before starting to update information security data to build an update plan.
//
// Parameters:
// 	Handlers - See InfobaseUpdate.NewUpdateHandlerTable
//
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Documents.EngineeringChangeOrder.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.26.84";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("e1eedbda-9b2c-47ba-895e-d0006a2fc450");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "Documents.EngineeringChangeOrder.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Normal;
	Handler.Comment = NStr("vi = 'Điền mục tin ""Mức độ ưu tiên thay thế"" bằng giá trị mặc định.';
							|ru = 'Заполнение реквизита ""Приоритет замены"" значением по умолчанию.';
							|en = 'Fill in the ""Replacement priority"" attribute with the default value.'; fa = 'Fill in the ""Replacement priority"" attribute with the default value.';
							|it = 'Fill in the ""Replacement priority"" attribute with the default value.';
							|pl = 'Fill in the ""Replacement priority"" attribute with the default value.';
							|tr = '""Değiştirme önceliği"" özniteliğinin varsayılan değerle doldurulması.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.EngineeringChangeOrder.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Documents.EngineeringChangeOrder.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullNamesOfObjects = "Document.EngineeringChangeOrder";
	SelectionParameters.OrderingFieldsOnUserOperations.Add("DATE DESC");
	SelectionParameters.OrderingFieldsOnProcessData.Add("DATE DESC");
	SelectionParameters.SelectionMethod = InfobaseUpdate.RefsSelectionMethod();
	
	QueryText = 
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Ref.ReplacementOption AS ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrders,
	|	SUM(DocumentData.QuantityOfMaterials) AS QuantityOfMaterials,
	|	SUM(DocumentData.NumberOfAnalogues) AS NumberOfAnalogues
	|INTO ReplacementPermissionData
	|FROM
	|	(SELECT
	|		PermissionToReplaceMaterialsMaterials.Ref AS Ref,
	|		SUM(1) AS QuantityOfMaterials,
	|		0 AS NumberOfAnalogues
	|	FROM
	|		Document.EngineeringChangeOrder.UsedMaterials AS PermissionToReplaceMaterialsMaterials
	|	
	|	GROUP BY
	|		PermissionToReplaceMaterialsMaterials.Ref
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		EngineeringChangeOrderSubstitutes.Ref,
	|		0,
	|		SUM(1)
	|	FROM
	|		Document.EngineeringChangeOrder.Substitutes AS EngineeringChangeOrderSubstitutes
	|	
	|	GROUP BY
	|		EngineeringChangeOrderSubstitutes.Ref) AS DocumentData
	|
	|GROUP BY
	|	DocumentData.Ref,
	|	DocumentData.Ref.ReplacementOption,
	|	DocumentData.Ref.UseItForAutocorrectInOrders
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ReplacementPermissionData.Ref AS Ref,
	|	ReplacementPermissionData.UseItForAutocorrectInOrders AS UseItForAutocorrectInOrdersInDocument,
	|	CASE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SubstituteList)
	|			THEN TRUE
	|		WHEN ReplacementPermissionData.ReplacementOption = VALUE(Enum.SubstituteReplacementOption.SetToSet)
	|			THEN ReplacementPermissionData.QuantityOfMaterials = 1
	|					AND ReplacementPermissionData.NumberOfAnalogues = 1
	|		ELSE FALSE
	|	END AS UseItForAutocorrectInInstallationOrders
	|INTO TableApplicationInOrders
	|FROM
	|	ReplacementPermissionData AS ReplacementPermissionData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	DocumentsForProcessing_.Ref AS Ref
	|FROM
	|	(SELECT
	|		PermissionToReplace.Ref AS Ref
	|	FROM
	|		Document.EngineeringChangeOrder AS PermissionToReplace
	|	WHERE
	|		PermissionToReplace.ReplacementPriority = VALUE(Enum.RulesOfReplacingWithSubstitutes.EmptyRef)
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Ref
	|	FROM
	|		TableApplicationInOrders AS Table
	|	WHERE
	|		Table.UseItForAutocorrectInOrdersInDocument <> Table.UseItForAutocorrectInInstallationOrders) AS DocumentsForProcessing_";
		
	Query = New Query(QueryText);
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

// An update handler.
// 
// Parameters:
//  Parameters - Structure - Handler Parameters:
//   * SubsystemVersionAtStartUpdates - String - the version of the subsystem.
//   * HandlerName - String - name of the handler.
//   * UpdatedData - Structure
//   * ProcessingCompleted - Boolean, Undefined - indicates End of processing.
//   * Queue - Number - the queue.
//   * ExecutionProgress - Structure:
//     ** TotalObjectCount - Number - total objects processed.
//     ** ProcessedObjectsCount1 - Number - processed objects.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Document.EngineeringChangeOrder";
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(
			Parameters.Queue, FullObjectName);
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	UpdatedData.Ref AS Ref,
	|	UpdatedData.Date AS Date
	|INTO TT_UpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TT_UpdatedData.Ref AS Ref,
	|	TT_UpdatedData.Ref.DataVersion AS DataVersion
	|FROM
	|	TT_UpdatedData AS TT_UpdatedData
	|
	|ORDER BY
	|	TT_UpdatedData.Date DESC";
	
	Query.SetParameter("UpdatedData", UpdatedData);
	
	QueryResult = Query.Execute();
	
	Selection = QueryResult.Select();
	EmptyReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.EmptyRef();
	DefaultReplacementPriority = Enums.RulesOfReplacingWithSubstitutes.IfThereAreNoMaterials;
	VariantSet = Enums.SubstituteReplacementOption.SetToSet;
	OptionList = Enums.SubstituteReplacementOption.SubstituteList;
		
	While Selection.Next() Do
		
		BeginTransaction();
		
		Try
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			DocumentObject = InfobaseUpdateTM.CheckGetObject(Selection.Ref, Selection.DataVersion, Parameters.Queue);
			
			If DocumentObject <> Undefined Then
				
				If DocumentObject.ReplacementPriority = EmptyReplacementPriority Then
					DocumentObject.ReplacementPriority = DefaultReplacementPriority;
				EndIf;
				
				If Not IsBlankString(DocumentObject.DeleteComment) Then
					
					CommentTemplate = NStr("vi = 'Ghi chú: %1';
											|ru = 'Комментарий: %1';
											|en = 'Comment: %1'; fa = 'Comment: %1';
											|it = 'Comment: %1';
											|pl = 'Comment: %1';
											|tr = 'Yorum: %1'");
					CommentText1 = StringFunctionsClientServer.SubstituteParametersToString(CommentTemplate, DocumentObject.DeleteComment);
					
					DocumentObject.UsageNote = DocumentObject.UsageNote + Chars.LF + CommentText1;
					DocumentObject.DeleteComment = "";
				
				EndIf;
				
				QuantityOfMaterials = DocumentObject.UsedMaterials.Count();
				NumberOfAnalogues = DocumentObject.Substitutes.Count();
				
				If DocumentObject.ReplacementOption = VariantSet
				   And DocumentObject.UseItForAutocorrectInOrders
				   And (QuantityOfMaterials > 1
				   Or NumberOfAnalogues > 1) Then
				
					DocumentObject.UseItForAutocorrectInOrders = False;
				
				EndIf;
				
				If DocumentObject.ReplacementOption = OptionList
				 Or (DocumentObject.ReplacementOption = VariantSet And QuantityOfMaterials = 1 And NumberOfAnalogues = 1) Then
				
					DocumentObject.UseItForAutocorrectInOrders = True;
				
				EndIf;
				
				If DocumentObject.Modified() Then
					InfobaseUpdate.WriteData(DocumentObject);
				Else
					InfobaseUpdate.MarkProcessingCompletion(DocumentObject);
				EndIf;
				
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
		EndTry;
		
	EndDo;

	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
