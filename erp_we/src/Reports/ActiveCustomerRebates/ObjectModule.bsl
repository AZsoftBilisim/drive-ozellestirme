//@strict-types

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

// When composing the result.
// 
// Parameters:
//  ResultDocument - SpreadsheetDocument - Result document
//  DetailsData - DataCompositionDetailsData - decryption data
//  StandardProcessing - Boolean - Standard treatment
//
Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	StandardProcessing = False;
	ReportSettings = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	
	ReportOptionParameter = DataCompositionClientServer.GetParameter(ReportSettings, "ReportVariant");
	PartnerParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Partner");
	CounterpartyParameter = DataCompositionClientServer.GetParameter(ReportSettings, "Counterparty");
	
	ParametersStructure = New Structure;
	ParametersStructure.Insert("PartnerParameter", PartnerParameter);
	ParametersStructure.Insert("CounterpartyParameter", CounterpartyParameter);
	ParametersStructure.Insert("ReportOptionParameter", ReportOptionParameter);
	
	SetAdditionalParameters(ReportSettings, ParametersStructure);
	ConfigureParameterAvailabilityRestriction(DataCompositionSchema, ReportOptionParameter);
	
	CompositionTemplate = TemplateComposer.Execute(DataCompositionSchema, ReportSettings, DetailsData);
	
	CompositionProcessor = New DataCompositionProcessor;
	CompositionProcessor.Initialize(CompositionTemplate,, DetailsData);
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(CompositionProcessor);
	
	ReportIsBlank = ReportsServer.ReportIsBlank(ThisObject, CompositionProcessor);
	SettingsComposer.UserSettings.AdditionalProperties.Insert("ReportIsBlank", ReportIsBlank);
	
EndProcedure

#EndRegion

#Region Internal

// Settings for the General report form in the report Options subsystem.
//
// Parameters:
//   Form - ClientApplicationForm, Undefined - report form or report settings form.
//       Undefined when a call is without context.
//   VariantKey - String, Undefined - the name of the predefined
//       or unique identifier of the custom version of the report.
//       Undefined when a call is without context.
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export 
	
	If VariantKey = "CurrentRebatesForClientContext"
	 Or VariantKey = "CurrentRebatesForCounterpartyContext" Then
		
		Settings.GenerateImmediately = True;
		Settings.EditOptionsAllowed = False;
		Settings.EditStructureAllowed = False;
		
	EndIf;
	
	Settings.Events.OnCreateAtServer = True; 
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// See ReportsOverridable.OnCreateAtServer
Procedure OnCreateAtServer(Form, Cancel, StandardProcessing) Export
	
	Parameters = Form.Parameters;
	
	If Parameters.Property("CommandParameter") Then
		
		Form.ReportSettings.OptionSelectionAllowed = False;
		
	EndIf;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//   For example, if the report schema depends on the option key or report parameters.
//   For schema changes to take effect, call the ReportServer method.Connect the circuit().
//
// Parameters:
//   Context - See CommonForm.ReportForm
//   SchemaKey - String -
//       ID of the current configuration Composer schema.
//       By default, it is not filled in (this means that the Composer is initialized based on the main schema).
//       It is used for optimization in order to reinitialize the Composer as rarely as possible).
//       It may not be used if reinitialization is performed unconditionally.
//   VariantKey - String, Undefined -
//       The name of a predefined or unique identifier of a custom version of the report.
//       It is undefined when the call is for a decryption option or without context.
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If SchemaKey = VariantKey Then
		Return;
	EndIf;
	
	If NewDCSettings = Undefined Then
		Return;
	EndIf;
	
	If TypeOf(Context) = Type("ClientApplicationForm") Then
		
		Parameters = Context.Parameters;
		If Parameters.Property("CommandParameter") Then
			
			CommandParameter = Parameters.CommandParameter; // CatalogRef.Partners, CatalogRef.Counterparties
			FillInParametersByContext(CommandParameter, NewDCSettings, NewDCUserSettings);
			
		EndIf;
		
		ReportOptionParameter = DataCompositionClientServer.GetParameter(NewDCSettings, "ReportVariant");
		ReportVariant = ReportOptionParameter.Value;
		SetAvailabilityOfParametersForReportVariant(ReportVariant, DataCompositionSchema);
		
		If Not GetFunctionalOption("UseMultipleCompanies") Then 
			
			ParameterOrganization = DataCompositionSchema.Parameters.Find("Organization");
			
			ParameterOrganization.UseRestriction = True;
			ParameterOrganization.Use = DataCompositionParameterUse.Auto;
			ParameterOrganization.DenyIncompleteValues = False;
			
			ACompanyByDefault = SettingsValueCached.GetDefaultOrganization();
			
			If ValueIsFilled(ACompanyByDefault) Then
				
				DataCompositionClientServer.SetParameter(
					NewDCSettings,
					"Organization", 
					ACompanyByDefault);
				
				If NewDCUserSettings <> Undefined Then
					
					DataCompositionClientServer.SetParameter(
						NewDCUserSettings,
						"Organization", 
						ACompanyByDefault);
					
				EndIf;
				
			EndIf;
			
		EndIf;
		
		ReportsServer.AttachSchema(ThisObject, Context, DataCompositionSchema, SchemaKey);
		
		If NewDCUserSettings <> Undefined Then
			
			ReportDateParameter = DataCompositionClientServer.GetParameter(
				NewDCUserSettings,
				"ReportDate");
			
			If ReportDateParameter <> Undefined
			   And Not ValueIsFilled(ReportDateParameter.Value) Then
				
				DateParameter = ReportDateParameter.Value; // StandardBeginningDate, Date
				If TypeOf(DateParameter) = Type("StandardBeginningDate") Then
					
					DateParameter.Date = BegOfDay(CurrentSessionDate());
					DateParameter.Variant = StandardBeginningDateVariant.BeginningOfThisDay;
					
				Else
					
					DateParameter = BegOfDay(CurrentSessionDate());
					
				EndIf;
				
				DataCompositionClientServer.SetParameter(
					NewDCUserSettings,
					"ReportDate", 
					DateParameter);
				
			EndIf;
			
		EndIf;
		
	EndIf;
	
	SchemaKey = VariantKey;
	
EndProcedure

#EndRegion

#Region Private

Procedure SetAvailabilityOfParametersForReportVariant(ReportVariant, Var_DataCompositionSchema)
	
	PartnerParameter = Var_DataCompositionSchema.Parameters.Find("Partner");
	CounterpartyParameter = Var_DataCompositionSchema.Parameters.Find("Counterparty");
	
	If ReportVariant = 1 Then // By customer
		
		PartnerParameter.UseRestriction = False;
		PartnerParameter.Use = DataCompositionParameterUse.Always;
		PartnerParameter.DenyIncompleteValues = True;
		
		CounterpartyParameter.UseRestriction = True;
		CounterpartyParameter.Use = DataCompositionParameterUse.Auto;
		CounterpartyParameter.DenyIncompleteValues = False;
		
	ElsIf ReportVariant = 2 Then // by counterparty
		
		PartnerParameter.UseRestriction = True;
		PartnerParameter.Use = DataCompositionParameterUse.Auto;
		PartnerParameter.DenyIncompleteValues = False;
		
		CounterpartyParameter.UseRestriction = False;
		CounterpartyParameter.Use = DataCompositionParameterUse.Always;
		CounterpartyParameter.DenyIncompleteValues = True; 
		
	ElsIf ReportVariant = 4 Then // by client (context)
		
		PartnerParameter.UseRestriction = True;
		PartnerParameter.Use = DataCompositionParameterUse.Always;
		PartnerParameter.DenyIncompleteValues = True;
		
		CounterpartyParameter.UseRestriction = True;
		CounterpartyParameter.Use = DataCompositionParameterUse.Auto;
		CounterpartyParameter.DenyIncompleteValues = False;
		
	ElsIf ReportVariant = 5 Then // by counterparty (context)
		
		PartnerParameter.UseRestriction = True;
		PartnerParameter.Use = DataCompositionParameterUse.Auto;
		PartnerParameter.DenyIncompleteValues = False;
		
		CounterpartyParameter.UseRestriction = True;
		CounterpartyParameter.Use = DataCompositionParameterUse.Always;
		CounterpartyParameter.DenyIncompleteValues = True;	
		
	Else // by client and counterparty
		
		PartnerParameter.UseRestriction = False;
		PartnerParameter.Use = DataCompositionParameterUse.Always;
		PartnerParameter.DenyIncompleteValues = True;
		
		CounterpartyParameter.UseRestriction = False;
		CounterpartyParameter.Use = DataCompositionParameterUse.Always;
		CounterpartyParameter.DenyIncompleteValues = True;
		
	EndIf;
	
EndProcedure

// Parameters:
//  ReportSettings - DataCompositionSettings - 
//  ParametersStructure - Structure:
// * PartnerParameter - DataCompositionParameterValue, Undefined, DataCompositionSettingsParameterValue - Partner Parameter
// * CounterpartyParameter - DataCompositionParameterValue, Undefined, DataCompositionSettingsParameterValue - Counterparty Parameter
//
Procedure SetAdditionalParameters(ReportSettings, ParametersStructure)
	
	PartnerParameter = ParametersStructure.PartnerParameter;
	CounterpartyParameter = ParametersStructure.CounterpartyParameter;
	ReportVariant = ParametersStructure.ReportOptionParameter.Value;
	
	Query = New Query;
	QueriesArray = New Array; // Array of String
	
	If ReportVariant = 2
	 Or ReportVariant = 5 Then
		
		QueryText = QueryTextCounterpartyData();
		QueriesArray.Add(QueryText);
		
		QueryText =
		"SELECT ALLOWED
		|	CounterpartyContracts.Ref AS Contract
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.Counterparty = &Counterparty
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)";
		
		QueriesArray.Add(QueryText);
		
		QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
		Query.Text = QueryText;
		
		Counterparty = CounterpartyParameter.Value;
		Query.SetParameter("Counterparty", Counterparty);
		
		EmptyPartnerLink = Catalogs.Partners.EmptyRef();
		DataCompositionClientServer.SetParameter(ReportSettings, "Partner", EmptyPartnerLink);
		
		Result = Query.ExecuteBatch(); 
		
		Selection = Result[0].Select();
		Selection.Next(); 
		TIN = Selection.TIN;
		CounterpartySPartner = Selection.Partner; // CatalogRef.Partners
		
		DataCompositionClientServer.SetParameter(ReportSettings, "TIN", TIN);
		DataCompositionClientServer.SetParameter(ReportSettings, "CounterpartySPartner", CounterpartySPartner);
		
		Contracts = Result[1].Unload().UnloadColumn("Contract");
		DataCompositionClientServer.SetParameter(ReportSettings, "Contracts", Contracts);
		
	Else
		
		QueryText =
		"SELECT ALLOWED
		|	Counterparties.Ref AS Counterparty
		|FROM
		|	Catalog.Counterparties AS Counterparties
		|WHERE
		|	Counterparties.Partner = &Partner
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT ALLOWED
		|	CounterpartyContracts.Ref AS Contract
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	NOT CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners
		|	AND CounterpartyContracts.Partner = &Partner
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND &Condition
		|
		|UNION ALL
		|
		|SELECT
		|	CounterpartyContracts.Ref
		|FROM
		|	Catalog.CounterpartyContracts AS CounterpartyContracts
		|WHERE
		|	CounterpartyContracts.ItIsAllowedToWorkWithSubsidiaryPartners
		|	AND CounterpartyContracts.Partner IN(&PartnerList)
		|	AND CounterpartyContracts.BusinessOperation = VALUE(Enum.BusinessTransactions.SaleToCustomer)
		|	AND &Condition";
		
		ConditionText = "TRUE";
		If ReportVariant = 3 Then
			
			Counterparty = CounterpartyParameter.Value;
			Query.SetParameter("Counterparty", Counterparty);
			ConditionText = "CounterpartyContracts.Counterparty = &Counterparty";
			
			QueryText = StrReplace(QueryText, "&Condition", ConditionText);
			QueriesArray.Add(QueryText);
			
			QueryText = QueryTextCounterpartyData();
			QueriesArray.Add(QueryText);
			
		Else
			
			EmptyCounterpartyLink = Catalogs.Counterparties.EmptyRef();
			DataCompositionClientServer.SetParameter(ReportSettings, "Counterparty", EmptyCounterpartyLink);
			DataCompositionClientServer.SetParameter(ReportSettings, "TIN", "");
			
			QueryText = StrReplace(QueryText, "&Condition", ConditionText);
			QueriesArray.Add(QueryText);
			
		EndIf;
		
		QueryText = StrConcat(QueriesArray, Common.QueryBatchSeparator());
		Query.Text = QueryText;
		
		Partner = PartnerParameter.Value; // CatalogRef.Partners
		PartnerList = New ValueList;
		PartnersAndCounterparties.FillInListOfPartnersWithParents(Partner, PartnerList);
		
		Query.SetParameter("Partner", Partner);
		Query.SetParameter("PartnerList", PartnerList);
		
		Result = Query.ExecuteBatch();
		
		Selection = Result[0].Select(); 
		
		PartnerCounterparties = New ValueList; // ValueList of CatalogRef.Counterparties
		While Selection.Next() Do
			PartnerCounterparties.Add(Selection.Counterparty);
		EndDo;
		DataCompositionClientServer.SetParameter(ReportSettings, "PartnerCounterparties", PartnerCounterparties);
		
		Contracts = Result[1].Unload().UnloadColumn("Contract");
		DataCompositionClientServer.SetParameter(ReportSettings, "Contracts", Contracts);
		
		If ReportVariant = 3 Then
			
			Selection = Result[2].Select();
			Selection.Next(); 
			TIN = Selection.TIN;
			CounterpartySPartner = Selection.Partner; // CatalogRef.Partners
			
			DataCompositionClientServer.SetParameter(ReportSettings, "TIN", TIN);
			DataCompositionClientServer.SetParameter(ReportSettings, "CounterpartySPartner", CounterpartySPartner);
			
		EndIf;
		
	EndIf;
	
EndProcedure

Function QueryTextCounterpartyData()
	
	QueryText =
	"SELECT ALLOWED
	|	Counterparties.TIN AS TIN,
	|	Counterparties.Partner AS Partner
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Ref = &Counterparty";
	
	Return QueryText;
	
EndFunction

Procedure ConfigureParameterAvailabilityRestriction(Var_DataCompositionSchema, ReportOptionParameter)
	
	If ReportOptionParameter <> Undefined
	   And ValueIsFilled(ReportOptionParameter.Value) Then
		
		ReportVariant = ReportOptionParameter.Value;
		If ReportVariant = 4 Then
			
			Var_DataCompositionSchema.Parameters.Partner.UseRestriction = False;
			
		ElsIf ReportVariant = 5 Then
			
			Var_DataCompositionSchema.Parameters.Counterparty.UseRestriction = False;
			
		EndIf;
		
	EndIf;
	
EndProcedure

// Fills in parameters from the passed context.
// 
// Parameters:
//  CommandParameter - AnyRef
//   NewDCSettings - DataCompositionSettings, Undefined -
//       Report variant settings that will be loaded into the settings Composer after it is initialized.
//       It is uncertain when the option settings do not need to be loaded (already loaded earlier).
//   NewDCUserSettings - DataCompositionUserSettings, Undefined -
//       User settings that will be loaded into the settings Composer after it is initialized.
//       Undefined when user settings do not need to be loaded (already loaded earlier).
//
Procedure FillInParametersByContext(CommandParameter, NewDCSettings, NewDCUserSettings)
	
	CommandParameterType = TypeOf(CommandParameter);
	
	If CommandParameterType = Type("CatalogRef.Partners") Then
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "Partner", CommandParameter);
		If NewDCUserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings,
				"Partner", 
				CommandParameter);
			
		EndIf;
		
	ElsIf CommandParameterType = Type("CatalogRef.Counterparties") Then
		
		DataCompositionClientServer.SetParameter(NewDCSettings, "Counterparty", CommandParameter);
		If NewDCUserSettings <> Undefined Then
			
			DataCompositionClientServer.SetParameter(
				NewDCUserSettings, 
				"Counterparty", 
				CommandParameter);
				
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion

#EndIf