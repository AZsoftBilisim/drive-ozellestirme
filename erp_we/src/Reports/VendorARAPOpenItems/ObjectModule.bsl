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
	
	If Parameters.Property("CommandParameter")
			And Parameters.Property("CommandDetails")
			And Parameters.CommandDetails.Property("AdditionalParameters") Then 
		
		ThisForm.ReportSettings.OptionSelectionAllowed = False;
		
		If Parameters.CommandDetails.AdditionalParameters.CommandName = "PaymentCardWithSupplier" Then
			
			VariantKey = GenerateParametersForSettlementsWithSupplier(Parameters.CommandParameter, ThisForm, Parameters);
			
		ElsIf Parameters.CommandDetails.AdditionalParameters.CommandName = "PaymentCardWithSupplierBasedOnDocuments" Then
			
			SettingsStructure = ReportSettings(Parameters.CommandParameter);
			ValuesOfFunctionalOptions = SettingsStructure.ValuesOfFunctionalOptions;	
			
			VariantKey = NameOfVariantKeyDependsOnFlag("PaymentCardWithSuppliersAccordingToDocumentsContext",
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
	FormSettingsComposer = ThisForm.Report.SettingsComposer;
	
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

Function GenerateParametersForSettlementsWithSupplier(CommandParameter, ThisForm, Parameters)
	
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
		VariantKey = NameOfVariantKeyDependsOnFlag("PaymentCardWithSuppliersContext",
			                                                      ThisIsBasic);
	Else
		FormParameters.PurposeUseKey = CommandParameter;
		Parameters.PurposeUseKey = CommandParameter;
		If ThisIsArray And CommandParameter.Count() = 1 Then
			VariantKey = NameOfVariantKeyDependsOnFlag("PaymentCardWithServiceProvider",
			                                                          ThisIsBasic);
		Else
			VariantKey = NameOfVariantKeyDependsOnFlag("PaymentCardWithSuppliersContext",
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
	Types.Add(Type("DocumentRef.VendorInvoice"));
	Types.Add(Type("DocumentRef.CCDImport"));
	Types.Add(Type("DocumentRef.PurchaseOrder"));
	Types.Add(Type("DocumentRef.ReturnOfGoodsToVendor"));
	Types.Add(Type("DocumentRef.VendorInvoiceServicesAndAssets"));
	Types.Add(Type("DocumentRef.RedemptionOfReturnablePackagingFromVendor"));
	Types.Add(Type("DocumentRef.SubcontractOrder2_5"));
	Types.Add(Type("DocumentRef.SubcontractorReport2_5"));

	SettingsStructure = New Structure;
	SettingsStructure.Insert("ValuesOfFunctionalOptions", ValuesOfFunctionalOptions);
	If TypeOf(CommandParameter) = Type("Array") Then
		ARAPObjects = New Array;
		For Each Document In CommandParameter Do
			If Types.Find(TypeOf(Document)) <> Undefined Then
				ARAPObjects.Add(ARAPObjectsServer.ObjectOfCalculationsFromLink(Document));
			EndIf;
		EndDo;
		ARAPObjects = CommonClientServer.CollapseArray(ARAPObjects);
		If ARAPObjects.Count() = 1 Then
			SettingsStructure.Insert("FiltersStructure", New Structure("ARAPObject", ARAPObjects[0]));
		Else
			SettingsStructure.Insert("FiltersStructure", New Structure("ARAPObject", ARAPObjects));
		EndIf;
	Else
		SettingsStructure.Insert("FiltersStructure",
		                           ARAPAccountingServer.StructureOfReportSelectionsSettlementsWithClients(CommandParameter,
		                                                                                        "VendorARAPOpenItems",
		                                                                                        "PaymentCardWithSupplierBasedOnDocuments",
		                                                                                        Types));
	EndIf;
	Return SettingsStructure
	
EndFunction

Function NameOfVariantKeyDependsOnFlag(VariantKeyName, ThisIsBasic)
	
	If Not ThisIsBasic Then
		Return VariantKeyName;
	EndIf;
	
	If VariantKeyName = "VendorARAPOpenItems" Then
		Return "PaymentCardWithSuppliersBasic";
	ElsIf VariantKeyName = "PaymentCardWithSuppliersAccordingToDocumentsContext" Then
		Return "PaymentCardWithSuppliersBasedOnDocumentsContextBasic";
	ElsIf VariantKeyName = "PaymentCardWithSuppliersContext" Then
		Return "PaymentCardWithSuppliersContextBasic";
	ElsIf VariantKeyName = "PaymentCardWithServiceProvider" Then
		Return "PaymentCardWithSupplierContextBasic";
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