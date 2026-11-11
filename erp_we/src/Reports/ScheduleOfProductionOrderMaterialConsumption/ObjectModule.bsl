#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DisplayingOrder = DataCompositionClientServer.GetParameter(
		SettingsComposer.UserSettings,
		"DisplayingOrder");
	If TypeOf(DisplayingOrder) = Type("DataCompositionSettingsParameterValue") Then
		DisplayingOrder.Value = ?(DisplayingOrder.Value = Undefined, False, DisplayingOrder.Value);
	
		Table            = FindByName(SettingsComposer.Settings.Structure, "TableConsumptionOfMaterials");
		String             = ?(Table = Undefined, Undefined, FindStringRecursively(Table.Rows, "BasicGroupingOfRows"));
		Column            = ?(String = Undefined, Undefined, FindByName(String.Selection.Items, "ProductionOrder"));
		ColumnGrouping = ?(String = Undefined, Undefined, FindByName(String.GroupFields.Items, "ProductionOrder"));
		
		If ColumnGrouping = Undefined Or Column = Undefined Then
			Return
		EndIf;
		
		Column.Use            = DisplayingOrder.Value;
		ColumnGrouping.Use = DisplayingOrder.Value;
	EndIf;
	
	DataSet = DataCompositionSchema.DataSets.Find("DataSet1");
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(DataSet.Query);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm - report form.
//   VariantKey - String - The name of the predefined report variant or the unique ID of the custom one.
//   Settings - See ReportsClientServer.GetDefaultReportSettings
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
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
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
		ThisForm.ParametersForm.Filter.Insert("LineOfBusiness",
				Common.ObjectAttributeValue(Parameters.CommandParameter, "LineOfBusiness"));
		
		ThisForm.ParametersForm.Insert("ContextOpening", True);
	EndIf;
		
EndProcedure

// Parameters:
//  ThisForm - ClientApplicationForm
//  NewDCSettings - DataCompositionUserSettings
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCSettings) Export
	
	Parameters = ThisForm.ParametersForm;
	If (Parameters.Property("ContextOpening") And Parameters.ContextOpening)
		Or ThisForm.DetailsMode Then
		DataCompositionServer.RemoveParameterFromUserReportSettings(SettingsComposer, "DisplayingOrder");
	EndIf;
	
	If ThisForm.Parameters.Property("CommandParameter")
		And TypeOf(ThisForm.Parameters.CommandParameter) = Type("DocumentRef.ProductionOrder2_2") Then
		OrderBoundaries = OrderStructureInternal.BoundariesOfRegulatorySchedulePeriod(ThisForm.Parameters.CommandParameter);
		
		PeriodValue = DataCompositionClientServer.GetParameter(SettingsComposer.UserSettings,
																		"Period").Value;
		PeriodIsFull = ValueIsFilled(PeriodValue);
		
		Period = ?(PeriodIsFull, PeriodValue, New StandardPeriod());//StandardPeriod
		
		If ValueIsFilled(OrderBoundaries.Ending) And ValueIsFilled(OrderBoundaries.Begin) Then
			Period.StartDate = BegOfMonth(OrderBoundaries.Begin);
			Period.EndDate = EndOfMonth(OrderBoundaries.Ending + 1);
		ElsIf Not PeriodIsFull Then 
			CurrentDate = CurrentSessionDate();
			Period.StartDate = BegOfYear(CurrentDate);
			Period.EndDate = EndOfYear(CurrentDate);
		EndIf;
		
		DataCompositionClientServer.SetParameter(SettingsComposer, "Period", Period);
	EndIf;
	
	NewDCSettings = SettingsComposer.GetSettings();

EndProcedure

#EndRegion

#Region Private

Function FindByName(Structure, Name)
	
	For Each Item In Structure Do
		If TypeOf(Item) = Type("DataCompositionSelectedField")
			Or TypeOf(Item) = Type("DataCompositionGroupField") Then
			
			If Item.Field = New DataCompositionField(Name) Then
				Return Item;
			EndIf;
			
		ElsIf TypeOf(Item) <> Type("DataCompositionSelectedFieldGroup") Then
			
			If Item.Name = Name Then
				Return Item;
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndFunction

Function FindStringRecursively(Structure, Name)
	
	For Each Item In Structure Do
		
		If TypeOf(Item) = Type("DataCompositionTableGroup") Then
			
			If Item.Name = Name Then
				Return Item;
			EndIf;
			
			If Item.Structure.Count() > 0 Then
				
				String = FindStringRecursively(Item.Structure, Name);
				
				If String <> Undefined Then
					Return String;
				EndIf; 
				
			EndIf;
			
		EndIf;
		
	EndDo;
	
	Return Undefined;
	
EndFunction

#EndRegion

#EndIf