
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
	FormParameters.Insert("ThisIsDelivery",  False);
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
		|INTO Collectors
		|FROM
		|	WarehousesAvailableToDispatcher AS WarehousesAvailableToDispatcher
		|		LEFT JOIN InformationRegister.StoreEmployees AS StoreEmployees
		|		ON WarehousesAvailableToDispatcher.Warehouse = StoreEmployees.Warehouse
		|WHERE
		|	StoreEmployees.Picker
		|
		|GROUP BY
		|	StoreEmployees.Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS AssemblyInProgress
		|INTO OrdersAreCollected
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status = &AssemblyInProgress
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assembled,
		|	MAX(AssemblyAndDeliveryStatuses.AssemblyDate) AS LastBuildDate_
		|INTO OrdersCollected_
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.AssemblyDate BETWEEN &BegOfDay AND &EndOfDay
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker AS Picker,
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Assigned_
		|INTO OrdersAssigned
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status = &BuildStatus
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse IN HIERARCHY(&Warehouse)
		|
		|GROUP BY
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Picker
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	ISNULL(Collectors.Employee, VALUE(Catalog.Persons.EmptyRef)) AS Employee,
		|	ISNULL(OrdersAreCollected.AssemblyInProgress, 0) AS AssemblyInProgress,
		|	ISNULL(OrdersCollected_.Assembled, 0) AS Assembled,
		|	CASE
		|		WHEN NOT Collectors.Employee IS NULL
		|			THEN ISNULL(OrdersAssigned.Assigned_, 0)
		|	END AS Assigned_,
		|	ISNULL(OrdersCollected_.LastBuildDate_, DATETIME(1, 1, 1, 0, 0, 0)) AS LatestBuild,
		|	CASE
		|		WHEN Collectors.Employee IS NULL
		|			THEN ISNULL(OrdersAssigned.Assigned_, 0)
		|		ELSE 0
		|	END AS Assign
		|FROM
		|	Collectors AS Collectors
		|		LEFT JOIN OrdersAreCollected AS OrdersAreCollected
		|		ON Collectors.Employee = OrdersAreCollected.Picker
		|		LEFT JOIN OrdersCollected_ AS OrdersCollected_
		|		ON Collectors.Employee = OrdersCollected_.Picker
		|		FULL JOIN OrdersAssigned AS OrdersAssigned
		|		ON Collectors.Employee = OrdersAssigned.Picker
		|TOTALS
		|	SUM(AssemblyInProgress),
		|	SUM(Assembled),
		|	SUM(Assigned_),
		|	SUM(Assign)
		|BY
		|	OVERALL";
	
	Query.SetParameter("Dispatcher", Dispatcher);
	Query.SetParameter("Warehouse", CurrentWarehouse);
	Query.SetParameter("AssemblyInProgress", Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	Query.SetParameter("BuildStatus", Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	Query.SetParameter("BegOfDay", BegOfDay(CurrentSessionDate()));
	Query.SetParameter("EndOfDay", EndOfDay(CurrentSessionDate()));
	
	QueryResult = Query.Execute();
	
	SampleTotal = QueryResult.Select(QueryResultIteration.ByGroups);
	
	SampleTotal.Next();	// Grand total
	Items.TotalValueAssigned.Title = SampleTotal.Assigned_;
	Items.TotalValueIsCollected.Title = SampleTotal.AssemblyInProgress;
	Items.TotalValueCollected.Title = SampleTotal.Assembled;
	Items.AssignATotalValue.Title = SampleTotal.Assign;
	
	SelectionDetailRecords = SampleTotal.Select();
	
	While SelectionDetailRecords.Next() Do
		
		If Not ValueIsFilled(SelectionDetailRecords.Employee) Then
			Continue;
		EndIf;
		
		NewRow = ListOfEmployees.Add();
		NewRow.Employee = SelectionDetailRecords.Employee;
		
		NewRow.SignatureIsBeingCollected = NStr("vi = 'Đi đến';
												|ru = 'Собирается';
												|en = 'Kitting in progress'; fa = 'کیت‌سازی در جریان';
												|it = 'In composizione';
												|pl = 'Trwa kompletowanie';
												|tr = 'Toplanıyor'") + " ";
		NewRow.AssemblyInProgress = SelectionDetailRecords.AssemblyInProgress;
		
		NewRow.CollectedSignature = NStr("vi = 'Gom được';
										|ru = 'Собрано';
										|en = 'Assembled'; fa = 'مونتاژشده';
										|it = 'Composto';
										|pl = 'Skompletowano';
										|tr = 'Toplandı'") + " ";
		NewRow.Assembled = SelectionDetailRecords.Assembled;
		
		NewRow.Assigned_ = SelectionDetailRecords.Assigned_;
		
		NewRow.TheLatestBuildSignature = NStr("vi = 'Lần gom hàng cuối cùng';
												|ru = 'Последняя сборка';
												|en = 'Last kitting'; fa = 'آخرین کیت‌سازی';
												|it = 'Ultimo assemblaggio';
												|pl = 'Ostatnia kompletacja';
												|tr = 'Son montaj'") + " - ";
		If SelectionDetailRecords.LatestBuild = Date(1,1,1) Then
			NewRow.LatestBuild = NStr("vi = 'không';
										|ru = 'нет';
										|en = 'no'; fa = 'no';
										|it = 'non ci sono';
										|pl = 'no';
										|tr = 'hayır'");
		Else
			NewRow.LatestBuild = NStr("vi = 'trong';
										|ru = 'в';
										|en = 'in'; fa = 'در';
										|it = 'il';
										|pl = 'in';
										|tr = 'içinde'") + " " + Format(SelectionDetailRecords.LatestBuild,"DF=HH:mm");
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
		Title = NStr("vi = 'Kiểm soát gom hàng';
					|ru = 'Контроль сборки';
					|en = 'Kitting control'; fa = 'کنترل کیت‌سازی';
					|it = 'Controllo di assemblaggio';
					|pl = 'Kontrola kompletacji';
					|tr = 'Montaj kontrolü'");
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
