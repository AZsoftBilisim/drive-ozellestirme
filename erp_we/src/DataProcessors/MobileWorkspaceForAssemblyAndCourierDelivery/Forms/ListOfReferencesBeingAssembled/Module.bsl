
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	CurrentWarehouse = Parameters.CurrentWarehouse;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeMailFetcher();
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

#Region FormTableItemsEventHandlersListOfOrdersAssignedToMe

&AtClient
Procedure ListOfOrdersAssignedToMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("OrderDocument", Item.CurrentData.ReferenceOrder);
	FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	LongDesc = New CallbackDescription("UpdateFormData", ThisForm);
	
	OpenForm(
	"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.PickerWorkspace",
	FormOpenParameters,
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

&AtClient
Procedure TakeToWork(Command)
	
	CurrentRow = Items.TheListOfUnallocatedOrders.CurrentData;
	AssignRemoveEmployee(CurrentRow.ReferenceOrder, EmployeeType, Employee);
	
EndProcedure

&AtServer
Procedure AssignRemoveEmployee(ReferenceOrder, EmployeeType, Employee = Undefined);
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.AssignRemoveEmployee(ReferenceOrder,
									EmployeeType,
									Employee);
	UpdateFormDataServer();
	
EndProcedure

&AtClient
Procedure RemoveFromMe(Command)
	
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	AssignRemoveEmployee(CurrentRow.ReferenceOrder, EmployeeType);
	
EndProcedure

&AtClient
Procedure UpdateForm(Command)
	UpdateFormData();
	PhotographPresentationOfSelections();
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure UpdateFormData(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateFormDataServer();
	
EndProcedure

&AtServer
Procedure UpdateFormDataServer()
	
	FillInListOfOrders_();
	FillInBuildStatistics();
	
EndProcedure

&AtServer
Procedure FillInBuildStatistics()
	
	Query = New Query();
	Query.Text = "SELECT
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
	               |	AND AssemblyAndDeliveryStatuses.Status IN(&StatusesForAssemblyAreGoingTo)
	               |	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	               |			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY (&Warehouse))
	               |
	               |GROUP BY
	               |	AssemblyAndDeliveryStatuses.Status
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	MAX(ISNULL(AssemblyAndDeliveryStatuses.AssemblyDate, DATETIME(1, 1, 1, 0, 0, 0))) AS AssemblyDate,
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
	
	StatusesForAssemblyAreGoingTo = New Array;
	StatusesForAssemblyAreGoingTo.Add(WarehousesServer.StatusOfOrderToBuild());
	StatusesForAssemblyAreGoingTo.Add(WarehousesServer.OrderStatusIsBeingCollected());
	
	
	Query.SetParameter("StatusesForAssemblyAreGoingTo", StatusesForAssemblyAreGoingTo);
	
	Results = Query.ExecuteBatch();
	
	SamplingInProgress_ = Results[0].Select();
	SampleCollected = Results[1].Unload();
	
	ForAssembly = 0;
	AssemblyInProgress = 0;
	Assembled = 0;
	LastBuildDate = Date('0001,01,01');
	
	While SamplingInProgress_.Next() Do
		
		If SamplingInProgress_.Status = Enums.AssemblyAndDeliveryStatuses.ForAssembly Then
			ForAssembly = SamplingInProgress_.Count;
		Else
			AssemblyInProgress = SamplingInProgress_.Count;
		EndIf;
		
	EndDo;
	
	For Each LineSelectionCollected In SampleCollected Do
		
		LastBuildDate = LineSelectionCollected.AssemblyDate;
		Assembled = LineSelectionCollected.Count;
		
	EndDo;
	
	Items.DesignatedNumberOf.Title = ForAssembly;
	Items.QuantityCollected_3.Title = AssemblyInProgress;
	Items.QuantityCollected.Title = Assembled;
	If LastBuildDate = Date('0001,01,01') Then
		Items.LastTime.Title = " none";
	Else
		Items.LastTime.Title = " In " + Format(LastBuildDate,"DF=HH:mm");
	EndIf;
EndProcedure

&AtServer
Procedure FillInListOfOrders_()
	
	Query = New Query();
	Query.Text = "SELECT ALLOWED
	|	StoreEmployees.Warehouse AS Warehouse
	|INTO AvailableWarehouses
	|FROM
	|	InformationRegister.StoreEmployees AS StoreEmployees
	|WHERE
	|	StoreEmployees.Employee = &Employee
	|	AND StoreEmployees.Picker
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
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
	|	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	|	AND Documents.Picker = &Employee
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
	|	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	|	AND Documents.Picker = &Employee
	|	AND Documents.Posted
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CASE
	|		WHEN References.Picker = &Employee
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS AssignedToMe_,
	|	CASE
	|		WHEN References.Picker = VALUE(Catalog.Persons.EmptyRef)
	|				AND NOT AvailableWarehouses.Warehouse IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END AS Unallocated,
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
	|		LEFT JOIN AvailableWarehouses AS AvailableWarehouses
	|		ON References.Warehouse = AvailableWarehouses.Warehouse
	|WHERE
	|	(References.Picker = &Employee
	|			OR NOT AvailableWarehouses.Warehouse IS NULL)
	|	AND (&Warehouse = VALUE(Catalog.Warehouses.EmptyRef)
	|			OR References.Warehouse IN HIERARCHY (&Warehouse))
	|
	|ORDER BY
	|	DeliveryDate,
	|	DeliveryTimeTo";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Statuses", WarehousesServer.OrderStatusIsBeingCollected());
	
	Results = Query.ExecuteBatch();
	
	SamplingByOrders = Results[2].Select();
	
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
	
	Return WarehousesServer.AvailableEmployeeWarehousesByEmployeeType(Employee, EmployeeType);
	
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
	
EndProcedure

#EndRegion
