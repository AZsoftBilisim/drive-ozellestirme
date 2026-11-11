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
		
		ThisForm.ParametersForm.Filter = New Structure("ConsignmentReportFromCustomer", Parameters.CommandParameter);
		Parameters.VariantKey = NameOfVariantKeyDependsOnFlag(
			"StatusOfSettlementsWithCommissionAgentsContext",
			ValuesOfFunctionalOptions.BaseVersion
		);
		
		ThisForm.ParametersForm.InitialOptionKey = Parameters.VariantKey;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
	If ParametersForm.Property("Filter")
		And ParametersForm.Filter.Property("ConsignmentReportFromCustomer") Then
		
		If TypeOf(ParametersForm.Filter.ConsignmentReportFromCustomer) = Type("DocumentRef.ConsignmentReportFromCustomer") Then
			
			Attributes = Documents.ConsignmentReportFromCustomer.DocumentAttributes(ParametersForm.Filter.ConsignmentReportFromCustomer);
			
		ElsIf TypeOf(ParametersForm.Filter.ConsignmentReportFromCustomer) = Type("DocumentRef.WriteOffReportFromCommissionAgent") Then
			
			Attributes = Documents.WriteOffReportFromCommissionAgent.DocumentAttributes(ParametersForm.Filter.ConsignmentReportFromCustomer);
			
		Else
			
			Attributes = Undefined;
			
		EndIf;
		
		If Attributes <> Undefined Then
			
			If ValueIsFilled(Attributes.Partner) Then
				ParametersForm.Filter.Insert("Consignee", Attributes.Partner);
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
	
	DataLayoutSchemaDataSets = DataCompositionSchema.DataSets.CommissionAgentsARAPAccounting; // DataCompositionSchemaDataSetUnion
	
	QueryText = DataLayoutSchemaDataSets.Items.GoodsTransferredToCommissionAgent.Query;

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor1", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("ItemsPrices.Package", "ItemsPrices.Products"));

	QueryText = StrReplace(
		QueryText, 
		"&QueryTextPackagingFactor2", 
		Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient("AgreementWithCustomerGoods.Package", "GoodsTransferred.Products"));

	DataLayoutSchemaDataSets.Items.GoodsTransferredToCommissionAgent.Query = QueryText;	
	
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
	PriceManagementSystem.SetVSKDPricingOption(SettingsComposer);
	
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
	
	If VariantKeyName = "StateOfSettlementsWithCommissionAgents" Then
		Return "StatusOfSettlementsWithCommissionAgentsIsBasic";
	ElsIf VariantKeyName = "StatusOfSettlementsWithCommissionAgentsContext" Then
		Return "StateOfSettlementsWithCommissionAgentsContext";
	EndIf;
	
EndFunction

#EndRegion

#EndIf