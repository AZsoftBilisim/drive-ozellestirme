#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Variables

#EndRegion

#Region Public

// Code of procedures and functions

#EndRegion

#Region EventHandlers

Procedure OnComposeResult(ResultDocument, DetailsData, StandardProcessing)
	StandardProcessing = False;
	Rule = SettingsComposer.Settings.DataParameters.Items.Find("Rule").Value;
	If TypeOf(Rule) <> Type("CatalogRef.MasterDataDuplicateSearchRules") Then
		DataTable = New ValueTable;
		DataTable.Columns.Add("Group");
		DataTable.Columns.Add("Duplicate1");
		DataTable.Columns.Add("Code");
	Else
		Query = Catalogs.MasterDataDuplicateSearchRules.GenerateRequestBasedOnRule(Rule);
		Overridable_1 = Common.ObjectAttributeValue(Rule, "Overridable_1");
		
		If Overridable_1 Then
			DataTable = Query.Execute().Unload();
			DataTable.Columns.Delete("Ref1");
			DataTable.GroupBy("Duplicate1, Group, Code");
		Else
			DataTable = InformationRegisters.MasterDataDuplicatesToConfirm.DistributeDuplicatesIntoGroups(Query.Execute().Unload(), Rule);
		
			Query.Text = 
			"SELECT
			|	DataTable.DuplicatesGroup AS DuplicatesGroup,
			|	DataTable.Duplicate1 AS Duplicate1
			|INTO TT_DataTable
			|FROM
			|	&DataTable AS DataTable
			|;
			|SELECT
			|	DataTable.DuplicatesGroup AS DuplicatesGroup,
			|	DataTable.Duplicate1.Description AS Description,
			|	DataTable.Duplicate1.Code AS Code,
			|	DataTable.Duplicate1 AS Ref
			|FROM
			|	TT_DataTable AS DataTable
			|TOTALS BY
			|	DataTable.DuplicatesGroup";
		
			Query.SetParameter("DataTable", DataTable);
			MetadataObjectID = Common.ObjectAttributeValue(Rule, "MetadataObject");
			Ref = Common.ObjectAttributeValue(MetadataObjectID, "EmptyRefValue");
			ObjectMetadata = Ref.Metadata();
			If ObjectMetadata.CodeLength = 0 Then
				Query.Text = StrReplace(Query.Text, "DataTable.Duplicate1.Code", """""");
			EndIf;
			If ObjectMetadata.DescriptionLength = 0 Then
				Query.Text = StrReplace(Query.Text, "DataTable.Duplicate1.Description", """""");
			EndIf;
	
			SampleGroup = Query.Execute().Select(QueryResultIteration.ByGroups);
			DataTable.Columns.Add("Group");
			DataTable.Columns.Add("Code");
			While SampleGroup.Next() Do
				Selection = SampleGroup.Select();
				ItemArray = New Array;
				While Selection.Next() Do
					ItemArray.Add(Selection.Description);
					DataRows = DataTable.FindRows(New Structure("Duplicate1", Selection.Ref));
					DataRows[0].Code = Selection.Code;
				EndDo;
				GroupDescription = InformationRegisters.MasterDataDuplicatesToConfirm.GroupPresentation(ItemArray);
				TheStructureOfTheSearch = New Structure("DuplicatesGroup", SampleGroup.DuplicatesGroup);
				DataRows = DataTable.FindRows(TheStructureOfTheSearch);
				For Each String In DataRows Do
					String.Group = GroupDescription;
				EndDo;
			EndDo;
		EndIf;
	EndIf;
	StructureOfData = New Structure;
	StructureOfData.Insert("DataTable", DataTable);
	
	DCSSettings = SettingsComposer.GetSettings();
	TemplateComposer = New DataCompositionTemplateComposer;
	Template = TemplateComposer.Execute(DataCompositionSchema, DCSSettings, DetailsData);
	DCSLayoutProcessor = New DataCompositionProcessor;
	DCSLayoutProcessor.Initialize(Template, StructureOfData, DetailsData);
	ResultDocument.Clear();
	
	OutputProcessor = New DataCompositionResultSpreadsheetDocumentOutputProcessor;
	OutputProcessor.SetDocument(ResultDocument);
	OutputProcessor.Output(DCSLayoutProcessor);
EndProcedure

#EndRegion

#Region Internal

// StandardSubsystems.ReportsOptions

// To set up a report form.
//
// Parameters:
//   Form - ClientApplicationForm
//         - Undefined
//   VariantKey - String
//                - Undefined
//   Settings - See ReportsClientServer.DefaultReportSettings
//
Procedure DefineFormSettings(Form, VariantKey, Settings) Export
	
	Settings.Events.BeforeImportSettingsToComposer = True;
	
EndProcedure

// Called before loading new settings. used to change the DCS of the report.
//
// Parameters:
//   Context - Arbitrary
//   SchemaKey - String
//   VariantKey - String
//                - Undefined
//   NewDCSettings - DataCompositionSettings
//                    - Undefined
//   NewDCUserSettings - DataCompositionUserSettings
//                                    - Undefined
//
Procedure BeforeImportSettingsToComposer(Context, SchemaKey, VariantKey, NewDCSettings, NewDCUserSettings) Export
	If TypeOf(Context) = Type("ClientApplicationForm") And Context.Parameters.Property("Rule") Then 
		NewDCSettings.DataParameters.SetParameterValue("Rule",Context.Parameters.Rule);
	EndIf;	
EndProcedure

#EndRegion

#Region Initialize

#EndRegion

#Else
Raise NStr("ru = 'Недопустимый вызов объекта на клиенте.';
			|vi = 'Invalid object call on the client.';
			|en = 'Invalid object call on the client.'; fa = 'Invalid object call on the client.';
			|it = 'Chiamata di oggetto non valida sul client.';
			|pl = 'Niedozwolone wezwanie obiektu na kliencie.';
			|tr = 'İstemcide geçersiz nesne çağrısı.'");
#EndIf