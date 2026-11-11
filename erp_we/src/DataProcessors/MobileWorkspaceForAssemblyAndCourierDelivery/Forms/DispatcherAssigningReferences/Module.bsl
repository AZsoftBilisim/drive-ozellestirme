
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Title = Employee;
	Employee          = Parameters.Employee;
	CurrentWarehouse       = Parameters.CurrentWarehouse;
	ThisIsControl        = Parameters.ThisIsControl;
	ThisIsDelivery        = Parameters.ThisIsDelivery;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	
	SetConditionalAppearance();
	FillInListOfOrders_();
	FillInStatistics();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersAssignedToMe

&AtClient
Procedure ListOfOrdersAssignedToMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListOfOrders_Selected Then
		
	Else
		
		LongDesc = New CallbackDescription("UpdateFormData", ThisForm);
		
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
		FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
			FormOpenParameters,
			ThisForm,,,,LongDesc,
			FormWindowOpeningMode.Independent);
		
	EndIf;

EndProcedure

&AtClient
Procedure ListOfOrders_SelectedOnChange(Item)
	
	OrdersSelected = 0;
	
	For Each OrderRow In ListOfOrders_ Do
		
		If OrderRow.Selected Then
			OrdersSelected = OrdersSelected + 1;
		EndIf;
		
	EndDo;
	
	Items.Assign.Title = NStr("vi = 'Ấn định';
								|ru = 'Назначить';
								|en = 'Assign'; fa = 'تخصیص';
								|it = 'Assegnare';
								|pl = 'Assign';
								|tr = 'Ata'") + " " + String(OrdersSelected);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Assign(Command)
	AssignEmployeeToServer();
	Close();
EndProcedure

&AtClient
Procedure RemoveAnEmployee(Command)
	OrderChanged_ = RemoveEmployeeFromServer(Items.ListOfOrders_.CurrentData.ReferenceOrder);
	If OrderChanged_ Then
		UpdateFormData();
	Else
		If ThisIsDelivery Then
			ErrorText = NStr("vi = 'Không thể bỏ người vận chuyển.';
							|ru = 'Не удалось снять курьера.';
							|en = 'Cannot release courier.'; fa = 'Cannot release courier.';
							|it = 'Non è stato possibile rimuovere il corriere.';
							|pl = 'Nie udało się odwołać kuriera.';
							|tr = 'Kurye kaldırılamadı.'");
		Else
			ErrorText = NStr("vi = 'Không thể bỏ người thu thập.';
							|ru = 'Не удалось снять сборщика.';
							|en = 'Cannot release picker.'; fa = 'Cannot release picker.';
							|it = 'Non è stato possibile rimuovere l''assemblatore.';
							|pl = 'Nie udało się odwołać zbieracza.';
							|tr = 'Montajcı kaldırılamadı.'");
		EndIf;
		CommonClient.MessageToUser(ErrorText);
	EndIf;
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	UpdateFormData();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	FillInListOfOrders_();
	FillInStatistics();
	
EndProcedure

&AtServer
Procedure FillInStatistics()
	
	Assigned_ = 0;
	InProcess = 0;
	Done = 0;
	LastDate_ = Date('0001,01,01');
	
	If ThisIsDelivery Then
		Query = RequestForDeliveryStatistics();
	Else
		Query = RequestForAssemblyStatistics();
	EndIf;

	Results = Query.ExecuteBatch();
	
	SelectionAssigned = Results[0].Select();
	SamplingInProgress = Results[1].Select();
	SelectionDone_ = Results[2].Unload();
	
	While SelectionAssigned.Next() Do
		Assigned_ = SelectionAssigned.Assigned_;
	EndDo;
	
	While SamplingInProgress.Next() Do
		InProcess = SamplingInProgress.InProcess;
	EndDo;
	
	For Each LineSelectionDone In SelectionDone_ Do
		
		LastDate_ = LineSelectionDone.Date;
		Done = LineSelectionDone.Count;
		
	EndDo;
	
	Items.DesignatedNumberOf.Title = Assigned_;
	Items.InTheProcessTheNumber.Title = InProcess;
	Items.NumberOfOrdersCompleted.Title = Done;
	If LastDate_ = NULL Then
		Items.LastTime.Title = " none";
	Else
		Items.LastTime.Title = " In " + Format(LastDate_,"DF=HH:mm");
	EndIf;
EndProcedure

&AtServer
Procedure FillInListOfOrders_()
	
	If ThisIsControl Then
		Query = RequestControl();
	Else
		Query = RequestAssignment();
	EndIf;
	
	Results = Query.ExecuteBatch();
	
	SamplingByOrders = Results[1].Select();
	
	ListOfOrders_.Clear();
	
	While SamplingByOrders.Next() Do
		
		NewRow = ListOfOrders_.Add();
		
		FillPropertyValues(NewRow, SamplingByOrders);
		
		If ValueIsFilled(NewRow.Comment) Then
			NewRow.CommentPicture_2 = PictureLib.CommentRedDelivery;
		EndIf;
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.ThereIsStillTimeForDelivery = Module.ThereIsStillTimeForDelivery(NewRow);
		NewRow.SumPresentation = Module.SumPresentation(NewRow);
		NewRow.PaymentMethodPresentation = Module.PaymentMethodPresentation(NewRow);
		
		NewRow.RowsCount = String(SamplingByOrders.NumberOfRowsAssembled) + "/" + String(SamplingByOrders.NumberOfRowsInOrder);
		
	EndDo;
	
	NumberOfOrdersPerWarehouse = ListOfOrders_.Count();
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()
	
	Title = Employee;
	
	Items.ListOfOrdersToRemove.Visible    = ThisIsControl;
	Items.ListOfOrders_Selected.Visible   = Not ThisIsControl;
	Items.Assign.Visible                  = Not ThisIsControl;
	
	If ThisIsDelivery Then
		Items.OrdersCompleted_3.Title             = NStr("vi = 'Đã chuyển';
														|ru = 'Доставлено';
														|en = 'Delivered'; fa = 'تحویل‌شده';
														|it = 'Consegnato';
														|pl = 'Dostarczono';
														|tr = 'Teslim edildi'");
		Items.OrdersInProgress.Title             = NStr("vi = 'Đang chuyển';
														|ru = 'Доставляется';
														|en = 'Delivery in progress'; fa = 'تحویل در جریان';
														|it = 'Consegnato';
														|pl = 'Dostarcza się';
														|tr = 'Teslim ediliyor'");
		Items.ListOfOrdersToRemove.Title           = NStr("vi = 'Bỏ người vận chuyển';
															|ru = 'Снять курьера';
															|en = 'Release courier'; fa = 'آزادسازی پیک';
															|it = 'Rimuovere corriere';
															|pl = 'Odwołaj kuriera';
															|tr = 'Kuryeni kaldır'");
		Items.ListOfOrders_RowsCount.Visible = False;
	Else
		Items.OrdersCompleted_3.Title             = NStr("vi = 'Gom được';
														|ru = 'Собрано';
														|en = 'Assembled'; fa = 'مونتاژشده';
														|it = 'Composto';
														|pl = 'Assembled';
														|tr = 'Toplandı'");
		Items.OrdersInProgress.Title             = NStr("vi = 'Đi đến';
														|ru = 'Собирается';
														|en = 'Kitting in progress'; fa = 'کیت‌سازی در جریان';
														|it = 'In composizione';
														|pl = 'Kitting in progress';
														|tr = 'Toplanıyor'");
		Items.ListOfOrdersToRemove.Title           = NStr("vi = 'Bỏ gom hàng';
															|ru = 'Снять сборщика';
															|en = 'Release picker'; fa = 'آزادسازی برداشت‌کننده';
															|it = 'Rimuovere assemblatore';
															|pl = 'Odwołaj zbieracza';
															|tr = 'Montajçıyı kaldır'");
		Items.ListOfOrders_RowsCount.Visible = ThisIsControl;
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrdersAssignedToMeStatus.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfOrdersAssignedToMe.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.ReadyStatusTextColorAssemblyAndDelivery);

	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfOrdersAssignedToMeThereIsStillTimeForDelivery.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfOrdersAssignedToMe.LateArrival");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValuesTextColor);
	
EndProcedure

&AtServer
Procedure AssignEmployeeToServer()
	
	For Each OrderLine_2 In ListOfOrders_ Do
		
		If OrderLine_2.Selected Then
			
			OrderObject__ = OrderLine_2.ReferenceOrder.GetObject();
			If ThisIsDelivery Then
				OrderObject__.Courier = Employee;
			Else
				OrderObject__.Picker = Employee;
			EndIf;
			OrderObject__.Write(DocumentWriteMode.Write);
			
		EndIf;
		
	EndDo;
	
EndProcedure

&AtServer
Function RequestControl()
	
	Query = New Query();
	Query.Text = "SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Picker AS Picker,
	|	Documents.Number AS Number,
	|	Documents.DateOfShipment AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	0 AS AmountToPay,
	|	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	NULL AS Date,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS RowsCount,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS NumberOfRowsInOrder,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsAssembled AS NumberOfRowsAssembled,
	|	Documents.Comment AS Comment
	|INTO AllReferences
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.SalesOrder AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND Documents.Posted
	|	AND CASE
	|		WHEN &ThisIsDelivery
	|			THEN Documents.Courier = &Employee
	|		ELSE Documents.Picker = &Employee
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status,
	|	Documents.Warehouse,
	|	Documents.Picker,
	|	Documents.Number,
	|	NULL,
	|	Documents.DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo,
	|	Documents.DocumentAmount,
	|	0,
	|	Documents.DeliveryAddress,
	|	Documents.DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation,
	|	Documents.Currency,
	|	Documents.PaymentMethod,
	|	Documents.Date,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS RowsCount,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsAssembled,
	|	Documents.Comment
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.CustomerInvoice AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND Documents.Posted
	|	AND CASE
	|		WHEN &ThisIsDelivery
	|			THEN Documents.Courier = &Employee
	|		ELSE Documents.Picker = &Employee
	|	END
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Status AS Status,
	|	References.Warehouse AS Warehouse,
	|	References.Picker AS Picker,
	|	References.Number AS Number,
	|	References.DeliveryDate AS DeliveryDate,
	|	References.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	References.DeliveryTimeTo AS DeliveryTimeTo,
	|	References.DocumentAmount AS DocumentAmount,
	|	References.AmountToPay AS AmountToPay,
	|	References.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	|	References.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	References.AdditionalDeliveryInformation AS Comment,
	|	References.Currency AS Currency,
	|	References.PaymentMethod AS PaymentMethod,
	|	References.Date AS Date,
	|	References.RowsCount AS RowsCount,
	|	References.NumberOfRowsInOrder AS NumberOfRowsInOrder,
	|	References.NumberOfRowsAssembled AS NumberOfRowsAssembled,
	|	References.Comment AS Comment1
	|FROM
	|	AllReferences AS References
	|WHERE
	|	References.Warehouse IN HIERARCHY (&Warehouse)
	|ORDER BY
	|	DeliveryDate,
	|	DeliveryTimeTo";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("ThisIsDelivery", ThisIsDelivery);
	If ThisIsDelivery Then
		Query.SetParameter("Statuses", WarehousesServer.OrderStatusesDeliveryControl());
	Else
		Query.SetParameter("Statuses", WarehousesServer.OrderStatusesBuildControl());
	EndIf;

	Return Query;
	
EndFunction

&AtServer
Function RequestAssignment()
	
	Query = New Query();
	Query.Text = "SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Picker AS Picker,
	|	Documents.Number AS Number,
	|	Documents.DateOfShipment AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	0 AS AmountToPay,
	|	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	NULL AS Date,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS RowsCount,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS NumberOfRowsInOrder,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsAssembled AS NumberOfRowsAssembled
	|INTO AllReferences
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.SalesOrder AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND CASE
	|		WHEN &ThisIsDelivery
	|			THEN Documents.Courier = VALUE(Catalog.Persons.EmptyRef)
	|		ELSE Documents.Picker = VALUE(Catalog.Persons.EmptyRef)
	|	END
	|	AND Documents.Posted
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status,
	|	Documents.Warehouse,
	|	Documents.Picker,
	|	Documents.Number,
	|	NULL,
	|	Documents.DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo,
	|	Documents.DocumentAmount,
	|	0,
	|	Documents.DeliveryAddress,
	|	Documents.DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation,
	|	Documents.Currency,
	|	Documents.PaymentMethod,
	|	Documents.Date,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS RowsCount,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder,
	|	AssemblyAndDeliveryStatuses.NumberOfRowsAssembled
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.CustomerInvoice AS Documents
	|		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND CASE
	|		WHEN &ThisIsDelivery
	|			THEN Documents.Courier = VALUE(Catalog.Persons.EmptyRef)
	|		ELSE Documents.Picker = VALUE(Catalog.Persons.EmptyRef)
	|	END
	|	AND Documents.Posted
	|;
	|
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Status AS Status,
	|	References.Warehouse AS Warehouse,
	|	References.Picker AS Picker,
	|	References.Number AS Number,
	|	References.DeliveryDate AS DeliveryDate,
	|	References.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	References.DeliveryTimeTo AS DeliveryTimeTo,
	|	References.DocumentAmount AS DocumentAmount,
	|	References.AmountToPay AS AmountToPay,
	|	References.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	|	References.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	References.AdditionalDeliveryInformation AS Comment,
	|	References.Currency AS Currency,
	|	References.PaymentMethod AS PaymentMethod,
	|	References.Date AS Date,
	|	References.RowsCount AS RowsCount,
	|	References.NumberOfRowsInOrder AS NumberOfRowsInOrder,
	|	References.NumberOfRowsAssembled AS NumberOfRowsAssembled
	|FROM
	|	AllReferences AS References
	|WHERE
	|	References.Warehouse IN HIERARCHY (&Warehouse)
	|ORDER BY
	|	DeliveryDate,
	|	DeliveryTimeTo";
	
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("ThisIsDelivery", ThisIsDelivery);
	
	Statuses = New Array;
	
	If ThisIsDelivery Then
		Statuses = WarehousesServer.StatusesOfOrdersToStartDeliveryByCourier();
	Else
		Statuses.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	EndIf;
	
	Query.SetParameter("Statuses", Statuses);
	
	Return Query;
	
EndFunction

&AtServer
Function RemoveEmployeeFromServer(ReferenceOrder)
	
	OrderStatus_ = OrderStatus_(ReferenceOrder);
	If OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.ForAssembly And Not ThisIsDelivery Then
		
		OrderObject__ = ReferenceOrder.GetObject();
		OrderObject__.Picker = Catalogs.Persons.EmptyRef();
		OrderObject__.Write(DocumentWriteMode.Write);
		
		Return True;
		
	ElsIf (OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery
		Or OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.ForAssembly
		Or OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.InProcessing
		Or OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress
		Or OrderStatus_ = Enums.AssemblyAndDeliveryStatuses.Assembled_) 
		And ThisIsDelivery Then
		
		OrderObject__ = ReferenceOrder.GetObject();
		OrderObject__.Courier = Catalogs.Persons.EmptyRef();
		OrderObject__.Write(DocumentWriteMode.Write);
		
		Return True;
		
	Else
		Return False;
	EndIf;
	
EndFunction

&AtServer
Function OrderStatus_(ReferenceOrder)
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	AssemblyAndDeliveryStatuses.Status AS Status
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.ReferenceOrder = &ReferenceOrder";
	
	Query.SetParameter("ReferenceOrder", ReferenceOrder);
	
	QueryResult = Query.Execute();
	
	SelectionDetailRecords = QueryResult.Select();
	
	While SelectionDetailRecords.Next() Do
		Return SelectionDetailRecords.Status;
	EndDo;
	
	Return Enums.AssemblyAndDeliveryStatuses.ForAssembly;
	
EndFunction

&AtServer
Function RequestForAssemblyStatistics()
	
	Query = New Query();
	Query.Text = "SELECT
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.Status = &ForAssembly
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))
	               |
	               |GROUP BY
	               |	AssemblyAndDeliveryStatuses.Status
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS InProcess
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.Status = &AssemblyInProgress
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))
	               |
	               |GROUP BY
	               |	AssemblyAndDeliveryStatuses.Status
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	MAX(ISNULL(AssemblyAndDeliveryStatuses.AssemblyDate, DATETIME(1, 1, 1, 0, 0, 0))) AS Date,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.AssemblyDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("BeginOfPeriod", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("EndOfPeriod", EndOfDay(CurrentSessionDate()));
	
	Query.SetParameter("ForAssembly", Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	Query.SetParameter("AssemblyInProgress", Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	
	Return Query;
	
EndFunction

&AtServer
Function RequestForDeliveryStatistics()
	
	Query = New Query();
	Query.Text = "SELECT
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.Status IN(&Assigned_)
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))
	               |
	               |GROUP BY
	               |	AssemblyAndDeliveryStatuses.Status
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS InProcess
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.Status = &DeliveryInProgress
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))
	               |
	               |GROUP BY
	               |	AssemblyAndDeliveryStatuses.Status
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	MAX(ISNULL(AssemblyAndDeliveryStatuses.DeliveryDate, DATETIME(1, 1, 1, 0, 0, 0))) AS Date,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.DeliveryDate BETWEEN &BeginOfPeriod AND &EndOfPeriod
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("BeginOfPeriod", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("EndOfPeriod", EndOfDay(CurrentSessionDate()));
	
	AssignedStatuses = New Array;
	AssignedStatuses.Add(Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery);
	AssignedStatuses.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	AssignedStatuses.Add(Enums.AssemblyAndDeliveryStatuses.InProcessing);
	AssignedStatuses.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	AssignedStatuses.Add(Enums.AssemblyAndDeliveryStatuses.Assembled_);
	
	Query.SetParameter("Assigned_", AssignedStatuses);
	Query.SetParameter("DeliveryInProgress", Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress);
	
	Return Query;
	
EndFunction

#EndRegion
