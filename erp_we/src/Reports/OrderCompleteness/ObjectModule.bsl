#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	// The selection for resources is duplicated from rows to columns (for a cross-table) and to subordinate groupings
	// It is used for the selection of "Only problematic positions"
	For Each StructureItem In SettingsComposer.Settings.Structure Do
		If TypeOf(StructureItem) = Type("DataCompositionTable") Then
			
			FilterInStrings = Undefined;
			For Each String In StructureItem.Rows Do
				For Each Item In String.Filter.Items Do
					If Not IsBlankString(Item.UserSettingID) Then
						UserSetting = SettingsComposer.UserSettings.Items.Find(
							Item.UserSettingID);
						If UserSetting <> Undefined
							And UserSetting.Use Then
							Field = SettingsComposer.Settings.SelectionAvailableFields.Items.Find(Item.LeftValue);
							If Field <> Undefined And Field.Resource Then
								FilterInStrings = Item;
								Break;
							EndIf;
						EndIf;
					EndIf;
				EndDo;
			EndDo;
			
			If FilterInStrings <> Undefined Then
				For Each Column In StructureItem.Columns Do  
					For Each FilterElement In Column.Filter.Items Do
						If FilterElement.LeftValue = FilterInStrings.LeftValue And FilterElement.ComparisonType = FilterInStrings.ComparisonType Then
							Column.Filter.Items.Delete(FilterElement);
						EndIf;
					EndDo;
					Item = Column.Filter.Items.Add(Type("DataCompositionFilterItem"));
					FillPropertyValues(Item, FilterInStrings, "LeftValue, RightValue, ComparisonType");
					Item.Use = True;
					Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
				EndDo;        
			Else
				For Each Column In StructureItem.Columns Do 
					For Each Item In Column.Filter.Items Do
						Field = SettingsComposer.Settings.SelectionAvailableFields.Items.Find(Item.LeftValue);
						If Field <> Undefined And Field.Resource Then
							Item.Use = False;
							Break;
						EndIf;						
					EndDo;
				EndDo;
			EndIf;			
				
		ElsIf TypeOf(StructureItem) = Type("DataCompositionGroup") Then
			
			FilterGroups = Undefined;
			Queue = New Array;
			For Each Item In StructureItem.Filter.Items Do
				If Not IsBlankString(Item.UserSettingID) Then
					UserSetting = SettingsComposer.UserSettings.Items.Find(
						Item.UserSettingID);
					If UserSetting <> Undefined
						And UserSetting.Use Then
						Field = SettingsComposer.Settings.SelectionAvailableFields.Items.Find(Item.LeftValue);
						If Field <> Undefined And Field.Resource Then
							FilterGroups = Item;
							Queue.Add(StructureItem.Structure);
							Break;
						EndIf;
					EndIf;
				EndIf;
			EndDo;
			
			If FilterGroups <> Undefined Then
				IndexOf = 0;
				While IndexOf <= Queue.UBound() Do
					For Each Group In Queue[IndexOf] Do
						Filter = Group.Filter; //DataCompositionFilter
						Item = Filter.Items.Add(Type("DataCompositionFilterItem"));
						FillPropertyValues(Item, FilterGroups, "LeftValue, RightValue, ComparisonType");
						Item.Use = True;
						Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
						
						Queue.Add(Group.Structure);
					EndDo;
					IndexOf = IndexOf + 1;
				EndDo;
			EndIf;
			
		EndIf;
	EndDo;
	
	// Additional selection for the "Key batch" if the selection for the document Stage is set
	For Each Item In SettingsComposer.Settings.Filter.Items Do
		If TypeOf(Item) = Type("DataCompositionFilterItem")
			And Item.Use Then
			If Item.LeftValue = New DataCompositionField("Stage")
				And Item.ComparisonType = DataCompositionComparisonType.Equal
				And TypeOf(Item.RightValue) = Type("DocumentRef.ProductionStage2_2") Then
				
				KeySelectionElement = Undefined;
				
				For Each FilterElement In SettingsComposer.Settings.Filter.Items Do
				
					If TypeOf(FilterElement) = Type("DataCompositionFilterItem")
					   And FilterElement.LeftValue = New DataCompositionField("KeyLot") Then
					
						KeySelectionElement = FilterElement;
						Break;
					
					EndIf;	
				
				EndDo;
				
				If KeySelectionElement = Undefined Then
					KeySelectionElement = SettingsComposer.Settings.Filter.Items.Add(Type("DataCompositionFilterItem"));
				EndIf;
				
				KeySelectionElement.LeftValue = New DataCompositionField("KeyLot");
				KeySelectionElement.ComparisonType = DataCompositionComparisonType.Equal;
				KeySelectionElement.RightValue = Common.ObjectAttributeValue(
					Item.RightValue, "ProductionLot").UUID();
				KeySelectionElement.Use = True;
				KeySelectionElement.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
				KeySelectionElement.Presentation = StrTemplate(NStr("vi = 'Công đoạn ""%1""';
																	|ru = 'Этап ""%1""';
																	|en = 'Stage ""%1""'; fa = 'Stage ""%1""';
																	|it = 'Fase ""%1""';
																	|pl = 'Etap: ""%1""';
																	|tr = '""%1"" aşaması'"),
					Documents.ProductionStage2_2.PresentationStage(Item.RightValue));
				
				Item.Use = False;
				
				Break;
			ElsIf Item.LeftValue = New DataCompositionField("KeyLot") Then
				Item.Presentation = NStr("vi = 'Đặt lọc theo lô hàng';
										|ru = 'Установлен отбор по партии';
										|en = 'Filter by lot is set'; fa = 'Filter by lot is set';
										|it = 'Filter by lot is set';
										|pl = 'Filter by lot is set';
										|tr = 'Lota göre filtre ayarlandı'");
			EndIf;
		EndIf;
	EndDo;
	
	// Disabling the fields of transcription of movements in case the movements are not used
	If SettingsComposer.Settings.AdditionalProperties.Property("VariantKey")
		And SettingsComposer.Settings.AdditionalProperties.VariantKey = "BySourcesAndDatesContext" Then
		
		// Checking for movements
		TemplateComposer = New DataCompositionTemplateComposer;
		CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, SettingsComposer.GetSettings());
		Query = DataCompositionServer.GETRequestFromLayoutTemplate(CompositionTemplate, "DataSet");
		
		TablesNames = StrSplit("Demand,ProductsAndWarehousesForCalculatingMovements,Transfers", ",");
		
		QuerySchema = New QuerySchema;
		QuerySchema.SetQueryText(Query.Text);
		For IndexOf = -QuerySchema.QueryBatch.Count()+1 To 0 Do
			SchemaRequest = QuerySchema.QueryBatch[-IndexOf];
			If IsBlankString(SchemaRequest.PlacementTable)
				Or TablesNames.Find(SchemaRequest.PlacementTable) = Undefined Then
				QuerySchema.QueryBatch.Delete(-IndexOf);
			EndIf;
		EndDo;
		
		If QuerySchema.QueryBatch.Count() > 0 Then
			Query.Text = QuerySchema.GetQueryText();
			Query.SetParameter("CurrentDate", BegOfDay(CurrentSessionDate()));
			Query.SetParameter("TheProductionScheduleIsUsed", 
				ProductionManagementCached.TheProductionScheduleIsUsed());
			Selection = Query.Execute().Select();
			Selection.Next();
			If Selection.Count = 0 Then
				
				// Disabling fields
				MovingFields = New Array;
				MovingFields.Add(New DataCompositionField("WarehouseRelocation"));
				MovingFields.Add(New DataCompositionField("DateOfReceiptTransfer"));
				MovingFields.Add(New DataCompositionField("SourceOfProvisionMoving"));
				
				Queue = New Array;
				Queue.Add(SettingsComposer.Settings.Structure);
				
				IndexOf = 0;
				While IndexOf <= Queue.UBound() Do
					For Each Group In Queue[IndexOf] Do
						If TypeOf(Group) = Type("DataCompositionGroup") Then
							For Each SelectedField In Group.Selection.Items Do
								If TypeOf(SelectedField) = Type("DataCompositionSelectedField")
									And MovingFields.Find(SelectedField.Field) <> Undefined Then
									SelectedField.Use = False;
								EndIf;
							EndDo;
							
							Queue.Add(Group.Structure);
						EndIf;
					EndDo;
					IndexOf = IndexOf + 1;
				EndDo;
				
			EndIf;
		EndIf;
	EndIf;
	
	DataSet = DataCompositionSchema.DataSets.Find("DataSet");
	
	QueryText = DataSet.Query;
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	DataSet.Query = QueryText;
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	Settings.Events.OnCreateAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Passed from the handler parameters "as is".
//
// See also:
//   "formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	// Additional command
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionOrder2_2") Then
	
		If Not Common.ObjectAttributeValue(Parameters.CommandParameter, "DynamicStructure") Then
			
			Common.MessageToUser(NStr("vi = 'Báo cáo này chỉ áp dụng đối với các đơn hàng có sử dụng cấu trúc động.';
										|ru = 'Данный отчет применим только к заказам с включенной динамической структурой.';
										|en = 'This report is applicable only to orders with enabled dynamic structure.'; fa = 'This report is applicable only to orders with enabled dynamic structure.';
										|it = 'Questo report è applicabile solo agli ordini con la struttura dinamica abilitata.';
										|pl = 'Niniejszy raport ma zastosowanie tylko do zamówień z włączoną strukturą dynamiczną.';
										|tr = 'Bu rapor sadece dinamik yapısı etkinleştirilmiş siparişler için geçerlidir.'"));
			Cancel = True;
			Return;
			
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("ProductionOrder", Parameters.CommandParameter);
	
	ElsIf Parameters.Property("CommandParameter")
		And TypeOf(Parameters.CommandParameter) = Type("CatalogRef.Products") Then
		
		ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
		
	ElsIf Parameters.Property("CommandParameter")
		And TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionStage2_2") Then
		
		If Not Common.ObjectAttributeValue(Parameters.CommandParameter, "DynamicStructure") Then
			
			Common.MessageToUser(NStr("vi = 'Báo cáo này chỉ áp dụng đối với các công đoạn sản xuất có sử dụng cấu trúc động.';
										|ru = 'Данный отчет применим только к этапам производства с включенной динамической структурой.';
										|en = 'This report is applicable only to stages with enabled dynamic structure.'; fa = 'This report is applicable only to stages with enabled dynamic structure.';
										|it = 'This report is applicable only to stages with enabled dynamic structure.';
										|pl = 'This report is applicable only to stages with enabled dynamic structure.';
										|tr = 'Bu rapor yalnızca dinamik yapısı etkinleştirilmiş üretim aşamaları için geçerlidir.'"));
			Cancel = True;
			Return;
			
		EndIf;
		
		ThisForm.ParametersForm.Filter.Insert("Stage", Parameters.CommandParameter);
		
	EndIf;
	
	If ThisForm.Parameters.Property("VariantKey")
		And (ThisForm.Parameters.VariantKey = "RemainingGoodsByShelfLives"
			Or ThisForm.Parameters.VariantKey = "ByOrder") Then
		
		Filters = ThisForm.ParametersForm.Filter; //Structure
		Filters.Delete("Warehouse");
		Filters.Delete("Purpose");
		
	EndIf;
	
	If Parameters.Property("KeyLot")
		And TypeOf(Parameters.KeyLot) = Type("UUID") Then
		Filter = GetAnalyticsForSelection(Parameters.KeyLot);
		
		Parameters.Filter.Insert("Products", Filter.Products);
		Parameters.Filter.Insert("Characteristic", Filter.Characteristic);
		Parameters.Filter.Insert("Warehouse", Filter.Warehouse);
		Parameters.Filter.Insert("Purpose", Filter.Purpose);
	EndIf;
	
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Form - ClientApplicationForm - The report Form consists of:
//   *Parameters - FormDataStructure - consists of:
//    **EndDate - Date -
//   NewDCUserSettings - DataCompositionUserSettings -
//       Custom settings to upload to the Settings Composer.
//
// See Syntax Assistant "Managed Form Extension for the report.Prizagruzkepusersing settings in the server"
//    in the syntax assistant.
//
Procedure OnLoadUserSettingsAtServer(Form, NewDCUserSettings) Export
	
	If Form.Parameters.Property("EndDate") Then
		DataCompositionClientServer.SetParameter(
			SettingsComposer,
			"EndDate",
			Form.Parameters.EndDate,
			ValueIsFilled(Form.Parameters.EndDate));
		NewDCUserSettings = SettingsComposer.GetSettings();
	EndIf;
	
EndProcedure
#EndRegion

#Region Private

Function GetAnalyticsForSelection(KeyLot)
	
	Query = New Query("
	|SELECT 
	|	RegisterRecords.Products,
	|	RegisterRecords.Characteristic,
	|	RegisterRecords.Warehouse,
	|	RegisterRecords.Purpose
	|FROM
	|	InformationRegister.OrderStructure AS RegisterRecords
	|WHERE
	|	RegisterRecords.KeyLot = &KeyLot
	|	AND RegisterRecords.LineKind = VALUE(Enum.KindsOfProductionOrderStructureLines.Consumption)");
	
	Query.SetParameter("KeyLot", KeyLot);
	Result = Query.Execute().Select();
	Result.Next();
	
	Return New Structure("Products,Characteristic,Warehouse,Purpose",
					Result.Products,
					Result.Characteristic,
					Result.Warehouse,
					Result.Purpose);
EndFunction

#EndRegion

#EndIf
