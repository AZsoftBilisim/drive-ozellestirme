//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region Posting

// Describes the accounting mechanisms used in the document for registration in the transaction mechanism.
//
// Parameters:
//  DocumentMechanisms - Array of String - list of names of accounting mechanisms that will be
//              registered in the tracking mechanism.
//
Procedure RegisterAccountingMechanisms(DocumentMechanisms) Export
	
	DocumentMechanisms.Add("GoodsDelivery");
	
EndProcedure

// Returns tables for movements that are necessary for conducting a document through registers of accounting mechanisms.
//
// Parameters:
//  Document - DocumentObject.Trip, DocumentRef.Trip - link to the document or object for which you want to get data
//  Registers - Structure - a list of register names for which you want to table
//  AddlParameters - Structure - additional parameters for getting data that define the context of the event.
//
// Returns:
//  ValueList of String, Structure - a collection of elements - tables of values - data to be reflected in the register.
//
Function DocumentDataForPosting(Document, Registers, AddlParameters = Undefined) Export
	
	If AddlParameters = Undefined Then
		AddlParameters = DocumentsPosting.AdditionalParametersDocumentDataForPosting();
	EndIf;
	
	If TypeOf(Document) = Type("DocumentObject.Trip") Then
		
		DocumentObject = Document;
		DocumentRef = Document.Ref;
		
	Else
		
		DocumentObject = Document.GetObject();
		DocumentRef = Document;
		
	EndIf;
	
	Query = New Query;
	QueryTexts = New ValueList; // ValueList of String
	
	GetDocumentData(Query, DocumentRef);
	
	If Not AddlParameters.GetQueryTexts Then
		
		FillInInitializationParameters(Query, DocumentRef);
		
		QueryTextGoodsDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters);
		
	EndIf;
	
	Return DocumentsPosting.InitializeDocumentDataForPosting(Query, QueryTexts, AddlParameters);
	
EndFunction

#EndRegion

#Region GenerateFrom

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	BusinessProcesses.Job.AddGenerateCommand(GenerationCommands);
	
	NewCommand = Documents.GoodsIssueNote.AddCommandToCreateSpendingOrderForGoodsBasedOnIt(GenerationCommands);
	If NewCommand <> Undefined Then
		
		AttachableCommands.AddCommandVisibilityCondition(
			NewCommand,
			"Status",
			Enums.TripStatuses.ForAssembly);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region InterfaceImplementation

// Prepares the print data.
// 
// Parameters:
//  DataSources - See PrintManagementOverridable.WhenPreparingPrintData.DataSources
//  ExternalDataSets - See PrintManagementOverridable.WhenPreparingPrintData.ExternalDataSets
//  LanguageCode - See PrintManagementOverridable.WhenPreparingPrintData.LanguageCode
//  AdditionalParameters - See PrintManagementOverridable.WhenPreparingPrintData.AdditionalParameters
//
Procedure WhenPreparingPrintData(DataSources, ExternalDataSets, LanguageCode, AdditionalParameters) Export
	
	PrintData = PrintDataOperationSheet(DataSources);
	RouteData = PrintData.RouteData;
	DataOnOrders = PrintData.DataOnOrders;
	DataOnPlanningDocuments = PrintData.DataOnPlanningDocuments;
	TripData = TripDataSet(RouteData, DataOnOrders, DataOnPlanningDocuments);
	ExternalDataSets.Insert("SetRoutes", TripData.SetOfRoutes);
	ExternalDataSets.Insert("SetOfTotals", TripData.TableOfResults);
	
EndProcedure

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// Fills in the list of print commands.
// 
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	PrintCommand = PrintCommands.Add();
	PrintCommand.PrintManager = "PrintManagement";
	PrintCommand.CheckPostingBeforePrint = True;
	PrintCommand.Id = "Document.Trip.PF_MXL_OperationSheet";
	PrintCommand.Presentation = NStr("vi = 'Sơ đồ lộ trình chuyến đi';
									|ru = 'Маршрутный лист рейса';
									|en = 'Trip route sheet'; fa = 'برگه مسیر سفر';
									|it = 'Trip route sheet';
									|pl = 'Trip route sheet';
									|tr = 'Sefer rota fişi'");
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.PickingUnderTrip.AddReportCommand(ReportsCommands, Parameters, "KitAssemblyAccordingToDataOfTrip");
	Reports.PickingUnderTrip.AddReportCommand(ReportsCommands, Parameters, "KitIsAssembledRegardlessOfTrip");
	
	Reports.InvoicesByTripReferences.AddReportCommand(
		ReportsCommands,
		Parameters,
		"InvoicesByTripReferences");
	
	Reports.TripRoute.AddReportCommand(ReportsCommands, Parameters, "TripRoute");
	
EndProcedure

// Description of the logic of access rights restrictions
//
// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowRead
	|WHERE
	|	ValueAllowed(Organization)
	|	AND ValueAllowed(DepartureWarehouse)
	|;
	|AllowUpdateIfReadingAllowed
	|WHERE
	|	ForAllRows(ObjectReadingAllowed(Route.Point, EmptyRef AS TRUE, Null AS TRUE))
	|	AND ForAllRows(ObjectReadingAllowed(Content.ReferenceOrder, EmptyRef AS TRUE, Null AS TRUE))
	|	AND ValueAllowed(Carrier, EmptyRef AS TRUE)";
	
EndProcedure

#EndRegion

#EndRegion

#Region Internal

// Returns a string representation of the flight status.
// 
// Parameters:
//  Object - DocumentObject.Trip -
//  	   - FormDataStructure: See Document.Trip.Form.DocumentForm.Object
// 
// Returns:
//  String 
// 
Function TripState(Object) Export
	
	CurrentStateOfFlight = "";
	Status = Object.Status;
	FlightStates = FlightStatusByStatus();
	If Status = Enums.TripStatuses.ForAssembly Then
		
		CurrentStateOfFlight = StateOfTripIsInStatusForKitting(Object.Ref);
		
	ElsIf FlightStates[Status] <> Undefined Then 
		
		CurrentStateOfFlight = FlightStates[Status];
		
	EndIf;
	
	Return CurrentStateOfFlight;
	
EndFunction

// Parameters:
//  ModifiedRows - Array of FormDataCollectionItem:
//  * PlanningDocument - DefinedType.DeliveryPlanningDocument
//  * RowCode - Number
//
Procedure FillInAdditionalContentParameters(ModifiedRows) Export
	
	PlanningDocuments = New Array; // Array of DefinedType.DeliveryPlanningDocument
	For Each String In ModifiedRows Do
		PlanningDocuments.Add(String.PlanningDocument);
	EndDo;
	
	AllAdditionalParameters = GoodsDelivery.AllAdditionalParametersFromDocumentStrings(PlanningDocuments);
	Filter = New Structure;
	Filter.Insert("DocumentDeliveries", Undefined);
	Filter.Insert("RowCode", 0);
	ParametersToFillIn = "DeliveryTimeFrom,DeliveryTimeTo,AdditionalDeliveryInformation,SpecialTransportationConditions,SpecialTransportationConditionsDescription";
	
	For Each String In ModifiedRows Do
		
		Filter.DocumentDeliveries = String.PlanningDocument;
		Filter.RowCode = String.RowCode;
		ParameterStrings = AllAdditionalParameters.FindRows(Filter);
		
		If ParameterStrings.Count() = 0 Then
			
			Filter.RowCode = 0;
			ParameterStrings = AllAdditionalParameters.FindRows(Filter);
			
		EndIf;
		
		If ParameterStrings.Count() > 0 Then
			
			FillPropertyValues(String, ParameterStrings[0], ParametersToFillIn);
			
		EndIf;
		
	EndDo;
	
EndProcedure

#EndRegion

#Region Private

#Region Posting

#Region DocumentData

Procedure GetDocumentData(Query, DocumentRef)
	
	ListOfRequests = New Array; // Array of String
	
	QueryTextDocumentDataHeader(ListOfRequests);
	QueryTextDataTableGoods(ListOfRequests);
	
	QueryText = StrConcat(ListOfRequests, Common.QueryBatchSeparator());
	
	Query.Text = QueryText;
	Query.TempTablesManager = New TempTablesManager();
	Query.SetParameter("Ref", DocumentRef);
	Query.Execute();
	
EndProcedure

Procedure QueryTextDocumentDataHeader(ListOfRequests)
	
	QueryText =
	"SELECT
	|	DocumentData.Ref AS Ref,
	|	DocumentData.Date AS Date,
	|	DocumentData.Number AS Number,
	|	DocumentData.DeletionMark AS DeletionMark,
	|	DocumentData.Posted AS Posted,
	|	DocumentData.Status AS Status,
	|	DocumentData.DateOfDeparture AS DateOfDeparture,
	|	DocumentData.Organization AS Organization,
	|	DocumentData.DeliveryMethod AS DeliveryMethod,
	|	DocumentData.DepartureWarehouse AS DepartureWarehouse,
	|	DocumentData.DepartureWarehouse.UseWarehouseManagemantSystemForGoodsIssue
	|		AND DocumentData.DepartureWarehouse.StartShipmentOnceDeliveryOrderIsCreated
	|		AND (DocumentData.DepartureWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue = DATETIME(1, 1, 1)
	|			OR DocumentData.DepartureWarehouse.StartDateOfWarehouseManagemantSystemForGoodsIssue <= DocumentData.DateOfDeparture) AS TripKitsByOrders,
	|	DocumentData.DeparturePoint_ AS DeparturePoint_,
	|	DocumentData.DepartureArea AS DepartureArea,
	|	DocumentData.Carrier AS Carrier,
	|	DocumentData.EmployeeResponsible AS EmployeeResponsible,
	|	DocumentData.Comment AS Comment
	|INTO DocumentDataHeader
	|FROM
	|	Document.Trip AS DocumentData
	|WHERE
	|	DocumentData.Ref = &Ref";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

Procedure QueryTextDataTableGoods(ListOfRequests)
	
	QueryText =
	"SELECT
	|	TableContents.Ref AS Ref,
	|	TableContents.LineNumber AS LineNumber,
	|	CASE
	|		WHEN VALUETYPE(TableRoute.Point) = TYPE(Catalog.Warehouses)
	|				AND TableRoute.Operation = VALUE(Enum.TripOperations.Loading)
	|			THEN VALUE(Enum.DeliveryTypes.OutgoingInfo)
	|		WHEN VALUETYPE(TableRoute.Point) = TYPE(Catalog.Warehouses)
	|				AND TableRoute.Operation = VALUE(Enum.TripOperations.Unloading)
	|			THEN VALUE(Enum.DeliveryTypes.IncomingDataMessage)
	|		WHEN VALUETYPE(TableRoute.Point) = TYPE(Catalog.Partners)
	|				AND TableRoute.Operation = VALUE(Enum.TripOperations.Loading)
	|			THEN VALUE(Enum.DeliveryTypes.IncomingDataMessage)
	|		WHEN VALUETYPE(TableRoute.Point) = TYPE(Catalog.Partners)
	|				AND TableRoute.Operation = VALUE(Enum.TripOperations.Unloading)
	|			THEN VALUE(Enum.DeliveryTypes.OutgoingInfo)
	|	END AS DeliveryType,
	|	TableRoute.Point AS Point,
	|	TableRoute.DeliveryPoint AS PointOfPoint,
	|	TableRoute.DeliveryZone AS PointArea,
	|	ISNULL(DeliveryFinalLeverage.Recipient, UNDEFINED) AS FinalDestination,
	|	TableContents.FinalDeliveryPoint AS FinalDeliveryPoint,
	|	TableContents.FinalDeliveryArea AS FinalDeliveryArea,
	|	TableContents.Products AS Products,
	|	TableContents.Characteristic AS Characteristic,
	|	TableContents.Series AS Series,
	|	TableContents.Count AS Count,
	|	TableContents.NumberOfPackages AS NumberOfPackages,
	|	TableContents.Package AS Package,
	|	TableContents.Net_Weight AS Net_Weight,
	|	TableContents.Weight AS Weight,
	|	TableContents.VolumeM3 AS VolumeM3,
	|	TableContents.ReferenceOrder AS ReferenceOrder,
	|	TableContents.PlanningDocument AS PlanningDocument,
	|	TableContents.RowCode AS RowCode,
	|	TableContents.Canceled AS Canceled
	|INTO DocumentDataTableItems
	|FROM
	|	Document.Trip.Content AS TableContents
	|		LEFT JOIN Document.Trip.Route AS TableRoute
	|		ON TableContents.Ref = TableRoute.Ref
	|			AND TableContents.ConnectionKey = TableRoute.ConnectionKey
	|		LEFT JOIN AccumulationRegister.Delivery AS DeliveryFinalLeverage
	|		ON TableContents.ReferenceOrder = DeliveryFinalLeverage.ReferenceOrder
	|			AND TableContents.PlanningDocument = DeliveryFinalLeverage.PlanningDocument
	|			AND TableContents.RowCode = DeliveryFinalLeverage.RowCode
	|			AND (DeliveryFinalLeverage.ThisIsFinalArm)
	|			AND (DeliveryFinalLeverage.OperationLevel IN (15, 20))
	|WHERE
	|	TableContents.Ref = &Ref
	|	AND NOT 1 IN
	|		(SELECT TOP 1
	|				1
	|			FROM
	|				InformationRegister.DocumentCorrections AS DocumentCorrections
	|			WHERE
	|				DocumentCorrections.CorrectedDocument = DeliveryFinalLeverage.Recorder
	|				OR DocumentCorrections.PreviousCorrection = DeliveryFinalLeverage.Recorder)";
	
	ListOfRequests.Add(QueryText);
	
EndProcedure

#EndRegion

Procedure FillInInitializationParameters(Query, DocumentRef)
	
	StatusesForKitsInStock = New Array; // Array of EnumRef.TripStatuses
	StatusesForKitsInStock.Add(Enums.TripStatuses.Generated1);
	StatusesForKitsInStock.Add(Enums.TripStatuses.ForAssembly);
	StatusesForKitsInStock.Add(Enums.TripStatuses.Shipped_5);
	StatusesForKitsInStock.Add(Enums.TripStatuses.Completed);
	Query.SetParameter("StatusesForKitsInStock", StatusesForKitsInStock);
	
	Attributes = DocumentAttributes(Query);
	
	Query.SetParameter("Period", Attributes.Date);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("DateOfDeparture", Attributes.DateOfDeparture);
	Query.SetParameter("ToFormRegisterRecordsOfKits", Attributes.ToFormRegisterRecordsOfKits);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("Status", Attributes.Status);
	Query.SetParameter("Status", Attributes.Status);
	
	OperationLevel = GoodsDelivery.LevelOfOperationOfDocument(DocumentRef);
	Query.SetParameter("OperationLevel", OperationLevel);
	
EndProcedure

// Parameters:
//  Query - Query - Query
// 
// Returns:
//  QueryResultSelection - The details of the document:
//  * Date - Date
//  * Status - EnumRef.TripStatuses
//  * DateOfDeparture - Date
//  * ToFormRegisterRecordsOfKits - Boolean
//
Function DocumentAttributes(Query)
	
	Query.Text =
	"SELECT
	|	DocumentDataHeader.Date AS Date,
	|	DocumentDataHeader.Status AS Status,
	|	DocumentDataHeader.DateOfDeparture AS DateOfDeparture,
	|	DocumentDataHeader.TripKitsByOrders
	|		AND DocumentDataHeader.Status IN (&StatusesForKitsInStock) AS ToFormRegisterRecordsOfKits
	|FROM
	|	DocumentDataHeader AS DocumentDataHeader";
	
	QueryResult = Query.Execute();
	Attributes = QueryResult.Select();
	Attributes.Next();
	
	Return Attributes;
	
EndFunction

Function QueryTextGoodsDelivery(Query, QueryTexts, Registers, DocumentObject, AddlParameters = Undefined)
	
	RegisterName = "Delivery";
	
	If Not DocumentsPosting.RequiresTableForRegisteredRecords(RegisterName, Registers) Then
		Return "";
	EndIf;
	
	QueryText =
	"SELECT
	|	GoodsTable.LineNumber AS LineNumber,
	|	BEGINOFPERIOD(&Period, DAY) AS Period,
	|	DocumentHeader.Organization AS Organization,
	|	GoodsTable.DeliveryType AS DeliveryType,
	|	DocumentHeader.DateOfDeparture AS DateOfShipment,
	|	DocumentHeader.DeliveryMethod AS DeliveryMethod,
	|	DocumentHeader.DepartureWarehouse AS Sender,
	|	DocumentHeader.DeparturePoint_ AS SenderPoint,
	|	DocumentHeader.DepartureArea AS Sender_Area,
	|	GoodsTable.Point AS Recipient,
	|	GoodsTable.PointOfPoint AS RecipientPoint,
	|	GoodsTable.PointArea AS Recipient_Area,
	|	GoodsTable.PlanningDocument AS PlanningDocument,
	|	GoodsTable.ReferenceOrder AS ReferenceOrder,
	|	&Ref AS Trip,
	|	GoodsTable.Products AS Products,
	|	GoodsTable.Characteristic AS Characteristic,
	|	GoodsTable.Series AS Series,
	|	GoodsTable.RowCode AS RowCode,
	|	1 AS Arm,
	|	GoodsTable.Package AS Package,
	|	DocumentHeader.Carrier AS Carrier,
	|	0 AS ToDeliver,
	|	0 AS ToTrip,
	|	GoodsTable.Count AS InTrip,
	|	CASE
	|		WHEN DocumentHeader.Status = VALUE(Enum.TripStatuses.Shipped_5)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS InTransit,
	|	CASE
	|		WHEN DocumentHeader.Status = VALUE(Enum.TripStatuses.Completed)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS Delivered,
	|	0 AS Canceled,
	|	CASE
	|		WHEN &ToFormRegisterRecordsOfKits
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END AS ForAssembly,
	|	0 AS AssemblyInProgress,
	|	0 AS Assembled,
	|	&OperationLevel AS OperationLevel,
	|	GoodsTable.Point = GoodsTable.FinalDestination AS ThisIsFinalArm,
	|	1 AS MinimumArmNumber,
	|	FALSE AS PrimaryRegisterRecord,
	|	DATETIME(1, 1, 1) AS SourceShipmentDate,
	|	VALUE(Catalog.Assignments.EmptyRef) AS Purpose
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		INNER JOIN Document.Trip AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|WHERE
	|	NOT GoodsTable.Canceled
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsTable.LineNumber,
	|	BEGINOFPERIOD(&Period, DAY),
	|	DocumentHeader.Organization,
	|	GoodsTable.DeliveryType,
	|	DocumentHeader.DateOfDeparture,
	|	VALUE(Enum.TransportMethods25.ByCarrier),
	|	GoodsTable.Point,
	|	GoodsTable.PointOfPoint,
	|	GoodsTable.PointArea,
	|	GoodsTable.FinalDestination,
	|	GoodsTable.FinalDeliveryPoint,
	|	GoodsTable.FinalDeliveryArea,
	|	GoodsTable.PlanningDocument,
	|	GoodsTable.ReferenceOrder,
	|	&Ref,
	|	GoodsTable.Products,
	|	GoodsTable.Characteristic,
	|	GoodsTable.Series,
	|	GoodsTable.RowCode,
	|	2,
	|	GoodsTable.Package,
	|	GoodsTable.Point,
	|	0,
	|	0,
	|	GoodsTable.Count,
	|	CASE
	|		WHEN DocumentHeader.Status = VALUE(Enum.TripStatuses.Shipped_5)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END,
	|	CASE
	|		WHEN DocumentHeader.Status = VALUE(Enum.TripStatuses.Completed)
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END,
	|	0,
	|	CASE
	|		WHEN &ToFormRegisterRecordsOfKits
	|			THEN GoodsTable.Count
	|		ELSE 0
	|	END,
	|	0,
	|	0,
	|	&OperationLevel,
	|	TRUE,
	|	0,
	|	FALSE,
	|	DATETIME(1, 1, 1),
	|	VALUE(Catalog.Assignments.EmptyRef)
	|FROM
	|	DocumentDataTableItems AS GoodsTable
	|		INNER JOIN DocumentDataHeader AS DocumentHeader
	|		ON GoodsTable.Ref = DocumentHeader.Ref
	|WHERE
	|	DocumentHeader.DeliveryMethod = VALUE(Enum.TransportMethods25.OwnDelivery)
	|	AND GoodsTable.Point <> GoodsTable.FinalDestination
	|	AND NOT GoodsTable.Canceled";
	
	SynonymForDocumentTable = "GoodsTable";
	GoodsDelivery.SetParametersOfEventRequest(Query, AddlParameters);
	GoodsDelivery.AddDocumentReflectionRequest(Query, Registers, QueryTexts, QueryText, SynonymForDocumentTable);
	
	Return QueryText;
	
EndFunction

#EndRegion

#Region PrintData

// Parameters:
//  ObjectsArray  See PrintManagementOverridable.OnPrint.ObjectsArray
// 
// Returns:
//  Structure:
// * RouteData - QueryResultSelection:
//  ** Ref - DocumentRef.Trip
//  ** LineNumber - Number
//  ** DeliveryTimeFrom - Date
//  ** DeliveryTimeTo - Date
//  ** ConnectionKey - String
//  ** LoadingPoint - Boolean
// * DataOnOrders - ValueTable:
//  ** Ref - DocumentRef.Trip
//  ** ConnectionKey - String
//  ** ReferenceOrder - String
//  ** Weight - Number
//  ** VolumeM3 - Number
// * DataOnPlanningDocuments - ValueTable:
//  ** Ref - DocumentRef.Trip
//  ** ConnectionKey - String
//  ** AdditionalDeliveryInformation - String
//  ** SpecialTransportationConditionsDescription - String
// 
Function PrintDataOperationSheet(ObjectsArray)
	
	QueryText =
	"SELECT
	|	TripRoute.Ref AS Ref,
	|	TripRoute.LineNumber AS LineNumber,
	|	TripRoute.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	TripRoute.DeliveryTimeTo AS DeliveryTimeTo,
	|	TripRoute.ConnectionKey AS ConnectionKey,
	|	CASE
	|		WHEN TripRoute.LineNumber = 1
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS LoadingPoint
	|FROM
	|	Document.Trip.Route AS TripRoute
	|WHERE
	|	TripRoute.Ref IN (&ObjectsArray)
	|TOTALS
	|BY
	|	Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TripContent.Ref AS Ref,
	|	TripContent.ConnectionKey AS ConnectionKey,
	|	SUM(TripContent.Weight) AS Weight,
	|	SUM(TripContent.VolumeM3) AS VolumeM3,
	|	PRESENTATION(TripContent.ReferenceOrder) AS ReferenceOrder
	|FROM
	|	Document.Trip.Content AS TripContent
	|WHERE
	|	TripContent.Ref IN (&ObjectsArray)
	|	AND NOT TripContent.Canceled
	|GROUP BY
	|	TripContent.Ref,
	|	TripContent.ConnectionKey,
	|	TripContent.ReferenceOrder,
	|	PRESENTATION(TripContent.ReferenceOrder)
	|
	|ORDER BY
	|	TripContent.ReferenceOrder
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TripContent.Ref AS Ref,
	|	TripContent.ConnectionKey AS ConnectionKey,
	|	TripContent.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	TripContent.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|FROM
	|	Document.Trip.Content AS TripContent
	|WHERE
	|	TripContent.Ref IN (&ObjectsArray)
	|	AND NOT TripContent.Canceled";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("ObjectsArray", ObjectsArray);
	Result = Query.ExecuteBatch();
	MaxIndex = Result.UBound();
	RouteData = Result[MaxIndex - 2].Select(QueryResultIteration.ByGroups);
	DataOnOrders = Result[MaxIndex - 1].Unload(); // ValueTable
	DataOnPlanningDocuments = Result[MaxIndex].Unload(); // ValueTable
	
	ItineraryData = New Structure;
	ItineraryData.Insert("RouteData", RouteData);
	ItineraryData.Insert("DataOnOrders", DataOnOrders);
	ItineraryData.Insert("DataOnPlanningDocuments", DataOnPlanningDocuments);
	
	Return ItineraryData;
	
EndFunction

Function TripDataSet(RouteData, DataOnOrders, DataOnPlanningDocuments)
	
	SetOfRoutes = RoutesTable();
	TableOfResults = NewItinerarySummaryTable();
	
	While RouteData.Next() Do
		
		Selection = RouteData.Select();
		Route = RouteData(Selection, DataOnOrders, DataOnPlanningDocuments);
		
		NewRow = SetOfRoutes.Add();
		NewRow.Ref = RouteData.Ref;
		NewRow.Route = Route;
		
		Filter = New Structure;
		Filter.Insert("CurrentActualPoint", True);
		FoundRows = Route.FindRows(Filter);
		WeightDeliveryPoint = 0;
		VolumeDeliveryPoint = 0;
		
		For Each CurrentRow In FoundRows Do
			
			WeightDeliveryPoint = WeightDeliveryPoint + CurrentRow.WeightDeliveryPoint;
			VolumeDeliveryPoint = VolumeDeliveryPoint + CurrentRow.VolumeDeliveryPoint;
			
		EndDo;
		
		NewRowOfTotals = TableOfResults.Add();
		NewRowOfTotals.Ref = RouteData.Ref;
		NewRowOfTotals.NumberOfDeliveryPoints = FoundRows.Count();
		NewRowOfTotals.Weight = WeightDeliveryPoint;
		NewRowOfTotals.VolumeM3 = VolumeDeliveryPoint;
		
	EndDo;
	
	TripData = New Structure;
	TripData.Insert("SetOfRoutes", SetOfRoutes);
	TripData.Insert("TableOfResults", TableOfResults);
	
	Return TripData;
	
EndFunction

Function RouteData(Selection, DataOnOrders, DataOnPlanningDocuments)
	
	RouteTable = NewRouteTable();
	LineNumberToPrint = 0;
	While Selection.Next() Do
		
		References = "";
		SelectionOfSearchOrders = New Structure;
		SelectionOfSearchOrders.Insert("Ref", Selection.Ref);
		SelectionOfSearchOrders.Insert("ConnectionKey", Selection.ConnectionKey);
		
		FoundRows = DataOnOrders.FindRows(SelectionOfSearchOrders);
		DeliveryPointVolume = 0;
		DeliveryPointWeight = 0;
		OrderCounter = 0;
		ThereIsDataOnDelivery = False;
		DeliveryTimeFrom = Selection.DeliveryTimeFrom;
		DeliveryTimeTo = Selection.DeliveryTimeTo;
		
		For Each CurrentFoundLine In FoundRows Do
			
			ThereIsDataOnDelivery = True;
			OrderCounter = OrderCounter + 1;
			DeliveryPointVolume = DeliveryPointVolume + CurrentFoundLine.VolumeM3;
			DeliveryPointWeight = DeliveryPointWeight + CurrentFoundLine.Weight;
			
			ReferenceOrder = CurrentFoundLine.ReferenceOrder;
			If OrderCounter = 1 Then
				References = ReferenceOrder;
			Else
				References = References + Chars.LF + ReferenceOrder;
			EndIf;
			
		EndDo;
		
		NewRow = RouteTable.Add();
		NewRow.LineNumber = Selection.LineNumber;
		NewRow.VolumeDeliveryPoint = DeliveryPointVolume;
		NewRow.WeightDeliveryPoint = DeliveryPointWeight;
		NewRow.DeliveryPointOrders = References;
		
		TimeFormat = "DF=HH:mm";
		
		If ValueIsFilled(DeliveryTimeFrom)
		 And ValueIsFilled(DeliveryTimeTo) Then
			
			TemplateDeliveryTime = "%1 - %2";
			NewRow.TimeOfDeliveryPresentation = StrTemplate(
				TemplateDeliveryTime,
				Format(DeliveryTimeFrom, TimeFormat),
				Format(DeliveryTimeTo, TimeFormat));
			
		ElsIf ValueIsFilled(DeliveryTimeFrom) Then
			
			NewRow.TimeOfDeliveryPresentation = Format(DeliveryTimeFrom, TimeFormat);
			
		ElsIf ValueIsFilled(DeliveryTimeTo) Then
			
			NewRow.TimeOfDeliveryPresentation = Format(DeliveryTimeTo, TimeFormat);
			
		EndIf;
		
		If ThereIsDataOnDelivery
		 Or Selection.LoadingPoint Then
			
			LineNumberToPrint = LineNumberToPrint + 1;
			NewRow.LineNumberToPrint = LineNumberToPrint;
			NewRow.CurrentActualPoint = True;
			
		EndIf;
		
		FoundRows = DataOnPlanningDocuments.FindRows(SelectionOfSearchOrders);
		AddedOptionsForSpecialConditions = New Map;
		AddedOptionsForAdditionalInformation = New Map;
		For Each CurrentFoundLine In FoundRows Do
			
			SpecialGoodsConditions = CurrentFoundLine.SpecialTransportationConditionsDescription;
			If ValueIsFilled(SpecialGoodsConditions) Then
				
				Hash = GoodsDelivery.HashOfSignificantCharactersOfString(SpecialGoodsConditions);
				If AddedOptionsForSpecialConditions[Hash] = Undefined Then
					
					NewRow.SpecialConditions = NewRow.SpecialConditions + Chars.LF + SpecialGoodsConditions;
					AddedOptionsForSpecialConditions.Insert(Hash, True);
					
				EndIf;
				
			EndIf;
			
			AdditionalGoodsInformation = CurrentFoundLine.AdditionalDeliveryInformation;
			If ValueIsFilled(AdditionalGoodsInformation) Then
				
				Hash = GoodsDelivery.HashOfSignificantCharactersOfString(AdditionalGoodsInformation);
				If AddedOptionsForAdditionalInformation[Hash] = Undefined Then
					
					NewRow.AdditionalInformation = NewRow.AdditionalInformation + Chars.LF + AdditionalGoodsInformation;
					AddedOptionsForAdditionalInformation.Insert(Hash, True);
					
				EndIf;
				
			EndIf;
			
		EndDo;
		
		NewRow.SpecialConditions = TrimAll(NewRow.SpecialConditions);
		NewRow.AdditionalInformation = TrimAll(NewRow.AdditionalInformation);
		
	EndDo;
	
	Return RouteTable;
	
EndFunction

// Returns a table of values for an external set of additional Print data Template.
// 
// Returns:
//  ValueTable - Table of products verification:
// * Ref - DocumentRef.Trip
// * Route - See NewRouteTable
//
Function RoutesTable()
	
	DescriptionOfLinkTypes = New TypeDescription("DocumentRef.Trip");
	DescriptionOfVTTypes = New TypeDescription("ValueTable");
	
	Routes = New ValueTable;
	Routes.Columns.Add("Ref", DescriptionOfLinkTypes);
	Routes.Columns.Add("Route", DescriptionOfVTTypes);
	
	Return Routes;
	
EndFunction

// Returns:
//  ValueTable:
// * LineNumber  - Number
// * TimeOfDeliveryPresentation - String
// * WeightDeliveryPoint - Number
// * VolumeDeliveryPoint - Number
// * DeliveryPointOrders - String
// * LineNumberToPrint  - Number
// * CurrentActualPoint  - Boolean
// * AdditionalInformation - String
// * SpecialConditions - String
// 
Function NewRouteTable()
	
	RouteTable = New ValueTable;
	
	TypeDescriptionNumber = Common.TypeDescriptionNumber(15, 3);
	TypeDetails = New TypeDescription("String");
	StringTypeDetails20 = Common.StringTypeDetails(20);
	BooleanTypeDetails = New TypeDescription("Boolean");
	
	Columns = RouteTable.Columns;
	Columns.Add("LineNumber", Common.TypeDescriptionNumber(10));
	Columns.Add("TimeOfDeliveryPresentation", StringTypeDetails20);
	Columns.Add("WeightDeliveryPoint", TypeDescriptionNumber);
	Columns.Add("VolumeDeliveryPoint", TypeDescriptionNumber);
	Columns.Add("DeliveryPointOrders", TypeDetails);
	Columns.Add("LineNumberToPrint", Common.TypeDescriptionNumber(10));
	Columns.Add("CurrentActualPoint", BooleanTypeDetails);
	Columns.Add("AdditionalInformation", TypeDetails);
	Columns.Add("SpecialConditions", TypeDetails);
	
	Return RouteTable;
	
EndFunction

// Returns:
//  ValueTable - Results for PF PF_MXL_MarshrutnyList:
// * Ref - DocumentRef.Trip
// * NumberOfDeliveryPoints - Number
// * Weight - Number
// * VolumeM3 - Number
// 
Function NewItinerarySummaryTable()
	
	TableOfResults = New ValueTable;
	
	TypeDescriptionNumber = Common.TypeDescriptionNumber(15, 3);
	DescriptionOfLinkTypes = New TypeDescription("DocumentRef.Trip");
	
	Columns = TableOfResults.Columns;
	Columns.Add("Ref", DescriptionOfLinkTypes);
	Columns.Add("NumberOfDeliveryPoints", TypeDescriptionNumber);
	Columns.Add("Weight", TypeDescriptionNumber);
	Columns.Add("VolumeM3", TypeDescriptionNumber);
	
	Return TableOfResults;
	
EndFunction

#EndRegion

#Region Other

// Returns:
//  Map of KeyAndValue:
//  * Key - EnumRef.TripStatuses -
//  * Value - String -
//
Function FlightStatusByStatus()
	
	FlightStates = New Map;
	
	StatePresentation = NStr("vi = 'Đang trong quá trình tạo';
							|ru = 'В процессе формирования';
							|en = 'Generation in progress'; fa = 'Generation in progress';
							|it = 'Generation in progress';
							|pl = 'Generation in progress';
							|tr = 'Oluşturulma sürecinde'");
	FlightStates.Insert(Enums.TripStatuses.Prepared, StatePresentation);
	
	StatePresentation = NStr("vi = 'Sẵn sàng để gửi';
							|ru = 'Готов к отправке';
							|en = 'Ready for dispatch'; fa = 'Ready for dispatch';
							|it = 'Ready for dispatch';
							|pl = 'Ready for dispatch';
							|tr = 'Gönderime hazır'");
	FlightStates.Insert(Enums.TripStatuses.Generated1, StatePresentation);
	
	StatePresentation = NStr("vi = 'Đang giao hàng';
							|ru = 'В процессе доставки';
							|en = 'Under delivery'; fa = 'Under delivery';
							|it = 'Under delivery';
							|pl = 'Under delivery';
							|tr = 'Teslimat sürecinde'");
	FlightStates.Insert(Enums.TripStatuses.Shipped_5, StatePresentation);
	
	StatePresentation = NStr("vi = 'Đã hoàn thành';
							|ru = 'Завершен';
							|en = 'Completed'; fa = 'تکمیل‌شده';
							|it = 'Completed';
							|pl = 'Completed';
							|tr = 'Tamamlandı'");
	FlightStates.Insert(Enums.TripStatuses.Completed, StatePresentation);
	
	StatePresentation = NStr("vi = 'Hủy bỏ';
							|ru = 'Отменен';
							|en = 'Canceled'; fa = 'لغوشده';
							|it = 'Canceled';
							|pl = 'Canceled';
							|tr = 'İptal edildi'");
	FlightStates.Insert(Enums.TripStatuses.RolledBack_, StatePresentation);
	
	Return FlightStates;
	
EndFunction

// Parameters:
//  Trip -  DocumentRef.Trip
//
// Returns:
//  QueryResultSelection:
//   * ForAssembly - Number
//   * KittingIsScheduled - Number
//   * AssemblyInProgress - Number
//   * Assembled - Number
//
Function FlightAssemblyData(Trip)
	
	QueryText =
	"SELECT
	|	DeliveryTurnover.Trip AS Trip,
	|	DeliveryTurnover.Arm AS Arm,
	|	CASE
	|		WHEN DeliveryTurnover.Arm = &ShoulderKitNumber
	|			THEN DeliveryTurnover.ForAssemblyTurnover
	|		ELSE 0
	|	END AS ForAssembly,
	|	DeliveryTurnover.KittingIsScheduledTurnover AS KittingIsScheduled,
	|	DeliveryTurnover.AssemblyInProgressTurnover AS AssemblyInProgress,
	|	DeliveryTurnover.AssembledTurnover AS Assembled
	|INTO TT_Turnovers
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(, , , Trip = &Trip) AS DeliveryTurnover
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Turnovers.Trip AS Trip,
	|	SUM(Turnovers.ForAssembly) AS ForAssembly,
	|	SUM(Turnovers.KittingIsScheduled) AS KittingIsScheduled,
	|	SUM(Turnovers.AssemblyInProgress) AS AssemblyInProgress,
	|	SUM(Turnovers.Assembled) AS Assembled
	|FROM
	|	TT_Turnovers AS Turnovers
	|GROUP BY
	|	Turnovers.Trip";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Trip", Trip);
	Query.SetParameter("ShoulderKitNumber", 1);
	
	Return Query.Execute().Select();
	
EndFunction

// Parameters:
//  Trip - DocumentRef.Trip -
// 
// Returns:
//  String
//
Function StateOfTripIsInStatusForKitting(Trip)
	
	TripState = "";
	StateOfKitInStock = NStr("vi = 'Đóng gói tại kho';
							|ru = 'Сборка на складе';
							|en = 'Picking in a warehouse'; fa = 'Picking in a warehouse';
							|it = 'Picking in a warehouse';
							|pl = 'Picking in a warehouse';
							|tr = 'Ambarda toplama'");
	
	Selection = FlightAssemblyData(Trip);
	If Selection.Next() Then
		
		If Selection.ForAssembly = 0 Then
			
			TripState = StateOfKitInStock;
			
		ElsIf Selection.ForAssembly > (Selection.KittingIsScheduled + Selection.AssemblyInProgress + Selection.Assembled) Then
			
			TripState = NStr("vi = 'Đang chờ phiếu';
							|ru = 'Ожидаются ордера';
							|en = 'Notes are expected'; fa = 'Notes are expected';
							|it = 'Notes are expected';
							|pl = 'Notes are expected';
							|tr = 'Siparişler bekleniyor'");
			
		ElsIf Selection.ForAssembly > Selection.Assembled Then
			
			TripState = NStr("vi = 'Đã tạo phiếu';
							|ru = 'Сформированы ордера';
							|en = 'Notes are generated'; fa = 'Notes are generated';
							|it = 'Notes are generated';
							|pl = 'Notes are generated';
							|tr = 'Siparişler oluşturuldu'");
			
		ElsIf Selection.ForAssembly <= Selection.Assembled Then
			
			TripState = NStr("vi = 'Đã đóng gói';
							|ru = 'Собрано';
							|en = 'Picked'; fa = 'برداشت‌شده';
							|it = 'Picked';
							|pl = 'Picked';
							|tr = 'Toplandı'");
			
		EndIf;
		
	Else
		
		TripState = StateOfKitInStock;
		
	EndIf;
	
	Return TripState;
	
EndFunction

#EndRegion

#EndRegion

#EndIf