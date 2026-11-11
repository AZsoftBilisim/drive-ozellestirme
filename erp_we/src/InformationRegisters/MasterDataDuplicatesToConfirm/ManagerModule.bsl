#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

// Adds duplicates to confirmation
//
// Parameters:
//   Duplicates - Array of CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users
//         - ValueTable - a table containing pairs of doubles to add:
//           * Ref1 - CatalogRef, ChartOfCharacteristicTypesRef - Link To The Double
//           * Ref2 - CatalogRef, ChartOfCharacteristicTypesRef - link to the double,
//   Source - CatalogRef.MasterDataDuplicateSearchRules - the search rule by which duplicates were found
//            - CatalogRef.Users - the user who marked the elements with duplicates
//   CalculationOfPlacesOfUse - Undefined, Boolean - the need to supplement the records with information about the use of links.
//
Procedure AddDuplicates(Duplicates, Source, CalculationOfPlacesOfUse = Undefined) Export
	
	Data = NormalizedInformationAboutDoubles(Duplicates);
	DoublesSelection = Data.DoublesSelection;
	PairsOfTakes = Data.PairsOfTakes;
	
	TableToWrite = DistributeDuplicatesIntoGroups(PairsOfTakes, Source, ExistingDuplicates(DoublesSelection));
	AddInformationOnLinks(TableToWrite, CalculationOfPlacesOfUse);
	
	RecordSet = CreateRecordSet();
	RecordSet.Load(TableToWrite);
	SetPrivilegedMode(True);
	RecordSet.Write(ReplacementMode.Append);
	SetPrivilegedMode(False);
	
EndProcedure

// Updates information about the places of use for the specified Master Data duplicates.
//
// Parameters:
//   DuplicatesToUpdate - Array of CatalogRef,ChartOfCharacteristicTypesRef - duplicates that require recalculation
//                                                                                of usage locations.
//
// Returns:
//   Map of CatalogRef,ChartOfCharacteristicTypesRef:
//     * Key - CatalogRef,ChartOfCharacteristicTypesRef - double.
//     * Value - Structure - with the keys "Place of use" and "Place of use":
//        ** OccurrenceSearchDate - Date
//        ** OccurrenceQuantity - Number
//
Function ReReadPlacesOfUse(DuplicatesToUpdate) Export
	
	Query = New Query;
	Query.Text = 
		"SELECT
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicatesToConfirm.Source AS Source,
		|	MasterDataDuplicatesToConfirm.AddedOn AS AddedOn,
		|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|MasterDataDuplicatesToConfirm.Duplicate1 IN (&Duplicates)";
	Query.SetParameter("Duplicates", DuplicatesToUpdate);
	
	SetUnloading = Query.Execute().Unload();
	AddInformationOnLinks(SetUnloading, True);
	
	RecordSet = CreateRecordSet();
	RecordSet.Load(SetUnloading);
	RecordSet.Write(ReplacementMode.Update);
	
	Result = New Map;
	For Each Record In SetUnloading Do
		If Result[Record.Duplicate1] = Undefined Then
			DuplicateData = New Structure;
			DuplicateData.Insert("OccurrenceSearchDate", Record.OccurrenceSearchDate);
			DuplicateData.Insert("OccurrenceQuantity", Record.OccurrenceQuantity);
			
			Result.Insert(Record.Duplicate1, DuplicateData);
		EndIf;
	EndDo;
	
	Return Result;
	
EndFunction

// Deletes register entries included in the specified duplicate groups. If duplicates are transmitted, then only records
// with these duplicates are deleted. If they are not transmitted, then all groups are deleted as a whole.
//
// Parameters:
//   GroupsIDs - String - ID of the duplicate group whose records should be deleted.
//                       - Array of String - ids of the duplicate group whose records need to be deleted.
//   Duplicates - CatalogRef,ChartOfCharacteristicTypesRef
//         - Array of CatalogRef,ChartOfCharacteristicTypesRef - duplicates that need to be deleted.
//
Procedure DeleteDuplicates(GroupsIDs, Duplicates = Undefined) Export
	
	If TypeOf(GroupsIDs) <> Type("Array") Then
		Groups = CommonClientServer.ValueInArray(GroupsIDs);
	Else
		Groups = GroupsIDs;
	EndIf;
	
	QueryText = 
		"SELECT
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicatesToConfirm.Source AS Source,
		|	MasterDataDuplicatesToConfirm.AddedOn AS AddedOn,
		|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	RECORDAUTONUMBER() AS SerialNumber
		|INTO TempTable
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup IN (&Groups)
		|	AND &FilterDuplicates
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TempTable.RefType AS RefType,
		|	TempTable.DuplicatesGroup AS DuplicatesGroup,
		|	TempTable.Duplicate1 AS Duplicate1,
		|	TempTable.Source AS Source,
		|	TempTable.AddedOn AS AddedOn,
		|	TempTable.OccurrenceQuantity AS OccurrenceQuantity,
		|	TempTable.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	INT(TempTable.SerialNumber / &MultiplicityOfGroups) AS Group
		|INTO Result
		|FROM
		|	TempTable AS TempTable
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	Result.RefType AS RefType,
		|	Result.DuplicatesGroup AS DuplicatesGroup,
		|	Result.Duplicate1 AS Duplicate1,
		|	Result.Source AS Source,
		|	Result.AddedOn AS AddedOn,
		|	Result.OccurrenceQuantity AS OccurrenceQuantity,
		|	Result.OccurrenceSearchDate AS OccurrenceSearchDate,
		|	Result.Group AS Group
		|FROM
		|	Result AS Result
		|TOTALS
		|BY
		|	Group";
		
	Query = New Query;
	
	If Duplicates <> Undefined Then
		QueryText = StrReplace(QueryText, "&FilterDuplicates", "MasterDataDuplicatesToConfirm.Duplicate1 IN (&Duplicates)");
		Query.SetParameter("Duplicates", Duplicates);
	Else
		QueryText = StrReplace(QueryText, "&FilterDuplicates", "TRUE");
	EndIf;
	
	Query.Text = QueryText;
	Query.SetParameter("Groups", Groups);
	Query.SetParameter("MultiplicityOfGroups", 100);
	
	QueryResult = Query.Execute();
	SampleGroup = QueryResult.Select(QueryResultIteration.ByGroups);
	
	While SampleGroup.Next() Do
		SetToDelete = CreateRecordSet();
		
		Selection = SampleGroup.Select();
		While Selection.Next() Do
			FillPropertyValues(SetToDelete.Add(), Selection);
		EndDo;
		
		SetToDelete.Write(ReplacementMode.Delete);
	EndDo;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	COUNT(MasterDataDuplicatesToConfirm.Duplicate1) AS Duplicate1
		|INTO GroupsToDelete
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|GROUP BY
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup
		|HAVING
		|	COUNT(MasterDataDuplicatesToConfirm.Duplicate1) = 1
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicatesToConfirm.Source AS Source,
		|	MasterDataDuplicatesToConfirm.AddedOn AS AddedOn,
		|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup IN
		|		(SELECT
		|			T.DuplicatesGroup
		|		FROM
		|			GroupsToDelete AS T)";
	SingleTakeGroups = Query.Execute().Unload();
	SetToDelete = CreateRecordSet();
	SetToDelete.Load(SingleTakeGroups);
	SetToDelete.Write(ReplacementMode.Delete);
	
EndProcedure

// Deletes entries about potential duplicates that
// no longer match the search rule from the Duplicate information register.
//
// Parameters:
//   PairsOfTakes - ValueTable - a table containing pairs of doubles:
//           * Ref1 - CatalogRef, ChartOfCharacteristicTypesRef - link to the double.
//           * Ref2 - CatalogRef, ChartOfCharacteristicTypesRef - link to the double.
//   Source - CatalogRef.MasterDataDuplicateSearchRules - the search rule for which duplicates were found.
//
Procedure CheckDuplicatesForComplianceWithSearchRule(PairsOfTakes, Source) Export
	
	Duplicates = New Array;
	CommonClientServer.SupplementArray(Duplicates, PairsOfTakes.UnloadColumn(0), True);
	CommonClientServer.SupplementArray(Duplicates, PairsOfTakes.UnloadColumn(1), True);
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicatesToConfirm.Source AS Source
		|INTO TTNewTakes
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.Source = &Source
		|	AND MasterDataDuplicatesToConfirm.Duplicate1 IN (&Duplicates)
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
		|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
		|	MasterDataDuplicatesToConfirm.Source AS Source,
		|	MasterDataDuplicatesToConfirm.AddedOn AS AddedOn,
		|	MasterDataDuplicatesToConfirm.OccurrenceQuantity AS OccurrenceQuantity,
		|	MasterDataDuplicatesToConfirm.OccurrenceSearchDate AS OccurrenceSearchDate
		|INTO TTDoublesAccordingToRule
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|WHERE
		|	MasterDataDuplicatesToConfirm.Source = &Source
		|;
		|
		|////////////////////////////////////////////////////////////////////////////////
		|SELECT
		|	TTDoublesAccordingToRule.RefType AS RefType,
		|	TTDoublesAccordingToRule.DuplicatesGroup AS DuplicatesGroup,
		|	TTDoublesAccordingToRule.Duplicate1 AS Duplicate1,
		|	TTDoublesAccordingToRule.Source AS Source,
		|	TTDoublesAccordingToRule.AddedOn AS AddedOn,
		|	TTDoublesAccordingToRule.OccurrenceQuantity AS OccurrenceQuantity,
		|	TTDoublesAccordingToRule.OccurrenceSearchDate AS OccurrenceSearchDate
		|FROM
		|	TTDoublesAccordingToRule AS TTDoublesAccordingToRule
		|		LEFT JOIN TTNewTakes AS TTNewTakes
		|		ON TTDoublesAccordingToRule.RefType = TTNewTakes.RefType
		|		AND TTDoublesAccordingToRule.Duplicate1 = TTNewTakes.Duplicate1
		|		AND TTDoublesAccordingToRule.DuplicatesGroup = TTNewTakes.DuplicatesGroup
		|		AND TTDoublesAccordingToRule.Source = TTNewTakes.Source
		|WHERE
		|	TTNewTakes.Duplicate1 IS NULL";
		
	Query.SetParameter("Source", Source);
	Query.SetParameter("Duplicates", Duplicates);
	
	EntriesToDelete = Query.Execute().Unload();
	RecordSet = CreateRecordSet();
	RecordSet.Load(EntriesToDelete);
	RecordSet.Write(ReplacementMode.Delete);
	
EndProcedure

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

Function NewRecordingKit(DescriptionOfTableTypes) Export
	
	TableToWrite = New ValueTable;
	Columns = "RefType,DuplicatesGroup,Duplicate1,Source,AddedOn,OccurrenceQuantity,OccurrenceSearchDate";
	
	For Each Column In StrSplit(Columns, ",", False) Do
		TableToWrite.Columns.Add(Column, DescriptionOfTableTypes[Column]);
	EndDo;
	
	Return TableToWrite;
	
EndFunction

Function DescriptionOfRegisterTableTypes() Export
	
	Result = New Structure;
	
	Register = Metadata.InformationRegisters.MasterDataDuplicatesToConfirm;
	
	For Each Dimension In Register.Dimensions Do
		Result.Insert(Dimension.Name, Dimension.Type);
	EndDo;
	
	For Each Resource In Register.Resources Do
		Result.Insert(Resource.Name, Resource.Type);
	EndDo;
	
	Return Result;
	
EndFunction

Function NormalizedInformationAboutDoubles(Duplicates)
	
	Result = New Structure;
	Result.Insert("DoublesSelection");
	Result.Insert("PairsOfTakes");
	
	If TypeOf(Duplicates) = Type("Array") Then
		Result.DoublesSelection = Duplicates;
		Result.PairsOfTakes = PairsOfTakes(Duplicates);
	Else
		DoublesSelection = New Array;
		CommonClientServer.SupplementArray(DoublesSelection, Duplicates.UnloadColumn(0), True);
		CommonClientServer.SupplementArray(DoublesSelection, Duplicates.UnloadColumn(1), True);
		
		Result.DoublesSelection = DoublesSelection;
		Result.PairsOfTakes = Duplicates;
	EndIf;
	
	Return Result;
	
EndFunction

Function PairsOfTakes(Duplicates)
	
	ArrayCopy = Common.CopyRecursive(Duplicates);
	
	PairsOfTakes = New ValueTable;
	PairsOfTakes.Columns.Add("Ref1");
	PairsOfTakes.Columns.Add("Ref2");
	
	TotalInArray = ArrayCopy.Count() - 1;
	For IndexOf = 0 To TotalInArray Do
		
		ReverseIndex = TotalInArray - IndexOf;
		
		For Each ArrayElement In ArrayCopy Do
			If ArrayCopy[ReverseIndex] <> ArrayElement Then
				String = PairsOfTakes.Add();
				String.Ref1 = ArrayCopy[ReverseIndex];
				String.Ref2 = ArrayElement;
			EndIf;
		EndDo;
		
		ArrayCopy.Delete(ReverseIndex);
		
	EndDo;
	
	Return PairsOfTakes;
	
EndFunction

Procedure AddDoubleToIndex(IndexesGroup, Duplicate1, DuplicatesGroup, Source)
	
	NewRow = IndexesGroup.Add();
	NewRow.Duplicate1 = Duplicate1;
	NewRow.DuplicatesGroup = DuplicatesGroup;
	NewRow.Source = Source;
	
EndProcedure

// Returns an array of groups that contain the specified duplicate object.
//
// Parameters:
//   IndexOfDoublesAndGroups - ValueTable - index table containing links of duplicates to groups and sources
//   Duplicate1 - CatalogRef
//         - ChartOfCharacteristicTypesRef - object to search for groups for
//
// Returns:
//   Array of Structure:
//                       * DuplicatesGroup - String
//                       * Source - CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users
//
Function DuplicateGroupsInIndex(IndexOfDoublesAndGroups, Duplicate1)
	
	Result = New Array;
	
	SearchBars = IndexOfDoublesAndGroups.FindRows(New Structure("Duplicate1", Duplicate1));
	For Each SearchString In SearchBars Do
		Result.Add(New Structure("DuplicatesGroup, Source", SearchString.DuplicatesGroup, SearchString.Source));
	EndDo;
	
	Return Result;
	
EndFunction

Procedure AddLineToSet(TableToWrite, Duplicate1, DuplicatesGroup, Source)
	
	NewRow = TableToWrite.Add();
	NewRow.Duplicate1 = Duplicate1;
	NewRow.DuplicatesGroup = DuplicatesGroup;
	NewRow.Source = Source;
	
EndProcedure

Function NeedToCreateNewGroup(GroupsOfDoubleOne, DoubleTwoGroups)
	
	BothAreNonEmpty = GroupsOfDoubleOne.Count() > 0 And DoubleTwoGroups.Count() > 0;
	BothAreEmpty = GroupsOfDoubleOne.Count() = 0 And DoubleTwoGroups.Count() = 0;
	
	If BothAreNonEmpty Or BothAreEmpty Then
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction

Function DuplicatesAreInSameGroup(Group1, Group2)
	
	AllGroups = New Array;
	
	For Each MasivaElement In Group1 Do
		AllGroups.Add(MasivaElement.DuplicatesGroup);
	EndDo;
	
	For Each MasivaElement In Group2 Do
		AllGroups.Add(MasivaElement.DuplicatesGroup);
	EndDo;
	
	UniqueGroups = New Array;
	CommonClientServer.SupplementArray(UniqueGroups, AllGroups, True);
	
	TheseAreTakesFromSameGroup = AllGroups.Count() <> UniqueGroups.Count();
	
	Return TheseAreTakesFromSameGroup;
	
EndFunction

// Supplements the row table with information about the types of links and the number of places where Master Data duplicates are used.
//
// Parameters:
//   TableToWrite - ValueTable - a table containing the "Double" column with links for processing.
//   ModeOfUpdatingPlacesOfUse - Boolean, Undefined - defines the mode for updating the number of usage locations.
//      If Undefined, then there is no update.
//      If True, then the update occurs.
//      If false, then the update depends on the value of the constant to perform a search for a place to use the version.
//
Procedure AddInformationOnLinks(TableToWrite, ModeOfUpdatingPlacesOfUse = Undefined) Export
	
	Duplicates = TableToWrite.UnloadColumn("Duplicate1");
	CountingLinks = New Map;
	For Each Duplicate1 In Duplicates Do
		LinkInfo = New Structure;
		LinkInfo.Insert("UsageInstancesCount", 0);
		LinkInfo.Insert("FullMetadataObjectName", Common.TableNameByRef(Duplicate1));
		LinkInfo.Insert("OccurrenceSearchDate");
		LinkInfo.Insert("AddedOn");
		
		CountingLinks.Insert(Duplicate1, LinkInfo);
	EndDo;
	
	If ModeOfUpdatingPlacesOfUse = Undefined Then
		SearchForPlacesOfUse = False;
	Else
		SetPrivilegedMode(True);
		SearchForPlacesOfUse = Constants.SearchForMasterDataDuplicateOccurrences.Get()
			Or ModeOfUpdatingPlacesOfUse;
		SetPrivilegedMode(False);
	EndIf;
	
	If SearchForPlacesOfUse Then
		SearchResult = Common.UsageInstances(Duplicates);
		SearchDate = CurrentSessionDate();
		
		For Each SearchString In SearchResult Do
			If Not SearchString.IsInternalData Then
				LinkInfo = CountingLinks[SearchString.Ref];
				LinkInfo.UsageInstancesCount = LinkInfo.UsageInstancesCount + 1;
				LinkInfo.OccurrenceSearchDate = SearchDate;
			EndIf;
		EndDo;
	EndIf;
	
	AddedOn = CurrentSessionDate();
	For Each LineToWrite In TableToWrite Do
		LinkInfo = CountingLinks[LineToWrite.Duplicate1];
		
		LineToWrite.RefType = Common.MetadataObjectID(LinkInfo.FullMetadataObjectName);
		If Not ValueIsFilled(LineToWrite.AddedOn) Then
			LineToWrite.AddedOn = AddedOn;
		EndIf;
		
		If SearchForPlacesOfUse Then
			LineToWrite.OccurrenceQuantity = LinkInfo.UsageInstancesCount;
			LineToWrite.OccurrenceSearchDate = LinkInfo.OccurrenceSearchDate;
		EndIf;
	EndDo;
	
EndProcedure

// Returns the number of duplicate entries for each Catalog type available.
//
// Returns:
//   ValueTable:
//     * RefType - CatalogRef.MetadataObjectIDs
//     * DuplicateCount - Number
//
Function TypesOfDubsWithQuantity() Export
	
	Query = New Query;
	Query.Text =
		"SELECT ALLOWED
		|	MasterDataDuplicatesToConfirm.RefType AS RefType,
		|	COUNT(MasterDataDuplicatesToConfirm.Duplicate1) AS DuplicateCount
		|FROM
		|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
		|GROUP BY
		|	MasterDataDuplicatesToConfirm.RefType";
	Result = Query.Execute().Unload();
	
	Return Result;
	
EndFunction

// Returns a selection of records based on the specified duplicates.
//
// Parameters:
//   DoublesSelection - Array of CatalogRef,ChartOfCharacteristicTypesRef - values for selection by the "Double" field
//
// Returns:
//   QueryResultSelection - sampling from the query result:
//     * Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef - link to the double.
//     * DuplicatesGroup - String - ID of the duplicate group.
//     * Source - CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users
//
Function ExistingDuplicates(DoublesSelection) Export
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	MasterDataDuplicatesToConfirm.Duplicate1 AS Duplicate1,
	|	MasterDataDuplicatesToConfirm.DuplicatesGroup AS DuplicatesGroup,
	|	MasterDataDuplicatesToConfirm.Source AS Source
	|FROM
	|	InformationRegister.MasterDataDuplicatesToConfirm AS MasterDataDuplicatesToConfirm
	|WHERE
	|	MasterDataDuplicatesToConfirm.Duplicate1 IN (&DoublesSelection)";
	Query.SetParameter("DoublesSelection", DoublesSelection);
	
	SetPrivilegedMode(True);
	ResultOfRequest = Query.Execute();
	SetPrivilegedMode(False);
	
	Return ResultOfRequest.Select();
	
EndFunction

// Distributes duplicates into groups based on the transmitted pairs of duplicates and the data source.
//
// Parameters:
//   PairsOfTakes - ValueTable - duplicates for distribution:
//     * Ref1 - CatalogRef,ChartOfCharacteristicTypesRef - link to the double.
//     * Ref2 - CatalogRef,ChartOfCharacteristicTypesRef - link to the double.
//   Source - CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users - the rule for searching for duplicates or answerable.
//   DuplicatesInDatabase - QueryResultSelection - See ExistingDuplicates
//
// Returns:
//   ValueTable - a table with duplicates distributed by groups:
//     * Duplicate1 - CatalogRef,ChartOfCharacteristicTypesRef - link to the double.
//     * DuplicatesGroup - String - ID of the duplicate group.
//     * Source - CatalogRef.MasterDataDuplicateSearchRules,CatalogRef.Users
//
Function DistributeDuplicatesIntoGroups(PairsOfTakes, Source, DuplicatesInDatabase = Undefined) Export
	
	DescriptionOfTableTypes = DescriptionOfRegisterTableTypes();
	DescriptionOfTableTypes.Duplicate1 = PairsOfTakes.Columns[0].ValueType;
	
	IndexOfDoublesAndGroups = New ValueTable;
	IndexOfDoublesAndGroups.Columns.Add("Duplicate1", DescriptionOfTableTypes.Duplicate1);
	IndexOfDoublesAndGroups.Columns.Add("DuplicatesGroup", DescriptionOfTableTypes.DuplicatesGroup);
	IndexOfDoublesAndGroups.Columns.Add("Source", DescriptionOfTableTypes.Source);
	IndexOfDoublesAndGroups.Indexes.Add("Duplicate1");
	IndexOfDoublesAndGroups.Indexes.Add("Source");
	
	If TypeOf(DuplicatesInDatabase) = Type("QueryResultSelection") Then
		While DuplicatesInDatabase.Next() Do
			AddDoubleToIndex(IndexOfDoublesAndGroups, DuplicatesInDatabase.Duplicate1, DuplicatesInDatabase.DuplicatesGroup, DuplicatesInDatabase.Source);
		EndDo;
	EndIf;
	
	DoublesByGroup = NewRecordingKit(DescriptionOfTableTypes);
	
	For Each CoupleOfTakes In PairsOfTakes Do
		
		TakeOne = CoupleOfTakes[0];
		TakeTwo = CoupleOfTakes[1];
		
		GroupsOfDoubleOne = DuplicateGroupsInIndex(IndexOfDoublesAndGroups, TakeOne);
		DoubleTwoGroups = DuplicateGroupsInIndex(IndexOfDoublesAndGroups, TakeTwo);
		
		If DuplicatesAreInSameGroup(GroupsOfDoubleOne, DoubleTwoGroups) Then
			
			Continue;
			
		ElsIf NeedToCreateNewGroup(GroupsOfDoubleOne, DoubleTwoGroups) Then
			
			NewFolder = String(New UUID());
			AddDoubleToIndex(IndexOfDoublesAndGroups, TakeOne, NewFolder, Source);
			AddDoubleToIndex(IndexOfDoublesAndGroups, TakeTwo, NewFolder, Source);
			AddLineToSet(DoublesByGroup, TakeOne, NewFolder, Source);
			AddLineToSet(DoublesByGroup, TakeTwo, NewFolder, Source);
			
		ElsIf GroupsOfDoubleOne.Count() = 0 Then
			
			For Each SourceGroup In DoubleTwoGroups Do
				If SourceGroup.Source = Source Then
					Group = SourceGroup.DuplicatesGroup;
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeOne, Group, Source);
					AddLineToSet(DoublesByGroup, TakeOne, Group, Source);
					Break;
				Else
					NewFolder = String(New UUID());
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeOne, NewFolder, Source);
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeTwo, NewFolder, Source);
					AddLineToSet(DoublesByGroup, TakeOne, NewFolder, Source);
					AddLineToSet(DoublesByGroup, TakeTwo, NewFolder, Source);
				EndIf;
			EndDo;
			
		ElsIf DoubleTwoGroups.Count() = 0 Then
			
			For Each SourceGroup In GroupsOfDoubleOne Do
				If SourceGroup.Source = Source Then
					Group = SourceGroup.DuplicatesGroup;
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeTwo, Group, Source);
					AddLineToSet(DoublesByGroup, TakeTwo, Group, Source);
					Break;
				Else
					NewFolder = String(New UUID());
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeOne, NewFolder, Source);
					AddDoubleToIndex(IndexOfDoublesAndGroups, TakeTwo, NewFolder, Source);
					AddLineToSet(DoublesByGroup, TakeOne, NewFolder, Source);
					AddLineToSet(DoublesByGroup, TakeTwo, NewFolder, Source);
				EndIf;
			EndDo;
			
		EndIf;
		
	EndDo;
	
	Return DoublesByGroup;
	
EndFunction

// Generates a string Presentation of the group by the names of the elements from the incoming array.
//
// Parameters:
//   Array - Array of CatalogRef.MasterDataDuplicateSearchRules - a collection of values containing links to elements of duplicate directories
//
// Returns:
//   String - group representation
//
Function GroupPresentation(Array) Export
	
	Result = "";
	LengthLimitation = 100;
	
	ResultsArray = New Array;
	For Each Item In Array Do
		If ResultsArray.Find(Item) = Undefined Then
			ResultsArray.Add(TrimAll(Item));
		EndIf;
	EndDo;
	Result = Left(StrConcat(ResultsArray, ","),LengthLimitation) + "...";
	
	Return Result;
	
EndFunction

// Returns an array of group IDs associated with the specified group via shared duplicates.
//
// Parameters:
//   Group - String - ID of the duplicate group.
//
// Returns:
//   Array of String
//
Function RelatedGroups(Group) Export
	
	RelatedGroups = New Map;
	RelatedGroups.Insert(Group, True);
	
	Stack = New Array;
	Stack.Add(Group);
	
	While Stack.Count() > 0 Do
		IndexOf = Stack.UBound();
		CurrentGroup = Stack.Get(IndexOf);
		Stack.Delete(IndexOf);
		
		Query = New Query;
		Query.Text =
			"SELECT DISTINCT
			|	Table2.DuplicatesGroup AS RelatedGroup
			|FROM
			|	InformationRegister.MasterDataDuplicatesToConfirm AS Table1
			|		INNER JOIN InformationRegister.MasterDataDuplicatesToConfirm AS Table2
			|		ON Table1.Duplicate1 = Table2.Duplicate1
			|WHERE
			|	Table1.DuplicatesGroup = &CurrentGroup
			|	AND Table2.DuplicatesGroup <> &CurrentGroup
			|	AND Table2.DuplicatesGroup NOT IN (&VisitedGroups)";
		
		VisitedGroups = New Array;
		For Each KeyValue In RelatedGroups Do
			VisitedGroups.Add(KeyValue.Key);
		EndDo;
		
		Query.SetParameter("CurrentGroup", CurrentGroup);
		Query.SetParameter("VisitedGroups", VisitedGroups);
		
		RelatedGroupsSelection = Query.Execute().Select();
		While RelatedGroupsSelection.Next() Do
			RelatedGroup = RelatedGroupsSelection.RelatedGroup;
			If RelatedGroups[RelatedGroup] = Undefined Then
				RelatedGroups.Insert(RelatedGroup, True);
				Stack.Add(RelatedGroup);
			EndIf;
		EndDo;
	EndDo;
	
	Result = New Array;
	For Each KeyValue In RelatedGroups Do
		Result.Add(KeyValue.Key);
	EndDo;
	
	Return Result;
	
EndFunction


#EndRegion

#EndIf
