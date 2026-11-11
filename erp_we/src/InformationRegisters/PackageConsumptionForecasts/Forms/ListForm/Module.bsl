
#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	SetConditionalAppearance();
	If Parameters.Property("AutoTest_2") Then // Refund upon receipt of the form for analysis.
		Return;
	EndIf;
	
	If Parameters.Property("Products") Then
		FilterProducts = Parameters.Products;
	EndIf;
	
	QueryText = List.QueryText;
	QueryText = StrReplace(QueryText,
								"&QueryTextPackagingFactor",
								Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
									"ForecastsOverridable.Package",
									"ForecastsOverridable.Products"));
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.QueryText					= QueryText;
	ListProperties.MainTable				= "InformationRegister.PackageConsumptionForecasts";
	ListProperties.DynamicDataRead	= True;
	
	Common.SetDynamicListProperties(Items.List, ListProperties);
	
	StandardStockLevel = "All";
	
	SetFilters();
	
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If ValueIsFilled(Warehouse) And Common.ObjectAttributeValue(Warehouse, "IsFolder") Then
		Warehouse = Undefined;
	EndIf;
	SetFilters();
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure WarehouseOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure PremiseOnChange(Item)
	SetFilters();
EndProcedure

&AtClient
Procedure TheStandardAmountOfTheStockIs1WhenChanging(Item)
	SetFilters();
EndProcedure

#EndRegion

#Region FormCommandsEventHandlers

&AtClient
Procedure UseRecommendedStandardInventoryQuantity(Command)
	RecordsArray = Items.List.SelectedRows;
	
	If RecordsArray.Count() = 0 Then
		MessageText = NStr("vi = 'Hãy chọn ra các dòng, trong đó cần thiết lập việc sử dụng vật tư định mức khuyến cáo.';
							|ru = 'Выделите строки, в которых нужно установить использование рекомендуемого нормативного запаса.';
							|en = 'Select rows in which use of recommended standard inventory level shall be set.'; fa = 'Select rows in which use of recommended standard inventory level shall be set.';
							|it = 'Evidenzia le linee in cui vuoi stabilire l''uso del margine standard raccomandato.';
							|pl = 'Zaznacz wierszy, w których chcesz zaznaczyć użycie zalecanego normatywnego rezerwy.';
							|tr = 'Önerilen standart stok kullanımını ayarlamak istediğiniz satırlarda seçin.'");
		ShowMessageBox(Undefined, MessageText);
		Return;
	Else
		QueryText = NStr("vi = 'Khi thực hiện giao dịch tại các dòng đã chọn sẽ xóa số lượng vật tư định mức được ấn định thủ công. Tiếp tục?';
						|ru = 'При выполнении операции в выделенных строках будет очищено нормативное количество запаса, назначенное вручную. Продолжить?';
						|en = 'Standard inventory specified manually will be cleared in the selected lines while executing the operation. Continue?'; fa = 'Standard inventory specified manually will be cleared in the selected lines while executing the operation. Continue?';
						|it = 'Quando si esegue un''operazione nelle righe selezionate, l''importo standard della riserva, assegnato manualmente, verrà cancellato. Continuare?';
						|pl = 'Podczas wykonywania operacji w wybranych wierszach normatywna ilość rezerwy, podana ręcznie, zostanie wyczyszczona. Kontynuować?';
						|tr = 'Seçilen satırlar üzerinde işlem yapıldığında manuel olarak atanan standart stok miktarı silinecektir. Devam edilsin mi?'");
		Response = Undefined;

		ShowQueryBox(New CallbackDescription("UseRecommendedStandardInventoryQuantityCompletion", ThisObject, New Structure("RecordsArray", RecordsArray)), QueryText,QuestionDialogMode.YesNo);
        Return;
	EndIf;
	
	UseRecommendedStandardInventoryQuantityServer(RecordsArray);
EndProcedure

&AtClient
Procedure UseRecommendedStandardInventoryQuantityCompletion(QuestionResult, AdditionalParameters) Export
    
    RecordsArray = AdditionalParameters.RecordsArray;
    
    
    Response = QuestionResult;
    
    If Response <> DialogReturnCode.Yes Then
        Return;
    EndIf;
    
    UseRecommendedStandardInventoryQuantityServer(RecordsArray);

EndProcedure

#EndRegion

#Region Private

&AtServer
Procedure SetConditionalAppearance()

	ConditionalAppearance.Items.Clear();

	//

	Item = ConditionalAppearance.Items.Add();

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Products.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Characteristic.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Series.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.Package.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardStockLevel.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.StandardStockQuantityRecommended.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShipmentProbabilityWithinDay.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.ShipmentProbabilityWithinDay.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.AverageDailyConsumption.Name);

	ItemField = Item.Fields.Items.Add();
	ItemField.Field = New DataCompositionField(Items.RootMeanSquareVariance.Name);

	ItemFilter = Item.Filter.Items.Add(Type("DataCompositionFilterItem"));
	ItemFilter.LeftValue = New DataCompositionField("List.ParticipatesInTheRecharge");
	ItemFilter.ComparisonType = DataCompositionComparisonType.Equal;
	ItemFilter.RightValue = False;

	Item.Appearance.SetParameterValue("TextColor", StyleColors.TextColorOfCanceledRowOfDocument);

EndProcedure

#Region OnChangeAttributes

&AtServer
Procedure SetFilters()
	
	OnlyValuesAssignedManually = (StandardStockLevel = "ManuallyAssigned");
	
	CommonClientServer.SetDynamicListFilterItem(List, "Premise", Premise, DataCompositionComparisonType.Equal,, True, DataCompositionSettingsItemViewMode.Inaccessible);
	CommonClientServer.SetDynamicListFilterItem(List, "Warehouse", Warehouse, DataCompositionComparisonType.Equal,, True, DataCompositionSettingsItemViewMode.Inaccessible);
	CommonClientServer.SetDynamicListFilterItem(List, "AssignedByUser", OnlyValuesAssignedManually, DataCompositionComparisonType.Equal,, OnlyValuesAssignedManually, DataCompositionSettingsItemViewMode.Inaccessible);
	
	If ValueIsFilled(FilterProducts) Then
		
		CommonClientServer.SetDynamicListFilterItem(List, "Products", FilterProducts,
			DataCompositionComparisonType.Equal,
			,
			True,
			DataCompositionSettingsItemViewMode.Inaccessible);
		
	EndIf;
	
	SetFormFunctionalOptionParameters(New Structure("Warehouse", Warehouse));
	
	If WarehousesServer.ForecastPackageConsumption(Warehouse, Premise) Then
		Items.DecorationUsePackagingConsumptionForecast.Title = "";
		Items.List.ChangeRowSet = True;
	ElsIf ValueIsFilled(Warehouse)
		And Not WarehousesServer.UseWarerooms(Warehouse,,False)
		Or ValueIsFilled(Premise) Then
		
		TitleText = NStr("vi = 'Tại kho ""%Warehouse%"", không sử dụng dự báo mức tiêu thụ đóng gói.';
						|ru = 'На складе ""%Warehouse%"" не используется прогнозирование расхода упаковок.';
						|en = 'Packaging units consumption is not forecasted in the ""%Warehouse%"" warehouse.'; fa = 'Packaging units consumption is not forecasted in the ""%Warehouse%"" warehouse.';
						|it = 'Nel magazzino ""%Warehouse%"" la previsione del consumo di imballaggio non viene utilizzata.';
						|pl = 'W magazynie ""%Warehouse%"" nie jest stosowane prognozowanie zużycia opakowań.';
						|tr = 'Ambarda ""%Warehouse%"", paketleme ünitesi gider tahminini kullanılmıyor.'");
		TitleText = StrReplace(TitleText, "%Warehouse%", WarehousesServer.GetWarehousePresentation(Warehouse, Premise));
		
		Items.DecorationUsePackagingConsumptionForecast.Title = TitleText;
		Items.List.ChangeRowSet = False;
	Else
		Items.DecorationUsePackagingConsumptionForecast.Title = "";
		Items.List.ChangeRowSet = False;
	EndIf;
		
EndProcedure

&AtServer
Procedure UseRecommendedStandardInventoryQuantityServer(RecordsArray)
	
	For Each ArrRow In RecordsArray Do
		If TypeOf(ArrRow) <> Type("InformationRegisterRecordKey.PackageConsumptionForecasts")
			Then
			Continue;
		EndIf;
		
		Set = InformationRegisters.PackageConsumptionForecasts.CreateRecordSet();
		Set.Filter.Warehouse.Set(ArrRow.Warehouse);
		Set.Filter.Premise.Set(ArrRow.Premise);
		Set.Filter.Products.Set(ArrRow.Products);
		Set.Filter.Characteristic.Set(ArrRow.Characteristic);
		Set.Filter.Series.Set(ArrRow.Series);
		Set.Filter.Package.Set(ArrRow.Package);
		
		Set.Read();
		
		If Set.Count() > 0 Then
			If Not Set[0].AssignedByUser Then
				Continue;
			EndIf;
		Else
			Continue;
		EndIf;
		
		NewRow = Set[0];
		NewRow.AssignedByUser      = False;
		NewRow.StandardStockLevel = 0;
		
		Set.Write();
	EndDo;
	
	Items.List.Refresh();
EndProcedure

#EndRegion

#EndRegion
