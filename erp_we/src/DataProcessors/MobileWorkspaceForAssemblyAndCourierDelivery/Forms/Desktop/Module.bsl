#Region Variables

&AtClient
Var ClosurePermitted;

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Not Common.IsMobileClient() Then
		Cancel = True;
		Return;
	EndIf;
	
	SetPartitionVisibility();
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	Items.CurrentUser.Title = Employee;
	
EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Exit Then
		WarningText = NStr("vi = 'Đóng ứng dụng?';
							|ru = 'Закрыть приложение?';
							|en = 'Close application?'; fa = 'Close application?';
							|it = 'Chiudere applicazione?';
							|pl = 'Zamknąć aplikację?';
							|tr = 'Uygulamayı kapat?'");
		Cancel = True;
	ElsIf ClosurePermitted=Undefined Then
		Mode = QuestionDialogMode.YesNo;
		Notification = New CallbackDescription("AfterClosingQuestion_", ThisObject, Parameters);
		ShowQueryBox(Notification, NStr("vi = 'Đóng ứng dụng?';
										|ru = 'Закрыть приложение?';
										|en = 'Close application?'; fa = 'Close application?';
										|it = 'Chiudere applicazione?';
										|pl = 'Zamknąć aplikację?';
										|tr = 'Uygulamayı kapat?'"), Mode, 0);
		
		Cancel = True;
	EndIf;
EndProcedure

&AtClient
Procedure ChoiceProcessing(ValueSelected, ChoiceSource)
	If Upper(ChoiceSource.FormName) = Upper("Catalog.Warehouses.Form.ChoiceForm") Then
		
		CurrentWarehouse = ValueSelected;
		PhotographPresentationOfSelections();
		UpdateWarehouseContactInformation();
		
	EndIf;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PhotographPresentationOfSelections();
	UpdateWarehouseContactInformation();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

#Region FormTableItemsEventHandlersListOfOrders_

&AtClient
Procedure ListOfOrders_Selection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	CurrentRow = Items.ListOfOrders_.CurrentData;
	
	If CurrentRow = Undefined Then
		Return;
	EndIf;
	
	If Field = Items.ListOfOrders_DeliveryAddressPresentation Then
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
Procedure ProductionStageDispatching(Command)
	GoToSection("ProductionStageDispatching");
	UpdateNumberOfOrdersSupervisor();
EndProcedure

&AtClient
Procedure Assembly(Command)
	GoToSection("Assembly");
	UpdateNumberOfOrdersAssembly();
EndProcedure

&AtClient
Procedure Delivery(Command)
	GoToSection("Delivery");
	UpdateNumberOfOrdersDelivery();
EndProcedure

&AtClient
Procedure Archive(Command)
	
	UpdateArchiveData();
	GoToSection("Archive");
	
EndProcedure

&AtClient
Procedure Settings(Command)
	GoToSection("Settings");
EndProcedure

&AtClient
Procedure GoOut(Command)
	Exit(True);
EndProcedure

&AtClient
Procedure ToAppointTheCollector(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.ToAppointTheCollector");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersSupervisor", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ThisIsControl", False);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.DispatcherAssignPicker",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure BuildControl(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.BuildControl");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersSupervisor", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ThisIsControl", True);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.DispatcherAssignPicker",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtClient
Procedure AssignACourier(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.AssignACourier");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersSupervisor", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ThisIsControl", False);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.DispatcherAssignCourier",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure DeliveryControl(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.DeliveryControl");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersSupervisor", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ThisIsControl", True);
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.DispatcherAssignCourier",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure UpdateForm(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.UpdateForm");
	
	If Items.Sections.CurrentPage = Items.ArchiveSection Then
		UpdateArchiveData();
	Else
		UpdateNumberOfOrdersSupervisor(); 
		UpdateNumberOfOrdersAssembly();
		UpdateNumberOfOrdersDelivery();
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSelections(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesArchive",
		FormParameters,
		ThisForm,,,,,
		FormWindowOpeningMode.Independent);
		
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
Procedure ClearSelections(Command)
	
	CurrentWarehouse = Undefined;
	PhotographPresentationOfSelections();
	UpdateWarehouseContactInformation();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure GoToSection(SectionName)
	
	If SectionName = "ProductionStageDispatching" Then
		IconName       = "TabDispatchingActiveAssemblyAndDelivery";
		NameOfSectionElement = "DispatchingSection";
		GroupName         = "DispatchingGroup";
	ElsIf SectionName = "Assembly" Then
		IconName       = "TabAssemblyActiveAssemblyAndDelivery";
		NameOfSectionElement = "BuildSection";
		GroupName         = "AssemblyGroup";
	ElsIf SectionName = "Delivery" Then
		IconName       = "TabDeliveryActiveAssemblyAndDelivery";
		NameOfSectionElement = "TheShippingSection";
		GroupName         = "DeliveryGroup";
	ElsIf SectionName = "Archive" Then
		IconName       = "TabArchiveActiveAssemblyAndDelivery";
		NameOfSectionElement = "ArchiveSection";
		GroupName         = "ArchiveGroup";
	ElsIf SectionName = "Settings" Then
		IconName       = "TabSettingsActiveAssemblyAndDelivery";
		NameOfSectionElement = "ConfigurationSection";
		GroupName         = "SettingsGroup1";	
	EndIf;
	
	// Changing the menu icon
	Items.ProductionStageDispatching.Picture = PictureLib.TabDispatchingAssemblyAndDelivery;
	Items.Assembly.Picture          = PictureLib.TabAssemblyAssemblyAndDelivery;
	Items.Delivery.Picture        = PictureLib.TabDeliveryAssemblyAndDelivery;
	Items.Archive.Picture           = PictureLib.TabArchiveAssemblyAndDelivery;
	Items.Settings.Picture       = PictureLib.TabSettingsAssemblyAndDelivery;
	
	Items[SectionName].Picture     = PictureLib[IconName];
	
	// Setting the visibility of the partition
	Items.DispatchingSection.Visible = False;
	Items.BuildSection.Visible          = False;
	Items.TheShippingSection.Visible        = False;
	Items.ArchiveSection.Visible           = False;
	Items.ConfigurationSection.Visible       = False;
	
	Items[NameOfSectionElement].Visible           = True;
	
	// Menu highlighting
	White  = WebColors.White;
	Yellow = WebColors.LightGoldenRod;
	
	Items.ProductionStageDispatching.BackColor = White;
	Items.Assembly.BackColor          = White;
	Items.Delivery.BackColor        = White; 
	Items.Archive.BackColor           = White; 
	Items.Settings.BackColor       = White; 
	
	Items[SectionName].BackColor     = Yellow;
	
	Items.DispatchingGroup.BackColor  = White;
	Items.AssemblyGroup.BackColor           = White;
	Items.DeliveryGroup.BackColor         = White;
	Items.ArchiveGroup.BackColor            = White;
	Items.SettingsGroup1.BackColor        = White;

	Items[GroupName].BackColor = Yellow;
	
EndProcedure

&AtClient
Procedure StartTheBuild(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.StartTheBuild");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersAssembly", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesForAssembly",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
EndProcedure

&AtClient
Procedure AssemblyInProgress(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.AssemblyInProgress");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersAssembly", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
	
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesBeingAssembled",FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
EndProcedure

&AtClient
Procedure ToStartShipping(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.ToStartShipping");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersDelivery", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesForDelivery",
		FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);

EndProcedure

&AtClient
Procedure DeliveryInProgress(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.DeliveryInProgress");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersDelivery", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesBeingDelivered",
		FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
		
EndProcedure

&AtClient
Procedure ReturnToTheStore(Command)
	
	PerformanceMonitorClient.TimeMeasurement(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.Desktop.ReturnToTheStore");
	
	LongDesc = New CallbackDescription("UpdateNumberOfOrdersDelivery", ThisForm);
	
	FormParameters = New Structure;
	FormParameters.Insert("ShowProductPhotos", ShowProductPhotos);
	FormParameters.Insert("CurrentWarehouse", CurrentWarehouse);
		
	OpenForm(
		"DataProcessor.MobileWorkspaceForAssemblyAndCourierDelivery.Form.ListOfReferencesReturn",
		FormParameters,
		ThisForm,,,,LongDesc,
		FormWindowOpeningMode.Independent);
	
EndProcedure

&AtServer
Procedure SetPartitionVisibility()

	EmployeeRoles = InformationRegisters.StoreEmployees.GetAvailableRoles(Users.CurrentUser());
	
	Items.DispatchingGroup.Visible = EmployeeRoles.Dispatcher;
	Items.AssemblyGroup.Visible = EmployeeRoles.Picker;
	Items.DeliveryGroup.Visible = EmployeeRoles.Courier;
	
	Yellow = WebColors.LightGoldenRod;
	
	If EmployeeRoles.Dispatcher Then
		Items.DispatchingSection.Visible = True;
		Items.ProductionStageDispatching.Picture        = PictureLib.TabDispatchingActiveAssemblyAndDelivery;
		Items.DispatchingGroup.BackColor  = Yellow;
		UpdateNumberOfOrdersSupervisorServer();
		Return;
	EndIf;
	
	If EmployeeRoles.Picker Then
		Items.BuildSection.Visible          = True;
		Items.ProductionStageDispatching.Picture        = PictureLib.TabAssemblyActiveAssemblyAndDelivery;
		Items.AssemblyGroup.BackColor           = Yellow;
		UpdateNumberOfOrdersAssemblyServer();
		Return;
	EndIf;
	
	If EmployeeRoles.Courier Then
		Items.TheShippingSection.Visible        = True;
		Items.ProductionStageDispatching.Picture        = PictureLib.TabDeliveryActiveAssemblyAndDelivery;
		Items.DeliveryGroup.BackColor         = Yellow;
		UpdateNumberOfOrdersDeliveryServer();
		Return;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateNumberOfOrdersSupervisor(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateNumberOfOrdersSupervisorServer();	
	
EndProcedure

&AtServer
Procedure UpdateNumberOfOrdersSupervisorServer()
	
	Individual = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Employee AS Employee,
		|	StoreEmployees.Warehouse AS Warehouse,
		|	StoreEmployees.Courier AS Courier,
		|	StoreEmployees.Picker AS Picker,
		|	StoreEmployees.Dispatcher AS Dispatcher,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsOrderAssembly
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsOrderAssembly
		|	END AS AssemblyIsAvailable,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsDeliveryByOwnCouriers
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsDeliveryByOwnCouriers
		|	END AS DeliveryIsAvailable
		|INTO TTWarehouses
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|			LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast AS HistoryOfChangesToStoreFormatsCrossSection
		|			ON Warehouses.Ref = HistoryOfChangesToStoreFormatsCrossSection.Warehouse
		|		ON StoreEmployees.Warehouse = Warehouses.Ref
		|WHERE
		|	StoreEmployees.Employee = &Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status = &ForAssembly
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = VALUE(Catalog.Persons.EmptyRef)
		|	AND TTWarehouses.AssemblyIsAvailable = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&StatusesForAssemblyAreGoingTo)
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Picker <> VALUE(Catalog.Persons.EmptyRef)
		|	AND TTWarehouses.AssemblyIsAvailable = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&AssignCourierStatus)
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = VALUE(Catalog.Persons.EmptyRef)
		|	AND TTWarehouses.DeliveryIsAvailable = TRUE
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&StatusesToControlDelivery)
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Courier <> VALUE(Catalog.Persons.EmptyRef)
		|	AND TTWarehouses.DeliveryIsAvailable = TRUE";
	
	Query.SetParameter("ForAssembly", Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	Query.SetParameter("Employee", Individual);
	
	StatusesForAssemblyAreGoingTo = New Array;
	StatusesForAssemblyAreGoingTo.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	StatusesForAssemblyAreGoingTo.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	
	Query.SetParameter("StatusesForAssemblyAreGoingTo", StatusesForAssemblyAreGoingTo);
	
	AssignCourierStatus = New Array;
	AssignCourierStatus.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	AssignCourierStatus.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	AssignCourierStatus.Add(Enums.AssemblyAndDeliveryStatuses.Assembled_);
	AssignCourierStatus.Add(Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery);
	AssignCourierStatus.Add(Enums.AssemblyAndDeliveryStatuses.InProcessing);
	
	Query.SetParameter("AssignCourierStatus", AssignCourierStatus);
	
	StatusesToControlDelivery = New Array;
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.Assembled_);
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.ReadyForDelivery);
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.InProcessing);
	StatusesToControlDelivery.Add(Enums.AssemblyAndDeliveryStatuses.DeliveryInProgress);
	
	Query.SetParameter("StatusesToControlDelivery", StatusesToControlDelivery);
	
	Results = Query.ExecuteBatch();
	
	MailCollector         = Results[1].Unload();
	OrdersCollectorControl = Results[2].Unload();
	OrdersCourier          = Results[3].Unload();
	OrdersCourierControl  = Results[4].Unload();

	If MailCollector.Count() > 0 Then
		Items.ToAppointTheCollector1.Title = MailCollector[0].Count;
	Else
		Items.ToAppointTheCollector1.Title = 0;
	EndIf;
	
	If OrdersCollectorControl.Count() > 0 Then
		Items.BuildControl1.Title = OrdersCollectorControl[0].Count;
	Else
		Items.BuildControl1.Title = 0;
	EndIf;
	
	If OrdersCourier.Count() > 0 Then
		Items.AssignACourier1.Title = OrdersCourier[0].Count;
	Else
		Items.AssignACourier1.Title = 0;
	EndIf;
	
	If OrdersCourierControl.Count() > 0 Then
		Items.DeliveryControl1.Title = OrdersCourierControl[0].Count;
	Else
		Items.DeliveryControl1.Title = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateNumberOfOrdersAssembly(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateNumberOfOrdersAssemblyServer();
	
EndProcedure

&AtServer
Procedure UpdateNumberOfOrdersAssemblyServer()
	
	Individual = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Employee AS Employee,
		|	StoreEmployees.Warehouse AS Warehouse,
		|	StoreEmployees.Courier AS Courier,
		|	StoreEmployees.Picker AS Picker,
		|	StoreEmployees.Dispatcher AS Dispatcher,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsOrderAssembly
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsOrderAssembly
		|	END AS AssemblyIsAvailable,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsDeliveryByOwnCouriers
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsDeliveryByOwnCouriers
		|	END AS DeliveryIsAvailable
		|INTO TTWarehouses
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|			LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast AS HistoryOfChangesToStoreFormatsCrossSection
		|			ON Warehouses.Ref = HistoryOfChangesToStoreFormatsCrossSection.Warehouse
		|		ON StoreEmployees.Warehouse = Warehouses.Ref
		|WHERE
		|	StoreEmployees.Employee = &Employee
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status = &ForAssembly
		|	AND TTWarehouses.AssemblyIsAvailable = TRUE
		|	AND (AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
		|			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = VALUE(Catalog.Persons.EmptyRef))
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	TTWarehouses.AssemblyIsAvailable = TRUE
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Picker = &Employee
		|	AND AssemblyAndDeliveryStatuses.Status = &AssemblyInProgress";
	
	Query.SetParameter("ForAssembly", Enums.AssemblyAndDeliveryStatuses.ForAssembly);
	Query.SetParameter("Employee", Individual);
	Query.SetParameter("AssemblyInProgress", Enums.AssemblyAndDeliveryStatuses.AssemblyInProgress);
	
	Results = Query.ExecuteBatch();
	
	OrdersToStart     = Results[1].Unload();
	OrdersAreCollected = Results[2].Unload();
	
	If OrdersToStart.Count() > 0 Then
		Items.StartTheBuild1.Title = OrdersToStart[0].Count;
	Else
		Items.StartTheBuild1.Title = 0;
	EndIf;
	
	If OrdersAreCollected.Count() > 0 Then
		Items.AssemblyInProgress1.Title = OrdersAreCollected[0].Count;
	Else
		Items.AssemblyInProgress1.Title = 0;
	EndIf;
	
EndProcedure

&AtClient
Procedure UpdateNumberOfOrdersDelivery(Result = Undefined, AdditionalParameters = Undefined) Export
	
	UpdateNumberOfOrdersDeliveryServer();
	
EndProcedure

&AtServer
Procedure UpdateNumberOfOrdersDeliveryServer()
	
	Individual = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	StoreEmployees.Employee AS Employee,
		|	StoreEmployees.Warehouse AS Warehouse,
		|	StoreEmployees.Courier AS Courier,
		|	StoreEmployees.Picker AS Picker,
		|	StoreEmployees.Dispatcher AS Dispatcher,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsOrderAssembly
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsOrderAssembly
		|	END AS AssemblyIsAvailable,
		|	CASE
		|		WHEN HistoryOfChangesToStoreFormatsCrossSection.StoreFormat IS NULL
		|			THEN Warehouses.StoreSupportsDeliveryByOwnCouriers
		|		ELSE HistoryOfChangesToStoreFormatsCrossSection.StoreFormat.StoreSupportsDeliveryByOwnCouriers
		|	END AS DeliveryIsAvailable
		|INTO TTWarehouses
		|FROM
		|	InformationRegister.StoreEmployees AS StoreEmployees
		|		LEFT JOIN Catalog.Warehouses AS Warehouses
		|			LEFT JOIN InformationRegister.HistoryOfStoreFormatChange.SliceLast AS HistoryOfChangesToStoreFormatsCrossSection
		|			ON Warehouses.Ref = HistoryOfChangesToStoreFormatsCrossSection.Warehouse
		|		ON StoreEmployees.Warehouse = Warehouses.Ref
		|WHERE
		|	StoreEmployees.Employee = &Employee
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
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|		LEFT JOIN InformationRegister.CourierDeliveryZones AS CourierDeliveryZones
		|		ON (AssemblyAndDeliveryStatuses.ReferenceOrder.DeliveryZone = CourierDeliveryZones.DeliveryZone)
		|			AND (CourierDeliveryZones.Courier = &Employee),
		|	AvailableZones AS AvailableZones
		|WHERE
		|	AssemblyAndDeliveryStatuses.Status IN(&StartDeliveryStatuses)
		|	AND TTWarehouses.DeliveryIsAvailable = TRUE
		|	AND CASE
		|			WHEN AvailableZones.NumberOfDeliveryZones > 0
		|				THEN CourierDeliveryZones.DeliveryZone = AssemblyAndDeliveryStatuses.ReferenceOrder.DeliveryZone
		|						OR AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = &Employee
		|			ELSE TRUE
		|		END
		|	AND (AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = VALUE(Catalog.Persons.EmptyRef)
		|			OR AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = &Employee)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	TTWarehouses AS TTWarehouses
		|		LEFT JOIN InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|		ON TTWarehouses.Warehouse = AssemblyAndDeliveryStatuses.ReferenceOrder.Warehouse
		|WHERE
		|	TTWarehouses.DeliveryIsAvailable = TRUE
		|	AND AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = &Employee
		|	AND AssemblyAndDeliveryStatuses.Status IN(&DeliveryInProgress)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	COUNT(DISTINCT AssemblyAndDeliveryStatuses.ReferenceOrder) AS Count
		|FROM
		|	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
		|WHERE
		|	AssemblyAndDeliveryStatuses.ReferenceOrder.Courier = &Employee
		|	AND AssemblyAndDeliveryStatuses.Status IN(&RolledBack_)";
	
	Query.SetParameter("StartDeliveryStatuses", WarehousesServer.StatusesOfOrdersToStartDeliveryByCourier());
	Query.SetParameter("Employee", Individual);
	Query.SetParameter("DeliveryInProgress", WarehousesServer.StatusesOfOrdersDeliveredByCourier());
	Query.SetParameter("RolledBack_", WarehousesServer.StatusesOfCanceledOrders());
	
	Results = Query.ExecuteBatch();
	
	OrdersToStart     = Results[2].Unload();
	OrdersAreDelivered_ = Results[3].Unload();
	OrdersCancelled = Results[4].Unload();
	
	If OrdersToStart.Count() > 0 Then
		Items.ToStartShipping1.Title = OrdersToStart[0].Count;
	Else
		Items.ToStartShipping1.Title = 0;
	EndIf;
	
	If OrdersAreDelivered_.Count() > 0 Then
		Items.DeliveryInProgress1.Title = OrdersAreDelivered_[0].Count;
	Else
		Items.DeliveryInProgress1.Title = 0;
	EndIf;
	
	If OrdersCancelled.Count() > 0 Then
		Items.ReturnToTheStore1.Title = OrdersCancelled[0].Count;
	Else
		Items.ReturnToTheStore1.Title = 0;
	EndIf;
	
EndProcedure

&AtServer
Procedure SetConditionalAppearance()

EndProcedure

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
Procedure UpdateArchiveData()
	
	Query = New Query();
	Query.Text = "SELECT
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder AS ReferenceOrder,
	               |	AssemblyAndDeliveryStatuses.Status AS Status,
	               |	Documents.Warehouse AS Warehouse,
	               |	Documents.Number AS Number,
	               |	Documents.DateOfShipment AS DeliveryDate,
	               |	Documents.DeliveryTimeFrom AS DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo AS DeliveryTimeTo,
	               |	Documents.DocumentAmount AS DocumentAmount,
	               |	Documents.DeliveryAddress AS DeliveryAddressPresentation,
	               |	Documents.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	               |	Documents.AdditionalDeliveryInformation AS AdditionalDeliveryInformation,
	               |	Documents.Currency AS Currency
	               |INTO TemporaryDisposalTable
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.SalesOrder AS Documents
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.SalesOrder)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	               |	AND Documents.Courier = &Employee
	               |	AND Documents.Posted
	               |
	               |UNION ALL
	               |
	               |SELECT
	               |	AssemblyAndDeliveryStatuses.ReferenceOrder,
	               |	AssemblyAndDeliveryStatuses.Status,
	               |	Documents.Warehouse,
	               |	Documents.Number,
	               |	Documents.Date,
	               |	Documents.DeliveryTimeFrom,
	               |	Documents.DeliveryTimeTo,
	               |	Documents.DocumentAmount,
	               |	Documents.DeliveryAddress,
	               |	Documents.DeliveryAddressFieldValues,
	               |	Documents.AdditionalDeliveryInformation,
	               |	Documents.Currency
	               |FROM
	               |	InformationRegister.AssemblyAndDeliveryStatuses AS AssemblyAndDeliveryStatuses
	               |		INNER JOIN Document.CustomerInvoice AS Documents
	               |		ON ((CAST(AssemblyAndDeliveryStatuses.ReferenceOrder AS Document.CustomerInvoice)) = Documents.Ref)
	               |WHERE
	               |	AssemblyAndDeliveryStatuses.Status IN(&Statuses)
	               |	AND Documents.Courier = &Employee
	               |	AND Documents.Posted
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT
	               |	SUM(1) AS NumberOfReferences
	               |FROM
	               |	TemporaryDisposalTable AS References
	               |;
	               |
	               |////////////////////////////////////////////////////////////////////////////////
	               |SELECT TOP 20
	               |	References.ReferenceOrder AS ReferenceOrder,
	               |	References.Status AS Status,
	               |	References.Warehouse AS Warehouse,
	               |	References.Number AS Number,
	               |	References.DeliveryDate AS DeliveryDate,
	               |	References.DeliveryTimeFrom AS DeliveryTimeFrom,
	               |	References.DeliveryTimeTo AS DeliveryTimeTo,
	               |	References.DocumentAmount AS DocumentAmount,
	               |	References.DeliveryAddressPresentation AS DeliveryAddressPresentation,
	               |	References.DeliveryAddressFieldValues AS DeliveryAddressFieldValues,
	               |	References.AdditionalDeliveryInformation AS Comment,
	               |	References.Currency AS Currency
	               |FROM
	               |	TemporaryDisposalTable AS References
	               |
	               |ORDER BY
	               |	DeliveryDate DESC,
	               |	DeliveryTimeTo DESC";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Statuses", WarehousesServer.StatusOfOrdersCompleted());
	
	Results = Query.ExecuteBatch();
	
	NumberOfReferences = 0;
	If Not Results[1].IsEmpty() Then
		NumberOfReferences = Results[1].Unload()[0].NumberOfReferences;
	EndIf;
	
	SamplingByOrders = Results[2].Select();
	
	ListOfOrders_.Clear();
	While SamplingByOrders.Next() Do
		
		NewRow = ListOfOrders_.Add();
		
		FillPropertyValues(NewRow, SamplingByOrders);
		
		If ValueIsFilled(NewRow.Comment) Then
			NewRow.CommentPicture_2 = 1;
		EndIf;
		
		Module = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery;
		
		NewRow.DateTimeOfDeliveryPresentation = Module.DateTimeOfDeliveryPresentation(NewRow);
		NewRow.SumPresentation = Module.SumPresentation(NewRow);
		
	EndDo;
	
	Items.NumberOfOrdersArchive.Title = NumberOfReferences;
	
EndProcedure

&AtClient
Procedure AfterClosingQuestion_(Result, Var_Parameters) Export
	
	If Result = DialogReturnCode.Yes Then
		ClosurePermitted = True;
		Exit(True);
	EndIf;
	
EndProcedure

&AtServer
Procedure UpdateWarehouseContactInformation()
	
	Items.AddressValue.Title = ContactsManager.ObjectContactInformation(CurrentWarehouse, Catalogs.ContactInformationKinds.WarehouseAddress,,True);
	Items.PhoneValue.Title = ContactsManager.ObjectContactInformation(CurrentWarehouse, Catalogs.ContactInformationKinds.WarehousePhone,,True);
	
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

&AtServer
Function AvailableWarehouses()
	
	Return WarehousesServer.AvailableEmployeeWarehousesByEmployeeType(Employee, EmployeeType);
	
EndFunction

#EndRegion

#EndRegion