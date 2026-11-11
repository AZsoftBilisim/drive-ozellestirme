#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region EventHandlers

Procedure BeforeWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	InfobaseUpdate.CheckObjectProcessed(ThisObject);
	
	CalculateConnections = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	If CalculateConnections Then
	
		AdditionalProperties.Insert("TimeStampAnalogsOfMaterials", CurrentUniversalDateInMilliseconds());
		
		Query = New Query;
		Query.TempTablesManager = New TempTablesManager;
		
		Query.Text = QueryTextMaterialsAndAnalogues("MaterialsAndAnaloguesBeforeWrite");
		
		Query.SetParameter("Recorder", Filter.Recorder.Value);
		
		Selection = Query.Execute().Select();
		If Selection.Next() And Selection.Count > 0 Then
			AdditionalProperties.Insert("ManagerOfTemporaryTablesAnalogsOfMaterials", Query.TempTablesManager);
		EndIf;
		
	EndIf;
	
EndProcedure

Procedure OnWrite(Cancel, Replacing)
	
	If DataExchange.Load Then
		Return;
	EndIf;
	
	CalculateConnections = GetFunctionalOption("DynamicStructureOfProductionOrders");
	
	If CalculateConnections Then
	
		CurrentRegistrar = Filter.Recorder.Value;
	
		TaskTable = Undefined;
		
		TempTablesManager = Undefined;
		
		If AdditionalProperties.Property("ManagerOfTemporaryTablesAnalogsOfMaterials", TempTablesManager) Then
			
			QueryTexts = New Array;
			QueryTexts.Add(QueryTextMaterialsAndAnalogues("MaterialsAndAnalogsForRecording"));
			
			QueryText =
			"SELECT
			|	Table.Products      AS Products,
			|	Table.Characteristic    AS Characteristic,
			|	Table.ReplacementPriority   AS ReplacementPriority,
			|	SUM(Table.Count) AS Count
			|FROM
			|	(SELECT
			|		Table.Products    AS Products,
			|		Table.Characteristic  AS Characteristic,
			|		Table.ReplacementPriority AS ReplacementPriority,
			|		Table.Count      AS Count
			|	FROM
			|		MaterialsAndAnalogsForRecording AS Table
			|
			|	UNION ALL
			|
			|	SELECT
			|		Table.Products    AS Products,
			|		Table.Characteristic  AS Characteristic,
			|		Table.ReplacementPriority AS ReplacementPriority,
			|		-Table.Count     AS Count
			|	FROM
			|		MaterialsAndAnaloguesBeforeWrite AS Table) AS Table
			|GROUP BY
			|	Table.Products,
			|	Table.Characteristic,
			|	Table.ReplacementPriority
			|HAVING
			|	SUM(Table.Count) <> 0";
			
			QueryTexts.Add(QueryText);
			
			Query = New Query;
			Query.TempTablesManager = TempTablesManager;
			
			Query.Text = StrConcat(QueryTexts, Common.QueryBatchSeparator());
			
			Query.SetParameter("Recorder", CurrentRegistrar);
			
			Result = Query.Execute();
			If Not Result.IsEmpty() Then
				
				Queue       = "JobsForCalculatingItemLinksByChangeOrders";
				TaskTable = DeferredJobs.InitializeTaskTable(Queue)[0].Jobs;
				
				TimeStampAnalogsOfMaterials = AdditionalProperties.TimeStampAnalogsOfMaterials;
				
				TemporaryTable = TempTablesManager.Tables;
				
				ResultOldRecords = TemporaryTable["MaterialsAndAnaloguesBeforeWrite"].GetData();
				If Not ResultOldRecords.IsEmpty() Then
					
					SamplingOldRecords = ResultOldRecords.Select();
					While SamplingOldRecords.Next() Do
						
						TableRow = TaskTable.Add();
						TableRow.Resolution       = CurrentRegistrar;
						TableRow.Products   = SamplingOldRecords.Products;
						TableRow.Characteristic = SamplingOldRecords.Characteristic;
						TableRow.Timestamp1 = TimeStampAnalogsOfMaterials;
						TableRow.OldRecord   = True;
						
					EndDo;
					
				EndIf;
				
				ResultNewEntries = TemporaryTable["MaterialsAndAnalogsForRecording"].GetData();
				If Not ResultNewEntries.IsEmpty() Then
					
					SamplingNewRecords = ResultNewEntries.Select();
					While SamplingNewRecords.Next() Do
						
						TableRow = TaskTable.Add();
						TableRow.Resolution       = CurrentRegistrar;
						TableRow.Products   = SamplingNewRecords.Products;
						TableRow.Characteristic = SamplingNewRecords.Characteristic;
						TableRow.Timestamp1 = TimeStampAnalogsOfMaterials;
						
					EndDo;
					
				EndIf;
				
			EndIf;
			
			AdditionalProperties.Delete("ManagerOfTemporaryTablesAnalogsOfMaterials");
			
		Else
			
			Query = New Query;
			Query.Text = QueryTextMaterialsAndAnalogues();
			
			Query.SetParameter("Recorder", CurrentRegistrar);
			
			ResultNewEntries = Query.Execute();
			If Not ResultNewEntries.IsEmpty() Then
				
				Queue       = "JobsForCalculatingItemLinksByChangeOrders";
				TaskTable = DeferredJobs.InitializeTaskTable(Queue)[0].Jobs;
				
				TimeStampAnalogsOfMaterials = AdditionalProperties.TimeStampAnalogsOfMaterials;
				
				SamplingNewRecords = ResultNewEntries.Select();
				While SamplingNewRecords.Next() Do
					
					TableRow = TaskTable.Add();
					TableRow.Resolution       = CurrentRegistrar;
					TableRow.Products   = SamplingNewRecords.Products;
					TableRow.Characteristic = SamplingNewRecords.Characteristic;
					TableRow.Timestamp1 = TimeStampAnalogsOfMaterials;
					
				EndDo;
			
			EndIf;
			
		EndIf;
		
		AdditionalProperties.Delete("TimeStampAnalogsOfMaterials");
		
		If ValueIsFilled(TaskTable) Then
			DeferredJobs.ProcessQueueTasks(Queue, TaskTable);
		EndIf;	
	
	EndIf;
	
EndProcedure

#EndRegion

#Region Private

Function QueryTextMaterialsAndAnalogues(TempTableName = "")
	
	QueryText =
	"SELECT
	|	Table.Products                                                       AS Products,
	|	Table.Characteristic                                                     AS Characteristic,
	|	Table.ReplacementPriority                                                    AS ReplacementPriority,
	|	Table.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS Count
	|INTO TempTableName
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	Table.Recorder = &Recorder
	|	AND Table.ProductsRole IN (
	|					VALUE(Enum.SubstituteRoles.Material),
	|					VALUE(Enum.SubstituteRoles.InterchangeableSubstitute))
	|	AND Table.UseItForAutocorrectInOrders
	|
	|UNION ALL
	|
	|SELECT
	|	Table.Products                                                       AS Products,
	|	Table.Characteristic                                                     AS Characteristic,
	|	Table.ReplacementPriority                                                    AS ReplacementPriority,
	|	Table.NumberOfPackages * ISNULL(&QueryTextPackagingFactor, 1) AS Count
	|FROM
	|	InformationRegister.AlternativeMaterials AS Table
	|WHERE
	|	Table.Recorder        = &Recorder
	|	AND Table.ProductsRole = VALUE(Enum.SubstituteRoles.Substitute)
	|	AND Table.UseItForAutocorrectInOrders
	|	AND NOT TRUE IN
	|			(SELECT TOP 1
	|				TRUE
	|			FROM
	|				InformationRegister.AlternativeMaterials AS TableOfMaterials
	|			WHERE
	|				TableOfMaterials.Recorder        = Table.Recorder
	|				AND TableOfMaterials.Products     = Table.Products
	|				AND TableOfMaterials.Characteristic   = Table.Characteristic
	|				AND TableOfMaterials.ProductsRole = VALUE(Enum.SubstituteRoles.Material))";
	
	If ValueIsFilled(TempTableName) Then
		QueryText = StrReplace(QueryText, "TempTableName", TempTableName);
	Else
		QueryText = StrReplace(QueryText, "INTO TempTableName", "");
	EndIf;
	
	QueryText = StrReplace(
						QueryText,
						"&QueryTextPackagingFactor",
						Catalogs.PackagesAndUnitsOfMeasure.RequestTextForPackingCoefficient(
							"Table.Package",
							"Table.Products"));
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf