
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	CurrentWarehouse = Parameters.CurrentWarehouse;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	UpdateFormData();
	
EndProcedure

&AtServer
Procedure BeforeLoadDataFromSettingsAtServer(Settings)
	
	CurrentTab = Settings.Get("CurrentTab");
	
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	CreateMenu_();
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

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "UpdateListOfOrders" Then
		UpdateFormData();
		CreateMenu_();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersAssignedToMe

&AtClient
Procedure ListOfOrdersAssignedToMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListOfOrdersAssignedToMeDeliveryAddressPresentation Then
		ShowMap(CurrentRow);
	Else
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
		FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
			
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
			FormOpenParameters,
			ThisForm,,,,,
			FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheListOfUnallocatedOrders

&AtClient
Procedure TheListOfUnallocatedOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.TheListOfUnallocatedOrders.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.TheListOfUnallocatedOrdersDeliveryAddressPresentation Then
		ShowMap(CurrentRow);
	Else
		FormOpenParameters = New Structure;
		FormOpenParameters.Insert("ReferenceOrder", CurrentRow.ReferenceOrder);
		FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
			
		OpenForm(
			"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ReferenceCard",
			FormOpenParameters,
			ThisForm,,,,,
			FormWindowOpeningMode.Independent);
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateForm(Command)
	
	UpdateFormData();
	CreateMenu_();
	
EndProcedure

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

&AtClient
Procedure GoToMyAssignedPages(Command)
	
	If CurrentTab = 1 Then
		GoToTab(0);
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToRetainedEarnings(Command)
	
	If CurrentTab = 0 Then
		GoToTab(1);
	EndIf;
	
EndProcedure

&AtClient
Procedure TakeForDelivery(Command)
	
	CurrentRow = Items.TheListOfUnallocatedOrders.CurrentData;
	OrderParameters = New Structure("Warehouse, ReferenceOrder", CurrentRow.Warehouse, CurrentRow.ReferenceOrder);
	AssignRemoveEmployee(OrderParameters, EmployeeType, Employee);
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure RemoveFromMe(Command)
	
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	OrderParameters = New Structure("Warehouse, ReferenceOrder", CurrentRow.Warehouse, CurrentRow.ReferenceOrder);
	AssignRemoveEmployee(OrderParameters, EmployeeType);
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure ToStartShipping(Command)
	
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	ProceedToDostaka(CurrentRow.ReferenceOrder);
	GenerateMenuCommandHeaders();

EndProcedure

&AtServer
Procedure ProceedToDostaka(ReferenceOrder);
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.SetStatusOfOrderBeingDelivered(ReferenceOrder);
	UpdateFormData();
	
EndProcedure

&AtServer
Procedure AssignRemoveEmployee(OrderParameters, EmployeeType, Employee = Undefined);
	
	WarehouseSettings = WarehousesServer.WarehouseSettingsForAssemblyAndDelivery(OrderParameters.Warehouse);
	
	If WarehouseSettings = Undefined Then
		Return;
	EndIf;
	
	If WarehouseSettings.CouriersCanAssignOrdersToThemselves Then
		
		DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.AssignRemoveEmployee(OrderParameters.ReferenceOrder,
										EmployeeType,
										Employee);
		UpdateFormData();
		
	Else
		
		ErrorText = StrTemplate(NStr("vi = 'Đối với kho bãi %1 đơn vị vận chuyển bị cấm giao/nhận đơn hàng.';
									|ru = 'Для склада %1 курьеру запрещено назначать/снимать с себя заказ.';
									|en = 'The courier cannot assign/release themselves from the order for warehouse %1.'; fa = 'The courier cannot assign/release themselves from the order for warehouse %1.';
									|it = 'Per il magazzino %1, al corriere è vietato assegnarsi/ rimuoversi l''ordine.';
									|pl = 'Dla magazynu %1 kurierowi zabronione jest przydzielać zamówienie/rezygnować z zamówienia.';
									|tr = 'Ambar için, %1 kuryenin kendisine sipariş atamasına/kaldırmasına izin verilmez.'"), OrderParameters.Warehouse);
		Common.MessageToUser(ErrorText);
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToTab(TabCode = 0)
	
	CurrentTab = TabCode;
	UpdateFormData();
	CreateMenu_();
	
EndProcedure

&AtServer
Procedure UpdateFormData()
	
	Query = New Query();
	Query.Text = "SELECT ALLOWED
	|	StoreEmployees.Warehouse AS Warehouse
	|INTO AvailableWarehouses
	|FROM
	|	InformationRegister.StoreEmployees AS StoreEmployees
	|WHERE
	|	StoreEmployees.Employee = &Employee
	|	AND StoreEmployees.Courier
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	COUNT(CourierDeliveryZones.DeliveryZone) AS NumberOfDeliveryZones
	|INTO AvailableZones
	|FROM
	|	InformationRegister.CourierDeliveryZones AS CourierDeliveryZones
	|WHERE
	|	CourierDeliveryZones.Courier = &Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status AS Status,
	|	Documents.Warehouse AS Warehouse,
	|	Documents.Courier AS Courier,
	|	Documents.Number AS Number,
	|	Documents.DateOfShipment AS DeliveryDate,
	|	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	|	Documents.DocumentAmount AS DocumentAmount,
	|	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	|	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	|	Documents.Currency AS Currency,
	|	Documents.PaymentMethod AS PaymentMethod,
	|	Documents.Organization AS Organization
	|INTO TemporaryDisposalTable
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.SalesOrder AS Documents
	|		ON CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder) = Documents.Ref
	|		LEFT JOIN InformationRegister.CourierDeliveryZones AS CourierDeliveryZones
	|		ON Documents.DeliveryZone = CourierDeliveryZones.DeliveryZone
	|		AND CourierDeliveryZones.Courier = &Employee,
	|	AvailableZones AS AvailableZones
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND (Documents.Courier = VALUE(Catalog.Persons.EmptyRef)
	|	OR Documents.Courier = &Employee)
	|	AND Documents.Posted
	|	AND CASE
	|		WHEN AvailableZones.NumberOfDeliveryZones > 0
	|			THEN CourierDeliveryZones.DeliveryZone = Documents.DeliveryZone
	|			OR Documents.Courier = &Employee
	|		ELSE TRUE
	|	END
	|
	|UNION ALL
	|
	|SELECT
	|	AssemblyAndDeliveryStatuses.ReferenceOrder,
	|	AssemblyAndDeliveryStatuses.Status,
	|	Documents.Warehouse,
	|	Documents.Courier,
	|	Documents.Number,
	|	Documents.Date,
	|	Documents.DeliveryTimeFrom,
	|	Documents.DeliveryTimeTo,
	|	Documents.DocumentAmount,
	|	Documents.DeliveryAddress,
	|	Documents.DeliveryAddressFieldValues,
	|	Documents.AdditionalDeliveryInformation,
	|	Documents.Currency,
	|	Documents.PaymentMethod,
	|	Documents.Organization
	|FROM
	|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	|		INNER JOIN Document.CustomerInvoice AS Documents
	|		ON CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice) = Documents.Ref
	|		LEFT JOIN InformationRegister.CourierDeliveryZones AS CourierDeliveryZones
	|		ON Documents.DeliveryZone = CourierDeliveryZones.DeliveryZone
	|		AND CourierDeliveryZones.Courier = &Employee,
	|	AvailableZones AS AvailableZones
	|WHERE
	|	AssemblyAndDeliveryStatuses.Status IN (&Statuses)
	|	AND (Documents.Courier = VALUE(Catalog.Persons.EmptyRef)
	|	OR Documents.Courier = &Employee)
	|	AND Documents.Posted
	|	AND CASE
	|		WHEN AvailableZones.NumberOfDeliveryZones > 0
	|			THEN CourierDeliveryZones.DeliveryZone = Documents.DeliveryZone
	|			OR Documents.Courier = &Employee
	|		ELSE TRUE
	|	END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	SUM(CASE
	|		WHEN References.Courier = &Employee
	|			THEN 1
	|		ELSE 0
	|	END) AS QuantityAssignedToMe,
	|	SUM(CASE
	|		WHEN References.Courier = VALUE(Catalog.Persons.EmptyRef)
	|		AND NOT AvailableWarehouses.Warehouse IS NULL
	|			THEN 1
	|		ELSE 0
	|	END) AS NumberOfUnallocated
	|FROM
	|	TemporaryDisposalTable AS References
	|		LEFT JOIN AvailableWarehouses AS AvailableWarehouses
	|		ON References.Warehouse = AvailableWarehouses.Warehouse
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	CashAccounts.Owner AS Organization,
	|	CashAccounts.Ref AS CashAccount
	|INTO CheckoutTemporaryTable
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		INNER JOIN Catalog.CashAccounts AS CashAccounts
	|		ON DisposalTable.Organization = CashAccounts.Owner
	|WHERE
	|	CashAccounts.DeletionMark = FALSE
	|	AND CashAccounts.OperationalCashAccount = TRUE
	|	AND CashAccounts.Individual = &Employee
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	DisposalTable.ReferenceOrder AS ReferenceOrder,
	|	DisposalTable.Status AS Status,
	|	SUM(ISNULL(CustomersARAPAccounting.AmountDueBalance, 0)) AS AmountToPay
	|INTO TemporaryTableForPaymentIntermediate
	|FROM
	|	TemporaryDisposalTable AS DisposalTable
	|		LEFT JOIN AccumulationRegister.CustomersARAPAccounting.Balance(,) AS CustomersARAPAccounting
	|		ON DisposalTable.ReferenceOrder = CustomersARAPAccounting.ARAPObject.Object
	|GROUP BY
	|	DisposalTable.ReferenceOrder,
	|	DisposalTable.Status
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	TemporaryTableForPayment.ReferenceOrder AS ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay AS AmountToPay,
	|	SUM(CASE
	|		WHEN CashAccountBalance.CashAccount = CashAccountsTable.CashAccount
	|			THEN CASE
	|				WHEN CashAccountBalance.RecordType = VALUE(AccumulationRecordType.Receipt)
	|					THEN CashAccountBalance.Sum
	|				ELSE -CashAccountBalance.Sum
	|			END
	|		ELSE 0
	|	END) AS AmountToBePaidCourier
	|INTO TemporaryTableForPayment
	|FROM
	|	TemporaryTableForPaymentIntermediate AS TemporaryTableForPayment
	|		LEFT JOIN AccumulationRegister.CashAccountBalance AS CashAccountBalance
	|		ON TemporaryTableForPayment.ReferenceOrder = CashAccountBalance.ARAPObject.Object
	|		LEFT JOIN CheckoutTemporaryTable AS CashAccountsTable
	|		ON CashAccountBalance.Organization = CashAccountsTable.Organization
	|GROUP BY
	|	TemporaryTableForPayment.ReferenceOrder,
	|	TemporaryTableForPayment.AmountToPay
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN References.Courier = &Employee
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AssignedToMe_,
	|	CASE
	|		WHEN References.Courier = VALUE(Catalog.Persons.EmptyRef)
	|		AND NOT AvailableWarehouses.Warehouse IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Unallocated,
	|	References.ReferenceOrder AS ReferenceOrder,
	|	References.Status AS Status,
	|	References.Warehouse AS Warehouse,
	|	References.Courier AS Courier,
	|	References.Number AS Number,
	|	References.DeliveryDate AS DeliveryDate,
	|	References.DeliveryTimeFrom AS DeliveryTimeFrom,
	|	References.DeliveryTimeTo AS DeliveryTimeTo,
	|	References.DocumentAmount AS DocumentAmount,
	|	References.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	|	References.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	|	References.AdditionalDeliveryInformation AS Comment,
	|	References.Currency AS Currency,
	|	References.PaymentMethod AS PaymentMethod,
	|	TableForPayment.AmountToPay + TableForPayment.AmountToBePaidCourier AS AmountToPay
	|FROM
	|	TemporaryDisposalTable AS References
	|		LEFT JOIN AvailableWarehouses AS AvailableWarehouses
	|		ON References.Warehouse = AvailableWarehouses.Warehouse
	|		LEFT JOIN TemporaryTableForPayment AS TableForPayment
	|		ON References.ReferenceOrder = TableForPayment.ReferenceOrder
	|WHERE
	|	(References.Courier = &Employee
	|	OR NOT AvailableWarehouses.Warehouse IS NULL)
	|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|	OR References.Warehouse IN HIERARCHY (&Warehouse))
	|ORDER BY
	|	DeliveryDate,
	|	DeliveryTimeTo";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Statuses", WarehousesServer.StatusesOfOrdersToStartDeliveryByCourier());
	
	Results = Query.ExecuteBatch();
	
	ResultIsSummarized = Results[3].Unload();
	SamplingByOrders = Results[7].Select();
	
	NumberOfOrdersAssignedToMe = ResultIsSummarized[0].QuantityAssignedToMe;
	TheNumberOfOrdersRetained = ResultIsSummarized[0].NumberOfUnallocated;
	
	ListOfOrdersAssignedToMe.Clear();
	TheListOfUnallocatedOrders.Clear();
	
	While SamplingByOrders.Next() Do
		
		If SamplingByOrders.AssignedToMe_ Then
			NewRow = ListOfOrdersAssignedToMe.Add();
		ElsIf SamplingByOrders.Unallocated Then
			NewRow = TheListOfUnallocatedOrders.Add();
		Else
			Continue;
		EndIf;
		
		FillPropertyValues(NewRow, SamplingByOrders);
		
		If ValueIsFilled(NewRow.Comment) Then
			NewRow.CommentPicture_2 = 1;
		EndIf;
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.ThereIsStillTimeForDelivery = Module.ThereIsStillTimeForDelivery(NewRow);
		NewRow.SumPresentation = Module.AmountToPayPresentation(NewRow);
		NewRow.PaymentMethodPresentation = Module.PaymentMethodPresentation(NewRow);
		
	EndDo;
	
	If CurrentTab = 0 Then
		NumberOfOrdersPerWarehouse = ListOfOrdersAssignedToMe.Count();
	Else
		NumberOfOrdersPerWarehouse = TheListOfUnallocatedOrders.Count();
	EndIf;
	
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
		Items.TeamSelectionsToOpen.TextColor = WebColors.Gray;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure CreateMenu_()
	
	If CurrentTab = 0 Then
		NameOfFrameElement    = "FrameAssignedToMe";
		NameOfCommandElement  = "TheTeamAssignedToMe";
		PageElementName = "AssignedToMePage";
	Else
		NameOfFrameElement    = "FrameUnallocated";
		NameOfCommandElement  = "TheUnallocatedCommand";
		PageElementName = "UnallocatedPage";
	EndIf;
	
	Items.FrameAssignedToMe.Picture = PictureLib.BorderMenuWhite;
	Items.TheTeamAssignedToMe.TextColor = WebColors.Gray;
	
	Items.FrameUnallocated.Picture = PictureLib.BorderMenuWhite;
	Items.TheUnallocatedCommand.TextColor = WebColors.Gray;
	
	Items[NameOfFrameElement].Picture = PictureLib.BorderMenuBlack;
	Items[NameOfCommandElement].TextColor = WebColors.Black;
	Items.GroupPages.CurrentPage = Items[PageElementName];
	
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtClient
Procedure GenerateMenuCommandHeaders()
	Items.TheTeamAssignedToMe.Title = StrTemplate(NStr("vi = 'Của tôi (%1)';
														|ru = 'Мои (%1)';
														|en = 'My (%1)'; fa = 'My (%1)';
														|it = 'Mio (%1)';
														|pl = 'Moje (%1)';
														|tr = 'Benim (%1)'"), NumberOfOrdersAssignedToMe);
	Items.TheUnallocatedCommand.Title = StrTemplate(NStr("vi = 'Tự do (%1)';
														|ru = 'Свободные (%1)';
														|en = 'Free (%1)'; fa = 'Free (%1)';
														|it = 'Liberi (%1)';
														|pl = 'Wolne (%1)';
														|tr = 'Boş (%1)'"), TheNumberOfOrdersRetained);
EndProcedure

&AtServer
Function AvailableWarehouses()
	
	Return WarehousesServer.AvailableEmployeeWarehousesByEmployeeType(Employee, EmployeeType);
	
EndFunction

&AtClient
Procedure ShowMap(Data)
 
#If MobileClient Then
	ListOfLocations = New ValueList;
	ListOfLocations.Add(GetClientCoordinates(Data)); 
	ShowOnMap(ListOfLocations);
#EndIf
	 
 EndProcedure

&AtClient
Function GetClientCoordinates(Data)
	
	Coordinates = New Structure();
	
#If MobileClient Then
		
	Coordinates = Undefined;
	AddressDataStructure = New Structure();
	AddressDataStructure.Insert("Presentation", Data.DeliveryAddressPresentation);
	
	AddressData = New AddressData(AddressDataStructure);
	Coordinates = GetLocationByAddress(AddressData);
 #EndIf
	 
	Return Coordinates;
	
EndFunction

&AtServer
Procedure SetConditionalAppearance()

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
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheListOfUnallocatedOrdersStatus.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheListOfUnallocatedOrders.Status");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.ReadyStatusTextColorAssemblyAndDelivery);
	
	ConditionalAppearanceItem = ConditionalAppearance.Items.Add();
	ItemField = ConditionalAppearanceItem.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.TheListOfUnallocatedOrdersThereIsStillTimeForDelivery.Name);
	ItemFilter = ConditionalAppearanceItem.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("TheListOfUnallocatedOrders.LateArrival");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = True;
	ConditionalAppearanceItem.Appearance.SetParameterValue("TextColor", StyleColors.NegativeValuesTextColor);
	
EndProcedure

#EndRegion
