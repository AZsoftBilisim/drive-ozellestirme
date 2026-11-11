
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	Warehouse = Parameters.Warehouse;
	StoreFormat = Parameters.StoreFormat;
	If ValueIsFilled(Warehouse) Then
	
		Items.FilterWarehouse.Visible = False;
		Items.ListWarehouse.Visible = False;
	
	EndIf; 
	If ValueIsFilled(StoreFormat) Then
	
		Items.FilterStoreFormat.Visible = False;
		Items.ListStoreFormat.Visible = False;
	
	EndIf;
	
	StartDate = CurrentSessionDate();
	
	AccessRightUpdate = AccessRight("Update", Metadata.InformationRegisters.HistoryOfStoreFormatChange);
	Items.ListCreate.Visible = AccessRightUpdate;
	Items.ListCopy.Visible = AccessRightUpdate;
	Items.ListClearFormat.Visible = AccessRightUpdate;
	Items.ListContextMenuClearFormat.Visible = AccessRightUpdate;
	
	If Not GetFunctionalOption("UseStoreFormats") Then
	
		ThisForm.Title = NStr("vi = 'Lịch sử thay đổi tùy chỉnh danh điểm mặt hàng trong cửa hàng';
								|ru = 'История изменения настроек ассортимента магазинов';
								|en = 'Change history of store product range settings'; fa = 'Change history of store product range settings';
								|it = 'Cronologia modifiche delle impostazioni dell''assortimento dei negozi';
								|pl = 'Historia zmiany ustawień asortymentu sklepów';
								|tr = 'Mağaza ürün gamı ayarlarındaki değişiklik geçmişi'");
		Items.GroupPages.PagesRepresentation = FormPagesRepresentation.None;
	
	EndIf; 
	
	UpdateList();
	
	FormEvents.OnCreateAtServer(ThisForm, StandardProcessing, Cancel);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure FilterWarehouseOnChange(Item)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure FilterStoreFormatOnChange(Item)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure StartDateOnChange(Item)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure PeriodEndingOnChange(Item)
	
	UpdateList();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersList

&AtClient
Procedure ListSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ListLine = List.FindByID(RowSelected);
	
	If ListLine = Undefined 
		Or Not ValueIsFilled(ListLine.Warehouse)
		Or Not ValueIsFilled(ListLine.Period) And Not AccessRightUpdate Then
		Return;
	EndIf; 
	
	If Not ValueIsFilled(ListLine.Period) Then
	
		FillingValues = New Structure;
		FillingValues.Insert("Period", Max(StartDate, EndDate));
		If ValueIsFilled(ListLine.Warehouse) Then
			FillingValues.Insert("Warehouse", ListLine.Warehouse);
		EndIf; 
		FormParameters = New Structure;
		FormParameters.Insert("FillingValues", FillingValues);
	
	Else
	
		Var_Key = GetRecordKey(ListLine.Period, ListLine.Warehouse);
	
		FormParameters = New Structure("Key", Var_Key);
	
	EndIf; 
	
	Notification = New CallbackDescription("OpeningRecordFormCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.RecordForm", FormParameters,,,,, Notification);
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SetDateInterval(Command)
	
	Notification = New CallbackDescription(
		"SetDateIntervalCompletion",
		ThisObject);
		
	TMCommonUseClient.EditPeriod(
		ThisForm, 
		New Structure("StartDate, EndDate", "StartDate", "EndDate"),
		Notification);
	
EndProcedure

&AtClient
Procedure Refresh(Command)
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure Change(Command)
	
	RowSelected = Items.List.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	ListLine = List.FindByID(RowSelected);
	
	If ListLine = Undefined
		Or Not ValueIsFilled(ListLine.Period)
		Or Not ValueIsFilled(ListLine.Warehouse) Then
		Return;
	EndIf; 
	
	Var_Key = GetRecordKey(ListLine.Period, ListLine.Warehouse);
	
	FormParameters = New Structure("Key", Var_Key);
	
	Notification = New CallbackDescription("OpeningRecordFormCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.RecordForm", FormParameters,,,,, Notification);
	
EndProcedure

&AtClient
Procedure Create(Command)
	
	FillingValues = New Structure;
	FillingValues.Insert("Period", Max(StartDate, EndDate));
	If ValueIsFilled(Warehouse) Then
		FillingValues.Insert("Warehouse", Warehouse);
	EndIf; 
	If Not FillingValues.Property("Warehouse") Then
		RowSelected = Items.List.CurrentRow;
		If RowSelected <> Undefined Then
			ListLine = List.FindByID(RowSelected);
			If ListLine <> Undefined And ValueIsFilled(ListLine.Warehouse) Then
				FillingValues.Insert("Warehouse", ListLine.Warehouse);
			EndIf; 
		EndIf; 
	EndIf; 
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	Notification = New CallbackDescription("OpeningRecordFormCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.RecordForm", FormParameters, ThisForm,,,, Notification);
	
EndProcedure

&AtClient
Procedure Copy(Command)
	
	RowSelected = Items.List.CurrentRow;
	
	If RowSelected = Undefined Then
		Return;
	EndIf;
	
	ListLine = List.FindByID(RowSelected);
	
	If ListLine = Undefined Then
		Return;
	EndIf;
	
	FillingValues = New Structure;
	FillingValues.Insert("Period", ListLine.Period);
	FillingValues.Insert("Warehouse", ListLine.Warehouse);
	FillingValues.Insert("StoreFormat", ListLine.StoreFormat);
	FillingValues.Insert("ControlProductRange", ListLine.ControlProductRange);
	FormParameters = New Structure;
	FormParameters.Insert("FillingValues", FillingValues);
	
	Notification = New CallbackDescription("OpeningRecordFormCompletion", ThisObject);
	
	OpenForm("InformationRegister.HistoryOfStoreFormatChange.RecordForm", FormParameters, ThisForm,,,, Notification);
	
EndProcedure

&AtClient
Procedure ClearFormat(Command)
	
	RowSelected = Items.List.CurrentRow;
	If RowSelected = Undefined Then
		Return;
	EndIf; 
	ListLine = List.FindByID(RowSelected);
	
	If ListLine = Undefined 
		Or Not ValueIsFilled(ListLine.Warehouse)
		Or Not ValueIsFilled(ListLine.Period)
		Or Not ValueIsFilled(ListLine.StoreFormat) Then
		Return;
	EndIf;
	
	Period = Max(ListLine.Period, StartDate, EndDate);
	If Period <= ListLine.Period Then
		Period =  EndOfDay(ListLine.Period)+1;
	EndIf;
	
	ClearFormatOnServer(ListLine.Warehouse, Period);
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure SetDateIntervalCompletion(Period, AdditionalParameters) Export 
	
	UpdateList();
	
EndProcedure

&AtClient
Procedure OpeningRecordFormCompletion(Result, AdditionalParameters) Export 
	
	UpdateList();
	
EndProcedure

&AtServer
Procedure UpdateList()

	Query = New Query;
	Query.Text = 
	"SELECT ALLOWED
	|	Table.Period AS Period,
	|	Table.Warehouse AS Warehouse,
	|	Table.StoreFormat,
	|	Table.ControlProductRange,
	|	Table.RetailPricesFromStoreFormat
	|INTO InitialFormats
	|FROM
	|	InformationRegister.HistoryOfStoreFormatChange.SliceLast(&StartDate, &FilterHistory__1) AS Table
	|WHERE &FilterFormat_1
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT ALLOWED
	|	Table.Period AS Period,
	|	Table.Warehouse AS Warehouse,
	|	Table.StoreFormat,
	|	Table.ControlProductRange,
	|	Table.RetailPricesFromStoreFormat
	|FROM
	|	InitialFormats AS Table
	|
	|UNION ALL
	|
	|SELECT
	|	ISNULL(Table.Period,DATETIME(1, 1, 1)) AS Period,
	|	Warehouses.Ref,
	|	Table.StoreFormat,
	|	Table.ControlProductRange,
	|	Table.RetailPricesFromStoreFormat
	|FROM
	|	Catalog.Warehouses AS Warehouses
	|	LEFT JOIN InformationRegister.HistoryOfStoreFormatChange AS Table
	|		ON Warehouses.Ref = Table.Warehouse
	|		AND Table.Period > &StartDate
	|		AND CASE
	|				WHEN &PeriodEnding = DATETIME(1, 1, 1)
	|					THEN TRUE
	|				ELSE Table.Period <= &PeriodEnding
	|			END
	|	LEFT JOIN InitialFormats AS InitialFormats
	|		ON Warehouses.Ref = InitialFormats.Warehouse
	|WHERE
	|	NOT Warehouses.IsFolder
	|	AND NOT Warehouses.DeletionMark
	|	AND (InitialFormats.Warehouse IS NULL 
	|		OR NOT Table.Warehouse IS NULL )
	|	AND &FilterHistory__2
	|	AND &FilterFormat_2
	|
	|ORDER BY
	|	Warehouse,
	|	Period";
	
	FilterHistory__1 = "";
	FilterHistory__2 = "";
	FilterFormat_1 = "TRUE";
	FilterFormat_2 = "";
	
	If ValueIsFilled(Warehouse) Then
		FilterHistory__1 = "Warehouse = &Warehouse";
		FilterHistory__2 = "AND Warehouses.Ref = &Warehouse";
	EndIf; 
	
	If ValueIsFilled(StoreFormat) Then
		FilterFormat_1 = "
			|	Table.StoreFormat = &StoreFormat";
		FilterFormat_2 = "AND Table.StoreFormat = &StoreFormat";
	EndIf; 
	
	Query.Text = StrReplace(Query.Text, "&FilterHistory__1",  FilterHistory__1);
	Query.Text = StrReplace(Query.Text, "AND &FilterHistory__2",  FilterHistory__2);
	Query.Text = StrReplace(Query.Text, "&FilterFormat_1", FilterFormat_1);
	Query.Text = StrReplace(Query.Text, "AND &FilterFormat_2", FilterFormat_2);
	
	Query.SetParameter("StartDate",    ?(ValueIsFilled(StartDate), StartDate, Date(1,1,1,0,0,1)));
	Query.SetParameter("PeriodEnding", EndDate);
	Query.SetParameter("Warehouse",            Warehouse);
	Query.SetParameter("StoreFormat",   StoreFormat);
	
	QueryResult = Query.Execute();
	
	Table = QueryResult.Unload();
	
	List.Load(Table);
	
EndProcedure 

&AtServerNoContext
Function GetRecordKey(Period, Warehouse)
	
	KeyStructure1 = New  Structure("Period, Warehouse", Period, Warehouse);
	Return InformationRegisters.HistoryOfStoreFormatChange.CreateRecordKey(KeyStructure1);
	
EndFunction

&AtServer
Procedure ClearFormatOnServer(Warehouse, Period)

	RecordSet = InformationRegisters.HistoryOfStoreFormatChange.CreateRecordSet();
	RecordSet.Filter.Warehouse.Set(Warehouse);
	RecordSet.Filter.Period.Set(Period);
	
	RsRecord = RecordSet.Add();
	RsRecord.Period = Period;
	RsRecord.Warehouse = Warehouse;
	
	RecordSet.Write();
	UpdateList();

EndProcedure

#EndRegion







 
 
 