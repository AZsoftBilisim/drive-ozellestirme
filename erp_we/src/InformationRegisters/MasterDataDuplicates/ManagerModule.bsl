#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

#Region InterfaceImplementation

// StandardSubsystems.AccessManagement

// Parameters:
//   Restriction - See AccessManagementOverridable.OnFillAccessRestriction.Restriction.
//
Procedure OnFillAccessRestriction(Restriction) Export
	
	Restriction.Text =
	"AllowReadUpdate
	|WHERE
	|	ListReadingAllowed(RefType)";
	
EndProcedure

// End StandardSubsystems.AccessManagement

#EndRegion

#EndRegion

#Region Private

// Adds new entries and updates existing ones, marks duplicates for deletion.
//
// Parameters:
//   Duplicates - ValueTable - collection of duplicates to add See RecordSetTemplate.
//
Procedure AddDuplicates(Duplicates) Export
	
	RecordSet = CreateRecordSet();
	AddedOn = CurrentSessionDate();
	For Each Duplicate1 In Duplicates Do
		NewRecord = RecordSet.Add();
		FillPropertyValues(NewRecord, Duplicate1);
		NewRecord.EmployeeResponsible = Users.CurrentUser();
		NewRecord.AddedOn = AddedOn;
		
		If Duplicate1.DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled Then
			DuplicateObject = Duplicate1.Duplicate1.GetObject();
			DuplicateObject.Lock();
			DuplicateObject.DataExchange.Load = True;
			DuplicateObject.SetDeletionMark(True);
		EndIf;
	EndDo;
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.MasterDataDuplicates");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = Duplicates;
		LockItem.UseFromDataSource("Duplicate1", "Duplicate1");
		Block.Lock();
	Except
		Raise;
	EndTry;
	
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Merge);
	SetPrivilegedMode(False);
	
EndProcedure

Procedure ChangeStatusOfDeletingDuplicates(Duplicates, State) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	MasterDataDuplicates.RefType AS RefType,
		|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicates.Original AS Original,
		|	MasterDataDuplicates.EmployeeResponsible AS EmployeeResponsible,
		|	MasterDataDuplicates.AddedOn AS AddedOn,
		|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
		|	MasterDataDuplicates.ReplacementErrors AS ReplacementErrors,
		|	MasterDataDuplicates.NumberOfReplacementAttempts AS NumberOfReplacementAttempts
		|FROM
		|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
		|WHERE
		|	MasterDataDuplicates.Duplicate1 IN(&Duplicates)";
	Query.SetParameter("Duplicates", Duplicates);
	
	BeginTransaction();
	Try
		BlockingSelection = New ValueTable;
		BlockingSelection.Columns.Add("Duplicate1");
		BlockingSelection.LoadColumn(Duplicates, "Duplicate1");
		
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.MasterDataDuplicates");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = BlockingSelection;
		LockItem.UseFromDataSource("Duplicate1", "Duplicate1");
		Block.Lock();
		
		SetUnloading = Query.Execute().Unload();
		
		ReplacementPlanned = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled;
		For Each Record In SetUnloading Do
			DuplicateObject = Record.Duplicate1.GetObject();
			DuplicateObject.Lock();
			DuplicateObject.DataExchange.Load = True;
			If State = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled Then
				DuplicateObject.SetDeletionMark(True);
			ElsIf State = Enums.MasterDataDuplicateDeletionStates.DeletionIsNotScheduled Then
				DuplicateObject.SetDeletionMark(False);
			EndIf;
			
			Record.DuplicateDeletionState = State;
			If State = ReplacementPlanned Then
				Record.NumberOfReplacementAttempts = 0;
			EndIf;
		EndDo;
		
		RecordSet = CreateRecordSet();
		RecordSet.Load(SetUnloading);
		RecordSet.Write(ReplacementMode.Update);
		
		CommitTransaction();
	Except
		RollbackTransaction();
		
		ErrorInfo = ErrorInfo();
		ForUser = NStr("ru = 'Не удалось изменить статус удаления дублей НСИ. Попробуйте позднее.';
						|vi = 'Cannot change the status of deleting master data duplicates. Try again later.';
						|en = 'Cannot change the status of deleting master data duplicates. Try again later.'; fa = 'Cannot change the status of deleting master data duplicates. Try again later.';
						|it = 'Cannot change the status of deleting master data duplicates. Try again later.';
						|pl = 'Cannot change the status of deleting master data duplicates. Try again later.';
						|tr = 'Master veri yinelenen öğelerinin silme durumu değiştirilemedi. Lütfen daha sonra tekrar deneyin.'");
		ForAdministrator = ErrorProcessing.DetailErrorDescription(ErrorInfo);
		
		Raise(ForUser, , , ForAdministrator, ErrorInfo);
	EndTry;
	
EndProcedure

Procedure DeleteDuplicates(Duplicates, UncheckDelete = False) Export
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	MasterDataDuplicates.RefType AS RefType,
		|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicates.Original AS Original,
		|	MasterDataDuplicates.EmployeeResponsible AS EmployeeResponsible,
		|	MasterDataDuplicates.AddedOn AS AddedOn,
		|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
		|	MasterDataDuplicates.ReplacementErrors AS ReplacementErrors,
		|	MasterDataDuplicates.NumberOfReplacementAttempts AS NumberOfReplacementAttempts
		|FROM
		|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
		|WHERE
		|	MasterDataDuplicates.Duplicate1 IN(&Duplicates)";
	Query.SetParameter("Duplicates", Duplicates);
	QueryResult = Query.Execute();
	
	If UncheckDelete Then
		For Each Duplicate1 In Duplicates Do
			DuplicateObject = Duplicate1.GetObject();
			DuplicateObject.DataExchange.Load = True;
			DuplicateObject.SetDeletionMark(False);
		EndDo;
	EndIf;
	
	Try
		Block = New DataLock;
		LockItem = Block.Add("InformationRegister.MasterDataDuplicates");
		LockItem.Mode = DataLockMode.Exclusive;
		LockItem.DataSource = QueryResult;
		LockItem.UseFromDataSource("Duplicate1", "Duplicate1");
		Block.Lock();
	Except
		Raise;
	EndTry;
	
	RecordSet = CreateRecordSet();
	SetPrivilegedMode(True);
	RecordSet.Load(QueryResult.Unload());
	RecordSet.Write(ReplacementMode.Delete);
	SetPrivilegedMode(False);
	
EndProcedure

// Constructor for creating a recordset.
//
// Returns:
//   ValueTable: 
//     * Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef
//     * Type - CatalogRef.MetadataObjectIDs
//     * Original - CatalogRef,ChartOfCharacteristicTypesRef
//     * OccurrenceQuantity - Number
//     * OccurrenceSearchDate - Date
//     * DuplicateDeletionState - EnumRef.MasterDataDuplicateDeletionStates
//
Function RecordSetTemplate() Export 
	
	RecordsTable = New ValueTable;
	RecordsTable.Columns.Add("Duplicate1");
	RecordsTable.Columns.Add("RefType");
	RecordsTable.Columns.Add("Original");
	RecordsTable.Columns.Add("OccurrenceQuantity", New TypeDescription("Number"));
	RecordsTable.Columns.Add("OccurrenceSearchDate", New TypeDescription("Date"));
	RecordsTable.Columns.Add("DuplicateDeletionState", New TypeDescription("EnumRef.MasterDataDuplicateDeletionStates"));

	Return RecordsTable;
	
EndFunction

Procedure RecalculatePlacesOfUse(Duplicates) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MasterDataDuplicates.RefType AS RefType,
		|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicates.Original AS Original,
		|	MasterDataDuplicates.EmployeeResponsible AS EmployeeResponsible,
		|	MasterDataDuplicates.AddedOn AS AddedOn,
		|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
		|	MasterDataDuplicates.ReplacementErrors AS ReplacementErrors,
		|	MasterDataDuplicates.NumberOfReplacementAttempts AS NumberOfReplacementAttempts
		|FROM
		|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
		|WHERE
		|	MasterDataDuplicates.Duplicate1 IN (&Duplicates)";
	Query.SetParameter("Duplicates", Duplicates);
	SetUnloading = Query.Execute().Unload();
	
	CountingLinks = New Map;
	SearchDate = CurrentSessionDate();
	For Each Duplicate1 In Duplicates Do
		LinkInfo = New Structure;
		LinkInfo.Insert("UsageInstancesCount", 0);
		LinkInfo.Insert("OccurrenceSearchDate", SearchDate);
		
		CountingLinks.Insert(Duplicate1, LinkInfo);
	EndDo;
	
	SearchResult = Common.UsageInstances(Duplicates);
	For Each SearchString In SearchResult Do
		If Not SearchString.IsInternalData Then
			LinkInfo = CountingLinks[SearchString.Ref];
			LinkInfo.UsageInstancesCount = LinkInfo.UsageInstancesCount + 1;
		EndIf;
	EndDo;
	
	For Each LineToWrite In SetUnloading Do
		LinkInfo = CountingLinks[LineToWrite.Duplicate1];
		LineToWrite.OccurrenceQuantity = LinkInfo.UsageInstancesCount;
		LineToWrite.OccurrenceSearchDate = LinkInfo.OccurrenceSearchDate;
	EndDo;
	
	RecordSet = CreateRecordSet();
	RecordSet.Load(SetUnloading);
	RecordSet.Write(ReplacementMode.Update);
	
EndProcedure

// Generates a list of "double-original" pairs to replace links in the database.
//
// Returns:
//   Map of KeyAndValue - replacement pairs where the key is a duplicate link and the value is the original link:
//    * Key - CatalogRef,ChartOfCharacteristicTypesRef
//    * Value - CatalogRef,ChartOfCharacteristicTypesRef
//
Function ReplacementPairs() Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicates.Original AS Original,
	|	VALUETYPE(MasterDataDuplicates.Duplicate1) AS TypeOfDuplicates
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.DuplicateDeletionState = &DuplicateDeletionState
	|	AND MasterDataDuplicates.NumberOfReplacementAttempts < &NumberOfReplacementAttempts
	|TOTALS
	|BY
	|	TypeOfDuplicates";
	
	Query.SetParameter("DuplicateDeletionState", Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionIsScheduled);
	Query.SetParameter("NumberOfReplacementAttempts", 3);
	
	ImpossibleReplacements = New ValueTable;
	ImpossibleReplacements.Columns.Add("Ref");
	ImpossibleReplacements.Columns.Add("DoubleParent");
	ImpossibleReplacements.Columns.Add("ErrorText");
	ImpossibleReplacements.Columns.Add("ErrorObject");
	ImpossibleReplacements.Indexes.Add("Ref");
	
	ReplacementPairs = New Map;
	DuplicatesAndOriginals = New Array;
	
	SetPrivilegedMode(True);
	SelectionByTypes = Query.Execute().Select(QueryResultIteration.ByGroups);
	SetPrivilegedMode(False);
	
	While SelectionByTypes.Next() Do
		
		PairsOfSubstitutionsByType = New Map;
		
		Selection = SelectionByTypes.Select();
		While Selection.Next() Do
			PairsOfSubstitutionsByType.Insert(Selection.Duplicate1, Selection.Original);
		EndDo;
		
		SearchAndReplaceDuplicatesMasterDataOverridable.CheckPossibilityOfReplacingDuplicates(PairsOfSubstitutionsByType, ImpossibleReplacements, SelectionByTypes.TypeOfDuplicates);
		
		For Each Pair In PairsOfSubstitutionsByType Do
			If ImpossibleReplacements.Find(Pair.Key) = Undefined Then
				ReplacementPairs.Insert(Pair.Key, Pair.Value);
				DuplicatesAndOriginals.Add(Pair.Key);
				DuplicatesAndOriginals.Add(Pair.Value);
			EndIf;
		EndDo;
		
		If SelectionByTypes.TypeOfDuplicates = Type("CatalogRef.Partners")
			And GetFunctionalOption("UsePartnersAsCounterparties") Then
			
			AddCounterparties(PairsOfSubstitutionsByType, ReplacementPairs, ImpossibleReplacements, DuplicatesAndOriginals);
		EndIf;
		
	EndDo;
	
	SetPrivilegedMode(True);
	SearchTable = Common.UsageInstances(DuplicatesAndOriginals);
	SearchTable.Indexes.Add("Data");
	SetPrivilegedMode(False);
	
	CheckPossibilityOfReplacingDuplicates(ReplacementPairs, SearchTable, ImpossibleReplacements);
	CheckPossibilityOfReplacingDuplicatesImitationOfReplacement(ReplacementPairs, SearchTable, ImpossibleReplacements);
	
	If ImpossibleReplacements.Count() Then
		UpdateInformationAboutReplacementErrors(ImpossibleReplacements);
	EndIf;
	
	For Each InvalidTake In ImpossibleReplacements Do
		ReplacementPairs.Delete(InvalidTake.Ref);
	EndDo;
	
	Return ReplacementPairs;
	
EndFunction

Procedure AddCounterparties(Partners, ReplacementPairs, ImpossibleReplacements, DuplicatesAndOriginals)
	
	ArrayOfPartners = New Array;
	For Each KeyAndValue In Partners Do
		ArrayOfPartners.Add(KeyAndValue.Key);
		ArrayOfPartners.Add(KeyAndValue.Value);
	EndDo;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Counterparties.Partner AS Partner,
	|	Counterparties.Ref AS Counterparty
	|FROM
	|	Catalog.Counterparties AS Counterparties
	|WHERE
	|	Counterparties.Partner IN (&Partners)";
	Query.SetParameter("Partners", ArrayOfPartners);
	
	SetPrivilegedMode(True);
	QueryResult = Query.Execute().Unload();
	SetPrivilegedMode(False);
	
	Counterparties = New Map;
	For Each KeyAndValue In Partners Do
		StringDouble = QueryResult.Find(KeyAndValue.Key, "Partner");
		Original_Line = QueryResult.Find(KeyAndValue.Value, "Partner");
		
		If StringDouble <> Undefined And Original_Line <> Undefined Then
			Counterparties.Insert(StringDouble.Counterparty, Original_Line.Counterparty);
		EndIf;
	EndDo;
	
	SearchAndReplaceDuplicatesMasterDataOverridable.CheckPossibilityOfReplacingDuplicates(
		Counterparties, ImpossibleReplacements, Type("CatalogRef.Counterparties"));
		
	For Each Pair In Counterparties Do
		If ImpossibleReplacements.Find(Pair.Key) = Undefined Then
			ReplacementPairs.Insert(Pair.Key, Pair.Value);
			DuplicatesAndOriginals.Add(Pair.Key);
			DuplicatesAndOriginals.Add(Pair.Value);
		EndIf;
	EndDo;
	
EndProcedure

Procedure CheckPossibilityOfReplacingDuplicates(ReplacementPairs, SearchTable, InvalidDuplicates)
	
	SearchIndex = New Map;
	For Each SearchString In SearchTable Do
		
		If SearchString.IsInternalData Then
			Continue;
		EndIf;
		
		ErrorObject = SearchString.Data;
		If SearchIndex[ErrorObject] = Undefined Then
			SearchIndex[ErrorObject] = New Array;
		EndIf;
		SearchIndex[ErrorObject].Add(SearchString.Ref);
		
	EndDo;
	
	For Each ReplacementPair In ReplacementPairs Do
		For Each SearchString In SearchIndex Do
			LinksInsideObject = SearchString.Value;
			
			If LinksInsideObject.Find(ReplacementPair.Key) <> Undefined
				And LinksInsideObject.Find(ReplacementPair.Value) <> Undefined Then
				
				InvalidTake = InvalidDuplicates.Add();
				InvalidTake.Ref = ReplacementPair.Key;
				InvalidTake.DoubleParent = ReplacementPair.Key;
				InvalidTake.ErrorText = NStr("ru = 'Дубль и оригинал находятся в одном объекте. Замена ссылок невозможна.';
											|vi = 'The duplicate and the original are in the same object. Cannot replace links.';
											|en = 'The duplicate and the original are in the same object. Cannot replace links.'; fa = 'The duplicate and the original are in the same object. Cannot replace links.';
											|it = 'The duplicate and the original are in the same object. Cannot replace links.';
											|pl = 'The duplicate and the original are in the same object. Cannot replace links.';
											|tr = 'Yinelenen öğe ve orijinal aynı nesnede bulunuyor. Bağlantı değişimi mümkün değil.'");
				InvalidTake.ErrorObject = SearchString.Key;
				
			EndIf;
			
		EndDo;
	EndDo;
	
EndProcedure

Procedure CheckPossibilityOfReplacingDuplicatesImitationOfReplacement(ReplacementPairs, Val SearchTable, InvalidDuplicates)
	
	RowsCount = SearchTable.Count();
	If RowsCount = 0 Then
		Return;
	EndIf;
	RowsOfSearchTable = New Array(RowsCount);
	For IndexOf = 0 To RowsCount - 1 Do
		RowsOfSearchTable[IndexOf] = SearchTable[IndexOf];
	EndDo;
	
	For Each SearchString In RowsOfSearchTable Do // ValueTableRow
		
		If SearchString.IsInternalData Then
			Continue;
		EndIf;
		
		Original = ReplacementPairs[SearchString.Ref];
		If Original = Undefined Then
			Continue;
		EndIf;
		
		SearchString.Ref = Original;
		Filter = New Structure("Data", SearchString.Data);
		FilterByData = SearchTable.FindRows(Filter);
		CheckPossibilityOfReplacingDuplicates(ReplacementPairs, FilterByData, InvalidDuplicates);
		
	EndDo
	
EndProcedure

// Updates information about Master Data duplicate replacement errors in the Information Register and increments the replacement attempt counter.
//
// Parameters:
//   ReplacementErrors - ValueTable - key columns:
//      * Ref - AnyRef
//      * ErrorText - String
//      * ErrorObject - AnyRef
//
Procedure UpdateInformationAboutReplacementErrors(ReplacementErrors) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicates.RefType AS RefType,
	|	MasterDataDuplicates.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicates.Original AS Original,
	|	MasterDataDuplicates.EmployeeResponsible AS EmployeeResponsible,
	|	MasterDataDuplicates.AddedOn AS AddedOn,
	|	MasterDataDuplicates.OccurrenceQuantity AS OccurrenceQuantity,
	|	MasterDataDuplicates.OccurrenceSearchDate AS OccurrenceSearchDate,
	|	MasterDataDuplicates.DuplicateDeletionState AS DuplicateDeletionState,
	|	MasterDataDuplicates.ReplacementErrors AS ReplacementErrors,
	|	MasterDataDuplicates.NumberOfReplacementAttempts AS NumberOfReplacementAttempts
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Duplicate1 IN (&Duplicates)";
	
	Query.SetParameter("Duplicates", ReplacementErrors.UnloadColumn("Ref"));
	UpgradeKit = Query.Execute().Unload();
	
	For Each Record In UpgradeKit Do
		
		ErrorInformation_ = New Structure;
		ErrorInformation_.Insert("Duplicate1", Record.Duplicate1);
		ErrorInformation_.Insert("Original", Record.Original);
		ErrorInformation_.Insert("Errors", New Array);
		
		CollectionOfErrors = ReplacementErrors.FindRows(New Structure("DoubleParent", Record.Duplicate1));
		
		For Each ReplacementError In CollectionOfErrors Do
			ErrorInfo = New Structure("ErrorText, ErrorObject");
			FillPropertyValues(ErrorInfo, ReplacementError);
			ErrorInformation_.Errors.Add(ErrorInfo);
		EndDo;
		
		Record.ReplacementErrors = New ValueStorage(ErrorInformation_, New Deflation(9));
		Record.NumberOfReplacementAttempts = Record.NumberOfReplacementAttempts + 1;
		
		If Record.NumberOfReplacementAttempts > 2 Then
			Record.DuplicateDeletionState = Enums.MasterDataDuplicateDeletionStates.LinkReplacementAndDeletionAreSuspendedDueToErrors;
		EndIf;
		
	EndDo;
	
	RecordSet = CreateRecordSet();
	RecordSet.Load(UpgradeKit);
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Update);
	
EndProcedure

// Returns a structure with information about replacement errors for the specified duplicate.
//
// Parameters:
//   Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef - Link to the duplicated element
//
// Returns:
//   Structure:
//     *Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef
//     *Original - CatalogRef,ChartOfCharacteristicTypesRef
//     *Errors - Array of Structure:
//        **ErrorText - String
//        **ErrorObject - AnyRef
//
Function DoubleReplacementErrors(Duplicate1)Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicates.ReplacementErrors AS ReplacementErrors
	|FROM
	|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates
	|WHERE
	|	MasterDataDuplicates.Duplicate1 = &Duplicate1";
	
	Query.SetParameter("Duplicate1", Duplicate1);
	
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure("Duplicate1, Original, Errors");
	FillPropertyValues(Result, Selection.ReplacementErrors.Get());
	Return Result;
	
EndFunction

// Returns the link types of duplicated Master Data objects.
//
// Returns:
//   ValueTable:
//      * RefType - CatalogRef.MetadataObjectIDs - the type of reference to the object being duplicated.
//
Function DuplicatesTypes()Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED DISTINCT
		|	MasterDataDuplicates.RefType AS RefType
		|FROM
		|	InformationRegister.MasterDataDuplicates AS MasterDataDuplicates";
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

#EndRegion

#EndIf