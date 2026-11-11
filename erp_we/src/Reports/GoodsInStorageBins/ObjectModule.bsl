#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

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
//   ThisForm - ClientApplicationForm - The Form of the report. Contains including:
//   	* Parameters - Structure - The parameter structure contains, among other things:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure:
//   				**** CommandName - String
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
		And Parameters.Property("CommandDetails")
		And Parameters.CommandDetails.AdditionalParameters.Property("CommandName") Then
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "ByStorageBin" Then
			ThisForm.ParametersForm.Filter.Insert("Cell", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "RemainingGoodsByShelfLives" Then
			ThisForm.ParametersForm.Filter.Insert("Products", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByStorageArea" Then
			ThisForm.ParametersForm.Filter.Insert("StorageArea", Parameters.CommandParameter);
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "ByInventoryItemGroup" Then
			ThisForm.ParametersForm.Filter.Insert("WarehouseGroupOfProducts", Parameters.CommandParameter);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	QueryText = DataCompositionSchema.DataSets.GoodsInStorageBins.Query;
	
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
			"ProductsInBalancesAndTurnoverCells.Package", 
			"ProductsInBalancesAndTurnoverCells.Products"));
			
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextVolumeM3", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageVolume(
			"ProductsInBalancesAndTurnoverCells.Package", 
			"ProductsInBalancesAndTurnoverCells.Products"));
			
	QueryText = StrReplace(
		QueryText, 
		"&QueryTextWeight", 
		Catalogs.PackagesAndUnitsOfMeasure.QueryTextPackageWeight(
			"ProductsInBalancesAndTurnoverCells.Package", 
			"ProductsInBalancesAndTurnoverCells.Products"));
	
	DataCompositionSchema.DataSets.GoodsInStorageBins.Query = QueryText;

	
	SegmentsServer.EnableSelectionBySegmentOfVSPDProductRange(SettingsComposer);	
EndProcedure

#EndRegion

#Region Private

Procedure SetFieldHeaders()
	
	If Not Common.SeparatedDataUsageAvailable() Then
		Return;
	EndIf;
	
	FieldHeaders = DataCompositionServer.MatchingUnitFieldHeaders(SettingsComposer);
	
	For Each DataSetField In DataCompositionSchema.DataSets.GoodsInStorageBins.Fields Do
		If TypeOf(DataSetField) = Type("DataCompositionSchemaDataSetField") Then
			For Each Field In FieldHeaders Do
				ReplacementString = "%" + Field.Key + "%";
				
				If StrFind(DataSetField.Title, ReplacementString) > 0 Then
					DataSetField.Title = StrReplace(DataSetField.Title, ReplacementString, Field.Value);
				EndIf;
			EndDo;
		EndIf;
	EndDo;

EndProcedure

SetFieldHeaders();

#EndRegion

#EndIf