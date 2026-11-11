//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	AdditionalMWProperties = AdditionalProperties.TempTablesManager; // TempTablesManager
	
	If AdditionalMWProperties.Tables.Find("RegisteredRecordsDeliveryBeforeRecording") <> Undefined Then
		Return;
	EndIf;
	
	AdditionalDocumentProperties = AdditionalProperties.DocumentProperties; // See DocumentsPosting.DocumentProperties
	
	Recorders = CommonClientServer.StructureProperty(
		AdditionalProperties, "Recorders", New Array); // Array from Documentlink
	
	If ValueIsFilled(Filter.Recorder.Value) Then
		
		// Cancellation of the event
		Recorders.Add(Filter.Recorder.Value);
		
	EndIf;
	
	Recorders = CommonClientServer.CollapseArray(Recorders);  // Array of DocumentRef
	
	Query = New Query;
	QueryText = QueryTextBeforeWrite();
	Query.Text = QueryText;
	
	Query.SetParameter("Recorders", Recorders);
	Query.SetParameter("IsNew", AdditionalDocumentProperties.IsNew);
	Query.SetParameter("DataExchange", DataExchange.Load);
	CalculateChanges_ = DocumentsPosting.CalculateChanges_(AdditionalProperties);
	Query.SetParameter("CalculateChanges_", CalculateChanges_);
	Query.TempTablesManager = AdditionalMWProperties;
	
	Query.Execute();
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load
	 Or Not DocumentsPosting.CalculateChanges_(AdditionalProperties) Then
		Return;
	EndIf;
	
	FixChangesAfterRecording = CommonClientServer.StructureProperty(
		AdditionalProperties, "FixChangesAfterRecording", True);
	
	If FixChangesAfterRecording Then
		
		GenerateTableOfChanges();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function QueryTextBeforeWrite()
	
	QueryText =
	"SELECT
	|	Table.Organization AS Organization,
	|	Table.DeliveryType AS DeliveryType,
	|	Table.DateOfShipment AS DateOfShipment,
	|	Table.DeliveryMethod AS DeliveryMethod,
	|	Table.Sender AS Sender,
	|	Table.SenderPoint AS SenderPoint,
	|	Table.Sender_Area AS Sender_Area,
	|	Table.Recipient AS Recipient,
	|	Table.RecipientPoint AS RecipientPoint,
	|	Table.Recipient_Area AS Recipient_Area,
	|	Table.PlanningDocument AS PlanningDocument,
	|	Table.ReferenceOrder AS ReferenceOrder,
	|	Table.Trip AS Trip,
	|	Table.Products AS Products,
	|	Table.Characteristic AS Characteristic,
	|	Table.Series AS Series,
	|	Table.RowCode AS RowCode,
	|	Table.Arm AS Arm,
	|	Table.Carrier AS Carrier,
	|	Table.Package AS Package,
	|	Table.ToDeliver AS ToDeliver,
	|	Table.ToTrip AS ToTrip,
	|	Table.InTrip AS InTrip,
	|	Table.InTransit AS InTransit,
	|	Table.Delivered AS Delivered,
	|	Table.Canceled AS Canceled,
	|	Table.ForAssembly AS ForAssembly,
	|	Table.KittingIsScheduled AS KittingIsScheduled,
	|	Table.AssemblyInProgress AS AssemblyInProgress,
	|	Table.Assembled AS Assembled
	|INTO RegisteredRecordsDeliveryBeforeRecording
	|FROM
	|	AccumulationRegister.Delivery AS Table
	|WHERE
	|	Table.Recorder IN (&Recorders)
	|	AND NOT &IsNew
	|	AND NOT &DataExchange
	|	AND &CalculateChanges_";
	
	Return QueryText;
	
EndFunction

Function QueryTextChangesAfterRecording()
	
	QueryText =
	"SELECT
	|	ChangesTable.Organization AS Organization,
	|	ChangesTable.DeliveryType AS DeliveryType,
	|	ChangesTable.DateOfShipment AS DateOfShipment,
	|	ChangesTable.DeliveryMethod AS DeliveryMethod,
	|	ChangesTable.Sender AS Sender,
	|	ChangesTable.SenderPoint AS SenderPoint,
	|	ChangesTable.Sender_Area AS Sender_Area,
	|	ChangesTable.Recipient AS Recipient,
	|	ChangesTable.RecipientPoint AS RecipientPoint,
	|	ChangesTable.Recipient_Area AS Recipient_Area,
	|	ChangesTable.PlanningDocument AS PlanningDocument,
	|	ChangesTable.ReferenceOrder AS ReferenceOrder,
	|	ChangesTable.Trip AS Trip,
	|	ChangesTable.Products AS Products,
	|	ChangesTable.Characteristic AS Characteristic,
	|	ChangesTable.Series AS Series,
	|	ChangesTable.RowCode AS RowCode,
	|	ChangesTable.Arm AS Arm,
	|	ChangesTable.Carrier AS Carrier,
	|	ChangesTable.Package AS Package,
	|	SUM(ChangesTable.ToDeliver) AS ToDeliverUpdate,
	|	SUM(ChangesTable.ToTrip) AS ToTripUpdate,
	|	SUM(ChangesTable.InTrip) AS InTripUpdate,
	|	SUM(ChangesTable.InTransit) AS InTransitUpdate,
	|	SUM(ChangesTable.Delivered) AS DeliveredUpdate,
	|	SUM(ChangesTable.Canceled) AS CanceledUpdate,
	|	SUM(ChangesTable.ForAssembly) AS ForAssemblyUpdate,
	|	SUM(ChangesTable.KittingIsScheduled) AS KittingIsScheduledUpdate,
	|	SUM(ChangesTable.AssemblyInProgress) AS AssemblyInProgressUpdate,
	|	SUM(ChangesTable.Assembled) AS AssembledUpdate
	|INTO RegisteredRecordsDeliveryChange
	|FROM
	|	(SELECT
	|		Table.Organization AS Organization,
	|		Table.DeliveryType AS DeliveryType,
	|		Table.DateOfShipment AS DateOfShipment,
	|		Table.DeliveryMethod AS DeliveryMethod,
	|		Table.Sender AS Sender,
	|		Table.SenderPoint AS SenderPoint,
	|		Table.Sender_Area AS Sender_Area,
	|		Table.Recipient AS Recipient,
	|		Table.RecipientPoint AS RecipientPoint,
	|		Table.Recipient_Area AS Recipient_Area,
	|		Table.PlanningDocument AS PlanningDocument,
	|		Table.ReferenceOrder AS ReferenceOrder,
	|		Table.Trip AS Trip,
	|		Table.Products AS Products,
	|		Table.Characteristic AS Characteristic,
	|		Table.Series AS Series,
	|		Table.RowCode AS RowCode,
	|		Table.Arm AS Arm,
	|		Table.Carrier AS Carrier,
	|		Table.Package AS Package,
	|		-1 * Table.ToDeliver AS ToDeliver,
	|		-1 * Table.ToTrip AS ToTrip,
	|		-1 * Table.InTrip AS InTrip,
	|		-1 * Table.InTransit AS InTransit,
	|		-1 * Table.Delivered AS Delivered,
	|		-1 * Table.Canceled AS Canceled,
	|		-1 * Table.ForAssembly AS ForAssembly,
	|		-1 * Table.KittingIsScheduled AS KittingIsScheduled,
	|		-1 * Table.AssemblyInProgress AS AssemblyInProgress,
	|		-1 * Table.Assembled AS Assembled
	|	FROM
	|		RegisteredRecordsDeliveryBeforeRecording AS Table
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		Table.Organization,
	|		Table.DeliveryType,
	|		Table.DateOfShipment,
	|		Table.DeliveryMethod,
	|		Table.Sender,
	|		Table.SenderPoint,
	|		Table.Sender_Area,
	|		Table.Recipient,
	|		Table.RecipientPoint,
	|		Table.Recipient_Area,
	|		Table.PlanningDocument,
	|		Table.ReferenceOrder,
	|		Table.Trip,
	|		Table.Products,
	|		Table.Characteristic,
	|		Table.Series,
	|		Table.RowCode,
	|		Table.Arm,
	|		Table.Carrier,
	|		Table.Package,
	|		Table.ToDeliver,
	|		Table.ToTrip,
	|		Table.InTrip,
	|		Table.InTransit,
	|		Table.Delivered,
	|		Table.Canceled,
	|		Table.ForAssembly,
	|		Table.KittingIsScheduled,
	|		Table.AssemblyInProgress,
	|		Table.Assembled
	|	FROM
	|		AccumulationRegister.Delivery AS Table
	|	WHERE
	|		Table.Recorder IN (&Recorders)) AS ChangesTable
	|WHERE
	|	NOT &DataExchange
	|	AND &CalculateChanges_
	|
	|GROUP BY
	|	ChangesTable.Organization,
	|	ChangesTable.DeliveryType,
	|	ChangesTable.DateOfShipment,
	|	ChangesTable.DeliveryMethod,
	|	ChangesTable.Sender,
	|	ChangesTable.SenderPoint,
	|	ChangesTable.Sender_Area,
	|	ChangesTable.Recipient,
	|	ChangesTable.RecipientPoint,
	|	ChangesTable.Recipient_Area,
	|	ChangesTable.PlanningDocument,
	|	ChangesTable.ReferenceOrder,
	|	ChangesTable.Trip,
	|	ChangesTable.Products,
	|	ChangesTable.Characteristic,
	|	ChangesTable.Series,
	|	ChangesTable.RowCode,
	|	ChangesTable.Arm,
	|	ChangesTable.Carrier,
	|	ChangesTable.Package
	|
	|HAVING
	|	(SUM(ChangesTable.ToDeliver) <> 0
	|		OR SUM(ChangesTable.ToTrip) <> 0
	|		OR SUM(ChangesTable.InTrip) <> 0
	|		OR SUM(ChangesTable.InTransit) <> 0
	|		OR SUM(ChangesTable.Delivered) <> 0
	|		OR SUM(ChangesTable.Canceled) <> 0
	|		OR SUM(ChangesTable.ForAssembly) <> 0
	|		OR SUM(ChangesTable.KittingIsScheduled) <> 0
	|		OR SUM(ChangesTable.AssemblyInProgress) <> 0
	|		OR SUM(ChangesTable.Assembled) <> 0)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ISNULL(MAX(
	|		CASE
	|			WHEN RegisteredRecordsDeliveryChange.ToDeliverUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.ToTripUpdate <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END), FALSE) AS ThereAreChangesToDeliveryForTrip,
	|	ISNULL(MAX(
	|		CASE
	|			WHEN RegisteredRecordsDeliveryChange.InTripUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.ToTripUpdate <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END), FALSE) AS ThereAreChangesToTripInTrip,
	|	ISNULL(MAX(
	|		CASE
	|			WHEN RegisteredRecordsDeliveryChange.ForAssemblyUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.InTransitUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.DeliveredUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.KittingIsScheduledUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.AssemblyInProgressUpdate <> 0
	|					OR RegisteredRecordsDeliveryChange.AssembledUpdate <> 0
	|				THEN TRUE
	|			ELSE FALSE
	|		END), FALSE) AS ThereAreBuildChanges
	|FROM
	|	RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP RegisteredRecordsDeliveryBeforeRecording
	|";
	
	Return QueryText;
	
EndFunction

Function QueryTextThereAreChangesInDimensionalGoods()
	
	QueryText =
	"SELECT TOP 1
	|	TRUE AS ThereAreChangesInDimensionalGoods
	|FROM
	|	(SELECT DISTINCT
	|		CAST(RegisteredRecordsDeliveryChange.Products AS Catalog.Products) AS Products
	|	FROM
	|		RegisteredRecordsDeliveryChange AS RegisteredRecordsDeliveryChange) AS ItemOfChanges
	|WHERE
	|	ItemOfChanges.Products.UnitOfMeasure.MeasuredValueType IN(&DimensionalTypesOfUnits)";
	
	Return QueryText;
	
EndFunction

Procedure GenerateTableOfChanges()
	
	Recorders = CommonClientServer.StructureProperty(
		AdditionalProperties, "Recorders", New Array); // Array from Documentlink
	
	AdditionalMWProperties = AdditionalProperties.TempTablesManager; // TempTablesManager
	
	If ValueIsFilled(Filter.Recorder.Value) Then
		
		// Cancellation of the event
		Recorders.Add(Filter.Recorder.Value);
		
	EndIf;
	
	Recorders = CommonClientServer.CollapseArray(Recorders);  // Array of DocumentRef
	
	Query = New Query;
	QueryText = QueryTextChangesAfterRecording();
	Query.Text = QueryText;
	
	Query.SetParameter("Recorders", Recorders);
	Query.SetParameter("DataExchange", DataExchange.Load);
	CalculateChanges_ = DocumentsPosting.CalculateChanges_(AdditionalProperties);
	Query.SetParameter("CalculateChanges_", CalculateChanges_);
	Query.TempTablesManager = AdditionalMWProperties;
	
	Result = Query.ExecuteBatch();
	SelectionUpdate = Result[Result.UBound() - 2].Select();
	HasChanges = (SelectionUpdate.Next() And SelectionUpdate.Count > 0);
	
	ControlTableParameters = GoodsDelivery.NewDeliveryControlTableParameters();
	SamplingFlags = Result[Result.UBound() - 1].Select();
	If SamplingFlags.Next() Then
		FillPropertyValues(ControlTableParameters, SamplingFlags);
	EndIf;
	
	If HasChanges
		And GetFunctionalOption("UseAllowableDeviationOfMeasuringGoodsShipmentReceiving") Then
		
		QueryText = QueryTextThereAreChangesInDimensionalGoods();
		Query.Text = QueryText;
		DimensionalTypesOfUnits = Catalogs.PackagesAndUnitsOfMeasure.DimensionalTypesOfUnits();
		Query.SetParameter("DimensionalTypesOfUnits", DimensionalTypesOfUnits);
		
		Selection = Query.Execute().Select();
		If Selection.Next() Then
			FillPropertyValues(ControlTableParameters, Selection);
		EndIf;
		
	EndIf;
	
	DocumentsPosting.RegisterControlTable(
		AdditionalProperties,
		"RegisteredRecordsDeliveryChange",
		HasChanges,
		ControlTableParameters);
	
EndProcedure

#EndRegion

#EndIf
