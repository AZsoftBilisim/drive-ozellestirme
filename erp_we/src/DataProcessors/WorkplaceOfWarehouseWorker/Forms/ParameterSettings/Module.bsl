
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;
	
	If Not GetFunctionalOption("UsePeripherals") Then
		ExceptionText = NStr("vi = 'Trong tùy chỉnh chương trình đã ngắt sử dụng thiết bị kết nối. Chỉ có thể sử dụng chỗ làm việc di động của nhân viên kho bãi khi sử dụng thiết bị kết nối.';
							|ru = 'В настройках программы отключено использование подключаемого оборудования. Использовать мобильные рабочие места работников склада можно только при использовании подключаемого оборудования.';
							|en = 'Peripherals are disabled in the application settings. You cannot use mobile workplaces of warehouse workers only unless peripherals are enabled.'; fa = 'Peripherals are disabled in the application settings. You cannot use mobile workplaces of warehouse workers only unless peripherals are enabled.';
							|it = 'Nelle impostazioni del programma è disattivato l''uso dell''apparecchiatura collegata. È possibile utilizzare i posti di lavori mobili dei dipendenti del magazzino solamente tramite l''uso dell''apparecchiatura collegata.';
							|pl = 'W ustawieniach programu zostało wyłączone korzystanie z podłączanego urządzenia. Korzystać z mobilnego miejsca pracy pracowników magazynu można tylko przy użyciu podłączanego urządzenia.';
							|tr = 'Bağlı ekipmanların kullanımı program ayarlarında devre dışı bırakılmıştır. Ambar çalışanlarının mobil çalışma alanları yalnızca bağlı ekipman kullanıldığında kullanılabilir.'");
		Raise ExceptionText;
	EndIf;
	
	NewRecord =  Parameters.Key.IsEmpty();
	
	If NewRecord Then
		Record.User = Parameters.User;
		Record.OpenedForm = Parameters.OpenedForm;
		
		OnReadCreateAtServer();
	EndIf;
	
EndProcedure

&AtServer
Procedure OnReadAtServer(CurrentObject)
	
	ParametersStructure = CurrentObject.Parameters.Get();
	
	If TypeOf(ParametersStructure) = Type("Structure")
		And ParametersStructure.Property("Warehouse")
		And ParametersStructure.Property("Premise") Then
		
		Warehouse = ParametersStructure.Warehouse;
		Premise = ParametersStructure.Premise;
		
		If Not ParametersStructure.Property("ScreenResolution") Then
			ScreenResolution = Enums.ScreenResolutions.Resolution320x320;
		Else
			ScreenResolution = ParametersStructure.ScreenResolution;
		EndIf;
		
		If Not ParametersStructure.Property("WarehouseJobProcessingProcedure") Then
			WarehouseJobProcessingProcedure = Enums.WarehouseJobProcessingProcedure.StorageBinGoods;
		Else
			WarehouseJobProcessingProcedure = ParametersStructure.WarehouseJobProcessingProcedure;
		EndIf;
		
	EndIf;
	
	OnReadCreateAtServer();
	
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("Warehouse", Warehouse);
	ParametersStructure.Insert("Premise", Premise);
	ParametersStructure.Insert("ScreenResolution", ScreenResolution);
	ParametersStructure.Insert("WarehouseJobProcessingProcedure", WarehouseJobProcessingProcedure);
	
	CurrentObject.Parameters = New ValueStorage(ParametersStructure);
	CurrentObject.ParameterPresentationText = WarehousesServer.GetWarehousePresentation(Warehouse, Premise);
	
EndProcedure

&AtServer
Procedure FillCheckProcessingAtServer(Cancel, CheckedAttributes)
	
	NotCheckedAttributeArray = New Array;
	
	If Not WarehousesServer.UseWarerooms(Warehouse) Then
		NotCheckedAttributeArray.Add("Premise");
	EndIf;
	
	TSPropsErrorPattern = NStr("vi = 'Chưa điền cột ""Khu làm việc"" tại dòng %LineNumber% trong danh sách ""Khu làm việc""';
								|ru = 'Не заполнена колонка ""Рабочий участок"" в строке %LineNumber% списка ""Рабочие участки""';
								|en = 'Column ""Warehouse area"" in line %LineNumber% of list ""Warehouse areas"" is not filled in'; fa = 'Column ""Warehouse area"" in line %LineNumber% of list ""Warehouse areas"" is not filled in';
								|it = 'La colonna ""Area di lavoro"" non è compilata nella riga %LineNumber% dell''elenco ""Aree di lavoro""';
								|pl = 'Nie została wypełniona kolumna ""Obszar roboczy"" w wierszu %LineNumber% listy ""Obszary robocze""';
								|tr = '""Çalışma alanları"" listesinin %LineNumber% satırındaki ""Çalışma alanı"" sütunu doldurulmadı'");
	
	For Each RowOfTables In WarehouseZones Do
		
		If Not ValueIsFilled(RowOfTables.WarehouseZone) Then
			
			LineNumber = WarehouseZones.IndexOf(RowOfTables) + 1;
			
			MessageText = StrReplace(TSPropsErrorPattern, "%LineNumber%", LineNumber);
			Field = CommonClientServer.PathToTabularSection("WarehouseZones", LineNumber, "WarehouseZone");
			
			CommonClientServer.MessageToUser(MessageText,, Field,, Cancel);
			
		EndIf;
		
	EndDo;
	
	Common.DeleteNotCheckedAttributesFromArray(CheckedAttributes, NotCheckedAttributeArray);
	
EndProcedure

&AtServer
Procedure ExcludeUserFromSiteEmployees(WarehouseZone, AreaWorker)
	
	WorkingAreaObject = WarehouseZone.GetObject();
	
	TSRow = WorkingAreaObject.AreaWorkers.Find(AreaWorker, "AreaWorker");
	If Not (TSRow = Undefined) Then
		WorkingAreaObject.AreaWorkers.Delete(TSRow);
		WorkingAreaObject.Write();
	EndIf;
	
EndProcedure

&AtServer
Procedure AfterWriteAtServer(CurrentObject, WriteParameters)
	
	// Go through the rows of the table of work sites before the change, if the work site
	// is not in the table after the change, it is necessary to exclude the user from the list of workers.
	
	FilterParameters = New Structure("WarehouseZone");
	
	For Each TablRow In WorkAreasUntilChange Do
		
		FilterParameters.WarehouseZone = TablRow.WarehouseZone;
		
		RowsArray = WarehouseZones.FindRows(FilterParameters);
		If RowsArray.Count() = 0 Then // the work site has been removed from the list
			ExcludeUserFromSiteEmployees(TablRow.WarehouseZone, Record.User);
		EndIf;
		
	EndDo;
	
	// Add a user to the list of site employees for all specified sites.
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	WarehouseZones.WarehouseZone
	|INTO CurWorkSites
	|FROM
	|	&WarehouseZones AS WarehouseZones
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CurWorkSites.WarehouseZone AS WarehouseZone
	|FROM
	|	CurWorkSites AS CurWorkSites
	|		LEFT JOIN Catalog.WarehouseZones.AreaWorkers AS WorkspacesInDatabase
	|		ON CurWorkSites.WarehouseZone = WorkspacesInDatabase.Ref
	|			AND (WorkspacesInDatabase.AreaWorker = &User)
	|WHERE
	|	WorkspacesInDatabase.Ref IS NULL ";
	
	PlotTable = WarehouseZones.Unload();
	
	PlotTable.GroupBy("WarehouseZone");
	
	Query.SetParameter("WarehouseZones", PlotTable);
	Query.SetParameter("User", CurrentObject.User);
	
	Selection = Query.Execute().Select();
	
	While Selection.Next() Do
		CatalogObject = Selection.WarehouseZone.GetObject(); // CatalogObject.WarehouseZones
		NewRow = CatalogObject.AreaWorkers.Add();
		NewRow.AreaWorker = CurrentObject.User;
		
		CatalogObject.Write();
	EndDo;
	
	// Install the version 8.2 interface for the specified user, because MPM is not available in a Taxi.
	IBUserID = Common.ObjectAttributeValue(Record.User, "IBUserID");
	UserName = InfoBaseUsers.FindByUUID(IBUserID).Name;
	If Not WorkplaceOfWarehouseWorkerServer.Version8_2OfClientApplicationInterface(UserName) Then 
		WorkplaceOfWarehouseWorkerServer.InstallVersion8_2OfClientApplicationInterface(UserName);
	EndIf;
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	DimensionStructure = New Structure;
	DimensionStructure.Insert("User", Record.User);
	DimensionStructure.Insert("OpenedForm", Record.OpenedForm);
	
	Notify("Write_ConfigureFormOpeningOnStartingApplication", WriteParameters, DimensionStructure);
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

&AtClient
Procedure UserOnChange(Item)
	
	FillInWorkAreas();
	
EndProcedure

#EndRegion

#Region Private

#Region OnChangeAttributes

&AtServer
Procedure WarehouseOnChangeServer()
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse,Premise", Warehouse,Premise));
	
	FillInWorkAreas();
	
EndProcedure

#EndRegion

#Region Other

&AtServer
Procedure OnReadCreateAtServer()
	
	StructureOfFormParameters = OpenFormsOnApplicationStartClientServerOverridable.FormSettings(Record.OpenedForm);
	LaunchParameter = StructureOfFormParameters.LaunchParameter;
	
	OldMeaningWarehouse = Warehouse;
	
	If GetFunctionalOption("UseSeveralWarehouses") Then
		Warehouse = SettingsValueCached.GetDefaultWarehouse(Warehouse);
	Else
		FillingStructure = New Structure("Warehouse");
		TMCommonUse.Filling(FillingStructure, Undefined, Undefined);
		Warehouse = FillingStructure.Warehouse;
	EndIf;
	
	If OldMeaningWarehouse <> Warehouse Then
		Premise = Catalogs.Warerooms.EmptyRef();
		WarehouseZones.Clear();
	EndIf;
	
	WarehouseOnChangeServer();
	
	WorkAreasUntilChange.Load(WarehouseZones.Unload())
	
EndProcedure

&AtServer
Procedure FillInWorkAreas()
	
	If Not WarehousesServer.UseWarehouseZones(Warehouse, Premise) Then
		WarehouseZones.Clear();
		Return;
	EndIf;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	WarehouseZonesAreaWorkers.Ref AS WarehouseZone
	|FROM
	|	Catalog.WarehouseZones.AreaWorkers AS WarehouseZonesAreaWorkers
	|WHERE
	|	WarehouseZonesAreaWorkers.AreaWorker = &AreaWorker
	|	AND WarehouseZonesAreaWorkers.Ref.Owner = &Warehouse
	|	AND WarehouseZonesAreaWorkers.Ref.Premise = &Premise
	|
	|ORDER BY
	|	WarehouseZonesAreaWorkers.Ref.Description";
	
	Query.SetParameter("AreaWorker", Record.User);
	Query.SetParameter("Warehouse", Warehouse);
	Query.SetParameter("Premise", Premise);
	
	WarehouseZones.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	
	WarehouseOnChangeServer();
	
EndProcedure

#EndRegion

#EndRegion
