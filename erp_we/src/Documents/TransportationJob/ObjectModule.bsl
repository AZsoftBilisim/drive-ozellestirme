// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Sets the status for the document object
//
// Parameters:
//	NewStatus - String - Name of the status that will be set for orders
//	AdditionalParameters - Structure - Structure of additional parameters for setting the status.
//
// Returns:
//	Boolean - True, in case of successful installation of the new status.
//
Function SetStatus(NewStatus, AdditionalParameters) Export
	
	MeaningOfNewStatus = Enums.StatusesOfTransportationJobs[NewStatus];
	
	If Operation = Enums.DeliveryKinds.FromWarehouse
	   And Status <> Enums.StatusesOfTransportationJobs.Sent
	   And Status <> Enums.StatusesOfTransportationJobs.Closed
	   And WarehousesServer.ThereIsOrderWarehouseForShipment(References.UnloadColumn("Warehouse"),Date)
	   And (MeaningOfNewStatus = Enums.StatusesOfTransportationJobs.Sent
		  Or MeaningOfNewStatus = Enums.StatusesOfTransportationJobs.Closed) Then
			
		If GoodsDelivery.ReCompleteTransportTaskForExpenseOrders(ThisObject) Then // there are changes after re-filling
			
			If References.Count() = 0 Then
				
				ErrorTemplate = NStr("vi = 'Trạng thái chứng từ %1 chưa được thiết lập sau khi điền lại theo phiếu xuất kho, không còn lệnh nào trong đó.';
									|ru = 'Статус документа %1 не установлен, т.к. после перезаполнения по расходным ордерам в нем не остается распоряжений.';
									|en = 'The %1 document status is not set, as there are no references in it after refilling by goods issue notes.'; fa = 'The %1 document status is not set, as there are no references in it after refilling by goods issue notes.';
									|it = 'Статус документа %1 не установлен, т.к. после перезаполнения по расходным ордерам в нем не остается распоряжений.';
									|pl = 'The %1 document status is not set, as there are no references in it after refilling by goods issue notes.';
									|tr = '%1 belge durumu ayarlanmadı, çünkü ambar çıkış fişlerini yeniden doldurduktan sonra, içinde hiç emir kalmamıştır.'");
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(ErrorTemplate, String(Ref));
				Common.MessageToUser(ErrorText, Ref);
				
				Return False;
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	Status = MeaningOfNewStatus;
	
	Return CheckFilling();
	
EndFunction

#EndRegion

#Region EventHandlers

Procedure Filling(FillingData, StandardProcessing)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		ExceptionText = NStr("vi = 'Chứng từ không được hỗ trợ trong bản phân phối phiên bản 2.5.';
							|ru = 'Документ не поддерживается в доставке версии 2.5';
							|en = 'The document is not supported in delivery version 2.5'; fa = 'The document is not supported in delivery version 2.5';
							|it = 'The document is not supported in delivery version 2.5';
							|pl = 'The document is not supported in delivery version 2.5';
							|tr = '2.5 sürümü teslimatta belge desteklenmiyor'");
		Raise ExceptionText;
		
	EndIf;
	
	If TypeOf(FillingData) = Type("Structure") Then
		FillPropertyValues(ThisObject, FillingData);
	EndIf;
	
	InitializeDocument(FillingData);
	
	TransportationJobLocalization.Filling(ThisObject, FillingData, StandardProcessing);
	
EndProcedure

Procedure OnCopy(CopiedObject)
	
	Status = Enums.StatusesOfTransportationJobs.BeingGenerated;
	PlanTripStartTime  = Max(CopiedObject.PlanTripStartTime, CurrentSessionDate());
	PlanTripEndTime = Date(1,1,1);
	ActualTripStartTime  = Date(1,1,1);
	ActualTripEndTime = Date(1,1,1);
	Weight                  = 0;
	VolumeM3                = 0;
	PointsNumber    = 0;
	EmployeeResponsible        = Users.CurrentUser();
	References.Clear();
	Route.Clear();
	
	TransportationJobLocalization.OnCopy(ThisObject, CopiedObject);

EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		// in delivery version 2.5, it is forbidden to write the document as a whole, See BeforeWrite
		CheckedAttributes.Clear();
		Return;
		
	EndIf;
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	// The PM of the Order is not edited manually
	NotCheckedAttributeArray.Add("References.Warehouse");
	
	If Status = Enums.StatusesOfTransportationJobs.BeingGenerated
	 Or Status = Enums.StatusesOfTransportationJobs.EmptyRef() Then
		
		NotCheckedAttributeArray.Add("Carrier");
		NotCheckedAttributeArray.Add("References");
		NotCheckedAttributeArray.Add("Route");
		If JobIsPerformedBy = Enums.TypesOfTransportationJobAssignees.Carrier Then
			NotCheckedAttributeArray.Add("Vehicle_");
		EndIf;
		
	EndIf;
	
	If JobIsPerformedBy <> Enums.TypesOfTransportationJobAssignees.Carrier Then
		NotCheckedAttributeArray.Add("Carrier");
	EndIf;
	
	KeyAttributes = New Array; // Array of String
	KeyAttributes.Add("ReferenceOrder");
	KeyAttributes.Add("Warehouse");
	
	TMCommonUse.CheckForDuplicatesOfTSStrings(ThisObject,"References",KeyAttributes,Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
	TransportationJobLocalization.FillCheckProcessing(ThisObject, Cancel, CheckedAttributes);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	If GoodsDeliveryClientServer.UsedDelivery25() Then
		
		MessageText = NStr("vi = 'Thay đổi chứng từ không được hỗ trợ trong bản phân phối phiên bản 2.5.';
							|ru = 'Изменение документа не поддерживается в доставке версии 2.5';
							|en = 'Changing the document is not supported in delivery version 2.5'; fa = 'Changing the document is not supported in delivery version 2.5';
							|it = 'Changing the document is not supported in delivery version 2.5';
							|pl = 'Changing the document is not supported in delivery version 2.5';
							|tr = 'Teslimat 2.5 sürümünde belge değişikliği desteklenmiyor'");
		Common.MessageToUser(MessageText, ThisObject,,, Cancel);
		Return;
		
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	Documents.TransportationJob.FillInFlightTimePlanFact(ThisObject);
	
	// Weight and Volume in units of measurement
	Weight   = Route.Total("Weight") * GoodsDelivery.TonConversionFactor();
	VolumeM3 = Route.Total("VolumeM3") * GoodsDelivery.CubicMeterConversionFactor();
	
	PointsNumber = Route.Count();
	
	If WriteMode = DocumentWriteMode.Posting
		Or WriteMode = DocumentWriteMode.UndoPosting Then
		
		QueryText =
		"SELECT
		|	T.ReferenceOrder
		|INTO References
		|FROM
		|	&References AS T
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	T.ReferenceOrder
		|FROM
		|	(SELECT
		|		T.ReferenceOrder AS ReferenceOrder
		|	FROM
		|		Document.TransportationJob.References AS T
		|	WHERE
		|		T.Ref = &Ref
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		T.ReferenceOrder
		|	FROM
		|		References AS T) AS T";
		
		Query = New Query(QueryText);
		Query.SetParameter("References", References.Unload(, "ReferenceOrder"));
		Query.SetParameter("Ref", Ref);
		AdditionalProperties.Insert(
			"InstructionsForRecordingState",
			Query.Execute().Unload().UnloadColumn("ReferenceOrder"));
		
	EndIf;
	
	AdditionalProperties.Insert("StatusBeforeWrite", Common.ObjectAttributeValue(Ref, "Status"));
	AdditionalProperties.Insert("PostedBeforeWrite", Posted);
	AdditionalProperties.Insert("IsNew", IsNew());
	AdditionalProperties.Insert("ChangesInCompositionOfOrders", ChangesInCompositionOfOrders());
	
	TransportationJobLocalization.BeforeWrite(ThisObject, Cancel, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	PostedBeforeWrite = AdditionalProperties.PostedBeforeWrite; // Boolean
	StatusBeforeWrite = AdditionalProperties.StatusBeforeWrite; // EnumRef.StatusesOfTransportationJobs
	
	If AdditionalProperties.Property("GoodsToDeliver") Then
		GoodsDelivery.PrepareGoodsForDelivery(AdditionalProperties.GoodsToDeliver, References, Ref);
	Else
		ClearItemsForDeliveryBasedOnOrdersDeletedFromTask();
	EndIf;
	
	// Filling in the register of goods for delivery in non-final status (if required)
	If Posted
	   And Status <> Enums.StatusesOfTransportationJobs.Closed
	   And (StatusBeforeWrite = Enums.StatusesOfTransportationJobs.Closed
		  Or Not PostedBeforeWrite) Then
		CheckAllGoodsForDelivery(Ref);
	EndIf;
	
	If Not PostedBeforeWrite
	   And Not Posted Then
		Return;
	EndIf;
	
	// The delivery status depends on the PC of the goods on delivery, we record after recording the goods for delivery.
	// When recording the delivery states, the archive records of the state registers of the Delivery Request and the goods delivery are cleared.
	If AdditionalProperties.Property("InstructionsForRecordingState") Then
		GoodsDelivery.ReflectDeliveryState(AdditionalProperties.InstructionsForRecordingState, Cancel);
	EndIf;
	
	// The launch of automatic creation of expense orders (performed when the Task and the goods have already been recorded for delivery)
	// when the event is canceled, for warehouses with FO, start the shipment after the formation of the order for transportation.
	If Operation = Enums.DeliveryKinds.FromWarehouse
		And Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically
		And (Not Posted
		   And StatusBeforeWrite <> Enums.StatusesOfTransportationJobs.BeingGenerated
		   And PostedBeforeWrite) Then
		
		Documents.TransportationJob.CreateQueueForReissuingSpendingOrders(Ref, Cancel);
		
	EndIf;
	
	TransportationJobLocalization.OnWrite(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	PostedBeforeWrite = AdditionalProperties.PostedBeforeWrite;
	StatusBeforeWrite = AdditionalProperties.StatusBeforeWrite;
	
	// Checking whether the status can be set
	If Operation = Enums.DeliveryKinds.FromWarehouse
		And (Status = Enums.StatusesOfTransportationJobs.Sent 
			Or Status = Enums.StatusesOfTransportationJobs.Closed) Then
		
		// Checking whether all the quantity according to the order for transportation has been issued expense orders,
		// only for warehouses with the FO to start the shipment after the formation of the order for transportation.
		ControlOfExecutedOrdersOnTransportationOrder(Ref, Cancel);
		
		// Checking the readiness of spending orders
		Query = New Query;
		Query.Text =
		"SELECT
		|	GoodsIssueNote.Ref
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.TransportationJob = &TransportationJob
		|	AND NOT(GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ToShip)
		|				OR GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.Shipped_))
		|	AND GoodsIssueNote.Posted";
		Query.SetParameter("TransportationJob", Ref);
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			MessageTemplate = NStr("vi = 'Phiếu xuất kho ""%1"" theo nhiệm vụ vận chuyển chưa sẵn sàng để giao hàng.';
									|ru = 'Расходный ордер ""%1"" по заданию на перевозку не готов к отгрузке.';
									|en = 'The ""%1"" goods issue note for the itinerary is not ready for shipment.'; fa = 'The ""%1"" goods issue note for the itinerary is not ready for shipment.';
									|it = 'Расходный ордер ""%1"" по заданию на перевозку не готов к отгрузке.';
									|pl = 'The ""%1"" goods issue note for the itinerary is not ready for shipment.';
									|tr = 'Taşıma planı kapsamındaki ""%1"" ambar çıkış fişi sevkiyata hazır değil.'");
			MessageText = StringFunctionsClientServer.SubstituteParametersToString(
				MessageTemplate, String(Selection.Ref));			
			Common.MessageToUser(MessageText, Selection.Ref,,, Cancel);
			
		EndDo;
	
	// Launch of automatic creation of expense orders
	// for warehouses with the FO to begin the shipment after the formation of the order for transportation.
	ElsIf Operation = Enums.DeliveryKinds.FromWarehouse
		And Constants.GoodsIssueNoteGenerationMode.Get() = Enums.GoodsIssueNoteGenerationModes.Automatically
		And (Status = Enums.StatusesOfTransportationJobs.ToLoad 
			And Not PostedBeforeWrite
				Or 
					Status = Enums.StatusesOfTransportationJobs.ToLoad
					And StatusBeforeWrite = Enums.StatusesOfTransportationJobs.BeingGenerated
				Or
					Status = Enums.StatusesOfTransportationJobs.BeingGenerated
					And StatusBeforeWrite <> Enums.StatusesOfTransportationJobs.BeingGenerated
					And PostedBeforeWrite
				Or
					StatusBeforeWrite <> Enums.StatusesOfTransportationJobs.BeingGenerated
					And StatusBeforeWrite <> Undefined
					And AdditionalProperties.ChangesInCompositionOfOrders.Count() > 0) Then
			
		Documents.TransportationJob.CreateQueueForReissuingSpendingOrders(
			Ref,
			Cancel,
			AdditionalProperties.ChangesInCompositionOfOrders);
		
	EndIf;
	
	If AdditionalProperties.IsNew
	 Or Cancel Then
		Return;
	EndIf;
	
	// Change the status of the expense orders to "Shipped" for the sent transportation tasks,
	// if all orders are executed and are in the status not lower than the shipment (this is checked above).
	If Operation = Enums.DeliveryKinds.FromWarehouse
		And (Status = Enums.StatusesOfTransportationJobs.Closed
			Or Status = Enums.StatusesOfTransportationJobs.Sent)
		And (Not PostedBeforeWrite
			Or 
				(StatusBeforeWrite <> Enums.StatusesOfTransportationJobs.Closed
				And StatusBeforeWrite <> Enums.StatusesOfTransportationJobs.Sent
				And Status <> StatusBeforeWrite)) Then 
		
		Query = New Query;
		Query.Text =
		"SELECT TOP 1
		|	GoodsIssueNote.Ref
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.TransportationJob = &TransportationJob
		|	AND GoodsIssueNote.Status = VALUE(Enum.GoodsIssueNoteStatuses.ToShip)
		|	AND GoodsIssueNote.Posted";
		Query.SetParameter("TransportationJob", Ref);
		
		If Not Query.Execute().IsEmpty() Then
			
			WarehousesServer.StartingBackgroundTransferOfStatusOfSpendingOrderToShipped(Ref);
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

#Region FillingAndInitialization

Procedure InitializeDocument(FillingData = Undefined)
	
	Warehouse          = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	EmployeeResponsible  = Users.CurrentUser();
	Priority      = SettingsValueCached.GetDefaultPriority(Priority);
	References.Clear();
	Route.Clear();
	
EndProcedure

#EndRegion

#Region Other

Procedure ControlOfExecutedOrdersOnTransportationOrder(Var_Ref, Cancel)
		
	Query = New Query;
	Query.Text = Documents.TransportationJob.TextOfRegisterControlRequestGoodsForShipmentAndGoodsForDelivery() +
	"SELECT DISTINCT
	|	GoodsForShipmentAndDelivery.Warehouse,
	|	GoodsForShipmentAndDelivery.DocumentShipments
	|FROM
	|	GoodsForShipmentAndDelivery AS GoodsForShipmentAndDelivery
	|		LEFT JOIN GoodsForIssueExpense AS GoodsForIssueExpense
	|		ON GoodsForShipmentAndDelivery.DocumentShipments = GoodsForIssueExpense.DocumentShipments
	|			AND GoodsForShipmentAndDelivery.Warehouse = GoodsForIssueExpense.Warehouse
	|			AND GoodsForShipmentAndDelivery.Recipient = GoodsForIssueExpense.Recipient
	|			AND GoodsForShipmentAndDelivery.Products = GoodsForIssueExpense.Products
	|			AND GoodsForShipmentAndDelivery.Characteristic = GoodsForIssueExpense.Characteristic
	|			AND GoodsForShipmentAndDelivery.Purpose = GoodsForIssueExpense.Purpose
	|			AND GoodsForShipmentAndDelivery.Series = GoodsForIssueExpense.Series
	|		LEFT JOIN GoodsCollectedCollected_ AS GoodsCollectedCollected_
	|		ON GoodsForShipmentAndDelivery.DocumentShipments = GoodsCollectedCollected_.DocumentShipments
	|			AND GoodsForShipmentAndDelivery.Warehouse = GoodsCollectedCollected_.Warehouse
	|			AND GoodsForShipmentAndDelivery.Recipient = GoodsCollectedCollected_.Recipient
	|			AND GoodsForShipmentAndDelivery.Products = GoodsCollectedCollected_.Products
	|			AND GoodsForShipmentAndDelivery.Characteristic = GoodsCollectedCollected_.Characteristic
	|			AND GoodsForShipmentAndDelivery.Purpose = GoodsCollectedCollected_.Purpose
	|			AND GoodsForShipmentAndDelivery.Series = GoodsCollectedCollected_.Series
	|		LEFT JOIN ProductsReadyForAssembly AS ProductsReadyForAssembly
	|		ON GoodsForShipmentAndDelivery.DocumentShipments = ProductsReadyForAssembly.DocumentShipments
	|			AND GoodsForShipmentAndDelivery.Warehouse = ProductsReadyForAssembly.Warehouse
	|			AND GoodsForShipmentAndDelivery.Recipient = ProductsReadyForAssembly.Recipient
	|			AND GoodsForShipmentAndDelivery.Products = ProductsReadyForAssembly.Products
	|			AND GoodsForShipmentAndDelivery.Characteristic = ProductsReadyForAssembly.Characteristic
	|			AND GoodsForShipmentAndDelivery.Purpose = ProductsReadyForAssembly.Purpose
	|			AND GoodsForShipmentAndDelivery.Series = ProductsReadyForAssembly.Series
	|WHERE
	|	CASE
	|			WHEN GoodsForShipmentAndDelivery.Count < GoodsForShipmentAndDelivery.QuantityToShip
	|				THEN GoodsForShipmentAndDelivery.Count > ISNULL(GoodsForIssueExpense.Count, 0) + ISNULL(GoodsCollectedCollected_.Count, 0) + ISNULL(ProductsReadyForAssembly.Count, 0)
	|			ELSE GoodsForShipmentAndDelivery.QuantityToShip > ISNULL(GoodsForIssueExpense.Count, 0) + ISNULL(GoodsCollectedCollected_.Count, 0) + ISNULL(ProductsReadyForAssembly.Count, 0)
	|		END";
	IssueInvoicesFirst = Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get() = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("TransportationJob", Var_Ref);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		MessageTemplate = NStr("vi = 'Chưa tạo tất cả phiếu xuất kho theo nhiệm vụ vận chuyển ""%1"" cho lệnh ""%2"" tại kho ""%3"". Hãy tạo phiếu và(hoặc) điền lại nhiệm vụ vận chuyển theo các phiếu xuất kho.';
								|ru = 'Не оформлены все расходные ордера по заданию на перевозку ""%1"" для распоряжения ""%2"" на  складе ""%3"". Оформите ордера и(или) перезаполните задание на перевозку по расходным ордерам.';
								|en = 'All goods issue notes of the ""%1"" itinerary are not registered for the ""%2"" reference in the ""%3"" warehouse. Register the notes and(or) refill the itinerary against the goods issue notes.'; fa = 'All goods issue notes of the ""%1"" itinerary are not registered for the ""%2"" reference in the ""%3"" warehouse. Register the notes and(or) refill the itinerary against the goods issue notes.';
								|it = 'Не оформлены все расходные ордера по заданию на перевозку ""%1"" для распоряжения ""%2"" на  складе ""%3"". Оформите ордера и(или) перезаполните задание на перевозку по расходным ордерам.';
								|pl = 'All goods issue notes of the ""%1"" itinerary are not registered for the ""%2"" reference in the ""%3"" warehouse. Register the notes and(or) refill the itinerary against the goods issue notes.';
								|tr = '""%3"" ambarında ""%2"" emri için ""%1"" taşıma planına ilişkin tüm ambar çıkış fişleri düzenlenmemiştir. Ambar çıkış fişlerini düzenleyin ve/veya ambar çıkış fişlerine göre taşıma planını yeniden doldurun.'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			String(Var_Ref),
			String(Selection.DocumentShipments),
			String(Selection.Warehouse));
		Common.MessageToUser(MessageText, Var_Ref,,, Cancel);
		
	EndDo;
	
EndProcedure

Procedure ClearItemsForDeliveryBasedOnOrdersDeletedFromTask()
	
	QueryText =
	"SELECT
	|	GoodsToDeliver.ReferenceOrder,
	|	GoodsToDeliver.Warehouse
	|FROM
	|	InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		LEFT JOIN Document.TransportationJob.References AS OrdersTasks
	|		ON (OrdersTasks.Ref = GoodsToDeliver.TransportationJob)
	|			AND (OrdersTasks.ReferenceOrder = GoodsToDeliver.ReferenceOrder)
	|			AND (OrdersTasks.Warehouse = GoodsToDeliver.Warehouse)
	|WHERE
	|	GoodsToDeliver.TransportationJob = &Ref
	|	AND OrdersTasks.ReferenceOrder IS NULL ";
	Query = New Query(QueryText);
	Query.SetParameter("Ref", Ref);
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		
		RecordSet = InformationRegisters.GoodsToDeliver.CreateRecordSet();
		RecordSet.Filter.TransportationJob.Set(Ref);
		RecordSet.Filter.ReferenceOrder.Set(Selection.ReferenceOrder);
		RecordSet.Filter.Warehouse.Set(Selection.Warehouse);
		RecordSet.Write();
		
	EndDo;
	
EndProcedure

Procedure CheckAllGoodsForDelivery(TransportationJob) Export
	
	Query = New Query;
	Query.Text = 
	"SELECT TOP 1
	|	GoodsToDeliver.TransportationJob
	|FROM
	|	InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|WHERE
	|	GoodsToDeliver.TransportationJob = &TransportationJob";
	Query.SetParameter("TransportationJob", Ref);
	If Not Query.Execute().IsEmpty() Then
		Return;
	EndIf;
	
	Query.Text =
	"SELECT
	|	GoodsIssueNoteGoodsByReferences.Products,
	|	GoodsIssueNoteGoodsByReferences.Characteristic,
	|	GoodsIssueNoteGoodsByReferences.Purpose,
	|	GoodsIssueNoteGoodsByReferences.Series,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder,
	|	SUM(GoodsIssueNoteGoodsByReferences.Count) AS Count,
	|	GoodsIssueNoteGoodsByReferences.Ref.Recipient,
	|	GoodsIssueNoteGoodsByReferences.Ref.Warehouse
	|INTO GoodsUnderSpendingOrder
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS GoodsIssueNoteGoodsByReferences
	|WHERE
	|	GoodsIssueNoteGoodsByReferences.Ref.TransportationJob = &TransportationJob
	|	AND GoodsIssueNoteGoodsByReferences.Ref.Posted
	|
	|GROUP BY
	|	GoodsIssueNoteGoodsByReferences.Ref.Warehouse,
	|	GoodsIssueNoteGoodsByReferences.Ref.Recipient,
	|	GoodsIssueNoteGoodsByReferences.Purpose,
	|	GoodsIssueNoteGoodsByReferences.Series,
	|	GoodsIssueNoteGoodsByReferences.Products,
	|	GoodsIssueNoteGoodsByReferences.ReferenceOrder,
	|	GoodsIssueNoteGoodsByReferences.Characteristic
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TransportationTask.ReferenceOrder,
	|	TransportationTask.Warehouse,
	|	TransportationTask.RecipientSender,
	|	TransportationTask.Ref AS TransportationJob,
	|	CASE
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue < TransportationTask.Ref.Date
	|				AND NOT GoodsUnderSpendingOrder.ReferenceOrder IS NULL
	|			THEN FALSE
	|		ELSE TRUE 
	|	END AS AllGoods,
	|	GoodsUnderSpendingOrder.Products,
	|	GoodsUnderSpendingOrder.Characteristic,
	|	GoodsUnderSpendingOrder.Purpose,
	|	GoodsUnderSpendingOrder.Series,
	|	GoodsUnderSpendingOrder.Count
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON TransportationTask.Warehouse = Warehouses.Ref
	|		LEFT JOIN GoodsUnderSpendingOrder AS GoodsUnderSpendingOrder
	|		ON TransportationTask.ReferenceOrder = GoodsUnderSpendingOrder.ReferenceOrder
	|			AND TransportationTask.Warehouse = GoodsUnderSpendingOrder.Warehouse
	|WHERE
	|	TransportationTask.Ref.Posted
	|	AND TransportationTask.Ref.Status <> VALUE(Enum.StatusesOfTransportationJobs.Closed)
	|	AND TransportationTask.Ref = &TransportationJob";
	
	Query.SetParameter("TransportationJob", TransportationJob);
	
	Selection = Query.Execute().Select();
	
	RecordSet = InformationRegisters.GoodsToDeliver.CreateRecordSet();
	RecordSet.Filter.TransportationJob.Set(TransportationJob);
	While Selection.Next() Do
		FillPropertyValues(RecordSet.Add(), Selection);
	EndDo;
	RecordSet.Write();
	
EndProcedure

Function ChangesInCompositionOfOrders()
	
	Query = New Query();
	Query.Text = 
	"SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Weight AS Weight,
	|	References.VolumeM3 AS VolumeM3,
	|	References.Carrier AS Carrier,
	|	References.RecipientSender AS RecipientSender,
	|	References.TimeFrom AS TimeFrom,
	|	References.TimeTo AS TimeTo,
	|	References.Delivered AS Delivered,
	|	References.Warehouse AS Warehouse,
	|	References.DeliveredInFull AS DeliveredInFull,
	|	1 AS CountingField
	|INTO TUECurrentOrders
	|FROM
	|	&References AS References
	|
	|;
	|
	|SELECT
	|	TransportationTask.ReferenceOrder AS ReferenceOrder,
	|	TransportationTask.Weight AS Weight,
	|	TransportationTask.VolumeM3 AS VolumeM3,
	|	TransportationTask.Carrier AS Carrier,
	|	TransportationTask.RecipientSender AS RecipientSender,
	|	TransportationTask.TimeFrom AS TimeFrom,
	|	TransportationTask.TimeTo AS TimeTo,
	|	TransportationTask.Delivered AS Delivered,
	|	TransportationTask.Warehouse AS Warehouse,
	|	TransportationTask.DeliveredInFull AS DeliveredInFull,
	|	-1 AS CountingField
	|INTO TUEInitialOrders
	|FROM
	|	Document.TransportationJob.References AS TransportationTask
	|WHERE
	|	TransportationTask.Ref = &Ref
	|
	|;
	|SELECT
	|	References.RecipientSender AS Recipient,
	|	References.Warehouse AS Warehouse,
	|	SUM(References.CountingField) AS CountingField
	|FROM
	|	(SELECT
	|		References.ReferenceOrder AS ReferenceOrder,
	|		References.Weight AS Weight,
	|		References.VolumeM3 AS VolumeM3,
	|		References.Carrier AS Carrier,
	|		References.RecipientSender AS RecipientSender,
	|		References.TimeFrom AS TimeFrom,
	|		References.TimeTo AS TimeTo,
	|		References.Delivered AS Delivered,
	|		References.Warehouse AS Warehouse,
	|		References.DeliveredInFull AS DeliveredInFull,
	|		References.CountingField AS CountingField
	|	FROM
	|		TUECurrentOrders AS References
	|
	|	UNION ALL
	|	
	|	SELECT
	|		References.ReferenceOrder AS ReferenceOrder,
	|		References.Weight AS Weight,
	|		References.VolumeM3 AS VolumeM3,
	|		References.Carrier AS Carrier,
	|		References.RecipientSender AS RecipientSender,
	|		References.TimeFrom AS TimeFrom,
	|		References.TimeTo AS TimeTo,
	|		References.Delivered AS Delivered,
	|		References.Warehouse AS Warehouse,
	|		References.DeliveredInFull AS DeliveredInFull,
	|		References.CountingField AS CountingField
	|	FROM
	|		TUEInitialOrders AS References) AS References
	|
	|GROUP BY
	|	References.ReferenceOrder,
	|	References.Weight,
	|	References.VolumeM3,
	|	References.Carrier,
	|	References.RecipientSender,
	|	References.TimeFrom,
	|	References.TimeTo,
	|	References.Delivered,
	|	References.Warehouse,
	|	References.DeliveredInFull
	|
	|HAVING
	|	SUM(References.CountingField) <> 0";
	
	FieldList = "ReferenceOrder, Weight, VolumeM3, Carrier, RecipientSender, 
	|TimeFrom, TimeTo, Delivered, Warehouse, DeliveredInFull";
	Query.SetParameter("References", References.Unload(, FieldList));
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

#EndRegion

#EndRegion

#EndIf
