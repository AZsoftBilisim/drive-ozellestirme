
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	CurrentWarehouse = Parameters.CurrentWarehouse;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeMailFetcher();
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

#EndRegion

#Region FormTableItemsEventHandlersListOfOrdersAssignedToMe

&AtClient
Procedure ListOfOrdersAssignedToMeSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("OrderDocument", Item.CurrentData.ReferenceOrder);
	FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	LongDesc = New CallbackDescription("UpdateForm", ThisForm);
	
	OpenForm(
	"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.PickerWorkspace",
	FormOpenParameters,
	ThisForm,,,,LongDesc,
	FormWindowOpeningMode.Independent);
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersTheListOfUnallocatedOrders

&AtClient
Procedure TheListOfUnallocatedOrdersSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	
	FormOpenParameters = New Structure;
	FormOpenParameters.Insert("OrderDocument", Item.CurrentData.ReferenceOrder);
	FormOpenParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	
	LongDesc = New CallbackDescription("UpdateForm", ThisForm);
	
	OpenForm(
	"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.PickerWorkspace",
	FormOpenParameters,
	ThisForm,,,, LongDesc,
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
Procedure TakeToWork(Command)
	
	CurrentRow = Items.TheListOfUnallocatedOrders.CurrentData;
	AssignRemoveEmployee(CurrentRow.ReferenceOrder, EmployeeType, Employee);
	GenerateMenuCommandHeaders();
	
EndProcedure

&AtServer
Procedure AssignRemoveEmployee(ReferenceOrder, EmployeeType, Employee = Undefined);
	
	DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.AssignRemoveEmployee(ReferenceOrder,
									EmployeeType,
									Employee);
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure RemoveFromMe(Command)
	
	CurrentRow = Items.ListOfOrdersAssignedToMe.CurrentData;
	AssignRemoveEmployee(CurrentRow.ReferenceOrder, EmployeeType);
	GenerateMenuCommandHeaders();
	
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
	               |	Documents.DateOfShipment DeliveryDate,
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
	               |	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder AS RowsCount
	               |INTO AllReferences
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.SalesOrder AS Documents
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	               |	AND (Documents.Picker = VALUE(Catalog.Persons.EmptyRef)
	               |			OR Documents.Picker = &Employee)
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
	               |	AssemblyAndDeliveryStatuses.NumberOfRowsInOrder
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.CustomerInvoice AS Documents
	               |			LEFT JOIN (SELECT
	               |				SalesOfGoodsServicesGoods.Ref AS Ref,
	               |				COUNT(DISTINCT SalesOfGoodsServicesGoods.LineNumber) AS RowsCount
	               |			FROM
	               |				Document.CustomerInvoice.Goods AS SalesOfGoodsServicesGoods
	               |			
	               |			GROUP BY
	               |				SalesOfGoodsServicesGoods.Ref) AS LinesInInvoice
	               |			ON Documents.Ref = LinesInInvoice.Ref
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	               |	AND (Documents.Picker = VALUE(Catalog.Persons.EmptyRef)
	               |			OR Documents.Picker = &Employee)
	               |	AND Documents.Posted
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	SUM(CASE
	               |			WHEN References.Picker = &Employee
	               |				THEN 1
	               |			ELSE 0
	               |		END) AS QuantityAssignedToMe,
	               |	SUM(CASE
	               |			WHEN References.Picker = VALUE(Catalog.Persons.EmptyRef)
	               |					AND NOT AvailableWarehouses.Warehouse IS NULL
	               |				THEN 1
	               |			ELSE 0
	               |		END) AS NumberOfUnallocated
	               |FROM
	               |	AllReferences AS References
	               |		LEFT JOIN AvailableWarehouses AS AvailableWarehouses
	               |		ON References.Warehouse = AvailableWarehouses.Warehouse
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
	               |	References.RowsCount AS RowsCount
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
	Query.SetParameter("Statuses", WarehousesServer.StatusOfOrderToBuild());
	
	Results = Query.ExecuteBatch();
	
	ResultIsSummarized = Results[2].Unload();
	SamplingByOrders = Results[3].Select();
	
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
			NewRow.CommentPicture_2 = PictureLib.CommentRedDelivery;
		EndIf;
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.ThereIsStillTimeForDelivery = Module.ThereIsStillTimeForDelivery(NewRow);
		NewRow.SumPresentation = Module.SumPresentation(NewRow);
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
		Items.TeamSelectionsToOpen.TextColor = WebColors.DarkGray;
		Items.GroupTeamQualifiersTheNumberOfClear.Visible = False;
		Items.FrameSelectionsOpen.Picture = PictureLib.BorderMenuGray;
	EndIf;
	
	Items.TeamSelectionsToOpen.Title = PresentationsOfSelections;
	
EndProcedure

&AtClient
Procedure CreateMenu_()
	
	If CurrentTab = 0 Then
		TabName = "AssignedToMe";
	Else
		TabName = "Unallocated_";
	EndIf;
	
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
	Items.TheTeamAssignedToMe.TextColor = WebColors.DarkGray;
	
	Items.FrameUnallocated.Picture = PictureLib.BorderMenuWhite;
	Items.TheUnallocatedCommand.TextColor = WebColors.DarkGray;
	
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

&AtClient
Procedure UpdateForm(Result = Undefined, AdditionalParameters = Undefined) Export 
	UpdateFormData();
	CreateMenu_();
	PhotographPresentationOfSelections();
EndProcedure

#EndRegion
