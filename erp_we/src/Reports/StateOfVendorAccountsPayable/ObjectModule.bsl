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
	
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	Parameters = ThisForm.Parameters;
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithSupplier" Then
			
			GenerateParametersStateOfSettlementsWithSupplier(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "StateOfSettlementsWithSupplierAccordingToDocuments" Then
			
			CommandParameter = Parameters.CommandParameter;
			
			SettingsStructure = ReportSettings(CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;
			
			ThisForm.ParametersForm.PurposeUseKey = CommandParameter;
			Parameters.PurposeUseKey = CommandParameter;
			
			If SettingsStructure.Property("FiltersStructure") Then
				For Each KeyAndValue In SettingsStructure.FiltersStructure Do
					SetFixedSelection(KeyAndValue.Key, KeyAndValue.Value);
				EndDo;
			EndIf;
			
			Parameters.VariantKey = NameOfVariantKeyDependsOnFlag("StateOfCalculationsForObjectOfCalculationsContext", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
			ThisForm.CurrentVariantKey = NameOfVariantKeyDependsOnFlag("StateOfCalculationsForObjectOfCalculationsContext", 
			                                                                    ValuesOfFunctionalOptions.BaseVersion);
			
		EndIf;
		
	EndIf;
	
	ParametersForm = ThisForm.ParametersForm;
	ARAPAccountingServer.ReplaceDocumentsOfSettlementsWithSuppliers(ParametersForm);

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
	
	StandardProcessing = False;
	
	SegmentsServer.EnableSelectionByVSKDPartnerSegment(SettingsComposer);
	Calculations = DataCompositionSchema.DataSets["Calculations"]; // DataCompositionSchemaDataSetUnion - 
	Package = Calculations.Items.SettlementBalances;
	Package.Query = StrReplace(Package.Query,
		"DocWP2_5 AS DocumentData",
		"Document.SubcontractOrder2_5 AS DocumentData");
	ReportSettings = SettingsComposer.GetSettings();
	
	TemplateComposer = New DataCompositionTemplateComposer;
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);

	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate, , DetailsData, True);

	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	
	//A warning about the unfulfilled distribution of mutual settlements.
	ARAPAccountingServer.DisplayUpdateWarning(ResultDocument);
	ARAPAccountingServer.DisplayWarningAboutEndOfOfflinePaymentSupport(ResultDocument);
	
	OutputProcessor.Output(CompositionProcessor);
	
EndProcedure

#EndRegion 

#Region Private
	
Procedure ConfigureSelectionParametersByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UsePartnersAsCounterparties") Then
		DataCompositionServer.RemoveSelectionItemFromAllReportSettings(FormSettingsComposer, "Counterparty");
	EndIf;
	
	If GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing") Then
		DataCompositionServer.DeleteSelectedFieldFromAllReportSettings(FormSettingsComposer, "PrepaymentBeforeConfirmation");
	EndIf;
	
EndProcedure

Procedure ConfigureUserSettingsByFunctionalOptions(FormSettingsComposer)
	
	If GetFunctionalOption("UseSimplifiedPaymentSchemeInPurchasing") Then
		DataCompositionServer.DisableSelectedFieldInUserSettings(FormSettingsComposer, "PrepaymentBeforeConfirmation");
	EndIf;
	
EndProcedure

Procedure GenerateParametersStateOfSettlementsWithSupplier(CommandParameter, ThisForm, Parameters)
	
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
		
		VariantKey = NameOfVariantKeyDependsOnFlag("StatusOfSettlementsWithSuppliersContext", 
			                                                                 ThisIsBasic);
	Else
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("StateOfSettlementsWithSupplierContext", 
			                                                                    ThisIsBasic);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("StatusOfSettlementsWithSuppliersContext", 
			                                                                    ThisIsBasic);
		EndIf;
	EndIf;
	Parameters.VariantKey = VariantKey;
	ThisForm.CurrentVariantKey = VariantKey;
	
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
	
EndProcedure

Function ReportSettings(CommandParameter)
	
	ValuesOfFunctionalOptions = New Structure;
	ValuesOfFunctionalOptions.Insert("BaseVersion", GetFunctionalOption("BaseVersion"));
	
	Types = New Array;
	Types.Add(Type("DocumentRef.VendorInvoice"));
	Types.Add(Type("DocumentRef.CCDImport"));
	Types.Add(Type("DocumentRef.PurchaseOrder"));
	Types.Add(Type("DocumentRef.ReturnOfGoodsToVendor"));
	Types.Add(Type("DocumentRef.RedemptionOfReturnablePackagingFromVendor"));
	Types.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	Types.Add(Type("DocumentRef.SubcontractOrder2_5"));
	Types.Add(Type("DocumentRef.SubcontractorReport2_5"));
	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	SettingsStructure.Insert("FiltersStructure",
	                           ARAPAccountingServer.StructureOfReportSelectionsSettlementsWithClients(CommandParameter,
	                                                                                        "StateOfVendorAccountsPayable",
	                                                                                        "StateOfSettlementsWithSupplierAccordingToDocuments",
	                                                                                        Types));
	Return SettingsStructure
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "StateOfVendorAccountsPayable" Then
		Return "StatusOfSettlementsWithSuppliersIsBasic";
	ElsIf VariantKeyName = "StateOfCalculationsForObjectOfCalculationsContext" Then
		Return "StateOfCalculationsForObjectOfCalculationsContextBasic";
	ElsIf VariantKeyName = "StateOfSettlementsWithSupplierContext" Then
		Return "StateOfSettlementsWithSupplierContextBasic";
	ElsIf VariantKeyName = "StatusOfSettlementsWithSuppliersContext" Then
		Return "StateOfSettlementsWithSuppliersContextBasic";
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