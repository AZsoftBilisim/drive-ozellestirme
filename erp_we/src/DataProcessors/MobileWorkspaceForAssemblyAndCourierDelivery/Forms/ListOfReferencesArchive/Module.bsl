
#Region FormEventHandlers
// Code of procedures and functions

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	SetConditionalAppearance();
	Employee = Common.ObjectAttributeValue(Users.CurrentUser(), "Individual");
	ShowProductPhotos = Parameters.ShowProductPhotos;
	EmployeeType = DataProcessors.MobileWorkspaceForAssemblyAndCourierDelivery.EmployeeTypeCourier();
	UpdateFormData();
	Filter = "Number";
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	PhotographPresentationOfSelections();
	Items.GroupPages.CurrentPage = Items.FiltersPage;

EndProcedure

&AtClient
Procedure BeforeClose(Cancel, Exit, WarningText, StandardProcessing)
	
	If Items.GroupPages.CurrentPage = Items.FiltersPage Then
		Cancel = True;
		Items.GroupPages.CurrentPage = Items.PageOfOrder;
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterValueClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	ProcessValueBySelection();
	
EndProcedure

&AtClient
Procedure FilterClearing(Item, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure FilterChoiceProcessing(Item, ValueSelected, StandardProcessing)
	
	Filter = ValueSelected;
	ProcessValueBySelection();
		
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

#Region FormTableItemsEventHandlersTheListOfUnallocatedOrders

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UpdateForm(Command)
	
	Items.GroupPages.CurrentPage = Items.PageOfOrder;
	UpdateFormData();
	
EndProcedure

&AtClient
Procedure ClearSelections(Command)
	
	ProcessValueBySelection();

EndProcedure

&AtClient
Procedure SelectionsOpenCompletion(Result, Var_Parameters) Export
	
	If Result <> Undefined Then
		
		Filter = Result.Value;
		ProcessValueBySelection();
		
	EndIf;
	
EndProcedure

&AtClient
Procedure ProcessValueBySelection()
	
	If Filter = "Number" Then
		
		FilterValue = "";
		
	ElsIf Filter = "DeliveryDate" Then
		
		FilterValue = New StandardPeriod;
		
	ElsIf Filter = "Warehouse" Then
		
		FilterValue = EmptyWarehouse;
		
	ElsIf Filter = "Address" Then
		
		FilterValue = "";
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GoToSelections(Command)
	
	Items.GroupPages.CurrentPage = Items.FiltersPage;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure UpdateFormData()
	
	Query = New Query();
	Text = "SELECT
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
	               |	AND Documents.Date >= &Date30
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
	               |	AND Documents.Date >= &Date30
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
	               |SELECT TOP 100
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
	               |WHERE &Filters
	               |ORDER BY
	               |	DeliveryDate DESC,
	               |	DeliveryTimeTo DESC";
	
	Query.SetParameter("Employee", Employee);
	Query.SetParameter("Date", CurrentSessionDate());
	Query.SetParameter("Statuses", WarehousesServer.StatusOfOrdersCompleted());
	Query.SetParameter("Date30", CurrentSessionDate()-30*24*60*60);
	
	SelectionText_ = "True";
	HasFilter = ValueIsFilled(FilterValue);
	
	If Filter = "Number" Then
		
		If HasFilter Then
			Query.SetParameter("Number", FilterValue);
			SelectionText_ = SelectionText_ + " And " + "References.Number LIKE ""%""+&Number+""%""";
		EndIf;
		
	ElsIf Filter = "DeliveryDate" Then
		
		If HasFilter  Then
			Query.SetParameter("StartDate", FilterValue.StartDate);
			Query.SetParameter("EndDate", FilterValue.EndDate);
			SelectionText_ = SelectionText_ + " And " + "References.DeliveryDate BETWEEN &StartDate AND &EndDate";
		EndIf;
		
	ElsIf Filter = "Warehouse" Then
		
		If HasFilter Then
			Query.SetParameter("Warehouse", FilterValue);
			SelectionText_ = SelectionText_ + " And " + "References.Warehouse IN(&Warehouse)";
		EndIf;
		
	ElsIf Filter = "Address" Then
		
		If HasFilter Then
			Query.SetParameter("Address", FilterValue);
			SelectionText_ = SelectionText_ + " And " + "CAST(References.DeliveryAddressPresentation AS STRING(500)) LIKE ""%""+&Address + ""%""";
		EndIf;
		
	EndIf;
	
	Text = StrReplace(Text, "&Filters", SelectionText_);
	
	Query.Text = Text;
	
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
	
	NumberOfSelectionOrders = ListOfOrders_.Count();
	
	Items.DecorationSearchResultQuantity.Title = NumberOfSelectionOrders;
	
EndProcedure

&AtClient
Procedure PhotographPresentationOfSelections()
	
	ProcessValueBySelection();
	
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
Procedure SetConditionalAppearance()

EndProcedure

#EndRegion
