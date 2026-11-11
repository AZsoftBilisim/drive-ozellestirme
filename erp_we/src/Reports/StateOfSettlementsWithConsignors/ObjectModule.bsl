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
//   ThisForm - ClientApplicationForm - report form.
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		ValuesOfFunctionalOptions = New Structure("BaseVersion", GetFunctionalOption("BaseVersion"));
		
		ThisForm.ParametersForm.Filter = New Structure("ConsignmentReportToVendor", Parameters.CommandParameter);
		Parameters.VariantKey = NameOfVariantKeyDependsOnFlag(
			"StateOfSettlementsWithCommitteesContext",
			ValuesOfFunctionalOptions.BaseVersion
		);
		
		ThisForm.ParametersForm.InitialOptionKey = Parameters.VariantKey;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
	If ParametersForm.Property("Filter")
		And ParametersForm.Filter.Property("ConsignmentReportToVendor") Then
		
		If TypeOf(ParametersForm.Filter.ConsignmentReportToVendor) = Type("DocumentRef.ConsignmentReportToVendor") Then
			
			Attributes = Documents.ConsignmentReportToVendor.DocumentAttributes(ParametersForm.Filter.ConsignmentReportToVendor);
			
		ElsIf TypeOf(ParametersForm.Filter.ConsignmentReportToVendor) = Type("DocumentRef.PurchaseInvoiceConsignmentStockLost") Then
			
			Attributes = Documents.PurchaseInvoiceConsignmentStockLost.DocumentAttributes(ParametersForm.Filter.ConsignmentReportToVendor);
			
		Else
			
			Attributes = Undefined;
			
		EndIf;
		
		If Attributes <> Undefined Then
			
			If ValueIsFilled(Attributes.Partner) Then	
				ParametersForm.Filter.Insert("Consignor", Attributes.Partner);
			EndIf;
			
			If ValueIsFilled(Attributes.BeginOfPeriod)
				Or ValueIsFilled(Attributes.EndOfPeriod) Then
				
				Period = New StandardPeriod;
				Period.Variant = StandardPeriodVariant.Custom;
				Period.StartDate = Attributes.BeginOfPeriod;
				Period.EndDate = Attributes.EndOfPeriod;
				ParametersForm.Filter.Insert("Period", Period);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	DataLayoutSchemaDataSets = DataCompositionSchema.DataSets.ConsignorsARAPAccounting; // DataCompositionSchemaDataSetUnion
	
	QueryText = DataLayoutSchemaDataSets.Items.CompanyGoods.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor1", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ItemsPrices.Package", "ItemsPrices.Products"));

	DataLayoutSchemaDataSets.Items.CompanyGoods.Query = QueryText;
	
	FixedPeriodSetting = FixedParameterSetting("Period");
	If FixedPeriodSetting.Use = True Then
		UsesPeriodSetting = CustomParameterSetting("Period");
		UsesPeriodSetting.Use = True;
		UsesPeriodSettingValue = UsesPeriodSetting.Value; // StandardPeriod
		FixedPeriodSettingValue  = FixedPeriodSetting.Value;  // StandardPeriod
		UsesPeriodSettingValue.StartDate    = FixedPeriodSettingValue.StartDate;
		UsesPeriodSettingValue.EndDate = FixedPeriodSettingValue.EndDate;
		
		FixedPeriodSetting.Use = False;
	EndIf;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);	
EndProcedure

#EndRegion

#Region Private

Function FixedParameterSetting(ParameterName)
	DataParameter = SettingsComposer.FixedSettings.DataParameters.Items.Find(ParameterName);
	
	Return DataParameter;
EndFunction

Function CustomParameterSetting(ParameterName)
	DataParameter = SettingsComposer.Settings.DataParameters.Items.Find(ParameterName);
	If DataParameter <> Undefined Then
		CustomSettingParameter = SettingsComposer.UserSettings.Items.Find(DataParameter.UserSettingID);
		If CustomSettingParameter <> Undefined Then
			Return CustomSettingParameter;
		Else
			Return DataParameter;
		EndIf;
	EndIf;
	
	Return Undefined;
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "StateOfSettlementsWithConsignors" Then
		Return "StatusOfSettlementsWithCommitteesIsBasic";
	ElsIf VariantKeyName = "StateOfSettlementsWithCommitteesContext" Then
		Return "StateOfSettlementsWithCommitteesContextBasic";
	EndIf;
	
EndFunction

#EndRegion

#EndIf