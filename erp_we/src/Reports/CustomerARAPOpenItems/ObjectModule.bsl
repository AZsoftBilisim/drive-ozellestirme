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
	Settings.Events.BeforeLoadVariantAtServer = True;
	Settings.Events.OnLoadUserSettingsAtServer = True;
EndProcedure

// Called in the handler of the report form event of the same name after executing the form code.
//
// Parameters:
//   ThisForm - ClientApplicationForm - Report form:
//   	* Parameters - Structure:
//   		** CommandDetails - Structure:
//   			*** AdditionalParameters - Structure
//   Cancel - Boolean - passed from the handler parameters "as is".
//   StandardProcessing - Boolean - passed from the handler parameters "as is".
//
// See also:
//   "Formaclientapplications.Joining the server" in the syntax assistant.
//
Procedure OnCreateAtServer(ThisForm, Cancel, StandardProcessing) Export
	
	Parameters = ThisForm.Parameters;
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "CustomerSettlementCard" Then
			
			VariantKey = GenerateParametersForSettlementsWithClient(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "CardOfSettlementsWithClientOnDocuments" Then
			
			SettingsStructure = ReportSettings(Parameters.CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;
			
			VariantKey = NameOfVariantKeyDependsOnFlag("CardOfSettlementsWithClientsOnDocumentsContext",
			                                                          ValuesOfFunctionalOptions.BaseVersion);
			
			Parameters.PurposeUseKey = Parameters.CommandParameter;
			ThisForm.ParametersForm.PurposeUseKey = Parameters.CommandParameter;
			
			If SettingsStructure.Property("FiltersStructure") Then
				For Each KeyAndValue In SettingsStructure.FiltersStructure Do
					SetFixedSelection(KeyAndValue.Key, KeyAndValue.Value);
				EndDo;
			EndIf;
			
		EndIf;
		
		Parameters.VariantKey = VariantKey;
		ThisForm.CurrentVariantKey = VariantKey;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	
	ARAPAccountingServer.ReplaceCustomerSettlementDocuments(ParametersForm);
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
//
// More detailed - See ReportsOverridable.BeforeLoadVariantAtServer
//
Procedure BeforeLoadVariantAtServer(ThisForm, NewDCSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	// Changing settings by functional options
	ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer);
	
	NewDCSettings = FormSettingsComposer.Settings;
	
EndProcedure

// Called in the report form handler of the same name after executing the form code.
// 
// Parameters:
//  ThisForm                         - ClientApplicationForm - Report form
//  NewDCUserSettings - DataCompositionSettings - 
//                                        Custom settings to upload to The Settings Composer.
//
Procedure OnLoadUserSettingsAtServer(ThisForm, NewDCUserSettings) Export
	
	Report = ThisForm.Report;
	FormSettingsComposer = Report.SettingsComposer;
	
	ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer);
	
	NewDCUserSettings = FormSettingsComposer.UserSettings;
	
EndProcedure

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)

	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);

EndProcedure

#EndRegion

#Region Private
	
Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
EndProcedure

Procedure ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer)
	
	If Not GetFunctionalOption("UseShipmentWithDeferredTransferOfTitle2_0") Then
		DataCompositionServer.DisableSelectedFieldInUserSettings(FormSettingsComposer,
			"CustomerDebtTotalOpeningBalance");
		DataCompositionServer.DisableSelectedFieldInUserSettings(FormSettingsComposer,
			"CustomerDebtTotalClosingBalance");
	EndIf;
	
EndProcedure

Function GenerateParametersForSettlementsWithClient(CommandParameter, ThisForm, Parameters)
	
	FormParameters = ThisForm.ParametersForm;
	
	If TypeOf(CommandParameter) = Type("Array") Then
		ThisIsArray = True;
		If CommandParameter.Count() > 0 Then
			TheFirstControl = CommandParameter[0];
		Else
			TheFirstControl = Undefined;
		EndIf;
	Else
		ThisIsArray = False;
		TheFirstControl = CommandParameter;
	EndIf;
	
	If ThisIsArray Then
		ThereAreSubordinatePartners = False;
		For Each CommandParameterElement In CommandParameter Do
			If PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameterElement) Then
				ThereAreSubordinatePartners = True;
				Break;
			EndIf;
		EndDo;
	Else
		ThereAreSubordinatePartners = PartnersAndCounterparties.ThereAreSubordinatePartners(CommandParameter);
	EndIf;
	
	ThisIsBasic = GetFunctionalOption("BaseVersion");
	
	VariantKey = ThisForm.CurrentVariantKey;
	
	If ThereAreSubordinatePartners Then
		FormParameters.PurposeUseKey = "Partners_Group";
		Parameters.PurposeUseKey = "Partners_Group";
		VariantKey = NameOfVariantKeyDependsOnFlag("CardOfSettlementsWithCustomersContext",
		                                                          ThisIsBasic);
	Else
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("CardOfSettlementsWithCustomerContext",
			                                                          ThisIsBasic);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("CardOfSettlementsWithCustomersContext",
			                                                          ThisIsBasic);
		EndIf;
	EndIf;
	
	FilterValue = CommandParameter;
	DCComparisonType = DataCompositionComparisonType.Equal;
	If ThisIsArray Then
		FilterValue = New ValueList;
		FilterValue.LoadValues(CommandParameter);
		If ThereAreSubordinatePartners Then
			DCComparisonType = DataCompositionComparisonType.InListByHierarchy;
		Else
			DCComparisonType = DataCompositionComparisonType.InList;
		EndIf;
	ElsIf ThereAreSubordinatePartners Then 
		DCComparisonType = DataCompositionComparisonType.InHierarchy;
	EndIf;
	CommonClientServer.SetFilterItem(
		SettingsComposer.FixedSettings.Filter,
		"Partner",
		FilterValue,
		DCComparisonType,,
		True);
	
	Return VariantKey;
	
EndFunction

Function ReportSettings(CommandParameter)
	
	ValuesOfFunctionalOptions = New Structure("BaseVersion", GetFunctionalOption("BaseVersion"));
	
	Types = New Array;
	Types.Add(Type("DocumentRef.ReturnOfGoodsFromCustomer"));
	Types.Add(Type("DocumentRef.RequestForReturnOfGoodsFromCustomer"));
	Types.Add(Type("DocumentRef.CustomerInvoiceServicesAndAssets"));
	Types.Add(Type("DocumentRef.SaleAdjustment"));
	Types.Add(Type("DocumentRef.CustomerInvoice"));
	Types.Add(Type("DocumentRef.ReturnablePackagingRedemptionByCustomer"));
	Types.Add(Type("DocumentRef.RedemptionOfGoodsByCustodian"));
	Types.Add(Type("DocumentRef.CustomerInvoiceServices"));
	Types.Add(Type("DocumentRef.SalesOrder"));
	Types.Add(Type("DocumentRef.MaterialProviderOrder2_5"));
	Types.Add(Type("DocumentRef.ReportToMaterialProvider2_5"));
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	SettingsStructure.Insert("FiltersStructure",
	                           ARAPAccountingServer.StructureOfReportSelectionsSettlementsWithClients(CommandParameter,
	                                                                                        "CustomerARAPOpenItems",
	                                                                                        "CardOfSettlementsWithClientOnDocuments", 
	                                                                                        Types));
	Return SettingsStructure
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "CustomerARAPOpenItems" Then
		Return "CustomerSettlementCardBasic";
	ElsIf VariantKeyName = "CardOfSettlementsWithClientsOnDocumentsContext" Then
		Return "CardOfSettlementsWithClientsOnDocumentsContextBasic";
	ElsIf VariantKeyName = "CardOfSettlementsWithCustomersContext" Then
		Return "CustomerSettlementCardContextBasic";
	ElsIf VariantKeyName = "CardOfSettlementsWithCustomerContext" Then
		Return "CustomerSettlementCardContextBasic_";
	EndIf;
	
EndFunction

Procedure SetFixedSelection(FieldName, Value)
	
	FilterValue = Value;
	DCComparisonType = DataCompositionComparisonType.Equal;
	If TypeOf(Value) = Type("Array") Then
		FilterValue = New ValueList;
		FilterValue.LoadValues(Value);
		DCComparisonType = DataCompositionComparisonType.InList;
	EndIf;
	CommonClientServer.SetFilterItem(
		SettingsComposer.FixedSettings.Filter,
		FieldName,
		FilterValue,
		DCComparisonType,,
		True);
	
EndProcedure

#EndRegion

#EndIf