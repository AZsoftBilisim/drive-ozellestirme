#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// To use in the procedure add a create command Based on other object Manager modules.
// Adds this object to the list of base creation commands.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//
// Returns:
//  ValueTableRow, Undefined - description of the added command.
//
Function AddGenerateCommand(GenerationCommands) Export
	
	Return GenerateFrom.AddGenerationCommand(GenerationCommands, Metadata.Catalogs.SubAssets);
	
EndFunction

// StandardSubsystems.Print

// Overrides the printing settings for the object.
//
// Parameters:
//  Settings - See PrintManagement.ObjectPrintingSettings.
//
Procedure OnDefinePrintSettings(Settings) Export
	
	Settings.OnAddPrintCommands = True;
	
EndProcedure

// End StandardSubsystems.Print

#EndRegion

// Fills in nodes for the specified selection
//
// Parameters:
// 		Filter - Structure - The structure of the selection object
// 		StructureOfAdditionalProperties - Structure - Structure of additional properties for recording an object
// 		Cancel - Boolean - return, indicates that the procedure failed.
//
Procedure FillInByPicking(Filter, StructureOfAdditionalProperties, Cancel=False) Export
	
	Query = New Query(
		"SELECT
		|	SubAssets.Parent AS Parent,
		|	SubAssets.Ref AS Ref
		|FROM
		|	Catalog.SubAssets AS SubAssets
		|WHERE
		|	(&SelectingParentField
		|			AND SubAssets.Ref <> &Parent
		|			AND SubAssets.Ref IN HIERARCHY (&Parent)
		|		OR &SelectingOwnerField
		|			AND SubAssets.Owner = &Owner)
		|
		|ORDER BY
		|	Parent");
	
	StructureOfRequestParameters = New Structure("Parent, Owner");
	FillPropertyValues(StructureOfRequestParameters, Filter);
	
	Query.SetParameter("Parent", StructureOfRequestParameters.Parent);
	Query.SetParameter("Owner", StructureOfRequestParameters.Owner);
	Query.SetParameter("SelectingParentField", ValueIsFilled(StructureOfRequestParameters.Parent));
	Query.SetParameter("SelectingOwnerField", ValueIsFilled(StructureOfRequestParameters.Owner));
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return;
	EndIf;
	
	SelectionTraversalArray = New Array;
	SelectionTraversalArray.Add(StructureOfRequestParameters.Parent);
	SampleTraversalStructure = New Structure("Parent");
	SampleTraversalCount = 0;
	
	Selection = Result.Select();
	
	While SampleTraversalCount < SelectionTraversalArray.Count() Do
		Selection.Reset();
		SampleTraversalStructure.Parent = SelectionTraversalArray[SampleTraversalCount];
		While Selection.FindNext(SampleTraversalStructure) Do
			
			SelectionTraversalArray.Add(Selection.Ref);
			
			ObjectOfCatalog = Selection.Ref.GetObject(); // CatalogObject.SubAssets - 
			ObjectOfCatalog.InitializeAdditionalPropertiesForRecord(StructureOfAdditionalProperties);
			
			Try
				ObjectOfCatalog.Write();
			Except
				Cancel = True;
				Return;
			EndTry;
			
		EndDo;
		
		SampleTraversalCount = SampleTraversalCount + 1;
		
	EndDo;
	
EndProcedure

// Returns a description of the operation object's details
//
// Returns:
// 		ValueTable - The table of the composition of the details.
//
Function AttributeSet() Export
	
	// Description of the format of the returned details table
	Table = New ValueTable;
	Table.Columns.Add("Name", New TypeDescription("String"));
	Table.Columns.Add("Synonym", New TypeDescription("String"));
	Table.Columns.Add("RequiredForFilling", New TypeDescription("Boolean"));
	Table.Columns.Add("RequiredForViewOnly", New TypeDescription("Boolean"));
	
	// The values to be filled in by default in the row of each of the details
	DefaultValues = New Structure;
	DefaultValues.Insert("Name", "");
	DefaultValues.Insert("Synonym", "");
	DefaultValues.Insert("RequiredForFilling", "False");
	DefaultValues.Insert("RequiredForViewOnly", "False");
	
	// Descriptions of the details, with parameter values different from the "default"
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("Status", New Structure("RequiredForFilling, RequiredForViewOnly", True, True));
	AttributesStructure1.Insert("Class", New Structure("RequiredForViewOnly", True));
	AttributesStructure1.Insert("Subclass", New Structure("RequiredForFilling, RequiredForViewOnly", False, True));
	AttributesStructure1.Insert("ObjectType", New Structure("RequiredForViewOnly", True));
	
	// A list of details that should be excluded: service, unused, intended for deletion, Boolean attributes
	// 		or any other not intended for interactive user configuration.
	StopList = New Structure(
		"LongDesc,
		|InfluenceOnWorkCenterAvailability,
		|Belonging");
	
	// Getting the details table from the metadata description
	StructureOfCatalog = Metadata.Catalogs.SubAssets;
	For Each Attribute In StructureOfCatalog.Attributes Do
		
		If StopList.Property(Attribute.Name) Then
			Continue;
		EndIf;
		
		PropsString = Table.Add();
		FillPropertyValues(PropsString, DefaultValues);
		FillPropertyValues(PropsString, Attribute);
		
		PropsString.RequiredForFilling = (Attribute.FillChecking = FillChecking.ShowError);
		
		If AttributesStructure1.Property(Attribute.Name) Then
			FillPropertyValues(PropsString, AttributesStructure1[Attribute.Name]);
		EndIf;
		
	EndDo;
	
	Return Table;
	
EndFunction

// Returns the structure of fill check parameters
//
// Returns:
// 		Structure - Structure of the fill check.
//
Function FillVerificationParameters() Export
	
	Parameters = New Structure;
	
	Parameters.Insert("ErrorStream", New Structure);
	Assets.InitializeErrorFlow(Parameters.ErrorStream);
	
	Parameters.Insert("Report_Errors", True);
	Parameters.Insert("Form", Undefined);
	
	Return Parameters;
	
EndFunction

// Procedure for checking the filling of the node of the operation object
//
// Parameters:
// 		VerificationObject - Array of CatalogRef.SubAssets, CatalogRef.SubAssets - Reference to the object or array of objects being checked
// 		CheckParameters - Structure - Structure of object validation parameters
// 		Cancel - Boolean - return, indicates that the procedure failed
// 		CachedValues - Structure - The cached value of the test fill.
//
Procedure CheckFilling(VerificationObject, CheckParameters, Cancel, CachedValues=Undefined) Export
	
	Assets.InitializeCachedFillCheckValues(CachedValues);
	
	ObjectType = TypeOf(VerificationObject);
	
	If ObjectType = Type("CatalogRef.SubAssets")
		Or ObjectType = Type("Array") Then
		
		Query = New Query;
		Query.SetParameter("Nodes", VerificationObject);
		
		Selection = Query.Execute().Select();
		While Selection.Next() Do
			
			CheckNodeOfObjectOfOperation(
				Selection,
				CheckParameters,
				CachedValues);
			
		EndDo;
		
	Else
		
		CheckNodeOfObjectOfOperation(
			VerificationObject,
			CheckParameters,
			CachedValues);
		
	EndIf;
	
	If CheckParameters.ErrorStream.ErrorList.Count() <> 0 Then
		Cancel = True;
	EndIf;
	
	If CheckParameters.Report_Errors Then
		Assets.ReportFillVerificationErrors(CheckParameters.ErrorStream, Cancel);
	EndIf;
	
EndProcedure

// Defines a list of creation commands based on.
//
// Parameters:
//  GenerationCommands - See GenerateFromOverridable.BeforeAddGenerationCommands.GenerationCommands
//  Parameters - See GenerateFromOverridable.BeforeAddGenerationCommands.Parameters
//
Procedure AddGenerationCommands(GenerationCommands, Parameters) Export
	
	Documents.RMOrder.AddGenerateCommand(GenerationCommands);
	Documents.SetRunningTimeValues.AddGenerateCommand(GenerationCommands);
	
EndProcedure

#EndRegion

#Region Private

Function GetRequiredBankingDetails(Class, CachedValues)
	
	RequiredDetails_ = CachedValues.RequiredDetails_.Get(Class);
	
	If RequiredDetails_ = Undefined Then
		
		Query = New Query;
		
		If ValueIsFilled(Class) Then
			Query.Text =
				"SELECT
				|	DetailsForNodeControl.Name,
				|	DetailsForNodeControl.Synonym
				|FROM
				|	Catalog.MaintenanceSchemes.AttributesForControl AS Attributes
				|		INNER JOIN DetailsOfNodes AS DetailsForNodeControl
				|		ON Attributes.AttributeName = DetailsForNodeControl.Name
				|WHERE
				|	Attributes.Ref = &Class
				|	AND Attributes.RequiredForFilling"
			;
		Else
			Query.Text =
				"SELECT
				|	Attributes.Name,
				|	Attributes.Synonym
				|FROM
				|	DetailsOfNodes AS Attributes
				|WHERE
				|	Attributes.RequiredForFilling"
			;
			
		EndIf;
		Query.TempTablesManager = CachedValues.TempTablesManager;
		Query.SetParameter("Class", Class);
		
		RequiredDetails_ = Query.Execute().Unload();
		
		CachedValues.RequiredDetails_.Insert(Class, RequiredDetails_);
		
	EndIf;
	
	Return RequiredDetails_;
	
EndFunction

Function GetPerformanceAccountingParameters(Class, CachedValues)
	
	RunningTimeRecordingParameters = CachedValues.RunningTimeRecordingParameters.Get(Class);
	
	If RunningTimeRecordingParameters = Undefined Then
		
		Query = New Query(
			"SELECT
			|	Parameters.RunningTimeValue AS RunningTimeValue,
			|	Parameters.CalculateResidualLifetime AS FillOutTheAssignedResource,
			|	Parameters.RegisterBySource AS FillInTheSource
			|FROM
			|	Catalog.MaintenanceSchemes.RunningTimeValues AS Parameters
			|WHERE
			|	Parameters.Ref = &Class
			|	AND (Parameters.RegisterBySource
			|			OR Parameters.CalculateResidualLifetime)");
		Query.TempTablesManager = CachedValues.TempTablesManager;
		Query.SetParameter("Class", Class);
		
		RunningTimeRecordingParameters = Query.Execute().Unload();
		
		CachedValues.RunningTimeRecordingParameters.Insert(Class, RunningTimeRecordingParameters);
		
	EndIf;
	
	Return RunningTimeRecordingParameters;
	
EndFunction

Procedure CheckNodeOfObjectOfOperation(VerificationObject, CheckParameters, CachedValues)
	
	CheckBankingDetails(VerificationObject, CheckParameters, CachedValues);
	
	CheckParametersOfAccountingOfDevelopments(VerificationObject, CheckParameters, CachedValues);
	
EndProcedure

Procedure CheckBankingDetails(VerificationObject, CheckParameters, CachedValues)
	
	RequiredDetails_ = GetRequiredBankingDetails(VerificationObject.Class, CachedValues);
	
	For Each Attribute In RequiredDetails_ Do
		
		If Not ValueIsFilled(VerificationObject[TrimAll(Attribute.Name)]) Then
			
			ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
				NStr("vi = 'Chưa điền trường  ""%1"".';
					|ru = 'Поле ""%1"" не заполнено.';
					|en = 'Field %1 is required.'; fa = 'Field %1 is required.';
					|it = 'Il campo ""%1"" non è compilato.';
					|pl = 'Nie wypełniono pola ""%1"".';
					|tr = '""%1"" gerekli.'"),
				TrimAll(Attribute.Synonym));
			
			Assets.AddUserError(
				CheckParameters.ErrorStream,
				VerificationObject.Ref,
				"Object."+Attribute.Name,
				ErrorText,
				"Attributes",
				0,
				ErrorText);
			
		EndIf;
		
	EndDo;
	
EndProcedure

Procedure CheckParametersOfAccountingOfDevelopments(VerificationObject, CheckParameters, CachedValues)
	
	If CheckParameters.Form = Undefined Then
		
		OperatingTimeAccountingParameters = GetPerformanceAccountingParameters(VerificationObject.Class, CachedValues);
		
		ParametersTable = TableParametersOfAccountingOfDevelopments(VerificationObject.RunningTimeRecordingParameters); 
		
		For Each ConfiguringMetric In OperatingTimeAccountingParameters Do
			
			String = ParametersTable.Find(ConfiguringMetric.RunningTimeValue, "RunningTimeValue");
			
			If String = Undefined Or (ConfiguringMetric.FillOutTheAssignedResource And Not ValueIsFilled(String.AssignedResource)) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chỉ định nguồn chỉ tiêu sản lượng ""%1"" chưa được điền';
						|ru = 'Назначенный ресурс показателя наработки ""%1"" не заполнен';
						|en = 'Specify lifetime for the ""%1"" asset activity measure'; fa = 'Specify lifetime for the ""%1"" asset activity measure';
						|it = 'La risorsa assegnata dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è compilata';
						|pl = 'Nie wypełniono wyznaczonego źródła wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşlem süresi göstergesinin atanman kaynağı ""%1"" tamamlanmadı'"),
					ConfiguringMetric.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters",
					ErrorText,
					"RunningTimeRecordingParameters",
					0,
					ErrorText);
				
			EndIf;
			
			If String = Undefined Or (ConfiguringMetric.FillInTheSource And Not ValueIsFilled(String.SourceOfParameter)) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nguồn của các giá trị hiện tại của chỉ báo sản lượng ""%1"" không được điền';
						|ru = 'Источник текущих значений показателя наработки ""%1"" не заполнен';
						|en = 'Specify the source of the current values of ""%1"" asset activity'; fa = 'Specify the source of the current values of ""%1"" asset activity';
						|it = 'La fonte dei valori correnti dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è indicata';
						|pl = 'Nie wypełniono źródła bieżących wartości wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşletim süresi göstergesi ""%1'''' mevcut değerlerinin kaynağı doldurulmamış'"),
					ConfiguringMetric.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters",
					ErrorText,
					"RunningTimeRecordingParameters",
					0,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
	Else
		
		If CheckParameters.Form.RunningTimeRecordingParameters.Count()=0 Then
			Return;
		EndIf;
		
		For CurIndex__=0 To CheckParameters.Form.RunningTimeRecordingParameters.Count()-1 Do
			
			String = CheckParameters.Form.RunningTimeRecordingParameters[CurIndex__];
			
			If String.FillOutTheAssignedResource And Not ValueIsFilled(String.AssignedResource) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Chỉ định nguồn chỉ tiêu sản lượng ""%1"" chưa được điền';
						|ru = 'Назначенный ресурс показателя наработки ""%1"" не заполнен';
						|en = 'Specify lifetime for the ""%1"" asset activity measure'; fa = 'Specify lifetime for the ""%1"" asset activity measure';
						|it = 'La risorsa assegnata dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è compilata';
						|pl = 'Nie wypełniono wyznaczonego źródła wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşlem süresi göstergesinin atanman kaynağı ""%1"" tamamlanmadı'"),
					String.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters[%1].AssignedResource",
					ErrorText,
					"RunningTimeRecordingParameters",
					CurIndex__,
					ErrorText);
				
			EndIf;
			
			If String.FillInTheSource And Not ValueIsFilled(String.SourceOfParameter) Then
				
				ErrorText = StringFunctionsClientServer.SubstituteParametersToString(
					NStr("vi = 'Nguồn của các giá trị hiện tại của chỉ báo sản lượng ""%1"" không được điền';
						|ru = 'Источник текущих значений показателя наработки ""%1"" не заполнен';
						|en = 'Specify the source of the current values of ""%1"" asset activity'; fa = 'Specify the source of the current values of ""%1"" asset activity';
						|it = 'La fonte dei valori correnti dell''indicatore del tempo di funzionamento senza guasti ""%1"" non è indicata';
						|pl = 'Nie wypełniono źródła bieżących wartości wskaźnika średniego czasu pracy ""%1""';
						|tr = 'İşletim süresi göstergesi ""%1'''' mevcut değerlerinin kaynağı doldurulmamış'"),
					String.RunningTimeValue);
				
				Assets.AddUserError(
					CheckParameters.ErrorStream,
					VerificationObject.Ref,
					"RunningTimeRecordingParameters[%1].FormObject",
					ErrorText,
					"RunningTimeRecordingParameters",
					CurIndex__,
					ErrorText);
				
			EndIf;
			
		EndDo;
		
	EndIf;
	
EndProcedure

// Parameters:
// 	RunningTimeRecordingParameters - TabularSection - 
// Returns:
// 	ValueTable:
//		* RunningTimeValue - CatalogRef.RunningTimeValues - 
//      * AssignedResource - Number -  
//      * SourceOfParameter - CatalogRef.Assets -
//      * ValueOffset - Number -
Function TableParametersOfAccountingOfDevelopments(RunningTimeRecordingParameters)
	
	Return RunningTimeRecordingParameters.Unload();
	
EndFunction

#Region Reports

// Fills in the list of print commands.
//
// Parameters:
//   PrintCommands - See PrintManagement.CreatePrintCommandsCollection
//
Procedure AddPrintCommands(PrintCommands) Export
	
	If AccessRight("View", Metadata.DataProcessors.LabelPrintingOfSubAssets) Then
		
		PrintCommand = PrintCommands.Add();
		PrintCommand.Handler = "RMManagementClient.LabelPrintingOfSubAssets";
		PrintCommand.Id = "LabelOfNodesOfObjectsOfOperation";
		PrintCommand.Presentation = NStr("vi = 'Nhãn tem';
										|ru = 'Этикетки';
										|en = 'Labels'; fa = 'برچسب‌ها';
										|it = 'Etichette';
										|pl = 'Labels';
										|tr = 'Etiketler'");
		
	EndIf;
	
EndProcedure

// Defines a list of report commands.
//
// Parameters:
//   ReportsCommands - See ReportsOptionsOverridable.BeforeAddReportCommands.ReportsCommands
//   Parameters - See ReportsOptionsOverridable.BeforeAddReportCommands.Parameters
//
Procedure AddReportCommands(ReportsCommands, Parameters) Export
	
	Reports.StateOfSubAssetsContext.AddReportCommand(ReportsCommands);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf