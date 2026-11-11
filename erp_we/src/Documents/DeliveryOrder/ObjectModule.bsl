// @strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure Filling(FillingData, FillingText, StandardProcessing)
	
	FillInDefaultAreaPoints = True;
	UpdateAdditionalParameters = False;
	FillInDataType = TypeOf(FillingData);
	
	If FillInDataType = Type("Structure") Then
		
		FillPropertyValues(ThisObject, FillingData);
		
		If FillingData.Property("AddressGoodsTable") Then
			
			GoodsTable = GetFromTempStorage(FillingData.AddressGoodsTable); // ValueTable
			Goods.Load(GoodsTable);
			
		EndIf;
		
		FillInDefaultAreaPoints = CommonClientServer.StructureProperty(
			FillingData, "FillInDefaultAreaPoints", True);
		UpdateAdditionalParameters = CommonClientServer.StructureProperty(
			FillingData, "UpdateAdditionalParameters", False);
		
	ElsIf FillInDataType = Type("DocumentRef.GoodsShipmentToCustomer") Then
		
		FillInBasedOnShipmentToCustomer(FillingData);
		
	ElsIf FillInDataType = Type("DocumentRef.CustomerInvoice") Then
		
		FillInBasedOnPTiY(FillingData);
	
	ElsIf FillInDataType = Type("DocumentRef.SalesOrder") Then
		
		FillInBasedOnCustomerSOrder(FillingData);
		
	EndIf;
	
	InitializeDocument(FillInDefaultAreaPoints, UpdateAdditionalParameters);
	
EndProcedure

Procedure FillCheckProcessing(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array; // Array of String
	
	If DeliveryMethod <> Enums.TransportMethods25.ByCarrier
	   And Not DeliveryToCarrier Then
		
		NotCheckedAttributeArray.Add("Carrier");
		
	EndIf;
	
	If DeliveryToCarrier Then
		
		NotCheckedAttributeArray.Add("DeliveryZone");
		
	Else
		
		NotCheckedAttributeArray.Add("CarrierDeliveryPoint");
		NotCheckedAttributeArray.Add("CarrierSDeliveryArea");
		
	EndIf;
	
	If DeliveryMethod = Enums.TransportMethods25.SelfPickup Then
		
		NotCheckedAttributeArray.Add("SenderDeparturePoint");
		NotCheckedAttributeArray.Add("DepartureArea");
		
		NotCheckedAttributeArray.Add("DeliveryPointRecipient");
		NotCheckedAttributeArray.Add("DeliveryZone");
		
	EndIf;
	
	If ValueIsFilled(DateOfShipment)
	   And DateOfShipment < BegOfDay(Date) Then
		
		MessageTemplate = NStr("vi = 'Ngày giao hàng %1 phải có ít nhất là ngày chứng từ %1';
								|ru = 'Дата отгрузки должна быть не меньше даты документа %1';
								|en = 'Shipment date must be not less than the document date (%1)'; fa = 'Shipment date must be not less than the document date (%1)';
								|it = 'Shipment date must be not less than the document date (%1)';
								|pl = 'Shipment date must be not less than the document date (%1)';
								|tr = 'Sevkiyat tarihi belge tarihi %1 ''den önce olmamalıdır'");
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			Format(Date, "DLF=DD"));
		
		Common.MessageToUser(MessageText,, "Object.DateOfShipment",, Cancel);
		
	EndIf;
	
	If Recipient = Carrier
		And Not Recipient.IsEmpty()
		And (DeliveryMethod = Enums.TransportMethods25.ByCarrier
			Or DeliveryToCarrier) Then
		
		MessageTemplate = NStr("vi = 'Thông tin của người nhận và người vận chuyển trùng nhau (%1), không thể lập vận chuyển.';
								|ru = 'Совпадают данные получателя и перевозчика (%1), оформление доставки невозможно.';
								|en = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.'; fa = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|it = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|pl = 'The details of the recipient and the carrier match (%1). Cannot register the delivery.';
								|tr = 'Alıcı ve taşıyıcı verileri (%1) eşleşiyor, teslimat oluşturma mümkün değil.'");
			
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(
			MessageTemplate,
			String(Recipient));
		
		Common.MessageToUser(
			MessageText,
			ThisObject,
			"Carrier",
			,
			Cancel);
		
	EndIf;
	
	QuantityVerificationParameters = ProductsServer.ParametersForCheckingFillingQuantity();
	ProductsServer.CheckQuantityFilling(ThisObject, CheckedAttributes, Cancel, QuantityVerificationParameters);
	
	ProductsServer.CheckWhetherCharacteristicsAreFilledIn(ThisObject, NotCheckedAttributeArray, Cancel);
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

Procedure BeforeWrite(Cancel, WriteMode, PostingMode)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	If DeliveryMethod <> Enums.TransportMethods25.OwnDelivery Then
		
		DeliveryToCarrier = False;
		
	EndIf;
	
	If DeliveryMethod <> Enums.TransportMethods25.ByCarrier
	   And Not DeliveryToCarrier Then
		
		Carrier = Catalogs.Partners.EmptyRef();
		
	EndIf;
	
	If Not SpecialTransportationConditions Then
		SpecialTransportationConditionsDescription = "";
	EndIf;
	
	If Not DeliveryToCarrier
		Or Not ValueIsFilled(Carrier) Then
		
		CarrierDeliveryPoint = Catalogs.DeliveryPoints.EmptyRef();
		CarrierSDeliveryArea = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	If DeliveryMethod = Enums.TransportMethods25.SelfPickup Then
		
		SenderDeparturePoint = Catalogs.DeliveryPoints.EmptyRef();
		DepartureArea = Catalogs.DeliveryZones.EmptyRef();
		
		DeliveryPointRecipient = Catalogs.DeliveryPoints.EmptyRef();
		DeliveryZone = Catalogs.DeliveryZones.EmptyRef();
		
	EndIf;
	
	GoodsLinesChangeOnlyPackaging = GoodsLinesChangeOnlyPackaging();
	AdditionalProperties.Insert("GoodsLinesChangeOnlyPackaging", GoodsLinesChangeOnlyPackaging);
	
	DocumentsPosting.BeforeWritingDocument(ThisObject, WriteMode, PostingMode);
	
EndProcedure

Procedure OnWrite(Cancel)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	DocumentsPosting.OnWriteDocument(ThisObject, Cancel);
	
EndProcedure

Procedure Posting(Cancel, PostingMode)
	
	DocumentsPosting.DocumentProcessing_(ThisObject, Cancel);
	
EndProcedure

Procedure UndoPosting(Cancel)
	
	DocumentsPosting.ProcessingOfDocumentDeletion(ThisObject, Cancel);
	
EndProcedure

#EndRegion

#Region Private

Procedure InitializeDocument(FillInDefaultAreaPoints, UpdateAdditionalParameters)
	
	EmployeeResponsible = Users.CurrentUser();
	Organization = SettingsValueCached.GetDefaultOrganization(Organization);
	DeliveryDirection = Enums.DeliveryDirections.PartnerWarehouse_;
	SenderSPointDataIsFilledIn = False;
	
	If Not ValueIsFilled(SenderDeparturePoint)
	   And FillInDefaultAreaPoints Then
		
		SenderSPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Sender);
		SenderDeparturePoint = SenderSPointData.DeliveryPoint;
		DepartureArea = SenderSPointData.DeliveryZone;
		SenderSPointDataIsFilledIn = True;
		
	EndIf;
	
	If Not ValueIsFilled(DepartureArea)
	   And ValueIsFilled(SenderDeparturePoint)
	   And Not SenderSPointDataIsFilledIn
	   And FillInDefaultAreaPoints Then
		
		DetailsOfPointOfDeparture = Common.ObjectAttributesValues(SenderDeparturePoint, "DeliveryZone");
		DepartureArea = DetailsOfPointOfDeparture.DeliveryZone;
		
	EndIf;
	
	If DeliveryPointRecipient.IsEmpty()
	   And FillInDefaultAreaPoints Then
		
		RecipientPointData = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Recipient);
		DeliveryPointRecipient = RecipientPointData.DeliveryPoint;
		
		If DeliveryZone.IsEmpty() Then
			
			DeliveryZone = RecipientPointData.DeliveryZone;
			
		EndIf;
		
	EndIf;
	
	If DeliveryMethod <> Enums.TransportMethods25.OwnDelivery Then
		
		DeliveryToCarrier = False;
		
	EndIf;
	
	If DeliveryToCarrier Then
		
		If CarrierDeliveryPoint.IsEmpty()
		   And FillInDefaultAreaPoints Then
			
			CarrierSDataPoints = Catalogs.DeliveryPoints.DeliveryPointInformationMain(Carrier);
			CarrierDeliveryPoint = CarrierSDataPoints.DeliveryPoint;
			
			If DeliveryZone.IsEmpty() Then
			
				DeliveryZone = CarrierSDataPoints.DeliveryZone;
			
			EndIf;
			
		EndIf;
		
	EndIf;
	
	If UpdateAdditionalParameters Then
		
		Documents.DeliveryOrder.UpdateAdditionalParameters(ThisObject, Goods);
		
	EndIf;
	
EndProcedure

// Parameters:
//  FillingData - DocumentRef.CustomerInvoice
//
Procedure FillInBasedOnPTiY(FillingData)
	
	QueryTextHeader =
	"SELECT
	|	CustomerInvoice.OrderSales AS OrderSales,
	|	CustomerInvoice.DeliveryIsRequired AS DeliveryIsRequired,
	|	CustomerInvoice.Warehouse.IsFolder AS GroupOfWarehouses,
	|	CustomerInvoice.DeliveryPlanning AS DeliveryPlanning,
	|	CustomerInvoice.Warehouse AS Sender,
	|	CustomerInvoice.Organization AS Organization,
	|	CustomerInvoice.DeliveryMethod25 AS DeliveryMethod,
	|	CustomerInvoice.Partner AS Recipient,
	|	CustomerInvoice.DeliveryPoint AS DeliveryPointRecipient,
	|	CustomerInvoice.DeliveryZone AS DeliveryZone,
	|	CustomerInvoice.DeliveryToCarrier AS DeliveryToCarrier,
	|	CustomerInvoice.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	CustomerInvoice.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	CustomerInvoice.CarrierPartner AS Carrier,
	|	CustomerInvoice.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	CustomerInvoice.DeliveryTimeTo AS DeliveryTimeTo,
	|	CustomerInvoice.Date AS DateOfShipment,
	|	CustomerInvoice.AdditionalDeliveryInformation AS AdditionalInformation,
	|	CustomerInvoice.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	CustomerInvoice.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|FROM
	|	Document.CustomerInvoice AS CustomerInvoice
	|WHERE
	|	CustomerInvoice.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	ImplementationOfWarehouseInformation.WarehousePoint AS SenderDeparturePoint,
	|	ImplementationOfWarehouseInformation.AreaOfWarehouse AS DepartureArea
	|FROM
	|	Document.CustomerInvoice.WarehousesDeliveryInformation AS ImplementationOfWarehouseInformation
	|WHERE
	|	ImplementationOfWarehouseInformation.Ref = &Ref
	|	AND ImplementationOfWarehouseInformation.Warehouse = ImplementationOfWarehouseInformation.Ref.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.RowCode AS DeliveryLineCode,
	|	DeliveryTurnover.Package AS Package,
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) AS Count
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder = &Ref
	|				AND Arm = 1) AS DeliveryTurnover
	|WHERE
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) > 0
	|
	|ORDER BY
	|	DeliveryLineCode";
	
	Query = New Query;
	Query.Text = QueryTextHeader;
	Query.SetParameter("Ref", FillingData);
	
	QueryResults = Query.ExecuteBatch();
	ResultHeader__ = QueryResults[0];
	ResultSender = QueryResults[1];
	ProductResult = QueryResults[2];
	
	Cancel = False;
	
	HeaderSelection = ResultHeader__.Select();
	HeaderSelection.Next();
	
	MessageTemplate = "";
	
	If HeaderSelection.GroupOfWarehouses Then
		
		MessageTemplate = NStr("vi = 'Trong chứng từ %1 đã chỉ định nhóm kho. Cấm nhập trên cơ sở.';
								|ru = 'В документе %1 указана группа складов. Ввод на основании запрещен.';
								|en = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|it = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|pl = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|tr = '%1 belgesinde ambar grubu belirtilmiş. Gerekçeye dayalı giriş yasaktır.'");
		Cancel = True;
		
	ElsIf HeaderSelection.OrderSales
			And GetFunctionalOption("UseAdvancedFeaturesOfSalesOrder") Then 
		
		MessageTemplate = NStr("vi = 'Chứng từ %1 được lập theo các lệnh. Cấm nhập trên cơ sở.';
								|ru = 'Документ %1 оформлен по распоряжениям. Ввод на основании запрещен.';
								|en = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.'; fa = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
								|it = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
								|pl = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
								|tr = '%1 belgesi talimatlara göre oluşturulmuş. Gerekçeye dayalı giriş yasaktır.'");
		Cancel = True;
		
	ElsIf Not HeaderSelection.DeliveryIsRequired Then 
		
		MessageTemplate = NStr("vi = 'Trong chứng từ %1 chưa thiết lập dấu hiệu ""Yêu cầu giao hàng"". Cấm nhập trên cơ sở.';
								|ru = 'В документе %1 не установлен признак ""Требуется доставка"". Ввод на основании запрещен.';
								|en = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|it = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|pl = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|tr = '%1 belgesinde ""Teslimat gerekiyor"" işareti ayarlanmamış. Gerekçeye dayalı giriş yasaktır.'");
		Cancel = True;
		
	ElsIf HeaderSelection.DeliveryPlanning <> Enums.DeliveryPlanningKinds.SeparateDocument Then 
		
		MessageTemplate = NStr("vi = 'Chứng từ %1 không cho phép lập kế hoạch giao hàng bằng chứng từ riêng. Cấm nhập trên cơ sở.';
								|ru = 'Документ %1 не предусматривает планирование доставки отдельным документом. Ввод на основании запрещен.';
								|en = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.'; fa = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|it = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|pl = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|tr = '%1 belgesi teslimat planlamasının ayrı bir belgeyle yapılmasını öngörmüyor. Gerekçeye dayalı giriş yasaktır.'");
		Cancel = True;
		
	EndIf;
	
	If Cancel Then
		
		BaseIsString = Common.SubjectString(FillingData);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, BaseIsString);
		
		Raise MessageText;
		
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderSelection);
	DeliveryDirection = Enums.DeliveryDirections.PartnerWarehouse_;
	
	SelectionSender = ResultSender.Select();
	If SelectionSender.Next() Then
		
		FillPropertyValues(ThisObject, SelectionSender);
		
	EndIf;
	
	SampleProducts_ = ProductResult.Select();
	While SampleProducts_.Next() Do
		
		LineProducts_ = Goods.Add();
		FillPropertyValues(LineProducts_, SampleProducts_);
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

// Parameters:
//  FillingData - DocumentRef.GoodsShipmentToCustomer
//
Procedure FillInBasedOnShipmentToCustomer(FillingData)
	
	ThereIsFix = DocumentCorrection.IsThereFixOrReverse(FillingData);
	If ThereIsFix Then
		
		MessageTemplate = NStr("vi = 'Trên cơ sở %1 đã nhập chứng từ điều chỉnh.
			|Đơn hàng giao hàng có thể nhập trên cơ sở chứng từ điều chỉnh gần nhất.';
			|ru = 'На основании %1 уже введен исправительный документ.
			|Заказ на доставку может быть введен только на основании последнего исправительного документа.';
			|en = 'The correction document is already entered using the %1 base document.
			|The delivery order can only be entered based on the last correction document.'; fa = 'The correction document is already entered using the %1 base document.
			|The delivery order can only be entered based on the last correction document.';
			|it = 'The correction document is already entered using the %1 base document.
			|The delivery order can only be entered based on the last correction document.';
			|pl = 'The correction document is already entered using the %1 base document.
			|The delivery order can only be entered based on the last correction document.';
			|tr = '%1 gerekçesiyle zaten bir düzeltme belgesi girilmiş. 
			|Satış siparişi yalnızca son düzeltme belgesi temel alınarak girilebilir.'");
		
		Cancel = True;
		
	Else
		
		HeaderData_ = HeaderDataOfShipmentDocument(FillingData);
		
		CheckResult = PossibilityOfInputBasedOnShipmentToCustomer(HeaderData_);
		
		MessageTemplate = CheckResult.MessageTemplate;
		Cancel = CheckResult.Cancel;
		
	EndIf;
	
	If Cancel Then
		
		BaseIsString = Common.SubjectString(FillingData);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, BaseIsString);
		
		Raise MessageText;
		
	EndIf;
	
	If HeaderData_.Patch Then
		
		CorrectedDocument = HeaderData_.CorrectedDocument;
		
	Else
		
		CorrectedDocument = FillingData;
		
	EndIf;
		
	QueryText = QueryTextForFillingInShipmentToCustomer();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("CurrentDocument", FillingData);
	Query.SetParameter("CorrectedDocument", CorrectedDocument);
	
	QueryResults = Query.ExecuteBatch();
	ResultSender = QueryResults[0];
	ProductResult = QueryResults[1];
	
	FillPropertyValues(ThisObject, HeaderData_);
	DeliveryDirection = Enums.DeliveryDirections.PartnerWarehouse_;
	
	SelectionSender = ResultSender.Select();
	If SelectionSender.Next() Then
		
		FillPropertyValues(ThisObject, SelectionSender);
		
	EndIf;
	
	SampleProducts_ = ProductResult.Select();
	While SampleProducts_.Next() Do
		
		LineProducts_ = Goods.Add();
		FillPropertyValues(LineProducts_, SampleProducts_);
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Function QueryTextForFillingInShipmentToCustomer()
	
	QueryText =
	"SELECT
	|	ShipmentInformationOfWarehouses.WarehousePoint AS SenderDeparturePoint,
	|	ShipmentInformationOfWarehouses.AreaOfWarehouse AS DepartureArea
	|FROM
	|	Document.GoodsShipmentToCustomer.WarehousesDeliveryInformation AS ShipmentInformationOfWarehouses
	|WHERE
	|	ShipmentInformationOfWarehouses.Ref = &CurrentDocument
	|	AND ShipmentInformationOfWarehouses.Warehouse = ShipmentInformationOfWarehouses.Ref.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.RowCode AS DeliveryLineCode,
	|	DeliveryTurnover.Package AS Package,
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) AS Count
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder = &CorrectedDocument
	|				AND Arm = 1) AS DeliveryTurnover
	|WHERE
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) > 0
	|
	|ORDER BY
	|	DeliveryLineCode";
	
	Return QueryText;
	
EndFunction

// Parameters:
//   DocumentShipments - DocumentRef.GoodsShipmentToCustomer -
//
// Returns:
//   QueryResultSelection:
//     * ShipmentByOrders - Boolean -
//     * OrderAsAProformaInvoice - Boolean -
//     * Patch - Boolean -
//     * CorrectedDocument - DocumentRef.GoodsShipmentToCustomer -
//     * DeliveryIsRequired - Boolean -
//     * GroupOfWarehouses - Boolean -
//     * DeliveryPlanning - EnumRef.DeliveryPlanningKinds -
//     * Sender - CatalogRef.Warehouses -
//     * Organization - CatalogRef.Companies -
//     * DeliveryMethod - EnumRef.TransportMethods -
//     * Recipient - CatalogRef.Partners -
//     * DeliveryPointRecipient - CatalogRef.DeliveryPoints -
//     * DeliveryZone - CatalogRef.DeliveryZones -
//     * DeliveryToCarrier - Boolean -
//     * CarrierDeliveryPoint - CatalogRef.DeliveryPoints -
//     * CarrierSDeliveryArea - CatalogRef.DeliveryZones -
//     * Carrier - CatalogRef.Partners -
//     * DeliveryTimeFrom - Date -
//     * DeliveryTimeTo - Date -
//     * DateOfShipment - Date -
//     * AdditionalInformation - String -
//     * SpecialTransportationConditions - Boolean -
//     * SpecialTransportationConditionsDescription - String -
//
Function HeaderDataOfShipmentDocument(DocumentShipments)
	
	QueryText =
	"SELECT
	|	GoodsShipmentToCustomer.ShipmentByOrders AS ShipmentByOrders,
	|	CASE
	|		WHEN GoodsShipmentToCustomer.ShipmentByOrders
	|			THEN CASE
	|				WHEN GoodsShipmentToCustomer.SalesOrder REFS Document.SalesOrder
	|					THEN CAST(GoodsShipmentToCustomer.SalesOrder AS Document.SalesOrder).ThisIsOrderAsInvoice
	|				WHEN GoodsShipmentToCustomer.SalesOrder REFS Document.RequestForReturnOfGoodsFromCustomer
	|					THEN CAST(GoodsShipmentToCustomer.SalesOrder AS Document.RequestForReturnOfGoodsFromCustomer).ThisIsOrderAsInvoice
	|				ELSE FALSE
	|			END
	|		ELSE FALSE
	|	END AS OrderAsAProformaInvoice,
	|	GoodsShipmentToCustomer.Patch AS Patch,
	|	GoodsShipmentToCustomer.CorrectedDocument AS CorrectedDocument,
	|	GoodsShipmentToCustomer.DeliveryIsRequired AS DeliveryIsRequired,
	|	GoodsShipmentToCustomer.Warehouse.IsFolder AS GroupOfWarehouses,
	|	GoodsShipmentToCustomer.DeliveryPlanning AS DeliveryPlanning,
	|	GoodsShipmentToCustomer.Warehouse AS Sender,
	|	GoodsShipmentToCustomer.Organization AS Organization,
	|	GoodsShipmentToCustomer.DeliveryMethod25 AS DeliveryMethod,
	|	GoodsShipmentToCustomer.Partner AS Recipient,
	|	GoodsShipmentToCustomer.DeliveryPoint AS DeliveryPointRecipient,
	|	GoodsShipmentToCustomer.DeliveryZone AS DeliveryZone,
	|	GoodsShipmentToCustomer.DeliveryToCarrier AS DeliveryToCarrier,
	|	GoodsShipmentToCustomer.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	GoodsShipmentToCustomer.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	GoodsShipmentToCustomer.CarrierPartner AS Carrier,
	|	GoodsShipmentToCustomer.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	GoodsShipmentToCustomer.DeliveryTimeTo AS DeliveryTimeTo,
	|	GoodsShipmentToCustomer.Date AS DateOfShipment,
	|	GoodsShipmentToCustomer.AdditionalDeliveryInformation AS AdditionalInformation,
	|	GoodsShipmentToCustomer.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	GoodsShipmentToCustomer.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|FROM
	|	Document.GoodsShipmentToCustomer AS GoodsShipmentToCustomer
	|WHERE
	|	GoodsShipmentToCustomer.Ref = &DocumentShipments";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("DocumentShipments", DocumentShipments);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection;
	
EndFunction

Function PossibilityOfInputBasedOnShipmentToCustomer(HeaderData_)
	
	Result = New Structure;
	Result.Insert("Cancel", False);
	Result.Insert("MessageTemplate", "");
	
	If HeaderData_.GroupOfWarehouses Then
		
		Result.MessageTemplate = NStr("vi = 'Trong chứng từ %1 đã chỉ định nhóm kho. Cấm nhập trên cơ sở.';
										|ru = 'В документе %1 указана группа складов. Ввод на основании запрещен.';
										|en = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
										|it = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
										|pl = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
										|tr = '%1 belgesinde ambar grubu belirtilmiş. Temele dayalı girişe izin verilmiyor.'");
		Result.Cancel = True;
		
	ElsIf HeaderData_.ShipmentByOrders 
			And Not HeaderData_.OrderAsAProformaInvoice Then 
		
		Result.MessageTemplate = NStr("vi = 'Chứng từ %1 được lập theo các lệnh. Cấm nhập trên cơ sở.';
										|ru = 'Документ %1 оформлен по распоряжениям. Ввод на основании запрещен.';
										|en = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.'; fa = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
										|it = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
										|pl = 'The ""%1"" document is created based on references. Generation from such base document is not allowed.';
										|tr = '%1 belgesi talimatlara göre oluşturulmuş. Temele dayalı girişe izin verilmiyor.'");
		Result.Cancel = True;
		
	ElsIf Not HeaderData_.DeliveryIsRequired Then 
		
		Result.MessageTemplate = NStr("vi = 'Trong chứng từ %1 chưa thiết lập dấu hiệu ""Yêu cầu giao hàng"". Cấm nhập trên cơ sở.';
										|ru = 'В документе %1 не установлен признак ""Требуется доставка"". Ввод на основании запрещен.';
										|en = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
										|it = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
										|pl = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
										|tr = '%1 belgesinde ""Teslimat gerekiyor"" işareti ayarlanmamış. Temele dayalı girişe izin verilmiyor.'");
		Result.Cancel = True;
		
	ElsIf HeaderData_.DeliveryPlanning <> Enums.DeliveryPlanningKinds.SeparateDocument Then 
		
		Result.MessageTemplate = NStr("vi = 'Chứng từ %1 không cho phép lập kế hoạch giao hàng bằng chứng từ riêng. Cấm nhập trên cơ sở.';
										|ru = 'Документ %1 не предусматривает планирование доставки отдельным документом. Ввод на основании запрещен.';
										|en = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.'; fa = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
										|it = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
										|pl = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
										|tr = '%1 belgesi teslimat planlamasının ayrı bir belgeyle yapılmasını öngörmüyor. Temele dayalı girişe izin verilmiyor.'");
		Result.Cancel = True;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Parameters:
//  FillingData - DocumentRef.SalesOrder
//
Procedure FillInBasedOnCustomerSOrder(FillingData)
	
	QueryText = QueryTextForFillingInAccordingToClientSOrder();
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Ref", FillingData);
	
	QueryResults = Query.ExecuteBatch();
	ResultHeader__ = QueryResults[0];
	ResultSender = QueryResults[1];
	ProductResult = QueryResults[2];
	ResultShipmentDate = QueryResults[3];
	
	Cancel = False;
	
	HeaderSelection = ResultHeader__.Select();
	HeaderSelection.Next();
	
	MessageTemplate = "";
	
	If HeaderSelection.GroupOfWarehouses Then
		
		MessageTemplate = NStr("vi = 'Trong chứng từ %1 đã chỉ định nhóm kho. Cấm nhập trên cơ sở.';
								|ru = 'В документе %1 указана группа складов. Ввод на основании запрещен.';
								|en = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|it = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|pl = 'A warehouse group is specified in the ""%1"" document. Generation from such base document is not allowed.';
								|tr = '%1 belgesinde ambar grubu belirtilmiş. Temele dayalı girişe izin verilmiyor.'");
		Cancel = True;
		
	ElsIf HeaderSelection.DeliverySpecificationMethod = Enums.DeliverySpecificationMethods.ByRows Then 
		
		MessageTemplate = NStr("vi = 'Trong chứng từ %1, việc giao hàng được cấu hình theo từng dòng. Cấm nhập trên cơ sở.';
								|ru = 'В документе %1 доставка настраивается построчно. Ввод на основании запрещен.';
								|en = 'In the ""%1"" document, delivery is configured line by line. Generation from such base document is not allowed.'; fa = 'In the ""%1"" document, delivery is configured line by line. Generation from such base document is not allowed.';
								|it = 'In the ""%1"" document, delivery is configured line by line. Generation from such base document is not allowed.';
								|pl = 'In the ""%1"" document, delivery is configured line by line. Generation from such base document is not allowed.';
								|tr = '%1 belgesinde teslimat satır satır ayarlanıyor. Temele dayalı girişe izin verilmiyor.'");
		Cancel = True;
		
	ElsIf Not HeaderSelection.DeliveryIsRequired Then 
		
		MessageTemplate = NStr("vi = 'Trong chứng từ %1 chưa thiết lập dấu hiệu ""Yêu cầu giao hàng"". Cấm nhập trên cơ sở.';
								|ru = 'В документе %1 не установлен признак ""Требуется доставка"". Ввод на основании запрещен.';
								|en = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.'; fa = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|it = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|pl = 'The ""Delivery is required"" checkbox is not selected in the ""%1"" document. Generation from such base document is not allowed.';
								|tr = '%1 belgesinde ""Teslimat gerekiyor"" işareti ayarlanmamış. Temele dayalı girişe izin verilmiyor.'");
		Cancel = True;
		
	ElsIf HeaderSelection.DeliveryPlanning <> Enums.DeliveryPlanningKinds.SeparateDocument Then 
		
		MessageTemplate = NStr("vi = 'Chứng từ %1 không cho phép lập kế hoạch giao hàng bằng chứng từ riêng. Cấm nhập trên cơ sở.';
								|ru = 'Документ %1 не предусматривает планирование доставки отдельным документом. Ввод на основании запрещен.';
								|en = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.'; fa = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|it = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|pl = 'The ""%1"" document does not provide for delivery planning in a separate document. Generation from such base document is not allowed.';
								|tr = '%1 belgesi teslimat planlamasının ayrı bir belgeyle yapılmasını öngörmüyor. Temele dayalı girişe izin verilmiyor.'");
		Cancel = True;
		
	EndIf;
	
	If Cancel Then
		
		BaseIsString = Common.SubjectString(FillingData);
		MessageText = StringFunctionsClientServer.SubstituteParametersToString(MessageTemplate, BaseIsString);
		
		Raise MessageText;
		
	EndIf;
	
	FillPropertyValues(ThisObject, HeaderSelection);
	DeliveryDirection = Enums.DeliveryDirections.PartnerWarehouse_;
	
	SelectionSender = ResultSender.Select();
	If SelectionSender.Next() Then
		
		FillPropertyValues(ThisObject, SelectionSender);
		
	EndIf;
	
	SampleShipmentDate = ResultShipmentDate.Select();
	If SampleShipmentDate.Count() = 1
	   And SampleShipmentDate.Next() Then
		
		DateOfShipment = SampleShipmentDate.DateOfShipment;
		
	EndIf;
	
	SampleProducts_ = ProductResult.Select();
	While SampleProducts_.Next() Do
		
		LineProducts_ = Goods.Add();
		FillPropertyValues(LineProducts_, SampleProducts_);
		
	EndDo;
	
	StructureOfActions = New Structure;
	StructureOfActions.Insert("RecalculateNumberOfPackages");
	
	BatchProcessingOfTablePartServer.TreatTS(Goods, StructureOfActions);
	
EndProcedure

Function QueryTextForFillingInAccordingToClientSOrder()
	
	QueryText =
	"SELECT
	|	SalesOrder.DeliveryIsRequired AS DeliveryIsRequired,
	|	SalesOrder.Warehouse.IsFolder AS GroupOfWarehouses,
	|	SalesOrder.DeliveryPlanning AS DeliveryPlanning,
	|	SalesOrder.DeliverySpecificationMethod AS DeliverySpecificationMethod,
	|	SalesOrder.Warehouse AS Sender,
	|	SalesOrder.Organization AS Organization,
	|	SalesOrder.DeliveryMethod25 AS DeliveryMethod,
	|	SalesOrder.Partner AS Recipient,
	|	SalesOrder.DeliveryPoint AS DeliveryPointRecipient,
	|	SalesOrder.DeliveryZone AS DeliveryZone,
	|	SalesOrder.DeliveryToCarrier AS DeliveryToCarrier,
	|	SalesOrder.CarrierDeliveryPoint AS CarrierDeliveryPoint,
	|	SalesOrder.CarrierSDeliveryArea AS CarrierSDeliveryArea,
	|	SalesOrder.CarrierPartner AS Carrier,
	|	SalesOrder.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	SalesOrder.DeliveryTimeTo AS DeliveryTimeTo,
	|	SalesOrder.AdditionalDeliveryInformation AS AdditionalInformation,
	|	SalesOrder.SpecialTransportationConditions AS SpecialTransportationConditions,
	|	SalesOrder.SpecialTransportationConditionsDescription AS SpecialTransportationConditionsDescription
	|FROM
	|	Document.SalesOrder AS SalesOrder
	|WHERE
	|	SalesOrder.Ref = &Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SalesOrderDetailsOfWarehouses.WarehousePoint AS SenderDeparturePoint,
	|	SalesOrderDetailsOfWarehouses.AreaOfWarehouse AS DepartureArea
	|FROM
	|	Document.SalesOrder.WarehousesDeliveryInformation AS SalesOrderDetailsOfWarehouses
	|WHERE
	|	SalesOrderDetailsOfWarehouses.Ref = &Ref
	|	AND SalesOrderDetailsOfWarehouses.Warehouse = SalesOrderDetailsOfWarehouses.Ref.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DeliveryTurnover.Products AS Products,
	|	DeliveryTurnover.Characteristic AS Characteristic,
	|	DeliveryTurnover.Series AS Series,
	|	DeliveryTurnover.ReferenceOrder AS ReferenceOrder,
	|	DeliveryTurnover.RowCode AS DeliveryLineCode,
	|	DeliveryTurnover.Package AS Package,
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) AS Count
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder = &Ref
	|				AND Arm = 1) AS DeliveryTurnover
	|WHERE
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) > 0
	|
	|ORDER BY
	|	DeliveryLineCode
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 2
	|	DeliveryTurnover.DateOfShipment AS DateOfShipment
	|FROM
	|	AccumulationRegister.Delivery.Turnovers(
	|			,
	|			,
	|			,
	|			ReferenceOrder = &Ref
	|				AND Arm = 1) AS DeliveryTurnover
	|WHERE
	|	(DeliveryTurnover.ToDeliverTurnover - DeliveryTurnover.ToTripTurnover) > 0";
	
	Return QueryText;
	
EndFunction

// Returns:
//  ValueTable - Product lines for which only the packaging units or quantity have changed:
//   * ReferenceOrder - DefinedType.DeliveryReferenceOrder25
//   * DeliveryLineCode - Number
//
Function GoodsLinesChangeOnlyPackaging()
	
	GoodsLinesChangePackaging = New ValueTable();
	GoodsLinesChangePackaging.Columns.Add("ReferenceOrder", Metadata.DefinedTypes.DeliveryReferenceOrder25.Type);
	GoodsLinesChangePackaging.Columns.Add("DeliveryLineCode", Common.TypeDescriptionNumber(10, 0));
	
	If Not IsNew() Then
		
		Query = New Query;
		Query.Text =
		"SELECT
		|	DeliveryOrderGoods.ReferenceOrder AS ReferenceOrder,
		|	DeliveryOrderGoods.DeliveryLineCode AS DeliveryLineCode,
		|	DeliveryOrderGoods.Package AS Package
		|FROM
		|	Document.DeliveryOrder.Goods AS DeliveryOrderGoods
		|		INNER JOIN Document.DeliveryOrder AS DeliveryOrder
		|		ON DeliveryOrderGoods.Ref = DeliveryOrder.Ref
		|WHERE
		|	DeliveryOrder.Ref = &Ref
		|	AND DeliveryOrder.DateOfShipment = &DateOfShipment
		|	AND DeliveryOrder.DeliveryMethod = &DeliveryMethod
		|	AND DeliveryOrder.Sender = &Sender
		|	AND DeliveryOrder.SenderDeparturePoint = &SenderDeparturePoint
		|	AND DeliveryOrder.DepartureArea = &DepartureArea
		|	AND DeliveryOrder.Recipient = &Recipient
		|	AND DeliveryOrder.DeliveryPointRecipient = &DeliveryPointRecipient
		|	AND DeliveryOrder.DeliveryZone = &DeliveryZone
		|	AND DeliveryOrder.DeliveryToCarrier = &DeliveryToCarrier
		|	AND DeliveryOrder.CarrierDeliveryPoint = &CarrierDeliveryPoint
		|	AND DeliveryOrder.Carrier = &Carrier
		|	AND DeliveryOrder.CarrierSDeliveryArea = &CarrierSDeliveryArea";
		
		Query.SetParameter("Ref", Ref);
		Query.SetParameter("DateOfShipment", DateOfShipment);
		Query.SetParameter("DeliveryMethod", DeliveryMethod);
		Query.SetParameter("Sender", Sender);
		Query.SetParameter("SenderDeparturePoint", SenderDeparturePoint);
		Query.SetParameter("DepartureArea", DepartureArea);
		Query.SetParameter("Recipient", Recipient);
		Query.SetParameter("DeliveryPointRecipient", DeliveryPointRecipient);
		Query.SetParameter("DeliveryZone", DeliveryZone);
		Query.SetParameter("DeliveryToCarrier", DeliveryToCarrier);
		Query.SetParameter("CarrierDeliveryPoint", CarrierDeliveryPoint);
		Query.SetParameter("Carrier", Carrier);
		Query.SetParameter("CarrierSDeliveryArea", CarrierSDeliveryArea);
		
		PreviousLines = Query.Execute().Unload();
		
		RowFilter = New Structure;
		RowFilter.Insert("ReferenceOrder", Undefined);
		RowFilter.Insert("DeliveryLineCode", 0);
		
		For Each PreviousString In PreviousLines Do
			
			FillPropertyValues(RowFilter, PreviousString);
			CurLines_ = Goods.FindRows(RowFilter);
			If CurLines_.Count() = 0 Then
				Continue;
			EndIf;
			
			CurrentRow = CurLines_[0];
			If CurrentRow.Package <> PreviousString.Package Then
				
				StringPackingChange = GoodsLinesChangePackaging.Add();
				FillPropertyValues(StringPackingChange, CurrentRow);
				
			EndIf;
			
		EndDo;
		
		GoodsLinesChangePackaging.GroupBy("ReferenceOrder, DeliveryLineCode");
		
	EndIf;
	
	Return GoodsLinesChangePackaging;
	
EndFunction

#EndRegion

#EndIf