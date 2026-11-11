
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	Parameters.Property("GeographicRegionValue", CurrentRegionValue);
	
	GeoSchemaStructure = Constants.GeographicDiagramForReports.Get().Get();
	If GeoSchemaStructure <> Undefined Then
		GeoSchemaStructure.Property("GeoDiagram", GeoDiagram);
		LoadGeoMapItems();
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlersForFormElements

&AtClient
Procedure GeographicRegionsSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	MakeChoice_();
	
EndProcedure

&AtClient
Procedure GeographicRegionsValueChoice(Item, Value, StandardProcessing)
	
	StandardProcessing = False;
	MakeChoice_();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Selection(Command)
	
	MakeChoice_();
	
EndProcedure

#EndRegion

#Region Private

&AtClient
Procedure MakeChoice_()
	
	CurrentData = Items.GeographicRegions.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	Result = New Structure("GeographicRegionValue, GeographicRegionName",
		CurrentData.GeographicRegionValue, CurrentData.GeographicRegionName);
	
	NotifyChoice(Result);
	
EndProcedure

&AtServer
Procedure LoadGeoMapItems()
	
	ChooseCities = False; // Cities will be selected only for the map of Russian regions with all cities
	If GeoDiagram.Layers.Find("States Russia_") <> Undefined
		And GeoDiagram.Layers.Find("Cities") <> Undefined Then
		Cities = GeoDiagram.Layers.Cities;
		Capital = Cities.Series.Capital; // GeographicalSchemaLayerDataSeries
		NotCapitals = Cities.SelectObjects(New Structure(Capital.Name, False));
		If NotCapitals.Count() Then
			ChooseCities = True;
			MatchingRegionsToCities = New Map;
		EndIf;
	EndIf;
	
	ListOfRegions = New ValueList;
	
	Layer = GeoDiagram.Layers[0];
	
	ThereIsSeriesTitle = False;
	SeriesName = Layer.Series.Find("Name1");
	If SeriesName <> Undefined Then
		ThereIsSeriesTitle = True;
	EndIf;
	
	For Each Object In Layer.Objects Do
		
		If ThereIsSeriesTitle Then
			NameOfObject = Layer.GetValue(Object, SeriesName);
			NewRegion = ListOfRegions.Add(Object.Value, NameOfObject.Value);
		Else
			NewRegion = ListOfRegions.Add(Object.Value, Object.Value);
		EndIf;

		If ChooseCities Then
			ThereIsSeriesNameOfCity = False;
			SeriesCityName = Cities.Series.Find("Name1");
			If SeriesCityName <> Undefined Then
				ThereIsSeriesNameOfCity = True;
			EndIf;
			
			ListOfCities = New ValueList;
			COD_CLADR_REGION = Cities.Series.COD_CLADR_REGION; // GeographicalSchemaLayerDataSeries
			CitiesInRegion = Cities.SelectObjects(New Structure(COD_CLADR_REGION.Name, Object.Value));
			For Each CityOfRegion In CitiesInRegion Do
				If ThereIsSeriesNameOfCity Then
					CityName = Cities.GetValue(CityOfRegion, SeriesCityName);
					ListOfCities.Add(CityOfRegion.Value, CityName.Value);
				Else
					ListOfCities.Add(CityOfRegion.Value, CityOfRegion.Value);
				EndIf;
			EndDo;
			ListOfCities.SortByPresentation();
			MatchingRegionsToCities.Insert(NewRegion.GetID(), ListOfCities);
		EndIf;
		
	EndDo;
	
	ListOfRegions.SortByPresentation();
	
	ElementsRegion = GeographicRegions.GetItems();
	LineID = 0;
	
	For Each State In ListOfRegions Do
		RegionElement = ElementsRegion.Add();
		RegionElement.GeographicRegionValue = State.Value;
		RegionElement.GeographicRegionName = State.Presentation;
		If CurrentRegionValue <> Undefined
			And State.Value = CurrentRegionValue Then // let's remember for further positioning of the line
			LineID = RegionElement.GetID();
		EndIf;
		If ChooseCities Then
			CityElements = RegionElement.GetItems();
			ListOfCities = MatchingRegionsToCities.Get(State.GetID());
			For Each City In ListOfCities Do
				CityElement = CityElements.Add();
				CityElement.GeographicRegionValue = City.Value;
				CityElement.GeographicRegionName = City.Presentation;
				If CurrentRegionValue <> Undefined
					And City.Value = CurrentRegionValue Then // let's remember for further positioning of the line
					LineID = CityElement.GetID();
				EndIf;
			EndDo;
		EndIf;
	EndDo;
	
	Items.GeographicRegions.CurrentRow = LineID;
	
EndProcedure

#EndRegion