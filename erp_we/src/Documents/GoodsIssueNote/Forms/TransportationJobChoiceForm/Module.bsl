
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	SetPrivilegedMode(True);
	
	If Parameters.Property("Orders_3") Then
		
		Query = New Query;
		Query.Text =
		"SELECT DISTINCT
		|	GoodsIssueNote.Recipient AS Recipient
		|FROM
		|	Document.GoodsIssueNote AS GoodsIssueNote
		|WHERE
		|	GoodsIssueNote.Ref IN(&Orders_3)";
		
		Query.SetParameter("Orders_3", Parameters.Orders_3);
		
		Recipients 	= Query.Execute().Unload().UnloadColumn("Recipient");
		Warehouse 		= Parameters.Warehouse;
		
		If Recipients.Count() = 1 Then
			Recipient = Recipients[0];
		EndIf;
		
		Orders_3.LoadValues(Parameters.Orders_3);
		
	Else
		
		Orders_3.Add(Parameters.WarehouseDocument);
		
		OrderDetails_1 = Common.ObjectAttributesValues(Parameters.WarehouseDocument, "Status, Recipient, Warehouse");
		
		NoteStatus 	= Parameters.NoteStatus;
		Recipient 		= OrderDetails_1.Recipient;
		Warehouse 			= OrderDetails_1.Warehouse;
		
		If Not ValueIsFilled(NoteStatus) Then
			NoteStatus = OrderDetails_1.Status;
		EndIf;
		
	EndIf;
	
	QueryText =
	"SELECT DISTINCT
	|	OrdersOrders_.ReferenceOrder AS ReferenceOrder
	|INTO OrdersOrders_
	|FROM
	|	Document.GoodsIssueNote.GoodsByReferences AS OrdersOrders_
	|WHERE
	|	OrdersOrders_.Ref IN(&Orders_3)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	NestedQuery.Carrier
	|FROM
	|	(SELECT
	|		VALUE(Catalog.Partners.EmptyRef) AS Carrier
	|	WHERE
	|		FALSE ) AS NestedQuery";
	
	QueryText = StrReplace(QueryText, ") AS NestedQuery", "");
	
	For Each TypeOfDeliveryOrder In Metadata.DefinedTypes.DeliveryReferenceOrder.Type.Types() Do
		
		MetadataOfOrders = Metadata.FindByType(TypeOfDeliveryOrder);
		
		If Not Common.HasObjectAttribute("CarrierPartner", MetadataOfOrders) Then
			Continue;
		EndIf;
		
		QueryText = QueryText + "
		|	UNION ALL
		|" + "
		|	SELECT
		|		OrderHeaderTable.CarrierPartner
		|	FROM
		|		#FullDocumentName AS OrderHeaderTable
		|	WHERE
		|		OrderHeaderTable.Ref IN
		|				(SELECT
		|					OrdersOrders_.ReferenceOrder
		|				FROM
		|					OrdersOrders_ AS OrdersOrders_)";
		
		FullDocumentName 	= MetadataOfOrders.FullName();
		QueryText 		= StrReplace(QueryText, "#FullDocumentName", FullDocumentName);
		
	EndDo;
	
	QueryText = QueryText + ") AS NestedQuery";
	
	Query = New Query;
	Query.Text = QueryText;
	Query.SetParameter("Orders_3", Orders_3);
	
	Carriers.LoadValues(Query.Execute().Unload().UnloadColumn("Carrier"));
	
	// First, we will add up the delivery zones in accordance to ensure that the values are not repeated.
	NameOfDeliveryZone 	= "";
	DeliveryAreasCompliance 	= New Map;
	RecipientSender 		= ?(ValueIsFilled(Recipient), Recipient, Undefined);
	
	// Most likely, there will be one carrier in the carriers, because within the framework of one order, it is unlikely
	// that there will be orders with different carriers.
	// If all orders with our delivery without a carrier, then there will be at least an empty link in the list.
	// So it will normally work here once, without a cycle.
	For Each Carrier In Carriers Do
		DeliveryDetails_ = GoodsDelivery.LastDeliveryDetailsFromTasks(RecipientSender, Carrier.Value);
		
		If DeliveryDetails_.Count() > 0
			And ValueIsFilled(DeliveryDetails_[0].DeliveryZone) Then
			
			DeliveryAreasCompliance.Insert(DeliveryDetails_[0].DeliveryZone);
			
		EndIf;
	EndDo;
	
	For Each DeliveryZone In DeliveryAreasCompliance Do
		DeliveryZones.Add(DeliveryZone.Key, DeliveryZone.Key);
		
		NameOfDeliveryZone = NameOfDeliveryZone + DeliveryZone.Key + ", ";
	EndDo;
	
	NameOfDeliveryZone = Left(NameOfDeliveryZone, StrLen(NameOfDeliveryZone) - 2);
	
	Items.FilterByReferences.ChoiceList.Clear();
	ChoiceItem = Items.FilterByReferences.ChoiceList.Add("TasksByOrders");
	
	ChoiceItem.Presentation = StrReplace(NStr("vi = 'Nhiệm vụ vận chuyển cho các lệnh giống như %WarehouseDocument%';
												|ru = 'Задания на перевозку по тем же распоряжениям, что и %WarehouseDocument%';
												|en = 'Itineraries by the same references as %WarehouseDocument%'; fa = 'Itineraries by the same references as %WarehouseDocument%';
												|it = 'Task di trasporto secondo le stesse disposizioni che %WarehouseDocument%';
												|pl = 'Zadania na przewóz według tych samych zamówień, co i %WarehouseDocument%';
												|tr = '%WarehouseDocument%Aynı siparişler altındaki taşıma planı'"), "%WarehouseDocument%",
		?(Orders_3.Count() > 1, NStr("vi = 'lệnh';
									|ru = 'ордера';
									|en = 'notes'; fa = 'notes';
									|it = 'mandati';
									|pl = 'notes';
									|tr = 'siparişler'"), NStr("vi = 'bảo đảm';
															|ru = 'ордер';
															|en = 'note'; fa = 'یادداشت';
															|it = 'mandato';
															|pl = 'note';
															|tr = 'sipariş'")));
	
	ChoiceItem = Items.FilterByReferences.ChoiceList.Add("TasksByRecipient");
	ChoiceItem.Presentation = StrReplace(NStr("vi = 'Tất cả các công việc cho người nhận ""%Recipient%""';
												|ru = 'Все задания по получателю ""%Recipient%""';
												|en = 'All jobs by recipient ""%Recipient%""'; fa = 'All jobs by recipient ""%Recipient%""';
												|it = 'Tutti i task secondo il destinatario ""%Recipient%""';
												|pl = 'Wszystkie zadania według odbiorcy ""%Recipient%""';
												|tr = 'Alıcıya göre görevler ""%Recipient%""'"), "%Recipient%", Recipient);
	ChoiceItem.Presentation = ?(StrFind(ChoiceItem.Presentation, """") <> 0,
		StrReplace(ChoiceItem.Presentation, """""", ""),
		ChoiceItem.Presentation);
	
	ChoiceItem = Items.FilterByReferences.ChoiceList.Add("TasksByDeliveryZone");
	ChoiceItem.Presentation = StrReplace(NStr("vi = 'Tất cả các nhiệm vụ cho %Zone% giao hàng ""%DeliveryZone%""';
												|ru = 'Все задания по %Zone% доставки ""%DeliveryZone%""';
												|en = 'All jobs for the ""%DeliveryZone%"" delivery %Zone%'; fa = 'All jobs for the ""%DeliveryZone%"" delivery %Zone%';
												|it = 'Tutti i task per %Zone% consegna""%DeliveryZone%""';
												|pl = 'Wszystkie zadania według %Zone% dostawy ""%DeliveryZone%""';
												|tr = 'Teslimatla %Zone% ile ilgili tüm görevler ""%DeliveryZone%""'"), "%Zone%",
		?(DeliveryZones.Count() > 1, NStr("vi = 'khu vực';
											|ru = 'зонам';
											|en = 'areas'; fa = 'areas';
											|it = 'aree';
											|pl = 'strefom';
											|tr = 'alanlara'"), NStr("vi = 'khu vực';
																|ru = 'зоне';
																|en = 'area'; fa = 'area';
																|it = 'area';
																|pl = 'strefie';
																|tr = 'alana'")));
	ChoiceItem.Presentation = StrReplace(ChoiceItem.Presentation, "%DeliveryZone%", NameOfDeliveryZone);
	ChoiceItem.Presentation = ?(StrFind(ChoiceItem.Presentation, """") <> 0,
		StrReplace(ChoiceItem.Presentation, """""", ""),
		ChoiceItem.Presentation);
	
	FilterByReferences 	= "TasksByOrders";
	SelectionByTaskStatus 	= Enums.StatusesOfTransportationJobs.ToLoad;
	
	FillInListOfTasks();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterByReferencesOnChange(Item)
	
	ClearMessages();
	
	If FilterByReferences <> "TasksByOrders" Then
		SelectionByTaskStatus = PredefinedValue("Enum.StatusesOfTransportationJobs.ToLoad");
		Items.SelectionByTaskStatus.Enabled = False;
	Else
		Items.SelectionByTaskStatus.Enabled = True;
	EndIf;
	
	FillInListOfTasks();
	
EndProcedure

&AtClient
Procedure SelectionByTaskStatusOnChange(Item)
	
	SetFilterByStatus();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersReferences

&AtClient
Procedure TransportationJobsSelection(Item, RowSelected, Field, StandardProcessing)
	
	CurrentData = Items.TransportationJobs.CurrentData;
	
	If YouCanChooseThisTask() Then
		NotifyChoice(CurrentData.TransportationJob);
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	CurrentData = Items.TransportationJobs.CurrentData;
	
	If CurrentData = Undefined Then
		WarningText_ = NStr("vi = 'Chọn một nhiệm vụ vận chuyển.';
							|ru = 'Выберите задание на перевозку.';
							|en = 'Select an itinerary.'; fa = 'Select an itinerary.';
							|it = 'Selezionate il task di trasporto.';
							|pl = 'Wybierz zadanie przewozu.';
							|tr = 'Taşıma planı görevi seç.'");
		
		ShowMessageBox(, WarningText_);
		Return;
	EndIf;
	
	If YouCanChooseThisTask() Then
		NotifyChoice(CurrentData.TransportationJob);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure FillInListOfTasks()
	
	TransportationJobs.Clear();
	
	Query = New Query;
	
	If FilterByReferences = "TasksByOrders" Then
		
		MessageText = NStr("vi = 'Không có nhiệm vụ có sẵn để lựa chọn, các đơn hàng trong số đó là các đơn hàng được chỉ định trong %PresentationOfOrders%.';
							|ru = 'Нет доступных заданий для выбора, распоряжениями которых являются распоряжения, указанные в %PresentationOfOrders%.';
							|en = 'No available jobs to select that have references specified in %PresentationOfOrders%.'; fa = 'No available jobs to select that have references specified in %PresentationOfOrders%.';
							|it = 'Non esistono task, che hanno come disposizioni quelle indicate nel %PresentationOfOrders%, disponibili per la selezione.';
							|pl = 'Brak dostępnych zadań do wyboru, zleceniami których są zlecenia, podane w %PresentationOfOrders%.';
							|tr = 'Emirler içinde %PresentationOfOrders%''de belirtilen emirler olan seçilebilecek erişilebilir görevler mevcut değil.'");
		MessageText = StrReplace(MessageText, "%PresentationOfOrders%",
			?(ValueIsFilled(NoteStatus),
				NStr("vi = 'đơn hàng đã chọn';
					|ru = 'выбранном ордере';
					|en = 'selected note'; fa = 'selected note';
					|it = 'mandato selezionato';
					|pl = 'wybranym zleceniu';
					|tr = 'seçili siparişte'"),
				NStr("vi = 'đơn hàng đã chọn';
					|ru = 'выбранных ордерах';
					|en = 'selected notes'; fa = 'selected notes';
					|it = 'mandati selezionati';
					|pl = 'wybranych zleceniach';
					|tr = 'seçili siparişlerde'")));
		
		QueryText =
		"SELECT DISTINCT
		|	OrdersOrders_.Ref 			AS WarehouseDocument,
		|	OrdersOrders_.ReferenceOrder 	AS ReferenceOrder
		|INTO OrdersOrders_
		|FROM
		|	Document.GoodsIssueNote.GoodsByReferences AS OrdersOrders_
		|WHERE
		|	OrdersOrders_.Ref IN(&Orders_3)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	OrdersOrders_.WarehouseDocument 					AS WarehouseDocument,
		|	HandlingTransportTasks.Ref 		AS Ref,
		|	HandlingTransportTasks.ReferenceOrder AS ReferenceOrder
		|INTO HandlingTransportTasks
		|FROM
		|	Document.TransportationJob.References AS HandlingTransportTasks
		|		LEFT JOIN OrdersOrders_ AS OrdersOrders_
		|		ON HandlingTransportTasks.ReferenceOrder = OrdersOrders_.ReferenceOrder
		|WHERE
		|	HandlingTransportTasks.Ref.Posted
		|	AND HandlingTransportTasks.ReferenceOrder IN
		|			(SELECT
		|				OrdersOrders_.ReferenceOrder
		|			FROM
		|				OrdersOrders_ AS OrdersOrders_)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	HandlingTransportTasks.Ref
		|INTO TransportationTasksWithoutOrdersOrders
		|FROM
		|	HandlingTransportTasks AS HandlingTransportTasks
		|		FULL JOIN OrdersOrders_ AS OrdersOrders_
		|		ON HandlingTransportTasks.WarehouseDocument = OrdersOrders_.WarehouseDocument
		|WHERE
		|	HandlingTransportTasks.WarehouseDocument IS NULL
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT DISTINCT
		|	HandlingTransportTasks.Ref
		|INTO SelectedTasks
		|FROM
		|	HandlingTransportTasks AS HandlingTransportTasks
		|WHERE
		|	NOT HandlingTransportTasks.Ref IN
		|			(SELECT
		|				TransportationTasksWithoutOrdersOrders.Ref
		|			FROM
		|				TransportationTasksWithoutOrdersOrders AS TransportationTasksWithoutOrdersOrders)";
		
	ElsIf FilterByReferences = "TasksByRecipient" Then
		
		MessageText = NStr("vi = 'Không có việc làm để lựa chọn. Trong các lệnh chỉ ra người nhận khác nhau.';
							|ru = 'Нет доступных заданий для выбора. В ордерах указаны различные получатели.';
							|en = 'No available jobs to select. Different recipients are specified in the notes.'; fa = 'No available jobs to select. Different recipients are specified in the notes.';
							|it = 'Non esistono task disponibili per selezione. Nei mandati sono indicati destinatari diversi.';
							|pl = 'Brak dostępnych zadań do wyboru. W zleceniach są podane rożni odbiorcy.';
							|tr = 'Aralarından seçim yapılabilecek görevler mevcut değil. Emirlerde farklı alıcıları belirtildi.'");
		
		If Not ValueIsFilled(Recipient) Then
			CommonClientServer.MessageToUser(MessageText);
			Return;
		Else
			QueryText =
			"SELECT DISTINCT
			|	TransportationTask.Ref
			|INTO SelectedTasks
			|FROM
			|	Document.TransportationJob.References AS TransportationTask
			|WHERE
			|	TransportationTask.Ref.Posted
			|	AND TransportationTask.RecipientSender = &Recipient
			|	AND TransportationTask.Carrier IN(&Carriers)
			|	AND TransportationTask.Warehouse = &Warehouse";
			
			Query.SetParameter("Recipient",  Recipient);
			Query.SetParameter("Carriers", Carriers.UnloadValues());
		EndIf;
		
	ElsIf FilterByReferences = "TasksByDeliveryZone" Then 
		
		MessageText = NStr("vi = 'Không có công việc nào có sẵn để chọn theo %Zone% giao hàng.';
							|ru = 'Нет доступных заданий для выбора по %Zone% доставки.';
							|en = 'No available jobs to select in delivery %Zone%.'; fa = 'No available jobs to select in delivery %Zone%.';
							|it = 'Non esistono task disponibili per selezione in base alla %Zone% di consegna.';
							|pl = 'Brak dostępnych zadań do wyboru wg %Zone% dostawy.';
							|tr = '%Zone% göre seçim için erişilebilir teslimat görevleri mevcut değil.'");
		MessageText = StrReplace(MessageText, "%Zone%",
			?(DeliveryZones.Count() > 1,
				NStr("vi = 'khu vực';
					|ru = 'зонам';
					|en = 'areas'; fa = 'areas';
					|it = 'aree';
					|pl = 'strefom';
					|tr = 'alanlara'"),
				NStr("vi = 'khu vực';
					|ru = 'зоне';
					|en = 'area'; fa = 'area';
					|it = 'area';
					|pl = 'strefie';
					|tr = 'alana'")));
		
		If Not ValueIsFilled(DeliveryZones) Then
			CommonClientServer.MessageToUser(MessageText);
			Return;
		Else
			QueryText =
			"SELECT
			|	DeliveryZones.Ref AS DeliveryZone
			|INTO DeliveryZones_
			|FROM
			|	Catalog.DeliveryZones AS DeliveryZones
			|WHERE
			|	DeliveryZones.Ref IN(&DeliveryZones)
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TaskForTransportationRoute.Ref	AS Ref,
			|	TaskForTransportationRoute.Zone 		AS DeliveryZone
			|INTO TasksForTransportationByDeliveryZones
			|FROM
			|	Document.TransportationJob.Route AS TaskForTransportationRoute
			|		INNER JOIN Document.TransportationJob.References AS TransportationTask
			|		ON TaskForTransportationRoute.Ref = TransportationTask.Ref
			|			AND TaskForTransportationRoute.ConnectionKey = TransportationTask.ConnectionKey
			|WHERE
			|	TaskForTransportationRoute.Ref.Posted
			|	AND TaskForTransportationRoute.Zone IN(&DeliveryZones)
			|	AND TransportationTask.Warehouse = &Warehouse
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TransportationJobs.Ref AS Ref
			|INTO TransportationTasksWithoutOrderRoutes
			|FROM
			|	TasksForTransportationByDeliveryZones AS TransportationJobs
			|		FULL JOIN DeliveryZones_ AS DeliveryZones_
			|		ON TransportationJobs.DeliveryZone = DeliveryZones_.DeliveryZone
			|WHERE
			|	TransportationJobs.DeliveryZone IS NULL
			|;
			|
			|////////////////////////////////////////////////////////////////////////////////
			|SELECT DISTINCT
			|	TransportationJobs.Ref
			|INTO SelectedTasks
			|FROM
			|	TasksForTransportationByDeliveryZones AS TransportationJobs
			|WHERE
			|	NOT TransportationJobs.Ref IN
			|		(SELECT
			|			TransportationTasksWithoutOrderRoutes.Ref
			|		FROM
			|			TransportationTasksWithoutOrderRoutes AS TransportationTasksWithoutOrderRoutes)";
			
			Query.SetParameter("DeliveryZones", DeliveryZones.UnloadValues());
		EndIf;
		
	EndIf;
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	SelectedTasks.Ref AS TransportationJob,
	|	SelectedTasks.Ref.Status AS Status,
	|	PRESENTATION(TaskForTransportationRoute.Zone) AS DeliveryZone,
	|	TaskForTransportationRoute.Ref.PlanTripStartTime
	|FROM
	|	SelectedTasks AS SelectedTasks
	|		INNER JOIN Document.TransportationJob.Route AS TaskForTransportationRoute
	|		ON SelectedTasks.Ref = TaskForTransportationRoute.Ref
	|
	|ORDER BY
	|	TaskForTransportationRoute.Ref.PlanTripStartTime
	|TOTALS BY
	|	TransportationJob";
	
	Query.Text = QueryText;
	Query.SetParameter("Orders_3", Orders_3);
	Query.SetParameter("Warehouse", 	Warehouse);
	
	QueryResult = Query.Execute();
	
	If QueryResult.IsEmpty() Then
		CommonClientServer.MessageToUser(MessageText);
		Return;
	EndIf;
	
	Selection = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While Selection.Next() Do
		
		DeliveryZoneText 	= "";
		NewRow 		= TransportationJobs.Add();
		
		SelectionByDeliveryZones = Selection.Select(QueryResultIteration.ByGroups);
		
		While SelectionByDeliveryZones.Next() Do
			NewRow.TransportationJob 	= SelectionByDeliveryZones.TransportationJob;
			NewRow.Status				= SelectionByDeliveryZones.Status;
			
			DeliveryZoneText = DeliveryZoneText + ?(IsBlankString(DeliveryZoneText), "","; ") +
				SelectionByDeliveryZones.DeliveryZone;
		EndDo;
		
		NewRow.DeliveryZones = DeliveryZoneText;
		
	EndDo;
	
	SetFilterByStatus();
	
EndProcedure

&AtServer
Procedure SetFilterByStatus()
	
	If ValueIsFilled(SelectionByTaskStatus) Then
		Items.TransportationJobs.RowFilter = New FixedStructure("Status", SelectionByTaskStatus);
	Else
		Items.TransportationJobs.RowFilter = Undefined;
	EndIf;
	
EndProcedure

&AtClient
Function YouCanChooseThisTask()
	
	CurrentData	= Items.TransportationJobs.CurrentData;
	StatusShipped = PredefinedValue("Enum.GoodsIssueNoteStatuses.Shipped_");
	
	If Orders_3.Count() = 1
		And NoteStatus <> StatusShipped
		And (CurrentData.Status = PredefinedValue("Enum.StatusesOfTransportationJobs.Sent")
			Or CurrentData.Status = PredefinedValue("Enum.StatusesOfTransportationJobs.Closed")) Then
		
		MessageText = NStr("vi = 'Tác vụ vận chuyển đã chọn ở trạng thái ""%JobStatus%"", do đó không thể chỉ định nó trong lệnh, ở trạng thái ""%NoteStatus%"". Thay đổi trạng thái lệnh thành ""%StatusShipped%"".';
							|ru = 'Выбранное задание на перевозку находится в статусе ""%JobStatus%"", поэтому его нельзя указать в ордере, который находится в статусе ""%NoteStatus%"". Измените статус ордера на ""%StatusShipped%"".';
							|en = 'The selected itinerary has status ""%JobStatus%"", so you cannot specify it in the note that has status ""%NoteStatus%"". Change the note status to ""%StatusShipped%"".'; fa = 'The selected itinerary has status ""%JobStatus%"", so you cannot specify it in the note that has status ""%NoteStatus%"". Change the note status to ""%StatusShipped%"".';
							|it = 'Task di trasporto selezionato è nello stato ""%JobStatus%"", perciò non è possibile indicarlo nel mandato, che ha lo stato ""%NoteStatus%"". Modifica lo stato del mandato a ""%StatusShipped%"".';
							|pl = 'Wybrane zadanie przewozu ma status ""%JobStatus%"", więc nie można go podać w zleceniu, który ma status ""%NoteStatus%"". Zmień status zlecenia na ""%StatusShipped%"".';
							|tr = 'Seçilen taşıma planı ""%JobStatus%"" durumunda yer almakta, ""%NoteStatus%"" durumundaki siparişte belirtilemez. Sipariş durumunu ""%StatusShipped%"" olarak değiştir.'");
		MessageText = StrReplace(MessageText, "%JobStatus%", 	CurrentData.Status);
		MessageText = StrReplace(MessageText, "%NoteStatus%", 		NoteStatus);
		MessageText = StrReplace(MessageText, "%StatusShipped%", 	StatusShipped);
		
		ShowMessageBox(, MessageText);
		Return False;
		
	EndIf;
	
	Return True;
	
EndFunction

#EndRegion