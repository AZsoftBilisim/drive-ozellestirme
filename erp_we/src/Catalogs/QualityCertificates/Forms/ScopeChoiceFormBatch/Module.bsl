
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Parameters.Property("AutoTest_2") Then
		Return;
	EndIf;

	SeriesDisplayMode = "AllSeries";
	Items.WarehouseSelection.Enabled = False;
	Items.RoomSelection_.Enabled  = False;
	
	Parameters.Property("Products", NomenclatureSeriesSelection);
	FeatureSelection = Parameters.Characteristic;
	ProductKind = Parameters.ProductKind;	
	If Not Parameters.ItemVariantsAreUsed Then
		FeatureSelectionLabel = NStr("vi = '<không sử dụng>';
									|ru = '<не используется>';
									|en = '<not used>'; fa = '<استفاده نمی‌شود>';
									|it = '<non viene utilizzato>';
									|pl = '<nie używa się>';
									|tr = '<kullanılmayan>'");
	ElsIf ValueIsFilled(FeatureSelection) Then
		FeatureSelectionLabel = FeatureSelection;
	EndIf;
	
	SetListOfWarehousesWithSeries(ProductKind);	
	
	TemplateParameters = New FixedStructure(Catalogs.ItemKinds.SeriesUseSettings(ProductKind));
	
	Items.ListOfEpisodesValidUntilAllEpisodes.Visible         = TemplateParameters.UseShelfLifeOnBatchRegistration;
	Items.TheListOfSeriesIsValidUntilOnlyWithLeftovers.Visible = TemplateParameters.UseShelfLifeOnBatchRegistration;
	Items.ListOfSeriesNumberAllSeries.Visible 		  = TemplateParameters.SpecifyNumberWhenRegisteringBatch;
	Items.ListOfSeriesNumberOnlyWithLeftovers.Visible   = TemplateParameters.SpecifyNumberWhenRegisteringBatch;
	
	ExecuteRequestToFillInSeriesTable();
	
	FreeBalanceHeader = NStr("vi = 'Số dư tự do, %UnitOfMeasure%';
							|ru = 'Свободный остаток, %UnitOfMeasure%';
							|en = 'Available inventory, %UnitOfMeasure%'; fa = 'Available inventory, %UnitOfMeasure%';
							|it = 'Saldo libero, %UnitOfMeasure%';
							|pl = 'Wolny ostatek, %UnitOfMeasure%';
							|tr = 'Serbest bakiye, %UnitOfMeasure%'");
	UnitOfMeasurePresentation = Common.ObjectAttributeValue(NomenclatureSeriesSelection,"UnitOfMeasure");
	FreeBalanceHeader = StrReplace(FreeBalanceHeader,
		"%UnitOfMeasure%",
		UnitOfMeasurePresentation);
	Items.TheListOfSeriesAvailableFundsOnlyWithTheRemnants.Title = FreeBalanceHeader;

	FormEvents.OnCreateAtServer(ThisForm, Cancel, StandardProcessing);

EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure SeriesDisplayModeOnChange(Item)
	
	SetAvailabilityOfElementsFromSeriesDisplayMode();
	
	If SeriesDisplayMode = "AllSeries" Then
		Items.ListPages.CurrentPage = Items.SeriesListAllSeriesPage;
	Else
		Items.ListPages.CurrentPage = Items.PageListOfEpisodesWithLeftoversOnly;
	EndIf;

	DisplayModeOfSeriesWhenChangingOnServer();	
		
EndProcedure

&AtClient
Procedure WarehouseSelectionOnChange(Item)
	FoldingWhenChangingOnServer();	
EndProcedure

&AtClient
Procedure RoomSelection_OnChange(Item)
	
	ExecuteRequestToFillInSeriesTable();
	
EndProcedure

#EndRegion

#Region FormTableItemsEventHandlersSeriesList
 
&AtClient
Procedure ListOfSeriesSelection(Item, RowSelected, Field, StandardProcessing)
	
	StandardProcessing = False;
	ChooseValue();
	
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure Select(Command)
	
	ChooseValue();
	
EndProcedure

&AtClient
Procedure Attachable_ExecuteOverridableCommand(Command)
	
	FormEventsClient.ExecuteOverridableCommand(ThisForm, Command);
	
EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure DisplayModeOfSeriesWhenChangingOnServer()	
	SetVisibilityOfPremises();	
	ExecuteRequestToFillInSeriesTable();
EndProcedure

&AtServer
Procedure FoldingWhenChangingOnServer()	
	SetVisibilityOfPremises();
	ExecuteRequestToFillInSeriesTable();
EndProcedure

&AtClient
Procedure ChooseValue()
	
	If SeriesDisplayMode = "AllSeries" Then
		If Items.SeriesListAllSeries.CurrentData <> Undefined Then
			NotifyChoice(Items.SeriesListAllSeries.CurrentData.Series);
		EndIf;	
	Else
		 If Items.ListOfSeriesOnlyWithBalance.CurrentData <> Undefined Then
			NotifyChoice(Items.ListOfSeriesOnlyWithBalance.CurrentData.Series);
		EndIf;	
	EndIf;

EndProcedure

&AtServer
Procedure SetListOfWarehousesWithSeries(ProductKind)
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	TypesOfProductPolicyAccountingSeries.Warehouse
	|FROM
	|	Catalog.ItemKinds.BatchAccountingPolicies AS TypesOfProductPolicyAccountingSeries
	|WHERE
	|	TypesOfProductPolicyAccountingSeries.Ref = &ProductKind";
	Query.SetParameter("ProductKind", ProductKind);
	
	WarehouseArray = Query.Execute().Unload().UnloadColumn("Warehouse");
	Items.WarehouseSelection.ChoiceList.LoadValues(WarehouseArray);
	
	If WarehouseArray.Count() = 1 Then
		WarehouseSelection = WarehouseArray[0];
	EndIf;
	
	SetVisibilityOfPremises();
	
EndProcedure

&AtServer
Procedure ExecuteRequestToFillInSeriesTable()
					
	If SeriesDisplayMode = "OnlyBalance" Then
		OptionOfDataReceivingFromRegisters = "GoodsInWarehousesWithoutDestination";
		
		If ValueIsFilled(WarehouseSelection) Then
			If UseWarerooms	
				And Not ValueIsFilled(RoomSelection_) Then
				SeriesList.Clear();
				Return;	
			EndIf;	
		Else
			SeriesList.Clear();
			Return;
		EndIf;

	Else
		OptionOfDataReceivingFromRegisters = "AllSeriesProducts";
	EndIf;
	
	QueryText = DataProcessors.SelectBatchToDocuments.TextOfRequestToGenerateTableRegisterData(OptionOfDataReceivingFromRegisters);
	
	QueryText = QueryText + "
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|";
		
	QueryText = QueryText + 
	"SELECT
	|	DataOfRegister.Series,
	|	DataOfRegister.AvailableStock AS AvailableStock,
	|	0 AS Count,
	|	0 AS NumberOfPackages,
	|	CAST(DataOfRegister.Series AS Catalog.ItemsBatches).Number AS Number,
	|	CAST(DataOfRegister.Series AS Catalog.ItemsBatches).ValidUntil_ AS ValidUntil_
	|FROM
	|		DataOfRegister AS DataOfRegister
	|WHERE
	|	DataOfRegister.Series <> VALUE(Catalog.ItemsBatches.EmptyRef)
	|	AND (&AllSeries
	|		OR DataOfRegister.AvailableStock > 0)
	|
	|ORDER BY
	|	ValidUntil_,
	|	Number";
	
	Query = New Query;
	Query.Text = QueryText;
	
	Query.SetParameter("Products", NomenclatureSeriesSelection);
	Query.SetParameter("Characteristic", FeatureSelection);
	Query.SetParameter("Warehouse", WarehouseSelection);
	Query.SetParameter("Premise", RoomSelection_);
	Query.SetParameter("PackagingFactor", 1);
	Query.SetParameter("AllSeries", SeriesDisplayMode = "AllSeries");
	Query.SetParameter("RemainderSign", 1);
	
	SeriesList.Load(Query.Execute().Unload());
	
EndProcedure

&AtClient
Procedure SetAvailabilityOfElementsFromSeriesDisplayMode()
	
	If SeriesDisplayMode = "AllSeries" Then
		Items.WarehouseSelection.Enabled = False;
		Items.RoomSelection_.Enabled  = False;
	Else
		Items.WarehouseSelection.Enabled = True;
		Items.RoomSelection_.Enabled  = True;	
	EndIf;
	
EndProcedure

&AtServer
Procedure SetVisibilityOfPremises()
	
	UseWarerooms = WarehousesServer.UseWarerooms(WarehouseSelection,,False);
	Items.RoomSelection_.Visible = UseWarerooms;
	
EndProcedure

#EndRegion

