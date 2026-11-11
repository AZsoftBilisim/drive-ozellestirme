
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Dispatcher     = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeDispatcher();
	ThisIsControl   = Parameters.ThisIsControl;
	ShowProductPhotos = Parameters.ShowProductPhotos;
	CurrentWarehouse = Parameters.CurrentWarehouse;
	
	SetConditionalAppearance();
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PhotographPresentationOfSelections();
	
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.ChoiceForm") Then
		
		CurrentWarehouse = ValueSelected;
		PhotographPresentationOfSelections();
		UpdateFormData();
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfEmployees

&AtClient
Procedure ListEmployeesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisForm);
	FormParameters = New Structure();
	FormParameters.Insert("Employee",    Item.CurrentData.Employee);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	FormParameters.Insert("ThisIsControl",  ThisIsControl);
	FormParameters.Insert("ThisIsDelivery",  True);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.DispatcherAssigningReferences",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure ClearSelections(Command)
	
	CurrentWarehouse = Undefined;
	PhotographPresentationOfSelections();
	UpdateFormData();

EndProcedure

&AtClient
Procedure SelectionsOpen(Command)
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("ChoiceMode", True);
	FormOpenParameters.Insert("MultipleChoice", False);
	FormOpenParameters.Insert("CloseOnChoice", True);
	FormOpenParameters.Insert("Filter", New Structure("Ref", AvailableWarehouses()));
	
	OpenForm(
		"Catalog.Warehouses.Form.ChoiceForm",
		FormOpenParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.LockOwnerWindow);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormDataServer();
	
EndProcedure

&AtServer
Procedure UpdateFormDataServer()
	
	ListOfEmployees.Clear();
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Warehouse AS Warehouse
		|INTO WarehousesAvailableToDispatcher
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|WHERE
		|	StoreEmployees.Dispatcher
		|	AND StoreEmployees.Warehouse IN HIERARCHY(&Warehouse)
		|	AND StoreEmployees.Employee = &Dispatcher
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	StoreEmployees.Employee AS Employee
		|INTO Couriers
		|FROM
		|	WarehousesAvailableToDispatcher AS WarehousesAvailableToDispatcher
		|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
		|		ON WarehousesAvailableToDispatcher.Warehouse = StoreEmployees.Warehouse
		|WHERE
		|	StoreEmployees.Courier
		|
		|GROUP BY
		|	StoreEmployees.Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS DeliveryInProgress
		|INTO OrdersAreDelivered
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status = &DeliveryInProgress
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Delivered,
		|	MAX(AssemblyAndDeliveryStatuses.DeliveryDate) AS LastDeliveryDate
		|INTO ReferencesDelivered
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.DeliveryDate BETWEEN &BegOfDay AND &EndOfDay
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier AS Courier,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_
		|INTO OrdersAssigned
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&DeliveryStatuses_)
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Couriers.Employee, VALUE(Catalog.Persons.EmptyRef)) AS Employee,
		|	ISNULL(OrdersAreDelivered.DeliveryInProgress, 0) AS DeliveryInProgress,
		|	ISNULL(ReferencesDelivered.Delivered, 0) AS Delivered,
		|	CASE
		|		WHEN NOT Couriers.Employee IS NULL
		|			THEN ISNULL(OrdersAssigned.Assigned_, 0)
		|	END AS Assigned_,
		|	ISNULL(ReferencesDelivered.LastDeliveryDate, DATETIME(1, 1, 1, 0, 0, 0)) AS TheLastShipment_3,
		|	CASE
		|		WHEN Couriers.Employee IS NULL
		|			THEN ISNULL(OrdersAssigned.Assigned_, 0)
		|		ELSE 0
		|	END AS Assign
		|FROM
		|	Couriers AS Couriers
		|		LEFT JOIN OrdersAreDelivered AS OrdersAreDelivered
		|		ON Couriers.Employee = OrdersAreDelivered.Courier
		|		LEFT JOIN ReferencesDelivered AS ReferencesDelivered
		|		ON Couriers.Employee = ReferencesDelivered.Courier
		|		FULL JOIN OrdersAssigned AS OrdersAssigned
		|		ON Couriers.Employee = OrdersAssigned.Courier
		|TOTALS
		|	SUM(DeliveryInProgress),
		|	SUM(Delivered),
		|	SUM(Assigned_),
		|	SUM(Assign)
		|BY
		|	OVERALL";
	
	Query.SetParameter("Dispatcher", Dispatcher);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("DeliveryInProgress", Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress);
	Query.SetParameter("DeliveryStatuses_", WarehousesServer.StatusesOfOrdersToStartDeliveryByCourier());
	Query.SetParameter("BegOfDay", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("EndOfDay", EndOfDay(CurrentSessionDate()));
	
	QueryResult = Query.Execute();
	
	SampleTotal = QueryResult.Select(QueryResultIteration.ByGroups);
	
	SampleTotal.Next();	// Grand total
	Items.TotalValueAssigned.Title = SampleTotal.Assigned_;
	Items.TheTotalValueIsDelivered.Title = SampleTotal.DeliveryInProgress;
	Items.TotalValueDelivered.Title = SampleTotal.Delivered;
	Items.AssignATotalValue.Title = SampleTotal.Assign;
	
	SelectionDetailRecords = SampleTotal.Select();
	
	While SelectionDetailRecords.Next() Do
		
		If Not ValueIsFilled(SelectionDetailRecords.Employee) Then
			Continue;
		EndIf;
		
		NewRow = ListOfEmployees.Add();
		NewRow.Employee = SelectionDetailRecords.Employee;
		
		NewRow.SignatureIsBeingDelivered = NStr("vi = 'Đang chuyển';
												|ru = 'Доставляется';
												|en = 'Delivery in progress'; fa = 'تحویل در جریان';
												|it = 'Consegnato';
												|pl = 'Delivery in progress';
												|tr = 'Teslim ediliyor'") + " ";
		NewRow.DeliveryInProgress = SelectionDetailRecords.DeliveryInProgress;
		
		NewRow.DeliveredSignature = NStr("vi = 'Đã chuyển';
										|ru = 'Доставлено';
										|en = 'Delivered'; fa = 'تحویل‌شده';
										|it = 'Consegnato';
										|pl = 'Delivered';
										|tr = 'Teslim edildi'") + " ";
		NewRow.Delivered = SelectionDetailRecords.Delivered;
		
		NewRow.Assigned_ = SelectionDetailRecords.Assigned_;
		
		NewRow.LastDeliverySignature = NStr("vi = 'Lần giao hàng sau cùng';
											|ru = 'Последняя доставка';
											|en = 'Last delivery'; fa = 'آخرین تحویل';
											|it = 'Последняя доставка';
											|pl = 'Ostatnia dostawa';
											|tr = 'Son teslimat'") + " - ";
		If SelectionDetailRecords.TheLastShipment_3 = Date(1,1,1) Then
			NewRow.TheLastShipment_3 = NStr("vi = 'không';
											|ru = 'нет';
											|en = 'no'; fa = 'no';
											|it = 'non ci sono';
											|pl = 'no';
											|tr = 'hayır'");
		Else
			NewRow.TheLastShipment_3 = NStr("vi = 'trong';
											|ru = 'в';
											|en = 'in'; fa = 'در';
											|it = 'il';
											|pl = 'in';
											|tr = 'içinde'") + " " + Format(SelectionDetailRecords.TheLastShipment_3,"DF=HH:mm");
		EndIf;
	EndDo;
	
EndProcedure

&AtServer
Procedure PhotographPresentationOfSelections()
	
	PresentationsOfSelections = "";
	If ValueIsFilled(CurrentWarehouse) Then
		PresentationsOfSelections = CurrentWarehouse;
		Items.TeamSelectionsToOpen.TextColor = WebColors.Black;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = True;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuBlack;
	Else
		PresentationsOfSelections = NStr("vi = 'Chọn cửa hàng/kho bãi';
										|ru = 'Выбрать магазин/склад';
										|en = 'Select store/warehouse'; fa = 'Select store/warehouse';
										|it = 'Selezionare punto vendita/ magazzino';
										|pl = 'Wybierz sklep/magazyn';
										|tr = 'Mağaza/ambar seç'");
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtServer
Function AvailableWarehouses()
	
	Return WarehousesServer.AvailableEmployeeWarehousesByEmployeeType(Dispatcher, EmployeeType);
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()
	
	If ThisIsControl Then
		Title = NStr("vi = 'Kiểm soát giao hàng';
					|ru = 'Контроль доставки';
					|en = 'Delivery control'; fa = 'کنترل تحویل';
					|it = 'Controllo di consegna';
					|pl = 'Kontrola dostawy';
					|tr = 'Teslimat kontrolü'");
	EndIf;
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ListOfEmployeesAssigned.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("ListOfEmployees.Assigned_");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = "0";
	If ThisIsControl Then
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.TextColorIssue);
	Else
		ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.ReadyStatusTextColorAssemblyAndDelivery);
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export 
	UpdateFormData();
	PhotographPresentationOfSelections();
EndProcedure

#EndRegion
