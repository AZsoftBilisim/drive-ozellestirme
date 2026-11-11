////////////////////////////////////////////////////////////////////////////////
// Procedures of the repair management subsystem.
// 
////////////////////////////////////////////////////////////////////////////////
//

#Region Public

#Region Posting

// Generates parameters for conducting a document on the registers of the accounting mechanism through the General mechanism of conducting.
//
// Parameters:
//  Document - DocumentObject - recordable document
//  Properties - See DocumentsPosting.DocumentProperties
//
// Returns:
//  Structure - See DocumentsPosting.ParametersOfAccountingMechanism
//
Function ParametersForHoldingDocument(Document, Properties) Export
	
	Parameters = DocumentsPosting.ParametersOfAccountingMechanism();
	
	// Posting
	If Properties.WriteMode = DocumentWriteMode.Posting Then
		
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.AssetRelevancePeriods);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.RMPlan);
		Parameters.SubordinateRegisters.Add(Metadata.InformationRegisters.WorkCenterRM);
		
	EndIf;
	
	Return Parameters;
	
EndFunction

// Returns the text of the queries to reverse the movements when correcting documents
// 
// Parameters:
// 	MetadataOfDocument - MetadataObjectDocument - Metadata of the document that is being held.
// 
// Returns:
// 	Map - Correspondence of the full register name to the text of the reversal request
//
Function TextsOfCancellationRequests(MetadataOfDocument) Export
	
	QueriesTexts = New Map();
	
	Return QueriesTexts;
	
EndFunction

// Complements the request text of the mechanism for checking the ban date by the table of changes.
// 
// Parameters:
// 	Query - Query - used for setting request parameters.
// 
// Returns:
//	Map - matching the names of the register change tables and query texts.
//	
Function QueryTextsMonitoringBanDateBasedOnChangesTable(Query) Export

	MatchingQueryTexts = New Map();
	Return MatchingQueryTexts;
	
EndFunction

// The procedure of formation of movements to the slave control registers repairs.
//
// Parameters:
//	TablesForRegisteredRecords - Structure - document data tables
//	RegisterRecords - RegisterRecordsCollection - collection of document movement record sets
//	Cancel - Boolean - indicates that the document was rejected.
//
Procedure ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, Cancel) Export
	
	If Cancel Then
		Return;
	EndIf;
	
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "AssetRelevancePeriods");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "RMPlan");
	DocumentsPosting.ReflectRegisteredRecords(TablesForRegisteredRecords, RegisterRecords, "WorkCenterRM");
	
EndProcedure

#EndRegion

#Region StandardSubsystems

// Fills an array of structures that will be used for initial filling and restoring the initial filling of profiles.
//
// Parameters:
//  ProfilesDetails - Array of See AccessManagement.NewAccessGroupProfileDescription
//  ParametersOfUpdate - Structure:
//   * UpdateModifiedProfiles - Boolean - the initial value is True.
//   * DenyProfilesChange - Boolean - the initial value is True.
//       If set to False, then the supplied profiles can not only be viewed, but also edited.
//   * UpdatingAccessGroups     - Boolean - the initial value is True.
//   * UpdatingAccessGroupsWithObsoleteSettings - Boolean - the initial value is False.
//       If set to True, the value settings made by the administrator for
//       the type of access that was removed from the profile will also be removed from the access groups.
//
Procedure FillInSuppliedAccessGroupProfiles(ProfilesDetails, ParametersOfUpdate) Export
	
	// The folder of profiles "Repair management".
	FolderDescription_ = AccessManagement.NewDescriptionOfTheAccessGroupProfilesFolder();
	FolderDescription_.Name           = "RMManagement";
	FolderDescription_.Id = "be8dcb85-eb81-11eb-81dc-4cedfb6825bf";
	FolderDescription_.Description  =
		NStr("vi = 'Quản lý sửa chữa';
			|ru = 'Управление ремонтами';
			|en = 'R&M management'; fa = 'R&M management';
			|it = 'Gestione delle riparazioni';
			|pl = 'Zarządzanie remontami';
			|tr = 'Bakım-onarım yönetimi'",
			Common.DefaultLanguageCode());
	ProfilesDetails.Add(FolderDescription_);
	
	AddProfileResponsibleForMaintainingNSIUR(ProfilesDetails);
	AddOperatorProfile(ProfilesDetails);
	AddRepairmanProfile(ProfilesDetails);
	AddRepairPlannerProfile(ProfilesDetails);
	
EndProcedure

// See FilesOperationsOverridable.OnDefineFileStorageCatalogs
//
Procedure OnDefineFileStorageCatalogs(TypeFileOwner, CatalogNames) Export
	
	If TypeFileOwner = Type("DocumentRef.EnterInformationAboutPastRM")
		Or TypeFileOwner = Type("DocumentRef.RMRequest")
		Or TypeFileOwner = Type("DocumentRef.SetRunningTimeValues") Then
		
		CatalogNames.Insert("DocumentsRepairAttachedFiles", True);
	EndIf;
	
EndProcedure

// Defines a list of configuration objects, in the modules of managers of which the procedure is provided 
// Add a creation command on the basis that forms creation commands based on objects.
// For the syntax of the Add Command Creation procedure, see the documentation.
//
// Parameters:
//   Objects - Array - metadata objects (metadata Objects) with commands to create based on.
//
// Example:
//	Objects.Add (Metadata.Guides.Companies);
//   
Procedure OnDefineObjectsWithCreationBasedOnCommands(Objects) Export

	Objects.Add(Metadata.Documents.RMOrder);
	Objects.Add(Metadata.Documents.RMRequest);
	Objects.Add(Metadata.Documents.SetRunningTimeValues);
	Objects.Add(Metadata.Catalogs.SubAssets);

EndProcedure

// See also updating the information base undefined.At firstfillingelements
//
// Parameters:
//  LanguagesCodes - See InfobaseUpdateOverridable.OnInitialItemsFilling.LanguagesCodes
//  Items   - See InfobaseUpdateOverridable.OnInitialItemsFilling.Items
//  TabularSections - See InfobaseUpdateOverridable.OnInitialItemsFilling.TabularSections
//
Procedure OnInitialItemsFilling(LanguagesCodes, Items, TabularSections) Export
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_RMTypes";
	Set.Ref = New UUID("7ba176d4-92ec-4b1e-923f-d72dae040d2f");
	Set.Used = GetFunctionalOption("UseRMManagement");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Dạng sửa chữa';
		|ru = 'Виды ремонтов';
		|en = 'R&M works';
		|it = 'Виды ремонтов';
		|pl = 'Rodzaje napraw';
		|tr = 'Onarım çeşitleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_MaintenanceSchemes";
	Set.Ref = New UUID("2e3f58f0-21e9-4246-9a7f-ae919ba2e145");
	Set.Used = GetFunctionalOption("UseRMManagement");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Phân loại đối tượng vận hành';
		|ru = 'Классы объектов эксплуатации';
		|en = 'Maintenance schemes';
		|it = 'Классы объектов эксплуатации';
		|pl = 'Klasy obiektów eksploatacji';
		|tr = 'Bakım planları'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Catalog_MaintenanceSchemeOptions";
	Set.Ref = New UUID("8195ab63-ba10-4b63-9667-924a13b1c6b9");
	Set.Used = GetFunctionalOption("UseRMManagement");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Phân loại đối tượng vận hành';
		|ru = 'Подклассы объектов эксплуатации';
		|en = 'Maintenance scheme options';
		|it = 'Подклассы объектов эксплуатации';
		|pl = 'Podklasy obiektów użytkowych';
		|tr = 'Bakım planı seçenekleri'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_EnterInformationAboutPastRM";
	Set.Ref = New UUID("ac3bc6e2-0ce0-44b6-8439-f71d7a78bf88");
	Set.Used = GetFunctionalOption("UseRMManagement");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Nhập thông tin về những lần đã sửa chữa';
		|ru = 'Ввод информации о прошлых ремонтах';
		|en = 'Enter information about past R&M';
		|it = 'Ввод информации о прошлых ремонтах';
		|pl = 'Wprowadzenie informacji o poprzednich naprawach';
		|tr = 'Geçmiş onarımlar hakkında bilgi girilmesi'", LanguagesCodes); // @NStr-2
	
	Set = Items.Add();
	Set.PredefinedSetName = "Document_RMRequest";
	Set.Ref = New UUID("53d7e79b-fd7f-499f-a402-288043527252");
	Set.Used = GetFunctionalOption("UseRMManagement");
	NationalLanguageSupportServer.FillMultilanguageAttribute(Set, "Description",
		"vi = 'Đăng ký hỏng hóc tài sản đang vận hành';
		|ru = 'Регистрация дефектов объектов эксплуатации';
		|en = 'Asset R&M request';
		|it = 'Регистрация дефектов объектов эксплуатации';
		|pl = 'Rejestracja wad obiektów eksploatacji';
		|tr = 'İşletme tesislerindeki kusurların kaydedilmesi.'", LanguagesCodes); // @NStr-2
	
EndProcedure

// Called from the module being overridden.
// Contains descriptions of tables and fields of objects for checking data modification prohibitions.
//   Called from the Modificationallowed procedure of the General module of
//   the date of change that is Used in subscribing to the event Before writing an object to check
//   for bans and refuse changes to the prohibited object.
//
// Parameters:
//  DataSources - ValueTable - with columns:
//   * Table     - String - the full name of the metadata object,
//                   such as Metadata.Documents.Prikhodnayanakladnaya.Full name().
//   * DateField    - String - name of the item's details or table part,
//                   such as "date", " Products.Upload date".
//   * Section      - String - the name of a predefined element
//                   "Provideopportunities.Razdelyayutsya".
//   * ObjectField - String - name of the item's or table part's details,
//                   such as "Organization" or " Products.Warehouse".
//
//  To add a string, you can use the add String procedure in the General module of the date change.
//
Procedure FillDataSourcesForPeriodClosingCheck(DataSources) Export
	
	PeriodClosingDates.AddRow(DataSources, "Document.EnterInformationAboutPastRM", "Date", "RMManagement", "Organization");
	PeriodClosingDates.AddRow(DataSources, "Document.RMRequest", "Date", "RMManagement", "Organization");
	PeriodClosingDates.AddRow(DataSources, "Document.SetRunningTimeValues", "Date", "RMManagement", "Organization");
	
EndProcedure


// See PrintManagementOverridable.OnDefinePrintSettings
//
Procedure OnDefinePrintSettings(Settings) Export
	
	ListOfObjects = Settings.PrintObjects;
	ListOfObjects.Add(Documents.EnterInformationAboutPastRM);
	ListOfObjects.Add(Documents.RMOrder);
	ListOfObjects.Add(Documents.RMRequest);
	ListOfObjects.Add(Documents.SetRunningTimeValues);
	ListOfObjects.Add(Catalogs.SubAssets);
	
EndProcedure

// Defines configuration objects whose manager modules have a procedure for adding Report commands
// describing commands for opening contextual reports.
// For the syntax of the Add Report Commands procedure, see the documentation.
//
// Parameters:
//  Objects - Array - metadata objects (metadata Objects) with report commands.
//
Procedure DefineObjectsWithReportCommands(Objects) Export

	Objects.Add(Metadata.Documents.EnterInformationAboutPastRM);
	Objects.Add(Metadata.Documents.RMOrder);
	Objects.Add(Metadata.Documents.RMRequest);
	Objects.Add(Metadata.Documents.SetRunningTimeValues);
	
	Objects.Add(Metadata.DataProcessors.RMDocumentJournal);
	
	Objects.Add(Metadata.Catalogs.SubAssets);
	
EndProcedure

#EndRegion

#Region Other

// The function returns a text representation of the remaining resource
//
// Parameters:
// 		DaysCount - Number - Number of days.
//
// Returns:
// 		String - String representation of the number of days.
//
Function ResidualTimeResourceByLine(DaysCount) Export
	
	Calculus = "";
	Count = 0;
	
	If Not ValueIsFilled(DaysCount) Or DaysCount <= 0 Then
		Return "";
	ElsIf DaysCount > 370 Then
		Calculus = NStr("vi = 'năm, năm, năm';
						|ru = 'год,года,лет';
						|en = 'year, year, years'; fa = 'year, year, years';
						|it = 'Anno, anni, anni';
						|pl = 'rok,roku,lat';
						|tr = 'yıl, yılın, yıllar'");
		Count = Round(DaysCount/365, 1);
	ElsIf DaysCount > 31 Then
		Calculus = NStr("vi = 'tháng, tháng, tháng';
						|ru = 'месяц,месяца,месяцев';
						|en = 'month, month, months'; fa = 'month, month, months';
						|it = 'Mese, mesi, mesi';
						|pl = 'miesiąc,miesiąca,miesięcy';
						|tr = 'ay, ayın, aylar'");
		Count = Round(DaysCount/31, 1);
	Else
		Calculus = NStr("vi = 'ngày,ngày,ngày';
						|ru = 'день,дня,дней';
						|en = 'day,day,days'; fa = 'day,day,days';
						|it = 'giorno, giorni, giorni';
						|pl = 'dzień,dni,dni';
						|tr = 'gün,gün,günler'");
		Count = Round(DaysCount, 1);
	EndIf;
	
	StructureOfCalculus = StringFunctionsClientServer.SplitStringIntoSubstringsArray(Calculus);
	
	NumberOfFirstTwoCharacters = Int(Count) - Int(Count/100)*100;
	NumberOfFirstCharacter_ = Int(Count) - Int(Count/10)*10;
	
	If (NumberOfFirstTwoCharacters>10 And NumberOfFirstTwoCharacters<15)
		Or NumberOfFirstCharacter_=0 Or NumberOfFirstCharacter_>4 Then
		
		Return Format(Count, "NFD=1") + " " + StructureOfCalculus[2];
		
	ElsIf NumberOfFirstCharacter_=1 Then
		
		Return Format(Count, "NFD=1") + " " + StructureOfCalculus[0];
		
	EndIf;
	
	Return Format(Count, "NFD=1") + " " + StructureOfCalculus[1];
	
EndFunction

// See ReportsOptionsOverridable.CustomizeReportsOptions.
//
Procedure CustomizeReportsOptions(Settings) Export

	Reports.AssetsState.CustomizeReportOptions(Settings);
	Reports.StateOfSubAssets.CustomizeReportOptions(Settings);
	Reports.StateOfSubAssetsContext.CustomizeReportOptions(Settings);
	Reports.DefectsOfSubAssets.CustomizeReportOptions(Settings);

EndProcedure

// Finds nodes of operational objects by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  PickingParameters - Structure - Selection parameters.
// 
// Returns:
//  Structure - Contains:
//    * ObjectsArray - Array of CatalogRef.SubAssets - found nodes
//    * NotFound_1 - Array of String - barcodes for which nodes could not be found
//    * DoNotFit - Array of CatalogRef.SubAssets - Nodes that do not match the selection parameters.
//
Function FindNodesByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export
	
	Result = New Structure;
	Result.Insert("ObjectsArray", New Array);
	Result.Insert("DoNotFit", New Array);
	Result.Insert("NotFound_1", New Array);
	
	ArrayOfBarcodes = NonCurrentAssets.ArrayOfBarcodes(BarcodeData_5);
	
	If ArrayOfBarcodes.Count() = 0 Then
		Return Result;
	EndIf; 
	
	TMCommonUse.DeleteDuplicateElementsFromArray(ArrayOfBarcodes);
	
	QueryText = 
	"SELECT
	|	SubAssets.Ref AS Ref,
	|	SubAssets.Barcode AS Barcode,
	|	(SubAssets.Ref IN (&NodesAvailableForSelection) 
	|		OR NOT &UseNodesAvailableForSelection) AS Compatible
	|FROM
	|	Catalog.SubAssets AS SubAssets
	|WHERE
	|	SubAssets.Barcode IN(&ArrayOfBarcodes)
	|
	|ORDER BY
	|	SubAssets.Description,
	|	SubAssets.Barcode";
	
	Query = New Query(QueryText);
	Query.SetParameter("ArrayOfBarcodes", ArrayOfBarcodes);
	
	If PickingParameters <> Undefined Then
		Query.SetParameter("NodesAvailableForSelection", NodesAvailableForSelection(PickingParameters));
		Query.SetParameter("UseNodesAvailableForSelection", True);
	Else
		Query.SetParameter("NodesAvailableForSelection", New Array);
		Query.SetParameter("UseNodesAvailableForSelection", False);
	EndIf;
	
	QueryResult = Query.Execute().Unload();
	
	ObjectsArray = New Array;
	DoNotFit = New Array;
	For Each Selection In QueryResult Do
		If Selection.Compatible Then
			ObjectsArray.Add(Selection.Ref);
		Else
			DoNotFit.Add(Selection.Ref);
		EndIf;
	EndDo;
	
	NotFound_1 = New Array;
	For Each Barcode In ArrayOfBarcodes Do
		If QueryResult.Find(Barcode, "Barcode") = Undefined Then
			NotFound_1.Add(Barcode);
		EndIf; 
	EndDo; 
	
	Result.ObjectsArray = ObjectsArray;
	Result.DoNotFit = DoNotFit;
	Result.NotFound_1 = NotFound_1;

	Return Result;

EndFunction

// Finds operational objects or nodes by barcodes.
//
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
//  PickingParameters - Structure - Selection parameters.
// 
// Returns:
//  Structure - Contains:
//    * ObjectsArray - Array of CatalogRef.Assets, CatalogRef.SubAssets - found objects
//    * NotFound_1 - Array of String - barcodes that could not be found
//    * DoNotFit - Array of CatalogRef.Assets, CatalogRef.SubAssets - Objects that do not match the selection parameters.
//
Function FindObjectsOfOperationOrNodesByBarcodes(BarcodeData_5, PickingParameters = Undefined) Export
	
	ArrayOfBarcodes = NonCurrentAssets.ArrayOfBarcodes(BarcodeData_5);
	
	If ArrayOfBarcodes.Count() = 0 Then
		Return New Array;
	EndIf; 
	
	Result = New Structure;
	Result.Insert("ObjectsArray", New Array);
	Result.Insert("DoNotFit", New Array);
	Result.Insert("NotFound_1", New Array);

	SearchResult = NonCurrentAssets.FindObjectsByBarcodes(BarcodeData_5, PickingParameters);
	CommonClientServer.SupplementArray(Result.ObjectsArray, SearchResult.ObjectsArray);
	CommonClientServer.SupplementArray(Result.DoNotFit, SearchResult.DoNotFit);
	CommonClientServer.SupplementArray(Result.NotFound_1, SearchResult.NotFound_1);
	
	SearchResult = FindNodesByBarcodes(BarcodeData_5, PickingParameters);
	CommonClientServer.SupplementArray(Result.ObjectsArray, SearchResult.ObjectsArray);
	CommonClientServer.SupplementArray(Result.DoNotFit, SearchResult.DoNotFit);
	CommonClientServer.SupplementArray(Result.NotFound_1, SearchResult.NotFound_1);
	
	Return Result;

EndFunction

// Adds nodes by barcode to the table part and fills in the operation object if it is not filled in.
// 
// Parameters:
//  BarcodeData_5 - Structure, Array of String - Barcode data.
// 	Object - FormDataStructure - 
// 	NodeTable_ - FormDataCollection - 
// 	AttributeName - String -
// 	Asset - CatalogRef.Assets -
// 	PickingParameters - Structure -  
// 	
// Returns:
// 	Array - Added lines.
//  Undefined - If nodes could not be found. 
Function AddNodesByBarcode(BarcodeData_5, Object, NodeTable_, AttributeName, Asset = Undefined, PickingParameters = Undefined) Export

	Result = FindNodesByBarcodes(BarcodeData_5, PickingParameters);
	If Result.ObjectsArray.Count() = 0 Then
		Return Undefined;
	EndIf;
	
	QueryText = 
	"SELECT
	|	Nodes.Ref,
	|	Nodes.Owner
	|INTO AllNodes
	|FROM
	|	Catalog.SubAssets AS Nodes
	|WHERE
	|	Nodes.Ref IN (&Nodes)
	|	AND (Nodes.Owner = &Owner
	|		OR &Owner = VALUE(Catalog.Assets.EmptyRef)
	|		OR &Owner = UNDEFINED)
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT TOP 1
	|	AllNodes.Owner
	|INTO OneOwner
	|FROM
	|	AllNodes AS AllNodes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	AllNodes.Ref,
	|	AllNodes.Owner
	|FROM
	|	AllNodes AS AllNodes
	|WHERE
	|	AllNodes.Owner IN
	|		(SELECT
	|			OneOwner.Owner
	|		FROM
	|			OneOwner)";
	
	Query = New Query(QueryText);
	Query.SetParameter("Nodes", Result.ObjectsArray);
	Query.SetParameter("Owner", Asset);
	
	If PickingParameters <> Undefined And PickingParameters.Property("RunningTimeRegistration") Then
		Query.SetParameter("RunningTimeRegistration", PickingParameters.RunningTimeRegistration);
	Else
		Query.SetParameter("RunningTimeRegistration", Undefined);
	EndIf;
	
	Result = Query.Execute();
	If Result.IsEmpty() Then
		Return Undefined;
	EndIf;
	
	AddedRows = New Array;
	
	Selection = Result.Select();
	While Selection.Next() Do
		
		If Not ValueIsFilled(Asset) Then
			Asset = Selection.Owner;
		EndIf;
		
		NewRow = NodeTable_.Add();
		NewRow[AttributeName] = Selection.Ref;
		
		AddedRows.Add(NewRow);
		
	EndDo;

	Return AddedRows;
	
EndFunction

// Returns the nodes available for selection according to the selection parameters.
// 
// Parameters:
// 	Parameters - Structure - 
// 	
// Returns:
// 	Array - Nodes available for selection
Function NodesAvailableForSelection(Parameters) Export
	
	Query = New Query;
	
	Query.SetParameter(
		"RunningTimeRegistration",
		Parameters.Property("RunningTimeRegistration") And Parameters.RunningTimeRegistration);
		
	Query.SetParameter(
		"SettingTheOperatingTime",
		Parameters.Property("SettingTheOperatingTime") And Parameters.SettingTheOperatingTime);
		
	Query.SetParameter(
		"SourceOfTheOperatingTimeIndicator",
		Parameters.Property("SourceOfTheOperatingTimeIndicator") And Parameters.SourceOfTheOperatingTimeIndicator);
		
	Query.SetParameter(
		"RunningTimeValue",
		?(Parameters.Property("RunningTimeValue"), Parameters.RunningTimeValue, Undefined));
		
	Query.SetParameter(
		"ConsumerOfOperatingTime",
		?(Parameters.Property("ConsumerOfOperatingTime"), Parameters.ConsumerOfOperatingTime, Undefined));
	
	If Parameters.Property("Filter")
		And Parameters.Filter.Property("Owner")
		And (ValueIsFilled(Parameters.Filter.Owner)
			Or Not Parameters.Property("AChoiceIsAvailableWithoutAnOwner")) Then
		Query.SetParameter("Owner", Parameters.Filter.Owner);
		Query.SetParameter("UseSelectionByOwner", True);
	Else
		Query.SetParameter("Owner", Undefined);
		Query.SetParameter("UseSelectionByOwner", False);
	EndIf;
	
	Query.Text =
	"SELECT DISTINCT
	|	ClassMetricParameters.Ref
	|INTO Classes
	|FROM
	|	Catalog.MaintenanceSchemes.RunningTimeValues AS ClassMetricParameters
	|WHERE
	|	NOT ClassMetricParameters.Ref.DeletionMark
	|	AND CASE
	|			WHEN &RunningTimeRegistration
	|				THEN NOT ClassMetricParameters.RegisterBySource
	|			WHEN &SettingTheOperatingTime
	|				THEN TRUE
	|			WHEN &SourceOfTheOperatingTimeIndicator
	|				THEN ClassMetricParameters.RunningTimeValue = &RunningTimeValue
	|			ELSE TRUE
	|		END
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	Nodes.Ref AS Ref
	|FROM
	|	Catalog.SubAssets AS Nodes
	|WHERE
	|	Nodes.Ref <> &ConsumerOfOperatingTime
	|
	|	AND (Nodes.Owner = &Owner
	|		OR NOT &UseSelectionByOwner)
	|
	|	AND (NOT &RunningTimeRegistration
	|			AND NOT &SettingTheOperatingTime
	|			AND NOT &SourceOfTheOperatingTimeIndicator
	|
	|		OR Nodes.Class IN
	|			(SELECT
	|				Classes.Ref
	|			FROM
	|				Classes AS Classes))";
	
	Return Query.Execute().Unload().UnloadColumn("Ref");
	
EndFunction

// Generates a new barcode for the node of the operation object.
// 
// Returns:
// 	String - New barcode
Function NewNodeBarcode() Export
	
	BarcodeNumber = CurMaximumNodeBarcode();
	Return GetNodeBarcodeByCode(BarcodeNumber + 1);
	
EndFunction

// Defines the maximum barcode as a number.
// 
// Returns:
// 	Number - The maximum barcode in the form of a number.
Function CurMaximumNodeBarcode() Export

	QueryText = 
	"SELECT TOP 1
	|	SUBSTRING(SubAssets.Barcode, 1, 9) AS CodeString_
	|FROM
	|	Catalog.SubAssets AS SubAssets
	|WHERE
	|	SubAssets.Barcode LIKE ""[0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9][0-9]""
	|ORDER BY
	|	SubAssets.Barcode DESC";
	
	Query = New Query(QueryText);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		DescriptionOfNumberType = Common.TypeDescriptionNumber(9, 0);
		Barcode = DescriptionOfNumberType.AdjustValue(Selection.CodeString_);
	Else	
		Barcode = 0;
	EndIf;

	Return Barcode;
	
EndFunction

// Generates a barcode based on a numeric code.
// 
// Parameters:
// 	Code - Number
// 	
// Returns:
// 	String - Barcode
Function GetNodeBarcodeByCode(Code) Export
	
	Return Format(Code, "ND=9; NLZ=; NG=;");
	
EndFunction

#EndRegion

#EndRegion

#Region Private

#Region Planning

// Adds the time in the specified unit of measurement to the date, taking into account the work schedule. 
// 
// Parameters:
// 	CurrentDate - Date - The date to add the time to.
// 	Time - Number - Time.
// 	TimeUnitOfMeasure - EnumRef.TimeMeasureUnits - The time unit is supported on the Day, the Day, Month, Year.
// 	WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
// 	
// Returns:
// 	Date - 
Function AddTimeToDateBasedOnWorkSchedule(CurrentDate, Time, TimeUnitOfMeasure, WorkScheduleCalendar) Export
	
	NewDate = '00010101000000';
	
	If TimeUnitOfMeasure = Enums.TimeMeasureUnits.Month
		Or TimeUnitOfMeasure = Enums.TimeMeasureUnits.Year Then
		
		If ValueIsFilled(WorkScheduleCalendar) Then
			NearestDatesByScheduleReceivingParameters = WorkSchedules.NearestDatesByScheduleReceivingParameters();
			NearestDatesByScheduleReceivingParameters.RaiseException1 = False;
			
			InitialDates = New Array;
			InitialDates.Add(TMCommonUseClientServer.AddTimeToDate(CurrentDate, Time, TimeUnitOfMeasure));
			UpcomingDates = WorkSchedules.NearestDatesIncludedInSchedule(
				WorkScheduleCalendar, InitialDates, NearestDatesByScheduleReceivingParameters);
				
			If UpcomingDates <> Undefined Then
				NewDate = UpcomingDates.Get(InitialDates[0]);
			EndIf;
		EndIf;
			
	ElsIf TimeUnitOfMeasure = Enums.TimeMeasureUnits.Days1
		Or TimeUnitOfMeasure = Enums.TimeMeasureUnits.Day Then
		
		If ValueIsFilled(WorkScheduleCalendar) Then
			NewDate = WorkSchedules.DateAccordingToSchedule(WorkScheduleCalendar, CurrentDate, Time, False);
		EndIf;
		
	Else
		
		Raise NStr("vi = 'Lỗi gọi hàm - giá trị đơn vị thời gian không được hỗ trợ';
					|ru = 'Ошибка при вызове функции - не поддерживаемое значение единицы времени';
					|en = 'Function call error - time unit value is not supported'; fa = 'Function call error - time unit value is not supported';
					|it = 'Errore durante la chiamata alla funzione - valore di unità temporale non supportato';
					|pl = 'Błąd podczas wywołania funkcji - nie obsługiwana wartość jednostki czasu';
					|tr = 'İşlevi çağırırken hata oluştu - zaman biriminin desteklenmeyen değeri'");

	EndIf;
	
	If Not ValueIsFilled(NewDate) Then
		NewDate = TMCommonUseClientServer.AddTimeToDate(CurrentDate, Time, TimeUnitOfMeasure);
	EndIf;
		
	Return NewDate;
	
EndFunction

// Adds the time in the specified unit of measurement to the date, taking into account the work schedule. 
// 
// Parameters:
// 	CurrentDate - Date - The date to add the time to.
// 	Time - Number - Time.
// 	TimeUnitOfMeasure - EnumRef.TimeMeasureUnits - Unit of time, supported Minute, Hour.
// 	WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
// 	TempTablesManager - TempTablesManager - Must contain a table Throttlebottom.
// 	
// Returns:
// 	Date - LongDesc
Function AddTimeToDateBasedOnWorkSchedule_(CurrentDate, Time, TimeUnitOfMeasure, WorkScheduleCalendar, TempTablesManager) Export

	If TimeUnitOfMeasure = Enums.TimeMeasureUnits.Minute Then
		MinutesCount = Time;
	ElsIf TimeUnitOfMeasure = Enums.TimeMeasureUnits.Hour Then
		MinutesCount = Time * 60;
	Else
		Raise NStr("vi = 'Lỗi gọi hàm - giá trị đơn vị thời gian không được hỗ trợ';
					|ru = 'Ошибка при вызове функции - не поддерживаемое значение единицы времени';
					|en = 'Function call error - time unit value is not supported'; fa = 'Function call error - time unit value is not supported';
					|it = 'Errore durante la chiamata alla funzione - valore di unità temporale non supportato';
					|pl = 'Błąd podczas wywołania funkcji - nie obsługiwana wartość jednostki czasu';
					|tr = 'İşlevi çağırırken hata oluştu - zaman biriminin desteklenmeyen değeri'");
	EndIf;
	
	NewDate = '00010101000000';

	QueryText = 
	"SELECT
	|	ISNULL(NextDate.ScheduleDate, DATETIME(1, 1, 1)) AS ScheduleDate,
	|	ISNULL(NextDate.BegOfMinute, DATETIME(1, 1, 1)) AS BegOfMinute
	|FROM
	|	TT_WorkScheduleByMinute AS CurrentDate
	|
	|		LEFT JOIN TT_WorkScheduleByMinute AS NextDate
	|		ON NextDate.WorkScheduleCalendar = &WorkScheduleCalendar
	|			AND NextDate.MinuteIsIncludedInSchedule
	|			AND NextDate.MinutesFromStartDate
	|				= CurrentDate.MinutesFromStartDate
	|					+ &MinutesCount
	|					+ CASE
	|						WHEN CurrentDate.MinuteIsIncludedInSchedule THEN 0
	|						ELSE 1
	|					END
	|
	|WHERE
	|	CurrentDate.WorkScheduleCalendar = &WorkScheduleCalendar
	|	AND CurrentDate.ScheduleDate = &CurrentDate
	|	AND CurrentDate.BegOfMinute = &BegOfMinute";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentDate", BegOfDay(CurrentDate));
	Query.SetParameter("BegOfMinute", Date(1, 1, 1, Hour(CurrentDate), Minute(CurrentDate), 0));
	Query.SetParameter("MinutesCount", MinutesCount);
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		NewDate = Selection.ScheduleDate + Hour(Selection.BegOfMinute) * 3600 + Minute(Selection.BegOfMinute) * 60;
	EndIf;
	
	If Not ValueIsFilled(NewDate) Then
		NewDate = TMCommonUseClientServer.AddTimeToDate(CurrentDate, Time, TimeUnitOfMeasure);
	EndIf;
	
	Return NewDate;

EndFunction

// Brings the date to the end of the working day, taking into account the work schedule. 
// 
// Parameters:
// 	CurrentDate - Date - The date to add the time to.
// 	WorkScheduleCalendar - CatalogRef.Calendars - work schedule.
// 	TempTablesManager - TempTablesManager - Must contain a table Throttlebottom.
// 	
// Returns:
// 	Date - 
Function EndOfWorkingDay(CurrentDate, WorkScheduleCalendar, TempTablesManager) Export
	
	NewDate = '00010101000000';
	
	QueryText = 
	"SELECT TOP 1
	|	WorkScheduleByMinute.BegOfMinute
	|FROM
	|	TT_WorkScheduleByMinute AS WorkScheduleByMinute
	|WHERE
	|	WorkScheduleByMinute.WorkScheduleCalendar = &WorkScheduleCalendar
	|	AND WorkScheduleByMinute.ScheduleDate = &CurrentDate
	|	AND WorkScheduleByMinute.MinuteIsIncludedInSchedule
	|
	|ORDER BY
	|	WorkScheduleByMinute.BegOfMinute DESC";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("CurrentDate", CurrentDate);
	Query.SetParameter("WorkScheduleCalendar", WorkScheduleCalendar);
	
	Result = Query.Execute();
	Selection = Result.Select();
	
	If Selection.Next() Then
		NewDate = CurrentDate + Hour(Selection.BegOfMinute) * 3600 + Minute(Selection.BegOfMinute) * 60;
	EndIf;
	
	If Not ValueIsFilled(NewDate) Then
		NewDate = EndOfDay(CurrentDate);
	EndIf;

	Return EndOfHour(NewDate);
	
EndFunction

Procedure CreateScheduleByMinute(TempTablesManager, Schedules, StartDate, EndDate) Export

	TablesToUse = TMCommonUse.ListOfTemporaryTables(TempTablesManager);
	
	WorkSchedules.CreateTTWorkSchedulesForPeriod(TempTablesManager, Schedules, StartDate, EndDate);
	
	ListOfMinutes = New ValueTable;
	ListOfMinutes.Columns.Add("BegOfMinute", Common.DateTypeDetails(DateFractions.Time));
	BegOfMinute = '00010101000000';
	For MinuteNumber = 1 To 1440 Do
		NewRow = ListOfMinutes.Add();
		NewRow.BegOfMinute = BegOfMinute + (MinuteNumber - 1) * 60;
	EndDo;
	
	QueryText = 
	"SELECT
	|	ListOfMinutes.BegOfMinute AS BegOfMinute
	|INTO ListOfMinutes
	|FROM
	|	&ListOfMinutes AS ListOfMinutes
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	CalendarSchedules.Calendar AS WorkScheduleCalendar,
	|	CalendarSchedules.ScheduleDate AS ScheduleDate,
	|	ISNULL(ListOfMinutes.BegOfMinute, DATETIME(1,1,1)) AS BegOfMinute,
	|	MAX(CASE
	|		WHEN NOT TTWorkSchedules.ScheduleDate IS NULL
	|			THEN TRUE
	|		ELSE FALSE
	|	END) AS MinuteIsIncludedInSchedule
	|FROM
	|	InformationRegister.CalendarSchedules AS CalendarSchedules
	|		LEFT JOIN ListOfMinutes AS ListOfMinutes
	|		ON TRUE
	|
	|		LEFT JOIN TTWorkSchedules AS TTWorkSchedules
	|		ON TTWorkSchedules.WorkScheduleCalendar = CalendarSchedules.Calendar
	|			AND TTWorkSchedules.ScheduleDate = CalendarSchedules.ScheduleDate
	|			AND TTWorkSchedules.BeginTime <= ListOfMinutes.BegOfMinute
	|			AND TTWorkSchedules.EndTime >= ListOfMinutes.BegOfMinute
	|WHERE
	|	CalendarSchedules.Calendar IN (&Schedules)
	|	AND CalendarSchedules.ScheduleDate BETWEEN &StartDate AND &EndDate
	|
	|GROUP BY
	|	CalendarSchedules.Calendar,
	|	CalendarSchedules.ScheduleDate,
	|	ISNULL(ListOfMinutes.BegOfMinute, DATETIME(1,1,1))
	|
	|ORDER BY
	|	WorkScheduleCalendar,
	|	ScheduleDate,
	|	BegOfMinute";
	
	Query = New Query(QueryText);
	Query.TempTablesManager = TempTablesManager;
	Query.SetParameter("ListOfMinutes", ListOfMinutes);
	Query.SetParameter("Schedules", Schedules);
	Query.SetParameter("StartDate", StartDate);
	Query.SetParameter("EndDate", EndDate);
	
	Result = Query.Execute();

	WorkScheduleByMinute = New ValueTable;
	WorkScheduleByMinute.Columns.Add("WorkScheduleCalendar", New TypeDescription("CatalogRef.Calendars"));
	WorkScheduleByMinute.Columns.Add("MinuteIsIncludedInSchedule", New TypeDescription("Boolean"));
	WorkScheduleByMinute.Columns.Add("ScheduleDate", Common.DateTypeDetails(DateFractions.Date));
	WorkScheduleByMinute.Columns.Add("BegOfMinute", Common.DateTypeDetails(DateFractions.Time));
	WorkScheduleByMinute.Columns.Add("MinutesFromStartDate", Common.TypeDescriptionNumber(15));

	CurWorkSchedule = Undefined;
	MinutesFromStartDate = 0;

	Selection = Result.Select();
	While Selection.Next() Do
	
		If Selection.WorkScheduleCalendar <> CurWorkSchedule Then
			CurWorkSchedule = Selection.WorkScheduleCalendar;
			MinutesFromStartDate = 0;
		EndIf;
		
		NewRow = WorkScheduleByMinute.Add();
		FillPropertyValues(NewRow, Selection);
		NewRow.MinutesFromStartDate = MinutesFromStartDate + ?(NewRow.MinuteIsIncludedInSchedule, 0, -1);
		
		If Selection.MinuteIsIncludedInSchedule Then
			MinutesFromStartDate = MinutesFromStartDate + 1;
		EndIf;
		
	EndDo;
	
	QueryText =
	"SELECT
	|	WorkScheduleByMinute.WorkScheduleCalendar AS WorkScheduleCalendar,
	|	WorkScheduleByMinute.ScheduleDate AS ScheduleDate,
	|	WorkScheduleByMinute.MinuteIsIncludedInSchedule AS MinuteIsIncludedInSchedule,
	|	WorkScheduleByMinute.BegOfMinute AS BegOfMinute,
	|	WorkScheduleByMinute.MinutesFromStartDate AS MinutesFromStartDate
	|INTO TT_WorkScheduleByMinute
	|FROM
	|	&WorkScheduleByMinute AS WorkScheduleByMinute
	|
	|INDEX BY
	|	WorkScheduleCalendar,
	|	MinuteIsIncludedInSchedule,
	|	MinutesFromStartDate,
	|	ScheduleDate";
	Query.Text = QueryText;
	Query.SetParameter("WorkScheduleByMinute", WorkScheduleByMinute);
	Query.Execute();
	
	TablesToUse.Add("TT_WorkScheduleByMinute");
	TMCommonUse.DestroyTemporaryTables(TempTablesManager,, TablesToUse);
	
EndProcedure

#EndRegion

#Region AccessManagement

Procedure AddProfileResponsibleForMaintainingNSIUR(ProfilesDetails)

	// Profile "Responsible for maintaining the NSI repair management".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "AssigneeForMaintainingOfMasterData";
	ProfileDetails.Id = "aa7f3ae5-3b21-498c-bd3a-3d9a005f2eaf";
	ProfileDetails.Parent      = "RMManagement";
	ProfileDetails.Description  = NStr("vi = 'Chịu trách nhiệm nhập Danh mục quản lý sửa chữa';
										|ru = 'Ответственный за ведение НСИ управления ремонтами';
										|en = 'Employee responsible for master data of R&M management'; fa = 'Employee responsible for master data of R&M management';
										|it = 'Responsabile per la conduzione dell''Informazione Normativa di Consultazione della gestione di manutenzioni';
										|pl = 'Odpowiedzialny za utrzymywanie normatywnych informacji w zakresie zarządzania naprawami';
										|tr = 'Onarım yönetimi için master verilerinin tutulmasından sorumlu'", Common.DefaultLanguageCode());
	
	AccessManagementERP.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reading the general NSI.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	
	// Setting up the production management NSI.
	ProfileDetails.Roles.Add("ReadRouteSheets");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadMainRouteSheets");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionSites");
	
	// Setting up a Repair Management NSI
	ProfileDetails.Roles.Add("AddEditFailureTypes");
	ProfileDetails.Roles.Add("AddEditRMTypes");
	ProfileDetails.Roles.Add("AddEditGeneralRMTypes");
	ProfileDetails.Roles.Add("AddEditRunningTimeValues");
	ProfileDetails.Roles.Add("AddEditRunningTimeSetting");
	ProfileDetails.Roles.Add("ReadRunningTime");
	ProfileDetails.Roles.Add("ReadRMActivities");
	
	// Reports
	ProfileDetails.Roles.Add("ViewReportAssetState");
	
	// KI
	ProfileDetails.Roles.Add("SubsystemRepairAndMaintenance");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr(
		"vi = 'Theo hồ sơ có thực hiện các nhiệm vụ sau:
		|1. Quản lý danh mục các đối tượng vận hành và hoạt động sửa chữa
		|2. Soạn thảo và quản lý tài liệu tiêu chuẩn và kỹ thuật quản lý sửa chữa
		|3. Phân tích tờ lộ trình có sẵn, hoàn thiện và phát triển tờ lộ trình mới trong công việc sửa chữa
		|4. Tính toán hiệu suất của thiết bị, tiêu hao nguyên vật liệu.';
		|ru = 'Под профилем выполняются задачи:
		|1. Ведение справочника объектов эксплуатации и ремонтной деятельности
		|2. Разработка и ведение технологической и нормативной документации управления ремонтами
		|3. Анализ существующих, доработка и разработка новых маршрутных карт ремонтных работ
		|4. Расчет производственной мощности оборудования, расходования сырья и материалов.';
		|en = 'Use this profile to:
		|1. Maintain the ""Assets"" and ""R&M activities"" catalogs
		|2. Develop and maintain the manufacturing and standard documents related to R&M management
		|3. Develop, analyze, and enhance R&M route sheets
		|4. Calculate the equipment production capacity, consumption of raw and consumable materials.'; fa = 'Use this profile to:
		|1. Maintain the ""Assets"" and ""R&M activities"" catalogs
		|2. Develop and maintain the manufacturing and standard documents related to R&M management
		|3. Develop, analyze, and enhance R&M route sheets
		|4. Calculate the equipment production capacity, consumption of raw and consumable materials.';
		|it = 'Sotto il profilo vengono eseguiti gli obiettivi:
		| 1. Tenuta del catalogo degli oggetti di esercizio e delle attività di manutenzione
		|2. Elaborazione e tenuta della documentazione tecnologica e normativa di gestione delle manutenzioni
		|3. Analisi delle schede di lavorazione esistenti, rifinitura e stesura delle nuove schede di lavorazione dei lavori di manutenzione
		|4. Calcolo di capacità produttiva dell''impianto, del consumo di materie prime e materiali.';
		|pl = 'Pod profilem są wykonywane zadania: 
		|1. Prowadzenie dokumentacji obiektów eksploatacji czynności naprawczych
		|2. Opracowanie i prowadzenie technologicznej i normatywnej dokumentacji zarządzania naprawami
		|3. Analiza istniejących, rozbudowa i tworzenie nowych kart technologicznych dla czynności naprawczych
		|4. Obliczanie mocy produkcyjnych sprzętu, zużycia surowców i materiałów.';
		|tr = 'Profil altında görevler gerçekleştirilir: 
		| 1. Operasyon nesnelerinin ve onarım faaliyetlerinin bir dizininin tutulması 
		| 2. Onarım yönetiminin teknolojik ve düzenleyici dokümantasyonunun geliştirilmesi ve sürdürülmesi 
		| 3. Onarım işinin mevcut rotalar analiz edilmesi, rafine edilmesi ve geliştirilmesi
		| 4. Ekipman üretim kapasitesinin, hammadde ve malzeme tüketiminin hesaplanması.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddOperatorProfile(ProfilesDetails)
	
	// Profile "Operator".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Operator";
	ProfileDetails.Id = "3be46362-d57a-494a-a0af-4fcf2d5268c9";
	ProfileDetails.Parent      = "RMManagement";
	ProfileDetails.Description  = NStr("vi = 'Người vận hành';
										|ru = 'Эксплуатационник';
										|en = 'Operator'; fa = 'Operator';
										|it = 'Tecnico di manutenzione';
										|pl = 'Operator';
										|tr = 'İşletmeci'", Common.DefaultLanguageCode());
	
	AccessManagementERP.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reading the general NSI.
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	
	// Setting up Repair Management
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadFailureTypes");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadSubAssets");
	ProfileDetails.Roles.Add("ReadRunningTime");
	ProfileDetails.Roles.Add("AddEditDefectRegistrations");
	ProfileDetails.Roles.Add("AddEditAssetActivityRecords");
	ProfileDetails.Roles.Add("AddEditAttachedFilesRMDocuments");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadDefects");
	
	// Reports and processing
	ProfileDetails.Roles.Add("UseRMDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("ViewReportAssetState");
	
	// KI
	ProfileDetails.Roles.Add("SubsystemRepairAndMaintenance");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr(
		"vi = 'Theo hồ sơ có thực hiện các nhiệm vụ sau:
		|1. Nhập bảng kê hỏng hóc và khắc phục hỏng hóc
		|2. Ghi nhận sản lượng của các đối tượng đang vận hành';
		|ru = 'Под профилем выполняются задачи:
		|1. Ведение дефектной ведомости и устранение дефектов
		|2. Регистрация наработок объектов эксплуатации';
		|en = 'The following tasks are performed under the profile:
		|1. Keeping of the defect list and defect elimination
		|2. Registration of the asset activity records'; fa = 'The following tasks are performed under the profile:
		|1. Keeping of the defect list and defect elimination
		|2. Registration of the asset activity records';
		|it = 'Sotto il profilo vengono eseguiti gli obiettivi:
		|1. Tenuta della lista difetti e eliminazione dei difetti
		|2. Registrazione di tempo di funzionamento senza guasti degli oggetti di esercizio';
		|pl = 'Pod profilem są wykonywane zadania: 
		|1. Prowadzenie listy usterek i usuwanie usterek
		|2. Rejestracja zbiorów danych obiektów obsługi';
		|tr = 'Profil altında görevler gerçekleştirilir: 
		|1. Kusur listesinin bakımı ve kusurların giderilmesi
		|2. Varlık işletme süresi kaydı'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddRepairmanProfile(ProfilesDetails)
	
	// Profile "Repairman".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "Repairman";
	ProfileDetails.Id = "a8aa578d-c4f7-49a7-b4b2-0a19e46bce0e";
	ProfileDetails.Parent      = "RMManagement";
	ProfileDetails.Description  = NStr("vi = 'Người sửa chữa';
										|ru = 'Ремонтник';
										|en = 'Repairman'; fa = 'Repairman';
										|it = 'Addetto alla manutenzione';
										|pl = 'Repairman';
										|tr = 'Tamirci'", Common.DefaultLanguageCode());
	
	AccessManagementERP.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reading the general NSI.
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadPriorities");
	ProfileDetails.Roles.Add("ReadPersons");
	ProfileDetails.Roles.Add("ViewLimitsForBudgetingData");
	// Setting up Repair Management
	ProfileDetails.Roles.Add("AddEditInputOfInformationAboutPastRM");
	ProfileDetails.Roles.Add("AddEditInventoryConsumption");
	ProfileDetails.Roles.Add("AddEditProvisionRequests");
	ProfileDetails.Roles.Add("AddEditRMOrders");
	ProfileDetails.Roles.Add("AddEditGoodsTransfers");
	ProfileDetails.Roles.Add("AddEditOtherGoodsReceipt");
	ProfileDetails.Roles.Add("AddEditGoodsIssueNotes");
	ProfileDetails.Roles.Add("AddEditDefectRegistrations");
	ProfileDetails.Roles.Add("AddEditGoodsAssemblies");
	ProfileDetails.Roles.Add("AddEditConsignmentNotes");
	ProfileDetails.Roles.Add("AddEditAttachedFilesRMDocuments");
	ProfileDetails.Roles.Add("ReadFailureTypes");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTime");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadSubAssets");
	ProfileDetails.Roles.Add("ReadPackingLists");
	
	// Operational production planning.
	ProfileDetails.Roles.Add("ReadTeams");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadProductionOrders2_2");
	ProfileDetails.Roles.Add("ReadValueCreationModels");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadBillsOfMaterials");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	
	// Production accounting.
	
	// Registers, reading
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	ProfileDetails.Roles.Add("ReadStockBalanceForReceipt");
	ProfileDetails.Roles.Add("ReadStockOnWarehouses");
	ProfileDetails.Roles.Add("ReadStockBalanceToShip");
	
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	
	// Reports and processing
	ProfileDetails.Roles.Add("UseDataProcessorInternalInventoryTransferLog");
	ProfileDetails.Roles.Add("UseRMDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("ViewReportAssetState");
	ProfileDetails.Roles.Add("ViewReportProductsWithExpiringCertificates");
	ProfileDetails.Roles.Add("ViewRMProgressReport");
	ProfileDetails.Roles.Add("RepairmansReportsAndDataProcessors");
	ProfileDetails.Roles.Add("UseDataProcessorQuantityAndBatchRequest");
	
	// KI
	ProfileDetails.Roles.Add("SubsystemRepairAndMaintenance");
	ProfileDetails.Roles.Add("ProductionSubsystem");
	ProfileDetails.Roles.Add("SectionProductionProductionByThirdParty");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr(
		"vi = 'Theo hồ sơ có thực hiện các nhiệm vụ sau:
		|1. Quản lý bảng kê hỏng hóc và khắc phục hỏng hóc
		|2. Thực hiện các công việc sửa chữa';
		|ru = 'Под профилем выполняются задачи:
		|1. Ведение дефектной ведомости и устранение дефектов
		|2. Выполнение ремонтных работ';
		|en = 'The following tasks are performed under the profile::
		|1. Keeping of the defect list and defect elimination
		|2. Execution of R&M activities'; fa = 'The following tasks are performed under the profile::
		|1. Keeping of the defect list and defect elimination
		|2. Execution of R&M activities';
		|it = 'Sotto il profilo vengono eseguiti i compiti:
		| 1.Tenuta della lista difetti ed eliminazione dei difetti
		|2. Svolgimento lavori di manutenzione';
		|pl = 'Pod profilem są wykonywane zadania: 
		|1. Prowadzenie listy usterek i usuwanie usterek
		|2. Wykonanie czynności naprawczych';
		|tr = 'Profil altında görevler gerçekleştirilir: 
		| 1. Kusur listelerinin tutulması ve kusurların giderilmesi 
		| 2. Onarım çalışmalarının yürütülmesi'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

Procedure AddRepairPlannerProfile(ProfilesDetails)
	
	// Profile "Repair Planner".
	ProfileDetails = AccessManagement.NewAccessGroupProfileDescription();
	ProfileDetails.Name           = "RepairPlanner";
	ProfileDetails.Id = "21f44963-d50c-4cf5-ba7d-4eea317974a9";
	ProfileDetails.Parent      = "RMManagement";
	ProfileDetails.Description  = NStr("vi = 'Lập kế hoạch sửa chữa';
										|ru = 'Планировщик ремонтов';
										|en = 'R&M scheduler'; fa = 'R&M scheduler';
										|it = 'Pianificatore delle manutenzioni';
										|pl = 'Planista napraw';
										|tr = 'Onarım Planlayıcısı'", Common.DefaultLanguageCode());
	
	AccessManagementERP.AddRequiredRolesToYourProfile(ProfileDetails);
	
	// Reading the general NSI.
	ProfileDetails.Roles.Add("ReadProductRange");
	ProfileDetails.Roles.Add("ReadInformationAboutItems");
	ProfileDetails.Roles.Add("ReadLogisticParameters");
	ProfileDetails.Roles.Add("ReadCashAccounts");
	ProfileDetails.Roles.Add("ReadAssignments");
	ProfileDetails.Roles.Add("ReadMasterData");
	ProfileDetails.Roles.Add("ReadDeliveryPoints");
	ProfileDetails.Roles.Add("ReadCompaniesAndBankAccountsOfCompanies");
	ProfileDetails.Roles.Add("ReadLabelTemplatesAndPriceTags");
	ProfileDetails.Roles.Add("ReadPriorities");
	
	// Setting up Repair Management
	ProfileDetails.Roles.Add("AddEditInputOfInformationAboutPastRM");
	ProfileDetails.Roles.Add("AddEditRMOrders");
	ProfileDetails.Roles.Add("ReadFailureTypes");
	ProfileDetails.Roles.Add("ReadRMTypes");
	ProfileDetails.Roles.Add("ReadDefects");
	ProfileDetails.Roles.Add("ReadMaintenanceSchemes");
	ProfileDetails.Roles.Add("ReadRunningTime");
	ProfileDetails.Roles.Add("ReadGeneralRMTypes");
	ProfileDetails.Roles.Add("ReadAssets");
	ProfileDetails.Roles.Add("ReadBalanceOfInventoryConsumptionOrders");
	ProfileDetails.Roles.Add("ReadRunningTimeValues");
	ProfileDetails.Roles.Add("ReadRMActivities");
	ProfileDetails.Roles.Add("ReadSubAssets");
	ProfileDetails.Roles.Add("ReadAttachedFilesRMDocuments");
	
	// Operational production planning.
	ProfileDetails.Roles.Add("ReadTeams");
	ProfileDetails.Roles.Add("ReadEmployeeActivityKinds");
	ProfileDetails.Roles.Add("ReadTypeOfWorkCentersAvailability");
	ProfileDetails.Roles.Add("ReadProductionSites");
	ProfileDetails.Roles.Add("ReadWorkCenterStructure");
	ProfileDetails.Roles.Add("ReadProductionSchedule");
	
	// Reports and processing
	ProfileDetails.Roles.Add("UseRMDocumentJournalDataProcessor");
	ProfileDetails.Roles.Add("UseRMScheduling");
	ProfileDetails.Roles.Add("ViewOfCommandOrderSupplyForecast");
	ProfileDetails.Roles.Add("ViewReportAssetState");
	ProfileDetails.Roles.Add("ViewRMProgressReport");
	ProfileDetails.Roles.Add("RepairPlannerReportsAndProcessing");
	
	// Registers, reading
	ProfileDetails.Roles.Add("ReadRemainingAvailableGoods");
	
	// KI
	ProfileDetails.Roles.Add("SubsystemRepairAndMaintenance");
	
	// Types of access.
	ProfileDetails.AccessKinds.Add("Departments", "AllAllowedByDefault");
	
	// description of the supplied profile.
	ProfileDetails.LongDesc = NStr(
		"vi = 'Theo hồ sơ có thực hiện các nhiệm vụ sau:
		|1. Phát triển chương trình và lịch biểu các công việc sửa chữa theo doanh nghiệp và bộ phận, những điều chỉnh trong kỳ dự tính
		|2. Tạo hướng dẫn phát triển và triển khai các định mức để lập kế hoạch cho hoạt động sửa chữa.';
		|ru = 'Под профилем выполняются задачи:
		|1. Разработка программ и календарных графиков ремонтных работ по предприятию и его подразделениям, их корректировка в течение планируемого периода
		|2. Осуществляется руководство разработкой и внедрением нормативов для планирования ремонтной деятельности.';
		|en = 'The following tasks are performed under the profile:
		|1. Development of programs and schedules of repair activities for the company and its business units, their adjustment during the planned period
		|2. Management of development and implementation of standards for planning repair activities.'; fa = 'The following tasks are performed under the profile:
		|1. Development of programs and schedules of repair activities for the company and its business units, their adjustment during the planned period
		|2. Management of development and implementation of standards for planning repair activities.';
		|it = 'Sotto il profilo vengono eseguiti gli obiettivi:
		|1. Elaborazione dei programmi e delle tabelle dei tempi di lavori di manutenzione in azienda e nei suoi reparti, la loro rettifica nel corso del periodo programmato
		|2. Viene effettuata la gestione dell''elaborazione e applicazione delle normative per la programmazione delle attività di manutenzione.';
		|pl = 'Pod profilem są wykonywane zadania: 
		|1. Opracowanie programów i kalendarzowych harmonogramów czynności naprawczych w firmie i jej działach, ich korekta w ciągu planowanego okresu
		|2. Odbywa się zarządzanie rozwojem i wdrożeniem standardów dla planowania czynności naprawczych.';
		|tr = 'Profil altında görevler gerçekleştirilir: 
		| 1. İşletme ve departmanları üzerindeki onarım çalışmalarının program ve çizelgelerinin geliştirilmesi, planlanan süre boyunca ayarlanması 
		| 2. Onarım faaliyetlerinin planlanması için standartların geliştirilmesi ve uygulanmasını yönetmek.'");
	
	ProfilesDetails.Add(ProfileDetails);
	
EndProcedure

#EndRegion

#EndRegion