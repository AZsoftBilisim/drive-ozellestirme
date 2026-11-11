#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	
	InternationalReportingServer.OnComposeResult(DataCompositionSchema, SettingsComposer, ResultDocument, DetailsData, StandardProcessing);
	
	InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Nợ';
																		|ru = 'Дебет';
																		|en = 'Debit'; fa = 'بدهکار';
																		|it = 'Debito';
																		|pl = 'Debet';
																		|tr = 'Borç'"));
	InternationalReportingServer.MergeFieldHeaders(ResultDocument, NStr("vi = 'Có';
																		|ru = 'Кредит';
																		|en = 'Credit'; fa = 'بستانکار';
																		|it = 'Credito';
																		|pl = 'Ma';
																		|tr = 'Alacak'"));
	
EndProcedure

#EndRegion

#Region Private

// For the General "report Form" form of the "report Options" subsystem.
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. Used to change the layout scheme.
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	
	If Not GetFunctionalOption("UseSeveralChartsOfAccountsInFinancialAccounting") Then
		AccountField = ThisObject.DataCompositionSchema.DataSets["MainDataSet"].Fields.Find("Account"); // DataCompositionSchemaDataSetField - 
		EditParameters =  AccountField.EditParameters.Items;
		ChartOfAccountsParameterField = New DataCompositionField("DataParameters.ChartOfAccounts");
		For Each EditingParameter In EditParameters Do
			If EditingParameter.Parameter = New DataCompositionParameter("ChoiceParameterLinks") Then
				EditingParameter.Use = False;
				For Each RelationshipOfSelectionParameters In EditingParameter.Value Do
					If RelationshipOfSelectionParameters.Field = ChartOfAccountsParameterField Then
						EditingParameter.Value.Delete(RelationshipOfSelectionParameters);
					EndIf;
				EndDo;
			EndIf;
		EndDo;
		ReportsServer.AttachSchema(ThisObject, Context, ThisObject.DataCompositionSchema, SchemaKey);
	EndIf;
	If TypeOf(Context) = Type("ClientApplicationForm") And Context.Parameters.Property("AdditionalParameters") Then 
		AdditionalParameters = CommonClientServer.StructureProperty(Context.Parameters,"AdditionalParameters");
		GroupByPeriod = CommonClientServer.StructureProperty(AdditionalParameters, "GroupByPeriod");
		If GroupByPeriod <> Undefined Then
			Field = GroupByPeriod;
			NewDCSettings.Structure.Clear();
			DataCompositionClientServer.AddGrouping(NewDCSettings, New DataCompositionField(Field));
		EndIf;
	EndIf;	
EndProcedure

#EndRegion

#EndIf
