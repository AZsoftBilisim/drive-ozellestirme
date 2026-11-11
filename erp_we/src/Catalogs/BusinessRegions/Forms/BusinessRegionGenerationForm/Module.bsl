
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	GeoSchemaStructure = Constants.GeographicDiagramForReports.Get().Get();
	If GeoSchemaStructure <> Undefined Then
		GeoSchemaStructure.Property("GeoDiagram", GeoDiagram);
		FillInGeoMapItems();
	Else
		UserMessage = NStr("vi = 'Để điền danh sách khu vực, cần chọn thẻ ""Marketing và CRM"" trong phân hệ quản trị hệ thống.';
							|ru = 'Для заполнения списка регионов необходимо выбрать карту в разделе администрирования ""Маркетинг и CRM"".';
							|en = 'To fill in the list of regions, select a map in ""Master data and settings – CRM and marketing – Business regions"".'; fa = 'To fill in the list of regions, select a map in ""Master data and settings – CRM and marketing – Business regions"".';
							|it = 'Per compilare l''elenco delle aree, è necessario selezionare una mappa nella sezione di gestione ""Marketing e CRM"".';
							|pl = 'W celu wypełnienia listy regionów należy wybrać mapę w rozdziale administrowania ""Marketing i CRM"".';
							|tr = 'Bölge listesini doldurmak için ""Pazarlama ve CRM"" yönetimi bölümünde bir kart seçilmeli.'");
		CommonClientServer.MessageToUser(UserMessage);
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure GeographicRegionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	Item.CurrentData.Check = Not Item.CurrentData.Check;
	
EndProcedure

&AtClient
Procedure GeographicRegionsOnEditEnd(Item, NewRow, CancelEdit)
	
	SelectedRegions = SelectedRegions();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure SelectAllExecute()
	
	ElementsGeographicRegions = GeographicRegions.GetItems();
	For Each GeographicalRegionElement In ElementsGeographicRegions Do
		GeographicalRegionElement.Check = True;
		UnderGeographicalRegionsElements = GeographicalRegionElement.GetItems();
		For Each UnderGeographicRegionElement In UnderGeographicalRegionsElements Do
			UnderGeographicRegionElement.Check = True;
		EndDo;
	EndDo;
	
	SelectedRegions = SelectedRegions();
	
EndProcedure

&AtClient
Procedure CancelSelectAllExecute()
	
	ElementsGeographicRegions = GeographicRegions.GetItems();
	For Each GeographicalRegionElement In ElementsGeographicRegions Do
		GeographicalRegionElement.Check = False;
		UnderGeographicalRegionsElements = GeographicalRegionElement.GetItems();
		For Each UnderGeographicRegionElement In UnderGeographicalRegionsElements Do
			UnderGeographicRegionElement.Check = False;
		EndDo;
	EndDo;
	
	SelectedRegions = 0;
	
EndProcedure

&AtClient
Procedure Fill(Command)
	
	If SelectedRegions() Then
		NumberOfNewRegions = FillInBusinessRegions();
		Close(NumberOfNewRegions);
	Else
		UserMessage = NStr("vi = 'Cần chọn ít nhất một khu vực địa lý để điền khu vực kinh doanh.';
							|ru = 'Необходимо выбрать хотя бы один географический регион для заполнения бизнес-регионов.';
							|en = 'Select at least one geographic region.'; fa = 'Select at least one geographic region.';
							|it = 'È necessario selezionare almeno un''area geografica per compilare le aree commerciali.';
							|pl = 'Należy wybrać chociaż jeden region geograficzny do wypełnienia regionów biznesowych.';
							|tr = 'İş bölgelerini doldurmak için en az bir coğrafi bölge seçilmeli.'");
		CommonClientServer.MessageToUser(UserMessage, , "GeographicRegions");
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Function FillInBusinessRegions()
	
	NumberOfNewRegions = 0;
	
	TreeOfRegions = FormAttributeToValue("GeographicRegions");
	ListOfRegions = TreeOfRegions.Rows.FindRows(New Structure("Check", True), True);
	
	For Each State In ListOfRegions Do
		BusinessRegion = FindBusinessRegion(State.GeographicRegionValue, State.GeographicRegionName);
		If BusinessRegion = Catalogs.BusinessRegions.EmptyRef() Then
			NewBusinessRegion = Catalogs.BusinessRegions.CreateItem();
			NewBusinessRegion.Description = State.GeographicRegionName;
			NewBusinessRegion.GeographicRegion = State.GeographicRegionName;
			NewBusinessRegion.GeographicRegionValue = State.GeographicRegionValue;
			If State.Parent <> Undefined Then
				ParentRegion = FindBusinessRegion(State.Parent.GeographicRegionValue,
					State.Parent.GeographicRegionName);
				NewBusinessRegion.Parent = ParentRegion;
			EndIf;
			NewBusinessRegion.Write();
			NumberOfNewRegions = NumberOfNewRegions + 1;
		EndIf;
	EndDo;
	
	Return NumberOfNewRegions;
	
EndFunction

&AtServer
Function FindBusinessRegion(GeographicRegionValue, GeographicRegion)
	
	FoundBusinessRegion = Catalogs.BusinessRegions.EmptyRef();
	
	FoundBusinessRegion = Catalogs.BusinessRegions.FindByAttribute("GeographicRegionValue", GeographicRegionValue);
	
	If FoundBusinessRegion = Catalogs.BusinessRegions.EmptyRef() Then
		FoundBusinessRegion = Catalogs.BusinessRegions.FindByDescription(GeographicRegion, True);
	EndIf;
	
	Return FoundBusinessRegion;

EndFunction

&AtServer
Procedure FillInGeoMapItems()
	
	ChooseCities = False; // Cities will be selected only for the map of Russian regions with all cities
	If GeoDiagram.Layers.Find("States Russia_") <> Undefined
		And GeoDiagram.Layers.Find("Cities") <> Undefined Then
		Cities = GeoDiagram.Layers.Cities; // GeographicalSchemaLayer
		Capital = Cities.Series.Capital; // GeographicalSchemaLayerDataSeries
		NotCapitals = Cities.SelectObjects(New Structure(Capital.Name, False));
		If NotCapitals.Count() Then
			ChooseCities = True;
		EndIf;
	EndIf;
	
	Tree = New ValueTree;
	
	Array = New Array;
	SQ = New StringQualifiers(255);
	Array.Add(Type("String"));
	TypeDescription = New TypeDescription(Array, , SQ);
	Tree.Columns.Add("GeographicRegionName", TypeDescription);
	KCH = New NumberQualifiers(25,0);
	Array.Add(Type("Number"));
	TypeDescription = New TypeDescription(Array, KCH, SQ);
	Tree.Columns.Add("GeographicRegionValue", TypeDescription);
	Array = New Array;
	Array.Add(Type("Boolean"));
	TypeDescription = New TypeDescription(Array, , );
	Tree.Columns.Add("Check", TypeDescription);
	
	
	Layer = GeoDiagram.Layers[0];
	
	ThereIsSeriesTitle = False;
	SeriesName = Layer.Series.Find("Name1");
	If SeriesName <> Undefined Then
		ThereIsSeriesTitle = True;
	EndIf;
	
	For Each Object In Layer.Objects Do
		
		NewRegion = Tree.Rows.Add();
		If ThereIsSeriesTitle Then
			NameOfObject = Layer.GetValue(Object, SeriesName);
			NewRegion.GeographicRegionName = NameOfObject.Value;
			NewRegion.GeographicRegionValue = Object.Value;
		Else
			NewRegion.GeographicRegionName = Object.Value;
			NewRegion.GeographicRegionValue = Object.Value;
		EndIf;
		
		If ChooseCities Then
			ThereIsSeriesNameOfCity = False;
			SeriesCityName = Cities.Series.Find("Name1");
			If SeriesCityName <> Undefined Then
				ThereIsSeriesNameOfCity = True;
			EndIf;
			
			COD_CLADR_REGION = Cities.Series.COD_CLADR_REGION; // GeographicalSchemaLayerDataSeries
			CitiesInRegion = Cities.SelectObjects(New Structure(COD_CLADR_REGION.Name, Object.Value));
			For Each CityOfRegion In CitiesInRegion Do
				NewTown = NewRegion.Rows.Add();
				If ThereIsSeriesNameOfCity Then
					CityName = Cities.GetValue(CityOfRegion, SeriesCityName);
					NewTown.GeographicRegionName = CityName.Value;
					NewTown.GeographicRegionValue = CityOfRegion.Value;
				Else
					NewTown.GeographicRegionName = CityOfRegion.Value;
					NewTown.GeographicRegionValue = CityOfRegion.Value;
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Tree.Rows.Sort("GeographicRegionName", True);
	
	ValueToFormAttribute(Tree, "GeographicRegions");
	
EndProcedure

// Returns the number of marked geographical regions
//
&AtClient
Function SelectedRegions()
	
	SelectedRegions = 0;
	
	ElementsGeographicRegions = GeographicRegions.GetItems();
	For Each GeographicalRegionElement In ElementsGeographicRegions Do
		If GeographicalRegionElement.Check Then
			SelectedRegions = SelectedRegions + 1;
		EndIf;
		UnderGeographicalRegionsElements = GeographicalRegionElement.GetItems();
		For Each UnderGeographicRegionElement In UnderGeographicalRegionsElements Do
			If UnderGeographicRegionElement.Check Then
				SelectedRegions = SelectedRegions + 1;
			EndIf;
		EndDo;
	EndDo;
	
	Return SelectedRegions;
	
EndFunction

#EndRegion