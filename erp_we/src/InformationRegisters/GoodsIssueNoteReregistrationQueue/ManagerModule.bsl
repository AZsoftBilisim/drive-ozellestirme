#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "InformationRegisters.GoodsIssueNoteReregistrationQueue.ProcessDataForMigrationToNewVersion";
	Handler.Version = "11.5.26.75";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("3c5d271c-8d12-431a-94da-ffe9746907f2");
	Handler.Multithreaded = True;
	Handler.UpdateDataFillingProcedure = "InformationRegisters.GoodsIssueNoteReregistrationQueue.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Order = Enums.OrderOfUpdateHandlers.Noncritical;
	Handler.Comment = NStr("vi = 'Đang cập nhật dữ liệu trong biểu ghi thông tin ""Trình tự tạo lại phiếu xuất kho"".';
							|ru = 'Обновляет данные в регистре сведений ""Очередь переоформления расходных ордеров"".';
							|en = 'Updates the data in the ""Goods issue note reregistration queue"" information register.'; fa = 'Updates the data in the ""Goods issue note reregistration queue"" information register.';
							|it = 'Updates the data in the ""Goods issue note reregistration queue"" information register.';
							|pl = 'Updates the data in the ""Goods issue note reregistration queue"" information register.';
							|tr = '""Ambar çıkış fişleri yeniden düzenleme kuyruğu"" bilgi kaydındaki verileri günceller.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Documents.TransportationJob.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.GoodsForIssue.FullName());
	ItemsToRead.Add(Metadata.AccumulationRegisters.ProductStock.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.StatesAndDetailsOfDelivery.FullName());
	ItemsToRead.Add(Metadata.InformationRegisters.GoodsToDeliver.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.InformationRegisters.GoodsIssueNoteReregistrationQueue.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.InformationRegisters.GoodsIssueNoteReregistrationQueue.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");
	
	Handler.ExecutionPriorities = InfobaseUpdate.HandlerExecutionPriorities();
	
EndProcedure

// Performs registration of data for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.GoodsIssueNoteReregistrationQueue.FullName();
	
	SelectionParameters = Parameters.SelectionParameters;
	SelectionParameters.FullRegistersNames = FullRegisterName;
	SelectionParameters.SelectionMethod = InfobaseUpdate.SelectionMethodOfIndependentInfoRegistryMeasurements();
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.Insert("FullRegisterName", FullRegisterName);
	AdditionalParameters.Insert("IsIndependentInformationRegister", True);
	
	GoodsIssueNoteGenerationMode = Constants.GoodsIssueNoteGenerationMode.Get();
	
	If GoodsIssueNoteGenerationMode = Enums.GoodsIssueNoteGenerationModes.Automatically Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	UpdatedData.Warehouse			AS Warehouse,
		|	UpdatedData.Recipient	AS Recipient
		|INTO DataForFilter
		|FROM
		|	InformationRegister.GoodsIssueNoteReregistrationQueue AS UpdatedData
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForShipmentTurnover.Warehouse			AS Warehouse,
		|	GoodsForShipmentTurnover.Recipient		AS Recipient,
		|	GoodsForShipmentTurnover.DocumentShipments	AS DocumentShipments,
		|	GoodsForShipmentTurnover.Products		AS Products,
		|	GoodsForShipmentTurnover.Characteristic	AS Characteristic,
		|	GoodsForShipmentTurnover.Purpose		AS Purpose,
		|	GoodsForShipmentTurnover.ControlledLotReference AS ControlledLotReference,
		|	GoodsForShipmentTurnover.Series			AS Series,
		|	SUM(CASE
		|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
		|			THEN -GoodsForShipmentTurnover.ToShipExpense
		|		ELSE CASE
		|				WHEN &IssueInvoicesFirst
		|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
		|				ELSE GoodsForShipmentTurnover.ToShipReceipt
		|			END
		|	END)									AS QuantityToShip,
		|	CASE
		|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
		|					(VALUE(Enum.TransportMethods.ToCustomer),
		|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
		|					)
		|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
		|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
		|						(VALUE(Enum.TransportMethods.ByCarrier),
		|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
		|						)
		|					)
		|			THEN TRUE
		|		ELSE FALSE
		|	END									AS ShipmentUnderTransportationJob
		|INTO GoodsForIssue
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			(Warehouse, Recipient) IN
		|					(SELECT
		|						DataForFilter.Warehouse,
		|						DataForFilter.Recipient
		|					FROM
		|						DataForFilter AS DataForFilter)
		|	) AS GoodsForShipmentTurnover
		|		LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
		|		ON StatesAndDetailsOfDelivery.Warehouse = GoodsForShipmentTurnover.Warehouse
		|			AND StatesAndDetailsOfDelivery.ReferenceOrder = GoodsForShipmentTurnover.DocumentShipments
		|
		|WHERE
		|	CASE
		|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
		|			THEN -GoodsForShipmentTurnover.ToShipExpense
		|		ELSE CASE
		|				WHEN &IssueInvoicesFirst
		|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
		|				ELSE GoodsForShipmentTurnover.ToShipReceipt
		|			END
		|	END <> 0
		|
		|GROUP BY
		|	GoodsForShipmentTurnover.Warehouse,
		|	GoodsForShipmentTurnover.Recipient,
		|	GoodsForShipmentTurnover.Products,
		|	GoodsForShipmentTurnover.DocumentShipments,
		|	GoodsForShipmentTurnover.Characteristic,
		|	GoodsForShipmentTurnover.Purpose,
		|	GoodsForShipmentTurnover.ControlledLotReference,
		|	GoodsForShipmentTurnover.Series,
		|	CASE
		|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
		|					(VALUE(Enum.TransportMethods.ToCustomer),
		|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
		|					)
		|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
		|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
		|						(VALUE(Enum.TransportMethods.ByCarrier),
		|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
		|						)
		|					)
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|
		|UNION ALL
		|
		|SELECT
		|	GoodsForShipmentTurnover.Warehouse					AS Warehouse,
		|	GoodsForShipmentTurnover.Recipient				AS Recipient,
		|	GoodsForShipmentTurnover.DocumentShipments			AS DocumentShipments,
		|	GoodsForShipmentTurnover.Products				AS Products,
		|	GoodsForShipmentTurnover.Characteristic			AS Characteristic,
		|	GoodsForShipmentTurnover.Purpose				AS Purpose,
		|	GoodsForShipmentTurnover.ControlledLotReference		AS ControlledLotReference,
		|	GoodsForShipmentTurnover.Series					AS Series,
		|	SUM(GoodsForShipmentTurnover.ToRegisterExpense)	AS QuantityToShip,
		|	CASE
		|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
		|					(VALUE(Enum.TransportMethods.ToCustomer),
		|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
		|					)
		|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
		|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
		|						(VALUE(Enum.TransportMethods.ByCarrier),
		|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
		|						)
		|					)
		|			THEN TRUE
		|		ELSE FALSE
		|	END											AS ShipmentUnderTransportationJob
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			(Warehouse, Recipient) IN
		|					(SELECT
		|						DataForFilter.Warehouse,
		|						DataForFilter.Recipient
		|					FROM
		|						DataForFilter AS DataForFilter)
		|	) AS GoodsForShipmentTurnover
		|		LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
		|		ON StatesAndDetailsOfDelivery.Warehouse = GoodsForShipmentTurnover.Warehouse
		|			AND StatesAndDetailsOfDelivery.ReferenceOrder = GoodsForShipmentTurnover.DocumentShipments
		|
		|WHERE
		|	&IssueInvoicesFirst
		|	AND GoodsForShipmentTurnover.ToRegisterExpense <> 0
		|
		|GROUP BY
		|	GoodsForShipmentTurnover.Warehouse,
		|	GoodsForShipmentTurnover.Recipient,
		|	GoodsForShipmentTurnover.Products,
		|	GoodsForShipmentTurnover.DocumentShipments,
		|	GoodsForShipmentTurnover.Characteristic,
		|	GoodsForShipmentTurnover.Purpose,
		|	GoodsForShipmentTurnover.ControlledLotReference,
		|	GoodsForShipmentTurnover.Series,
		|	CASE
		|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
		|					(VALUE(Enum.TransportMethods.ToCustomer),
		|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
		|					)
		|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
		|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
		|						(VALUE(Enum.TransportMethods.ByCarrier),
		|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
		|						)
		|					)
		|			THEN TRUE
		|		ELSE FALSE
		|	END
		|
		|INDEX BY
		|	Warehouse,
		|	DocumentShipments,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	ControlledLotReference,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssue.Warehouse				AS Warehouse,
		|	GoodsForIssue.Recipient			AS Recipient,
		|	GoodsForIssue.DocumentShipments	AS DocumentShipments,
		|	GoodsForIssue.Products		AS Products,
		|	GoodsForIssue.Characteristic		AS Characteristic,
		|	GoodsForIssue.Purpose			AS Purpose,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssue.Series				AS Series,
		|	GoodsForIssue.QuantityToShip	AS QuantityToShip,
		|	SUM(CASE
		|			WHEN NOT GoodsForIssue.ShipmentUnderTransportationJob
		|					OR GoodsToDeliver.AllGoods
		|				THEN GoodsForIssue.QuantityToShip
		|			ELSE CASE
		|					WHEN GoodsForIssue.QuantityToShip >= GoodsToDeliver.Count
		|						THEN GoodsToDeliver.Count
		|					ELSE GoodsForIssue.QuantityToShip
		|				END
		|		END)							AS Count
		|INTO GoodsForShipmentAndDelivery
		|FROM
		|	GoodsForIssue AS GoodsForIssue
		|		LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
		|		ON GoodsForIssue.DocumentShipments = GoodsToDeliver.ReferenceOrder
		|			AND GoodsForIssue.Warehouse = GoodsToDeliver.Warehouse
		|			AND (GoodsForIssue.Products = GoodsToDeliver.Products
		|					AND GoodsForIssue.Characteristic = GoodsToDeliver.Characteristic
		|					AND GoodsForIssue.Purpose = GoodsToDeliver.Purpose
		|					AND GoodsForIssue.Series = GoodsToDeliver.Series
		|				OR GoodsToDeliver.AllGoods)
		|			AND GoodsToDeliver.TransportationJob.Posted
		|			AND GoodsToDeliver.TransportationJob.Status <> VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated)
		|			AND GoodsForIssue.ShipmentUnderTransportationJob
		|WHERE
		|	NOT (GoodsForIssue.ShipmentUnderTransportationJob
		|		AND GoodsToDeliver.TransportationJob IS NULL)
		|
		|GROUP BY
		|	GoodsForIssue.Warehouse,
		|	GoodsForIssue.Recipient,
		|	GoodsForIssue.DocumentShipments,
		|	GoodsForIssue.Products,
		|	GoodsForIssue.Characteristic,
		|	GoodsForIssue.Purpose,
		|	GoodsForIssue.ControlledLotReference,
		|	GoodsForIssue.Series,
		|	GoodsForIssue.QuantityToShip
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssue.Warehouse				AS Warehouse,
		|	GoodsForIssue.Recipient			AS Recipient,
		|	GoodsForIssue.DocumentShipments	AS DocumentShipments,
		|	GoodsForIssue.Products		AS Products,
		|	GoodsForIssue.Characteristic		AS Characteristic,
		|	GoodsForIssue.Purpose			AS Purpose,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssue.Series				AS Series,
		|	GoodsForIssue.ToShipExpense		AS Count
		|INTO GoodsForIssueExpense
		|FROM
		|	AccumulationRegister.GoodsForIssue.Turnovers(
		|			,
		|			,
		|			,
		|			(Warehouse, Recipient) IN
		|					(SELECT
		|						DataForFilter.Warehouse,
		|						DataForFilter.Recipient
		|					FROM
		|						DataForFilter AS DataForFilter)
		|	) AS GoodsForIssue
		|
		|WHERE
		|	GoodsForIssue.ToShipExpense > 0
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssueBalance.Warehouse			AS Warehouse,
		|	GoodsForIssueBalance.Recipient		AS Recipient,
		|	GoodsForIssueBalance.DocumentShipments	AS DocumentShipments,
		|	GoodsForIssueBalance.Products		AS Products,
		|	GoodsForIssueBalance.Characteristic	AS Characteristic,
		|	GoodsForIssueBalance.Purpose		AS Purpose,
		|	GoodsForIssueBalance.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssueBalance.Series			AS Series,
		|	GoodsForIssueBalance.ForAssemblyBalance	AS ForAssemblyBalance,
		|	GoodsForIssueBalance.AssemblyInProgressBalance + GoodsForIssueBalance.AssembledBalance AS CollectedRemainderIsCollected
		|INTO GoodsBeingShipped
		|FROM
		|	AccumulationRegister.GoodsForIssue.Balance(
		|			,
		|			(Warehouse, Recipient) IN
		|					(SELECT
		|						DataForFilter.Warehouse,
		|						DataForFilter.Recipient
		|					FROM
		|						DataForFilter AS DataForFilter)
		|	) AS GoodsForIssueBalance
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	GoodsForIssueBalance.Warehouse			AS Warehouse,
		|	GoodsForIssueBalance.Recipient		AS Recipient,
		|	GoodsForIssueBalance.DocumentShipments	AS DocumentShipments,
		|	GoodsForIssueBalance.Products		AS Products,
		|	GoodsForIssueBalance.Characteristic	AS Characteristic,
		|	GoodsForIssueBalance.Purpose		AS Purpose,
		|	GoodsForIssueBalance.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssueBalance.Series			AS Series
		|INTO RemainingGoodsForShipment
		|FROM
		|	(SELECT
		|		GoodsForShipmentAndDelivery.Warehouse				AS Warehouse,
		|		GoodsForShipmentAndDelivery.Recipient			AS Recipient,
		|		GoodsForShipmentAndDelivery.DocumentShipments	AS DocumentShipments,
		|		GoodsForShipmentAndDelivery.Products		AS Products,
		|		GoodsForShipmentAndDelivery.Characteristic		AS Characteristic,
		|		GoodsForShipmentAndDelivery.Purpose			AS Purpose,
		|		GoodsForShipmentAndDelivery.ControlledLotReference AS ControlledLotReference,
		|		GoodsForShipmentAndDelivery.Series				AS Series,
		|		CASE
		|			WHEN GoodsForShipmentAndDelivery.Count < GoodsForShipmentAndDelivery.QuantityToShip
		|				THEN GoodsForShipmentAndDelivery.Count
		|			ELSE GoodsForShipmentAndDelivery.QuantityToShip
		|		END										AS ToShipReceipt,
		|		0											AS ToShipExpense,
		|		0											AS CollectedRemainderIsCollected,
		|		0											AS ForAssemblyBalance
		|	FROM
		|		GoodsForShipmentAndDelivery AS GoodsForShipmentAndDelivery
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsForIssueExpense.Warehouse,
		|		GoodsForIssueExpense.Recipient,
		|		GoodsForIssueExpense.DocumentShipments,
		|		GoodsForIssueExpense.Products,
		|		GoodsForIssueExpense.Characteristic,
		|		GoodsForIssueExpense.Purpose,
		|		GoodsForIssueExpense.ControlledLotReference,
		|		GoodsForIssueExpense.Series,
		|		0,
		|		GoodsForIssueExpense.Count,
		|		0,
		|		0
		|	FROM
		|		GoodsForIssueExpense AS GoodsForIssueExpense
		|	
		|	UNION ALL
		|	
		|	SELECT
		|		GoodsBeingShipped.Warehouse,
		|		GoodsBeingShipped.Recipient,
		|		GoodsBeingShipped.DocumentShipments,
		|		GoodsBeingShipped.Products,
		|		GoodsBeingShipped.Characteristic,
		|		GoodsBeingShipped.Purpose,
		|		GoodsBeingShipped.ControlledLotReference,
		|		GoodsBeingShipped.Series,
		|		0,
		|		0,
		|		GoodsBeingShipped.CollectedRemainderIsCollected,
		|		GoodsBeingShipped.ForAssemblyBalance
		|	FROM
		|		GoodsBeingShipped AS GoodsBeingShipped
		|	
		|	) AS GoodsForIssueBalance
		|
		|GROUP BY
		|	GoodsForIssueBalance.Warehouse,
		|	GoodsForIssueBalance.Recipient,
		|	GoodsForIssueBalance.DocumentShipments,
		|	GoodsForIssueBalance.Products,
		|	GoodsForIssueBalance.Characteristic,
		|	GoodsForIssueBalance.Purpose,
		|	GoodsForIssueBalance.ControlledLotReference,
		|	GoodsForIssueBalance.Series
		|
		|HAVING
		|	(SUM(GoodsForIssueBalance.ForAssemblyBalance) > 0
		|		AND SUM(GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected) < SUM(GoodsForIssueBalance.ForAssemblyBalance))
		|	OR SUM(GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected) > SUM(GoodsForIssueBalance.ForAssemblyBalance)
		|
		|INDEX BY
		|	Warehouse,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	ControlledLotReference,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsForIssue.Warehouse			AS Warehouse,
		|	GoodsForIssue.Products	AS Products,
		|	GoodsForIssue.Characteristic	AS Characteristic,
		|	GoodsForIssue.Purpose		AS Purpose,
		|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
		|	GoodsForIssue.Series			AS Series
		|INTO TableOfNomenclatureSelection
		|FROM
		|	RemainingGoodsForShipment AS GoodsForIssue
		|
		|INDEX BY
		|	Warehouse,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	ControlledLotReference,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ProductStock.Warehouse			AS Warehouse,
		|	ProductStock.Products	AS Products,
		|	ProductStock.Characteristic	AS Characteristic,
		|	ProductStock.Purpose		AS Purpose,
		|	ProductStock.ControlledLotReference AS ControlledLotReference,
		|	BalancesForShipment.Series			AS Series
		|INTO BalanceGoodsInWarehouses
		|FROM
		|	AccumulationRegister.ProductStock.Balance(
		|			,
		|			(Warehouse, Products, Characteristic, Purpose, ControlledLotReference) IN
		|					(SELECT DISTINCT
		|						BalancesForShipment.Warehouse,
		|						BalancesForShipment.Products,
		|						BalancesForShipment.Characteristic,
		|						BalancesForShipment.Purpose,
		|						BalancesForShipment.ControlledLotReference
		|					FROM
		|						TableOfNomenclatureSelection AS BalancesForShipment)
		|	) AS ProductStock
		|		INNER JOIN TableOfNomenclatureSelection AS BalancesForShipment
		|		ON ProductStock.Warehouse = BalancesForShipment.Warehouse
		|			AND ProductStock.Products = BalancesForShipment.Products
		|			AND ProductStock.Characteristic = BalancesForShipment.Characteristic
		|			AND ProductStock.Purpose = BalancesForShipment.Purpose
		|			AND ProductStock.ControlledLotReference = BalancesForShipment.ControlledLotReference
		|			AND (ProductStock.Series = BalancesForShipment.Series
		|				OR BalancesForShipment.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
		|
		|GROUP BY
		|	ProductStock.Warehouse,
		|	ProductStock.Products,
		|	ProductStock.Characteristic,
		|	ProductStock.Purpose,
		|	ProductStock.ControlledLotReference,
		|	BalancesForShipment.Series
		|
		|HAVING
		|	SUM(ProductStock.InStockBalance - ProductStock.ToShipBalance) > 0
		|
		|INDEX BY
		|	Warehouse,
		|	Products,
		|	Characteristic,
		|	Purpose,
		|	ControlledLotReference,
		|	Series
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	GoodsForIssue.Warehouse		AS Warehouse,
		|	GoodsForIssue.Recipient	AS Recipient
		|INTO NeedForOrders
		|FROM
		|	RemainingGoodsForShipment AS GoodsForIssue
		|		INNER JOIN BalanceGoodsInWarehouses AS ProductStock
		|		ON GoodsForIssue.Warehouse = ProductStock.Warehouse
		|			AND GoodsForIssue.Products = ProductStock.Products
		|			AND GoodsForIssue.Characteristic = ProductStock.Characteristic
		|			AND GoodsForIssue.Purpose = ProductStock.Purpose
		|			AND GoodsForIssue.ControlledLotReference = ProductStock.ControlledLotReference
		|			AND GoodsForIssue.Series = ProductStock.Series
		|
		|INDEX BY
		|	Warehouse,
		|	Recipient
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	DataForFilter.Warehouse			AS Warehouse,
		|	DataForFilter.Recipient	AS Recipient
		|FROM
		|	DataForFilter AS DataForFilter
		|		LEFT JOIN NeedForOrders AS NeedForOrders
		|		ON DataForFilter.Warehouse = NeedForOrders.Warehouse
		|			AND DataForFilter.Recipient = NeedForOrders.Recipient
		|WHERE
		|	NeedForOrders.Warehouse IS NULL";
		
		ProcedureForProcessingDocuments	= Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
		IssueInvoicesFirst	= 
			ProcedureForProcessingDocuments = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
		
		Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
		Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
			GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
		
		DataToBeUpdated = Query.Execute().Unload();
	Else
		RecordSetIsEmpty	= InformationRegisters.GoodsIssueNoteReregistrationQueue.CreateRecordSet();
		DataToBeUpdated	= RecordSetIsEmpty.UnloadColumns("Warehouse, Recipient");
	EndIf;
	
	InfobaseUpdate.MarkForProcessing(Parameters, DataToBeUpdated, AdditionalParameters);
	
EndProcedure

// Performs processing of data registered for updating.
//
// Parameters:
//	Parameters - See InfobaseUpdate.MainProcessingMarkParameters.
//
Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullRegisterName = Metadata.InformationRegisters.GoodsIssueNoteReregistrationQueue.FullName();
	
	If Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullRegisterName) Then
		Parameters.ProcessingCompleted = True;
		
		Return;
	EndIf;
	
	UpdatedData = InfobaseUpdate.DataToUpdateInMultithreadHandler(Parameters);
	
	If UpdatedData.Count() = 0 Then
		Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																							FullRegisterName);
		
		Return;
	EndIf;
	
	TempTableManager = New TempTablesManager;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "TTBlockedGoodsForShipment";
	
	InfobaseUpdate.CreateTemporaryTableOfLockedDimensionValues(
		Parameters.Queue, "AccumulationRegister.GoodsForIssue", "Warehouse", TempTableManager, AdditionalParameters);
	
	AdditionalParameters.TempTableName = "TTBlockedGoodsInWarehouses";
	
	InfobaseUpdate.CreateTemporaryTableOfLockedDimensionValues(
		Parameters.Queue, "AccumulationRegister.ProductStock", "Warehouse", TempTableManager, AdditionalParameters);
	
	Query = New Query;
	Query.TempTablesManager = TempTableManager;
	Query.Text =
	"SELECT
	|	UpdatedData.Warehouse			AS Warehouse,
	|	UpdatedData.Recipient	AS Recipient
	|INTO TTUpdatedData
	|FROM
	|	&UpdatedData AS UpdatedData
	|
	|INDEX BY
	|	Warehouse,
	|	Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Warehouse			AS Warehouse,
	|	UpdatedData.Recipient	AS Recipient
	|INTO DataForFilter
	|FROM
	|	TTUpdatedData AS UpdatedData
	|
	|WHERE
	|	NOT UpdatedData.Warehouse IN
	|			(SELECT
	|				TTLocked.Warehouse
	|			FROM
	|				TTBlockedGoodsForShipment AS TTLocked)
	|	AND NOT UpdatedData.Warehouse IN
	|			(SELECT
	|				TTLocked.Warehouse
	|			FROM
	|				TTBlockedGoodsInWarehouses AS TTLocked)
	|
	|INDEX BY
	|	Warehouse,
	|	Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForShipmentTurnover.Warehouse			AS Warehouse,
	|	GoodsForShipmentTurnover.Recipient		AS Recipient,
	|	GoodsForShipmentTurnover.DocumentShipments	AS DocumentShipments,
	|	GoodsForShipmentTurnover.Products		AS Products,
	|	GoodsForShipmentTurnover.Characteristic	AS Characteristic,
	|	GoodsForShipmentTurnover.Purpose		AS Purpose,
	|	GoodsForShipmentTurnover.ControlledLotReference AS ControlledLotReference,
	|	GoodsForShipmentTurnover.Series			AS Series,
	|	SUM(CASE
	|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
	|			THEN -GoodsForShipmentTurnover.ToShipExpense
	|		ELSE CASE
	|				WHEN &IssueInvoicesFirst
	|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
	|				ELSE GoodsForShipmentTurnover.ToShipReceipt
	|			END
	|	END)									AS QuantityToShip,
	|	CASE
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
	|					(VALUE(Enum.TransportMethods.ToCustomer),
	|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|					)
	|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
	|						(VALUE(Enum.TransportMethods.ByCarrier),
	|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
	|						)
	|					)
	|			THEN TRUE
	|		ELSE FALSE
	|	END									AS ShipmentUnderTransportationJob
	|INTO GoodsForIssue
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(Warehouse, Recipient) IN
	|					(SELECT
	|						DataForFilter.Warehouse,
	|						DataForFilter.Recipient
	|					FROM
	|						DataForFilter AS DataForFilter)
	|	) AS GoodsForShipmentTurnover
	|		LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON StatesAndDetailsOfDelivery.Warehouse = GoodsForShipmentTurnover.Warehouse
	|			AND StatesAndDetailsOfDelivery.ReferenceOrder = GoodsForShipmentTurnover.DocumentShipments
	|
	|WHERE
	|	CASE
	|		WHEN GoodsForShipmentTurnover.ToShipExpense < 0
	|			THEN -GoodsForShipmentTurnover.ToShipExpense
	|		ELSE CASE
	|				WHEN &IssueInvoicesFirst
	|					THEN GoodsForShipmentTurnover.ToShipReceipt - GoodsForShipmentTurnover.ToRegisterReceipt
	|				ELSE GoodsForShipmentTurnover.ToShipReceipt
	|			END
	|	END <> 0
	|
	|GROUP BY
	|	GoodsForShipmentTurnover.Warehouse,
	|	GoodsForShipmentTurnover.Recipient,
	|	GoodsForShipmentTurnover.Products,
	|	GoodsForShipmentTurnover.DocumentShipments,
	|	GoodsForShipmentTurnover.Characteristic,
	|	GoodsForShipmentTurnover.Purpose,
	|	GoodsForShipmentTurnover.ControlledLotReference,
	|	GoodsForShipmentTurnover.Series,
	|	CASE
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
	|					(VALUE(Enum.TransportMethods.ToCustomer),
	|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|					)
	|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
	|						(VALUE(Enum.TransportMethods.ByCarrier),
	|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
	|						)
	|					)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	GoodsForShipmentTurnover.Warehouse					AS Warehouse,
	|	GoodsForShipmentTurnover.Recipient				AS Recipient,
	|	GoodsForShipmentTurnover.DocumentShipments			AS DocumentShipments,
	|	GoodsForShipmentTurnover.Products				AS Products,
	|	GoodsForShipmentTurnover.Characteristic			AS Characteristic,
	|	GoodsForShipmentTurnover.Purpose				AS Purpose,
	|	GoodsForShipmentTurnover.ControlledLotReference		AS ControlledLotReference,
	|	GoodsForShipmentTurnover.Series					AS Series,
	|	SUM(GoodsForShipmentTurnover.ToRegisterExpense)	AS QuantityToShip,
	|	CASE
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
	|					(VALUE(Enum.TransportMethods.ToCustomer),
	|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|					)
	|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
	|						(VALUE(Enum.TransportMethods.ByCarrier),
	|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
	|						)
	|					)
	|			THEN TRUE
	|		ELSE FALSE
	|	END											AS ShipmentUnderTransportationJob
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(Warehouse, Recipient) IN
	|					(SELECT
	|						DataForFilter.Warehouse,
	|						DataForFilter.Recipient
	|					FROM
	|						DataForFilter AS DataForFilter)
	|	) AS GoodsForShipmentTurnover
	|		LEFT JOIN InformationRegister.StatesAndDetailsOfDelivery AS StatesAndDetailsOfDelivery
	|		ON StatesAndDetailsOfDelivery.Warehouse = GoodsForShipmentTurnover.Warehouse
	|			AND StatesAndDetailsOfDelivery.ReferenceOrder = GoodsForShipmentTurnover.DocumentShipments
	|
	|WHERE
	|	&IssueInvoicesFirst
	|	AND GoodsForShipmentTurnover.ToRegisterExpense <> 0
	|
	|GROUP BY
	|	GoodsForShipmentTurnover.Warehouse,
	|	GoodsForShipmentTurnover.Recipient,
	|	GoodsForShipmentTurnover.Products,
	|	GoodsForShipmentTurnover.DocumentShipments,
	|	GoodsForShipmentTurnover.Characteristic,
	|	GoodsForShipmentTurnover.Purpose,
	|	GoodsForShipmentTurnover.ControlledLotReference,
	|	GoodsForShipmentTurnover.Series,
	|	CASE
	|		WHEN StatesAndDetailsOfDelivery.DeliveryMethod IN
	|					(VALUE(Enum.TransportMethods.ToCustomer),
	|					VALUE(Enum.TransportMethods.ByCarrierToAddress)
	|					)
	|				OR (&UseTransportationJobsForDeliveryAccountingByCarriers
	|					AND StatesAndDetailsOfDelivery.DeliveryMethod IN
	|						(VALUE(Enum.TransportMethods.ByCarrier),
	|						VALUE(Enum.TransportMethods.ToCustomerIsDefinedByTransportationCompany)
	|						)
	|					)
	|			THEN TRUE
	|		ELSE FALSE
	|	END
	|
	|INDEX BY
	|	Warehouse,
	|	DocumentShipments,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Warehouse				AS Warehouse,
	|	GoodsForIssue.Recipient			AS Recipient,
	|	GoodsForIssue.DocumentShipments	AS DocumentShipments,
	|	GoodsForIssue.Products		AS Products,
	|	GoodsForIssue.Characteristic		AS Characteristic,
	|	GoodsForIssue.Purpose			AS Purpose,
	|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
	|	GoodsForIssue.Series				AS Series,
	|	GoodsForIssue.QuantityToShip	AS QuantityToShip,
	|	SUM(CASE
	|			WHEN NOT GoodsForIssue.ShipmentUnderTransportationJob
	|					OR GoodsToDeliver.AllGoods
	|				THEN GoodsForIssue.QuantityToShip
	|			ELSE CASE
	|					WHEN GoodsForIssue.QuantityToShip >= GoodsToDeliver.Count
	|						THEN GoodsToDeliver.Count
	|					ELSE GoodsForIssue.QuantityToShip
	|				END
	|		END)							AS Count
	|INTO GoodsForShipmentAndDelivery
	|FROM
	|	GoodsForIssue AS GoodsForIssue
	|		LEFT JOIN InformationRegister.GoodsToDeliver AS GoodsToDeliver
	|		ON GoodsForIssue.DocumentShipments = GoodsToDeliver.ReferenceOrder
	|			AND GoodsForIssue.Warehouse = GoodsToDeliver.Warehouse
	|			AND (GoodsForIssue.Products = GoodsToDeliver.Products
	|					AND GoodsForIssue.Characteristic = GoodsToDeliver.Characteristic
	|					AND GoodsForIssue.Purpose = GoodsToDeliver.Purpose
	|					AND GoodsForIssue.Series = GoodsToDeliver.Series
	|				OR GoodsToDeliver.AllGoods)
	|			AND GoodsToDeliver.TransportationJob.Posted
	|			AND GoodsToDeliver.TransportationJob.Status <> VALUE(Enum.StatusesOfTransportationJobs.BeingGenerated)
	|			AND GoodsForIssue.ShipmentUnderTransportationJob
	|WHERE
	|	NOT (GoodsForIssue.ShipmentUnderTransportationJob
	|		AND GoodsToDeliver.TransportationJob IS NULL)
	|
	|GROUP BY
	|	GoodsForIssue.Warehouse,
	|	GoodsForIssue.Recipient,
	|	GoodsForIssue.DocumentShipments,
	|	GoodsForIssue.Products,
	|	GoodsForIssue.Characteristic,
	|	GoodsForIssue.Purpose,
	|	GoodsForIssue.ControlledLotReference,
	|	GoodsForIssue.Series,
	|	GoodsForIssue.QuantityToShip
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssue.Warehouse				AS Warehouse,
	|	GoodsForIssue.Recipient			AS Recipient,
	|	GoodsForIssue.DocumentShipments	AS DocumentShipments,
	|	GoodsForIssue.Products		AS Products,
	|	GoodsForIssue.Characteristic		AS Characteristic,
	|	GoodsForIssue.Purpose			AS Purpose,
	|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
	|	GoodsForIssue.Series				AS Series,
	|	GoodsForIssue.ToShipExpense		AS Count
	|INTO GoodsForIssueExpense
	|FROM
	|	AccumulationRegister.GoodsForIssue.Turnovers(
	|			,
	|			,
	|			,
	|			(Warehouse, Recipient) IN
	|					(SELECT
	|						DataForFilter.Warehouse,
	|						DataForFilter.Recipient
	|					FROM
	|						DataForFilter AS DataForFilter)
	|	) AS GoodsForIssue
	|
	|WHERE
	|	GoodsForIssue.ToShipExpense > 0
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssueBalance.Warehouse			AS Warehouse,
	|	GoodsForIssueBalance.Recipient		AS Recipient,
	|	GoodsForIssueBalance.DocumentShipments	AS DocumentShipments,
	|	GoodsForIssueBalance.Products		AS Products,
	|	GoodsForIssueBalance.Characteristic	AS Characteristic,
	|	GoodsForIssueBalance.Purpose		AS Purpose,
	|	GoodsForIssueBalance.ControlledLotReference AS ControlledLotReference,
	|	GoodsForIssueBalance.Series			AS Series,
	|	GoodsForIssueBalance.ForAssemblyBalance	AS ForAssemblyBalance,
	|	GoodsForIssueBalance.AssemblyInProgressBalance + GoodsForIssueBalance.AssembledBalance AS CollectedRemainderIsCollected
	|INTO GoodsBeingShipped
	|FROM
	|	AccumulationRegister.GoodsForIssue.Balance(
	|			,
	|			(Warehouse, Recipient) IN
	|					(SELECT
	|						DataForFilter.Warehouse,
	|						DataForFilter.Recipient
	|					FROM
	|						DataForFilter AS DataForFilter)
	|	) AS GoodsForIssueBalance
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	GoodsForIssueBalance.Warehouse			AS Warehouse,
	|	GoodsForIssueBalance.Recipient		AS Recipient,
	|	GoodsForIssueBalance.DocumentShipments	AS DocumentShipments,
	|	GoodsForIssueBalance.Products		AS Products,
	|	GoodsForIssueBalance.Characteristic	AS Characteristic,
	|	GoodsForIssueBalance.Purpose		AS Purpose,
	|	GoodsForIssueBalance.ControlledLotReference AS ControlledLotReference,
	|	GoodsForIssueBalance.Series			AS Series
	|INTO RemainingGoodsForShipment
	|FROM
	|	(SELECT
	|		GoodsForShipmentAndDelivery.Warehouse				AS Warehouse,
	|		GoodsForShipmentAndDelivery.Recipient			AS Recipient,
	|		GoodsForShipmentAndDelivery.DocumentShipments	AS DocumentShipments,
	|		GoodsForShipmentAndDelivery.Products		AS Products,
	|		GoodsForShipmentAndDelivery.Characteristic		AS Characteristic,
	|		GoodsForShipmentAndDelivery.Purpose			AS Purpose,
	|		GoodsForShipmentAndDelivery.ControlledLotReference AS ControlledLotReference,
	|		GoodsForShipmentAndDelivery.Series				AS Series,
	|		CASE
	|			WHEN GoodsForShipmentAndDelivery.Count < GoodsForShipmentAndDelivery.QuantityToShip
	|				THEN GoodsForShipmentAndDelivery.Count
	|			ELSE GoodsForShipmentAndDelivery.QuantityToShip
	|		END										AS ToShipReceipt,
	|		0											AS ToShipExpense,
	|		0											AS CollectedRemainderIsCollected,
	|		0											AS ForAssemblyBalance
	|	FROM
	|		GoodsForShipmentAndDelivery AS GoodsForShipmentAndDelivery
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsForIssueExpense.Warehouse,
	|		GoodsForIssueExpense.Recipient,
	|		GoodsForIssueExpense.DocumentShipments,
	|		GoodsForIssueExpense.Products,
	|		GoodsForIssueExpense.Characteristic,
	|		GoodsForIssueExpense.Purpose,
	|		GoodsForIssueExpense.ControlledLotReference,
	|		GoodsForIssueExpense.Series,
	|		0,
	|		GoodsForIssueExpense.Count,
	|		0,
	|		0
	|	FROM
	|		GoodsForIssueExpense AS GoodsForIssueExpense
	|	
	|	UNION ALL
	|	
	|	SELECT
	|		GoodsBeingShipped.Warehouse,
	|		GoodsBeingShipped.Recipient,
	|		GoodsBeingShipped.DocumentShipments,
	|		GoodsBeingShipped.Products,
	|		GoodsBeingShipped.Characteristic,
	|		GoodsBeingShipped.Purpose,
	|		GoodsBeingShipped.ControlledLotReference,
	|		GoodsBeingShipped.Series,
	|		0,
	|		0,
	|		GoodsBeingShipped.CollectedRemainderIsCollected,
	|		GoodsBeingShipped.ForAssemblyBalance
	|	FROM
	|		GoodsBeingShipped AS GoodsBeingShipped
	|	
	|	) AS GoodsForIssueBalance
	|
	|GROUP BY
	|	GoodsForIssueBalance.Warehouse,
	|	GoodsForIssueBalance.Recipient,
	|	GoodsForIssueBalance.DocumentShipments,
	|	GoodsForIssueBalance.Products,
	|	GoodsForIssueBalance.Characteristic,
	|	GoodsForIssueBalance.Purpose,
	|	GoodsForIssueBalance.ControlledLotReference,
	|	GoodsForIssueBalance.Series
	|
	|HAVING
	|	(SUM(GoodsForIssueBalance.ForAssemblyBalance) > 0
	|		AND SUM(GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected) < SUM(GoodsForIssueBalance.ForAssemblyBalance))
	|	OR SUM(GoodsForIssueBalance.ToShipReceipt - GoodsForIssueBalance.ToShipExpense - GoodsForIssueBalance.CollectedRemainderIsCollected) > SUM(GoodsForIssueBalance.ForAssemblyBalance)
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsForIssue.Warehouse			AS Warehouse,
	|	GoodsForIssue.Products	AS Products,
	|	GoodsForIssue.Characteristic	AS Characteristic,
	|	GoodsForIssue.Purpose		AS Purpose,
	|	GoodsForIssue.ControlledLotReference AS ControlledLotReference,
	|	GoodsForIssue.Series			AS Series
	|INTO TableOfNomenclatureSelection
	|FROM
	|	RemainingGoodsForShipment AS GoodsForIssue
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ProductStock.Warehouse			AS Warehouse,
	|	ProductStock.Products	AS Products,
	|	ProductStock.Characteristic	AS Characteristic,
	|	ProductStock.Purpose		AS Purpose,
	|	ProductStock.ControlledLotReference AS ControlledLotReference,
	|	BalancesForShipment.Series			AS Series
	|INTO BalanceGoodsInWarehouses
	|FROM
	|	AccumulationRegister.ProductStock.Balance(
	|			,
	|			(Warehouse, Products, Characteristic, Purpose, ControlledLotReference) IN
	|					(SELECT DISTINCT
	|						BalancesForShipment.Warehouse,
	|						BalancesForShipment.Products,
	|						BalancesForShipment.Characteristic,
	|						BalancesForShipment.Purpose,
	|						BalancesForShipment.ControlledLotReference
	|					FROM
	|						TableOfNomenclatureSelection AS BalancesForShipment)
	|	) AS ProductStock
	|		INNER JOIN TableOfNomenclatureSelection AS BalancesForShipment
	|		ON ProductStock.Warehouse = BalancesForShipment.Warehouse
	|			AND ProductStock.Products = BalancesForShipment.Products
	|			AND ProductStock.Characteristic = BalancesForShipment.Characteristic
	|			AND ProductStock.Purpose = BalancesForShipment.Purpose
	|			AND ProductStock.ControlledLotReference = BalancesForShipment.ControlledLotReference
	|			AND (ProductStock.Series = BalancesForShipment.Series
	|				OR BalancesForShipment.Series = VALUE(Catalog.ItemsBatches.EmptyRef))
	|
	|GROUP BY
	|	ProductStock.Warehouse,
	|	ProductStock.Products,
	|	ProductStock.Characteristic,
	|	ProductStock.Purpose,
	|	ProductStock.ControlledLotReference,
	|	BalancesForShipment.Series
	|
	|HAVING
	|	SUM(ProductStock.InStockBalance - ProductStock.ToShipBalance) > 0
	|
	|INDEX BY
	|	Warehouse,
	|	Products,
	|	Characteristic,
	|	Purpose,
	|	ControlledLotReference,
	|	Series
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	GoodsForIssue.Warehouse		AS Warehouse,
	|	GoodsForIssue.Recipient	AS Recipient
	|INTO NeedForOrders
	|FROM
	|	RemainingGoodsForShipment AS GoodsForIssue
	|		INNER JOIN BalanceGoodsInWarehouses AS ProductStock
	|		ON GoodsForIssue.Warehouse = ProductStock.Warehouse
	|			AND GoodsForIssue.Products = ProductStock.Products
	|			AND GoodsForIssue.Characteristic = ProductStock.Characteristic
	|			AND GoodsForIssue.Purpose = ProductStock.Purpose
	|			AND GoodsForIssue.ControlledLotReference = ProductStock.ControlledLotReference
	|			AND GoodsForIssue.Series = ProductStock.Series
	|
	|INDEX BY
	|	Warehouse,
	|	Recipient
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DataForFilter.Warehouse			AS Warehouse,
	|	DataForFilter.Recipient	AS Recipient
	|FROM
	|	DataForFilter AS DataForFilter
	|		LEFT JOIN NeedForOrders AS NeedForOrders
	|		ON DataForFilter.Warehouse = NeedForOrders.Warehouse
	|			AND DataForFilter.Recipient = NeedForOrders.Recipient
	|WHERE
	|	NeedForOrders.Warehouse IS NULL
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	UpdatedData.Warehouse			AS Warehouse,
	|	UpdatedData.Recipient	AS Recipient
	|FROM
	|	TTUpdatedData AS UpdatedData
	|		INNER JOIN DataForFilter AS DataForFilter
	|		ON UpdatedData.Warehouse = DataForFilter.Warehouse
	|			AND UpdatedData.Recipient = DataForFilter.Recipient";
	
	ProcedureForProcessingDocuments	= Constants.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.Get();
	IssueInvoicesFirst	= 
		ProcedureForProcessingDocuments = Enums.ProcedureOfInvoiceAndGoodsIssueNoteRegistration.InvoicesFirst;
	
	Query.SetParameter("UpdatedData", UpdatedData);
	Query.SetParameter("IssueInvoicesFirst", IssueInvoicesFirst);
	Query.SetParameter("UseTransportationJobsForDeliveryAccountingByCarriers",
		GetFunctionalOption("UseTransportationJobsForDeliveryAccountingByCarriers"));
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingMarkParameters();
	AdditionalParameters.IsIndependentInformationRegister = True;
	AdditionalParameters.FullRegisterName = FullRegisterName;
	
	BeginTransaction();
	
	Try
		Block = New DataLock;
		
		LockItem = Block.Add(FullRegisterName);
		LockItem.DataSource = UpdatedData;
		LockItem.UseFromDataSource("Warehouse",		"Warehouse");
		LockItem.UseFromDataSource("Recipient",	"Recipient");
		
		LockItem = Block.Add("AccumulationRegister.GoodsForIssue");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("AccumulationRegister.ProductStock");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("InformationRegister.GoodsToDeliver");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("InformationRegister.StatesAndDetailsOfDelivery");
		LockItem.Mode = DataLockMode.Shared;
		
		LockItem = Block.Add("Document.TransportationJob");
		LockItem.Mode = DataLockMode.Shared;
		
		Block.Lock();
		
		QueryResult = Query.ExecuteBatch();
		DataToProcess	= QueryResult[QueryResult.UBound()].Unload();
		RecordsToDelete			= QueryResult[QueryResult.UBound() - 1];
		
		If Not RecordsToDelete.IsEmpty() Then
			RecordSet = CreateRecordSet();
			
			RecordSet.AdditionalProperties.Insert("RegisterAtExchangePlanNodesOnUpdateIB");
			RecordSet.DataExchange.Load = True;
			RecordSet.DataExchange.Recipients.AutoFill = False;
			
			RecordSet.Load(RecordsToDelete.Unload());
			RecordSet.Write(ReplacementMode.Delete);
		EndIf;
		
		InfobaseUpdate.MarkProcessingCompletion(DataToProcess, AdditionalParameters);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		MessageText = NStr("vi = 'Không thể cập nhật dữ liệu trong biểu ghi %1 do: %2';
							|ru = 'Не удалось обновить данные в регистре %1 по причине: %2';
							|en = 'Cannot update data in the %1 register due to: %2'; fa = 'Cannot update data in the %1 register due to: %2';
							|it = 'Cannot update data in the %1 register due to: %2';
							|pl = 'Cannot update data in the %1 register due to: %2';
							|tr = '%1 kaydındaki veriler şu nedenden dolayı güncellenemedi: %2'");
		MessageText = StrTemplate(MessageText,
									FullRegisterName,
									ErrorProcessing.DetailErrorDescription(ErrorInfo()));
		
		WriteLogEvent(InfobaseUpdate.EventLogEvent(),
									EventLogLevel.Warning,
									Metadata.InformationRegisters.GoodsIssueNoteReregistrationQueue,
									,
									MessageText);
	EndTry;
	
	Parameters.ProcessingCompleted = InfobaseUpdate.DataProcessingCompleted(Parameters.Queue,
																						FullRegisterName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf
