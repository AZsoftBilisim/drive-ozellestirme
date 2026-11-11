#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

// Returns the next operation number within the specified owner (route map, stage, process).
//
// Parameters:
//  Owner - CatalogRef.RouteSheets,CatalogRef.ProductionStages - the owner of operations in which
//		you need to get the next number.
//
// Returns:
//   Number - The new operation number.
//
Function NewOperationNumber(Owner) Export
	
	If Owner.IsEmpty() Then
		Return 1;
	EndIf;
	
	Query = New Query;
	Query.Text = "
	|SELECT TOP 1
	|	ManufacturingOperations.OperationNumber AS OperationNumber
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	ManufacturingOperations.Owner = &Owner
	|	AND NOT ManufacturingOperations.DeletionMark
	|
	|ORDER BY
	|	OperationNumber DESC";
	
	Query.SetParameter("Owner", Owner);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 1;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	Return Selection.OperationNumber + 1;

EndFunction

// Returns the next ID inside the specified route map.
//
// Parameters:
//  Owner  - CatalogRef.RouteSheets,CatalogRef.ProductionStages,CatalogRef.TechnologicalProcesses	 - the owner of transactions
//  Failure-Boolean-indicates that the action was refused.
// 
// Returns:
//  Number - New Operation ID.
//
Function NewOperationID(Owner) Export
	
	If Not TransactionActive() Then
		Raise NStr("vi = 'Nhận một định danh giao dịch mới chỉ có thể được thực hiện trong một giao dịch.';
					|ru = 'Получение нового идентификатора операции может выполняться только в транзакции.';
					|en = 'New operation ID can be received only in a transaction.'; fa = 'New operation ID can be received only in a transaction.';
					|it = 'L''ottenimento di un nuovo identificatore dell''operazione è possibile solo durante la transazione.';
					|pl = 'Uzyskiwanie nowego identyfikatora operacji może być wykonywane tylko w transakcji.';
					|tr = 'Yeni bir işlem tanımlayıcısı almak sadece işlem (transaction) üzerinden gerçekleştirilebilir.'");
	EndIf;
	
	If Owner.IsEmpty() Then
		Return 1;
	EndIf;

	DataLock = New DataLock;
	
	LockItem = DataLock.Add("Catalog.ManufacturingOperations");
	LockItem.SetValue("Owner", Owner);
	
	Try
		
		DataLock.Lock();
		
	Except
		
		ExceptionText = StrTemplate(
			NStr("vi = 'Không thể nhận tên định danh mới cho giao dịch với đối tượng %1.';
				|ru = 'Не удалось получить новый идентификатор операции для объекта %1.';
				|en = 'Cannot get new operation ID for object %1.'; fa = 'Cannot get new operation ID for object %1.';
				|it = 'Non è stato possibile ottenere un nuovo identificatore dell''operazione per l''oggetto %1.';
				|pl = 'Nie udało się otrzymać nowego identyfikatora operacji dla obiektu %1.';
				|tr = '%1 nesnesi için yeni işlem tanımlayıcısı alınamadı.'"),
			Owner);
		Raise ExceptionText;
		
	EndTry;
	
	Query = New Query("
		|SELECT TOP 1
		|	ManufacturingOperations.Id AS Id
		|FROM
		|	Catalog.ManufacturingOperations AS ManufacturingOperations
		|WHERE
		|	ManufacturingOperations.Owner = &Owner
		|	AND NOT ManufacturingOperations.DeletionMark
		|
		|ORDER BY
		|	Id DESC");
	
	Query.SetParameter("Owner", Owner);
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return 1;
	EndIf;
	
	Selection = Result.Select();
	Selection.Next();

	Return Selection.Id + 1;

EndFunction

// Creates a new directory item by copying an existing one, then writes it.
//  (used when copying the route map).
//
// Parameters:
//  Source - CatalogRef.ManufacturingOperations	 - the operation-source
//  Owner - CatalogRef.RouteSheets			 - the owner of the operations.
// 
// Returns:
//  CatalogRef.ManufacturingOperations - a new operation.
//
Function CopyProcessOperation(Source, Owner) Export
	
	LinkToOperation = Catalogs.ManufacturingOperations.EmptyRef();
	
	BeginTransaction();
	Try
		
		OperationObject = Source.Copy();
		OperationObject.Owner = Owner;
		
		OperationObject.FillInServiceDetails();
		
		OperationObject.DataExchange.Load = True;
		OperationObject.Write();
		
		LinkToOperation = OperationObject.Ref;
		
		CommitTransaction();
		
	Except
		
		RollbackTransaction();
		
		EventName = NStr("vi = 'Thực hiện giao dịch';
						|ru = 'Выполнение операции';
						|en = 'Performing operation'; fa = 'در حال اجرای عملیات';
						|it = 'Svolgimento dell''operazione';
						|pl = 'Wykonanie operacji';
						|tr = 'İşlemin gerçekleştirilmesi'", CommonClientServer.DefaultLanguageCode());
		
		WriteLogEvent(
			EventName,
			EventLogLevel.Error,
			Metadata.Catalogs.ManufacturingOperations,
			,
			DetailErrorDescription(ErrorInfo()));
		
	EndTry;
	
	Return LinkToOperation;
	
EndFunction

// Determines whether operations are looped
//
// Parameters:
//  RouteMapToCheck	- CatalogRef.RouteSheets - route map
//								whose operations (and all subordinates) will be checked for looping
//  OriginalRouteMap		- CatalogRef.RouteSheets - a route map that should not be referenced
//  Cancel						- Boolean - indicates that the action was rejected.
//
// Returns:
//   Boolean   - True if there is a looping of operations.
//
Function HasLoop(RouteMapToCheck, OriginalRouteMap, Cancel = False) Export

	If RouteMapToCheck = OriginalRouteMap Then
		Cancel = True;
		Return True;
	EndIf; 
	
	Query = New Query;
	Query.Text = 
	"SELECT
	|	ManufacturingOperations.Ref AS Ref,
	|	ManufacturingOperations.NestedRoute AS NestedRoute
	|FROM
	|	Catalog.ManufacturingOperations AS ManufacturingOperations
	|WHERE
	|	NOT ManufacturingOperations.DeletionMark
	|	AND ManufacturingOperations.Owner IN(&VerifiableRouteMaps)
	|	AND ManufacturingOperations.ContainsNestedRoute";
	
	Query.SetParameter("OriginalRouteMap", OriginalRouteMap);
	
	VerifiableRouteMaps = New Array;
	VerifiableRouteMaps.Add(RouteMapToCheck);
	
	While VerifiableRouteMaps.Count() <> 0 Do
		
		Query.SetParameter("VerifiableRouteMaps", VerifiableRouteMaps);
		
		Result = Query.Execute();
		Selection = Result.Select();
		
		VerifiableRouteMaps.Clear();
		
		While Selection.Next() Do
			If Selection.NestedRoute = OriginalRouteMap Then
				Cancel = True;
				Return True;
			Else
				VerifiableRouteMaps.Add(Selection.NestedRoute);
			EndIf;
		EndDo;
		
	EndDo;

	Return False;
	
EndFunction

// Returns the standard value of the additional details of the operation.
//
// Parameters:
//  Ref - CatalogRef.ManufacturingOperations - operation for which you need to get standards.
// 
// Returns:
//  ValueTable - standards with columns:
//		* Property - ChartOfCharacteristicTypesRef.AdditionalAttributesAndInfo - link to the props.
//		* ValueMin - Number - lower standard value.
//		* ValueMax - Number - upper standard value.
//		* Format - String - format for editing and displaying props.
//
Function StandardsOfValuesOfAdditionalDetails(Ref) Export
	
	Query = New Query;
	
	OperationKind = Common.ObjectAttributeValue(Ref, "OperationKind");
	
	If OperationKind.IsEmpty() Then
		
		Query.Text = 
			"SELECT
			|	Standards.Property     AS Property,
			|	Standards.ValueMin  AS ValueMin,
			|	Standards.ValueMax AS ValueMax,
			|	""""                   AS Format
			|FROM
			|	Catalog.ManufacturingOperations.OperationKindStandards AS Standards
			|WHERE
			|	Standards.Ref = &Ref";
		
	Else
		
		TempTablesManager = New TempTablesManager;
		Catalogs.TechnologicalOperationKinds.CreateTTSetProperties(OperationKind, TempTablesManager, True, False);
		Query.TempTablesManager = TempTablesManager;
		
		Query.Text = 
			"SELECT
			|	Standards.Property                            AS Property,
			|	Standards.ValueMin                         AS ValueMin,
			|	Standards.ValueMax                        AS ValueMax,
			|	ISNULL(SetProperties.FormatProperties, """") AS Format
			|FROM
			|	Catalog.ManufacturingOperations.OperationKindStandards AS Standards
			|		LEFT JOIN TTSetProperties AS SetProperties
			|		ON Standards.Property = SetProperties.Property
			|WHERE
			|	Standards.Ref = &Ref";
		
	EndIf;
	
	Query.SetParameter("Ref", Ref);
	
	Return Query.Execute().Unload();
	
EndFunction

// Returns the text of the request for getting the details of the operation performer
//
// Parameters:
//  NameOfOperationTable	 - String	 - name of the process Operation table.
// 
// Returns:
//   - String - the text of the request for obtaining the details of calculating the time of the operation.
//
Function QueryTextAttributesOfContractorOfOperation(NameOfOperationTable) Export
	
	QueryText =
		"CASE
		|	WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenterTypes
		|		THEN ManufacturingOperations.WorkCenter
		|	ELSE ManufacturingOperations.WorkCenter.WorkCenterType
		|END AS WorkCenterType,
		|
		|ManufacturingOperations.WorkCenter AS WorkCenter,
		|
		|CASE
		|	WHEN ManufacturingOperations.WorkCenter = UNDEFINED
		|			OR ManufacturingOperations.WorkCenter = VALUE(Catalog.WorkCenterTypes.EmptyRef)
		|			OR ManufacturingOperations.WorkCenter = VALUE(Catalog.WorkCenters.EmptyRef)
		|		THEN FALSE
		|	WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenterTypes
		|		THEN ManufacturingOperations.WorkCenter.ParallelLoad
		|	ELSE ManufacturingOperations.WorkCenter.WorkCenterType.ParallelLoad
		|END AS ParallelLoad";
		
	Return StrReplace(QueryText, "ManufacturingOperations" ,NameOfOperationTable);
	
EndFunction

// Returns the text of the request for getting details for calculating the operation execution time.
//
// Parameters:
//  NameOfOperationTable	 - String	 - name of the process Operation table.
// 
// Returns:
//   - String - the text of the request for obtaining the details of calculating the time of the operation.
//
Function QueryTextAttributesForCalculatingTimeOfOperation(NameOfOperationTable) Export
	
	QueryText = 
		"CASE
		|		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN CASE
		|					WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).ParallelLoad
		|							AND CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|						THEN CASE
		|								WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).SetupSettingsAreUsed
		|									THEN ManufacturingOperations.SetupSettings.OperationTime
		|								ELSE CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).OperationTime
		|							END
		|					ELSE ManufacturingOperations.TimePerPiece
		|				END
		|		ELSE CASE
		|				WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ParallelLoad
		|						AND CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|					THEN CASE
		|							WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.SetupSettingsAreUsed
		|								THEN ManufacturingOperations.SetupSettings.OperationTime
		|							ELSE CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.OperationTime
		|						END
		|				ELSE ManufacturingOperations.TimePerPiece
		|			END
		|	END AS TimePerPiece,
		|	CASE
		|		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN CASE
		|					WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).ParallelLoad
		|							AND CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|						THEN CASE
		|								WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).SetupSettingsAreUsed
		|									THEN ManufacturingOperations.SetupSettings.UnitOfMeasure
		|								ELSE CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenterTypes).UnitOfMeasure
		|							END
		|					ELSE ManufacturingOperations.TimePerPieceUnitOfMeasure
		|				END
		|		ELSE CASE
		|				WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ParallelLoad
		|						AND CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.ImportOption = VALUE(Enum.WorkCenterLoadOptions.Synchronous)
		|					THEN CASE
		|							WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.SetupSettingsAreUsed
		|								THEN ManufacturingOperations.SetupSettings.UnitOfMeasure
		|							ELSE CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkCenterType.UnitOfMeasure
		|						END
		|				ELSE ManufacturingOperations.TimePerPieceUnitOfMeasure
		|			END
		|	END AS TimePerPieceUnitOfMeasure,
		|	ManufacturingOperations.SetupTime AS SetupTime,
		|	ManufacturingOperations.SetupTimeUnitOfMeasure AS SetupTimeUnitOfMeasure,
		|	CASE
		|		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenters
		|			THEN CASE
		|					WHEN CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters) = VALUE(Catalog.WorkCenters.EmptyRef)
		|						THEN 1
		|					ELSE  CAST(ManufacturingOperations.WorkCenter AS Catalog.WorkCenters).WorkTimeFactor
		|				END
		|			ELSE 1
		|	END AS WorkTimeFactor";
		
	Return StrReplace(QueryText, "ManufacturingOperations" ,NameOfOperationTable);
	
EndFunction

// Query Text for getting the Type of Work Center and Work Center.
// 
// Parameters:
//  NameOfOperationTable - String
//  Fields - String - Fields
//  OutputAliases - Boolean
// 
// Returns:
//  String - The Query Text of the RCVRC
Function QueryTextOfRCVRC(NameOfOperationTable, Fields = "", OutputAliases = True) Export
	
	QueryText = "";
	
	FieldName = "WorkCenterType";
	If IsBlankString(Fields) Or StrFind(Fields, FieldName) > 0 Then
		QueryText = QueryText + StrTemplate("CASE
		|		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenterTypes
		|			THEN ManufacturingOperations.WorkCenter
		|		ELSE
		|			ManufacturingOperations.WorkCenter.WorkCenterType
		|	END %1,
		|", ?(OutputAliases, "AS "+FieldName, ""));
	EndIf;
	
	FieldName = "WorkCenter";
	If IsBlankString(Fields) Or StrFind(Fields, FieldName) > 0 Then
		QueryText = QueryText + StrTemplate("CASE
		|		WHEN ManufacturingOperations.WorkCenter REFS Catalog.WorkCenters
		|			THEN ManufacturingOperations.WorkCenter
		|		ELSE
		|			VALUE(Catalog.WorkCenters.EmptyRef)
		|	END %1,
		|", ?(OutputAliases, "AS "+FieldName, ""));
	EndIf;
	
	QueryText = StrReplace(QueryText, "ManufacturingOperations", NameOfOperationTable);
	
	Return QueryText;
	
EndFunction

#EndRegion

#EndIf

#Region EventHandlers

Procedure FormGetProcessing(FormType, Parameters, SelectedForm, AdditionalInformation, StandardProcessing)

	ProductDataManagementServerCall.TechnologicalOperationsProcessingOfObtainingForm(
				FormType, 
				Parameters, 
				SelectedForm, 
				StandardProcessing);
	
EndProcedure

#EndRegion

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

#Region NumberingOfOperations

// Fills in the order of operations in the table
// 
// Parameters:
// 	OperationTable - ValueTable - operation table
//
Procedure FillInOrderOfOperations(OperationTable) Export
	
	OperationTable.Columns.Add("AssignedNumber",          New TypeDescription("Boolean"));
	OperationTable.Columns.Add("FollowingNumberIsAssigned", New TypeDescription("Boolean"));
	
	CurrentNumber = MaximumOperationNumber(OperationTable) + 1;
	AssignedNumbers = New Map;
	
	FillInNumberOfInitialOperations(OperationTable, CurrentNumber, AssignedNumbers);
	FillInNumberOfDependentOperations(OperationTable, CurrentNumber, AssignedNumbers);
	RemoveNestedRoutesFromOperationsTable(OperationTable);
	
	OperationTable.Columns.Delete("AssignedNumber");
	OperationTable.Columns.Delete("FollowingNumberIsAssigned");
	
EndProcedure

Function MaximumOperationNumber(OperationTable)
	
	If ValueIsFilled(OperationTable) Then
		
		TableOfOperationsCopy = OperationTable.Copy(, "OriginalOperationNumber");
		TableOfOperationsCopy.Sort("OriginalOperationNumber Desc");
		Return TableOfOperationsCopy[0].OriginalOperationNumber;
		
	Else
		
		Return 0;
		
	EndIf;
	
EndFunction

Procedure FillInNumberOfInitialOperations(OperationTable, CurrentNumber, AssignedNumbers)
	
	ParentCommunicationKey = New UUID("00000000-0000-0000-0000-000000000000");
	OperationNumbers = InitialOperationNumbers(OperationTable, ParentCommunicationKey);
	
	For Each OperationNumber In OperationNumbers Do
		
		FilterStructure1 = New Structure;
		FilterStructure1.Insert("OriginalOperationNumber", OperationNumber);
		FilterStructure1.Insert("ParentCommunicationKey", ParentCommunicationKey);
	
		StringsList = OperationTable.FindRows(FilterStructure1);
		For Each String In StringsList Do
			
			String.OperationNumber = OperationNumber;
			String.NextOperation = String.SourceNumberOfNextOperation;
			SetOperationNumberAssignedFlag(String);
			
			If String.ContainsNestedRoute Then
				FillInNumberOfOperationsOfNestedRouteRecursively(
					OperationTable, OperationNumber, CurrentNumber, String.ConnectionKey, AssignedNumbers);
			EndIf;
			
		EndDo;
		
	EndDo;
	
EndProcedure

Procedure FillInNumberOfDependentOperations(OperationTable, CurrentNumber, AssignedNumbers)
	
	FilterStructure1 = New Structure;
	FilterStructure1.Insert("ParentCommunicationKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	FilterRawStrings = New Structure;
	FilterRawStrings.Insert("AssignedNumber", True);
	FilterRawStrings.Insert("FollowingNumberIsAssigned", False);
	FilterRawStrings.Insert("ParentCommunicationKey", New UUID("00000000-0000-0000-0000-000000000000"));
	
	StringsList = OperationTable.FindRows(FilterRawStrings);
	While Not StringsList.Count() = 0 Do
		
		For Each String In StringsList Do
			
			FilterStructure1.Insert("OriginalOperationNumber", String.SourceNumberOfNextOperation);
			FollowingLines = OperationTable.FindRows(FilterStructure1);
			
			For Each NextRow In FollowingLines Do
				
				If Not NextRow.AssignedNumber Then
					
					NextRow.OperationNumber = NextRow.OriginalOperationNumber;
					NextRow.NextOperation = NextRow.SourceNumberOfNextOperation;
					SetOperationNumberAssignedFlag(NextRow);
					
					If NextRow.ContainsNestedRoute Then
						FillInNumberOfOperationsOfNestedRouteRecursively(
							OperationTable, NextRow.OperationNumber, CurrentNumber, NextRow.ConnectionKey, AssignedNumbers);
					EndIf;
					
				EndIf;
				
			EndDo;
			
			String.FollowingNumberIsAssigned = True;
			
		EndDo;
		
		StringsList = OperationTable.FindRows(FilterRawStrings);
		
	EndDo;
	
EndProcedure

Procedure RemoveNestedRoutesFromOperationsTable(OperationTable)
	
	OperationSearchStructure = New Structure("ContainsNestedRoute", True);
	StringsList = OperationTable.FindRows(OperationSearchStructure);
	
	If ValueIsFilled(StringsList) Then
		
		For Each LineOperation In StringsList Do
			
			TheStructureOfTheSearch = New Structure("ParentCommunicationKey,NextOperation", LineOperation.ConnectionKey, 0);
			ListOfRecentOperations = OperationTable.FindRows(TheStructureOfTheSearch);
			For Each LastOperation In ListOfRecentOperations Do
				LastOperation.NextOperation = LineOperation.NextOperation;
			EndDo;
			
			OperationTable.Delete(LineOperation);
			
		EndDo;
		
		RenumberMapOperationsWithNestedRoutes(OperationTable);
		OperationTable.Sort("OperationNumber Asc");
		
	EndIf;
	
EndProcedure

Function InitialOperationNumbers(OperationTable, ParentCommunicationKey)
	
	Result = New Array;
	
	TheStructureOfTheSearch = New Structure("ParentCommunicationKey, SourceNumberOfNextOperation", ParentCommunicationKey);
	
	For Each String In OperationTable Do
		
		If String.ParentCommunicationKey <> ParentCommunicationKey Then
			Continue;
		EndIf;
		
		TheStructureOfTheSearch.SourceNumberOfNextOperation = String.OriginalOperationNumber;
		
		FoundRows = OperationTable.FindRows(TheStructureOfTheSearch);
		If FoundRows.Count() = 0 Then
			Result.Add(String.OriginalOperationNumber);
		EndIf;
		
	EndDo;
	
	TMCommonUse.DeleteDuplicateElementsFromArray(Result);
	
	Return Result;
	
EndFunction

Procedure SetOperationNumberAssignedFlag(OperationString)
	
	OperationString.AssignedNumber = True;
	If OperationString.SourceNumberOfNextOperation = 0 Then
		OperationString.FollowingNumberIsAssigned = True;
	EndIf;
	
EndProcedure

Procedure FillInNumberOfOperationsOfNestedRouteRecursively(OperationTable, InitialNumber, CurrentNumber, ParentCommunicationKey, AssignedNumbers)
	
	#Region FirstOperations
	
	OperationNumbers = InitialOperationNumbers(OperationTable, ParentCommunicationKey);
	FilterStructure1 = New Structure("ParentCommunicationKey, OriginalOperationNumber", ParentCommunicationKey);
	
	For Each OriginalOperationNumber In OperationNumbers Do
		
		FilterStructure1.OriginalOperationNumber = OriginalOperationNumber;
		RouteLines = OperationTable.FindRows(FilterStructure1);
		
		For Each String In RouteLines Do
			
			If String.OriginalOperationNumber = 1 Then
				
				String.OperationNumber = InitialNumber;
				
			Else
				
				String.OperationNumber = CurrentNumber;
				CurrentNumber = CurrentNumber + 1;
				
			EndIf;
			
			If ValueIsFilled(String.SourceNumberOfNextOperation) Then
				
				FillInNumberOfNextOperationOfNestedRoute(
					String, AssignedNumbers, CurrentNumber, ParentCommunicationKey);
				
			EndIf;
			
			SetOperationNumberAssignedFlag(String);
			
			If String.ContainsNestedRoute Then
				
				FillInNumberOfOperationsOfNestedRouteRecursively(
					OperationTable, InitialNumber, CurrentNumber, String.ConnectionKey, AssignedNumbers);
				
			EndIf;
			
		EndDo;
		
	EndDo;
	
	#EndRegion
	
	#Region SubsequentOperations
	
	FilterRawStrings = New Structure;
	FilterRawStrings.Insert("AssignedNumber", True);
	FilterRawStrings.Insert("FollowingNumberIsAssigned", False);
	FilterRawStrings.Insert("ParentCommunicationKey", ParentCommunicationKey);
	
	StringsList = OperationTable.FindRows(FilterRawStrings);
	While Not StringsList.Count() = 0 Do
		
		For Each String In StringsList Do
			
			FilterStructure1.Insert("OriginalOperationNumber", String.SourceNumberOfNextOperation);
			FollowingLines = OperationTable.FindRows(FilterStructure1);
			
			For Each NextRow In FollowingLines Do
				
				If Not NextRow.AssignedNumber Then
					
					NextRow.OperationNumber = String.NextOperation;
					
					If ValueIsFilled(NextRow.SourceNumberOfNextOperation) Then
						
						FillInNumberOfNextOperationOfNestedRoute(
							NextRow, AssignedNumbers, CurrentNumber, ParentCommunicationKey);
						
					EndIf;
					
					SetOperationNumberAssignedFlag(NextRow);
					
					If NextRow.ContainsNestedRoute Then
						
						FillInNumberOfOperationsOfNestedRouteRecursively(
							OperationTable, NextRow.OperationNumber, CurrentNumber, NextRow.ConnectionKey, AssignedNumbers);
						
					EndIf;
					
				EndIf;
				
			EndDo;
			
			String.FollowingNumberIsAssigned = True;
			
		EndDo;
		
		StringsList = OperationTable.FindRows(FilterRawStrings);
		
	EndDo;
	
	#EndRegion
	
EndProcedure

Procedure RenumberMapOperationsWithNestedRoutes(OperationTable)
	
	OperationTable.Sort("OperationNumber Asc");
	OperationTable.FillValues(False, "AssignedNumber");
	
	OperationTable.Columns.Add("Successors");
	OperationTable.Columns.Add("Predecessors");
	FillIndexesOfAdjacentOperations(OperationTable);
	
	AssignedNumbers = New Map;
	OperationNumber = 1;
	
	For Each String In OperationTable Do
		
		If String.Predecessors.Count() = 0 Then
			RenumberOperationsRecursively(OperationTable, String, OperationNumber, AssignedNumbers);
		EndIf;
		
	EndDo;
	
	OperationTable.Columns.Delete("Successors");
	OperationTable.Columns.Delete("Predecessors");
	
EndProcedure

Procedure FillInNumberOfNextOperationOfNestedRoute(String, AssignedNumbers, CurrentNumber, ParentCommunicationKey)
	
	SourceNumberOfNextOperation = String.SourceNumberOfNextOperation;
	
	ParentNumbers = AssignedNumbers.Get(ParentCommunicationKey);
	
	If ParentNumbers = Undefined Then
		ParentNumbers = New Map;
	EndIf;
	
	NextOperation = ParentNumbers.Get(SourceNumberOfNextOperation);
	
	If NextOperation = Undefined Then
		
		NextOperation = CurrentNumber;
		CurrentNumber = CurrentNumber + 1;
		ParentNumbers.Insert(SourceNumberOfNextOperation, NextOperation);
		
	EndIf;
	
	String.NextOperation = NextOperation;
	
	AssignedNumbers.Insert(ParentCommunicationKey, ParentNumbers);
	
EndProcedure

Procedure FillIndexesOfAdjacentOperations(OperationTable)
	
	For Each String In OperationTable Do
		
		Successors = New Array;
		TheStructureOfTheSearch = New Structure("OperationNumber", String.NextOperation);
		FoundRows = OperationTable.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In FoundRows Do
			Successors.Add(OperationTable.IndexOf(FoundRow));
		EndDo;
		String.Successors = Successors;
		
		Predecessors = New Array;
		TheStructureOfTheSearch = New Structure("NextOperation", String.OperationNumber);
		FoundRows = OperationTable.FindRows(TheStructureOfTheSearch);
		For Each FoundRow In FoundRows Do
			Predecessors.Add(OperationTable.IndexOf(FoundRow));
		EndDo;
		String.Predecessors = Predecessors;
		
	EndDo;
	
EndProcedure

Procedure RenumberOperationsRecursively(OperationTable, Operation, OperationNumber, AssignedNumbers)
	
	For Each IndexOf In Operation.Predecessors Do
		If Not OperationTable[IndexOf].AssignedNumber Then
			Return;
		EndIf;
	EndDo;
	
	Number = AssignedNumbers.Get(Operation.OperationNumber);
	
	If Number = Undefined Then
		
		Number = OperationNumber;
		AssignedNumbers.Insert(Operation.OperationNumber, Number);
		
		For Each IndexOf In Operation.Predecessors Do
			OperationTable[IndexOf].NextOperation = Number;
		EndDo;
		
		OperationNumber = OperationNumber + 1;
		
	EndIf;
	
	Operation.OperationNumber = Number;
	Operation.AssignedNumber = True;
	
	For Each IndexOf In Operation.Successors Do
		RenumberOperationsRecursively(OperationTable, OperationTable[IndexOf], OperationNumber, AssignedNumbers);
	EndDo;
	
EndProcedure

#EndRegion

#Region Other

Function LengthOfOperationID() Export
	
	Return 5;
	
EndFunction

Function CalculateConversionFactorOfStandards(Operation, Count) Export
	
	If ValueIsFilled(Operation)
		And ValueIsFilled(Count) Then
		
		NumberOfOperations = Common.ObjectAttributeValue(Operation, "Count");
		
		If ValueIsFilled(NumberOfOperations) Then
			Result = Count / NumberOfOperations;
		Else
			Result = 1;
		EndIf;
		
	Else
		
		Result = 1;
		
	EndIf;
	
	Return Result;
	
EndFunction

// Operation Table Constructor
// 
// Returns:
// 	ValueTable - LongDesc:
// * Operation - CatalogRef.ManufacturingOperations -
// * OperationPresentation - String -
// * ConnectionKey - UUID -
// * QuantityPerBatch - Number -
// * Count - Number -
// * UnitOfMeasure - CatalogRef.PackagesAndUnitsOfMeasure
// * OperationID - Number -
// * OperationNumber - Number -
// * NextOperation - Number -
// * OriginalOperationNumber - Number -
// * SourceNumberOfNextOperation - Number -
// * WorkCenter - CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes -
// * WorkCenterType - CatalogRef.WorkCenterTypes -
// * Norm - Number -
// * ParallelLoad - Boolean -
// * RunTime - Number -
// * ExecutionTimeUnitOfMeasure - EnumRef.TimeMeasureUnits -
// * TimePerPiece - Number -
// * TimePerPieceUnitOfMeasure - EnumRef.TimeMeasureUnits -
// * SetupTime - Number -
// * SetupTimeUnitOfMeasure - EnumRef.TimeMeasureUnits -
// * SetupSettings - CatalogRef.SetupOptions -
// * Load - Number -
// * Continuous - Boolean -
// * OperationParent - CatalogRef.ManufacturingOperations -
// * ContainsNestedRoute - Boolean -
// * NestedRoute - CatalogRef.RouteSheets -
// * ParentCommunicationKey - UUID -
// * LinkKeyNestedRoute - UUID -
// * ContainsTechnologicalProcess - Boolean -
// * TechnologicalProcess - CatalogRef.TechnologicalProcesses -
Function OperationTableConstructor() Export
	
	OperationTable = New ValueTable;
	OperationTable.Columns.Add("Operation",              New TypeDescription("CatalogRef.ManufacturingOperations"));
	OperationTable.Columns.Add("OperationPresentation", New TypeDescription("String",, New StringQualifiers(100)));
	OperationTable.Columns.Add("OperationParent",      New TypeDescription("CatalogRef.ManufacturingOperations"));
	OperationTable.Columns.Add("ConnectionKey",             New TypeDescription("UUID"));
	OperationTable.Columns.Add("ParentCommunicationKey",     New TypeDescription("UUID"));
	OperationTable.Columns.Add("QuantityPerBatch",    New TypeDescription("Number", New NumberQualifiers(15,3)));
	OperationTable.Columns.Add("OperationKind",           New TypeDescription("CatalogRef.TechnologicalOperationKinds"));
	
	OperationTable.Columns.Add("Count",            New TypeDescription("Number", New NumberQualifiers(15,3)));
	OperationTable.Columns.Add("UnitOfMeasure",      New TypeDescription("CatalogRef.PackagesAndUnitsOfMeasure"));
	
	OperationTable.Columns.Add("OperationID", New TypeDescription("Number", New NumberQualifiers(25,0)));
	OperationTable.Columns.Add("ProductionOperation", New TypeDescription("DocumentRef.ProductionOperation2_2"));
	
	OperationTable.Columns.Add("OperationNumber",                  New TypeDescription("Number", New NumberQualifiers(5)));
	OperationTable.Columns.Add("NextOperation",         New TypeDescription("Number", New NumberQualifiers(5)));
	OperationTable.Columns.Add("OriginalOperationNumber",          New TypeDescription("Number", New NumberQualifiers(5)));
	OperationTable.Columns.Add("SourceNumberOfNextOperation", New TypeDescription("Number", New NumberQualifiers(5)));
	
	OperationTable.Columns.Add("WorkCenterType", New TypeDescription("CatalogRef.WorkCenterTypes"));
	OperationTable.Columns.Add("WorkCenter",      New TypeDescription("CatalogRef.WorkCenters, CatalogRef.WorkCenterTypes"));
	OperationTable.Columns.Add("ProductionArea", New TypeDescription("CatalogRef.ProductionSites"));
	
	OperationTable.Columns.Add("Norm",             New TypeDescription("Number", New NumberQualifiers(15,3)));
	
	OperationTable.Columns.Add("ParallelLoad", New TypeDescription("Boolean"));
	
	OperationTable.Columns.Add("RunTime",      New TypeDescription("Number", New NumberQualifiers(10,1)));
	OperationTable.Columns.Add("ExecutionTimeUnitOfMeasure", New TypeDescription("EnumRef.TimeMeasureUnits"));
	
	OperationTable.Columns.Add("WorkTimeFactor",  New TypeDescription("Number", New NumberQualifiers(5,2)));
	
	OperationTable.Columns.Add("TimePerPiece",      New TypeDescription("Number", New NumberQualifiers(10,1)));
	OperationTable.Columns.Add("TimePerPieceUnitOfMeasure", New TypeDescription("EnumRef.TimeMeasureUnits"));
	
	OperationTable.Columns.Add("SetupTime",      New TypeDescription("Number", New NumberQualifiers(10,1)));
	OperationTable.Columns.Add("SetupTimeUnitOfMeasure", New TypeDescription("EnumRef.TimeMeasureUnits"));
	
	OperationTable.Columns.Add("SetupSettings",     New TypeDescription("CatalogRef.SetupOptions"));
	OperationTable.Columns.Add("Load",           New TypeDescription("Number", New NumberQualifiers(15,3)));
	OperationTable.Columns.Add("Continuous",        New TypeDescription("Boolean"));
	OperationTable.Columns.Add("Repeatable",     New TypeDescription("Boolean"));
	OperationTable.Columns.Add("Skippable",    New TypeDescription("Boolean"));
	OperationTable.Columns.Add("Control",           New TypeDescription("EnumRef.ManufacturingOperationControlOptions"));
	OperationTable.Columns.Add("TransferLot", New TypeDescription("Number", New NumberQualifiers(15,3)));
	
	//
	OperationTable.Columns.Add("ContainsNestedRoute",  New TypeDescription("Boolean"));
	OperationTable.Columns.Add("NestedRoute",          New TypeDescription("CatalogRef.RouteSheets")); 
	OperationTable.Columns.Add("LinkKeyNestedRoute", New TypeDescription("UUID"));
	OperationTable.Columns.Add("RouteSheet",           New TypeDescription("CatalogRef.RouteSheets"));
	
	//
	TypesOfProcessTechnology = New Array;
	TypesOfProcessTechnology.Add(Type("CatalogRef.RouteSheets"));
	TypesOfProcessTechnology.Add(Type("CatalogRef.TechnologicalProcesses"));
	
	OperationTable.Columns.Add("ContainsTechnologicalProcess", New TypeDescription("Boolean"));
	OperationTable.Columns.Add("TechnologicalProcess", New TypeDescription(TypesOfProcessTechnology));
	OperationTable.Columns.Add("TechnologicalProcessFactor", New TypeDescription("Number", New NumberQualifiers(15,3)));
	OperationTable.Columns.Add("CoefficientOfTechnologicalProcessPerUnitOfBatchOutput", New TypeDescription("Number", New NumberQualifiers(15,3)));
	
	//
	OperationTable.Columns.Add("Stage",       New TypeDescription("CatalogRef.ProductionStages"));
	OperationTable.Columns.Add("StageNumber", New TypeDescription("Number", New NumberQualifiers(5)));
	
	//
	
	
	Return OperationTable;
	
EndFunction

Function DetailsOfOperationRoute(OwnerOfOperation) Export
	
	Result = New Structure("Route, RoutePresentation, RouteAvailable");
	
	If Not ValueIsFilled(OwnerOfOperation) Then
		Result.RoutePresentation = IndividualTechnicalProcessPresentation();
	ElsIf TypeOf(OwnerOfOperation) = Type("CatalogRef.ProductionStages") Then
		Attributes = New Structure;
		Attributes.Insert("Owner");
		Attributes.Insert("OwnerPresentation", "Owner.Presentation");
		AttributesValues = Common.ObjectAttributesValues(OwnerOfOperation, Attributes);
		Result.Route              = AttributesValues.Owner;
		Result.RoutePresentation = AttributesValues.OwnerPresentation;
	Else
		Result.Route              = OwnerOfOperation;
		Result.RoutePresentation = String(OwnerOfOperation);
	EndIf;
	
	Result.RouteAvailable = ValueIsFilled(Result.Route)
		And ?(TypeOf(Result.Route) = Type("CatalogRef.RouteSheets"),
				GetFunctionalOption("UseRouteSheets"),
				GetFunctionalOption("StoreOperationsInBillsOfMaterials"));
	
	Return Result;
	
EndFunction

Function IndividualTechnicalProcessPresentation()
	Return NStr("vi = 'Riêng biệt';
				|ru = 'Индивидуальный';
				|en = 'Individual'; fa = 'شخص حقیقی';
				|it = 'Individual';
				|pl = 'Individual';
				|tr = 'Özelleştirilmiş'");
EndFunction

// Available units for measuring the time of operation.
// 
// Returns:
//  Array of EnumRef.TimeMeasureUnits
Function AvailableTimeUnits() Export
	
	Result = New Array;
	
	Result.Add(Enums.TimeMeasureUnits.Second);
	Result.Add(Enums.TimeMeasureUnits.Minute);
	Result.Add(Enums.TimeMeasureUnits.Hour);
	Result.Add(Enums.TimeMeasureUnits.Days1);
	
	Return Result;
	
EndFunction

Function CheckCorrectTimeUnits(Object)
	
	ObjectModified = False;
	
	AttributesStructure1 = New Structure;
	AttributesStructure1.Insert("TimePerPiece", "TimePerPieceUnitOfMeasure");
	AttributesStructure1.Insert("SetupTime",      "SetupTimeUnitOfMeasure");
	
	For Each KeyAndValue In AttributesStructure1 Do
		
		UnitOfMeasure = Object[KeyAndValue.Value];
		
		If UnitOfMeasure = Enums.TimeMeasureUnits.Day Then
			Object[KeyAndValue.Value] = Enums.TimeMeasureUnits.Days1;
			ObjectModified = True;
		ElsIf UnitOfMeasure = Enums.TimeMeasureUnits.Month Then
			Object[KeyAndValue.Key]     = Object[KeyAndValue.Key] * 30;
			Object[KeyAndValue.Value] = Enums.TimeMeasureUnits.Days1;
			ObjectModified = True;
		ElsIf UnitOfMeasure = Enums.TimeMeasureUnits.Year Then
			Object[KeyAndValue.Key]     = Object[KeyAndValue.Key] * 365;
			Object[KeyAndValue.Value] = Enums.TimeMeasureUnits.Days1;
			ObjectModified = True;
		EndIf;
		
	EndDo;
	
	Return ObjectModified;
	
EndFunction

#EndRegion

#Region InfobaseUpdate

// See InfobaseUpdateSSL.OnAddUpdateHandlers
Procedure OnAddUpdateHandlers(Handlers) Export

	Handler = Handlers.Add();
	Handler.Procedure = "Catalogs.ManufacturingOperations.ProcessDataForMigrationToNewVersion";
	Handler.Version = "2.5.23.25";
	Handler.ExecutionMode = "Deferred";
	Handler.Id = New UUID("83ad3376-d006-69fc-1122-d6c674aa79b3");
	Handler.UpdateDataFillingProcedure = "Catalogs.ManufacturingOperations.RegisterDataToProcessForMigrationToNewVersion";
	Handler.CheckProcedure = "InfobaseUpdate.DataUpdatedForNewApplicationVersion";
	Handler.Comment = NStr("vi = 'Đang sửa đơn vị tính không chính xác.';
							|ru = 'Исправляет некорректные единицы измерения.';
							|en = 'Corrects incorrect units of measure.'; fa = 'Corrects incorrect units of measure.';
							|it = 'Corrects incorrect units of measure.';
							|pl = 'Corrects incorrect units of measure.';
							|tr = 'Hatalı ölçü birimlerini düzeltir.'");
	
	ItemsToRead = New Array;
	ItemsToRead.Add(Metadata.Catalogs.ManufacturingOperations.FullName());
	Handler.ObjectsToRead = StrConcat(ItemsToRead, ",");
	
	Editable1 = New Array;
	Editable1.Add(Metadata.Catalogs.ManufacturingOperations.FullName());
	Handler.ObjectsToChange = StrConcat(Editable1, ",");
	
	ToLock = New Array;
	ToLock.Add(Metadata.Catalogs.ManufacturingOperations.FullName());
	Handler.ObjectsToLock = StrConcat(ToLock, ",");

EndProcedure

// Parameters:
// 	Parameters - See InfobaseUpdate.MainProcessingMarkParameters
//
Procedure RegisterDataToProcessForMigrationToNewVersion(Parameters) Export
	
	Query = New Query("
	|SELECT DISTINCT
	|	Table.Ref AS Ref
	|FROM
	|	Catalog.ManufacturingOperations AS Table
	|WHERE
	|	NOT (Table.TimePerPieceUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.EmptyRef)
	|			OR Table.TimePerPieceUnitOfMeasure IN (&AvailableTimeUnits))
	|	OR NOT (Table.SetupTimeUnitOfMeasure = VALUE(Enum.TimeMeasureUnits.EmptyRef)
	|			OR Table.SetupTimeUnitOfMeasure IN (&AvailableTimeUnits))
	|");
	
	Query.SetParameter("AvailableTimeUnits", AvailableTimeUnits());
	
	InfobaseUpdate.MarkForProcessing(Parameters, Query.Execute().Unload().UnloadColumn("Ref"));
	
EndProcedure

Procedure ProcessDataForMigrationToNewVersion(Parameters) Export
	
	FullObjectName = "Catalog.ManufacturingOperations";
	
	TempTablesManager = New TempTablesManager;
	
	AdditionalParameters = InfobaseUpdate.AdditionalProcessingDataSelectionParameters();
	AdditionalParameters.TempTableName = "TTLinksToProcess";
	
	Result = InfobaseUpdate.CreateTemporaryTableOfRefsToProcess(
		Parameters.Queue,
		FullObjectName,
		TempTablesManager,
		AdditionalParameters);
	
	If Not Result.HasDataToProcess Then
		Parameters.ProcessingCompleted = True;
		Return;
	EndIf;
	
	If Not Result.HasRecordsInTemporaryTable Then
		Parameters.ProcessingCompleted = False;
		Return;
	EndIf;
	
	Query = New Query("
	|SELECT
	|	RefsTable.Ref AS Ref
	|FROM
	|	TTLinksToProcess AS RefsTable
	|");
	Query.TempTablesManager = TempTablesManager;
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		
		BeginTransaction();
		Try
			
			Block = New DataLock;
			Block.Add(FullObjectName).SetValue("Ref", Selection.Ref);
			Block.Lock();
			
			Object = Selection.Ref.GetObject();
				
			ObjectModified = False;
			
			If CheckCorrectTimeUnits(Object) Then
				ObjectModified = True;
			EndIf;
			
			If ObjectModified Then
				InfobaseUpdate.WriteData(Object);
			Else
				InfobaseUpdate.MarkProcessingCompletion(Selection.Ref);
			EndIf;
			
			CommitTransaction();
			
		Except
			
			RollbackTransaction();
			
			InfobaseUpdateTM.ReportFailedProcessing(ErrorInfo(), Selection.Ref);
			
		EndTry;
		
	EndDo;
	
	Parameters.ProcessingCompleted = Not InfobaseUpdate.HasDataToProcess(Parameters.Queue, FullObjectName);
	
EndProcedure

#EndRegion

#EndRegion

#EndIf