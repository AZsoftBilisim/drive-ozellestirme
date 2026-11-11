#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Private

#Region Formationquery

Function QueryResultBasedOnReportData(StructureOfReportGeneration)
	
	StructureOfReportGeneration.Insert("ThereAreAppealsToRegistersCalculationsOnDocumentsClients",    False);
	StructureOfReportGeneration.Insert("ThereAreAppealsToRegistersCalculationsOnDocuments", False);
	StructureOfReportGeneration.Insert("TypesOfObjectsToCheckForAccess",                       New Array);
	StructureOfReportGeneration.Insert("NewCalculationArchitectureIsUsed",                 GetFunctionalOption("NewOnlineARAPAccounting"));
	
	Query = New Query();
	QueryText = "";
	TemporaryTable = New TempTablesManager;
	ReportDate = CurrentSessionDate();
	QueryText = QueryText + QueryTextByFilter(Query, StructureOfReportGeneration);
	RequestTextByEventType = RequestTextDataByEventType(Query, StructureOfReportGeneration);
	QueryText = QueryText
		+ StructureOfReportGeneration.TextQueriesTemporaryTables
		+ Chars.LF
		+ RequestTextByEventType;
	QueryText = QueryText + QueryTextResultingFrom(StructureOfReportGeneration);
	SetRequestParameterValues(Query,StructureOfReportGeneration);
	Query.TempTablesManager = TemporaryTable;
	Query.Text = QueryText;
	
	SetPrivilegedMode(True);
	If StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients 
		And Not StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		ARAPAccountingServer.CalculateCustomerSOperationalPaymentDates(TemporaryTable, ReportDate);
	EndIf;
	If StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocuments
		And Not StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		ARAPAccountingServer.CalculateSupplierSOperationalPaymentDates(TemporaryTable, ReportDate);
	EndIf;
	Query.Execute();
	SetPrivilegedMode(False);
	
	Return RequestResultWithAccessRights(Query, StructureOfReportGeneration);
	
EndFunction

Function RequestResultWithAccessRights(Query, StructureOfReportGeneration)

	QueryTextAccessRights = "
	|SELECT DISTINCT ALLOWED
	|	EventsWithoutPermission.ReferenceToEventObject AS ReferenceToEventObject
	|	INTO AvailableEventObjects
	|FROM EventsWithoutPermission AS EventsWithoutPermission
	|	INNER JOIN &ObjectTable AS ObjectTable
	|	ON EventsWithoutPermission.ReferenceToEventObject = ObjectTable.Ref
	|";
	
	QueryText = "";
	Counter = 1;
	
	For Each ArrayElement In StructureOfReportGeneration.TypesOfObjectsToCheckForAccess Do
		
		RequestTextForMetadataObject = QueryTextAccessRights;
		
		If Counter <> 1 Then

			TextUnion = "
			|UNION ALL 
			|
			|SELECT"; // @query-part
			
			RequestTextForMetadataObject = StrReplace(QueryTextAccessRights,"SELECT DISTINCT ALLOWED",TextUnion); //@Query-part
			RequestTextForMetadataObject = StrReplace(RequestTextForMetadataObject,"INTO AvailableEventObjects","");
			
		EndIf;
		
		RequestTextForMetadataObject = StrReplace(RequestTextForMetadataObject,"&ObjectTable",ArrayElement);
		
		QueryText = QueryText + RequestTextForMetadataObject;
		
		Counter = Counter + 1;
		
	EndDo;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	EventsWithoutPermission.ReferenceToEventObject,
	|	EventsWithoutPermission.SubjectOf,
	|	EventsWithoutPermission.EventType,
	|	EventsWithoutPermission.DateOfEventObject AS DateOfEventObject,
	|	EventsWithoutPermission.EventDate AS EventDate,
	|	EventsWithoutPermission.Status AS Status,
	|	EventsWithoutPermission.EmployeeResponsible AS EmployeeResponsible,
	|	EventsWithoutPermission.Partner AS Partner,
	|	EventsWithoutPermission.LongDesc AS LongDesc,
	|	EventsWithoutPermission.AdditionalDetailsDescription1 AS AdditionalDetailsDescription1,
	|	EventsWithoutPermission.AdditionalPropsDescription2 AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN EventsWithoutPermission.Status = &Upcoming
	|			THEN 3
	|		WHEN EventsWithoutPermission.Status = &CurrentBusinessUnit
	|			THEN 2
	|		ELSE 1
	|	END AS StatusOrder_1,
	|	EventsWithoutPermission.CalculationsAreIrrelevantWithClient AS CalculationsAreIrrelevantWithClient,
	|	EventsWithoutPermission.CalculationsAreIrrelevantWithSupplier AS CalculationsAreIrrelevantWithSupplier
	|FROM
	|	AvailableEventObjects AS AvailableEventObjects
	|	INNER JOIN EventsWithoutPermission AS EventsWithoutPermission
	|	ON EventsWithoutPermission.ReferenceToEventObject = AvailableEventObjects.ReferenceToEventObject
	|
	|ORDER BY
	|	StatusOrder_1,
	|	EventDate ASC
	|
	|TOTALS 
	|	COUNT(DateOfEventObject)
	|BY
	|	Status,
	|	EventDate";
	
	Query.Text = QueryText;
	Return Query.Execute();

EndFunction

Procedure SetRequestParameterValues(Query,StructureOfReportGeneration)
	
	Query.SetParameter("Upcoming", "Upcoming");
	Query.SetParameter("CurrentBusinessUnit", "CurrentBusinessUnit");
	Query.SetParameter("Overdue", "Overdue");
	Query.SetParameter("CurrentDate", CurrentSessionDate());
	Query.SetParameter("EndDate", EndDateOfFormationPeriod(StructureOfReportGeneration.FormationPeriod));
	
	Query.SetParameter("SalesOrderApproval",NStr("vi = 'Thống nhất đơn hàng của khách';
												|ru = 'Согласовать заказ клиента';
												|en = 'Approve sales order'; fa = 'تأیید سفارش فروش';
												|it = 'Concordare l''ordine del cliente';
												|pl = 'Uzgodnij zamówienie klienta';
												|tr = 'İstemci siparişinin onayla'"));
	Query.SetParameter("WaitingForPaymentBeforeSecuring",NStr("vi = 'Nhận thanh toán trước khi đảm bảo';
																|ru = 'Получить оплату до обеспечения';
																|en = 'Receive payment before supply'; fa = 'Receive payment before supply';
																|it = 'Ricevere il pagamento prima dell''approvvigionamento';
																|pl = 'Odbierz płatność do zapewnienia';
																|tr = 'Tedarik öncesi ödemeyi al'"));
	Query.SetParameter("RequiresSupply",NStr("vi = 'Cung cấp';
											|ru = 'Обеспечить';
											|en = 'Supply'; fa = 'Supply';
											|it = 'Approvvigionare';
											|pl = 'Supply';
											|tr = 'Sağla'"));
	Query.SetParameter("WaitingForPrepaymentBeforeShipment",NStr("vi = 'Nhận trả trước trước khi giao hàng';
																|ru = 'Получить предоплату до отгрузки';
																|en = 'Receive prepayment before shipment'; fa = 'Receive prepayment before shipment';
																|it = 'Ricevere il prepagamento prima della spedizione';
																|pl = 'Otrzymać przedpłatę przed wysyłką';
																|tr = 'Ödemeyi sevkiyattan önce al'"));
	Query.SetParameter("PreparationForShipment",NStr("vi = 'Chuẩn bị giao hàng';
													|ru = 'Подготовить отгрузку';
													|en = 'Prepare shipment'; fa = 'Prepare shipment';
													|it = 'Preparare la spedizione';
													|pl = 'Przygotuj wysyłkę';
													|tr = 'Sevkiyatı hazırla'"));
	Query.SetParameter("Shipment",NStr("vi = 'Vận chuyển';
										|ru = 'Отгрузить';
										|en = 'Ship'; fa = 'ارسال';
										|it = 'Da spedire';
										|pl = 'Ship';
										|tr = 'Sevk et'"));
	Query.SetParameter("WaitingForPaymentAfterShipment",NStr("vi = 'Nhận thanh toán sau khi giao hàng';
															|ru = 'Получить оплату после отгрузки';
															|en = 'Receive payment after shipment'; fa = 'Receive payment after shipment';
															|it = 'Ricevere il pagamento dopo la spedizione';
															|pl = 'Otrzymaj płatność po wysyłce';
															|tr = 'Ödemeyi sevkiyat sonrası al'"));
	Query.SetParameter("ClosingOrder",NStr("vi = 'Đóng đơn hàng';
											|ru = 'Закрыть заказ';
											|en = 'Close order'; fa = 'بستن سفارش';
											|it = 'Chiudi l''ordine';
											|pl = 'Zamknij zamówienie';
											|tr = 'Siparişi kapat'"));
	Query.SetParameter("MonitorOrderClosing", GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompletePayment") 
						Or GetFunctionalOption("DoNotCloseSalesOrdersWithoutCompleteShipment"));
	
	Query.SetParameter("SupplierOrderApproval",NStr("vi = 'Thống nhất đơn hàng đặt nhà cung cấp';
													|ru = 'Согласовать заказ поставщику';
													|en = 'Approve purchase order'; fa = 'Approve purchase order';
													|it = 'Concordare l''ordine al fornitore';
													|pl = 'Uzgodnij zamówienie dostawcy';
													|tr = 'Satın alma siparişini onayla'"));
	Query.SetParameter("MakeAdvancePaymentBeforeConfirmation",NStr("vi = 'Nhập thanh toán trước khi xác nhận';
																	|ru = 'Внести оплату до подтверждения';
																	|en = 'Deposit a payment before confirmation'; fa = 'Deposit a payment before confirmation';
																	|it = 'Effettuare il pagamento prima della conferma';
																	|pl = 'Dokonaj płatności przed potwierdzeniem';
																	|tr = 'Ödemeyi onaydan önce gir'"));
	Query.SetParameter("OrderConfirmation",NStr("vi = 'Nhận xác nhận đơn hàng';
												|ru = 'Получить подтверждение заказа';
												|en = 'Receive order confirmation'; fa = 'Receive order confirmation';
												|it = 'Ricevere la conferma d''ordine';
												|pl = 'Uzyskaj potwierdzenie zamówienia';
												|tr = 'Sipariş onayını al'"));
	Query.SetParameter("MakingAdvancePaymentBeforeShipment",NStr("vi = 'Nhập ứng trước trước khi tiếp nhận';
																|ru = 'Внести предоплату до поступления';
																|en = 'Deposit prepayment before receipt'; fa = 'Deposit prepayment before receipt';
																|it = 'Effettuare il prepagamento prima dell''arrivo';
																|pl = 'Dokonaj przedpłaty przed otrzymaniem';
																|tr = 'Ön ödemeyi tahsilattan önce gir'"));
	Query.SetParameter("PreparationForAdmission",NStr("vi = 'Chuẩn bị tiếp nhận';
														|ru = 'Подготовить поступление';
														|en = 'Prepare receipt'; fa = 'Prepare receipt';
														|it = 'Preparare l''arrivo';
														|pl = 'Przygotuj otrzymanie';
														|tr = 'Tahsilatı hazırla'"));
	Query.SetParameter("ReceivingOrder",NStr("vi = 'Nhận đơn hàng';
											|ru = 'Получить заказ';
											|en = 'Get order'; fa = 'Get order';
											|it = 'Ricevere l''ordine';
											|pl = 'Otrzymaj zamówienie';
											|tr = 'Sipariş al'"));
	Query.SetParameter("PaymentAfterReceipt",NStr("vi = 'Thanh toán sau khi tiếp nhận';
													|ru = 'Оплатить после поступления';
													|en = 'Pay after receipt'; fa = 'Pay after receipt';
													|it = 'Pagare dopo l''arrivo';
													|pl = 'Zapłacić po otrzymaniu';
													|tr = 'Tahsilattan sonra öde'"));
	Query.SetParameter("ClosingOrderToSupplier",NStr("vi = 'Đóng đơn hàng đặt nhà cung cấp';
													|ru = 'Закрыть заказ поставщику';
													|en = 'Close purchase order'; fa = 'Close purchase order';
													|it = 'Chiudere l''ordine di acquisto al fornitore';
													|pl = 'Zamknij zamówienie dla dostawcy';
													|tr = 'Satın alma siparişini kapat'"));
	Query.SetParameter("NotUsePurchaseOrderStatuses", Not GetFunctionalOption("UsePurchaseOrderStatuses"));
	Query.SetParameter("Payment", NStr("vi = 'Thanh toán';
										|ru = 'Оплатить';
										|en = 'Pay'; fa = 'پرداخت';
										|it = 'Pagare';
										|pl = 'Pay';
										|tr = 'Öde'"));
	
	Query.SetParameter("ApprovalOfRefundRequest",NStr("vi = 'Thống nhất giấy đề nghị trả lại hàng';
														|ru = 'Согласовать заявку на возврат';
														|en = 'Approve return request'; fa = 'Approve return request';
														|it = 'Concordare la richiesta di reso';
														|pl = 'Uzgodnić wniosek o zwrot';
														|tr = 'İade başvurusunu onayla'"));
	Query.SetParameter("MakingRequestForRefund",NStr("vi = 'Lập chứng từ nhận hàng bán bị trả lại';
													|ru = 'Оформить возврат от клиента';
													|en = 'Register return from the customer'; fa = 'Register return from the customer';
													|it = 'Formalizzare il reso dal cliente';
													|pl = 'Sporządź zwrot od klienta';
													|tr = 'İstemciden iadeyi düzenle'"));
	Query.SetParameter("WaitingForPaymentBeforeSecuringRefundRequest",NStr("vi = 'Nhận thanh toán trước khi đảm bảo';
																			|ru = 'Получить оплату до обеспечения';
																			|en = 'Receive payment before supply'; fa = 'Receive payment before supply';
																			|it = 'Ricevere il pagamento prima dell''approvvigionamento';
																			|pl = 'Odbierz płatność do zapewnienia';
																			|tr = 'Tedarik öncesi ödemeyi al'"));
	Query.SetParameter("WaitingForPrepaymentBeforeShipmentRequestForRefund",NStr("vi = 'Nhận trả trước trước khi giao hàng để thay thế';
																				|ru = 'Получить предоплату до отгрузки по замене';
																				|en = 'Receive prepayment before shipment for replacement'; fa = 'Receive prepayment before shipment for replacement';
																				|it = 'Ricevere il prepagamento prima della spedizione della sostituzione';
																				|pl = 'Uzyskaj przedpłatę przed wysyłką do wymiany';
																				|tr = 'Yedek sevkiyatından önce ön ödeme al'"));
	Query.SetParameter("PreparationForShipmentRequestForReturn",NStr("vi = 'Chuẩn bị giao hàng thay thế';
																	|ru = 'Подготовить отгрузку замены';
																	|en = 'Prepare replacement shipment'; fa = 'Prepare replacement shipment';
																	|it = 'Preparare la spedizione della sostituzione';
																	|pl = 'Przygotować przesyłkę wymiany';
																	|tr = 'Yedek sevkiyatı hazırla'"));
	Query.SetParameter("ShipmentReturnRequest",NStr("vi = 'Giao hàng thay thế';
													|ru = 'Отгрузить замену';
													|en = 'Ship replacement'; fa = 'Ship replacement';
													|it = 'Spedire la sostituzione';
													|pl = 'Dokonać przesyłki wymiany';
													|tr = 'Yedek sevk et'"));
	Query.SetParameter("WaitingForPaymentAfterShipmentRequestForRefund",NStr("vi = 'Nhận thanh toán sau khi giao hàng để thay thế';
																			|ru = 'Получить оплату после отгрузки по замене';
																			|en = 'Receive payment after shipment for replacement'; fa = 'Receive payment after shipment for replacement';
																			|it = 'Ricevere il pagamento dopo la spedizione della sostituzione';
																			|pl = 'Otrzymać płatność po wysyłce po wymianie';
																			|tr = 'Yedek sevkiyatından sonra ödeme al'"));
	Query.SetParameter("MarkWhenRefundRequestWasCompleted",NStr("vi = 'Đánh dấu thực hiện';
																|ru = 'Отметить выполнение';
																|en = 'Mark as completed'; fa = 'علامت‌گذاری به‌عنوان تکمیل‌شده';
																|it = 'Segnare completamento';
																|pl = 'Zaznacz wykonanie';
																|tr = 'Gerçekleştirmeyi işaretle'"));
	Query.SetParameter("ReceivingPayment", NStr("vi = 'Nhận thanh toán';
												|ru = 'Получить оплату';
												|en = 'Receive payment'; fa = 'Receive payment';
												|it = 'Ricevere il pagamento';
												|pl = 'Otrzymać zapłatę';
												|tr = 'Ödemeyi al'"));
	
	Query.SetParameter("ControlShipmentByImplementation",NStr("vi = 'Kiểm soát giao hàng';
																|ru = 'Проконтролировать отгрузку';
																|en = 'Monitor shipment'; fa = 'Monitor shipment';
																|it = 'Controllare la spedizione';
																|pl = 'Sprawdź wysyłkę';
																|tr = 'Sevkiyatı kontrol et'"));
	Query.SetParameter("SwitchToShippedStatus",NStr("vi = 'Chuyển sang trạng thái ""Đã triển khai""';
													|ru = 'Перевести в статус ""Реализовано""';
													|en = 'Transfer to status ""Sold""'; fa = 'Transfer to status ""Sold""';
													|it = 'Assegnare lo stato ""Venduto""';
													|pl = 'Przekaż w status ""Zrealizowane""';
													|tr = '""Uygulandı"" durumuna transfer et'"));
	Query.SetParameter("GetPaidForSales",NStr("vi = 'Nhận thanh toán';
												|ru = 'Получить оплату';
												|en = 'Receive payment'; fa = 'Receive payment';
												|it = 'Ricevere il pagamento';
												|pl = 'Otrzymać zapłatę';
												|tr = 'Ödemeyi al'"));
EndProcedure

Function EndDateOfFormationPeriod(FormationPeriod)

	SecondsPerDay = 24*60*60;
	CurrentSessionDate = CurrentSessionDate();
	
	If FormationPeriod = "Today" Then
		
		Return BegOfDay(CurrentSessionDate + SecondsPerDay);
		
	ElsIf FormationPeriod = "ThreeDaysAhead" Then
		
		Return BegOfDay(CurrentSessionDate + 3 * SecondsPerDay);
		
	ElsIf FormationPeriod = "WeekInAdvance" Then
		
		Return BegOfDay(CurrentSessionDate + 7 * SecondsPerDay);
		
	ElsIf FormationPeriod ="MonthInAdvance" Then
		
		Return BegOfDay(AddMonth(CurrentSessionDate,1) + SecondsPerDay);
		
	ElsIf FormationPeriod = "MonthInAdvance" Then
		
		Return BegOfDay(AddMonth(CurrentSessionDate,3) + SecondsPerDay);
		
	ElsIf FormationPeriod = "HalfYearAhead" Then
		
		Return BegOfDay(AddMonth(CurrentSessionDate,6) + SecondsPerDay);
		
	ElsIf FormationPeriod = "YearAhead" Then
		
		Return BegOfDay(AddMonth(CurrentSessionDate,12) + SecondsPerDay);
		
	EndIf;
	
	Return Date(1,1,1);

EndFunction

Function QueryTextByFilter(Query, StructureOfReportGeneration)
	
	QueryText = "";
	ConditionTextForUsers = "";
	
	SchemeForFilter = GetTemplate("SchemeFilters");
	
	TemplateComposer = New DataCompositionTemplateComposer();
	DataCompositionTemplate = TemplateComposer.Execute(SchemeForFilter, SettingsComposer.GetSettings(),,,Type("DataCompositionValueCollectionTemplateGenerator"));
	
	If DataCompositionTemplate.ParameterValues.Count() <> 1 Then
		
		QueryText = DataCompositionTemplate.DataSets.FilterForSpecifiedUsers.Query;
		
		For Each Parameter In DataCompositionTemplate.ParameterValues Do
			Query.Parameters.Insert(Parameter.Name, Parameter.Value);
		EndDo;
		
		QueryText = QueryText +"
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|";
		
		FoundItemFROM = StrFind(QueryText,"FROM");
		If FoundItemFROM <> 0 Then
			QueryText = Left(QueryText,FoundItemFROM - 1) + "  INTO FilterForSpecifiedUsers
			|  " + Right(QueryText,StrLen(QueryText) - FoundItemFROM + 1);
			
		EndIf;
		
		ConditionTextForUsers = " IN 
		|	(SELECT
		|		FilterForSpecifiedUsers.User
		|	FROM
		|		FilterForSpecifiedUsers AS FilterForSpecifiedUsers)";
		
	EndIf;
	
	StructureOfReportGeneration.Insert("ConditionTextForUsers",ConditionTextForUsers);

	Return QueryText;
	
EndFunction

Function QueryTextResultingFrom(StructureOfReportGeneration)
	
	QueryText = "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////";
		
	For Indus = 1 To StructureOfReportGeneration.CurSubqueryNumberByEventType Do
		
		SubqueryByEventType = "
		|SELECT
		|	TableName.ReferenceToEventObject,
		|	TableName.SubjectOf,
		|	TableName.EventType,
		|	TableName.DateOfEventObject AS DateOfEventObject,
		|	TableName.EventDate AS EventDate,
		|	TableName.Status AS Status,
		|	TableName.EmployeeResponsible AS EmployeeResponsible,
		|	TableName.Partner AS Partner,
		|	TableName.LongDesc AS LongDesc,
		|	TableName.AdditionalDetailsDescription1 AS AdditionalDetailsDescription1,
		|	TableName.AdditionalPropsDescription2 AS AdditionalPropsDescription2
		|INTO Events
		|FROM
		|	TableName AS TableName";
		
		TextTable = "DataByEventType" + String(Indus);
		
		If Indus <> 1 Then
		
			SubqueryByEventType = "
			|
			|UNION ALL
			|" + SubqueryByEventType;
			
			SubqueryByEventType = StrReplace(SubqueryByEventType,"INTO Events","");
			
		EndIf;
		
		SubqueryByEventType = StrReplace(SubqueryByEventType,  "TableName", TextTable);
		
		QueryText = QueryText + SubqueryByEventType;
		
	EndDo;
	
	If Not StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients And Not StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocuments Then
		
		QueryText = QueryText + "
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Events.ReferenceToEventObject,
		|	Events.SubjectOf,
		|	Events.EventType,
		|	Events.DateOfEventObject AS DateOfEventObject,
		|	Events.EventDate AS EventDate,
		|	Events.Status AS Status,
		|	Events.EmployeeResponsible AS EmployeeResponsible,
		|	Events.Partner AS Partner,
		|	Events.LongDesc AS LongDesc,
		|	Events.AdditionalDetailsDescription1 AS AdditionalDetailsDescription1,
		|	Events.AdditionalPropsDescription2 AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN Events.Status = &Upcoming
		|			THEN 3
		|		WHEN Events.Status = &CurrentBusinessUnit
		|			THEN 2
		|		ELSE 1
		|	END AS StatusOrder_1,
		|	FALSE AS CalculationsAreIrrelevantWithClient,
		|	FALSE AS CalculationsAreIrrelevantWithSupplier
		|INTO EventsWithoutPermission
		|FROM
		|	Events AS Events";
		
	Else
		
		If StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients Then
			
			QueryText = QueryText + "
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	Events.Partner
			|INTO PartnersAndClients
			|FROM
			|	Events AS Events
			|WHERE
			|	(Events.EventType = &ClosingOrder
			|			OR Events.EventType = &WaitingForPaymentAfterShipment
			|			OR Events.EventType = &PreparationForShipment
			|			OR Events.EventType = &WaitingForPrepaymentBeforeShipment
			|			OR Events.EventType = &GetPaidForSales
			|			OR Events.EventType = &WaitingForPaymentBeforeSecuringRefundRequest
			|			OR Events.EventType = &WaitingForPrepaymentBeforeShipmentRequestForRefund
			|			OR Events.EventType = &PreparationForShipmentRequestForReturn
			|			OR Events.EventType = &WaitingForPaymentAfterShipmentRequestForRefund
			|			OR Events.EventType = &MarkWhenRefundRequestWasCompleted
			|			OR Events.EventType = &WaitingForPaymentBeforeSecuring)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	AccountingDimensionByPartners.DimensionKey
			|INTO SelectingPartnerAnalytics
			|FROM
			|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
			|WHERE
			|	AccountingDimensionByPartners.Partner IN
			|			(SELECT
			|				PartnersCalculations.Partner
			|			FROM
			|				PartnersAndClients AS PartnersCalculations)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	Jobs.AccountingDimensionByPartners.Partner AS Partner
			|INTO PartnersSettlementsWithClientsAreIrrelevant
			|FROM
			|	InformationRegister.JobsForAllocatingCustomersARAP AS Jobs
			|WHERE
			|	Jobs.Month <= &EndDate
			|	AND Jobs.Document <> UNDEFINED
			|	AND Jobs.AccountingDimensionByPartners IN
			|			(SELECT
			|				SelectingPartnerAnalytics.DimensionKey
			|			FROM
			|				SelectingPartnerAnalytics AS SelectingPartnerAnalytics)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		Else
			
			QueryText = QueryText + "
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|
			|SELECT
			|	VALUE(Catalog.Partners.EmptyRef) AS Partner
			|INTO PartnersSettlementsWithClientsAreIrrelevant
			|WHERE
			|	FALSE
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
		If StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocuments Then
			
			QueryText = QueryText + "
			|SELECT DISTINCT
			|	Events.Partner
			|INTO PartnersAndSuppliers
			|FROM
			|	Events AS Events
			|WHERE
			|	(Events.EventType = &MakeAdvancePaymentBeforeConfirmation
			|			OR Events.EventType = &OrderConfirmation
			|			OR Events.EventType = &MakingAdvancePaymentBeforeShipment
			|			OR Events.EventType = &PreparationForAdmission
			|			OR Events.EventType = &PaymentAfterReceipt
			|			OR Events.EventType = &ClosingOrderToSupplier)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	AccountingDimensionByPartners.DimensionKey
			|INTO SelectionOfPartnerAnalyticsSuppliers
			|FROM
			|	InformationRegister.AccountingDimensionByPartners AS AccountingDimensionByPartners
			|WHERE
			|	AccountingDimensionByPartners.Partner IN
			|			(SELECT
			|				PartnersCalculations.Partner
			|			FROM
			|				PartnersAndSuppliers AS PartnersCalculations)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT ALLOWED DISTINCT
			|	Jobs.AccountingDimensionByPartners.Partner AS Partner
			|INTO PartnersSettlementsWithSuppliersAreIrrelevant
			|FROM
			|	InformationRegister.JobsForAllocatingVendorsARAP AS Jobs
			|WHERE
			|	Jobs.Month <= &EndDate
			|	AND Jobs.Document <> UNDEFINED
			|	AND Jobs.AccountingDimensionByPartners IN
			|			(SELECT
			|				SelectingPartnerAnalytics.DimensionKey
			|			FROM
			|				SelectionOfPartnerAnalyticsSuppliers AS SelectingPartnerAnalytics)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|"
			
		Else
			
			QueryText = QueryText + "
			|
			|SELECT
			|	VALUE(Catalog.Partners.EmptyRef) AS Partner
			|INTO PartnersSettlementsWithSuppliersAreIrrelevant
			|WHERE
			|	FALSE
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|";
			
		EndIf;
		
		QueryText = QueryText + "
		|SELECT
		|	Events.ReferenceToEventObject,
		|	Events.SubjectOf,
		|	Events.EventType,
		|	Events.DateOfEventObject AS DateOfEventObject,
		|	Events.EventDate AS EventDate,
		|	Events.Status AS Status,
		|	Events.EmployeeResponsible AS EmployeeResponsible,
		|	Events.Partner AS Partner,
		|	Events.LongDesc AS LongDesc,
		|	Events.AdditionalDetailsDescription1 AS AdditionalDetailsDescription1,
		|	Events.AdditionalPropsDescription2 AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN Events.Status = &Upcoming
		|			THEN 3
		|		WHEN Events.Status = &CurrentBusinessUnit
		|			THEN 2
		|		ELSE 1
		|	END AS StatusOrder_1,
		|	CASE
		|		WHEN PartnersSettlementsWithClientsAreIrrelevant.Partner IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS CalculationsAreIrrelevantWithClient,
		|	CASE
		|		WHEN PartnersSettlementsWithSuppliersAreIrrelevant.Partner IS NULL 
		|			THEN FALSE
		|		ELSE TRUE
		|	END AS CalculationsAreIrrelevantWithSupplier
		|INTO EventsWithoutPermission
		|FROM
		|	Events AS Events
		|		LEFT JOIN PartnersSettlementsWithClientsAreIrrelevant AS PartnersSettlementsWithClientsAreIrrelevant
		|		ON Events.Partner = PartnersSettlementsWithClientsAreIrrelevant.Partner
		|			AND (Events.EventType = &ClosingOrder
		|			OR Events.EventType = &WaitingForPaymentAfterShipment
		|			OR Events.EventType = &PreparationForShipment
		|			OR Events.EventType = &WaitingForPrepaymentBeforeShipment
		|			OR Events.EventType = &GetPaidForSales
		|			OR Events.EventType = &WaitingForPaymentBeforeSecuringRefundRequest
		|			OR Events.EventType = &WaitingForPrepaymentBeforeShipmentRequestForRefund
		|			OR Events.EventType = &PreparationForShipmentRequestForReturn
		|			OR Events.EventType = &WaitingForPaymentAfterShipmentRequestForRefund
		|			OR Events.EventType = &MarkWhenRefundRequestWasCompleted
		|			OR Events.EventType = &WaitingForPaymentBeforeSecuring)
		|		LEFT JOIN PartnersSettlementsWithSuppliersAreIrrelevant AS PartnersSettlementsWithSuppliersAreIrrelevant
		|		ON Events.Partner = PartnersSettlementsWithSuppliersAreIrrelevant.Partner
		|			AND (Events.EventType = &MakeAdvancePaymentBeforeConfirmation
		|			OR Events.EventType = &OrderConfirmation
		|			OR Events.EventType = &MakingAdvancePaymentBeforeShipment
		|			OR Events.EventType = &PreparationForAdmission
		|			OR Events.EventType = &PaymentAfterReceipt
		|			OR Events.EventType = &ClosingOrderToSupplier)";
		
	EndIf;
	
	Return QueryText;
	
EndFunction

Function RequestTextDataByEventType(Query, StructureOfReportGeneration)
	
	QueryText = "";
	StructureOfReportGeneration.Insert("CurSubqueryNumberByEventType",0);
	StructureOfReportGeneration.Insert("TextQueriesTemporaryTables","");
	
	For Each UpperLevelRow In StructureOfReportGeneration.EventKinds.Rows Do
		
		If UpperLevelRow.Check > 0 Then
			
			For Each StringTypeOfEvents In UpperLevelRow.Rows Do
				
				If StringTypeOfEvents.Check > 0 Then
					
					QueryText = QueryText + RequestTextByEventType_(Query,StringTypeOfEvents.EventKind,StructureOfReportGeneration);
					
				EndIf;
				
			EndDo
			
		EndIf;
		
	EndDo;
	
	Return QueryText;
	
EndFunction

Function RequestTextByEventType_(Query,EventKind,StructureOfReportGeneration)
	
	StructureOfReportGeneration.CurSubqueryNumberByEventType = StructureOfReportGeneration.CurSubqueryNumberByEventType + 1;
	
	If EventKind = "IncomingMessages" Then
		Return QueryTextIncomingMessages(Query, StructureOfReportGeneration);
	ElsIf EventKind = "OutgoingMessages" Then
		Return QueryTextOutgoingMessages(Query, StructureOfReportGeneration);
	ElsIf EventKind = "Meetings" Then
		Return QueryTextMeetings(Query, StructureOfReportGeneration);
	ElsIf EventKind = "PhoneCalls" Then
		Return QueryTextPhoneCalls(Query, StructureOfReportGeneration);
	ElsIf EventKind = "PlannedInteractions" Then
		Return QueryTextPlannedInteractions(Query,StructureOfReportGeneration);
	ElsIf EventKind = "BirthdaysOfContactPersons" Then
		Return QueryTextBirthdaysOfContactPersons(Query,StructureOfReportGeneration);
	ElsIf EventKind = "CounterpartyAgreements" Then
		Return QueryTextCounterpartyAgreements(Query,StructureOfReportGeneration);
	ElsIf EventKind = "MarketingActivities" Then
		Return QueryTextMarketingActivities(Query,StructureOfReportGeneration);
	ElsIf EventKind = "Projects" Then
		Return QueryTextProjects(Query,StructureOfReportGeneration);
	ElsIf EventKind = "SalesOpportunities" Then
		Return QueryTextSalesOpportunities(Query,StructureOfReportGeneration);
	ElsIf EventKind = "AgreementsWithClients" Then
		Return QueryTextTermsOfSale(Query,StructureOfReportGeneration);
	ElsIf EventKind = "TermsOfPurchaseFromVendors" Then
		Return QueryTextTermsOfPurchaseFromVendors(Query,StructureOfReportGeneration);
	ElsIf EventKind = "SettingPrices" Then
		Return QueryTextSettingPrices(Query,StructureOfReportGeneration);
	ElsIf EventKind = "SalesOrders" Then
		Return QueryTextSalesOrders(Query,StructureOfReportGeneration);
	ElsIf EventKind = "PurchaseOrders" Then
		Return QueryTextPurchaseOrders(Query,StructureOfReportGeneration);
	ElsIf EventKind = "RequestsForReturn" Then
		Return QueryTextRequestsForReturn(Query,StructureOfReportGeneration);
	ElsIf EventKind = "SalesOfGoodsAndServices_" Then
		Return QueryTextSalesOfGoodsAndServices_(Query,StructureOfReportGeneration);
	ElsIf EventKind = "RefundsToSupplier" Then
		Return QueryTextRefundsToSupplier(Query,StructureOfReportGeneration);
	ElsIf EventKind = "PowerOfAttorneyReceiptOfGoods" Then
		Return QueryTextPowerOfAttorneyReceiptOfGoods(Query,StructureOfReportGeneration);
	ElsIf EventKind = "InventoryConsumptionOrder" Then
		Return QueryTextInventoryConsumptionOrder(Query,StructureOfReportGeneration);
	ElsIf EventKind = "InventoryConsumption" Then
		Return QueryTextInventoryConsumption(Query,StructureOfReportGeneration);
	ElsIf EventKind = "OrderOfMaterialsForProduction" Then
		Return QueryTextOrderOfMaterialsForProduction(Query,StructureOfReportGeneration);
	ElsIf EventKind = "PaymentRequest" Then
		Return QueryTextPaymentRequest(Query,StructureOfReportGeneration);
	ElsIf EventKind = "ARAPReconciliation2_4" Then
		Return QueryTextARAPReconciliation(Query,StructureOfReportGeneration);
	ElsIf EventKind = "ARAPReconciliation2_5_11" Then
		Return QueryTextARAPReconciliation2_5_11(Query,StructureOfReportGeneration);
	ElsIf EventKind = "PerformerTask" Then
		Return RequestTextOtherTasksOfExecutor(Query,StructureOfReportGeneration);
	ElsIf EventKind = "CustomerAcceptanceCertificates" Then
		Return QueryTextCustomerAcceptanceCertificates(Query,StructureOfReportGeneration);
	Else
		QueryText = "";
		CRMLocalization.WhenGettingRequestTextByEventType(ThisObject, EventKind, Query, QueryText, StructureOfReportGeneration);
		Return QueryText;
	EndIf;
	
EndFunction

Function ConditionTextForObjectsExcludedFromRequestTextOtherContractorTasks()
	
	ConditionText = "
	|		AND NOT PerformerTask.SubjectOf REFS Document.IncomingEmail
	|		AND NOT PerformerTask.SubjectOf REFS Document.OutgoingEmail
	|		AND NOT PerformerTask.SubjectOf REFS Document.Meeting
	|		AND NOT PerformerTask.SubjectOf REFS Document.PhoneCall
	|		AND NOT PerformerTask.SubjectOf REFS Document.PlannedInteraction
	|		AND NOT PerformerTask.SubjectOf REFS Document.ARAPReconciliation2_4
	|		AND NOT PerformerTask.SubjectOf REFS Document.PaymentRequest
	|		AND NOT PerformerTask.SubjectOf REFS Document.InventoryConsumptionOrder
	|		AND NOT PerformerTask.SubjectOf REFS Document.IssuedLetterOfAuthority
	|		AND NOT PerformerTask.SubjectOf REFS Document.ReturnOfGoodsToVendor
	|		AND NOT PerformerTask.SubjectOf REFS Document.CustomerInvoice
	|		AND NOT PerformerTask.SubjectOf REFS Document.CommercialProposalForCustomer
	|		AND NOT PerformerTask.SubjectOf REFS Document.RequestForReturnOfGoodsFromCustomer
	|		AND NOT PerformerTask.SubjectOf REFS Document.PurchaseOrder
	|		AND NOT PerformerTask.SubjectOf REFS Document.SalesOrder
	|		AND NOT PerformerTask.SubjectOf REFS Document.ARAPReconciliation2_5_11
	|		AND NOT PerformerTask.SubjectOf REFS Document.PriceSetup
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.TermsOfPurchaseFromVendors
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.TermsOfSale
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.SalesOpportunitiesToCustomer
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.Projects
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.MarketingActivities
	|		AND NOT PerformerTask.SubjectOf REFS Catalog.CounterpartyContracts
	|";
	
	
	ConditionText = ConditionText + "
	|		AND NOT PerformerTask.SubjectOf REFS Document.OrderOfMaterialsForProduction
	|		AND NOT PerformerTask.SubjectOf REFS Document.MovementOfProductsAndMaterials
	|";
	
	Return ConditionText;
	
EndFunction

Function RequestTextOtherTasksOfExecutor(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	PerformerTask.Ref AS ReferenceToEventObject,
	|	PerformerTask.SubjectOf AS SubjectOf,
	|	PerformerTask.Description AS EventType,
	|	PerformerTask.Date AS DateOfEventObject,
	|	CASE
	|	WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
	|		THEN PerformerTask.Date
	|		ELSE PerformerTask.TaskDueDate
	|	END AS EventDate,
	|	PRESENTATION(PerformerTask.SubjectOf) AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
	|		THEN &CurrentBusinessUnit
	|		ELSE CASE
	|			WHEN PerformerTask.TaskDueDate < &CurrentDate
	|				THEN &Overdue
	|			WHEN BEGINOFPERIOD(PerformerTask.TaskDueDate, DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
	|				THEN &CurrentBusinessUnit
	|			ELSE &Upcoming
	|		END
	|	END AS Status,
	|	PerformerTask.SubjectOf.Partner AS Partner,
	|	PerformerTask.Performer AS EmployeeResponsible
	|,&TheTextToPut
	|FROM
	|	Task.PerformerTask AS PerformerTask
	|WHERE
	|	PerformerTask.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Running)
	|		AND NOT PerformerTask.Executed
	|		AND CASE
	|			WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE PerformerTask.TaskDueDate < &EndDate
	|		END 
	|	AND &TermsTextExcludedItems
	|	AND &ConditionTextTaskSelection";
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		ConditionTextTaskSelection ="
		|AND  PerformerTask.Performer" + StructureOfReportGeneration.ConditionTextForUsers;
		
		If StructureOfReportGeneration.ThereIsAnAssigneeRoleRight Then
				
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	PerformerTask.Ref,
		|	PerformerTask.SubjectOf,
		|	PerformerTask.Description,
		|	PerformerTask.Date,
		|	CASE
		|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|		THEN BEGINOFPERIOD(&CurrentDate, DAY)
		|		ELSE PerformerTask.TaskDueDate
		|	END,
		|	PerformerTask.SubjectOf AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|		WHEN PerformerTask.TaskDueDate < &CurrentDate
		|			THEN &Overdue
		|		WHEN BEGINOFPERIOD(PerformerTask.TaskDueDate, DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			ELSE &Upcoming
		|		END
		|	END,
		|	PerformerTask.SubjectOf.Partner,
		|	CASE
		|		WHEN PerformerTask.Performer = VALUE(Catalog.Users.EmptyRef)
		|			THEN PerformerTask.PerformerRole
		|		ELSE PerformerTask.Performer
		|	END 
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|	INNER JOIN FilterForSpecifiedUsers AS FilterForSpecifiedUsers
		|	ON (PerformerTask.PerformerRole = FilterForSpecifiedUsers.PerformerRole
		|			AND PerformerTask.MainAddressingObject = FilterForSpecifiedUsers.MainAddressingObject
		|			AND PerformerTask.AdditionalAddressingObject = FilterForSpecifiedUsers.AdditionalAddressingObject)
		|WHERE
		|	PerformerTask.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Running)
		|	AND NOT PerformerTask.Executed
		|	AND CASE
		|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|			THEN TRUE
		|		ELSE PerformerTask.TaskDueDate < &EndDate
		|	END
		|	AND &TermsTextExcludedItems";
		
		EndIf;
		
	Else
		
		ConditionTextTaskSelection = "";
		
	EndIf;
		
	QueryText = StrReplace(QueryText,"AND &ConditionTextTaskSelection",        ConditionTextTaskSelection);
	QueryText = StrReplace(QueryText,"AND &TermsTextExcludedItems",ConditionTextForObjectsExcludedFromRequestTextOtherContractorTasks());
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Task.PerformerTask");
	
	Return QueryText;
	
EndFunction

Function QueryTextARAPReconciliation(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	ARAPReconciliation.Ref AS ReferenceToEventObject,
	|	ARAPReconciliation.Ref AS SubjectOf,
	|	CASE
	|		WHEN ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation.CreatedOn_)
	|			THEN &SendForReconciliation
	|		ELSE &CoordinateReconciliationData
	|	END AS EventType,
	|	ARAPReconciliation.Date AS DateOfEventObject,
	|	BEGINOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	ARAPReconciliation.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	ARAPReconciliation.Partner AS Partner,
	|	ARAPReconciliation.Manager AS EmployeeResponsible
	|,&TheTextToPut
	|FROM
	|	Document.ARAPReconciliation2_4 AS ARAPReconciliation
	|WHERE
	|	ARAPReconciliation.Posted
	|	AND (ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation.CreatedOn_)
	|			OR ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation.OnReconciliation))
	|	AND NOT (TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.ARAPReconciliation2_4.GroupingsFinancialInstruments AS FinTools
	|		WHERE
	|			ARAPReconciliation.Ref = FinTools.Ref
	|			AND FinTools.PaymentType_ IN (&ProhibitedPaymentTypes)
	|		)
	|	)
	|	AND &TextOfSelectionCondition
	|";
	
	Query.SetParameter("SendForReconciliation",NStr("vi = 'Chuyển bạn hàng để đối chiếu';
													|ru = 'Передать партнеру на сверку';
													|en = 'Transfer to the partner for reconciliation'; fa = 'Transfer to the partner for reconciliation';
													|it = 'Invia al partner per la riconciliazione';
													|pl = 'Wyślij do partnera do weryfikacji';
													|tr = 'Mutabakat için iş ortağına transfer et'"));
	Query.SetParameter("CoordinateReconciliationData",NStr("vi = 'Thống nhất với bạn hàng dữ liệu đối chiếu';
															|ru = 'Согласовать с партнером данные сверки';
															|en = 'Approve reconciliation data with partner'; fa = 'Approve reconciliation data with partner';
															|it = 'Concordare con il partner i dati della riconciliazione';
															|pl = 'Uzgodnić z partnerem dane weryfikacji';
															|tr = 'Mutabakat verilerini iş ortağıyla onayla'"));
	Query.SetParameter("ProhibitedPaymentTypes", Documents.ARAPReconciliation2_4.ProhibitedPaymentTypes());
	
	AddRequestForIssues(QueryText,"Document.ARAPReconciliation2_4",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND ARAPReconciliation.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.ARAPReconciliation2_4");
	
	Return QueryText;
	
EndFunction


Function QueryTextARAPReconciliation2_5_11(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	ARAPReconciliation.Ref AS ReferenceToEventObject,
	|	ARAPReconciliation.Ref AS SubjectOf,
	|	CASE
	|		WHEN ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.CreatedOn_)
	|			THEN &SendForReconciliation
	|		ELSE &CoordinateReconciliationData
	|	END AS EventType,
	|	ARAPReconciliation.Date AS DateOfEventObject,
	|	BEGINOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	ARAPReconciliation.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	ARAPReconciliation.Partner AS Partner,
	|	ARAPReconciliation.Manager AS EmployeeResponsible
	|,&TheTextToPut
	|FROM
	|	Document.ARAPReconciliation2_5_11 AS ARAPReconciliation
	|WHERE
	|	ARAPReconciliation.Posted
	|	AND (ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.CreatedOn_)
	|			OR ARAPReconciliation.Status = VALUE(Enum.StatusesOfARAPReconciliation2_5_11.OnReconciliation))
	|	AND NOT (TRUE IN (
	|		SELECT TOP 1
	|			TRUE
	|		FROM
	|			Document.ARAPReconciliation2_5_11.SummaryRecords AS SummaryRecords
	|		WHERE
	|			ARAPReconciliation.Ref = SummaryRecords.Ref
	|			AND SummaryRecords.PaymentType_ IN (&ProhibitedPaymentTypes)
	|		)
	|	)
	|	AND &TextOfSelectionCondition
	|";
	
	Query.SetParameter("SendForReconciliation",NStr("vi = 'Chuyển bạn hàng để đối chiếu';
													|ru = 'Передать партнеру на сверку';
													|en = 'Transfer to the partner for reconciliation'; fa = 'Transfer to the partner for reconciliation';
													|it = 'Invia al partner per la riconciliazione';
													|pl = 'Wyślij do partnera do weryfikacji';
													|tr = 'Mutabakat için iş ortağına transfer et'"));
	Query.SetParameter("CoordinateReconciliationData",NStr("vi = 'Thống nhất với bạn hàng dữ liệu đối chiếu';
															|ru = 'Согласовать с партнером данные сверки';
															|en = 'Approve reconciliation data with partner'; fa = 'Approve reconciliation data with partner';
															|it = 'Concordare con il partner i dati della riconciliazione';
															|pl = 'Uzgodnić z partnerem dane weryfikacji';
															|tr = 'Mutabakat verilerini iş ortağıyla onayla'"));
	Query.SetParameter("ProhibitedPaymentTypes", Documents.ARAPReconciliation2_5_11.ProhibitedPaymentTypes());
	
	AddRequestForIssues(QueryText,"Document.ARAPReconciliation2_5_11",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND ARAPReconciliation.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.ARAPReconciliation2_5_11");
	
	Return QueryText;
	
EndFunction

Function QueryTextPaymentRequest(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	PaymentRequest.Ref AS ReferenceToEventObject,
	|	PaymentRequest.Ref AS SubjectOf,
	|	&AgreeOnApplicationForSpendingMoney AS EventType,
	|	PaymentRequest.Date AS DateOfEventObject,
	|	PaymentRequest.RequiredPaymentDate AS EventDate,
	|	PaymentRequest.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN PaymentRequest.RequiredPaymentDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &Upcoming
	|		WHEN PaymentRequest.RequiredPaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END AS Status,
	|	NULL AS Partner,
	|	PaymentRequest.WhoStated AS EmployeeResponsible
	|,&TheTextToPut
	|FROM
	|	Document.PaymentRequest AS PaymentRequest
	|WHERE
	|	PaymentRequest.Posted AND PaymentRequest.RequiredPaymentDate < &EndDate
	|	AND PaymentRequest.Status = VALUE(Enum.StatusesOfPaymentRequests.NotAgreedUpon) AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	PaymentRequest.Ref,
	|	PaymentRequest.Ref,
	|	&ApproveApplicationForSpendingFunds,
	|	PaymentRequest.Date,
	|	PaymentRequest.RequiredPaymentDate,
	|	PaymentRequest.Presentation,
	|	NULL,
	|	NULL,
	|	CASE
	|		WHEN PaymentRequest.RequiredPaymentDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &Upcoming
	|		WHEN PaymentRequest.RequiredPaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END,
	|	NULL AS Partner,
	|	PaymentRequest.WhoStated AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Document.PaymentRequest AS PaymentRequest
	|WHERE
	|	PaymentRequest.Posted  AND PaymentRequest.RequiredPaymentDate < &EndDate
	|	AND PaymentRequest.Status = VALUE(Enum.StatusesOfPaymentRequests.AgreedUpon) 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("AgreeOnApplicationForSpendingMoney",NStr("vi = 'Nhận thống nhất giấy đề nghị';
																|ru = 'Получить согласование заявки';
																|en = 'Receive request coordination'; fa = 'Receive request coordination';
																|it = 'Ottenere il concordamento della richiesta';
																|pl = 'Uzyskanie uzgadnianie zgłoszenia';
																|tr = 'Başvuru onayını al'"));
	Query.SetParameter("ApproveApplicationForSpendingFunds",NStr("vi = 'Nhận xác nhận giấy đề nghị';
																|ru = 'Получить утверждение заявки';
																|en = 'Receive request confirmation'; fa = 'Receive request confirmation';
																|it = 'Ottenere l''approvazione della richiesta';
																|pl = 'Uzyskanie zatwierdzenia zgłoszenia';
																|tr = 'Başvuru onayını al'"));
	
	AddRequestForIssues(QueryText,"Document.PaymentRequest",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND PaymentRequest.WhoStated" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.PaymentRequest");
	
	Return QueryText;

EndFunction

Function QueryTextInventoryConsumption(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT DISTINCT
	|	InventoryConsumption.Ref AS ReferenceToEventObject,
	|	InventoryConsumption.Ref AS SubjectOf,
	|	&ControlShipmentDomesticConsumption AS EventType,
	|	InventoryConsumption.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	InventoryConsumption.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	NULL AS Partner,
	|	InventoryConsumption.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.InventoryConsumption AS InventoryConsumption
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON InventoryConsumption.Warehouse = Warehouses.Ref
	|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments REFS Document.InventoryConsumption AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
	|		ON GoodsForIssueBalance.DocumentShipments = InventoryConsumption.Ref
	|WHERE
	|	InventoryConsumption.Posted
	|	AND CASE
	|			WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|						AND InventoryConsumption.Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|				THEN GoodsForIssueBalance.ToShipBalance > 0
	|						OR GoodsForIssueBalance.AssemblyInProgressBalance > 0
	|						OR GoodsForIssueBalance.AssembledBalance > 0
	|			ELSE FALSE
	|		END
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ControlShipmentDomesticConsumption",NStr("vi = 'Kiểm soát giao hàng';
																|ru = 'Проконтролировать отгрузку';
																|en = 'Monitor shipment'; fa = 'Monitor shipment';
																|it = 'Controllare la spedizione';
																|pl = 'Sprawdź wysyłkę';
																|tr = 'Sevkiyatı kontrol et'"));
	
	AddRequestForIssues(QueryText,"Document.InventoryConsumption",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND InventoryConsumption.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfConditionAndDocumentOfShipment ="
		|AND DocumentShipments.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfConditionAndDocumentOfShipment ="";
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfConditionAndDocumentOfShipment",TextOfConditionAndDocumentOfShipment);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.InventoryConsumption");
	
	Return QueryText;

EndFunction

Function QueryTextOrderOfMaterialsForProduction(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	DocumentOrderOfMaterialsForProduction.Ref AS ReferenceToEventObject,
	|	DocumentOrderOfMaterialsForProduction.Ref AS SubjectOf,
	|	&PrepareToShip AS EventType,
	|	DocumentOrderOfMaterialsForProduction.Date AS DateOfEventObject,
	|	MIN(ENDOFPERIOD(OrderOfMaterialsForProductionGoods.ShipmentStart, DAY)) AS EventDate,
	|	DocumentOrderOfMaterialsForProduction.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END AS Status,
	|	NULL AS Partner,
	|	DocumentOrderOfMaterialsForProduction.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Document.OrderOfMaterialsForProduction.Goods AS OrderOfMaterialsForProductionGoods
	|		INNER JOIN Document.OrderOfMaterialsForProduction AS DocumentOrderOfMaterialsForProduction
	|		ON OrderOfMaterialsForProductionGoods.Ref = DocumentOrderOfMaterialsForProduction.Ref
	|WHERE
	|	DocumentOrderOfMaterialsForProduction.Posted
	|	AND DocumentOrderOfMaterialsForProduction.Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion)
	|	AND OrderOfMaterialsForProductionGoods.ShipmentStart < &EndDate  AND &TextOfSelectionConditionDocument
	|
	|GROUP BY
	|	DocumentOrderOfMaterialsForProduction.Ref,
	|	DocumentOrderOfMaterialsForProduction.Date,
	|	DocumentOrderOfMaterialsForProduction.Presentation,
	|	DocumentOrderOfMaterialsForProduction.EmployeeResponsible,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END,
	|	DocumentOrderOfMaterialsForProduction.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentOrderOfMaterialsForProduction.Ref AS ReferenceToEventObject,
	|	DocumentOrderOfMaterialsForProduction.Ref AS SubjectOf,
	|	&ExecuteOrderOfMaterialsInProduction AS EventType,
	|	DocumentOrderOfMaterialsForProduction.Date AS DateOfEventObject,
	|	ENDOFPERIOD(OrderOfMaterialsForProductionGoods.ShipmentStart, DAY) AS EventDate,
	|	OrdersOfMaterialsForProductionBalance.ReferenceOrder.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = OrderOfMaterialsForProductionGoods.ShipmentStart
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END AS Status,
	|	NULL AS Partner,
	|	DocumentOrderOfMaterialsForProduction.EmployeeResponsible AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	AccumulationRegister.OrdersOfMaterialsForProduction.Balance(
	|			,
	|			ReferenceOrder REFS Document.OrderOfMaterialsForProduction
	|				AND CAST(ReferenceOrder AS Document.OrderOfMaterialsForProduction).Goods.ShipmentStart < &EndDate
	|				AND CAST(ReferenceOrder AS Document.OrderOfMaterialsForProduction).Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion) AND &TextOfConditionSelectionOrder) AS OrdersOfMaterialsForProductionBalance
	|		INNER JOIN Document.OrderOfMaterialsForProduction.Goods AS OrderOfMaterialsForProductionGoods
	|		ON OrdersOfMaterialsForProductionBalance.ReferenceOrder = OrderOfMaterialsForProductionGoods.Ref
	|			AND OrdersOfMaterialsForProductionBalance.RowCode = OrderOfMaterialsForProductionGoods.RowCode
	|		INNER JOIN Document.OrderOfMaterialsForProduction AS DocumentOrderOfMaterialsForProduction
	|		ON OrdersOfMaterialsForProductionBalance.ReferenceOrder = DocumentOrderOfMaterialsForProduction.Ref
	|WHERE
	|	OrdersOfMaterialsForProductionBalance.ToRegisterBalance > 0 
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentOrderOfMaterialsForProduction.Ref AS ReferenceToEventObject,
	|	DocumentOrderOfMaterialsForProduction.Ref AS SubjectOf,
	|	&CloseOrderOfMaterialsInProduction AS EventType,
	|	DocumentOrderOfMaterialsForProduction.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	DocumentOrderOfMaterialsForProduction.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	NULL AS Partner,
	|	DocumentOrderOfMaterialsForProduction.EmployeeResponsible AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Document.OrderOfMaterialsForProduction AS DocumentOrderOfMaterialsForProduction
	|		LEFT JOIN AccumulationRegister.OrdersOfMaterialsForProduction.Balance(
	|			,
	|			ReferenceOrder REFS Document.OrderOfMaterialsForProduction
	|			AND CAST(ReferenceOrder AS Document.OrderOfMaterialsForProduction).Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion) AND &TextOfConditionSelectionOrder) AS OrdersOfMaterialsForProductionBalance
	|		ON OrdersOfMaterialsForProductionBalance.ReferenceOrder = DocumentOrderOfMaterialsForProduction.Ref
	|WHERE
	|	ISNULL(OrdersOfMaterialsForProductionBalance.ToRegisterBalance, 0) = 0 
	|	AND DocumentOrderOfMaterialsForProduction.Status = VALUE(Enum.StatusesOfOrdersForMaterialsForProduction.ForCompletion) 
	|	AND &TextOfSelectionConditionDocument";
	
	Query.SetParameter("PrepareToShip",NStr("vi = 'Chuẩn bị giao hàng';
											|ru = 'Подготовить к отгрузке';
											|en = 'Prepare to ship'; fa = 'Prepare to ship';
											|it = 'Preparare per la spedizione';
											|pl = 'Przygotuj do wysyłki';
											|tr = 'Sevkiyat için hazırla'"));
	Query.SetParameter("ExecuteOrderOfMaterialsInProduction",NStr("vi = 'Thực hiện đơn hàng';
																	|ru = 'Выполнить заказ';
																	|en = 'Fulfill order'; fa = 'Fulfill order';
																	|it = 'Eseguire l''ordine';
																	|pl = 'Wykonaj zamówienie';
																	|tr = 'Siparişi gerçekleştir'"));
	Query.SetParameter("CloseOrderOfMaterialsInProduction",NStr("vi = 'Đóng đơn hàng';
																|ru = 'Закрыть заказ';
																|en = 'Close order'; fa = 'بستن سفارش';
																|it = 'Chiudi l''ordine';
																|pl = 'Zamknij zamówienie';
																|tr = 'Siparişi kapat'"));
	
	AddRequestForIssues(QueryText,"Document.OrderOfMaterialsForProduction",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND OrderOfMaterialsForProduction.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfConditionSelectionOrder ="
		|AND ReferenceOrder.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionConditionDocument ="
		|AND DocumentOrderOfMaterialsForProduction.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition             = "";
		TextOfSelectionConditionDocument     = "";
		TextOfConditionSelectionOrder = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionConditionDocument",TextOfSelectionConditionDocument);
	QueryText = StrReplace(QueryText,"AND &TextOfConditionSelectionOrder",TextOfConditionSelectionOrder);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.OrderOfMaterialsForProduction");
	
	Return QueryText;
	
EndFunction


Function QueryTextInventoryConsumptionOrder(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	DocumentInventoryConsumptionOrder.Ref AS ReferenceToEventObject,
	|	DocumentInventoryConsumptionOrder.Ref AS SubjectOf,
	|	&PrepareToShip AS EventType,
	|	DocumentInventoryConsumptionOrder.Date AS DateOfEventObject,
	|	MIN(ENDOFPERIOD(InventoryConsumptionOrderGoods.DateOfShipment, DAY)) AS EventDate,
	|	DocumentInventoryConsumptionOrder.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END AS Status,
	|	NULL AS Partner,
	|	DocumentInventoryConsumptionOrder.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Document.InventoryConsumptionOrder.Goods AS InventoryConsumptionOrderGoods
	|		INNER JOIN Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder
	|		ON InventoryConsumptionOrderGoods.Ref = DocumentInventoryConsumptionOrder.Ref
	|WHERE
	|	DocumentInventoryConsumptionOrder.Posted
	|	AND DocumentInventoryConsumptionOrder.Status = VALUE(Enum.InternalOrderStatuses.AwaitingApproval)
	|	AND InventoryConsumptionOrderGoods.DateOfShipment < &EndDate AND &TextOfSelectionConditionDocument
	|
	|GROUP BY
	|	DocumentInventoryConsumptionOrder.Ref,
	|	DocumentInventoryConsumptionOrder.Date,
	|	DocumentInventoryConsumptionOrder.Presentation,
	|	DocumentInventoryConsumptionOrder.EmployeeResponsible,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END,
	|	DocumentInventoryConsumptionOrder.Ref
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInventoryConsumptionOrder.Ref AS ReferenceToEventObject,
	|	DocumentInventoryConsumptionOrder.Ref AS SubjectOf,
	|	&ExecuteOrderForDomesticConsumption AS EventType,
	|	DocumentInventoryConsumptionOrder.Date AS DateOfEventObject,
	|	ENDOFPERIOD(InventoryConsumptionOrderGoods.DateOfShipment,DAY) AS EventDate,
	|	InventoryConsumptionOrdersBalance.InventoryConsumptionOrder.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) < InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = InventoryConsumptionOrderGoods.DateOfShipment
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END AS Status,
	|	NULL AS Partner,
	|	DocumentInventoryConsumptionOrder.EmployeeResponsible AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	AccumulationRegister.InventoryConsumptionOrders.Balance(
	|			,
	|			InventoryConsumptionOrder.Goods.DateOfShipment < &EndDate
	|				AND InventoryConsumptionOrder.Status = VALUE(Enum.InternalOrderStatuses.ForCompletion) AND &TextOfSelectionCondition) AS InventoryConsumptionOrdersBalance
	|		INNER JOIN Document.InventoryConsumptionOrder.Goods AS InventoryConsumptionOrderGoods
	|		ON InventoryConsumptionOrdersBalance.InventoryConsumptionOrder = InventoryConsumptionOrderGoods.Ref
	|			AND InventoryConsumptionOrdersBalance.RowCode = InventoryConsumptionOrderGoods.RowCode
	|		INNER JOIN Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder
	|		ON InventoryConsumptionOrdersBalance.InventoryConsumptionOrder = DocumentInventoryConsumptionOrder.Ref
	|WHERE
	|	InventoryConsumptionOrdersBalance.ToRegisterBalance > 0 
	|
	|UNION ALL
	|
	|SELECT
	|	DocumentInventoryConsumptionOrder.Ref AS ReferenceToEventObject,
	|	DocumentInventoryConsumptionOrder.Ref AS SubjectOf,
	|	&CloseDomesticConsumptionOrder AS EventType,
	|	DocumentInventoryConsumptionOrder.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	DocumentInventoryConsumptionOrder.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	NULL AS Partner,
	|	DocumentInventoryConsumptionOrder.EmployeeResponsible AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Document.InventoryConsumptionOrder AS DocumentInventoryConsumptionOrder
	|		LEFT JOIN AccumulationRegister.InventoryConsumptionOrders.Balance(, InventoryConsumptionOrder.Status = VALUE(Enum.InternalOrderStatuses.ForCompletion) AND &TextOfSelectionCondition) AS InventoryConsumptionOrdersBalance
	|		ON InventoryConsumptionOrdersBalance.InventoryConsumptionOrder = DocumentInventoryConsumptionOrder.Ref
	|WHERE
	|	ISNULL(InventoryConsumptionOrdersBalance.ToRegisterBalance, 0) = 0 
	|	AND DocumentInventoryConsumptionOrder.Status = VALUE(Enum.InternalOrderStatuses.ForCompletion) 
	|	AND &TextOfSelectionConditionDocument";
	
	Query.SetParameter("PrepareToShip",NStr("vi = 'Chuẩn bị giao hàng';
											|ru = 'Подготовить к отгрузке';
											|en = 'Prepare to ship'; fa = 'Prepare to ship';
											|it = 'Preparare per la spedizione';
											|pl = 'Przygotuj do wysyłki';
											|tr = 'Sevkiyat için hazırla'"));
	Query.SetParameter("ExecuteOrderForDomesticConsumption",NStr("vi = 'Thực hiện đơn hàng';
																|ru = 'Выполнить заказ';
																|en = 'Fulfill order'; fa = 'Fulfill order';
																|it = 'Eseguire l''ordine';
																|pl = 'Wykonaj zamówienie';
																|tr = 'Siparişi gerçekleştir'"));
	Query.SetParameter("CloseDomesticConsumptionOrder",NStr("vi = 'Đóng đơn hàng';
															|ru = 'Закрыть заказ';
															|en = 'Close order'; fa = 'بستن سفارش';
															|it = 'Chiudi l''ordine';
															|pl = 'Zamknij zamówienie';
															|tr = 'Siparişi kapat'"));
	
	AddRequestForIssues(QueryText,"Document.InventoryConsumptionOrder",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND InventoryConsumptionOrder.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionConditionDocument ="
		|AND DocumentInventoryConsumptionOrder.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		TextOfSelectionConditionDocument ="";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionConditionDocument",TextOfSelectionConditionDocument);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.InventoryConsumptionOrder");
	
	Return QueryText;

EndFunction

Function QueryTextPowerOfAttorneyReceiptOfGoods(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	IssuedLetterOfAuthority.Ref AS ReferenceToEventObject,
	|	IssuedLetterOfAuthority.Ref AS SubjectOf,
	|	&ControlDeliveryOfPowerOfAttorney AS EventType,
	|	IssuedLetterOfAuthority.Date AS DateOfEventObject,
	|	CASE
	|		WHEN IssuedLetterOfAuthority.ValidityEndDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE ENDOFPERIOD(IssuedLetterOfAuthority.ValidityEndDate,DAY)
	|	END AS EventDate,
	|	IssuedLetterOfAuthority.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN IssuedLetterOfAuthority.ValidityEndDate = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < IssuedLetterOfAuthority.ValidityEndDate
	|					THEN &Upcoming
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = IssuedLetterOfAuthority.ValidityEndDate
	|					THEN &CurrentBusinessUnit
	|				ELSE &Overdue
	|			END
	|	END AS Status,
	|	IssuedLetterOfAuthority.Partner AS Partner,
	|	IssuedLetterOfAuthority.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Document.IssuedLetterOfAuthority AS IssuedLetterOfAuthority
	|WHERE
	|	NOT IssuedLetterOfAuthority.DeletionMark
	|	AND IssuedLetterOfAuthority.Status = VALUE(Enum.StatusesOfAuthorizationLetters.Issued)
	|	AND CASE
	|			WHEN IssuedLetterOfAuthority.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE IssuedLetterOfAuthority.ValidityEndDate < &EndDate
	|		END 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ControlDeliveryOfPowerOfAttorney",NStr("vi = 'Kiểm soát việc cấp giấy giới thiệu';
																|ru = 'Проконтролировать сдачу доверенности';
																|en = 'Monitor authorization letter delivery'; fa = 'Monitor authorization letter delivery';
																|it = 'Controllare la restituzione della procura';
																|pl = 'Przekontrolować oddanie pełnomocnictwa';
																|tr = 'Yetki belgesi teslimini kontrol et'"));
	
	AddRequestForIssues(QueryText,"Document.IssuedLetterOfAuthority",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND IssuedLetterOfAuthority.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.IssuedLetterOfAuthority");
	
	Return QueryText;

EndFunction

Function QueryTextRefundsToSupplier(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT DISTINCT
	|	ReturnOfGoodsToVendor.Ref AS ReferenceToEventObject,
	|	ReturnOfGoodsToVendor.Ref AS SubjectOf,
	|	&ControlShipmentByReturnToSupplier AS EventType,
	|	ReturnOfGoodsToVendor.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	ReturnOfGoodsToVendor.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	ReturnOfGoodsToVendor.Manager AS EmployeeResponsible,
	|	ReturnOfGoodsToVendor.Partner AS Partner
	|   ,&TheTextToPut
	|FROM
	|	Document.ReturnOfGoodsToVendor AS ReturnOfGoodsToVendor
	|		INNER JOIN Catalog.Warehouses AS Warehouses
	|		ON ReturnOfGoodsToVendor.Warehouse = Warehouses.Ref
	|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(, DocumentShipments REFS Document.ReturnOfGoodsToVendor AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
	|		ON GoodsForIssueBalance.DocumentShipments = ReturnOfGoodsToVendor.Ref
	|WHERE
	|	ReturnOfGoodsToVendor.Posted
	|	AND CASE
	|		WHEN Warehouses.UseWarehouseManagemantSystemForGoodsIssue
	|				AND ReturnOfGoodsToVendor.Date >= Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue
	|			THEN GoodsForIssueBalance.ToShipBalance > 0
	|					OR GoodsForIssueBalance.AssemblyInProgressBalance > 0
	|					OR GoodsForIssueBalance.AssembledBalance > 0
	|			ELSE TRUE
	|		END
	|	AND &TextOfSelectionCondition
	|";
	
	Query.SetParameter("ControlShipmentByReturnToSupplier",NStr("vi = 'Kiểm soát giao hàng';
																|ru = 'Проконтролировать отгрузку';
																|en = 'Monitor shipment'; fa = 'Monitor shipment';
																|it = 'Controllare la spedizione';
																|pl = 'Sprawdź wysyłkę';
																|tr = 'Sevkiyatı kontrol et'"));
	
	AddRequestForIssues(QueryText,"Document.ReturnOfGoodsToVendor",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND ReturnOfGoodsToVendor.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfConditionAndDocumentOfShipment ="
		|AND DocumentShipments.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		TextOfConditionAndDocumentOfShipment ="";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfConditionAndDocumentOfShipment",TextOfConditionAndDocumentOfShipment);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.ReturnOfGoodsToVendor");
	
	Return QueryText;

EndFunction

Function QueryTextSalesOfGoodsAndServices_(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	ARAPObjects.Object,
	|	ARAPObjects.Object,
	|	&GetPaidForSales,
	|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
	|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
	|	ARAPObjects.Description,
	|	NULL,
	|	NULL,
	|	CASE
	|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &Overdue
	|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Upcoming
	|	END,
	|	ARAPObjects.Partner AS Partner,
	|	ARAPObjects.Manager
	|FROM
	|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.CustomerInvoice
	|	AND BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
	|GROUP BY
	|	ARAPObjects.Object,
	|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
	|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
	|	ARAPObjects.Description,
	|	ARAPObjects.Partner,
	|	ARAPObjects.Manager";
	
	QueryText = "
	|SELECT DISTINCT
	|	CustomerInvoice.Ref AS ReferenceToEventObject,
	|	CustomerInvoice.Ref AS SubjectOf,
	|	&GetPaidForSales AS EventType,
	|	CustomerInvoice.Date AS DateOfEventObject,
	|	ENDOFPERIOD(CustomersARAPAccounting.PaymentDate,DAY) AS EventDate,
	|	CustomerInvoice.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN CustomersARAPAccounting.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		WHEN CustomersARAPAccounting.PaymentDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &Upcoming
	|		ELSE &Overdue
	|	END AS Status,
	|	CustomerInvoice.Partner,
	|	CustomerInvoice.Manager AS EmployeeResponsible
	|FROM
	|	TableOfCustomerBalancesPayable AS CustomersARAPAccounting
	|
	|	INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|	ON CustomersARAPAccounting.Object = CustomerInvoice.Ref
	|WHERE
	|	CustomersARAPAccounting.AmountDueBalance > 0
	|	AND NOT CustomerInvoice.OrderSales
	|	AND CustomersARAPAccounting.PaymentDate < &EndDate
	|	AND CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
	|	AND &TextOfSelectionCondition";
	

	If StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		
		QueryText = " 
		|SELECT
		|	CustomerInvoice.Ref AS ReferenceToEventObject,
		|	CustomerInvoice.Ref AS SubjectOf,
		|	&ControlShipmentByImplementation AS EventType,
		|	CustomerInvoice.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
		|	CustomerInvoice.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	&CurrentBusinessUnit AS Status,
		|	CustomerInvoice.Partner,
		|	CustomerInvoice.Manager AS EmployeeResponsible
		|  ,&TheTextToPut
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				DocumentShipments REFS Document.CustomerInvoice
		|					AND DocumentShipments IN
		|						(SELECT
		|							TotalCompositionOfWarehouses.Ref
		|						FROM
		|							TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|						WHERE
		|							TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0)) AS GoodsForIssueBalance
		|		ON (GoodsForIssueBalance.DocumentShipments = CustomerInvoice.Ref)
		|WHERE
		|	CustomerInvoice.Ref IN
		|			(SELECT
		|				TotalCompositionOfWarehouses.Ref
		|			FROM
		|				TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|			WHERE
		|				(TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0
		|						AND (ISNULL(GoodsForIssueBalance.ToShipBalance, 0) > 0
		|							OR ISNULL(GoodsForIssueBalance.AssemblyInProgressBalance, 0) > 0
		|							OR ISNULL(GoodsForIssueBalance.AssembledBalance, 0) > 0)))
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&GetPaidForSales,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.CustomerInvoice
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|";
		
	Else

		QueryText = " 
		|SELECT
		|	CustomerInvoice.Ref AS ReferenceToEventObject,
		|	CustomerInvoice.Ref AS SubjectOf,
		|	&ControlShipmentByImplementation AS EventType,
		|	CustomerInvoice.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
		|	CustomerInvoice.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	&CurrentBusinessUnit AS Status,
		|	CustomerInvoice.Partner,
		|	CustomerInvoice.Manager AS EmployeeResponsible
		|  ,&TheTextToPut
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				DocumentShipments REFS Document.CustomerInvoice
		|					AND DocumentShipments IN
		|						(SELECT
		|							TotalCompositionOfWarehouses.Ref
		|						FROM
		|							TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|						WHERE
		|							TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0)) AS GoodsForIssueBalance
		|		ON (GoodsForIssueBalance.DocumentShipments = CustomerInvoice.Ref)
		|WHERE
		|	CustomerInvoice.Ref IN
		|			(SELECT
		|				TotalCompositionOfWarehouses.Ref
		|			FROM
		|				TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|			WHERE
		|				(TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0
		|						AND (ISNULL(GoodsForIssueBalance.ToShipBalance, 0) > 0
		|							OR ISNULL(GoodsForIssueBalance.AssemblyInProgressBalance, 0) > 0
		|							OR ISNULL(GoodsForIssueBalance.AssembledBalance, 0) > 0)))
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	CustomerInvoice.Ref AS ReferenceToEventObject,
		|	CustomerInvoice.Ref AS SubjectOf,
		|	&GetPaidForSales AS EventType,
		|	CustomerInvoice.Date AS DateOfEventObject,
		|	ENDOFPERIOD(CustomersARAPAccounting.PaymentDate,DAY) AS EventDate,
		|	CustomerInvoice.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN CustomersARAPAccounting.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		WHEN CustomersARAPAccounting.PaymentDate > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		ELSE &Overdue
		|	END AS Status,
		|	CustomerInvoice.Partner,
		|	CustomerInvoice.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	TableOfCustomerBalancesPayable AS CustomersARAPAccounting
		|
		|	INNER JOIN Document.CustomerInvoice AS CustomerInvoice
		|	ON CustomersARAPAccounting.Object = CustomerInvoice.Ref
		|WHERE
		|	CustomersARAPAccounting.AmountDueBalance > 0
		|	AND NOT CustomerInvoice.OrderSales
		|	AND CustomersARAPAccounting.PaymentDate < &EndDate
		|	AND CustomerInvoice.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND &TextOfSelectionCondition
		|";
	
	EndIf;
	
	If GetFunctionalOption("UseStatusesOfGoodsServicesSales") Then
			
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	CustomerInvoice.Ref,
		|	CustomerInvoice.Ref,
		|	&SwitchToShippedStatus,
		|	CustomerInvoice.Date,
		|	ENDOFPERIOD(&CurrentDate, DAY),
		|	CustomerInvoice.Presentation,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit,
		|	CustomerInvoice.Partner,
		|	CustomerInvoice.Manager
		|FROM
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|				,
		|				DocumentShipments REFS Document.CustomerInvoice
		|					AND DocumentShipments IN
		|						(SELECT
		|							TotalCompositionOfWarehouses.Ref
		|						FROM
		|							TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|						WHERE
		|							TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0)) AS GoodsForIssueBalance
		|		ON (GoodsForIssueBalance.DocumentShipments = CustomerInvoice.Ref)
		|WHERE
		|	CustomerInvoice.Ref IN
		|			(SELECT
		|				TotalCompositionOfWarehouses.Ref
		|			FROM
		|				TotalCompositionOfWarehouses AS TotalCompositionOfWarehouses
		|			WHERE
		|				TotalCompositionOfWarehouses.ThereAreNonOrderWarehouses = 0
		|				AND TotalCompositionOfWarehouses.ThereAreAdvancedWarehouses > 0
		|				AND ISNULL(GoodsForIssueBalance.ToShipBalance, 0) <= 0
		|				AND ISNULL(GoodsForIssueBalance.AssemblyInProgressBalance, 0) <= 0
		|				AND ISNULL(GoodsForIssueBalance.AssembledBalance, 0) <= 0)
		|	AND CustomerInvoice.Status <> VALUE(Enum.StatusesOfCustomerInvoices.Shipped) 
		|
		|UNION ALL
		|
		|SELECT
		|	CustomerInvoice.Ref AS ReferenceToEventObject,
		|	CustomerInvoice.Ref AS SubjectOf,
		|	&SwitchToShippedStatus AS EventType,
		|	CustomerInvoice.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
		|	CustomerInvoice.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	&CurrentBusinessUnit AS Status,
		|	CustomerInvoice.Partner,
		|	CustomerInvoice.Manager AS EmployeeResponsible
		|FROM
		|
		|	Document.CustomerInvoice AS CustomerInvoice
		|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTObjectsOfRtiuCalculations.ARAPObject FROM TTObjectsOfRtiuCalculations)) AS CustomersARAPAccounting
		|		ON CustomerInvoice.Ref = CustomersARAPAccounting.ARAPObject.Object
		|WHERE
		|	CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment) 
		|	AND CustomerInvoice.AmountARAP >= ISNULL(CustomersARAPAccounting.AmountDueBalance, 0)
		|	AND &TextOfSelectionCondition";
			
	EndIf;
	
	StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients = True;
	AddRequestForIssues(QueryText,"Document.CustomerInvoice",StructureOfReportGeneration);
	
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	RequestTextForWarehousesImplementations = "
	|SELECT ALLOWED
	|	SalesOfGoodsServicesGoods.Ref,
	|	SUM(CASE
	|			WHEN ISNULL(Warehouses.UseWarehouseManagemantSystemForGoodsIssue, FALSE)
	|				AND CustomerInvoice.Date >= ISNULL(Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
	|				THEN 1
	|			ELSE 0
	|		END) AS ThereAreAdvancedWarehouses,
	|	SUM(CASE
	|			WHEN ISNULL(Warehouses.UseWarehouseManagemantSystemForGoodsIssue, FALSE) = FALSE
	|				OR CustomerInvoice.Date < ISNULL(Warehouses.StartDateOfWarehouseManagemantSystemForGoodsIssue, DATETIME(1,1,1))
	|				THEN 1
	|			ELSE 0
	|		END) AS ThereAreNonOrderWarehouses
	|INTO TotalCompositionOfWarehouses
	|FROM
	|	Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	|		LEFT JOIN Catalog.Warehouses AS Warehouses
	|		ON SalesOfGoodsServicesGoods.Warehouse = Warehouses.Ref
	|		INNER JOIN Document.CustomerInvoice AS CustomerInvoice
	|		ON SalesOfGoodsServicesGoods.Ref = CustomerInvoice.Ref
	|WHERE
	|	CustomerInvoice.Status = VALUE(Enum.StatusesOfCustomerInvoices.Shipped) 
	|	AND &TextOfSelectionCondition
	|
	|GROUP BY
	|	SalesOfGoodsServicesGoods.Ref
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	TextRequestCalculationObjects = "
	|SELECT
	|	ARAPObjects.Ref AS ARAPObject
	|INTO TTObjectsOfRtiuCalculations
	|FROM 
	|	Catalog.ARAPObjects AS ARAPObjects
	|WHERE
	|	ARAPObjects.Object REFS Document.CustomerInvoice
	|	AND CAST(ARAPObjects.Object AS Document.CustomerInvoice).Status = VALUE(Enum.StatusesOfCustomerInvoices.ForPrepayment)
	|	AND &TextOfOrderConditions
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND CustomerInvoice.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfOrderConditions ="
		|AND ARAPObjects.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TermsAndConditionsAndPaymentPlan = "
		|AND ARAPObject.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfOrderConditions     ="";
		TextOfSelectionCondition          ="";
		TermsAndConditionsAndPaymentPlan = "";
		
	EndIf;
	
	QueryText                    = StrReplace(QueryText,"AND &TermsAndConditionsAndPaymentPlan", TermsAndConditionsAndPaymentPlan);
	QueryText                    = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	RequestTextForWarehousesImplementations = StrReplace(RequestTextForWarehousesImplementations,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	TextRequestCalculationObjects      = StrReplace(TextRequestCalculationObjects,"AND &TextOfOrderConditions",TextOfOrderConditions);
	
	StructureOfReportGeneration.TextQueriesTemporaryTables = StructureOfReportGeneration.TextQueriesTemporaryTables +RequestTextForWarehousesImplementations + TextRequestCalculationObjects;
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.CustomerInvoice");
	
	Return QueryText; 

EndFunction

Function QueryTextRequestsForReturn(Query,StructureOfReportGeneration)

	If StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder.ReturnedGoods.DateOfReceipt < &EndDate
			|			AND ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
			|		OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
			|		OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
			|			AND &TextOfConditionParametersOfTTSelection";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.Indexes = "ReferenceOrder, RowCode";
		TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
		
		TT_ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = TT_ShipmentOrdersTurnoverExpanded
		+ Common.QueryBatchSeparator()
		+ "
		|SELECT
		|	RequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	RequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&ApprovalOfRefundRequest AS EventType,
		|	RequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(RequestForReturnOfGoodsFromCustomer.ApprovalDate,DAY)
		|	END AS EventDate,
		|	RequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	RequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	RequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
		|WHERE
		|	RequestForReturnOfGoodsFromCustomer.Posted
		|	AND RequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|	AND CASE
		|			WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE RequestForReturnOfGoodsFromCustomer.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionCondition
		|	
		|	UNION ALL
		|	
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&MakingRequestForRefund AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerReturnedGoods.DateOfReceipt, DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerReturnedGoods.DateOfReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.ApprovalDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Overdue
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|		ON RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|		INNER JOIN TT_ShipmentOrdersTurnoverExpanded AS BalanceTable
		|		ON RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref = BalanceTable.ReferenceOrder
		|			AND RequestForReturnOfGoodsFromCustomerReturnedGoods.RowCode = BalanceTable.RowCode
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|			OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|			OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip))
		|	AND (BalanceTable.ForRegistrationOnReturnsQuantityTurnover -
		|		BalanceTable.IssuedByReturnsQuantityTurnover) > 0
		|	AND &TextOfSelectionConditionDocument
		|	
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPaymentBeforeSecuringRefundRequest,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.RequestForReturnOfGoodsFromCustomer
		|	AND PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&RequiresSupply AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoods_.DateOfShipment = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoods_.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				WHEN RequestForReturnOfGoods_.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|		ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoods_.Ref
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND RequestForReturnOfGoods_.SupplyOption IN (
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.NotRequired))
		|	AND NOT RequestForReturnOfGoods_.WithAssignment
		|	AND NOT RequestForReturnOfGoods_.Canceled
		|	AND CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPrepaymentBeforeShipmentRequestForRefund,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.RequestForReturnOfGoodsFromCustomer
		|	AND PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&PreparationForShipmentRequestForReturn AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoods_.DateOfShipment = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoods_.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				WHEN RequestForReturnOfGoods_.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|		ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoods_.Ref
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND RequestForReturnOfGoods_.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT RequestForReturnOfGoods_.Canceled
		|	AND CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RequestForReturnOfGoodsFromCustomerGoods.Ref AS ReferenceToEventObject,
		|	RequestForReturnOfGoodsFromCustomerGoods.Ref AS SubjectOf,
		|	&ShipmentReturnRequest AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Overdue
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoodsFromCustomerGoods
		|			ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoodsFromCustomerGoods.Ref
		|	LEFT JOIN #ShipmentOrdersTurnoverExpanded AS TurnoversByOrders
		|	ON
		|		DocumentRequestForReturnOfGoodsFromCustomer.Ref = TurnoversByOrders.ReferenceOrder
		|		AND (TurnoversByOrders.ForRegistrationQuantityTurnover -
		|			TurnoversByOrders.IssuedQuantityTurnover) <> 0
		|	LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|		,
		|		DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
		|			AND CAST(DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).SubstituteGoods.DateOfShipment < &EndDate
		|			AND (DocumentShipments.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|			OR DocumentShipments.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
		|	ON
		|		DocumentRequestForReturnOfGoodsFromCustomer.Ref = GoodsForIssueBalance.DocumentShipments
		|WHERE
		|	ISNULL(TurnoversByOrders.ForRegistrationQuantityTurnover - TurnoversByOrders.IssuedQuantityTurnover, 0) <>
		|		ISNULL(GoodsForIssueBalance.ToShipBalance, 0)
		|	AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPaymentAfterShipmentRequestForRefund,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.RequestForReturnOfGoodsFromCustomer
		|	AND (PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)
		|		OR PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&MarkWhenRefundRequestWasCompleted AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTObjectsOfRefundRequestCalculations.ARAPObject FROM TTObjectsOfRefundRequestCalculations)) AS CustomersARAPAccounting
		|	ON DocumentRequestForReturnOfGoodsFromCustomer.ARAPObject = CustomersARAPAccounting.ARAPObject
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND &MonitorOrderClosing
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND DocumentRequestForReturnOfGoodsFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND ISNULL(CustomersARAPAccounting.ToShipBalance, 0) = 0
		|	AND ISNULL(CustomersARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"VALUETYPE(ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
			|		AND ReferenceOrder.SubstituteGoods.DateOfShipment < &EndDate
			|		AND (ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
			|			OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
			|		AND &TextOfOrderCondition";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
	Else
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"ReferenceOrder.ReturnedGoods.DateOfReceipt < &EndDate
			|			AND ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
			|		OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
			|		OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
			|			AND &TextOfConditionParametersOfTTSelection";
		TableFormationParameters.Group = "ReferenceOrder, RowCode";
		TableFormationParameters.Indicators = "ToRegisterForReturns, RegisteredOnReturns";
		TableFormationParameters.Resources = "Count";
		TableFormationParameters.Indexes = "ReferenceOrder, RowCode";
		TableFormationParameters.TempTableName = "TT_ShipmentOrdersTurnoverExpanded";
		
		TT_ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = TT_ShipmentOrdersTurnoverExpanded
		+ Common.QueryBatchSeparator()
		+ "
		|SELECT
		|	RequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	RequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&ApprovalOfRefundRequest AS EventType,
		|	RequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(RequestForReturnOfGoodsFromCustomer.ApprovalDate,DAY)
		|	END AS EventDate,
		|	RequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	RequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	RequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS RequestForReturnOfGoodsFromCustomer
		|WHERE
		|	RequestForReturnOfGoodsFromCustomer.Posted
		|	AND RequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.NotAgreedUpon)
		|	AND CASE
		|			WHEN RequestForReturnOfGoodsFromCustomer.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE RequestForReturnOfGoodsFromCustomer.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionCondition
		|	
		|	UNION ALL
		|	
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&MakingRequestForRefund AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerReturnedGoods.DateOfReceipt, DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerReturnedGoods.DateOfReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.ApprovalDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Overdue
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.ReturnedGoods AS RequestForReturnOfGoodsFromCustomerReturnedGoods
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|		ON RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|		INNER JOIN TT_ShipmentOrdersTurnoverExpanded AS BalanceTable
		|		ON RequestForReturnOfGoodsFromCustomerReturnedGoods.Ref = BalanceTable.ReferenceOrder
		|			AND RequestForReturnOfGoodsFromCustomerReturnedGoods.RowCode = BalanceTable.RowCode
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)
		|			OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|			OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip))
		|	AND (BalanceTable.ForRegistrationOnReturnsQuantityTurnover -
		|		BalanceTable.IssuedByReturnsQuantityTurnover) > 0
		|	AND &TextOfSelectionConditionDocument
		|	
		|UNION ALL
		|
		|SELECT
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&WaitingForPaymentBeforeSecuringRefundRequest,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,DAY),
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END AS Field3,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|		ON RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomersARAPAccountingBalance
		|		ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = CustomersARAPAccountingBalance.Object
		|			AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = CustomersARAPAccountingBalance.PaymentDate
		|			AND CustomersARAPAccountingBalance.PaymentDate < &EndDate
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)
		|			OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn))
		|	AND DocumentRequestForReturnOfGoodsFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|	AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref,
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager
		|
		|HAVING
		|	SUM(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomersARAPAccountingBalance.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&RequiresSupply AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoods_.DateOfShipment = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoods_.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				WHEN RequestForReturnOfGoods_.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|		ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoods_.Ref
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND RequestForReturnOfGoods_.SupplyOption IN (
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.NotRequired))
		|	AND NOT RequestForReturnOfGoods_.WithAssignment
		|	AND NOT RequestForReturnOfGoods_.Canceled
		|	AND CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&WaitingForPrepaymentBeforeShipmentRequestForRefund AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|		ON RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomersARAPAccountingBalance
		|		ON RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref = CustomersARAPAccountingBalance.Object
		|			AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = CustomersARAPAccountingBalance.PaymentDate
		|			AND CustomersARAPAccountingBalance.PaymentDate < &EndDate
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ForReturn)  OR
		|		DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND DocumentRequestForReturnOfGoodsFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|	AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|	
		|GROUP BY
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref,
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager
		|
		|HAVING
		|	SUM(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomersARAPAccountingBalance.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&PreparationForShipmentRequestForReturn AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoods_.DateOfShipment = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN RequestForReturnOfGoods_.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &CurrentBusinessUnit
		|				WHEN RequestForReturnOfGoods_.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|					THEN &Upcoming
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoods_
		|		ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoods_.Ref
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND RequestForReturnOfGoods_.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT RequestForReturnOfGoods_.Canceled
		|	AND CASE
		|		WHEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentRequestForReturnOfGoodsFromCustomer.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	RequestForReturnOfGoodsFromCustomerGoods.Ref AS ReferenceToEventObject,
		|	RequestForReturnOfGoodsFromCustomerGoods.Ref AS SubjectOf,
		|	&ShipmentReturnRequest AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN RequestForReturnOfGoodsFromCustomerGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Overdue
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	INNER JOIN Document.RequestForReturnOfGoodsFromCustomer.SubstituteGoods AS RequestForReturnOfGoodsFromCustomerGoods
		|			ON DocumentRequestForReturnOfGoodsFromCustomer.Ref = RequestForReturnOfGoodsFromCustomerGoods.Ref
		|	LEFT JOIN #ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|	ON
		|		DocumentRequestForReturnOfGoodsFromCustomer.Ref = ShippingOrdersTurnover.ReferenceOrder
		|		AND (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|			ShippingOrdersTurnover.IssuedQuantityTurnover) <> 0
		|	LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|		,
		|		DocumentShipments REFS Document.RequestForReturnOfGoodsFromCustomer
		|			AND CAST(DocumentShipments AS Document.RequestForReturnOfGoodsFromCustomer).SubstituteGoods.DateOfShipment < &EndDate
		|			AND (DocumentShipments.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|			OR DocumentShipments.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply)) AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
		|	ON
		|		DocumentRequestForReturnOfGoodsFromCustomer.Ref = GoodsForIssueBalance.DocumentShipments
		|WHERE
		|	ISNULL(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover, 0) <>
		|		ISNULL(GoodsForIssueBalance.ToShipBalance, 0)
		|	AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&WaitingForPaymentAfterShipmentRequestForRefund AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL AS Field1,
		|	NULL AS Field2,
		|	CASE
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer.PaymentScheduleSteps AS RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps
		|		INNER JOIN Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|		ON RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref = DocumentRequestForReturnOfGoodsFromCustomer.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomersARAPAccountingBalance
		|		ON RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref = CustomersARAPAccountingBalance.Object
		|			AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate = CustomersARAPAccountingBalance.PaymentDate
		|			AND CustomersARAPAccountingBalance.PaymentDate < &EndDate
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND DocumentRequestForReturnOfGoodsFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND (RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)
		|		OR RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
		|	AND RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.Ref,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref,
		|	RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager
		|
		|HAVING
		|	SUM(RequestForReturnOfGoodsFromCustomerPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomersARAPAccountingBalance.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS ReferenceToEventObject,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Ref AS SubjectOf,
		|	&MarkWhenRefundRequestWasCompleted AS EventType,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Partner AS Partner,
		|	DocumentRequestForReturnOfGoodsFromCustomer.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.RequestForReturnOfGoodsFromCustomer AS DocumentRequestForReturnOfGoodsFromCustomer
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTObjectsOfRefundRequestCalculations.ARAPObject FROM TTObjectsOfRefundRequestCalculations)) AS CustomersARAPAccounting
		|	ON DocumentRequestForReturnOfGoodsFromCustomer.ARAPObject = CustomersARAPAccounting.ARAPObject
		|WHERE
		|	DocumentRequestForReturnOfGoodsFromCustomer.Posted
		|	AND &MonitorOrderClosing
		|	AND (DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
		|		OR DocumentRequestForReturnOfGoodsFromCustomer.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND DocumentRequestForReturnOfGoodsFromCustomer.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND ISNULL(CustomersARAPAccounting.ToShipBalance, 0) = 0
		|	AND ISNULL(CustomersARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.ConditionText =
			"VALUETYPE(ReferenceOrder) = TYPE(Document.RequestForReturnOfGoodsFromCustomer)
			|		AND ReferenceOrder.SubstituteGoods.DateOfShipment < &EndDate
			|		AND (ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip)
			|			OR ReferenceOrder.Status = VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
			|	AND &TextOfOrderCondition";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients = True;
		
	EndIf;
	
	TextRequestCalculationObjects = "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TTObjectsOfRefundRequestCalculations
		|FROM 
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object REFS Document.RequestForReturnOfGoodsFromCustomer
		|	AND CAST(ARAPObjects.Object AS Document.RequestForReturnOfGoodsFromCustomer).Status IN (VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToShip),
		|					VALUE(Enum.StatusesOfRequestsForReturnOfGoodsFromCustomers.ToSupply))
		|	AND &ConditionTextAndCalculationObjects
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////////////////////////////";
	
	AddRequestForIssues(QueryText,"Document.RequestForReturnOfGoodsFromCustomer",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfConditionParametersOfTTSelection = "
		|AND ReferenceOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionCondition ="
		|AND RequestForReturnOfGoodsFromCustomer.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfOrderCondition ="
		|AND ReferenceOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionConditionDocument ="
		|AND DocumentRequestForReturnOfGoodsFromCustomer.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfConditionAndDocumentOfShipment = "
		|AND DocumentShipments.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TermsAndConditionsAndPaymentPlan = "
		|AND ARAPObject.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		ConditionTextAndCalculationObjects = "
		|AND ARAPObjects.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfConditionParametersOfTTSelection      = "";
		TextOfSelectionCondition                 = "";
		TextOfOrderCondition                 = "";
		TextOfSelectionConditionDocument         = "";
		TermsAndConditionsAndPaymentPlan        = "";
		TextOfConditionAndDocumentOfShipment = "";
		ConditionTextAndCalculationObjects  = "";
		
	EndIf;;
	
	QueryText = StrReplace(QueryText,"AND &TextOfConditionParametersOfTTSelection", TextOfConditionParametersOfTTSelection);
	QueryText = StrReplace(QueryText,"AND &TextOfConditionAndDocumentOfShipment",TextOfConditionAndDocumentOfShipment);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionConditionDocument",TextOfSelectionConditionDocument);
	QueryText = StrReplace(QueryText,"AND &TermsAndConditionsAndPaymentPlan", TermsAndConditionsAndPaymentPlan);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	QueryText = StrReplace(QueryText,"AND &TextOfOrderCondition",TextOfOrderCondition);
	TextRequestCalculationObjects = StrReplace(TextRequestCalculationObjects,"AND &ConditionTextAndCalculationObjects",ConditionTextAndCalculationObjects);
	
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	StructureOfReportGeneration.TextQueriesTemporaryTables = StructureOfReportGeneration.TextQueriesTemporaryTables + TextRequestCalculationObjects;
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.RequestForReturnOfGoodsFromCustomer");
	
	Return QueryText;

EndFunction

Function QueryTextPurchaseOrders(Query,StructureOfReportGeneration)
	
	If StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		
				QueryText = "
		|SELECT
		|	PurchaseOrder.Ref AS ReferenceToEventObject,
		|	PurchaseOrder.Ref AS SubjectOf,
		|	&SupplierOrderApproval AS EventType,
		|	PurchaseOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(PurchaseOrder.ApprovalDate,DAY)
		|	END AS EventDate,
		|	PurchaseOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < PurchaseOrder.ApprovalDate
		|					THEN &Upcoming
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = PurchaseOrder.ApprovalDate
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	PurchaseOrder.Partner AS Partner,
		|	PurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Posted
		|	AND PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
		|	AND CASE
		|			WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE PurchaseOrder.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionCondition
		|
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&MakeAdvancePaymentBeforeConfirmation,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.PurchaseOrder
		|	AND PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS VendorsARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON VendorsARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	VendorsARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&MakingAdvancePaymentBeforeShipment,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.PurchaseOrder
		|	AND PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS VendorsARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON VendorsARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	VendorsARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	PurchaseOrderGoods.Ref AS ReferenceToEventObject,
		|	PurchaseOrderGoods.Ref AS SubjectOf,
		|	&ReceivingOrder AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(PurchaseOrderGoods.DateOfReceipt, DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN PurchaseOrderGoods.DateOfReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN PurchaseOrderGoods.DateOfReceipt = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|	ELSE &Overdue
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(
		|		,
		|		PurchaseOrder REFS Document.PurchaseOrder
		|			AND PurchaseOrder.Goods.DateOfReceipt < &EndDate
		|			AND (PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses) AND &TextOfSelectionCondition) AS PurchaseOrdersBalance
		|	INNER JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
		|		ON PurchaseOrdersBalance.PurchaseOrder = DocumentPurchaseOrder.Ref
		|	INNER JOIN Document.PurchaseOrder.Goods AS PurchaseOrderGoods
		|		ON PurchaseOrdersBalance.RowCode = PurchaseOrderGoods.RowCode
		|			AND PurchaseOrdersBalance.PurchaseOrder = PurchaseOrderGoods.Ref
		|WHERE
		|	PurchaseOrdersBalance.ToRegisterBalance > 0
		|
		|UNION ALL
		|
		|	SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&PaymentAfterReceipt,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.PurchaseOrder
		|	AND (PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment)
		|		OR PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt))
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS VendorsARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON VendorsARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	VendorsARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentPurchaseOrder.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&MarkWhenRefundRequestWasCompleted AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder AS DocumentPurchaseOrder
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTSettlementObjectsOrdersToSupplier.ARAPObject FROM TTSettlementObjectsOrdersToSupplier)) AS VendorsARAPAccounting
		|	ON DocumentPurchaseOrder.ARAPObject = VendorsARAPAccounting.ARAPObject
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND &MonitorOrderClosing
		|	AND DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND ISNULL(VendorsARAPAccounting.ToReceiveBalance, 0) = 0
		|	AND ISNULL(VendorsARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument";
		
	Else
		
		QueryText = "
		|SELECT
		|	PurchaseOrder.Ref AS ReferenceToEventObject,
		|	PurchaseOrder.Ref AS SubjectOf,
		|	&SupplierOrderApproval AS EventType,
		|	PurchaseOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(PurchaseOrder.ApprovalDate,DAY)
		|	END AS EventDate,
		|	PurchaseOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < PurchaseOrder.ApprovalDate
		|					THEN &Upcoming
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = PurchaseOrder.ApprovalDate
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	PurchaseOrder.Partner AS Partner,
		|	PurchaseOrder.Manager AS EmployeeResponsible
		|  ,&TheTextToPut
		|FROM
		|	Document.PurchaseOrder AS PurchaseOrder
		|WHERE
		|	PurchaseOrder.Posted
		|	AND PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.NotApproved)
		|	AND CASE
		|			WHEN PurchaseOrder.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE PurchaseOrder.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionCondition
		|
		|UNION ALL
		|
		|SELECT
		|	OrderToSupplierStagesOfPaymentSchedule.Ref,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&MakeAdvancePaymentBeforeConfirmation,
		|	DocumentPurchaseOrder.Date,
		|	ENDOFPERIOD(OrderToSupplierStagesOfPaymentSchedule.PaymentDate,DAY),
		|	DocumentPurchaseOrder.Presentation,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
		|		INNER JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = DocumentPurchaseOrder.Ref
		|
		|		LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = TableOfSupplierBalances.Object
		|			AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate = TableOfSupplierBalances.PaymentDate
		|			AND TableOfSupplierBalances.PaymentDate < &EndDate 
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND OrderToSupplierStagesOfPaymentSchedule.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeConfirmation)
		|	AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	OrderToSupplierStagesOfPaymentSchedule.Ref,
		|	DocumentPurchaseOrder.Ref,
		|	OrderToSupplierStagesOfPaymentSchedule.PaymentDate,
		|	DocumentPurchaseOrder.Date,
		|	DocumentPurchaseOrder.Presentation,
		|	DocumentPurchaseOrder.Partner,
		|	DocumentPurchaseOrder.Manager
		|
		|HAVING
		|	SUM(OrderToSupplierStagesOfPaymentSchedule.PaymentAmount) > 0 AND
		|	ISNULL(SUM(TableOfSupplierBalances.AmountDueBalance), 0) < 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentPurchaseOrder.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&OrderConfirmation AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentPurchaseOrder.DateOfFirstReceipt,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN DocumentPurchaseOrder.DateOfFirstReceipt = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder AS DocumentPurchaseOrder
		|
		|	LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|	ON DocumentPurchaseOrder.Ref = TableOfSupplierBalances.Object
		|		AND CASE
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN DocumentPurchaseOrder.DateOfFirstReceipt < &EndDate
		|			ELSE TRUE
		|		END
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation > 0
		|	AND DocumentPurchaseOrder.DocumentAmount + ISNULL(TableOfSupplierBalances.AmountDueBalance, 0) >= DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation
		|	AND CASE
		|		WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN DocumentPurchaseOrder.DateOfFirstReceipt < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	OrderToSupplierStagesOfPaymentSchedule.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&MakingAdvancePaymentBeforeShipment AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(OrderToSupplierStagesOfPaymentSchedule.PaymentDate,DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
		|		INNER JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = DocumentPurchaseOrder.Ref
		|	
		|		LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = TableOfSupplierBalances.Object
		|			AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate = TableOfSupplierBalances.PaymentDate
		|			AND TableOfSupplierBalances.PaymentDate < &EndDate 
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND ( DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Approved) 
		|		OR DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|		OR &NotUsePurchaseOrderStatuses)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND OrderToSupplierStagesOfPaymentSchedule.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.PrepaymentBeforeReceipt)
		|	AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	OrderToSupplierStagesOfPaymentSchedule.Ref,
		|	DocumentPurchaseOrder.Ref,
		|	OrderToSupplierStagesOfPaymentSchedule.PaymentDate,
		|	DocumentPurchaseOrder.Date,
		|	DocumentPurchaseOrder.Presentation,
		|	DocumentPurchaseOrder.Partner,
		|	DocumentPurchaseOrder.Manager
		|
		|HAVING
		|	SUM(OrderToSupplierStagesOfPaymentSchedule.PaymentAmount) > 0 AND
		|	ISNULL(SUM(TableOfSupplierBalances.AmountDueBalance), 0) < 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentPurchaseOrder.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&PreparationForAdmission AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentPurchaseOrder.DateOfFirstReceipt, DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|	WHEN DocumentPurchaseOrder.DateOfFirstReceipt = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|	ELSE CASE
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder AS DocumentPurchaseOrder
		|	LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|	ON DocumentPurchaseOrder.Ref = TableOfSupplierBalances.Object
		|		AND CASE
		|			WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN DocumentPurchaseOrder.DateOfFirstReceipt < &EndDate
		|			ELSE TRUE
		|		END 
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND (DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation + DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt) > 0
		|	AND DocumentPurchaseOrder.DocumentAmount + ISNULL(TableOfSupplierBalances.AmountDueBalance, 0) >= (DocumentPurchaseOrder.AmountAdvanceBeforeConfirmation + DocumentPurchaseOrder.PrepaymentAmountBeforeReceipt)
		|	AND CASE
		|		WHEN DocumentPurchaseOrder.DateOfFirstReceipt <> DATETIME(1, 1, 1)
		|			THEN DocumentPurchaseOrder.DateOfFirstReceipt < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	PurchaseOrderGoods.Ref AS ReferenceToEventObject,
		|	PurchaseOrderGoods.Ref AS SubjectOf,
		|	&ReceivingOrder AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(PurchaseOrderGoods.DateOfReceipt, DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN PurchaseOrderGoods.DateOfReceipt > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN PurchaseOrderGoods.DateOfReceipt = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|	ELSE &Overdue
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.PurchaseOrders.Balance(
		|		,
		|		PurchaseOrder REFS Document.PurchaseOrder
		|			AND PurchaseOrder.Goods.DateOfReceipt < &EndDate
		|			AND (PurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_) OR &NotUsePurchaseOrderStatuses) AND &TextOfSelectionCondition) AS PurchaseOrdersBalance
		|	INNER JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
		|		ON PurchaseOrdersBalance.PurchaseOrder = DocumentPurchaseOrder.Ref
		|	INNER JOIN Document.PurchaseOrder.Goods AS PurchaseOrderGoods
		|		ON PurchaseOrdersBalance.RowCode = PurchaseOrderGoods.RowCode
		|			AND PurchaseOrdersBalance.PurchaseOrder = PurchaseOrderGoods.Ref
		|WHERE
		|	PurchaseOrdersBalance.ToRegisterBalance > 0
		|
		|UNION ALL
		|
		|SELECT
		|	OrderToSupplierStagesOfPaymentSchedule.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&PaymentAfterReceipt AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(OrderToSupplierStagesOfPaymentSchedule.PaymentDate,DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN OrderToSupplierStagesOfPaymentSchedule.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder.PaymentScheduleSteps AS OrderToSupplierStagesOfPaymentSchedule
		|		INNER JOIN Document.PurchaseOrder AS DocumentPurchaseOrder
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = DocumentPurchaseOrder.Ref
		|
		|		LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|		ON OrderToSupplierStagesOfPaymentSchedule.Ref = TableOfSupplierBalances.Object
		|			AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate = TableOfSupplierBalances.PaymentDate
		|			AND TableOfSupplierBalances.PaymentDate < &EndDate 
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND (DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|		OR &NotUsePurchaseOrderStatuses)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND (OrderToSupplierStagesOfPaymentSchedule.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterShipment)
		|		OR OrderToSupplierStagesOfPaymentSchedule.PaymentOption = VALUE(Enum.OptionsForControllingPaymentToSupplier.CreditAfterReceipt))
		|	AND OrderToSupplierStagesOfPaymentSchedule.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	OrderToSupplierStagesOfPaymentSchedule.Ref,
		|	DocumentPurchaseOrder.Ref,
		|	OrderToSupplierStagesOfPaymentSchedule.PaymentDate,
		|	DocumentPurchaseOrder.Date,
		|	DocumentPurchaseOrder.Presentation,
		|	DocumentPurchaseOrder.Partner,
		|	DocumentPurchaseOrder.Manager
		|
		|HAVING
		|	SUM(OrderToSupplierStagesOfPaymentSchedule.PaymentAmount) > 0 AND
		|	ISNULL(SUM(TableOfSupplierBalances.AmountDueBalance), 0) < 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentPurchaseOrder.Ref AS ReferenceToEventObject,
		|	DocumentPurchaseOrder.Ref AS SubjectOf,
		|	&MarkWhenRefundRequestWasCompleted AS EventType,
		|	DocumentPurchaseOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentPurchaseOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentPurchaseOrder.Partner AS Partner,
		|	DocumentPurchaseOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.PurchaseOrder AS DocumentPurchaseOrder
		|	LEFT JOIN AccumulationRegister.VendorsARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTSettlementObjectsOrdersToSupplier.ARAPObject FROM TTSettlementObjectsOrdersToSupplier)) AS VendorsARAPAccounting
		|	ON DocumentPurchaseOrder.ARAPObject = VendorsARAPAccounting.ARAPObject
		|WHERE
		|	DocumentPurchaseOrder.Posted
		|	AND &MonitorOrderClosing
		|	AND DocumentPurchaseOrder.Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|	AND DocumentPurchaseOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND ISNULL(VendorsARAPAccounting.ToReceiveBalance, 0) = 0
		|	AND ISNULL(VendorsARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument";
		
		StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocuments = True;
	
	EndIf;
	
	TextRequestCalculationObjects = "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TTSettlementObjectsOrdersToSupplier
		|FROM 
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object REFS Document.PurchaseOrder
		|	AND CAST(ARAPObjects.Object AS Document.PurchaseOrder).Status = VALUE(Enum.PurchaseOrderStatuses.Confirmed_)
		|	AND &ConditionTextAndCalculationObjects
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////////////////////////////";
	
	AddRequestForIssues(QueryText,"Document.PurchaseOrder",StructureOfReportGeneration);
		
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND PurchaseOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionConditionDocument ="
		|AND DocumentPurchaseOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TermsAndConditionsAndPaymentPlan = "
		|AND ARAPObject.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		ConditionTextAndCalculationObjects = "
		|AND ARAPObjects.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition                 = "";
		TextOfSelectionConditionDocument         = "";
		TermsAndConditionsAndPaymentPlan        = "";
		ConditionTextAndCalculationObjects  = "";
		
	EndIf;
	
	QueryText               = StrReplace(QueryText,"AND &TextOfSelectionConditionDocument",TextOfSelectionConditionDocument);
	QueryText               = StrReplace(QueryText,"AND &TermsAndConditionsAndPaymentPlan", TermsAndConditionsAndPaymentPlan);
	QueryText               = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	TextRequestCalculationObjects = StrReplace(TextRequestCalculationObjects,"AND &ConditionTextAndCalculationObjects",ConditionTextAndCalculationObjects);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.PurchaseOrder");
	
	StructureOfReportGeneration.TextQueriesTemporaryTables = StructureOfReportGeneration.TextQueriesTemporaryTables + TextRequestCalculationObjects;
	
	Return QueryText;

EndFunction

Function QueryTextSalesOrders(Query,StructureOfReportGeneration)
	
	If StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then
		
		QueryText = "
		|SELECT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&SalesOrderApproval AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(DocumentSalesOrder.ApprovalDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < DocumentSalesOrder.ApprovalDate
		|					THEN &Upcoming
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = DocumentSalesOrder.ApprovalDate
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	AND CASE
		|			WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE DocumentSalesOrder.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPaymentBeforeSecuring,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|  ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.SalesOrder
		|	AND PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&RequiresSupply AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentSalesOrder.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|	WHEN CustomerOrderGoods.DateOfShipment = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|	ELSE CASE
		|			WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND CustomerOrderGoods.SupplyOption IN (
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.NotRequired))
		|	AND NOT CustomerOrderGoods.WithAssignment
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentSalesOrder.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPrepaymentBeforeShipment,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.SalesOrder
		|	AND PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&PreparationForShipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentSalesOrder.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|	WHEN CustomerOrderGoods.DateOfShipment = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|	ELSE CASE
		|			WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND CustomerOrderGoods.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentSalesOrder.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	CustomerOrderGoods.Ref AS ReferenceToEventObject,
		|	CustomerOrderGoods.Ref AS SubjectOf,
		|	&Shipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(CustomerOrderGoods.DateOfShipment,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|	ELSE &Overdue
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|	LEFT JOIN #ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|	ON
		|		DocumentSalesOrder.Ref = ShippingOrdersTurnover.ReferenceOrder
		|		AND (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|			ShippingOrdersTurnover.IssuedQuantityTurnover) <> 0
		|	LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|		,
		|		DocumentShipments REFS Document.SalesOrder
		|			AND CAST(DocumentShipments AS Document.SalesOrder).Goods.DateOfShipment < &EndDate
		|			AND (DocumentShipments.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|			OR DocumentShipments.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)) AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
		|	ON
		|		DocumentSalesOrder.Ref = GoodsForIssueBalance.DocumentShipments
		|WHERE
		|	ISNULL(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover, 0) > 0 
		|	AND ISNULL(GoodsForIssueBalance.ToShipBalance, 0) > 0 
		|	AND ISNULL(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover, 0) <> ISNULL(GoodsForIssueBalance.ToShipBalance, 0)
		|	AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&WaitingForPaymentAfterShipment,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Document.SalesOrder
		|	AND (PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)
		|		OR PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&ClosingOrder AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTCalculationObjectsOrder.ARAPObject FROM TTCalculationObjectsOrder)) AS CustomersARAPAccounting
		|	ON DocumentSalesOrder.ARAPObject = CustomersARAPAccounting.ARAPObject
		|WHERE
		|	DocumentSalesOrder.Posted 
		|	AND &MonitorOrderClosing
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|	AND ISNULL(CustomersARAPAccounting.ToShipBalance, 0) = 0
		|	AND ISNULL(CustomersARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument ";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.EndOfPeriod = "&EndDate";
		TableFormationParameters.ConditionText =
			"VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
			|		AND (ReferenceOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
			|			OR ReferenceOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
			|	AND &TextOfTermsAndConditionsForCustomerSOrder";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
	Else
	
		QueryText = "
		|SELECT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&SalesOrderApproval AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE ENDOFPERIOD(DocumentSalesOrder.ApprovalDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|			THEN &CurrentBusinessUnit
		|		ELSE CASE
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < DocumentSalesOrder.ApprovalDate
		|					THEN &Upcoming
		|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = DocumentSalesOrder.ApprovalDate
		|					THEN &CurrentBusinessUnit
		|				ELSE &Overdue
		|			END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.NotApproved)
		|	AND CASE
		|			WHEN DocumentSalesOrder.ApprovalDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE DocumentSalesOrder.ApprovalDate < &EndDate
		|		END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrderPaymentScheduleSteps.Ref,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&WaitingForPaymentBeforeSecuring,
		|	DocumentSalesOrder.Date,
		|	ENDOFPERIOD(SalesOrderPaymentScheduleSteps.PaymentDate,DAY),
		|	DocumentSalesOrder.Presentation,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
		|		INNER JOIN Document.SalesOrder AS DocumentSalesOrder
		|		ON SalesOrderPaymentScheduleSteps.Ref = DocumentSalesOrder.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomerBalanceTable
		|		ON SalesOrderPaymentScheduleSteps.Ref = CustomerBalanceTable.Object
		|			AND SalesOrderPaymentScheduleSteps.PaymentDate = CustomerBalanceTable.PaymentDate
		|			AND CustomerBalanceTable.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|	AND DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeProvision)
		|	AND SalesOrderPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	SalesOrderPaymentScheduleSteps.Ref,
		|	DocumentSalesOrder.Ref,
		|	SalesOrderPaymentScheduleSteps.PaymentDate,
		|	DocumentSalesOrder.Date,
		|	DocumentSalesOrder.Presentation,
		|	DocumentSalesOrder.Partner,
		|	DocumentSalesOrder.Manager
		|
		|HAVING
		|	SUM(SalesOrderPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomerBalanceTable.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&RequiresSupply AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentSalesOrder.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|	WHEN CustomerOrderGoods.DateOfShipment = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|	ELSE CASE
		|			WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND CustomerOrderGoods.SupplyOption IN (
		|		VALUE(Enum.SupplyOptions.ReserveAsReceived),
		|		VALUE(Enum.SupplyOptions.ToSupply),
		|		VALUE(Enum.SupplyOptions.NotRequired))
		|	AND NOT CustomerOrderGoods.WithAssignment
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentSalesOrder.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrderPaymentScheduleSteps.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&WaitingForPrepaymentBeforeShipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(SalesOrderPaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
		|		INNER JOIN Document.SalesOrder AS DocumentSalesOrder
		|		ON SalesOrderPaymentScheduleSteps.Ref = DocumentSalesOrder.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomerBalanceTable
		|		ON SalesOrderPaymentScheduleSteps.Ref = CustomerBalanceTable.Object
		|			AND SalesOrderPaymentScheduleSteps.PaymentDate = CustomerBalanceTable.PaymentDate
		|			AND CustomerBalanceTable.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)
		|	AND DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.PrepaymentBeforeShipment)
		|	AND SalesOrderPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	SalesOrderPaymentScheduleSteps.Ref,
		|	DocumentSalesOrder.Ref,
		|	SalesOrderPaymentScheduleSteps.PaymentDate,
		|	DocumentSalesOrder.Date,
		|	DocumentSalesOrder.Presentation,
		|	DocumentSalesOrder.Partner,
		|	DocumentSalesOrder.Manager
		|
		|HAVING
		|	SUM(SalesOrderPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomerBalanceTable.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&PreparationForShipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN ENDOFPERIOD(DocumentSalesOrder.DateOfShipment,DAY)
		|		ELSE ENDOFPERIOD(&CurrentDate,DAY)
		|	END AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|	WHEN CustomerOrderGoods.DateOfShipment = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|	ELSE CASE
		|			WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &Upcoming
		|			ELSE &Overdue
		|		END
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND CustomerOrderGoods.SupplyOption <> VALUE(Enum.SupplyOptions.Ship)
		|	AND NOT CustomerOrderGoods.Canceled
		|	AND CASE
		|		WHEN DocumentSalesOrder.DateOfShipment <> DATETIME(1, 1, 1)
		|			THEN DocumentSalesOrder.DateOfShipment < &EndDate
		|		ELSE TRUE
		|	END AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT DISTINCT
		|	CustomerOrderGoods.Ref AS ReferenceToEventObject,
		|	CustomerOrderGoods.Ref AS SubjectOf,
		|	&Shipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(CustomerOrderGoods.DateOfShipment,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN CustomerOrderGoods.DateOfShipment > BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Upcoming
		|		WHEN CustomerOrderGoods.DateOfShipment = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|	ELSE &Overdue
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	INNER JOIN Document.SalesOrder.Goods AS CustomerOrderGoods
		|		ON DocumentSalesOrder.Ref = CustomerOrderGoods.Ref
		|	LEFT JOIN #ShipmentOrdersTurnoverExpanded AS ShippingOrdersTurnover
		|	ON
		|		DocumentSalesOrder.Ref = ShippingOrdersTurnover.ReferenceOrder
		|		AND (ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|			ShippingOrdersTurnover.IssuedQuantityTurnover) <> 0
		|	LEFT JOIN AccumulationRegister.GoodsForIssue.Balance(
		|		,
		|		DocumentShipments REFS Document.SalesOrder
		|			AND CAST(DocumentShipments AS Document.SalesOrder).Goods.DateOfShipment < &EndDate
		|			AND (DocumentShipments.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|			OR DocumentShipments.Status = VALUE(Enum.SalesOrderStatuses.ToSupply)) AND &TextOfConditionAndDocumentOfShipment) AS GoodsForIssueBalance
		|	ON
		|		DocumentSalesOrder.Ref = GoodsForIssueBalance.DocumentShipments
		|WHERE
		|	ISNULL(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover, 0) > 0
		|	AND ISNULL(GoodsForIssueBalance.ToShipBalance, 0) > 0
		|	AND ISNULL(ShippingOrdersTurnover.ForRegistrationQuantityTurnover -
		|		ShippingOrdersTurnover.IssuedQuantityTurnover, 0) <> ISNULL(GoodsForIssueBalance.ToShipBalance, 0)
		|	AND &TextOfSelectionConditionDocument
		|
		|UNION ALL
		|
		|SELECT
		|	SalesOrderPaymentScheduleSteps.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&WaitingForPaymentAfterShipment AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(SalesOrderPaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN SalesOrderPaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder.PaymentScheduleSteps AS SalesOrderPaymentScheduleSteps
		|		INNER JOIN Document.SalesOrder AS DocumentSalesOrder
		|		ON SalesOrderPaymentScheduleSteps.Ref = DocumentSalesOrder.Ref
		|
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomerBalanceTable
		|		ON SalesOrderPaymentScheduleSteps.Ref = CustomerBalanceTable.Object
		|			AND SalesOrderPaymentScheduleSteps.PaymentDate = CustomerBalanceTable.PaymentDate
		|			AND CustomerBalanceTable.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|WHERE
		|	DocumentSalesOrder.Posted
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND (SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditAfterShipment)
		|		OR SalesOrderPaymentScheduleSteps.PaymentOption = VALUE(Enum.CustomerPaymentControlOptions.CreditPlanned))
		|	AND SalesOrderPaymentScheduleSteps.PaymentDate < &EndDate AND &TextOfSelectionConditionDocument
		|
		|GROUP BY
		|	SalesOrderPaymentScheduleSteps.Ref,
		|	DocumentSalesOrder.Ref,
		|	SalesOrderPaymentScheduleSteps.PaymentDate,
		|	DocumentSalesOrder.Date,
		|	DocumentSalesOrder.Presentation,
		|	DocumentSalesOrder.Partner,
		|	DocumentSalesOrder.Manager
		|
		|HAVING
		|	SUM(SalesOrderPaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomerBalanceTable.AmountDueBalance), 0) > 0
		|
		|UNION ALL
		|
		|SELECT
		|	DocumentSalesOrder.Ref AS ReferenceToEventObject,
		|	DocumentSalesOrder.Ref AS SubjectOf,
		|	&ClosingOrder AS EventType,
		|	DocumentSalesOrder.Date AS DateOfEventObject,
		|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
		|	DocumentSalesOrder.Presentation AS LongDesc,
		|	NULL,
		|	NULL,
		|	&CurrentBusinessUnit AS Status,
		|	DocumentSalesOrder.Partner AS Partner,
		|	DocumentSalesOrder.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.SalesOrder AS DocumentSalesOrder
		|	LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(
		|			,
		|			ARAPObject IN (SELECT TTCalculationObjectsOrder.ARAPObject FROM TTCalculationObjectsOrder)) AS CustomersARAPAccounting
		|	ON DocumentSalesOrder.ARAPObject = CustomersARAPAccounting.ARAPObject
		|WHERE
		|	DocumentSalesOrder.Posted 
		|	AND &MonitorOrderClosing
		|	AND (DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
		|		OR DocumentSalesOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
		|	AND DocumentSalesOrder.ARAPObjectSettings = VALUE(Enum.ARAPObjectSettings.ByOrders)
		|	AND DocumentSalesOrder.BusinessOperation <> VALUE(Enum.BusinessTransactions.TransferToCommissionAgent)
		|	AND ISNULL(CustomersARAPAccounting.ToShipBalance, 0) = 0
		|	AND ISNULL(CustomersARAPAccounting.AmountDueBalance, 0) = 0 AND &TextOfSelectionConditionDocument ";
		
		TableFormationParameters = AccumulationRegisters.ShipmentAndReturnReferences.NewParametersForCreatingExpandedTable();
		TableFormationParameters.EndOfPeriod = "&EndDate";
		TableFormationParameters.ConditionText =
			"VALUETYPE(ReferenceOrder) = TYPE(Document.SalesOrder)
			|		AND (ReferenceOrder.Status = VALUE(Enum.SalesOrderStatuses.ToShip)
			|			OR ReferenceOrder.Status = VALUE(Enum.SalesOrderStatuses.ToSupply))
			|	AND &TextOfTermsAndConditionsForCustomerSOrder";
		TableFormationParameters.Group = "ReferenceOrder";
		TableFormationParameters.Indicators = "ToRegister, Issued_1";
		TableFormationParameters.Resources = "Count";
		
		ShipmentOrdersTurnoverExpanded =
			AccumulationRegisters.ShipmentAndReturnReferences.QueryTextExpandedTable(
				TableFormationParameters);
		
		QueryText = StrReplace(QueryText,
			"#ShipmentOrdersTurnoverExpanded",
			ShipmentOrdersTurnoverExpanded);
		
		StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients = True;
	
	EndIf;
	
	TextRequestCalculationObjects = "
		|SELECT
		|	ARAPObjects.Ref AS ARAPObject
		|INTO TTCalculationObjectsOrder
		|FROM 
		|	Catalog.ARAPObjects AS ARAPObjects
		|WHERE
		|	ARAPObjects.Object REFS Document.SalesOrder
		|	AND CAST(ARAPObjects.Object AS Document.SalesOrder).Status IN (VALUE(Enum.SalesOrderStatuses.ToSupply),
		|					VALUE(Enum.SalesOrderStatuses.ToShip))
		|	AND &TextOfSelectionCondition
		|;
		|
		|//////////////////////////////////////////////////////////////////////////////////////////////////////";
	
	AddRequestForIssues(QueryText,"Document.SalesOrder",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition = "
		|AND ARAPObjects.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfTermsAndConditionsForCustomerSOrder = "
		|AND ReferenceOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfSelectionConditionDocument = "
		|AND DocumentSalesOrder.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TextOfConditionAndDocumentOfShipment = "
		|AND DocumentShipments.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TermsAndConditionsAndPaymentPlan = "
		|AND ARAPObject.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition                 = "";
		TextOfSelectionConditionDocument         = "";
		TextOfTermsAndConditionsForCustomerSOrder     = "";
		TextOfConditionAndDocumentOfShipment = "";
		TermsAndConditionsAndPaymentPlan        = "";
		
	EndIf;
	
	TextRequestCalculationObjects = StrReplace(TextRequestCalculationObjects,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	QueryText = StrReplace(QueryText,"AND &TextOfConditionAndDocumentOfShipment",TextOfConditionAndDocumentOfShipment);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionConditionDocument",TextOfSelectionConditionDocument);
	QueryText = StrReplace(QueryText,"AND &TextOfTermsAndConditionsForCustomerSOrder",TextOfTermsAndConditionsForCustomerSOrder);
	QueryText = StrReplace(QueryText,"AND &TermsAndConditionsAndPaymentPlan", TermsAndConditionsAndPaymentPlan);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
			
	StructureOfReportGeneration.TextQueriesTemporaryTables = StructureOfReportGeneration.TextQueriesTemporaryTables + TextRequestCalculationObjects;
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.SalesOrder");
	
	Return QueryText;
	
EndFunction

Function QueryTextSettingPrices(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	PriceSetup.Ref AS ReferenceToEventObject,
	|	PriceSetup.Ref AS SubjectOf,
	|	&PriceApproval AS EventType,
	|	PriceSetup.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
	|	PriceSetup.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	NULL AS Partner,
	|	PriceSetup.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.PriceSetup AS PriceSetup
	|WHERE
	|	PriceSetup.Posted
	|	AND PriceSetup.Status = VALUE(Enum.ProductPricingStatuses.NotApproved) 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("PriceApproval",NStr("vi = 'Thống nhất bảng giá';
											|ru = 'Согласовать цены номенклатуры';
											|en = 'Approve prices of products'; fa = 'Approve prices of products';
											|it = 'Concordare i prezzi degli articoli';
											|pl = 'Uzgodnij ceny nomenklatury';
											|tr = 'Ürün fiyatını onayla'"));
	
	AddRequestForIssues(QueryText,"Document.PriceSetup",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND PriceSetup.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.PriceSetup");
	
	Return QueryText;

EndFunction

Function QueryTextTermsOfPurchaseFromVendors(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	TermsOfPurchaseFromVendors.Ref AS ReferenceToEventObject,
	|	TermsOfPurchaseFromVendors.Ref AS SubjectOf,
	|	&AgreementWithSupplier AS EventType,
	|	TermsOfPurchaseFromVendors.Date AS DateOfEventObject,
	|	CASE
	|		WHEN TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE ENDOFPERIOD(TermsOfPurchaseFromVendors.ValidityStartDate, DAY)
	|	END AS EventDate,
	|	TermsOfPurchaseFromVendors.Description AS LongDesc,
	|	TermsOfPurchaseFromVendors.Number AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN &CurrentDate > TermsOfPurchaseFromVendors.ValidityStartDate
	|					THEN &Overdue
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = DATEADD(TermsOfPurchaseFromVendors.ValidityStartDate, DAY, -1)
	|					THEN &CurrentBusinessUnit
	|				ELSE &Upcoming
	|			END
	|	END AS Status,
	|	TermsOfPurchaseFromVendors.Partner AS Partner,
	|	TermsOfPurchaseFromVendors.Manager AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	NOT TermsOfPurchaseFromVendors.DeletionMark
	|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.NotApproved)
	|	AND CASE
	|			WHEN TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE TermsOfPurchaseFromVendors.ValidityEndDate > &CurrentDate
	|		END 
	|	AND CASE
	|		WHEN TermsOfPurchaseFromVendors.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE TermsOfPurchaseFromVendors.ValidityStartDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	TermsOfPurchaseFromVendors.Ref,
	|	TermsOfPurchaseFromVendors.Ref,
	|	&TerminationOfAgreementWithSupplier,
	|	TermsOfPurchaseFromVendors.Date,
	|	ENDOFPERIOD(TermsOfPurchaseFromVendors.ValidityEndDate,DAY),
	|	TermsOfPurchaseFromVendors.Description,
	|	TermsOfPurchaseFromVendors.Number AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN &CurrentDate < TermsOfPurchaseFromVendors.ValidityEndDate
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = TermsOfPurchaseFromVendors.ValidityEndDate
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END,
	|	TermsOfPurchaseFromVendors.Partner AS Partner,
	|	TermsOfPurchaseFromVendors.Manager
	|   ,&TextEmptyString
	|FROM
	|	Catalog.TermsOfPurchaseFromVendors AS TermsOfPurchaseFromVendors
	|WHERE
	|	NOT TermsOfPurchaseFromVendors.DeletionMark
	|	AND TermsOfPurchaseFromVendors.Status = VALUE(Enum.StatusesOfTermsOfPurchase.Valid)
	|	AND NOT TermsOfPurchaseFromVendors.ValidityEndDate = DATETIME(1, 1, 1)
	|	AND TermsOfPurchaseFromVendors.ValidityStartDate < &CurrentDate
	|	AND TermsOfPurchaseFromVendors.ValidityEndDate < &EndDate 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("TerminationOfAgreementWithSupplier",NStr("vi = 'Xử lý kết thúc thời hạn thực hiện thỏa thuận với nhà cung cấp';
																|ru = 'Отработать окончание срока действия соглашения с поставщиком';
																|en = 'Process expiration of terms of purchase'; fa = 'Process expiration of terms of purchase';
																|it = 'Elaborare la data di fine validità dell''accordo con il fornitore';
																|pl = 'Wypracować datę wygaśnięcia umowy z dostawcą';
																|tr = 'Satın alma koşullarının geçerlilik süresi bitişi üzerinde çalış'"));
	Query.SetParameter("AgreementWithSupplier",NStr("vi = 'Thống nhất thỏa thuận với nhà cung cấp';
													|ru = 'Согласовать соглашение с поставщиком';
													|en = 'Approve terms of purchase'; fa = 'Approve terms of purchase';
													|it = 'Concordare l''accordo con il fornitore';
													|pl = 'Uzgodnij porozumienie z dostawcą';
													|tr = 'Satın alma koşullarını onayla'"));
	
	AddRequestForIssues(QueryText,"Catalog.TermsOfPurchaseFromVendors",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND TermsOfPurchaseFromVendors.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.TermsOfPurchaseFromVendors");
	
	Return QueryText;

EndFunction

Function QueryTextTermsOfSale(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	TermsOfSale.Ref AS ReferenceToEventObject,
	|	TermsOfSale.Ref AS SubjectOf,
	|	&ApprovalOfAgreementWithACustomer AS EventType,
	|	TermsOfSale.Date AS DateOfEventObject,
	|	CASE
	|		WHEN TermsOfSale.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE ENDOFPERIOD(TermsOfSale.ValidityStartDate,DAY)
	|	END AS EventDate,
	|	TermsOfSale.Description AS LongDesc,
	|	TermsOfSale.Number AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN TermsOfSale.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN &CurrentDate > TermsOfSale.ValidityStartDate
	|					THEN &Overdue
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) = DATEADD(TermsOfSale.ValidityStartDate, DAY, -1)
	|					THEN &CurrentBusinessUnit
	|				ELSE &Upcoming
	|			END
	|	END AS Status,
	|	TermsOfSale.Partner AS Partner,
	|	TermsOfSale.Manager AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	NOT TermsOfSale.DeletionMark
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.NotApproved)
	|	AND CASE
	|			WHEN TermsOfSale.ValidityEndDate = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE TermsOfSale.ValidityEndDate > &CurrentDate
	|		END
	|	AND CASE
	|		WHEN TermsOfSale.ValidityStartDate = DATETIME(1, 1, 1)
	|			THEN TRUE
	|		ELSE TermsOfSale.ValidityStartDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	TermsOfSale.Ref,
	|	TermsOfSale.Ref,
	|	&TerminationOfAgreementWithClient,
	|	TermsOfSale.Date,
	|	ENDOFPERIOD(TermsOfSale.ValidityEndDate,DAY),
	|	TermsOfSale.Description,
	|	TermsOfSale.Number AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN &CurrentDate < TermsOfSale.ValidityEndDate
	|			THEN &Upcoming
	|		WHEN BEGINOFPERIOD(&CurrentDate, DAY) = TermsOfSale.ValidityEndDate
	|			THEN &CurrentBusinessUnit
	|		ELSE &Overdue
	|	END,
	|	TermsOfSale.Partner,
	|	TermsOfSale.Manager
	|   ,&TextEmptyString
	|FROM
	|	Catalog.TermsOfSale AS TermsOfSale
	|WHERE
	|	NOT TermsOfSale.DeletionMark
	|	AND TermsOfSale.Status = VALUE(Enum.StatusesOfTermsOfSales.Valid)
	|	AND NOT TermsOfSale.ValidityEndDate = DATETIME(1, 1, 1)
	|	AND TermsOfSale.ValidityStartDate < &CurrentDate 
	|	AND TermsOfSale.ValidityEndDate < &EndDate 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("TerminationOfAgreementWithClient",NStr("vi = 'Xử lý kết thúc thời hạn thực hiện thỏa thuận với khách hàng';
																|ru = 'Отработать окончание срока действия соглашения с клиентом';
																|en = 'Process customer agreement expiration'; fa = 'Process customer agreement expiration';
																|it = 'Elaborare la data di fine validità dell''accordo con il cliente';
																|pl = 'Wypracować datę wygaśnięcia umowy z klientem';
																|tr = 'Satış koşullarının geçerlilik süresi bitişi üzerinde çalış'"));
	Query.SetParameter("ApprovalOfAgreementWithACustomer",NStr("vi = 'Thống nhất thỏa thuận với khách hàng';
																|ru = 'Согласовать соглашения с клиентом';
																|en = 'Approve terms of sales'; fa = 'تأیید شرایط فروش';
																|it = 'Concordare l''accordo con il cliente';
																|pl = 'Uzgodnij porozumienie z klientem';
																|tr = 'Satış koşullarında mutabakat'"));
	
	AddRequestForIssues(QueryText,"Catalog.TermsOfSale",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND TermsOfSale.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.TermsOfSale");
	
	Return QueryText;

EndFunction

Function QueryTextSalesOpportunities(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	SalesOpportunitiesToCustomer.Ref AS ReferenceToEventObject,
	|	SalesOpportunitiesToCustomer.Ref AS SubjectOf,
	|	StatisticsOfCustomerOpportunities.ProcessStep AS EventType,
	|	SalesOpportunitiesToCustomer.StartDate AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate,DAY) AS EventDate,
	|	SalesOpportunitiesToCustomer.Description AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	SalesOpportunitiesToCustomer.Partner AS Partner,
	|	SalesOpportunitiesToCustomer.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|		INNER JOIN Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|			INNER JOIN Catalog.CustomerOpportunityKinds AS CustomerOpportunityKinds
	|			ON SalesOpportunitiesToCustomer.SalesOpportunityKind = CustomerOpportunityKinds.Ref
	|		ON StatisticsOfCustomerOpportunities.SalesOpportunity = SalesOpportunitiesToCustomer.Ref
	|			AND (StatisticsOfCustomerOpportunities.EndDate = DATETIME(1, 1, 1))
	|WHERE
	|	NOT SalesOpportunitiesToCustomer.DeletionMark
	|	AND NOT SalesOpportunitiesToCustomer.Closed_
	|	AND (CustomerOpportunityKinds.SalesOpportunityType = VALUE(Enum.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement)
	|			OR CustomerOpportunityKinds.SalesOpportunityType = VALUE(Enum.TypesOfCustomerOpportunities.StandardSale)
	|				AND SalesOpportunitiesToCustomer.ManualControlEnabled) 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	SalesOpportunitiesToCustomer.Ref,
	|	SalesOpportunitiesToCustomer.Ref,
	|	&ClosingTransaction,
	|	SalesOpportunitiesToCustomer.StartDate,
	|	ENDOFPERIOD(&CurrentDate,DAY),
	|	SalesOpportunitiesToCustomer.Description,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit,
	|	SalesOpportunitiesToCustomer.Partner AS Partner,
	|	SalesOpportunitiesToCustomer.EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Catalog.SalesOpportunitiesToCustomer AS SalesOpportunitiesToCustomer
	|		INNER JOIN Catalog.CustomerOpportunityKinds AS CustomerOpportunityKinds
	|		ON SalesOpportunitiesToCustomer.SalesOpportunityKind = CustomerOpportunityKinds.Ref
	|		LEFT JOIN InformationRegister.StatisticsOfCustomerOpportunities AS StatisticsOfCustomerOpportunities
	|		ON (StatisticsOfCustomerOpportunities.SalesOpportunity = SalesOpportunitiesToCustomer.Ref)
	|			AND (StatisticsOfCustomerOpportunities.EndDate = DATETIME(1, 1, 1))
	|WHERE
	|	NOT SalesOpportunitiesToCustomer.DeletionMark
	|	AND NOT SalesOpportunitiesToCustomer.Closed_
	|	AND (CustomerOpportunityKinds.SalesOpportunityType = VALUE(Enum.TypesOfCustomerOpportunities.SalesOpportunitiesWithManualStageAdvancement)
	|			OR CustomerOpportunityKinds.SalesOpportunityType = VALUE(Enum.TypesOfCustomerOpportunities.StandardSale)
	|				AND SalesOpportunitiesToCustomer.ManualControlEnabled)
	|	AND StatisticsOfCustomerOpportunities.SalesOpportunity IS NULL 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ClosingTransaction",NStr("vi = 'Đóng vụ việc';
												|ru = 'Закрыть сделку';
												|en = 'Close sales opportunity'; fa = 'Close sales opportunity';
												|it = 'Chiudere la transazione';
												|pl = 'Zamknąć umowę';
												|tr = 'Satış fırsatını kapat'"));
	
	AddRequestForIssues(QueryText,"Catalog.SalesOpportunitiesToCustomer",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  SalesOpportunitiesToCustomer.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	
	If StructureOfReportGeneration.ThereIsAProjectTaskRight Then
		QueryText = QueryText + RequestTextForProjectPlanIssues(Query,StructureOfReportGeneration,"SalesOpportunitiesToCustomer");
	EndIf;
	
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.SalesOpportunitiesToCustomer");
	
	Return QueryText;

EndFunction

Function QueryTextProjects(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	Projects.Ref AS ReferenceToEventObject,
	|	Projects.Ref AS SubjectOf,
	|	&ProjectStart AS EventType,
	|	CASE
	|		WHEN Projects.StartDate = DATETIME(1, 1, 1)
	|			THEN Projects.PlannedStartDate
	|		ELSE Projects.StartDate
	|	END AS DateOfEventObject,
	|	CASE
	|		WHEN Projects.StartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(Projects.PlannedStartDate,DAY)
	|		ELSE ENDOFPERIOD(Projects.StartDate,DAY)
	|	END AS EventDate,
	|	Projects.Description AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN Projects.StartDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN Projects.PlannedStartDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &Upcoming
	|					WHEN Projects.PlannedStartDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &CurrentBusinessUnit
	|					ELSE &Overdue
	|				END
	|		ELSE CASE
	|				WHEN Projects.StartDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &Upcoming
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	NULL AS Partner,
	|	Projects.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT Projects.DeletionMark
	|	AND NOT Projects.Completed
	|	AND (Projects.StartDate = DATETIME(1, 1, 1)
	|			OR Projects.StartDate >= BEGINOFPERIOD(&CurrentDate, DAY))
	|	AND CASE
	|		WHEN Projects.StartDate = DATETIME(1, 1, 1)
	|			THEN Projects.PlannedStartDate < &EndDate
	|		ELSE Projects.StartDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	Projects.Ref,
	|	Projects.Ref,
	|	&EndOfProject,
	|	CASE
	|		WHEN Projects.EndDate = DATETIME(1, 1, 1)
	|			THEN Projects.PlannedEndDate
	|		ELSE Projects.EndDate
	|	END,
	|	CASE
	|		WHEN Projects.EndDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(Projects.PlannedEndDate,DAY)
	|		ELSE ENDOFPERIOD(Projects.EndDate,DAY)
	|	END,
	|	Projects.Description,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN Projects.EndDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN Projects.PlannedEndDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &Upcoming
	|					WHEN Projects.PlannedEndDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &CurrentBusinessUnit
	|					ELSE &Overdue
	|				END
	|		ELSE CASE
	|				WHEN Projects.EndDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &Upcoming
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END,
	|	NULL AS Partner,
	|	Projects.EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Catalog.Projects AS Projects
	|WHERE
	|	NOT Projects.DeletionMark
	|	AND NOT Projects.Completed
	|	AND Projects.StartDate <> DATETIME(1, 1, 1)
	|	AND Projects.StartDate < BEGINOFPERIOD(&CurrentDate, DAY) 
	|AND CASE
	|		WHEN Projects.EndDate = DATETIME(1, 1, 1)
	|			THEN Projects.PlannedEndDate < &EndDate
	|		ELSE Projects.EndDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ProjectStart",NStr("vi = 'Bắt đầu dự án';
											|ru = 'Начать проект';
											|en = 'Start a project'; fa = 'Start a project';
											|it = 'Avviare il progetto';
											|pl = 'Rozpocząć projekt';
											|tr = 'Projeyi başlat'"));
	Query.SetParameter("EndOfProject",NStr("vi = 'Kết thúc dự án';
											|ru = 'Завершить проект';
											|en = 'Finish project'; fa = 'Finish project';
											|it = 'Completare il progetto';
											|pl = 'Ukończ projekt';
											|tr = 'Projeyi tamamla'"));
	
	AddRequestForIssues(QueryText,"Catalog.Projects",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  Projects.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	
	If StructureOfReportGeneration.ThereIsAProjectTaskRight Then
		QueryText = QueryText + RequestTextForProjectPlanIssues(Query,StructureOfReportGeneration,"Projects");
	EndIf;
	
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.Projects");
	
	Return QueryText;

EndFunction

Function QueryTextMarketingActivities(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	MarketingActivities.Ref AS ReferenceToEventObject,
	|	MarketingActivities.Ref AS SubjectOf,
	|	&StartOfMarketingEvent AS EventType,
	|	CASE
	|		WHEN MarketingActivities.StartDate = DATETIME(1, 1, 1)
	|			THEN MarketingActivities.PlannedStartDate
	|		ELSE MarketingActivities.StartDate
	|	END AS DateOfEventObject,
	|	CASE
	|		WHEN MarketingActivities.StartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(MarketingActivities.PlannedStartDate,DAY)
	|		ELSE ENDOFPERIOD(MarketingActivities.StartDate,DAY)
	|	END AS EventDate,
	|	MarketingActivities.Description AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN MarketingActivities.StartDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN MarketingActivities.PlannedStartDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &Upcoming
	|					WHEN MarketingActivities.PlannedStartDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &CurrentBusinessUnit
	|					ELSE &Overdue
	|				END
	|		ELSE CASE
	|				WHEN MarketingActivities.StartDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &Upcoming
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	NULL AS Partner,
	|	MarketingActivities.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Catalog.MarketingActivities AS MarketingActivities
	|WHERE
	|	NOT MarketingActivities.DeletionMark
	|	AND NOT MarketingActivities.Completed
	|	AND (MarketingActivities.StartDate = DATETIME(1, 1, 1)
	|			OR MarketingActivities.StartDate >= BEGINOFPERIOD(&CurrentDate, DAY))
	|	AND CASE
	|		WHEN MarketingActivities.StartDate = DATETIME(1, 1, 1)
	|			THEN MarketingActivities.PlannedStartDate < &EndDate
	|		ELSE MarketingActivities.StartDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	MarketingActivities.Ref,
	|	MarketingActivities.Ref,
	|	&EndOfMarketingEvent,
	|	CASE
	|		WHEN MarketingActivities.EndDate = DATETIME(1, 1, 1)
	|			THEN MarketingActivities.PlannedEndDate
	|		ELSE MarketingActivities.EndDate
	|	END,
	|	CASE
	|		WHEN MarketingActivities.EndDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(MarketingActivities.PlannedEndDate, DAY)
	|		ELSE ENDOFPERIOD(MarketingActivities.EndDate,DAY)
	|	END,
	|	MarketingActivities.Description,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN MarketingActivities.EndDate = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN MarketingActivities.PlannedEndDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &Upcoming
	|					WHEN MarketingActivities.PlannedEndDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|						THEN &CurrentBusinessUnit
	|					ELSE &Overdue
	|				END
	|		ELSE CASE
	|				WHEN MarketingActivities.EndDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &Upcoming
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END,
	|	NULL AS Partner,
	|	MarketingActivities.EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Catalog.MarketingActivities AS MarketingActivities
	|WHERE
	|	NOT MarketingActivities.DeletionMark
	|	AND NOT MarketingActivities.Completed
	|	AND MarketingActivities.StartDate <> DATETIME(1, 1, 1)
	|	AND MarketingActivities.StartDate < BEGINOFPERIOD(&CurrentDate, DAY) 
	|AND CASE
	|		WHEN MarketingActivities.EndDate = DATETIME(1, 1, 1)
	|			THEN MarketingActivities.PlannedEndDate < &EndDate
	|		ELSE MarketingActivities.EndDate < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("StartOfMarketingEvent",NStr("vi = 'Bắt đầu hoạt động Marketing';
													|ru = 'Начать маркетинговое мероприятие';
													|en = 'Start marketing activity'; fa = 'Start marketing activity';
													|it = 'Avviare l''evento di marketing';
													|pl = 'Rozpocznij wydarzenie marketingowe';
													|tr = 'Pazarlama faaliyetlerini başlat'"));
	Query.SetParameter("EndOfMarketingEvent",NStr("vi = 'Kết thúc hoạt động Marketing';
													|ru = 'Завершить маркетинговое мероприятие';
													|en = 'Finish marketing activity'; fa = 'Finish marketing activity';
													|it = 'Completare l''evento di marketing';
													|pl = 'Zakończ wydarzenie marketingowe';
													|tr = 'Pazarlama faaliyetlerini tamamla'"));
	
	AddRequestForIssues(QueryText,"Catalog.MarketingActivities",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  MarketingActivities.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	
	If StructureOfReportGeneration.ThereIsAProjectTaskRight Then
		QueryText = QueryText + RequestTextForProjectPlanIssues(Query,StructureOfReportGeneration,"MarketingActivities");
	EndIf;
	
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.MarketingActivities");
	
	Return QueryText;

EndFunction

Function QueryTextCounterpartyAgreements(Query,StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	ARAPObjects.Object,
	|	ARAPObjects.Object,
	|	&Payment,
	|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
	|	ENDOFPERIOD(VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
	|	ARAPObjects.Description,
	|	NULL,
	|	NULL,
	|	CASE
	|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &Overdue
	|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Upcoming
	|	END,
	|	ARAPObjects.Partner AS Partner,
	|	ARAPObjects.Manager
	|FROM
	|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Catalog.CounterpartyContracts
	|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS VendorsARAPAccountingCashFlowPlanBalance
	|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
	|		ON VendorsARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
	|WHERE
	|	VendorsARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
	|GROUP BY
	|	ARAPObjects.Object,
	|	VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
	|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
	|	ARAPObjects.Description,
	|	ARAPObjects.Partner,
	|	ARAPObjects.Manager
	|";
	

	QueryText = "
	|SELECT
		|	CounterpartyContracts.Ref,
		|	CounterpartyContracts.Ref,
		|	&Payment AS EventType,
		|	CounterpartyContracts.Date AS DateOfEventObject,
		|	ENDOFPERIOD(ContractScheduleSteps.DateAccordingToSchedule,DAY) AS EventDate,
		|	CounterpartyContracts.Description AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN ContractScheduleSteps.DateAccordingToSchedule < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN ContractScheduleSteps.DateAccordingToSchedule = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	CounterpartyContracts.Partner AS Partner,
		|	CounterpartyContracts.Manager AS EmployeeResponsible
		|
		|FROM
		|	Document.ContractSchedule.ContractScheduleSteps AS ContractScheduleSteps
		|		
		|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON ContractScheduleSteps.Ref = CounterpartyContracts.Ref
		|		
		|		LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|		ON ContractScheduleSteps.Ref.Contract = TableOfSupplierBalances.Object
		|			AND ContractScheduleSteps.DateAccordingToSchedule = TableOfSupplierBalances.PaymentDate
		|			AND ContractScheduleSteps.DateAccordingToSchedule < &EndDate
		|WHERE
		|	NOT CounterpartyContracts.DeletionMark
		|	AND ContractScheduleSteps.DateAccordingToSchedule < &EndDate
		|
		|GROUP BY
		|	ContractScheduleSteps.Ref,
		|	CounterpartyContracts.Ref,
		|	ContractScheduleSteps.DateAccordingToSchedule,
		|	CounterpartyContracts.Date,
		|	CounterpartyContracts.Presentation,
		|	CounterpartyContracts.Partner,
		|	CounterpartyContracts.Manager";

	If StructureOfReportGeneration.NewCalculationArchitectureIsUsed Then

		QueryText = "
		|SELECT
		|	CounterpartyContracts.Ref AS ReferenceToEventObject,
		|	CounterpartyContracts.Ref AS SubjectOf,
		|	&ContractExpires AS EventType,
		|	CounterpartyContracts.Date AS DateOfEventObject,
		|	ENDOFPERIOD(CounterpartyContracts.ValidityEndDate,DAY) AS EventDate,
		|	CounterpartyContracts.Description AS LongDesc,
		|	CounterpartyContracts.BusinessOperation AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN &CurrentDate < CounterpartyContracts.ValidityEndDate
		|			THEN &Upcoming
		|		ELSE &CurrentBusinessUnit
		|	END AS Status,
		|	CounterpartyContracts.Partner AS Partner,
		|	CounterpartyContracts.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	NOT CounterpartyContracts.DeletionMark
		|	AND CounterpartyContracts.ValidityEndDate <> DATETIME(1, 1, 1)
		|	AND CounterpartyContracts.ValidityEndDate < &EndDate
		|	AND CounterpartyContracts.ValidityEndDate >= BEGINOFPERIOD(&CurrentDate, DAY)
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND &TextOfSelectionCondition
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&Payment,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.VendorsARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Catalog.CounterpartyContracts
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS VendorsARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON VendorsARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	VendorsARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	VendorsARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	VendorsARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|
		|UNION ALL
		|
		|SELECT
		|	ARAPObjects.Object,
		|	ARAPObjects.Object,
		|	&ReceivingPayment,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ENDOFPERIOD(CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate, DAY),
		|	ARAPObjects.Description,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE &Upcoming
		|	END,
		|	ARAPObjects.Partner AS Partner,
		|	ARAPObjects.Manager
		|   ,&TextEmptyString
		|FROM
		|	AccumulationRegister.CustomersARAPAccountingCashFlowPlan.Balance(, ARAPObject.Object REFS Catalog.CounterpartyContracts
		|	AND PlannedRepaymentDate < &EndDate AND &TermsAndConditionsAndPaymentPlan) AS CustomersARAPAccountingCashFlowPlanBalance
		|		INNER JOIN Catalog.ARAPObjects AS ARAPObjects
		|		ON CustomersARAPAccountingCashFlowPlanBalance.ARAPObject = ARAPObjects.Ref
		|WHERE
		|	CustomersARAPAccountingCashFlowPlanBalance.AmountDueBalance > 0
		|GROUP BY
		|	ARAPObjects.Object,
		|	CustomersARAPAccountingCashFlowPlanBalance.PlannedRepaymentDate,
		|	CustomersARAPAccountingCashFlowPlanBalance.OccurrenceDate,
		|	ARAPObjects.Description,
		|	ARAPObjects.Partner,
		|	ARAPObjects.Manager
		|";
	
	Else
		
		QueryText = "
		|SELECT
		|	CounterpartyContracts.Ref AS ReferenceToEventObject,
		|	CounterpartyContracts.Ref AS SubjectOf,
		|	&ContractExpires AS EventType,
		|	CounterpartyContracts.Date AS DateOfEventObject,
		|	ENDOFPERIOD(CounterpartyContracts.ValidityEndDate,DAY) AS EventDate,
		|	CounterpartyContracts.Description AS LongDesc,
		|	CounterpartyContracts.BusinessOperation AS AdditionalDetailsDescription1,
		|	NULL AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN &CurrentDate < CounterpartyContracts.ValidityEndDate
		|			THEN &Upcoming
		|		ELSE &CurrentBusinessUnit
		|	END AS Status,
		|	CounterpartyContracts.Partner AS Partner,
		|	CounterpartyContracts.Manager AS EmployeeResponsible
		|   ,&TheTextToPut
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	NOT CounterpartyContracts.DeletionMark
		|	AND CounterpartyContracts.ValidityEndDate <> DATETIME(1, 1, 1)
		|	AND CounterpartyContracts.ValidityEndDate < &EndDate
		|	AND CounterpartyContracts.ValidityEndDate >= BEGINOFPERIOD(&CurrentDate, DAY)
		|	AND CounterpartyContracts.Status = VALUE(Enum.CounterpartyContractStatuses.Valid)
		|	AND &TextOfSelectionCondition
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Ref,
		|	CounterpartyContracts.Ref,
		|	&Payment AS EventType,
		|	CounterpartyContracts.Date AS DateOfEventObject,
		|	ENDOFPERIOD(PaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	CounterpartyContracts.Description AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN PaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN PaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	CounterpartyContracts.Partner AS Partner,
		|	CounterpartyContracts.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|
		|FROM
		|	Document.ContractSchedule.PaymentScheduleSteps AS PaymentScheduleSteps
		|		
		|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON PaymentScheduleSteps.Ref = CounterpartyContracts.Ref
		|		
		|		LEFT JOIN TableOfSupplierBalancesPayable AS TableOfSupplierBalances
		|		ON PaymentScheduleSteps.Ref.Contract = TableOfSupplierBalances.Object
		|			AND PaymentScheduleSteps.PaymentDate = TableOfSupplierBalances.PaymentDate
		|			AND PaymentScheduleSteps.PaymentDate < &EndDate
		|WHERE
		|	NOT CounterpartyContracts.DeletionMark
		|	AND PaymentScheduleSteps.PaymentDate < &EndDate
		|
		|GROUP BY
		|	PaymentScheduleSteps.Ref,
		|	CounterpartyContracts.Ref,
		|	PaymentScheduleSteps.PaymentDate,
		|	CounterpartyContracts.Date,
		|	CounterpartyContracts.Presentation,
		|	CounterpartyContracts.Partner,
		|	CounterpartyContracts.Manager
		|
		|HAVING
		|	SUM(PaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(TableOfSupplierBalances.AmountDueBalance), 0) < 0
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Ref,
		|	CounterpartyContracts.Ref,
		|	&ReceivingPayment AS EventType,
		|	CounterpartyContracts.Date AS DateOfEventObject,
		|	ENDOFPERIOD(PaymentScheduleSteps.PaymentDate,DAY) AS EventDate,
		|	CounterpartyContracts.Description AS LongDesc,
		|	NULL,
		|	NULL,
		|	CASE
		|		WHEN PaymentScheduleSteps.PaymentDate < BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &Overdue
		|		WHEN PaymentScheduleSteps.PaymentDate = BEGINOFPERIOD(&CurrentDate, DAY)
		|			THEN &CurrentBusinessUnit
		|		ELSE  &Upcoming
		|	END AS Status,
		|	CounterpartyContracts.Partner AS Partner,
		|	CounterpartyContracts.Manager AS EmployeeResponsible
		|   ,&TextEmptyString
		|FROM
		|	Document.ContractSchedule.PaymentScheduleSteps AS PaymentScheduleSteps
		|		
		|		INNER JOIN Catalog.CounterpartyContracts AS CounterpartyContracts
		|		ON PaymentScheduleSteps.Ref = CounterpartyContracts.Ref
		|		
		|		LEFT JOIN TableOfCustomerBalancesPayable AS CustomerBalanceTable
		|		ON PaymentScheduleSteps.Ref.Contract = CustomerBalanceTable.Object
		|			AND PaymentScheduleSteps.PaymentDate = CustomerBalanceTable.PaymentDate
		|			AND PaymentScheduleSteps.PaymentDate < &EndDate
		|WHERE
		|	NOT CounterpartyContracts.DeletionMark
		|	AND PaymentScheduleSteps.PaymentDate < &EndDate
		|
		|GROUP BY
		|	PaymentScheduleSteps.Ref,
		|	CounterpartyContracts.Ref,
		|	PaymentScheduleSteps.PaymentDate,
		|	CounterpartyContracts.Date,
		|	CounterpartyContracts.Presentation,
		|	CounterpartyContracts.Partner,
		|	CounterpartyContracts.Manager
		|
		|HAVING
		|	SUM(PaymentScheduleSteps.PaymentAmount) > 0 AND
		|	ISNULL(SUM(CustomerBalanceTable.AmountDueBalance), 0) < 0
		|";
		
		StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocumentsClients = True;
		StructureOfReportGeneration.ThereAreAppealsToRegistersCalculationsOnDocuments = True;
		
	EndIf;
	
	Query.SetParameter("ContractExpires",NStr("vi = 'Xử lý kết thúc thời hạn thực hiện hợp đồng với đối tác';
												|ru = 'Отработать окончание срока действия договора с контрагентом';
												|en = 'Process counterparty contract expiration'; fa = 'Process counterparty contract expiration';
												|it = 'Elaborare la data di fine validità del contratto con il contraente';
												|pl = 'Wypracować datę wygaśnięcia umowy z kontrahentem';
												|tr = 'Cari hesap ile sözleşmenin sonlandırılması üzerinde işlemek'"));

	AddRequestForIssues(QueryText,"Catalog.CounterpartyContracts",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  CounterpartyContracts.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		TermsAndConditionsAndPaymentPlan = "
		|AND ARAPObject.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition          = "";
		TermsAndConditionsAndPaymentPlan = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TermsAndConditionsAndPaymentPlan", TermsAndConditionsAndPaymentPlan);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",          TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.CounterpartyContracts");
	
	Return QueryText;

EndFunction

Function RequestTextForProjectPlanIssues(Query,StructureOfReportGeneration,CatalogOwner)

	QueryText = "
	|UNION ALL
	|
	|SELECT 
	|	ProjectTasks.Ref AS ReferenceToEventObject,
	|	ProjectTasks.Ref AS SubjectOf,
	|	&ScheduleProjectTask AS EventType,
	|	ProjectTasks.Owner.StartDate AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	ProjectTasks.Description AS LongDesc,
	|	ProjectTasks.Owner AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	NULL AS Partner,
	|	ProjectTasks.Performer AS EmployeeResponsible
	|FROM
	|	Catalog.ProjectTasks AS ProjectTasks
	|WHERE
	|	NOT ProjectTasks.DeletionMark
	|	AND NOT ProjectTasks.Closed_
	|	AND ProjectTasks.Phase = VALUE(Enum.TaskPhases.NotPlanned) 
	|	AND &TextOfConditionSelectionExecutor 
	|	AND &OwnerConditionText
	|
	|UNION ALL
	|
	|SELECT
	|	ProjectTasks.Ref,
	|	ProjectTasks.Ref,
	|	&StartProjectTask,
	|	ProjectTasks.Owner.StartDate,
	|	CASE
	|		WHEN ProjectTasks.PlannedStartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE ENDOFPERIOD(ProjectTasks.PlannedStartDate, DAY)
	|	END,
	|	ProjectTasks.Description,
	|	ProjectTasks.Owner AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ProjectTasks.PlannedStartDate = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN ProjectTasks.PlannedStartDate > BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &Upcoming
	|				WHEN ProjectTasks.PlannedStartDate = BEGINOFPERIOD(&CurrentDate, DAY)
	|					THEN &CurrentBusinessUnit
	|				ELSE &Overdue
	|			END
	|	END,
	|	NULL AS Partner,
	|	ProjectTasks.Performer AS EmployeeResponsible
	|FROM
	|	Catalog.ProjectTasks AS ProjectTasks
	|WHERE
	|	NOT ProjectTasks.DeletionMark
	|	AND NOT ProjectTasks.Closed_
	|	AND ProjectTasks.Phase = VALUE(Enum.TaskPhases.Planned)
	|	AND CASE
	|			WHEN ProjectTasks.PlannedStartDate <> DATETIME(1, 1, 1)
	|				THEN ProjectTasks.PlannedStartDate < &EndDate
	|			ELSE TRUE
	|		END 
	|	AND &TextOfConditionSelectionExecutor 
	|	AND &OwnerConditionText
	|
	|UNION ALL
	|
	|SELECT
	|	ProjectTasks.Ref,
	|	ProjectTasks.Ref,
	|	&CompletingProjectTask,
	|	ProjectTasks.Owner.StartDate,
	|	CASE
	|		WHEN ProjectTasks.PlannedStartDate = DATETIME(1, 1, 1)
	|			THEN ENDOFPERIOD(&CurrentDate, DAY)
	|		ELSE CASE
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) < DATEADD(ProjectTasks.PlannedStartDate, DAY, ProjectTasks.PlannedDuration)
	|					THEN ENDOFPERIOD(&CurrentDate, DAY)
	|				ELSE ENDOFPERIOD(DATEADD(ProjectTasks.PlannedStartDate, DAY, ProjectTasks.PlannedDuration),DAY)
	|			END
	|	END,
	|	ProjectTasks.Description,
	|	ProjectTasks.Owner AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ProjectTasks.PlannedStartDate = DATETIME(1, 1, 1)
	|			THEN &CurrentBusinessUnit
	|		ELSE CASE
	|				WHEN BEGINOFPERIOD(&CurrentDate, DAY) <= DATEADD(ProjectTasks.PlannedStartDate, DAY, ProjectTasks.PlannedDuration)
	|					THEN &CurrentBusinessUnit
	|				ELSE &Overdue
	|			END
	|	END,
	|	NULL AS Partner,
	|	ProjectTasks.Performer AS EmployeeResponsible
	|FROM
	|	Catalog.ProjectTasks AS ProjectTasks
	|WHERE
	|	NOT ProjectTasks.DeletionMark
	|	AND NOT ProjectTasks.Closed_
	|	AND ProjectTasks.Phase = VALUE(Enum.TaskPhases.Running)
	|	AND &TextOfConditionSelectionExecutor 
	|	AND &OwnerConditionText
	|
	|UNION ALL
	|
	|SELECT
	|	ProjectTasks.Ref,
	|	ProjectTasks.Ref,
	|	&CheckProjectTaskCompletion,
	|	ProjectTasks.Owner.StartDate,
	|	ENDOFPERIOD(&CurrentDate, DAY),
	|	ProjectTasks.Description,
	|	ProjectTasks.Owner AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit,
	|	NULL AS Partner,
	|	ProjectTasks.Supervisor_ AS EmployeeResponsible
	|FROM
	|	Catalog.ProjectTasks AS ProjectTasks
	|WHERE
	|	NOT ProjectTasks.DeletionMark
	|	AND NOT ProjectTasks.Closed_
	|	AND ProjectTasks.Phase = VALUE(Enum.TaskPhases.Executed) 
	|	AND &TextConditionsSelectionCurator 
	|	AND &OwnerConditionText
	|
	|UNION ALL
	|
	|SELECT
	|	ProjectTasks.Ref,
	|	ProjectTasks.Ref,
	|	&ClosingProjectTask,
	|	BEGINOFPERIOD(&CurrentDate, DAY),
	|	ENDOFPERIOD(&CurrentDate, DAY),
	|	ProjectTasks.Description,
	|	ProjectTasks.Owner AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit,
	|	NULL AS Partner,
	|	ProjectTasks.Supervisor_ AS EmployeeResponsible
	|FROM
	|	Catalog.ProjectTasks AS ProjectTasks
	|WHERE
	|	NOT ProjectTasks.DeletionMark
	|	AND NOT ProjectTasks.Closed_
	|	AND ProjectTasks.Phase = VALUE(Enum.TaskPhases.Proved)
	|	AND &TextConditionsSelectionCurator
	|	AND &OwnerConditionText";
	
	Query.SetParameter("ScheduleProjectTask",NStr("vi = 'Lên lịch một nhiệm vụ dự án';
													|ru = 'Запланировать задачу проекта';
													|en = 'Schedule project task'; fa = 'Schedule project task';
													|it = 'Pianificare l''obiettivo del progetto';
													|pl = 'Zaplanuj zadanie projektu';
													|tr = 'Proje görevini programla'"));
	Query.SetParameter("StartProjectTask",NStr("vi = 'Bắt đầu thực hiện nhiệm vụ dự án';
												|ru = 'Начать выполнение задачи проекта';
												|en = 'Start fulfilling project task'; fa = 'Start fulfilling project task';
												|it = 'Iniziare l''esecuzione dell''obiettivo del progetto';
												|pl = 'Rozpocznij realizację zadań projektowych';
												|tr = 'Proje görevi gerçekleştirilmesini başlat'"));
	Query.SetParameter("CompletingProjectTask",NStr("vi = 'Hoàn thành nhiệm vụ dự án';
													|ru = 'Выполнить задачу проекта';
													|en = 'Complete project task'; fa = 'Complete project task';
													|it = 'Effettuare l''obbiettivo del progetto';
													|pl = 'Wypełnij zadanie projektu';
													|tr = 'Proje görevini gerçekleştir'"));
	Query.SetParameter("CheckProjectTaskCompletion",NStr("vi = 'Kiểm tra việc thực hiện nhiệm vụ dự án';
														|ru = 'Проверить выполнение задачи проекта';
														|en = 'Check project task execution'; fa = 'Check project task execution';
														|it = 'Controllare l''esecuzione dell''obiettivo del progetto';
														|pl = 'Sprawdź realizację zadań projektowych';
														|tr = 'Proje görevinin gerçekleştirilmesini kontrol et'"));
	Query.SetParameter("ClosingProjectTask",NStr("vi = 'Đóng nhiệm vụ dự án';
												|ru = 'Закрыть задачу проекта';
												|en = 'Close project task'; fa = 'Close project task';
												|it = 'Chiudere l''obiettivo del progetto';
												|pl = 'Zamknij zadanie projektu';
												|tr = 'Proje görevini kapat'"));
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfConditionSelectionExecutor ="
		|AND  ProjectTasks.Performer" + StructureOfReportGeneration.ConditionTextForUsers;
		TextConditionsSelectionCurator ="
		|AND  ProjectTasks.Supervisor_" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfConditionSelectionExecutor = "";
		TextConditionsSelectionCurator = "";
		
	EndIf;
	
	OwnerConditionText = "
	|AND  ProjectTasks.Owner REFS Catalog." + CatalogOwner;
	
	If CatalogOwner = "Complaints" Or CatalogOwner = "SalesOpportunities" Then
		TextSelectedFieldPartner = "
		|	ProjectTasks.Owner.Partner AS Partner,";
	Else
		TextSelectedFieldPartner = "
		|	NULL AS Partner,";
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfConditionSelectionExecutor",TextOfConditionSelectionExecutor);
	QueryText = StrReplace(QueryText,"AND &TextConditionsSelectionCurator",TextConditionsSelectionCurator);
	QueryText = StrReplace(QueryText,"AND &OwnerConditionText",OwnerConditionText);
	QueryText = StrReplace(QueryText,"%TextSelectedFieldPartner%",TextSelectedFieldPartner);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.ProjectTasks");
	
	Return QueryText;

EndFunction

Function QueryTextIncomingMessages(Query, StructureOfReportGeneration)
	
	QueryText = "
	|SELECT
	|	IncomingEmail.Ref AS ReferenceToEventObject,
	|	IncomingEmail.Ref AS SubjectOf,
	|	&ViewIncomingEmail AS EventType,
	|	IncomingEmail.Date AS DateOfEventObject,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN IncomingEmail.Date
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1))
	|	END AS EventDate,
	|	IncomingEmail.Subject AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN DATEADD(IncomingEmail.Date, HOUR, 1) < &CurrentDate
	|						THEN &Overdue
	|					ELSE &CurrentBusinessUnit
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) > &CurrentDate
	|					THEN &Upcoming
	|				WHEN DATEADD(ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)), HOUR, 1) < &CurrentDate
	|					THEN &Overdue
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	CASE
	|		WHEN IncomingEmail.SenderContact REFS Catalog.Partners THEN IncomingEmail.SenderContact
	|		WHEN IncomingEmail.SenderContact REFS Catalog.ContactPersonsForPartners THEN IncomingEmail.SenderContact.Owner
	|		ELSE NULL
	|	END AS Partner,
	|	IncomingEmail.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.IncomingEmail AS IncomingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON IncomingEmail.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT IncomingEmail.DeletionMark
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|	AND CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN IncomingEmail.Date < &EndDate
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) < &EndDate
	|	END
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ViewIncomingEmail",NStr("vi = 'Xử lý E-mail đến';
												|ru = 'Отработать входящее письмо';
												|en = 'Process incoming email'; fa = 'Process incoming email';
												|it = 'Elaborare l''email in arrivo';
												|pl = 'Wypracować przychodzący list';
												|tr = 'Gelen mektubu işlemek'"));
	
	AddRequestForIssues(QueryText,"Document.IncomingEmail",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|	AND IncomingEmail.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.IncomingEmail");
	
	Return QueryText;

EndFunction

Function QueryTextOutgoingMessages(Query, StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	OutgoingEmail.Ref AS ReferenceToEventObject,
	|	OutgoingEmail.Ref AS SubjectOf,
	|	&MonitorOutgoingEmail AS EventType,
	|	OutgoingEmail.PostingDate AS DateOfEventObject,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN OutgoingEmail.Date
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1))
	|	END AS EventDate,
	|	OutgoingEmail.Subject AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN DATEADD(OutgoingEmail.Date, HOUR, 1) < &CurrentDate
	|						THEN &Overdue
	|					ELSE &CurrentBusinessUnit
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) > &CurrentDate
	|					THEN &Upcoming
	|				WHEN DATEADD(ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)), HOUR, 1) < &CurrentDate
	|					THEN &Overdue
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	NULL AS Partner,
	|	OutgoingEmail.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.OutgoingEmail AS OutgoingEmail
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON OutgoingEmail.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT OutgoingEmail.DeletionMark
	|	AND NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE)
	|	AND OutgoingEmail.EmailStatus = VALUE(Enum.OutgoingEmailStatuses.Sent)
	|	AND CASE
	|			WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|				THEN OutgoingEmail.Date < &EndDate
	|			ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) < &EndDate
	|	END
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("MonitorOutgoingEmail",NStr("vi = 'Kiểm tra E-mail đến';
													|ru = 'Проконтролировать исходящее письмо';
													|en = 'Monitor outgoing email'; fa = 'Monitor outgoing email';
													|it = 'Controllare l''email in uscita';
													|pl = 'Przekontrolować przychodzący list';
													|tr = 'Giden mektubu kontrol et'"));
	
	AddRequestForIssues(QueryText,"Document.OutgoingEmail",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND OutgoingEmail.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.OutgoingEmail");
	
	Return QueryText;

EndFunction

Function QueryTextMeetings(Query, StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	Meeting.Ref AS ReferenceToEventObject,
	|	Meeting.Ref AS SubjectOf,
	|	&ConsiderAppointment AS EventType,
	|	Meeting.Date AS DateOfEventObject,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN Meeting.EndDate
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1))
	|	END AS EventDate,
	|	Meeting.Subject AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN DATEADD(Meeting.EndDate, HOUR, 1) < &CurrentDate
	|						THEN &Overdue
	|					ELSE &CurrentBusinessUnit
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) > &CurrentDate
	|					THEN &Upcoming
	|				WHEN DATEADD(ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)), HOUR, 1) < &CurrentDate
	|					THEN &Overdue
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	NULL AS Partner,
	|	Meeting.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.Meeting AS Meeting
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON Meeting.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT Meeting.DeletionMark
	|	AND NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE)
	|	AND Meeting.EndDate < &CurrentDate 
	|	AND CASE
	|			WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|				THEN TRUE
	|			ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) < &EndDate
	|	END
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	Meeting.Ref,
	|	Meeting.Ref,
	|	&Appointment,
	|	Meeting.Date,
	|	Meeting.StartDate,
	|	Meeting.Subject,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN Meeting.StartDate > &CurrentDate
	|			THEN &Upcoming
	|		ELSE &CurrentBusinessUnit
	|	END,
	|	NULL AS Partner,
	|	Meeting.EmployeeResponsible AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Document.Meeting AS Meeting
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON Meeting.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT Meeting.DeletionMark
	|	AND &CurrentDate < Meeting.EndDate 
	|	AND Meeting.StartDate < &EndDate 
	|	AND &TextOfConditionsSelectionWithParticipants";
	
	Query.SetParameter("ConsiderAppointment",NStr("vi = 'Xử lý kết quả cuộc gặp';
													|ru = 'Отработать результаты встречи';
													|en = 'Process meeting results'; fa = 'Process meeting results';
													|it = 'Elaborare i risultati della riunione';
													|pl = 'Wypracować wyniki spotkania';
													|tr = 'Randevu sonuçlarını işlemek'"));
	Query.SetParameter("Appointment",NStr("vi = 'Đi gặp gỡ';
											|ru = 'Прийти на встречу';
											|en = 'Attend the meeting'; fa = 'Attend the meeting';
											|it = 'Partecipare alla riunione';
											|pl = 'Przyjść na spotkanie';
											|tr = 'Randevuya gel'"));
	
	AddRequestForIssues(QueryText,"Document.Meeting",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  Meeting.EmployeeResponsible " + StructureOfReportGeneration.ConditionTextForUsers;
		
		TextOfConditionsSelectionWithParticipants ="
		|AND Meeting.EmployeeResponsible " + StructureOfReportGeneration.ConditionTextForUsers + "
		|OR Meeting.Ref IN
		|	(SELECT DISTINCT
		|		MeetingParticipants.Ref
		|	FROM
		|		Document.Meeting.Attendees AS MeetingParticipants
		|	WHERE
		|		MeetingParticipants.Contact " +StructureOfReportGeneration.ConditionTextForUsers + ")"
		
	Else
		
		TextOfSelectionCondition = "";
		TextOfConditionsSelectionWithParticipants = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfConditionsSelectionWithParticipants",TextOfConditionsSelectionWithParticipants);
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.Meeting");
	
	Return QueryText;
	
EndFunction

Function QueryTextPhoneCalls(Query, StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	PhoneCall.Ref AS ReferenceToEventObject,
	|	PhoneCall.Ref AS SubjectOf,
	|	&ConsiderPhoneCall AS EventType,
	|	PhoneCall.Date AS DateOfEventObject,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN PhoneCall.Date
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1))
	|	END AS EventDate,
	|	PhoneCall.Subject AS LongDesc,
	|	CASE 
	|		WHEN PhoneCall.Incoming
	|			THEN &Incoming
	|		ELSE &Outgoing
	|	END AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN DATEADD(PhoneCall.Date, HOUR, 1) < &CurrentDate
	|						THEN &Overdue
	|					ELSE &CurrentBusinessUnit
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) > &CurrentDate
	|					THEN &Upcoming
	|				WHEN DATEADD(ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)), HOUR, 1) < &CurrentDate
	|					THEN &Overdue
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	PhoneCall.SubscriberContact AS Partner,
	|	PhoneCall.EmployeeResponsible AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.PhoneCall AS PhoneCall
	|		LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON PhoneCall.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT PhoneCall.DeletionMark
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE))
	|	AND CASE
	|			WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|				THEN PhoneCall.Date < &EndDate
	|			ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ConsiderPhoneCall",NStr("vi = 'Xử lý cuộc gọi';
												|ru = 'Отработать телефонный звонок';
												|en = 'Process phone call'; fa = 'Process phone call';
												|it = 'Elaborare la telefonata';
												|pl = 'Wypracować połączenie telefoniczne';
												|tr = 'Telefon görüşmesini işlemek'"));
	Query.SetParameter("Incoming",NStr("vi = 'Đến';
										|ru = 'Входящий';
										|en = 'Incoming'; fa = 'ورودی';
										|it = 'In entrata';
										|pl = 'Przychodzący';
										|tr = 'Gelen'"));
	Query.SetParameter("Outgoing",NStr("vi = 'Đi';
										|ru = 'Исходящий';
										|en = 'Outgoing'; fa = 'خروجی';
										|it = 'In uscita';
										|pl = 'Wychodzący';
										|tr = 'Giden'"));
	
	AddRequestForIssues(QueryText,"Document.PhoneCall",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND PhoneCall.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.PhoneCall");
	
	Return QueryText;

EndFunction

Function QueryTextPlannedInteractions(Query, StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	PlannedInteraction.Ref AS ReferenceToEventObject,
	|	PlannedInteraction.Ref AS SubjectOf,
	|	&ConsiderPlannedInteraction AS EventType,
	|	PlannedInteraction.Date AS DateOfEventObject,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN PlannedInteraction.Date
	|		ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1))
	|	END AS EventDate,
	|	PlannedInteraction.Subject AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|			THEN CASE
	|					WHEN DATEADD(PlannedInteraction.Date, HOUR, 1) < &CurrentDate
	|						THEN &Overdue
	|					ELSE &CurrentBusinessUnit
	|				END
	|		ELSE CASE
	|				WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) > &CurrentDate
	|					THEN &Upcoming
	|				WHEN DATEADD(ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)), HOUR, 1) < &CurrentDate
	|					THEN &Overdue
	|				ELSE &CurrentBusinessUnit
	|			END
	|	END AS Status,
	|	NULL AS Partner,
	|	PlannedInteraction.EmployeeResponsible AS EmployeeResponsible
	|  ,&TheTextToPut
	|FROM
	|	Document.PlannedInteraction AS PlannedInteraction
	|	LEFT JOIN InformationRegister.InteractionsFolderSubjects AS InteractionsFolderSubjects
	|		ON PlannedInteraction.Ref = InteractionsFolderSubjects.Interaction
	|WHERE
	|	NOT PlannedInteraction.DeletionMark
	|	AND (NOT ISNULL(InteractionsFolderSubjects.Reviewed, FALSE)) 
	|	AND CASE
	|			WHEN ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) = DATETIME(1, 1, 1)
	|				THEN PlannedInteraction.Date < &EndDate
	|			ELSE ISNULL(InteractionsFolderSubjects.ReviewAfter, DATETIME(1,1,1)) < &EndDate
	|	END 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ConsiderPlannedInteraction",NStr("vi = 'Xử lý giao tiếp dự kiến';
														|ru = 'Отработать запланированное взаимодействие';
														|en = 'Process planned interaction'; fa = 'Process planned interaction';
														|it = 'Elaborare l''interazione pianificata';
														|pl = 'Wypracować zaplanowaną interakcję';
														|tr = 'Programlı etkileşimi işlemek'"));
	
	AddRequestForIssues(QueryText,"Document.PlannedInteraction",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND PlannedInteraction.EmployeeResponsible" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.PlannedInteraction");
	
	Return QueryText;

EndFunction

Function QueryTextBirthdaysOfContactPersons(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	ContactPersonsForPartners.Ref AS ReferenceToEventObject,
	|	ContactPersonsForPartners.Ref AS SubjectOf,
	|	&BirthdayOfContactPerson AS EventType,
	|	ContactPersonsForPartners.BirthDate AS DateOfEventObject,
	|	ENDOFPERIOD(DATEADD(ContactPersonsForPartners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(ContactPersonsForPartners.BirthDate)),DAY) AS EventDate,
	|	ContactPersonsForPartners.Description AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(DATEADD(ContactPersonsForPartners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(ContactPersonsForPartners.BirthDate)), DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Upcoming
	|	END AS Status,
	|	Partners.Ref AS Partner,
	|	Partners.MainManager AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Catalog.ContactPersonsForPartners AS ContactPersonsForPartners
	|		INNER JOIN Catalog.Partners AS Partners
	|		ON ContactPersonsForPartners.Owner = Partners.Ref
	|WHERE
	|	(ContactPersonsForPartners.RelationEndDate = DATETIME(1, 1, 1)
	|			OR ContactPersonsForPartners.RelationEndDate > &CurrentDate)
	|	AND NOT ContactPersonsForPartners.DeletionMark
	|	AND ContactPersonsForPartners.BirthDate <> DATETIME(1, 1, 1)
	|	AND BEGINOFPERIOD(DATEADD(ContactPersonsForPartners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(ContactPersonsForPartners.BirthDate)), DAY) >= BEGINOFPERIOD(&CurrentDate, DAY)
	|	AND DATEADD(ContactPersonsForPartners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(ContactPersonsForPartners.BirthDate)) < &EndDate
	|	AND &TextOfSelectionCondition
	|
	|UNION
	|
	|SELECT
	|	Partners.Ref AS ReferenceToEventObject,
	|	Partners.Ref AS SubjectOf,
	|	&PartnerSBirthday AS EventType,
	|	Partners.BirthDate AS DateOfEventObject,
	|	ENDOFPERIOD(DATEADD(Partners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(Partners.BirthDate)),DAY) AS EventDate,
	|	Partners.Description AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	CASE
	|		WHEN BEGINOFPERIOD(DATEADD(Partners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(Partners.BirthDate)), DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
	|			THEN &CurrentBusinessUnit
	|		ELSE &Upcoming
	|	END AS Status,
	|	Partners.Ref AS Partner,
	|	Partners.MainManager AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Catalog.Partners AS Partners
	|WHERE
	|	NOT Partners.DeletionMark
	|	AND Partners.BirthDate <> DATETIME(1, 1, 1)
	|	AND BEGINOFPERIOD(DATEADD(Partners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(Partners.BirthDate)), DAY) >= BEGINOFPERIOD(&CurrentDate, DAY)
	|	AND DATEADD(Partners.BirthDate, YEAR, YEAR(&CurrentDate) - YEAR(Partners.BirthDate)) < &EndDate 
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("BirthdayOfContactPerson",NStr("vi = 'Chúc mừng sinh nhật người liên hệ của bạn hàng';
														|ru = 'Поздравить с днем рождения контактное лицо партнера';
														|en = 'Wish happy birthday to the partner''s contact person'; fa = 'Wish happy birthday to the partner''s contact person';
														|it = 'Fare gli auguri di compleanno alla persona di contatto del partner';
														|pl = 'Złożyć gratulacje z okazji urodzin osobie kontaktowej partnera';
														|tr = 'İş ortağı irtibat kişisinin doğum gününü tebrik et'"));
	Query.SetParameter("PartnerSBirthday",NStr("vi = 'Chúc mừng sinh nhật của bạn hàng';
												|ru = 'Поздравить с днем рождения партнера';
												|en = 'Wish happy birthday to the partner'; fa = 'Wish happy birthday to the partner';
												|it = 'Fare gli auguri di compleanno al partner';
												|pl = 'Złożyć gratulacje z okazji urodzin partnerowi';
												|tr = 'İş ortağının doğum gününü tebrik et'"));
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND  Partners.MainManager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.ContactPersonsForPartners");
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Catalog.Partners");
	
	Return QueryText;

EndFunction

Function QueryTextCustomerAcceptanceCertificates(Query,StructureOfReportGeneration)

	QueryText = "
	|SELECT
	|	DiscrepancyReportFollowingShipment.Ref AS ReferenceToEventObject,
	|	DiscrepancyReportFollowingShipment.Ref AS SubjectOf,
	|	&ApprovalOfActOfDiscrepanciesAfterShipment AS EventType,
	|	DiscrepancyReportFollowingShipment.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	DiscrepancyReportFollowingShipment.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	DiscrepancyReportFollowingShipment.Partner AS Partner,
	|	DiscrepancyReportFollowingShipment.Manager AS EmployeeResponsible
	|   ,&TheTextToPut
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|WHERE
	|	DiscrepancyReportFollowingShipment.Posted
	|	AND DiscrepancyReportFollowingShipment.Status = VALUE(Enum.StatusesOfDiscrepancyReport.NotApproved)
	|	AND &TextOfSelectionCondition
	|
	|UNION ALL
	|
	|SELECT
	|	DiscrepancyReportFollowingShipment.Ref AS ReferenceToEventObject,
	|	DiscrepancyReportFollowingShipment.Ref AS SubjectOf,
	|	&WorkingOutActOfDiscrepanciesAfterShipment AS EventType,
	|	DiscrepancyReportFollowingShipment.Date AS DateOfEventObject,
	|	ENDOFPERIOD(&CurrentDate, DAY) AS EventDate,
	|	DiscrepancyReportFollowingShipment.Presentation AS LongDesc,
	|	NULL AS AdditionalDetailsDescription1,
	|	NULL AS AdditionalPropsDescription2,
	|	&CurrentBusinessUnit AS Status,
	|	DiscrepancyReportFollowingShipment.Partner AS Partner,
	|	DiscrepancyReportFollowingShipment.Manager AS EmployeeResponsible
	|   ,&TextEmptyString
	|FROM
	|	Document.DiscrepancyReportFollowingShipment AS DiscrepancyReportFollowingShipment
	|WHERE
	|	DiscrepancyReportFollowingShipment.Posted
	|	AND DiscrepancyReportFollowingShipment.Status = VALUE(Enum.StatusesOfDiscrepancyReport.Approved)
	|	AND &TextOfSelectionCondition";
	
	Query.SetParameter("ApprovalOfActOfDiscrepanciesAfterShipment",NStr("vi = 'Đồng ý với báo cáo sai lệch sau khi giao hàng';
																		|ru = 'Согласовать акт расхождений после отгрузки';
																		|en = 'Approve discrepancy report following shipment'; fa = 'Approve discrepancy report following shipment';
																		|it = 'Concordare l''atto sulle discrepanze dopo la spedizione';
																		|pl = 'Uzgodnij protokół o odchyleniu po wysyłce';
																		|tr = 'Sevkiyattan sonra tutarsızlık raporunu onayla'"));
	Query.SetParameter("WorkingOutActOfDiscrepanciesAfterShipment",NStr("vi = 'Tìm ra hành vi chênh lệch sau khi giao hàng';
																		|ru = 'Отработать акт расхождений после отгрузки';
																		|en = 'Process discrepancy report following shipment'; fa = 'Process discrepancy report following shipment';
																		|it = 'Elaborare l''atto sulle discrepanze dopo la spedizione';
																		|pl = 'Odpracuj protokół o odchyleniu po wysyłce';
																		|tr = 'Sevkiyattan sonra tutarsızlık raporunu işlemek'"));
	
	AddRequestForIssues(QueryText,"Document.DiscrepancyReportFollowingShipment",StructureOfReportGeneration);
	
	If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
		
		TextOfSelectionCondition ="
		|AND DiscrepancyReportFollowingShipment.Manager" + StructureOfReportGeneration.ConditionTextForUsers;
		
	Else
		
		TextOfSelectionCondition = "";
		
	EndIf;
	
	QueryText = StrReplace(QueryText,"AND &TextOfSelectionCondition",TextOfSelectionCondition);
	ProcessSubqueryTextByEventType(QueryText,StructureOfReportGeneration.CurSubqueryNumberByEventType);
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Document.DiscrepancyReportFollowingShipment");
	
	Return QueryText;

EndFunction

Procedure ProcessSubqueryTextByEventType(QueryText,CurSubqueryNumberByEventType) Export
	
	If CurSubqueryNumberByEventType <> 1 Then
		
		QueryText = "
		|;
		|
		|/////////////////////////////////////////////////////////
		|
		|" + QueryText;
	
	EndIf;
	
	TheTextToPut = " INTO DataByEventType" + String(CurSubqueryNumberByEventType);
	QueryText   = StrReplace(QueryText,",&TheTextToPut",TheTextToPut);
	QueryText   = StrReplace(QueryText,",&TextEmptyString", "");

EndProcedure

Procedure AddRequestForIssues(QueryText,MetadataObjectName,StructureOfReportGeneration) Export
	
	If StructureOfReportGeneration.ThereIsAnAssigneeTaskRight And StructureOfReportGeneration.UseBusinessProcessesAndTasks Then
		
		QueryText = QueryText + "
		|
		|UNION ALL
		|
		|SELECT
		|	PerformerTask.Ref AS ReferenceToEventObject,
		|	PerformerTask.SubjectOf AS SubjectOf,
		|	PerformerTask.Description AS EventType,
		|	PerformerTask.Date AS DateOfEventObject,
		|	CASE
		|	WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|		THEN ENDOFPERIOD(&CurrentDate, DAY)
		|		ELSE PerformerTask.TaskDueDate
		|	END AS EventDate,
		|	PRESENTATION(PerformerTask.SubjectOf) AS LongDesc,
		|	&TextAdditionalProps1 AS AdditionalDetailsDescription1,
		|	&TextAdditionalProps2 AS AdditionalPropsDescription2,
		|	CASE
		|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|		THEN &CurrentBusinessUnit
		|		ELSE CASE
		|			WHEN PerformerTask.TaskDueDate < &CurrentDate
		|				THEN &Overdue
		|			WHEN BEGINOFPERIOD(PerformerTask.TaskDueDate, DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
		|				THEN &CurrentBusinessUnit
		|			ELSE &Upcoming
		|		END
		|	END AS Status,
		|	PerformerTask.SubjectOf.Partner AS Partner,
		|	PerformerTask.Performer AS EmployeeResponsible
		|FROM
		|	Task.PerformerTask AS PerformerTask
		|WHERE
		|	PerformerTask.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Running)
		|		AND NOT PerformerTask.Executed
		|		AND VALUETYPE(PerformerTask.SubjectOf) = &ReferenceToMetadataObjectName
		|		AND CASE
		|			WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
		|				THEN TRUE
		|			ELSE PerformerTask.TaskDueDate < &EndDate
		|		END 
		|	AND &ConditionTextTaskSelection";
		
		If Not IsBlankString(StructureOfReportGeneration.ConditionTextForUsers) Then
			
			ConditionTextTaskSelection ="
			|AND  PerformerTask.Performer" + StructureOfReportGeneration.ConditionTextForUsers;
			
			If  StructureOfReportGeneration.ThereIsAnAssigneeRoleRight Then
			
			QueryText = QueryText + "
			|
			|UNION ALL
			|
			|SELECT
			|	PerformerTask.Ref,
			|	PerformerTask.SubjectOf,
			|	PerformerTask.Description,
			|	PerformerTask.Date,
			|	CASE
			|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
			|		THEN BEGINOFPERIOD(&CurrentDate, DAY)
			|		ELSE PerformerTask.TaskDueDate
			|	END,
			|	PerformerTask.SubjectOf AS LongDesc,
			|	&TextAdditionalProps1,
			|	&TextAdditionalProps2,
			|	CASE
			|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
			|			THEN &CurrentBusinessUnit
			|		ELSE CASE
			|		WHEN PerformerTask.TaskDueDate < &CurrentDate
			|			THEN &Overdue
			|		WHEN BEGINOFPERIOD(PerformerTask.TaskDueDate, DAY) = BEGINOFPERIOD(&CurrentDate, DAY)
			|				THEN &CurrentBusinessUnit
			|			ELSE &Upcoming
			|		END
			|	END,
			|	PerformerTask.SubjectOf.Partner,
			|	CASE
			|		WHEN PerformerTask.Performer = VALUE(Catalog.Users.EmptyRef)
			|			THEN PerformerTask.PerformerRole
			|		ELSE PerformerTask.Performer
			|	END 
			|FROM
			|	Task.PerformerTask AS PerformerTask
			|	INNER JOIN FilterForSpecifiedUsers AS FilterForSpecifiedUsers
			|	ON (PerformerTask.PerformerRole = FilterForSpecifiedUsers.PerformerRole
			|			AND PerformerTask.MainAddressingObject = FilterForSpecifiedUsers.MainAddressingObject
			|			AND PerformerTask.AdditionalAddressingObject = FilterForSpecifiedUsers.AdditionalAddressingObject)
			|WHERE
			|	PerformerTask.BusinessProcessState = VALUE(Enum.BusinessProcessStates.Running)
			|	AND NOT PerformerTask.Executed
			|	AND VALUETYPE(PerformerTask.SubjectOf) = &ReferenceToMetadataObjectName
			|	AND CASE
			|		WHEN PerformerTask.TaskDueDate = DATETIME(1, 1, 1)
			|			THEN TRUE
			|		ELSE PerformerTask.TaskDueDate < &EndDate
			|	END";
			
			EndIf;
			
		Else
			
			ConditionTextTaskSelection = "";
			
		EndIf;
		
		QueryText = StrReplace(QueryText,"AND &ConditionTextTaskSelection",ConditionTextTaskSelection);
		QueryText = StrReplace(QueryText,"&ReferenceToMetadataObjectName","TYPE(" + " " + MetadataObjectName + ")"); //@Query-part-2
		
		If MetadataObjectName = "Catalog.TermsOfSale" Or MetadataObjectName = "Catalog.TermsOfPurchaseFromVendors" Then
			
			TextAdditionalProps1 = "PerformerTask.SubjectOf.Number";
			TextAdditionalProps2 = "NULL";
			
		ElsIf MetadataObjectName = "Catalog.CounterpartyContracts" Then
			
			TextAdditionalProps1 = "PRESENTATION(PerformerTask.SubjectOf.BusinessOperation)";
			TextAdditionalProps2 = "NULL";
			
		ElsIf MetadataObjectName = "Document.IncomingEmail" Then
			
			TextAdditionalProps1 = "CAST(PerformerTask.SubjectOf.Subject AS STRING(1024))";
			TextAdditionalProps2 = "PerformerTask.SubjectOf.Date";
			
		ElsIf MetadataObjectName = "Document.OutgoingEmail" Then
			
			TextAdditionalProps1 = "CAST(PerformerTask.SubjectOf.Subject AS STRING(1024))";
			TextAdditionalProps2 = "PerformerTask.SubjectOf.PostingDate";
			
		ElsIf MetadataObjectName = "Document.Meeting" Then
			
			TextAdditionalProps1 = "CAST(PerformerTask.SubjectOf.Subject AS STRING(1024))";
			TextAdditionalProps2 = "PerformerTask.SubjectOf.Date";
			
		ElsIf MetadataObjectName = "Document.PhoneCall" Then
			
			TextAdditionalProps1 = "CAST(PerformerTask.SubjectOf.Subject AS STRING(1024))";
			TextAdditionalProps2 = "PerformerTask.SubjectOf.Date";
			
		ElsIf MetadataObjectName = "Document.PlannedInteraction" Then
			
			TextAdditionalProps1 = "CAST(PerformerTask.SubjectOf.Subject AS STRING(1024))";
			TextAdditionalProps2 = "PerformerTask.SubjectOf.Date";
			
		Else
			
			TextAdditionalProps1 = "NULL";
			TextAdditionalProps2 = "NULL";
			
		EndIf;
		
		QueryText = StrReplace(QueryText,"&TextAdditionalProps1",TextAdditionalProps1);
		QueryText = StrReplace(QueryText,"&TextAdditionalProps2",TextAdditionalProps2);
		
	EndIf;
	
	AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration,"Task.PerformerTask");
	
EndProcedure

Procedure AddTypesToArrayToBeCheckedForAccess(StructureOfReportGeneration, NameOfMetadataObjects) Export
	
	If StructureOfReportGeneration.TypesOfObjectsToCheckForAccess.Find(NameOfMetadataObjects) = Undefined Then
		
		StructureOfReportGeneration.TypesOfObjectsToCheckForAccess.Add(NameOfMetadataObjects);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region DataOutput

Procedure OutputDataToTable(Result, StructureOfReportGeneration, ReportTable)
	
	PartnersARAPRequireUpdate.Clear();
	
	ReportTable.Clear();
	Template = GetTemplate("DataOutput");
	
	EmptyStringArea = Template.GetArea("IsBlankString");
	HeaderArea_    = Template.GetArea("Title");
	SectionHeader        = Template.GetArea("Header");
	AreaRow       = Template.GetArea("String");
	GroupingArea  = Template.GetArea("StringGrouping");
	
	ReportTable.Put(EmptyStringArea);
	HeaderArea_.Parameters.TitleText = NStr("vi = 'Lịch sự kiện';
											|ru = 'Календарь событий';
											|en = 'Event calendar'; fa = 'تقویم رویدادها';
											|it = 'Calendario eventi';
											|pl = 'Kalendarz wydarzeń';
											|tr = 'Etkinlik takvimi'");
	ReportTable.Put(HeaderArea_);
	ReportTable.Put(EmptyStringArea);

	ReportTable.Put(SectionHeader);
	
	CurDateUpcoming = Date(1,1,1);
	ThereIsGroupingUpcoming = False;
	ThereIsGroupingFurther       = False;
	
	SampleStatus = Result.Select(QueryResultIteration.ByGroups);
	While SampleStatus.Next() Do
		
		EventArea  = AreaRow.Areas.EventRow; // SpreadsheetDocumentRange
		AreaValue = GroupingArea.Areas.GroupingValue; // SpreadsheetDocumentRange
		
		If SampleStatus.Status = "Upcoming" Then
			
			EventArea.TextColor  = StyleColors.TextColorOfCanceledRowOfDocument;
			AreaValue.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
			
		Else
			If SampleStatus.Status = "CurrentBusinessUnit" Then
				
				EventArea.TextColor  = StyleColors.FieldTextColor;
				AreaValue.TextColor = StyleColors.FieldTextColor;
				GroupingArea.Parameters.Value = NStr("vi = 'Hôm nay';
													|ru = 'Сегодня';
													|en = 'Today'; fa = 'امروز';
													|it = 'Oggi';
													|pl = 'Today';
													|tr = 'Bugün'") + " ( " + Format(CurrentSessionDate(),"DLF=DD") + " ) - " + SampleStatus.DateOfEventObject;
				
			ElsIf SampleStatus.Status = "Overdue" Then
				
				EventArea.TextColor  = StyleColors.OverdueDataColor;
				AreaValue.TextColor = StyleColors.OverdueDataColor;
				GroupingArea.Parameters.Value = NStr("vi = 'Quá hạn';
													|ru = 'Просроченные';
													|en = 'Overdue'; fa = 'سررسیدگذشته';
													|it = 'Scaduti';
													|pl = 'Overdue';
													|tr = 'Vadesi geçenler'") + " - " + SampleStatus.DateOfEventObject;
				
			EndIf;
			
			ReportTable.Put(GroupingArea);
			ReportTable.StartRowGroup("Group");
			
		EndIf;
		
		SampleDate = SampleStatus.Select(QueryResultIteration.ByGroups);
		While SampleDate.Next() Do
			
			If (SampleStatus.Status = "Upcoming"
				And CurDateUpcoming - (24*60*60*7) < BegOfDay(CurrentSessionDate())
				And BegOfDay(SampleDate.EventDate) <> CurDateUpcoming) Then
				
				CurDateUpcoming = BegOfDay(SampleDate.EventDate);
				TextOfUpcomingGrouping = "";
				
				If BegOfDay(SampleDate.EventDate) - BegOfDay(CurrentSessionDate()) > (24*60*60*7) Then
					TextOfUpcomingGrouping = NStr("vi = 'Tiếp theo...';
													|ru = 'Далее...';
													|en = 'Next ...'; fa = 'Next ...';
													|it = 'Continua...';
													|pl = 'Dalej...';
													|tr = 'İleri...'") ;
					ThereIsGroupingFurther = True;
					
				ElsIf  BegOfDay(SampleDate.EventDate) - BegOfDay(CurrentSessionDate()) = 1 Then
					TextOfUpcomingGrouping = NStr("vi = 'Ngày mai';
													|ru = 'Завтра';
													|en = 'Tomorrow'; fa = 'Tomorrow';
													|it = 'Domani';
													|pl = 'Jutro';
													|tr = 'Yarın'") + " ( " + Format(SampleDate.EventDate,"DLF=DD") + " ) - " + SampleDate.DateOfEventObject;
				Else
					TextOfUpcomingGrouping = String(Enums.WeekDays.Get(WeekDay(SampleDate.EventDate) -1)) + " ( " + Format(SampleDate.EventDate,"DLF=DD") + " ) - " + SampleDate.DateOfEventObject;
				EndIf;
				
				GroupingArea.Parameters.Value = TextOfUpcomingGrouping;
				
				If Not ThereIsGroupingFurther Then
					ThereIsGroupingUpcoming = True;
				EndIf;
				ReportTable.Put(GroupingArea);
				ReportTable.StartRowGroup("Group");
				
			EndIf;
			
			Selection = SampleDate.Select(QueryResultIteration.ByGroups);
			While Selection.Next() Do
				
				FillPropertyValues(AreaRow.Parameters,Selection);
				TransformSubjectPresentation(AreaRow.Parameters.LongDesc,Selection);
				ConvertWhatToDo(AreaRow.Parameters.EventType, Selection);
				WorkOutRelevanceOfCalculations(AreaRow,Selection);
				
				ReportTable.Put(AreaRow,2);
				
			EndDo;
			
			If ThereIsGroupingUpcoming Then
				ReportTable.EndRowGroup();
				ThereIsGroupingUpcoming = False;
			EndIf;
			
		EndDo;
		
		If SampleStatus.Status <> "Upcoming" Or ThereIsGroupingFurther Then
			ReportTable.EndRowGroup();
		EndIf;
		
	EndDo;
	
	ReportTable.FixedTop = 4;
	
EndProcedure

Procedure WorkOutRelevanceOfCalculations(AreaRow,Selection)
	
	EventArea  = AreaRow.Areas.EventStringWithNoDate; // SpreadsheetDocumentRange
	
	If Selection.CalculationsAreIrrelevantWithClient Or Selection.CalculationsAreIrrelevantWithSupplier Then
		
		If PartnersARAPRequireUpdate.FindByValue(Selection.Partner) = Undefined Then
			PartnersARAPRequireUpdate.Add(Selection.Partner);
		EndIf;
		
		If Selection.CalculationsAreIrrelevantWithClient Then
			ThereAreCustomersARAPRequireUpdate = True;
		EndIf;
		
		If Selection.CalculationsAreIrrelevantWithSupplier Then
			ThereAreVendorsARAPRequireUpdate = True;
		EndIf;
		
		EventArea.TextColor = StyleColors.TextColorOfCanceledRowOfDocument;
		AreaRow.Parameters.EventType = NStr("vi = '[Tính toán không thiết thực]';
											|ru = '[Расчет не актуален]';
											|en = '[Calculation is not relevant]'; fa = '[Calculation is not relevant]';
											|it = '[Calcolo obsoleto]';
											|pl = '[Расчет не актуален]';
											|tr = '[Mutabakat güncel değil]'") + Chars.LF + AreaRow.Parameters.EventType;
		
	Else
		
		EventArea.TextColor = StyleColors.FieldTextColor;
		
	EndIf;
	
EndProcedure

Procedure TransformSubjectPresentation(LongDesc,Selection)
	
	If TypeOf(Selection.SubjectOf) = Type("CatalogRef.TermsOfPurchaseFromVendors") Or
		TypeOf(Selection.SubjectOf) = Type("CatalogRef.TermsOfSale") Then
		
		LongDesc = NStr("vi = 'Thỏa thuận với nhà cung cấp';
						|ru = 'Соглашение с поставщиком';
						|en = 'Terms of purchase'; fa = 'شرایط خرید';
						|it = 'Accordi con il fornitore';
						|pl = 'Umowa z dostawcą';
						|tr = 'Satın alma koşulları'") + " '" + LongDesc + "'";
		If Not IsBlankString(Selection.AdditionalDetailsDescription1) Then
			LongDesc = LongDesc + " № " + Selection.AdditionalDetailsDescription1;
		EndIf;
		
		If Date(Selection.DateOfEventObject) <> Date(1,1,1) Then
			LongDesc = LongDesc + " " + NStr("vi = 'ngày';
											|ru = 'от';
											|en = 'dated'; fa = 'مورخ';
											|it = 'del';
											|pl = 'od';
											|tr = 'itibaren'") +" " + Format(Selection.DateOfEventObject,"DLF=D");
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
		
		LongDesc = NStr("vi = 'Vụ việc';
						|ru = 'Сделка';
						|en = 'Sales opportunity'; fa = 'فرصت فروش';
						|it = 'Transazione';
						|pl = 'Umowa';
						|tr = 'Satış fırsatı'") + " '" + LongDesc + "' " + NStr("vi = 'ngày';
																					|ru = 'от';
																					|en = 'dated'; fa = 'مورخ';
																					|it = 'del';
																					|pl = 'od';
																					|tr = 'itibaren'") + " " + Format(Selection.DateOfEventObject,"DLF=D");
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("CatalogRef.Projects") Then
		
		LongDesc = NStr("vi = 'Dự án';
						|ru = 'Проект';
						|en = 'Project'; fa = 'پروژه';
						|it = 'Progetto';
						|pl = 'Projekt';
						|tr = 'Proje'") + " '" + LongDesc + "'";
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("CatalogRef.MarketingActivities") Then
		
		LongDesc = NStr("vi = 'Hoạt động Marketing';
						|ru = 'Маркетинговое мероприятие';
						|en = 'Marketing activity'; fa = 'فعالیت بازاریابی';
						|it = 'Evento di marketing';
						|pl = 'Impreza marketingowa';
						|tr = 'Pazarlama faaliyeti'") + " '" + LongDesc + "'";
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("CatalogRef.CounterpartyContracts") Then
		
		LongDesc = NStr("vi = 'Hợp đồng';
						|ru = 'Договор';
						|en = 'Contract'; fa = 'قرارداد';
						|it = 'Contratto';
						|pl = 'Umowa';
						|tr = 'Sözleşme'") + " " + PresentationOfTransactionContractType(Selection.AdditionalDetailsDescription1) + " '" + LongDesc + "'";
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("DocumentRef.IncomingEmail") Then
		
		If TypeOf(Selection.ReferenceToEventObject) = Type("DocumentRef.IncomingEmail") Then
			LongDesc = NStr("vi = 'E-mail đến';
							|ru = 'Входящее письмо';
							|en = 'Incoming email'; fa = 'ایمیل ورودی';
							|it = 'E-mail in arrivo';
							|pl = 'Przychodzący list';
							|tr = 'Gelen e-posta'") + " '" + ?(IsBlankString(Selection.LongDesc),NStr("vi = 'Chưa chỉ ra chủ đề';
																										|ru = 'Тема не указана';
																										|en = 'Subject is not specified'; fa = 'Subject is not specified';
																										|it = 'Oggetto non specificato';
																										|pl = 'Nie podano tematu';
																										|tr = 'Konu belirtilmedi'") + " ",Selection.LongDesc) + "' "
			           + NStr("vi = 'ngày';
								|ru = 'от';
								|en = 'dated'; fa = 'مورخ';
								|it = 'del';
								|pl = 'od';
								|tr = 'itibaren'") + " " + Selection.DateOfEventObject;
		Else
			LongDesc = NStr("vi = 'E-mail đến';
							|ru = 'Входящее письмо';
							|en = 'Incoming email'; fa = 'ایمیل ورودی';
							|it = 'E-mail in arrivo';
							|pl = 'Przychodzący list';
							|tr = 'Gelen e-posta'") + " '" + ?(IsBlankString(Selection.AdditionalDetailsDescription1),NStr("vi = 'Chưa chỉ ra chủ đề';
																															|ru = 'Тема не указана';
																															|en = 'Subject is not specified'; fa = 'Subject is not specified';
																															|it = 'Oggetto non specificato';
																															|pl = 'Nie podano tematu';
																															|tr = 'Konu belirtilmedi'") + " ",Selection.AdditionalDetailsDescription1)
			           + "' " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") + " " + Selection.AdditionalPropsDescription2;
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("DocumentRef.OutgoingEmail") Then
		
		If TypeOf(Selection.ReferenceToEventObject) = Type("DocumentRef.OutgoingEmail") Then
			LongDesc = NStr("vi = 'E-mail đi';
							|ru = 'Исходящее письмо';
							|en = 'Outgoing email'; fa = 'ایمیل خروجی';
							|it = 'Messaggio in uscita';
							|pl = 'List wychodzący';
							|tr = 'Giden e-posta'") + " '" 
			           + ?(IsBlankString(Selection.LongDesc),NStr("vi = 'Chưa chỉ ra chủ đề';
																	|ru = 'Тема не указана';
																	|en = 'Subject is not specified'; fa = 'Subject is not specified';
																	|it = 'Oggetto non specificato';
																	|pl = 'Nie podano tematu';
																	|tr = 'Konu belirtilmedi'") + " ",Selection.LongDesc) 
			           + "' " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") + " " + Selection.DateOfEventObject;
		Else
			LongDesc = NStr("vi = 'E-mail đi';
							|ru = 'Исходящее письмо';
							|en = 'Outgoing email'; fa = 'ایمیل خروجی';
							|it = 'Messaggio in uscita';
							|pl = 'List wychodzący';
							|tr = 'Giden e-posta'") + " '" 
			           + ?(IsBlankString(Selection.AdditionalDetailsDescription1),NStr("vi = 'Chưa chỉ ra chủ đề';
																						|ru = 'Тема не указана';
																						|en = 'Subject is not specified'; fa = 'Subject is not specified';
																						|it = 'Oggetto non specificato';
																						|pl = 'Nie podano tematu';
																						|tr = 'Konu belirtilmedi'") +" ",Selection.AdditionalDetailsDescription1) 
			           + "' " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") +" " + Selection.AdditionalPropsDescription2;
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("DocumentRef.Meeting") Then
		
		If TypeOf(Selection.ReferenceToEventObject) = Type("DocumentRef.Meeting") Then
			LongDesc = NStr("vi = 'Cuộc gặp';
							|ru = 'Встреча';
							|en = 'Meeting'; fa = 'Meeting';
							|it = 'Incontro';
							|pl = 'Spotkanie';
							|tr = 'Randevu'") + " '" + ?(IsBlankString(Selection.LongDesc),NStr("vi = 'Chưa chỉ ra chủ đề';
																								|ru = 'Тема не указана';
																								|en = 'Subject is not specified'; fa = 'Subject is not specified';
																								|it = 'Oggetto non specificato';
																								|pl = 'Nie podano tematu';
																								|tr = 'Konu belirtilmedi'") + " ",Selection.LongDesc) + "' "
			           + NStr("vi = 'ngày';
								|ru = 'от';
								|en = 'dated'; fa = 'مورخ';
								|it = 'del';
								|pl = 'od';
								|tr = 'itibaren'") + " " + Selection.DateOfEventObject;
		Else
			LongDesc = NStr("vi = 'Cuộc gặp';
							|ru = 'Встреча';
							|en = 'Meeting'; fa = 'Meeting';
							|it = 'Incontro';
							|pl = 'Spotkanie';
							|tr = 'Randevu'") + " '" + ?(IsBlankString(Selection.AdditionalDetailsDescription1),NStr("vi = 'Chưa chỉ ra chủ đề';
																													|ru = 'Тема не указана';
																													|en = 'Subject is not specified'; fa = 'Subject is not specified';
																													|it = 'Oggetto non specificato';
																													|pl = 'Nie podano tematu';
																													|tr = 'Konu belirtilmedi'") + " ",Selection.AdditionalDetailsDescription1)
			           + "' " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") + " " + Selection.AdditionalPropsDescription2;
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("DocumentRef.PlannedInteraction") Then
		
		If TypeOf(Selection.ReferenceToEventObject) = Type("DocumentRef.PlannedInteraction") Then
			LongDesc = NStr("vi = 'Giao tiếp dự tính';
							|ru = 'Запланированное взаимодействие';
							|en = 'Scheduled interaction'; fa = 'تعامل برنامه‌ریزی‌شده';
							|it = 'Interazione pianificata';
							|pl = 'Interakcja zaplanowana';
							|tr = 'Programlı etkileşim'") + " '" +
			           ?(IsBlankString(Selection.LongDesc),NStr("vi = 'Chưa chỉ ra chủ đề';
																|ru = 'Тема не указана';
																|en = 'Subject is not specified'; fa = 'Subject is not specified';
																|it = 'Oggetto non specificato';
																|pl = 'Nie podano tematu';
																|tr = 'Konu belirtilmedi'") + " ",Selection.LongDesc) + "' " + NStr("vi = 'ngày';
																																			|ru = 'от';
																																			|en = 'dated'; fa = 'مورخ';
																																			|it = 'del';
																																			|pl = 'od';
																																			|tr = 'itibaren'") + " " + Selection.DateOfEventObject;
		Else
			LongDesc = NStr("vi = 'Giao tiếp dự tính';
							|ru = 'Запланированное взаимодействие';
							|en = 'Scheduled interaction'; fa = 'تعامل برنامه‌ریزی‌شده';
							|it = 'Interazione pianificata';
							|pl = 'Interakcja zaplanowana';
							|tr = 'Programlı etkileşim'") + " '"
			           + ?(IsBlankString(Selection.AdditionalDetailsDescription1),NStr("vi = 'Chưa chỉ ra chủ đề';
																						|ru = 'Тема не указана';
																						|en = 'Subject is not specified'; fa = 'Subject is not specified';
																						|it = 'Oggetto non specificato';
																						|pl = 'Nie podano tematu';
																						|tr = 'Konu belirtilmedi'") 
			           + " ",Selection.AdditionalDetailsDescription1) + "' " + NStr("vi = 'ngày';
																					|ru = 'от';
																					|en = 'dated'; fa = 'مورخ';
																					|it = 'del';
																					|pl = 'od';
																					|tr = 'itibaren'") + " " + Selection.AdditionalPropsDescription2;
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("DocumentRef.PhoneCall") Then
		
		If TypeOf(Selection.ReferenceToEventObject) = Type("DocumentRef.PhoneCall") Then
		
			LongDesc = Selection.AdditionalDetailsDescription1 + " " + NStr("vi = 'cuộc gọi điện thoại';
																			|ru = 'тел. звонок';
																			|en = 'phone call'; fa = 'phone call';
																			|it = 'telefonata';
																			|pl = 'połączenie tel.';
																			|tr = 'telefon görüşmesi'") + " '"
			           + ?(IsBlankString(Selection.LongDesc),NStr("vi = 'Chưa chỉ ra chủ đề';
																	|ru = 'Тема не указана';
																	|en = 'Subject is not specified'; fa = 'Subject is not specified';
																	|it = 'Oggetto non specificato';
																	|pl = 'Nie podano tematu';
																	|tr = 'Konu belirtilmedi'") + " ",Selection.LongDesc) + "' " + NStr("vi = 'ngày';
																																			|ru = 'от';
																																			|en = 'dated'; fa = 'مورخ';
																																			|it = 'del';
																																			|pl = 'od';
																																			|tr = 'itibaren'") + " " + Selection.DateOfEventObject;
		
		Else
		
			LongDesc = NStr("vi = 'cuộc gọi điện thoại';
							|ru = 'тел. звонок';
							|en = 'Phone call'; fa = 'تماس تلفنی';
							|it = 'telefonata';
							|pl = 'połączenie tel.';
							|tr = 'telefon görüşmesi'") + " '" + ?(IsBlankString(Selection.AdditionalDetailsDescription1),NStr("vi = 'Chưa chỉ ra chủ đề';
																														|ru = 'Тема не указана';
																														|en = 'Subject is not specified'; fa = 'Subject is not specified';
																														|it = 'Oggetto non specificato';
																														|pl = 'Nie podano tematu';
																														|tr = 'Konu belirtilmedi'") + " ",Selection.AdditionalDetailsDescription1) +
			           "' " + NStr("vi = 'ngày';
									|ru = 'от';
									|en = 'dated'; fa = 'مورخ';
									|it = 'del';
									|pl = 'od';
									|tr = 'itibaren'") + " " + Selection.AdditionalPropsDescription2;
			
		EndIf;
		
	ElsIf TypeOf(Selection.SubjectOf) = Type("CatalogRef.ProjectTasks") Then
		
		If TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.Complaints") Then
			LongDesc = NStr("vi = 'Nhiệm vụ dự án theo khiếu nại của khách hàng';
							|ru = 'Задача проекта по претензии клиента';
							|en = 'Project task on the customer complaint'; fa = 'Project task on the customer complaint';
							|it = 'Obiettivo del progetto relativo al reclamo del cliente';
							|pl = 'Zadanie projektu dla roszczenia klienta';
							|tr = 'Müşteri şikayetine göre proje görevi'") + " '" + LongDesc + "'";
		ElsIf TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
			LongDesc = NStr("vi = 'Nhiệm vụ dự án theo vụ việc';
							|ru = 'Задача проекта по сделке';
							|en = 'Project task under sales opportunity'; fa = 'Project task under sales opportunity';
							|it = 'Obiettivo del progetto relativo alla transazione';
							|pl = 'Zadanie projektu wg umowy';
							|tr = 'Satış fırsatına göre proje görevi'")  + " '" + LongDesc + "'";
		ElsIf TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.MarketingActivities") Then
			LongDesc = NStr("vi = 'Nhiệm vụ dự án theo hoạt động Marketing';
							|ru = 'Задача проекта по маркетинговому мероприятию';
							|en = 'Project task for marketing activity'; fa = 'Project task for marketing activity';
							|it = 'Obiettivo del progetto relativo all''evento di marketing';
							|pl = 'Zadanie projektu';
							|tr = 'Pazarlama faaliyetlerine göre proje görevi'")  + " '" + LongDesc + "'";
		Else
			LongDesc = NStr("vi = 'Nhiệm vụ của dự án';
							|ru = 'Задача проекта';
							|en = 'Project task'; fa = 'وظیفه پروژه';
							|it = 'Attività del progetto';
							|pl = 'Zadanie projektu';
							|tr = 'Proje görevi'") + " '" + LongDesc + "'";
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure ConvertWhatToDo(EventType, Selection)
	
	If TypeOf(Selection.SubjectOf) = Type("CatalogRef.ProjectTasks") Then
		If TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.Complaints") Then
			EventType = EventType + NStr("vi = 'theo khiếu nại của khách hàng';
										|ru = 'по претензии клиента';
										|en = 'by customer complaint'; fa = 'by customer complaint';
										|it = 'relativo al reclamo del cliente';
										|pl = 'dla roszczenia klienta';
										|tr = 'müşteri şikayetine göre'");
		ElsIf TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.SalesOpportunitiesToCustomer") Then
			EventType = EventType + NStr("vi = 'theo vụ việc';
										|ru = 'по сделке';
										|en = 'by sales opportunity'; fa = 'by sales opportunity';
										|it = 'relativo alla transazione';
										|pl = 'wg umowy';
										|tr = 'satış fırsatına göre'");
		ElsIf TypeOf(Selection.AdditionalDetailsDescription1) = Type("CatalogRef.MarketingActivities") Then
			EventType = EventType + NStr("vi = 'theo sự kiện Marketing';
										|ru = 'по маркетинговому мероприятию';
										|en = 'by marketing activity'; fa = 'by marketing activity';
										|it = 'relativo all''evento di marketing';
										|pl = 'dla wydarzenia marketingowego';
										|tr = 'pazarlama faaliyetlerine göre'");
		EndIf;
	EndIf;
	
EndProcedure

Function PresentationOfTransactionContractType(Operation)
	
	If Operation = Enums.BusinessTransactions.SaleToCustomer Then
		Return NStr("vi = 'với khách hàng';
					|ru = 'с покупателем';
					|en = 'with customer'; fa = 'with customer';
					|it = 'con il cliente';
					|pl = 'z kupującym';
					|tr = 'müşteriyle'");
	ElsIf Operation = Enums.BusinessTransactions.TransferToCommissionAgent Then
		Return NStr("vi = 'với người nhận bán ký gửi';
					|ru = 'с комиссионером';
					|en = 'with consignee'; fa = 'with consignee';
					|it = 'con il commissionario';
					|pl = 'z komisantem';
					|tr = 'konsinye ile'");
	ElsIf Operation = Enums.BusinessTransactions.PurchaseFromSupplier Then
		Return NStr("vi = 'với nhà cung cấp';
					|ru = 'с поставщиком';
					|en = 'with vendor'; fa = 'with vendor';
					|it = 'con il fornitore';
					|pl = 'z dostawcą';
					|tr = 'tedarikçiyle'");
	ElsIf Operation = Enums.BusinessTransactions.ConsignmentProcurement Then
		Return NStr("vi = 'với người đặt ký gửi';
					|ru = 'с комитентом';
					|en = 'with consignor'; fa = 'with consignor';
					|it = 'con il committente';
					|pl = 'z komitentem';
					|tr = 'göndericiyle'");
	ElsIf Operation = Enums.BusinessTransactions.PurchaseByImport Then
		Return NStr("vi = 'kết nhập';
					|ru = 'импорта';
					|en = 'import'; fa = 'import';
					|it = 'importazione';
					|pl = 'import';
					|tr = 'ithalat'");
	Else
		Return "";
	EndIf;
	
EndFunction

#EndRegion

#Region Other

Procedure GenerateReport(ReportTable, StructureOfReportGeneration)  Export
	
	Result = QueryResultBasedOnReportData(StructureOfReportGeneration);
	OutputDataToTable(Result, StructureOfReportGeneration, ReportTable);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf