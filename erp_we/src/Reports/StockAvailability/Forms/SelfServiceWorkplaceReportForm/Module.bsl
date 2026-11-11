#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	NameOfDimensionToDisable = ?(GetFunctionalOption("UseGoodsQualityControl"),
		"QualityControlIsDisabled",
		"QualityControl_Enabled");
		
	SettingsStructure = Report.SettingsComposer.Settings.Structure;
	For Each StructureItem In SettingsStructure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			
			For Each LayoutStringInfo In StructureItem.Rows Do
				If TypeOf(LayoutStringInfo) = Type("DataCompositionTableGroup") Then
					If LayoutStringInfo.Name = NameOfDimensionToDisable Then
						StructureItem.Rows.Delete(LayoutStringInfo);
					EndIf;
				EndIf;
			EndDo;
			For Each LayoutColumn In StructureItem.Columns Do
				If TypeOf(LayoutColumn) = Type("DataCompositionTableGroup") Then
					If LayoutColumn.Name = NameOfDimensionToDisable Then
						StructureItem.Columns.Delete(LayoutColumn);
					EndIf;
				EndIf;
			EndDo;
			
		ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			
			If StructureItem.Name = NameOfDimensionToDisable Then
				SettingsStructure.Items.Delete(StructureItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	AvailabilityByDates = True;
	AvailabilityByDateWhenChangedWithoutContext(Report.SettingsComposer, AvailabilityByDates);
	
	If Parameters.Property("Filter") And Parameters.Filter.Property("Warehouse") Then
		
		If TypeOf(Parameters.Filter.Warehouse) = Type("CatalogRef.Warehouses") Then
			Items.Warehouse.ChoiceList.Add(Parameters.Filter.Warehouse);
			Warehouse = Parameters.Filter.Warehouse;
			Items.Warehouse.Enabled = False;
		Else
			Items.Warehouse.ChoiceList.LoadValues(Parameters.Filter.Warehouse.UnloadValues());
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region FormHeaderItemsEventHandlers

&AtClient
Procedure ResultDetailProcessing(Item, Details, StandardProcessing)
	
	StandardProcessing = False;
	
EndProcedure

&AtClient
Procedure WarehouseOnChange(Item)
	
	WarehouseOnChangeServer();
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure SKUOnChange(Item)
	
	FilterItems1 = Report.SettingsComposer.FixedSettings.Filter;
	If IsBlankString(SKU) Then
		CommonClientServer.SetFilterItem(FilterItems1, "Products.SKU", "", ,,False);
	Else
		CommonClientServer.SetFilterItem(FilterItems1, "Products.SKU", SKU,DataCompositionComparisonType.Contains , , True);
	EndIf;
	
	SetStateReportNotGenerated();
	
EndProcedure

&AtClient
Procedure AvailabilityByDatesOnChange(Item)
	
	AvailabilityByDateWhenChangedWithoutContext(Report.SettingsComposer, AvailabilityByDates);
	SetStateReportNotGenerated();
	
EndProcedure

#EndRegion

#Region Private

&AtClientAtServerNoContext
Procedure AvailabilityByDateWhenChangedWithoutContext(Composer, AvailabilityByDates)
	
	For Each SettingsTable In Composer.Settings.Structure Do
		If TypeOf(SettingsTable) = Type("DataCompositionTable") Then
		For Each SettingsItem In SettingsTable.Columns Do
			
			FoundGrouping = FindGroupingRecursively(SettingsItem, "DateOfAvailabilityForSelfService");
			If FoundGrouping <> Undefined Then
				
				SettingID = FoundGrouping.UserSettingID;
				UserSetting = Composer.UserSettings.Items.Find(SettingID);
				If UserSetting <> Undefined Then
					UserSetting.Use = AvailabilityByDates;
				EndIf;
				
			EndIf;
			
			FoundGrouping = FindGroupingRecursively(SettingsItem, "QualityControlAvailabilityDate");
			If FoundGrouping <> Undefined Then
				
				SettingID = FoundGrouping.UserSettingID;
				UserSetting = Composer.UserSettings.Items.Find(SettingID);
				If UserSetting <> Undefined Then
					UserSetting.Use = AvailabilityByDates;
				EndIf;
				
			EndIf;
			
		EndDo;
		EndIf;
	EndDo;
	
EndProcedure

&AtClientAtServerNoContext
Function FindGroupingRecursively(SettingsItem, GroupName)
	
	If TypeOf(SettingsItem) = Type("DataCompositionTableGroup") Then
		
		If SettingsItem.Name = "DateOfAvailabilityForSelfService" Then
			Return SettingsItem;
		Else
			For Each Item In SettingsItem.Structure Do
				
				FoundGrouping = FindGroupingRecursively(Item, GroupName);
				If FoundGrouping <> Undefined Then
					Return FoundGrouping;
				EndIf;
				
			EndDo;
			Return Undefined;
		EndIf;
		
	EndIf;
	
	Return Undefined;
	
EndFunction

&AtServer
Procedure WarehouseOnChangeServer()

	FilterItems1 = Report.SettingsComposer.FixedSettings.Filter;
	FilterList = New ValueList;
	ArrayOfAvailableWarehouses = Items.Warehouse.ChoiceList.UnloadValues();
	
	If Not ValueIsFilled(Warehouse) Then
		
		FilterList.LoadValues(ArrayOfAvailableWarehouses);
		
	Else
		
		Query = New Query;
		Query.Text = "SELECT ALLOWED
		|	Warehouses.Ref AS Warehouse
		|FROM
		|	Catalog.Warehouses AS Warehouses
		|WHERE
		|	Warehouses.Ref IN HIERARCHY(&SelectedWarehouse)
		|	AND Warehouses.Ref IN(&AvailableWarehouses)";
		
		Query.SetParameter("AvailableWarehouses",ArrayOfAvailableWarehouses);
		Query.SetParameter("SelectedWarehouse",Warehouse);
		
		FilterList.LoadValues(Query.Execute().Unload().UnloadColumn("Warehouse"));
		
	EndIf;
	
	CommonClientServer.SetFilterItem(FilterItems1, "Warehouse", FilterList);
	
EndProcedure

&AtClient
Procedure SetStateReportNotGenerated()
	
	Items.Result.StatePresentation.AdditionalShowMode = AdditionalShowMode.Irrelevance;
	Items.Result.StatePresentation.Text = NStr("vi = 'Chưa lập báo cáo. Hãy nhấn nút ""Lập báo cáo"" để nhận báo cáo.';
												|ru = 'Отчет не сформирован. Нажмите ""Сформировать"" для получения отчета.';
												|en = 'Report is not generated. To generate the report, click ""Generate"".'; fa = 'Report is not generated. To generate the report, click ""Generate"".';
												|it = 'Il report non è stato creato. Fate clic su ""Crea"" per ricevere il rapporto.';
												|pl = 'Raport nie został wygenerowany. Kliknij ""Utwórz"", aby wygenerować raport.';
												|tr = 'Rapor oluşturulmadı. Raporu oluşturmak için ""Oluştur"" butonuna tıklayın.'");
	Items.Result.StatePresentation.Visible = True;
	
EndProcedure

#EndRegion
