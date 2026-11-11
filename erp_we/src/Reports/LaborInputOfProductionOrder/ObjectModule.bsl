#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	PlannedDates = DataCompositionSchema.DataSets.Find("PlannedDates");
	
	QueryText = PlannedDates.Query;
	
	ProductionManagement.SubstitutionOfActualRegisterOfGraph(QueryText);
	
	PlannedDates.Query = QueryText;
	
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
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   Var_ThisObject - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Passed from the handler parameters "as is".
//
// See also:
//   "formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(Var_ThisObject, Cancel, StandardProcessing) Export
	
	Parameters = Var_ThisObject.Parameters;
	
	If Parameters.Property("CommandParameter")
	   And Parameters.Property("VariantKey") Then
		
		VariantKey = Parameters.VariantKey;
		
		If TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionOrder2_2") Then
		
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
			
			Var_ThisObject.ParametersForm.Filter.Insert("ProductionOrder", Parameters.CommandParameter);
			
		ElsIf TypeOf(Parameters.CommandParameter) = Type("DocumentRef.ProductionStage2_2") Then
			
			If Not Common.ObjectAttributeValue(Parameters.CommandParameter, "DynamicStructure") Then
				
				Common.MessageToUser(NStr("vi = 'Báo cáo này chỉ áp dụng đối với các đơn hàng có sử dụng cấu trúc động.';
											|ru = 'Данный отчет применим только к этапам с включенной динамической структурой.';
											|en = 'This report is applicable only to stages with enabled dynamic structure.'; fa = 'This report is applicable only to stages with enabled dynamic structure.';
											|it = 'Данный отчет применим только к этапам с включенной динамической структурой.';
											|pl = 'This report is applicable only to stages with enabled dynamic structure.';
											|tr = 'Bu rapor sadece dinamik yapısı etkinleştirilmiş aşamalar için geçerlidir.'"));
				Cancel = True;
				Return;
				
			EndIf;
			
			If VariantKey = "LaborInputByBatch" Then
				
				Lot = Common.ObjectAttributeValue(Parameters.CommandParameter, "ProductionLot");
				Var_ThisObject.ParametersForm.Filter.Insert("ProductionLot", Lot);
				
			ElsIf VariantKey = "LaborInputByStage" Then
				
				Var_ThisObject.ParametersForm.Filter.Insert("Stage", Parameters.CommandParameter);
				
			EndIf;
			
		EndIf;
		
	EndIf;
		
EndProcedure

#EndRegion

#EndIf

