#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Generate a report.
// 
// Parameters:
//  ReportTable      - SpreadsheetDocument - it displays a report
//  ObjectForScripts - CatalogRef, DocumentRef - the object for which the report is generated
//
Procedure GenerateReport(ReportTable, ObjectForScripts)  Export
	
	SetPrivilegedMode(True);
	
	If TypeOf(ObjectForScripts) = Type("CatalogRef.MetadataObjectIDs") Then
	
		DataToFill = DataToFillInDemoScenariosOfObject(ObjectForScripts); 
	Else
		
		DataToFill = DataToFillOutDemoProfileScenarios(ObjectForScripts);
		
	EndIf;
	
	ReportTable = TabularDocumentObjectDemonstrationScenarios(DataToFill);
	
	If PrivilegedMode() Then
		SetPrivilegedMode(False);
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function TabularDocumentObjectDemonstrationScenarios(DataToFill) Export
	
	SpreadsheetDocument = New SpreadsheetDocument;
	
	Template = GetTemplate("DemoScenarios");
	HeaderArea_ = Template.GetArea("Title");
	
	HeaderArea_.Parameters.TitleText = 
		StrTemplate(NStr("vi = 'Mô tả các quy trình ""%1""';
						|ru = 'Описания процессов ""%1""';
						|en = 'Process details %1'; fa = 'Process details %1';
						|it = 'Описания процессов ""%1""';
						|pl = 'Process details %1';
						|tr = '""%1"" süreçlerinin açıklamaları'"), DataToFill.MetadataObjectPresentation); 
	
	SpreadsheetDocument.Put(HeaderArea_);
	
	Level = 0; 
	
	For Each TreeRow In DataToFill.ScenarioTree.Rows Do
		 PrintScriptLineTabularDocument(TreeRow, SpreadsheetDocument, Template, Level);
	EndDo;
		
	Return SpreadsheetDocument;
	
EndFunction

Procedure PrintScriptLineTabularDocument(TreeRow, SpreadsheetDocument, Template, Val Level)
	
	ParentRow = TreeRow.Parent;
	
	If ParentRow <> Undefined 
		And ParentRow.Ref = TreeRow.Ref Then
		Return;
	EndIf;
	
	IndentationAreaIsGeneral = Template.GetArea("IndentationAreaIsGeneral");
	SpreadsheetDocument.Put(IndentationAreaIsGeneral);
	
	IndentationAreaGrouping = Template.GetArea("IndentationAreaGrouping");
	
	Indus = 1;
	While Indus <= Level Do
		
		SpreadsheetDocument.Join(IndentationAreaGrouping);
		Indus = Indus + 1;
		
	EndDo;
	
	ScenarioArea = Template.GetArea("ScenarioArea");
	ScenarioArea.Parameters.NameOfScript = TreeRow.Description;
	ScenarioArea.Parameters.LinkToScript     = TreeRow.Ref;
	If TreeRow.IsFolder Then
		ScenarioArea.Areas.ScenarioArea.TextColor = StyleColors.TextColorGroupBranching;
	EndIf;

	If TreeRow.GroupType = 1 Or TreeRow.GroupType = Enums.TypesOfProcessDetailsGroups.Branching Then
		ScenarioArea.Parameters.ScriptPicture = PictureLib.Help;
	EndIf;
	
	SpreadsheetDocument.Join(ScenarioArea);
	
	Level = Level + 1;
	For Each SubordinateRow In TreeRow.Rows Do
		 PrintScriptLineTabularDocument(SubordinateRow, SpreadsheetDocument, Template, Level);
	EndDo;
	
EndProcedure

Function DataToFillInDemoScenariosOfObject(ObjectForScripts)
	
	DataToFill = New Structure;
	DataToFill.Insert("MetadataObjectPresentation", "");
	DataToFill.Insert("ScenarioTree",                New ValueTree);
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	DemoScenarios.Ref       AS Ref, 
	|	DemoScenarios.Description AS Description,
	|	DemoScenarios.GroupType    AS GroupType,
	|	DemoScenarios.IsFolder    AS IsFolder
	|FROM
	|	Catalog.DemoScenarios.ConfigurationObjects AS DemoScenariosConfigurationObjects
	|		INNER JOIN Catalog.DemoScenarios AS DemoScenarios
	|		ON DemoScenariosConfigurationObjects.Ref = DemoScenarios.Ref
	|WHERE
	|	DemoScenariosConfigurationObjects.ConfigurationObject = &MetadataObjectID
	|
	|ORDER BY
	|	DemoScenarios.Description
	|TOTALS BY
	|	Ref HIERARCHY";
	
	If Not ValueIsFilled(ObjectForScripts) Then
		Return DataToFill;
	EndIf;
	
	DataToFill.MetadataObjectPresentation = String(ObjectForScripts);
	
	Query.SetParameter("MetadataObjectID", ObjectForScripts); 
	
	NationalLanguageSupportServer.ChangeRequestFieldUnderCurrentLanguage(Query.Text, "Description");
	
	DataToFill.ScenarioTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy); 
	
	NameOfFieldToChange = DemoScenarios.NameOfMultilingualAttribute("Description");
	DataToFill.ScenarioTree.Columns[NameOfFieldToChange].Name = "Description";
	
	Return DataToFill;
	
EndFunction 

Function DataToFillOutDemoProfileScenarios(ObjectForScripts)
	
	DataToFill = New Structure;
	DataToFill.Insert("MetadataObjectPresentation", "");
	DataToFill.Insert("ScenarioTree",                Undefined);
	
	Query = New Query;
	
	Query.Text =
	"SELECT
	|	DemoScenarios.Ref       AS Ref, 
	|	DemoScenarios.Description AS Description,
	|	DemoScenarios.GroupType    AS GroupType,
	|	DemoScenarios.IsFolder    AS IsFolder
	|FROM
	|	Catalog.DemoScenarios.AccessGroupProfiles AS DemoScenariosAccessGroupProfiles
	|		INNER JOIN Catalog.DemoScenarios AS DemoScenarios
	|		ON DemoScenariosAccessGroupProfiles.Ref = DemoScenarios.Ref
	|WHERE
	|	DemoScenariosAccessGroupProfiles.Profile = &AccessGroupsProfile
	|
	|ORDER BY
	|	DemoScenarios.Description
	|TOTALS BY
	|	Ref HIERARCHY";
	
	If Not ValueIsFilled(ObjectForScripts) Then
		Return DataToFill;
	EndIf;
	
	DataToFill.MetadataObjectPresentation = StrTemplate("%1 (%2)", String(ObjectForScripts), NStr("vi = 'Hồ sơ nhóm truy cập';
																									|ru = 'Профиль групп доступа';
																									|en = 'Access group profile'; fa = 'پروفایل گروه دسترسی';
																									|it = 'Profili dei gruppi di accesso';
																									|pl = 'Profil grup dostępu';
																									|tr = 'Grup profiline erişmek'"));
	
	Query.SetParameter("AccessGroupsProfile", ObjectForScripts); 
	
	DataToFill.ScenarioTree = Query.Execute().Unload(QueryResultIteration.ByGroupsWithHierarchy);
	
	Return DataToFill;
	
	
EndFunction


#EndRegion

#EndIf